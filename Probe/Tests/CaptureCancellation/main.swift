import Foundation

/// Fake AX operations. The serial worker owns calls; the main thread reads after completion.
final class BlockingAccess: SelectionAccess, @unchecked Sendable {
    typealias Node = Int
    typealias Marker = Int
    let entered: DispatchSemaphore?
    let release: DispatchSemaphore?
    private(set) var calls = 0
    init(entered: DispatchSemaphore? = nil, release: DispatchSemaphore? = nil) {
        self.entered = entered
        self.release = release
    }
    func text(_ node: Int, attribute: String) -> String? {
        calls += 1
        if attribute == "AXSelectedText" {
            entered?.signal()
            if let release { precondition(release.wait(timeout: .now() + 5) == .success, "test must release active fake AX") }
            return "Public fixture"
        }
        return "AXTextArea"
    }
    func parent(_ node: Int) -> Int? { calls += 1; return nil }
    func children(_ node: Int, limit: Int) -> [Int] { calls += 1; return [] }
    func selectedRange(_ node: Int) -> NSRange? { calls += 1; return nil }
    func string(_ node: Int, range: NSRange) -> String? { calls += 1; return nil }
    func selectedMarker(_ node: Int) -> Int? { calls += 1; return nil }
    func length(_ node: Int, marker: Int) -> Int? { calls += 1; return nil }
    func string(_ node: Int, marker: Int) -> String? { calls += 1; return nil }
}

let queue = DispatchQueue(label: "test.selection.serial")
let entered = DispatchSemaphore(value: 0)
let release = DispatchSemaphore(value: 0)
let completed = DispatchSemaphore(value: 0)
let activePermit = SelectionCapturePermit()
let active = BlockingAccess(entered: entered, release: release)
queue.async {
    let result = SelectionExtraction(access: active, now: { 0 }, canContinue: { activePermit.isValid }).read(focused: 1)
    precondition(result == nil, "cancellation during an issued AX call discards its text")
}
precondition(entered.wait(timeout: .now() + 5) == .success, "first fake AX call must start")
activePermit.cancel()
let queued = (0..<4).map { _ in (SelectionCapturePermit(), BlockingAccess()) }
for (permit, access) in queued {
    queue.async {
        let result = SelectionExtraction(access: access, now: { 0 }, canContinue: { permit.isValid }).read(focused: 1)
        precondition(result == nil, "cancelled queued capture must return no text")
    }
    permit.cancel()
}
let latestPermit = SelectionCapturePermit()
let latest = BlockingAccess()
queue.async {
    let result = SelectionExtraction(access: latest, now: { 0 }, canContinue: { latestPermit.isValid }).read(focused: 1)
    precondition(result?.text == "Public fixture", "latest capture must complete on the same serial queue")
    completed.signal()
}
release.signal()
precondition(completed.wait(timeout: .now() + 5) == .success, "latest capture must not wait for obsolete budgets")
precondition(active.calls == 1, "cancelled active request must not issue another fake AX operation")
precondition(queued.allSatisfy { $0.1.calls == 0 }, "all obsolete queued requests must issue zero AX operations")
precondition(latest.calls == 2, "latest request reads selected text and role only")
print("Capture cancellation: active-call discard, zero queued AX and latest serial request checks passed")
