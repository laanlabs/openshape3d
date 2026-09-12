//
//  LineChainUITests.swift
//  openshape3dUITests
//
//  The Shapr3D line workflow: while the Line tool is armed, each tap places the
//  next polyline vertex (extending from the previous point), and a tap back on
//  the start closes the polygon. A closed polygon fills, so tapping inside it
//  arms Extrude — which only happens if the taps chained into one closed loop
//  rather than drawing disconnected single segments.
//

import XCTest

final class LineChainUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func useDefaultLineSnapSettings(_ app: XCUIApplication) {
        // UI tests share the app's UserDefaults across launches. Pin the line
        // construction defaults so the guide-only case cannot make later
        // topology checks order-dependent.
        app.launchArguments += [
            "-os3d.snapToGrid", "YES",
            "-os3d.snapToSketchGuidelines", "YES",
            "-os3d.snapToSketchGuidepoints", "YES",
            "-os3d.snapToFaceGuidepoints", "YES"
        ]
    }

    private func startGroundLineSketch(_ app: XCUIApplication, _ window: XCUIElement) {
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // let the head-on camera animation settle
        lookAtSketch(app)
    }

    func testTapsChainAPolylineAndCloseThePolygon() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        useDefaultLineSnapSettings(app)
        app.launch()
        let window = app.windows.firstMatch
        startGroundLineSketch(app, window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Tap the four corners of a square — each tap extends the chain from the
        // previous vertex — then tap the first corner again to close the loop.
        p(0.42, 0.42).tap()   // A: starts the chain (no segment yet)
        usleep(500_000)
        p(0.60, 0.42).tap()   // B: segment A→B
        usleep(500_000)
        p(0.60, 0.60).tap()   // C: segment B→C
        usleep(500_000)
        p(0.42, 0.60).tap()   // D: segment C→D
        usleep(500_000)
        p(0.42, 0.42).tap()   // back to A: closes with segment D→A
        sleep(1)

        // Four taps after the first produced four chained segments: A→B, B→C,
        // C→D, and the closing D→A. The fourth segment only exists because the
        // tap on the start point closed the loop, so exactly four undo steps
        // proves BOTH that taps extend the polyline AND that it closed. (Five
        // disconnected single lines, or taps that failed to chain, would leave a
        // different count.)
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Chaining the polyline should push undoable steps")
        for step in 1...4 {
            XCTAssertTrue(undo.isEnabled, "Closed-chain Undo step \(step) should exist")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "A tapped-and-closed square is exactly four chained line segments")
    }

    func testReturnFinishesOpenChainThenEndpointStartsAClosableChain() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        useDefaultLineSnapSettings(app)
        app.launch()
        let window = app.windows.firstMatch
        startGroundLineSketch(app, window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // A→B→C is an open two-segment chain. Return must finish only its
        // transient continuation while leaving Line armed and history intact.
        // Use the same grid-separated coordinates as the proven closed-chain
        // workflow. Closer A/B inputs can snap to one grid point, correctly
        // producing no zero-length segment.
        p(0.42, 0.42).tap() // A
        usleep(500_000)
        p(0.60, 0.42).tap() // B
        usleep(500_000)
        p(0.60, 0.60).tap() // C
        sleep(1)

        app.typeKey(.return, modifierFlags: [])

        // Return clears the transient chain but leaves the final B→C segment
        // selected, so its two rendered endpoint markers are the reliable
        // post-inference locations for B and C. Resolve B as the marker nearest
        // the original B input rather than assuming duplicated markers for all
        // selected chain segments.
        let initialMarkers = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(initialMarkers.count, 2)
        let intendedB = p(0.60, 0.42).screenPoint
        let sharedB = initialMarkers.min {
            hypot($0.frame.midX - intendedB.x, $0.frame.midY - intendedB.y)
              < hypot($1.frame.midX - intendedB.x, $1.frame.midY - intendedB.y)
        }!
        let bPoint = CGPoint(x: sharedB.frame.midX, y: sharedB.frame.midY)
        let windowFrame = window.frame
        func screenPoint(_ point: CGPoint) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(
                dx: (point.x - windowFrame.minX) / windowFrame.width,
                dy: (point.y - windowFrame.minY) / windowFrame.height
            ))
        }
        let b = screenPoint(bPoint)
        let d = screenPoint(CGPoint(x: bPoint.x - 100, y: bPoint.y + 180))
        let e = screenPoint(CGPoint(x: bPoint.x - 220, y: bPoint.y + 80))

        // An endpoint tap now starts a fresh chain at B. D→E→B closes a
        // triangle intentionally. Desired history is two old segments plus
        // exactly three resumed segments. If Return did nothing, B extends
        // the old C anchor and leaves six undo entries instead.
        // Keep every point left of the constraint rail so this remains a
        // canvas-routing test rather than a panel-hit test.
        sharedB.tap() // resume at B; no segment yet
        usleep(500_000)
        d.tap() // B→D
        usleep(500_000)
        e.tap() // D→E
        usleep(500_000)
        // B is not part of the currently selected D→E segment, so it is no
        // longer exposed as a marker. Its rendered screen location is stable;
        // tapping the saved coordinate intentionally closes E→B.
        b.tap()
        sleep(1)
        let finalMarkers = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
        let finalShot = XCTAttachment(screenshot: app.screenshot())
        finalShot.name = "return-resume-close-final-\(finalMarkers.count)-markers"
        finalShot.lifetime = .keepAlways
        add(finalShot)

        let undo = app.buttons["UndoButton"]
        for step in 1...5 {
            XCTAssertTrue(undo.isEnabled, "Undo step \(step) should exist")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "Return + endpoint resume should produce exactly five segments")
    }

    func testGuideOnlyDrawingAfterSettingsDismissal() {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        useDefaultLineSnapSettings(app)
        app.launch()
        let window = app.windows.firstMatch
        startGroundLineSketch(app, window)
        app.buttons["ConstraintRailSettings"].tap()
        func setSwitch(_ id: String, on: Bool) {
            let control = app.switches[id].firstMatch
            let form = app.collectionViews.firstMatch
            XCTAssertTrue(form.waitForExistence(timeout: 5))
            func visible() -> Bool {
                control.exists && control.isHittable
                    && form.frame.insetBy(dx: 0, dy: 20).contains(control.frame)
            }
            for _ in 0..<8 where !visible() {
                form.swipeUp()
            }
            XCTAssertTrue(visible(), "\(id): row \(control.frame), form \(form.frame)")
            if (control.value as? String == "1") != on {
                // Hit the visible thumb; row-center taps need not toggle a
                // SwiftUI Form control even when accessibility says hittable.
                control.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            }
            XCTAssertEqual(control.value as? String, on ? "1" : "0", id)
        }
        setSwitch("SnapToGridToggle", on: false)
        setSwitch("SnapToSketchGuidelinesToggle", on: true)
        setSwitch("SnapToSketchGuidepointsToggle", on: false)
        setSwitch("SnapToFaceGuidepointsToggle", on: false)
        setSwitch("AutoConstrainToggle", on: false)
        app.buttons["ConstraintSettingsDone"].tap()
        XCTAssertFalse(app.buttons["ConstraintSettingsDone"].exists)
        let a = window.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.43))
        let b = window.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.432))
        a.press(forDuration: 0.2, thenDragTo: b)
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Guide-only drag must create a real undoable segment")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format:
            "identifier == 'ConstraintGlyph' AND label == 'H'")).firstMatch.exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "guide-only-after-settings"; shot.lifetime = .keepAlways; add(shot)
        undo.tap()
        XCTAssertFalse(undo.isEnabled, "One drag must create exactly one history entry")
        app.buttons["RedoButton"].tap()
        XCTAssertTrue(undo.isEnabled)
    }

}
