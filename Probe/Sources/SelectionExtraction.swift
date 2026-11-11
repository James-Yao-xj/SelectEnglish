import Foundation

/// Expose only selection and scoped hierarchy operations to the extraction algorithm.
protocol SelectionAccess {
    associatedtype Node: Hashable
    associatedtype Marker
    func text(_ node: Node, attribute: String) -> String?
    func parent(_ node: Node) -> Node?
    func children(_ node: Node, limit: Int) -> [Node]
    func selectedRange(_ node: Node) -> NSRange?
    func string(_ node: Node, range: NSRange) -> String?
    func selectedMarker(_ node: Node) -> Marker?
    func length(_ node: Node, marker: Marker) -> Int?
    func string(_ node: Node, marker: Marker) -> String?
}

/// Extract actual selected text without reading document values or unrelated window siblings.
struct SelectionExtraction<Access: SelectionAccess> {
    let access: Access
    let now: () -> TimeInterval
    let canContinue: () -> Bool
    var maximumCalls = 256
    var maximumNodes = 80
    var maximumDepth = 8
    var maximumSeconds: TimeInterval = 1.5

    struct Result {
        let text: String
        let role: String
    }

    func read(focused: Access.Node) -> Result? {
        let deadline = now() + maximumSeconds
        var calls = 0
        func call<T>(_ operation: () -> T?) -> T? {
            guard calls < maximumCalls, now() < deadline, canContinue() else { return nil }
            calls += 1
            return operation()
        }
        func selected(_ node: Access.Node) -> String? {
            if let text = call({ access.text(node, attribute: "AXSelectedText") }), !text.isEmpty {
                return text.utf16.count <= 20_000 ? text : nil
            }
            if let range = call({ access.selectedRange(node) }), range.location != NSNotFound, range.location >= 0,
               range.length > 0, range.length <= 20_000, range.location <= Int.max - range.length,
               let text = call({ access.string(node, range: range) }), !text.isEmpty, text.utf16.count == range.length {
                return text
            }
            if let marker = call({ access.selectedMarker(node) }),
               let length = call({ access.length(node, marker: marker) }), length > 0, length <= 20_000,
               let text = call({ access.string(node, marker: marker) }), !text.isEmpty, text.utf16.count == length {
                return text
            }
            return nil
        }
        func result(_ text: String, node: Access.Node) -> Result {
            Result(text: text, role: call({ access.text(node, attribute: "AXRole") }) ?? "未知")
        }
        if let text = selected(focused) { return result(text, node: focused) }

        // Only a proven PDF root may open descendant traversal. Never search a whole window.
        var ancestor: Access.Node? = focused
        var ancestors = Set<Access.Node>()
        var pdfRoot: Access.Node?
        for _ in 0..<7 {
            guard let node = ancestor, ancestors.insert(node).inserted else { break }
            let role = call({ access.text(node, attribute: "AXRole") })
            if role == "AXWindow" || role == "AXApplication" { break }
            let subrole = call({ access.text(node, attribute: "AXSubrole") })
            let url = call({ access.text(node, attribute: "AXURL") }).flatMap(URL.init(string:))
            let chromePDF = url?.scheme == "chrome-extension" && url?.host == "mhjfbmdgcfjbbpaeojofohoefgiehjai"
            if subrole == "AXPDFDocument" || url?.pathExtension.lowercased() == "pdf" || chromePDF {
                pdfRoot = node
                break
            }
            ancestor = call({ access.parent(node) })
        }
        guard let pdfRoot else { return nil }
        var queue: [(Access.Node, Int)] = [(pdfRoot, 0)]
        var visited = Set<Access.Node>()
        var index = 0
        while index < queue.count, visited.count < maximumNodes, calls < maximumCalls, now() < deadline, canContinue() {
            let (node, depth) = queue[index]
            index += 1
            guard visited.insert(node).inserted else { continue }
            let role = call({ access.text(node, attribute: "AXRole") })
            if ["AXWindow", "AXApplication", "AXToolbar", "AXTextField", "AXTextArea", "AXComboBox",
                "AXSecureTextField", "AXButton", "AXPopUpButton", "AXSlider"].contains(role ?? "") { continue }
            if node != focused, let text = selected(node) { return result(text, node: node) }
            guard depth < maximumDepth else { continue }
            let remaining = maximumNodes - visited.count - (queue.count - index)
            guard remaining > 0 else { continue }
            let children = call({ access.children(node, limit: remaining) }) ?? []
            queue.append(contentsOf: children.prefix(remaining).map { ($0, depth + 1) })
        }
        return nil
    }
}
