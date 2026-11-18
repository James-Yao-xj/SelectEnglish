import Foundation
import AppKit

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
        let readThread = try await KeyStore.readAsync(using: { Thread.isMainThread ? "main" : "background" })
        try check(readThread == "background", "credential read does not block the main thread")
        let releaseReader = DispatchSemaphore(value: 0)
        var pendingKey: Task<String?, Error>!
        await withCheckedContinuation { (started: CheckedContinuation<Void, Never>) in
            pendingKey = Task {
                try await KeyStore.readAsync(using: {
                    started.resume()
                    releaseReader.wait()
                    return "fake-test-value"
                })
            }
        }
        pendingKey.cancel()
        releaseReader.signal()
        do { _ = try await pendingKey.value; throw AppError.message("cancelled credential returned") }
        catch { try check(error is CancellationError, "cancelled credential wait cannot return a key for a request") }
        print("PASS: background credential read and post-read cancellation (fake reader only)")

        let credentialDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: credentialDirectory) }
        let credentialFile = credentialDirectory.appendingPathComponent("Private/api-key")
        let missingKey = try KeyStore.read(file: credentialFile)
        try check(missingKey == nil, "missing local credential returns nil")
        try KeyStore.save("fake-local-first", file: credentialFile)
        let firstKey = try KeyStore.read(file: credentialFile)
        try check(firstKey == "fake-local-first", "local credential survives reopen")
        let directoryMode = try FileManager.default.attributesOfItem(atPath: credentialFile.deletingLastPathComponent().path)[.posixPermissions] as! NSNumber
        let fileMode = try FileManager.default.attributesOfItem(atPath: credentialFile.path)[.posixPermissions] as! NSNumber
        try check(directoryMode.intValue == 0o700 && fileMode.intValue == 0o600, "private directory and credential file modes")
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: credentialFile.deletingLastPathComponent().path)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: credentialFile.path)
        try KeyStore.save("fake-local-replaced", file: credentialFile)
        let replaced = try KeyStore.read(file: credentialFile)
        let replacedDirectoryMode = try FileManager.default.attributesOfItem(atPath: credentialFile.deletingLastPathComponent().path)[.posixPermissions] as! NSNumber
        let replacedFileMode = try FileManager.default.attributesOfItem(atPath: credentialFile.path)[.posixPermissions] as! NSNumber
        try check(replaced == "fake-local-replaced" && replacedDirectoryMode.intValue == 0o700 && replacedFileMode.intValue == 0o600, "replace restores private permissions")
        try KeyStore.save("", file: credentialFile)
        let deleted = try KeyStore.read(file: credentialFile)
        try check(deleted == nil, "empty save deletes local credential")
        try KeyStore.save("", file: credentialFile)
        try Data([0xff, 0xfe]).write(to: credentialFile)
        do { _ = try KeyStore.read(file: credentialFile); throw AppError.message("accepted corrupt credential") }
        catch { try check(error.localizedDescription != "accepted corrupt credential", "corrupt UTF-8 is an error") }
        let blockedParent = credentialDirectory.appendingPathComponent("not-a-directory")
        try Data("fake file".utf8).write(to: blockedParent)
        do { try KeyStore.save("fake-key", file: blockedParent.appendingPathComponent("api-key")); throw AppError.message("suppressed write error") }
        catch { try check(error.localizedDescription != "suppressed write error", "local I/O failures propagate") }
        do { _ = try KeyStore.read(file: credentialFile.deletingLastPathComponent()); throw AppError.message("suppressed read error") }
        catch { try check(error.localizedDescription != "suppressed read error", "read I/O failures propagate") }
        print("PASS: isolated local credential save/replace/reopen/delete/modes/UTF-8/I/O failures")

        // A separate suite and fake writer isolate every binding test from real user data.
        let bindingSuite = "SelectEnglish.Tests.Binding." + UUID().uuidString
        let bindingDefaults = UserDefaults(suiteName: bindingSuite)!
        defer { bindingDefaults.removePersistentDomain(forName: bindingSuite) }
        let oldOrigin = "https://old.invalid:443"
        let newOrigin = "https://new.invalid:443"
        let oldEndpoint = "https://old.invalid/chat/completions"
        var fakeCredential = "synthetic-old"
        bindingDefaults.set(oldEndpoint, forKey: "ai.endpoint")
        bindingDefaults.set(oldOrigin, forKey: "ai.keyOrigin")
        do {
            try KeyStore.saveBound("synthetic-new", origin: newOrigin, defaults: bindingDefaults) { value in
                try check(bindingDefaults.string(forKey: "ai.keyOrigin") == nil, "unbind before the first replacement side effect")
                fakeCredential = value
                throw AppError.message("injected post-replacement failure")
            }
            throw AppError.message("partial replacement unexpectedly succeeded")
        } catch { try check(error.localizedDescription == "injected post-replacement failure", "partial write error propagates") }
        try check(fakeCredential == "synthetic-new", "fault writer actually replaced fake bytes")
        try check(bindingDefaults.string(forKey: "ai.keyOrigin") == nil, "partial write cannot keep the old provider binding")
        try check(bindingDefaults.string(forKey: "ai.endpoint") == oldEndpoint, "failed replacement does not change endpoint")
        bindingDefaults.set(oldOrigin, forKey: "ai.keyOrigin")
        do {
            try KeyStore.saveBound("synthetic-unused", origin: newOrigin, defaults: bindingDefaults) { _ in
                throw AppError.message("injected pre-write failure")
            }
            throw AppError.message("pre-write failure unexpectedly succeeded")
        } catch { try check(error.localizedDescription == "injected pre-write failure", "pre-write error propagates") }
        try check(fakeCredential == "synthetic-new" && bindingDefaults.string(forKey: "ai.keyOrigin") == nil,
                  "failure before mutation also leaves the credential unbound")
        try KeyStore.saveBound("synthetic-success", origin: newOrigin, defaults: bindingDefaults) { value in
            try check(bindingDefaults.string(forKey: "ai.keyOrigin") == nil, "success writer starts unbound")
            fakeCredential = value
        }
        try check(fakeCredential == "synthetic-success" && bindingDefaults.string(forKey: "ai.keyOrigin") == newOrigin,
                  "only a completed writer binds the new provider")
        do {
            try KeyStore.saveBound("synthetic-same-provider", origin: newOrigin, defaults: bindingDefaults) { value in
                fakeCredential = value
                throw AppError.message("injected same-origin failure")
            }
            throw AppError.message("same-origin failure unexpectedly succeeded")
        } catch { try check(error.localizedDescription == "injected same-origin failure", "same-origin error propagates") }
        try check(bindingDefaults.string(forKey: "ai.keyOrigin") == nil, "same-origin write failures must not restore a stale binding")
        print("PASS: isolated provider binding fails closed before/after mutation and on same-origin errors")

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let client = AnalysisClient(session: session)

        // This checks the real delegate decision, not TLS or URLSession redirect delivery.
        // The task is never resumed; all values are synthetic and no request can reach DNS.
        let redirectPolicy = NoRedirects()
        var original = URLRequest(url: URL(string: "https://provider.invalid/chat/completions")!)
        original.httpMethod = "POST"
        original.setValue("Bearer fake-redirect-test", forHTTPHeaderField: "Authorization")
        original.httpBody = Data("synthetic selected text".utf8)
        let redirectTask = session.dataTask(with: original)
        defer { redirectTask.cancel() }
        for (status, destination) in [
            (302, "https://provider.invalid/other/chat/completions"),
            (307, "https://different-provider.invalid/chat/completions"),
            (301, "http://provider.invalid/chat/completions")
        ] {
            let response = HTTPURLResponse(url: original.url!, statusCode: status, httpVersion: nil,
                                           headerFields: ["Location": destination])!
            var proposed = original
            proposed.url = URL(string: destination)!
            var decisions: [URLRequest?] = []
            redirectPolicy.urlSession(session, task: redirectTask, willPerformHTTPRedirection: response,
                                      newRequest: proposed) { decisions.append($0) }
            try check(decisions.count == 1, "redirect callback completes exactly once")
            try check(decisions[0] == nil, "redirect policy never forwards headers or selected text")
        }
        print("PASS: actual redirect delegate rejects same-origin, cross-origin and downgrade decisions (unresumed task)")
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

        let providerCases: [(String, String, Bool)] = [
            ("https://api.deepseek.com/chat/completions", "deepseek-flash", true),
            ("https://api.deepseek.com/v1/chat/completions", "deepseek-v4-pro", true),
            ("https://API.DeepSeek.COM/chat/completions", "deepseek-flash", true),
            ("https://proxy.invalid/chat/completions", "deepseek-flash", false),
            ("https://api.deepseek.com.evil.invalid/chat/completions", "deepseek-v4-pro", false),
            ("https://sub.api.deepseek.com/chat/completions", "deepseek-flash", false),
            ("https://api.deepseek.com/chat/completions", "deepseek-chat", false),
            ("https://api.deepseek.com/chat/completions", "deepseek-reasoner", false),
            ("https://api.deepseek.com/chat/completions", "deepseek-v4-pro-extra", false),
            ("https://api.deepseek.com/chat/completions", "DEEPSEEK-FLASH", false)
        ]
        for (endpoint, model, expectedThinkingControl) in providerCases {
            MockProtocol.handler = { request in
                let body: Data
                if let direct = request.httpBody { body = direct }
                else {
                    let stream = request.httpBodyStream!
                    stream.open()
                    defer { stream.close() }
                    var result = Data()
                    var buffer = [UInt8](repeating: 0, count: 1024)
                    while stream.hasBytesAvailable {
                        let count = stream.read(&buffer, maxLength: buffer.count)
                        if count <= 0 { break }
                        result.append(buffer, count: count)
                    }
                    body = result
                }
                let object = try JSONSerialization.jsonObject(with: body) as! [String: Any]
                if expectedThinkingControl {
                    try check((object["thinking"] as? [String: String]) == ["type": "disabled"], "official current model uses explicit non-thinking")
                } else { try check(object["thinking"] == nil, "custom host or unknown model gets no vendor option") }
                try check(object["reasoning_effort"] == nil && object["max_tokens"] == nil, "no extra reasoning option or truncation cap")
                try check(object["model"] as? String == model && request.url?.absoluteString == endpoint, "provider and model remain user configured")
                return (200, envelope)
            }
            _ = try await client.analyze(text: "keep asking", configuration: AIConfiguration(endpoint: endpoint, model: model), key: "test-key")
        }
        print("PASS: serialized official DeepSeek host/model boundaries")


        let headings = analysis.displaySections.map(\.heading)
        try check(headings == ["生词", "整句解释", "固定表达"], "shared popup and notebook order")
        try check(analysis.displayText.contains("[动词（动名词形式）]") && analysis.displayText.contains("这是一个短语"), "contextual POS and sentence explanation visible")
        let singleWord = Analysis(translation: "开心的", expressions: [], vocabulary: [.init(word: "Happy", partOfSpeech: "形容词", meaning: "开心的；快乐的")], sentenceExplanation: "这里只选中了一个形容词，表示开心或快乐。")
        _ = try singleWord.validated(source: "Happy")
        for source in ["happy", "HAPPY!", "“Happy!”", "(Happy)"] { _ = try singleWord.validated(source: source) }
        let wrongWord = Analysis(translation: "开心", expressions: [], vocabulary: [.init(word: "banana", partOfSpeech: "名词", meaning: "香蕉")], sentenceExplanation: "这是单词。")
        do { _ = try wrongWord.validated(source: "Happy"); throw AppError.message("accepted unrelated vocabulary") }
        catch { try check(error.localizedDescription != "accepted unrelated vocabulary", "single word requires matching vocabulary, not merely nonempty array") }
        let inflection = Analysis(translation: "开心", expressions: [], vocabulary: [.init(word: "happier", partOfSpeech: "形容词", meaning: "更开心")], sentenceExplanation: "这是单词。")
        do { _ = try inflection.validated(source: "Happy"); throw AppError.message("accepted different inflection") }
        catch { try check(error.localizedDescription != "accepted different inflection", "no stemming across distinct inflections") }
        for (source, wrong) in [("well-being", "wellbeing"), ("can't", "cant")] {
            let exact = Analysis(translation: "测试释义", expressions: [], vocabulary: [.init(word: source, partOfSpeech: "测试词性", meaning: "测试词义")], sentenceExplanation: "只有一个词。")
            _ = try exact.validated(source: "“" + source + "!”")
            let different = Analysis(translation: "测试释义", expressions: [], vocabulary: [.init(word: wrong, partOfSpeech: "测试词性", meaning: "测试词义")], sentenceExplanation: "只有一个词。")
            do { _ = try different.validated(source: source); throw AppError.message("stripped internal punctuation") }
            catch { try check(error.localizedDescription != "stripped internal punctuation", "internal hyphens and apostrophes preserved") }
        }
        print("PASS: exact single-word vocabulary, case/boundary punctuation and preserved inflection")

        func vocabularyResult(_ word: String) -> Analysis {
            Analysis(translation: "测试译文", expressions: [], vocabulary: [.init(word: word, partOfSpeech: "测试词性", meaning: "测试词义")], sentenceExplanation: "测试解析。")
        }
        for (source, word) in [
            ("The scientist scrutinized the results.", "banana"),
            ("The scientists scrutinized the results.", "scientist"),
            ("A neuroscientist led the study.", "scientist"),
            ("A scientist-led study.", "scientist"),
            ("A scientist-led study.", "led"),
            ("They checked the internet.", "net"),
            ("They use C++ and .NET.", "C"),
            ("They use C++ and .NET.", "NET"),
            ("They use C++ and .NET.", "C#"),
            ("They discuss well-being.", "wellbeing"),
            ("They discuss well‑being.", "well-being"),
            ("They can't proceed.", "cant")
        ] {
            do { _ = try vocabularyResult(word).validated(source: source); throw AppError.message("accepted unrelated source form") }
            catch { try check(error.localizedDescription != "accepted unrelated source form", "sentence vocabulary must retain complete source forms") }
        }
        for (source, word) in [
            ("The SCIENTIST scrutinized the results.", "scientist"),
            ("A 'scientist' scrutinized the results.", "scientist"),
            ("A scientist-led study.", "scientist-led"),
            ("They use C++ and .NET.", "C++"),
            ("They use C++ and .NET.", ".NET"),
            ("They use C#.", "C#"),
            ("They discuss well-being.", "well-being"),
            ("They can't proceed.", "can't"),
            ("They study neural\n  networks.", "neural networks"),
            ("A neuroscientist and a scientist.", "scientist")
        ] { _ = try vocabularyResult(word).validated(source: source) }
        let unrelatedContent = String(decoding: try JSONEncoder().encode(vocabularyResult("banana")), as: UTF8.self)
        let unrelatedEnvelope = try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": unrelatedContent]]]])
        MockProtocol.handler = { _ in (200, unrelatedEnvelope) }
        do {
            _ = try await client.analyze(text: "The scientist scrutinized the results.", configuration: settings, key: "test-key")
            throw AppError.message("accepted unrelated HTTP vocabulary")
        } catch {
            try check(error.localizedDescription != "accepted unrelated HTTP vocabulary"
                && !error.localizedDescription.contains("scientist") && !error.localizedDescription.contains("banana"),
                "production HTTP validation rejects unrelated vocabulary without echoing selected text")
        }
        print("PASS: sentence vocabulary provenance, technical boundaries and multiline source forms")

        try check(singleWord.displayText.contains("原文没有明显的固定表达。"), "single word can have no fixed expressions")
        let noWords = Analysis(translation: "他在。", expressions: [], vocabulary: [], sentenceExplanation: "这是一个简短陈述。")
        _ = try noWords.validated(source: "He is here.")
        _ = try noWords.validated(source: "happy/sad")
        _ = try noWords.validated(source: "Hello,world!")
        do { _ = try noWords.validated(source: "Happy"); throw AppError.message("accepted missing single word") }
        catch { try check(error.localizedDescription != "accepted missing single word", "single-word input requires its POS/meaning") }
        for term in ["3D", "COVID-19", "C+", "C++", ".NET", "C#"] {
            _ = try vocabularyResult(term).validated(source: term)
            for invalid in [noWords, vocabularyResult("banana")] {
                do { _ = try invalid.validated(source: term); throw AppError.message("accepted missing technical term") }
                catch { try check(error.localizedDescription != "accepted missing technical term", "isolated technical term requires its literal vocabulary entry") }
            }
        }
        _ = try noWords.validated(source: "123")
        _ = try noWords.validated(source: "They use 3D models, COVID-19 data and C++.")
        print("PASS: isolated alphanumeric and plus-suffix terms require exact vocabulary; fragments and sentences may stay empty")
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
        let identityFile = directory.appendingPathComponent("identity-notebook.json")
        let identityStore = NotebookStore(file: identityFile)
        try identityStore.save(source: "A", analysis: analysis)
        let originalA = identityStore.entries[0]
        let selectedAItem = NotebookMenuSelection.item(for: originalA, title: "Identical display title")
        try check(selectedAItem.representedObject as? UUID == originalA.id, "production menu item binds saved record UUID")
        try identityStore.save(source: "C", analysis: analysis)
        let insertedC = identityStore.entries[0]
        let insertedCItem = NotebookMenuSelection.item(for: insertedC, title: "Identical display title")
        try check(insertedCItem.representedObject as? UUID != selectedAItem.representedObject as? UUID, "identical titles retain distinct identities")
        let resolvedA = NotebookMenuSelection.entry(for: selectedAItem, in: identityStore.entries)
        try check(resolvedA?.source == "A" && resolvedA?.id == originalA.id, "old selected menu item resolves A after C is prepended")
        try identityStore.delete(id: resolvedA!.id)
        let identityReopened = NotebookStore(file: identityFile)
        try check(identityReopened.entries.count == 1 && identityReopened.entries[0].id == insertedC.id && identityReopened.entries[0].source == "C", "delete selected A preserves new C after reopen")
        try check(NotebookMenuSelection.entry(for: selectedAItem, in: identityReopened.entries) == nil, "removed menu identity cannot resolve to another record")
        print("PASS: production notebook menu identity prevents stale-selection wrong deletion")
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
