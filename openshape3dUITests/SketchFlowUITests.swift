//
//  SketchFlowUITests.swift
//  openshape3dUITests
//
//  Sketch mode: arm the Rect tool, confirm sketch mode UI, drag to draw a
//  rectangle, verify the entity committed (undoable), and finish the sketch.
//

import XCTest

final class SketchFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testDrawRectangleInSketchMode() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_AUTO_OPEN"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")

        // Plane pickers appear; tapping the bare ground starts there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()

        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3),
                      "Sketch status bar should appear")
        lookAtSketch(app)

        // Let the head-on camera animation settle.
        sleep(2)
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.45))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.62))
        start.press(forDuration: 0.15, thenDragTo: end)

        // The committed entity is undoable — this session started clean.
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing a rectangle should push an undoable command")

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists,
                       "Exiting should dismiss the sketch status bar")
    }
}
