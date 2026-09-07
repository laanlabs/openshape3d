//
//  PullArrowTestSupport.swift
//  openshape3dUITests
//
//  Shapr3D face push/pull is driven ONLY by the floating pull-arrow handle now
//  (dragging the face itself orbits). These helpers grab that handle by its
//  accessibility identifier so tests stay robust to the camera angle.
//

import XCTest

extension XCUIApplication {
    /// The extrude / push-pull arrow handle overlay (`arrow.up.and.down`).
    var pullArrowHandle: XCUIElement {
        descendants(matching: .any).matching(identifier: "PullArrowHandle").firstMatch
    }
}

extension XCTestCase {
    /// Grab the pull-arrow handle and drag it to `end` to push/pull the selected
    /// face. Only the arrow moves a face, so this replaces face-center drags.
    func dragPullArrow(_ app: XCUIApplication, to end: XCUICoordinate,
                       duration: TimeInterval = 0.15) {
        let handle = app.pullArrowHandle
        XCTAssertTrue(handle.waitForExistence(timeout: 5), "pull-arrow handle should be visible")
        handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: duration, thenDragTo: end)
    }

    // MARK: - Sketch camera

    /// Square the camera up to the active sketch plane.
    ///
    /// Entering a sketch KEEPS the camera where the user left it (Shapr3D
    /// behaviour — you draw on the plane from whatever view you were in), so a
    /// test that drives a sketch by normalized screen coordinates has to face
    /// the plane first; otherwise its taps land somewhere else entirely on the
    /// plane and the geometry it thinks it drew is not the geometry it drew.
    ///
    /// The Look at Sketch button only exists while the camera is off-axis, so
    /// its absence means we are already head-on and there is nothing to do.
    func lookAtSketch(_ app: XCUIApplication, settle: UInt32 = 2) {
        let button = app.buttons["Look at Sketch"]
        if button.waitForExistence(timeout: 3), button.isHittable {
            button.tap()
        }
        sleep(settle) // camera flight
    }

    // MARK: - Context-sensitive palette (Shapr3D-style)
    //
    // Tools now live in flyout groups (Sketch/Modify/Transform/Combine in body
    // mode; Constrain/Symbol while sketching) and sketch tools are hidden outside
    // a sketch. These helpers open the owning group first if the tool isn't
    // already directly reachable, so tests don't care whether a tool is top-level
    // or behind a flyout.

    /// Tap a palette tool found by its visible label (Line/Rect/Circle/Union/…),
    /// opening `group` first if it isn't directly hittable.
    func tapPaletteTool(_ app: XCUIApplication, group: String, label: String) {
        let query = app.buttons.containing(.staticText, identifier: label)
        if !query.firstMatch.isHittable {
            app.buttons[group + "Group"].tap()
            _ = query.firstMatch.waitForExistence(timeout: 2)
        }
        query.firstMatch.tap()
    }

    /// Tap a palette tool found by its accessibility id (TranslateButton,
    /// DimensionButton, …), opening `group` first if needed.
    func tapPaletteTool(_ app: XCUIApplication, group: String, id: String) {
        let btn = app.buttons[id]
        if !btn.isHittable {
            app.buttons[group + "Group"].tap()
            _ = btn.waitForExistence(timeout: 2)
        }
        btn.tap()
    }

    /// Start a sketch by choosing a draw tool from the body-mode Sketch flyout.
    func startSketchTool(_ app: XCUIApplication, _ label: String) {
        tapPaletteTool(app, group: "Sketch", label: label)
    }

    /// Tapping a profile arms Extrude at ZERO height (arrow only, no default
    /// pull) — type a height into the bar's Distance field; submitting
    /// commits the tool.
    func typeExtrudeHeight(_ app: XCUIApplication, _ value: String = "2") {
        let field = app.textFields["Distance"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3),
                      "Extrude Distance field should be visible")
        replaceText(field, with: value)   // onSubmit commits the extrude
    }

    /// Replace a text field's whole contents and submit.
    ///
    /// The rename tests used to do `tap()` + `doubleTap()` + `typeText`,
    /// relying on the double tap to select the existing word so the typed text
    /// replaced it. On this simulator (iOS 26.2) the double tap no longer
    /// selects, so the text was APPENDED — the body really was renamed, just
    /// to "ExtrudeMyPart" instead of "MyPart", and the assertion on the new
    /// name failed while the app was behaving correctly.
    ///
    /// It also matters for the NUMERIC fields, which arrive pre-filled: the
    /// extrude Distance field and the arrow pill both hold the current value,
    /// so typing without clearing produced "0-3" (evaluates to -3 — right by
    /// luck) or "-30" (30 mm into a 4 mm box — refused, no command).
    ///
    /// So: caret to the end, backspace it empty, type, then VERIFY what landed
    /// and retry once. The verify is not belt-and-braces — it fires in real
    /// runs, and without it a mistyped value reaches the tool as a silently
    /// different number.
    func replaceText(_ field: XCUIElement, with text: String, submit: Bool = true) {
        // Numeric fields now open the on-canvas number pad instead of the
        // system keyboard, so there is nothing to type INTO. Drive the pad when
        // it appears; the typing path below still serves the text fields
        // (names, search) that legitimately want a keyboard.
        let app = XCUIApplication()
        field.tap()
        let padDelete = app.buttons["KeypadDelete"]
        if padDelete.waitForExistence(timeout: 2) {
            for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
                padDelete.tap()
            }
            for character in text {
                // The pad has no "-" key: sign is the ± toggle. On an empty
                // field ± yields "-", so a leading minus works positionally.
                let key = character == "-" ? "±" : String(character)
                app.buttons["Keypad-\(key)"].tap()
            }
            XCTAssertEqual(field.value as? String, text,
                           "the pad should hold exactly what was entered")
            if submit { app.buttons["KeypadCommit"].tap() }
            return
        }

        func attempt() {
            // Put the caret at the END, then backspace. Tapping the field's
            // trailing edge lands the caret after the last character, which is
            // what makes plain backspaces reliable — `field.tap()` hits the
            // centre, and at caret position 0 backspaces delete nothing. That
            // is how "-3" typed into a field already holding "0" came out as
            // "-30": 30 mm into a 4 mm box, refused, no command, and a failure
            // ten lines later blaming the commit.
            //
            // The two tidier-looking options are both wrong here:
            //  • ⌘A is the app's own Select All hotkey (CommandRegistry
            //    "edit.selectAll"), so sending it fires that command and leaves
            //    the app non-idle — XCTest then waits 60s for animations on
            //    EVERY field edit, which took the suite from 41 to 78 minutes.
            //  • `XCUIKeyboardKey.forwardDelete` is not interpreted by iOS text
            //    input; it gets typed in as an invisible character, so the field
            //    ends up holding "2\u{F728}…" and compares unequal to "2".
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            let existing = ((field.value as? String) ?? "").count + 2
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing))
            field.typeText(text)
        }
        attempt()
        if (field.value as? String) != text {
            NSLog("OS3D_BUG field held '\((field.value as? String) ?? "<nil>")' "
                  + "after typing '\(text)'; retrying")
            attempt()
        }
        XCTAssertEqual(field.value as? String, text,
                       "the field should hold exactly what was typed before submitting")
        if submit { field.typeText("\n") }
    }
}
