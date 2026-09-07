//
//  ItemsUITests.swift
//  openshape3dUITests
//
//  Items Manager v1 (spec §11): sketch auto-hide after extrude, eye toggle,
//  rename, and context-menu delete with undo restore.
//

import XCTest

final class ItemsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func drawRectangle(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.42))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.60))
        start.press(forDuration: 0.15, thenDragTo: end)

        app.buttons["Exit Sketching"].tap()
    }

    func testItemsPanelVisibilityRenameAndDelete() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        // Create a body: rect sketch + extrude.
        drawRectangle(in: app)
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.51)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app)
        XCTAssertFalse(app.staticTexts["Extrude"].exists)

        // Open the Items panel.
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.staticTexts["Bodies"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sketches"].exists)
        XCTAssertTrue(app.staticTexts["Planes"].exists)

        // Shapr3D parity (spec §11): extrude auto-hides the sketch it
        // consumed, but the row stays listed and the eye toggles it back.
        let sketchEye = app.buttons["ItemEye-Sketch 1"]
        XCTAssertTrue(sketchEye.waitForExistence(timeout: 3),
                      "The consumed sketch should still be listed")
        XCTAssertEqual(sketchEye.value as? String, "hidden",
                       "Extrude should auto-hide the sketch it consumed")
        sketchEye.tap() // show again
        XCTAssertEqual(sketchEye.value as? String, "visible",
                       "The eye should un-hide the consumed sketch")
        sketchEye.tap() // back to hidden
        XCTAssertEqual(sketchEye.value as? String, "hidden")

        // Rename the extruded body.
        let nameField = app.textFields["ItemName-Extrude"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3),
                      "The extruded body should be listed")
        replaceText(nameField, with: "MyPart")
        let renamedField = app.textFields["ItemName-MyPart"]
        XCTAssertTrue(renamedField.waitForExistence(timeout: 3),
                      "Submitting the field should rename the body")

        // Delete the body from the row's context menu. Long-press on the
        // row's type icon (pressing the text field would edit text instead).
        let row = app.otherElements["ItemRow-MyPart"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5))
            .press(forDuration: 1.0)
        let deleteItem = app.collectionViews.buttons["Delete"]
        XCTAssertTrue(deleteItem.waitForExistence(timeout: 3),
                      "Long-pressing the row should show the context menu")
        deleteItem.tap()
        XCTAssertFalse(app.textFields["ItemName-MyPart"].waitForExistence(timeout: 2),
                       "Deleting should remove the body row")

        // Undo restores the body (name included).
        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-MyPart"].waitForExistence(timeout: 3),
                      "Undo should restore the deleted body")
    }
}
