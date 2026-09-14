//
//  BlendEditUITests.swift
//  openshape3dUITests
//
//  Mission 3 item 3: re-open an existing fillet from its History row and change
//  which edges it blends.
//
//  This is the coverage the unit tests cannot give. `BlendEditEvalTests` proves
//  the MECHANISM — that truncating the graph at the blend node recovers the
//  pre-blend body — but every part that could still be wrong lives in the
//  wiring: that `inputBody` actually truncates, that `beginBlendEdit` picks
//  against the recovered body, and above all that committing an edit EDITS the
//  node instead of appending a second blend on top of the first. That last one
//  is invisible to geometry assertions (two 1 mm fillets of the same edge look
//  much like one) and shows up only as a second row in History.
//

import XCTest

final class BlendEditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

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
        p(0.45, 0.45).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app); sleep(1)
        app.buttons["ViewsMenu"].tap()
        app.buttons["Isometric"].tap(); sleep(2)
    }

    private func filletRows(_ app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryRow-Fillet'"))
    }

    func testEditEdgesReopensTheFilletAndDoesNotAddASecondOne() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        func p(_ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
            window.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        }

        extrudeBox(app, window)

        // Fillet one edge.
        tapPaletteTool(app, group: "Modify", id: "FilletButton")
        let apply = app.buttons["BlendApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 3))
        for pt in [(0.42, 0.34), (0.37, 0.27), (0.65, 0.26), (0.59, 0.45)] {
            p(CGFloat(pt.0), CGFloat(pt.1)).tap()
            sleep(1)
            if apply.isEnabled { break }
        }
        XCTAssertTrue(apply.isEnabled, "an edge should be selected")
        apply.tap(); sleep(2)
        shot("01-filleted")

        // One Fillet row, no errors.
        app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        XCTAssertTrue(filletRows(app).firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(filletRows(app).count, 1, "one fillet so far")

        // Re-open it: long-press the row for its context menu, then Edit Edges.
        filletRows(app).firstMatch.press(forDuration: 1.0)
        let editEdges = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'EditEdges-'")).firstMatch
        XCTAssertTrue(editEdges.waitForExistence(timeout: 5),
                      "a blend row must offer Edit Edges")
        shot("02-context-menu")
        editEdges.tap(); sleep(2)

        // The blend bar is back, and Apply is already enabled because the
        // feature's existing edges were re-selected for us — an empty seed
        // would leave it disabled.
        XCTAssertTrue(apply.waitForExistence(timeout: 5),
                      "Edit Edges must re-enter edge picking")
        XCTAssertTrue(apply.isEnabled,
                      "the fillet's existing edges should already be selected")
        shot("03-reopened")

        // Commit the edit unchanged. The point of the test: this must EDIT the
        // existing feature, not stack a second fillet onto it.
        apply.tap(); sleep(2)
        // Open History only if it is not already showing. `HistoryButton`
        // TOGGLES, and the panel survives the edit — tapping it blindly closed
        // the panel and reported zero rows, which reads exactly like the
        // feature having been destroyed.
        if !filletRows(app).firstMatch.exists {
            app.buttons["HistoryButton"].firstMatch.tap(); sleep(1)
        }
        XCTAssertEqual(filletRows(app).count, 1,
                       "editing a blend must not append a second Fillet feature")
        let errors = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'HistoryError-'"))
        XCTAssertEqual(errors.count, 0, "the edited fillet must still evaluate cleanly")
        shot("04-after-edit")
    }
}
