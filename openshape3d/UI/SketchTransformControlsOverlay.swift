import SwiftUI
import simd

/// Explicit sketch Move/Rotate: white directional controls and nearby exact input.
struct SketchTransformControlsOverlay: View {
    @Bindable var viewModel: EditorViewModel
    @State private var editing: EditorViewModel.SketchTransformControl?
    @State private var dragging: EditorViewModel.SketchTransformControl?
    @State private var text = "0"
    @State private var initialValueSelected = true
    @State private var usingKeyboard = false
    @FocusState private var focused: Bool

    var body: some View {
        let _ = viewModel.cameraEpoch
        GeometryReader { geo in
            if viewModel.sketchTransformActive, viewModel.mode.sketchTool == nil,
               viewModel.editingDimension == nil,
               let center = viewModel.sketchSelectionCentroid,
               let plane = viewModel.activeSketch?.plane,
               let camera = viewModel.cameraControl,
               let c = camera.worldToScreenPoint(plane.toWorld(center)),
               let px = camera.worldToScreenPoint(plane.toWorld(center + SIMD2(1, 0))),
               let py = camera.worldToScreenPoint(plane.toWorld(center + SIMD2(0, 1))) {
                let x = SIMD2(Double(px.x - c.x), Double(px.y - c.y))
                let y = SIMD2(Double(py.x - c.x), Double(py.y - c.y))
                if simd_length(x) > 0.01, simd_length(y) > 0.01 {
                    let ux = simd_normalize(x), uy = simd_normalize(y)
                    ZStack {
                        Circle().fill(.white).overlay(Circle().stroke(.gray, lineWidth: 1))
                            .frame(width: 16, height: 16).position(c)
                            .allowsHitTesting(false)
                        ForEach(EditorViewModel.SketchTransformControl.allCases, id: \.self) { part in
                            control(part, center: c, x: x, y: y, ux: ux, uy: uy)
                        }
                        if let editing {
                            input(editing)
                                .position(editorPosition(c, size: geo.size))
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.sketchTransformActive) { _, active in
            if !active { editing = nil; dragging = nil }
        }
        .onChange(of: viewModel.selectedSketchEntityIDs) { _, _ in editing = nil }
    }

    private func control(_ part: EditorViewModel.SketchTransformControl,
                         center: CGPoint, x: SIMD2<Double>, y: SIMD2<Double>,
                         ux: SIMD2<Double>, uy: SIMD2<Double>) -> some View {
        let offset = part == .x ? ux * 80 : part == .y ? uy * 80 : (ux + uy) * 80
        let anchor = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
        let rotation = part == .x ? atan2(ux.y, ux.x) : part == .y ? atan2(uy.y, uy.x) : atan2(offset.y, offset.x)
        return ZStack {
            Image(systemName: part == .rotation ? "arrow.left.and.right" : "arrow.right")
                .foregroundStyle(Color(white: 0.2)).scaleEffect(1.10)
            Image(systemName: part == .rotation ? "arrow.left.and.right" : "arrow.right")
                .foregroundStyle(.white)
        }
        .font(.system(size: 28, weight: .semibold))
        .rotationEffect(.radians(rotation))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .position(anchor)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("SketchTransform-\(part.rawValue)")
        .accessibilityLabel(part == .rotation ? "Rotate sketch" : "Move sketch \(part.title)")
        .accessibilityAddTraits(.isButton)
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
            let delta = SIMD2(Double(value.translation.width), Double(value.translation.height))
            guard simd_length(delta) > 2 || dragging != nil else { return }
            if dragging == nil { editing = nil; dragging = part }
            let amount: Double
            if part == .rotation {
                let start = atan2(simd_dot(offset, uy), simd_dot(offset, ux))
                let current = atan2(simd_dot(offset + delta, uy), simd_dot(offset + delta, ux))
                amount = (current - start) * 180 / .pi
            } else {
                let axis = part == .x ? x : y
                amount = simd_dot(delta, simd_normalize(axis)) / simd_length(axis)
            }
            viewModel.updateSketchTransformControl(part, value: amount)
        }.onEnded { _ in
            if dragging != nil {
                viewModel.endSketchTransformControl()
                dragging = nil
            } else {
                text = "0"; initialValueSelected = true; usingKeyboard = false
                editing = part
            }
        })
    }

    private func input(_ part: EditorViewModel.SketchTransformControl) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Text(part.title).font(.caption.weight(.semibold))
                TextField("", text: $text)
                    .font(.caption.monospacedDigit())
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .allowsHitTesting(usingKeyboard)
                    .onSubmit { commit(part) }
                    .accessibilityIdentifier("SketchTransformField")
                Button { editing = nil } label: { Image(systemName: "xmark.circle.fill") }
                    .accessibilityIdentifier("SketchTransformCancel")
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
            if !usingKeyboard {
                NumericKeypad(text: $text, isLocked: nil, initialValueSelected: $initialValueSelected,
                    onCommit: { commit(part) }, onSwitchToSystemKeyboard: {
                        usingKeyboard = true; focused = true
                    })
            }
        }
        .frame(width: 300)
    }

    private func commit(_ part: EditorViewModel.SketchTransformControl) {
        if viewModel.commitSketchTransformControl(part, text: text) { editing = nil }
    }

    private func editorPosition(_ center: CGPoint, size: CGSize) -> CGPoint {
        let left: CGFloat = AppSettings.shared.paletteOnRight ? 184 : 96
        let right: CGFloat = AppSettings.shared.paletteOnRight ? 96 : 184
        let lowX = left + 150, highX = size.width - right - 150
        let lowY: CGFloat = 300, highY = size.height - 250
        return CGPoint(x: highX >= lowX ? min(max(center.x, lowX), highX) : size.width / 2,
                       y: highY >= lowY ? min(max(center.y, lowY), highY) : size.height / 2)
    }
}
