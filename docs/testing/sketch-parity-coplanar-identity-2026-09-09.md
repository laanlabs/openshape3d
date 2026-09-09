# QA-48 coplanar sketch identity — September 9, 2026

Baseline69d3bba pushed. Native Front current geometry belongs to Sketch02
(Items). Exit, blank deselect, Sketch starts new Sketch03 in same Front plane.
Existing02 geometry turns gray; drawline800600→950600 belongs to03; exit/Items
shows both. Explicit Items02 immediately opens02, preserving03 separately.
Screenshots /tmp/os3d-coplanar-native-{items,new-entry,independent-line,two-items,select-old-item}.png.

Clone Front Sketch1 has Ø2 circle430450. Exit, no selection, Sketch→Line→Front
tile450340, drawline300600→450600. Circle is active blue throughout; exit/Items
still only Sketch1 containing both. Explicit item entry also reopens1. This
confirms the old first-coincident reuse rule prevents independent same-plane
sketches; geometric plane equality must not imply sketch identity.

Correction: plane-based creation always allocates a uniquely named new sketch;
explicit item/outline routes and tool switching continue their chosen sketch.
New unit coverage checks separate geometry ownership/undo, empty new entry
leaving a hidden old sketch untouched, and named continuation. New UI checks
two same-ground entries produce two rows and named continuation no third row.
Serial21925 running: SketchIdentityTests, PlaneTests, HistoryProfileEditTests,
PlanesUITests. Simulator exclusively reserved. Live postfix/publication pending.

Initial21925 compilation failed: new Plane UI test referenced an absent local
attach helper. Added helper; no tests ran in first attempt. Corrected serial76929
running /tmp/os3d-coplanar-r2-20260909.log/.xcresult.

Diagnosis publication verified: illustrated138 images and all3 new PNG hashes
matched /tmp/os3d-coplanar-diagnosis.docx. Twelve unit checks and first two UI
checks passed so far in corrected run; full result still pending.

Post-fix live recipe: fresh Front circle inSketch1, exit/no selection, Front
plane entry and isolated line inSketch2; Items must list2. Explicitly open1
and editcircle without addingline to1; independent visibility and gallery reopen
should retain membership. Compare inactive geometry treatment to native gray
reference (native-independent-line.png). Native explicit02 route already sampled.

Corrected76929 completed0:12unit+4UI=16/16 in one corrected run; first attempt
compile-only failure retained. Fresh live Front: circleØ0.992 inSketch1; exit,
newFront line300600→450600 inSketch2. Items lists2. Hide2 removesline only;
unhide/open1 editscircle toØ1 with line unchanged/inactive. Hide1 removescircle
only. Galleryreopen retains twoitems, hidden1, visibleline2. Native Items02 hide
leaves new03 line; galleryreopen retains hidden02/visible03. Both final hidden
reopen screenshots inspected. No full QA48 consumed/downstream matrix signoff.

New visual followup: clone inactive circle remains blue-filled while drawing in
newSketch2; native oldcircle is clear gray while drawing03. See
os3d-coplanar-post-new-entry.png vs native-independent-line.png. Identity is
verified independently; inactive profile rendering remains a confirmed gap.

## September 9 — independent coplanar sketch identity (f4319dd)

Paired native unselected Front entry creates03 independently of02; clone first-
coincident reuse incorrectly joined new geometry to1. Plane-based creation now
allocates a new identity; explicit named item/outline continuation is retained.
Corrected16/16 (12unit+4UI); initial missing-helper compilation failure ran no
tests. Live independent circle1/line2, named edit, independent visibility and
paired gallery reopen with hidden old/visible new sketch verified. Consumed/
overlapping selection/downstream variants remain open.
[Receipt](testing/sketch-parity-coplanar-identity-2026-09-09.md).

Illustrated142 images/all4 final hashes and master38 final note verified.

Inactive profile blue-fill gap now under separate focused regression4410;
rendering keeps all unselected profiles clear during sketching, while preserving
model-mode extrusion fills. No live post-fix claim yet.

## September 9 — inactive reference profile fill verified

Focused serial4410 completed clean6/6 (4 SketchIdentity unit + 2 Plane UI).
No runner remains. Fresh live Front circle1/line2: inactive circle clear during
Sketch2 editing; Exit restores profile fill; interior selection offers Extrude,
cancelled without creating a body. Gallery reopen retains two items and clear
reference while explicitly reopening2. Native reopened03 likewise shows old02
clear; normalized Front screenshot inspected. Reference color/style differences
remain outside this fill correction. Consumed/overlap/downstream cases remain open.

Illustrated145 images and all3 new PNG hashes verified by anonymous DOCX export;
master38 final reopen note verified. Evidence os3d-reference-fill-native-front.png,
os3d-reference-fill-final-reopen.png, os3d-reference-fill-extrude.png and exports
retained in workspace reports/openshape3d-core-sketch-milestone-2026-09-08/
transform-controls. No iPad-ready claim.
