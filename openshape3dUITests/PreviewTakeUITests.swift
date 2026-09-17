//
//  PreviewTakeUITests.swift
//  openshape3dUITests
//
//  The tap half of the App Store preview take (scripts/preview_video.py).
//  The script records the simulator display and sequences everything —
//  pauses, camera moves and the modelling over the DEBUG bridge — and this
//  test only performs the taps it asks for, by element identity, so the
//  take does not depend on screen coordinates or on which Simulator window
//  is on top. Remote control is a tiny HTTP loop on the host: the test
//  posts "ready", then polls GET /next for an action name, performs it,
//  posts "done", and stops at "finish".
//
//  Skipped unless the runner has OS3D_PREVIEW_TAKE=1 (pass it as
//  TEST_RUNNER_OS3D_PREVIEW_TAKE=1 to xcodebuild), so the ordinary suite
//  never waits on a host that is not there.
//

import XCTest

final class PreviewTakeUITests: XCTestCase {

    private var control = URL(string: "http://127.0.0.1:8898")!

    func testRemoteControlledTake() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["OS3D_PREVIEW_TAKE"] == "1",
                          "only runs under scripts/preview_video.py")
        if let port = env["OS3D_PREVIEW_CONTROL_PORT"] {
            control = URL(string: "http://127.0.0.1:\(port)")!
        }
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_WELCOME"] = "1"
        app.launchEnvironment["OS3D_AGENT"] = "1"
        app.launchEnvironment["OS3D_AGENT_PORT"] = env["OS3D_PREVIEW_BRIDGE_PORT"] ?? "8899"
        app.launch()
        XCTAssertTrue(app.buttons["WelcomeAddSamplesButton"].waitForExistence(timeout: 20),
                      "the take opens on the welcome sheet")
        post("ready")

        let deadline = Date().addingTimeInterval(240)
        while Date() < deadline {
            guard let action = get("/next") else { Thread.sleep(forTimeInterval: 0.1); continue }
            switch action {
            case "":
                Thread.sleep(forTimeInterval: 0.05)
                continue
            case "finish":
                return
            case "add_samples":
                app.buttons["WelcomeAddSamplesButton"].tap()
            case "wheel_card":
                let card = app.staticTexts["Motorcycle Wheel"].firstMatch
                XCTAssertTrue(card.waitForExistence(timeout: 5))
                card.tap()
            case "back":
                app.buttons["Demos"].firstMatch.tap()
            case "new_design":
                let button = app.buttons["NewDesignButton"].firstMatch
                XCTAssertTrue(button.waitForExistence(timeout: 5))
                button.tap()
            case "history":
                tapToolbarItem(app, id: "HistoryButton", label: "History")
            default:
                XCTFail("unknown action \(action)")
            }
            post("done")
        }
        XCTFail("the host never sent finish")
    }

    /// Bar items fold into a "More" (…) menu on the phone, where they
    /// surface by label rather than identifier.
    private func tapToolbarItem(_ app: XCUIApplication, id: String, label: String) {
        let match = NSPredicate(format: "identifier == %@ OR label == %@", id, label)
        let item = app.descendants(matching: .any).matching(match).firstMatch
        if !(item.exists && item.isHittable) {
            app.buttons["More"].firstMatch.tap()
            XCTAssertTrue(item.waitForExistence(timeout: 3), "\(label) should be in the … menu")
        }
        item.tap()
    }

    // MARK: Control channel

    private func get(_ path: String) -> String? {
        var result: String?
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: control.appendingPathComponent(path)) { data, _, _ in
            result = data.flatMap { String(data: $0, encoding: .utf8) }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 5)
        return result
    }

    private func post(_ message: String) {
        var request = URLRequest(url: control.appendingPathComponent("event"))
        request.httpMethod = "POST"
        request.httpBody = Data(message.utf8)
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, _, _ in done.signal() }.resume()
        _ = done.wait(timeout: .now() + 5)
    }
}
