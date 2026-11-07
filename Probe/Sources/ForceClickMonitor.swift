import AppKit

/// Observe the verified passive session stream. All callbacks run on the main run loop.
final class ForceClickMonitor {
    var onTrigger: ((NSRunningApplication) -> Void)?
    var onStatusChange: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var gate = GestureGate()
    private(set) var rawGestures = 0
    private(set) var pressureEvents = 0
    private(set) var stage2Events = 0
    private(set) var triggers = 0
    var isEnabled: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    /// Reinstall after a permission change. The tap never includes keyboard events.
    func start() {
        stop()
        let types = [CGEventType.leftMouseDown.rawValue, CGEventType.leftMouseUp.rawValue,
                     CGEventType.leftMouseDragged.rawValue,
                     UInt32(NSEvent.EventType.gesture.rawValue), UInt32(NSEvent.EventType.pressure.rawValue)]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .listenOnly, eventsOfInterest: mask, callback: { _, type, event, context in
                let owner = Unmanaged<ForceClickMonitor>.fromOpaque(context!).takeUnretainedValue()
                owner.receive(type: type, event: event)
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        if let tap, let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) {
            self.source = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        onStatusChange?()
    }

    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil
        tap = nil
        gate = GestureGate()
    }

    /// Fix the source app at stage 2. Never perform AX or network work in this callback.
    private func receive(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async { [weak self] in self?.onStatusChange?() }
            return
        }
        if type == .leftMouseUp { _ = gate.receive(stage: 0); return }
        if type.rawValue == UInt32(NSEvent.EventType.gesture.rawValue) { rawGestures += 1 }
        guard type.rawValue == UInt32(NSEvent.EventType.gesture.rawValue)
                || type.rawValue == UInt32(NSEvent.EventType.pressure.rawValue),
              let cocoa = NSEvent(cgEvent: event), cocoa.type == .pressure else { return }
        pressureEvents += 1
        if cocoa.stage == 2 { stage2Events += 1 }
        guard gate.receive(stage: cocoa.stage), let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        triggers += 1
        DispatchQueue.main.async { [weak self] in self?.onTrigger?(app) }
    }

    deinit { stop() }
}
