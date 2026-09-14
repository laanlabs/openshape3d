# QA-18 drawing-on-points audit — September 11, 2026

## Scope and current verdict

QA-18 passes its finite recipe. Endpoint, existing-circle-center,
rectangle-corner, line-midpoint, and top-face-corner initiation all have paired
live evidence. History preserves the source geometry and the corrected clone
retains the face-corner result after gallery reopen. The 56-case inventory is
now 11 passed / 0 failed / 1 device-blocked / 44 incomplete.

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

## Face-corner placement and history

- A fresh closed rectangle was extruded in each app, its top face was selected,
  and a Circle was started at the corresponding face vertex.
- Native Shapr3D and OpenShape3D both released a circle centered on that face
  corner. In both apps Undo removed only the new circle and left the body/face
  intact; Redo restored the circle at the same corner.
- OpenShape3D gallery reopen retained the body, face sketch, and corner-centered
  circle. The perspective reopen image projects the circle around the top-face
  vertex; it is not an offset construction plane.
- This closes point placement only. Face editing, topology changes, hover, and
  physical Pencil/touch remain covered by their own acceptance lanes.

## Regression history

- `/tmp/os3d-qa18-midpoint-20260911.xcresult`: 0/2. Both workflows reached the
  radial-label assertion, but the fixture assumed a diameter label while the
  saved Always Radius preference correctly produced radius labels. Retained as
  a fixture failure, not a product failure.
- `/tmp/os3d-qa18-midpoint-radial-aware-20260911.xcresult`: clean 2/2 with no
  failures or skips. It covers Circle creation at a rectangle corner and at a
  horizontal-line midpoint through the visible constraint badge.
- `/tmp/os3d-qa18-point-placement-final2-20260911.xcresult`: clean 13/13 in one
  serial current-tree run with no failures or skips: ten `FaceSnapTests`, the
  sketch-on-face downstream UI workflow, and the two armed-Circle corner/
  midpoint workflows.

## Evidence

Local paired PNGs and exact hashes are stored under:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/drawing-on-points/`

The midpoint checkpoint illustrated export contains 779 image placements. The
closure export contains 786: all seven face-corner hashes occur exactly once,
and none of the 779 predecessor hashes were lost. The master export retains 38
media and contains the dated QA-18 closure/inventory note. Verified exports and
SHA256 lists are stored under the `drawing-on-points/face-corner` directory.
The immutable `05be744` IPA was not modified or installed.
