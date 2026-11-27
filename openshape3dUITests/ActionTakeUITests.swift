//
//  ActionTakeUITests.swift
//  openshape3dUITests
//
//  The touch half of the "CAD actions" YouTube series
//  (scripts/youtube_series/action_tutorial.py). Every step in those videos is
//  a real touch, and every touch is REPORTED before it happens: the test posts
//  `vis:tap:x,y`, `vis:double:x,y` or `vis:drag:x1,y1;x2,y2;seconds` (window-
//  normalised) so the host can draw a touch ring on the recording exactly
//  where and when the finger landed — palette buttons, keypad keys and bar
//  buttons included. Same remote loop as TutorialTakeUITests: post "ready",
//  poll GET /next, act, post "done[:detail]".
//
//  Skipped unless TEST_RUNNER_OS3D_ACTION_TAKE=1.
//

import XCTest

final class ActionTakeUITests: XCTestCase {

    private var control = URL(string: "http://127.0.0.1:8930")!
    private var app: XCUIApplication!
    private var window: XCUIElement!

    func testRemoteControlledActionTake() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["OS3D_ACTION_TAKE"] == "1", "only runs under scripts/youtube_series/")
        if let port = env["OS3D_TUTORIAL_CONTROL_PORT"] {
            control = URL(string: "http://127.0.0.1:\(port)")!
        }
        continueAfterFailure = true
        // iPad takes are landscape; the Shorts are shot on an iPhone held upright
        XCUIDevice.shared.orientation = env["OS3D_TAKE_ORIENTATION"] == "portrait" ? .portrait : .landscapeLeft

        app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_WELCOME"] = "1"
        app.launchEnvironment["OS3D_AGENT"] = "1"
        app.launchEnvironment["OS3D_AGENT_PORT"] = env["OS3D_TUTORIAL_BRIDGE_PORT"] ?? "8931"
        app.launchArguments += ["-os3d.snapToGrid", "YES", "-os3d.alwaysShowDimensions", "NO"]
        app.launch()
        window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["WelcomeNewDesignButton"].waitForExistence(timeout: 20))
        post("ready")

        let deadline = Date().addingTimeInterval(1800)
        while Date() < deadline {
            guard let raw = get("/next") else { Thread.sleep(forTimeInterval: 0.1); continue }
            if raw.isEmpty { Thread.sleep(forTimeInterval: 0.05); continue }
            if raw == "finish" { return }
            let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
            post(perform(parts[0], parts.count > 1 ? parts[1] : ""))
        }
        XCTFail("the host never sent finish")
    }

    // MARK: - actions

    private func perform(_ name: String, _ arg: String) -> String {
        switch name {
        case "new_design":
            tap(app.buttons["WelcomeNewDesignButton"])
            return app.buttons["SketchGroup"].waitForExistence(timeout: 15) ? "done" : "done:no-editor"
        case "tap_id":                            // tap_id:FilletButton (identifier or label)
            let e = element(arg)
            guard e.waitForExistence(timeout: 5) else { return "done:missing" }
            tap(e); return "done"
        case "tap_button":                        // tap_button:Subtract (a button by label or id)
            let e = button(arg)
            guard e.waitForExistence(timeout: 5) else { return "done:missing" }
            tap(e); return "done"
        case "palette":                           // palette:Modify/FilletButton (group, then tool by id)
            let g = arg.split(separator: "/").map(String.init)
            let tool = app.buttons[g[1]]
            if !(tool.exists && tool.isHittable) {
                tap(app.buttons[g[0] + "Group"])
                _ = tool.waitForExistence(timeout: 3)
            }
            guard tool.exists else { return "done:missing" }
            tap(tool); return "done"
        case "palette_label":                     // palette_label:Sketch/Rectangle (tool by visible label)
            let g = arg.split(separator: "/").map(String.init)
            let tool = app.buttons.containing(.staticText, identifier: g[1]).firstMatch
            if !(tool.exists && tool.isHittable) {
                tap(app.buttons[g[0] + "Group"])
                _ = tool.waitForExistence(timeout: 3)
            }
            guard tool.exists else { return "done:missing" }
            tap(tool); return "done"
        case "tap":                               // tap:0.5,0.5
            let (x, y) = point(arg); tapAt(x, y); return "done"
        case "double_tap":
            let (x, y) = point(arg)
            post("vis:double:\(f(x)),\(f(y))")
            p(x, y).doubleTap(); return "done"
        case "drag":                              // drag:x,y;x,y[;pressSeconds]
            let s = arg.split(separator: ";")
            let (x1, y1) = point(String(s[0])), (x2, y2) = point(String(s[1]))
            let hold = s.count > 2 ? Double(s[2]) ?? 0.3 : 0.3
            post("vis:drag:\(f(x1)),\(f(y1));\(f(x2)),\(f(y2));\(hold)")
            p(x1, y1).press(forDuration: hold, thenDragTo: p(x2, y2), withVelocity: .slow, thenHoldForDuration: 0.2)
            return "done"
        case "orbit":                             // orbit:x,y;x,y;pointsPerSecond — NOT reported (no ring)
            let s = arg.split(separator: ";")
            let (x1, y1) = point(String(s[0])), (x2, y2) = point(String(s[1]))
            let v = s.count > 2 ? Double(s[2]) ?? 120 : 120
            p(x1, y1).press(forDuration: 0.05, thenDragTo: p(x2, y2),
                            withVelocity: XCUIGestureVelocity(rawValue: CGFloat(v)), thenHoldForDuration: 0.3)
            return "done"
        case "pinch":                             // pinch:scale[;velocity] about the window centre — NOT reported
            let s = arg.split(separator: ";").compactMap { Double($0) }
            #if targetEnvironment(macCatalyst)
            _ = s                                     // no pinch gesture on the Mac
            #else
            window.pinch(withScale: CGFloat(s.first ?? 1.3), velocity: CGFloat(s.count > 1 ? s[1] : 0.6))
            #endif
            return "done"
        case "chain":                             // chain:x,y;x,y;… 0.7 s apart
            for (i, s) in arg.split(separator: ";").enumerated() {
                if i > 0 { usleep(700_000) }
                let (x, y) = point(String(s)); tapAt(x, y)
            }
            return "done"
        case "field":                             // field:Distance=12 (a numeric field → the keypad)
            let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
            let field = app.textFields[kv[0]].firstMatch
            guard field.waitForExistence(timeout: 5) else { return "done:missing" }
            return typeOnPad(field, kv[1])
        case "tap_pad":                           // tap_pad:ExtrudeArrowValue|ExtrudeArrowField=5
            // tap a control that opens a field with the keypad, then type
            let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
            let ids = kv[0].split(separator: "|").map(String.init)
            let opener = element(ids[0])
            guard opener.waitForExistence(timeout: 5) else { return "done:missing" }
            tap(opener)
            let field = app.textFields[ids[1]].firstMatch
            guard field.waitForExistence(timeout: 4) else { return "done:no-field" }
            return typeOnPad(field, kv[1], tapField: false)
        case "tap_top":                           // tap_top:GizmoRing-Y — 6 pt inside the frame's top edge
            let e = element(arg)
            guard e.waitForExistence(timeout: 5) else { return "done:missing" }
            let wf = window.frame, ef = e.frame
            let x = (ef.midX - wf.minX) / wf.width, y = (ef.minY + 6 - wf.minY) / wf.height
            tapAt(x, y); return "done"
        case "frame":                             // frame:ID → done:x,y,w,h (window-normalised)
            let e = element(arg)
            guard e.waitForExistence(timeout: 3) else { return "done:missing" }
            let wf = window.frame, ef = e.frame
            return "done:\(f((ef.minX - wf.minX) / wf.width)),\(f((ef.minY - wf.minY) / wf.height)),"
                + "\(f(ef.width / wf.width)),\(f(ef.height / wf.height))"
        case "dimension":                         // dimension:40[@1] (a selected entity's label)
            let kv = arg.split(separator: "@").map(String.init)
            let index = kv.count > 1 ? Int(kv[1]) ?? 0 : 0
            let field = app.textFields.matching(identifier: "DimensionField").firstMatch
            if !field.exists {
                let labels = app.buttons.matching(identifier: "DimensionLabel")
                guard labels.firstMatch.waitForExistence(timeout: 3), labels.count > index else {
                    return "done:no-dimension"
                }
                tap(labels.element(boundBy: index))
            }
            guard field.waitForExistence(timeout: 3) else { return "done:no-field" }
            return typeOnPad(field, kv[0], tapField: false)
        case "text_field":                        // text_field:TextContentField=JULES (keyboard)
            let kv = arg.split(separator: "=", maxSplits: 1).map(String.init)
            let field = element(kv[0])
            guard field.waitForExistence(timeout: 5) else { return "done:missing" }
            tap(field)
            field.typeText(kv[1])
            return "done"
        case "menu":                              // menu:ExportMenu/STL (open a menu, pick an item)
            let m = arg.split(separator: "/").map(String.init)
            let menu = element(m[0])
            guard menu.waitForExistence(timeout: 5) else { return "done:missing" }
            tap(menu)
            let item = app.buttons[m[1]].firstMatch
            guard item.waitForExistence(timeout: 3) else { return "done:no-item" }
            Thread.sleep(forTimeInterval: 0.8)
            tap(item); return "done"
        case "save_sheet":                        // save_sheet:2.5 — the export's save panel
            let save = app.buttons["Save"].firstMatch
            guard save.waitForExistence(timeout: 15) else { return "done:no-sheet" }
            Thread.sleep(forTimeInterval: Double(arg) ?? 2.0)
            tap(save)
            let replace = app.buttons["Replace"].firstMatch
            if replace.waitForExistence(timeout: 2.5) { tap(replace) }
            let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)
            return XCTWaiter().wait(for: [gone], timeout: 8) == .completed ? "done:saved" : "done:stuck"
        case "exists":                            // exists:MaterialApply → done:yes / done:no
            return element(arg).waitForExistence(timeout: 3) ? "done:yes" : "done:no"
        case "text":                              // text:Face selected → done:yes / done:no (substring)
            let t = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", arg)).firstMatch
            return t.waitForExistence(timeout: 4) ? "done:yes" : "done:no"
        case "value":                             // value:FieldID → done:<current value>
            let e = element(arg)
            return e.waitForExistence(timeout: 3) ? "done:\((e.value as? String) ?? "")" : "done:missing"
        case "sleep":
            Thread.sleep(forTimeInterval: Double(arg) ?? 0.5); return "done"
        default:
            return "done:unknown"
        }
    }

    // MARK: - reported touches

    /// Tap an element, reporting where the finger lands first.
    private func tap(_ e: XCUIElement) {
        let wf = window.frame, ef = e.frame
        let x = (ef.midX - wf.minX) / wf.width, y = (ef.midY - wf.minY) / wf.height
        post("vis:tap:\(f(x)),\(f(y))")
        e.tap()
    }

    private func tapAt(_ x: Double, _ y: Double) {
        post("vis:tap:\(f(x)),\(f(y))")
        p(x, y).tap()
    }

    /// Clear a numeric field and type `text` on the on-canvas keypad, one
    /// reported key at a time, then commit. "-" is the keypad's ± on an
    /// empty field.
    private func typeOnPad(_ field: XCUIElement, _ text: String, tapField: Bool = true) -> String {
        // A field that opened with its keypad already up (a gizmo ring tap)
        // must not be tapped again: that dismisses the pad and the tool.
        if tapField && !app.buttons["KeypadDelete"].exists {
            // In a Form row (the Helix sheet) the field's frame is the whole
            // row, and only the value box on its right opens the pad.
            let wf = window.frame, ef = field.frame
            if ef.width > 200 {
                tapAt((ef.maxX - 45 - wf.minX) / wf.width, (ef.midY - wf.minY) / wf.height)
            } else {
                tap(field)
            }
        }
        let delete = app.buttons["KeypadDelete"]
        guard delete.waitForExistence(timeout: 3) else { return "done:no-keypad" }
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            tap(delete); usleep(160_000)
        }
        for c in text {
            let key = app.buttons[c == "-" ? "Keypad-±" : "Keypad-\(c)"]
            guard key.exists else { return "done:no-key-\(c)" }
            tap(key); usleep(320_000)
        }
        usleep(500_000)
        tap(app.buttons["KeypadCommit"])
        return "done"
    }

    // MARK: - helpers

    private func element(_ arg: String) -> XCUIElement {
        let match = NSPredicate(format: "identifier == %@ OR label == %@", arg, arg)
        return app.descendants(matching: .any).matching(match).firstMatch
    }

    private func button(_ arg: String) -> XCUIElement {
        let match = NSPredicate(format: "identifier == %@ OR label == %@", arg, arg)
        return app.buttons.matching(match).firstMatch
    }

    private func p(_ x: Double, _ y: Double) -> XCUICoordinate {
        window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }

    private func point(_ s: String) -> (Double, Double) {
        let v = s.split(separator: ",").compactMap { Double($0) }
        return (v[0], v[1])
    }

    private func f(_ v: Double) -> String { String(format: "%.4f", v) }

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
