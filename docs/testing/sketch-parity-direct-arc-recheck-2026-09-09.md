# Direct arc endpoint input recheck — September 9

Baseline3ca4c2d. Native Shapr3D1924 Front, main Untitled Project Sketch03;
OpenShape3D5147 portrait simulator, Untitled2 Sketch2, latest topology build.
Scales differ. No Pencil/device evidence.

Native two endpoint clicks900280→1040280 created a45-degree arc with radius
and sweep readouts. Repeated isolated600540→760540 also produced45 degrees.
Return left the geometry/readouts visible; not proof of a finish-state change.
Dragging the first arc midpoint instead began another arc. An intervening
More-menu coordinate was mistaken for Arc and selected Circle: created a large
circle, then moved it while selected. These attempts are excluded. Subsequent
Undo attempts did not visibly remove that circle. No cleanup success claimed.
Native following drag600650→760650 instead connected to the prior760540 tip;
continued endpoint acquisition remains under investigation.

Clone Arc armed, taps300350→460350 created no arc; inspected screenshot.
Chord drag over the same points created its pending arc with radius-only
readout. Confirmed missing two-click construction route. Added snapped first/
second endpoint route to the existing PendingArc machinery; repeated first point
cannot create a degenerate arc. Tool switch, stroke start and history clear the
unfinished first endpoint. Existing default shape/bulge/finish behavior unchanged.

First run93730 exited65 at test-helper Float/Double ray conversion before tests.
Helper corrected; second serial arc unit/UI regression result pending. Live post-fix,
history/reopen and screenshot publication pending. Initial native45-degree
versus clone quarter-chord sagitta, pending labels/feedback, native finish and
bulge acquisition remain open; no fullQA13 pass.
Evidence /tmp/os3d-direct-arc-*.png; durable copy follows.

Diagnosis publication: illustrated187 placements and all3 PNG hashes verified
by /tmp/os3d-direct-arc-diagnosis-illustrated.docx. Full native/clone screenshots
and export retained in durable transform-controls evidence folder. No post-fix
claim in the published addendum.

Regression history: corrected run59803 exited65:3/3 new unit checks and existing
arc sweep/radial numeric UI passed; new two-tap UI failed at reselect radius.
Its immediate pending screenshot was blank, but saved gallery contained an arc
between later taps rather than expected first/second. Live settled clicks250300
then450300 created the expected horizontal-chord pending arc. No production
change made for this diagnostic. Test now settles the final camera transition,
each endpoint tap and tool toggle before reselect; targeted82401 running.
The UI test reset the disposable simulator gallery via its existing fresh/reset
launch convention; previous Untitled2 topology samples are no longer present.
Prior screenshots, read-only geometry fixture and verified exports are retained.
Current live project is test Untitled, Ground/Top; native remains Front. Distinct
plane/scale and test-reset state recorded, not hidden.

Final targeted82401 passed1/1 with settled camera/tap/tool transitions; app code
unchanged after original two-click addition. Five distinct checks pass across
runs, not one clean combined run. New fresh live250300→450300 arc, blank500750
commit, toolbarUndo removal/Redo restoration and reselectR1.553mm/106.26° passed.
Native CmdZ removed its latest connected arc and CmdShiftZ restored it. Paired
finalgallery reopen retains native arcs and clone arcs; clone readouts and radius
keypad re-open after saved recovery. Native large circle from excluded menu
misstep remains in test sketch, not a corrected/accepted arc sample.

Final publication verified: illustrated191 placements/all4 new result PNG hashes;
master38 image placements/finalreopen note. Exports os3d-direct-arc-final-
illustrated.docx and -master.docx retained in durable transform-controls folder.
No fullQA13 or candidate-ready claim. Next: reverse-order native default curvature
and exact construction feedback, while preserving existing drag/bulge behavior.
