# Radial handle viewport origin — September 9, 2026

Starting revision `02b304e`. Native Shapr3D window1924 versus OpenShape3D
simulator5147, Front view, portrait simulator, mouse/Peekaboo healthy GUI bridge.
Different physical scales; compare handle relative to rim and coordinate origin.

## Confirmed mismatch

- Native free circle center1000,610, radius42 screen px: radial handle near1000,550,
  beyond the upper rim568. `os3d-free-circle-native-selected.png`.
- Clone circle center450,650, radius40px: radial glyph near450,638, inside upper
  rim610 and overlapping diameter text. `os3d-escape-reopen-final.png`.
- Native arc center811,426, top405: radial glyph near811,386, outside the rim.
  `os3d-readouts-native-arc-normal.png`.
- Clone arc center280,460, top360: radial glyph near280,394, inside the arc.
  `os3d-readouts-free-arc-normal.png`.

Source inspection: radial overlay alone lacked the full-viewport frame and
safe-area override used by adjacent transform and rectangle overlays. Projected
world points therefore acquired an extra safe-area origin. Existing resize tests
found the displaced accessibility handle and passed, without checking placement.

## Correction and verification

Radial overlay now fills/ignores safe area like its viewport. No radius/constraint
solver or stored geometry change. Existing circle and arc UI tests strengthened:
handle center must lie beyond the drawn upper rim, then actual radius change,
driving-size refusal and history continue through existing workflows.

Serial66209 owns simulator: `/tmp/os3d-radial-origin-20260909.log` and `.xcresult`.
Post-fix tests and paired live portrait/landscape, free/driven/history/reopen are
pending. No pass implied by implementation. No device/Pencil or full layout claim.

Evidence retained under workspace report `transform-controls/`; existing paired
normal-state screenshots are reused, not described as newly captured here.

66209 completed clean2/2, no failures,95.99seconds. Both outside-rim assertions
and existing radius/history workflows passed. Exclusive live testing resumed.

Live portrait correction: circle center450650/rim610 now has handle450592,
18px beyond rim. Drag from painted handle changes diameter0.992→1.74 with center
unchanged. Undo0.992/Redo1.74 restored. Matches native outside-rim placement.
Fresh native radial-drag repeat produced no geometry change, so excluded from
resize evidence; subsequent Undo reached prior arcR500 edit, reapplied with Redo.
SynthOnly retry also no change and reports local runtime despite bridge parameter;
input-delivery limitation retained. No speculative native/clone geometry change.
Earlier native radial resize reference remains in circle-radial-handle receipt.
Current correction changes coordinate placement only. Landscape check underway.

Settled landscape: circle525509 rim456/handle439 retains outside-rim placement.
Painted drag changes diameter1.74→2.402; Undo restores1.74. Typeddiameter1 retains
handle outside rim; painted drag refuses with notice and diameter1 unchanged.
Landscape free arc center280410/rim310 has handle280291 (outside), clear of106.26
sweep text. Live arc drag/history and return-to-portrait follow.
Initial landscape capture occurred during rotation animation; use settled capture,
not the transitional skewed image, for placement evidence.

Arc live resize R1.654→1.985 preserves center280410/sweep106.26; Undo1.654,
Redo1.985. Return portrait handle remains18px outside rim (arc partly offcanvas,
no pan/geometry mutation). Gallery reopen retains R1.985/106.26 and circleØ1,
with normal handles outside rim. Selecting circle initially added it to the arc;
blank-deselect then single-circle selection restores scoped normal handle.
Illustrated112 images/all4 new paired PNG SHA256 values matched exported media.
Both final result/reopen notes inserted; export verification before commit.

Both final notes export-verified (illustrated112/master38 images).
