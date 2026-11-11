import Foundation

final class FakeMenu: BrowserCopyMenuAccess {
    var nodes: [Int: [Int]] = [0: [1], 1: [2], 2: [3]]
    var identifiers: [Int: String] = [3: "copy:"]
    var commands: [Int: String] = [:]
    var masks: [Int: Int] = [:]
    var enabledItems: Set<Int> = [3]
    var pressed: [Int] = []
    var enabledHook: (() -> Void)?
    func children(_ node: Int, limit: Int) -> [Int] { Array((nodes[node] ?? []).prefix(limit)) }
    func identifier(_ node: Int) -> String? { identifiers[node] }
    func command(_ node: Int) -> String? { commands[node] }
    func modifiers(_ node: Int) -> Int? { masks[node] }
    func enabled(_ node: Int) -> Bool { enabledHook?(); return enabledItems.contains(node) }
    func press(_ node: Int) throws { pressed.append(node) }
}
func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
let date = Date(timeIntervalSince1970: 1)
let source = BrowserCopySource(pid: 12, launchDate: date, bundleID: "com.google.Chrome")
check(source.matches(pid: 12, launchDate: date, bundleID: "com.google.Chrome"), "same browser process accepted")
check(!source.matches(pid: 13, launchDate: date, bundleID: "com.google.Chrome"), "front app switch rejected")
check(!source.matches(pid: 12, launchDate: date.addingTimeInterval(1), bundleID: "com.google.Chrome"), "PID reuse rejected")
let other = BrowserCopySource(pid: 12, launchDate: date, bundleID: "example.editor")
check(!other.matches(pid: 12, launchDate: date, bundleID: "example.editor"), "non-browser never copied")
let menu = FakeMenu()
var current = true
let search = BrowserCopyMenuSearch(access: menu, isCurrent: { current }, now: { 0 })
let found = try search.find(in: 0)
try search.invoke(found)
check(menu.pressed == [3], "actual search and action use native Copy identifier")
menu.pressed = []
current = false
do { try search.invoke(found); fatalError("copied stale source") } catch is CancellationError {}
check(menu.pressed.isEmpty, "cancelled source has no copy side effect")
current = true
menu.enabledHook = { current = false }
do { try search.invoke(found); fatalError("copied source changed during enabled check") } catch is CancellationError {}
check(menu.pressed.isEmpty, "source rechecked immediately before action")
menu.enabledHook = nil
current = true
menu.identifiers = [:]
menu.commands[3] = "C"
menu.masks[3] = 0
let shortcut = try search.find(in: 0)
check(shortcut == 3, "standard Command-C accepted without localized title")
menu.masks[3] = 8
do { _ = try search.find(in: 0); fatalError("accepted non-Command shortcut") } catch {}
menu.masks[3] = 0
menu.enabledItems = []
do { _ = try search.find(in: 0); fatalError("accepted disabled Copy") } catch {}
let permit = BrowserCopyPermit()
permit.cancel()
let cancelled = BrowserCopyMenuSearch(access: menu, isCurrent: { permit.isValid }, now: { 0 })
do { _ = try cancelled.find(in: 0); fatalError("searched after cancellation") } catch is CancellationError {}
var clock: TimeInterval = 0
let expired = BrowserCopyMenuSearch(access: menu, isCurrent: { true }, now: { clock += 1; return clock })
do { _ = try expired.find(in: 0); fatalError("ignored deadline") } catch {}
menu.nodes = [0: [1], 1: [0]]
do { _ = try search.find(in: 0); fatalError("cycle produced Copy") } catch {}
print("Browser copy: source/identity/menu/cancel/race/deadline/cycle checks passed")
