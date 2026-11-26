//
//  FieldOfViewSheet.swift
//  openshape3d
//
//  View ▸ Field of View… (spec §7.3): a slider over the perspective angle,
//  reaching 0° = orthographic, applied live.
//

import SwiftUI

struct FieldOfViewSheet: View {
    @Bindable var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Field of View")
                    Spacer()
                    Text(viewModel.fieldOfViewDegrees < 1
                         ? "Orthographic"
                         : "\(Int(viewModel.fieldOfViewDegrees.rounded()))°")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("FieldOfViewValue")
                }
                Slider(value: Binding(
                    get: { viewModel.fieldOfViewDegrees },
                    set: { viewModel.setFieldOfView($0) }
                ), in: 0...100, step: 1)
                .accessibilityIdentifier("FieldOfViewSlider")
                Text("0° shows the model orthographically, without perspective.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Field of View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
