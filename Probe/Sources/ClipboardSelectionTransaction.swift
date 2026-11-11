import AppKit

/// One clipboard item with all original byte representations.
struct SelectionPasteboardItem: Equatable {
    let representations: [String: Data]
}

/// Main-actor clipboard operations. Offline tests use an in-memory implementation.
@MainActor protocol SelectionPasteboard: AnyObject {
    var changeCount: Int { get }
    func snapshot() throws -> [SelectionPasteboardItem]
    func clear() -> Int
    func string() -> String?
    func restore(_ items: [SelectionPasteboardItem]) throws
}

enum ClipboardSelectionError: Error, LocalizedError {
    case backupUnavailable, changed, noText, oversized, restoreFailed
    var errorDescription: String? {
        switch self {
        case .backupUnavailable: return "无法完整备份剪贴板，未执行复制。"
        case .changed: return "剪贴板或当前选区已变化，请重新选中后重试。"
        case .noText: return "未取得新的可复制文字，请确认选区后重试。"
        case .oversized: return "选中文字超过 20,000 字符，请缩小选区。"
        case .restoreFailed: return "无法恢复剪贴板，请检查剪贴板内容。"
        }
    }
}

/// Bounded copy transaction. The OS clipboard does not expose the writer's identity.
@MainActor enum ClipboardSelectionTransaction {
    /// Copy fresh text and restore the old clipboard if its observed version is unchanged.
    ///
    /// Args:
    ///   isCurrent: Checks the original source and controller generation.
    ///   performCopy: Sends Copy to the source. Check source identity before its side effect.
    /// Returns:
    ///   Trimmed fresh text, limited to 20,000 characters.
    /// Throws:
    ///   Backup, copy, timeout, cancellation, or restoration errors.
    static func run(isCurrent: @escaping () -> Bool,
                    performCopy: @escaping () async throws -> Void) async throws -> String {
        try await run(pasteboard: SystemSelectionPasteboard(), isCurrent: isCurrent, performCopy: performCopy)
    }

    /// Inject clipboard and waiting operations to test without user data or real delays.
    static func run(pasteboard: any SelectionPasteboard, attempts: Int = 30,
                    wait: () async throws -> Void = { try await Task.sleep(nanoseconds: 20_000_000) },
                    isCurrent: @escaping () -> Bool,
                    performCopy: @escaping () async throws -> Void) async throws -> String {
        func checkCurrent() throws {
            try Task.checkCancellation()
            guard isCurrent() else { throw CancellationError() }
        }
        try checkCurrent()
        let originalCount = pasteboard.changeCount
        let backup = try pasteboard.snapshot()
        try checkCurrent()
        guard pasteboard.changeCount == originalCount else { throw ClipboardSelectionError.changed }
        // Empty the clipboard so a failed Copy cannot return stale text.
        let emptyCount = pasteboard.clear()
        var ownedCount = emptyCount
        do {
            try checkCurrent()
            try await performCopy()
            // Record a synchronous Copy result before a cancellation check needs cleanup.
            let commandCount = pasteboard.changeCount
            if commandCount != emptyCount { ownedCount = commandCount }
            try checkCurrent()
            for _ in 0..<attempts {
                try checkCurrent()
                let count = pasteboard.changeCount
                if ownedCount != emptyCount && count != ownedCount {
                    throw ClipboardSelectionError.changed
                }
                if count != emptyCount {
                    // Treat the first post-command write as Copy. No OS API can prove its writer.
                    ownedCount = count
                    let text = pasteboard.string()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    guard pasteboard.changeCount == count else { throw ClipboardSelectionError.changed }
                    guard !text.isEmpty else { throw ClipboardSelectionError.noText }
                    guard text.count <= 20_000 else { throw ClipboardSelectionError.oversized }
                    try checkCurrent()
                    guard pasteboard.changeCount == ownedCount else { throw ClipboardSelectionError.changed }
                    try pasteboard.restore(backup)
                    return text
                }
                try await wait()
            }
            throw ClipboardSelectionError.noText
        } catch {
            // Cancellation still cleans up our empty clipboard; a subsequent copy wins.
            if pasteboard.changeCount == ownedCount { try pasteboard.restore(backup) }
            throw error
        }
    }
}

/// Native adapter. Offline tests must not instantiate this type.
@MainActor final class SystemSelectionPasteboard: SelectionPasteboard {
    private let board: NSPasteboard
    init(board: NSPasteboard = .general) { self.board = board }
    var changeCount: Int { board.changeCount }

    /// Materialize all data before mutation, within 32 items, 64 types/item and 8 MiB total.
    func snapshot() throws -> [SelectionPasteboardItem] {
        let items = board.pasteboardItems ?? []
        guard items.count <= 32, !items.isEmpty || (board.types ?? []).isEmpty else {
            throw ClipboardSelectionError.backupUnavailable
        }
        var total = 0
        return try items.map { item in
            guard item.types.count <= 64 else { throw ClipboardSelectionError.backupUnavailable }
            var representations: [String: Data] = [:]
            for type in item.types {
                guard let data = item.data(forType: type), data.count <= 8 * 1_024 * 1_024 - total else {
                    throw ClipboardSelectionError.backupUnavailable
                }
                total += data.count
                representations[type.rawValue] = data
            }
            return SelectionPasteboardItem(representations: representations)
        }
    }
    func clear() -> Int { board.clearContents() }
    func string() -> String? { board.string(forType: .string) }
    func restore(_ items: [SelectionPasteboardItem]) throws {
        let restored = try items.map { saved in
            let item = NSPasteboardItem()
            for (type, data) in saved.representations {
                guard item.setData(data, forType: NSPasteboard.PasteboardType(type)) else {
                    throw ClipboardSelectionError.restoreFailed
                }
            }
            return item
        }
        board.clearContents()
        if !restored.isEmpty && !board.writeObjects(restored) { throw ClipboardSelectionError.restoreFailed }
    }
}
