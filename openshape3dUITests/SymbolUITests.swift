//
//  SymbolUITests.swift
//  openshape3dUITests
//
//  Symbols (plan §B16, spec §1.16): select two sketch lines, Make Symbol
//  "Bracket" via the name prompt, Insert Symbol arms tap-to-place, two taps
//  stamp two one-command instances, then rename the symbol in Items. The
//  undo audit proves each placement was exactly one command.
//

import XCTest

final class SymbolUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testMakeSymbolInsertTwiceAndRenameInItems() throws {
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

        // Two parallel lines: the symbol geometry.
        point(0.35, 0.40).press(forDuration: 0.15, thenDragTo: point(0.60, 0.40))
        point(0.35, 0.48).press(forDuration: 0.15, thenDragTo: point(0.60, 0.48))

        // Select both (tap toggles each into the selection).
        point(0.47, 0.40).tap()
        sleep(1)
        point(0.47, 0.48).tap()
        sleep(1)

        // Make Symbol "Bracket" through the name prompt (Symbol flyout).
        app.buttons["SymbolGroup"].tap()
        let makeButton = app.buttons["MakeSymbolButton"]
        XCTAssertTrue(makeButton.waitForExistence(timeout: 3))
        XCTAssertTrue(makeButton.isEnabled,
                      "Selecting sketch entities should enable Make Symbol")
        makeButton.tap()
        let alert = app.alerts["Make Symbol"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3),
                      "Make Symbol should prompt for a name")
        let nameField = alert.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Bracket")
        alert.buttons["Create"].tap()

        // Insert Symbol lists "Bracket"; choosing it arms tap-to-place.
        app.buttons["SymbolGroup"].tap()
        let insertMenu = app.buttons["InsertSymbolMenu"]
        XCTAssertTrue(insertMenu.waitForExistence(timeout: 3))
        XCTAssertTrue(insertMenu.isEnabled,
                      "Creating a symbol should enable Insert Symbol")
        insertMenu.tap()
        let choice = app.buttons["Bracket"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 3),
                      "The Insert menu should list the new symbol")
        choice.tap()
        let done = app.buttons["InsertSymbolDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 3),
                      "Choosing a symbol should arm tap-to-place")

        // Two taps stamp two instances (one command each).
        point(0.30, 0.66).tap()
        sleep(1)
        point(0.62, 0.66).tap()
        sleep(1)
        done.tap()
        XCTAssertFalse(app.buttons["InsertSymbolDone"].exists,
                       "Done should exit symbol placement")

        app.buttons["Exit Sketching"].tap()

        // Items panel: Symbols section lists "Bracket"; rename it.
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.staticTexts["Symbols"].waitForExistence(timeout: 3),
                      "Items should show a Symbols section")
        let symbolField = app.textFields["ItemName-Bracket"]
        XCTAssertTrue(symbolField.waitForExistence(timeout: 3),
                      "The symbol should be listed in Items")
        replaceText(symbolField, with: "Clip")
        XCTAssertTrue(app.textFields["ItemName-Clip"].waitForExistence(timeout: 3),
                      "Submitting the field should rename the symbol")

        // Undo audit: rename, placement B, placement A, Make Symbol,
        // line B, line A — exactly six steps, so each of the two taps
        // was one command.
        let undo = app.buttons["UndoButton"]
        for step in 1...6 {
            XCTAssertTrue(undo.isEnabled, "Undo step \(step) should be available")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "Two lines + Make Symbol + two placements + rename should be six undo steps")
    }
}
