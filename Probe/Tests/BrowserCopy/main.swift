import Foundation

final class FakePoster: BrowserCopyEventPoster {
    var created: [BrowserCopyKeyIntent] = []
    var posted: [(pid_t, BrowserCopyKeyIntent)] = []
    var failKeyUpCreation = false
    var creationHook: (() -> Void)?
    var postHook: (() -> Void)?
    func make(_ intent: BrowserCopyKeyIntent) -> BrowserCopyKeyIntent? {
        created.append(intent)
        creationHook?()
        return !intent.keyDown && failKeyUpCreation ? nil : intent
    }
    func post(_ event: BrowserCopyKeyIntent, to pid: pid_t) { posted.append((pid, event)); postHook?() }
}
func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
let date = Date(timeIntervalSince1970: 1)
let source = BrowserCopySource(pid: 12, launchDate: date, bundleID: "com.google.Chrome")
check(source.matches(pid: 12, launchDate: date, bundleID: "com.google.Chrome"), "same browser accepted")
check(!source.matches(pid: 13, launchDate: date, bundleID: "com.google.Chrome"), "foreground process switch rejected")
check(!source.matches(pid: 12, launchDate: date.addingTimeInterval(1), bundleID: "com.google.Chrome"), "PID reuse rejected")
let editor = BrowserCopySource(pid: 12, launchDate: date, bundleID: "example.editor")
check(!editor.matches(pid: 12, launchDate: date, bundleID: "example.editor"), "unknown app never copied")
var current = true
let poster = FakePoster()
let shortcut = BrowserCopyShortcut(poster: poster, isCurrent: { current })
try shortcut.perform(to: 12)
check(poster.posted.count == 2 && poster.posted.allSatisfy { $0.0 == 12 }, "both events target original PID only")
check(poster.posted.map(\.1) == [BrowserCopyKeyIntent(keyCode: 8, keyDown: true, command: true), BrowserCopyKeyIntent(keyCode: 8, keyDown: false, command: true)], "exact C down/up with Command intent")
poster.posted = []
poster.created = []
current = false
do { try shortcut.perform(to: 12); fatalError("posted stale source") } catch is CancellationError {}
check(poster.created.isEmpty && poster.posted.isEmpty, "cancel before start creates/posts nothing")
current = true
poster.creationHook = { current = false }
do { try shortcut.perform(to: 12); fatalError("posted after source changed during preparation") } catch is CancellationError {}
check(poster.posted.isEmpty, "source checked again immediately before key-down")
poster.creationHook = nil
current = true
poster.failKeyUpCreation = true
do { try shortcut.perform(to: 12); fatalError("posted without releasable key") } catch {}
check(poster.posted.isEmpty, "creation failure does not leave a key down")
poster.failKeyUpCreation = false
let permit = BrowserCopyPermit()
poster.postHook = { current = false; permit.cancel() }
let cancellable = BrowserCopyShortcut(poster: poster, isCurrent: { current && permit.isValid })
try cancellable.perform(to: 12)
check(poster.posted.count == 2 && poster.posted.last?.0 == 12 && poster.posted.last?.1.keyDown == false, "cancellation after down still releases original PID")
print("Browser copy: targeted Command-C intent/source/cancel/creation/cleanup checks passed (fake poster only)")
