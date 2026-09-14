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

    /// Tapping (not dragging) a rotation ring opens the angle field WITH the
    /// app's keypad — on the iPad the field came up empty with no keyboard
    /// (2026-09-14) — and the ring is drawn lit while the entry is open;
    /// the keypad commits the angle as one undoable rotation.
    func testTappingARingOpensTheAngleKeypadAndLightsTheRing() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch
        // The horizontal ring's arc sits just below the pivot (seed layout,
        // portrait iPad; see the 2026-09-14 screenshot in the receipt).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.528, dy: 0.749)).tap()
        XCTAssertTrue(app.textFields["RotationAngleField"].waitForExistence(timeout: 3),
                      "A ring tap should open the angle field")
        XCTAssertTrue(app.otherElements["NumericKeypad"].waitForExistence(timeout: 3),
                      "The app's keypad comes up with the field")
        let lit = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'GizmoRing-' AND value == 'lit'"))
        XCTAssertEqual(lit.count, 1, "The tapped ring is drawn lit while its entry is open")

        app.buttons["Keypad-4"].tap()
        app.buttons["Keypad-5"].tap()
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(app.textFields["RotationAngleField"].waitForNonExistence(timeout: 3))
        XCTAssertEqual(lit.count, 0, "Nothing stays lit once the entry closes")
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Rotate undoes first, leaving the seed Add")
    }

    /// The same for an arrow: distance field + keypad, and the arrow lit.
    func testTappingAnArrowOpensTheDistanceKeypadAndLightsTheArrow() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.499, dy: 0.592)).tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForExistence(timeout: 3),
                      "An arrow tap should open the distance field")
        XCTAssertTrue(app.otherElements["NumericKeypad"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "GizmoAxis-Y").firstMatch.value as? String, "lit")
        app.buttons["MoveDistanceCancel"].tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForNonExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "GizmoAxis-Y").firstMatch.value as? String, "idle")
    }

    private func launchSeeded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles
        return app
    }
}
