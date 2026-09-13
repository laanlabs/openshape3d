//
//  CompactWidthBarUITests.swift
//  openshape3dUITests
//
//  iPhone-width regression guard for the bottom contextual bars.
//
//  The bars used to lay out as a single fixed HStack sized for iPad. At iPhone
//  width SwiftUI compressed each label to its minimum and wrapped it one
//  character per line: "Extrude", "Offset Plane" and "Cancel" each became a
//  vertical stack of letters, the Extrude button rendered as an unlabelled blue
//  pill, and the bar ate ~40% of the screen — pushing the tool palette's last
//  entries off. See marketing/bugs/iphone-extrude-bar-broken.png.
//
//  The assertions here are geometric on purpose. A per-character-wrapped button
//  still reports the full `label` string to XCUITest, so comparing labels alone
//  cannot catch the bug; what actually distinguishes a healthy text button is
//  that it is wider than it is tall.
//
//  These tests are meaningful only where the horizontal size class is compact,
//  so they skip themselves on iPad rather than failing there.
//

import XCTest

final class CompactWidthBarUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Launches straight into the seeded document, matching the bug repro.
    private func launchSeeded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launchEnvironment["OS3D_DEBUG_SEED"] = "1"
        app.launchEnvironment["OS3D_AUTO_OPEN"] = "1"
        app.launch()
        return app
    }

    /// iPad lays these bars out as one row by design; only compact width is
    /// under test. 500pt is comfortably above every iPhone portrait width and
    /// below every iPad one.
    private func skipUnlessCompact(_ app: XCUIApplication) throws {
        let width = app.windows.firstMatch.frame.width
        try XCTSkipUnless(width > 0 && width < 500,
                          "Compact-width layout test; window is \(width)pt wide")
    }

    /// A healthy text control is a horizontal pill. When the label wraps one
    /// character per line it becomes narrow and very tall, which is exactly the
    /// shape this asserts against.
    private func assertReadsHorizontally(_ element: XCUIElement,
                                         minimumWidth: CGFloat,
                                         _ what: String,
                                         file: StaticString = #filePath,
                                         line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5),
                      "\(what) should exist", file: file, line: line)
        XCTAssertTrue(element.isHittable,
                      "\(what) should be hittable, not clipped or covered",
                      file: file, line: line)
        let frame = element.frame
        XCTAssertGreaterThan(frame.width, frame.height,
                             "\(what) is taller than it is wide — its label is wrapping vertically",
                             file: file, line: line)
        XCTAssertGreaterThan(frame.width, minimumWidth,
                             "\(what) is only \(frame.width)pt wide — its label is truncated",
                             file: file, line: line)
    }

    /// The extrude bar: the worst of the two reported cases.
    func testExtrudeBarIsUsableAtCompactWidth() throws {
        let app = launchSeeded()
        try skipUnlessCompact(app)

        // Tap the seeded box's top face to arm extrude.
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.27)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping the top face should arm the extrude bar")

        // The two controls called out in the bug report, plus the widest label
        // in the bar, which is the first to be squeezed.
        assertReadsHorizontally(app.buttons["Extrude"], minimumWidth: 50, "Extrude button")
        assertReadsHorizontally(app.buttons["Cancel"], minimumWidth: 44, "Cancel button")
        assertReadsHorizontally(app.buttons["Offset Plane"], minimumWidth: 70, "Offset Plane button")

        // The bar must leave the tool palette usable: Delete is its last entry
        // and was unreachable under the old layout.
        let delete = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        // Nine entries do not fit an iPhone portrait screen above the info
        // strip and the bar, so the palette scrolls there (ViewThatFits); the
        // requirement is that Delete is reachable — directly or by scrolling
        // the palette — rather than sitting under the bar where no scroll
        // could reveal it (the original defect).
        if !delete.isHittable {
            let palette = app.scrollViews["ToolPalette"]
            XCTAssertTrue(palette.exists, "A palette that does not fit should scroll")
            palette.swipeUp()
        }
        XCTAssertTrue(delete.isHittable,
                      "The extrude bar is covering the tool palette's last entry")

        // …and it must not swallow the viewport. The old bar reached ~40%.
        let barTop = app.buttons["Extrude"].frame.minY
        let screenHeight = window.frame.height
        XCTAssertGreaterThan(barTop, screenHeight * 0.6,
                             "The extrude bar starts \(barTop)pt down a \(screenHeight)pt screen — too tall")
    }

    /// Landscape is the tightest case: on every iPhone but the Max/Plus the
    /// width stays compact while the height drops to ~390pt, so the bar, the
    /// info strip and the tool palette are all competing for it.
    ///
    /// Unlike the tests above this one runs everywhere — reading horizontally
    /// and staying reachable are requirements in both size classes, so there is
    /// nothing to skip.
    func testExtrudeBarIsUsableInLandscape() throws {
        let app = launchSeeded()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.30)).tap()
        XCTAssertTrue(app.staticTexts["Extrude"].waitForExistence(timeout: 5),
                      "Tapping the top face should arm the extrude bar in landscape")

        assertReadsHorizontally(app.buttons["Extrude"], minimumWidth: 50, "Extrude button")
        assertReadsHorizontally(app.buttons["Cancel"], minimumWidth: 44, "Cancel button")

        // The palette cannot show all eight tools in ~390pt on any layout, so
        // the requirement here is that Delete is *reachable* by scrolling —
        // not that it is on screen already. What must not happen is the bar
        // growing until the palette has no usable scroll region left.
        let delete = app.buttons.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        if !delete.isHittable {
            let palette = app.scrollViews.containing(.staticText, identifier: "Sketch").firstMatch
            XCTAssertTrue(palette.exists, "Tool palette should be a scrollable column")
            palette.swipeUp()
        }
        XCTAssertTrue(delete.isHittable,
                      "The tool palette's last entry is unreachable even after scrolling")

        // The bar must still leave the model visible to work on.
        let barTop = app.buttons["Extrude"].frame.minY
        let screenHeight = window.frame.height
        XCTAssertGreaterThan(barTop, screenHeight * 0.5,
                             "The bar starts \(barTop)pt down a \(screenHeight)pt landscape screen — it covers over half the viewport")
    }

    /// The primitive dimension bar, which showed "B/o/x" stacked vertically.
    func testPrimitiveDimensionBarIsUsableAtCompactWidth() throws {
        let app = launchSeeded()
        try skipUnlessCompact(app)

        let title = app.staticTexts["Box"]
        XCTAssertTrue(title.waitForExistence(timeout: 10),
                      "The seeded box should open with its dimension bar showing")
        XCTAssertGreaterThan(title.frame.width, title.frame.height,
                             "The 'Box' title is wrapping one character per line")

        assertReadsHorizontally(app.buttons["Done"], minimumWidth: 44, "Done button")

        // Every dimension field must be reachable, not squeezed off the bar.
        let fields = app.textFields
        XCTAssertEqual(fields.count, 3, "A box should offer width/depth/height fields")
        for index in 0..<3 {
            XCTAssertTrue(fields.element(boundBy: index).isHittable,
                          "Dimension field \(index) is not hittable")
        }
    }
}
