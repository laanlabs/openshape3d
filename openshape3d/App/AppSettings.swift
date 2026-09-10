//
//  AppSettings.swift
//  openshape3d
//
//  App-wide preferences (Phase F, spec §17): display units, theme, interface
//  side, anti-aliasing. The DOCUMENT always stores millimetres — `DisplayUnit`
//  converts at the view layer only, so switching units never touches geometry.
//

import Foundation
import SwiftUI

// MARK: - Display units

/// User preference for showing/typing lengths. Conversion is view-layer only.
nonisolated enum DisplayUnit: String, CaseIterable, Codable, Sendable {
    case millimeters = "mm"
    case centimeters = "cm"
    case meters = "m"
    case inches = "in"
    case feet = "ft"

    var symbol: String { rawValue }

    /// Multiply a millimetre value by this to get the display value.
    var factorFromMM: Double {
        switch self {
        case .millimeters: return 1
        case .centimeters: return 0.1
        case .meters: return 0.001
        case .inches: return 1 / 25.4
        case .feet: return 1 / 304.8
        }
    }

    /// Sensible decimals for a length readout in this unit.
    var lengthDecimals: Int {
        switch self {
        case .millimeters, .centimeters: return 2
        case .meters, .inches, .feet: return 3
        }
    }

    func display(fromMM value: Double) -> Double { value * factorFromMM }
    func mm(fromDisplay value: Double) -> Double { value / factorFromMM }

    /// "12.70 mm", "0.500 in" — a length readout.
    func lengthString(fromMM value: Double) -> String {
        String(format: "%.\(lengthDecimals)f %@", display(fromMM: value), symbol)
    }

    /// Compact length for labels/pills: trims trailing zeros ("12.7 mm").
    func compactLengthString(fromMM value: Double) -> String {
        let v = display(fromMM: value)
        // Native on-canvas imperial dimensions use quote marks rather than
        // the input suffixes shown in the unit picker. Keep those input tokens
        // unchanged, and retain the fourth decimal used by decimal feet.
        let imperial = self == .inches || self == .feet
        let scale = imperial ? 10000.0 : 1000.0
        let rounded = (v * scale).rounded() / scale
        if self == .inches { return String(format: "%g", rounded) + "\"" }
        if self == .feet { return String(format: "%g", rounded) + "'" }
        return String(format: "%g %@", rounded, symbol)
    }

    /// "161.29 cm²" — an area readout (factor squared).
    func areaString(fromMM2 value: Double) -> String {
        let f = factorFromMM
        return String(format: "%.\(lengthDecimals)f %@²", value * f * f, symbol)
    }

    /// "16.387 cm³" — a volume readout (factor cubed).
    func volumeString(fromMM3 value: Double) -> String {
        let f = factorFromMM
        return String(format: "%.\(lengthDecimals)f %@³", value * f * f * f, symbol)
    }

    /// A view-layer binding that shows and edits a millimetre value in this
    /// unit (get converts out, set converts back).
    func binding(_ mm: Binding<Double>) -> Binding<Double> {
        Binding(
            get: { self.display(fromMM: mm.wrappedValue) },
            set: { mm.wrappedValue = self.mm(fromDisplay: $0) }
        )
    }
}

// MARK: - Theme

nonisolated enum AppTheme: String, CaseIterable, Codable, Sendable {
    case system, light, dark

    var title: String { rawValue.capitalized }

    /// nil = follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Settings store

/// Singleton preference store, UserDefaults-backed. Views read it through
/// `@Observable` tracking so a change re-renders everything that shows units,
/// flips the palette, or re-themes the window.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let unit = "os3d.displayUnit"
        static let theme = "os3d.theme"
        static let paletteOnRight = "os3d.paletteOnRight"
        static let antiAliasing = "os3d.antiAliasing"
        static let singleKeyAction = "os3d.singleKeyAction"
        static let alwaysShowDimensions = "os3d.alwaysShowDimensions"
        static let alwaysShowConstraints = "os3d.alwaysShowConstraints"
        static let snapToGrid = "os3d.snapToGrid"
        static let snapToSketchGuidepoints = "os3d.snapToSketchGuidepoints"
        static let snapToFaceGuidepoints = "os3d.snapToFaceGuidepoints"
        static let showSnapHints = "os3d.showSnapHints"
    }

    var unit: DisplayUnit {
        didSet { defaults.set(unit.rawValue, forKey: Key.unit) }
    }
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }
    /// Shapr3D's "interface side": tool palette on the right for left-handed
    /// use (panels stay put; only the palette flips).
    var paletteOnRight: Bool {
        didSet { defaults.set(paletteOnRight, forKey: Key.paletteOnRight) }
    }
    /// MSAA sample count (1 = off, 2, 4). Pipelines bake the sample count at
    /// startup, so this takes effect on the next launch (the sheet says so).
    var antiAliasing: Int {
        didSet { defaults.set(antiAliasing, forKey: Key.antiAliasing) }
    }
    /// What a BARE letter does on a hardware keyboard (spec §8.4): fire the
    /// hotkey it is bound to, or open Command Search pre-typed with it.
    /// Chorded shortcuts (⌘Z, ⇧⌘I…) are unaffected either way.
    var singleKeyAction: SingleKeyAction {
        didSet { defaults.set(singleKeyAction.rawValue, forKey: Key.singleKeyAction) }
    }

    /// Shapr3D's "Constraint & Locked Dimension Visibility": when on, a
    /// sketch's dimensions stay on canvas after you leave the sketch, and every
    /// visible sketch shows its own — not just the one being edited. Off, they
    /// follow the selection, which is Shapr3D's shipped default.
    var alwaysShowDimensions: Bool {
        didSet { defaults.set(alwaysShowDimensions, forKey: Key.alwaysShowDimensions) }
    }
    /// The same, for constraint glyphs.
    var alwaysShowConstraints: Bool {
        didSet { defaults.set(alwaysShowConstraints, forKey: Key.alwaysShowConstraints) }
    }

    var snapToGrid: Bool {
        didSet { defaults.set(snapToGrid, forKey: Key.snapToGrid) }
    }
    var snapToSketchGuidepoints: Bool {
        didSet { defaults.set(snapToSketchGuidepoints, forKey: Key.snapToSketchGuidepoints) }
    }
    var snapToFaceGuidepoints: Bool {
        didSet { defaults.set(snapToFaceGuidepoints, forKey: Key.snapToFaceGuidepoints) }
    }
    var showSnapHints: Bool {
        didSet { defaults.set(showSnapHints, forKey: Key.showSnapHints) }
    }

    var snapOptions: SnapOptions {
        SnapOptions(grid: snapToGrid, sketchGuidepoints: snapToSketchGuidepoints,
                    faceGuidepoints: snapToFaceGuidepoints)
    }

    /// The sample count pipelines were actually built with this launch.
    static func launchSampleCount(defaults: UserDefaults = .standard) -> Int {
        let stored = defaults.integer(forKey: Key.antiAliasing)
        return [1, 2, 4].contains(stored) ? stored : 4
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        snapToGrid = defaults.object(forKey: Key.snapToGrid) as? Bool ?? true
        snapToSketchGuidepoints = defaults.object(forKey: Key.snapToSketchGuidepoints) as? Bool ?? true
        snapToFaceGuidepoints = defaults.object(forKey: Key.snapToFaceGuidepoints) as? Bool ?? true
        showSnapHints = defaults.object(forKey: Key.showSnapHints) as? Bool ?? true
        unit = defaults.string(forKey: Key.unit).flatMap(DisplayUnit.init) ?? .millimeters
        theme = defaults.string(forKey: Key.theme).flatMap(AppTheme.init) ?? .system
        paletteOnRight = defaults.bool(forKey: Key.paletteOnRight)
        antiAliasing = Self.launchSampleCount(defaults: defaults)
        singleKeyAction = defaults.string(forKey: Key.singleKeyAction)
            .flatMap(SingleKeyAction.init) ?? .hotkeys
        // Both default OFF, verified against the running Shapr3D: its
        // Constraint Settings ship "Always Show Constraints" and "Always Show
        // Dimensions" off, with the footer "Logical constraints and locked
        // dimensions are shown based on your current selection." Off is NOT
        // hidden here either — individual annotations follow selected geometry.
        // `object(forKey:)` so an explicit choice survives a
        // relaunch (`bool(forKey:)` cannot tell false from unset).
        alwaysShowDimensions =
            defaults.object(forKey: Key.alwaysShowDimensions) as? Bool ?? false
        // Constraints default OFF: a canvas of ⌖ ∥ ⊥ ◎ badges over every visible
        // sketch while you are modelling is noise, and Shapr3D does not do it by
        // default either. Off still shows annotations referring to selected geometry.
        alwaysShowConstraints =
            defaults.object(forKey: Key.alwaysShowConstraints) as? Bool ?? false
    }

    // Under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, this class is
    // implicitly `@MainActor`, and (SE-0371) a global-actor-isolated `deinit`
    // is isolated to that actor. Deallocating an isolated-`deinit` `@Observable`
    // then routes through `swift_task_deinitOnExecutorImpl`, which double-frees
    // in the current toolchain — deterministically crashing any test that lets
    // an `AppSettings` instance go out of scope (malloc "pointer being freed
    // was not allocated"). There's no teardown work to do here, so opt the
    // deinit out of actor isolation to skip the executor hop entirely.
    nonisolated deinit {}
}
