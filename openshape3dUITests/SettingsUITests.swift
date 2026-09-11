//
//  SettingsUITests.swift
//  openshape3dUITests
//
//  Phase F tranche 1: the Settings sheet exists and switching the display
//  unit re-renders the selection info bar live (mm³ → in³ and back).
//

import XCTest

final class SettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testSettingsCenterTargetOpensInBothOrientations() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launch()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            sleep(2)
            let settings = app.buttons["SettingsButton"]
            XCTAssertTrue(settings.waitForExistence(timeout: 10))
            XCTAssertGreaterThanOrEqual(settings.frame.width, 44)
            // UIKit clips toolbar height to 36pt; verify delivered center taps,
            // not an assumed external height for the SwiftUI content frame.
            settings.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["SettingsDone"].waitForExistence(timeout: 3))
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "settings-center-\(orientation.rawValue)"
            shot.lifetime = .keepAlways; add(shot)
            app.buttons["SettingsDone"].tap()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    func testSnappingControlsPersistAcrossLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SettingsButton"].waitForExistence(timeout: 10))
        app.buttons["SettingsButton"].tap()
        let identifiers = ["SnapToGridToggle", "SnapToSketchGuidelinesToggle",
                           "SnapToSketchGuidepointsToggle",
                           "SnapToFaceGuidepointsToggle", "ShowSnapHintsToggle"]
        func reveal(_ identifier: String) -> XCUIElement {
            for _ in 0..<10 {
                let toggle = app.switches[identifier].firstMatch
                if toggle.exists && toggle.isHittable { return toggle }
                app.swipeUp(velocity: .slow)
                sleep(1)
            }
            return app.switches[identifier].firstMatch
        }
        func expectValue(_ value: String, on toggle: XCUIElement) {
            let changed = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", value), object: toggle)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed)
        }
        func activate(_ toggle: XCUIElement, identifier: String) {
            if identifier == "ShowSnapHintsToggle" {
                toggle.tap()
            } else {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.5)).tap()
            }
        }
        for identifier in identifiers {
            let toggle = reveal(identifier)
            XCTAssertTrue(toggle.exists)
            if toggle.value as? String == "1" {
                activate(toggle, identifier: identifier)
            }
            expectValue("0", on: toggle)
        }
        app.buttons["SettingsDone"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["SettingsButton"].waitForExistence(timeout: 10))
        app.buttons["SettingsButton"].tap()
        for identifier in identifiers {
            let toggle = reveal(identifier)
            XCTAssertEqual(toggle.value as? String, "0", "Explicit off must survive relaunch")
            activate(toggle, identifier: identifier) // restore default
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "restoring-\(identifier)"; shot.lifetime = .keepAlways; add(shot)
            expectValue("1", on: toggle)
        }
        app.buttons["SettingsDone"].tap()
    }

    /// Extrude a rectangle into a box and select it, so the info bar shows
    /// Volume/Bounds rows with unit readouts.
    private func makeAndSelectBox(_ app: XCUIApplication, _ window: XCUIElement) {
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        p(0.80, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        p(0.32, 0.32).press(forDuration: 0.15, thenDragTo: p(0.68, 0.62))
        app.buttons["Exit Sketching"].tap(); sleep(1)
        p(0.45, 0.45).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app); sleep(1)
        p(0.5, 0.5).doubleTap(); sleep(1)
    }

    func testUnitSwitchRelabelsInfoBarLive() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        makeAndSelectBox(app, window)

        func hasUnitText(_ suffix: String) -> Bool {
            app.staticTexts.matching(
                NSPredicate(format: "label ENDSWITH %@", suffix)
            ).firstMatch.waitForExistence(timeout: 3)
        }

        // Settings persist across runs on the same simulator — normalize to
        // mm through the UI first, then flip to inches, then restore.
        func setUnit(_ symbol: String) {
            app.buttons["SettingsButton"].tap()
            XCTAssertTrue(app.buttons["SettingsDone"].waitForExistence(timeout: 3))
            app.buttons[symbol].firstMatch.tap()
            app.buttons["SettingsDone"].tap()
            sleep(1)
        }

        setUnit("mm")
        XCTAssertTrue(hasUnitText("mm³"), "volume row shows mm³ in millimetres")

        setUnit("in")
        XCTAssertTrue(hasUnitText("in³"), "volume row re-renders to in³ live")
        XCTAssertFalse(
            app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'mm³'"))
                .firstMatch.exists,
            "no stale mm³ readout remains")

        setUnit("mm")
        XCTAssertTrue(hasUnitText("mm³"), "switching back restores mm³")
    }
}
