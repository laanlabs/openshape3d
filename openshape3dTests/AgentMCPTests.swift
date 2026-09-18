//
//  AgentMCPTests.swift
//  openshape3dTests
//
//  The app's own MCP endpoint and the guard in front of the whole control
//  channel, as pure values — no socket, no `EditorViewModel` (STATUS gotcha 1).
//
//  Two things here are security properties rather than features, and are
//  tested as such: a channel a PERSON switched on answers nobody without the
//  pairing code, and no browser request gets through with or without it.
//

import XCTest
@testable import openshape3d

final class AgentMCPTests: XCTestCase {

    // MARK: Helpers

    private func request(_ method: String = "POST", _ path: String = "/mcp",
                         headers: [String: String] = [:], json: [String: Any]? = nil) -> AgentRequest {
        let body = json.map { try! JSONSerialization.data(withJSONObject: $0) } ?? Data()
        return AgentRequest(method: method, path: path, headers: headers, body: body)
    }

    private func rpc(_ method: String, id: Any? = 1, params: [String: Any] = [:]) -> AgentRequest {
        var message: [String: Any] = ["jsonrpc": "2.0", "method": method, "params": params]
        if let id { message["id"] = id }
        return request(json: message)
    }

    private func object(_ response: AgentResponse) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: response.body)) as? [String: Any] ?? [:]
    }

    private func reply(_ plan: AgentMCP.Plan, file: StaticString = #filePath, line: UInt = #line) -> AgentResponse {
        guard case let .reply(response) = plan else {
            XCTFail("expected a direct reply", file: file, line: line)
            return .failure(500, "x", error: "x", message: "x")
        }
        return response
    }

    private func call(_ plan: AgentMCP.Plan, file: StaticString = #filePath, line: UInt = #line) -> AgentMCP.ToolCall? {
        guard case let .call(_, tool) = plan else {
            XCTFail("expected a tool call", file: file, line: line)
            return nil
        }
        return tool
    }

    // MARK: The guard — who may ask at all

    private let code = "K7QF2-M9XA4-0BCDE-FGH12"

    func testABrowserIsRefusedEvenWithTheCode() {
        let r = request(headers: ["origin": "https://evil.example", "host": "127.0.0.1:8787",
                                  "authorization": "Bearer \(code)"])
        guard case let .reply(status, error, _)? = AgentRouter.refusal(for: r, requiredToken: code) else {
            return XCTFail("a request with an Origin must be refused")
        }
        XCTAssertEqual(status, 403)
        XCTAssertEqual(error, "browser_refused")
    }

    func testAReboundHostnameIsRefused() {
        let r = request(headers: ["host": "evil.example:8787", "authorization": "Bearer \(code)"])
        guard case let .reply(status, error, _)? = AgentRouter.refusal(for: r, requiredToken: code) else {
            return XCTFail("a non-loopback Host must be refused")
        }
        XCTAssertEqual(status, 403)
        XCTAssertEqual(error, "bad_host")
    }

    func testLoopbackHostSpellings() {
        for host in ["127.0.0.1", "127.0.0.1:8787", "localhost:8790", "LOCALHOST", "[::1]:8787"] {
            XCTAssertTrue(AgentRouter.isLoopbackHost(host), host)
        }
        for host in ["evil.example", "127.0.0.1.evil.example:8787", "10.0.0.5:8787", "localhost.evil.example"] {
            XCTAssertFalse(AgentRouter.isLoopbackHost(host), host)
        }
    }

    func testAUserStartedChannelAnswersNobodyWithoutTheCode() {
        for headers in [[:], ["authorization": "Bearer WRONG-WRONG-WRONG-WRONG"], ["authorization": "Basic \(code)"],
                        ["authorization": "Bearer "]] as [[String: String]] {
            for path in ["/mcp", "/v1/state", "/v1/exec", "/v1/export", "/v1/commands"] {
                guard case let .reply(status, error, _)? =
                        AgentRouter.refusal(for: request("POST", path, headers: headers), requiredToken: code) else {
                    return XCTFail("\(path) answered \(headers) without the pairing code")
                }
                XCTAssertEqual(status, 401)
                XCTAssertEqual(error, "pairing_required")
            }
        }
    }

    func testTheCodeIsAcceptedHoweverAPersonPastesIt() {
        for spelling in [code, code.lowercased(), code.replacingOccurrences(of: "-", with: ""), " \(code) "] {
            let r = request(headers: ["host": "127.0.0.1:8787", "authorization": "Bearer \(spelling)"])
            XCTAssertNil(AgentRouter.refusal(for: r, requiredToken: code), spelling)
        }
    }

    func testHealthAloneIsReachableUnpairedAndSaysOnlyWhoItIs() {
        XCTAssertNil(AgentRouter.refusal(for: request("GET", "/v1/health"), requiredToken: code))
        let said = object(AgentRouter.unpairedHealthResponse())
        XCTAssertEqual(said["app"] as? String, "openshape3d")
        XCTAssertEqual(said["pairing"] as? String, "required")
        XCTAssertNil(said["pid"]); XCTAssertNil(said["hasDocument"]); XCTAssertNil(said["port"])
    }

    func testADevelopersDebugLaunchNeedsNoCode() {
        XCTAssertNil(AgentRouter.refusal(for: request("POST", "/v1/exec"), requiredToken: nil))
    }

    func testConstantTimeEqualRejectsEmptyAndDifferentLengths() {
        XCTAssertFalse(AgentRouter.constantTimeEqual("", ""))
        XCTAssertFalse(AgentRouter.constantTimeEqual("ABC", "ABCD"))
        XCTAssertTrue(AgentRouter.constantTimeEqual("ABC", "ABC"))
    }

    func testPairingCodesAreLongRandomAndUnambiguous() {
        let a = PairingCodeStore.generate(), b = PairingCodeStore.generate()
        XCTAssertNotEqual(a, b)
        XCTAssertEqual(AgentRouter.normalizedCode(a).count, 20)
        XCTAssertEqual(a.split(separator: "-").map(\.count), [5, 5, 5, 5])
        XCTAssertTrue(a.allSatisfy { $0 == "-" || PairingCodeStore.alphabet.contains($0) })
        XCTAssertFalse(PairingCodeStore.alphabet.contains { "ILOU".contains($0) })
    }

    // MARK: Handshake

    func testInitializeCarriesTheGuideAndEchoesAKnownProtocol() {
        let result = object(reply(AgentMCP.plan(for: rpc("initialize", params: ["protocolVersion": "2025-03-26"]))))["result"] as? [String: Any]
        XCTAssertEqual(result?["protocolVersion"] as? String, "2025-03-26")
        XCTAssertEqual((result?["serverInfo"] as? [String: Any])?["name"] as? String, "openshape3d")
        XCTAssertTrue((result?["instructions"] as? String ?? "").contains("Y is up"))
    }

    func testAnUnknownProtocolFallsBackToOurNewest() {
        let result = object(reply(AgentMCP.plan(for: rpc("initialize", params: ["protocolVersion": "1999-01-01"]))))["result"] as? [String: Any]
        XCTAssertEqual(result?["protocolVersion"] as? String, AgentMCP.supportedProtocols[0])
    }

    func testNotificationsAreAcceptedWithNoBody() {
        let response = reply(AgentMCP.plan(for: rpc("notifications/initialized", id: nil)))
        XCTAssertEqual(response.status, 202)
        XCTAssertTrue(response.body.isEmpty)
    }

    func testStringAndNumberIdsAreEchoedUnchanged() {
        XCTAssertEqual(object(reply(AgentMCP.plan(for: rpc("ping", id: "abc"))))["id"] as? String, "abc")
        XCTAssertEqual(object(reply(AgentMCP.plan(for: rpc("ping", id: 7))))["id"] as? Int, 7)
    }

    func testGetAndGarbageAreRefusedInProtocol() {
        XCTAssertEqual(reply(AgentMCP.plan(for: request("GET"))).status, 405)
        let garbage = AgentRequest(method: "POST", path: "/mcp", body: Data("not json".utf8))
        let error = object(reply(AgentMCP.plan(for: garbage)))["error"] as? [String: Any]
        XCTAssertEqual(error?["code"] as? Int, -32600)
        let unknown = object(reply(AgentMCP.plan(for: rpc("resources/list"))))["error"] as? [String: Any]
        XCTAssertEqual(unknown?["code"] as? Int, -32601)
    }

    // MARK: Tools

    func testToolListIsTheBundledCatalog() {
        let result = object(reply(AgentMCP.plan(for: rpc("tools/list"))))["result"] as? [String: Any]
        let names = Set((result?["tools"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String })
        XCTAssertEqual(names, ["os3d_health", "os3d_list_commands", "os3d_state", "os3d_run_command", "os3d_screenshot",
                               "os3d_guide", "os3d_exec", "os3d_faces", "os3d_edges", "os3d_sketches", "os3d_check",
                               "os3d_export"])
    }

    func testEveryListedToolResolvesToARoute() {
        let samples: [String: [String: Any]] = [
            "os3d_run_command": ["id": "view.fit"], "os3d_exec": ["op": "sketch.create"],
            "os3d_faces": ["body": "B"], "os3d_edges": ["body": "B"]]
        for tool in AgentMCP.tools.compactMap({ $0["name"] as? String }) where tool != "os3d_guide" {
            guard case .success = AgentMCP.restRequest(tool: tool, arguments: samples[tool] ?? [:]) else {
                return XCTFail("\(tool) is listed but has no route")
            }
        }
    }

    func testToolsGoThroughTheSameRouterAsREST() {
        XCTAssertEqual(call(AgentMCP.plan(for: rpc("tools/call", params: ["name": "os3d_state"])))?.route, .state)
        XCTAssertEqual(call(AgentMCP.plan(for: rpc("tools/call", params: [
            "name": "os3d_run_command", "arguments": ["id": "view.fit"]])))?.route, .runCommand(id: "view.fit"))
        XCTAssertEqual(call(AgentMCP.plan(for: rpc("tools/call", params: [
            "name": "os3d_check", "arguments": ["body": "B", "bop": true]])))?.route, .check(bodyID: "B", runBOPCheck: true))
        XCTAssertEqual(call(AgentMCP.plan(for: rpc("tools/call", params: [
            "name": "os3d_export", "arguments": ["format": "3mf", "up": "z", "body": ["A", "B"], "name": "pot"]])))?.route,
                       .export(format: .threeMF, bodyIDs: ["A", "B"], zUp: true))
    }

    func testARouterRefusalBecomesAToolErrorWithItsCode() throws {
        let tool = try XCTUnwrap(call(AgentMCP.plan(for: rpc("tools/call", params: [
            "name": "os3d_run_command", "arguments": ["id": "no.such.command"]]))))
        let refusal = try XCTUnwrap(AgentRouter.response(for: tool.route))
        let result = object(AgentMCP.result(id: .number(1), tool: tool, response: refusal))["result"] as? [String: Any]
        XCTAssertEqual(result?["isError"] as? Bool, true)
        let text = ((result?["content"] as? [[String: Any]])?.first?["text"] as? String) ?? ""
        XCTAssertTrue(text.contains("unknown_command"))
    }

    func testMissingArgumentsAreToolErrorsNotProtocolErrors() {
        for (name, arguments) in [("os3d_exec", [:]), ("os3d_faces", [:]), ("os3d_run_command", [:]), ("os3d_nope", [:])]
            as [(String, [String: Any])] {
            let result = object(reply(AgentMCP.plan(for: rpc("tools/call", params: ["name": name, "arguments": arguments]))))["result"] as? [String: Any]
            XCTAssertEqual(result?["isError"] as? Bool, true, name)
        }
    }

    func testAFeatureThatDidNotBuildReadsAsAnError() {
        let tool = AgentMCP.ToolCall(name: "os3d_exec", route: .state)
        let built = AgentMCP.result(id: .number(1), tool: tool, response: .ok(["producedBodyIDs": ["B"]]))
        XCTAssertNil((object(built)["result"] as? [String: Any])?["isError"])
        let failed = AgentMCP.result(id: .number(1), tool: tool, response: .ok(["failed": true, "message": "radius too large"]))
        XCTAssertEqual((object(failed)["result"] as? [String: Any])?["isError"] as? Bool, true)
    }

    func testScreenshotComesBackAsAnImage() {
        let tool = AgentMCP.ToolCall(name: "os3d_screenshot", route: .screenshot(width: 64, height: 64))
        let result = object(AgentMCP.result(id: .number(1), tool: tool, response: .png(Data([1, 2, 3]))))["result"] as? [String: Any]
        let item = (result?["content"] as? [[String: Any]])?.first
        XCTAssertEqual(item?["type"] as? String, "image")
        XCTAssertEqual(item?["data"] as? String, Data([1, 2, 3]).base64EncodedString())
    }

    func testExportReportsWhereItWasSavedAndTheTriangleCount() {
        var stl = Data(count: 80)
        stl.append(contentsOf: [2, 0, 0, 0])
        stl.append(Data(count: 100))
        let tool = AgentMCP.ToolCall(name: "os3d_export", route: .export(format: .stl, bodyIDs: [], zUp: true),
                                     exportName: "pot", exportFormat: .stl)
        var response = AgentResponse(status: 200, reason: "OK", contentType: "model/stl", body: stl)
        response.info = ["Size-MM": "110.00 x 110.00 x 150.00", "Bodies": "1"]
        let saved = AgentMCP.result(id: .number(1), tool: tool, response: response,
                                    saved: URL(fileURLWithPath: "/Users/x/Downloads/pot.stl"))
        let text = (((object(saved)["result"] as? [String: Any])?["content"] as? [[String: Any]])?.first?["text"] as? String) ?? ""
        XCTAssertTrue(text.contains("\"triangles\":2"), text)
        XCTAssertTrue(text.contains("110.00 x 110.00 x 150.00"), "the saved file's size lets an assistant confirm it: \(text)")
        XCTAssertTrue(text.contains("pot.stl"), text)
        // A sandboxed app's Downloads is a container path; a person's is ~/Downloads.
        XCTAssertEqual(AgentMCP.friendlyPath(URL(fileURLWithPath:
            "/Users/x/Library/Containers/com.laan.labs.openshape3d/Data/Downloads/pot.stl")), "~/Downloads/pot.stl")
        XCTAssertEqual(AgentMCP.friendlyPath(URL(fileURLWithPath: "/tmp/elsewhere/pot.stl")), "/tmp/elsewhere/pot.stl")
        let unsaved = AgentMCP.result(id: .number(1), tool: tool, response: response, saved: nil, saveProblem: "disk full")
        XCTAssertEqual((object(unsaved)["result"] as? [String: Any])?["isError"] as? Bool, true)
    }

    // MARK: Export file names — a model chooses them, so they are hostile input

    func testExportFileNamesCannotLeaveTheFolder() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(AgentMCP.exportFileName(requested: "flowerpot", format: .stl), "flowerpot.stl")
        XCTAssertEqual(AgentMCP.exportFileName(requested: "flowerpot.STL", format: .stl), "flowerpot.stl")
        XCTAssertEqual(AgentMCP.exportFileName(requested: "../../.ssh/authorized_keys", format: .stl), "authorized_keys.stl")
        XCTAssertEqual(AgentMCP.exportFileName(requested: "/etc/passwd", format: .step), "passwd.step")
        XCTAssertEqual(AgentMCP.exportFileName(requested: ".hidden", format: .obj), "hidden.obj")
        XCTAssertTrue(AgentMCP.exportFileName(requested: "  ", format: .threeMF, now: now).hasPrefix("openshape3d-"))
        XCTAssertTrue(AgentMCP.exportFileName(requested: "a/b\\c:d*e", format: .stl).allSatisfy { !"/\\:*".contains($0) })
        XCTAssertLessThanOrEqual(AgentMCP.exportFileName(requested: String(repeating: "x", count: 500), format: .stl).count, 84)
    }

    func testExportsNeverOverwriteAPersonsFile() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        XCTAssertEqual(AgentExportFolder.unused("pot.stl", in: folder).lastPathComponent, "pot.stl")
        try Data([1]).write(to: folder.appendingPathComponent("pot.stl"))
        XCTAssertEqual(AgentExportFolder.unused("pot.stl", in: folder).lastPathComponent, "pot 2.stl")
    }

    // MARK: Developer-only routes

    func testCaptureAndPathImportAreDeveloperRoutes() {
        // This suite runs a DEBUG build, where they exist; the Release gate is
        // the `developerRoutes` constant these routes are conditioned on.
        XCTAssertTrue(AgentRouter.developerRoutes)
        guard case .capture = AgentRouter.route(request("POST", "/v1/capture")) else {
            return XCTFail("capture should route in DEBUG")
        }
    }

    // MARK: The three copies of the text stay one text

    func testBundledGuideIsTheSkillBody() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let skill = try String(contentsOf: root.appendingPathComponent(".claude/skills/model-openshape3d/SKILL.md"), encoding: .utf8)
        let body = skill.components(separatedBy: "---").dropFirst(2).joined(separator: "---")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(AgentMCP.guide.trimmingCharacters(in: .whitespacesAndNewlines), body,
                       "run scripts/sync_ai_resources.py")
    }

    func testTheClaudeExtensionIsBundled() {
        XCTAssertNotNil(Bundle.main.url(forResource: "OpenShape3D", withExtension: "mcpb"))
        XCTAssertFalse(AgentMCP.tools.isEmpty)
    }
}
