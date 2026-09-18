//
//  AgentMCP.swift
//  openshape3d
//
//  MCP (Model Context Protocol) spoken by the app itself, at `POST /mcp` on the
//  control channel — the "streamable HTTP" transport reduced to what a tool
//  server needs: one JSON-RPC message in, one JSON reply out (202 for a
//  notification). No sessions, no server-initiated stream; `GET /mcp` is 405,
//  which the transport allows.
//
//  Why the app speaks MCP at all, when `scripts/mcp_openshape3d.py` already
//  translates: that script needs a Python, a path and a config file, which is
//  a developer's setup. Someone who installed the app from the store has none
//  of them. With MCP in the app, ChatGPT/Codex connect to an address, and
//  Claude Desktop connects through a bundled extension whose whole job is to
//  copy lines between stdio and this endpoint.
//
//  NO LOGIC OF ITS OWN, like the script: every tool is rewritten as the REST
//  request it stands for and sent through `AgentRouter.route`, so validation
//  and error shaping cannot drift between the two dialects. The tool list and
//  the modelling guide are bundled resources (`MCPTools.json`,
//  `ModelingGuide.md`) shared with the extension and the Claude Code skill;
//  `AgentMCPTests` keeps the copies honest.
//
//  Pure values throughout (the file write for `os3d_export` is handed in), so
//  it is unit-testable without a socket or an editor.
//

import Foundation

nonisolated enum AgentMCP {

    static let path = "/mcp"
    static let supportedProtocols = ["2025-06-18", "2025-03-26", "2024-11-05"]

    // MARK: Bundled text

    /// The tool catalog (`{"tools":[…]}`), exactly as `tools/list` returns it.
    static let tools: [[String: Any]] = {
        guard let url = Bundle.main.url(forResource: "MCPTools", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tools = object["tools"] as? [[String: Any]] else { return [] }
        return tools
    }()

    static let guide: String = {
        guard let url = Bundle.main.url(forResource: "ModelingGuide", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "The modelling guide is missing from this build."
        }
        return text
    }()

    // MARK: What to do with a request

    /// A tool call, reduced to the REST route that serves it.
    nonisolated struct ToolCall: Sendable {
        var name: String
        var route: AgentRoute
        /// `os3d_export` only: the file name the person (or the model) asked for.
        var exportName: String?
        var exportFormat: AgentExportFormat?
    }

    nonisolated enum Plan: Sendable {
        /// Answerable here: handshake, tool list, guide, every refusal.
        case reply(AgentResponse)
        /// Needs the router's answer (and usually the editor).
        case call(id: JSONRPCID, tool: ToolCall)
    }

    /// JSON-RPC ids are strings or numbers and must be echoed unchanged.
    nonisolated enum JSONRPCID: Sendable, Equatable {
        case string(String), number(Double)
        var json: Any {
            switch self {
            case .string(let s): return s
            case .number(let n): return n == n.rounded() ? Int(n) as Any : n as Any
            }
        }
    }

    static func plan(for request: AgentRequest) -> Plan {
        guard request.method == "POST" else {
            return .reply(.failure(405, "Method Not Allowed", error: "method_not_allowed",
                                   message: "POST one JSON-RPC message to /mcp."))
        }
        guard let message = request.jsonBody, message["jsonrpc"] as? String == "2.0" else {
            return .reply(rpcError(id: nil, code: -32600, message: "Expected one JSON-RPC 2.0 object."))
        }
        let method = message["method"] as? String
        guard let id = rpcID(message["id"]) else {
            // A notification (or a response to something we never asked): accepted, no body.
            return .reply(AgentResponse(status: 202, reason: "Accepted", body: Data()))
        }
        let params = message["params"] as? [String: Any] ?? [:]

        switch method {
        case "initialize":
            let asked = params["protocolVersion"] as? String
            let version = asked.flatMap { supportedProtocols.contains($0) ? $0 : nil } ?? supportedProtocols[0]
            return .reply(rpcResult(id: id, [
                "protocolVersion": version,
                "capabilities": ["tools": [String: Any]()],
                "serverInfo": ["name": "openshape3d", "title": "OpenShape 3D", "version": appVersion],
                "instructions": guide,
            ]))
        case "ping":
            return .reply(rpcResult(id: id, [:]))
        case "tools/list":
            return .reply(rpcResult(id: id, ["tools": tools]))
        case "tools/call":
            let name = params["name"] as? String ?? ""
            let arguments = params["arguments"] as? [String: Any] ?? [:]
            if name == "os3d_guide" {
                return .reply(rpcResult(id: id, toolText(guide, isError: false)))
            }
            switch restRequest(tool: name, arguments: arguments) {
            case .failure(let problem):
                return .reply(rpcResult(id: id, toolText(problem.message, isError: true)))
            case .success(let rest):
                var call = ToolCall(name: name, route: AgentRouter.route(rest))
                if name == "os3d_export" {
                    call.exportName = arguments["name"] as? String
                    call.exportFormat = AgentExportFormat(rawValue: (arguments["format"] as? String ?? "stl").lowercased())
                }
                return .call(id: id, tool: call)
            }
        default:
            return .reply(rpcError(id: id, code: -32601, message: "Method not found: \(method ?? "")"))
        }
    }

    // MARK: Tool → REST

    nonisolated struct Problem: Error, Sendable { var message: String }

    /// The REST request a tool call stands for. Everything past this point is
    /// `AgentRouter`'s, including the refusals.
    static func restRequest(tool: String, arguments: [String: Any]) -> Result<AgentRequest, Problem> {
        func get(_ path: String, _ query: [String: String] = [:]) -> Result<AgentRequest, Problem> {
            .success(AgentRequest(method: "GET", path: path, query: query))
        }
        func post(_ path: String, _ body: [String: Any]) -> Result<AgentRequest, Problem> {
            let data = (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
            return .success(AgentRequest(method: "POST", path: path, body: data))
        }
        func bodyID() -> String? { (arguments["body"] as? String).flatMap { $0.isEmpty ? nil : $0 } }

        switch tool {
        case "os3d_health":        return get("/v1/health")
        case "os3d_list_commands": return get("/v1/commands")
        case "os3d_state":         return get("/v1/state")
        case "os3d_sketches":      return get("/v1/sketches")
        case "os3d_run_command":
            guard let id = arguments["id"] as? String, !id.isEmpty else {
                return .failure(Problem(message: "os3d_run_command needs an 'id'. os3d_list_commands lists them."))
            }
            return post("/v1/command", ["id": id])
        case "os3d_exec":
            guard let op = arguments["op"] as? String, !op.isEmpty else {
                return .failure(Problem(message: "os3d_exec needs an 'op'. os3d_guide lists the operations."))
            }
            return post("/v1/exec", ["op": op, "args": arguments["args"] as? [String: Any] ?? [:]])
        case "os3d_faces", "os3d_edges":
            guard let body = bodyID() else {
                return .failure(Problem(message: "\(tool) needs 'body' — a body id from os3d_state."))
            }
            return get(tool == "os3d_faces" ? "/v1/faces" : "/v1/edges", ["body": body])
        case "os3d_check":
            var query: [String: String] = [:]
            if let body = bodyID() { query["body"] = body }
            if arguments["bop"] as? Bool == true { query["bop"] = "1" }
            return get("/v1/check", query)
        case "os3d_screenshot":
            var query: [String: String] = [:]
            if let w = arguments["width"] as? Int { query["w"] = String(w) }
            if let h = arguments["height"] as? Int { query["h"] = String(h) }
            return get("/v1/screenshot", query)
        case "os3d_export":
            var query = ["format": arguments["format"] as? String ?? "stl",
                         "up": arguments["up"] as? String ?? "y"]
            let bodies = (arguments["body"] as? [String]) ?? (arguments["body"] as? String).map { [$0] } ?? []
            if !bodies.isEmpty { query["body"] = bodies.joined(separator: ",") }
            return get("/v1/export", query)
        default:
            return .failure(Problem(message: "Unknown tool: \(tool)"))
        }
    }

    // MARK: REST answer → tool result

    /// `saved` is where the caller wrote an export's bytes (nil when it could
    /// not, with `saveProblem` saying why).
    static func result(id: JSONRPCID, tool: ToolCall, response: AgentResponse,
                       saved: URL? = nil, saveProblem: String? = nil) -> AgentResponse {
        let failedHTTP = response.status >= 400
        if tool.name == "os3d_screenshot", !failedHTTP, response.contentType == "image/png" {
            return rpcResult(id: id, ["content": [[
                "type": "image", "mimeType": "image/png",
                "data": response.body.base64EncodedString(),
            ]]])
        }
        if tool.name == "os3d_export", !failedHTTP, !response.contentType.contains("json") {
            guard let saved else {
                return rpcResult(id: id, toolText(saveProblem ?? "The file could not be saved.", isError: true))
            }
            var report: [String: Any] = ["ok": true, "path": friendlyPath(saved), "bytes": response.body.count,
                                         "fileName": saved.lastPathComponent,
                                         "units": "mm", "format": tool.exportFormat?.rawValue ?? "stl"]
            if let size = response.info["Size-MM"] { report["sizeMM"] = size }
            if let count = response.info["Bodies"] { report["bodies"] = Int(count) ?? 1 }
            if tool.exportFormat == .stl, response.body.count >= 84 {
                // Binary STL: an 80-byte header, then a little-endian UInt32 triangle count.
                let count = response.body.subdata(in: 80..<84).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
                report["triangles"] = Int(UInt32(littleEndian: count))
            }
            let text = (try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]))
                .map { String(decoding: $0, as: UTF8.self) } ?? "{\"ok\":true}"
            return rpcResult(id: id, toolText(text, isError: false))
        }
        let text = String(decoding: response.body, as: UTF8.self)
        // A feature that was recorded but did not build is HTTP 200 with
        // "failed": true — to a model that must read as an error, not a success.
        let failedFeature = (try? JSONSerialization.jsonObject(with: response.body) as? [String: Any])?["failed"] as? Bool == true
        return rpcResult(id: id, toolText(text, isError: failedHTTP || failedFeature))
    }

    /// Where a person will look for the file. A sandboxed Mac app sees its
    /// Downloads folder as `~/Library/Containers/<bundle id>/Data/Downloads` —
    /// true, and useless to someone told to "open it in your slicer" (the
    /// first real Claude Desktop run reported exactly that path).
    static func friendlyPath(_ url: URL) -> String {
        url.deletingLastPathComponent().lastPathComponent == "Downloads"
            ? "~/Downloads/" + url.lastPathComponent : url.path
    }

    /// A safe file name for an export: the last path component only, nothing
    /// hidden, the format's extension enforced.
    static func exportFileName(requested: String?, format: AgentExportFormat, now: Date = Date()) -> String {
        let ext = format.rawValue
        var base = (requested ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        base = (base as NSString).lastPathComponent
        if base.lowercased().hasSuffix("." + ext) { base = String(base.dropLast(ext.count + 1)) }
        base = String(base.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || " -_().".unicodeScalars.contains($0)
        }.map(Character.init))
        while base.hasPrefix(".") { base.removeFirst() }
        base = String(base.prefix(80)).trimmingCharacters(in: .whitespaces)
        if base.isEmpty {
            let stamp = DateFormatter()
            stamp.dateFormat = "yyyyMMdd-HHmmss"
            stamp.locale = Locale(identifier: "en_US_POSIX")
            base = "openshape3d-" + stamp.string(from: now)
        }
        return base + "." + ext
    }

    // MARK: JSON-RPC shaping

    static func rpcID(_ raw: Any?) -> JSONRPCID? {
        if let s = raw as? String { return .string(s) }
        if let n = raw as? NSNumber { return .number(n.doubleValue) }
        return nil
    }

    static func toolText(_ text: String, isError: Bool) -> [String: Any] {
        var result: [String: Any] = ["content": [["type": "text", "text": text]]]
        if isError { result["isError"] = true }
        return result
    }

    static func rpcResult(id: JSONRPCID, _ result: [String: Any]) -> AgentResponse {
        .json(200, "OK", ["jsonrpc": "2.0", "id": id.json, "result": result])
    }

    static func rpcError(id: JSONRPCID?, code: Int, message: String) -> AgentResponse {
        .json(200, "OK", ["jsonrpc": "2.0", "id": id?.json ?? NSNull(),
                          "error": ["code": code, "message": message]])
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
}
