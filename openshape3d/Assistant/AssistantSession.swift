//
//  AssistantSession.swift
//  openshape3d
//
//  One conversation with the built-in assistant (#119): what the panel
//  shows, and the loop behind it. The person types; the request goes to the
//  provider they chose (Claude, OpenAI or Gemini) with their own key; when
//  the reply asks for a tool, the call runs against the open design
//  (`AssistantTools`) and the answer goes back, until the model has nothing
//  more to do or the person presses Stop.
//
//  The loop is the same for every provider. What differs between them, the
//  request, the stream, the shape of a conversation, is behind
//  `AssistantProvider`; the wire shapes are in `AssistantWire` (Claude),
//  `OpenAIWire` and `GeminiWire`.
//
//  A conversation lives as long as its editor: it is not saved with the
//  design, and closing the design ends it. It is in its provider's own
//  shape, so changing provider starts a new one.
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
    /// Whether there is a key for `provider`.
    private(set) var hasKey: Bool
    /// Tokens this conversation has used so far, as the API reported them.
    private(set) var tokensIn = 0
    private(set) var tokensOut = 0

    /// Whose model answers. Changing it starts a new chat: a conversation is
    /// in its provider's own shape and cannot be carried across.
    var provider: AssistantProvider {
        didSet {
            guard provider != oldValue else { return }
            UserDefaults.standard.set(provider.rawValue, forKey: Self.providerKey)
            newChat()
            options = AssistantRequestOptions()
            modelID = Self.storedModel(for: provider)
            hasKey = apiKey != nil
        }
    }

    var modelID: String {
        didSet { UserDefaults.standard.set(modelID, forKey: Self.modelKey(provider)) }
    }
    var model: AssistantModel { provider.model(modelID) }

    /// The providers that have a key on this device.
    var providersWithKeys: [AssistantProvider] {
        AssistantProvider.allCases.filter { key(for: $0) != nil }
    }

    // MARK: Behind it

    private static let providerKey = "assistant.provider"
    /// Claude's choice keeps the name it had before there were other providers.
    private static func modelKey(_ provider: AssistantProvider) -> String {
        provider == .anthropic ? "assistant.model" : "assistant.model." + provider.rawValue
    }
    private static func storedModel(for provider: AssistantProvider) -> String {
        provider.model(UserDefaults.standard.string(forKey: modelKey(provider))).id
    }

    /// Requests in one turn before the assistant stops and says so. A long
    /// build is a few dozen; this is the guard against a loop that never ends.
    static let maxRequestsPerTurn = 80

    @ObservationIgnored private var conversation: [[String: Any]] = []
    @ObservationIgnored private var task: Task<Void, Never>?
    /// The form of request this key's account accepts, learned as it goes.
    @ObservationIgnored private var options = AssistantRequestOptions()
    @ObservationIgnored private let endpointOverride: URL?
    @ObservationIgnored private let fixedKey: String?
    @ObservationIgnored private let urlSession: URLSession

    init() {
        var endpointOverride: URL?
        var fixedKey: String?
        var provider = AssistantProvider(rawValue: UserDefaults.standard.string(forKey: Self.providerKey) ?? "") ?? .anthropic
        #if DEBUG
        // UI tests: a stand-in server on this machine, a key that is not one,
        // and the provider whose wire the stand-in speaks.
        let environment = ProcessInfo.processInfo.environment
        if let raw = environment["OS3D_ASSISTANT_URL"], let url = URL(string: raw) { endpointOverride = url }
        if let key = environment["OS3D_ASSISTANT_KEY"], !key.isEmpty { fixedKey = key }
        if let named = environment["OS3D_ASSISTANT_PROVIDER"].flatMap(AssistantProvider.init(rawValue:)) { provider = named }
        #endif
        self.endpointOverride = endpointOverride
        self.fixedKey = fixedKey
        let configuration = URLSessionConfiguration.ephemeral   // no cookies, no cache on disk
        configuration.timeoutIntervalForRequest = 180           // silence between pieces of a reply
        configuration.timeoutIntervalForResource = 60 * 60
        configuration.waitsForConnectivity = false
        urlSession = URLSession(configuration: configuration)
        self.provider = provider
        modelID = Self.storedModel(for: provider)
        hasKey = fixedKey != nil || AssistantKeyStore.load(provider) != nil
    }

    // MARK: Keys

    private func key(for provider: AssistantProvider) -> String? {
        fixedKey ?? AssistantKeyStore.load(provider)
    }

    private var apiKey: String? { key(for: provider) }

    /// Store the key the person pasted for the chosen provider. Nil on
    /// success, else what to tell them.
    func saveKey(_ pasted: String) -> String? {
        let key = AssistantKeyStore.tidy(pasted)
        guard AssistantKeyStore.isPlausible(key) else {
            return "That does not look like an API key. Paste the whole key from \(provider.company)."
        }
        guard AssistantKeyStore.save(key, for: provider) else {
            return "The key could not be saved to this device's keychain."
        }
        hasKey = true
        return nil
    }

    /// Remove the chosen provider's key from this device.
    func removeKey() {
        stop()
        AssistantKeyStore.remove(provider)
        hasKey = fixedKey != nil
    }

    // MARK: Conversation

    func newChat() {
        stop()
        conversation = []
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
        provider.appendUserText(text, to: &conversation)
        isRunning = true
        let provider = self.provider
        task = Task { [weak self] in
            await self?.runTurn(provider: provider, key: key)
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

    private func runTurn(provider: AssistantProvider, key: String) async {
        // While the assistant builds, the view follows what it makes, as it
        // does for an assistant connected from outside (`framesAssistantWork`).
        let framedBefore = AgentBridge.shared.framesAssistantWork
        AgentBridge.shared.framesAssistantWork = true
        defer { AgentBridge.shared.framesAssistantWork = framedBefore }

        let system = AnthropicWire.systemPrompt(guide: AgentMCP.guide)

        for _ in 0..<Self.maxRequestsPerTurn {
            if Task.isCancelled { return noteStopped() }

            let reply: AssistantReply
            do {
                reply = try await request(provider: provider, key: key, system: system)
            } catch is CancellationError {
                return noteStopped()
            } catch let failure as Failure {
                entries.append(Entry(kind: .problem(failure.message)))
                return
            } catch {
                if Task.isCancelled || (error as? URLError)?.code == .cancelled { return noteStopped() }
                entries.append(Entry(kind: .problem(Self.describe(error, provider: provider))))
                return
            }
            tokensIn += reply.tokensIn
            tokensOut += reply.tokensOut

            if reply.outcome == .declined {
                // Nothing of a declined reply is kept, and the request that
                // drew it is taken back so the next message starts clean.
                provider.removePendingUserText(from: &conversation)
                entries.append(Entry(kind: .problem("\(provider.name) declined this request, so nothing was changed. "
                                                    + "Try asking in a different way.")))
                return
            }

            conversation.append(contentsOf: reply.history)

            switch reply.outcome {
            case .toolCalls, .cutOff where !reply.calls.isEmpty:
                // A reply cut off at its length limit may hold half a call:
                // none of that reply's calls run, and the model is told why.
                let cutOff = reply.outcome == .cutOff
                var results: [(call: AssistantToolCall, content: [AssistantToolContent], isError: Bool)] = []
                for call in reply.calls {
                    let row = entries.count
                    let label = AssistantTools.label(op: call.op, args: call.input["args"] as? [String: Any] ?? [:])
                    entries.append(Entry(kind: .activity(label, .running)))
                    let outcome: (content: [AssistantToolContent], isError: Bool)
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
                    results.append((call, outcome.content, outcome.isError))
                }
                // Every call is answered before anything else is said.
                provider.appendToolResults(results, to: &conversation)
                if Task.isCancelled { return noteStopped() }
                continue

            case .paused:
                continue   // the API paused its own work; the same conversation resumes it

            case .cutOff:
                entries.append(Entry(kind: .notice("The reply reached its length limit and was cut short.")))
                return

            case .toolCalls, .done, .declined:
                if reply.history.isEmpty {
                    entries.append(Entry(kind: .notice("\(provider.name) sent an empty reply. Try sending the message again.")))
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
    private struct Dropped: Error { var message: String }

    /// Send the conversation and read the reply as it streams, showing its
    /// text as it arrives. A request that fails before anything of the reply
    /// was shown is tried again a couple of times when that can help.
    private func request(provider: AssistantProvider, key: String, system: String) async throws -> AssistantReply {
        var attempt = 0
        while true {
            attempt += 1
            let mark = entries.count
            status = "Thinking…"
            do {
                return try await requestOnce(provider: provider, key: key, system: system)
            } catch let failure as HTTPFailure {
                entries.removeSubrange(mark...)
                // The API refused this form of the request and another form
                // avoids the reason: carry on with that one.
                if provider.adjust(&options, afterStatus: failure.status, body: failure.body) { continue }
                let wait: Double?
                if provider.isWorthRetrying(status: failure.status) {
                    wait = Double(attempt) * 2
                } else if failure.status == 429, let after = failure.retryAfter, after <= 20 {
                    wait = max(after, 1)
                } else {
                    wait = nil
                }
                guard attempt < 3, let wait else {
                    throw Failure(message: provider.errorMessage(status: failure.status, body: failure.body))
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

    private func requestOnce(provider: AssistantProvider, key: String, system: String) async throws -> AssistantReply {
        let parts = provider.request(apiKey: key, model: model, system: system, mcpTools: AgentMCP.tools,
                                     conversation: conversation, options: options)
        var request = URLRequest(url: endpointOverride ?? parts.url)
        request.httpMethod = "POST"
        for (name, value) in parts.headers { request.setValue(value, forHTTPHeaderField: name) }
        request.httpBody = parts.body

        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await urlSession.bytes(for: request)
        } catch let error as URLError where error.code != .cancelled {
            throw Dropped(message: Self.describe(error, provider: provider))
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

        var stream = AssistantStream(provider)
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
                        ? "The model declined; another model is answering."
                        : "The model declined; \(name) is answering instead.")))
                    replyRow = nil
                case .failed, .nothing:
                    break
                }
            }
        } catch let error as URLError where error.code != .cancelled {
            throw Dropped(message: Self.describe(error, provider: provider))
        }
        if let failure = stream.failure {
            throw Dropped(message: "\(provider.company)'s service stopped the reply: \(failure)")
        }
        if stream.endedMidReply {
            throw Dropped(message: "The connection closed before the reply was complete.")
        }
        return stream.reply
    }

    // MARK: Words

    private static func describe(_ error: Error, provider: AssistantProvider) -> String {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return "This device is offline. The assistant needs an internet connection."
            case .timedOut:
                return "\(provider.company) did not answer in time. Try again."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                return "Could not reach \(provider.company). Check the connection and try again."
            default:
                return "Could not reach \(provider.company) (\(url.localizedDescription))."
            }
        }
        return "Something went wrong: \(error.localizedDescription)"
    }

    /// The start of a failed call's answer, for the row's detail line.
    private static func firstText(_ content: [AssistantToolContent]) -> String {
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
