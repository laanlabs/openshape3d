//
//  BottleTakeUITests.swift
//  openshape3dUITests
//
//  The gesture half of the "Glass Bottle" YouTube tutorial take
//  (scripts/youtube_tutorial/bottle_take.py). The host script records the
//  simulator, paces the narration and reads the bridge; this test performs
//  the real touch interactions it asks for — palette taps by element
//  identity, viewport taps by normalised window coordinates — so the video
//  shows the app driven exactly as a user would drive it. Same remote loop
//  as PreviewTakeUITests: post "ready", poll GET /next, act, post "done".
//
//  Skipped unless TEST_RUNNER_OS3D_BOTTLE_TAKE=1.
//

import XCTest

final class BottleTakeUITests: XCTestCase {

    private var control = URL(string: "http://127.0.0.1:8897")!

    func testRemoteControlledBottleTake() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["OS3D_BOTTLE_TAKE"] == "1",
                          "only runs under scripts/youtube_tutorial/bottle_take.py")
        if let port = env["OS3D_BOTTLE_CONTROL_PORT"] {
            control = URL(string: "http://127.0.0.1:\(port)")!
        }
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft

        let app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_WELCOME"] = "1"
        app.launchEnvironment["OS3D_AGENT"] = "1"
        app.launchEnvironment["OS3D_AGENT_PORT"] = env["OS3D_BOTTLE_BRIDGE_PORT"] ?? "8921"
        app.launchArguments += [
            "-os3d.snapToGrid", "NO",
            "-os3d.snapToSketchGuidelines", "YES",
            "-os3d.snapToSketchGuidepoints", "YES",
            "-os3d.snapToFaceGuidepoints", "YES",
            "-os3d.alwaysShowDimensions", "NO",
        ]
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["WelcomeNewDesignButton"].waitForExistence(timeout: 20),
                      "the take opens on the welcome sheet")
        post("ready")

        func p(_ x: Double, _ y: Double) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        func point(_ s: Substring) -> (Double, Double) {
            let parts = s.split(separator: ",").compactMap { Double($0) }
            return (parts[0], parts[1])
        }

        let deadline = Date().addingTimeInterval(600)
        while Date() < deadline {
            guard let raw = get("/next") else { Thread.sleep(forTimeInterval: 0.1); continue }
            if raw.isEmpty { Thread.sleep(forTimeInterval: 0.05); continue }
            if raw == "finish" { return }
            let action = raw.split(separator: ":", maxSplits: 1).map(String.init)
            let name = action[0], arg = action.count > 1 ? action[1] : ""
            var result = "done"
            switch name {
            case "new_design":
                app.buttons["WelcomeNewDesignButton"].tap()
                XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 15))
            case "sketch_tool":                       // sketch_tool:Line
                startSketchTool(app, arg)
            case "tap":                               // tap:0.5,0.5
                let (x, y) = point(Substring(arg)); p(x, y).tap()
            case "drag":                              // drag:x,y;x,y (press, then drag)
                let ends = arg.split(separator: ";")
                let (x0, y0) = point(ends[0]); let (x1, y1) = point(ends[1])
                p(x0, y0).press(forDuration: 0.15, thenDragTo: p(x1, y1))
            case "key":                               // key:escape | key:return
                app.typeKey(arg == "escape" ? XCUIKeyboardKey.escape : XCUIKeyboardKey.return, modifierFlags: [])
            case "double_tap":
                let (x, y) = point(Substring(arg)); p(x, y).doubleTap()
            case "chain":                             // chain:x,y;x,y;… with 0.6 s between taps
                for (i, s) in arg.split(separator: ";").enumerated() {
                    if i > 0 { usleep(600_000) }
                    let (x, y) = point(s); p(x, y).tap()
                }
            case "wait_text":                         // wait_text:Sketching on plane
                result = app.staticTexts[arg].waitForExistence(timeout: 5) ? "done" : "done:missing"
            case "button":                            // button:Exit Sketching  (id or label)
                let match = NSPredicate(format: "identifier == %@ OR label == %@", arg, arg)
                let b = app.buttons.matching(match).firstMatch
                if b.waitForExistence(timeout: 5) { b.tap() } else { result = "done:missing" }
            case "palette":                           // palette:Modify/ShellButton
                let parts = arg.split(separator: "/").map(String.init)
                tapPaletteTool(app, group: parts[0], id: parts[1])
            case "palette_label":                     // palette_label:Sketch/Line (toggle a draw tool)
                let parts = arg.split(separator: "/").map(String.init)
                tapPaletteTool(app, group: parts[0], label: parts[1])
            case "dimension":                         // dimension:230 (a line is selected)
                // The badge appears once the tapped entity is selected; give it
                // time, and fall back to a "<n> mm" button if the id is absent.
                let field = app.textFields.matching(identifier: "DimensionField").firstMatch
                var label = app.buttons["DimensionLabel"].firstMatch
                if !label.waitForExistence(timeout: 6) {
                    label = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "^[0-9.]+ (mm|cm|in)$")).firstMatch
                }
                if label.exists {
                    label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    if field.waitForExistence(timeout: 4) {
                        typeOnPad(app, field: field, arg)
                    } else {
                        result = "done:no-field"
                    }
                } else {
                    result = "done:no-dimension"
                }
            case "field":                             // field:ShellThicknessField=2
                let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
                let field = app.textFields[kv[0]].firstMatch
                if field.waitForExistence(timeout: 5) { typeOnPad(app, field: field, kv[1]) } else { result = "done:missing" }
            case "key_return":
                app.typeKey(.return, modifierFlags: [])
            case "exists":                            // exists:ShellApply → done:yes / done:no
                let match = NSPredicate(format: "identifier == %@ OR label == %@", arg, arg)
                let e = app.descendants(matching: .any).matching(match).firstMatch
                result = e.waitForExistence(timeout: 3) ? "done:yes" : "done:no"
            case "enabled":                           // enabled:ShellApply → done:yes / done:no
                let b = app.buttons[arg].firstMatch
                result = (b.waitForExistence(timeout: 3) && b.isEnabled) ? "done:yes" : "done:no"
            case "sleep":
                Thread.sleep(forTimeInterval: Double(arg) ?? 0.5)
            default:
                result = "done:unknown"
            }
            post(result)
        }
        XCTFail("the host never sent finish")
    }

    /// Enter `text` on the on-canvas keypad the numeric fields open, then commit.
    private func typeOnPad(_ app: XCUIApplication, field: XCUIElement, _ text: String) {
        field.tap()
        let padDelete = app.buttons["KeypadDelete"]
        guard padDelete.waitForExistence(timeout: 3) else { return }
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            padDelete.tap(); usleep(120_000)
        }
        for character in text {
            // The pad has no "-" key: sign is the ± toggle, which on an empty
            // field yields "-", so a leading minus works positionally.
            let key = character == "-" ? "±" : String(character)
            app.buttons["Keypad-\(key)"].tap(); usleep(280_000)
        }
        usleep(500_000)
        app.buttons["KeypadCommit"].tap()
    }

    private func get(_ path: String) -> String? {
        let sem = DispatchSemaphore(value: 0)
        var out: String?
        URLSession.shared.dataTask(with: control.appendingPathComponent(path)) { data, _, _ in
            out = data.flatMap { String(data: $0, encoding: .utf8) }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 5)
        return out
    }

    private func post(_ message: String) {
        var req = URLRequest(url: control)
        req.httpMethod = "POST"
        req.httpBody = message.data(using: .utf8)
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { _, _, _ in sem.signal() }.resume()
        _ = sem.wait(timeout: .now() + 5)
    }
}
