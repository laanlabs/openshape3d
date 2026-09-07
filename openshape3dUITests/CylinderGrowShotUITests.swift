//
//  CylinderGrowShotUITests.swift
//  Tapping a cylinder's side selects the whole wall and opens the Diameter
//  bar (radial push/pull), never a single-facet tab.
//

import XCTest

final class CylinderGrowShotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testCylinderSideOpensDiameterBar() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        // Circle → cylinder.
        startSketchTool(app, "Circle")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.80)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.15,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.63, dy: 0.40)))
        app.buttons["Exit Sketching"].tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app)
        sleep(1)

        // Front view: the cylinder's side wall faces the camera, so a
        // center tap deterministically lands on the curved wall.
        app.buttons["ViewsMenu"].tap()
        XCTAssertTrue(app.buttons["Front"].waitForExistence(timeout: 3))
        app.buttons["Front"].tap()
        sleep(2)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Whole-wall selection → Diameter bar (radial), NOT the Extrude facet bar.
        XCTAssertTrue(app.staticTexts["Diameter"].waitForExistence(timeout: 3),
                      "Tapping a cylinder side should open the Diameter (radial) bar")

        // Grow the diameter and commit → still exactly one body. The Diameter
        // field opens the on-canvas number pad rather than the keyboard, so
        // `replaceText` drives whichever is in front and commits.
        let field = app.textFields.matching(identifier: "RadialDiameterField").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        replaceText(field, with: "14")
        sleep(1)

        // Growing committed to exactly one selectable body (no facet fragments).
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled, "The grown cylinder is the single selection")
        deleteButton.tap() // one delete removes the whole cylinder
        sleep(1)
        XCTAssertFalse(deleteButton.isEnabled, "One clean body — deleted in a single step")
    }
}
