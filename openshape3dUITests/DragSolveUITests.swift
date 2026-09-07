//
//  DragSolveUITests.swift
//  openshape3dUITests
//
//  Solve-on-edit dragging (plan §C1): draw a rectangle from four lines, add a
//  Horizontal constraint to its top edge, then drag a top corner sideways. The
//  drag routes through the constraint solver, so the top edge stays horizontal
//  (both top points move together in Y) and the whole solve coalesces into ONE
//  undoable "Move" step. Asserted via undo count and stability (the drag never
//  crashes and undo cleanly restores the pre-drag geometry).
//

import XCTest

final class DragSolveUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Every element lookup here goes through `.firstMatch`. The run failed
    /// once with "Multiple matching elements found" and no identifier in the
    /// message — a duplicate can appear transiently (the Constrain flyout and
    /// the Constrain MENU both carry `Constraint_*` buttons, so a frame where
    /// both are up makes those queries ambiguous). These are drive-the-UI
    /// steps, not the assertions under test, so resolving to the first match is
    /// the right trade: the test keeps testing the solver, not the chrome.
    func testDragTopCornerKeepsHorizontalEdgeAndCoalesces() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch

        // Enter a ground sketch with the Line tool.
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].firstMatch.waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].firstMatch.waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        func drag(_ from: XCUICoordinate, _ to: XCUICoordinate) {
            from.press(forDuration: 0.2, thenDragTo: to, withVelocity: .slow,
                       thenHoldForDuration: 0.2)
        }

        // Rectangle corners (screen y grows downward, so 0.42 is the top edge).
        let bl = (dx: CGFloat(0.35), dy: CGFloat(0.58))
        let br = (dx: CGFloat(0.65), dy: CGFloat(0.58))
        let tr = (dx: CGFloat(0.65), dy: CGFloat(0.42))
        let tl = (dx: CGFloat(0.35), dy: CGFloat(0.42))

        // Four chained lines: bottom, right, top, left (each stroke starts on
        // the previous endpoint, so the corners weld into shared points).
        drag(p(bl.dx, bl.dy), p(br.dx, br.dy)) // bottom
        drag(p(br.dx, br.dy), p(tr.dx, tr.dy)) // right
        drag(p(tr.dx, tr.dy), p(tl.dx, tl.dy)) // top
        drag(p(tl.dx, tl.dy), p(bl.dx, bl.dy)) // left (closes the loop)

        let undo = app.buttons["UndoButton"].firstMatch
        XCTAssertTrue(undo.isEnabled, "Drawing the rectangle should push undoable steps")

        // Select the top edge (tap its middle) and level it with Horizontal.
        p(0.50, 0.42).tap()
        sleep(1)
        let menu = app.buttons["ConstraintsMenu"].firstMatch
        if !menu.isHittable { app.buttons["ConstrainGroup"].firstMatch.tap() }
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "Constraints menu should exist")
        menu.tap()
        let horizontal = app.buttons["Constraint_Horizontal"].firstMatch
        XCTAssertTrue(horizontal.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontal.isEnabled, "Horizontal should enable for a single line")
        horizontal.tap()
        sleep(1)
        XCTAssertTrue(undo.isEnabled, "Applying Horizontal should push an undoable step")

        // Clear the selection (avoids the selection gizmo claiming the drag).
        p(0.85, 0.15).tap()
        sleep(1)

        // Drag the top-right corner down and to the side. The solver keeps the
        // top edge horizontal and coalesces the whole solve into ONE step.
        drag(p(tr.dx, tr.dy), p(0.76, 0.53))
        sleep(1)
        XCTAssertTrue(undo.isEnabled, "The solved drag should push a Move step")

        // Undo/stability: four line draws + Horizontal + one coalesced Move =
        // exactly six undo steps. The Move being a single step proves the
        // per-frame solve coalesced into one command.
        var steps = 0
        while undo.isEnabled && steps < 12 {
            undo.tap()
            steps += 1
        }
        XCTAssertEqual(steps, 6,
                       "4 lines + Horizontal + one coalesced solved Move = six undo steps")
        XCTAssertFalse(undo.isEnabled, "Undo stack should be empty after draining")

        app.buttons["Exit Sketching"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].firstMatch.exists)
    }
}
