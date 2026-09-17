//
//  WelcomeUITests.swift
//  openshape3dUITests
//
//  The welcome sheet: forced with OS3D_WELCOME on a reset store, "Add Sample
//  Designs" fills a Demos folder whose designs open in the editor, and
//  Gallery › Welcome… brings the sheet back.
//

import XCTest

final class WelcomeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Secondary toolbar actions fold into the "More" (…) menu on every
    /// width, where the items surface by label rather than identifier.
    private func tapMenuItem(_ app: XCUIApplication, _ id: String, label: String) {
        let match = NSPredicate(format: "identifier == %@ OR label == %@", id, label)
        let item = app.descendants(matching: .any).matching(match).firstMatch
        if !item.waitForExistence(timeout: 1) {
            app.navigationBars.buttons["More"].firstMatch.tap()
            XCTAssertTrue(item.waitForExistence(timeout: 3), "\(label) should be in the … menu")
        }
        item.tap()
    }

    func testWelcomeInstallsSamplesIntoDemosFolder() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_WELCOME"] = "1"
        app.launch()

        XCTAssertTrue(app.otherElements["WelcomeView"].waitForExistence(timeout: 10),
                      "OS3D_WELCOME should open the welcome sheet on a fresh store")
        XCTAssertTrue(app.staticTexts["Welcome to OpenShape 3D"].exists)
        XCTAssertTrue(app.buttons["WelcomeNewDesignButton"].exists)

        let add = app.buttons["WelcomeAddSamplesButton"]
        XCTAssertTrue(add.exists, "the bundle ships samples, so the button shows")
        add.tap()

        // The sheet closes onto the Demos folder with every sample listed.
        XCTAssertTrue(app.navigationBars["Demos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Crumb-Designs"].exists)
        for name in ["Motorcycle Wheel", "Mounting Plate", "Glass Bottle", "Plate Cam"] {
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 3), name)
        }

        // A sample opens in the editor.
        app.staticTexts["Mounting Plate"].firstMatch.tap()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10),
                      "opening a sample should land in the editor")
        XCTAssertTrue(app.navigationBars["Mounting Plate"].exists
                      || app.staticTexts["Mounting Plate"].exists)

        // Back to the gallery (the back button carries the folder's name):
        // adding again is idempotent, and Welcome… reopens the sheet.
        app.buttons["Demos"].firstMatch.tap()
        XCTAssertTrue(app.buttons["NewFolderButton"].waitForExistence(timeout: 5))
        tapMenuItem(app, "AddSampleDesignsButton", label: "Add Sample Designs")
        XCTAssertTrue(app.navigationBars["Demos"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Mounting Plate").count, 1,
                       "Add Sample Designs must not duplicate an installed sample")

        tapMenuItem(app, "GalleryWelcomeButton", label: "Welcome…")
        XCTAssertTrue(app.otherElements["WelcomeView"].waitForExistence(timeout: 5))
        app.buttons["WelcomeCloseButton"].tap()
        XCTAssertFalse(app.otherElements["WelcomeView"].waitForExistence(timeout: 2))
    }

    func testWelcomeIsSuppressedUnderTheAutomationHooks() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["No Designs"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.otherElements["WelcomeView"].exists,
                       "OS3D_RESET_STORE launches (every UI test) must not start under the sheet")
    }
}
