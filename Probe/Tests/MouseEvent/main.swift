import AppKit

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

let frame = NSRect(x: -500, y: 200, width: 420, height: 250)
var state = PopupDismissalState()
state.beginCapture(generation: 1, startedAt: 100)
check(state.completeCapture(generation: 1), "capture completes before visible mouse checks")

// These recorded events need no window, event posting, or physical pointer movement.
for (point, expectedDismissal) in [(NSPoint(x: -400, y: 300), false),
                                    (NSPoint(x: 600, y: 300), true)] {
    let event = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [],
        timestamp: 101, windowNumber: 0, context: nil, eventNumber: 1, clickCount: 1, pressure: 0)!
    check(event.window == nil, "global event fixture has no window")
    let recordedPoint = PopupMouseEvent.screenPoint(for: event)
    check(recordedPoint == point, "queued mouse classification uses the recorded screen point")
    let shouldDismiss = state.shouldDismissMouseDown(timestamp: event.timestamp, popupVisible: true,
        pointInsidePopup: frame.contains(recordedPoint))
    check(shouldDismiss == expectedDismissal, "visible popup follows recorded inside/outside click")
}
print("Popup mouse events: recorded global positions and dismissal checks passed")
