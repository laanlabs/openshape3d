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

        // The seeded box is selected; the gizmo sits at the box's centre
        // (2026-09-14), which the fitted camera projects at about (0.5, 0.5),
        // and the green Y arrow rises from it: drag along it, upward.
        let window = app.windows.firstMatch
        let arrowStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.499, dy: 0.44))
        let arrowEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.499, dy: 0.25))
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
        // portrait iPad; gizmo at the box centre since 2026-09-14).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.526, dy: 0.558)).tap()
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
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.499, dy: 0.407)).tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForExistence(timeout: 3),
                      "An arrow tap should open the distance field")
        XCTAssertTrue(app.otherElements["NumericKeypad"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "GizmoAxis-Y").firstMatch.value as? String, "lit")
        app.buttons["MoveDistanceCancel"].tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForNonExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "GizmoAxis-Y").firstMatch.value as? String, "idle")
    }

    /// Copy badge on, then a typed distance: the copy moves, the original
    /// stays (iPad, 2026-09-14) — three undo steps (seed Add, Copy, Move)
    /// where a plain typed move leaves two.
    func testCopyBadgeThenTypedDistanceMovesADuplicate() throws {
        let app = launchSeeded()
        let copy = app.buttons["CopyBadge"]
        XCTAssertTrue(copy.waitForExistence(timeout: 3))
        copy.tap()
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.499, dy: 0.407)).tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForExistence(timeout: 3))
        app.buttons["Keypad-5"].tap()
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(app.textFields["MoveDistanceField"].waitForNonExistence(timeout: 3))
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()   // Move
        XCTAssertTrue(undo.isEnabled)
        undo.tap()   // Copy
        XCTAssertTrue(undo.isEnabled, "A copied move leaves the seed Add still undoable")
        undo.tap()   // seed Add
        XCTAssertFalse(undo.isEnabled)
    }

    /// Reposition badge → "move the gizmo" mode: a tap on the box's top face
    /// drops the gizmo there (the crosshair moves), Recenter appears and
    /// puts it back, Done leaves the mode (iPad, 2026-09-14).
    func testRepositionBadgeMovesTheGizmoAndRecenterReturnsIt() throws {
        let app = launchSeeded()
        let reposition = app.buttons["RepositionBadge"]
        XCTAssertTrue(reposition.waitForExistence(timeout: 3))
        reposition.tap()
        XCTAssertTrue(app.staticTexts["GizmoRepositionHint"].waitForExistence(timeout: 3))
        let crosshair = app.descendants(matching: .any).matching(identifier: "GizmoPivotCrosshair").firstMatch
        XCTAssertTrue(crosshair.waitForExistence(timeout: 3))
        let before = crosshair.frame.midX
        XCTAssertFalse(app.buttons["RecenterBadge"].exists, "nothing to recentre yet")

        // Tap the top face, left of the pivot: the gizmo goes there.
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.35)).tap()
        let recenter = app.buttons["RecenterBadge"]
        XCTAssertTrue(recenter.waitForExistence(timeout: 3), "off its centre, Recenter is offered")
        XCTAssertLessThan(crosshair.frame.midX, before - 60, "the crosshair moved to the tap")

        recenter.tap()
        XCTAssertTrue(recenter.waitForNonExistence(timeout: 3))
        XCTAssertEqual(crosshair.frame.midX, before, accuracy: 4, "back at the centre")

        reposition.tap()   // reads Done while the mode is on
        XCTAssertTrue(app.staticTexts["GizmoRepositionHint"].waitForNonExistence(timeout: 3))
        XCTAssertFalse(crosshair.exists, "the dot is back")
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
