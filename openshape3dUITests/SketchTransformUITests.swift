//
//  SketchTransformUITests.swift
//  openshape3dUITests
//
//  Plan §B6 transform flows: the sketch selection gizmo (select two lines,
//  drag the centroid move handle, one coalesced undo step) and body Rotate
//  Around Axis (world X + typed 45° commit, undoable).
//

import XCTest

final class SketchTransformUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testSketchSelectionMoveHandleDragUndo() throws {
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
        sleep(2) // let the head-on camera animation settle

        func point(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Two parallel horizontal lines; their centroid lands between them
        // on empty grid, where the selection gizmo's move handle will sit.
        point(0.35, 0.42).press(forDuration: 0.15, thenDragTo: point(0.65, 0.42))
        point(0.35, 0.58).press(forDuration: 0.15, thenDragTo: point(0.65, 0.58))

        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.isEnabled, "Drawing lines should push undoable commands")

        // Select both lines (tap + tap toggles each into the selection).
        point(0.50, 0.42).tap()
        sleep(1)
        point(0.50, 0.58).tap()
        sleep(1)

        // The sketch Copy chip riding the selection proves the gizmo state
        // is armed for the selection.
        XCTAssertTrue(app.buttons["SketchCopyBadge"].waitForExistence(timeout: 3),
                      "Selecting sketch entities should show the sketch Copy chip")

        // Drag the move handle at the selection centroid: both lines
        // translate in ONE coalesced undo step.
        point(0.50, 0.50).press(
            forDuration: 0.3,
            thenDragTo: point(0.58, 0.50),
            withVelocity: .slow,
            thenHoldForDuration: 0.2
        )
        sleep(1)

        // Exactly three undo steps: line A, line B, gizmo move.
        for step in 1...3 {
            XCTAssertTrue(undo.isEnabled, "Undo step \(step) should be available")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "Line + line + gizmo move should be exactly three undo steps")

        app.buttons["Exit Sketching"].tap()
    }

    func testRotateAroundWorldAxisTypedAngleCommitUndo() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles

        // Seeded box is selected: arm Rotate Around Axis.
        tapPaletteTool(app, group: "Transform", id: "RotateAxisButton")
        XCTAssertTrue(
            app.staticTexts["Tap a sketch line, or pick a world axis"].waitForExistence(timeout: 3),
            "Rotate Axis should prompt for an axis"
        )

        // World X axis → the angle bar appears.
        app.buttons["RotateAxisX"].tap()
        let angleField = app.textFields["RotateAxisAngle"]
        XCTAssertTrue(angleField.waitForExistence(timeout: 3),
                      "Choosing an axis should open the angle field")

        // Type an exact 45° and commit. The angle field opens the number pad,
        // not the keyboard; `replaceText` drives whichever is in front.
        replaceText(angleField, with: "45")
        let apply = app.buttons["RotateAxisApply"]
        if apply.exists {
            apply.tap()
        }
        XCTAssertFalse(angleField.waitForExistence(timeout: 2),
                       "Committing should dismiss the rotate bar")

        // Two undoable commands: seed Add and the rotation.
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Rotation should undo first, leaving the seed Add")
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Both commands undone — stack should be empty")
    }
}
