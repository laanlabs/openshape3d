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
    /// by the on-canvas pad. Completed lines, circles and rectangles retain
    /// readouts; an explicit badge tap opens the editor.
    private func setDimension(_ app: XCUIApplication, to value: String) {
        let field = app.textFields.matching(identifier: "DimensionField").firstMatch
        if !field.exists {
            let label = app.buttons["DimensionLabel"].firstMatch
            XCTAssertTrue(label.waitForExistence(timeout: 3),
                          "Selecting the entity should show an editable dimension label")
            label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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

    func testSystemKeyboardReplacesSeedAndPreservesDraftAcrossKeypadToggle() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.4))
            .press(forDuration: 0.15, thenDragTo:
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.4)))
        let label = app.buttons.matching(identifier: "DimensionLabel").firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        let original = label.label
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["DimensionSystemKeyboard"].tap()
        let field = app.textFields["DimensionField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.typeText("1")
        XCTAssertEqual(field.value as? String, "1", "Keyboard entry replaces the untouched seed")
        let keypad = app.buttons["DimensionNumericKeyboard"]
        XCTAssertTrue(keypad.exists, "Keyboard field must offer a route back to the numeric pad")
        keypad.tap()
        XCTAssertTrue(app.buttons["Keypad-2"].waitForExistence(timeout: 3))
        XCTAssertEqual(field.value as? String, "1")
        app.buttons["Keypad-2"].tap()
        XCTAssertEqual(field.value as? String, "12", "A real draft is not replaced on keyboard switches")
        app.buttons["DimensionSystemKeyboard"].tap()
        field.typeText("+")
        XCTAssertEqual(field.value as? String, "12+")
        field.typeText("\n")
        XCTAssertTrue(app.staticTexts["DimensionValidationMessage"].waitForExistence(timeout: 3))
        XCTAssertTrue(field.exists, "Invalid Return preserves a recoverable draft")
        field.typeText("1")
        XCTAssertEqual(field.value as? String, "12+1")
        field.typeText("\n")
        XCTAssertFalse(field.exists)
        XCTAssertTrue(label.label.contains("13"))
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.label, original, "One Undo restores geometry before numeric edit")
    }

    /// Painted left circle rim, away from both the diameter annotation and the
    /// radial control above the circle. The radial control is 30 points beyond
    /// the top rim, so its distance from the center marker recovers the radius.
    private func circleLeftRim(
        _ app: XCUIApplication, window: XCUIElement, radial: XCUIElement
    ) -> XCUICoordinate {
        let center = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").firstMatch
        XCTAssertTrue(center.waitForExistence(timeout: 3))
        let radius = max(center.frame.midY - radial.frame.midY - 30, 8)
        return window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: center.frame.midX - radius - window.frame.minX,
            dy: center.frame.midY - window.frame.minY
        ))
    }

    func testSketchAxisTypedMoveCancelAndUndo() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Circle")
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.5, 0.6).press(forDuration: 0.15, thenDragTo: p(0.6, 0.6))
        sleep(1)
        tapPaletteTool(app, group: "Sketch", label: "Circle")
        let label = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        let before = label.frame, value = label.label
        let radial = app.descendants(matching: .any)
            .matching(identifier: "SketchCircleRadiusHandle").firstMatch
        XCTAssertTrue(radial.waitForExistence(timeout: 3))
        // The circle handle anchor is 30 points beyond its top rim. Save the
        // painted rim coordinate before Undo clears selection and the handle.
        let reselect = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: radial.frame.midX - window.frame.minX,
            dy: radial.frame.midY - window.frame.minY + 30
        ))
        let mode = app.buttons["SketchTransformMode"]
        mode.tap()
        let y = app.buttons["SketchTransform-y"]
        XCTAssertTrue(y.waitForExistence(timeout: 3))
        y.tap()
        XCTAssertTrue(app.textFields["SketchTransformField"].waitForExistence(timeout: 3))
        app.buttons["Keypad-1"].tap()
        app.buttons["SketchTransformCancel"].tap()
        mode.tap()
        XCTAssertEqual(label.frame.midY, before.midY, accuracy: 3)
        mode.tap()
        y.tap()
        app.buttons["Keypad-1"].tap()
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(app.buttons["SketchTransformValue-y"].waitForExistence(timeout: 3))
        app.buttons["UndoButton"].tap()
        sleep(1)
        XCTAssertEqual(mode.label, "Done")
        XCTAssertFalse(app.buttons["SketchTransformValue-y"].exists)
        XCTAssertFalse(y.exists)
        XCTAssertFalse(app.buttons["ConstraintRailSettings"].exists)
        reselect.tap()
        XCTAssertTrue(y.waitForExistence(timeout: 3), "Reselection must resume the armed transform")
        XCTAssertEqual(mode.label, "Done")
        mode.tap()
        XCTAssertTrue(app.buttons["ConstraintRailSettings"].waitForExistence(timeout: 3))
        XCTAssertEqual(label.frame.midY, before.midY, accuracy: 3)
        app.buttons["RedoButton"].tap()
        XCTAssertEqual(mode.label, "Move/Rotate")
        XCTAssertEqual(label.label, value)
        XCTAssertEqual(label.frame.midX, before.midX, accuracy: 3)
        XCTAssertLessThan(label.frame.midY, before.midY - 20)
        attach(app, "sketch-typed-y-move-diameter-preserved")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.frame.midY, before.midY, accuracy: 3)
        app.buttons["RedoButton"].tap()
        XCTAssertLessThan(label.frame.midY, before.midY - 20)
    }

    func testCircleExplicitCenterMoveRemainsClearOfDiameterButton() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Circle")
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.5, 0.6).press(forDuration: 0.15, thenDragTo: p(0.6, 0.6))
        tapPaletteTool(app, group: "Sketch", label: "Circle")
        let label = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        let value = label.label
        let original = label.frame
        let mode = app.buttons["SketchTransformMode"]
        mode.tap()
        XCTAssertFalse(label.exists, "Free diameter readout is hidden during explicit Move/Rotate")
        p(0.5, 0.6).press(forDuration: 0.3, thenDragTo: p(0.5, 0.5))
        XCTAssertFalse(app.textFields["DimensionField"].exists)
        mode.tap()
        XCTAssertEqual(label.label, value)
        XCTAssertLessThan(label.frame.midY, original.midY - 50, "Painted center must actually move the circle")
        attach(app, "circle-painted-center-moved-diameter-retained")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.frame.midY, original.midY, accuracy: 3)
        app.buttons["RedoButton"].tap()
        XCTAssertLessThan(label.frame.midY, original.midY - 50)
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
    }

    func testArcCopyRetainsExplicitTransformMode() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Arc")
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.3, 0.55).press(forDuration: 0.15, thenDragTo: p(0.65, 0.55))
        p(0.48, 0.42).tap()
        sleep(1)
        if app.buttons["KeypadCommit"].exists { app.buttons["KeypadCommit"].tap() }
        sleep(1)
        tapPaletteTool(app, group: "Sketch", label: "Arc")
        // Committing the third point does not select the saved arc. The point
        // used to define it is guaranteed to lie on the resulting curve.
        p(0.48, 0.42).tap()
        sleep(1)
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        let radius = labels.matching(NSPredicate(format: "label BEGINSWITH %@", "R")).firstMatch
        XCTAssertTrue(radius.waitForExistence(timeout: 3))
        let originalRadius = radius.label
        let radialHandle = app.descendants(matching: .any).matching(identifier: "SketchArcRadiusHandle").firstMatch
        app.buttons["SketchCopyBadge"].tap()
        XCTAssertFalse(radialHandle.exists)
        // Explicit arc transform uses its visible bounds center: halfway
        // between the 45-degree sagitta and the chord, not circle center.
        let centerY = 0.485
        p(0.475, centerY).press(forDuration: 0.2, thenDragTo: p(0.595, centerY))
        sleep(1)
        XCTAssertEqual(app.buttons["SketchTransformMode"].label, "Done")
        XCTAssertFalse(radialHandle.exists, "Copy must not dismiss explicit Move/Rotate")
        XCTAssertFalse(radius.exists, "Free arc radius is hidden during the explicit Copy transform")
        attach(app, "arc-copy-transform-retained")
        app.buttons["SketchTransformMode"].tap()
        XCTAssertTrue(radialHandle.waitForExistence(timeout: 3))
        XCTAssertEqual(radius.label, originalRadius)
        let copiedFrame = radialHandle.frame
        app.buttons["UndoButton"].tap() // copied arc translation
        sleep(1)
        XCTAssertLessThan(radialHandle.frame.midX, copiedFrame.midX - 20,
                          "Undo must restore the copied arc to its original location")
        app.buttons["RedoButton"].tap()
        sleep(1)
        XCTAssertEqual(radialHandle.frame.midX, copiedFrame.midX, accuracy: 2)
    }

    func testArcTwoTapEndpointsExposeEditableCommittedArc() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Arc")
        sleep(1) // settle the final Look at Sketch transition before tap acquisition
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.3, 0.55).tap()
        sleep(1)
        p(0.65, 0.55).tap()
        sleep(1)
        attach(app, "arc-two-tap-pending")
        let live = app.staticTexts.matching(identifier: "LiveDimension")
        XCTAssertEqual(live.count, 2, "a pending arc shows radius and sweep")
        XCTAssertTrue(live.matching(NSPredicate(format: "label BEGINSWITH %@", "R")).firstMatch.exists)
        XCTAssertTrue(live.matching(NSPredicate(format: "label CONTAINS %@", "°")).firstMatch.exists)
        p(0.48, 0.35).tap()
        sleep(1)
        tapPaletteTool(app, group: "Sketch", label: "Arc")
        sleep(1)
        p(0.48, 0.35).tap()
        sleep(1)
        attach(app, "arc-two-tap-reselected")
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        let radius = labels.matching(NSPredicate(format: "label BEGINSWITH %@", "R")).firstMatch
        XCTAssertTrue(radius.waitForExistence(timeout: 3))
        XCTAssertTrue(labels.matching(NSPredicate(format: "label CONTAINS %@", "°")).firstMatch.exists)
        radius.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
        attach(app, "arc-two-tap-radius-editor")
    }

    func testArcSweepBadgeEditAndUndoRetainRadius() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Arc")
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.3, 0.55).press(forDuration: 0.15, thenDragTo: p(0.65, 0.55))
        p(0.48, 0.42).tap()
        sleep(1)
        if app.buttons["KeypadCommit"].exists { app.buttons["KeypadCommit"].tap() }
        sleep(1)
        tapPaletteTool(app, group: "Sketch", label: "Arc")
        // The third-point definition point remains on the saved arc and is a
        // stable reselection target for this fixture.
        let bulgeY: CGFloat = 0.42
        p(0.48, bulgeY).tap()
        sleep(1)
        attach(app, "arc-selected-before-sweep-editor")
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        let angle = labels.matching(NSPredicate(format: "label CONTAINS %@", "°")).firstMatch
        let radius = labels.matching(NSPredicate(format: "label BEGINSWITH %@", "R")).firstMatch
        XCTAssertTrue(angle.waitForExistence(timeout: 3))
        XCTAssertTrue(radius.exists)
        let beforeAngle = angle.label
        let undrivenRadius = radius.label
        let handle = app.descendants(matching: .any).matching(identifier: "SketchArcRadiusHandle").firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        let arcRimY = window.frame.minY + window.frame.height * bulgeY
        XCTAssertGreaterThan(abs(handle.frame.midY - arcRimY), 5,
                          "Radial handle must remain visibly separated from the arc")
        let grab = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grab.press(forDuration: 0.15, thenDragTo: grab.withOffset(CGVector(dx: 0, dy: 40)))
        sleep(1)
        XCTAssertNotEqual(radius.label, undrivenRadius)
        XCTAssertEqual(angle.label, beforeAngle)
        attach(app, "arc-radial-handle-resize")
        app.buttons["UndoButton"].tap()
        sleep(1)
        XCTAssertEqual(radius.label, undrivenRadius)
        radius.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
        app.buttons["Keypad-2"].tap()
        app.buttons["KeypadCommit"].tap()
        sleep(1)
        XCTAssertEqual(angle.label, beforeAngle)
        XCTAssertTrue(radius.label.contains("2"))
        attach(app, "arc-radius-two-sweep-retained")
        let beforeRadius = radius.label
        let drivenGrab = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        drivenGrab.press(forDuration: 0.15, thenDragTo: drivenGrab.withOffset(CGVector(dx: 0, dy: 40)))
        XCTAssertEqual(radius.label, beforeRadius)
        XCTAssertTrue(app.staticTexts["Locked or constrained sketch parts can't be moved."].exists)
        let transformMode = app.buttons["SketchTransformMode"]
        transformMode.tap()
        XCTAssertFalse(handle.exists)
        transformMode.tap()
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        angle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
        app.buttons["Keypad-9"].tap(); app.buttons["Keypad-0"].tap()
        app.buttons["KeypadCommit"].tap()
        sleep(1)
        attach(app, "arc-sweep-90-radius-retained")
        XCTAssertTrue(angle.label.contains("90"))
        XCTAssertEqual(radius.label, beforeRadius)
        app.buttons["UndoButton"].tap()
        sleep(1)
        XCTAssertEqual(angle.label, beforeAngle)
        XCTAssertEqual(radius.label, beforeRadius)
        app.buttons["RedoButton"].tap()
        sleep(1)
        XCTAssertTrue(angle.label.contains("90"))
        XCTAssertEqual(radius.label, beforeRadius)
        angle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
        for digit in ["3", "6", "0"] { app.buttons["Keypad-\(digit)"].tap() }
        app.buttons["KeypadCommit"].tap()
        sleep(1)
        let diameter = labels.matching(NSPredicate(format: "label BEGINSWITH %@", "Ø")).firstMatch
        XCTAssertTrue(diameter.exists)
        XCTAssertFalse(angle.exists)
        attach(app, "full-turn-converted-circle")
        app.buttons["UndoButton"].tap()
        sleep(1)
        XCTAssertTrue(angle.label.contains("90"))
        XCTAssertEqual(radius.label, beforeRadius)
        app.buttons["RedoButton"].tap()
        sleep(1)
        XCTAssertTrue(diameter.exists)
        XCTAssertFalse(angle.exists)
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

    // MARK: - Circle diameter dimension

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

        // Native release retains diameter without forcing numeric entry.
        p(0.50, 0.50).press(forDuration: 0.15, thenDragTo: p(0.63, 0.50))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.label.hasPrefix("Ø"))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists,
                       "Circle release must not auto-open the keypad")
        attach(app, "circle-release-readout")
        tapPaletteTool(app, group: "Sketch", label: "Circle")
        sleep(1)
        let radial = app.descendants(matching: .any).matching(identifier: "SketchCircleRadiusHandle").firstMatch
        XCTAssertTrue(radial.waitForExistence(timeout: 3))
        let circleRimY = window.frame.minY + window.frame.height * 0.50 - window.frame.width * 0.13
        XCTAssertLessThan(radial.frame.midY, circleRimY - 5,
                          "Radial handle must sit above the circle rim, clear of diameter text")
        let originalDiameter = app.buttons["DimensionLabel"].firstMatch.label
        let grab = radial.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grab.press(forDuration: 0.15, thenDragTo: grab.withOffset(CGVector(dx: 0, dy: -40)))
        sleep(1)
        XCTAssertNotEqual(app.buttons["DimensionLabel"].firstMatch.label, originalDiameter)
        attach(app, "circle-radial-resize")
        app.buttons["UndoButton"].tap()
        sleep(1)
        XCTAssertEqual(app.buttons["DimensionLabel"].firstMatch.label, originalDiameter)

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
        tapPaletteTool(app, group: "Constrain", label: "Dimension")
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3),
                      "Palette entry must reopen the stored diameter, not an invisible candidate")
        XCTAssertEqual(app.textFields["DimensionField"].firstMatch.value as? String, "10")
        setDimension(app, to: "8")
        XCTAssertEqual(app.buttons["DimensionLabel"].firstMatch.label, "Ø8 mm")
        XCTAssertTrue(app.staticTexts["4.00 mm"].waitForExistence(timeout: 3))
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(app.buttons["DimensionLabel"].firstMatch.label, "Ø10 mm")
        attach(app, "circle-palette-existing-dimension-reedit-history")
    }

    func testDimensionLockActsImmediatelyAndRejectsEditedDraft() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Circle")
        let center = window.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.65))
        center.press(forDuration: 0.15, thenDragTo:
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.60)))
        sleep(1) // release selection must settle before disarming the draw tool
        tapPaletteTool(app, group: "Sketch", label: "Circle")
        setDimension(app, to: "1")
        let label = app.buttons["DimensionLabel"].firstMatch
        let radialBeforeLock = app.descendants(matching: .any)
            .matching(identifier: "SketchCircleRadiusHandle").firstMatch
        XCTAssertTrue(radialBeforeLock.waitForExistence(timeout: 3))
        let reselect = circleLeftRim(app, window: window, radial: radialBeforeLock)
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let field = app.textFields["DimensionField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let lock = app.buttons["KeypadLock"]
        XCTAssertTrue(lock.isEnabled)
        app.buttons["Keypad-2"].tap()
        XCTAssertEqual(field.value as? String, "2")
        XCTAssertFalse(lock.isEnabled, "Uncommitted size must not toggle a saved dimension")
        attach(app, "dimension-lock-disabled-for-draft")
        app.buttons["KeypadDelete"].tap()
        app.buttons["Keypad-1"].tap()
        XCTAssertTrue(lock.isEnabled)
        lock.tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 3), "Unlock acts without Commit")
        XCTAssertTrue(label.waitForNonExistence(timeout: 3), "Native clears selection after lock action")
        sleep(1)
        reselect.tap()
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertEqual(label.label, "Ø1 mm")
        let radial = app.descendants(matching: .any).matching(identifier: "SketchCircleRadiusHandle").firstMatch
        XCTAssertTrue(radial.waitForExistence(timeout: 3))
        let grab = radial.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grab.press(forDuration: 0.15, thenDragTo: grab.withOffset(CGVector(dx: 0, dy: -40)))
        sleep(1)
        XCTAssertNotEqual(label.label, "Ø1 mm", "Immediate unlock must actually free radial sizing")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.label, "Ø1 mm")
        attach(app, "dimension-unlocked-free-resize-undo")
    }

    func testNearRailCircleDiameterTargetRemainsReachable() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Circle")
        let center = window.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.65))
        center.press(forDuration: 0.15, thenDragTo:
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.60)))
        sleep(1) // release selection must settle before disarming the draw tool
        tapPaletteTool(app, group: "Sketch", label: "Circle")
        let label = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        let rail = app.buttons["ConstraintRailDisconnect"]
        XCTAssertTrue(rail.exists)
        XCTAssertLessThan(label.frame.maxX, rail.frame.minX,
                          "The complete diameter touch target must clear side controls")
        attach(app, "near-rail-circle-outside-diameter")
        let before = label.label
        setDimension(app, to: "1")
        XCTAssertEqual(label.label, "Ø1 mm")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.label, before)
        app.buttons["RedoButton"].tap()
        XCTAssertEqual(label.label, "Ø1 mm")
        let initial = label.frame
        let grab = label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grab.press(forDuration: 0.15, thenDragTo: grab.withOffset(CGVector(dx: -160, dy: 50)))
        sleep(1)
        XCTAssertEqual(label.label, "Ø1 mm", "Moving annotation must not resize circle")
        XCTAssertFalse(app.textFields["DimensionField"].exists, "Dragging must not open keypad")
        XCTAssertLessThan(label.frame.midX, initial.midX - 70)
        let moved = label.frame
        let radial = app.descendants(matching: .any)
            .matching(identifier: "SketchCircleRadiusHandle").firstMatch
        XCTAssertTrue(radial.waitForExistence(timeout: 3))
        // The circle was drawn with a vertical radius of 5% of the window
        // height. Reselect its painted left rim, away from the top radial
        // control and the moved diameter annotation.
        let reselect = circleLeftRim(app, window: window, radial: radial)
        attach(app, "driven-circle-label-repositioned")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(label.frame.midX, initial.midX, accuracy: 3)
        app.buttons["RedoButton"].tap()
        XCTAssertEqual(label.frame.midX, moved.midX, accuracy: 3)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.75)).tap()
        XCTAssertTrue(label.waitForNonExistence(timeout: 3))
        sleep(1) // settle the label/gesture teardown before the next touch
        attach(app, "circle-label-deselected-before-reselect")
        // Painted left rim, away from the top radial-control region; live
        // top and left reselect both work, but the original immediate top tap
        // failed to acquire selection in this XCTest sequence.
        reselect.tap()
        attach(app, "circle-label-after-reselect-touch")
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertEqual(label.frame.midX, moved.midX, accuracy: 3)
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].waitForExistence(timeout: 3))
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

    /// Click-away must accept, not silently discard, a typed dimension. It
    /// consumes the canvas tap, so no additional drawing operation is created.
    func testDimensionClickAwayAndToolSwitchCommitDraft() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        startGroundSketch(app, window: window, tool: "Line")
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        p(0.34, 0.50).press(forDuration: 0.15, thenDragTo: p(0.62, 0.50))
        let badge = app.buttons["DimensionLabel"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3))
        let original = badge.label
        badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Keypad-+"].tap()
        p(0.70, 0.70).tap()
        let invalidField = app.textFields["DimensionField"].firstMatch
        let invalidDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: invalidField)
        XCTAssertEqual(XCTWaiter.wait(for: [invalidDismissed], timeout: 3), .completed)
        XCTAssertEqual(badge.label, original, "Invalid click-away preserves geometry")
        XCTAssertTrue(app.staticTexts["EditorNotice"].exists)
        attach(app, "invalid-click-away-preserves-geometry")
        badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Keypad-3"].tap()
        XCTAssertEqual(app.textFields["DimensionField"].firstMatch.value as? String, "3")
        attach(app, "before-click-away")
        p(0.70, 0.70).tap()
        let field = app.textFields["DimensionField"].firstMatch
        // Viewport single tap waits for its double-tap recognizer to fail.
        let dismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: field)
        let result = XCTWaiter.wait(for: [dismissed], timeout: 3)
        attach(app, "after-click-away")
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(badge.label, "3 mm")
        attach(app, "click-away-committed-three")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(badge.label, original, "One undo restores the pre-edit geometry")
        app.buttons["RedoButton"].tap()
        XCTAssertEqual(badge.label, "3 mm")
        badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Keypad-4"].tap()
        startSketchTool(app, "Circle")
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        XCTAssertEqual(badge.label, "4 mm", "Tool switch accepts the pending value")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(badge.label, "3 mm")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(badge.label, original)
        app.buttons["UndoButton"].tap()
        XCTAssertFalse(app.buttons["UndoButton"].isEnabled,
                       "Draw plus two edits only: click-away must not add a stray point")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
