//
//  SketchStateUITests.swift
//  openshape3dUITests
//
//  Sketch definition state (plan §C4): the sketch pill carries a state chip
//  that reads "Under-defined — N DOF" (blue) for free geometry and
//  "Fully defined" (green) once every variable is pinned. Draws a line
//  (4 free DOF → under-defined), then Locks the whole line (both endpoints
//  fixed → 0 DOF → fully defined) and asserts the chip flips.
//

import XCTest

final class SketchStateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func startGroundSketch(_ app: XCUIApplication, window: XCUIElement) {
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)
    }

    private func applyConstraint(_ app: XCUIApplication, _ identifier: String) {
        let menu = app.buttons["ConstraintsMenu"]
        if !menu.isHittable { app.buttons["ConstrainGroup"].tap() }
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "Constraints menu should exist")
        menu.tap()
        let item = app.buttons[identifier]
        XCTAssertTrue(item.waitForExistence(timeout: 3), "\(identifier) should be present")
        XCTAssertTrue(item.isEnabled, "\(identifier) should be enabled for this selection")
        item.tap()
    }

    func testLineUnderDefinedThenLockedFullyDefined() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // A single line: both endpoints are free (4 DOF) → under-defined.
        // The under-defined state is shown on-canvas (blue points), NOT as a
        // toolbar badge, so no "Fully defined" chip should be present yet.
        p(0.32, 0.46).press(forDuration: 0.15, thenDragTo: p(0.64, 0.52))
        XCTAssertFalse(
            app.staticTexts.containing(NSPredicate(format: "label == %@", "Fully defined")).firstMatch.exists,
            "A fresh free line is under-defined — no Fully-defined chip yet"
        )

        // The completed line is selected; Lock it: both endpoints become fixed → 0 DOF.
        sleep(1)
        applyConstraint(app, "Constraint_Lock")
        sleep(1)

        // The chip flips to fully defined.
        let fully = NSPredicate(format: "label == %@", "Fully defined")
        let defined = app.staticTexts.containing(fully).firstMatch
        XCTAssertTrue(defined.waitForExistence(timeout: 3),
                      "Locking the whole line should make the sketch fully defined")
    }
}
