import XCTest

final class ConstraintRailUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }
    func testVisibleConstraintsReflectSelectionAndSettingsAreOneTapAway() {
        verifyRail()
    }
    func testVisibleConstraintsInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        verifyRail()
    }
    private func verifyRail() {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        let window = app.windows.firstMatch
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2); lookAtSketch(app)
        let parallel = app.buttons["ConstraintRail-parallel"]
        XCTAssertTrue(parallel.exists)
        XCTAssertFalse(parallel.isEnabled)
        XCTAssertTrue(app.staticTexts["Select two or more lines"].exists)
        app.buttons["ConstraintRailSettings"].tap()
        XCTAssertTrue(app.switches["AlwaysShowDimensionsToggle"].firstMatch.waitForExistence(timeout: 3))
        let grid = app.switches["SnapToGridToggle"].firstMatch
        let gridWasOn = grid.value as? String == "1"
        if gridWasOn {
            grid.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            expectation(for: NSPredicate(format: "value == '0'"), evaluatedWith: grid)
            waitForExpectations(timeout: 3)
        }
        app.buttons["ConstraintSettingsDone"].tap()
        p(0.32, 0.42).press(forDuration: 0.15, thenDragTo: p(0.58, 0.42))
        p(0.32, 0.60).press(forDuration: 0.15, thenDragTo: p(0.58, 0.64))
        if gridWasOn {
            app.buttons["ConstraintRailSettings"].tap()
            grid.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            app.buttons["ConstraintSettingsDone"].tap()
        }
        app.buttons["Line"].firstMatch.tap() // disarm to select/edit geometry
        // The last drawn segment is already selected; select only the first
        // to form the pair, rather than toggling the second off again.
        p(0.45, 0.42).tap()
        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: parallel)
        waitForExpectations(timeout: 3)
        parallel.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:
            "identifier == 'ConstraintGlyph' AND label == '∥'")).firstMatch.waitForExistence(timeout: 3))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "parallel-from-visible-rail"; shot.lifetime = .keepAlways; add(shot)
    }
}
