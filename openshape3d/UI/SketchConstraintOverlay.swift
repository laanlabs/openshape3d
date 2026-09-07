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
            .position(x: anchor.x, y: anchor.y + offset)
            .accessibilityIdentifier(
                conflicting ? "ConstraintGlyphConflict" : "ConstraintGlyph")
        }
    }
}
