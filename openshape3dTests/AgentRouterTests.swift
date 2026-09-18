//
//  AgentRouterTests.swift
//  openshape3dTests
//
//  Routing and error shaping for the agent bridge. Pure statics only — no
//  `EditorViewModel` (STATUS_AND_NEXT_STEPS gotcha 1), which is why the router
//  was split out of `AgentServer` in the first place.
//
//  The heart of this file is the three-way split on a command id. A human
//  pressing a dead key just presses another one; an agent told only "false"
//  retries the same call forever. So "no such id", "id exists but nothing
//  routes it", and "id is fine but the mode is wrong" have to be three
//  different answers, and the first two are decidable without the editor.
//

import XCTest
@testable import openshape3d

final class AgentRouterTests: XCTestCase {

    // MARK: Helpers

    private func request(_ method: String, _ target: String, body: String? = nil) -> AgentRequest {
        var text = "\(method) \(target) HTTP/1.1\r\n"
        if let body {
            text += "Content-Length: \(body.utf8.count)\r\n\r\n\(body)"
        } else {
            text += "\r\n"
        }
        guard case let .complete(parsed) = AgentHTTP.parse(Data(text.utf8)) else {
            fatalError("test fixture did not parse: \(text)")
        }
        return parsed
    }

    private func route(_ method: String, _ target: String, body: String? = nil) -> AgentRoute {
        AgentRouter.route(request(method, target, body: body))
    }

    private func json(_ response: AgentResponse) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: response.body)) as? [String: Any] ?? [:]
    }

    // MARK: Routing

    func testRoutesTheReadOnlyEndpoints() {
        XCTAssertEqual(route("GET", "/v1/health"), .health)
        XCTAssertEqual(route("GET", "/v1/commands"), .commands)
        XCTAssertEqual(route("GET", "/v1/state"), .state)
    }

    func testScreenshotTakesItsSizeFromTheQuery() {
        XCTAssertEqual(route("GET", "/v1/screenshot?w=800&h=600"), .screenshot(width: 800, height: 600))
    }

    func testScreenshotSizeDefaultsAndClamps() {
        XCTAssertEqual(route("GET", "/v1/screenshot"),
                       .screenshot(width: AgentRouter.defaultShotSize, height: AgentRouter.defaultShotSize))
        XCTAssertEqual(route("GET", "/v1/screenshot?w=99999&h=2"),
                       .screenshot(width: AgentRouter.maxShotSize, height: AgentRouter.minShotSize))
    }

    // MARK: /v1/export

    func testExportDefaultsToSTLOfTheWholeDesign() {
        XCTAssertEqual(route("GET", "/v1/export"), .export(format: .stl, bodyIDs: [], zUp: false))
        XCTAssertTrue(AgentRoute.export(format: .stl, bodyIDs: [], zUp: false).needsEditor)
    }

    func testExportTakesFormatAndBodies() {
        XCTAssertEqual(route("GET", "/v1/export?format=3MF&body=A,%20B"),
                       .export(format: .threeMF, bodyIDs: ["A", "B"], zUp: false))
        XCTAssertEqual(route("GET", "/v1/export?format=step&up=Z"),
                       .export(format: .step, bodyIDs: [], zUp: true))
    }

    func testExportRefusesAnUpAxisThatIsNotYOrZ() {
        guard case let .reply(status, error, _) = route("GET", "/v1/export?up=x") else {
            return XCTFail("expected a reply")
        }
        XCTAssertEqual(status, 400)
        XCTAssertEqual(error, "bad_up_axis")
    }

    func testExportRefusesAnUnknownFormatByName() {
        guard case let .reply(status, error, message) = route("GET", "/v1/export?format=gcode") else {
            return XCTFail("expected a reply")
        }
        XCTAssertEqual(status, 400)
        XCTAssertEqual(error, "unknown_format")
        XCTAssertTrue(message.contains("stl"), "the refusal must name the formats that work")
    }

    func testExportIsGETOnly() {
        guard case let .reply(status, _, _) = route("POST", "/v1/export", body: "{}") else {
            return XCTFail("expected a reply")
        }
        XCTAssertEqual(status, 405)
    }

    // MARK: /v1/check and /v1/capture (docs/FREECAD_PLAYBOOK.md D1/D2)

    func testCheckRoutesWithBodyAndBOPQuery() {
        XCTAssertEqual(route("GET", "/v1/check"),
                       .check(bodyID: nil, runBOPCheck: false))
        XCTAssertEqual(route("GET", "/v1/check?bop=1"),
                       .check(bodyID: nil, runBOPCheck: true))
        XCTAssertEqual(route("GET", "/v1/check?body=AB12&bop=0"),
                       .check(bodyID: "AB12", runBOPCheck: false))
    }

    func testCaptureCarriesItsNote() {
        XCTAssertEqual(route("POST", "/v1/capture",
                             body: #"{"note":"wheel hub looks wrong"}"#),
                       .capture(note: "wheel hub looks wrong"))
        XCTAssertEqual(route("POST", "/v1/capture"), .capture(note: ""))
    }

    func testCheckIsGETOnlyAndCaptureIsPOSTOnly() {
        guard case let .reply(checkStatus, checkError, _) = route("POST", "/v1/check") else {
            return XCTFail("expected a reply for POST /v1/check")
        }
        XCTAssertEqual(checkStatus, 405)
        XCTAssertEqual(checkError, "method_not_allowed")
        guard case let .reply(captureStatus, captureError, _) = route("GET", "/v1/capture") else {
            return XCTFail("expected a reply for GET /v1/capture")
        }
        XCTAssertEqual(captureStatus, 405)
        XCTAssertEqual(captureError, "method_not_allowed")
    }

    func testCheckAndCaptureNeedTheEditor() {
        XCTAssertTrue(AgentRoute.check(bodyID: nil, runBOPCheck: false).needsEditor)
        XCTAssertTrue(AgentRoute.capture(note: "").needsEditor)
    }

    func testEdgeAndFaceDiscoveryRequireABodyParam() {
        XCTAssertEqual(route("GET", "/v1/edges?body=AB12"), .edges(bodyID: "AB12"))
        XCTAssertEqual(route("GET", "/v1/faces?body=AB12"), .faces(bodyID: "AB12"))
        for path in ["/v1/edges", "/v1/faces"] {
            guard case let .reply(status, error, message) = route("GET", path) else {
                return XCTFail("expected a reply for \(path) without ?body=")
            }
            XCTAssertEqual(status, 400)
            XCTAssertEqual(error, "missing_body_param")
            XCTAssertTrue(message.contains("/v1/state"), message)
        }
        XCTAssertTrue(AgentRoute.edges(bodyID: "x").needsEditor)
        XCTAssertTrue(AgentRoute.faces(bodyID: "x").needsEditor)
    }

    func testUnknownPathIs404() {
        guard case let .reply(status, error, _) = route("GET", "/v1/nope") else {
            return XCTFail("expected a reply")
        }
        XCTAssertEqual(status, 404)
        XCTAssertEqual(error, "unknown_path")
    }

    func testWrongMethodIs405() {
        for target in ["/v1/health", "/v1/commands", "/v1/state", "/v1/screenshot"] {
            guard case let .reply(status, error, _) = route("POST", target) else {
                return XCTFail("expected a reply for POST \(target)")
            }
            XCTAssertEqual(status, 405, "POST \(target)")
            XCTAssertEqual(error, "method_not_allowed")
        }
        guard case let .reply(status, _, _) = route("GET", "/v1/command") else {
            return XCTFail("expected a reply")
        }
        XCTAssertEqual(status, 405)
    }

    // MARK: POST /v1/command — the three-way split

    func testRoutableCommandReachesTheEditor() {
        XCTAssertEqual(route("POST", "/v1/command", body: #"{"id":"view.isometric"}"#),
                       .runCommand(id: "view.isometric"))
    }

    func testUnknownCommandIdIsRejectedWithoutTheEditor() {
        guard case let .reply(status, error, message) = route(
            "POST", "/v1/command", body: #"{"id":"view.izometric"}"#
        ) else { return XCTFail("expected a reply") }
        XCTAssertEqual(status, 400)
        XCTAssertEqual(error, "unknown_command")
        // The recovery has to be in the message, or the agent has nowhere to go.
        XCTAssertTrue(message.contains("/v1/commands"), message)
    }

    /// The catalog is deliberately wider than the routing table — it names
    /// commands whose editor entry points do not exist yet. Reporting those as
    /// a plain failure would be indistinguishable from a wrong-mode refusal.
    func testCatalogCommandWithNoEntryPointSaysSo() throws {
        guard let unrouted = CommandRegistry.all.first(where: {
            !CommandRegistry.routableIDs.contains($0.id)
        }) else {
            throw XCTSkip("every catalog command now routes — delete this test")
        }
        guard case let .reply(status, error, _) = route(
            "POST", "/v1/command", body: #"{"id":"\#(unrouted.id)"}"#
        ) else { return XCTFail("expected a reply") }
        XCTAssertEqual(status, 400)
        XCTAssertEqual(error, "unrouted_command")
    }

    func testCommandWithNoBodyOrNoIdIs400() {
        for body in [nil, "{}", #"{"id":""}"#, "not json"] as [String?] {
            guard case let .reply(status, error, _) = route("POST", "/v1/command", body: body) else {
                return XCTFail("expected a reply for body \(String(describing: body))")
            }
            XCTAssertEqual(status, 400, "body \(String(describing: body))")
            XCTAssertEqual(error, "missing_id")
        }
    }

    // MARK: Which routes need the main actor

    func testOnlyEditorRoutesRequireTheHop() {
        XCTAssertFalse(AgentRoute.health.needsEditor)
        XCTAssertFalse(AgentRoute.commands.needsEditor)
        XCTAssertFalse(AgentRoute.reply(status: 404, error: "x", message: "y").needsEditor)
        XCTAssertTrue(AgentRoute.state.needsEditor)
        XCTAssertTrue(AgentRoute.runCommand(id: "view.fit").needsEditor)
        XCTAssertTrue(AgentRoute.screenshot(width: 10, height: 10).needsEditor)
    }

    // MARK: Response shaping

    func testHealthReportsPortAndProtocol() {
        let payload = json(AgentRouter.healthResponse(port: 8787))
        XCTAssertEqual(payload["ok"] as? Bool, true)
        XCTAssertEqual(payload["port"] as? Int, 8787)
        XCTAssertEqual(payload["protocol"] as? Int, AgentServer.protocolVersion)
        XCTAssertEqual(payload["app"] as? String, "openshape3d")
        XCTAssertNotNil(payload["hasDocument"] as? Bool)
    }

    /// An agent handed the full catalog would waste turns on ids that cannot
    /// run, so `/v1/commands` must offer exactly what Command Search offers.
    func testCommandsListsOnlyWhatCanActuallyRun() {
        let payload = json(AgentRouter.commandsResponse())
        guard let commands = payload["commands"] as? [[String: Any]] else {
            return XCTFail("no commands array")
        }
        XCTAssertEqual(commands.count, CommandRegistry.launchableCommands.count)
        XCTAssertEqual(payload["count"] as? Int, commands.count)

        let ids = Set(commands.compactMap { $0["id"] as? String })
        XCTAssertEqual(ids, Set(CommandRegistry.launchableCommands.map(\.id)))
        for id in ids {
            XCTAssertTrue(CommandRegistry.routableIDs.contains(id), "\(id) is offered but cannot run")
        }
        XCTAssertFalse(ids.contains("app.commandSearch"), "the launcher itself is not a target")
    }

    func testEveryOfferedCommandCarriesTitleAndCategory() {
        let payload = json(AgentRouter.commandsResponse())
        let commands = payload["commands"] as? [[String: Any]] ?? []
        for entry in commands {
            XCTAssertNotNil(entry["title"] as? String, "\(entry)")
            XCTAssertNotNil(entry["category"] as? String, "\(entry)")
        }
    }

    func testFailureCarriesAStableCodeAndAHumanMessage() {
        let response = AgentRouter.response(for: .reply(status: 409, error: "no_document", message: "open one"))
        XCTAssertEqual(response?.status, 409)
        XCTAssertEqual(response?.reason, "Conflict")
        let payload = json(response!)
        XCTAssertEqual(payload["ok"] as? Bool, false)
        XCTAssertEqual(payload["error"] as? String, "no_document")
        XCTAssertEqual(payload["message"] as? String, "open one")
    }

    func testResponseForNonReplyRouteIsNil() {
        XCTAssertNil(AgentRouter.response(for: .health))
        XCTAssertNil(AgentRouter.response(for: .state))
    }

    func testPNGResponseIsNotLabelledJSON() {
        XCTAssertEqual(AgentResponse.png(Data([0x89, 0x50])).contentType, "image/png")
        XCTAssertEqual(AgentResponse.ok([:]).contentType, "application/json")
    }
}
