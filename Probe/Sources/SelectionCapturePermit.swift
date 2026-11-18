import Foundation

/// Share one capture's cancellation across the serial AX and browser-copy workers.
/// Cancellation prevents later calls; it cannot interrupt an AX request already in flight.
final class SelectionCapturePermit: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isValid: Bool { lock.lock(); defer { lock.unlock() }; return !cancelled }
}
