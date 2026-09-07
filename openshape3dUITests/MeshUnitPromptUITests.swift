//
//  MeshUnitPromptUITests.swift
//  openshape3dUITests
//
//  The Import Units prompt: opens for a mesh file, preselects the detected
//  unit, previews the size under another unit, and imports at that scale.
//  The system file picker can't be driven, so the DEBUG hook
//  OS3D_DEBUG_IMPORT_MESH stands in for "the user picked this file".
//

import XCTest

final class MeshUnitPromptUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testPromptPreviewsAndAppliesChosenUnit() throws {
        // A 4.7-unit cube: the size heuristic reads it as metres.
        let obj = """
        v 0 0 0
        v 4.7 0 0
        v 4.7 4.7 0
        v 0 4.7 0
        v 0 0 4.7
        v 4.7 0 4.7
        v 4.7 4.7 4.7
        v 0 4.7 4.7
        f 1 4 3 2
        f 5 6 7 8
        f 1 2 6 5
        f 2 3 7 6
        f 3 4 8 7
        f 4 1 5 8
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("unit-prompt-cube.obj")
        try Data(obj.utf8).write(to: url)

        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_IMPORT_MESH"] = url.path
        app.launch()

        XCTAssertTrue(app.navigationBars["Import Units"].waitForExistence(timeout: 15),
                      "Picking a mesh file should open the units prompt")
        let metres = app.buttons["MeshUnitRow-metres"]
        XCTAssertTrue(metres.waitForExistence(timeout: 3))
        XCTAssertEqual(metres.value as? String, "4.70 × 4.70 × 4.70 m, selected, detected",
                       "The detected unit is preselected and previews the size")
        XCTAssertEqual(app.buttons["MeshUnitRow-millimetres"].value as? String, "4.70 × 4.70 × 4.70 mm")

        // Choose centimetres: the preview follows.
        app.buttons["MeshUnitRow-centimetres"].tap()
        XCTAssertEqual(app.buttons["MeshUnitRow-centimetres"].value as? String,
                       "47.00 × 47.00 × 47.00 mm, selected")
        XCTAssertEqual(metres.value as? String, "4.70 × 4.70 × 4.70 m, detected")
        XCTAssertTrue(app.staticTexts["MeshUnitResult"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["MeshUnitResult"].label.hasSuffix("47.00 × 47.00 × 47.00 mm"),
                      "Result row should preview the chosen unit: \(app.staticTexts["MeshUnitResult"].label)")

        app.buttons["MeshUnitImport"].tap()
        XCTAssertTrue(app.navigationBars["Import Units"].waitForNonExistence(timeout: 5))

        // Select the body from the Items panel (body mode shows Bounds in
        // the info bar) and read its size at the chosen scale.
        XCTAssertTrue(app.buttons["UndoButton"].isEnabled, "The import is one undo step")
        app.buttons["ItemsButton"].tap()
        let row = app.otherElements["ItemRow-unit-prompt-cube"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The imported body is listed under its file's name")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).tap()
        let bounds = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "47.00 × 47.00 × 47.00 mm")).firstMatch
        XCTAssertTrue(bounds.waitForExistence(timeout: 5),
                      "The body should be 47 mm across after importing as centimetres")
    }
}
