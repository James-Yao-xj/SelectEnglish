import AppKit

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

/// Share cancellation with the serial copy worker without reading controller state off-main.
final class BrowserCopyPermit: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isValid: Bool { lock.lock(); defer { lock.unlock() }; return !cancelled }
}

/// Describe the only key events that this opt-in feature may create.
struct BrowserCopyKeyIntent: Equatable {
    let keyCode: CGKeyCode
    let keyDown: Bool
    let command: Bool
}

protocol BrowserCopyEventPoster {
    associatedtype Event
    func make(_ intent: BrowserCopyKeyIntent) -> Event?
    func post(_ event: Event, to pid: pid_t)
}

/// Send one Command-C pair to a fixed process, with mandatory key-up cleanup.
struct BrowserCopyShortcut<Poster: BrowserCopyEventPoster> {
    let poster: Poster
    let isCurrent: () -> Bool
    func perform(to pid: pid_t) throws {
        guard isCurrent() else { throw CancellationError() }
        guard let down = poster.make(BrowserCopyKeyIntent(keyCode: 8, keyDown: true, command: true)),
              let up = poster.make(BrowserCopyKeyIntent(keyCode: 8, keyDown: false, command: true)) else {
            throw AppError.message("无法创建浏览器复制快捷键事件。")
        }
        guard isCurrent() else { throw CancellationError() }
        poster.post(down, to: pid)
        // No cancellation branch may skip release of the original process after key-down.
        poster.post(up, to: pid)
        // The caller observes clipboard changeCount before it performs cancellation cleanup.
    }
}

private struct NativeBrowserCopyEventPoster: BrowserCopyEventPoster {
    func make(_ intent: BrowserCopyKeyIntent) -> CGEvent? {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: intent.keyCode, keyDown: intent.keyDown) else { return nil }
        event.flags = intent.command ? .maskCommand : []
        return event
    }
    func post(_ event: CGEvent, to pid: pid_t) {
        // Never use a system-wide event tap or activate a different application.
        event.postToPid(pid)
    }
}

/// Prepare an original-browser-only shortcut before the clipboard transaction starts.
// Immutable handle; posting stays on one shared serial queue.
final class BrowserCopyFallback: @unchecked Sendable {
    private static let queue = DispatchQueue(label: "com.selectenglish.browser-copy")
    private let source: BrowserCopySource
    private let permit: BrowserCopyPermit
    private init(source: BrowserCopySource, permit: BrowserCopyPermit) { self.source = source; self.permit = permit }

    @MainActor static func prepare(source: BrowserCopySource, permit: BrowserCopyPermit) async throws -> BrowserCopyFallback {
        let releaseDeadline = ProcessInfo.processInfo.systemUptime + 0.6
        while NSEvent.pressedMouseButtons & 1 != 0 {
            guard permit.isValid, source.isCurrent else { throw CancellationError() }
            guard ProcessInfo.processInfo.systemUptime < releaseDeadline else { throw AppError.message("请松开触控板后重新重按。") }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try Task.checkCancellation()
        guard permit.isValid, source.isCurrent else { throw CancellationError() }
        return BrowserCopyFallback(source: source, permit: permit)
    }

    func performCopy() async throws {
        try Task.checkCancellation()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Self.queue.async {
                do {
                    let shortcut = BrowserCopyShortcut(poster: NativeBrowserCopyEventPoster(), isCurrent: {
                        self.permit.isValid && self.source.isCurrent
                    })
                    try shortcut.perform(to: self.source.pid)
                    continuation.resume()
                } catch { continuation.resume(throwing: error) }
            }
        }
        // Do not throw after posting: the clipboard transaction must observe the copied version first.
    }
}
