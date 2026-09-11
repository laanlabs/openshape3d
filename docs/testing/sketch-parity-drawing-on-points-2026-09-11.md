# QA-18 drawing-on-points audit — September 11, 2026

## Scope and current verdict

QA-18 remains partial. Endpoint, existing-circle-center, rectangle-corner, and
line-midpoint initiation have paired live evidence. Face-corner initiation is
still untested in the current finite recipe, so this receipt does not close the
case or change the 56-case acceptance inventory.

## Confirmed midpoint discrepancy and correction

- Native Shapr3D starts a Circle at the midpoint of an existing horizontal
  line, retains the source line, and shows the new circle centered on it.
- Before the correction, OpenShape3D's visible horizontal-constraint glyph
  intercepted the same armed Circle stroke. Exact-midpoint and within-snap
  drags produced no circle.
- Ordinary constraint glyphs now remain visible but stop hit-testing while a
  drawing tool owns the canvas. Dedicated center Lock controls remain separate
  and interactive.
- On the exact corrected build, OpenShape3D creates the circle through the
  visible midpoint glyph and retains the source line. Undo removes only the
  circle; Redo restores it at the same midpoint; gallery reopen retains the
  profile. Native Undo/Redo shows the same geometry lifecycle.

This comparison proves point placement and input routing. It does not infer a
persistent midpoint constraint: that relationship is not imposed without a
separate paired movement comparison.

## Regression history

- `/tmp/os3d-qa18-midpoint-20260911.xcresult`: 0/2. Both workflows reached the
  radial-label assertion, but the fixture assumed a diameter label while the
  saved Always Radius preference correctly produced radius labels. Retained as
  a fixture failure, not a product failure.
- `/tmp/os3d-qa18-midpoint-radial-aware-20260911.xcresult`: clean 2/2 with no
  failures or skips. It covers Circle creation at a rectangle corner and at a
  horizontal-line midpoint through the visible constraint badge.

## Evidence

Local paired PNGs and exact hashes are stored under:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/drawing-on-points/`

The illustrated Google Doc export contains 779 image placements, all seven new
published hashes exactly once, and no loss from the 772-image QA-15 export. The
master export retains 38 media and contains one QA-18 midpoint note. Verified
exports and SHA256 lists are stored beside the PNGs. The immutable `05be744`
IPA was not modified or installed.
