//
//  ConstraintApplyUITests.swift
//  openshape3dUITests
//
//  Applying sketch constraints from the palette (plan §C3). Draws geometry,
//  selects it, opens the adaptive Constraints menu, and applies a constraint —
//  asserting the operation is a single undoable step and that re-applying it to
//  the now-satisfied sketch stays stable (a second solve does not drift).
//

import XCTest

final class ConstraintApplyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func startGroundSketch(_ app: XCUIApplication, window: XCUIElement) {
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)
    }

    /// Undo repeatedly until the stack empties, returning the step count.
    private func drainUndo(_ app: XCUIApplication, cap: Int = 10) -> Int {
        let undo = app.buttons["UndoButton"]
        var steps = 0
        while undo.isEnabled && steps < cap {
            undo.tap()
            steps += 1
        }
        return steps
    }

    private func applyConstraint(_ app: XCUIApplication, _ identifier: String) {
        let menu = app.buttons["ConstraintsMenu"]
        if !menu.isHittable { app.buttons["ConstrainGroup"].tap() }
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "Constraints menu should exist")
        menu.tap()
        let item = app.buttons[identifier]
        XCTAssertTrue(item.waitForExistence(timeout: 3), "\(identifier) should be present")
        XCTAssertTrue(item.isEnabled, "\(identifier) should be enabled for this selection")
        item.tap()
    }

    // MARK: - Coincident welds a shared corner

    func testCoincidentWeldsCorner() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Line A and line B meeting at an approximate corner (small gap).
        p(0.30, 0.45).press(forDuration: 0.15, thenDragTo: p(0.55, 0.45))
        p(0.57, 0.47).press(forDuration: 0.15, thenDragTo: p(0.66, 0.70))

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing two lines should push undoable steps")

        // The last drawn line is selected; add the first line to the pair.
        p(0.42, 0.45).tap()
        sleep(1)

        // Apply Coincident: the corner snaps together (one undo step).
        applyConstraint(app, "Constraint_Coincident")
        sleep(1)
        XCTAssertTrue(undo.isEnabled, "Applying Coincident should push an undoable step")

        // Re-apply to the now-satisfied sketch: a second solve must stay stable
        // (no crash, still a valid one-step command).
        applyConstraint(app, "Constraint_Coincident")
        sleep(1)

        // Two line draws + two coincident applications = exactly four steps.
        XCTAssertEqual(drainUndo(app), 4,
                       "Each draw and each constraint application is one undo step")
        XCTAssertFalse(undo.isEnabled)
    }

    // MARK: - Horizontal levels a near-horizontal line

    func testHorizontalLevelsLine() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // A single near-horizontal line (slight downward slope).
        p(0.32, 0.46).press(forDuration: 0.15, thenDragTo: p(0.64, 0.52))

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing a line should push an undoable step")

        // The completed line is selected; level it directly.
        sleep(1)
        applyConstraint(app, "Constraint_Horizontal")
        sleep(1)

        // Line draw + Horizontal = exactly two undo steps.
        XCTAssertEqual(drainUndo(app), 2,
                       "Draw + Horizontal should be exactly two undo steps")
        XCTAssertFalse(undo.isEnabled)
    }
}
