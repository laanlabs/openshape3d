//
//  SweepLoftUITests.swift
//  openshape3dUITests
//
//  Sweep end-to-end: sketch a circle beside a 2-segment chained line path,
//  tap the fill to start the profile tool, arm Sweep, tap the two lines to
//  chain the path, commit, and undo. Plus a Loft flow smoke: arm Loft from a
//  fill, tap a second fill (section count updates), commit (coplanar
//  sections are rejected with an error), and cancel back out. Real loft
//  geometry is covered by SweepLoftTests (unit).
//

import XCTest

final class SweepLoftUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testSweepCircleAlongTwoSegmentLinePath() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch

        // Circle left of center on the ground plane.
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Circle")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        let circleCenter = window.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.50))
        let circleEdge = window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.50))
        circleCenter.press(forDuration: 0.15, thenDragTo: circleEdge)

        // Two chained line segments to the right: the future sweep path.
        // They start well clear of the circle's rim: strokes now run from the
        // touch-down (2026-09-04), so the circle above is its full 0.08 of
        // the width, and a line begun within the rim's grab tolerance
        // (~0.5 mm, ≈45 pt at this zoom) resizes the circle instead.
        startSketchTool(app, "Line")
        let lineStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.50))
        let lineElbow = window.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.50))
        let lineEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.36))
        lineStart.press(forDuration: 0.15, thenDragTo: lineElbow)
        lineElbow.press(forDuration: 0.15, thenDragTo: lineEnd)

        app.buttons["Exit Sketching"].tap()

        // Tap the circle fill → Extrude tool with a Sweep option.
        circleCenter.tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping a filled profile should start the profile tool")

        app.buttons["Sweep"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Tap sketch lines to build the sweep path"].waitForExistence(timeout: 3),
            "Sweep should prompt for path entities"
        )

        // Chain both line segments into the spine.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.64, dy: 0.50)).tap()
        XCTAssertTrue(app.staticTexts["1 path segment"].waitForExistence(timeout: 3),
                      "The first tapped line should join the path")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.43)).tap()
        XCTAssertTrue(app.staticTexts["2 path segments"].waitForExistence(timeout: 3),
                      "The second tapped line should chain onto the path")

        // Commit: the swept body is created and selected.
        app.buttons["SweepCommit"].tap()
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        XCTAssertTrue(deleteButton.isEnabled, "Swept body should be selected")
        XCTAssertFalse(app.staticTexts["Tap sketch lines to build the sweep path"].exists)

        // Four undoable commands: circle, line 1, line 2, sweep body.
        let undo = app.buttons["UndoButton"]
        for _ in 0..<4 {
            XCTAssertTrue(undo.isEnabled)
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled, "Exactly four undoable commands expected")
    }

    func testLoftFlowCollectsSectionsAndRejectsCoplanarCommit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch

        // Two rectangles of different sizes on the ground plane.
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.34, dy: 0.40))
            .press(forDuration: 0.15, thenDragTo:
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.48, dy: 0.56)))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.56, dy: 0.44))
            .press(forDuration: 0.15, thenDragTo:
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.66, dy: 0.54)))

        app.buttons["Exit Sketching"].tap()

        // Tap the first fill → Extrude tool with a Loft option.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.41, dy: 0.48)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))

        app.buttons["Loft"].firstMatch.tap()
        XCTAssertTrue(
            app.staticTexts["Tap profile fills to add loft sections"].waitForExistence(timeout: 3),
            "Loft should prompt for more sections"
        )
        XCTAssertTrue(app.staticTexts["1 section — tap more profile fills"].exists)

        // Add the second rectangle: the section count updates.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.61, dy: 0.49)).tap()
        XCTAssertTrue(app.staticTexts["2 sections — tap more profile fills"].waitForExistence(timeout: 3),
                      "Tapping another fill should append a loft section")

        // Commit: coplanar sections can't loft — the tool errors and stays.
        app.buttons["LoftCommit"].tap()
        XCTAssertTrue(app.staticTexts["Something Went Wrong"].waitForExistence(timeout: 3),
                      "Coplanar loft sections should be rejected")
        app.buttons["OK"].tap()

        // Cancel back to the extrude bar, then out entirely.
        app.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 3),
                      "Cancelling the loft pick should return to Extrude")
        app.buttons["Cancel"].firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Extrude"].exists)

        // Only the two sketch entities are undoable.
        let undo = app.buttons["UndoButton"]
        for _ in 0..<2 {
            XCTAssertTrue(undo.isEnabled)
            undo.tap()
        }
        XCTAssertFalse(undo.isEnabled)
    }
}
