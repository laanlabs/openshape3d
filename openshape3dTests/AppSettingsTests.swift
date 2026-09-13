//
//  AppSettingsTests.swift
//  openshape3dTests
//
//  Phase F tranche 1: display units + the settings store. The document is
//  always millimetres — DisplayUnit converts at the view layer only, so the
//  round-trips here are what keep geometry stable across unit switches.
//

import XCTest
@testable import openshape3d

final class AppSettingsTests: XCTestCase {

    @MainActor
    func testCircularAnnotationPreferencePersistsWithCompatibleDefault() throws {
        let suite = "CircularAnnotationsTests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.circularAnnotations, .radiusAndDiameter)
        settings.circularAnnotations = .alwaysRadius
        XCTAssertEqual(AppSettings(defaults: defaults).circularAnnotations, .alwaysRadius)
        settings.circularAnnotations = .radiusAndDiameter
        XCTAssertEqual(AppSettings(defaults: defaults).circularAnnotations, .radiusAndDiameter)
    }

    // MARK: DisplayUnit conversion

    func testConversionFactors() {
        XCTAssertEqual(DisplayUnit.millimeters.display(fromMM: 25.4), 25.4)
        XCTAssertEqual(DisplayUnit.centimeters.display(fromMM: 25.4), 2.54, accuracy: 1e-12)
        XCTAssertEqual(DisplayUnit.meters.display(fromMM: 1500), 1.5, accuracy: 1e-12)
        XCTAssertEqual(DisplayUnit.inches.display(fromMM: 25.4), 1.0, accuracy: 1e-12)
        XCTAssertEqual(DisplayUnit.feet.display(fromMM: 304.8), 1.0, accuracy: 1e-12)
    }

    func testRoundTripThroughEveryUnit() {
        for unit in DisplayUnit.allCases {
            let mm = 123.456
            XCTAssertEqual(unit.mm(fromDisplay: unit.display(fromMM: mm)), mm,
                           accuracy: 1e-9, "\(unit) must round-trip")
        }
    }

    // MARK: Formatting

    func testLengthStrings() {
        XCTAssertEqual(DisplayUnit.millimeters.lengthString(fromMM: 12.7), "12.70 mm")
        XCTAssertEqual(DisplayUnit.inches.lengthString(fromMM: 12.7), "0.500 in")
        XCTAssertEqual(DisplayUnit.centimeters.lengthString(fromMM: 12.7), "1.27 cm")
    }

    func testAreaAndVolumeScaleByPowers() {
        // 1 in² = 645.16 mm²; 1 in³ = 16387.064 mm³.
        XCTAssertEqual(DisplayUnit.inches.areaString(fromMM2: 645.16), "1.000 in²")
        XCTAssertEqual(DisplayUnit.inches.volumeString(fromMM3: 16387.064), "1.000 in³")
        XCTAssertEqual(DisplayUnit.centimeters.volumeString(fromMM3: 1000), "1.00 cm³")
    }

    func testCompactLengthTrimsZeros() {
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 12.7), "12.7 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 5), "5 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 0.869 / 2), "0.4345 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 12.34567), "12.3457 mm")
        XCTAssertEqual(DisplayUnit.inches.compactLengthString(fromMM: 25.4), "1\"")
        XCTAssertEqual(DisplayUnit.inches.compactLengthString(fromMM: 1.016), "0.04\"")
        XCTAssertEqual(DisplayUnit.feet.compactLengthString(fromMM: 20.32), "0.0667'")
        XCTAssertEqual(DisplayUnit.feet.compactLengthString(fromMM: 1.016), "0.0033'")
        XCTAssertEqual(DisplayUnit.inches.symbol, "in", "Input suffix stays distinct from annotation")
        XCTAssertEqual(DisplayUnit.feet.symbol, "ft")
    }

    /// Native canvas labels paired 2026-09-13: "123,456.7891 mm",
    /// "164,058.8074 mm", "R 50,000 mm" — every decimal kept, thousands
    /// grouped. `%g` had capped labels at six significant digits.
    func testCompactLengthKeepsDenseValuesAndGroupsThousands() {
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 123456.7891), "123,456.7891 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 164058.8074), "164,058.8074 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 50000), "50,000 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 1234.5678), "1,234.5678 mm")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: 1234.56785), "1,234.5679 mm")
        XCTAssertEqual(DisplayUnit.centimeters.compactLengthString(fromMM: 12345.6789), "1,234.568 cm")
        XCTAssertEqual(DisplayUnit.inches.compactLengthString(fromMM: 1234.56789 * 25.4), "1,234.5679\"")
        XCTAssertEqual(DisplayUnit.millimeters.compactLengthString(fromMM: -0.00001), "0 mm")
    }

    // MARK: Persistence

    private func freshDefaults() -> UserDefaults {
        let name = "AppSettingsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testDefaultsAreMillimetersSystemLeftPalette4x() {
        let settings = AppSettings(defaults: freshDefaults())
        XCTAssertEqual(settings.unit, .millimeters)
        XCTAssertEqual(settings.theme, .system)
        XCTAssertFalse(settings.paletteOnRight)
        XCTAssertEqual(settings.antiAliasing, 4)
    }

    func testSnappingPreferencesPersistIncludingExplicitOff() {
        let defaults = freshDefaults()
        let first = AppSettings(defaults: defaults)
        XCTAssertEqual(first.snapOptions, SnapOptions())
        XCTAssertTrue(first.showSnapHints)
        XCTAssertTrue(first.snapToSketchGuidelines)
        first.snapToGrid = false
        first.snapToSketchGuidelines = false
        first.snapToSketchGuidepoints = false
        first.snapToFaceGuidepoints = false
        first.showSnapHints = false
        let next = AppSettings(defaults: defaults)
        XCTAssertEqual(next.snapOptions, SnapOptions(grid: false, sketchGuidepoints: false,
                                                    faceGuidepoints: false))
        XCTAssertFalse(next.showSnapHints)
        XCTAssertFalse(next.snapToSketchGuidelines)
        next.snapToGrid = true
        XCTAssertTrue(AppSettings(defaults: defaults).snapToGrid)
    }

    /// UI tests override snapping with launch arguments (`-os3d.snapToGrid
    /// NO`), which land in the argument domain as strings. Those must read
    /// as booleans, and an unrelated string must not turn a default off.
    func testLaunchArgumentStringsOverrideSnapDefaults() {
        let defaults = freshDefaults()
        defaults.set("NO", forKey: "os3d.snapToGrid")
        defaults.set("YES", forKey: "os3d.snapToSketchGuidelines")
        defaults.set("0", forKey: "os3d.snapToSketchGuidepoints")
        defaults.set("1", forKey: "os3d.showSnapHints")
        let settings = AppSettings(defaults: defaults)
        XCTAssertFalse(settings.snapToGrid)
        XCTAssertTrue(settings.snapToSketchGuidelines)
        XCTAssertFalse(settings.snapToSketchGuidepoints)
        XCTAssertTrue(settings.showSnapHints)
        XCTAssertTrue(settings.snapToFaceGuidepoints, "unset keeps the default")
        // A real Bool written by the app still round-trips as before.
        settings.snapToGrid = true
        XCTAssertTrue(AppSettings(defaults: defaults).snapToGrid)
    }

    func testSettingsPersistAcrossReload() {
        let defaults = freshDefaults()
        let first = AppSettings(defaults: defaults)
        first.unit = .inches
        first.theme = .dark
        first.paletteOnRight = true
        first.antiAliasing = 2

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.unit, .inches)
        XCTAssertEqual(second.theme, .dark)
        XCTAssertTrue(second.paletteOnRight)
        XCTAssertEqual(second.antiAliasing, 2)
    }

    func testAnchoredSketchEntityPreferencePersistsWithFirstSelectedDefault() {
        let defaults = freshDefaults()
        let first = AppSettings(defaults: defaults)
        XCTAssertEqual(first.anchoredSketchEntity, .firstSelected)
        first.anchoredSketchEntity = .lastSelected
        XCTAssertEqual(AppSettings(defaults: defaults).anchoredSketchEntity, .lastSelected)
        first.anchoredSketchEntity = .firstSelected
        XCTAssertEqual(AppSettings(defaults: defaults).anchoredSketchEntity, .firstSelected)
    }

    func testLaunchSampleCountRejectsInvalidStoredValues() {
        let defaults = freshDefaults()
        defaults.set(3, forKey: "os3d.antiAliasing")
        XCTAssertEqual(AppSettings.launchSampleCount(defaults: defaults), 4,
                       "an invalid stored MSAA count falls back to 4")
        defaults.set(2, forKey: "os3d.antiAliasing")
        XCTAssertEqual(AppSettings.launchSampleCount(defaults: defaults), 2)
    }

    // MARK: View-model readouts follow the shared setting

    @MainActor
    func testFormattedLengthFollowsSharedUnit() {
        let saved = AppSettings.shared.unit
        defer { AppSettings.shared.unit = saved }
        AppSettings.shared.unit = .inches
        XCTAssertEqual(EditorViewModel.formattedLength(25.4), "1.000 in")
        AppSettings.shared.unit = .millimeters
        XCTAssertEqual(EditorViewModel.formattedLength(25.4), "25.40 mm")
    }
}
