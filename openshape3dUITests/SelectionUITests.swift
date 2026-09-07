//
//  SelectionUITests.swift
//  openshape3dUITests
//
//  Selection UX (plan §B13 UI, spec §8.2–8.3): Select-mode marquee over a
//  patterned set selects every body (info bar shows count), palette Delete
//  removes them all in one undoable step, and a long-press opens the
//  Select Through popup listing the bodies under the point.
//

import XCTest

final class SelectionUITests: XCTestCase {

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

    func testMarqueeSelectsPatternBodiesAndDeleteRemovesAll() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        // Fastest multi-body setup: pattern the seeded box (Linear, X, 3).
        tapPaletteTool(app, group: "Transform", id: "PatternButton")
        let apply = app.buttons["PatternApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 3),
                      "Pattern should open the pattern bar")
        apply.tap()

        // Frame all instances, then clear the pattern's selection with an
        // empty tap so the marquee does the selecting.
        app.buttons["Fit View"].tap()
        sleep(1) // camera flight settles
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85)).tap()

        // Select mode: the pill with the filter chips appears.
        app.buttons["SelectModeButton"].tap()
        XCTAssertTrue(app.staticTexts["Drag to select"].waitForExistence(timeout: 3),
                      "Select mode should show its status pill")

        // Crossing marquee (right→left) across the model.
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.25))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.8))
        start.press(forDuration: 0.05, thenDragTo: end)

        // Multi-selection info bar: count + combined bounds (plan §B13).
        XCTAssertTrue(app.staticTexts["3 bodies"].waitForExistence(timeout: 3),
                      "Marquee should select every pattern instance")

        // Delete removes all three bodies at once…
        app.buttons["DeleteButton"].tap()
        app.buttons["ItemsButton"].tap()
        XCTAssertFalse(app.textFields["ItemName-Box"].waitForExistence(timeout: 2),
                       "Delete should remove every selected body")
        XCTAssertFalse(app.textFields["ItemName-Box 2"].exists)

        // …and a single undo restores them (one DeleteBodiesCommand).
        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Box"].waitForExistence(timeout: 3),
                      "Undo should restore the deleted bodies")
        XCTAssertTrue(app.textFields["ItemName-Box 2"].exists)
        XCTAssertTrue(app.textFields["ItemName-Box 3"].exists)
    }

    func testLongPressShowsSelectThroughPopup() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        // Long-press candidates around the seeded box center (camera-fit
        // variance); the popup lists pickAllBodies hits by name (spec §8.3).
        let title = app.staticTexts["Select Through"]
        let candidates: [CGVector] = [
            CGVector(dx: 0.50, dy: 0.55),
            CGVector(dx: 0.46, dy: 0.50),
            CGVector(dx: 0.54, dy: 0.50),
            CGVector(dx: 0.50, dy: 0.45),
            CGVector(dx: 0.42, dy: 0.55),
        ]
        for offset in candidates where !title.exists {
            window.coordinate(withNormalizedOffset: offset).press(forDuration: 0.8)
            _ = title.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(title.exists,
                      "Long-press on the body should open the Select Through popup")

        // Choosing the listed body selects it and dismisses the popup.
        let bodyChoice = app.buttons["Box"]
        XCTAssertTrue(bodyChoice.waitForExistence(timeout: 2),
                      "The popup should list the body by name")
        bodyChoice.tap()
        XCTAssertFalse(title.waitForExistence(timeout: 2),
                       "Choosing a body should dismiss the popup")
        XCTAssertTrue(app.buttons["CopyBadge"].waitForExistence(timeout: 3),
                      "The chosen body should be selected (gizmo badge visible)")
    }
}
