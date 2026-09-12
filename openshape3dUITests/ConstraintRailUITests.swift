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
    func testCircleSymmetryChoosesAxisAfterOperandsAndCancels() {
        verifySymmetryAxisPick(circles: true)
    }
    func testLineSymmetryChoosesAxisAfterOperandsAndCancels() {
        verifySymmetryAxisPick(circles: false)
    }
    private func verifySymmetryAxisPick(circles: Bool) {
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
        p(0.49, 0.35).press(forDuration: 0.15, thenDragTo: p(0.49, 0.73))
        if circles {
            app.buttons["Circle"].firstMatch.tap()
            p(0.34, 0.52).press(forDuration: 0.15, thenDragTo: p(0.40, 0.52))
            p(0.64, 0.57).press(forDuration: 0.15, thenDragTo: p(0.70, 0.57))
            app.buttons["Circle"].firstMatch.tap()
            p(0.34, 0.475).tap()
        } else {
            p(0.30, 0.52).press(forDuration: 0.15, thenDragTo: p(0.40, 0.56))
            p(0.62, 0.57).press(forDuration: 0.15, thenDragTo: p(0.74, 0.53))
            app.buttons["Line"].firstMatch.tap()
            p(0.35, 0.54).tap()
        }
        // The last created entity remains selected; add only the first.
        sleep(1) // Let the single-tap recognizer resolve before opening a menu.
        let selectionShot = XCTAttachment(screenshot: app.screenshot())
        selectionShot.name = circles ? "circle-symmetry-operands" : "line-symmetry-operands"; selectionShot.lifetime = .keepAlways; add(selectionShot)
        func invokeSymmetry() {
            app.buttons["ConstraintRailMore"].tap()
            let symmetry = app.buttons["Symmetric"].firstMatch
            XCTAssertTrue(symmetry.waitForExistence(timeout: 3))
            XCTAssertTrue(symmetry.isEnabled)
            symmetry.tap()
            XCTAssertTrue(app.buttons["CancelSymmetry"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["Select a line for the axis of symmetry"].exists)
        }
        invokeSymmetry()
        app.buttons["CancelSymmetry"].tap()
        XCTAssertFalse(app.buttons["CancelSymmetry"].exists)
        invokeSymmetry()
        p(0.49, 0.40).tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons["CancelSymmetry"])
        waitForExpectations(timeout: 3)
        // The axis participates in the saved relationship; selecting it exposes its glyph.
        p(0.49, 0.40).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:
            "identifier == 'ConstraintGlyph' AND label == '⧓'")).firstMatch.waitForExistence(timeout: 3))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = circles ? "circle-symmetry-axis-applied" : "line-symmetry-axis-applied"; shot.lifetime = .keepAlways; add(shot)
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
        let settingsForm = app.collectionViews.firstMatch
        XCTAssertTrue(settingsForm.exists)
        let grid = app.switches["SnapToGridToggle"].firstMatch
        for _ in 0..<2 where !grid.isHittable {
            settingsForm.swipeUp()
        }
        let gridWasOn = grid.value as? String == "1"
        if gridWasOn {
            grid.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            expectation(for: NSPredicate(format: "value == '0'"), evaluatedWith: grid)
            waitForExpectations(timeout: 3)
        }
        let anchorPicker = app.segmentedControls["AnchoredSketchEntityPicker"].firstMatch
        for _ in 0..<4 where !anchorPicker.exists || !anchorPicker.isHittable {
            settingsForm.swipeUp()
        }
        XCTAssertTrue(anchorPicker.waitForExistence(timeout: 3))
        XCTAssertTrue(anchorPicker.buttons["First Selected"].exists)
        XCTAssertTrue(anchorPicker.buttons["Last Selected"].exists)
        anchorPicker.buttons["Last Selected"].tap()
        XCTAssertTrue(anchorPicker.buttons["Last Selected"].isSelected)
        anchorPicker.buttons["First Selected"].tap()
        XCTAssertTrue(anchorPicker.buttons["First Selected"].isSelected)
        app.buttons["ConstraintSettingsDone"].tap()
        p(0.32, 0.42).press(forDuration: 0.15, thenDragTo: p(0.58, 0.42))
        p(0.32, 0.60).press(forDuration: 0.15, thenDragTo: p(0.58, 0.64))
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
