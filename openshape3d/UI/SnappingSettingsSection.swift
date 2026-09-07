import SwiftUI

struct SnappingSettingsSection: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section {
            Toggle("Grid", isOn: $settings.snapToGrid)
                .accessibilityIdentifier("SnapToGridToggle")
            Toggle("Sketch Guidepoints", isOn: $settings.snapToSketchGuidepoints)
                .accessibilityIdentifier("SnapToSketchGuidepointsToggle")
            Toggle("Face Guidepoints", isOn: $settings.snapToFaceGuidepoints)
                .accessibilityIdentifier("SnapToFaceGuidepointsToggle")
            Toggle("Snapping Hints", isOn: $settings.showSnapHints)
                .accessibilityIdentifier("ShowSnapHintsToggle")
        } header: {
            Text("Snapping")
        } footer: {
            Text("Snap to grid steps, sketch points, or the corners and edges of the face you are sketching on. Hints label the snap without changing it. Auto-Constrain separately controls inferred geometric relationships.")
        }
    }
}
