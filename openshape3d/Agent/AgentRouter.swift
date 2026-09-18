//
//  AgentRouter.swift
//  openshape3d
//
//  The response half of the DEBUG-only agent bridge: which endpoint a parsed
//  request names, and every reply that can be produced without touching the
//  live editor.
//
//  Split out of `AgentServer` so the interesting decisions are pure values a
//  test can assert on. What is left in the server is the socket, and what is in
//  `AgentBridge` is the main-actor hop; neither is testable, and neither needs
//  to be once routing and error shaping live here.
//
//  THE ONE THING THIS FILE EXISTS TO GET RIGHT: `EditorViewModel.runCommand`
//  returns a single `Bool` for three very different situations — the id was a
//  typo, the id is real but nothing routes it yet, or the id is fine but the
//  editor is in the wrong mode. A human pressing a key cannot tell those apart
//  and does not need to. An agent absolutely does: told only "false", it will
//  retry the same call forever. The catalog is a pure static, so this file can
//  separate all three before the request ever reaches the main actor.
//


import Foundation

// MARK: - A reply

nonisolated struct AgentResponse: Sendable {
    var status: Int
    var reason: String
    var contentType: String = "application/json"
    var body: Data
    /// Facts about a binary body that the bytes cannot say for themselves
    /// (an export's overall size). Sent as `X-OS3D-<Key>` headers over REST and
    /// folded into the tool result over MCP.
    var info: [String: String] = [:]

    static func json(_ status: Int, _ reason: String, _ object: [String: Any]) -> AgentResponse {
        // `.sortedKeys` so responses are byte-stable — worth it for diffing a
        // log and for asserting on one in a test.
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            ?? Data(#"{"ok":false,"error":"encoding_failed"}"#.utf8)
        return AgentResponse(status: status, reason: reason, body: data)
    }

    static func ok(_ object: [String: Any]) -> AgentResponse {
        var payload = object
        payload["ok"] = true
        return .json(200, "OK", payload)
    }

    /// `error` is a stable machine code; `message` is for a human reading a log.
    static func failure(_ status: Int, _ reason: String, error: String, message: String) -> AgentResponse {
        .json(status, reason, ["ok": false, "error": error, "message": message])
    }

    static func png(_ data: Data) -> AgentResponse {
        AgentResponse(status: 200, reason: "OK", contentType: "image/png", body: data)
    }
}

// MARK: - Where a request is headed

/// The fabrication formats `/v1/export` writes — the Export menu's mesh
/// formats plus STEP. Millimetres, like everything else on the wire.
nonisolated enum AgentExportFormat: String, Sendable, CaseIterable {
    case stl, obj, threeMF = "3mf", step

    var contentType: String {
        switch self {
        case .stl: return "model/stl"
        case .obj: return "model/obj"
        case .threeMF: return "model/3mf"
        case .step: return "model/step"
        }
    }
}

nonisolated enum AgentRoute: Sendable, Equatable {
    /// Answerable without the editor.
    case health
    case commands
    /// Needs the live `EditorViewModel` — see `AgentBridge`.
    case state
    case runCommand(id: String)
    case exec(AgentExecOp)
    case screenshot(width: Int, height: Int)
    /// Geometry health report for one body (or all with a `brep`) —
    /// docs/FREECAD_PLAYBOOK.md D1. `bop` adds the slow self-intersection check.
    case check(bodyID: String?, runBOPCheck: Bool)
    /// Snapshot every analytic body into a replayable capture bundle —
    /// the "op succeeded but the geometry looks wrong" repro path (D2).
    case capture(note: String)
    /// Kernel edge discovery for identity-addressed exec blends: indices,
    /// adjacent-face pairs, names, and enough geometry to pick by.
    case edges(bodyID: String)
    /// Kernel face discovery — the shell/fillet counterpart of /v1/state's
    /// body list, one level deeper.
    case faces(bodyID: String)
    /// Every sketch in the document with its plane and entities in sketch
    /// (u, v) millimetres — the numeric truth behind a drawn profile, so a
    /// sketch built by touch can be checked without reading pixels.
    case sketches
    /// The open design as a `.os3d` archive (the same bytes Export Project
    /// writes), after a save and a fresh thumbnail — how the bundled sample
    /// designs in `openshape3d/Demos/` are baked (`scripts/demo_models.py`).
    case archive
    /// The design (or the named bodies) in a fabrication format — what the
    /// Export menu writes, as bytes. The route an agent finishes a
    /// "make me a printable X" request with.
    /// `zUp` stands the Y-up model on its base for a slicer (Z-up world).
    case export(format: AgentExportFormat, bodyIDs: [String], zUp: Bool)
    /// World points → viewport points (pt, the coordinate space a touch
    /// lands in), so a driver can aim a tap at a known edge midpoint or face
    /// centre instead of measuring screenshots.
    case project(points: [SIMD3<Double>])
    /// A plane cut through one body, as closed loops in the plane's frame —
    /// the drawing view, for checking a rebuild section-for-section.
    case section(bodyID: String, origin: SIMD3<Double>, normal: SIMD3<Double>,
                 xAxisHint: SIMD3<Double>?, deflection: Double)
    /// Already-decided replies.
    case reply(status: Int, error: String, message: String)

    /// Whether serving this needs a hop to the main actor.
    var needsEditor: Bool {
        switch self {
        case .state, .runCommand, .exec, .screenshot, .check, .capture,
             .edges, .faces, .sketches, .project, .section, .archive, .export:
            return true
        case .health, .commands, .reply: return false
        }
    }
}

// MARK: - Routing

nonisolated enum AgentRouter {

    /// Bounds on `?w=`/`?h=`. The upper end is a guard against an accidental
    /// 40000px request wedging the renderer, not a considered maximum.
    static let defaultShotSize = 1024
    static let minShotSize = 64
    static let maxShotSize = 4096

    static func route(_ request: AgentRequest) -> AgentRoute {
        switch request.path {

        case "/v1/health":
            return get(request) ?? .health

        case "/v1/commands":
            return get(request) ?? .commands

        case "/v1/state":
            return get(request) ?? .state

        case "/v1/screenshot":
            if let bad = get(request) { return bad }
            return .screenshot(
                width: request.intQuery("w", default: defaultShotSize,
                                        min: minShotSize, max: maxShotSize),
                height: request.intQuery("h", default: defaultShotSize,
                                         min: minShotSize, max: maxShotSize))

        case "/v1/check":
            if let bad = get(request) { return bad }
            return .check(bodyID: request.query["body"],
                          runBOPCheck: request.query["bop"] == "1")

        case "/v1/edges", "/v1/faces":
            if let bad = get(request) { return bad }
            guard let body = request.query["body"], !body.isEmpty else {
                return .reply(status: 400, error: "missing_body_param",
                              message: "\(request.path) needs ?body=<uuid> — ids come from /v1/state.")
            }
            return request.path == "/v1/edges"
                ? .edges(bodyID: body) : .faces(bodyID: body)

        case "/v1/archive":
            return get(request) ?? .archive

        case "/v1/export":
            if let bad = get(request) { return bad }
            let raw = (request.query["format"] ?? "stl").lowercased()
            guard let format = AgentExportFormat(rawValue: raw) else {
                return .reply(status: 400, error: "unknown_format",
                              message: "/v1/export?format= takes one of "
                                     + AgentExportFormat.allCases.map(\.rawValue).joined(separator: ", ")
                                     + " (default stl); optional body=<uuid>[,<uuid>…] from /v1/state, "
                                     + "up=z to stand the Y-up model upright for a slicer.")
            }
            let up = (request.query["up"] ?? "y").lowercased()
            guard up == "y" || up == "z" else {
                return .reply(status: 400, error: "bad_up_axis",
                              message: "up= is y (the app's world, default) or z (slicers, most CAD).")
            }
            let ids = (request.query["body"] ?? "").split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return .export(format: format, bodyIDs: ids, zUp: up == "z")

        case "/v1/sketches":
            if let bad = get(request) { return bad }
            return .sketches

        case "/v1/project":
            if let bad = get(request) { return bad }
            let points = (request.query["points"] ?? "").split(separator: ";").compactMap { vector3(String($0)) }
            guard !points.isEmpty else {
                return .reply(status: 400, error: "missing_points",
                              message: "/v1/project needs ?points=x,y,z;x,y,z… (world mm).")
            }
            return .project(points: points)

        case "/v1/section":
            if let bad = get(request) { return bad }
            guard let body = request.query["body"], !body.isEmpty else {
                return .reply(status: 400, error: "missing_body_param",
                              message: "/v1/section needs ?body=<uuid> — ids come from /v1/state.")
            }
            guard let normal = vector3(request.query["normal"]), simd_length(normal) > 1e-9 else {
                return .reply(status: 400, error: "bad_plane",
                              message: "/v1/section needs ?normal=x,y,z (non-zero); optional origin=x,y,z "
                                     + "(default 0,0,0), xAxis=x,y,z (the loops' u direction), deflection (mm, 0.05).")
            }
            let origin = vector3(request.query["origin"]) ?? .zero
            let hint = vector3(request.query["xAxis"])
            let deflection = request.query["deflection"].flatMap(Double.init) ?? 0.05
            return .section(bodyID: body, origin: origin, normal: normal,
                            xAxisHint: hint, deflection: deflection)

        case "/v1/capture":
            guard developerRoutes else { return developerOnly(request.path) }
            guard request.method == "POST" else {
                return .reply(status: 405, error: "method_not_allowed",
                              message: "POST to /v1/capture (optional JSON body {\"note\":\"…\"}).")
            }
            return .capture(note: request.jsonBody?["note"] as? String ?? "")

        case "/v1/command":
            guard request.method == "POST" else {
                return .reply(status: 405, error: "method_not_allowed",
                              message: "POST a JSON body to /v1/command.")
            }
            guard let id = request.jsonBody?["id"] as? String, !id.isEmpty else {
                return .reply(status: 400, error: "missing_id",
                              message: #"Body must be JSON like {"id":"view.isometric"}."#)
            }
            return classify(id)

        case "/v1/exec":
            guard request.method == "POST" else {
                return .reply(status: 405, error: "method_not_allowed",
                              message: "POST a JSON body to /v1/exec.")
            }
            switch AgentExec.parse(request.jsonBody) {
            case .success(.importFile) where !developerRoutes:
                return developerOnly("document.import")
            case .success(let op):
                return .exec(op)
            case .failure(let error):
                return .reply(status: 400, error: error.code, message: error.message)
            }

        default:
            return .reply(status: 404, error: "unknown_path",
                          message: "No such endpoint: \(request.path). GET /v1/commands lists what this build can do.")
        }
    }

    /// Capture bundles and importing a file by PATH are development tools:
    /// they touch the file system on the caller's say-so, so they do not
    /// exist outside DEBUG builds.
    static var developerRoutes: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private static func developerOnly(_ what: String) -> AgentRoute {
        .reply(status: 404, error: "developer_only",
               message: "\(what) is only available in development builds.")
    }

    // MARK: Who may ask at all

    /// Decided before any route is read. Three refusals, in this order:
    ///
    /// - **A browser.** Every cross-site request a web page can make that
    ///   changes anything (a POST, a fetch with a JSON body) carries `Origin`.
    ///   No real client of this channel sends one, so its presence is the
    ///   whole test — and it needs no CORS machinery to get right.
    /// - **A rebound hostname.** A page served from `evil.example` whose DNS
    ///   later points at 127.0.0.1 is same-origin to itself, but it still says
    ///   `Host: evil.example`. Only loopback names pass.
    /// - **A stranger on this computer.** When the person switched the channel
    ///   on in Settings (every Release start), `requiredToken` is the pairing
    ///   code and each request must carry it as `Authorization: Bearer …`.
    ///   `/v1/health` alone answers without it — reduced to the app's name, so
    ///   a client can find the port and say "pair me" instead of "not running".
    ///   A DEBUG launch with `OS3D_AGENT=1` passes nil: a developer's own flag.
    static func refusal(for request: AgentRequest, requiredToken: String?) -> AgentRoute? {
        if request.headers["origin"] != nil {
            return .reply(status: 403, error: "browser_refused",
                          message: "This channel does not serve web pages.")
        }
        if let host = request.headers["host"], !isLoopbackHost(host) {
            return .reply(status: 403, error: "bad_host",
                          message: "Address this channel as 127.0.0.1 or localhost.")
        }
        guard let requiredToken, request.path != "/v1/health" else { return nil }
        let presented = request.headers["authorization"].flatMap { value -> String? in
            let parts = value.split(separator: " ", maxSplits: 1)
            guard parts.count == 2, parts[0].lowercased() == "bearer" else { return nil }
            return parts[1].trimmingCharacters(in: .whitespaces)
        }
        guard let presented, constantTimeEqual(normalizedCode(presented), normalizedCode(requiredToken)) else {
            return .reply(status: 401, error: "pairing_required",
                          message: "Send the pairing code from OpenShape 3D ▸ Settings ▸ AI Assistant "
                                 + "as 'Authorization: Bearer <code>'.")
        }
        return nil
    }

    /// `127.0.0.1`, `localhost` or `[::1]`, with or without a port.
    static func isLoopbackHost(_ header: String) -> Bool {
        var host = header.lowercased()
        if host.hasPrefix("[") {                       // [::1]:8787
            host = String(host.dropFirst().prefix { $0 != "]" })
        } else if let colon = host.lastIndex(of: ":") {
            host = String(host[host.startIndex..<colon])
        }
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
    }

    /// People paste codes with the dashes, without them, in lower case.
    static func normalizedCode(_ code: String) -> String {
        code.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Length leaks; content does not.
    static func constantTimeEqual(_ a: String, _ b: String) -> Bool {
        let x = Array(a.utf8), y = Array(b.utf8)
        guard x.count == y.count, !x.isEmpty else { return false }
        var difference: UInt8 = 0
        for i in 0..<x.count { difference |= x[i] ^ y[i] }
        return difference == 0
    }

    /// What `/v1/health` says to a caller that has not presented the code.
    static func unpairedHealthResponse() -> AgentResponse {
        .ok(["app": "openshape3d", "protocol": AgentServer.protocolVersion, "pairing": "required"])
    }

    /// The three-way split described in this file's header.
    private static func classify(_ id: String) -> AgentRoute {
        guard CommandRegistry.command(inCatalog: id) != nil else {
            return .reply(status: 400, error: "unknown_command",
                          message: "No command with id '\(id)'. GET /v1/commands for the list.")
        }
        guard CommandRegistry.routableIDs.contains(id) else {
            // The catalog is deliberately wider than the routing table: it also
            // names commands whose editor entry points do not exist yet, and
            // `unroutedChordedCommands` keeps that gap visible. Saying so beats
            // reporting a success that changed nothing.
            return .reply(status: 400, error: "unrouted_command",
                          message: "'\(id)' is in the catalog but has no editor entry point in this build.")
        }
        return .runCommand(id: id)
    }

    /// 405 unless the method is GET.
    /// `"x,y,z"` from a query string; nil unless exactly three numbers.
    private static func vector3(_ raw: String?) -> SIMD3<Double>? {
        guard let raw else { return nil }
        let parts = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 3 else { return nil }
        return SIMD3(parts[0], parts[1], parts[2])
    }

    private static func get(_ request: AgentRequest) -> AgentRoute? {
        request.method == "GET" ? nil : .reply(
            status: 405, error: "method_not_allowed",
            message: "\(request.path) is GET only.")
    }

    // MARK: Replies that need no editor

    static func healthResponse(port: UInt16) -> AgentResponse {
        .ok([
            "protocol": AgentServer.protocolVersion,
            "app": "openshape3d",
            "port": Int(port),
            "pid": Int(ProcessInfo.processInfo.processIdentifier),
            "platform": platformName,
            // An agent that knows a document is open can skip straight to
            // /v1/state; one that does not knows to open a project first.
            "hasDocument": AgentAttachment.isAttached,
        ])
    }

    /// Exactly what Command Search is allowed to offer — commands that actually
    /// reach the editor. An agent handed the full catalog would waste turns on
    /// ids that cannot run.
    static func commandsResponse() -> AgentResponse {
        let commands = CommandRegistry.launchableCommands.map { command -> [String: Any] in
            var entry: [String: Any] = [
                "id": command.id,
                "title": command.title,
                "category": command.category.rawValue,
            ]
            if let chord = command.chord { entry["chord"] = chord.label }
            return entry
        }
        return .ok(["count": commands.count, "commands": commands])
    }

    static func response(for reply: AgentRoute) -> AgentResponse? {
        guard case let .reply(status, error, message) = reply else { return nil }
        return .failure(status, httpReason(status), error: error, message: message)
    }

    static func httpReason(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 409: return "Conflict"
        case 413: return "Payload Too Large"
        case 500: return "Internal Server Error"
        default: return "Error"
        }
    }

    static var platformName: String {
        #if targetEnvironment(macCatalyst)
        return "maccatalyst"
        #elseif targetEnvironment(simulator)
        return "simulator"
        #else
        return "device"
        #endif
    }
}

