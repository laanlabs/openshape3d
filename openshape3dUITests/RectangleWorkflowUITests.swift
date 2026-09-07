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
        sleep(2); lookAtSketch(app)
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

    func testCenterRectangleExtendsAcrossItsStartingPoint() {
        let app = start()
        type(app, "center")
        p(app, 0.52, 0.48).press(forDuration: 0.15, thenDragTo: p(app, 0.66, 0.60))
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
        attach(app, "three-point-rectangle")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
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
