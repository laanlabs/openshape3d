//
//  GeminiWire.swift
//  openshape3d
//
//  The built-in assistant's side of Google's Gemini API, as pure values: the
//  counterpart of `AssistantWire.swift` (Claude) for a person who brings a
//  Gemini API key. Unit-tested without a network (`AssistantProviderTests`).
//
//  `POST …/v1beta/models/{model}:streamGenerateContent?alt=sse`, where each
//  `data:` line is a whole response chunk. The key goes in the
//  `x-goog-api-key` header, never in the URL.
//
//  Shapes follow Google's reference as read on 2026-11-26. Two rules there
//  shape this file: a reply's parts go back exactly as they came (a function
//  call carries a `thoughtSignature` the API checks), and all the answers to
//  one reply's calls go back together in one message.
//

import Foundation

nonisolated enum GeminiWire {

    static let models: [AssistantModel] = [
        AssistantModel(id: "gemini-4-hydrogen", name: "Gemini 4 Hydrogen", note: "Recommended", retriesDeclines: false),
        AssistantModel(id: "gemini-4-carbon", name: "Gemini 4 Carbon", note: "Strongest reasoning, highest cost", retriesDeclines: false),
        AssistantModel(id: "gemini-3.8-flash", name: "Gemini 3.8 Flash", note: "Faster, lower cost", retriesDeclines: false),
        AssistantModel(id: "gemini-3.5-flash-lite", name: "Gemini 3.5 Flash-Lite", note: "Fastest, lowest cost", retriesDeclines: false),
    ]
    static let defaultModelID = "gemini-4-hydrogen"

    static func endpoint(model: AssistantModel) -> URL {
        let id = model.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model.id
        return URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(id):streamGenerateContent?alt=sse")!
    }

    // MARK: - Request

    /// The MCP tool list as function declarations.
    ///
    /// Normally the tool's own JSON Schema is passed as it is
    /// (`parametersJsonSchema`). Its `args` is a free-form object, and whether
    /// every model accepts one is not something Google's reference settles;
    /// `argsAsText` is the fallback, where `args` is declared as a string
    /// holding a JSON object (`AssistantToolCall` reads either).
    static func tools(fromMCP mcpTools: [[String: Any]], argsAsText: Bool) -> [[String: Any]] {
        let declarations: [[String: Any]] = mcpTools.compactMap { tool in
            guard let name = tool["name"] as? String, name == AnthropicWire.toolName,
                  let description = tool["description"] as? String,
                  let schema = tool["inputSchema"] as? [String: Any] else { return nil }
            guard argsAsText else {
                return ["name": name, "description": description, "parametersJsonSchema": schema]
            }
            let op = (schema["properties"] as? [String: Any])?["op"] as? [String: Any]
            return ["name": name, "description": description, "parameters": [
                "type": "object",
                "properties": [
                    "op": ["type": "string", "description": op?["description"] as? String ?? "Operation name."],
                    "args": ["type": "string",
                             "description": "The operation's arguments: a JSON object written out as text, "
                                          + "for example {\"body\": \"…\"}. Leave out when the operation takes none."],
                ],
                "required": ["op"],
            ] as [String: Any]]
        }
        return declarations.isEmpty ? [] : [["functionDeclarations": declarations]]
    }

    static func requestBody(system: String, tools: [[String: Any]], contents: [[String: Any]]) -> [String: Any] {
        ["systemInstruction": ["parts": [["text": system]]],
         "contents": contents,
         "tools": tools]
    }

    static func headers(apiKey: String) -> [String: String] {
        ["content-type": "application/json",
         "accept": "text/event-stream",
         "x-goog-api-key": apiKey]
    }

    // MARK: - Conversation shapes

    private static func isPlainUserText(_ content: [String: Any]) -> Bool {
        guard content["role"] as? String == "user", let parts = content["parts"] as? [[String: Any]] else { return false }
        return !parts.isEmpty && parts.allSatisfy { $0["text"] != nil && $0.count == 1 }
    }

    /// Add what the person typed. A message of theirs that nothing answered
    /// yet takes the text as another part.
    static func appendUserText(_ text: String, to contents: inout [[String: Any]]) {
        if let last = contents.last, isPlainUserText(last) {
            var parts = last["parts"] as? [[String: Any]] ?? []
            parts.append(["text": text])
            contents[contents.count - 1]["parts"] = parts
        } else {
            contents.append(["role": "user", "parts": [["text": text]]])
        }
    }

    static func removePendingUserText(from contents: inout [[String: Any]]) {
        if let last = contents.last, isPlainUserText(last) { contents.removeLast() }
    }

    /// The answers to one reply's calls, together in one user message, in the
    /// order the calls were made.
    static func toolResults(_ results: [(call: AnthropicWire.ToolCall, content: [AnthropicWire.ToolContent], isError: Bool)])
        -> [String: Any] {
        let parts: [[String: Any]] = results.map { result in
            var texts: [String] = []
            var media: [[String: Any]] = []
            for piece in result.content {
                switch piece {
                case .text(let text):
                    if !text.isEmpty { texts.append(text) }
                case let .image(mediaType, base64):
                    media.append(["inlineData": ["mimeType": mediaType, "data": base64]])
                }
            }
            let text = texts.joined(separator: "\n")
            // `response` must be an object. A JSON answer is passed as the
            // object it is; anything else is wrapped.
            let parsed = (text.data(using: .utf8)).flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
            var response: [String: Any]
            if result.isError {
                response = ["error": parsed ?? (text.isEmpty ? "It did not work." : text) as Any]
            } else if let parsed {
                response = parsed
            } else {
                response = ["result": text.isEmpty ? (media.isEmpty ? "Done." : "The picture is attached.") : text]
            }
            if response.isEmpty { response = ["result": "Done."] }
            var functionResponse: [String: Any] = ["name": result.call.name, "response": response]
            // The id the model gave the call, when it gave one.
            if !result.call.id.isEmpty, !result.call.id.hasPrefix(GeminiStream.localIDPrefix) {
                functionResponse["id"] = result.call.id
            }
            if !media.isEmpty { functionResponse["parts"] = media }
            return ["functionResponse": functionResponse]
        }
        return ["role": "user", "parts": parts]
    }

    // MARK: - Errors

    /// A failed request, in words for the panel. The body is
    /// `{"error": {"code", "message", "status", "details": [{"reason"}]}}`.
    static func errorMessage(status: Int, body: Data) -> String {
        let error = Self.error(in: body)
        let detail = (error["message"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let reasons = (error["details"] as? [[String: Any]] ?? []).compactMap { $0["reason"] as? String }
        let state = error["status"] as? String ?? ""
        func with(_ lead: String) -> String { detail.isEmpty ? lead : lead + " (" + detail + ")" }
        if reasons.contains("API_KEY_INVALID") || status == 401 {
            return "Google did not accept this API key. Check the key in the assistant's settings."
        }
        switch status {
        case 403:
            return with("This key is not allowed to do that.")
        case 404:
            return with("This model is not available to this key. Pick another model in the assistant's settings.")
        case 413:
            return "The conversation has grown too large to send. Start a new chat."
        case 429:
            return with("The key's rate limit or quota was reached. Wait a moment and send again.")
        case 500...599:
            return with("Google's service is busy or had a problem. Try again in a moment.")
        default:
            if state == "RESOURCE_EXHAUSTED" { return with("The key's rate limit or quota was reached.") }
            return detail.isEmpty ? "The request failed (HTTP \(status))." : detail
        }
    }

    private static func error(in body: Data) -> [String: Any] {
        let parsed = try? JSONSerialization.jsonObject(with: body)
        // The streaming endpoint may wrap the error object in an array.
        let object = parsed as? [String: Any] ?? (parsed as? [[String: Any]])?.first
        return object?["error"] as? [String: Any] ?? [:]
    }

    /// True when a 400 is about how the tool was declared, so the request is
    /// worth sending again with `args` declared as text.
    static func isAboutToolSchema(status: Int, body: Data) -> Bool {
        guard status == 400 else { return false }
        let error = Self.error(in: body)
        if (error["details"] as? [[String: Any]] ?? []).contains(where: { $0["reason"] as? String == "API_KEY_INVALID" }) {
            return false
        }
        let text = (error["message"] as? String ?? "").lowercased()
        return ["function_declarations", "functiondeclarations", "parameters_json_schema", "parametersjsonschema",
                "schema", "properties"].contains { text.contains($0) }
    }

    static func isWorthRetrying(status: Int) -> Bool {
        status == 500 || status == 502 || status == 503 || status == 504
    }
}

// MARK: - A streamed reply, put back together

/// Feed it the `data:` payload of each server-sent event: each is a whole
/// `GenerateContentResponse` chunk. Text arrives a piece per chunk; a
/// function call arrives whole.
nonisolated struct GeminiStream {

    /// Prefix of the ids made up here for calls the model sent without one.
    static let localIDPrefix = "local-call-"

    private var parts: [[String: Any]] = []
    private var finishReason: String?
    private var blockReason: String?
    private(set) var failure: String?
    private var tokensIn = 0
    private var tokensOut = 0

    private static let declinedReasons: Set<String> = [
        "SAFETY", "RECITATION", "BLOCKLIST", "PROHIBITED_CONTENT", "SPII", "LANGUAGE",
        "IMAGE_SAFETY", "IMAGE_PROHIBITED_CONTENT",
    ]
    private static let brokenReasons: [String: String] = [
        "MALFORMED_FUNCTION_CALL": "Gemini wrote a tool call that could not be read. Try sending the message again.",
        "UNEXPECTED_TOOL_CALL": "Gemini tried to call a tool that does not exist here. Try sending the message again.",
        "TOO_MANY_TOOL_CALLS": "Gemini asked for too many tool calls at once. Try asking for less in one message.",
        "MISSING_THOUGHT_SIGNATURE": "Google refused the conversation as sent. Start a new chat.",
        "MALFORMED_RESPONSE": "Gemini's reply could not be read. Try sending the message again.",
    ]

    mutating func consume(data payload: String) -> AssistantStreamUpdate {
        guard let bytes = payload.data(using: .utf8),
              let chunk = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any] else { return .nothing }

        if let error = chunk["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "The reply was interrupted."
            failure = message
            return .failed(message)
        }
        if let usage = chunk["usageMetadata"] as? [String: Any] {
            func number(_ key: String) -> Int { (usage[key] as? NSNumber)?.intValue ?? 0 }
            tokensIn = number("promptTokenCount") + number("toolUsePromptTokenCount")
            tokensOut = number("candidatesTokenCount") + number("thoughtsTokenCount")
        }
        if let feedback = chunk["promptFeedback"] as? [String: Any], let reason = feedback["blockReason"] as? String,
           reason != "BLOCK_REASON_UNSPECIFIED" {
            blockReason = reason
        }
        guard let candidate = (chunk["candidates"] as? [[String: Any]])?.first else { return .nothing }
        if let reason = candidate["finishReason"] as? String, reason != "FINISH_REASON_UNSPECIFIED" {
            finishReason = reason
        }

        var update = AssistantStreamUpdate.nothing
        var shown = ""
        for part in (candidate["content"] as? [String: Any])?["parts"] as? [[String: Any]] ?? [] {
            if let call = part["functionCall"] as? [String: Any] {
                parts.append(part)
                update = .toolStarted(name: call["name"] as? String ?? "")
            } else if part["thought"] as? Bool == true {
                parts.append(part)
                if case .nothing = update { update = .thinking }
            } else if let text = part["text"] as? String, part.count == 1 {
                // Plain text: pieces of one answer are joined back together.
                if let last = parts.last, last.count == 1, let soFar = last["text"] as? String {
                    parts[parts.count - 1]["text"] = soFar + text
                } else if !text.isEmpty {
                    parts.append(part)
                }
                shown += text
            } else {
                // Anything else, a part carrying a signature above all, goes
                // back exactly as it came.
                parts.append(part)
                if let text = part["text"] as? String { shown += text }
            }
        }
        if !shown.isEmpty { return .text(shown) }
        return update
    }

    var isEmpty: Bool { parts.isEmpty && finishReason == nil && blockReason == nil }

    /// The stream ended without saying why the reply stopped.
    var endedMidReply: Bool { finishReason == nil && blockReason == nil }

    /// What a reply that stopped for a reason the person should hear about
    /// says, or nil for an ordinary stop.
    var brokenReply: String? { finishReason.flatMap { Self.brokenReasons[$0] } }

    var reply: AssistantReply {
        var calls: [AnthropicWire.ToolCall] = []
        for part in parts {
            guard let call = part["functionCall"] as? [String: Any] else { continue }
            let id = (call["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? Self.localIDPrefix + String(calls.count + 1)
            calls.append(AnthropicWire.ToolCall(id: id, name: call["name"] as? String ?? "",
                                                input: call["args"] as? [String: Any] ?? [:], invalidInput: nil))
        }
        let outcome: AssistantReply.Outcome
        if blockReason != nil || finishReason.map(Self.declinedReasons.contains) == true {
            outcome = .declined
        } else if finishReason == "MAX_TOKENS" {
            outcome = .cutOff
        } else if !calls.isEmpty {
            outcome = .toolCalls
        } else {
            outcome = .done
        }
        return AssistantReply(history: parts.isEmpty ? [] : [["role": "model", "parts": parts]],
                              calls: calls, outcome: outcome, tokensIn: tokensIn, tokensOut: tokensOut)
    }
}
