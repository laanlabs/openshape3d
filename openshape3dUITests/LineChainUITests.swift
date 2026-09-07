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
        app.launch()
        let window = app.windows.firstMatch
        startGroundLineSketch(app, window)

        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        // Tap the four corners of a square — each tap extends the chain from the
        // previous vertex — then tap the first corner again to close the loop.
        p(0.42, 0.42).tap()   // A: starts the chain (no segment yet)
        p(0.60, 0.42).tap()   // B: segment A→B
        p(0.60, 0.60).tap()   // C: segment B→C
        p(0.42, 0.60).tap()   // D: segment C→D
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
        for _ in 0..<4 { undo.tap() }
        XCTAssertFalse(undo.isEnabled,
                       "A tapped-and-closed square is exactly four chained line segments")
    }
}
