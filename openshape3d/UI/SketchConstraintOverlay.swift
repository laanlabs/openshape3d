//
//  SketchConstraintOverlay.swift
//  openshape3d
//
//  On-canvas constraint glyphs (plan §C3). Each symbolic constraint draws a
//  small code badge at its location (a relationship has no geometry of its own,
//  so the anchor is the average of its operand points, projected from world
//  space each camera move via `cameraEpoch`). Tapping a glyph selects the
//  constraint (blue highlight); the palette / Delete key then removes it
//  (undoable) and re-solves. Mirrors `SketchDimensionOverlay`.
//

import SwiftUI

struct SketchConstraintOverlay: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        // Reproject whenever the camera moves.
        let _ = viewModel.cameraEpoch
        // Mirrors `SketchDimensionOverlay`, including gating on content rather
        // than mode so an empty overlay never sits over the viewport.
        let glyphs = viewModel.sketchConstraintGlyphs
        if !glyphs.isEmpty {
            ZStack(alignment: .topLeading) {
                ForEach(glyphs) { glyph in
                    glyphView(glyph)
                }
            }
            .allowsHitTesting(true)
            // The Metal viewport is full-bleed; a SwiftUI overlay is safe-area
            // inset by default, which would draw every projected point ~85pt
            // below the geometry it annotates.
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func glyphView(_ glyph: EditorViewModel.SketchConstraintGlyph) -> some View {
        if let anchor = viewModel.cameraControl?.worldToScreenPoint(glyph.worldAnchor) {
            let selected = viewModel.selectedConstraintID == glyph.id
            // Stage-2 conflict attribution: this constraint is one the solver
            // could not satisfy — paint it red so the chip's "Constraints
            // conflict" has a WHERE. Tap-to-select still works (that is how
            // the user deletes their way out of the conflict).
            let conflicting =
                viewModel.sketchConflictAttribution.constraintIDs.contains(glyph.id)
            let tint = conflicting ? Color.red : Color.blue
            // Fan out glyphs that share an anchor so each stays tappable.
            let offset = CGFloat(glyph.slot) * 22
            // Do not put a clickable constraint badge over the transform's
            // center drag target. Native keeps these glyphs beside its axes.
            let position = glyphPosition(anchor: anchor, offset: offset, sketchID: glyph.sketchID)
            Button {
                viewModel.selectConstraint(glyph.id, in: glyph.sketchID)
            } label: {
                Text(glyph.code)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(selected ? Color.white : tint)
                    .frame(minWidth: 18, minHeight: 18)
                    .padding(2)
                    .background(
                        selected ? tint : Color(.systemBackground).opacity(0.9),
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(tint, lineWidth: conflicting ? 2 : 1)
                    )
            }
            .buttonStyle(.plain)
            .position(position)
            .accessibilityIdentifier(
                conflicting ? "ConstraintGlyphConflict" : "ConstraintGlyph")
        }
    }

    private func glyphPosition(anchor: CGPoint, offset: CGFloat, sketchID: SketchID) -> CGPoint {
        let original = CGPoint(x: anchor.x, y: anchor.y + offset)
        guard viewModel.sketchTransformActive,
              let sketch = viewModel.activeSketch, sketch.id == sketchID,
              let centroid = viewModel.sketchSelectionCentroid,
              let center = viewModel.cameraControl?.worldToScreenPoint(sketch.plane.toWorld(centroid)),
              abs(original.x - center.x) < 44, abs(original.y - center.y) < 44 else { return original }
        return CGPoint(x: center.x - 58, y: center.y + 24 + offset)
    }
}
