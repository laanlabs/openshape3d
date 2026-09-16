//
//  SheetDetentTapUITests.swift
//  openshape3dUITests
//
//  Tap probe for sheets at their medium detent. Each test opens one sheet
//  WITHOUT swiping (a swipe up expands a medium sheet and hides the bug),
//  then taps one control 15 times at a fixed window point (an element tap
//  may scroll, which would also expand the sheet) and records whether each
//  tap took. The control is the one nearest the sheet's bottom edge, except
//  where a test says otherwise.
//
//  A diagnostic, not part of the regular suite (≈15 min). The constraint
//  sheet cases check #40 (that sheet opens full height, so they pass); on a
//  tree from before it (de2f65f) they are the positive controls that show
//  the probe catches lost taps. Run it on purpose:
//
//      TEST_RUNNER_OS3D_SHEET_PROBE=1 xcodebuild test … \
//          -only-testing:openshape3dUITests/SheetDetentTapUITests
//
//  Each trial prints `SHEETPROBE <sheet> trial i/15 took|LOST`; findings are
//  in docs/STATUS_AND_NEXT_STEPS.md (2026-09-15, medium-detent sheets).
//

import XCTest

final class SheetDetentTapUITests: XCTestCase {

    private static let trials = 15

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OS3D_SHEET_PROBE"] == "1",
                          "diagnostic probe; set TEST_RUNNER_OS3D_SHEET_PROBE=1 to run it")
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Harness

    private func launch(seeded: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        if seeded { app.launchEnvironment["OS3D_DEBUG_SEED"] = "1" }
        app.launch()
        return app
    }

    private func poll(_ timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            usleep(100_000)
        } while Date() < end
        return condition()
    }

    private func tap(_ app: XCUIApplication, at point: CGPoint) {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y)).tap()
    }

    /// Opens main Settings on either device. On an iPad the gear is in the
    /// editor's toolbar. On a phone the toolbar folds into a "…" menu, and
    /// the Settings row there has no `SettingsButton` identifier, so it is
    /// found by its title (gotcha 58).
    private func openSettings(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10), "editor should be up")
        let gear = app.buttons["SettingsButton"]
        if gear.exists && gear.isHittable {
            gear.tap()
        } else {
            let overflow = app.navigationBars.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'more'")).firstMatch
            XCTAssertTrue(overflow.waitForExistence(timeout: 5), "the toolbar should offer a \"…\" menu")
            overflow.tap()
            let row = app.buttons["Settings"].firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5), "Settings should be in the \"…\" menu")
            row.tap()
        }
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should open")
    }

    /// Opens the constraint settings sheet from an active sketch. The
    /// regular-width rail has a gear (`ConstraintRailSettings`); at compact
    /// width the rail is a menu (`ConstraintRailMenu`) whose "Constraint
    /// Settings" row is found by its title.
    private func openConstraintSettings(_ app: XCUIApplication) {
        let gear = app.buttons["ConstraintRailSettings"]
        let menu = app.buttons["ConstraintRailMenu"]
        XCTAssertTrue(poll(5) { gear.exists || menu.exists }, "the constraint rail should be up")
        if gear.exists {
            gear.tap()
        } else {
            menu.tap()
            let row = app.buttons["Constraint Settings"].firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 3), "the rail menu should offer Constraint Settings")
            row.tap()
        }
    }

    /// The point on a Form switch row that lands on the switch itself.
    private func switchPoint(_ row: XCUIElement) -> CGPoint {
        let f = row.frame
        return CGPoint(x: f.minX + f.width * 0.91, y: f.midY)
    }

    private func shoot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Runs the trials. `fire` taps the target once; `landed` reports whether
    /// that tap took; `reset` restores the state for the next trial.
    private func probe(_ app: XCUIApplication, sheet: String, navTitle: String,
                       fire: () -> Void, landed: () -> Bool,
                       reset: (Bool) -> Void) {
        let grabber = app.buttons["Sheet Grabber"]
        let nav = app.navigationBars[navTitle]
        XCTAssertTrue(nav.waitForExistence(timeout: 5), "\(sheet): sheet should be up")
        sleep(1)
        let startTop = nav.frame.minY
        shoot(app, "\(sheet)-start")
        var lost = 0
        var grew = 0
        for trial in 1...Self.trials {
            let grabberState = grabber.exists ? (grabber.value as? String ?? "?") : "none"
            let top = nav.frame.minY
            if abs(top - startTop) > 1 { grew += 1 }
            fire()
            let took = poll(2.5, landed)
            if !took { lost += 1 }
            print("SHEETPROBE \(sheet) trial \(trial)/\(Self.trials) "
                  + (took ? "took" : "LOST") + " grabber=\(grabberState) top=\(top)")
            if !took { shoot(app, "\(sheet)-lost-\(trial)") }
            reset(took)
            usleep(600_000)
        }
        shoot(app, "\(sheet)-end")
        print("SHEETPROBE-SUMMARY \(sheet) lost \(lost) of \(Self.trials); "
              + "sheet moved off its first stop on \(grew) trials")
        XCTAssertEqual(grew, 0, "\(sheet): the sheet must stay at its first stop")
        XCTAssertEqual(lost, 0, "\(sheet): lost \(lost) of \(Self.trials) taps")
    }

    /// A Form switch: each tap must flip its value.
    private func probeSwitch(_ app: XCUIApplication, sheet: String, navTitle: String,
                             identifier: String) {
        let row = app.switches[identifier].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        // A switch below the fold is not a lost tap: a tap there misses the
        // sheet. Fail loudly rather than record 15 false losses.
        guard row.frame.maxY <= app.windows.firstMatch.frame.maxY + 1 else {
            XCTFail("\(sheet): the switch is below the fold (row \(row.frame)); nothing to probe")
            return
        }
        let point = switchPoint(row)
        var before = row.value as? String
        probe(app, sheet: sheet, navTitle: navTitle,
              fire: { before = row.value as? String; tap(app, at: point) },
              landed: { row.value as? String != before },
              reset: { _ in })
    }

    /// A Form menu picker: each tap must open its menu; picking the other
    /// option closes it.
    private func probeMenuPicker(_ app: XCUIApplication, sheet: String, navTitle: String,
                                 picker: XCUIElement, options: [String]) {
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        let point = CGPoint(x: picker.frame.midX, y: picker.frame.midY)
        var next = 1
        probe(app, sheet: sheet, navTitle: navTitle,
              fire: { tap(app, at: point) },
              landed: { app.buttons[options[next]].exists },
              reset: { took in
                  guard took else { return }
                  app.buttons[options[next]].tap()
                  XCTAssertTrue(poll(2) { picker.label.hasSuffix(options[next]) },
                                "\(sheet): picking \(options[next]) should stick")
                  next = (next + 1) % options.count
              })
    }

    // MARK: - [.medium, .large] sheets

    /// The sheet the 2026-09-15 diagnostic caught. A positive control on a
    /// tree that still gives it a medium detent (it lost 17 of 60 taps);
    /// since #40 it opens full height and should lose none.
    func testConstraintSettingsGridSwitch() {
        let app = launch(seeded: false)
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        openConstraintSettings(app)
        probeSwitch(app, sheet: "constraint", navTitle: "Constraints",
                    identifier: "SnapToGridToggle")
    }

    /// Same sheet, the switch at the TOP of the form (well clear of the
    /// bottom edge): tells a bottom-edge effect from a switch-in-a-resizable-
    /// sheet effect.
    func testConstraintSettingsTopSwitch() {
        let app = launch(seeded: false)
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        openConstraintSettings(app)
        probeSwitch(app, sheet: "constraint-top", navTitle: "Constraints",
                    identifier: "AlwaysShowDimensionsToggle")
    }

    /// Main Settings at medium: the lowest control above the fold is the
    /// Circular Annotations menu (the snapping switches are below it).
    func testSettingsCircularAnnotationsPicker() {
        let app = launch(seeded: false)
        openSettings(app)
        probeMenuPicker(app, sheet: "settings", navTitle: "Settings",
                        picker: app.buttons["SettingsCircularAnnotations"],
                        options: ["Radius and Diameter", "Always Radius"])
    }

    /// Main Settings at medium, its Grid switch, where the medium stop shows
    /// it at all. The iPad's card does not (the test skips there). A phone's
    /// half-height sheet may; Settings opens there through the "…" menu
    /// since #44 (before that it could not be opened on a phone at all).
    func testSettingsGridSwitch() throws {
        let app = launch(seeded: false)
        openSettings(app)
        sleep(1)
        let row = app.switches["SnapToGridToggle"].firstMatch
        let form = app.collectionViews.firstMatch
        // A point of slack. On a phone the Grid row sits flush with the
        // sheet's bottom edge at medium: its frame and the form's both end at
        // 948 pt, but on opposite sides of a 1e-13 floating-point hairline,
        // which skipped this test with the switch plainly on screen
        // (2026-09-16).
        let visible = row.exists && row.frame.maxY <= form.frame.maxY + 1
            && row.frame.maxY <= app.windows.firstMatch.frame.maxY + 1
        print("SHEETPROBE settings-grid row=\(row.exists ? "\(row.frame)" : "absent") "
              + "form=\(form.frame)")
        try XCTSkipUnless(visible, "the Grid switch is below the fold at medium here")
        probeSwitch(app, sheet: "settings-grid", navTitle: "Settings",
                    identifier: "SnapToGridToggle")
    }

    /// Main Settings at medium, the Units segmented control (top of the
    /// form). Like a switch it tracks drags itself, which is what the lost
    /// constraint-sheet taps have in common.
    func testSettingsUnitsSegment() {
        let app = launch(seeded: false)
        openSettings(app)
        let picker = app.segmentedControls["SettingsUnitPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        let segments = [picker.buttons["cm"], picker.buttons["mm"]]
        let points = segments.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        var next = 0
        probe(app, sheet: "settings-units", navTitle: "Settings",
              fire: { tap(app, at: points[next]) },
              landed: { segments[next].isSelected },
              reset: { took in if took { next = 1 - next } })
    }

    /// Material at medium: the Color row sits on the bottom edge (the
    /// sliders are below the fold). Each tap must open the colour picker.
    func testMaterialColorPicker() {
        let app = launch(seeded: true)
        let button = app.buttons["MaterialButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        let row = app.buttons["MaterialColorPicker"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        // The well is the circle at the row's trailing end.
        let point = CGPoint(x: row.frame.maxX - 14, y: row.frame.midY)
        let applyFrame = app.buttons["MaterialApply"].frame
        // The system colour picker opens as a popover with Grid / Spectrum /
        // Sliders tabs and no close button.
        let spectrum = app.buttons["Spectrum"]
        probe(app, sheet: "material", navTitle: "Material",
              fire: { tap(app, at: point) },
              landed: { spectrum.exists },
              reset: { took in
                  guard took else { return }
                  // Outside the popover (it opens below the bar), inside the
                  // sheet's bar: dismisses only the popover.
                  tap(app, at: CGPoint(x: applyFrame.minX - 150, y: applyFrame.midY))
                  XCTAssertTrue(poll(3) { !spectrum.exists }, "material: colour picker should close")
              })
    }

    /// Gallery "Move to Folder" at medium: F04 is the last whole row above
    /// the bottom edge. A tap that takes moves the design and closes the
    /// sheet; the design is then moved back to the root for the next trial.
    func testGalleryMovePickerBottomRow() {
        let app = launch(seeded: false)
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        app.buttons["Designs"].firstMatch.tap()
        XCTAssertTrue(app.buttons["NewFolderButton"].waitForExistence(timeout: 5))
        for index in 1...5 {
            app.buttons["NewFolderButton"].tap()
            fillAlert(app, title: "New Folder", text: String(format: "F%02d", index), confirm: "Create")
        }
        // Select mode, not the card's context menu: after a long-press the
        // app never reports idle, and each menu cost XCUITest a 60 s wait.
        // A pick leaves select mode by itself.
        func openPicker() {
            let select = app.buttons["SelectProjectsButton"]
            XCTAssertTrue(select.waitForExistence(timeout: 5))
            select.tap()
            let card = app.staticTexts["Untitled"]
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            card.tap()
            let move = app.buttons["MoveSelectedButton"]
            XCTAssertTrue(poll(3) { move.isEnabled })
            move.tap()
            XCTAssertTrue(app.buttons["MovePickCancel"].waitForExistence(timeout: 3))
            sleep(1)
        }
        openPicker()
        let row = app.buttons["MovePick-F04"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        let point = CGPoint(x: row.frame.midX, y: row.frame.midY)
        let cancel = app.buttons["MovePickCancel"]
        probe(app, sheet: "gallerymove", navTitle: "Move to Folder",
              fire: { tap(app, at: point) },
              landed: { !cancel.exists },
              reset: { took in
                  if took {
                      // Bring the design back: into F04, move it to the root.
                      app.buttons["SidebarFolder-F04"].tap()
                      openPicker()
                      app.buttons["MovePickRoot"].tap()
                      XCTAssertTrue(poll(3) { !cancel.exists }, "move back should close the sheet")
                      app.buttons["SidebarRoot"].tap()
                  } else {
                      cancel.tap()
                      XCTAssertTrue(poll(3) { !cancel.exists })
                      app.buttons["CancelSelectButton"].tap()
                  }
                  openPicker()
              })
    }

    // MARK: - [.medium] sheets (one stop, no grabber)

    func testTextFontPicker() {
        let app = launch(seeded: false)
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Text")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Tap to place text"].waitForExistence(timeout: 3))
        sleep(2)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.70)).tap()
        XCTAssertTrue(app.textFields["TextContentField"].waitForExistence(timeout: 3))
        probeMenuPicker(app, sheet: "text", navTitle: "Text",
                        picker: app.buttons["TextFontPicker"],
                        options: ["Helvetica", "Georgia"])
    }

    func testHelixTurnsField() {
        let app = launch(seeded: false)
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.34, dy: 0.40))
            .press(forDuration: 0.15, thenDragTo:
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.56)))
        app.buttons["Exit Sketching"].tap()
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.41, dy: 0.48)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        app.buttons["Helix"].firstMatch.tap()
        let turns = app.textFields["HelixTurns"]
        XCTAssertTrue(turns.waitForExistence(timeout: 3))
        // The tappable box is the 90 pt field at the row's trailing end.
        let point = CGPoint(x: turns.frame.maxX - 45, y: turns.frame.midY)
        let pad = app.buttons["KeypadCommit"]
        probe(app, sheet: "helix", navTitle: "Helix",
              fire: { tap(app, at: point) },
              landed: { pad.exists },
              reset: { took in
                  guard took else { return }
                  pad.tap()
                  XCTAssertTrue(poll(3) { !pad.exists }, "helix: the pad should close")
              })
    }

    func testScreenshotGridSwitch() {
        let app = launch(seeded: true)
        let menu = app.buttons["ExportMenu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()
        let entry = app.buttons["PNG Screenshot…"]
        XCTAssertTrue(entry.waitForExistence(timeout: 3))
        entry.tap()
        probeSwitch(app, sheet: "screenshot", navTitle: "Screenshot",
                    identifier: "ScreenshotGrid")
    }

    func testMeshExportPerBodySwitch() {
        let app = launch(seeded: true)
        let menu = app.buttons["ExportMenu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()
        XCTAssertTrue(app.buttons["GLB"].waitForExistence(timeout: 3))
        app.buttons["GLB"].tap()
        probeSwitch(app, sheet: "meshexport", navTitle: "GLB Export",
                    identifier: "ExportPerBodyToggle")
    }

    private func fillAlert(_ app: XCUIApplication, title: String, text: String, confirm: String) {
        let alert = app.alerts[title]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "\(title) alert should appear")
        let field = alert.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        let existing = ((field.value as? String) ?? "").count + 2
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing))
        field.typeText(text)
        alert.buttons[confirm].tap()
    }
}
