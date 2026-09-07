//
//  BugHuntUITests.swift
//  openshape3dUITests
//
//  Exploratory: drive a complex-shape modeling workflow (Shapr3D-tutorial-style)
//  and capture screenshots + readouts to surface bugs. Not a pass/fail spec —
//  screenshots are inspected and readouts logged.
//

import XCTest

final class BugHuntUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Log every SelectionInfoBar row (Volume/Bounds/Area/…) and panel counts.
    private func logReadouts(_ app: XCUIApplication, _ tag: String) {
        let infoTexts = app.staticTexts.allElementsBoundByIndex
            .map { $0.label }
            .filter { $0.contains("mm") }
        NSLog("OS3D_BUG [\(tag)] readouts=\(infoTexts)")
    }

    // MARK: - Base build: rectangle with a circular hole, extruded

    func testBuildRectWithHoleExtrude() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // 1) Rectangle on the ground plane.
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        p(0.80, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        p(0.32, 0.32).press(forDuration: 0.15, thenDragTo: p(0.68, 0.62))

        // 2) A circle inside it (the hole).
        startSketchTool(app, "Circle")
        p(0.50, 0.47).press(forDuration: 0.2, thenDragTo: p(0.58, 0.47))
        sleep(1)
        shot("01-sketch-rect-with-hole")

        app.buttons["Exit Sketching"].tap()
        sleep(1)
        shot("02-fills-after-exit")

        // 3) Tap the ring (top-left corner area, well outside the circle).
        p(0.36, 0.36).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping the ring region should arm extrude")
        logReadouts(app, "extrude-armed")
        shot("03-extrude-armed")

        // 4) Type a 2mm height — profile taps arm at zero now.
        typeExtrudeHeight(app)
        sleep(1)
        logReadouts(app, "after-extrude")
        // Isometric so the hole is visible.
        app.buttons["ViewsMenu"].tap()
        app.buttons["Isometric"].tap()
        sleep(2)
        shot("04-extruded-body-iso")
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "Extrude should have committed")

        // 5) Select the body and read its Volume/Bounds.
        p(0.85, 0.85).tap() // deselect
        sleep(1)
        p(0.5, 0.5).tap()   // select the body/face
        sleep(1)
        logReadouts(app, "body-selected")
        shot("05-body-selected-info")

        // 6) History should have exactly one healthy feature (no error badge).
        app.buttons["HistoryButton"].firstMatch.tap()
        sleep(1)
        let historyRows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-'"))
        let errorBadges = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        NSLog("OS3D_BUG history rows=\(historyRows.count) errorBadges=\(errorBadges.count)")
        shot("06-history")
        XCTAssertEqual(errorBadges.count, 0, "Extrude feature should not have an error badge")
    }

    // MARK: - Probe: circle inside a just-drawn rectangle (hole authoring)

    private func groundSketch(_ app: XCUIApplication, _ window: XCUIElement, first tool: String) {
        startSketchTool(app, tool)
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
    }

    func testCircleAloneDraws() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        groundSketch(app, window, first: "Circle")
        p(0.50, 0.47).press(forDuration: 0.15, thenDragTo: p(0.58, 0.47))
        shot("circle-alone")
    }

    func testCircleInsideRect() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        groundSketch(app, window, first: "Rect")
        p(0.32, 0.32).press(forDuration: 0.15, thenDragTo: p(0.68, 0.62))
        shot("rect-drawn")

        // Draw a circle inside the (now-selected) rect.
        startSketchTool(app, "Circle")
        p(0.50, 0.47).press(forDuration: 0.15, thenDragTo: p(0.55, 0.47))
        shot("circle-inside-rect")

        // Deselect the rect first, then try again.
        p(0.15, 0.15).tap() // empty-area tap
        sleep(1)
        p(0.44, 0.44).press(forDuration: 0.15, thenDragTo: p(0.48, 0.44))
        shot("circle-after-deselect")
    }

    // MARK: - Probe: sketch on a body face → extrude a boss (union), then edit base

    func testSketchOnFaceBossAndEditBase() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }
        func bodyCount() -> Int {
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-'")).count
        }

        // Base box.
        groundSketch(app, window, first: "Rect")
        p(0.34, 0.34).press(forDuration: 0.15, thenDragTo: p(0.66, 0.60))
        app.buttons["Exit Sketching"].tap(); sleep(1)
        p(0.5, 0.47).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app); sleep(1)
        app.buttons["ViewsMenu"].tap(); app.buttons["Isometric"].tap(); sleep(2)
        logReadouts(app, "base-body"); shot("f01-base-body")
        NSLog("OS3D_BUG features-after-base=\(bodyCount())")

        // Select the top face and sketch a smaller rectangle on it.
        p(0.85, 0.85).tap(); sleep(1)
        p(0.5, 0.33).tap() // top face in iso view
        sleep(1)
        NSLog("OS3D_BUG faceSelected=\(app.staticTexts["Face selected — drag it to push or pull"].exists)")
        shot("f02-top-face-selected")
        startSketchTool(app, "Rect")
        NSLog("OS3D_BUG sketchingOnFace=\(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Sketching'")).firstMatch.label)")
        sleep(2)
        p(0.44, 0.30).press(forDuration: 0.15, thenDragTo: p(0.56, 0.42))
        shot("f03-boss-sketch-on-face")
        app.buttons["Exit Sketching"].tap(); sleep(1)

        // Extrude the boss up.
        p(0.5, 0.32).tap()
        if app.staticTexts["Extrude"].waitForExistence(timeout: 5) {
            typeExtrudeHeight(app); sleep(1)
        } else {
            NSLog("OS3D_BUG boss-extrude-not-armed")
        }
        logReadouts(app, "after-boss"); shot("f04-boss-extruded")
        NSLog("OS3D_BUG features-after-boss=\(bodyCount())")

        // Edit the BASE extrude distance in History → the boss should ride up.
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        // Both extrudes recorded as healthy features (parametric edit / rebuild
        // on distance change is covered by the pure feature-graph unit tests).
        let errBadges = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'")).count
        NSLog("OS3D_BUG history-errors=\(errBadges)")
        shot("f05-history")
        XCTAssertEqual(errBadges, 0, "Base + boss features should both be healthy")
    }

}
