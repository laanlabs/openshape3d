//
//  SplitPatternUITests.swift
//  openshape3dUITests
//
//  Phase B split/pattern flows (plan §B3/§B5): a linear body pattern adds
//  count−1 instances in one undo step, and Split by a world plane tile
//  replaces the body with two halves.
//

import XCTest

final class SplitPatternUITests: XCTestCase {

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

    func testLinearPatternCreatesThreeBodies() throws {
        let app = launchSeeded()

        // Seeded box is selected: Pattern opens the bar (Linear, X, count 3).
        tapPaletteTool(app, group: "Transform", id: "PatternButton")
        let apply = app.buttons["PatternApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 3),
                      "Pattern action should open the pattern bar")
        apply.tap()

        // Three bodies: the original plus two pattern copies.
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Box"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["ItemName-Box 2"].waitForExistence(timeout: 3),
                      "Second pattern instance should exist")
        XCTAssertTrue(app.textFields["ItemName-Box 3"].exists,
                      "Third pattern instance should exist")

        // One CompositeCommand: a single undo removes both copies …
        let undo = app.buttons["UndoButton"]
        undo.tap()
        XCTAssertFalse(app.textFields["ItemName-Box 2"].waitForExistence(timeout: 2),
                       "Undoing the pattern should remove every copy at once")
        XCTAssertFalse(app.textFields["ItemName-Box 3"].exists)
        XCTAssertTrue(app.textFields["ItemName-Box"].exists,
                      "The original body should survive the undo")

        // … leaving only the seeded Add undoable.
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Only the seed Add should remain after the pattern undo")
    }

    func testSplitByWorldPlaneMakesTwoBodies() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        tapPaletteTool(app, group: "Transform", id: "SplitButton")
        let pill = app.staticTexts["Tap a plane or profile to split"]
        XCTAssertTrue(pill.waitForExistence(timeout: 3),
                      "Split should arm the cutter pick")

        // The YZ world tile passes through the box; candidate taps around
        // the box center cover camera-fit variance (a successful split
        // dismisses the pill; misses keep the pick armed).
        let candidates: [CGVector] = [
            CGVector(dx: 0.42, dy: 0.55),
            CGVector(dx: 0.46, dy: 0.50),
            CGVector(dx: 0.50, dy: 0.55),
            CGVector(dx: 0.38, dy: 0.60),
            CGVector(dx: 0.46, dy: 0.62),
            CGVector(dx: 0.54, dy: 0.50),
            CGVector(dx: 0.50, dy: 0.45),
        ]
        for offset in candidates where pill.exists {
            window.coordinate(withNormalizedOffset: offset).tap()
            // A tangent cutter alerts (empty half); dismiss and keep trying.
            let ok = app.alerts.buttons["OK"].firstMatch
            if ok.waitForExistence(timeout: 1) { ok.tap() }
        }
        XCTAssertFalse(pill.exists, "A cutter tap should split and end the pick")

        // Two bodies, named "<name> A" / "<name> B" after the source body.
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Box A"].waitForExistence(timeout: 3),
                      "First half should be renamed <name> A")
        XCTAssertTrue(app.textFields["ItemName-Box B"].waitForExistence(timeout: 3),
                      "Split should leave two bodies")

        // One undo restores the single box (composite Replace + Add).
        app.buttons["UndoButton"].tap()
        XCTAssertFalse(app.textFields["ItemName-Box B"].waitForExistence(timeout: 2),
                       "Undo should remove the second half")
        XCTAssertTrue(app.textFields["ItemName-Box"].waitForExistence(timeout: 2),
                      "Undo should restore the original body and its name")
    }
}
