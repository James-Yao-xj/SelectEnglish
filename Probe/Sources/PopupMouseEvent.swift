import AppKit

/// Convert recorded mouse events without reading the current pointer position.
enum PopupMouseEvent {
    /// Return the event position in AppKit screen coordinates.
    static func screenPoint(for event: NSEvent) -> NSPoint {
        // Global monitor events have no local window and already use screen coordinates.
        event.window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
    }
}
