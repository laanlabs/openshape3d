//
//  SketchOffsetUITests.swift
//  openshape3dUITests
//
//  Offset Edge in sketch mode (spec §1.9) — the tool the Shapr3D starter
//  tutorial opens with. Draw a rectangle, offset it, and prove the result is
//  a real second profile by extruding it after leaving the sketch.
//

import XCTest

final class SketchOffsetUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Arm Offset on a fresh sketch containing one rectangle.
    private func sketchWithRectangle(_ app: XCUIApplication) -> XCUIElement {
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")

        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        lookAtSketch(app)
        sleep(2)

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.34, dy: 0.38))
            .press(forDuration: 0.15,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.60)))
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "The rectangle should be undoable")
        return window
    }

    func testOffsetEdgeAddsASecondProfileThatExtrudes() throws {
        let app = XCUIApplication()
        let window = sketchWithRectangle(app)

        startSketchTool(app, "Offset")
        XCTAssertTrue(app.staticTexts["Tap sketch geometry to offset"].waitForExistence(timeout: 3),
                      "Arming Offset should show its bar with the pick prompt")

        let apply = app.buttons["SketchOffsetApply"]
        XCTAssertFalse(apply.isEnabled, "Apply stays disabled until something is picked")

        // Tap the rectangle's top edge.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.38)).tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: 3),
                      "Tapping the rectangle should pick it")
        XCTAssertTrue(apply.isEnabled, "A pick with a non-zero distance should enable Apply")

        apply.tap()

        // Committing resets the pick but leaves the tool armed for another
        // offset, matching Shapr3D.
        XCTAssertTrue(app.staticTexts["Tap sketch geometry to offset"].waitForExistence(timeout: 3))
        XCTAssertFalse(apply.isEnabled)

        // The offset is real geometry: leaving the sketch, the band between the
        // two rectangles is its own closed region and can be extruded.
        app.buttons["Exit Sketching"].tap()
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.34)).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 5),
                      "The offset should produce a profile the extrude bar recognises")
    }

    func testOffsetCancelLeavesTheSketchUntouched() throws {
        let app = XCUIApplication()
        let window = sketchWithRectangle(app)

        startSketchTool(app, "Offset")
        XCTAssertTrue(app.staticTexts["Tap sketch geometry to offset"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.38)).tap()
        XCTAssertTrue(app.staticTexts["1 selected"].waitForExistence(timeout: 3))

        app.buttons["SketchOffsetCancel"].tap()

        // Cancel drops the tool, so the bar goes away and nothing was added:
        // one undo still leaves an empty redo-able rectangle behind it.
        XCTAssertFalse(app.staticTexts["1 selected"].exists)
        app.buttons["UndoButton"].tap()
        XCTAssertFalse(app.buttons["UndoButton"].isEnabled,
                       "Only the rectangle should have been on the undo stack")
    }
}
