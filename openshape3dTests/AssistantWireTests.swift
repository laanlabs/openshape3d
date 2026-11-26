//
//  AssistantWireTests.swift
//  openshape3dTests
//
//  The built-in assistant's wire layer as pure values (#119): the request
//  it sends, a streamed reply put back together, what goes back into the
//  conversation, tool answers, and the wording of failures. No network and
//  no editor.
//

import XCTest
@testable import openshape3d

final class AssistantWireTests: XCTestCase {

    private let mcpTools: [[String: Any]] = [[
        "name": "os3d", "title": "OpenShape 3D", "description": "Everything goes through this tool.",
        "inputSchema": ["type": "object", "properties": ["op": ["type": "string"]], "required": ["op"]],
    ]]

    private func json(_ object: [String: Any]) -> String {
        String(decoding: try! JSONSerialization.data(withJSONObject: object), as: UTF8.self)
    }

    private func stream(_ events: [[String: Any]]) -> AnthropicStream {
        var stream = AnthropicStream()
        for event in events { _ = stream.consume(data: json(event)) }
        return stream
    }

    // MARK: Request

    func testToolsAreTheMCPToolInMessagesSpelling() {
        let tools = AnthropicWire.tools(fromMCP: mcpTools + [["name": "other", "description": "x", "inputSchema": [:]]])
        XCTAssertEqual(tools.count, 1, "only the one listed tool is offered")
        XCTAssertEqual(tools[0]["name"] as? String, "os3d")
        XCTAssertNotNil(tools[0]["input_schema"] as? [String: Any])
        XCTAssertNil(tools[0]["inputSchema"], "the MCP spelling is not sent")
        XCTAssertNil(tools[0]["title"])
        XCTAssertEqual(tools[0]["eager_input_streaming"] as? Bool, true)
    }

    func testTheBundledToolListYieldsTheTool() {
        let tools = AnthropicWire.tools(fromMCP: AgentMCP.tools)
        XCTAssertEqual(tools.count, 1)
        XCTAssertFalse((tools.first?["description"] as? String ?? "").isEmpty)
    }

    func testRequestBody() {
        let model = AnthropicWire.model("claude-opus-5-5")
        let body = AnthropicWire.requestBody(model: model, system: "SYS", tools: AnthropicWire.tools(fromMCP: mcpTools),
                                             messages: [AnthropicWire.userMessage(text: "a cube")], retryDeclines: true)
        XCTAssertEqual(body["model"] as? String, "claude-opus-5-5")
        XCTAssertEqual(body["stream"] as? Bool, true)
        XCTAssertEqual(body["max_tokens"] as? Int, 64_000)
        XCTAssertEqual((body["thinking"] as? [String: Any])?["type"] as? String, "adaptive")
        XCTAssertEqual((body["output_config"] as? [String: Any])?["effort"] as? String, "high")
        XCTAssertEqual(body["fallbacks"] as? String, "default")
        let system = body["system"] as? [[String: Any]]
        XCTAssertEqual(system?.first?["text"] as? String, "SYS")
        XCTAssertNotNil(system?.first?["cache_control"], "the guide is a cache read after the first request")
        XCTAssertNotNil(body["cache_control"], "the growing conversation is cached too")
        // Sampling parameters and a thinking budget are refused by these models.
        for refused in ["temperature", "top_p", "top_k", "tool_choice"] { XCTAssertNil(body[refused]) }
        XCTAssertNil((body["thinking"] as? [String: Any])?["budget_tokens"])
    }

    func testDeclineRetryIsLeftOutWhereItCannotBeUsed() {
        let haiku = AnthropicWire.model("claude-haiku-5-5")
        let body = AnthropicWire.requestBody(model: haiku, system: "", tools: [], messages: [], retryDeclines: true)
        XCTAssertNil(body["fallbacks"], "Claude Haiku 5.5 has no server-side retry")
        XCTAssertNil(AnthropicWire.headers(apiKey: "k", model: haiku, retryDeclines: true)["anthropic-beta"])

        let opus = AnthropicWire.model("claude-opus-5-5")
        let off = AnthropicWire.requestBody(model: opus, system: "", tools: [], messages: [], retryDeclines: false)
        XCTAssertNil(off["fallbacks"])
        XCTAssertNil(AnthropicWire.headers(apiKey: "k", model: opus, retryDeclines: false)["anthropic-beta"])
        XCTAssertEqual(AnthropicWire.headers(apiKey: "k", model: opus, retryDeclines: true)["anthropic-beta"],
                       "server-side-fallback-2026-07-01")
    }

    func testHeadersCarryTheKeyOnlyAsXAPIKey() {
        let headers = AnthropicWire.headers(apiKey: "sk-ant-test", model: AnthropicWire.models[0], retryDeclines: false)
        XCTAssertEqual(headers["x-api-key"], "sk-ant-test")
        XCTAssertEqual(headers["anthropic-version"], "2026-10-21")
        XCTAssertNil(headers["authorization"])
        XCTAssertEqual(AnthropicWire.endpoint.host, "api.anthropic.com")
        XCTAssertEqual(AnthropicWire.endpoint.scheme, "https")
    }

    func testEncodingIsStableSoTheCacheKeepsHitting() {
        let body: [String: Any] = ["b": 1, "a": ["z": 1, "y": 2], "c": "x"]
        XCTAssertEqual(AnthropicWire.encode(body), AnthropicWire.encode(body))
        XCTAssertEqual(String(decoding: AnthropicWire.encode(body), as: UTF8.self), #"{"a":{"y":2,"z":1},"b":1,"c":"x"}"#)
    }

    func testAnUnknownModelFallsBackToTheDefault() {
        XCTAssertEqual(AnthropicWire.model("claude-nothing").id, AnthropicWire.defaultModelID)
        XCTAssertEqual(AnthropicWire.models.first?.id, AnthropicWire.defaultModelID)
    }

    func testTheSystemPromptCarriesTheGuide() {
        let prompt = AnthropicWire.systemPrompt(guide: "GUIDE-TEXT-HERE")
        XCTAssertTrue(prompt.hasSuffix("\n\nGUIDE-TEXT-HERE"))
        XCTAssertTrue(prompt.hasPrefix("You are the assistant built into OpenShape 3D, a CAD app"),
                      "the preamble is the bundled AssistantPrompt.md")
        XCTAssertTrue(prompt.contains("os3d"))
        XCTAssertTrue(prompt.contains("document.export"))
    }

    // MARK: Conversation

    func testUserTextJoinsAPendingUserMessageSoRolesAlternate() {
        var messages: [[String: Any]] = []
        AnthropicWire.appendUserText("one", to: &messages)
        AnthropicWire.appendUserText("two", to: &messages)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual((messages[0]["content"] as? [[String: Any]])?.count, 2)

        messages.append(["role": "assistant", "content": [["type": "text", "text": "ok"]]])
        AnthropicWire.appendUserText("three", to: &messages)
        XCTAssertEqual(messages.map { $0["role"] as? String }, ["user", "assistant", "user"])

        // After tool answers the text follows them in the same message.
        var loop: [[String: Any]] = [["role": "user", "content": [
            AnthropicWire.toolResult(id: "t1", content: [.text("done")], isError: false)]]]
        AnthropicWire.appendUserText("and now a hole", to: &loop)
        let content = loop[0]["content"] as? [[String: Any]] ?? []
        XCTAssertEqual(content.map { $0["type"] as? String }, ["tool_result", "text"])
    }

    // MARK: Stream

    private var textAndToolEvents: [[String: Any]] {
        [
            ["type": "message_start", "message": ["model": "claude-opus-5-5",
                                                  "usage": ["input_tokens": 12, "cache_read_input_tokens": 900]]],
            ["type": "content_block_start", "index": 0,
             "content_block": ["type": "thinking", "thinking": "", "signature": ""]],
            ["type": "content_block_delta", "index": 0, "delta": ["type": "signature_delta", "signature": "SIG"]],
            ["type": "content_block_stop", "index": 0],
            ["type": "content_block_start", "index": 1, "content_block": ["type": "text", "text": ""]],
            ["type": "content_block_delta", "index": 1, "delta": ["type": "text_delta", "text": "Building "]],
            ["type": "content_block_delta", "index": 1, "delta": ["type": "text_delta", "text": "a cube."]],
            ["type": "content_block_stop", "index": 1],
            ["type": "content_block_start", "index": 2,
             "content_block": ["type": "tool_use", "id": "toolu_1", "name": "os3d", "input": [String: Any]()]],
            ["type": "content_block_delta", "index": 2,
             "delta": ["type": "input_json_delta", "partial_json": "{\"op\":\"sketch.create\","]],
            ["type": "content_block_delta", "index": 2,
             "delta": ["type": "input_json_delta", "partial_json": "\"args\":{\"plane\":\"xz\"}}"]],
            ["type": "content_block_stop", "index": 2],
            ["type": "message_delta", "delta": ["stop_reason": "tool_use"], "usage": ["output_tokens": 40]],
            ["type": "message_stop"],
        ]
    }

    func testAStreamedReplyIsPutBackTogether() {
        let reply = stream(textAndToolEvents)
        XCTAssertEqual(reply.stopReason, "tool_use")
        XCTAssertEqual(reply.model, "claude-opus-5-5")
        XCTAssertEqual(reply.inputTokens, 12)
        XCTAssertEqual(reply.cacheReadTokens, 900)
        XCTAssertEqual(reply.outputTokens, 40)
        XCTAssertFalse(reply.endedMidReply)
        XCTAssertNil(reply.failure)

        let content = reply.content
        XCTAssertEqual(content.map { $0["type"] as? String }, ["thinking", "text", "tool_use"])
        XCTAssertEqual(content[0]["signature"] as? String, "SIG", "a thinking block goes back with its signature")
        XCTAssertEqual(content[0]["thinking"] as? String, "")
        XCTAssertEqual(content[1]["text"] as? String, "Building a cube.")
        let input = content[2]["input"] as? [String: Any]
        XCTAssertEqual(input?["op"] as? String, "sketch.create")
        XCTAssertEqual((input?["args"] as? [String: Any])?["plane"] as? String, "xz")
    }

    func testStreamUpdatesSayWhatToShow() {
        var stream = AnthropicStream()
        var updates: [AnthropicStream.Update] = []
        for event in textAndToolEvents { updates.append(stream.consume(data: json(event))) }
        XCTAssertTrue(updates.contains(.thinking))
        XCTAssertTrue(updates.contains(.text("Building ")))
        XCTAssertTrue(updates.contains(.text("a cube.")))
        XCTAssertTrue(updates.contains(.toolStarted(name: "os3d")))
        XCTAssertEqual(stream.consume(data: "not json"), .nothing)
        XCTAssertEqual(stream.consume(data: json(["type": "ping"])), .nothing)
        XCTAssertEqual(stream.consume(data: json(["type": "something_new", "index": 9])), .nothing)
    }

    func testACallWithNoArgumentsGetsAnEmptyInput() {
        let reply = stream([
            ["type": "content_block_start", "index": 0,
             "content_block": ["type": "tool_use", "id": "t", "name": "os3d", "input": [String: Any]()]],
            ["type": "content_block_stop", "index": 0],
            ["type": "message_delta", "delta": ["stop_reason": "tool_use"]],
            ["type": "message_stop"],
        ])
        let calls = AnthropicWire.toolCalls(in: reply.content)
        XCTAssertEqual(calls.count, 1)
        XCTAssertNil(calls[0].invalidInput)
        XCTAssertNotNil(calls[0].problem, "no op: refused by the check, not by a crash")
    }

    func testUnparseableToolInputIsRefusedAndNeverRun() {
        let reply = stream([
            ["type": "content_block_start", "index": 0,
             "content_block": ["type": "tool_use", "id": "t9", "name": "os3d", "input": [String: Any]()]],
            ["type": "content_block_delta", "index": 0,
             "delta": ["type": "input_json_delta", "partial_json": "{\"op\":\"feature.extrude\",\"args\":{\"dist"]],
            ["type": "content_block_stop", "index": 0],
            ["type": "message_delta", "delta": ["stop_reason": "tool_use"]],
            ["type": "message_stop"],
        ])
        let calls = AnthropicWire.toolCalls(in: reply.content)
        XCTAssertEqual(calls.first?.invalidInput, "{\"op\":\"feature.extrude\",\"args\":{\"dist")
        let problem = calls.first?.problem ?? ""
        XCTAssertTrue(problem.contains("INVALID_JSON"))
        XCTAssertNotNil(try? JSONSerialization.jsonObject(with: Data(problem.utf8)), "the wrapper itself is valid JSON")

        // What goes back to the API has an object for input and no private marker.
        let sent = AnthropicStream.sendable(AnthropicWire.echo(reply.content))
        XCTAssertNil(sent[0][AnthropicStream.invalidInputKey])
        XCTAssertNotNil(sent[0]["input"] as? [String: Any])
        XCTAssertTrue(JSONSerialization.isValidJSONObject(sent))
    }

    func testToolCallChecks() {
        func call(_ name: String, _ input: [String: Any]) -> AnthropicWire.ToolCall {
            AnthropicWire.ToolCall(id: "t", name: name, input: input, invalidInput: nil)
        }
        XCTAssertNil(call("os3d", ["op": "state"]).problem)
        XCTAssertNil(call("os3d", ["op": "faces", "args": ["body": "b1"]]).problem)
        XCTAssertNotNil(call("os3d", [:]).problem)
        XCTAssertNotNil(call("os3d", ["op": ""]).problem)
        XCTAssertNotNil(call("os3d", ["op": 3]).problem)
        XCTAssertNotNil(call("os3d", ["op": "faces", "args": "b1"]).problem, "args must be an object")
        XCTAssertNotNil(call("bash", ["op": "state"]).problem, "there is no other tool")
    }

    func testAnErrorEventAndAnUnfinishedStreamAreNoticed() {
        var broken = AnthropicStream()
        let update = broken.consume(data: json(["type": "error",
                                                "error": ["type": "overloaded_error", "message": "Overloaded"]]))
        XCTAssertEqual(update, .failed("Overloaded"))
        XCTAssertEqual(broken.failure, "Overloaded")

        let cut = stream([
            ["type": "content_block_start", "index": 0, "content_block": ["type": "text", "text": ""]],
            ["type": "content_block_delta", "index": 0, "delta": ["type": "text_delta", "text": "Half a"]],
        ])
        XCTAssertTrue(cut.endedMidReply, "no message_stop: the reply is not trusted")
        XCTAssertFalse(cut.isEmpty)
        XCTAssertTrue(AnthropicStream().isEmpty)
    }

    func testARefusalCarriesItsCategory() {
        let reply = stream([
            ["type": "message_delta", "delta": ["stop_reason": "refusal", "stop_details": ["type": "refusal", "category": "cyber"]]],
            ["type": "message_stop"],
        ])
        XCTAssertEqual(reply.stopReason, "refusal")
        XCTAssertEqual(reply.stopCategory, "cyber")
    }

    // MARK: Echo

    func testEmptyTextBlocksAreNotSentBack() {
        let blocks: [[String: Any]] = [
            ["type": "text", "text": ""], ["type": "text", "text": "  \n"],
            ["type": "thinking", "thinking": "", "signature": "S"], ["type": "text", "text": "Done."],
        ]
        let echoed = AnthropicWire.echo(blocks)
        XCTAssertEqual(echoed.map { $0["type"] as? String }, ["thinking", "text"])
        XCTAssertEqual(echoed[0]["signature"] as? String, "S", "an empty thinking block is kept: its signature matters")
    }

    func testAfterAModelSwitchTheFirstModelsThinkingAndCallsAreLeftOut() {
        let blocks: [[String: Any]] = [
            ["type": "thinking", "thinking": "", "signature": "A"],
            ["type": "text", "text": "Starting."],
            ["type": "tool_use", "id": "old", "name": "os3d", "input": ["op": "state"]],
            ["type": "fallback", "from": ["model": "claude-opus-5-5"], "to": ["model": "claude-opus-5"]],
            ["type": "thinking", "thinking": "", "signature": "B"],
            ["type": "tool_use", "id": "new", "name": "os3d", "input": ["op": "state"]],
        ]
        let echoed = AnthropicWire.echo(blocks)
        XCTAssertEqual(echoed.map { $0["type"] as? String }, ["text", "fallback", "thinking", "tool_use"])
        XCTAssertEqual(echoed[2]["signature"] as? String, "B")
        XCTAssertEqual(AnthropicWire.toolCalls(in: blocks).map(\.id), ["new"], "the replaced model's call does not run")

        var stream = AnthropicStream()
        let update = stream.consume(data: json(["type": "content_block_start", "index": 0, "content_block": blocks[3]]))
        XCTAssertEqual(update, .switchedModel("claude-opus-5"))
    }

    // MARK: Tool answers

    func testAnMCPReplyBecomesToolContent() {
        let ok = AgentMCP.rpcResult(id: .number(1), AgentMCP.toolText("{\"ok\":true}", isError: false))
        let (content, isError) = AnthropicWire.toolContent(fromMCPReply: ok.body)
        XCTAssertEqual(content, [.text("{\"ok\":true}")])
        XCTAssertFalse(isError)

        let failed = AgentMCP.rpcResult(id: .number(1), AgentMCP.toolText("no such body", isError: true))
        XCTAssertTrue(AnthropicWire.toolContent(fromMCPReply: failed.body).isError)

        let image = AgentMCP.rpcResult(id: .number(1), ["content": [["type": "image", "mimeType": "image/jpeg", "data": "QUJD"]]])
        XCTAssertEqual(AnthropicWire.toolContent(fromMCPReply: image.body).content,
                       [.image(mediaType: "image/jpeg", base64: "QUJD")])

        let refused = AgentMCP.rpcError(id: .number(1), code: -32601, message: "Method not found")
        let refusal = AnthropicWire.toolContent(fromMCPReply: refused.body)
        XCTAssertEqual(refusal.content, [.text("Method not found")])
        XCTAssertTrue(refusal.isError)

        XCTAssertTrue(AnthropicWire.toolContent(fromMCPReply: Data("junk".utf8)).isError)
    }

    func testAVeryLongAnswerIsCutWithANoteTheModelCanRead() {
        let long = String(repeating: "x", count: AnthropicWire.maxResultCharacters + 500)
        let reply = AgentMCP.rpcResult(id: .number(1), AgentMCP.toolText(long, isError: false))
        guard case .text(let text)? = AnthropicWire.toolContent(fromMCPReply: reply.body).content.first else {
            return XCTFail("expected text")
        }
        XCTAssertTrue(text.contains("500 more characters"))
        XCTAssertLessThan(text.count, long.count)
    }

    func testToolResultBlock() {
        let block = AnthropicWire.toolResult(id: "toolu_1", content: [.text("ok"), .image(mediaType: "image/jpeg", base64: "QUJD")],
                                             isError: false)
        XCTAssertEqual(block["type"] as? String, "tool_result")
        XCTAssertEqual(block["tool_use_id"] as? String, "toolu_1")
        XCTAssertNil(block["is_error"])
        let content = block["content"] as? [[String: Any]] ?? []
        XCTAssertEqual(content[0]["text"] as? String, "ok")
        let source = content[1]["source"] as? [String: Any]
        XCTAssertEqual(source?["type"] as? String, "base64")
        XCTAssertEqual(source?["media_type"] as? String, "image/jpeg")
        XCTAssertEqual(source?["data"] as? String, "QUJD")

        let failed = AnthropicWire.toolResult(id: "t", content: [.text("")], isError: true)
        XCTAssertEqual(failed["is_error"] as? Bool, true)
        XCTAssertEqual(((failed["content"] as? [[String: Any]])?.first)?["text"] as? String, "Done.",
                       "an empty text block would be refused")
    }

    // MARK: Failures

    func testErrorWording() {
        func body(_ type: String, _ message: String) -> Data {
            Data(json(["type": "error", "error": ["type": type, "message": message]]).utf8)
        }
        XCTAssertTrue(AnthropicWire.errorMessage(status: 401, body: body("authentication_error", "invalid x-api-key"))
            .contains("did not accept this API key"))
        XCTAssertTrue(AnthropicWire.errorMessage(status: 429, body: body("rate_limit_error", "slow down")).contains("slow down"))
        XCTAssertTrue(AnthropicWire.errorMessage(status: 529, body: Data()).contains("busy"))
        XCTAssertEqual(AnthropicWire.errorMessage(status: 400, body: body("invalid_request_error", "bad thing")), "bad thing")
        XCTAssertTrue(AnthropicWire.errorMessage(status: 418, body: Data("<html>".utf8)).contains("418"))
    }

    func testWhichFailuresAreTriedAgain() {
        for status in [500, 502, 503, 504, 529] { XCTAssertTrue(AnthropicWire.isWorthRetrying(status: status)) }
        for status in [400, 401, 403, 404, 413, 429] { XCTAssertFalse(AnthropicWire.isWorthRetrying(status: status)) }
        let beta = Data(#"{"type":"error","error":{"type":"invalid_request_error","message":"Unexpected value(s) `server-side-fallback-2026-07-01` for the `anthropic-beta` header."}}"#.utf8)
        XCTAssertTrue(AnthropicWire.isAboutDeclineRetry(status: 400, body: beta))
        XCTAssertFalse(AnthropicWire.isAboutDeclineRetry(status: 401, body: beta))
        XCTAssertFalse(AnthropicWire.isAboutDeclineRetry(status: 400, body: Data(#"{"error":{"message":"max_tokens too large"}}"#.utf8)))
    }

    // MARK: Lines, keys, labels

    func testServerSentEventLines() {
        XCTAssertEqual(ServerSentEvents.dataPayload(ofLine: "data: {\"type\":\"ping\"}"), "{\"type\":\"ping\"}")
        XCTAssertEqual(ServerSentEvents.dataPayload(ofLine: "data:{\"a\":1}"), "{\"a\":1}")
        XCTAssertNil(ServerSentEvents.dataPayload(ofLine: "event: message_start"))
        XCTAssertNil(ServerSentEvents.dataPayload(ofLine: ": comment"))
        XCTAssertNil(ServerSentEvents.dataPayload(ofLine: ""))
        XCTAssertNil(ServerSentEvents.dataPayload(ofLine: "data:"))
    }

    func testAPastedKeyIsTidiedAndChecked() {
        XCTAssertEqual(AssistantKeyStore.tidy("  sk-ant-abc\n def \t"), "sk-ant-abcdef")
        XCTAssertTrue(AssistantKeyStore.isPlausible("sk-ant-" + String(repeating: "a", count: 40)))
        XCTAssertFalse(AssistantKeyStore.isPlausible("short"))
        XCTAssertFalse(AssistantKeyStore.isPlausible(String(repeating: "é", count: 40)))
        XCTAssertFalse(AssistantKeyStore.isPlausible(String(repeating: "a", count: 600)))
    }

    func testActivityLabels() {
        XCTAssertEqual(AssistantTools.label(op: "state", args: [:]), "Reading the design")
        XCTAssertEqual(AssistantTools.label(op: "feature.extrude", args: [:]), "Extrude")
        XCTAssertEqual(AssistantTools.label(op: "feature.pushPull", args: [:]), "Push pull")
        XCTAssertEqual(AssistantTools.label(op: "command.run", args: ["id": "edit.undo"]), "Undo")
        XCTAssertEqual(AssistantTools.label(op: "command.run", args: ["id": "view.front"]), "Change the view")
        XCTAssertEqual(AssistantTools.label(op: "document.export", args: ["format": "3mf"]), "Export 3MF")
        XCTAssertEqual(AssistantTools.label(op: "", args: [:]), "Working")
    }

    func testReplyFormattingKeepsPlainTextAndLineBreaks() {
        let shown = AssistantPanelView.formatted("A **40 mm** cube.\nVolume: 64 000 mm³")
        let plain = String(shown.characters)
        XCTAssertTrue(plain.contains("40 mm"))
        XCTAssertFalse(plain.contains("**"))
        XCTAssertTrue(plain.contains("\n"))
    }
}
