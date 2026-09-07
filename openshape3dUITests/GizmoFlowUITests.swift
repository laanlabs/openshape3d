//
//  GizmoFlowUITests.swift
//  openshape3dUITests
//
//  Verifies the move gizmo: launch with a seeded selected box, drag the
//  Y arrow upward, and confirm a second undoable command exists (seed add +
//  move). If the drag had orbited the camera instead of claiming the gizmo,
//  only one undo would exist.
//

import XCTest

final class GizmoFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testGizmoDragCreatesUndoableMove() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles

        // The seeded box is selected with its pivot at the world origin. The
        // camera frames the box, so the pivot projects below screen center
        // and the green Y arrow rises from it: drag along it, upward.
        let window = app.windows.firstMatch
        let arrowStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.66))
        let arrowEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        arrowStart.press(forDuration: 0.1, thenDragTo: arrowEnd)

        // Two commands should now be undoable: seed Add and Move.
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Move should undo first, leaving Add undoable")
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Both commands undone — stack should be empty")
    }
}
