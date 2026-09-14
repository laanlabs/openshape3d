//
//  ParityWalkthroughUITests.swift
//  openshape3dUITests
//
//  Visual parity walkthrough: drives every major flow and captures named
//  screenshots (kept in the result bundle) for review against
//  docs/PARITY_SPEC.md. Assertions are deliberately light — the
//  screenshots are the deliverable; flow tests elsewhere assert behavior.
//

import XCTest

final class ParityWalkthroughUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        usleep(300_000)
    }

    private func launchFresh(seed: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        if seed { app.launchEnvironment["OS3D_DEBUG_SEED"] = "1" }
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        sleep(1)
        return app
    }

    func testWalkthrough01SketchTools() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch
        snap("01-editor-empty-palette")

        // Plane pickers
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        snap("02-plane-pickers")

        // Ground sketch: rect + circle inside (hole) + polygon beside
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.35))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.60)))
        startSketchTool(app, "Circle")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.47))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.54, dy: 0.51)))
        startSketchTool(app, "Polygon")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.76, dy: 0.42))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.84, dy: 0.50)))
        snap("03-sketch-rect-hole-polygon-fills")

        app.buttons["Exit Sketching"].tap()
        sleep(1)
        snap("04-fills-after-exit")
    }

    func testWalkthrough02ExtrudeBar() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch

        startSketchTool(app, "Rect")
        _ = app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        _ = app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3)
        lookAtSketch(app)
        sleep(2)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.40))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.58)))
        app.buttons["Exit Sketching"].tap()
        sleep(1)

        // Tap the fill: full extrude bar (badge, symmetric, revolve/sweep/loft)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.49)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        snap("05-extrude-bar-with-badge")

        // Pull upward: dynamic preview + arrow
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.49))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.51, dy: 0.30)))
        snap("06-extrude-pull-preview")

        app.buttons["Extrude"].firstMatch.tap()
        sleep(1)
        snap("07-committed-body-info-bar")
    }

    func testWalkthrough03FaceItemsViews() throws {
        let app = launchFresh(seed: true)
        let window = app.windows.firstMatch
        snap("08-seeded-selected-gizmo-rings")

        // Face selection
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        XCTAssertTrue(
            app.staticTexts["Face selected — drag it to push or pull"].waitForExistence(timeout: 3)
        )
        snap("09-face-selected-highlight")

        // Items panel
        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.staticTexts["Bodies"].waitForExistence(timeout: 3))
        snap("10-items-panel")
        app.buttons["ItemsButton"].tap()

        // Views menu
        app.buttons["ViewsMenu"].tap()
        XCTAssertTrue(app.buttons["Front"].waitForExistence(timeout: 3))
        snap("11-views-menu")
        app.buttons["Front"].tap()
        sleep(1)
        snap("12-front-view")
    }

    func testWalkthrough04PatternMeasure() throws {
        let app = launchFresh(seed: true)
        let window = app.windows.firstMatch

        // Pattern bar with ghost previews
        tapPaletteTool(app, group: "Transform", id: "PatternButton")
        XCTAssertTrue(app.buttons["PatternApply"].waitForExistence(timeout: 3))
        snap("13-pattern-bar-ghosts")
        app.buttons["Cancel"].firstMatch.tap()
        sleep(1)

        // Measure two corners
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)
        app.buttons["MeasureButton"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Tap two points to measure"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.34, dy: 0.62)).tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.66, dy: 0.62)).tap()
        _ = app.staticTexts["MeasureDistanceValue"].waitForExistence(timeout: 3)
        snap("14-measure-distance")
        app.buttons["Done"].firstMatch.tap()
    }

    func testWalkthrough05RevolveSweepLoft() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch

        // Rect + separate vertical line (axis), then arm Revolve
        startSketchTool(app, "Rect")
        _ = app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        _ = app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3)
        lookAtSketch(app)
        sleep(2)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.40))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.56)))
        startSketchTool(app, "Line")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.35))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.62)))
        app.buttons["Exit Sketching"].tap()
        sleep(1)

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.47)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))

        app.buttons["Revolve"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Tap a sketch line to set the revolve axis"].waitForExistence(timeout: 3)
        )
        snap("15-revolve-axis-pill")

        window.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.48)).tap()
        XCTAssertTrue(app.staticTexts["Angle"].waitForExistence(timeout: 5))
        snap("16-revolve-preview-angle-bar")

        app.buttons["Cancel"].firstMatch.tap()
    }

    func testWalkthrough06SectionAndXRay() throws {
        let app = launchFresh(seed: true)
        let window = app.windows.firstMatch

        // Deselect the seeded box so the section shot is uncluttered.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap()
        sleep(1)

        // Views → Section arms the plane picker.
        app.buttons["ViewsMenu"].tap()
        let section = app.buttons["Section"]
        XCTAssertTrue(section.waitForExistence(timeout: 3))
        section.tap()
        XCTAssertTrue(app.staticTexts["Choose a section plane"].waitForExistence(timeout: 3))
        snap("17-section-plane-pickers")

        // Tap a plane tile through the box (candidates cover camera-fit
        // variance, same pattern as SplitPatternUITests).
        let flip = app.buttons["SectionFlip"]
        let candidates: [CGVector] = [
            CGVector(dx: 0.42, dy: 0.55),
            CGVector(dx: 0.46, dy: 0.50),
            CGVector(dx: 0.50, dy: 0.55),
            CGVector(dx: 0.54, dy: 0.50),
            CGVector(dx: 0.77, dy: 0.49),
            CGVector(dx: 0.38, dy: 0.60),
        ]
        for offset in candidates where !flip.exists {
            window.coordinate(withNormalizedOffset: offset).tap()
            _ = flip.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(flip.exists, "A tile tap should activate the section")
        sleep(1)
        // Orbit slightly off the head-on view so the open cut reads as a
        // sectioned box, not a flat quad (drag starts on empty grid →
        // camera orbit; orbit sensitivity is high, keep the drag tiny).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.33))
            .press(forDuration: 0.1,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.68, dy: 0.35)))
        sleep(1)
        snap("18-section-active-flip-off-badges")
        app.buttons["SectionOff"].tap()
        sleep(1)

        // Views → Display → X-Ray.
        app.buttons["ViewsMenu"].tap()
        let displayShaded = app.buttons["Display: Shaded"]
        XCTAssertTrue(displayShaded.waitForExistence(timeout: 3))
        displayShaded.tap()
        let xray = app.buttons["X-Ray"]
        XCTAssertTrue(xray.waitForExistence(timeout: 3))
        xray.tap()
        sleep(1)
        snap("19-xray-display-mode")
    }

    func testWalkthrough07MarqueeAndMaterial() throws {
        let app = launchFresh(seed: true)
        let window = app.windows.firstMatch

        // Pattern the seeded box so the marquee has several targets.
        tapPaletteTool(app, group: "Transform", id: "PatternButton")
        XCTAssertTrue(app.buttons["PatternApply"].waitForExistence(timeout: 3))
        app.buttons["PatternApply"].tap()
        app.buttons["Fit View"].tap()
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85)).tap()

        // Select mode: status pill + filter chips.
        app.buttons["SelectModeButton"].tap()
        XCTAssertTrue(app.staticTexts["Drag to select"].waitForExistence(timeout: 3))
        snap("20-select-mode-pill-filters")

        // Crossing marquee (right→left), captured MID-DRAG: the finger holds
        // at the stroke end while a background queue grabs the screen — the
        // dashed crossing rect is still up.
        var midDrag: XCUIScreenshot?
        let captured = expectation(description: "mid-drag screenshot")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.8) {
            midDrag = XCUIScreen.main.screenshot()
            captured.fulfill()
        }
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.25))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.8))
        start.press(forDuration: 0.05, thenDragTo: end,
                    withVelocity: .default, thenHoldForDuration: 2.5)
        wait(for: [captured], timeout: 10)
        if let midDrag {
            let attachment = XCTAttachment(screenshot: midDrag)
            attachment.name = "21-marquee-crossing-in-progress"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCTAssertTrue(app.staticTexts["3 bodies"].waitForExistence(timeout: 3),
                      "The crossing marquee should select every pattern instance")
        snap("22-marquee-multi-selection-info")

        // Material sheet over the selection.
        app.buttons["MaterialButton"].tap()
        XCTAssertTrue(app.staticTexts["MaterialMetallicValue"].waitForExistence(timeout: 3))
        snap("23-material-sheet")
        app.buttons["MaterialCancel"].tap()
    }

    func testWalkthrough08ImageSelected() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED_IMAGE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        let itemsButton = app.buttons["ItemsButton"]
        XCTAssertTrue(itemsButton.waitForExistence(timeout: 10))
        sleep(1)

        // Tap the seeded reference image: selection outline + image bar.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.sliders["ImageOpacitySlider"].waitForExistence(timeout: 3))

        // The seed camera-fits the quad edge-to-edge; shrink it via the
        // size field so the shot reads as a reference image on the grid
        // (viewport pinches are unreliable under synthesized touches).
        let sizeField = app.textFields["ImageSizeField"]
        XCTAssertTrue(sizeField.exists)
        replaceText(sizeField, with: "12")
        sleep(1)
        snap("24-inserted-image-selected-bar")
    }

    func testWalkthrough09SymbolPlacement() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch

        startSketchTool(app, "Line")
        _ = app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        _ = app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3)
        lookAtSketch(app)
        sleep(2)

        func point(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Two parallel lines, selected, become the "Bracket" symbol.
        point(0.35, 0.40).press(forDuration: 0.15, thenDragTo: point(0.60, 0.40))
        point(0.35, 0.48).press(forDuration: 0.15, thenDragTo: point(0.60, 0.48))
        point(0.47, 0.40).tap()
        sleep(1)
        point(0.47, 0.48).tap()
        sleep(1)
        app.buttons["SymbolGroup"].tap()
        app.buttons["MakeSymbolButton"].tap()
        let alert = app.alerts["Make Symbol"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        snap("25-make-symbol-prompt")
        let nameField = alert.textFields.firstMatch
        nameField.tap()
        nameField.typeText("Bracket")
        alert.buttons["Create"].tap()

        // Insert arms tap-to-place; two taps stamp two instances.
        app.buttons["SymbolGroup"].tap()
        let insertMenu = app.buttons["InsertSymbolMenu"]
        XCTAssertTrue(insertMenu.waitForExistence(timeout: 3))
        insertMenu.tap()
        let choice = app.buttons["Bracket"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 3))
        choice.tap()
        XCTAssertTrue(app.buttons["InsertSymbolDone"].waitForExistence(timeout: 3))
        point(0.30, 0.66).tap()
        sleep(1)
        point(0.62, 0.66).tap()
        sleep(1)
        snap("26-symbol-placement-two-instances")
        app.buttons["InsertSymbolDone"].tap()
    }

    // MARK: - Phase C: constraints, dimensions, sketch states

    /// Enter a ground sketch with the named tool (plane-pick step, then settle
    /// the head-on camera animation). Mirrors the constraint flow tests.
    private func startGroundSketch(
        _ app: XCUIApplication, window: XCUIElement, tool: String
    ) {
        startSketchTool(app, tool)
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
    }

    /// Constraints tranche: the sketch-state chip flipping blue→green, and the
    /// adaptive Constrain menu (only the constraints valid for two selected
    /// lines are enabled). Draws two lines meeting at a corner, snaps the
    /// under-defined (blue) chip, opens the adaptive menu, then Locks the lines
    /// so the chip flips to fully-defined (green).
    func testWalkthrough10ConstraintsAndStates() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Two near-touching lines: a horizontal-ish top and a slanted side, all
        // four endpoints free → the sketch is under-defined.
        //
        // Each stroke is confirmed by the per-point DOF markers it should leave
        // behind (2 per line), and retried once if it left none. A synthesized
        // press-and-drag is occasionally swallowed, and when the SECOND line
        // went missing the failure landed six steps later as "Parallel should
        // enable for two lines" — the menu was right, the sketch was short a
        // line. (This was the long-serial-run flake.)
        let markers = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker")
        func drawLine(_ a: XCUICoordinate, _ b: XCUICoordinate, expecting count: Int) {
            func settled() -> Bool {
                let deadline = Date().addingTimeInterval(4)
                while Date() < deadline {
                    if markers.count >= count { return true }
                    usleep(250_000)
                }
                return false
            }
            a.press(forDuration: 0.15, thenDragTo: b)
            if !settled() {
                a.press(forDuration: 0.2, thenDragTo: b)
                XCTAssertTrue(settled(),
                              "the line stroke never landed — \(markers.count) point markers, "
                              + "expected \(count)")
            }
        }
        drawLine(p(0.30, 0.45), p(0.55, 0.45), expecting: 2)
        drawLine(p(0.57, 0.47), p(0.66, 0.70), expecting: 4)
        sleep(1)
        app.buttons["Line"].tap()
        sleep(1)

        // Under-defined geometry reads on-canvas (blue points), not as a toolbar
        // badge — so no "Fully defined" chip should be present yet.
        XCTAssertFalse(
            app.staticTexts.containing(NSPredicate(format: "label == %@", "Fully defined")).firstMatch.exists,
            "Fresh free lines are under-defined — no Fully-defined chip yet"
        )
        snap("27-sketch-under-defined-blue")

        // Release retains the second line. Add the horizontal line at a
        // marker-derived quarter point, away from its dimension label and the
        // near-touching endpoints. Tapping the second line again would toggle
        // it out of the additive selection.
        let centers = markers.allElementsBoundByIndex.map {
            CGPoint(x: $0.frame.midX, y: $0.frame.midY)
        }
        XCTAssertEqual(centers.count, 4)
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let horizontal = pairs
            .filter { abs(centers[$0.0].y - centers[$0.1].y) < 30 }
            .max {
                abs(centers[$0.0].x - centers[$0.1].x)
                    < abs(centers[$1.0].x - centers[$1.1].x)
            }!
        func tapQuarterPoint(_ i: Int, _ j: Int) {
            let target = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: (centers[i].x * 0.75 + centers[j].x * 0.25) - window.frame.minX,
                dy: (centers[i].y * 0.75 + centers[j].y * 0.25) - window.frame.minY
            ))
            target.tap()
        }
        tapQuarterPoint(horizontal.0, horizontal.1)
        sleep(1)

        // Open the adaptive Constrain menu. With two lines selected, direction
        // relations (Parallel/Perpendicular/Equal Length/Coincident/Lock) are
        // enabled while circle-only ones (Concentric/Equal Radius/Tangent) stay
        // disabled — the screenshot captures that adaptive enablement.
        let menu = app.buttons["ConstraintsMenu"]
        if !menu.isHittable { app.buttons["ConstrainGroup"].tap() }
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
        menu.tap()
        let parallel = app.buttons["Constraint_Parallel"]
        XCTAssertTrue(parallel.waitForExistence(timeout: 3))
        XCTAssertTrue(parallel.isEnabled,
                      "Parallel should enable for two lines (both midpoint taps must have "
                      + "selected a line)")
        XCTAssertFalse(app.buttons["Constraint_Concentric"].isEnabled,
                       "Concentric needs two circles — disabled for two lines")
        snap("28-constraint-menu-adaptive")

        // Lock both lines: all four endpoints fixed → 0 DOF → fully defined.
        let lock = app.buttons["Constraint_Lock"]
        XCTAssertTrue(lock.isEnabled, "Lock should enable for a non-empty selection")
        lock.tap()
        sleep(1)

        // The chip flips to GREEN "Fully defined".
        let fully = NSPredicate(format: "label == %@", "Fully defined")
        let defined = app.staticTexts.containing(fully).firstMatch
        XCTAssertTrue(defined.waitForExistence(timeout: 3),
                      "Locking the lines should make the sketch fully defined")

        // Clear the selection so the shot reads cleanly: the move/rotate gizmo
        // and the candidate angle label drop away, leaving the locked geometry,
        // its Lock glyph, and the green chip. A tap on empty grid only
        // deselects — it never draws a line (which needs a drag stroke).
        p(0.86, 0.28).tap()
        sleep(1)
        snap("29-sketch-fully-defined-green")

        app.buttons["Exit Sketching"].tap()
    }

    /// Dimensions tranche: selecting a line surfaces its editable length label;
    /// tapping it opens the inline numeric field. Captures the label being
    /// edited (the field + commit check open over the annotation line).
    func testWalkthrough11DimensionEditing() throws {
        let app = launchFresh()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // A single line, then tap its middle to select it → the driving-length
        // candidate label appears in the overlay.
        p(0.34, 0.50).press(forDuration: 0.15, thenDragTo: p(0.62, 0.50))
        sleep(1)
        app.buttons["Line"].tap()
        sleep(1)
        p(0.80, 0.70).tap()
        sleep(1)
        let lineMarkers = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
        XCTAssertEqual(lineMarkers.count, 2)
        let lineMidpoint = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: (lineMarkers[0].frame.midX + lineMarkers[1].frame.midX) / 2 - window.frame.minX,
            dy: (lineMarkers[0].frame.midY + lineMarkers[1].frame.midY) / 2 - window.frame.minY
        ))
        lineMidpoint.tap()
        sleep(1)

        let label = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 3),
                      "Selecting the line should show an editable dimension label")
        label.tap()

        // The field opens with the on-canvas keypad rather than the system
        // keyboard, so the value is entered by tapping keys.
        let field = app.textFields["DimensionField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let delete = app.buttons["KeypadDelete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            delete.tap()
        }
        app.buttons["Keypad-2"].tap()
        app.buttons["Keypad-0"].tap()
        XCTAssertTrue(app.buttons["KeypadCommit"].waitForExistence(timeout: 2))
        snap("30-dimension-label-editing")

        // Commit: the solver drives the line to length 20.
        app.buttons["KeypadCommit"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["20.00 mm"].waitForExistence(timeout: 3),
                      "The line should be driven to length 20")
        snap("31-dimension-driven-length")

        app.buttons["Exit Sketching"].tap()
    }
}
