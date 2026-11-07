import Foundation
import Security

/// Keep the API key in the login keychain. No key is written to preferences.
enum KeyStore {
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.selectenglish.probe.ai",
         kSecAttrAccount as String: "api-key"]
    }

    static func read() throws -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw failure(status) }
        guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw AppError.message("钥匙串中的密钥数据无法读取，请重新保存密钥。")
        }
        return key
    }

    /// Replace the existing key, or delete it when the user explicitly clears it.
    static func save(_ key: String) throws {
        if key.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw failure(status) }
            return
        }
        let data = Data(key.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var request = query
            request[kSecValueData as String] = data
            request[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(request as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw failure(addStatus) }
        } else if status != errSecSuccess { throw failure(status) }
    }

    private static func failure(_ status: OSStatus) -> AppError {
        .message("钥匙串操作失败（\(status)），请检查系统提示后重试。")
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
