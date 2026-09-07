//
//  ModifyGroupUITests.swift
//  openshape3dUITests
//
//  Body-mode "Modify" flyout: pick a 3D-create operation first (Shapr3D-style),
//  then tap a sketch region to apply it. Verifies the tap-tool-then-region flow
//  that arms Extrude/Revolve from the palette (not just the fill-tap gesture).
//

import XCTest

final class ModifyGroupUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Draw a rectangle on the ground and return to body mode with the fill.
    private func drawGroundRect(_ app: XCUIApplication, _ window: XCUIElement) {
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.40))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.58)))
        app.buttons["Exit Sketching"].tap()
        sleep(1)
    }

    func testModifyExtrudeFromPalette() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        drawGroundRect(app, window)

        // Modify ▸ Extrude arms the operation and prompts for a region.
        tapPaletteTool(app, group: "Modify", id: "ExtrudeButton")
        XCTAssertTrue(
            app.staticTexts["Tap a sketch region to Extrude"].waitForExistence(timeout: 3),
            "Picking Extrude from Modify should prompt for a region"
        )

        // Tapping the fill builds the extrude and shows the bar.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.49)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping the region should open the extrude bar")
        typeExtrudeHeight(app)
        sleep(1)
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "The extrude should have committed")
    }

    func testModifyRevolveFromPalette() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        drawGroundRect(app, window)

        // Modify ▸ Revolve routes straight into the axis pick after the region.
        tapPaletteTool(app, group: "Modify", id: "RevolveButton")
        XCTAssertTrue(app.staticTexts["Tap a sketch region to Revolve"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.49)).tap()
        XCTAssertTrue(
            app.staticTexts["Tap a sketch line to set the revolve axis"].waitForExistence(timeout: 5),
            "Revolve should arm the axis pick once the region is chosen"
        )
    }
}
