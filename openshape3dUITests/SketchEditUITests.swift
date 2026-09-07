//
//  SketchEditUITests.swift
//  openshape3dUITests
//
//  Sketch editing (A3): draw two crossing lines, drag one line's endpoint
//  (pushes a coalesced move command), then trim the dragged line at the
//  crossing. The undo stack must hold exactly four steps: line, line, move,
//  trim.
//

import XCTest

final class SketchEditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testEndpointDragAndTrimPushUndoSteps() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")

        // Plane pickers appear; tapping the bare ground starts there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()

        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3),
                      "Sketch status bar should appear")
        lookAtSketch(app)

        // Let the head-on camera animation settle.
        sleep(2)

        func point(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Line A: horizontal. Line B: vertical, crossing A near its middle
        // (B starts on empty space so the stroke draws instead of editing).
        point(0.35, 0.50).press(forDuration: 0.15, thenDragTo: point(0.65, 0.50))
        point(0.50, 0.38).press(forDuration: 0.15, thenDragTo: point(0.50, 0.62))

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing lines should push undoable commands")

        // Tap B to select it (also ends line chaining, so the next drag on
        // its endpoint edits instead of chaining a new line).
        point(0.50, 0.55).tap()
        sleep(1) // let the tap's gesture recognizers fully resolve

        // Drag B's lower endpoint: the stroke starts on the entity, so it
        // edits (move command) instead of drawing a new line. Slow drag with
        // an end hold so the pan recognizer reliably engages and settles.
        point(0.50, 0.62).press(
            forDuration: 0.3,
            thenDragTo: point(0.60, 0.70),
            withVelocity: .slow,
            thenHoldForDuration: 0.2
        )
        sleep(1)

        // Trim B between the crossing and the moved endpoint.
        let trimButton = app.buttons.containing(.staticText, identifier: "Trim").firstMatch
        XCTAssertTrue(trimButton.exists)
        trimButton.tap()
        point(0.55, 0.60).tap()

        // Exactly four undo steps: line A, line B, endpoint move, trim. The
        // move being one step proves the drag coalesced into one command.
        for step in 1...4 {
            XCTAssertTrue(undo.isEnabled, "Undo step \(step) should be available")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "Line + line + move + trim should be exactly four undo steps")

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists,
                       "Exiting should dismiss the sketch status bar")
    }
}
