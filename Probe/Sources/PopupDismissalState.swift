import Foundation

/// Track a pending AX capture separately from the visibility of its result popup.
struct PopupDismissalState {
    private var pendingGeneration: Int?
    /// Retain the cutoff after AX completes or AI starts; the initiating click can arrive late.
    private var ignoreMouseDownThrough: TimeInterval?
    var hasPendingCapture: Bool { pendingGeneration != nil }

    mutating func beginCapture(generation: Int, startedAt: TimeInterval) {
        pendingGeneration = generation
        ignoreMouseDownThrough = startedAt
    }

    /// Clear only this capture. An old completion must not clear a newer capture.
    mutating func completeCapture(generation: Int) -> Bool {
        guard pendingGeneration == generation else { return false }
        pendingGeneration = nil
        return true
    }

    mutating func invalidateCapture() { pendingGeneration = nil }

    /// Use event uptime, not callback delivery time, to ignore the initiating mouse-down.
    func shouldDismissMouseDown(timestamp: TimeInterval, popupVisible: Bool, pointInsidePopup: Bool) -> Bool {
        if let ignoreMouseDownThrough, timestamp <= ignoreMouseDownThrough { return false }
        if popupVisible { return !pointInsidePopup }
        return pendingGeneration != nil
    }
}
