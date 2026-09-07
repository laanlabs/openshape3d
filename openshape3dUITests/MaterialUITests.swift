//
//  MaterialUITests.swift
//  openshape3dUITests
//
//  Plan §B15: the Material sheet on the seeded selected box — pick the Steel
//  preset, Apply (undoable SetMaterialCommand), then Undo restores the
//  default material (verified through the sheet's metallic readout). Plus a
//  Ground Shadow toggle smoke test in the Views menu.
//

import XCTest

final class MaterialUITests: XCTestCase {

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
        return app
    }

    /// Opens the Material sheet (seeded box is selected) and returns the
    /// metallic readout element.
    private func openMaterialSheet(_ app: XCUIApplication) -> XCUIElement {
        let materialButton = app.buttons["MaterialButton"]
        XCTAssertTrue(materialButton.waitForExistence(timeout: 10))
        materialButton.tap()
        let metallicValue = app.staticTexts["MaterialMetallicValue"]
        XCTAssertTrue(metallicValue.waitForExistence(timeout: 3),
                      "The Material sheet should present with its sliders")
        return metallicValue
    }

    func testSteelPresetAppliesAndUndoRestoresDefault() throws {
        let app = launchSeeded()

        // The seeded box carries the default material: metallic 0%.
        var metallicValue = openMaterialSheet(app)
        XCTAssertEqual(metallicValue.label, "0%",
                       "Seeded box should open on the default material")

        // Pick Steel: the sliders jump to the preset (metallic 100%).
        let steel = app.buttons["MaterialPresetSteel"]
        XCTAssertTrue(steel.waitForExistence(timeout: 3))
        steel.tap()
        XCTAssertEqual(metallicValue.label, "100%",
                       "Picking Steel should load its metallic factor")

        // Apply commits one undoable SetMaterialCommand.
        app.buttons["MaterialApply"].tap()
        XCTAssertFalse(metallicValue.waitForExistence(timeout: 2),
                       "Apply should dismiss the sheet")

        // Reopen: the stored material is Steel now.
        metallicValue = openMaterialSheet(app)
        XCTAssertEqual(metallicValue.label, "100%",
                       "The applied Steel material should persist on the body")
        app.buttons["MaterialCancel"].tap()
        XCTAssertFalse(metallicValue.waitForExistence(timeout: 2))

        // Undo restores the default material (selection is untouched).
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        metallicValue = openMaterialSheet(app)
        XCTAssertEqual(metallicValue.label, "0%",
                       "Undo should restore the default material")
        app.buttons["MaterialCancel"].tap()
    }

    func testGroundShadowToggleSmoke() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        let viewsButton = app.buttons["ViewsMenu"]
        XCTAssertTrue(viewsButton.waitForExistence(timeout: 10))
        sleep(1) // camera fit settles

        // Views → Ground Shadow on (menu Toggles can surface as buttons or
        // switches — match either, like SectionDisplayUITests).
        viewsButton.tap()
        let groundShadow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == 'Ground Shadow'")).firstMatch
        XCTAssertTrue(groundShadow.waitForExistence(timeout: 3),
                      "The Views menu should offer the Ground Shadow toggle")
        groundShadow.tap()

        // The app stays interactive with shadows on: the menu reopens and
        // the toggle is still there to switch back off.
        viewsButton.tap()
        XCTAssertTrue(groundShadow.waitForExistence(timeout: 3))
        groundShadow.tap()

        // Close-out sanity: the viewport still responds (deselect tap).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        XCTAssertTrue(viewsButton.isHittable)
    }
}
