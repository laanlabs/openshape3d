//
//  ItemsFolderUITests.swift
//  openshape3dUITests
//
//  Items Manager folders (spec §11): New Folder, Move to Folder from a row's
//  menu, the folder eye hiding its children, Remove Folder keeping the item,
//  and undo.
//

import XCTest

final class ItemsFolderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func drawRectangle(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
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

    /// Long-press a row's leading icon (pressing the name field would edit).
    private func openRowMenu(_ app: XCUIApplication, rowID: String) {
        let row = app.otherElements[rowID].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3), "\(rowID) should be listed")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).press(forDuration: 1.0)
    }

    func testFolderCreateMoveEyeRemoveUndo() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()

        // A body: rect sketch + extrude.
        drawRectangle(in: app)
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.53, dy: 0.51)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5))
        typeExtrudeHeight(app)
        XCTAssertFalse(app.staticTexts["Extrude"].exists)

        app.buttons["ItemsButton"].tap()
        XCTAssertTrue(app.staticTexts["Bodies"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["ItemName-Extrude"].waitForExistence(timeout: 3))

        // New Folder → "Folder 1" row appears under a Folders header.
        app.buttons["ItemsNewFolderButton"].tap()
        XCTAssertTrue(app.otherElements["ItemFolderRow-Folder 1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Folders"].exists)

        // Move the body in from its row menu (no-op if the selection already
        // put it there — either way it ends up inside).
        openRowMenu(app, rowID: "ItemRow-Extrude")
        let moveMenu = app.collectionViews.buttons["Move to Folder"]
        XCTAssertTrue(moveMenu.waitForExistence(timeout: 3), "Row menu should offer Move to Folder")
        moveMenu.tap()
        let target = app.collectionViews.buttons["Folder 1"]
        XCTAssertTrue(target.waitForExistence(timeout: 3), "Submenu should list the folder")
        if target.isEnabled { target.tap() } else { app.tap() }
        XCTAssertTrue(app.textFields["ItemName-Extrude"].waitForExistence(timeout: 3))

        // The folder eye hides its child; the body's own eye reports it.
        let folderEye = app.buttons["ItemEye-Folder 1"]
        XCTAssertTrue(folderEye.waitForExistence(timeout: 3))
        XCTAssertEqual(folderEye.value as? String, "visible")
        folderEye.tap()
        let bodyEye = app.buttons["ItemEye-Extrude"]
        XCTAssertEqual(bodyEye.value as? String, "hidden", "Folder eye should hide the body inside")
        XCTAssertEqual(folderEye.value as? String, "hidden")
        folderEye.tap()
        XCTAssertEqual(bodyEye.value as? String, "visible")

        // Rename the folder inline.
        replaceText(app.textFields["ItemName-Folder 1"], with: "Parts")
        XCTAssertTrue(app.otherElements["ItemFolderRow-Parts"].waitForExistence(timeout: 3))

        // Remove Folder keeps the body (back in Bodies); undo brings the folder back.
        openRowMenu(app, rowID: "ItemFolderRow-Parts")
        let remove = app.collectionViews.buttons["Remove Folder"]
        XCTAssertTrue(remove.waitForExistence(timeout: 3))
        remove.tap()
        XCTAssertFalse(app.otherElements["ItemFolderRow-Parts"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["ItemName-Extrude"].exists, "The body survives removing its folder")
        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.otherElements["ItemFolderRow-Parts"].waitForExistence(timeout: 3),
                      "Undo should restore the folder")
    }
}
