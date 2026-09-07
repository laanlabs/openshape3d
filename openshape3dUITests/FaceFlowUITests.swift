//
//  FaceFlowUITests.swift
//  openshape3dUITests
//
//  Shapr3D face push/pull: tap a body to select the face under the tap,
//  drag the face to pull it out (auto-union), and complete the tool.
//

import XCTest

final class FaceFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testSelectFaceAndPull() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles

        let window = app.windows.firstMatch

        // Deselect the seeded box (tap empty space, away from the palette).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1) // stay clear of the double-tap window

        // Tap the box's top face → face selection.
        let facePoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        facePoint.tap()
        sleep(1)
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"].waitForExistence(timeout: 3),
            "Tapping a body should select the face under the tap"
        )

        // Pull the face upward via its arrow handle (only the arrow moves it).
        let pullEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.10))
        dragPullArrow(app, to: pullEnd)

        // Complete the tool.
        app.buttons["Extrude"].firstMatch.tap()

        // Seed add + face extrude = two undoable commands.
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Face extrude should undo first, leaving the seed")
        undo.tap()
        XCTAssertFalse(undo.isEnabled)
    }

    /// Regression: pushing the top face DOWN must truncate the box to one clean
    /// body — not leave hanging side walls. The result is a single body, so it
    /// takes exactly one Delete, and the whole session undoes in two steps
    /// (seed add + push/pull replace).
    func testPushFaceInwardLeavesOneCleanBody() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1)
        let window = app.windows.firstMatch

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)
        let facePoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        facePoint.tap()
        sleep(1)
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"].waitForExistence(timeout: 3)
        )

        // Push the top face DOWN (inward) via its arrow handle — the failure case.
        let pushEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.58))
        dragPullArrow(app, to: pushEnd)
        app.buttons["Extrude"].firstMatch.tap()

        // Exactly one body remains: the truncated box. It is selected on commit.
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled, "The truncated box should be the single selection")

        // Two commands: seed add + push/pull replace.
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Push/pull undoes first, leaving the seeded box")
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Exactly two undoable commands — no stray bodies")
    }

    /// Typing a NEGATIVE value into the on-arrow pill pushes the face inward
    /// (regression: the pill used to strip the sign with `abs`, so a typed
    /// negative extruded outward or did nothing).
    func testTypeNegativeIntoArrowPill() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1)
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        sleep(1)
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"].waitForExistence(timeout: 3)
        )

        let pill = app.buttons["ExtrudeArrowValue"]
        XCTAssertTrue(pill.waitForExistence(timeout: 3))
        pill.tap()
        let field = app.textFields["ExtrudeArrowField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        // The pill's field arrives holding the current value ("0"), so typing
        // into it without clearing produced "0-3" (which evaluates to -3 and
        // passed by luck) or "-30" (30 mm into a 4 mm box — refused, no
        // command). `replaceText` clears first and verifies what landed.
        replaceText(field, with: "-3")   // explicit negative → push inward

        // Wait for the COMMIT, not for a stopwatch. Submitting runs a CSG push
        // and ends the face selection, and a fixed sleep(1) is not enough on a
        // loaded machine — the undo assertions below then ran against a stack
        // that had only the seed in it, and read as "the negative did not
        // commit" when it simply had not finished. (Long-serial-run flake.)
        XCTAssertTrue(field.waitForNonExistence(timeout: 15),
                      "Submitting should close the pill's field")
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"]
                .waitForNonExistence(timeout: 15),
            "Committing the push should end the face selection")

        // Seed add + inward push = two undoable commands (the push committed).
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "Typing a negative should commit an inward push")
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "Exactly two commands — the negative push committed once")
    }
}
