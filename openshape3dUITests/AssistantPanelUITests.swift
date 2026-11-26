//
//  AssistantPanelUITests.swift
//  openshape3dUITests
//
//  The built-in assistant, end to end in the live app (#119): open the panel,
//  type a request, and watch a block get built — with a stand-in for
//  Anthropic's API running inside this test, so no key and no network are
//  involved. The stand-in speaks the real streaming shape and checks what the
//  app sends it (headers, alternating roles, every tool call answered), so a
//  malformed conversation fails here and not in front of a person.
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
            app.launchEnvironment["OS3D_ASSISTANT_URL"] = "http://127.0.0.1:\(server.port)/v1/messages"
            app.launchEnvironment["OS3D_ASSISTANT_KEY"] = "test-key-not-a-real-one"
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

    // MARK: A whole build

    func testARequestBuildsABlock() throws {
        let server = try StandInAPI { request, _ in
            let results = StandInAPI.toolResults(in: request)
            switch results.count {
            case 0 where StandInAPI.turns(in: request) == 1:
                return StandInAPI.reply(thinkingSignature: "sig-one", text: "Building a 40 × 30 × 10 mm block.",
                                        call: ("call_1", ["op": "sketch.create"]))
            case 1:
                let sketch = StandInAPI.json(results[0])["sketchID"] as? String ?? ""
                return StandInAPI.reply(call: ("call_2", ["op": "sketch.addEntities", "args": [
                    "sketchID": sketch, "entities": [["kind": "rect", "min": [-20, -15], "max": [20, 15]]]]]))
            case 2:
                let sketch = StandInAPI.json(results[0])["sketchID"] as? String ?? ""
                return StandInAPI.reply(call: ("call_3", ["op": "feature.extrude", "args": [
                    "sketchID": sketch, "seedPoint": [0, 0], "distance": 10]]))
            case 3:
                return StandInAPI.reply(call: ("call_4", ["op": "state"]))
            default:
                return StandInAPI.reply(text: "Finished: one block, 40 × 30 × 10 mm.", stop: "end_turn")
            }
        }
        defer { server.stop() }

        let app = launch(server: server)
        openPanel(app)

        let input = app.textFields["AssistantInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "with a key the message box is there")
        XCTAssertTrue(app.staticTexts["AssistantFootnote"].exists, "the reminder of where messages go stays visible")
        input.tap()
        input.typeText("Make a 40 by 30 by 10 mm block")
        app.buttons["AssistantSend"].tap()

        let finished = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Finished: one block")).firstMatch
        XCTAssertTrue(finished.waitForExistence(timeout: 60), "the final reply arrives. Problems: \(server.problems)")
        keepScreenshot("assistant-built-a-block")
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
        let state = StandInAPI.json(try XCTUnwrap(StandInAPI.toolResults(in: last).last))
        let bodies = state["bodies"] as? [[String: Any]] ?? []
        XCTAssertEqual(bodies.count, 1, "one body was built")
        let volume = (bodies.first?["volumeMM3"] as? NSNumber)?.doubleValue ?? 0
        XCTAssertEqual(volume, 12_000, accuracy: 1, "40 × 30 × 10 mm")

        // What went back to the API kept the model's thinking block intact.
        let messages = last["messages"] as? [[String: Any]] ?? []
        let firstReply = (messages.first { $0["role"] as? String == "assistant" }?["content"] as? [[String: Any]]) ?? []
        XCTAssertEqual(firstReply.first?["type"] as? String, "thinking")
        XCTAssertEqual(firstReply.first?["signature"] as? String, "sig-one")

        // And the person can undo what the assistant did, like any other step.
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "the build is on the undo stack")
    }

    // MARK: A key Anthropic refuses

    func testARefusedKeyIsExplained() throws {
        let server = try StandInAPI { _, _ in
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
}

// MARK: - A stand-in for the Messages API

/// A tiny HTTP server on the loopback interface that answers `POST
/// /v1/messages` with a scripted streaming reply, and records every way a
/// request breaks the API's rules.
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
    private(set) var port: UInt16 = 0

    var requestCount: Int { lock.lock(); defer { lock.unlock() }; return received.count }
    var lastRequest: [String: Any]? { lock.lock(); defer { lock.unlock() }; return received.last }
    var problems: [String] { lock.lock(); defer { lock.unlock() }; return found }

    init(script: @escaping ([String: Any], Int) -> Response) throws {
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
        found.append(contentsOf: Self.violations(headers: request.headers, body: request.body).map { "request \(index + 1): \($0)" })
        lock.unlock()

        var out = Data()
        switch script(request.body, index) {
        case .events(let events):
            out.append(Data("HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nConnection: close\r\n\r\n".utf8))
            for event in events {
                let type = event["type"] as? String ?? "message"
                let payload = String(decoding: (try? JSONSerialization.data(withJSONObject: event)) ?? Data(), as: UTF8.self)
                out.append(Data("event: \(type)\ndata: \(payload)\n\n".utf8))
            }
        case let .failure(status, body):
            out.append(Data("HTTP/1.1 \(status) Error\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)".utf8))
        }
        connection.send(content: out, completion: .contentProcessed { _ in connection.cancel() })
    }

    // MARK: The API's rules, as far as this app can break them

    private static func violations(headers: [String: String], body: [String: Any]) -> [String] {
        var out: [String] = []
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
        return out
    }

    // MARK: Reading a request

    /// How many times the person has spoken: user messages that carry text.
    static func turns(in request: [String: Any]) -> Int {
        (request["messages"] as? [[String: Any]] ?? []).filter { message in
            message["role"] as? String == "user"
                && (message["content"] as? [[String: Any]] ?? []).contains { $0["type"] as? String == "text" }
        }.count
    }

    /// The text of every tool answer so far, in order.
    static func toolResults(in request: [String: Any]) -> [String] {
        var out: [String] = []
        for message in request["messages"] as? [[String: Any]] ?? [] where message["role"] as? String == "user" {
            for block in message["content"] as? [[String: Any]] ?? [] where block["type"] as? String == "tool_result" {
                let pieces = block["content"] as? [[String: Any]] ?? []
                out.append(pieces.compactMap { $0["text"] as? String }.joined())
            }
        }
        return out
    }

    static func json(_ text: String) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any] ?? [:]
    }

    // MARK: Writing a reply

    /// A streamed reply: an optional thinking block, optional text, and
    /// optionally one tool call whose input arrives in two pieces.
    static func reply(thinkingSignature: String? = nil, text: String? = nil,
                      call: (id: String, input: [String: Any])? = nil, stop: String? = nil) -> Response {
        var events: [[String: Any]] = [[
            "type": "message_start",
            "message": ["id": "msg_test", "type": "message", "role": "assistant", "model": "claude-opus-5-5",
                        "content": [Any](), "usage": ["input_tokens": 100, "output_tokens": 1]],
        ]]
        var index = 0
        if let thinkingSignature {
            events.append(["type": "content_block_start", "index": index,
                           "content_block": ["type": "thinking", "thinking": "", "signature": ""]])
            events.append(["type": "content_block_delta", "index": index,
                           "delta": ["type": "signature_delta", "signature": thinkingSignature]])
            events.append(["type": "content_block_stop", "index": index])
            index += 1
        }
        if let text {
            events.append(["type": "content_block_start", "index": index, "content_block": ["type": "text", "text": ""]])
            let middle = text.index(text.startIndex, offsetBy: text.count / 2)
            for piece in [String(text[..<middle]), String(text[middle...])] {
                events.append(["type": "content_block_delta", "index": index, "delta": ["type": "text_delta", "text": piece]])
            }
            events.append(["type": "content_block_stop", "index": index])
            index += 1
        }
        if let call {
            events.append(["type": "content_block_start", "index": index,
                           "content_block": ["type": "tool_use", "id": call.id, "name": "os3d", "input": [String: Any]()]])
            let input = String(decoding: (try? JSONSerialization.data(withJSONObject: call.input)) ?? Data(), as: UTF8.self)
            let middle = input.index(input.startIndex, offsetBy: input.count / 2)
            for piece in [String(input[..<middle]), String(input[middle...])] {
                events.append(["type": "content_block_delta", "index": index,
                               "delta": ["type": "input_json_delta", "partial_json": piece]])
            }
            events.append(["type": "content_block_stop", "index": index])
        }
        events.append(["type": "ping"])
        events.append(["type": "message_delta", "delta": ["stop_reason": stop ?? (call == nil ? "end_turn" : "tool_use")],
                       "usage": ["output_tokens": 25]])
        events.append(["type": "message_stop"])
        return .events(events)
    }
}
