//
//  SettingsView.swift
//  openshape3d
//
//  App settings sheet (Phase F, spec §17): units, appearance, interface side,
//  anti-aliasing. Bound straight to `AppSettings.shared`; every control
//  persists immediately.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                // First, because the people it is for came for exactly this
                // and know no other setting. Desktop assistants live on the
                // Mac; an iPad has none to pair with (DEBUG keeps the section
                // everywhere so it can be tested).
                #if targetEnvironment(macCatalyst) || DEBUG
                AIAssistantSettingsSection(control: AIControl.shared)
                #endif

                Section("Units") {
                    Picker("Length Unit", selection: $settings.unit) {
                        ForEach(DisplayUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsUnitPicker")
                    Text("Models are stored in millimetres; this changes how lengths are shown and typed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Sketch Annotations") {
                    Picker("Circular Annotations", selection: $settings.circularAnnotations) {
                        ForEach(CircularAnnotations.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .accessibilityIdentifier("SettingsCircularAnnotations")
                    Text("Choose radius or diameter readouts for circles without resizing them.")
                        .font(.caption).foregroundStyle(.secondary)
                    Picker("Default Spline Type", selection: $settings.defaultSplineType) {
                        Text("Fit Point").tag(SplineType.fit)
                        Text("Control Point").tag(SplineType.control)
                    }
                    .accessibilityIdentifier("SettingsDefaultSplineType")
                }

                SnappingSettingsSection(settings: settings)

                Section("Appearance") {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsThemePicker")
                }

                Section("Interface") {
                    Picker("Toolbar Side", selection: $settings.paletteOnRight) {
                        Text("Left").tag(false)
                        Text("Right").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsPaletteSide")
                    Text("Put the tool palette on the right for left-handed sketching.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Single Key Action", selection: $settings.singleKeyAction) {
                        Text("Hotkeys").tag(SingleKeyAction.hotkeys)
                        Text("Command Search").tag(SingleKeyAction.commandSearch)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsSingleKeyAction")
                    Text("What a single letter does on a hardware keyboard — "
                         + "run its tool, or open Command Search typed with it. "
                         + "⌘ shortcuts work either way.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Selection Extension", selection: $settings.selectionExtension) {
                        ForEach(SelectionExtension.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsSelectionExtension")
                    Text(settings.selectionExtension == .click
                         ? "Each click adds to the selection or takes away; Shift-click selects just that one."
                         : "A click selects one item; Shift-click adds to the selection or takes away.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Menu Button Labels", isOn: $settings.menuButtonLabels)
                        .accessibilityIdentifier("SettingsMenuButtonLabels")

                    Picker("Start With", selection: $settings.startWith) {
                        ForEach(StartWith.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("SettingsStartWith")

                    NavigationLink("Keyboard Shortcuts") { KeyboardShortcutsView(settings: settings) }
                        .accessibilityIdentifier("SettingsKeyboardShortcuts")
                }

                Section("Graphics") {
                    Picker("Anti-Aliasing", selection: $settings.antiAliasing) {
                        Text("Off").tag(1)
                        Text("2×").tag(2)
                        Text("4×").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("SettingsAntiAliasing")
                    if settings.antiAliasing != AppSettings.launchSampleCount() {
                        Text("Takes effect the next time the app launches.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Picker("Tessellation Quality", selection: $settings.tessellationQuality) {
                        ForEach(TessellationQuality.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("SettingsTessellation")
                    VStack(alignment: .leading) {
                        LabeledContent("Tool Preview Opacity",
                                       value: "\(Int((settings.toolPreviewOpacity * 100).rounded()))%")
                        Slider(value: $settings.toolPreviewOpacity, in: 0.1...1, step: 0.05)
                            .accessibilityIdentifier("SettingsToolPreviewOpacity")
                        Text("How solid a tool's preview draws while editing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if settings.tessellationQuality != TessellationQuality.launch {
                        Text("Takes effect the next time the app launches, for curved faces built after it.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    Picker("Navigation Preset", selection: $settings.navigationPreset) {
                        ForEach(NavigationPreset.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("SettingsNavigationPreset")
                    Toggle("Reverse Scroll Direction", isOn: $settings.reverseZoom)
                        .accessibilityIdentifier("SettingsReverseZoom")
                } header: {
                    Text("Mouse Navigation")
                } footer: {
                    Text(settings.navigationPreset.summary + " The mouse wheel zooms; a trackpad pans with two fingers and pinches to zoom.")
                }

                // The Mac and the web read a SpaceMouse; iPadOS gives apps no
                // access to one (DEBUG keeps the section so it can be tested).
                #if targetEnvironment(macCatalyst) || DEBUG
                SpaceMouseSettingsSection(settings: settings, driver: SpaceMouseDriver.shared)
                #endif

                Section {
                    Toggle("Display Touches and Clicks", isOn: $settings.showTouches)
                        .accessibilityIdentifier("SettingsShowTouches")
                    Toggle("Display Keyboard Shortcuts", isOn: $settings.showKeyPresses)
                        .accessibilityIdentifier("SettingsShowKeys")
                } header: {
                    Text("Tutorial Mode")
                } footer: {
                    Text("For recording tutorials: each touch shows a ring, and each keyboard shortcut its keys.")
                }
            }
            .navigationTitle("Settings")
            .onDisappear { MacWindowTitle.restore() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("SettingsDone")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Settings ▸ SpaceMouse (spec §7.5).
private struct SpaceMouseSettingsSection: View {
    @Bindable var settings: AppSettings
    var driver: SpaceMouseDriver

    var body: some View {
        Section {
            LabeledContent("Device", value: driver.deviceName ?? "Not Connected")
                .accessibilityIdentifier("SpaceMouseDevice")
            VStack(alignment: .leading) {
                LabeledContent("Speed", value: String(format: "%.2g×", settings.spaceMouse.speed))
                // Logarithmic, so ½× and 2× sit equally either side of 1×.
                Slider(value: Binding(
                    get: { log2(settings.spaceMouse.speed) },
                    set: { settings.spaceMouse.speed = pow(2, ($0 * 4).rounded() / 4) }),
                       in: -2...2)
                    .accessibilityIdentifier("SpaceMouseSpeed")
            }
            Toggle("Rotation", isOn: $settings.spaceMouse.rotation)
                .accessibilityIdentifier("SpaceMouseRotation")
            Toggle("Pan and Zoom", isOn: $settings.spaceMouse.panZoom)
                .accessibilityIdentifier("SpaceMousePanZoom")
            Toggle("Dominant Axis Only", isOn: $settings.spaceMouse.dominantAxis)
                .accessibilityIdentifier("SpaceMouseDominant")
            Toggle("Invert Pan Left/Right", isOn: $settings.spaceMouse.invertPanX)
            Toggle("Invert Pan Up/Down", isOn: $settings.spaceMouse.invertPanY)
            Toggle("Invert Zoom", isOn: $settings.spaceMouse.invertZoom)
                .accessibilityIdentifier("SpaceMouseInvertZoom")
            Toggle("Invert Tilt", isOn: $settings.spaceMouse.invertTilt)
            Toggle("Invert Spin", isOn: $settings.spaceMouse.invertSpin)
        } header: {
            Text("SpaceMouse")
        } footer: {
            Text("Move the cap as if holding the model: push, lift and twist it and the model follows. "
                 + "The buttons fit the view (Fit) and jump to the standard views.")
        }
    }
}
