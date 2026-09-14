import XCTest

final class DragSolveUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testLockedEndpointDragProjectsOntoHorizontalAndCoalesces() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        func p(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        }
        func at(_ point: CGPoint) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.x, dy: point.y))
        }
        func points() -> [CGPoint] {
            app.descendants(matching: .any).matching(identifier: "SketchPointMarker")
                .allElementsBoundByIndex.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
                .sorted { $0.x < $1.x }
        }
        func attach(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        func assertPoints(_ expected: [CGPoint]) {
            let actual = points()
            XCTAssertEqual(actual.count, expected.count)
            for (a, b) in zip(actual, expected) {
                XCTAssertEqual(a.x, b.x, accuracy: 1)
                XCTAssertEqual(a.y, b.y, accuracy: 1)
            }
        }

        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")
        p(0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        p(0.35, 0.55).press(forDuration: 0.15, thenDragTo: p(0.65, 0.55))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        tapPaletteTool(app, group: "Sketch", label: "Line")
        p(0.5, 0.75).tap()
        sleep(1)
        let drawn = points()
        XCTAssertEqual(drawn.count, 2)
        guard drawn.count == 2 else { return }
        at(drawn[0]).tap()
        sleep(1)
        let lock = app.buttons["ConstraintRail-fixed"]
        XCTAssertTrue(lock.isEnabled)
        lock.tap()
        sleep(1)
        let before = points()
        XCTAssertEqual(before.count, 2, "The fixture must contain exactly two rendered endpoints")
        guard before.count == 2 else { return }
        XCTAssertEqual(before[0].y, before[1].y, accuracy: 1)
        let topRight = before[1]
        attach("locked-line-before-drag")
        // Select the actual snapped endpoint, not the original pointer position.
        p(0.5, 0.75).tap()
        sleep(1)
        at(topRight).press(forDuration: 0.2,
                           thenDragTo: at(CGPoint(x: topRight.x + 70, y: topRight.y + 45)),
                           withVelocity: .slow, thenHoldForDuration: 0.2)
        sleep(1)
        let after = points()
        XCTAssertEqual(after.count, 2)
        guard after.count == 2 else { return }
        XCTAssertEqual(after[0].y, after[1].y, accuracy: 1,
                       "Solved endpoints must remain horizontal")
        XCTAssertGreaterThan(after[1].x - before[1].x, 5,
                             "A rejected/no-op drag is not a pass")
        XCTAssertEqual(after[0].x, before[0].x, accuracy: 1)
        XCTAssertEqual(after[0].y, before[0].y, accuracy: 1)
        XCTAssertFalse(app.staticTexts["Constraints conflict"].exists)
        attach("locked-line-after-drag")
        let undo = app.buttons["UndoButton"].firstMatch
        undo.tap()
        sleep(1)
        assertPoints(before)
        app.buttons["RedoButton"].tap()
        sleep(1)
        assertPoints(after)
        undo.tap()
        undo.tap() // Lock
        undo.tap() // Draw
        XCTAssertFalse(undo.isEnabled, "Draw + Lock + one coalesced Move exhausts history")
        XCTAssertEqual(points().count, 0)
    }
}
