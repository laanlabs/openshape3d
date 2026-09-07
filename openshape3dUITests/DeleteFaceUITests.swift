//
//  DeleteFaceUITests.swift
//  openshape3dUITests
//
//  Delete Face (spec §4.16) end to end, asserted on GEOMETRY rather than on
//  chrome: the seeded body is a 10 × 10 × 6 box with a Ø4 through-hole, so
//  deleting the hole's wall must take the volume to exactly the full box —
//  600.00 mm³. A heal that merely capped the hole, or that removed the wrong
//  face, would land on a different number.
//
//  `OS3D_DEBUG_SEED_HOLE` exists for this: it is the only seed with a
//  cylindrical face, which is the face this tool is for.
//

import XCTest

final class DeleteFaceUITests: XCTestCase {

    /// 10 × 10 × 6 box minus a Ø4 drill = 600 − π·2²·6 = 524.60 mm³, and the
    /// bar reads exactly that: since 2026-09-02 the volume comes from the
    /// B-rep (`MeasureKit.volume(of:)`), not the render mesh. It used to read
    /// 524.62 — the faceted hole is an inscribed polygon, so a hair too small,
    /// leaving a hair too much box. A regression to mesh-integrated volume
    /// would land back on 524.62 and fail here.
    private let drilledVolume = "524.60 mm³"
    private let healedVolume = "600.00 mm³"

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testDeletingAHoleWallHealsTheBoxAndUndoBringsItBack() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED_HOLE"] = "1"
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(app.buttons["ModifyGroup"].waitForExistence(timeout: 15))

        tapPaletteTool(app, group: "Modify", id: "DeleteFaceButton")
        let apply = app.buttons["DeleteFaceApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        XCTAssertFalse(apply.isEnabled, "Apply stays off until a face is picked")

        // The drill runs up the Y axis, so the hole opens through the TOP face
        // and its wall is what shows through the opening.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        XCTAssertTrue(app.staticTexts["1 face to delete"].waitForExistence(timeout: 5),
                      "tapping the hole wall should pick exactly one face")
        XCTAssertTrue(apply.isEnabled, "a healable pick enables Apply")

        // Apply leaves the healed body selected, so the info bar reports it.
        apply.tap()
        XCTAssertTrue(app.staticTexts[healedVolume].waitForExistence(timeout: 10),
                      "deleting the hole wall must heal the box to its FULL volume — "
                      + "a capped hole or a wrong face would land elsewhere")

        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.staticTexts[drilledVolume].waitForExistence(timeout: 10),
                      "one undo restores the hole")
    }
}
