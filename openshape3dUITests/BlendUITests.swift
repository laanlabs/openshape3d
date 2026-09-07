//
//  BlendUITests.swift
//  openshape3dUITests
//
//  Phase E tranche 1: drive Chamfer/Fillet end to end — extrude a box, arm the
//  tool, tap an edge, Apply, and verify a healthy feature lands in History.
//

import XCTest

final class BlendUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Extrude a plain rectangle on the ground into a box, then view isometric.
    private func extrudeBox(_ app: XCUIApplication, _ window: XCUIElement) {
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        p(0.80, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        p(0.32, 0.32).press(forDuration: 0.15, thenDragTo: p(0.68, 0.62))
        app.buttons["Exit Sketching"].tap(); sleep(1)
        p(0.45, 0.45).tap()   // arm extrude on the region
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app); sleep(1)
        app.buttons["ViewsMenu"].tap()
        app.buttons["Isometric"].tap(); sleep(2)
    }

    func testChamferAnEdgeRecordsHealthyFeature() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        extrudeBox(app, window)
        shot("01-box")

        // Arm Chamfer from the Modify group.
        tapPaletteTool(app, group: "Modify", id: "ChamferButton")
        XCTAssertTrue(app.buttons["BlendApply"].waitForExistence(timeout: 3),
                      "the blend bar should appear")
        shot("02-chamfer-armed")

        // Tap the body to pick the nearest edge; Apply enables once an edge is in.
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        let apply = app.buttons["BlendApply"]
        for pt in [(0.5, 0.42), (0.5, 0.5), (0.55, 0.45), (0.45, 0.55)] {
            p(CGFloat(pt.0), CGFloat(pt.1)).tap()
            sleep(1)
            if apply.isEnabled { break }
        }
        XCTAssertTrue(apply.isEnabled, "tapping the body should select an edge and enable Apply")
        shot("03-edge-selected")

        apply.tap(); sleep(2)
        shot("04-after-chamfer")

        // History has a healthy Chamfer feature (no error badge).
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Chamfer'"))
            .firstMatch.waitForExistence(timeout: 3),
            "a Chamfer feature should be recorded")
        let errors = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        NSLog("OS3D_BUG chamfer errorBadges=\(errors.count)")
        XCTAssertEqual(errors.count, 0, "the chamfer must evaluate cleanly")
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled)
    }

    func testFilletAnEdgeRecordsHealthyFeature() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        extrudeBox(app, window)

        tapPaletteTool(app, group: "Modify", id: "FilletButton")
        XCTAssertTrue(app.buttons["BlendApply"].waitForExistence(timeout: 3),
                      "the blend bar should appear for fillet")

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        let apply = app.buttons["BlendApply"]
        for pt in [(0.5, 0.42), (0.5, 0.5), (0.55, 0.45), (0.45, 0.55)] {
            p(CGFloat(pt.0), CGFloat(pt.1)).tap()
            sleep(1)
            if apply.isEnabled { break }
        }
        XCTAssertTrue(apply.isEnabled, "tapping the body should select an edge")
        apply.tap(); sleep(2)
        shot("fillet-after")

        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Fillet'"))
            .firstMatch.waitForExistence(timeout: 3),
            "a Fillet feature should be recorded")
        let errors = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        NSLog("OS3D_BUG fillet errorBadges=\(errors.count)")
        XCTAssertEqual(errors.count, 0, "the fillet must evaluate cleanly")
    }

    func testChamferTwoEdgesInOneFeature() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        extrudeBox(app, window)

        tapPaletteTool(app, group: "Modify", id: "ChamferButton")
        XCTAssertTrue(app.buttons["BlendApply"].waitForExistence(timeout: 3))

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        // Tap around the box until two DISTINCT edges are in (the bar text is
        // the deterministic readout; a repeat tap on the same edge toggles it
        // off, so the loop just keeps going).
        let two = app.staticTexts["2 edges selected"]
        let candidates: [(CGFloat, CGFloat)] = [
            (0.50, 0.42), (0.62, 0.55), (0.45, 0.55),
            (0.55, 0.33), (0.70, 0.45), (0.40, 0.45),
        ]
        for pt in candidates {
            p(pt.0, pt.1).tap()
            sleep(1)
            if two.exists { break }
        }
        XCTAssertTrue(two.exists, "two distinct edges should be selected")
        shot("two-edges-selected")

        app.buttons["BlendApply"].tap(); sleep(2)
        shot("two-edges-chamfered")

        // One Chamfer feature covering BOTH edges, evaluated cleanly.
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Chamfer'"))
            .firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS '2 edges'"))
            .firstMatch.exists, "the history subtitle shows the edge count")
        let errors = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        XCTAssertEqual(errors.count, 0, "the two-edge chamfer must evaluate cleanly")
    }

    func testDragArrowScrubsBlendSize() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        extrudeBox(app, window)

        tapPaletteTool(app, group: "Modify", id: "ChamferButton")
        XCTAssertTrue(app.buttons["BlendApply"].waitForExistence(timeout: 3))

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        // Pick one edge → the drag arrow appears on it.
        p(0.50, 0.42).tap(); sleep(1)
        XCTAssertTrue(app.staticTexts["1 edge selected"].waitForExistence(timeout: 3))
        let field = app.textFields["BlendValueField"]
        let before = (field.value as? String) ?? ""
        XCTAssertTrue(app.pullArrowHandle.waitForExistence(timeout: 3),
                      "the size arrow rides the picked edge")
        shot("drag-armed")

        // Drag the arrow toward the body interior (the way it points) to grow.
        // A SHORT drag, measured from the handle itself. Strokes now start at
        // the touch-down (2026-09-04); before that the pan recognizer only
        // counted the tail of a fast synthetic drag, so the old window-
        // relative target scrubbed ~0.5 mm — the same drag now scrubs the
        // whole ~2.3 mm it always asked for, past what a 2 mm-high box can
        // chamfer (the preview went invalid and Apply correctly disabled).
        // ~0.007 mm per pt along the arrow: 55 pt ≈ +0.4 mm.
        let handleCenter = app.pullArrowHandle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        dragPullArrow(app, to: handleCenter.withOffset(CGVector(dx: 24, dy: 48)), duration: 0.3)
        sleep(1)
        let after = (field.value as? String) ?? ""
        NSLog("OS3D_BUG blendDrag before=\(before) after=\(after)")
        XCTAssertNotEqual(before, after, "dragging the arrow must scrub the size")
        XCTAssertGreaterThan(Double(after.replacingOccurrences(of: ",", with: ".")) ?? 0, 0,
                             "the dragged size stays positive")
        shot("after-drag")

        // The scrubbed size commits like any other.
        let apply = app.buttons["BlendApply"]
        XCTAssertTrue(apply.isEnabled, "a valid dragged size keeps Apply enabled")
        apply.tap(); sleep(2)
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Chamfer'"))
            .firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'")).count, 0)
    }
}
