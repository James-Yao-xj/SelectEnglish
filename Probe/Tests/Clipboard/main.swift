import Foundation

/// Fake clipboard; no native clipboard is created or read by this suite.
@MainActor final class FakePasteboard: SelectionPasteboard {
    private var version = 0
    var onVersionRead: (() -> Void)?
    var changeCount: Int {
        let observed = version
        onVersionRead?()
        return observed
    }
    var items: [SelectionPasteboardItem]
    var backupFails = false
    var clearCalls = 0
    var onRead: (() -> Void)?
    init(_ items: [SelectionPasteboardItem]) { self.items = items }
    func snapshot() throws -> [SelectionPasteboardItem] {
        if backupFails { throw ClipboardSelectionError.backupUnavailable }
        return items
    }
    func clear() -> Int { clearCalls += 1; items = []; version += 1; return version }
    func string() -> String? {
        let data = items.first?.representations["public.utf8-plain-text"]
        onRead?()
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
    func restore(_ saved: [SelectionPasteboardItem]) throws { items = saved; version += 1 }
    func copy(_ text: String) {
        items = [SelectionPasteboardItem(representations: ["public.utf8-plain-text": Data(text.utf8)])]
        version += 1
    }
}

@main struct ClipboardChecks {
    @MainActor static func main() async throws {
        let original = [SelectionPasteboardItem(representations: ["public.utf8-plain-text": Data("stale secret".utf8), "custom.binary": Data([0, 255, 1])]), SelectionPasteboardItem(representations: ["public.rtf": Data([5, 6])])]
        func check(_ value: Bool, _ label: String) { precondition(value, label) }
        let board = FakePasteboard(original)
        let text = try await ClipboardSelectionTransaction.run(pasteboard: board, wait: {}, isCurrent: { true }, performCopy: { board.copy(" fresh ") })
        check(text == "fresh" && board.items == original, "fresh copy and all item/type bytes roundtrip")

        for payload in ["", "  \n", String(repeating: "x", count: 20_001)] {
            let fake = FakePasteboard(original)
            do {
                _ = try await ClipboardSelectionTransaction.run(pasteboard: fake, wait: {}, isCurrent: { true }, performCopy: { fake.copy(payload) })
                preconditionFailure("invalid text accepted")
            } catch {}
            check(fake.items == original, "failed copied text restores backup")
        }
        let noWrite = FakePasteboard(original)
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: noWrite, attempts: 2, wait: {}, isCurrent: { true }, performCopy: {})
            preconditionFailure("stale text accepted")
        } catch {}
        check(noWrite.items == original, "timeout restores without stale result")

        let backupFailure = FakePasteboard(original)
        backupFailure.backupFails = true
        var commandSent = false
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: backupFailure, isCurrent: { true }, performCopy: { commandSent = true })
            preconditionFailure("backup failure ignored")
        } catch {}
        check(!commandSent && backupFailure.clearCalls == 0, "incomplete backup aborts before mutation")

        let failedCommand = FakePasteboard(original)
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: failedCommand, isCurrent: { true }, performCopy: { throw ClipboardSelectionError.noText })
            preconditionFailure("failed command accepted")
        } catch {}
        check(failedCommand.items == original, "command error restores empty transaction")

        let cancelled = FakePasteboard(original)
        var current = true
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: cancelled, wait: { current = false }, isCurrent: { current }, performCopy: {})
            preconditionFailure("cancel ignored")
        } catch is CancellationError {} catch { throw error }
        check(cancelled.items == original, "generation cancellation restores")

        let taskCancelled = FakePasteboard(original)
        let task = Task { @MainActor in
            try await ClipboardSelectionTransaction.run(pasteboard: taskCancelled, wait: {
                withUnsafeCurrentTask { $0?.cancel() }
                try Task.checkCancellation()
            }, isCurrent: { true }, performCopy: {})
        }
        do { _ = try await task.value; preconditionFailure("task cancellation ignored") }
        catch is CancellationError {} catch { throw error }
        check(taskCancelled.items == original, "task cancellation restores")

        let betweenCommandAndPoll = FakePasteboard(original)
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: betweenCommandAndPoll, wait: {}, isCurrent: { true }, performCopy: {
                betweenCommandAndPoll.copy("browser selection")
                betweenCommandAndPoll.onVersionRead = {
                    betweenCommandAndPoll.onVersionRead = nil
                    betweenCommandAndPoll.copy("later user copy")
                }
            })
            preconditionFailure("newer version after observed Copy accepted")
        } catch ClipboardSelectionError.changed {} catch { throw error }
        check(betweenCommandAndPoll.string() == "later user copy", "later version before polling is preserved")

        let concurrent = FakePasteboard(original)
        concurrent.onRead = { concurrent.copy("user newer copy") }
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: concurrent, wait: {}, isCurrent: { true }, performCopy: { concurrent.copy("selected") })
            preconditionFailure("concurrent change accepted")
        } catch {}
        concurrent.onRead = nil
        check(concurrent.string() == "user newer copy", "concurrent copy during read wins")

        let cancelledWithCopy = FakePasteboard(original)
        var active = true
        do {
            _ = try await ClipboardSelectionTransaction.run(pasteboard: cancelledWithCopy, wait: {
                cancelledWithCopy.copy("user copy during cancellation")
                active = false
            }, isCurrent: { active }, performCopy: {})
            preconditionFailure("cancel ignored")
        } catch {}
        check(cancelledWithCopy.string() == "user copy during cancellation", "cancel does not overwrite concurrent copy")
        print("PASS: clipboard fresh copy, lossless backup, failures, bounds, cancellation and concurrent-copy preservation")
    }
}
