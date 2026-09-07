//
//  TextProjectUITests.swift
//  openshape3dUITests
//
//  Text (plan §B7) and Project (plan §B8) UI flows: the Text dialog turns
//  'OK' into glyph-outline profiles whose fills extrude into a body, and the
//  Project tool flattens a seeded box's feature edges into a ground sketch
//  as one undoable command.
//

import XCTest

final class TextProjectUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testTextGlyphProfilesExtrudeIntoBody() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Text")

        // Plane pickers appear; tapping the bare ground starts there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Tap to place text"].waitForExistence(timeout: 3),
                      "The Text tool should prompt for a placement tap")
        sleep(2) // head-on camera animation
        lookAtSketch(app)

        // Tap-to-place left of center so the 'O' (about 11mm wide at height
        // 10) stays on screen, then fill in the dialog. Height defaults to
        // 10mm; content 'OK'.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.70)).tap()
        let contentField = app.textFields["TextContentField"]
        XCTAssertTrue(contentField.waitForExistence(timeout: 3),
                      "Tapping with the Text tool should present the dialog")
        contentField.tap()
        contentField.typeText("OK")
        app.buttons["TextAdd"].tap()

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        XCTAssertTrue(undo.isEnabled,
                      "Adding text should commit one undoable command")

        app.buttons["Exit Sketching"].tap()

        // Tap the left stroke of the 'O' ring — its fill proves the glyph
        // loops closed into profiles; Extrude opens. The exact screen spot
        // depends on font metrics, so probe a few candidates.
        let extrudeTitle = app.staticTexts["Extrude"]
        let candidates: [CGVector] = [
            CGVector(dx: 0.46, dy: 0.20),
            CGVector(dx: 0.42, dy: 0.20),
            CGVector(dx: 0.50, dy: 0.20),
            CGVector(dx: 0.46, dy: 0.27),
            CGVector(dx: 0.46, dy: 0.13),
        ]
        for candidate in candidates where !extrudeTitle.exists {
            window.coordinate(withNormalizedOffset: candidate).tap()
            _ = extrudeTitle.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(extrudeTitle.exists,
                      "Tapping a glyph fill should start the Extrude tool")

        // Type a height (arming starts at zero): a body appears, selected.
        typeExtrudeHeight(app)
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        let predicate = NSPredicate(format: "isEnabled == true")
        expectation(for: predicate, evaluatedWith: deleteButton)
        waitForExpectations(timeout: 5)
    }

    func testProjectBoxEdgesIntoGroundSketch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles
        startSketchTool(app, "Project")

        // Plane pickers appear; tap bare ground away from the seeded box.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(
            app.staticTexts["Tap a body to project its edges"].waitForExistence(timeout: 3),
            "The Project tool should prompt for a body tap"
        )
        sleep(2) // head-on (top-down) camera animation
        lookAtSketch(app)

        // Tap the box at screen center: its feature edges flatten onto the
        // ground sketch as one undoable command.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.45)).tap()

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled,
                      "Projecting should commit an undoable command")

        // Undo count: exactly two commands exist — the projection and the
        // seeded box add.
        undo.tap()
        XCTAssertTrue(undo.isEnabled,
                      "After undoing the projection the seed command remains")
        undo.tap()
        XCTAssertFalse(undo.isEnabled,
                       "Projection must be a single composite undo step")
    }
}
