//
//  FilletLeakUITests.swift
//  openshape3dUITests
//
//  Regression: "the next cube I drew after using the fillet tool was
//  automatically filleted." Fillet a box, then draw a SECOND box far away and
//  assert it is a plain box — the fillet must belong to the first body only.
//

import XCTest

final class FilletLeakUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func p(_ w: XCUIElement, _ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
        w.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
    }

    /// Sketch a rectangle on the ground within [x0,x1]×[y0,y1] and extrude it.
    private func drawBox(_ app: XCUIApplication, _ w: XCUIElement,
                         _ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat,
                         tapAt: (CGFloat, CGFloat)) {
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        p(w, 0.80, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2); lookAtSketch(app)
        p(w, x0, y0).press(forDuration: 0.15, thenDragTo: p(w, x1, y1))
        app.buttons["Exit Sketching"].tap(); sleep(1)
        p(w, tapAt.0, tapAt.1).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app); sleep(1)
    }

    func testFilletDoesNotLeakToTheNextBox() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        // Box 1, top-left of the ground.
        drawBox(app, window, 0.22, 0.30, 0.46, 0.52, tapAt: (0.34, 0.41))
        app.buttons["ViewsMenu"].tap(); app.buttons["Isometric"].tap(); sleep(2)

        // Fillet an edge of box 1.
        tapPaletteTool(app, group: "Modify", id: "FilletButton")
        XCTAssertTrue(app.buttons["BlendApply"].waitForExistence(timeout: 3))
        let apply = app.buttons["BlendApply"]
        // Start on the rendered top/front edge. A face-interior tap selects
        // the whole face, whose four-edge 1 mm preview is invalid on this
        // 1.5 mm-wide box.
        for pt in [(0.36, 0.30), (0.30, 0.27), (0.48, 0.28), (0.44, 0.40)] {
            p(window, CGFloat(pt.0), CGFloat(pt.1)).tap(); sleep(1)
            if apply.isEnabled { break }
        }
        XCTAssertTrue(apply.isEnabled, "an edge should arm the fillet")
        apply.tap(); sleep(2)

        // Now draw a SECOND box, well away (bottom-right).
        drawBox(app, window, 0.60, 0.60, 0.84, 0.82, tapAt: (0.72, 0.71))
        app.buttons["ViewsMenu"].tap(); app.buttons["Isometric"].tap(); sleep(2)

        // History must contain exactly ONE Fillet — not two.
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        let fillets = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Fillet'"))
        XCTAssertEqual(fillets.count, 1,
                       "the fillet must apply to the first box only, not the second")
    }
}
