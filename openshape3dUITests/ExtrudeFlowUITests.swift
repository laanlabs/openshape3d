//
//  ExtrudeFlowUITests.swift
//  openshape3dUITests
//
//  The core Shapr3D loop end-to-end: sketch a rectangle base, exit sketching,
//  then turn the filled profile into a solid — both by tapping it (numeric
//  extrude) and by pulling it directly (push/pull, commits on release).
//

import XCTest

final class ExtrudeFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func drawRectangle(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        // Plane pickers appear; tap the bare ground to sketch there.
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.42))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.60))
        start.press(forDuration: 0.15, thenDragTo: end)

        app.buttons["Exit Sketching"].tap()
    }

    func testTapProfileThenExtrudeButton() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        drawRectangle(in: app)

        // Tap inside the filled profile → jumps into the Extrude command.
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.51)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping a filled profile should start extruding")

        // Arming starts at zero height — type one to commit.
        typeExtrudeHeight(app)

        // Commit selects the new body: Delete lights up, extrude bar dismisses.
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled)
        XCTAssertFalse(app.staticTexts["Extrude"].exists)
    }

    func testSymmetricToggleCommitsExtrude() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        drawRectangle(in: app)

        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.51)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))

        // Symmetric sides: distance is per-side, the solid grows both ways
        // (total depth 2× — asserted at the kernel level in ProfileTests).
        let symmetric = app.buttons["Symmetric"].firstMatch
        XCTAssertTrue(symmetric.waitForExistence(timeout: 3), "Extrude bar shows the Symmetric toggle")
        symmetric.tap()

        typeExtrudeHeight(app)

        // Commit selects the new body; two undoable commands (sketch + extrude).
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled)
        XCTAssertFalse(app.staticTexts["Extrude"].exists)

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo symmetric extrude
        XCTAssertTrue(undo.isEnabled, "Sketch command should remain")
        undo.tap() // undo sketch entity
        XCTAssertFalse(undo.isEnabled)
    }

    func testBooleanBadgeNewBodyKeepsBothBodies() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))

        // Body A.
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // camera animation
        lookAtSketch(app)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.42))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.58)))
        app.buttons["Exit Sketching"].tap()
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.37, dy: 0.50)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app)
        XCTAssertFalse(app.staticTexts["Extrude"].exists)

        // Profile B overlaps body A; tap point sits outside A's footprint.
        startSketchTool(app, "Rect")
        XCTAssertTrue(app.staticTexts["Choose a sketch plane"].waitForExistence(timeout: 3))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.78)).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        lookAtSketch(app)
        // Drawn from the far corner: the stroke must START on empty space
        // (a stroke starting on rect A's outline would drag-edit it, A3).
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.60, dy: 0.58))
            .press(forDuration: 0.15, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.40, dy: 0.42)))
        app.buttons["Exit Sketching"].tap()
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.50)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))

        // Boolean badge → New Body: the overlap must NOT auto-union.
        let newBodySegment = app.buttons["New Body"].firstMatch
        XCTAssertTrue(newBodySegment.waitForExistence(timeout: 3), "Extrude bar shows the boolean badge")
        newBodySegment.tap()
        typeExtrudeHeight(app)

        // Commit selects the new body — delete it.
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled)
        deleteButton.tap()

        // Body A must survive as a separate body: tapping its footprint
        // selects it again. (Had the commit auto-unioned, deleting the result
        // would have emptied the scene.)
        sleep(1)
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.37, dy: 0.50)).tap()
        let predicate = NSPredicate(format: "isEnabled == true")
        expectation(for: predicate, evaluatedWith: deleteButton)
        waitForExpectations(timeout: 5)
    }

    func testPullProfileCreatesBodyOnRelease() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        drawRectangle(in: app)

        // Push/pull: drag upward starting inside the fill. In the head-on
        // view the screen-space fallback drives the distance. Releasing keeps
        // the dynamic preview (Shapr3D); completing the tool commits.
        let window = app.windows.firstMatch
        let pullStart = window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.51))
        let pullEnd = window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.30))
        pullStart.press(forDuration: 0.15, thenDragTo: pullEnd)

        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 3),
                      "Releasing the pull keeps the Extrude tool active")
        app.buttons["Extrude"].firstMatch.tap()

        // Two undoable commands now: the sketch entity and the extrude.
        let deleteButton = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        XCTAssertTrue(deleteButton.isEnabled, "Pulled body should be selected")

        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.tap() // undo extrude
        XCTAssertTrue(undo.isEnabled, "Sketch command should remain")
        undo.tap() // undo sketch entity
        XCTAssertFalse(undo.isEnabled)
    }
}
