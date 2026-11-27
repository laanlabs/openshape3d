//
//  AgentLocalCall.swift
//  openshape3d
//
//  One tool call made from INSIDE the app rather than over the control
//  channel: the built-in assistant on the iPad and the Mac
//  (`Assistant/AssistantTools.swift`), and the same assistant in the web app,
//  whose engine compiles this file (`Web/AgentHost.swift`, op "ed.agent").
//
//  NO LOGIC OF ITS OWN: the call is phrased as the MCP `tools/call` it is and
//  goes through `AgentMCP.plan` → `AgentRouter` → `AgentBridge`, the path
//  Claude Desktop and ChatGPT use from outside. So an assistant inside the
//  app can do exactly what one outside can, with the same validation, the
//  same refusals and the same undoable features, and the two cannot drift.
//
//  The difference is the door, not the room: nothing listens on a port for
//  this, and the "Let AI Assistants Build Here" switch (which is about OTHER
//  apps on the Mac) does not have to be on.
//

import Foundation

@MainActor
enum AgentLocalCall {

    /// Where an export's bytes go: the Downloads folder on a Mac, the page's
    /// download in a browser. Returns the file's URL, or why it was not saved.
    typealias Save = (_ data: Data, _ requestedName: String?, _ format: AgentExportFormat) -> (URL?, String?)

    /// Run tool `name` with `arguments` against the open design. The reply is
    /// the JSON-RPC answer `AgentMCP` would have sent over the wire.
    static func run(name: String, arguments: [String: Any], save: Save) -> AgentResponse {
        let message: [String: Any] = [
            "jsonrpc": "2.0", "id": 1, "method": "tools/call",
            "params": ["name": name, "arguments": arguments],
        ]
        guard JSONSerialization.isValidJSONObject(message),
              let body = try? JSONSerialization.data(withJSONObject: message) else {
            return AgentMCP.rpcResult(id: .number(1), AgentMCP.toolText("The call could not be encoded.", isError: true))
        }
        let request = AgentRequest(method: "POST", path: AgentMCP.path, body: body)

        switch AgentMCP.plan(for: request) {
        case .reply(let reply):
            return reply
        case let .call(id, tool):
            let answer: AgentResponse
            if let decided = AgentRouter.response(for: tool.route) {
                answer = decided
            } else if !tool.route.needsEditor {
                answer = tool.route == .commands ? AgentBridge.shared.commandsResponse()
                                                 : AgentRouter.healthResponse(port: 0)
            } else {
                answer = AgentBridge.shared.handle(tool.route)
            }
            var saved: URL?
            var saveProblem: String?
            if case .export = tool.route, answer.status < 400, !answer.contentType.contains("json") {
                (saved, saveProblem) = save(answer.body, tool.exportName, tool.exportFormat ?? .stl)
            }
            return AgentMCP.result(id: id, tool: tool, response: answer, saved: saved, saveProblem: saveProblem)
        }
    }
}
