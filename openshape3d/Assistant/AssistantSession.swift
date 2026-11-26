//
//  AssistantSession.swift
//  openshape3d
//
//  One conversation with the built-in assistant (#119): what the panel
//  shows, and the loop behind it. The person types; the request goes to
//  Claude with their own key; when the reply asks for a tool, the call runs
//  against the open design (`AssistantTools`) and the answer goes back, until
//  the model has nothing more to do or the person presses Stop.
//
//  The loop is written out here rather than taken from an SDK because Swift
//  has none for this API. The wire shapes are in `AssistantWire`.
//
//  A conversation lives as long as its editor: it is not saved with the
//  design, and closing the design ends it.
//

import Foundation
import Observation

@Observable
final class AssistantSession {

    // MARK: What the panel shows

    struct Entry: Identifiable, Equatable {
        enum Progress: Equatable { case running, done, failed(String) }
        enum Kind: Equatable {
            case user(String)
            case reply(String)
            case activity(String, Progress)
            case notice(String)
            case problem(String)
        }
        let id = UUID()
        var kind: Kind
    }

    private(set) var entries: [Entry] = []
    private(set) var isRunning = false
    /// "Thinking…" and the like, while a reply is on its way.
    private(set) var status: String?
    private(set) var hasKey: Bool
    /// Tokens this conversation has used so far, as the API reported them.
    private(set) var tokensIn = 0
    private(set) var tokensOut = 0

    var modelID: String {
        didSet { UserDefaults.standard.set(modelID, forKey: Self.modelKey) }
    }
    var model: AssistantModel { AnthropicWire.model(modelID) }

    // MARK: Behind it

    private static let modelKey = "assistant.model"
    /// Requests in one turn before the assistant stops and says so. A long
    /// build is a few dozen; this is the guard against a loop that never ends.
    static let maxRequestsPerTurn = 80

    @ObservationIgnored private var messages: [[String: Any]] = []
    @ObservationIgnored private var task: Task<Void, Never>?
    /// Cleared when the API says this key cannot use the decline-retry feature.
    @ObservationIgnored private var retryDeclines = true
    @ObservationIgnored private let endpoint: URL
    @ObservationIgnored private let fixedKey: String?
    @ObservationIgnored private let urlSession: URLSession

    init() {
        var endpoint = AnthropicWire.endpoint
        var fixedKey: String?
        #if DEBUG
        // UI tests: a stand-in server on this machine and a key that is not one.
        let environment = ProcessInfo.processInfo.environment
        if let raw = environment["OS3D_ASSISTANT_URL"], let url = URL(string: raw) { endpoint = url }
        if let key = environment["OS3D_ASSISTANT_KEY"], !key.isEmpty { fixedKey = key }
        #endif
        self.endpoint = endpoint
        self.fixedKey = fixedKey
        let configuration = URLSessionConfiguration.ephemeral   // no cookies, no cache on disk
        configuration.timeoutIntervalForRequest = 180           // silence between pieces of a reply
        configuration.timeoutIntervalForResource = 60 * 60
        configuration.waitsForConnectivity = false
        urlSession = URLSession(configuration: configuration)
        hasKey = fixedKey != nil || AssistantKeyStore.load() != nil
        let stored = UserDefaults.standard.string(forKey: Self.modelKey) ?? AnthropicWire.defaultModelID
        modelID = AnthropicWire.model(stored).id
    }

    // MARK: Key

    /// Store the key the person pasted. Nil on success, else what to tell them.
    func saveKey(_ pasted: String) -> String? {
        let key = AssistantKeyStore.tidy(pasted)
        guard AssistantKeyStore.isPlausible(key) else {
            return "That does not look like an API key. Paste the whole key, which starts with sk-ant-."
        }
        guard AssistantKeyStore.save(key) else {
            return "The key could not be saved to this device's keychain."
        }
        hasKey = true
        return nil
    }

    func removeKey() {
        stop()
        AssistantKeyStore.remove()
        hasKey = fixedKey != nil
    }

    private var apiKey: String? { fixedKey ?? AssistantKeyStore.load() }

    // MARK: Conversation

    func newChat() {
        stop()
        messages = []
        entries = []
        tokensIn = 0
        tokensOut = 0
        status = nil
    }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isRunning else { return }
        guard let key = apiKey else {
            hasKey = false
            return
        }
        entries.append(Entry(kind: .user(text)))
        AnthropicWire.appendUserText(text, to: &messages)
        isRunning = true
        task = Task { [weak self] in
            await self?.runTurn(key: key)
            self?.finishTurn()
        }
    }

    func stop() {
        task?.cancel()
    }

    private func finishTurn() {
        isRunning = false
        status = nil
        task = nil
        // A row still spinning belongs to a call that never came back.
        for index in entries.indices {
            if case .activity(let label, .running) = entries[index].kind {
                entries[index].kind = .activity(label, .failed("Stopped."))
            }
        }
    }

    // MARK: The loop

    private func runTurn(key: String) async {
        // While the assistant builds, the view follows what it makes, as it
        // does for an assistant connected from outside (`framesAssistantWork`).
        let framedBefore = AgentBridge.shared.framesAssistantWork
        AgentBridge.shared.framesAssistantWork = true
        defer { AgentBridge.shared.framesAssistantWork = framedBefore }

        let system = AnthropicWire.systemPrompt(guide: AgentMCP.guide)
        let tools = AnthropicWire.tools(fromMCP: AgentMCP.tools)

        for _ in 0..<Self.maxRequestsPerTurn {
            if Task.isCancelled { return noteStopped() }

            let reply: AnthropicStream
            do {
                reply = try await request(key: key, system: system, tools: tools)
            } catch is CancellationError {
                return noteStopped()
            } catch let failure as Failure {
                entries.append(Entry(kind: .problem(failure.message)))
                return
            } catch {
                if Task.isCancelled || (error as? URLError)?.code == .cancelled { return noteStopped() }
                entries.append(Entry(kind: .problem(Self.describe(error))))
                return
            }
            tokensIn += reply.inputTokens + reply.cacheReadTokens + reply.cacheWriteTokens
            tokensOut += reply.outputTokens

            let content = reply.content
            let calls = AnthropicWire.toolCalls(in: content)

            if reply.stopReason == "refusal" {
                // Nothing of a declined reply is kept, and the request that
                // drew it is taken back so the next message starts clean.
                if let last = messages.last, last["role"] as? String == "user",
                   !((last["content"] as? [[String: Any]]) ?? []).contains(where: { $0["type"] as? String == "tool_result" }) {
                    messages.removeLast()
                }
                entries.append(Entry(kind: .problem("Claude declined this request, so nothing was changed. "
                                                    + "Try asking in a different way.")))
                return
            }

            let echoed = AnthropicStream.sendable(AnthropicWire.echo(content))
            if !echoed.isEmpty { messages.append(["role": "assistant", "content": echoed]) }

            switch reply.stopReason {
            case "tool_use" where !calls.isEmpty, "max_tokens" where !calls.isEmpty:
                // A reply cut off at its length limit may hold half a call:
                // none of that reply's calls run, and the model is told why.
                let cutOff = reply.stopReason == "max_tokens"
                var results: [[String: Any]] = []
                for call in calls {
                    let row = entries.count
                    let label = AssistantTools.label(op: call.op, args: call.input["args"] as? [String: Any] ?? [:])
                    entries.append(Entry(kind: .activity(label, .running)))
                    let outcome: (content: [AnthropicWire.ToolContent], isError: Bool)
                    if Task.isCancelled {
                        outcome = ([.text("The person pressed Stop before this ran. It was not done.")], true)
                    } else if cutOff {
                        outcome = ([.text("The reply was cut off at its length limit before this call was complete, "
                                          + "so it was not run. Send the call again.")], true)
                    } else {
                        await Task.yield()   // let the row appear before a long operation holds the main thread
                        outcome = AssistantTools.run(call)
                    }
                    entries[row].kind = .activity(label, outcome.isError ? .failed(Self.firstText(outcome.content)) : .done)
                    results.append(AnthropicWire.toolResult(id: call.id, content: outcome.content, isError: outcome.isError))
                }
                // Every call is answered, in one message, before anything else is said.
                messages.append(["role": "user", "content": results])
                if Task.isCancelled { return noteStopped() }
                continue

            case "pause_turn":
                continue   // the API paused its own work; the same conversation resumes it

            case "max_tokens":
                entries.append(Entry(kind: .notice("The reply reached its length limit and was cut short.")))
                return

            default:
                if echoed.isEmpty {
                    entries.append(Entry(kind: .notice("Claude sent an empty reply. Try sending the message again.")))
                }
                return
            }
        }
        entries.append(Entry(kind: .notice("Paused after \(Self.maxRequestsPerTurn) steps. Send “continue” to carry on.")))
    }

    private func noteStopped() {
        entries.append(Entry(kind: .notice("Stopped.")))
    }

    // MARK: One request

    private struct Failure: Error { var message: String }
    private struct HTTPFailure: Error { var status: Int; var body: Data; var retryAfter: Double? }

    /// Send the conversation and read the reply as it streams, showing its
    /// text as it arrives. A request that fails before anything of the reply
    /// was shown is tried again a couple of times when that can help.
    private func request(key: String, system: String, tools: [[String: Any]]) async throws -> AnthropicStream {
        var attempt = 0
        while true {
            attempt += 1
            let mark = entries.count
            status = "Thinking…"
            do {
                return try await requestOnce(key: key, system: system, tools: tools)
            } catch let failure as HTTPFailure {
                entries.removeSubrange(mark...)
                if retryDeclines, AnthropicWire.isAboutDeclineRetry(status: failure.status, body: failure.body) {
                    retryDeclines = false   // this key cannot use it; carry on without
                    continue
                }
                let wait: Double?
                if AnthropicWire.isWorthRetrying(status: failure.status) {
                    wait = Double(attempt) * 2
                } else if failure.status == 429, let after = failure.retryAfter, after <= 20 {
                    wait = max(after, 1)
                } else {
                    wait = nil
                }
                guard attempt < 3, let wait else {
                    throw Failure(message: AnthropicWire.errorMessage(status: failure.status, body: failure.body))
                }
                status = "Waiting to try again…"
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            } catch let dropped as Dropped {
                // The connection went away. Nothing of the reply is kept, so
                // sending again repeats no tool call; text already shown is withdrawn.
                entries.removeSubrange(mark...)
                guard attempt < 3 else { throw Failure(message: dropped.message) }
                status = "Reconnecting…"
                try await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
            }
        }
    }

    private struct Dropped: Error { var message: String }

    private func requestOnce(key: String, system: String, tools: [[String: Any]]) async throws -> AnthropicStream {
        let model = self.model
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        for (name, value) in AnthropicWire.headers(apiKey: key, model: model, retryDeclines: retryDeclines) {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.httpBody = AnthropicWire.encode(AnthropicWire.requestBody(
            model: model, system: system, tools: tools, messages: messages, retryDeclines: retryDeclines))

        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await urlSession.bytes(for: request)
        } catch let error as URLError where error.code != .cancelled {
            throw Dropped(message: Self.describe(error))
        }
        let http = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? 0
        guard statusCode == 200 else {
            var body = Data()
            for try await byte in bytes {
                body.append(byte)
                if body.count > 64_000 { break }
            }
            let retryAfter = http?.value(forHTTPHeaderField: "retry-after").flatMap(Double.init)
            throw HTTPFailure(status: statusCode, body: body, retryAfter: retryAfter)
        }

        var stream = AnthropicStream()
        var replyRow: Int?
        do {
            for try await line in bytes.lines {
                try Task.checkCancellation()
                guard let payload = ServerSentEvents.dataPayload(ofLine: line) else { continue }
                switch stream.consume(data: payload) {
                case .text(let piece):
                    status = nil
                    if let row = replyRow, case .reply(let soFar) = entries[row].kind {
                        entries[row].kind = .reply(soFar + piece)
                    } else {
                        replyRow = entries.count
                        entries.append(Entry(kind: .reply(piece)))
                    }
                case .thinking:
                    status = "Thinking…"
                case .toolStarted:
                    status = "Working…"
                    replyRow = nil   // text after a call starts a new paragraph of its own
                case .switchedModel(let name):
                    entries.append(Entry(kind: .notice(name.isEmpty
                        ? "The model declined; another Claude model is answering."
                        : "The model declined; \(name) is answering instead.")))
                    replyRow = nil
                case .failed, .nothing:
                    break
                }
            }
        } catch let error as URLError where error.code != .cancelled {
            throw Dropped(message: Self.describe(error))
        }
        if let failure = stream.failure {
            throw Dropped(message: "Anthropic's service stopped the reply: \(failure)")
        }
        if stream.endedMidReply {
            throw Dropped(message: "The connection closed before the reply was complete.")
        }
        return stream
    }

    // MARK: Words

    private static func describe(_ error: Error) -> String {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return "This device is offline. The assistant needs an internet connection."
            case .timedOut:
                return "Anthropic did not answer in time. Try again."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                return "Could not reach Anthropic. Check the connection and try again."
            default:
                return "Could not reach Anthropic (\(url.localizedDescription))."
            }
        }
        return "Something went wrong: \(error.localizedDescription)"
    }

    /// The start of a failed call's answer, for the row's detail line.
    private static func firstText(_ content: [AnthropicWire.ToolContent]) -> String {
        for piece in content {
            if case .text(let text) = piece {
                // A refused or failed call answers with JSON carrying a message.
                if let data = text.data(using: .utf8),
                   let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = object["message"] as? String, !message.isEmpty {
                    return String(message.prefix(300))
                }
                return String(text.prefix(300))
            }
        }
        return "It did not work."
    }
}
