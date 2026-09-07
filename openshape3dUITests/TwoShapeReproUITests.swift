import XCTest

/// Minimal repro that does NOT depend on the number pad, so it can be run on a
/// tree with the pad work stashed: draw a shape, switch tool, draw a second.
final class TwoShapeReproUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    func testToggleOffAndExitDismissPendingDimensionEditor() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let w = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        w.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            w.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(0.62, 0.60))
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["Rect"].firstMatch.tap()
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        XCTAssertFalse(app.buttons["Keypad-7"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Exit Sketching"].exists)
        // Reopen a candidate's editor, then exit with it still open.
        let badge = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3))
        let beforeTap = XCTAttachment(screenshot: app.screenshot())
        beforeTap.name = "rectangle-before-reopen"; beforeTap.lifetime = .keepAlways; add(beforeTap)
        // Tap the visible badge centre; XCTest's automatic hittable-point
        // fallback can choose a corner outside the compact rounded label.
        badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let afterTap = XCTAttachment(screenshot: app.screenshot())
        afterTap.name = "rectangle-after-reopen"; afterTap.lifetime = .keepAlways; add(afterTap)
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        XCTAssertFalse(app.buttons["Keypad-7"].firstMatch.exists)
    }

    func testDrawSwitchToolDrawAgain() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let w = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        w.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2); lookAtSketch(app)

        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            w.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(0.62, 0.60))
        sleep(1)
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].exists, "alive after shape 1")

        startSketchTool(app, "Circle")
        sleep(1)
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].exists, "alive after tool switch")

        // The regression this test exists for: the size card a freshly drawn
        // shape opens used to survive arming the next tool, so the next stroke
        // began ON the card (its digit grid spans the middle of the canvas)
        // rather than on the sketch — and the app hung and relaunched onto the
        // gallery. Arming a tool now ends the pending edit.
        XCTAssertFalse(app.textFields.matching(identifier: "DimensionField").firstMatch.exists,
                       "arming a tool dismisses the pending value editor")
        XCTAssertFalse(app.buttons.matching(identifier: "Keypad-7").firstMatch.exists,
                       "and takes its keypad with it")

        p(0.48, 0.47).press(forDuration: 0.15, thenDragTo: p(0.54, 0.51))
        sleep(2)
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = "at-failure"; a.lifetime = .keepAlways; add(a)
        let alive = app.staticTexts["Sketching on ground plane"].exists
        let anyEditorChrome = app.buttons["Exit Sketching"].exists
            || app.buttons.matching(identifier: "SketchGroup").count > 0
        print("REPRO alive-after-shape-2=\(alive) editorChrome=\(anyEditorChrome) "
              + "keypadKeys=\(app.buttons.matching(identifier: "Keypad-7").count)")
        XCTAssertTrue(alive, "alive after shape 2")
    }
}
