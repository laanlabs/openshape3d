//
//  AssistantProviderTests.swift
//  openshape3dTests
//
//  The built-in assistant's other two providers, OpenAI and Gemini, and the
//  switchboard that lets one conversation loop run over all three
//  (`AssistantProvider`). Pure values: the request each sends, a streamed
//  reply put back together, how tool answers go back, the wording of
//  failures. No network and no editor. Claude's own wire is in
//  `AssistantWireTests`.
//

import XCTest
@testable import openshape3d

final class AssistantProviderTests: XCTestCase {

    private let mcpTools: [[String: Any]] = [[
        "name": "os3d", "title": "OpenShape 3D", "description": "Everything goes through this tool.",
        "inputSchema": ["type": "object",
                        "properties": ["op": ["type": "string", "description": "Operation name."],
                                       "args": ["type": "object", "description": "Arguments."]],
                        "required": ["op"]],
    ]]

    private func json(_ object: Any) -> String {
        String(decoding: try! JSONSerialization.data(withJSONObject: object), as: UTF8.self)
    }

    private func object(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    private func call(_ id: String, _ input: [String: Any], name: String = "os3d") -> AssistantToolCall {
        AssistantToolCall(id: id, name: name, input: input, invalidInput: nil)
    }

    // MARK: - The three providers

    func testEachProviderHasItsOwnNamesModelsAndKeyPage() {
        XCTAssertEqual(AssistantProvider.allCases.map(\.name), ["Claude", "ChatGPT", "Gemini"])
        XCTAssertEqual(AssistantProvider.allCases.map(\.company), ["Anthropic", "OpenAI", "Google"])
        for provider in AssistantProvider.allCases {
            XCTAssertFalse(provider.models.isEmpty)
            XCTAssertTrue(provider.models.contains { $0.id == provider.defaultModelID }, "\(provider) default is offered")
            XCTAssertEqual(Set(provider.models.map(\.id)).count, provider.models.count)
            XCTAssertEqual(provider.model("no-such-model").id, provider.defaultModelID)
            XCTAssertEqual(provider.model(nil).id, provider.defaultModelID)
            XCTAssertEqual(provider.keysPage.scheme, "https")
        }
        XCTAssertEqual(Set(AssistantProvider.allCases.map(AssistantKeyStore.account(for:))).count, 3,
                       "each provider's key is filed apart")
        XCTAssertEqual(AssistantKeyStore.account(for: .anthropic), "anthropic-api-key",
                       "a key saved before there were other providers is still found")
    }

    func testAKeyOnlyGoesToItsOwnProvider() {
        let key = "secret-key-for-the-test"
        for provider in AssistantProvider.allCases {
            let request = provider.request(apiKey: key, model: provider.model(nil), system: "SYS", mcpTools: mcpTools,
                                           conversation: [], options: AssistantRequestOptions())
            XCTAssertEqual(request.url.scheme, "https")
            XCTAssertFalse(request.url.absoluteString.contains(key), "\(provider): the key is never in the URL")
            XCTAssertFalse(String(decoding: request.body, as: UTF8.self).contains(key), "\(provider): nor in the body")
            XCTAssertEqual(request.headers.values.filter { $0.contains(key) }.count, 1, "\(provider): one header carries it")
        }
        func host(_ provider: AssistantProvider) -> String? {
            provider.request(apiKey: "k", model: provider.model(nil), system: "", mcpTools: [], conversation: [],
                             options: AssistantRequestOptions()).url.host
        }
        XCTAssertEqual(host(.anthropic), "api.anthropic.com")
        XCTAssertEqual(host(.openai), "api.openai.com")
        XCTAssertEqual(host(.google), "generativelanguage.googleapis.com")
    }

    func testEveryProviderGetsTheSameInstructionsAndTheOneTool() {
        for provider in AssistantProvider.allCases {
            let request = provider.request(apiKey: "k", model: provider.model(nil), system: "THE-SYSTEM-PROMPT",
                                           mcpTools: mcpTools, conversation: [], options: AssistantRequestOptions())
            let text = String(decoding: request.body, as: UTF8.self)
            XCTAssertTrue(text.contains("THE-SYSTEM-PROMPT"), "\(provider)")
            XCTAssertTrue(text.contains("\"os3d\""), "\(provider)")
            XCTAssertTrue(text.contains("Everything goes through this tool."), "\(provider)")
        }
    }

    // MARK: - OpenAI: request

    func testOpenAIRequest() {
        let model = AssistantProvider.openai.model("gpt-6.2-sol")
        var input: [[String: Any]] = []
        OpenAIWire.appendUserText("a cube", to: &input)
        let request = AssistantProvider.openai.request(apiKey: "sk-test", model: model, system: "SYS", mcpTools: mcpTools,
                                                       conversation: input, options: AssistantRequestOptions())
        XCTAssertEqual(request.url.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(request.headers["authorization"], "Bearer sk-test")
        let body = object(request.body)
        XCTAssertEqual(body["model"] as? String, "gpt-6.2-sol")
        XCTAssertEqual(body["instructions"] as? String, "SYS")
        XCTAssertEqual(body["stream"] as? Bool, true)
        XCTAssertEqual(body["store"] as? Bool, false, "the conversation is kept on this device")
        let tools = body["tools"] as? [[String: Any]] ?? []
        XCTAssertEqual(tools.count, 1)
        XCTAssertEqual(tools[0]["type"] as? String, "function")
        XCTAssertEqual(tools[0]["name"] as? String, "os3d")
        XCTAssertEqual(tools[0]["strict"] as? Bool, false, "args is a free-form object, which strict mode refuses")
        XCTAssertNotNil(tools[0]["parameters"] as? [String: Any])
        let first = (body["input"] as? [[String: Any]])?.first
        XCTAssertEqual(first?["role"] as? String, "user")
        XCTAssertEqual(((first?["content"] as? [[String: Any]])?.first)?["type"] as? String, "input_text")
        for unsupported in ["temperature", "top_p", "messages", "previous_response_id"] { XCTAssertNil(body[unsupported]) }
    }

    func testOpenAIConversationShapes() {
        var input: [[String: Any]] = []
        OpenAIWire.appendUserText("one", to: &input)
        OpenAIWire.appendUserText("two", to: &input)
        XCTAssertEqual(input.count, 2, "items need not alternate here")
        OpenAIWire.removePendingUserText(from: &input)
        XCTAssertEqual(input.count, 1)
        input.append(["type": "function_call_output", "call_id": "c", "output": "x"])
        OpenAIWire.removePendingUserText(from: &input)
        XCTAssertEqual(input.count, 2, "a tool answer is not taken back")
    }

    func testOpenAIToolOutputs() {
        let plain = OpenAIWire.toolOutput(callID: "call_1", content: [.text("{\"ok\":true}")], isError: false)
        XCTAssertEqual(plain["type"] as? String, "function_call_output")
        XCTAssertEqual(plain["call_id"] as? String, "call_1")
        XCTAssertEqual(plain["output"] as? String, "{\"ok\":true}")

        let failed = OpenAIWire.toolOutput(callID: "c", content: [.text("no such body")], isError: true)
        XCTAssertEqual(failed["output"] as? String, "Error: no such body", "there is no error flag, so the text says it")
        let failedJSON = OpenAIWire.toolOutput(callID: "c", content: [.text("{\"error\":\"unknown_body\"}")], isError: true)
        XCTAssertEqual(failedJSON["output"] as? String, "{\"error\":\"unknown_body\"}", "JSON that already says so is left alone")

        let picture = OpenAIWire.toolOutput(callID: "c", content: [.image(mediaType: "image/jpeg", base64: "QUJD")], isError: false)
        let parts = picture["output"] as? [[String: Any]] ?? []
        XCTAssertEqual(parts.map { $0["type"] as? String }, ["input_text", "input_image"])
        XCTAssertEqual(parts[1]["image_url"] as? String, "data:image/jpeg;base64,QUJD")

        XCTAssertEqual(OpenAIWire.toolOutput(callID: "c", content: [.text("")], isError: false)["output"] as? String, "Done.")
    }

    // MARK: - OpenAI: stream

    private var openAIOutput: [[String: Any]] {
        [
            ["id": "rs_1", "type": "reasoning", "summary": [Any](), "encrypted_content": "ENCRYPTED"],
            ["id": "msg_1", "type": "message", "role": "assistant", "status": "completed",
             "content": [["type": "output_text", "text": "Building a cube.", "annotations": [Any]()]]],
            ["id": "fc_1", "type": "function_call", "call_id": "call_1", "name": "os3d", "status": "completed",
             "arguments": "{\"op\":\"sketch.create\",\"args\":{\"plane\":\"xz\"}}"],
        ]
    }

    private func openAIEvents(status: String = "completed", output: [[String: Any]]? = nil,
                              extra: [String: Any] = [:]) -> [[String: Any]] {
        let output = output ?? openAIOutput
        var response: [String: Any] = ["id": "resp_1", "status": status, "output": output,
                                       "usage": ["input_tokens": 120, "output_tokens": 30,
                                                 "input_tokens_details": ["cached_tokens": 100]]]
        for (key, value) in extra { response[key] = value }
        return [
            ["type": "response.created", "response": ["id": "resp_1"]],
            ["type": "response.output_item.added", "item": ["type": "reasoning"]],
            ["type": "response.output_item.added", "item": ["type": "message"]],
            ["type": "response.output_text.delta", "delta": "Building "],
            ["type": "response.output_text.delta", "delta": "a cube."],
            ["type": "response.output_item.added", "item": ["type": "function_call", "name": "os3d"]],
            ["type": "response.function_call_arguments.delta", "delta": "{\"op\""],
            ["type": status == "completed" ? "response.completed" : "response.\(status)", "response": response],
        ]
    }

    func testOpenAIStreamedReplyIsReadFromTheClosingEvent() {
        var stream = OpenAIStream()
        var updates: [AssistantStreamUpdate] = []
        for event in openAIEvents() { updates.append(stream.consume(data: json(event))) }
        XCTAssertTrue(updates.contains(.thinking))
        XCTAssertTrue(updates.contains(.text("Building ")))
        XCTAssertTrue(updates.contains(.text("a cube.")))
        XCTAssertTrue(updates.contains(.toolStarted(name: "os3d")))
        XCTAssertFalse(stream.endedMidReply)
        XCTAssertNil(stream.failure)

        let reply = stream.reply
        XCTAssertEqual(reply.outcome, .toolCalls)
        XCTAssertEqual(reply.calls.count, 1)
        XCTAssertEqual(reply.calls[0].id, "call_1", "the call is answered by call_id, not the item id")
        XCTAssertEqual(reply.calls[0].op, "sketch.create")
        XCTAssertNil(reply.calls[0].problem)
        XCTAssertEqual(reply.tokensIn, 120)
        XCTAssertEqual(reply.tokensOut, 30)

        // Every output item goes back unchanged, the reasoning item included.
        XCTAssertEqual(reply.history.count, 3)
        XCTAssertEqual(reply.history[0]["encrypted_content"] as? String, "ENCRYPTED")
        XCTAssertEqual(reply.history[2]["arguments"] as? String, "{\"op\":\"sketch.create\",\"args\":{\"plane\":\"xz\"}}")
        XCTAssertTrue(JSONSerialization.isValidJSONObject(reply.history))
    }

    func testOpenAIItemsCollectedAlongTheWayAreTheFallback() {
        var stream = OpenAIStream()
        for item in openAIOutput { _ = stream.consume(data: json(["type": "response.output_item.done", "item": item])) }
        _ = stream.consume(data: json(["type": "response.completed", "response": ["status": "completed"]]))
        XCTAssertEqual(stream.reply.history.count, 3)
        XCTAssertEqual(stream.reply.calls.first?.id, "call_1")
    }

    func testOpenAIOutcomes() {
        func reply(_ events: [[String: Any]]) -> AssistantReply {
            var stream = OpenAIStream()
            for event in events { _ = stream.consume(data: json(event)) }
            return stream.reply
        }
        let text: [[String: Any]] = [["type": "message", "role": "assistant",
                                      "content": [["type": "output_text", "text": "Done."]]]]
        XCTAssertEqual(reply(openAIEvents(output: text)).outcome, .done)
        XCTAssertEqual(reply(openAIEvents(status: "incomplete", output: text,
                                          extra: ["incomplete_details": ["reason": "max_output_tokens"]])).outcome, .cutOff)
        XCTAssertEqual(reply(openAIEvents(status: "incomplete", output: text,
                                          extra: ["incomplete_details": ["reason": "content_filter"]])).outcome, .declined)
        let refused: [[String: Any]] = [["type": "message", "role": "assistant",
                                         "content": [["type": "refusal", "refusal": "I can't help with that."]]]]
        XCTAssertEqual(reply(openAIEvents(output: refused)).outcome, .declined)
    }

    func testOpenAIUnparseableArgumentsAreRefusedNotRun() {
        var stream = OpenAIStream()
        let broken: [[String: Any]] = [["type": "function_call", "call_id": "call_9", "name": "os3d",
                                        "arguments": "{\"op\":\"feature.extrude\",\"args\":{\"dist"]]
        for event in openAIEvents(output: broken) { _ = stream.consume(data: json(event)) }
        let call = stream.reply.calls[0]
        XCTAssertNotNil(call.invalidInput)
        XCTAssertTrue(call.problem?.contains("INVALID_JSON") == true)

        var empty = OpenAIStream()
        let noArguments: [[String: Any]] = [["type": "function_call", "call_id": "c", "name": "os3d", "arguments": ""]]
        for event in openAIEvents(output: noArguments) { _ = empty.consume(data: json(event)) }
        XCTAssertNil(empty.reply.calls[0].invalidInput)
        XCTAssertNotNil(empty.reply.calls[0].problem, "no op: refused by the check")
    }

    func testOpenAIFailuresInTheStream() {
        var failed = OpenAIStream()
        XCTAssertEqual(failed.consume(data: json(["type": "response.failed",
                                                  "response": ["status": "failed", "error": ["message": "Server had a problem"]]])),
                       .failed("Server had a problem"))
        XCTAssertEqual(failed.failure, "Server had a problem")

        var errored = OpenAIStream()
        XCTAssertEqual(errored.consume(data: json(["type": "error", "message": "Rate limit reached"])), .failed("Rate limit reached"))

        var cut = OpenAIStream()
        _ = cut.consume(data: json(["type": "response.output_text.delta", "delta": "Half a"]))
        XCTAssertTrue(cut.endedMidReply, "no closing event: the reply is not trusted")
        XCTAssertFalse(cut.isEmpty)
        XCTAssertTrue(OpenAIStream().isEmpty)
        XCTAssertEqual(cut.consume(data: "[DONE]"), .nothing)
        XCTAssertEqual(cut.consume(data: json(["type": "response.something_new"])), .nothing)
    }

    func testOpenAIErrorWording() {
        func body(_ type: String, _ code: String, _ message: String) -> Data {
            Data(json(["error": ["message": message, "type": type, "code": code, "param": NSNull()]]).utf8)
        }
        XCTAssertTrue(OpenAIWire.errorMessage(status: 401, body: body("invalid_request_error", "invalid_api_key", "Incorrect API key provided"))
            .contains("did not accept this API key"))
        XCTAssertTrue(OpenAIWire.errorMessage(status: 429, body: body("insufficient_quota", "insufficient_quota", "You exceeded your quota"))
            .contains("out of credit"))
        XCTAssertTrue(OpenAIWire.errorMessage(status: 429, body: body("rate_limit_error", "rate_limit_exceeded", "slow down"))
            .contains("rate limit"))
        XCTAssertTrue(OpenAIWire.errorMessage(status: 503, body: Data()).contains("busy"))
        XCTAssertEqual(OpenAIWire.errorMessage(status: 400, body: body("invalid_request_error", "x", "bad thing")), "bad thing")
        XCTAssertTrue(OpenAIWire.isWorthRetrying(status: 503))
        XCTAssertFalse(OpenAIWire.isWorthRetrying(status: 429), "a 429 waits for retry-after or is a spent quota")
        var options = AssistantRequestOptions()
        XCTAssertFalse(AssistantProvider.openai.adjust(&options, afterStatus: 400, body: body("x", "x", "schema")))
    }

    // MARK: - Gemini: request

    func testGeminiRequest() {
        let model = AssistantProvider.google.model("gemini-4-hydrogen")
        var contents: [[String: Any]] = []
        GeminiWire.appendUserText("a cube", to: &contents)
        let request = AssistantProvider.google.request(apiKey: "AIza-test", model: model, system: "SYS", mcpTools: mcpTools,
                                                       conversation: contents, options: AssistantRequestOptions())
        XCTAssertEqual(request.url.absoluteString,
                       "https://generativelanguage.googleapis.com/v1beta/models/gemini-4-hydrogen:streamGenerateContent?alt=sse")
        XCTAssertEqual(request.headers["x-goog-api-key"], "AIza-test")
        let body = object(request.body)
        XCTAssertEqual((((body["systemInstruction"] as? [String: Any])?["parts"] as? [[String: Any]])?.first)?["text"] as? String, "SYS")
        let declaration = (((body["tools"] as? [[String: Any]])?.first)?["functionDeclarations"] as? [[String: Any]])?.first
        XCTAssertEqual(declaration?["name"] as? String, "os3d")
        XCTAssertNotNil(declaration?["parametersJsonSchema"] as? [String: Any], "the tool's own schema is passed as it is")
        XCTAssertNil(declaration?["parameters"])
        let first = (body["contents"] as? [[String: Any]])?.first
        XCTAssertEqual(first?["role"] as? String, "user")
        XCTAssertEqual(((first?["parts"] as? [[String: Any]])?.first)?["text"] as? String, "a cube")
        for ignored in ["generationConfig", "safetySettings"] { XCTAssertNil(body[ignored], "defaults are left alone") }
    }

    func testGeminiFallsBackToArgsAsTextWhenTheSchemaIsRefused() {
        func error(_ message: String, reason: String? = nil) -> Data {
            var error: [String: Any] = ["code": 400, "message": message, "status": "INVALID_ARGUMENT"]
            if let reason { error["details"] = [["reason": reason]] }
            return Data(json(["error": error]).utf8)
        }
        var options = AssistantRequestOptions()
        XCTAssertFalse(AssistantProvider.google.adjust(&options, afterStatus: 400,
                                                       body: error("API key not valid.", reason: "API_KEY_INVALID")))
        XCTAssertFalse(AssistantProvider.google.adjust(&options, afterStatus: 429, body: error("schema")))
        XCTAssertTrue(AssistantProvider.google.adjust(&options, afterStatus: 400,
            body: error("Invalid JSON payload: function_declarations[0].parameters_json_schema.properties[args] ...")))
        XCTAssertTrue(options.argsAsText)
        XCTAssertFalse(AssistantProvider.google.adjust(&options, afterStatus: 400, body: error("schema")), "only once")

        let request = AssistantProvider.google.request(apiKey: "k", model: AssistantProvider.google.model(nil), system: "",
                                                       mcpTools: mcpTools, conversation: [], options: options)
        let declaration = (((object(request.body)["tools"] as? [[String: Any]])?.first)?["functionDeclarations"] as? [[String: Any]])?.first
        let args = ((declaration?["parameters"] as? [String: Any])?["properties"] as? [String: Any])?["args"] as? [String: Any]
        XCTAssertEqual(args?["type"] as? String, "string")
        XCTAssertNil(declaration?["parametersJsonSchema"])

        // And a call written that way is read as the object it means.
        let written = AssistantStream.withArgsAsObject(call("c", ["op": "faces", "args": "{\"body\": \"b1\"}"]))
        XCTAssertEqual((written.input["args"] as? [String: Any])?["body"] as? String, "b1")
        XCTAssertNil(written.problem)
        XCTAssertNil(AssistantStream.withArgsAsObject(call("c", ["op": "state", "args": "  "])).input["args"])
        XCTAssertNotNil(AssistantStream.withArgsAsObject(call("c", ["op": "faces", "args": "not json"])).problem,
                        "text that is not an object is still refused")
    }

    func testGeminiConversationShapes() {
        var contents: [[String: Any]] = []
        GeminiWire.appendUserText("one", to: &contents)
        GeminiWire.appendUserText("two", to: &contents)
        XCTAssertEqual(contents.count, 1, "a message nothing answered takes the text as another part")
        XCTAssertEqual((contents[0]["parts"] as? [[String: Any]])?.count, 2)

        contents.append(["role": "model", "parts": [["functionCall": ["name": "os3d", "args": ["op": "state"]]]]])
        contents.append(GeminiWire.toolResults([(call("local-call-1", ["op": "state"]), [.text("{\"bodies\":[]}")], false)]))
        GeminiWire.appendUserText("and now a hole", to: &contents)
        XCTAssertEqual(contents.count, 4, "text does not join a message of tool answers")
        GeminiWire.removePendingUserText(from: &contents)
        XCTAssertEqual(contents.count, 3)
        GeminiWire.removePendingUserText(from: &contents)
        XCTAssertEqual(contents.count, 3, "tool answers are not taken back")
    }

    func testGeminiToolResultsGoBackTogetherInOrder() {
        let message = GeminiWire.toolResults([
            (call("fc-1", ["op": "state"]), [.text("{\"bodies\":[]}")], false),
            (call("local-call-2", ["op": "faces"]), [.text("no such body")], true),
            (call("fc-3", ["op": "screenshot"]), [.image(mediaType: "image/jpeg", base64: "QUJD")], false),
            (call("fc-4", ["op": "check"]), [.text("plain words")], false),
        ])
        XCTAssertEqual(message["role"] as? String, "user")
        let parts = (message["parts"] as? [[String: Any]] ?? []).compactMap { $0["functionResponse"] as? [String: Any] }
        XCTAssertEqual(parts.count, 4, "one message answers every call of the reply")

        XCTAssertEqual(parts[0]["name"] as? String, "os3d")
        XCTAssertEqual(parts[0]["id"] as? String, "fc-1")
        XCTAssertNotNil((parts[0]["response"] as? [String: Any])?["bodies"], "a JSON answer is the object it is")

        XCTAssertNil(parts[1]["id"], "an id made up here is not sent")
        XCTAssertEqual((parts[1]["response"] as? [String: Any])?["error"] as? String, "no such body")

        let media = (parts[2]["parts"] as? [[String: Any]])?.first?["inlineData"] as? [String: Any]
        XCTAssertEqual(media?["mimeType"] as? String, "image/jpeg")
        XCTAssertEqual(media?["data"] as? String, "QUJD")
        XCTAssertNotNil((parts[2]["response"] as? [String: Any])?["result"])

        XCTAssertEqual((parts[3]["response"] as? [String: Any])?["result"] as? String, "plain words")
        XCTAssertTrue(JSONSerialization.isValidJSONObject(message))
    }

    // MARK: - Gemini: stream

    private func geminiChunk(_ parts: [[String: Any]], finish: String? = nil, usage: [String: Any]? = nil) -> [String: Any] {
        var candidate: [String: Any] = ["content": ["role": "model", "parts": parts], "index": 0]
        if let finish { candidate["finishReason"] = finish }
        var chunk: [String: Any] = ["candidates": [candidate]]
        if let usage { chunk["usageMetadata"] = usage }
        return chunk
    }

    func testGeminiStreamedReplyKeepsPartsAsTheyCame() {
        var stream = GeminiStream()
        XCTAssertEqual(stream.consume(data: json(geminiChunk([["text": "Building "]]))), .text("Building "))
        XCTAssertEqual(stream.consume(data: json(geminiChunk([["text": "a cube."]]))), .text("a cube."))
        let callPart: [String: Any] = ["functionCall": ["name": "os3d", "id": "fc-1", "args": ["op": "sketch.create"]],
                                       "thoughtSignature": "SIGNATURE-1"]
        let second: [String: Any] = ["functionCall": ["name": "os3d", "args": ["op": "state"]]]
        XCTAssertEqual(stream.consume(data: json(geminiChunk([callPart, second]))), .toolStarted(name: "os3d"))
        XCTAssertTrue(stream.endedMidReply, "no finish reason yet")
        _ = stream.consume(data: json(geminiChunk([], finish: "STOP",
                                                  usage: ["promptTokenCount": 200, "candidatesTokenCount": 20, "thoughtsTokenCount": 15])))
        XCTAssertFalse(stream.endedMidReply)

        let reply = stream.reply
        XCTAssertEqual(reply.outcome, .toolCalls)
        XCTAssertEqual(reply.calls.map(\.id), ["fc-1", "local-call-2"])
        XCTAssertEqual(reply.calls.map(\.op), ["sketch.create", "state"])
        XCTAssertEqual(reply.tokensIn, 200)
        XCTAssertEqual(reply.tokensOut, 35)

        XCTAssertEqual(reply.history.count, 1)
        XCTAssertEqual(reply.history[0]["role"] as? String, "model")
        let parts = reply.history[0]["parts"] as? [[String: Any]] ?? []
        XCTAssertEqual(parts.count, 3, "the two pieces of text are one part again; the calls follow")
        XCTAssertEqual(parts[0]["text"] as? String, "Building a cube.")
        XCTAssertEqual(parts[1]["thoughtSignature"] as? String, "SIGNATURE-1", "the signature goes back with its call")
        XCTAssertNil(parts[2]["thoughtSignature"])
    }

    func testGeminiASignatureOnAnEmptyTextPartIsKept() {
        var stream = GeminiStream()
        _ = stream.consume(data: json(geminiChunk([["text": "Done."]])))
        _ = stream.consume(data: json(geminiChunk([["text": "", "thoughtSignature": "SIG-END"]], finish: "STOP")))
        let parts = stream.reply.history[0]["parts"] as? [[String: Any]] ?? []
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[1]["thoughtSignature"] as? String, "SIG-END")
        XCTAssertEqual(stream.reply.outcome, .done)
    }

    func testGeminiOutcomes() {
        func stream(_ chunks: [[String: Any]]) -> GeminiStream {
            var stream = GeminiStream()
            for chunk in chunks { _ = stream.consume(data: json(chunk)) }
            return stream
        }
        XCTAssertEqual(stream([geminiChunk([["text": "x"]], finish: "MAX_TOKENS")]).reply.outcome, .cutOff)
        XCTAssertEqual(stream([geminiChunk([], finish: "SAFETY")]).reply.outcome, .declined)
        XCTAssertEqual(stream([geminiChunk([], finish: "PROHIBITED_CONTENT")]).reply.outcome, .declined)

        let blocked = stream([["promptFeedback": ["blockReason": "SAFETY"]]])
        XCTAssertEqual(blocked.reply.outcome, .declined)
        XCTAssertFalse(blocked.endedMidReply)
        XCTAssertTrue(blocked.reply.history.isEmpty)

        let malformed = stream([geminiChunk([], finish: "MALFORMED_FUNCTION_CALL")])
        XCTAssertNotNil(malformed.brokenReply)
        XCTAssertNotNil(AssistantStream.google(malformed).failure, "the loop hears about it")
        XCTAssertNil(stream([geminiChunk([["text": "x"]], finish: "STOP")]).brokenReply)

        var errored = GeminiStream()
        XCTAssertEqual(errored.consume(data: json(["error": ["code": 503, "message": "The model is overloaded."]])),
                       .failed("The model is overloaded."))
        XCTAssertEqual(errored.failure, "The model is overloaded.")
        XCTAssertTrue(GeminiStream().isEmpty)
        XCTAssertEqual(errored.consume(data: "not json"), .nothing)
    }

    func testGeminiErrorWording() {
        let badKey = Data(#"{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.","status":"INVALID_ARGUMENT","details":[{"@type":"type.googleapis.com/google.rpc.ErrorInfo","reason":"API_KEY_INVALID"}]}}"#.utf8)
        XCTAssertTrue(GeminiWire.errorMessage(status: 400, body: badKey).contains("did not accept this API key"))
        XCTAssertFalse(GeminiWire.isAboutToolSchema(status: 400, body: badKey))
        let quota = Data(#"{"error":{"code":429,"message":"Quota exceeded","status":"RESOURCE_EXHAUSTED"}}"#.utf8)
        XCTAssertTrue(GeminiWire.errorMessage(status: 429, body: quota).contains("Quota exceeded"))
        XCTAssertTrue(GeminiWire.errorMessage(status: 503, body: Data()).contains("busy"))
        let wrapped = Data(#"[{"error":{"code":400,"message":"bad thing","status":"INVALID_ARGUMENT"}}]"#.utf8)
        XCTAssertEqual(GeminiWire.errorMessage(status: 400, body: wrapped), "bad thing", "the stream endpoint may wrap the error in an array")
        XCTAssertTrue(GeminiWire.errorMessage(status: 418, body: Data("<html>".utf8)).contains("418"))
    }

    // MARK: - The switchboard

    func testAToolRoundTripInEachProvidersShape() {
        let results: [(call: AssistantToolCall, content: [AssistantToolContent], isError: Bool)] = [
            (call("id-1", ["op": "state"]), [.text("{\"bodies\":[]}")], false),
            (call("id-2", ["op": "faces"]), [.text("no such body")], true),
        ]
        var claude: [[String: Any]] = []
        AssistantProvider.anthropic.appendToolResults(results, to: &claude)
        XCTAssertEqual(claude.count, 1, "Claude: one user message answers both")
        XCTAssertEqual((claude[0]["content"] as? [[String: Any]])?.compactMap { $0["tool_use_id"] as? String }, ["id-1", "id-2"])

        var openai: [[String: Any]] = []
        AssistantProvider.openai.appendToolResults(results, to: &openai)
        XCTAssertEqual(openai.compactMap { $0["call_id"] as? String }, ["id-1", "id-2"], "OpenAI: one item per call")

        var gemini: [[String: Any]] = []
        AssistantProvider.google.appendToolResults(results, to: &gemini)
        XCTAssertEqual(gemini.count, 1, "Gemini: one user message answers both")
        XCTAssertEqual((gemini[0]["parts"] as? [[String: Any]])?.count, 2)

        var none: [[String: Any]] = []
        for provider in AssistantProvider.allCases { provider.appendToolResults([], to: &none) }
        XCTAssertTrue(none.isEmpty)
    }

    func testADeclinedMessageIsTakenBackInEveryShape() {
        for provider in AssistantProvider.allCases {
            var conversation: [[String: Any]] = []
            provider.appendUserText("something declined", to: &conversation)
            provider.removePendingUserText(from: &conversation)
            XCTAssertTrue(conversation.isEmpty, "\(provider)")
        }
    }

    func testClaudeStreamAsANeutralReply() {
        func reply(stop: String, blocks: [[String: Any]]) -> AssistantReply {
            var stream = AnthropicStream()
            for (index, block) in blocks.enumerated() {
                _ = stream.consume(data: json(["type": "content_block_start", "index": index, "content_block": block]))
                _ = stream.consume(data: json(["type": "content_block_stop", "index": index]))
            }
            _ = stream.consume(data: json(["type": "message_delta", "delta": ["stop_reason": stop],
                                           "usage": ["output_tokens": 7]]))
            _ = stream.consume(data: json(["type": "message_stop"]))
            return AssistantStream.anthropic(stream).reply
        }
        let text: [String: Any] = ["type": "text", "text": "Hello."]
        let toolUse: [String: Any] = ["type": "tool_use", "id": "t1", "name": "os3d", "input": ["op": "state"]]

        let asking = reply(stop: "tool_use", blocks: [text, toolUse])
        XCTAssertEqual(asking.outcome, .toolCalls)
        XCTAssertEqual(asking.calls.map(\.id), ["t1"])
        XCTAssertEqual(asking.history.first?["role"] as? String, "assistant")
        XCTAssertEqual(asking.tokensOut, 7)

        XCTAssertEqual(reply(stop: "end_turn", blocks: [text]).outcome, .done)
        XCTAssertEqual(reply(stop: "max_tokens", blocks: [toolUse]).outcome, .cutOff)
        XCTAssertEqual(reply(stop: "pause_turn", blocks: [text]).outcome, .paused)
        XCTAssertEqual(reply(stop: "tool_use", blocks: [text]).outcome, .done, "asked for tools but sent none")

        let declined = reply(stop: "refusal", blocks: [text, toolUse])
        XCTAssertEqual(declined.outcome, .declined)
        XCTAssertTrue(declined.history.isEmpty, "nothing of a declined reply is kept")
        XCTAssertTrue(declined.calls.isEmpty)
    }

    func testAdjustingARequestClaudeCannotMake() {
        var options = AssistantRequestOptions()
        let beta = Data(#"{"type":"error","error":{"type":"invalid_request_error","message":"Unexpected value(s) `x` for the `anthropic-beta` header."}}"#.utf8)
        XCTAssertTrue(AssistantProvider.anthropic.adjust(&options, afterStatus: 400, body: beta))
        XCTAssertFalse(options.retryDeclines)
        XCTAssertFalse(AssistantProvider.anthropic.adjust(&options, afterStatus: 400, body: beta), "only once")
        let request = AssistantProvider.anthropic.request(apiKey: "k", model: AssistantProvider.anthropic.model(nil), system: "",
                                                          mcpTools: mcpTools, conversation: [], options: options)
        XCTAssertNil(request.headers["anthropic-beta"])
        XCTAssertNil(object(request.body)["fallbacks"])
    }
}
