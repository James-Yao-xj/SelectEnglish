import Foundation

/// Intercept every test request so no network connection is made.
// The lock protects callback cancellation; the test runner changes handlers serially.
final class MockProtocol: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) throws -> (Int, Data))!
    static var delay = 0.0
    private let lock = NSLock()
    private var stopped = false
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        DispatchQueue.global().asyncAfter(deadline: .now() + Self.delay) { [self] in
            lock.lock()
            defer { lock.unlock() }
            guard !stopped else { return }
            do {
                let (status, data) = try Self.handler(request)
                client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch { client?.urlProtocol(self, didFailWithError: error) }
        }
    }
    override func stopLoading() { lock.lock(); stopped = true; lock.unlock() }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw AppError.message("TEST FAILED: \(message)") }
}

@main struct ServiceChecks {
    static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let client = AnalysisClient(session: session)
        let settings = AIConfiguration(endpoint: "https://api.invalid/v1/chat/completions", model: "test-model")
        let analysis = Analysis(translation: "持续提问。", expressions: [.init(phrase: "keep asking", meaning: "持续提问", usage: "keep + 动词 ing", example: "Keep asking questions.")], vocabulary: [.init(word: "asking", partOfSpeech: "动词（动名词形式）", meaning: "提问")], sentenceExplanation: "这是一个短语，强调持续提出问题。")
        let encoded = String(decoding: try JSONEncoder().encode(analysis), as: UTF8.self)
        let envelope = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": "```json\n\(encoded)\n```"]]]])
        var checkedRequest = false
        MockProtocol.handler = { request in
            try check(request.url == URL(string: settings.endpoint), "full endpoint must be unchanged")
            try check(request.httpMethod == "POST", "POST method")
            try check(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key", "authorization header")
            let body: Data
            if let direct = request.httpBody { body = direct }
            else {
                let stream = request.httpBodyStream!
                stream.open()
                defer { stream.close() }
                var data = Data()
                var buffer = [UInt8](repeating: 0, count: 1024)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    data.append(buffer, count: count)
                }
                body = data
            }
            let object = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            try check(object["model"] as? String == "test-model", "model field")
            try check(object["stream"] as? Bool == false, "nonstreaming")
            try check(object["response_format"] == nil, "no provider-specific forced format")
            let messages = object["messages"] as! [[String: String]]
            let prompt = messages[0]["content"]!
            try check(prompt.contains("partOfSpeech") && prompt.contains("sentenceExplanation") && prompt.contains("0–5") && prompt.contains("single word"), "new contextual contract and no forced expressions")
            checkedRequest = true
            return (200, envelope)
        }
        let result = try await client.analyze(text: "keep asking", configuration: settings, key: "test-key")
        try check(result == analysis && checkedRequest, "decode fenced structured success and request contract")
        print("PASS: request contract and structured success")

        let headings = analysis.displaySections.map(\.heading)
        try check(headings == ["生词", "整句解释", "固定表达"], "shared popup and notebook order")
        try check(analysis.displayText.contains("[动词（动名词形式）]") && analysis.displayText.contains("这是一个短语"), "contextual POS and sentence explanation visible")
        let singleWord = Analysis(translation: "开心的", expressions: [], vocabulary: [.init(word: "Happy", partOfSpeech: "形容词", meaning: "开心的；快乐的")], sentenceExplanation: "这里只选中了一个形容词，表示开心或快乐。")
        _ = try singleWord.validated(source: "Happy")
        try check(singleWord.displayText.contains("原文没有明显的固定表达。"), "single word can have no fixed expressions")
        let noWords = Analysis(translation: "他在。", expressions: [], vocabulary: [], sentenceExplanation: "这是一个简短陈述。")
        _ = try noWords.validated(source: "He is here.")
        do { _ = try noWords.validated(source: "Happy"); throw AppError.message("accepted missing single word") }
        catch { try check(error.localizedDescription != "accepted missing single word", "single-word input requires its POS/meaning") }
        for invalid in [
            Analysis(translation: "旧译文", expressions: []),
            Analysis(translation: "译文", expressions: [], vocabulary: [], sentenceExplanation: " "),
            Analysis(translation: "译文", expressions: [], vocabulary: [.init(word: "happy", partOfSpeech: "", meaning: "开心")], sentenceExplanation: "句意"),
            Analysis(translation: "译文", expressions: [], vocabulary: Array(repeating: .init(word: "happy", partOfSpeech: "形容词", meaning: "开心"), count: 9), sentenceExplanation: "句意")
        ] {
            do { _ = try invalid.validated(); throw AppError.message("accepted invalid live analysis") }
            catch { try check(error.localizedDescription != "accepted invalid live analysis", "missing sections/POS/oversized list rejected live") }
        }
        let oldContent = "{\"translation\":\"历史译文\",\"expressions\":[]}"
        let oldEnvelope = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": oldContent]]]])
        MockProtocol.handler = { _ in (200, oldEnvelope) }
        do { _ = try await client.analyze(text: "An old response", configuration: settings, key: "test-key"); throw AppError.message("accepted old live response") }
        catch { try check(error.localizedDescription != "accepted old live response", "old live schema rejected through HTTP parser") }
        print("PASS: learning order, contextual vocabulary, single word, optional empty arrays, and live schema validation")


        MockProtocol.handler = { _ in (401, Data("sensitive-provider-body".utf8)) }
        do { _ = try await client.analyze(text: "hello", configuration: settings, key: "test-key"); throw AppError.message("missing HTTP error") }
        catch { try check(error.localizedDescription.contains("401") && !error.localizedDescription.contains("sensitive-provider-body"), "HTTP error excludes body") }
        print("PASS: HTTP error redaction")

        for data in [Data("not-json".utf8), try JSONSerialization.data(withJSONObject: ["choices": []])] {
            MockProtocol.handler = { _ in (200, data) }
            do { _ = try await client.analyze(text: "hello", configuration: settings, key: "test-key"); throw AppError.message("unexpected success") }
            catch { try check(error.localizedDescription != "unexpected success", "reject malformed or empty response") }
        }
        print("PASS: malformed and empty response")

        MockProtocol.handler = { _ in throw URLError(.timedOut) }
        do { _ = try await client.analyze(text: "hello", configuration: settings, key: "test-key"); throw AppError.message("missing timeout") }
        catch { try check((error as? URLError)?.code == .timedOut, "timeout propagates") }
        MockProtocol.delay = 0.5
        MockProtocol.handler = { _ in (200, envelope) }
        let task = Task { try await client.analyze(text: "hello", configuration: settings, key: "test-key") }
        try await Task.sleep(nanoseconds: 30_000_000)
        task.cancel()
        do { _ = try await task.value; throw AppError.message("missing cancellation") }
        catch { try check(error is CancellationError || (error as? URLError)?.code == .cancelled, "cancel propagates") }
        MockProtocol.delay = 0
        print("PASS: timeout and cancellation")

        do { _ = try AIConfiguration(endpoint: "http://api.invalid/v1/chat/completions", model: "m").validatedURL(); throw AppError.message("allowed HTTP") }
        catch { try check(error.localizedDescription != "allowed HTTP", "reject insecure endpoint") }
        try check(settings.origin == "https://api.invalid:443", "stable key-binding origin")
        do { _ = try await client.analyze(text: String(repeating: "a", count: 20_001), configuration: settings, key: "test-key"); throw AppError.message("allowed oversized text") }
        catch { try check(error.localizedDescription != "allowed oversized text", "reject oversized selection") }
        print("PASS: endpoint and length limits")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("notebook.json")
        let legacyFile = directory.appendingPathComponent("legacy-notebook.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyData = try JSONSerialization.data(withJSONObject: [["id": UUID().uuidString, "createdAt": 0, "source": "Historical test source", "analysis": ["translation": "历史译文", "expressions": [["phrase": "old phrase", "meaning": "旧释义", "usage": "旧用法", "example": "Old example."]]]]])
        try legacyData.write(to: legacyFile)
        let legacyStore = NotebookStore(file: legacyFile)
        try check(legacyStore.loadError == nil && legacyStore.entries.count == 1, "legacy favorite still decodes")
        let historical = legacyStore.entries[0].analysis
        try check(historical.vocabulary == nil && historical.sentenceExplanation == nil, "missing historical analysis stays absent")
        try check(historical.displayText.contains("此历史收藏未包含生词分析") && historical.displayText.contains("此历史收藏未包含句意解析") && historical.displayText.contains("旧记录未区分固定搭配"), "historical content not misrepresented as new analysis")
        let untouched = try Data(contentsOf: legacyFile)
        try check(untouched == legacyData, "opening legacy favorites does not rewrite them")
        try legacyStore.save(source: "keep asking", analysis: analysis)
        let mixedStore = NotebookStore(file: legacyFile)
        try check(mixedStore.loadError == nil && mixedStore.entries.count == 2, "new favorite can coexist with legacy record")
        try check(mixedStore.entries[0].analysis == analysis, "new analysis sections persist in mixed notebook")
        let retainedLegacy = mixedStore.entries[1].analysis
        try check(retainedLegacy.vocabulary == nil && retainedLegacy.sentenceExplanation == nil && retainedLegacy.expressions.first?.phrase == "old phrase", "legacy missing markers and original expression survive explicit notebook save")
        print("PASS: historical favorites open unchanged and coexist with new records")
        let store = NotebookStore(file: file)
        try store.save(source: "keep asking", analysis: analysis)
        let reopened = NotebookStore(file: file)
        try check(reopened.entries.count == 1 && reopened.entries[0].analysis == analysis, "notebook survives reopen")
        try reopened.delete(id: reopened.entries[0].id)
        try check(NotebookStore(file: file).entries.isEmpty, "delete persists")
        let corrupt = Data("broken file".utf8)
        try corrupt.write(to: file)
        let damaged = NotebookStore(file: file)
        try check(damaged.loadError != nil, "corruption reported")
        do { try damaged.save(source: "new", analysis: analysis); throw AppError.message("overwrote corruption") }
        catch { try check(error.localizedDescription != "overwrote corruption", "corruption blocks writes") }
        let kept = try Data(contentsOf: file)
        try check(kept == corrupt, "corrupt source retained")
        print("PASS: notebook persistence, deletion, corruption preservation")
    }
}
