//
//  SketchEditUITests.swift
//  openshape3dUITests
//
//  Sketch editing (A3): draw two crossing lines, drag one line's endpoint
//  (pushes a coalesced move command), then trim the dragged line at the
//  crossing. The undo stack must hold exactly four steps: line, line, move,
//  trim.
//

import XCTest

final class SketchEditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testEndpointDragAndTrimPushUndoSteps() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Line")

        // Plane pickers appear; tapping the bare ground starts there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()

        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3),
                      "Sketch status bar should appear")
        lookAtSketch(app)

        // Let the head-on camera animation settle.
        sleep(2)

        func point(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Line A: horizontal. Line B: vertical, crossing A near its middle
        // (B starts on empty space so the stroke draws instead of editing).
        point(0.35, 0.50).press(forDuration: 0.15, thenDragTo: point(0.65, 0.50))
        point(0.50, 0.38).press(forDuration: 0.15, thenDragTo: point(0.50, 0.62))
        sleep(1)
        app.buttons["Line"].tap()
        sleep(1)

        func markerCenters() -> [CGPoint] {
            app.descendants(matching: .any)
                .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
                .map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        }
        let originalCenters = markerCenters()
        XCTAssertEqual(originalCenters.count, 4)
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let vertical = pairs.min {
            abs(originalCenters[$0.0].x - originalCenters[$0.1].x)
                < abs(originalCenters[$1.0].x - originalCenters[$1.1].x)
        }!
        let lower = [originalCenters[vertical.0], originalCenters[vertical.1]]
            .max(by: { $0.y < $1.y })!

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled, "Drawing lines should push undoable commands")

        // Release retains B as the selection; toggling Line off above ends
        // chaining without requiring another selection tap.

        // Drag B's lower endpoint: the stroke starts on the entity, so it
        // edits (move command) instead of drawing a new line. Slow drag with
        // an end hold so the pan recognizer reliably engages and settles.
        let lowerMarker = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
            .min(by: {
                hypot($0.frame.midX - lower.x, $0.frame.midY - lower.y)
                    < hypot($1.frame.midX - lower.x, $1.frame.midY - lower.y)
            })!
        // Resolve the rendered endpoint element rather than translating its
        // frame through the window coordinate space. The latter can miss the
        // Metal view after the sketch camera/status insets settle.
        let lowerCoordinate = lowerMarker.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        )
        lowerCoordinate.press(
            forDuration: 0.3,
            thenDragTo: point(0.60, 0.70),
            withVelocity: .slow,
            thenHoldForDuration: 0.2
        )
        sleep(1)
        let movedCenters = markerCenters()
        XCTAssertTrue(movedCenters.contains(where: {
            $0.x > lower.x + 70 && $0.y > lower.y + 70
        }), "Endpoint drag must move the grabbed lower endpoint; "
            + "before=\(originalCenters), after=\(movedCenters), lower=\(lower)")
        sleep(1)

        // Trim B between the crossing and the moved endpoint.
        let trimButton = app.buttons.containing(.staticText, identifier: "Trim").firstMatch
        XCTAssertTrue(trimButton.exists)
        trimButton.tap()
        // Tap the moved half of the diagonal, between its crossing of the
        // unchanged horizontal line and the dragged lower endpoint.
        let horizontalY = originalCenters.enumerated()
            .filter { $0.offset != vertical.0 && $0.offset != vertical.1 }
            .map { $0.element.y }.reduce(0, +) / 2
        let movedLower = movedCenters.max(by: { $0.y < $1.y })!
        let fixedUpper = movedCenters.min(by: { $0.y < $1.y })!
        let t = (horizontalY - fixedUpper.y) / (movedLower.y - fixedUpper.y)
        let crossingX = fixedUpper.x + t * (movedLower.x - fixedUpper.x)
        let trimPoint = CGPoint(x: (crossingX + movedLower.x) / 2,
                                y: (horizontalY + movedLower.y) / 2)
        window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: trimPoint.x - window.frame.minX,
            dy: trimPoint.y - window.frame.minY
        )).tap()

        // Exactly four undo steps: line A, line B, endpoint move, trim. The
        // move being one step proves the drag coalesced into one command.
        for step in 1...4 {
            XCTAssertTrue(undo.isEnabled, "Undo step \(step) should be available")
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled,
                       "Line + line + move + trim should be exactly four undo steps")

        app.buttons["Exit Sketching"].tap()
        XCTAssertFalse(app.staticTexts["Sketching on ground plane"].exists,
                       "Exiting should dismiss the sketch status bar")
    }
}
