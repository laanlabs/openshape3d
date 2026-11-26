//
//  AssistantWire.swift
//  openshape3d
//
//  The built-in assistant's side of the Claude Messages API (#119), as pure
//  values: the request body, the streamed reply put back together, the
//  wording of an error, and a tool answer turned into a `tool_result`.
//  Nothing here opens a connection or touches the editor, so all of it is
//  unit-tested (`AssistantWireTests`).
//
//  The person brings their own API key; requests go from this device straight
//  to api.anthropic.com. There is no OpenShape 3D server in between.
//
//  Swift has no official Anthropic SDK, so this is the raw HTTP shape:
//  `POST /v1/messages` with `stream: true`, read as server-sent events.
//

import Foundation

/// A model the person can pick in the panel.
nonisolated struct AssistantModel: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var note: String
    /// Whether a declined request can be retried on another model by the
    /// API itself (`fallbacks`). Claude Haiku 5.5 has no such retry.
    var retriesDeclines: Bool
}

nonisolated enum AnthropicWire {

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2026-10-21"
    static let fallbackBeta = "server-side-fallback-2026-07-01"
    /// A ceiling on one reply, not a target; replies are streamed.
    static let maxTokens = 64_000
    /// The one tool the assistant has: the same `os3d` tool the MCP server lists.
    static let toolName = "os3d"

    static let models: [AssistantModel] = [
        AssistantModel(id: "claude-opus-5-5", name: "Claude Opus 5.5",
                       note: "Recommended", retriesDeclines: true),
        AssistantModel(id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5",
                       note: "Faster, lower cost", retriesDeclines: true),
        AssistantModel(id: "claude-haiku-5-5", name: "Claude Haiku 5.5",
                       note: "Fastest, lowest cost", retriesDeclines: false),
        AssistantModel(id: "claude-fable-5-2", name: "Claude Fable 5.2",
                       note: "Most capable, highest cost", retriesDeclines: true),
    ]
    static let defaultModelID = "claude-opus-5-5"

    static func model(_ id: String) -> AssistantModel {
        models.first { $0.id == id } ?? models[0]
    }

    // MARK: - Request

    /// Who the assistant is in this app: `AssistantPrompt.md`, a bundled
    /// resource so the web app sends the same words (openshape-cloud copies
    /// the file, as it does the tool list and the guide).
    static let preamble: String = {
        guard let url = Bundle.main.url(forResource: "AssistantPrompt", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "You are the assistant built into OpenShape 3D. Work on the open design through the os3d tool."
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    /// What the assistant is told before the conversation: who it is here,
    /// then the modelling guide every other assistant gets.
    static func systemPrompt(guide: String) -> String {
        preamble + "\n\n" + guide
    }

    /// The MCP tool list (`MCPTools.json`) in the Messages API's spelling.
    /// Tool inputs stream as they are written (`eager_input_streaming`), so
    /// the API does not validate them: `ToolCall.parse` does.
    static func tools(fromMCP mcpTools: [[String: Any]]) -> [[String: Any]] {
        mcpTools.compactMap { tool in
            guard let name = tool["name"] as? String, name == toolName,
                  let description = tool["description"] as? String,
                  let schema = tool["inputSchema"] as? [String: Any] else { return nil }
            return ["name": name, "description": description, "input_schema": schema,
                    "eager_input_streaming": true]
        }
    }

    static func requestBody(model: AssistantModel, system: String, tools: [[String: Any]],
                            messages: [[String: Any]], retryDeclines: Bool) -> [String: Any] {
        var body: [String: Any] = [
            "model": model.id,
            "max_tokens": maxTokens,
            "stream": true,
            // Thinking is adaptive on every model offered; depth is set by effort.
            "thinking": ["type": "adaptive"],
            "output_config": ["effort": "high"],
            // The guide and tool never change, so they are a cache read after
            // the first request; the top-level marker caches the conversation
            // so far as it grows.
            "system": [["type": "text", "text": system, "cache_control": ["type": "ephemeral"]]],
            "cache_control": ["type": "ephemeral"],
            "tools": tools,
            "messages": messages,
        ]
        if retryDeclines, model.retriesDeclines { body["fallbacks"] = "default" }
        return body
    }

    static func headers(apiKey: String, model: AssistantModel, retryDeclines: Bool) -> [String: String] {
        var headers = ["content-type": "application/json",
                       "accept": "text/event-stream",
                       "x-api-key": apiKey,
                       "anthropic-version": apiVersion]
        if retryDeclines, model.retriesDeclines { headers["anthropic-beta"] = fallbackBeta }
        return headers
    }

    /// Request bytes with sorted keys, so the same conversation always
    /// serialises to the same bytes and the prompt cache keeps hitting.
    static func encode(_ body: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])) ?? Data()
    }

    // MARK: - Conversation shapes

    static func userMessage(text: String) -> [String: Any] {
        ["role": "user", "content": [["type": "text", "text": text]]]
    }

    /// Add what the person typed to the conversation. Roles must alternate,
    /// so when the last message is already the user's (tool answers, or a
    /// turn that was stopped before the model replied) the text joins it.
    static func appendUserText(_ text: String, to messages: inout [[String: Any]]) {
        let block: [String: Any] = ["type": "text", "text": text]
        if let last = messages.last, last["role"] as? String == "user" {
            var content = last["content"] as? [[String: Any]] ?? []
            content.append(block)
            messages[messages.count - 1]["content"] = content
        } else {
            messages.append(["role": "user", "content": [block]])
        }
    }

    /// An assistant reply as it goes back into the conversation.
    ///
    /// Blocks are returned exactly as received (thinking blocks carry a
    /// signature that only verifies unchanged), with two exceptions the API
    /// asks for: a text block with nothing in it is refused, and after the
    /// API retried a declined reply on another model (a `fallback` block)
    /// the first model's thinking and tool calls before that block are left
    /// out while the block itself stays where it was.
    static func echo(_ blocks: [[String: Any]]) -> [[String: Any]] {
        let boundary = blocks.lastIndex { $0["type"] as? String == "fallback" }
        var out: [[String: Any]] = []
        for (index, block) in blocks.enumerated() {
            let type = block["type"] as? String ?? ""
            if type == "text" {
                let text = block["text"] as? String ?? ""
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            }
            if let boundary, index < boundary, type != "text", type != "fallback" { continue }
            out.append(block)
        }
        return out
    }

    /// The tool calls of a reply that should run: those after any `fallback`
    /// block (calls before it belong to the model that was replaced).
    static func toolCalls(in blocks: [[String: Any]]) -> [ToolCall] {
        let boundary = blocks.lastIndex { $0["type"] as? String == "fallback" } ?? -1
        return blocks.enumerated().compactMap { index, block in
            guard index > boundary, block["type"] as? String == "tool_use",
                  let id = block["id"] as? String else { return nil }
            return ToolCall(id: id, name: block["name"] as? String ?? "",
                            input: block["input"] as? [String: Any] ?? [:],
                            invalidInput: block[AnthropicStream.invalidInputKey] as? String)
        }
    }

    nonisolated struct ToolCall {
        var id: String
        var name: String
        var input: [String: Any]
        /// The text the model wrote where JSON was expected, when it did not parse.
        var invalidInput: String?

        var op: String { input["op"] as? String ?? "" }

        /// Why this call cannot run, or nil when it is well formed. The API
        /// does not check streamed tool inputs, so this is the check.
        var problem: String? {
            if let invalidInput {
                let wrapped = (try? JSONSerialization.data(withJSONObject: ["INVALID_JSON": invalidInput]))
                    .map { String(decoding: $0, as: UTF8.self) }
                return wrapped ?? "{\"INVALID_JSON\":\"\"}"
            }
            if name != AnthropicWire.toolName { return "Unknown tool: \(name). The only tool is \(AnthropicWire.toolName)." }
            guard let op = input["op"] as? String, !op.isEmpty else {
                return "os3d needs an 'op' string, such as state or feature.extrude."
            }
            if let args = input["args"], !(args is [String: Any]) {
                return "'args' must be a JSON object, for example {\"body\": \"…\"}."
            }
            return nil
        }
    }

    // MARK: - Tool answers

    /// One piece of a tool answer.
    nonisolated enum ToolContent: Equatable {
        case text(String)
        case image(mediaType: String, base64: String)
    }

    /// Longest text answer passed on whole. Anything longer is cut with a
    /// note the model can read, so it knows to ask for less.
    static let maxResultCharacters = 400_000

    /// An MCP `tools/call` reply (`AgentMCP.result`) as tool content.
    static func toolContent(fromMCPReply body: Data) -> (content: [ToolContent], isError: Bool) {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return ([.text("The app returned an answer that could not be read.")], true)
        }
        if let error = object["error"] as? [String: Any] {
            return ([.text(error["message"] as? String ?? "The app refused the call.")], true)
        }
        let result = object["result"] as? [String: Any] ?? [:]
        var content: [ToolContent] = []
        for item in result["content"] as? [[String: Any]] ?? [] {
            switch item["type"] as? String {
            case "text":
                let text = item["text"] as? String ?? ""
                if text.count > maxResultCharacters {
                    let kept = String(text.prefix(maxResultCharacters))
                    content.append(.text(kept + "\n[Cut here: \(text.count - maxResultCharacters) more characters "
                                         + "were left out. Ask for a narrower read.]"))
                } else {
                    content.append(.text(text))
                }
            case "image":
                if let data = item["data"] as? String {
                    content.append(.image(mediaType: item["mimeType"] as? String ?? "image/jpeg", base64: data))
                }
            default: break
            }
        }
        if content.isEmpty { content = [.text("Done.")] }
        return (content, result["isError"] as? Bool == true)
    }

    static func toolResult(id: String, content: [ToolContent], isError: Bool) -> [String: Any] {
        var block: [String: Any] = [
            "type": "tool_result",
            "tool_use_id": id,
            "content": content.map { piece -> [String: Any] in
                switch piece {
                case .text(let text):
                    return ["type": "text", "text": text.isEmpty ? "Done." : text]
                case let .image(mediaType, base64):
                    return ["type": "image",
                            "source": ["type": "base64", "media_type": mediaType, "data": base64]]
                }
            },
        ]
        if isError { block["is_error"] = true }
        return block
    }

    // MARK: - Errors

    /// A failed request, in words for the panel.
    static func errorMessage(status: Int, body: Data) -> String {
        let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        let detail = ((object?["error"] as? [String: Any])?["message"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        func with(_ lead: String) -> String { detail.isEmpty ? lead : lead + " (" + detail + ")" }
        switch status {
        case 401:
            return "Anthropic did not accept this API key. Check the key in the assistant's settings."
        case 402:
            return with("Anthropic reports a billing problem on this key's account.")
        case 403:
            return with("This key is not allowed to do that.")
        case 404:
            return with("This model is not available to this key. Pick another model in the assistant's settings.")
        case 413:
            return "The conversation has grown too large to send. Start a new chat."
        case 429:
            return with("The key's rate or spending limit was reached. Wait a moment and send again.")
        case 500...599:
            return with("Anthropic's service is busy or had a problem. Try again in a moment.")
        default:
            return detail.isEmpty ? "The request failed (HTTP \(status))." : detail
        }
    }

    /// True when a 400 is about the optional decline-retry feature rather
    /// than the conversation, so the request is worth sending without it.
    static func isAboutDeclineRetry(status: Int, body: Data) -> Bool {
        guard status == 400 else { return false }
        let text = String(decoding: body, as: UTF8.self).lowercased()
        return text.contains("anthropic-beta") || text.contains("fallback")
    }

    /// Whether the same request may succeed if sent again shortly.
    static func isWorthRetrying(status: Int) -> Bool {
        status == 500 || status == 502 || status == 503 || status == 504 || status == 529
    }
}

// MARK: - A streamed reply, put back together

/// Feed it the `data:` payload of each server-sent event; when the stream
/// ends it holds the reply's content blocks as the API would have returned
/// them in one piece.
nonisolated struct AnthropicStream {

    /// Private marker on a `tool_use` block whose input was not valid JSON.
    /// Removed before the block is sent back (`finishedBlocks`).
    static let invalidInputKey = "_os3d_invalid_input"

    /// What one event means for someone watching.
    nonisolated enum Update: Equatable {
        case nothing
        case text(String)
        case thinking
        case toolStarted(name: String)
        /// The API switched to another model after the first declined.
        case switchedModel(String)
        case failed(String)
    }

    private var blocks: [Int: [String: Any]] = [:]
    private var partialInputs: [Int: String] = [:]
    private(set) var stopReason: String?
    private(set) var stopCategory: String?
    private(set) var model: String?
    private(set) var inputTokens = 0
    private(set) var outputTokens = 0
    private(set) var cacheReadTokens = 0
    private(set) var cacheWriteTokens = 0
    private(set) var failure: String?
    private(set) var sawMessageStop = false

    /// Whether anything of the reply has arrived (a request that failed
    /// before this can be sent again without repeating visible output).
    var isEmpty: Bool { blocks.isEmpty }

    mutating func consume(data payload: String) -> Update {
        guard let bytes = payload.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let type = event["type"] as? String else { return .nothing }
        let index = (event["index"] as? NSNumber)?.intValue ?? -1

        switch type {
        case "message_start":
            let message = event["message"] as? [String: Any] ?? [:]
            model = message["model"] as? String
            readUsage(message["usage"] as? [String: Any])
            return .nothing

        case "content_block_start":
            guard index >= 0, let block = event["content_block"] as? [String: Any] else { return .nothing }
            blocks[index] = block
            switch block["type"] as? String {
            case "tool_use":
                partialInputs[index] = ""
                return .toolStarted(name: block["name"] as? String ?? "")
            case "thinking", "redacted_thinking":
                return .thinking
            case "fallback":
                let to = (block["to"] as? [String: Any])?["model"] as? String ?? ""
                return .switchedModel(to)
            case "text":
                let text = block["text"] as? String ?? ""
                return text.isEmpty ? .nothing : .text(text)
            default:
                return .nothing
            }

        case "content_block_delta":
            guard index >= 0, var block = blocks[index],
                  let delta = event["delta"] as? [String: Any] else { return .nothing }
            defer { blocks[index] = block }
            switch delta["type"] as? String {
            case "text_delta":
                let piece = delta["text"] as? String ?? ""
                block["text"] = (block["text"] as? String ?? "") + piece
                return piece.isEmpty ? .nothing : .text(piece)
            case "thinking_delta":
                block["thinking"] = (block["thinking"] as? String ?? "") + (delta["thinking"] as? String ?? "")
                return .nothing
            case "signature_delta":
                block["signature"] = (block["signature"] as? String ?? "") + (delta["signature"] as? String ?? "")
                return .nothing
            case "input_json_delta":
                partialInputs[index, default: ""] += delta["partial_json"] as? String ?? ""
                return .nothing
            case "citations_delta":
                var citations = block["citations"] as? [Any] ?? []
                if let citation = delta["citation"] { citations.append(citation) }
                block["citations"] = citations
                return .nothing
            default:
                return .nothing
            }

        case "content_block_stop":
            guard index >= 0, var block = blocks[index], block["type"] as? String == "tool_use" else { return .nothing }
            let raw = partialInputs[index] ?? ""
            if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // A call with no arguments streams no input at all.
                if !(block["input"] is [String: Any]) { block["input"] = [String: Any]() }
            } else if let bytes = raw.data(using: .utf8),
                      let input = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any] {
                block["input"] = input
            } else {
                block["input"] = [String: Any]()
                block[Self.invalidInputKey] = raw
            }
            blocks[index] = block
            return .nothing

        case "message_delta":
            let delta = event["delta"] as? [String: Any] ?? [:]
            if let reason = delta["stop_reason"] as? String { stopReason = reason }
            if let details = delta["stop_details"] as? [String: Any] { stopCategory = details["category"] as? String }
            readUsage(event["usage"] as? [String: Any])
            return .nothing

        case "message_stop":
            sawMessageStop = true
            return .nothing

        case "error":
            let error = event["error"] as? [String: Any] ?? [:]
            let message = error["message"] as? String ?? "The reply was interrupted."
            failure = message
            return .failed(message)

        default:
            return .nothing   // ping, and anything added later
        }
    }

    private mutating func readUsage(_ usage: [String: Any]?) {
        guard let usage else { return }
        func number(_ key: String) -> Int? { (usage[key] as? NSNumber)?.intValue }
        if let n = number("input_tokens") { inputTokens = n }
        if let n = number("output_tokens") { outputTokens = n }
        if let n = number("cache_read_input_tokens") { cacheReadTokens = n }
        if let n = number("cache_creation_input_tokens") { cacheWriteTokens = n }
    }

    /// The reply's blocks in order, with this type's private marker on
    /// unparseable tool inputs still attached (`AnthropicWire.toolCalls`
    /// reads it; `AnthropicWire.echo` output must go through `sendable`).
    var content: [[String: Any]] {
        blocks.keys.sorted().compactMap { blocks[$0] }
    }

    /// `blocks` without the private marker, safe to send back to the API.
    static func sendable(_ blocks: [[String: Any]]) -> [[String: Any]] {
        blocks.map { block in
            guard block[invalidInputKey] != nil else { return block }
            var clean = block
            clean.removeValue(forKey: invalidInputKey)
            return clean
        }
    }

    /// Whether a tool call's input may have been cut short (the reply hit
    /// its length limit, or the stream ended without saying it was done).
    var endedMidReply: Bool { !sawMessageStop || stopReason == nil }
}

// MARK: - Server-sent event lines

nonisolated enum ServerSentEvents {
    /// The payload of a `data:` line, or nil for every other line (`event:`,
    /// comments, blanks). Each Messages API event is one complete JSON
    /// object on one `data:` line, so no joining across lines is needed.
    static func dataPayload(ofLine line: String) -> String? {
        guard line.hasPrefix("data:") else { return nil }
        var payload = Substring(line.dropFirst(5))
        if payload.first == " " { payload = payload.dropFirst() }
        return payload.isEmpty ? nil : String(payload)
    }
}
