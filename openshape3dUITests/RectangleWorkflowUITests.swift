import XCTest

final class RectangleWorkflowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }
    private func start() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        p(app, 0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // automatic camera flight after choosing the plane
        XCTAssertFalse(app.buttons["Look at Sketch"].exists,
                       "Sketch entry should align the camera without a second action")
        return app
    }
    private func p(_ app: XCUIApplication, _ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }
    private func type(_ app: XCUIApplication, _ name: String) {
        app.buttons["RectangleTypeMenu"].tap()
        app.buttons["RectangleType-" + name].tap()
        sleep(1) // menu dismissal completes before the first canvas point
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    func testGalleryReopenedDesignCanUndoNewRectangle() {
        let app = start()
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.55, 0.48))
        app.buttons["Exit Sketching"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Designs"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "OS3D_FRESH")
        app.launchEnvironment.removeValue(forKey: "OS3D_RESET_STORE")
        app.launch()
        let card = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Untitled'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        p(app, 0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        p(app, 0.35, 0.65).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.82))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2)
        sleep(3) // allow the same autosave window as manual live interaction
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(labels.firstMatch.waitForNonExistence(timeout: 3),
                      "Undo in a gallery-reopened project must remove the newly drawn rectangle")
        attach(app, "gallery-undo-before-profile-check")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.5, 0.74).tap()
        XCTAssertFalse(app.buttons["Extrude"].exists,
                       "Undo must remove the profile, not only clear selection")
        app.buttons["RedoButton"].tap()
        p(app, 0.5, 0.74).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Redo must restore the usable profile; selection badges need not return")
        attach(app, "gallery-redo-restored-profile")
    }

    func testDiagonalWidthEditKeepsProfileNearFirstCorner() throws {
        let app = start()
        type(app, "diagonal")
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.60))
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(field.exists, "Rectangle release must not open the keypad")
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 2)
        attach(app, "diagonal-before-badge-tap")
        // Use the visible badge center, matching the paired Peekaboo input;
        // XCTest's inferred hit point can select an overlapping canvas point.
        app.buttons["DimensionLabel"].firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attach(app, "diagonal-after-badge-tap")
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let original = try XCTUnwrap(Double((field.value as? String) ?? ""))
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            app.buttons["KeypadDelete"].tap()
        }
        let half = String(format: "%.4f", original / 2)
        for c in half { app.buttons["Keypad-\(c)"].tap() }
        app.buttons["KeypadCommit"].tap()
        attach(app, "diagonal-half-width-first-corner")
        app.buttons["Exit Sketching"].tap()
        // Inside the resized rectangle near the first corner. A center-based
        // shrink instead starts at x=.425, leaving this point outside.
        p(app, 0.39, 0.47).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Width editing must preserve the first corner, not the center")
    }


    func testRightSideHeightKeypadIsReachableAndReplacesSeed() throws {
        let app = start()
        type(app, "center")
        p(app, 0.68, 0.76).press(forDuration: 0.15, thenDragTo: p(app, 0.78, 0.82))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        let height = try XCTUnwrap(labels.allElementsBoundByIndex.max { $0.frame.midX < $1.frame.midX })
        attach(app, "height-before-badge-tap")
        height.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attach(app, "height-after-badge-tap")
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let commit = app.buttons["KeypadCommit"]
        XCTAssertTrue(commit.isHittable)
        let rail = app.buttons["ConstraintRail-Horizontal"]
        if rail.exists { XCTAssertFalse(commit.frame.intersects(rail.frame)) }
        // A first digit replaces the measurement, then subsequent digits append.
        app.buttons["Keypad-1"].tap()
        XCTAssertEqual(field.value as? String, "1")
        app.buttons["Keypad-."] .tap()
        app.buttons["Keypad-5"].tap()
        XCTAssertEqual(field.value as? String, "1.5")
        attach(app, "right-height-keypad-clear-of-rail")
        commit.tap()
        XCTAssertFalse(field.exists)
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1.5 mm'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testCenterRectangleExtendsAcrossItsStartingPoint() {
        let app = start()
        type(app, "center")
        p(app, 0.52, 0.48).press(forDuration: 0.15, thenDragTo: p(app, 0.66, 0.60))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        attach(app, "center-rectangle")
        app.buttons["Exit Sketching"].tap()
        // This is inside the reflected quadrant, not a diagonal rectangle
        // starting at (.52, .48).
        p(app, 0.45, 0.42).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testThreePointRectangleDragCreatesRotatedExtrudableProfile() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).press(forDuration: 0.15, thenDragTo: p(app, 0.64, 0.46))
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        p(app, 0.64, 0.46).press(forDuration: 0.15, thenDragTo: p(app, 0.58, 0.65))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 2)
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        attach(app, "three-point-rectangle")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testThreePointHeightCanBeEditedWithoutLosingBaselineBadge() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).press(forDuration: 0.15, thenDragTo: p(app, 0.64, 0.46))
        p(app, 0.64, 0.46).press(forDuration: 0.15, thenDragTo: p(app, 0.58, 0.65))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2)
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        labels.element(boundBy: 1).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let previousHeight = field.value as? String
        XCTAssertNotEqual(previousHeight, "1")
        app.buttons["Keypad-1"].tap()
        XCTAssertEqual(field.value as? String, "1")
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2, "Editing height must keep the baseline accessible")
        attach(app, "three-point-height-edited-both-badges")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(labels.count, 2)
        XCTAssertFalse(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.exists,
                       "Undo must restore the pre-edit height, not merely retain two labels")
        app.buttons["RedoButton"].tap()
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testThreePointTapsAndCancelDoNotLeaveStrayBaseline() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).tap()
        XCTAssertTrue(app.buttons["CancelRectangle"].waitForExistence(timeout: 3))
        p(app, 0.64, 0.46).tap()
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        app.buttons["CancelRectangle"].tap()
        XCTAssertFalse(app.buttons["CancelRectangle"].exists)
        // A fresh three-tap construction is one completed rectangle.
        p(app, 0.35, 0.38).tap()
        XCTAssertTrue(app.buttons["CancelRectangle"].waitForExistence(timeout: 3))
        p(app, 0.64, 0.46).tap()
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        p(app, 0.58, 0.65).tap()
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        app.buttons["Exit Sketching"].tap()
        app.buttons["UndoButton"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertFalse(app.buttons["Extrude"].exists, "One undo removes the whole rectangle")
        app.buttons["RedoButton"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testArmedCircleDrawsAtExistingRectangleCornerInsteadOfMovingIt() {
        let app = start()
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.60, 0.60))
        startSketchTool(app, "Circle")
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.44, 0.35))
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3),
                      "The circle draw must not become a rectangle control-point edit")
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:
            "identifier == 'DimensionLabel' AND label BEGINSWITH 'Ø'")).firstMatch.waitForExistence(timeout: 3))
        attach(app, "circle-at-rectangle-corner")
    }
}
