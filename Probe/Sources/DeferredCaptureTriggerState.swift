import Foundation

/// Keep a queued pressure trigger separate from a capture that has already started.
struct DeferredCaptureTriggerState {
    struct Token: Equatable {
        fileprivate let sequence: Int
        /// Source event uptime in seconds, used as the initiating-click cutoff.
        let timestamp: TimeInterval
    }

    private var sequence = 0
    private var pending: Token?
    /// Retain input seen before a delayed pressure callback reaches this state.
    private var latestMouseDown: TimeInterval?
    /// Reject source events that arrive after the action which cancelled them.
    private var cancelledThrough: TimeInterval?

    /// Queue a source event unless a newer mouse-down has already been observed.
    mutating func schedule(timestamp: TimeInterval) -> Token? {
        guard latestMouseDown.map({ $0 <= timestamp }) ?? true else { return nil }
        guard cancelledThrough.map({ $0 < timestamp }) ?? true else { return nil }
        sequence += 1
        let token = Token(sequence: sequence, timestamp: timestamp)
        pending = token
        return token
    }

    /// Cancel only a trigger older than this click. Late initiating clicks are harmless.
    mutating func observeMouseDown(timestamp: TimeInterval) {
        latestMouseDown = max(latestMouseDown ?? timestamp, timestamp)
        if let pending, timestamp > pending.timestamp { self.pending = nil }
    }

    /// Take a queued trigger once. Cancellation or a newer trigger makes it unavailable.
    mutating func take(_ token: Token) -> TimeInterval? {
        guard pending == token else { return nil }
        pending = nil
        return token.timestamp
    }

    /// Cancel queued work and source events at or before this uptime, in seconds.
    mutating func cancel(through timestamp: TimeInterval) {
        pending = nil
        cancelledThrough = max(cancelledThrough ?? timestamp, timestamp)
    }
}
