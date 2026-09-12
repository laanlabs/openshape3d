//
//  PlanesUITests.swift
//  openshape3dUITests
//
//  Sketch planes (A1): tapping a sketch tool with nothing selected shows the
//  origin plane pickers (tap a tile OR the bare ground to start), and a
//  selected planar face becomes the sketch plane directly — profiles drawn on
//  a face are extrudable like any other.
//

import XCTest

final class PlanesUITests: XCTestCase {

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testPlanePickersAppearAndGroundTapStartsSketch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")

        // The three origin plane tiles are up; the status pill tracks them.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3),
                      "Tapping a sketch tool with no plane should show the plane pickers")

        // Tapping the bare ground (away from the tiles) starts a ground sketch.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3),
                      "Tapping the ground should start sketching there")
        lookAtSketch(app)
        sleep(2) // camera animation

        // Draw a rectangle: one undoable command.
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.42))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.58))
        start.press(forDuration: 0.15, thenDragTo: end)
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled,
                      "Drawing on the picked plane should commit an undoable entity")

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists)
    }

    func testWorldTileTapStartsSketchOnThatPlane() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))

        // The XY tile (front plane) projects right-and-up of screen center
        // under the default camera.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.39)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on plane"].waitForExistence(timeout: 3),
                      "Tapping a plane tile should start sketching on that (non-ground) plane")
        lookAtSketch(app)

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on plane"].exists)
    }

    func testCoplanarNewSketchAndNamedContinuationStaySeparate() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        for y in [CGFloat(0.45), CGFloat(0.65)] {
            startSketchTool(app, "Line")
            XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
            p(0.80, 0.78).tap()
            XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
            lookAtSketch(app)
            sleep(1)
            p(0.40, y).press(forDuration: 0.15, thenDragTo: p(0.60, y))
            app.buttons["Exit Sketching"].tap()
        }
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Sketch 1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["ItemName-Sketch 2"].exists,
                      "Starting on the same plane must not silently append to Sketch 1")
        attach(app, "independent-coplanar-items")
        let first = app.otherElements["ItemRow-Sketch 1"].firstMatch
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).tap()
        app.buttons["ItemsButton"].tap()
        tapPaletteTool(app, group: "Sketch", label: "Line")
        XCTAssertFalse(app.staticTexts["Choose a sketch plane"].exists,
                       "Explicit item entry must continue that sketch")
        p(0.40, 0.55).press(forDuration: 0.15, thenDragTo: p(0.60, 0.55))
        app.buttons["Exit Sketching"].tap()
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Sketch 2"].exists)
        XCTAssertFalse(app.textFields["ItemName-Sketch 3"].exists)
        attach(app, "named-continuation-keeps-two-items")
    }

    func testSketchOnFaceThenExtrudeNewBody() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles

        let window = app.windows.firstMatch

        // Deselect the seeded box, then tap its top face.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1) // stay clear of the double-tap window
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"].waitForExistence(timeout: 3)
        )

        // A sketch tool with a face selected sketches ON that face.
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Sketching on plane"].waitForExistence(timeout: 3),
                      "Sketch tools should start on the selected face's plane")
        lookAtSketch(app)
        sleep(2) // head-on camera animation

        // Draw a rectangle on the face.
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.42))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.60, dy: 0.58))
        start.press(forDuration: 0.15, thenDragTo: end)
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled)

        app.buttons["Exit Sketching"].tap()

        // Tap the new fill (coincident with the top face): Extrude starts.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.50)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "The profile drawn on the face should be tappable for extrude")

        // Boolean badge → New Body so the result stays separate from the box.
        let newBodySegment = app.buttons["New Body"].firstMatch
        XCTAssertTrue(newBodySegment.waitForExistence(timeout: 3))
        newBodySegment.tap()
        typeExtrudeHeight(app)

        // The new body is selected; delete it — the box must survive as a
        // separate body (two bodies existed).
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled)
        deleteButton.tap()

        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.62)).tap()
        let predicate = NSPredicate(format: "isEnabled == true")
        expectation(for: predicate, evaluatedWith: deleteButton)
        waitForExpectations(timeout: 5)

        // Undo count sane: seed add, sketch entity, extrude add, delete.
        let undo = app.buttons["UndoButton"]
        for _ in 0..<4 {
            XCTAssertTrue(undo.isEnabled)
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled, "Exactly four undoable commands expected")
    }
}
