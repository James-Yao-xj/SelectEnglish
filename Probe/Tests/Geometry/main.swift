import Foundation
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}
let primary = CGRect(x: 0, y: 24, width: 1440, height: 850)
let left = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
let screens = [primary, left]
for point in [CGPoint(x: 0, y: 24), CGPoint(x: 1439, y: 873), CGPoint(x: 1430, y: 30), CGPoint(x: -1919, y: 1), CGPoint(x: -10, y: 1079)] {
    let frame = PopupGeometry.frame(anchor: point, visibleFrames: screens, contentHeight: 900)
    let screen = point.x < 0 ? left : primary
    check(screen.insetBy(dx: 12, dy: 12).contains(frame), "edge popup must fit the anchor's monitor")
    check(frame.width == 420 && frame.height <= 520, "compact maximum dimensions")
}
let anchor = CGPoint(x: 500, y: 700)
let compact = PopupGeometry.frame(anchor: anchor, visibleFrames: screens, contentHeight: 190)
let expanded = PopupGeometry.frame(anchor: anchor, visibleFrames: screens, contentHeight: 510)
check(compact.maxY == expanded.maxY && compact.minX == expanded.minX, "updates below pointer keep the same anchor edges")
let tiny = CGRect(x: 100, y: 100, width: 300, height: 240)
let tinyFrame = PopupGeometry.frame(anchor: CGPoint(x: 350, y: 200), visibleFrames: [tiny], contentHeight: 520)
check(tiny.insetBy(dx: 12, dy: 12).contains(tinyFrame), "small monitor bounds")
let outside = PopupGeometry.frame(anchor: CGPoint(x: -2500, y: 500), visibleFrames: screens, contentHeight: 200)
check(left.contains(outside), "nearest negative-origin monitor for an off-screen anchor")
let above = CGRect(x: 0, y: 900, width: 1440, height: 850)
let stripFrame = PopupGeometry.frame(anchor: CGPoint(x: 600, y: 890), visibleFrames: [primary, above], contentHeight: 200,
    screenFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900), CGRect(x: 0, y: 900, width: 1440, height: 900)])
check(primary.contains(stripFrame), "menu-bar strip uses containing full screen rather than nearer adjacent visible area")
print("Popup geometry: edge, monitor, menu-strip, and stable-anchor checks passed")
