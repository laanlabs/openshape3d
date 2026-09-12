# Nested-profile acceptance — September 9

Baseline ed0a004 pushed. No code change or test runner for this lane.
Native Sketch03 Front: outer circle diameter3400 at680510 and inner1200,
concentric. First inner attempt moved selected outer; next hit its label;
a stale More target selected Arc and created an arc, undone and screenshot
verified removed. Correct fresh Circle menu selection then created inner circle.
Model-mode click635510 selects annulus only, inner disk stays unselected.
Native solid extrusion is still pending; One-Sided menu selections alone did
not expose a distance control. Current view navigation trying cube corners;
no native body created in this recipe yet.

Clone Sketch2 (same project as reference-fill sample): outer circle300400 r70,
inner300430 r20, offset nested rather than concentric. OldSketch1 circle430450
remains separate. Exit and click260400 selects surrounding region separately.
Distance field custom keypad: physical typing did not change0; on-screen1
appended01; first immediate commit did not settle, second commit produced a
solid with visible inner wall/opening. No full through-hole/reopen claim yet.
Screenshot os3d-nested-clone-preview-settled.png inspected. Native annulus
os3d-nested-native-annulus.png inspected. Exact dimensions differ with zoom;
current paired result is nested-region selection only, not identical geometry.

All screenshots retained locally in transform-controls report directory.
Publication pending. Next: complete native extrusion/through-hole and paired
history/reopen, then focused existing profile geometry checks as appropriate.

## Final sampled nested-profile result

Native double-click view cube exposes default oblique view; reselect annulus
and click0mm badge. Typed500 and committed: Body02 with visible bore. Undo
removesBody02, Redo restores; gallery reopen retains body/bore. Clone Undo
removes its offset-hole solid, Redo restores; gallery reopen retains it in
oblique view. Images inspected. Native concentric and clone offset samples
are different geometries: paired result is nested-region/extrusion/history/
persistence behavior, not equal dimensions or complete topology acceptance.

Existing ProfileTests completed clean15/15, including through-hole ray probe,
/tmp/os3d-nested-profile-20260909.log/.xcresult, serial41439 completed0. No
implementation changes in this lane. Illustrated147 images with both final
reopen PNG hashes matched; master38 final15/15 note verified. Exports/evidence
copied to durable transform-controls report. Touching loops, tiny gaps,
duplicate edges, downstream rebuild and device artifact remain open.
