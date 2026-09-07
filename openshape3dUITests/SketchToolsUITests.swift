//
//  SketchToolsUITests.swift
//  openshape3dUITests
//
//  New sketch tools (A2): draw a polygon and an ellipse in a fresh design,
//  confirm each commits an undoable entity, then exit sketching and tap
//  inside the polygon — the Extrude bar appearing proves profile detection
//  works end-to-end for the new closed-loop entities.
//

import XCTest

final class SketchToolsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testPolygonAndEllipseProfilesExtrudable() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Polygon")

        // Plane pickers appear; tapping the bare ground starts there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()

        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3),
                      "Sketch status bar should appear")
        lookAtSketch(app)

        // Let the head-on camera animation settle.
        sleep(2)

        // Polygon: drag center -> vertex.
        let polygonCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.42))
        let polygonVertex = window.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.42))
        polygonCenter.press(forDuration: 0.15, thenDragTo: polygonVertex)

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing a polygon should push an undoable command")

        // Ellipse: switch tools, drag center -> corner (away from the polygon).
        startSketchTool(app, "Ellipse")
        let ellipseCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.65))
        let ellipseCorner = window.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.72))
        ellipseCenter.press(forDuration: 0.15, thenDragTo: ellipseCorner)

        // Two entities = two undoable commands: after one undo the stack
        // still has the polygon.
        undo.tap()
        XCTAssertTrue(undo.isEnabled, "The polygon command should remain after undoing the ellipse")
        app.buttons["RedoButton"].tap()

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists,
                       "Exiting should dismiss the sketch status bar")

        // Tap inside the polygon: profile detection should open Extrude.
        polygonCenter.tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Tapping inside the polygon should start the Extrude tool")
    }
}
