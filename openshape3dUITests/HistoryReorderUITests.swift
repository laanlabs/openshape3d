//
//  HistoryReorderUITests.swift
//  openshape3dUITests
//
//  Phase D tranche 6: drag-to-reorder history steps. Backend (MoveFeatureCommand
//  + graph re-eval + broken-ref surfacing) is unit-covered; this drives the
//  History-panel drag and verifies it commits without error.
//

import XCTest

final class HistoryReorderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Sketch a rectangle on the ground between two points and extrude the default.
    private func extrudeRect(_ app: XCUIApplication, _ window: XCUIElement,
                             from a: CGVector, to b: CGVector, tapInside: CGVector,
                             height: String = "2") {
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: a)
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: b))
        app.buttons["Exit Sketching"].tap(); sleep(1)
        window.coordinate(withNormalizedOffset: tapInside).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app, height); sleep(1)
    }

    func testDragReorderTwoExtrudes() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        // Two independent extrudes → two history rows (both "Extrude").
        // DIFFERENT heights on purpose: both features are named "Extrude", so
        // `HistoryRow-<name>` is identical for the two rows and cannot tell you
        // which one is on top. The row's own distance field can.
        extrudeRect(app, window,
                    from: CGVector(dx: 0.30, dy: 0.40), to: CGVector(dx: 0.44, dy: 0.56),
                    tapInside: CGVector(dx: 0.37, dy: 0.48), height: "2")
        extrudeRect(app, window,
                    from: CGVector(dx: 0.56, dy: 0.40), to: CGVector(dx: 0.70, dy: 0.56),
                    tapInside: CGVector(dx: 0.63, dy: 0.48), height: "3")

        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-'"))
        XCTAssertEqual(rows.count, 2, "two extrudes → two history rows")
        let att0 = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att0.name = "before-reorder"; att0.lifetime = .keepAlways; add(att0)

        // Drag the second row onto the first to reorder — and WAIT for the
        // order to actually change. A synthesized press-and-drag onto a
        // SwiftUI reorderable list does not always take; when it did not, the
        // Undo below undid the previous EXTRUDE instead of the reorder, and the
        // test failed at the very end with "1 row" and no clue why. (This was
        // the long-serial-run flake.) One retry, then a failure that says what
        // actually went wrong.
        func topDistance() -> String {
            (rows.element(boundBy: 0).textFields["HistoryDistanceField"]
                .firstMatch.value as? String) ?? ""
        }
        let topBefore = topDistance()
        func reorderLanded() -> Bool {
            let deadline = Date().addingTimeInterval(6)
            while Date() < deadline {
                if topDistance() != topBefore { return true }
                usleep(300_000)
            }
            return false
        }
        // Press the row's reorder GRIP, not the row: the row carries a
        // context menu, and a 1 s press on it opens that menu instead of
        // lifting a drag (the retry then found the rows covered — "Not
        // hittable"). The grip has no menu, so the press always lifts.
        func grip(_ index: Int) -> XCUIElement {
            rows.element(boundBy: index).descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryDragHandle-'"))
                .firstMatch
        }
        XCTAssertTrue(grip(1).waitForExistence(timeout: 3), "each row has a reorder grip")
        grip(1).press(forDuration: 0.8, thenDragTo: rows.element(boundBy: 0))
        if !reorderLanded() {
            grip(1).press(forDuration: 1.2, thenDragTo: rows.element(boundBy: 0))
            XCTAssertTrue(reorderLanded(),
                          "the drag never reordered the rows — the top row still reads "
                          + "\(topBefore) mm, so the Undo below would undo the extrude instead")
        }
        let att1 = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att1.name = "after-reorder"; att1.lifetime = .keepAlways; add(att1)

        // The reorder committed and left both features healthy (no broken-ref badge).
        let errBadges = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        NSLog("OS3D_BUG reorder errorBadges=\(errBadges.count) rows=\(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-'")).count)")
        XCTAssertEqual(errBadges.count, 0, "reordering two independent extrudes must not break refs")
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled)

        // Undo restores; both extrudes survive the round-trip.
        app.buttons["UndoButton"].tap(); sleep(1)
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-'")).count,
            2, "undoing the reorder keeps both features")
    }
}
