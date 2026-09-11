# Sketch parity — snap categories (September 11, 2026)

## Scope and status

QA-19 asks whether Grid, Sketch Guide Lines, Sketch Guidepoints, Face Guidepoints,
and Snapping Hints can be controlled independently and whether acquisition is
truly free when the acquisition categories are off. This checkpoint remains
**partial** pending one clean native 3D-Guide-Points on/off near-threshold repeat.
It does not close QA-20 zoom or QA-21 hover/feedback.

## Existing paired evidence retained

- `sketch-parity-snap-lock-2026-09-08.md`: paired all-acquisition-off free input,
  Grid-only input, Guide-Lines-only input, and settings persistence.
- `sketch-parity-preplacement-snap-2026-09-08.md`: paired Sketch Guidepoint
  near/far acquisition at two clone scales.
- `sketch-parity-drawing-on-points-2026-09-11.md`: paired exact top-face-corner
  circle placement, Undo/Redo, and clone reopen.

## Confirmed interaction defect and correction

The first expanded settings regression exposed a reproducible defect limited to
Snapping Hints: its row was reported hittable, but tap, label tap, and swipe did
not change the value. The other four settings had already persisted off. The
last row now uses an explicit trailing switch inside the unchanged visual row.
This gives the control its rendered 44-point switch target instead of the full
Form-row accessibility frame. The settings test also includes the previously
omitted Sketch Guide Lines toggle and uses a finite reveal helper.

Exact-build Peekaboo verification toggled Snapping Hints off and Face Guidepoints
off independently. A seeded top-face sketch then showed a raw, visibly displaced
circle centre with Grid and Face Guidepoints both off. Face Guidepoints could be
restored without changing the other stored categories. A controlled repeated
near-threshold on/off gesture was outside the screen-space tolerance after
Simulator coordinate quantization, so it is retained as inconclusive rather
than claimed as a live snap distinction.

## Regression history

- `/tmp/os3d-qa19-category-matrix-20260911.xcresult`: 20/21; initial expanded
  run failed only at the nonresponsive Hints switch.
- `/tmp/os3d-qa19-settings-center-taps-20260911.xcresult`,
  `/tmp/os3d-qa19-settings-frame-diag2-20260911.xcresult`,
  `/tmp/os3d-qa19-settings-trailing-switch-20260911.xcresult`, and
  `/tmp/os3d-qa19-settings-switch-swipes-20260911.xcresult`: retained failed
  interaction diagnostics; no product pass is inferred from them.
- `/tmp/os3d-qa19-settings-h-row3-20260911.xcresult`: corrected targeted 1/1.
- `/tmp/os3d-qa19-category-matrix-final-20260911.xcresult`: final clean **21/21**
  in one serial run: 20 AppSettings/Foundation/LineGuide tests plus the five-row
  settings persistence workflow.

## Evidence

Local evidence and exact hashes:
`~/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/snap-categories/`.
Publication is pending and must be hash/export verified before counting.

## Remaining closure step

Repeat one near-threshold top-face-corner gesture in native Shapr3D with Grid
off and 3D Guide Points off/on, then the same calibrated gesture in the clone.
If both pairs distinguish raw versus acquired placement and the report is
published without duplicate images, QA-19 can close. Physical Pencil input
remains QA-52 and is not inferred from Simulator evidence.
