//
//  TutorialTakeUITests.swift
//  openshape3dUITests
//
//  The touch half of the YouTube tutorial series takes
//  (scripts/youtube_series/). The host script records the simulator, paces
//  the narration and drives the bridge; this test performs the gestures it
//  asks for — palette taps by element identity, viewport taps and drags by
//  normalised window coordinates, keypad entry — so the video shows the app
//  driven as a user drives it. Same remote loop as PreviewTakeUITests:
//  post "ready", poll GET /next, act, post "done[:detail]".
//
//  Skipped unless TEST_RUNNER_OS3D_TUTORIAL_TAKE=1.
//

import XCTest

final class TutorialTakeUITests: XCTestCase {

    private var control = URL(string: "http://127.0.0.1:8930")!

    func testRemoteControlledTutorialTake() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["OS3D_TUTORIAL_TAKE"] == "1",
                          "only runs under scripts/youtube_series/")
        if let port = env["OS3D_TUTORIAL_CONTROL_PORT"] {
            control = URL(string: "http://127.0.0.1:\(port)")!
        }
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft

        let app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_WELCOME"] = "1"
        app.launchEnvironment["OS3D_AGENT"] = "1"
        app.launchEnvironment["OS3D_AGENT_PORT"] = env["OS3D_TUTORIAL_BRIDGE_PORT"] ?? "8931"
        app.launchArguments += ["-os3d.snapToGrid", "YES", "-os3d.alwaysShowDimensions", "NO"]
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
        func byIdOrLabel(_ arg: String) -> XCUIElement {
            let match = NSPredicate(format: "identifier == %@ OR label == %@", arg, arg)
            return app.descendants(matching: .any).matching(match).firstMatch
        }

        let deadline = Date().addingTimeInterval(1200)
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
            case "add_samples":
                app.buttons["WelcomeAddSamplesButton"].tap()
                XCTAssertTrue(app.navigationBars["Demos"].waitForExistence(timeout: 10))
            case "open_card":                         // open_card:Motorcycle Wheel
                let card = app.staticTexts[arg].firstMatch
                XCTAssertTrue(card.waitForExistence(timeout: 5))
                card.tap()
                XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 20))
            case "back":                              // back:Demos (the folder's name)
                app.buttons[arg.isEmpty ? "Designs" : arg].firstMatch.tap()
            case "sketch_tool":                       // sketch_tool:Rect
                startSketchTool(app, arg)
            case "palette":                           // palette:Modify/ShellButton
                let parts = arg.split(separator: "/").map(String.init)
                tapPaletteTool(app, group: parts[0], id: parts[1])
            case "palette_label":                     // palette_label:Modify/Fillet
                let parts = arg.split(separator: "/").map(String.init)
                tapPaletteTool(app, group: parts[0], label: parts[1])
            case "tap":                               // tap:0.5,0.5
                let (x, y) = point(Substring(arg)); p(x, y).tap()
            case "double_tap":
                let (x, y) = point(Substring(arg)); p(x, y).doubleTap()
            case "drag":                              // drag:x,y;x,y[;pressSeconds]
                let parts = arg.split(separator: ";")
                let (x1, y1) = point(parts[0]), (x2, y2) = point(parts[1])
                let hold = parts.count > 2 ? Double(parts[2]) ?? 0.25 : 0.25
                p(x1, y1).press(forDuration: hold, thenDragTo: p(x2, y2),
                                withVelocity: .slow, thenHoldForDuration: 0.2)
            case "pinch":                             // pinch:0.5 (zoom out) / pinch:2 (zoom in)
                let scale = Double(arg) ?? 0.5
                p(0.5, 0.5).referencedElement.pinch(withScale: CGFloat(scale), velocity: scale < 1 ? -1.0 : 1.0)
            case "chain":                             // chain:x,y;x,y;… 0.6 s apart
                for (i, s) in arg.split(separator: ";").enumerated() {
                    if i > 0 { usleep(600_000) }
                    let (x, y) = point(s); p(x, y).tap()
                }
            case "button":                            // button:Exit Sketching (id or label)
                let b = byIdOrLabel(arg)
                if b.waitForExistence(timeout: 5) { b.tap() } else { result = "done:missing" }
            case "toolbar":                           // toolbar:HistoryButton — folds into … on narrow bars
                let b = byIdOrLabel(arg)
                if !(b.exists && b.isHittable) {
                    app.buttons["More"].firstMatch.tap()
                    _ = b.waitForExistence(timeout: 3)
                }
                if b.exists { b.tap() } else { result = "done:missing" }
            case "dimension":                         // dimension:40[@1] (label index; an entity is selected)
                let parts = arg.split(separator: "@").map(String.init)
                let value = parts[0], index = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
                let field = app.textFields.matching(identifier: "DimensionField").firstMatch
                if !field.exists {
                    let labels = app.buttons.matching(identifier: "DimensionLabel")
                    if labels.firstMatch.waitForExistence(timeout: 3), labels.count > index {
                        labels.element(boundBy: index)
                            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    }
                }
                if field.waitForExistence(timeout: 3) { typeOnPad(app, field: field, value) }
                else { result = "done:no-dimension" }
            case "field":                             // field:Distance=6 (a bar text field)
                let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
                let field = app.textFields[kv[0]].firstMatch
                if field.waitForExistence(timeout: 5) { typeOnPad(app, field: field, kv[1]) }
                else { result = "done:missing" }
            case "key_return":
                app.typeKey(.return, modifierFlags: [])
            case "exists":                            // exists:MaterialApply → done:yes / done:no
                result = byIdOrLabel(arg).waitForExistence(timeout: 3) ? "done:yes" : "done:no"
            case "text":                              // text:Sketching on plane → done:yes / done:no
                result = app.staticTexts[arg].waitForExistence(timeout: 3) ? "done:yes" : "done:no"
            case "sleep":
                Thread.sleep(forTimeInterval: Double(arg) ?? 0.5)
            default:
                result = "done:unknown"
            }
            post(result)
        }
        XCTFail("the host never sent finish")
    }

    /// Enter `text` on the on-canvas keypad a numeric field opens, then commit.
    /// Falls back to the hardware keyboard when no keypad appears.
    private func typeOnPad(_ app: XCUIApplication, field: XCUIElement, _ text: String) {
        field.tap()
        let padDelete = app.buttons["KeypadDelete"]
        if padDelete.waitForExistence(timeout: 2) {
            for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
                padDelete.tap(); usleep(120_000)
            }
            for character in text {
                app.buttons["Keypad-\(character)"].tap(); usleep(280_000)
            }
            usleep(500_000)
            app.buttons["KeypadCommit"].tap()
        } else {
            replaceText(field, with: text)
        }
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
        var req = URLRequest(url: control.appendingPathComponent("event"))
        req.httpMethod = "POST"
        req.httpBody = message.data(using: .utf8)
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { _, _, _ in sem.signal() }.resume()
        _ = sem.wait(timeout: .now() + 5)
    }
}
