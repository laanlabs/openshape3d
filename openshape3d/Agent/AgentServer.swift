//
//  AgentServer.swift
//  openshape3d
//
//  The control channel: a loopback HTTP listener that lets an AI assistant on
//  the same computer build in the open design. It serves two dialects of one
//  protocol — the REST endpoints (`/v1/…`, `docs/AGENT_CONTROL.md`) and MCP
//  itself at `POST /mcp` (`AgentMCP`), which is what ChatGPT/Codex connect to
//  and what the bundled Claude Desktop extension relays to.
//
//  WHO CAN TURN IT ON. A person, in Settings ▸ AI Assistant (`AIControl`): off
//  by default, and the only start a Release build has. DEBUG builds also
//  honour a developer's `OS3D_AGENT=1`, like the other `OS3D_*` hooks.
//
//  WHO IT ANSWERS. Loopback peers only (checked in `accept`), never a browser
//  or a rebound hostname, and — whenever a person started it — only callers
//  presenting that installation's pairing code (`AgentRouter.refusal`). The
//  developer-only routes (`/v1/capture`, `document.import`) stay DEBUG-only.
//  The sandbox entitlement is `ENABLE_INCOMING_NETWORK_CONNECTIONS`.
//
//  Everything here is explicitly `nonisolated` because the project builds with
//  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — without it these types would
//  be implicitly main-actor and could not run on the listener queue.
//
//  This file is now only the socket. The parts worth testing live next door:
//  framing in `AgentHTTP`, routing and error shaping in `AgentRouter`, and the
//  hop onto the editor in `AgentBridge`.
//
//  TWO THINGS THAT COST AN HOUR, both of which fail SILENTLY:
//
//  1. The app must be launched through LaunchServices (`open Foo.app`), NOT by
//     exec'ing `Contents/MacOS/openshape3d`. Executed directly, a Catalyst app
//     does not get its full sandbox/entitlement context and `listen()` never
//     takes effect — while NWListener still reports `.ready`. To pass the env
//     var through `open`, set it for the session first:
//         launchctl setenv OS3D_AGENT 1 && open path/to/openshape3d.app
//         …then `launchctl unsetenv OS3D_AGENT` when finished.
//
//  2. Do not set `requiredLocalEndpoint` on listener parameters. It is meant
//     for outbound connections; on a listener it produces the same silent
//     no-op. Pass the port to `NWListener(using:on:)` instead.
//
//  The diagnostic for both: `lsof -nP -iTCP -a -p <pid>` shows the socket in
//  (CLOSED) rather than (LISTEN), even though the listener logged "ready".
//  Always log `listener.port` — never the requested port — or this is invisible.
//


import Foundation
import Network

nonisolated final class AgentServer: @unchecked Sendable {
    static let shared = AgentServer()

    /// Bumped when a response shape changes incompatibly. Clients check it in
    /// `/v1/health` and refuse rather than misread a newer app.
    static let protocolVersion = 1

    /// Default port; `OS3D_AGENT_PORT` overrides. Fixed-by-default means the
    /// clients have something to talk to with no discovery file.
    static let defaultPort: UInt16 = 8787

    /// How many ports from the default are tried when one is taken. 8787 is a
    /// popular number; the Claude Desktop extension scans the same range.
    static let portAttempts: UInt16 = 10

    nonisolated enum Status: Sendable, Equatable {
        case stopped
        case starting
        case listening(port: UInt16)
        case failed(String)
    }

    /// All mutable state below is confined to this queue.
    private let queue = DispatchQueue(label: "com.laan.labs.openshape3d.agent", qos: .userInitiated)
    private var listener: NWListener?
    private var boundPort: UInt16?
    private var lastPort: UInt16 = 0
    /// The pairing code every request must present. Non-nil for every start a
    /// PERSON made (Settings ▸ AI Assistant — the only start a Release build
    /// has); nil only for a developer's `OS3D_AGENT=1` launch of a DEBUG build.
    private var requiredToken: String?
    private var status: Status = .stopped
    /// Called on the main queue with every status change (Settings shows it).
    private var onStatus: (@Sendable (Status) -> Void)?

    private init() {}

    func observeStatus(_ handler: @escaping @Sendable (Status) -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            self.onStatus = handler
            let current = self.status
            DispatchQueue.main.async { handler(current) }
        }
    }

    private func set(_ new: Status) {
        status = new
        if let onStatus { DispatchQueue.main.async { onStatus(new) } }
    }

    /// The developer hook: DEBUG builds only, and only when `OS3D_AGENT` is
    /// set, so an ordinary debug run is unaffected. No pairing code — it is the
    /// developer's own launch flag. Returns whether it started the channel.
    @discardableResult
    func startIfRequested() -> Bool {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["OS3D_AGENT"] != nil else { return false }
        let requested = ProcessInfo.processInfo.environment["OS3D_AGENT_PORT"].flatMap(UInt16.init)
        queue.async { [weak self] in
            guard let self, self.listener == nil else { return }
            self.requiredToken = nil
            self.begin(from: requested)
        }
        return true
        #else
        return false
        #endif
    }

    /// Settings ▸ AI Assistant switched on. `pairingCode` is mandatory: a
    /// channel a person opened never answers a caller that cannot present it.
    func start(pairingCode: String) {
        precondition(!AgentRouter.normalizedCode(pairingCode).isEmpty, "a user-started channel needs a pairing code")
        queue.async { [weak self] in
            guard let self, self.listener == nil else { return }
            self.requiredToken = pairingCode
            self.begin(from: nil)
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.listener?.cancel()
            self.listener = nil
            self.boundPort = nil
            self.set(.stopped)
        }
    }

    /// A nil port means the default, moving up past ports something else owns.
    private func begin(from requested: UInt16?) {
        let first = requested ?? Self.defaultPort
        lastPort = requested == nil ? first + Self.portAttempts - 1 : first
        set(.starting)
        start(port: first)
    }

    /// The next port in the range, or a failure the person can read.
    private func retry(after port: UInt16, because reason: String) {
        listener?.cancel()
        listener = nil
        boundPort = nil
        guard port < lastPort else {
            NSLog("[agent] giving up: \(reason)")
            set(.failed(reason))
            return
        }
        NSLog("[agent] port \(port) unusable (\(reason)); trying \(port + 1)")
        start(port: port + 1)
    }

    private func start(port requested: UInt16) {
        guard listener == nil else { return }
        guard let port = NWEndpoint.Port(rawValue: requested) else {
            NSLog("[agent] invalid port \(requested)")
            set(.failed("Port \(requested) is not valid."))
            return
        }

        let params = NWParameters.tcp
        // Loopback ONLY, via the INTERFACE constraint. Do not use
        // `requiredLocalEndpoint` here: that is meant for outbound connections,
        // and on a listener it yields a socket stuck in CLOSED while the
        // listener still reports `.ready` — i.e. a silent no-op. The port must
        // come from `NWListener(using:on:)`.
        params.requiredInterfaceType = .loopback
        params.allowLocalEndpointReuse = true
        params.includePeerToPeer = false

        let listener: NWListener
        do {
            listener = try NWListener(using: params, on: port)
        } catch {
            NSLog("[agent] NWListener init failed on \(requested): \(error)")
            retry(after: requested, because: error.localizedDescription)
            return
        }
        self.listener = listener

        listener.stateUpdateHandler = { [weak self, weak listener] state in
            guard let self, let listener, self.listener === listener else { return }
            switch state {
            case .ready:
                // Log the ACTUAL bound port, never the requested one — that
                // distinction is what hid the CLOSED-socket bug above.
                let actual = listener.port?.rawValue ?? 0
                self.boundPort = actual
                NSLog("[agent] bound \(actual) (\(AgentRouter.platformName), protocol \(Self.protocolVersion))")
                self.confirmReachable(on: actual)
            case .failed(let error):
                // In use — or, sandboxed, EPERM: no com.apple.security.network.server.
                NSLog("[agent] listener FAILED on \(requested): \(error)")
                self.retry(after: requested, because: error.localizedDescription)
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)
    }

    /// `.ready` is not proof. When another program owns the IPv4 side of the
    /// port, the listener binds IPv6 only and 127.0.0.1 keeps reaching the
    /// stranger (seen on a Mac where a Python service held *:8787). So ask
    /// 127.0.0.1 who is there, and move on unless it is this very process.
    private func confirmReachable(on port: UInt16) {
        guard let url = URL(string: "http://127.0.0.1:\(port)/v1/health") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        if let requiredToken { request.setValue("Bearer \(requiredToken)", forHTTPHeaderField: "Authorization") }
        let pid = Int(ProcessInfo.processInfo.processIdentifier)
        URLSession(configuration: .ephemeral).dataTask(with: request) { [weak self] data, response, _ in
            let reply = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
            // Only an ANSWER from someone else disqualifies the port. No answer
            // at all is the sandbox refusing this outbound probe (the Mac app
            // has no network-client entitlement), which says nothing about who
            // is listening — so the bind stands.
            let mine = response == nil
                || (reply?["app"] as? String == "openshape3d" && reply?["pid"] as? Int == pid)
            self?.queue.async {
                guard let self, self.boundPort == port else { return }
                if mine {
                    NSLog("[agent] listening on http://127.0.0.1:\(port)")
                    self.set(.listening(port: port))
                } else {
                    self.retry(after: port, because: "Another program is using port \(port).")
                }
            }
        }.resume()
    }

    private func accept(_ connection: NWConnection) {
        // Defence in depth: the interface constraint above should make this
        // unreachable, but never serve a non-loopback peer.
        if case let .hostPort(host, _) = connection.endpoint, !Self.isLoopback(host) {
            NSLog("[agent] rejecting non-loopback peer \(host)")
            connection.cancel()
            return
        }
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private static func isLoopback(_ host: NWEndpoint.Host) -> Bool {
        switch host {
        case .ipv4(let address): return address.isLoopback
        case .ipv6(let address): return address.isLoopback
        case .name(let name, _): return name == "localhost"
        @unknown default: return false
        }
    }

    /// Accumulate until `AgentHTTP` says the request is whole — which, unlike
    /// the original header-only read, includes waiting for a `Content-Length`
    /// body that arrived in a second packet.
    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) {
            [weak self] chunk, _, isComplete, error in
            guard let self else { return }
            var buffer = buffer
            if let chunk { buffer.append(chunk) }

            if let error {
                NSLog("[agent] receive error: \(error)")
                connection.cancel()
                return
            }

            switch AgentHTTP.parse(buffer) {
            case .incomplete:
                // A half-sent request with the peer already gone is a dead
                // connection, not a slow one.
                if isComplete { connection.cancel(); return }
                self.receive(on: connection, buffer: buffer)

            case .complete(let request):
                self.dispatch(request, on: connection)

            case .malformed(let reason):
                NSLog("[agent] malformed request: \(reason)")
                self.send(.failure(400, "Bad Request", error: "malformed_request",
                                   message: reason), on: connection)

            case .tooLarge:
                self.send(.failure(413, "Payload Too Large", error: "body_too_large",
                                   message: "Bodies are capped at \(AgentHTTP.maxBodyBytes) bytes."),
                          on: connection)
            }
        }
    }

    private func dispatch(_ request: AgentRequest, on connection: NWConnection) {
        // Browsers, rebound hostnames and unpaired callers stop here, before
        // any route is read.
        if let refusal = AgentRouter.refusal(for: request, requiredToken: requiredToken),
           let reply = AgentRouter.response(for: refusal) {
            send(reply, on: connection)
            return
        }
        // Unpaired, `/v1/health` says only "this is OpenShape 3D".
        if requiredToken != nil, request.path == "/v1/health", request.headers["authorization"] == nil {
            send(AgentRouter.unpairedHealthResponse(), on: connection)
            return
        }
        if request.path == AgentMCP.path {
            dispatchMCP(request, on: connection)
            return
        }
        let route = AgentRouter.route(request)

        // Anything the editor is not needed for is answered right here on the
        // listener queue — including /v1/health, which must still respond when
        // the main actor is wedged, since that is the condition it exists to
        // report.
        if let decided = AgentRouter.response(for: route) {
            send(decided, on: connection)
            return
        }
        guard route.needsEditor else {
            switch route {
            case .health:   send(AgentRouter.healthResponse(port: boundPort ?? 0), on: connection)
            case .commands: send(AgentRouter.commandsResponse(), on: connection)
            default:        send(.failure(500, "Internal Server Error", error: "unhandled_route",
                                          message: "No handler for \(request.path)."), on: connection)
            }
            return
        }

        Task { @MainActor [weak self] in
            let response = AgentBridge.shared.handle(route)
            self?.send(response, on: connection)
        }
    }

    /// MCP over HTTP: one JSON-RPC message in, one JSON reply (or 202) out.
    private func dispatchMCP(_ request: AgentRequest, on connection: NWConnection) {
        switch AgentMCP.plan(for: request) {
        case .reply(let response):
            send(response, on: connection)
        case let .call(id, tool):
            if let decided = AgentRouter.response(for: tool.route) {
                send(AgentMCP.result(id: id, tool: tool, response: decided), on: connection)
                return
            }
            guard tool.route.needsEditor else {
                let answer = tool.route == .commands
                    ? AgentRouter.commandsResponse() : AgentRouter.healthResponse(port: boundPort ?? 0)
                send(AgentMCP.result(id: id, tool: tool, response: answer), on: connection)
                return
            }
            Task { @MainActor [weak self] in
                let answer = AgentBridge.shared.handle(tool.route)
                var saved: URL?
                var problem: String?
                if tool.name == "os3d_export", answer.status < 400, !answer.contentType.contains("json") {
                    (saved, problem) = AgentExportFolder.save(answer.body, requestedName: tool.exportName,
                                                             format: tool.exportFormat ?? .stl)
                }
                self?.send(AgentMCP.result(id: id, tool: tool, response: answer,
                                           saved: saved, saveProblem: problem), on: connection)
            }
        }
    }

    private func send(_ response: AgentResponse, on connection: NWConnection) {
        var out = Data("HTTP/1.1 \(response.status) \(response.reason)\r\n".utf8)
        out.append(Data("Content-Type: \(response.contentType)\r\n".utf8))
        out.append(Data("Content-Length: \(response.body.count)\r\n".utf8))
        for (key, value) in response.info.sorted(by: { $0.key < $1.key }) {
            out.append(Data("X-OS3D-\(key): \(value)\r\n".utf8))
        }
        out.append(Data("Connection: close\r\n\r\n".utf8))
        out.append(response.body)

        connection.send(content: out, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

