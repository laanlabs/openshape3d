//
//  AssistantPanelUITests.swift
//  openshape3dUITests
//
//  The built-in assistant, end to end in the live app (#119): open the panel,
//  type a request, and watch a block get built — with a stand-in for the
//  provider's API running inside this test, so no key and no network are
//  involved. The stand-in speaks each provider's real streaming shape
//  (Claude, OpenAI, Gemini) and checks what the app sends it (headers, every
//  tool call answered, what must go back unchanged), so a malformed
//  conversation fails here and not in front of a person.
//

import XCTest
import Network

final class AssistantPanelUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    private func launch(server: StandInAPI?) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        if let server {
            app.launchEnvironment["OS3D_ASSISTANT_URL"] = "http://127.0.0.1:\(server.port)/stand-in"
            app.launchEnvironment["OS3D_ASSISTANT_KEY"] = "test-key-not-a-real-one"
            app.launchEnvironment["OS3D_ASSISTANT_PROVIDER"] = server.dialect.rawValue
        }
        app.launch()
        return app
    }

    private func openPanel(_ app: XCUIApplication) {
        let button = app.buttons["AssistantButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "the Assistant button is in the top bar")
        button.tap()
        XCTAssertTrue(app.staticTexts["AssistantTitle"].waitForExistence(timeout: 5), "the panel opens")
    }

    /// Keep a picture of the screen with the test's results.
    private func keepScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: Before there is a key

    func testThePanelWarnsBeforeAKeyIsSaved() throws {
        let app = launch(server: nil)
        openPanel(app)

        let notice = app.descendants(matching: .any).matching(identifier: "AssistantNotice").firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 5), "the notice is shown before anything can be sent")
        XCTAssertTrue(notice.label.contains("sent from this device straight to Anthropic"))
        XCTAssertTrue(notice.label.contains("bills your key"))
        XCTAssertFalse(app.textFields["AssistantInput"].exists, "no message box until a key is saved")
        keepScreenshot("assistant-notice")

        // The notice names whoever would receive the data: choose another
        // provider and it says so.
        let picker = app.segmentedControls["AssistantProviderPicker"]
        XCTAssertTrue(picker.exists, "the three providers are offered")
        picker.buttons["ChatGPT"].tap()
        XCTAssertTrue(notice.label.contains("straight to OpenAI"), notice.label)
        picker.buttons["Gemini"].tap()
        XCTAssertTrue(notice.label.contains("straight to Google"), notice.label)
        XCTAssertFalse(notice.label.contains("Anthropic"))
        picker.buttons["Claude"].tap()

        // The way in without a key, an assistant app over MCP, is offered too.
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "AssistantAppsOffer").firstMatch.exists)

        let save = app.buttons["AssistantSaveKey"]
        XCTAssertFalse(save.isEnabled, "nothing to save yet")
        let field = app.secureTextFields["AssistantKeyField"]
        field.tap()
        field.typeText("not-a-key")
        XCTAssertTrue(save.isEnabled)
        // Return saves too, which is the only way on a phone in landscape,
        // where the keyboard covers the button.
        field.typeText("\n")
        XCTAssertTrue(app.staticTexts["AssistantKeyProblem"].waitForExistence(timeout: 3),
                      "an obviously wrong paste is refused and not stored")
        XCTAssertFalse(app.textFields["AssistantInput"].exists)

        app.buttons["AssistantClose"].tap()
        XCTAssertTrue(app.staticTexts["AssistantTitle"].waitForNonExistence(timeout: 3), "the panel closes")
    }

    // MARK: A whole build, once per provider

    func testARequestBuildsABlock() throws { try buildABlock(.anthropic) }
    func testARequestBuildsABlockWithOpenAI() throws { try buildABlock(.openai) }
    func testARequestBuildsABlockWithGemini() throws { try buildABlock(.google) }

    private func buildABlock(_ dialect: StandInAPI.Dialect) throws {
        let server = try StandInAPI(dialect) { request, _ in
            let results = dialect.toolResults(in: request)
            switch results.count {
            case 0:
                return dialect.reply(marker: "sig-one", text: "Building a 40 × 30 × 10 mm block.",
                                     call: ("call_1", ["op": "sketch.create"]))
            case 1:
                let sketch = StandInAPI.json(results[0])["sketchID"] as? String ?? ""
                return dialect.reply(call: ("call_2", ["op": "sketch.addEntities", "args": [
                    "sketchID": sketch, "entities": [["kind": "rect", "min": [-20, -15], "max": [20, 15]]]]]))
            case 2:
                let sketch = StandInAPI.json(results[0])["sketchID"] as? String ?? ""
                return dialect.reply(call: ("call_3", ["op": "feature.extrude", "args": [
                    "sketchID": sketch, "seedPoint": [0, 0], "distance": 10]]))
            case 3:
                return dialect.reply(call: ("call_4", ["op": "state"]))
            default:
                return dialect.reply(text: "Finished: one block, 40 × 30 × 10 mm.")
            }
        }
        defer { server.stop() }

        let app = launch(server: server)
        openPanel(app)

        let input = app.textFields["AssistantInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "with a key the message box is there")
        let footnote = app.staticTexts["AssistantFootnote"]
        XCTAssertTrue(footnote.exists, "the reminder of where messages go stays visible")
        XCTAssertTrue(footnote.label.contains(dialect.company), footnote.label)
        input.tap()
        input.typeText("Make a 40 by 30 by 10 mm block")
        app.buttons["AssistantSend"].tap()

        let finished = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Finished: one block")).firstMatch
        XCTAssertTrue(finished.waitForExistence(timeout: 60), "the final reply arrives. Problems: \(server.problems)")
        keepScreenshot("assistant-built-a-block-\(dialect.rawValue)")
        XCTAssertEqual(server.problems, [], "every request the app sent was well formed")
        XCTAssertEqual(server.requestCount, 5, "one request per step of the build")

        // The panel showed its work, and no call failed.
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Building a 40")).firstMatch.exists)
        let activity = app.descendants(matching: .any).matching(identifier: "AssistantActivity")
        XCTAssertGreaterThanOrEqual(activity.count, 4)
        XCTAssertFalse(app.staticTexts["AssistantProblem"].exists)

        // The design really holds the block: the last tool answer is the
        // `state` read, with the exact volume of a 40 × 30 × 10 mm solid.
        let last = try XCTUnwrap(server.lastRequest)
        let state = StandInAPI.json(try XCTUnwrap(dialect.toolResults(in: last).last))
        let bodies = state["bodies"] as? [[String: Any]] ?? []
        XCTAssertEqual(bodies.count, 1, "one body was built")
        let volume = (bodies.first?["volumeMM3"] as? NSNumber)?.doubleValue ?? 0
        XCTAssertEqual(volume, 12_000, accuracy: 1, "40 × 30 × 10 mm")

        // What must go back to the API unchanged did: Claude's thinking
        // block, OpenAI's reasoning item, Gemini's signature on its call.
        XCTAssertTrue(dialect.sentBackMarker("sig-one", in: last), "the model's own state went back as it came")

        // And the person can undo what the assistant did, like any other step.
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "the build is on the undo stack")
    }

    // MARK: A key the provider refuses

    func testARefusedKeyIsExplained() throws {
        let server = try StandInAPI(.anthropic) { _, _ in
            .failure(status: 401, body: #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#)
        }
        defer { server.stop() }

        let app = launch(server: server)
        openPanel(app)
        let input = app.textFields["AssistantInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("A cube")
        app.buttons["AssistantSend"].tap()

        let problem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "did not accept this API key")).firstMatch
        XCTAssertTrue(problem.waitForExistence(timeout: 20), "the refusal is put in plain words")
        XCTAssertEqual(server.requestCount, 1, "a refused key is not retried")
        XCTAssertTrue(app.buttons["AssistantSend"].waitForExistence(timeout: 5), "the panel is ready for another message")
    }

    func testGeminiRetriesWithArgsAsTextWhenItsSchemaIsRefused() throws {
        let server = try StandInAPI(.google) { request, index in
            if index == 0 {
                return .failure(status: 400, body: #"{"error":{"code":400,"message":"Invalid value at 'tools[0].function_declarations[0].parameters_json_schema'","status":"INVALID_ARGUMENT"}}"#)
            }
            let results = StandInAPI.Dialect.google.toolResults(in: request)
            if results.isEmpty {
                // The model writes args as text, as the fallback declaration asks.
                return StandInAPI.Dialect.google.reply(call: ("fc-1", ["op": "command.run", "args": "{\"id\": \"view.fit\"}"]))
            }
            return StandInAPI.Dialect.google.reply(text: "Fitted the view.")
        }
        defer { server.stop() }

        let app = launch(server: server)
        openPanel(app)
        let input = app.textFields["AssistantInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("Fit the view")
        app.buttons["AssistantSend"].tap()

        let finished = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Fitted the view")).firstMatch
        XCTAssertTrue(finished.waitForExistence(timeout: 30), "the request went through on the second form")
        XCTAssertEqual(server.requestCount, 3)
        XCTAssertFalse(app.staticTexts["AssistantProblem"].exists, "the person never sees the refused first form")
        let declaration = (((server.lastRequest?["tools"] as? [[String: Any]])?.first)?["functionDeclarations"] as? [[String: Any]])?.first
        let args = ((declaration?["parameters"] as? [String: Any])?["properties"] as? [String: Any])?["args"] as? [String: Any]
        XCTAssertEqual(args?["type"] as? String, "string", "args is declared as text from then on")
        let answer = StandInAPI.json(StandInAPI.Dialect.google.toolResults(in: server.lastRequest ?? [:]).last ?? "")
        XCTAssertEqual(answer["ran"] as? Bool, true, "the call written as text ran")
    }
}

// MARK: - A stand-in for a provider's API

/// A tiny HTTP server on the loopback interface that answers a POST with a
/// scripted streaming reply in one provider's shape, and records every way a
/// request breaks that provider's rules.
final class StandInAPI: @unchecked Sendable {

    enum Response {
        case events([[String: Any]])
        case failure(status: Int, body: String)
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "stand-in-api")
    private let lock = NSLock()
    private var received: [[String: Any]] = []
    private var found: [String] = []
    private let script: ([String: Any], Int) -> Response
    let dialect: Dialect
    private(set) var port: UInt16 = 0

    var requestCount: Int { lock.lock(); defer { lock.unlock() }; return received.count }
    var lastRequest: [String: Any]? { lock.lock(); defer { lock.unlock() }; return received.last }
    var problems: [String] { lock.lock(); defer { lock.unlock() }; return found }

    init(_ dialect: Dialect, script: @escaping ([String: Any], Int) -> Response) throws {
        self.dialect = dialect
        self.script = script
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback
        listener = try NWListener(using: parameters, on: .any)
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state { ready.signal() }
            if case .failed = state { ready.signal() }
        }
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            connection.start(queue: self.queue)
            self.read(connection, buffer: Data())
        }
        listener.start(queue: queue)
        _ = ready.wait(timeout: .now() + 5)
        port = listener.port?.rawValue ?? 0
    }

    func stop() { listener.cancel() }

    private func read(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buffer = buffer
            if let data { buffer.append(data) }
            if let request = Self.parse(buffer) {
                self.answer(request, on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                self.read(connection, buffer: buffer)
            }
        }
    }

    /// Headers and JSON body once the whole request has arrived.
    private static func parse(_ buffer: Data) -> (headers: [String: String], body: [String: Any])? {
        guard let split = buffer.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: buffer[..<split.lowerBound], as: UTF8.self)
        var headers: [String: String] = [:]
        for line in head.components(separatedBy: "\r\n").dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[line[..<colon].lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        let length = Int(headers["content-length"] ?? "") ?? 0
        let body = buffer[split.upperBound...]
        guard body.count >= length else { return nil }
        let object = (try? JSONSerialization.jsonObject(with: body.prefix(length))) as? [String: Any] ?? [:]
        return (headers, object)
    }

    private func answer(_ request: (headers: [String: String], body: [String: Any]), on connection: NWConnection) {
        lock.lock()
        let index = received.count
        received.append(request.body)
        found.append(contentsOf: dialect.violations(headers: request.headers, body: request.body)
            .map { "request \(index + 1): \($0)" })
        lock.unlock()

        var out = Data()
        switch script(request.body, index) {
        case .events(let events):
            out.append(Data("HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nConnection: close\r\n\r\n".utf8))
            for event in events {
                let payload = String(decoding: (try? JSONSerialization.data(withJSONObject: event)) ?? Data(), as: UTF8.self)
                // Claude and OpenAI name each event; Gemini sends data lines only.
                if dialect != .google, let type = event["type"] as? String { out.append(Data("event: \(type)\n".utf8)) }
                out.append(Data("data: \(payload)\n\n".utf8))
            }
        case let .failure(status, body):
            out.append(Data("HTTP/1.1 \(status) Error\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)".utf8))
        }
        connection.send(content: out, completion: .contentProcessed { _ in connection.cancel() })
    }

    static func json(_ text: String) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] ?? [:]
    }

    static func string(_ object: Any) -> String {
        String(decoding: (try? JSONSerialization.data(withJSONObject: object)) ?? Data(), as: UTF8.self)
    }
}

// MARK: - Each provider's shape

extension StandInAPI {

    enum Dialect: String {
        case anthropic, openai, google

        var company: String {
            switch self {
            case .anthropic: return "Anthropic"
            case .openai: return "OpenAI"
            case .google: return "Google"
            }
        }

        // MARK: Reading a request

        /// The text of every tool answer so far, in order.
        func toolResults(in request: [String: Any]) -> [String] {
            var out: [String] = []
            switch self {
            case .anthropic:
                for message in request["messages"] as? [[String: Any]] ?? [] where message["role"] as? String == "user" {
                    for block in message["content"] as? [[String: Any]] ?? [] where block["type"] as? String == "tool_result" {
                        out.append((block["content"] as? [[String: Any]] ?? []).compactMap { $0["text"] as? String }.joined())
                    }
                }
            case .openai:
                for item in request["input"] as? [[String: Any]] ?? [] where item["type"] as? String == "function_call_output" {
                    if let text = item["output"] as? String {
                        out.append(text)
                    } else {
                        out.append((item["output"] as? [[String: Any]] ?? []).compactMap { $0["text"] as? String }.joined())
                    }
                }
            case .google:
                for content in request["contents"] as? [[String: Any]] ?? [] {
                    for part in content["parts"] as? [[String: Any]] ?? [] {
                        guard let response = (part["functionResponse"] as? [String: Any])?["response"] as? [String: Any] else { continue }
                        // A JSON answer is the object itself; other text is under "result" or "error".
                        if let text = response["result"] as? String ?? response["error"] as? String, response.count == 1 {
                            out.append(text)
                        } else {
                            out.append(StandInAPI.string(response))
                        }
                    }
                }
            }
            return out
        }

        /// Whether the opaque piece of model state the first reply carried
        /// came back in a later request, untouched.
        func sentBackMarker(_ marker: String, in request: [String: Any]) -> Bool {
            switch self {
            case .anthropic:
                let messages = request["messages"] as? [[String: Any]] ?? []
                let first = (messages.first { $0["role"] as? String == "assistant" }?["content"] as? [[String: Any]])?.first
                return first?["type"] as? String == "thinking" && first?["signature"] as? String == marker
            case .openai:
                return (request["input"] as? [[String: Any]] ?? []).contains {
                    $0["type"] as? String == "reasoning" && $0["encrypted_content"] as? String == marker
                }
            case .google:
                return (request["contents"] as? [[String: Any]] ?? []).contains { content in
                    (content["parts"] as? [[String: Any]] ?? []).contains {
                        $0["functionCall"] != nil && $0["thoughtSignature"] as? String == marker
                    }
                }
            }
        }

        // MARK: Writing a reply

        /// A streamed reply: optional model state that must come back
        /// unchanged (`marker`), optional text in two pieces, and optionally
        /// one tool call.
        func reply(marker: String? = nil, text: String? = nil, call: (id: String, input: [String: Any])? = nil) -> Response {
            func halves(_ text: String) -> [String] {
                let middle = text.index(text.startIndex, offsetBy: text.count / 2)
                return [String(text[..<middle]), String(text[middle...])]
            }
            switch self {
            case .anthropic:
                var events: [[String: Any]] = [[
                    "type": "message_start",
                    "message": ["id": "msg_test", "type": "message", "role": "assistant", "model": "claude-opus-5-5",
                                "content": [Any](), "usage": ["input_tokens": 100, "output_tokens": 1]],
                ]]
                var index = 0
                if let marker {
                    events.append(["type": "content_block_start", "index": index,
                                   "content_block": ["type": "thinking", "thinking": "", "signature": ""]])
                    events.append(["type": "content_block_delta", "index": index,
                                   "delta": ["type": "signature_delta", "signature": marker]])
                    events.append(["type": "content_block_stop", "index": index])
                    index += 1
                }
                if let text {
                    events.append(["type": "content_block_start", "index": index, "content_block": ["type": "text", "text": ""]])
                    for piece in halves(text) {
                        events.append(["type": "content_block_delta", "index": index, "delta": ["type": "text_delta", "text": piece]])
                    }
                    events.append(["type": "content_block_stop", "index": index])
                    index += 1
                }
                if let call {
                    events.append(["type": "content_block_start", "index": index,
                                   "content_block": ["type": "tool_use", "id": call.id, "name": "os3d", "input": [String: Any]()]])
                    for piece in halves(StandInAPI.string(call.input)) {
                        events.append(["type": "content_block_delta", "index": index,
                                       "delta": ["type": "input_json_delta", "partial_json": piece]])
                    }
                    events.append(["type": "content_block_stop", "index": index])
                }
                events.append(["type": "ping"])
                events.append(["type": "message_delta", "delta": ["stop_reason": call == nil ? "end_turn" : "tool_use"],
                               "usage": ["output_tokens": 25]])
                events.append(["type": "message_stop"])
                return .events(events)

            case .openai:
                var output: [[String: Any]] = []
                var events: [[String: Any]] = [["type": "response.created", "response": ["id": "resp_test", "status": "in_progress"]]]
                if let marker {
                    let item: [String: Any] = ["id": "rs_test", "type": "reasoning", "summary": [Any](), "encrypted_content": marker]
                    events.append(["type": "response.output_item.added", "item": ["id": "rs_test", "type": "reasoning"]])
                    events.append(["type": "response.output_item.done", "item": item])
                    output.append(item)
                }
                if let text {
                    let item: [String: Any] = ["id": "msg_test", "type": "message", "role": "assistant", "status": "completed",
                                               "content": [["type": "output_text", "text": text, "annotations": [Any]()]]]
                    events.append(["type": "response.output_item.added", "item": ["id": "msg_test", "type": "message"]])
                    for piece in halves(text) { events.append(["type": "response.output_text.delta", "delta": piece]) }
                    events.append(["type": "response.output_item.done", "item": item])
                    output.append(item)
                }
                if let call {
                    let arguments = StandInAPI.string(call.input)
                    let item: [String: Any] = ["id": "fc_" + call.id, "type": "function_call", "call_id": call.id,
                                               "name": "os3d", "arguments": arguments, "status": "completed"]
                    events.append(["type": "response.output_item.added",
                                   "item": ["id": "fc_" + call.id, "type": "function_call", "call_id": call.id, "name": "os3d", "arguments": ""]])
                    for piece in halves(arguments) { events.append(["type": "response.function_call_arguments.delta", "delta": piece]) }
                    events.append(["type": "response.output_item.done", "item": item])
                    output.append(item)
                }
                events.append(["type": "response.completed",
                               "response": ["id": "resp_test", "status": "completed", "output": output,
                                            "usage": ["input_tokens": 100, "output_tokens": 25, "total_tokens": 125]]])
                return .events(events)

            case .google:
                var chunks: [[String: Any]] = []
                func chunk(_ parts: [[String: Any]], finish: String? = nil) -> [String: Any] {
                    var candidate: [String: Any] = ["content": ["role": "model", "parts": parts], "index": 0]
                    if let finish { candidate["finishReason"] = finish }
                    var out: [String: Any] = ["candidates": [candidate], "modelVersion": "gemini-4-hydrogen"]
                    if finish != nil { out["usageMetadata"] = ["promptTokenCount": 100, "candidatesTokenCount": 25, "totalTokenCount": 125] }
                    return out
                }
                if let text { for piece in halves(text) { chunks.append(chunk([["text": piece]])) } }
                if let call {
                    var part: [String: Any] = ["functionCall": ["name": "os3d", "id": call.id, "args": call.input]]
                    if let marker { part["thoughtSignature"] = marker }
                    chunks.append(chunk([part]))
                }
                chunks.append(chunk([], finish: "STOP"))
                return .events(chunks)
            }
        }

        // MARK: The provider's rules, as far as this app can break them

        func violations(headers: [String: String], body: [String: Any]) -> [String] {
            var out: [String] = []
            switch self {
            case .anthropic:
                if (headers["x-api-key"] ?? "").isEmpty { out.append("no x-api-key header") }
                if headers["anthropic-version"] != "2026-10-21" { out.append("anthropic-version is \(headers["anthropic-version"] ?? "missing")") }
                if body["stream"] as? Bool != true { out.append("not a streaming request") }
                if (body["model"] as? String ?? "").isEmpty { out.append("no model") }
                if (body["max_tokens"] as? Int ?? 0) <= 0 { out.append("no max_tokens") }
                let tools = body["tools"] as? [[String: Any]] ?? []
                if tools.count != 1 || tools.first?["input_schema"] == nil { out.append("the tool list is wrong") }
                if (body["system"] as? [[String: Any]])?.first?["text"] as? String == nil { out.append("no system prompt") }

                let messages = body["messages"] as? [[String: Any]] ?? []
                if messages.first?["role"] as? String != "user" { out.append("the first message is not the user's") }
                var pending: Set<String> = []
                for (index, message) in messages.enumerated() {
                    let role = message["role"] as? String ?? ""
                    if index > 0, messages[index - 1]["role"] as? String == role { out.append("two \(role) messages in a row at \(index)") }
                    let content = message["content"] as? [[String: Any]] ?? []
                    if content.isEmpty { out.append("message \(index) is empty") }
                    if role == "user" {
                        let answered = Set(content.compactMap { $0["type"] as? String == "tool_result" ? $0["tool_use_id"] as? String : nil })
                        if answered != pending { out.append("message \(index) answers \(answered.sorted()) but \(pending.sorted()) were called") }
                        pending = []
                    } else {
                        for block in content {
                            switch block["type"] as? String {
                            case "tool_use":
                                if let id = block["id"] as? String { pending.insert(id) }
                                if !(block["input"] is [String: Any]) { out.append("a tool call's input is not an object") }
                                if block.keys.contains(where: { $0.hasPrefix("_") }) { out.append("a private marker was sent") }
                            case "text":
                                if (block["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    out.append("an empty text block was sent back")
                                }
                            default: break
                            }
                        }
                    }
                }
                if !pending.isEmpty { out.append("the last tool calls were never answered") }

            case .openai:
                if !(headers["authorization"] ?? "").hasPrefix("Bearer ") { out.append("no bearer key") }
                if body["stream"] as? Bool != true { out.append("not a streaming request") }
                if body["store"] as? Bool != false { out.append("store is not off") }
                if (body["model"] as? String ?? "").isEmpty { out.append("no model") }
                if (body["instructions"] as? String ?? "").isEmpty { out.append("no instructions") }
                let tools = body["tools"] as? [[String: Any]] ?? []
                if tools.count != 1 || tools.first?["type"] as? String != "function" || tools.first?["parameters"] == nil {
                    out.append("the tool list is wrong")
                }
                let input = body["input"] as? [[String: Any]] ?? []
                if input.first?["role"] as? String != "user" { out.append("the first item is not the user's") }
                var pending: [String] = []
                for item in input {
                    switch item["type"] as? String {
                    case "function_call":
                        if !(item["arguments"] is String) { out.append("a call's arguments are not a string") }
                        pending.append(item["call_id"] as? String ?? "")
                    case "function_call_output":
                        let id = item["call_id"] as? String ?? ""
                        if let at = pending.firstIndex(of: id) { pending.remove(at: at) } else { out.append("an answer to \(id), which was not called") }
                        if !(item["output"] is String) && !(item["output"] is [[String: Any]]) { out.append("an answer is neither text nor parts") }
                    default: break
                    }
                }
                if !pending.isEmpty { out.append("calls \(pending) were never answered") }

            case .google:
                if (headers["x-goog-api-key"] ?? "").isEmpty { out.append("no x-goog-api-key header") }
                if (((body["systemInstruction"] as? [String: Any])?["parts"] as? [[String: Any]])?.first)?["text"] as? String == nil {
                    out.append("no system instruction")
                }
                let declarations = ((body["tools"] as? [[String: Any]])?.first)?["functionDeclarations"] as? [[String: Any]] ?? []
                if declarations.count != 1 || (declarations[0]["parametersJsonSchema"] == nil && declarations[0]["parameters"] == nil) {
                    out.append("the tool list is wrong")
                }
                let contents = body["contents"] as? [[String: Any]] ?? []
                if contents.first?["role"] as? String != "user" { out.append("the first message is not the user's") }
                var owed = 0
                for (index, content) in contents.enumerated() {
                    let role = content["role"] as? String ?? ""
                    let parts = content["parts"] as? [[String: Any]] ?? []
                    if role != "user" && role != "model" { out.append("message \(index) has role \(role)") }
                    if parts.isEmpty { out.append("message \(index) is empty") }
                    if role == "model" {
                        if owed > 0 { out.append("calls before message \(index) were never answered") }
                        owed = parts.filter { $0["functionCall"] != nil }.count
                    } else {
                        let answers = parts.filter { $0["functionResponse"] != nil }
                        if owed > 0 {
                            // Every call of the reply is answered in the very next message, together.
                            if answers.count != owed { out.append("message \(index) answers \(answers.count) of \(owed) calls") }
                            if answers.count != parts.count { out.append("message \(index) mixes tool answers with other parts") }
                            owed = 0
                        } else if !answers.isEmpty {
                            out.append("message \(index) answers a call that was not made")
                        }
                        for answer in answers where !((answer["functionResponse"] as? [String: Any])?["response"] is [String: Any]) {
                            out.append("a tool answer's response is not an object")
                        }
                    }
                }
                if owed > 0 { out.append("the last tool calls were never answered") }
            }
            return out
        }
    }
}
