import Foundation

final class FakeAccess: SelectionAccess {
    typealias Node = Int
    typealias Marker = Int
    var texts: [Int: [String: String]] = [:]
    var parents: [Int: Int] = [:]
    var descendants: [Int: [Int]] = [:]
    var ranges: [Int: NSRange] = [:]
    var markers: [Int: Int] = [:]
    var lengths: [Int: Int] = [:]
    var rangeStrings: [Int: String] = [:]
    var markerStrings: [Int: String] = [:]
    var calls: [String] = []
    func text(_ node: Int, attribute: String) -> String? { calls.append("\(node):\(attribute)"); return texts[node]?[attribute] }
    func parent(_ node: Int) -> Int? { calls.append("\(node):parent"); return parents[node] }
    func children(_ node: Int, limit: Int) -> [Int] { calls.append("\(node):children"); return Array((descendants[node] ?? []).prefix(limit)) }
    func selectedRange(_ node: Int) -> NSRange? { calls.append("\(node):range"); return ranges[node] }
    func string(_ node: Int, range: NSRange) -> String? { calls.append("\(node):rangeString"); return rangeStrings[node] }
    func selectedMarker(_ node: Int) -> Int? { calls.append("\(node):marker"); return markers[node] }
    func length(_ node: Int, marker: Int) -> Int? { calls.append("\(node):markerLength"); return lengths[marker] }
    func string(_ node: Int, marker: Int) -> String? { calls.append("\(node):markerString"); return markerStrings[marker] }
}
func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
func read(_ access: FakeAccess) -> SelectionExtraction<FakeAccess>.Result? {
    SelectionExtraction(access: access, now: { 0 }, canContinue: { true }).read(focused: 1)
}
let direct = FakeAccess()
direct.texts[1] = ["AXSelectedText": "Selected", "AXRole": "AXTextArea"]
check(read(direct)?.text == "Selected", "focused text still works")
check(!direct.calls.contains("1:children"), "no traversal after direct success")
let ranged = FakeAccess()
ranged.ranges[1] = NSRange(location: 9, length: 4)
ranged.rangeStrings[1] = "Only"
check(read(ranged)?.text == "Only", "same element selected range conversion")
ranged.rangeStrings[1] = "Whole document instead"
check(read(ranged) == nil, "range conversion cannot return beyond selected length")
ranged.rangeStrings[1] = "Only"
ranged.ranges[1] = NSRange(location: 9, length: 0)
ranged.calls = []
check(read(ranged) == nil && !ranged.calls.contains("1:rangeString"), "empty caret never reads document range")
ranged.ranges[1] = NSRange(location: -2, length: 4)
ranged.calls = []
check(read(ranged) == nil && !ranged.calls.contains("1:rangeString"), "negative ranges never parameterized")
ranged.ranges[1] = NSRange(location: 0, length: 20_001)
ranged.calls = []
check(read(ranged) == nil && !ranged.calls.contains("1:rangeString"), "oversized ranges never requested")
let marker = FakeAccess()
marker.markers[1] = 10
marker.lengths[10] = 5
marker.markerStrings[10] = "Hello"
check(read(marker)?.text == "Hello", "selected marker range conversion")
marker.markerStrings[10] = "Wrong longer text"
check(read(marker) == nil, "marker conversion cannot return beyond selected length")
marker.markerStrings[10] = "Hello"
marker.lengths[10] = 0
marker.calls = []
check(read(marker) == nil && !marker.calls.contains("1:markerString"), "empty marker range not read")
let pdf = FakeAccess()
pdf.texts[1] = ["AXURL": "chrome-extension://mhjfbmdgcfjbbpaeojofohoefgiehjai/index.html"]
pdf.descendants = [1: [2], 2: [3], 3: [1]]
pdf.texts[3] = ["AXSelectedText": "PDF selection"]
check(read(pdf)?.text == "PDF selection", "focused PDF iframe descendants reached")
let unrelated = FakeAccess()
unrelated.texts[1] = ["AXURL": "https://example.org/page"]
unrelated.descendants = [1: [2]]
unrelated.texts[2] = ["AXSelectedText": "stale sibling"]
check(read(unrelated) == nil && !unrelated.calls.contains("1:children"), "normal pages never scavenged for selections")
let toolbar = FakeAccess()
toolbar.texts[1] = ["AXRole": "AXWebArea", "AXURL": "chrome-extension://mhjfbmdgcfjbbpaeojofohoefgiehjai/index.html"]
toolbar.descendants[1] = [2, 3]
toolbar.texts[2] = ["AXRole": "AXTextField", "AXSelectedText": "1"]
toolbar.texts[3] = ["AXRole": "AXWebArea", "AXSelectedText": "Dummy"]
check(read(toolbar)?.text == "Dummy", "PDF text wins over stale toolbar field selection")
toolbar.texts[3] = ["AXRole": "AXWebArea"]
check(read(toolbar) == nil && !toolbar.calls.contains("2:AXSelectedText"), "toolbar selection alone is not PDF text")
let window = FakeAccess()
window.texts[1] = ["AXRole": "AXWindow", "AXURL": "https://example.org/active.pdf"]
window.descendants[1] = [2]
window.texts[2] = ["AXSelectedText": "unrelated control"]
check(read(window) == nil && !window.calls.contains("1:children"), "PDF URL on window cannot authorize window scavenging")
pdf.texts[3] = [:]
check(read(pdf) == nil && pdf.calls.count < 100, "cycles terminate")
let bounded = SelectionExtraction(access: pdf, now: { 0 }, canContinue: { true }, maximumCalls: 2)
pdf.calls = []
check(bounded.read(focused: 1) == nil && pdf.calls.count <= 2, "call budget applies to actual algorithm")
let stopped = SelectionExtraction(access: pdf, now: { 0 }, canContinue: { false })
pdf.calls = []
check(stopped.read(focused: 1) == nil && pdf.calls.isEmpty, "terminated source stops calls")
var ticks: TimeInterval = 0
let timed = SelectionExtraction(access: pdf, now: { ticks += 1; return ticks }, canContinue: { true }, maximumSeconds: 0.1)
check(timed.read(focused: 1) == nil, "deadline bounds traversal")
check(!pdf.calls.contains(where: { $0.contains("AXValue") }), "no whole-document attribute fallback")
print("Selection: focused/range/marker/PDF scope/cycle/budget/deadline checks passed")
