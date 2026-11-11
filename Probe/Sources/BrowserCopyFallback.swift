import AppKit
import ApplicationServices

/// Bind every fallback action to the original supported browser process.
struct BrowserCopySource: Sendable {
    let pid: pid_t
    let launchDate: Date?
    let bundleID: String
    static let supportedBrowsers: Set<String> = ["com.google.Chrome", "com.apple.Safari", "org.chromium.Chromium", "com.microsoft.edgemac", "com.brave.Browser", "org.mozilla.firefox"]
    func matches(pid: pid_t?, launchDate: Date?, bundleID: String?) -> Bool {
        Self.supportedBrowsers.contains(self.bundleID) && self.pid == pid && self.launchDate == launchDate && self.bundleID == bundleID
    }
    var isCurrent: Bool {
        guard let app = NSWorkspace.shared.frontmostApplication, !app.isTerminated else { return false }
        return matches(pid: app.processIdentifier, launchDate: app.launchDate, bundleID: app.bundleIdentifier)
    }
}

/// Share cancellation with the serial AX worker without reading controller state off-main.
final class BrowserCopyPermit: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isValid: Bool { lock.lock(); defer { lock.unlock() }; return !cancelled }
}

protocol BrowserCopyMenuAccess {
    associatedtype Node: Hashable
    func children(_ node: Node, limit: Int) -> [Node]
    func identifier(_ node: Node) -> String?
    func command(_ node: Node) -> String?
    func modifiers(_ node: Node) -> Int?
    func enabled(_ node: Node) -> Bool
    func press(_ node: Node) throws
}

/// Find the native Copy action without relying on a localized menu title or injecting keys.
struct BrowserCopyMenuSearch<Access: BrowserCopyMenuAccess> {
    let access: Access
    let isCurrent: () -> Bool
    let now: () -> TimeInterval
    func find(in root: Access.Node) throws -> Access.Node {
        let deadline = now() + 1
        var calls = 0
        func call<T>(_ operation: () -> T) throws -> T {
            guard isCurrent() else { throw CancellationError() }
            guard calls < 256, now() < deadline else { throw AppError.message("浏览器复制菜单查找超时。") }
            calls += 1
            return operation()
        }
        var queue: [(Access.Node, Int)] = [(root, 0)]
        var seen = Set<Access.Node>()
        var index = 0
        while index < queue.count, seen.count < 128 {
            let (node, depth) = queue[index]; index += 1
            guard seen.insert(node).inserted else { continue }
            let identifier = try call { access.identifier(node) }
            // Zero modifiers mean Command alone in the AX menu API.
            let copyShortcut = identifier == "copy:" ? true : try call { access.command(node)?.lowercased() == "c" }
                && call { access.modifiers(node) == 0 }
            if copyShortcut, try call({ access.enabled(node) }) { return node }
            if depth < 3 && queue.count < 128 {
                let children = try call { access.children(node, limit: 128 - queue.count) }
                queue.append(contentsOf: children.map { ($0, depth + 1) })
            }
        }
        throw AppError.message("浏览器未提供可用的原生复制命令。请先选中文字。")
    }
    func invoke(_ node: Access.Node) throws {
        guard isCurrent(), access.enabled(node), isCurrent() else { throw CancellationError() }
        try access.press(node)
    }
}

/// Prepare a bounded browser-specific Copy action before the clipboard transaction starts.
// Immutable prepared handle; all native AX access stays on the shared serial queue.
final class BrowserCopyFallback: @unchecked Sendable {
    private static let queue = DispatchQueue(label: "com.selectenglish.browser-copy")
    private let source: BrowserCopySource
    private let permit: BrowserCopyPermit
    private let access: NativeCopyMenuAccess
    private let item: NativeCopyMenuAccess.Node
    private init(source: BrowserCopySource, permit: BrowserCopyPermit, access: NativeCopyMenuAccess, item: NativeCopyMenuAccess.Node) {
        self.source = source; self.permit = permit; self.access = access; self.item = item
    }
    @MainActor static func prepare(source: BrowserCopySource, permit: BrowserCopyPermit) async throws -> BrowserCopyFallback {
        let releaseDeadline = ProcessInfo.processInfo.systemUptime + 0.6
        while NSEvent.pressedMouseButtons & 1 != 0 {
            guard permit.isValid, source.isCurrent else { throw CancellationError() }
            guard ProcessInfo.processInfo.systemUptime < releaseDeadline else { throw AppError.message("请松开触控板后重新重按。") }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let access = NativeCopyMenuAccess(source: source, permit: permit)
                    guard let root = access.menuBar() else { throw AppError.message("无法读取浏览器的原生菜单。") }
                    let search = BrowserCopyMenuSearch(access: access, isCurrent: { permit.isValid && source.isCurrent }, now: { ProcessInfo.processInfo.systemUptime })
                    let item = try search.find(in: root)
                    continuation.resume(returning: BrowserCopyFallback(source: source, permit: permit, access: access, item: item))
                } catch { continuation.resume(throwing: error) }
            }
        }
    }
    func performCopy() async throws {
        try Task.checkCancellation()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Self.queue.async {
                do {
                    let search = BrowserCopyMenuSearch(access: self.access, isCurrent: { self.permit.isValid && self.source.isCurrent }, now: { ProcessInfo.processInfo.systemUptime })
                    try search.invoke(self.item)
                    continuation.resume()
                } catch { continuation.resume(throwing: error) }
            }
        }
        // Let the transaction observe the command's clipboard version before cancellation cleanup.
    }
}

private final class NativeCopyMenuAccess: BrowserCopyMenuAccess {
    struct Node: Hashable {
        let element: AXUIElement
        static func == (lhs: Node, rhs: Node) -> Bool { CFEqual(lhs.element, rhs.element) }
        func hash(into hasher: inout Hasher) { hasher.combine(CFHash(element)) }
    }
    private let source: BrowserCopySource
    private let permit: BrowserCopyPermit
    init(source: BrowserCopySource, permit: BrowserCopyPermit) { self.source = source; self.permit = permit }
    private func prepare(_ node: Node) -> Bool {
        guard permit.isValid, source.isCurrent else { return false }
        AXUIElementSetMessagingTimeout(node.element, 0.08)
        return true
    }
    private func value(_ node: Node, _ attribute: String) -> CFTypeRef? {
        guard prepare(node) else { return nil }
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(node.element, attribute as CFString, &result) == .success else { return nil }
        return result
    }
    func menuBar() -> Node? {
        let app = Node(element: AXUIElementCreateApplication(source.pid))
        guard let result = value(app, "AXMenuBar"), CFGetTypeID(result) == AXUIElementGetTypeID() else { return nil }
        return Node(element: unsafeBitCast(result, to: AXUIElement.self))
    }
    func identifier(_ node: Node) -> String? { value(node, "AXIdentifier") as? String }
    func command(_ node: Node) -> String? { value(node, "AXMenuItemCmdChar") as? String }
    func modifiers(_ node: Node) -> Int? { (value(node, "AXMenuItemCmdModifiers") as? NSNumber)?.intValue }
    func enabled(_ node: Node) -> Bool { (value(node, "AXEnabled") as? NSNumber)?.boolValue == true }
    func children(_ node: Node, limit: Int) -> [Node] {
        guard limit > 0, prepare(node) else { return [] }
        var values: CFArray?
        guard AXUIElementCopyAttributeValues(node.element, kAXChildrenAttribute as CFString, 0, limit, &values) == .success, let values else { return [] }
        return (values as [AnyObject]).compactMap {
            guard CFGetTypeID($0) == AXUIElementGetTypeID() else { return nil }
            return Node(element: unsafeBitCast($0, to: AXUIElement.self))
        }
    }
    func press(_ node: Node) throws {
        guard prepare(node), permit.isValid, source.isCurrent else { throw CancellationError() }
        let error = AXUIElementPerformAction(node.element, kAXPressAction as CFString)
        guard error == .success else { throw AppError.message("浏览器复制命令未完成（AX \(error.rawValue)）。") }
    }
}
