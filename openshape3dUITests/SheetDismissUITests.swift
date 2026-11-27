//
//  SheetDismissUITests.swift
//  openshape3dUITests
//
//  A sheet closes from its own Done or Cancel button (#117). On the Mac the
//  button took the click and ran its action, and the sheet stayed up; only
//  Esc closed it. Runs on every platform, the Mac included:
//
//    xcodebuild test -scheme openshape3d \
//      -destination 'platform=macOS,variant=Mac Catalyst' \
//      -only-testing:openshape3dUITests/SheetDismissUITests
//

import XCTest

final class SheetDismissUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launch()
        return app
    }

    func testSettingsClosesFromDone() throws {
        let app = launch()
        let gear = app.buttons["SettingsButton"]
        XCTAssertTrue(gear.waitForExistence(timeout: 20))
        gear.tap()
        let done = app.buttons["SettingsDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Settings should open")
        done.tap()
        XCTAssertTrue(done.waitForNonExistence(timeout: 5), "Done should close Settings")
    }
}
