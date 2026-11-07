import AppKit

/// Hold numeric metadata for one bounded passive event-stream experiment.
final class TapStatistics {
    var rawEvents = 0
    var mouseEvents = 0
    var gestureEvents = 0
    var rawPressureEvents = 0
    var convertedPressureEvents = 0
    var stageCounts: [Int: Int] = [:]
    var triggers = 0
    var disabledEvents = 0
    var maximumMousePressure = 0.0
    var gate = GestureGate()

    /// Report aggregate counters only. No text or key fields are read.
    func report() {
        let stages = stageCounts.keys.sorted().map { "\($0):\(stageCounts[$0]!)" }.joined(separator: ",")
        print("events=\(rawEvents) mouse=\(mouseEvents) rawGesture=\(gestureEvents) rawPressure=\(rawPressureEvents) convertedPressure=\(convertedPressureEvents) stages=[\(stages)] stage2Triggers=\(triggers) disabled=\(disabledEvents) maxMousePressure=\(maximumMousePressure)")
        fflush(stdout)
    }
}

let statistics = TapStatistics()
let seconds = min(120, max(1, CommandLine.arguments.count > 1 ? (Double(CommandLine.arguments[1]) ?? 120) : 120))
// CGEventType has no named pressure case. These AppKit mask values are an experiment.
let gestureType = UInt32(NSEvent.EventType.gesture.rawValue)
let pressureType = UInt32(NSEvent.EventType.pressure.rawValue)
let watchedTypes = [CGEventType.leftMouseDown.rawValue, CGEventType.leftMouseUp.rawValue,
                    CGEventType.leftMouseDragged.rawValue, gestureType, pressureType]
let mask = watchedTypes.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }

let callback: CGEventTapCallBack = { _, type, event, context in
    let stats = Unmanaged<TapStatistics>.fromOpaque(context!).takeUnretainedValue()
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        stats.disabledEvents += 1
        return Unmanaged.passUnretained(event)
    }
    stats.rawEvents += 1
    let rawType = type.rawValue
    if type == .leftMouseDown || type == .leftMouseUp || type == .leftMouseDragged {
        stats.mouseEvents += 1
        stats.maximumMousePressure = max(stats.maximumMousePressure, event.getDoubleValueField(.mouseEventPressure))
        if type == .leftMouseUp { _ = stats.gate.receive(stage: 0) }
    }
    if rawType == UInt32(NSEvent.EventType.gesture.rawValue) { stats.gestureEvents += 1 }
    if rawType == UInt32(NSEvent.EventType.pressure.rawValue) { stats.rawPressureEvents += 1 }
    // Raw gesture wrappers can convert to AppKit pressure events. Do not inspect keys.
    if rawType == UInt32(NSEvent.EventType.gesture.rawValue) || rawType == UInt32(NSEvent.EventType.pressure.rawValue),
       let cocoaEvent = NSEvent(cgEvent: event), cocoaEvent.type == .pressure {
        stats.convertedPressureEvents += 1
        stats.stageCounts[cocoaEvent.stage, default: 0] += 1
        if stats.gate.receive(stage: cocoaEvent.stage) { stats.triggers += 1 }
    }
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                  options: .listenOnly, eventsOfInterest: mask, callback: callback,
                                  userInfo: Unmanaged.passUnretained(statistics).toOpaque()) else {
    print("TAP_CREATE_FAILED: permissions or event mask unavailable; no hardware conclusion.")
    exit(2)
}
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
print("TAP_READY duration=\(Int(seconds))s listenOnly=true keyboard=false maskTypes=\(watchedTypes)")
fflush(stdout)
let timer = Timer(timeInterval: 5, repeats: true) { _ in statistics.report() }
RunLoop.current.add(timer, forMode: .common)
CFRunLoopRunInMode(.defaultMode, seconds, false)
timer.invalidate()
CGEvent.tapEnable(tap: tap, enable: false)
CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
CFMachPortInvalidate(tap)
print("TAP_FINISHED")
statistics.report()
