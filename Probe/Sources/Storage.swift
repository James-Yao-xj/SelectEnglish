import Foundation

/// Keep the API key in a private per-user file outside the repository.
enum KeyStore {
    /// One queue keeps async local reads ordered without blocking the UI.
    private static let readQueue = DispatchQueue(label: "com.selectenglish.credential-read")

    private static var applicationFile: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SelectEnglish/Private/api-key")
    }

    /// Read off the UI thread. Tests supply a fake reader without user credentials.
    ///
    /// Returns:
    ///   The saved key, or nil when no key exists. A cancelled caller never receives a key.
    static func readAsync(using reader: @escaping @Sendable () throws -> String? = { try KeyStore.read() }) async throws -> String? {
        try Task.checkCancellation()
        let value: String? = try await withCheckedThrowingContinuation { continuation in
            readQueue.async {
                do { continuation.resume(returning: try reader()) }
                catch { continuation.resume(throwing: error) }
            }
        }
        try Task.checkCancellation()
        return value
    }

    /// Read the local UTF-8 key. A supplied file URL is used only for isolated tests.
    static func read(file: URL? = nil) throws -> String? {
        let data: Data
        do { data = try Data(contentsOf: file ?? applicationFile) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return nil }
        guard let key = String(data: data, encoding: .utf8) else {
            throw AppError.message("本地密钥文件不是有效 UTF-8，请在 AI 设置中重新保存密钥。")
        }
        return key
    }

    /// Atomically replace the key inside a mode-0700 directory, or delete it for an empty save.
    static func save(_ key: String, file: URL? = nil) throws {
        let destination = file ?? applicationFile
        let manager = FileManager.default
        if key.isEmpty {
            do { try manager.removeItem(at: destination) }
            catch let error as CocoaError where error.code == .fileNoSuchFile { return }
            return
        }
        let directory = destination.deletingLastPathComponent()
        try manager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        // Restrict an existing directory before an atomic write creates its temporary file.
        try manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        try Data(key.utf8).write(to: destination, options: .atomic)
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
    }
}

struct SavedAnalysis: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let source: String
    let analysis: Analysis
}

/// Store only user-saved results. A corrupt file is left intact and blocks writes.
final class NotebookStore {
    private(set) var entries: [SavedAnalysis] = []
    private(set) var loadError: String?
    private let file: URL

    init(file: URL) {
        self.file = file
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                entries = try JSONDecoder().decode([SavedAnalysis].self, from: Data(contentsOf: file))
            }
        } catch {
            loadError = "收藏文件无法读取，原文件已保留。请备份后检查：\(file.path)"
        }
    }

    static func applicationStore() -> NotebookStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SelectEnglish", isDirectory: true)
        return NotebookStore(file: directory.appendingPathComponent("notebook.json"))
    }

    /// Commit to disk before publishing the new in-memory collection.
    func save(source: String, analysis: Analysis) throws {
        var updated = entries
        updated.insert(SavedAnalysis(id: UUID(), createdAt: Date(), source: source, analysis: analysis), at: 0)
        try persist(updated)
    }

    func delete(id: UUID) throws {
        try persist(entries.filter { $0.id != id })
    }

    private func persist(_ updated: [SavedAnalysis]) throws {
        if let loadError { throw AppError.message(loadError) }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(updated)
        try data.write(to: file, options: [.atomic, .completeFileProtectionUnlessOpen])
        entries = updated
    }
}
