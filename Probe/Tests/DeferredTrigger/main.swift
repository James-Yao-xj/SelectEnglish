import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

var trigger = DeferredCaptureTriggerState()
let cancelledByClick = trigger.schedule(timestamp: 100)!
trigger.observeMouseDown(timestamp: 102)
check(trigger.take(cancelledByClick) == nil, "a click before handoff prevents a new capture")
check(trigger.schedule(timestamp: 101) == nil, "input seen before a delayed pressure callback prevents capture")

let delayedInitiatingClick = trigger.schedule(timestamp: 200)!
trigger.observeMouseDown(timestamp: 190)
let originalTimestamp = trigger.take(delayedInitiatingClick)!
check(originalTimestamp == 200, "the original event time survives a delayed handoff")
check(trigger.take(delayedInitiatingClick) == nil, "a queued trigger is consumed only once")

// A click delivered after handoff must use the same source cutoff, not callback time 205.
var dismissal = PopupDismissalState()
dismissal.beginCapture(generation: 1, startedAt: originalTimestamp)
check(dismissal.shouldDismissMouseDown(timestamp: 202, popupVisible: false, pointInsidePopup: false),
      "a later click cancels capture even if callback delivery was delayed")
check(!dismissal.shouldDismissMouseDown(timestamp: 190, popupVisible: false, pointInsidePopup: false),
      "the delayed initiating mouse-down cannot cancel its own capture")

let explicitCancel = trigger.schedule(timestamp: 300)!
trigger.cancel(through: 305)
check(trigger.take(explicitCancel) == nil, "explicit cancellation or listener stop prevents resurrection")
check(trigger.schedule(timestamp: 304) == nil, "a source event delivered after cancellation cannot resurrect capture")
check(trigger.schedule(timestamp: 305) == nil, "an event at the cancellation cutoff stays cancelled")
let older = trigger.schedule(timestamp: 400)!
let newer = trigger.schedule(timestamp: 401)!
check(trigger.take(older) == nil && trigger.take(newer) == 401, "only the newest pressure handoff runs")
print("Deferred trigger: event time, click ordering, cancellation and supersession checks passed")
