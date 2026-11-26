//
//  AssistantProvider.swift
//  openshape3d
//
//  Whose model the built-in assistant talks to. The person picks one and
//  brings their own API key for it: Claude (Anthropic), ChatGPT's models
//  (OpenAI) or Gemini (Google).
//
//  The three APIs differ in everything but the idea: the request, the
//  streamed reply, how a tool call and its answer are written, how a
//  conversation is kept. Each has its own wire file (`AssistantWire.swift`,
//  `OpenAIWire.swift`, `GeminiWire.swift`). This file is the switchboard that
//  lets `AssistantSession` run one loop over any of them: it asks the
//  provider to build a request, hands the stream's events to it, and gets
//  back an `AssistantReply` in terms the loop understands.
//
//  A conversation is in its provider's own shape, so changing provider starts
//  a new chat. The tool, the modelling guide and the preamble are the same
//  for all three.
//

import Foundation

typealias AssistantToolCall = AnthropicWire.ToolCall
typealias AssistantToolContent = AnthropicWire.ToolContent
typealias AssistantStreamUpdate = AnthropicStream.Update

/// One reply, read off the wire, in terms the conversation loop understands.
nonisolated struct AssistantReply {
    enum Outcome: Equatable {
        /// The model asked for tool calls and is waiting for their answers.
        case toolCalls
        /// The model has finished its turn.
        case done
        /// The reply hit its length limit (its tool calls, if any, may be cut short).
        case cutOff
        /// The provider declined to answer.
        case declined
        /// The API paused its own work; sending the same conversation resumes it.
        case paused
    }
    /// What goes into the conversation for this reply, in the provider's shape.
    var history: [[String: Any]]
    var calls: [AssistantToolCall]
    var outcome: Outcome
    var tokensIn = 0
    var tokensOut = 0
}

/// What a request can be asked to do differently after the API refused the
/// first form of it.
nonisolated struct AssistantRequestOptions: Equatable {
    /// Claude: ask the API to retry a declined reply on another model.
    var retryDeclines = true
    /// Gemini: declare the tool's `args` as text instead of a free-form object.
    var argsAsText = false
}

nonisolated enum AssistantProvider: String, CaseIterable, Identifiable, Sendable {
    case anthropic, openai, google

    var id: String { rawValue }

    /// The assistant's name, as people know it.
    var name: String {
        switch self {
        case .anthropic: return "Claude"
        case .openai: return "ChatGPT"
        case .google: return "Gemini"
        }
    }

    /// Who receives the requests and bills the key.
    var company: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        case .google: return "Google"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .anthropic: return "Claude API key (sk-ant-…)"
        case .openai: return "OpenAI API key (sk-…)"
        case .google: return "Gemini API key (AIza…)"
        }
    }

    /// Where a key is made.
    var keysPage: URL {
        switch self {
        case .anthropic: return URL(string: "https://platform.claude.com/settings/keys")!
        case .openai: return URL(string: "https://platform.openai.com/api-keys")!
        case .google: return URL(string: "https://aistudio.google.com/apikey")!
        }
    }

    var models: [AssistantModel] {
        switch self {
        case .anthropic: return AnthropicWire.models
        case .openai: return OpenAIWire.models
        case .google: return GeminiWire.models
        }
    }

    var defaultModelID: String {
        switch self {
        case .anthropic: return AnthropicWire.defaultModelID
        case .openai: return OpenAIWire.defaultModelID
        case .google: return GeminiWire.defaultModelID
        }
    }

    func model(_ id: String?) -> AssistantModel {
        models.first { $0.id == id } ?? models.first { $0.id == defaultModelID } ?? models[0]
    }

    // MARK: - Request

    /// Everything a request needs: where it goes, its headers and its body.
    func request(apiKey: String, model: AssistantModel, system: String, mcpTools: [[String: Any]],
                 conversation: [[String: Any]], options: AssistantRequestOptions)
        -> (url: URL, headers: [String: String], body: Data) {
        switch self {
        case .anthropic:
            let body = AnthropicWire.requestBody(model: model, system: system, tools: AnthropicWire.tools(fromMCP: mcpTools),
                                                 messages: conversation, retryDeclines: options.retryDeclines)
            return (AnthropicWire.endpoint,
                    AnthropicWire.headers(apiKey: apiKey, model: model, retryDeclines: options.retryDeclines),
                    AnthropicWire.encode(body))
        case .openai:
            let body = OpenAIWire.requestBody(model: model, system: system, tools: OpenAIWire.tools(fromMCP: mcpTools),
                                              input: conversation)
            return (OpenAIWire.endpoint, OpenAIWire.headers(apiKey: apiKey), AnthropicWire.encode(body))
        case .google:
            let tools = GeminiWire.tools(fromMCP: mcpTools, argsAsText: options.argsAsText)
            let body = GeminiWire.requestBody(system: system, tools: tools, contents: conversation)
            return (GeminiWire.endpoint(model: model), GeminiWire.headers(apiKey: apiKey), AnthropicWire.encode(body))
        }
    }

    // MARK: - Conversation

    func appendUserText(_ text: String, to conversation: inout [[String: Any]]) {
        switch self {
        case .anthropic: AnthropicWire.appendUserText(text, to: &conversation)
        case .openai: OpenAIWire.appendUserText(text, to: &conversation)
        case .google: GeminiWire.appendUserText(text, to: &conversation)
        }
    }

    /// Take back the person's last message when the provider declined it, so
    /// the next one starts clean. A message that carries tool answers stays.
    func removePendingUserText(from conversation: inout [[String: Any]]) {
        switch self {
        case .anthropic:
            if let last = conversation.last, last["role"] as? String == "user",
               !((last["content"] as? [[String: Any]]) ?? []).contains(where: { $0["type"] as? String == "tool_result" }) {
                conversation.removeLast()
            }
        case .openai: OpenAIWire.removePendingUserText(from: &conversation)
        case .google: GeminiWire.removePendingUserText(from: &conversation)
        }
    }

    /// Put the answers to one reply's calls into the conversation.
    func appendToolResults(_ results: [(call: AssistantToolCall, content: [AssistantToolContent], isError: Bool)],
                           to conversation: inout [[String: Any]]) {
        guard !results.isEmpty else { return }
        switch self {
        case .anthropic:
            // Every call is answered, in one message, before anything else is said.
            conversation.append(["role": "user", "content": results.map {
                AnthropicWire.toolResult(id: $0.call.id, content: $0.content, isError: $0.isError)
            }])
        case .openai:
            for result in results {
                conversation.append(OpenAIWire.toolOutput(callID: result.call.id, content: result.content,
                                                          isError: result.isError))
            }
        case .google:
            conversation.append(GeminiWire.toolResults(results))
        }
    }

    // MARK: - Failures

    func errorMessage(status: Int, body: Data) -> String {
        switch self {
        case .anthropic: return AnthropicWire.errorMessage(status: status, body: body)
        case .openai: return OpenAIWire.errorMessage(status: status, body: body)
        case .google: return GeminiWire.errorMessage(status: status, body: body)
        }
    }

    func isWorthRetrying(status: Int) -> Bool {
        switch self {
        case .anthropic: return AnthropicWire.isWorthRetrying(status: status)
        case .openai: return OpenAIWire.isWorthRetrying(status: status)
        case .google: return GeminiWire.isWorthRetrying(status: status)
        }
    }

    /// When the API refused the request for a reason another form of it
    /// avoids, switch `options` to that form and say so.
    func adjust(_ options: inout AssistantRequestOptions, afterStatus status: Int, body: Data) -> Bool {
        switch self {
        case .anthropic:
            guard options.retryDeclines, AnthropicWire.isAboutDeclineRetry(status: status, body: body) else { return false }
            options.retryDeclines = false
            return true
        case .openai:
            return false
        case .google:
            guard !options.argsAsText, GeminiWire.isAboutToolSchema(status: status, body: body) else { return false }
            options.argsAsText = true
            return true
        }
    }
}

// MARK: - One streamed reply being read

nonisolated enum AssistantStream {
    case anthropic(AnthropicStream)
    case openai(OpenAIStream)
    case google(GeminiStream)

    init(_ provider: AssistantProvider) {
        switch provider {
        case .anthropic: self = .anthropic(AnthropicStream())
        case .openai: self = .openai(OpenAIStream())
        case .google: self = .google(GeminiStream())
        }
    }

    mutating func consume(data payload: String) -> AssistantStreamUpdate {
        switch self {
        case .anthropic(var stream):
            let update = stream.consume(data: payload)
            self = .anthropic(stream)
            return update
        case .openai(var stream):
            let update = stream.consume(data: payload)
            self = .openai(stream)
            return update
        case .google(var stream):
            let update = stream.consume(data: payload)
            self = .google(stream)
            return update
        }
    }

    /// The provider said, in the stream, that the reply failed.
    var failure: String? {
        switch self {
        case .anthropic(let stream): return stream.failure
        case .openai(let stream): return stream.failure
        case .google(let stream): return stream.failure ?? stream.brokenReply
        }
    }

    /// The connection closed before the reply said it was done.
    var endedMidReply: Bool {
        switch self {
        case .anthropic(let stream): return stream.endedMidReply
        case .openai(let stream): return stream.endedMidReply
        case .google(let stream): return stream.endedMidReply
        }
    }

    var reply: AssistantReply {
        var reply: AssistantReply
        switch self {
        case .anthropic(let stream): reply = AnthropicWire.reply(from: stream)
        case .openai(let stream): reply = stream.reply
        case .google(let stream): reply = stream.reply
        }
        reply.calls = reply.calls.map(Self.withArgsAsObject)
        return reply
    }

    /// A model told to write `args` as text (Gemini's fallback declaration),
    /// or one that did so unasked, still means an object: read it as one.
    static func withArgsAsObject(_ call: AssistantToolCall) -> AssistantToolCall {
        guard let text = call.input["args"] as? String else { return call }
        var call = call
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            call.input.removeValue(forKey: "args")
        } else if let data = trimmed.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            call.input["args"] = object
        }
        return call
    }
}

extension AnthropicWire {
    /// A finished Claude stream as a provider-neutral reply.
    static func reply(from stream: AnthropicStream) -> AssistantReply {
        let content = stream.content
        let calls = toolCalls(in: content)
        let outcome: AssistantReply.Outcome
        switch stream.stopReason {
        case "refusal": outcome = .declined
        case "pause_turn": outcome = .paused
        case "max_tokens": outcome = .cutOff
        case "tool_use" where !calls.isEmpty: outcome = .toolCalls
        default: outcome = .done
        }
        // Nothing of a declined reply is kept.
        let echoed = outcome == .declined ? [] : AnthropicStream.sendable(echo(content))
        return AssistantReply(history: echoed.isEmpty ? [] : [["role": "assistant", "content": echoed]],
                              calls: outcome == .declined ? [] : calls, outcome: outcome,
                              tokensIn: stream.inputTokens + stream.cacheReadTokens + stream.cacheWriteTokens,
                              tokensOut: stream.outputTokens)
    }
}
