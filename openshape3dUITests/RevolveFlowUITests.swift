//
//  RevolveFlowUITests.swift
//  openshape3dUITests
//
//  Revolve end-to-end: sketch a rectangle beside a line, tap the fill to
//  start the profile tool, switch to Revolve, pick the line as the axis, and
//  commit the revolved body.
//

import XCTest

final class RevolveFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testRevolveProfileAboutSketchLine() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        // Rectangle right of center.
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        // Plane pickers appear; tap the bare ground to sketch there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        let rectStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.40))
        let rectEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.58))
        rectStart.press(forDuration: 0.15, thenDragTo: rectEnd)

        // Vertical line just left of the rectangle: the future axis.
        startSketchTool(app, "Line")
        let lineStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.44, dy: 0.35))
        let lineEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.44, dy: 0.62))
        lineStart.press(forDuration: 0.15, thenDragTo: lineEnd)

        app.buttons["Exit Sketching"].tap()

        // Tap the rectangle fill → Extrude tool with a Revolve option.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.59, dy: 0.49)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping a filled profile should start the profile tool")

        app.buttons["Revolve"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Tap a sketch line to set the revolve axis"].waitForExistence(timeout: 3),
            "Revolve should ask for an axis line"
        )

        // Tap the line → live revolve preview with the angle field.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.44, dy: 0.48)).tap()
        XCTAssertTrue(app.staticTexts["Angle"].waitForExistence(timeout: 5),
                      "Picking the axis should switch the bar to Revolve")

        // Commit: the revolved body is created and selected.
        app.buttons["Revolve"].firstMatch.tap()
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        XCTAssertTrue(deleteButton.isEnabled, "Revolved body should be selected")
        XCTAssertFalse(app.staticTexts["Angle"].exists)

        // Three undoable commands: rect entity, line entity, revolve body.
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo revolve
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo line entity
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo rect entity
        XCTAssertFalse(undo.isEnabled)
    }
}
