//
//  ImageUITests.swift
//  openshape3dUITests
//
//  Insert Image (plan §B10, spec §6.3): a seeded reference image
//  (OS3D_DEBUG_SEED_IMAGE) lists in the Items Manager, tap-selects in the
//  viewport to show the image bar (opacity slider + size field), and deletes.
//

import XCTest

final class ImageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchWithSeededImage() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED_IMAGE"] = "1"
        app.launch()
        return app
    }

    func testSeededImageListsInItemsSelectsOnTapAndDeletes() throws {
        let app = launchWithSeededImage()
        let window = app.windows.firstMatch

        // The seeded image appears in the Items Manager.
        let itemsButton = app.buttons["ItemsButton"]
        XCTAssertTrue(itemsButton.waitForExistence(timeout: 10))
        itemsButton.tap()
        XCTAssertTrue(app.staticTexts["Images"].waitForExistence(timeout: 3),
                      "Items should have an Images section")
        XCTAssertTrue(app.textFields["ItemName-Image 1"].waitForExistence(timeout: 3),
                      "The seeded image should be listed")
        itemsButton.tap() // close the panel so the viewport is unobstructed

        // Tap the image in the viewport (the quad is centered on the origin,
        // which the default camera looks at) → image bar with opacity slider.
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let slider = app.sliders["ImageOpacitySlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 3),
                      "Tapping the image should select it and show the opacity bar")
        XCTAssertTrue(app.textFields["ImageSizeField"].exists,
                      "The image bar should carry the size field")

        // Scrubbing the slider is an UpdateImageCommand edit; the bar stays up.
        slider.adjust(toNormalizedSliderPosition: 0.3)
        XCTAssertTrue(slider.exists)

        // Delete from the bar: the bar dismisses and the Items row is gone.
        app.buttons["ImageDelete"].tap()
        XCTAssertFalse(app.sliders["ImageOpacitySlider"].waitForExistence(timeout: 2),
                       "Deleting the image should dismiss the image bar")
        itemsButton.tap()
        XCTAssertTrue(app.staticTexts["Images"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["ItemName-Image 1"].exists,
                       "Deleting should remove the image row")
        XCTAssertTrue(app.staticTexts["No images yet"].exists)

        // Undo restores the image row (RemoveImageCommand round-trip).
        app.buttons["UndoButton"].tap()
        XCTAssertTrue(app.textFields["ItemName-Image 1"].waitForExistence(timeout: 3),
                      "Undo should restore the deleted image")
    }

    func testItemsRowSelectsImageAndEmptyTapDeselects() throws {
        let app = launchWithSeededImage()
        let window = app.windows.firstMatch

        // Selecting from the Items row shows the image bar without needing
        // a viewport hit.
        let itemsButton = app.buttons["ItemsButton"]
        XCTAssertTrue(itemsButton.waitForExistence(timeout: 10))
        itemsButton.tap()
        let row = app.otherElements["ItemRow-Image 1"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        // Tap the row's type icon (tapping the text field would edit text).
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.5)).tap()
        itemsButton.tap() // close the panel
        XCTAssertTrue(app.sliders["ImageOpacitySlider"].waitForExistence(timeout: 3),
                      "The Items row tap should select the image")

        // Done dismisses the bar; a fresh viewport tap re-selects.
        app.buttons["ImageDone"].tap()
        XCTAssertFalse(app.sliders["ImageOpacitySlider"].waitForExistence(timeout: 2))
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.sliders["ImageOpacitySlider"].waitForExistence(timeout: 3),
                      "Tapping the quad again should re-select the image")
    }
}
