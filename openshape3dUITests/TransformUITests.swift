//
//  TransformUITests.swift
//  openshape3dUITests
//
//  Phase A6 transform depth: rotation-ring drags create an undoable
//  transform, and the Copy badge duplicates the body on drag.
//

import XCTest

final class TransformUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
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

    func testRingDragRotatesUndoably() throws {
        let app = launchSeeded()

        // The seeded box pivot projects at ~(0.5, 0.68). These two screen
        // points lie on the Z rotation handle (world XY plane) at its 150°
        // and 240° points — a quarter-turn drag. (Radius 0.5 in gizmo units
        // after the compact-gizmo restyle.)
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.4445, dy: 0.6385))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.4689, dy: 0.7131))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Two commands undoable: seed Add and the ring rotation (Move).
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Rotation should undo first, leaving Add undoable")
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Both commands undone — stack should be empty")
    }

    func testCopyDragDuplicatesBody() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        // Arm the Copy badge, then drag the Y arrow up: the drag first
        // duplicates the box and moves the copy.
        let copyBadge = app.buttons["CopyBadge"]
        XCTAssertTrue(copyBadge.waitForExistence(timeout: 5))
        copyBadge.tap()

        let arrowStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.66))
        let arrowEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        arrowStart.press(forDuration: 0.1, thenDragTo: arrowEnd)

        // The moved copy is selected: delete it.
        let delete = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(delete.isEnabled, "Copy should be selected after the drag")
        delete.tap()

        // The untouched original is still there: select it and delete it too.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).doubleTap()
        XCTAssertTrue(delete.isEnabled, "Original should still exist and be selectable")
        delete.tap()
        XCTAssertFalse(delete.isEnabled, "Both bodies deleted — nothing left to delete")
    }
}
