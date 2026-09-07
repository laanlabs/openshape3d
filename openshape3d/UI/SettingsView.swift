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
                }
            }
            .navigationTitle("Settings")
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
