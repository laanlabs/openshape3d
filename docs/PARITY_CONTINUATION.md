# Parity continuation checkpoint

Updated September8,2026,08:45 EDT. Dedicated active session; no duplicate workers.

## Revision and ownership

Branch `fix/sketch-parity-foundations`, [PR29](https://github.com/laanlabs/openshape3d/pull/29).
HEADe004769 pushed. Dirty: edge-layout documentation, acceptance matrix and
this checkpoint. Pre-existing untracked IDENTITY.md/SOUL.md/USER.md preserved.
This session exclusively owns desktop; parent does not operate it. No subagents.

**Actual execution:** exec38658 completed0, clean15/15 (11Camera+4Dimension)
at08:34:50 EDT. No test/Peekaboo worker active between interactions. Live corrected
portrait↔landscape rotation passed without canvas refresh; Doc68images and master roadmap update verified.
Reconcile actual processes on resume.

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

## Current confirmed discrepancy / exact next action

Clone portrait→landscape rotation stretched cached Metal rectangle while markers
reprojected correctly. Waiting/opening keypad did not fix; tool-off scene redraw
aligned them. Native corner-resize preserved aspect/alignment. Direct native
resize command failed mutation-receipt validation; only actual corner drag counts.
Renderer now requests `setNeedsDisplay` on drawable-size change.
`testing/sketch-parity-resize-rendering-2026-09-08.md`.

**Next:** checkpoint edge-layout documentation then start paired selection/
editing integrity. Numeric/layout remains partial: right-palette Settings click
has no observed sheet, compact/system keyboard untested. Do not mark those passed.
Clone landscape887×736 at275,44,Untitled2 Top Rectangle armed, no editor;
rectangles4×1.5(center) and3×0.5(bottomright504–686,y575–606). Native1293×743 at99,79,
FrontSketch02 Rectangle armed,three rectangles:600×150,580×165,700×125bottomright.
Edge-height keypad/commit usable in both; receipt sketch-parity-edge-layout-2026-09-08.md.
No running test/Peekaboo worker between calls. Continue independent core checks.

## Publication and retained audit

Evidence root:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/`
Folders history, planes, line-cancel, quadrants, numeric, layout.
[Illustrated Doc](https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit)
verified72inline images, all4edge-layout PNG hashes/text matched anonymous DOCX
export. `published-edge-layout.docx`, `edge-layout-publication.json`.
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
