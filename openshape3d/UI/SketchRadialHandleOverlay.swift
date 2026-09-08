import SwiftUI
import simd

/// A single selected arc exposes radial sizing. Move/Rotate is explicit.
struct SketchRadialHandleOverlay: View {
    @Bindable var viewModel: EditorViewModel
    @State private var dragAxis: SIMD2<Double>?
    @State private var pointsPerUnit: Double = 1

    var body: some View {
        let _ = viewModel.cameraEpoch
        if !viewModel.sketchTransformActive, viewModel.editingDimension == nil,
           case let .arc(_, center, radius, start, end)? = viewModel.selectedSingleArc,
           let plane = viewModel.activeSketch?.plane,
           let camera = viewModel.cameraControl,
           let c = camera.worldToScreenPoint(plane.toWorld(center)) {
            let mid = start + SketchEntity.arcSweep(startAngle: start, endAngle: end) / 2
            let rim = center + SIMD2(cos(mid), sin(mid)) * radius
            if let p = camera.worldToScreenPoint(plane.toWorld(rim)) {
                let delta = SIMD2(Double(p.x - c.x), Double(p.y - c.y))
                let length = simd_length(delta)
                if length > 1 {
                    let axis = delta / length
                    let anchor = CGPoint(x: p.x + axis.x * 30, y: p.y + axis.y * 30)
                    ZStack {
                        Image(systemName: "arrow.left.and.right")
                            .foregroundStyle(Color(white: 0.15)).scaleEffect(1.12)
                        Image(systemName: "arrow.left.and.right").foregroundStyle(.white)
                    }
                    .font(.system(size: 28, weight: .semibold))
                    .rotationEffect(.radians(atan2(axis.y, axis.x)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .position(anchor)
                    .accessibilityIdentifier("SketchArcRadiusHandle")
                    .accessibilityLabel("Adjust arc radius")
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
                        if dragAxis == nil {
                            dragAxis = axis
                            pointsPerUnit = length / radius
                        }
                        let translation = SIMD2(Double(value.translation.width), Double(value.translation.height))
                        viewModel.updateArcRadiusDrag(delta: simd_dot(translation, dragAxis ?? axis) / pointsPerUnit)
                    }.onEnded { _ in
                        viewModel.endArcRadiusDrag()
                        dragAxis = nil
                    })
                }
            }
        }
    }
}
