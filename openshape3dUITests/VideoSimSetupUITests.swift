//
//  VideoSimSetupUITests.swift
//  openshape3dUITests
//
//  One-off simulator preparation for the tutorial recordings: a freshly
//  created iPadOS 26 simulator opens apps in floating windows, and there is
//  no `simctl` switch for it, so this drives Settings › Multitasking &
//  Gestures › Full Screen Apps. Skipped unless TEST_RUNNER_OS3D_SIM_SETUP=1.
//

import XCTest

final class VideoSimSetupUITests: XCTestCase {

    func testSwitchToFullScreenApps() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["OS3D_SIM_SETUP"] == "1")
        XCUIDevice.shared.orientation = .landscapeLeft
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let row = settings.staticTexts["Multitasking & Gestures"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), settings.debugDescription)
        row.tap()
        let full = settings.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] 'Full Screen Apps'")).firstMatch
        XCTAssertTrue(full.waitForExistence(timeout: 10), settings.debugDescription)
        full.tap()
        sleep(2)
        print("[setup] tapped Full Screen Apps; selected=\(full.isSelected) value=\(String(describing: full.value))")
        settings.terminate()
    }
}
