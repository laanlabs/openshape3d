//
//  MeasureUITests.swift
//  openshape3dUITests
//
//  A9 measure/info bar: tapping a face shows Area in the bottom info strip;
//  the Measure tool shows a distance after two notable-point picks.
//

import XCTest

final class MeasureUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchSeeded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1) // camera fit settles
        return app
    }

    /// Review R3-D: assert geometry VALUES through the UI, not just that a
    /// label appears. The seeded box is exactly 4×4×4 mm, so every readout
    /// is a closed-form constant: volume 64.00 mm³, bounds 4.00 × 4.00 ×
    /// 4.00 mm, top-face area 16.00 mm², perimeter 16.00 mm. A kernel,
    /// tessellation, or measurement regression that changes any digit of
    /// these fails here even when the happy-path flow still "works".
    func testSeededBoxReportsExactGeometryValues() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        // Whole-body selection: exact volume + bounds strings.
        XCTAssertTrue(
            app.staticTexts["64.00 mm³"].waitForExistence(timeout: 5),
            "a 4×4×4 seeded box must measure exactly 64.00 mm³"
        )
        XCTAssertTrue(
            app.staticTexts["4.00 × 4.00 × 4.00 mm"].exists,
            "bounds must read the box's exact edge lengths"
        )

        // Deselect, then tap the top face: exact area + perimeter strings.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1) // stay clear of the double-tap window
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        XCTAssertTrue(
            app.staticTexts["16.00 mm²"].waitForExistence(timeout: 5),
            "the 4×4 top face must measure exactly 16.00 mm²"
        )
        XCTAssertTrue(
            app.staticTexts["16.00 mm"].exists,
            "the top face's perimeter is exactly 16.00 mm"
        )
    }

    func testFaceSelectionShowsAreaInInfoBar() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        // Seeded box arrives selected: the info bar already shows Volume.
        XCTAssertTrue(
            app.staticTexts["Volume"].waitForExistence(timeout: 3),
            "Whole-body selection should show Volume in the info bar"
        )

        // Deselect, then tap the box's top face → face selection.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1) // stay clear of the double-tap window
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()

        XCTAssertTrue(
            app.staticTexts["Area"].waitForExistence(timeout: 3),
            "Face selection should show Area in the info bar"
        )
        XCTAssertTrue(app.staticTexts["Perimeter"].exists)
    }

    func testMeasureTwoPointsShowsDistance() throws {
        let app = launchSeeded()
        let window = app.windows.firstMatch

        app.buttons["MeasureButton"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Tap two points to measure"].waitForExistence(timeout: 3)
        )

        // Tap near two box corners; the picker snaps to the nearest body
        // vertex within tolerance. Sweep a few candidate spots so the test
        // survives small camera-framing differences. (Zoom to Fit has
        // respected the portrait aspect since 2026-09-14: on this iPad the box
        // draws at 0.75× its old size, so each spot sits 0.75× as far from
        // the centre as it used to.)
        let candidates: [CGVector] = [
            CGVector(dx: 0.56, dy: 0.44),   // front-top corner
            CGVector(dx: 0.78, dy: 0.665),  // bottom-right corner
            CGVector(dx: 0.455, dy: 0.29),  // top-back corner
            CGVector(dx: 0.81, dy: 0.335),  // top-right corner
            CGVector(dx: 0.55, dy: 0.77),   // bottom-front corner
            CGVector(dx: 0.22, dy: 0.65),   // bottom-left corner
        ]
        let distance = app.staticTexts["MeasureDistanceValue"]
        for offset in candidates {
            window.coordinate(withNormalizedOffset: offset).tap()
            sleep(1) // stay clear of the double-tap recognizer window
            if distance.exists { break }
        }

        XCTAssertTrue(
            distance.waitForExistence(timeout: 3),
            "Two measure picks should show the distance pill"
        )
        XCTAssertTrue(distance.label.hasSuffix("mm"))

        // Done exits the tool.
        app.buttons["Done"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["MeasureDistanceValue"].exists)
    }
}
