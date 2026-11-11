import AppKit
import ApplicationServices

/// Return selection text and diagnostic metadata without changing application focus.
enum SelectionReader {
    struct Result {
        let role: String
        let text: String
        let message: String
    }

    /// Read only the original process through bounded public selection APIs.
    static func read(pid: pid_t, launchDate: Date?) -> Result {
        guard let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated,
              app.launchDate == launchDate else { return Result(role: "未知", text: "", message: "触发时的目标应用已退出或进程已改变。") }
        guard AXIsProcessTrusted() else { return Result(role: "未知", text: "", message: "当前进程未获得辅助功能授权；请授权后重试。") }
        let access = NativeSelectionAccess()
        let application = NativeSelectionAccess.Node(element: AXUIElementCreateApplication(pid))
        guard let focused = access.element(application, attribute: "AXFocusedUIElement") else {
            return Result(role: "未知", text: "", message: "无法获取目标应用的焦点元素。" + access.failureDescription)
        }
        let extractor = SelectionExtraction(access: access, now: { ProcessInfo.processInfo.systemUptime }, canContinue: {
            !app.isTerminated && NSRunningApplication(processIdentifier: pid)?.launchDate == launchDate
        })
        guard let result = extractor.read(focused: focused), !app.isTerminated else {
            return Result(role: access.text(focused, attribute: "AXRole") ?? "未知", text: "", message: "没有读取到有效选区；目标 PDF 可能未通过辅助功能暴露选中文字。" + access.failureDescription)
        }
        return Result(role: result.role, text: result.text, message: "已读取 \(result.text.count) 个字符，请核对是否为完整选区。")
    }
}

/// Translate the extraction protocol to public AX calls with short per-call timeouts.
private final class NativeSelectionAccess: SelectionAccess {
    struct Node: Hashable {
        let element: AXUIElement
        static func == (lhs: Node, rhs: Node) -> Bool { CFEqual(lhs.element, rhs.element) }
        func hash(into hasher: inout Hasher) { hasher.combine(CFHash(element)) }
    }
    typealias Marker = CFTypeRef
    private let deadline = ProcessInfo.processInfo.systemUptime + 1.5
    private var substantiveError: AXError?
    var failureDescription: String {
        if let error = substantiveError {
            let label: String
            switch error {
            case .apiDisabled: label = "辅助功能 API 未启用"
            case .cannotComplete: label = "目标应用未能完成请求"
            case .invalidUIElement: label = "焦点元素已失效"
            default: label = "辅助功能请求失败"
            }
            return " \(label)（AX \(error.rawValue)）。"
        }
        return ProcessInfo.processInfo.systemUptime >= deadline ? " 已达到读取时限。" : ""
    }

    private func succeeded(_ error: AXError) -> Bool {
        if error != .success && error != .noValue && error != .attributeUnsupported
            && error != .parameterizedAttributeUnsupported && error != .notImplemented && substantiveError == nil {
            substantiveError = error
        }
        return error == .success
    }

    /// Share the total deadline across focus discovery, extraction, and diagnostic metadata.
    private func prepare(_ node: Node) -> Bool {
        let remaining = deadline - ProcessInfo.processInfo.systemUptime
        guard remaining > 0 else { return false }
        AXUIElementSetMessagingTimeout(node.element, Float(min(0.08, remaining)))
        return true
    }

    private func attribute(_ node: Node, _ name: String) -> CFTypeRef? {
        guard prepare(node) else { return nil }
        var value: CFTypeRef?
        guard succeeded(AXUIElementCopyAttributeValue(node.element, name as CFString, &value)) else { return nil }
        return value
    }

    private func parameter(_ node: Node, _ name: String, _ input: CFTypeRef) -> CFTypeRef? {
        guard prepare(node) else { return nil }
        var value: CFTypeRef?
        guard succeeded(AXUIElementCopyParameterizedAttributeValue(node.element, name as CFString, input, &value)) else { return nil }
        return value
    }

    func text(_ node: Node, attribute name: String) -> String? {
        let value = attribute(node, name)
        if let url = value as? URL { return url.absoluteString }
        return value as? String
    }

    func element(_ node: Node, attribute name: String) -> Node? {
        guard let value = attribute(node, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return Node(element: unsafeBitCast(value, to: AXUIElement.self))
    }

    func parent(_ node: Node) -> Node? { element(node, attribute: "AXParent") }

    func children(_ node: Node, limit: Int) -> [Node] {
        guard prepare(node) else { return [] }
        var values: CFArray?
        guard succeeded(AXUIElementCopyAttributeValues(node.element, kAXChildrenAttribute as CFString, 0, limit, &values)),
              let values else { return [] }
        return (values as [AnyObject]).compactMap {
            guard CFGetTypeID($0) == AXUIElementGetTypeID() else { return nil }
            return Node(element: unsafeBitCast($0, to: AXUIElement.self))
        }
    }

    func selectedRange(_ node: Node) -> NSRange? {
        guard let value = attribute(node, "AXSelectedTextRange"), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cfRange else { return nil }
        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range), range.location >= 0, range.length >= 0 else { return nil }
        return NSRange(location: range.location, length: range.length)
    }

    func string(_ node: Node, range: NSRange) -> String? {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let value = AXValueCreate(.cfRange, &cfRange) else { return nil }
        return parameter(node, "AXStringForRange", value) as? String
    }

    func selectedMarker(_ node: Node) -> CFTypeRef? {
        guard let marker = attribute(node, "AXSelectedTextMarkerRange"), CFGetTypeID(marker) == AXTextMarkerRangeGetTypeID() else { return nil }
        return marker
    }

    func length(_ node: Node, marker: CFTypeRef) -> Int? {
        (parameter(node, "AXLengthForTextMarkerRange", marker) as? NSNumber)?.intValue
    }

    func string(_ node: Node, marker: CFTypeRef) -> String? {
        parameter(node, "AXStringForTextMarkerRange", marker) as? String
    }
}
