import Foundation

func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
let launch = Date(timeIntervalSince1970: 10)
let source = SelectionCommandIdentity(pid: 42, launchDate: launch)
check(source.matches(pid: 42, launchDate: launch), "same source remains eligible")
check(!source.matches(pid: 43, launchDate: launch), "foreground process switch rejects command")
check(!source.matches(pid: 42, launchDate: launch.addingTimeInterval(1)), "PID reuse rejects command")
let window = SelectionWindowIdentity(captured: "PDF window A")
check(window.matches(current: "PDF window A"), "original focused window accepted")
check(!window.matches(current: "window B"), "another window cannot provide copy result")
check(!window.matches(current: nil), "lost captured window fails closed")
check(SelectionWindowIdentity<String>(captured: nil).matches(current: nil), "unsupported window attribute makes no window claim")
// Use the same action router as finishCapture. The fake action represents cache/HTTP entry.
var analysisEntries = 0
SelectionTextOrigin.clipboard.analyzeAutomaticallyIfAllowed(requested: true) { analysisEntries += 1 }
check(analysisEntries == 0, "clipboard preview never enters automatic cache or HTTP analysis")
SelectionTextOrigin.scopedAccessibility.analyzeAutomaticallyIfAllowed(requested: true) { analysisEntries += 1 }
check(analysisEntries == 0, "scoped PDF fragments never enter automatic cache or HTTP analysis")
check(SelectionTextOrigin.scopedAccessibility.requiresConfirmation, "scoped PDF text requires Analyze action")
check(SelectionTextOrigin.clipboard.requiresConfirmation, "copied text requires Analyze action")
check(!SelectionTextOrigin.accessibility.requiresConfirmation, "focused AX result keeps automatic behavior")
SelectionTextOrigin.accessibility.analyzeAutomaticallyIfAllowed(requested: false) { analysisEntries += 1 }
check(analysisEntries == 0, "manual AX diagnostics remain offline")
SelectionTextOrigin.accessibility.analyzeAutomaticallyIfAllowed(requested: true) { analysisEntries += 1 }
check(analysisEntries == 1, "authoritative requested AX snapshot enters analysis once")
print("Selection command source, window and preview action-routing checks passed")
