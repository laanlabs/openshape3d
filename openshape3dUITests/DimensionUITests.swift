//
//  DimensionUITests.swift
//  openshape3dUITests
//
//  Driving dimensions (plan §C2, spec §2.2). Draws geometry, selects it so its
//  editable dimension label appears in the sketch overlay, opens the inline
//  numeric field, and commits a new value — asserting the solver drives the
//  geometry to that value (read back from the overlay's measured label).
//

import XCTest

final class DimensionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func startGroundSketch(
        _ app: XCUIApplication, window: XCUIElement, tool: String
    ) {
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, tool)
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)
    }

    /// Open the dimension field, clear it, enter `value` ON THE KEYPAD, commit.
    ///
    /// There is no system keyboard to type into any more — the field is edited
    /// by the on-canvas pad, which is the point of it. Drawing a circle /
    /// rectangle / polygon already opens the field on lift-off (bug report
    /// 5ef841c2), so only tap a label when one is not open yet.
    private func setDimension(_ app: XCUIApplication, to value: String) {
        let field = app.textFields.matching(identifier: "DimensionField").firstMatch
        if !field.exists {
            let label = app.buttons["DimensionLabel"].firstMatch
            XCTAssertTrue(label.waitForExistence(timeout: 3),
                          "Selecting the entity should show an editable dimension label")
            label.tap()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 3), "The dimension field is open")
        XCTAssertTrue(app.buttons["KeypadDelete"].waitForExistence(timeout: 3),
                      "The keypad comes up with the field, not the system keyboard")

        // Clear whatever the field opened with, one key at a time.
        let delete = app.buttons["KeypadDelete"]
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            delete.tap()
        }
        for character in value {
            app.buttons["Keypad-\(character)"].tap()
        }
        XCTAssertEqual(field.value as? String, value, "the keypad entered the value")
        attach(app, "keypad-mid-edit")

        let commit = app.buttons.matching(identifier: "KeypadCommit").firstMatch
        XCTAssertTrue(commit.waitForExistence(timeout: 2))
        commit.tap()
    }

    // MARK: - Line length dimension

    func testLineLengthDimensionDrivesGeometry() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // A completed line exposes its length without a selection tap or keypad.
        p(0.34, 0.50).press(forDuration: 0.15, thenDragTo: p(0.62, 0.50))
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing a line should push an undoable step")
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists,
                       "Finishing a line shows a readout, not an automatic keypad")
        sleep(1)

        // Edit the length dimension to 20 (inline arithmetic also accepted).
        setDimension(app, to: "20")
        sleep(1)

        // The solved line is length 20: the measured label reads it back, and
        // the Dimension edit is one extra undo step (line draw + dimension = 2).
        XCTAssertTrue(app.staticTexts["20.00 mm"].waitForExistence(timeout: 3),
                      "The line should be driven to length 20")
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo the dimension
        undo.tap() // undo the line draw
        XCTAssertFalse(undo.isEnabled,
                       "Line draw + dimension should be exactly two undo steps")
    }

    // MARK: - Circle radius dimension

    func testCircleDiameterDimensionDrivesGeometry() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Circle")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Draw a circle (center → radius handle). Lift-off selects it and opens
        // its radius field, so type straight in — no second tap. Note the
        // on-screen keyboard that field raises carries its own "Undo" button,
        // which is why the undo assertion waits until after the commit.
        p(0.50, 0.50).press(forDuration: 0.15, thenDragTo: p(0.63, 0.50))

        // A full circle dimensions as a DIAMETER (it reads Ø while you drag it
        // out, so offering R on release showed two numbers for one circle).
        setDimension(app, to: "10")
        sleep(1)

        XCTAssertTrue(app.buttons["UndoButton"].firstMatch.isEnabled,
                      "Drawing a circle should push an undoable step")

        // Ø10 drives the radius to 5, which is what the info bar reports.
        XCTAssertTrue(app.staticTexts["5.00 mm"].waitForExistence(timeout: 3),
                      "Ø10 should drive the circle to radius 5")
        XCTAssertEqual(app.buttons["DimensionLabel"].firstMatch.label, "Ø10 mm",
                       "the badge carries the CAD leader")
        attach(app, "circle-diameter-badge")
    }

    // MARK: - Dimensions survive leaving the sketch

    /// What Shapr3D actually does, verified by driving it on 2026-09-06: with
    /// "Always Show Dimensions" off (its shipped default), a dimension follows
    /// the SELECTION. Leaving the sketch with nothing selected hides it;
    /// selecting the geometry again brings it back, ready to edit. The original
    /// complaint — "dimensions vanish" — is only a bug when selecting cannot
    /// bring them back, which is what this pins.
    func testDimensionFollowsTheSelectionAfterExitingTheSketch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        p(0.34, 0.50).press(forDuration: 0.15, thenDragTo: p(0.62, 0.50))
        sleep(1)
        setDimension(app, to: "20")
        sleep(1)

        let badge = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3),
                      "the dimension is visible while sketching")
        attach(app, "dimension-inside-sketch")

        app.buttons["Exit Sketching"].tap()
        sleep(2)
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists,
                       "we really did leave sketch mode")
        attach(app, "dimension-after-exit")

        // Leaving the sketch hides it, which matches Shapr3D's default.
        XCTAssertFalse(app.buttons["DimensionLabel"].firstMatch.exists,
                       "with Always Show off, nothing selected means nothing shown")

        // Normal model-mode taps must recover the dimension.
        p(0.48, 0.50).tap()
        sleep(1)
        attach(app, "dimension-after-reselect")
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3),
                      "selecting the line shows its dimension again, as Shapr3D does")
        app.buttons["DimensionLabel"].firstMatch.tap()
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3),
                      "the recovered badge opens an editor, not only a readout")
        XCTAssertTrue(app.buttons["Exit Sketching"].exists,
                      "editing an external badge enters its owning sketch without arming a draw tool")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
