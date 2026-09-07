//
//  ReplaceFaceUITests.swift
//  openshape3dUITests
//
//  Replace Face (spec §4.12) end to end, on geometry rather than chrome.
//
//  The seeded body is a stepped block: a low half up to y = 6 and a high half
//  up to y = 12, 1800 mm³ together. Replacing the low step's top face onto the
//  high step's plane must make it one solid 20 × 10 × 12 box — 2400 mm³. Any
//  other answer means the prism went the wrong way, the wrong distance, or
//  onto the wrong plane.
//
//  It also covers the two-stage pick itself, which nothing else does: the tool
//  needs a source face AND a target face, and the refusal for a target that is
//  not parallel is a real geometric answer that has to reach the user.
//

import XCTest

final class ReplaceFaceUITests: XCTestCase {

    private let steppedVolume = "1800.00 mm³"
    private let boxedVolume = "2400.00 mm³"

    /// The low step's top face (y = 6) and the high step's top face (y = 12),
    /// as the seeded camera frames them.
    private let lowStepTop = CGVector(dx: 0.233, dy: 0.475)
    private let highStepTop = CGVector(dx: 0.667, dy: 0.375)
    /// A vertical wall — used to prove the not-parallel refusal.
    private let frontWall = CGVector(dx: 0.6, dy: 0.62)

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED_STEP"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["ModifyGroup"].waitForExistence(timeout: 15))
        return app
    }

    func testReplacingTheLowStepOntoTheHighStepMakesASolidBox() throws {
        let app = launch()
        let window = app.windows.firstMatch

        tapPaletteTool(app, group: "Modify", id: "ReplaceFaceButton")
        let apply = app.buttons["ReplaceFaceApply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        XCTAssertFalse(apply.isEnabled, "Apply is off until both faces are picked")

        // Stage 1 — the face to move.
        window.coordinate(withNormalizedOffset: lowStepTop).tap()
        XCTAssertTrue(app.staticTexts["Now tap the face to move it to"]
            .waitForExistence(timeout: 5), "the first tap should pick the source face")
        XCTAssertTrue(app.staticTexts["100.00 mm²"].exists,
                      "the low step's top is 10 × 10")
        XCTAssertFalse(apply.isEnabled, "still off with only a source")

        // Stage 2 — the plane to move it onto.
        window.coordinate(withNormalizedOffset: highStepTop).tap()
        XCTAssertTrue(app.staticTexts["Ready — Apply to replace"]
            .waitForExistence(timeout: 5), "a parallel target should resolve")
        XCTAssertTrue(apply.isEnabled)

        apply.tap()
        XCTAssertTrue(app.staticTexts[boxedVolume].waitForExistence(timeout: 10),
                      "the step should fill to a solid 20 × 10 × 12 box")

        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.staticTexts[steppedVolume].waitForExistence(timeout: 10),
                      "one undo restores the step")
    }

    /// A target that is not parallel cannot be described by one prism — the gap
    /// varies across the face. The tool must SAY so rather than leaving a
    /// disabled Apply and no explanation.
    func testANonParallelTargetIsRefusedOutLoud() throws {
        let app = launch()
        let window = app.windows.firstMatch

        tapPaletteTool(app, group: "Modify", id: "ReplaceFaceButton")
        window.coordinate(withNormalizedOffset: lowStepTop).tap()
        XCTAssertTrue(app.staticTexts["Now tap the face to move it to"]
            .waitForExistence(timeout: 5))

        window.coordinate(withNormalizedOffset: frontWall).tap()
        XCTAssertTrue(app.staticTexts["The target face isn't parallel to the one being replaced"]
            .waitForExistence(timeout: 5),
                      "the refusal has to name the reason")
        XCTAssertFalse(app.buttons["ReplaceFaceApply"].isEnabled,
                       "and Apply must stay off")
    }
}
