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
        let analysis = Analysis(translation: "持续提问。", expressions: [.init(phrase: "keep asking", meaning: "持续提问", usage: "keep + 动词 ing", example: "Keep asking questions.")])
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
            checkedRequest = true
            return (200, envelope)
        }
        let result = try await client.analyze(text: "keep asking", configuration: settings, key: "test-key")
        try check(result == analysis && checkedRequest, "decode fenced structured success and request contract")
        print("PASS: request contract and structured success")

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
