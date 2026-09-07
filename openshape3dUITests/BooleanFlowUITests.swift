//
//  BooleanFlowUITests.swift
//  openshape3dUITests
//
//  Boolean flow, Shapr3D-style: create two bodies by sketching rectangles and
//  extruding them, select one, arm Subtract, tap the other, and verify the
//  operation completes (tool body consumed, result selected).
//

import XCTest

final class BooleanFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Draws a rectangle between two normalized points and extrudes it via
    /// the numeric bar (works in the head-on sketch view).
    private func makeBody(
        in app: XCUIApplication,
        from start: CGVector, to end: CGVector, tapInside: CGVector,
        newBody: Bool = false
    ) {
        let window = app.windows.firstMatch
        startSketchTool(app, "Rect")
        // Plane pickers appear; tap the bare ground to sketch there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation to head-on
        lookAtSketch(app)

        window.coordinate(withNormalizedOffset: start)
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: end))
        app.buttons["Exit Sketching"].tap()

        window.coordinate(withNormalizedOffset: tapInside).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        if newBody {
            // The profile overlaps the body already there, so the extrude
            // offers a boolean: keep them separate, or there is nothing to
            // subtract later.
            let segment = app.buttons["New Body"].firstMatch
            XCTAssertTrue(segment.waitForExistence(timeout: 3))
            segment.tap()
        }
        typeExtrudeHeight(app)
        // The commit dismisses the keyboard + extrude bar, and the tool
        // palette re-centers. A palette tap issued mid-animation uses a stale
        // frame and lands one button off (CombineGroup's tap armed Measure).
        // Wait for the bar to leave, then let the palette settle.
        XCTAssertTrue(app.staticTexts["Extrude"].waitForNonExistence(timeout: 5))
        sleep(1)
    }

    func testSubtractFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        // Two separate bodies. The camera stays head-on between sketches, so
        // screen coordinates map stably onto the ground plane.
        // The two must OVERLAP: a subtract whose tool never reaches the
        // target is refused with a notice now (bug report a1ee4e4a) instead
        // of silently handing back an unchanged body, so side-by-side boxes
        // would never exercise the CSG at all. The second is dragged
        // right-to-left so the stroke STARTS clear of the first body.
        makeBody(
            in: app,
            from: CGVector(dx: 0.30, dy: 0.42), to: CGVector(dx: 0.45, dy: 0.58),
            tapInside: CGVector(dx: 0.37, dy: 0.5)
        )
        makeBody(
            in: app,
            from: CGVector(dx: 0.58, dy: 0.58), to: CGVector(dx: 0.43, dy: 0.42),
            tapInside: CGVector(dx: 0.52, dy: 0.5),
            newBody: true
        )

        let window = app.windows.firstMatch

        // Select the first body (bodies occlude their profiles from above).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.37, dy: 0.5)).tap()
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.isEnabled, "First body should be selected")
        // Selecting slides the info strip in and the palette re-centers; a
        // palette tap mid-animation lands on a stale frame one button off
        // (CombineGroup's tap armed Measure). Let it settle.
        sleep(1)

        // Arm Subtract (in the Combine flyout) and tap the second body.
        app.buttons["CombineGroup"].tap()
        let subtractButton = app.buttons.containing(.staticText, identifier: "Subtract").firstMatch
        XCTAssertTrue(subtractButton.waitForExistence(timeout: 2))
        XCTAssertTrue(subtractButton.isEnabled)
        subtractButton.tap()
        XCTAssertTrue(app.staticTexts["Tap the second body to subtract"].waitForExistence(timeout: 3))

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.5)).tap()

        // Computation completes and the result stays selected.
        let selected = NSPredicate(format: "isEnabled == true")
        expectation(for: selected, evaluatedWith: deleteButton)
        waitForExpectations(timeout: 15)
        XCTAssertFalse(app.staticTexts["Tap the second body to subtract"].exists)
    }
}
