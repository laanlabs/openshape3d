//
//  ShapeTwoTapUITests.swift
//  openshape3dUITests
//
//  #142: Circle, Ellipse and Polygon are drawn by two taps (centre, then the
//  radius / corner / vertex), as Rectangle already was — the natural gesture
//  with a mouse or trackpad. Dragging keeps working.
//
//  Each case counts undo steps: a committed shape is exactly one, and a
//  pending first tap is none (Undo only discards it).
//

import XCTest

final class ShapeTwoTapUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchIntoGroundSketch(tool: String) -> (XCUIApplication, XCUIElement) {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, tool)
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)
        return (app, window)
    }

    private func point(_ window: XCUIElement, _ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
        window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
    }

    /// Undo until it disables; how many steps that took.
    private func undoSteps(_ app: XCUIApplication, limit: Int = 6) -> Int {
        let undo = app.buttons["UndoButton"]
        var steps = 0
        while undo.isEnabled, steps < limit {
            undo.tap()
            usleep(400_000)
            steps += 1
        }
        return steps
    }

    func testCircleIsDrawnByTwoTaps() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Circle")
        let undo = app.buttons["UndoButton"]
        XCTAssertFalse(undo.isEnabled, "a fresh sketch has nothing to undo")

        point(window, 0.50, 0.55).tap()      // centre
        usleep(600_000)
        XCTAssertTrue(undo.isEnabled, "Undo can discard the pending centre")
        XCTAssertFalse(app.descendants(matching: .any)["CircleCenterControl"].firstMatch.exists,
                       "one tap draws nothing yet")

        point(window, 0.62, 0.55).tap()      // radius
        sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)["CircleCenterControl"].firstMatch.waitForExistence(timeout: 3),
                      "the second tap commits the circle and leaves it selected, like a drag")
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3),
                      "the committed circle shows its diameter")
        XCTAssertEqual(undoSteps(app), 1, "two taps are one Draw step")
    }

    func testUndoDiscardsAPendingCentreWithoutTouchingHistory() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Circle")
        let undo = app.buttons["UndoButton"]

        point(window, 0.50, 0.55).tap()
        usleep(600_000)
        XCTAssertTrue(undo.isEnabled)
        undo.tap()
        usleep(600_000)
        XCTAssertFalse(undo.isEnabled, "the pending centre is gone and nothing was drawn")

        // The tool is still armed: two more taps draw one circle.
        point(window, 0.45, 0.50).tap()
        usleep(600_000)
        point(window, 0.55, 0.50).tap()
        sleep(1)
        XCTAssertEqual(undoSteps(app), 1)
    }

    func testPolygonIsDrawnByTwoTaps() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Polygon")
        point(window, 0.50, 0.55).tap()      // centre
        usleep(600_000)
        point(window, 0.60, 0.55).tap()      // a vertex
        sleep(1)
        XCTAssertEqual(undoSteps(app), 1, "two taps are one polygon")
    }

    func testEllipseIsDrawnByTwoTaps() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Ellipse")
        point(window, 0.50, 0.55).tap()      // centre
        usleep(600_000)
        point(window, 0.62, 0.61).tap()      // a corner of its box: both radii
        sleep(1)
        XCTAssertEqual(undoSteps(app), 1, "two taps are one ellipse")
    }

    func testDraggingStillDrawsACircle() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Circle")
        point(window, 0.50, 0.55).press(forDuration: 0.15, thenDragTo: point(window, 0.60, 0.55))
        sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)["CircleCenterControl"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(undoSteps(app), 1)
    }

    func testATapFollowedByADragElsewhereIsAnOrdinaryDrag() throws {
        let (app, window) = launchIntoGroundSketch(tool: "Circle")
        point(window, 0.30, 0.40).tap()      // a stray first tap
        usleep(600_000)
        // Press far from it and drag: the circle is centred where the drag began.
        point(window, 0.55, 0.60).press(forDuration: 0.15, thenDragTo: point(window, 0.63, 0.60))
        sleep(1)
        let center = app.descendants(matching: .any)["CircleCenterControl"].firstMatch
        XCTAssertTrue(center.waitForExistence(timeout: 3))
        let expected = point(window, 0.55, 0.60).screenPoint
        XCTAssertEqual(center.frame.midX, expected.x, accuracy: 30, "centred on the drag's start, not the stray tap")
        XCTAssertEqual(center.frame.midY, expected.y, accuracy: 30)
        XCTAssertEqual(undoSteps(app), 1)
    }
}
