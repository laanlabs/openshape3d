# Parity continuation checkpoint

Updated September8,2026,09:13 EDT. Dedicated active session; no duplicate workers.

## Revision and ownership

Branch `fix/sketch-parity-foundations`, [PR29](https://github.com/laanlabs/openshape3d/pull/29).
HEADd984465 pushed (edge-layout documentation). Dirty constrained-drag fix:
SketchSolverBridge.swift, DragSolveBridgeTests.swift, EditorView.swift,
DragSolveUITests.swift; new drag receipt/checkpoint.
Pre-existing untracked IDENTITY.md/SOUL.md/USER.md preserved.
**Actual running work:** no test/build/Peekaboo child process. Dedicated session
active, exclusive desktop; next paired constraint removal/settings checks.
Last UI run exec7390 completed0: exact locked-line drag/geometry Undo/Redo passed.
Initial14unit passes + corrected1UI pass, NOT a clean combined run. Failed old
armed-Line fixture, two-point-rect marker assumption and stale AX title diagnostic
retained. Diagnostic AX source removed; no history implementation change.

Simulator AC2FD923-1661-435F-BF47-3E9DF30D1A16 (iPad13M5/iOS26.5), window2386.
Portrait window683×940 at275,44; landscape887×737. Tests force portrait/reset store;
query actual state after run, do not assume old Untitled2 survives.
Native Shapr3D window1924 at99,79 **now1293×743** after successful corner drag.
Front Sketch02 has left600×150mm and right580×165mm rectangles, left top edge selected.

Latest collected/tested executable SHA256 (resize build):
`7a49dcfed7caa38bc954dc021b9bce065ea2b13c71468299cb4206bc048132e6`.
No device artifact claim.

## Latest verified outcomes

- 0e02425 active-plane grid: clean21/21 Plane/Camera/UI; live Front/Right/Top grid
  and empty Front cancellation. `testing/sketch-parity-plane-grid-2026-09-08.md`.
- 7400e01 circle readout without auto-keypad: clean4/4; paired endpoint-start and
  diameter edit preserve source geometry. Concentric and3point cancellation
  documented02a50fa. `testing/sketch-parity-line-circle-2026-09-08.md`.
- b18e4a8 diagonal lower-left correction: clean22/22; paired reverse-width and
  down/right-height samples match native. Earlier first-corner generalization
  superseded, historical evidence retained. Center/explicit relation fallback
  unchanged. `testing/sketch-parity-diagonal-anchors-2026-09-08.md`.
- 4c1120e pending numeric click-away: native Escape cancels, blank click accepts;
  clone corrected. Live2→3 blank and3→4 Circle switch, height1.5 preserved; zero
  rejects without mutation. Initial3pass/1failure then targeted1pass after waiting
  for asynchronous single-tap recognition; NOT one combined clean run.
  `testing/sketch-parity-numeric-dismissal-2026-09-08.md`.

## Latest correction / exact next action

Constrained endpoint projection is regression-tested and paired live. Clone fresh
Untitled2 Top landscape: locked171,515; free352→383,y515,3→3.5mm. Native locked
401,455; free632→661,y455; unrelated rectangles unchanged. No false conflict.
Receipt: testing/sketch-parity-constrained-drag-2026-09-08.md.
Live executablee0c92bc8929490962e12311111f0a2d222f8a12b114f9e4605cd934076ec08ec
includes temporary toolbar AX titles removed before commit; solver unchanged.

**Next:** paired point-lock removal and free drag, then constraint/snap settings
using available rail settings. Native foreground, free right endpoint661,455
selected, lockedleft401,455. Clone Untitled2 line3.5mm, lockedleft171,515,
right383,515 selected. Click coordinates window-relative, drags global.
No parallelGUI/tests. Remaining numeric/layout partial: right-palette Settings
click no observed sheet, compact/system keyboard untested. Full queue below.

## Publication and retained audit

Evidence root:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/`
Folders history, planes, line-cancel, quadrants, numeric, layout.
[Illustrated Doc](https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit)
verified76inline images; corrected drag text and both PNG hashes matched anonymous
DOCX export. `published-drag-fixed.docx`, `drag-fixed-publication.json`; master
constrained-drag update also verified.
Numeric corrected64image export retained; anchor58image export/master roadmap
verification retained. Final gallery-reopen publication completed earlier this
milestone (clone1.5/0.5,native140/50). Full42issue audit and56QA recipes preserved.
[Master roadmap](https://docs.google.com/document/d/1LyptlUULQ6e4yWiBz9QBMgxvZKoft6bhAhISfRvHXdE/edit)
plan/anchor and latest numeric/resize updates verified by anonymous export.
Browser profileopenclaw, illustratedt11, mastert13; no need recreate tabs/docs.

## Unresolved input/history and remaining gate

Live Peekaboo Undo/keyboard delivery still unresolved despite foreground, exact
coords, held/synth input and settled captures. XCTest geometry/profile history
passes, including gallery reopen; do not promote to live/device sign-off or make
speculative history changes. Native Escape clears line preview; clone delivery
not observed. `testing/sketch-parity-milestone-start-2026-09-08.md`.

Working capture: `peekaboo see --app ... --window-id ... --no-web-focus --path ...`.
Inspect saved images; command exit alone is not evidence. Immediate captures may
show older Metal frames: settle1sec ordinary,2sec camera/cancel, recapture if odd.
Clicks window-relative; drags global. Simulator keyboard capture restoredOFF;
Hardware Keyboard stayschecked. No permission/security/service changes.

Continue ordered plan `SKETCH_PARITY_NEXT_MILESTONE.md` and full acceptance matrix:
remaining quadrants/axis orders/constraints, numeric/layout, selection/snapping/
trim/move, persistence/profile/extrusion, final revision regression, verified
publication, identified installable iPad build and short Pencil A/B checklist.
Core history blocker means not candidate-ready. Simulator build is not device
installation. No merge/restart/logout/lock/Screen Sharing changes, no credentials.
Preserve existing30minute watchdog; never claim a stopped turn is a live worker.
