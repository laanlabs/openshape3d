//
//  OpenAIWire.swift
//  openshape3d
//
//  The built-in assistant's side of OpenAI's Responses API, as pure values:
//  the counterpart of `AssistantWire.swift` (Claude) for a person who brings
//  an OpenAI API key. Unit-tested without a network (`AssistantProviderTests`).
//
//  `POST /v1/responses` with `stream: true`, read as server-sent events. The
//  conversation is kept here (`store: false`), not on OpenAI's side: every
//  request carries the whole `input`, and each reply's output items go back
//  into it unchanged, reasoning items included, as the API asks.
//
//  Shapes follow OpenAI's reference as read on 2026-11-26. The Responses API
//  is used and not Chat Completions because the current flagship models only
//  call tools through it.
//

import Foundation

nonisolated enum OpenAIWire {

    static let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    static let models: [AssistantModel] = [
        AssistantModel(id: "gpt-6.2-sol", name: "GPT-6.2 Sol", note: "Recommended", retriesDeclines: false),
        AssistantModel(id: "gpt-6.2-astra", name: "GPT-6.2 Astra", note: "Most capable, highest cost", retriesDeclines: false),
        AssistantModel(id: "gpt-6.1-terra", name: "GPT-6.1 Terra", note: "Faster, lower cost", retriesDeclines: false),
        AssistantModel(id: "gpt-6-luna", name: "GPT-6 Luna", note: "Fastest, lowest cost", retriesDeclines: false),
    ]
    static let defaultModelID = "gpt-6.2-sol"

    // MARK: - Request

    /// The MCP tool list as Responses function tools. `strict` is off: the
    /// tool's `args` is a free-form object, which strict mode does not allow.
    static func tools(fromMCP mcpTools: [[String: Any]]) -> [[String: Any]] {
        mcpTools.compactMap { tool in
            guard let name = tool["name"] as? String, name == AnthropicWire.toolName,
                  let description = tool["description"] as? String,
                  let schema = tool["inputSchema"] as? [String: Any] else { return nil }
            return ["type": "function", "name": name, "description": description,
                    "parameters": schema, "strict": false]
        }
    }

    static func requestBody(model: AssistantModel, system: String, tools: [[String: Any]],
                            input: [[String: Any]]) -> [String: Any] {
        [
            "model": model.id,
            "instructions": system,
            "input": input,
            "tools": tools,
            "stream": true,
            // The conversation lives on this device; nothing is kept for it
            // on OpenAI's side beyond what its API terms say.
            "store": false,
        ]
    }

    static func headers(apiKey: String) -> [String: String] {
        ["content-type": "application/json",
         "accept": "text/event-stream",
         "authorization": "Bearer " + apiKey]
    }

    // MARK: - Conversation shapes

    static func appendUserText(_ text: String, to input: inout [[String: Any]]) {
        input.append(["role": "user", "content": [["type": "input_text", "text": text]]])
    }

    /// Take back the person's last message when nothing answered it.
    static func removePendingUserText(from input: inout [[String: Any]]) {
        if let last = input.last, last["role"] as? String == "user" { input.removeLast() }
    }

    /// A tool answer as a `function_call_output` item. Text alone is a
    /// string; a picture makes it an array of text and image parts.
    static func toolOutput(callID: String, content: [AnthropicWire.ToolContent], isError: Bool) -> [String: Any] {
        var texts: [String] = []
        var images: [[String: Any]] = []
        for piece in content {
            switch piece {
            case .text(let text):
                if !text.isEmpty { texts.append(text) }
            case let .image(mediaType, base64):
                images.append(["type": "input_image", "image_url": "data:\(mediaType);base64,\(base64)"])
            }
        }
        var text = texts.joined(separator: "\n")
        if text.isEmpty { text = images.isEmpty ? "Done." : "The picture is attached." }
        // There is no error flag on this item: a failure has to read as one.
        if isError, !Self.looksLikeJSONObject(text) { text = "Error: " + text }
        var item: [String: Any] = ["type": "function_call_output", "call_id": callID]
        if images.isEmpty {
            item["output"] = text
        } else {
            item["output"] = [["type": "input_text", "text": text] as [String: Any]] + images
        }
        return item
    }

    static func looksLikeJSONObject(_ text: String) -> Bool {
        guard text.first == "{", let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) is [String: Any]
    }

    // MARK: - Errors

    /// A failed request, in words for the panel. The body is
    /// `{"error": {"message", "type", "code", "param"}}`.
    static func errorMessage(status: Int, body: Data) -> String {
        let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        let error = object?["error"] as? [String: Any]
        let detail = (error?["message"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = (error?["type"] as? String ?? "") + " " + (error?["code"] as? String ?? "")
        func with(_ lead: String) -> String { detail.isEmpty ? lead : lead + " (" + detail + ")" }
        switch status {
        case 401:
            return "OpenAI did not accept this API key. Check the key in the assistant's settings."
        case 403:
            return with("This key is not allowed to do that.")
        case 404:
            return with("This model is not available to this key. Pick another model in the assistant's settings.")
        case 413:
            return "The conversation has grown too large to send. Start a new chat."
        case 429:
            if kind.contains("insufficient_quota") || kind.contains("credit") || kind.contains("billing") {
                return with("This key's OpenAI account is out of credit or over its spending limit.")
            }
            return with("The key's rate limit was reached. Wait a moment and send again.")
        case 500...599:
            return with("OpenAI's service is busy or had a problem. Try again in a moment.")
        default:
            return detail.isEmpty ? "The request failed (HTTP \(status))." : detail
        }
    }

    static func isWorthRetrying(status: Int) -> Bool {
        status == 500 || status == 502 || status == 503 || status == 504
    }
}

// MARK: - A streamed reply, put back together

/// Feed it the `data:` payload of each server-sent event. Every event is a
/// JSON object with a `type`. The last one (`response.completed`,
/// `.incomplete` or `.failed`) carries the whole response, which is what the
/// reply is read from; the items collected along the way are the fallback.
nonisolated struct OpenAIStream {

    private var finished: [String: Any]?
    private var items: [[String: Any]] = []
    private(set) var failure: String?
    private var sawText = false

    mutating func consume(data payload: String) -> AssistantStreamUpdate {
        guard let bytes = payload.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let type = event["type"] as? String else { return .nothing }

        switch type {
        case "response.output_text.delta":
            let piece = event["delta"] as? String ?? ""
            if !piece.isEmpty { sawText = true }
            return piece.isEmpty ? .nothing : .text(piece)

        case "response.output_item.added":
            let item = event["item"] as? [String: Any] ?? [:]
            switch item["type"] as? String {
            case "function_call": return .toolStarted(name: item["name"] as? String ?? "")
            case "reasoning": return .thinking
            default: return .nothing
            }

        case "response.output_item.done":
            if let item = event["item"] as? [String: Any] { items.append(item) }
            return .nothing

        case "response.completed", "response.incomplete":
            finished = event["response"] as? [String: Any] ?? [:]
            return .nothing

        case "response.failed":
            let response = event["response"] as? [String: Any] ?? [:]
            finished = response
            let message = (response["error"] as? [String: Any])?["message"] as? String
            failure = message ?? "The reply failed."
            return .failed(failure ?? "")

        case "error":
            let nested = event["error"] as? [String: Any]
            let message = event["message"] as? String ?? nested?["message"] as? String ?? "The reply was interrupted."
            failure = message
            return .failed(message)

        default:
            return .nothing
        }
    }

    var isEmpty: Bool { items.isEmpty && !sawText && finished == nil }

    /// The stream ended without its closing event.
    var endedMidReply: Bool { finished == nil }

    /// The reply's output items, exactly as received.
    var output: [[String: Any]] {
        if let whole = finished?["output"] as? [[String: Any]], !whole.isEmpty { return whole }
        return items
    }

    var reply: AssistantReply {
        let output = self.output
        var calls: [AnthropicWire.ToolCall] = []
        var refusal: String?
        for item in output {
            switch item["type"] as? String {
            case "function_call":
                let raw = item["arguments"] as? String ?? ""
                var input: [String: Any] = [:]
                var invalid: String?
                if raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    input = [:]
                } else if let bytes = raw.data(using: .utf8),
                          let parsed = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any] {
                    input = parsed
                } else {
                    invalid = raw
                }
                calls.append(AnthropicWire.ToolCall(id: item["call_id"] as? String ?? item["id"] as? String ?? "",
                                                    name: item["name"] as? String ?? "",
                                                    input: input, invalidInput: invalid))
            case "message":
                for part in item["content"] as? [[String: Any]] ?? [] where part["type"] as? String == "refusal" {
                    refusal = part["refusal"] as? String ?? ""
                }
            default: break
            }
        }

        let status = finished?["status"] as? String
        let reason = (finished?["incomplete_details"] as? [String: Any])?["reason"] as? String
        let outcome: AssistantReply.Outcome
        if refusal != nil || reason == "content_filter" {
            outcome = .declined
        } else if status == "incomplete" {
            outcome = .cutOff
        } else if !calls.isEmpty {
            outcome = .toolCalls
        } else {
            outcome = .done
        }

        let usage = finished?["usage"] as? [String: Any] ?? [:]
        return AssistantReply(history: output, calls: calls, outcome: outcome,
                              tokensIn: (usage["input_tokens"] as? NSNumber)?.intValue ?? 0,
                              tokensOut: (usage["output_tokens"] as? NSNumber)?.intValue ?? 0)
    }
}
