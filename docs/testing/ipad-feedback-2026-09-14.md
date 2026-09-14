# iPad feedback, 2026-09-14: plane picker size, gizmo typed entry

Jason, testing the final branch build on the paired iPad (Laan iPad Pro
11-inch, iPadOS 26.6.2), reported two things.

## 1. "Choose a plane" graphic not proportional to the view

Zoomed way out, choosing Sketch showed three tiny origin planes; zoomed
in, enormous ones. The picker tiles were sized in world units (2.3 mm, or
60 % of the largest body since 2026-09-05), so their on-screen size
tracked the zoom. Shapr3D's picker is a fixed fraction of the view.

Fix (3004c48): `PlanePickerTile.screenProportional` — the origin tiles are
unit rectangles that the renderer resolves per frame and the hit test per
tap from the same gizmo unit at the origin (`gizmoScale(origin:)`, the
scale that keeps the move gizmo a constant size on screen), 1.5 gizmo
units to the outer edge — about a third of the view's half height — so
what is tapped is what is drawn, at any zoom. Without a viewport (unit
tests) the 2.3 mm default holds. The scene-extent rule is gone with the
problem it patched.

Gate (/tmp/os3d-picker-20260914.xcresult): PlaneTests 3/3,
HeavyMeshGuardTests 7/7 (its scene-extent test rewritten to the new
rule), SectionDisplayTests 7/7, SelectionUXTests 16/16, PlanesUITests 6/6.
On-device look: Jason's next iPad session (the build is installed).

## 2. Tapping a rotation ring: empty field, no keypad; nothing lit

Tapping a move-gizmo arrow opens the distance field with the app's own
keypad. Tapping a rotation ring opened the angle field but relied on
focusing a SwiftUI text field from the overlay to raise the system
keyboard — on the iPad nothing came up, leaving an empty field. And
neither a tapped arrow nor a tapped ring was drawn any differently while
its entry waited for a value: every handle stayed white.

Fix: `RotationAngleField` now has the same shape as `MoveDistanceField` —
the keypad comes up with the field, its keyboard key hands over to the
system keyboard. `EditorViewModel.litGizmoPart` (landed with 3004c48) is
the dragged/hovered part, else the part whose typed entry is open, and
`MoveGizmoOverlay` draws that one lit. The overlay exposes the lit state
(`GizmoAxis-*` / `GizmoRing-*` accessibility value "lit"/"idle") so the
UI suite can see it.

Gate (ba42c5b, /tmp/os3d-gizmo2-20260914.xcresult): GizmoFlowUITests 3/3 —
testTappingARingOpensTheAngleKeypadAndLightsTheRing,
testTappingAnArrowOpensTheDistanceKeypadAndLightsTheArrow, and the
existing drag test. On-device look: Jason's next iPad session.

## 3. Copy badge ignored by a typed distance

With the Copy badge on, tapping a move arrow and typing a distance moved
the original body; only a dragged move honoured the badge (the drag path
duplicates in `beginMove`, the typed path built its transforms directly).
Shapr3D's Copy applies to either.

Fix: `commitAxisMove` duplicates first when the badge is on (the same
`duplicateSelectionForDrag` / image duplicate the drag uses), moves the
duplicate, resets the badge and leaves the copy selected; a face move or
a model-mode sketch move clears the badge, as the drag path does (Copy is
a whole-body affordance). A typed rotation already went through
`beginMove` and honoured it.

Gate: GizmoTypedCopyTests 3/3 (typed distance with Copy on: two bodies,
the original at rest, the copy moved, the badge reset, history = Copy +
Move; Copy off unchanged; typed rotation with Copy on duplicates), with
ModelSketchTransformTests 7/7 and SelectionTests 14/14 on the iPad (A16)
simulator (/tmp/os3d-typedcopy-20260914.xcresult). UI test
GizmoFlowUITests.testCopyBadgeThenTypedDistanceMovesADuplicate written;
runs with the suite on the parity simulator. **On device:** Jason tested
the a282de6 build on the iPad — Copy then a typed distance moves the copy
and leaves the original ("it works", 2026-09-14).

