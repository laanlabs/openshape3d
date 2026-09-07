//
//  SketchParityStepsUITests.swift
//  openshape3dUITests
//
//  The sketching steps, each from a FRESH sketch, run exactly as they were run
//  by hand in the live Shapr3D on 2026-09-06 so the two can be compared frame
//  for frame. Chaining all of them into one sketch compounds coordinate error
//  into geometry neither app would produce, which tests nothing.
//
//  Measured Shapr3D reference:
//   • a line ~1.6° off horizontal is NOT snapped flat and gains NO constraint
//     (0.57° is snapped and constrained, 1.15° and 1.6° are not);
//   • its length shows while selected, and clicking it opens a number pad
//     whose field carries a variables affordance;
//   • a rectangle shows BOTH dimensions at once;
//   • a circle is dimensioned as a DIAMETER.
//

import XCTest

final class SketchParityStepsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Fresh app, fresh ground sketch, `tool` armed and the camera square on.
    private func freshSketch(tool: String) -> (XCUIApplication, XCUIElement) {
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
        sleep(2)
        // Square the camera up and PROVE it. Screen coordinates only map to the
        // sketch plane's angles head-on: obliquely, a 1.6° drag on screen is a
        // much smaller angle in sketch space and legitimately snaps flat, which
        // is what made an earlier run look like a tolerance bug.
        lookAtSketch(app)
        lookAtSketch(app)
        XCTAssertFalse(app.buttons["Look at Sketch"].exists,
                       "the camera must be square on the sketch plane")
        return (app, window)
    }

    private func point(_ w: XCUIElement, _ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
        w.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
    }

    // MARK: 1 — draw a line, then edit its length

    func testLineIsNotConstrainedAndItsLengthEdits() throws {
        let (app, w) = freshSketch(tool: "Line")
        // ~1.6° off horizontal, clear of the origin axes (drawing along an axis
        // snaps to the AXIS, a different rule).
        // ~1.6° off horizontal, clear of the origin axes (drawing along an axis
        // snaps to the AXIS, a different rule). Shapr3D leaves this angle alone.
        func dy(_ deg: Double) -> CGFloat { CGFloat(330 * tan(deg * .pi / 180) / 1376) }
        point(w, 0.30, 0.64).press(forDuration: 0.15,
                                   thenDragTo: point(w, 0.62, 0.64 - dy(1.6)))
        sleep(1)
        shot(app, "line-1-drawn")

        let glyphs = app.buttons.matching(identifier: "ConstraintGlyph")
            .allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(glyphs, [], "Shapr3D leaves a 1.6° line alone; so must this")

        point(w, 0.46, 0.64 - dy(1.6) / 2).tap(); sleep(1)
        shot(app, "line-2-selected")
        let badge = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "selecting shows the length, as Shapr3D does")

        badge.tap(); sleep(1)
        shot(app, "line-3-number-pad")
        XCTAssertTrue(app.buttons["KeypadDelete"].waitForExistence(timeout: 3),
                      "the pad opens, not the system keyboard")
        XCTAssertTrue(app.buttons["DimensionVariables"].exists,
                      "the field carries the variables affordance Shapr3D has")

        let field = app.textFields.matching(identifier: "DimensionField").firstMatch
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            app.buttons["KeypadDelete"].tap()
        }
        for ch in "300" { app.buttons["Keypad-\(ch)"].tap() }
        app.buttons["KeypadCommit"].tap(); sleep(1)
        shot(app, "line-4-length-300")
    }

    // MARK: 4 — rectangle

    func testRectangleShowsBothDimensions() throws {
        let (app, w) = freshSketch(tool: "Rect")
        point(w, 0.28, 0.42).press(forDuration: 0.15, thenDragTo: point(w, 0.62, 0.60))
        sleep(1)
        // Drawing opens the value field for ONE side (bug report 5ef841c2),
        // so the other side is the badge: both dimensions are present, one
        // editable. `SketchAnnotationVisibilityTests` covers the selected case
        // as pure values, without coordinates that a resize can invalidate.
        let editing = app.buttons.matching(identifier: "DimensionLabel")
            .allElementsBoundByIndex.map(\.label)
        print("PARITY rect while-editing badges=\(editing)")
        shot(app, "rect-1-drawn")
        let field = app.textFields.matching(identifier: "DimensionField").firstMatch
        XCTAssertTrue(field.exists, "one side opens for typing")
        XCTAssertEqual(editing.count, 1,
                       "and the other shows as a badge; got \(editing)")
    }

    /// Is the first stroke after entering a sketch different, or was that a
    /// camera-settle artefact in the harness? Same angle, tool armed at entry.
    func testFirstStrokeAfterEnteringASketchIsNotConstrained() throws {
        let (app, w) = freshSketch(tool: "Line")
        sleep(3)   // let everything settle; nothing else touched in between
        func dy(_ deg: Double) -> CGFloat { CGFloat(330 * tan(deg * .pi / 180) / 1376) }
        point(w, 0.30, 0.64).press(forDuration: 0.15,
                                   thenDragTo: point(w, 0.62, 0.64 - dy(1.6)))
        sleep(1)
        shot(app, "first-stroke")
        let glyphs = app.buttons.matching(identifier: "ConstraintGlyph")
            .allElementsBoundByIndex.map(\.label)
        print("PARITY first-stroke glyphs=\(glyphs)")
        XCTAssertEqual(glyphs, [], "the first stroke must behave like any other")
    }

    // MARK: 5 — circle

    func testCircleIsDimensionedAsADiameter() throws {
        let (app, w) = freshSketch(tool: "Circle")
        point(w, 0.45, 0.45).press(forDuration: 0.15, thenDragTo: point(w, 0.62, 0.45))
        sleep(1)
        shot(app, "circle-1-drawn")
        // Drawing a circle opens its value field on lift-off, so read the field.
        let field = app.textFields.matching(identifier: "DimensionField").firstMatch
        if field.exists {
            print("PARITY circle field=\(String(describing: field.value))")
            app.buttons["KeypadCommit"].tap(); sleep(1)
        }
        point(w, 0.62, 0.45).tap(); sleep(1)
        shot(app, "circle-2-selected")
        let labels = app.buttons.matching(identifier: "DimensionLabel")
            .allElementsBoundByIndex.map(\.label)
        print("PARITY circle badges=\(labels)")
        XCTAssertTrue(labels.contains { $0.hasPrefix("Ø") },
                      "a circle reads as a diameter; badges: \(labels)")
    }

    /// Is the constraint a tolerance question at all? 8° is far outside any
    /// plausible snap. If this also gains an H, the tolerance is not reaching
    /// the engine; if it is clean, then 1.6° is being made exactly horizontal
    /// by something else before the H/V test sees it.
    func testLineWellOutsideToleranceIsNotConstrained() throws {
        let (app, w) = freshSketch(tool: "Line")
        sleep(1)
        func dy(_ deg: Double) -> CGFloat { CGFloat(330 * tan(deg * .pi / 180) / 1376) }
        point(w, 0.30, 0.64).press(forDuration: 0.15,
                                   thenDragTo: point(w, 0.62, 0.64 - dy(8.0)))
        sleep(1)
        shot(app, "line-8deg")
        let glyphs = app.buttons.matching(identifier: "ConstraintGlyph")
            .allElementsBoundByIndex.map(\.label)
        print("PARITY 8deg glyphs=\(glyphs)")
        XCTAssertEqual(glyphs, [], "8° must never be snapped flat")
    }

    /// After a shape auto-opens its value pad, can another tool still be
    /// picked? `ParityWalkthrough01` fails right here, and `tapPaletteTool`
    /// falls back to "SketchGroup" — which does not exist inside a sketch — so
    /// a tool that is merely covered reports as a confusing missing-button.
    func testAnotherToolIsReachableWhileTheValuePadIsOpen() throws {
        let (app, w) = freshSketch(tool: "Rect")
        point(w, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: point(w, 0.62, 0.60))
        sleep(1)
        XCTAssertTrue(app.buttons["KeypadDelete"].exists, "the pad auto-opened")

        let circle = app.buttons.containing(.staticText, identifier: "Circle").firstMatch
        print("PARITY circle tool hittable=\(circle.isHittable) frame=\(circle.frame)")
        shot(app, "pad-open-tool-switch")
        XCTAssertTrue(circle.isHittable,
                      "another sketch tool must stay reachable while the pad is up")

        // …and tapping it must not take the app down.
        circle.tap(); sleep(2)
        shot(app, "after-tool-switch")
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].exists,
                      "still in the sketch after switching tools with the pad open")
        point(w, 0.48, 0.47).press(forDuration: 0.15, thenDragTo: point(w, 0.54, 0.51))
        sleep(2)
        shot(app, "after-second-shape")
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].exists,
                      "still alive after drawing a second shape")
    }
}
