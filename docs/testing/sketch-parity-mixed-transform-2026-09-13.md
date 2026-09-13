# QA-45 — mixed selection exact values; compact layout (2026-09-13)

Open scope from the Sept 11 checkpoint: "a fresh paired mixed primitive
selection and compact viewport control-layout comparison".

## Gap found and fixed — no exact values for a mixed selection

Clone: `usesExplicitSketchTransform` only opted single lines/rectangles and
single radial entities into the Move/Rotate button, so a mixed selection
(line + circle) had the drag gizmo only — no typed X/Y/angle. Native offers
Move/Rotate arrows with a keypad for whatever is selected. The typed path
(`commitSketchTransformControl` → `updateSketchTransformControl`) already drove
the selection-wide gizmo baseline (the Sept 11 unit test proved it for a mixed
set); only the button's visibility rule blocked it. Fix: the Move/Rotate pill
shows for any non-empty sketch selection (EditorView). **Fixed at d790646.** Gate: ConstraintApplyTests +
SketchTransformUITests (new testMixedSelectionOffersExactMoveRotate: line and
circle by drag, Items row selects both, Move/Rotate → X → typed 2 commits an
undoable step) — 84/84, 0 skipped, one clean serial run
(/tmp/os3d-qa45-ipad2-20260913.xcresult).

Clone live (bridge-seeded "Mixed" sketch: line (−3,0)→(3,0), circle c(0,−4)
r1.5; Items row selects both, Total Length 15.42 mm): Move/Rotate pill present
(clone-03), explicit controls appear (clone-05), X arrow opens exact entry
(clone-06), keypad 2 ✓ → line a.x −3→−1 and circle centre x 0→2 in one
"Move" step (clone-07); Undo restored both, Redo re-applied (bridge
/v1/sketches). Hardware keystrokes do not reach the app's custom keypad; the
value was entered through the keypad buttons.

## Native — mixed selection not deliverable here

In Sketch 04 a plain click on an arc replaced the selected line (native-07/08);
a zero-length shift drag cleared the selection (native-10); the long line
runs off-screen so a marquee cannot enclose a mixed pair. Native's exact-value
keypad on the Move/Rotate arrow was observed earlier for a single selection.
The mixed native comparison therefore remains "supported-input blocked", as
the Sept 11 checkpoint recorded.

## Compact layout (iPhone 17 Pro, iOS 26.5)

A compact-width check of the sketch Move/Rotate controls was attempted as a
new CompactWidthBarUITests case and is **not committed**: at compact width the
drawn line could not be selected in XCUITest by either route tried — tapping
midway between its two SketchPointMarker elements, or the Items row (the
compact toolbar has no ItemsButton) — so the pills were never reached (three
runs, /tmp/os3d-qa45-iphone{2,3,4}-20260913.xcresult). Whether that is a
compact-width selection defect or a test-harness artefact is open; the
hierarchy dumps show the line's markers present and no "Length" readout after
the tap. **Pre-existing failure found:** testExtrudeBarIsUsableAtCompactWidth
fails on the branch — the extrude bar covers the tool palette's Delete entry
(not hittable). Not fixed here; recorded under QA-53 as a confirmed
compact-layout bug.

## Result

Mixed-selection exact values: clone gap closed at d790646, live-verified;
native comparison still input-blocked. Compact layout: transform-control check
open (line not selectable at compact width in XCUITest — diagnose); extrude-bar
defect logged. Partial; no promotion. Evidence:
…/planes/qa45-mixed-transform-live-2026-09-13/ — 11 assets,
evidence-index.json. **Published 2026-09-13 17:51 UTC:** https://docs.google.com/document/d/1VE2Yq2sPpUiHWFY5U2OdQnWtaXiFYkh0-0oygXDqNys/edit. 32/0/1/23; iPad unchanged.
