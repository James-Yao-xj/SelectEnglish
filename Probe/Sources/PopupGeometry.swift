import Foundation
import CoreGraphics

/// Place a compact popup near an anchor in global AppKit screen coordinates.
enum PopupGeometry {
    /// Use the anchor's screen, including negative-origin monitors, and stay in its visible area.
    static func frame(anchor: CGPoint, visibleFrames: [CGRect], contentHeight: CGFloat, screenFrames: [CGRect]? = nil) -> CGRect {
        let containing = zip(screenFrames ?? visibleFrames, visibleFrames).first(where: { $0.0.contains(anchor) })?.1
        guard let screen = containing ?? visibleFrames.min(by: {
            distance(anchor, to: $0) < distance(anchor, to: $1)
        }) else { return CGRect(x: anchor.x, y: anchor.y, width: 420, height: min(520, max(160, contentHeight))) }
        let margin = min(12, min(screen.width, screen.height) / 4)
        let available = screen.insetBy(dx: margin, dy: margin)
        let size = CGSize(width: min(420, available.width), height: min(520, min(max(160, contentHeight), available.height)))
        let below = anchor.y - 12 - size.height
        let proposedY = below >= available.minY ? below : anchor.y + 12
        return CGRect(x: min(max(anchor.x + 12, available.minX), available.maxX - size.width),
                      y: min(max(proposedY, available.minY), available.maxY - size.height),
                      width: size.width, height: size.height)
    }

    private static func distance(_ point: CGPoint, to frame: CGRect) -> CGFloat {
        let dx = max(frame.minX - point.x, max(0, point.x - frame.maxX))
        let dy = max(frame.minY - point.y, max(0, point.y - frame.maxY))
        return dx * dx + dy * dy
    }
}
