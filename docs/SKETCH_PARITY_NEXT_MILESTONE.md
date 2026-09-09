# Next milestone: core-sketch acceptance and iPad comparison candidate

Planned September 8, 2026. Starting revision `cd0937d`, PR #29.

## Outcome and boundaries

Deliver a screenshot-backed, reproducible core-sketch acceptance report and an
identified installable iPad comparison candidate. This is not full Shapr3D
feature parity, nor physical Pencil sign-off. Preserve all 42 existing audit
records and map the original 56 acceptance scenarios to covered, failed,
blocked, or explicitly deferred; do not silently narrow the audit.

Native macOS Shapr3D and mouse-operated iPad simulator remain the available
reference pair. Record version, build revision, input, plane, orientation,
settings, and project state. Differences in scale are acceptable when comparing
interaction semantics; record actual dimensions and anchors separately.

## Blocking on-canvas acceptance gate (Jason's subsequent steering)

Line, circle, rectangle and arc UI must be compared in drawing, selected,
unselected and numeric-edit states: label placement/style, dimension leaders and
arrowheads, handles, selection highlights, constraint icons, and keypad
appearance/activation/commit/cancel. Geometry-only passes do not satisfy this
gate. The agent identifies visible mismatches from paired screenshots; Jason is
not required to catalog them. Native macOS versus simulator scaling differences
must be recorded, not used to claim exact matching. Known visual differences
remain blocking until corrected or explicitly accepted by Jason.

## Ordered execution

### 1. Recover baseline and resolve history uncertainty

- Reconcile actual git state, active processes, installed simulator build, and
  desktop availability; replace stale running claims in the checkpoint.
- Use disposable projects and give one workflow exclusive desktop ownership.
- Repeat creation, dimension edit, Undo, and Redo in both apps, first in a new
  project and then after gallery reopen. Compare toolbar input and supported
  keyboard/accessible input independently; verify foreground delivery.
- Inspect geometry and usable closed profiles, not merely selection badges.
- Distinguish an input-delivery failure from product history failure before
  changing source. If one route remains blocked, explicitly retain that gap
  and continue independent acceptance rather than looping on identical clicks.
- Exit: demonstrated geometry restoration and no-op diagnosis, or an explicit
  reproducible blocker that prevents history sign-off. Fix confirmed app bugs.

### 2. Drawing, plane entry, and cancellation

- Compare XY/XZ/YZ entry, ground fallback, camera normal alignment, visible
  grid, exit/re-entry, and intended sketch identity on a coincident plane.
- Exercise line drag and supported tap-chain interaction, retained length,
  explicit numeric edit, next segment, finish, and half-finished cancellation.
- Test circle initiation at existing geometry without unintended movement.
- Cancel each rectangle construction stage and switch tools while numeric
  input is open; confirm no phantom geometry or blocked canvas remains.
- Exit: reproducible entry/draw/cancel flows, correct destination sketch, no
  unintended edits, coherent undo, and paired before/after evidence.

### 3. Complete rectangle and numeric-input matrix

- Diagonal rectangles: all four drag quadrants, width then height and reverse
  sequence, native anchor preservation, reselection, save/reopen, undo/redo.
  September8 paired evidence corrects the earlier first-corner assumption:
  sampled diagonal numeric edits preserve normalized lower-left bounds.
- Center rectangles: both axis-edit orders and center preservation.
- Three-point rectangles: opposite baseline directions/slopes, each dimension,
  reselection/reload, and interaction with explicit constraints.
- Numeric entry: initial replacement, decimal/sign where valid, commit/cancel,
  supported width-to-height navigation, invalid input, and tool-switch cleanup.
- Check keypad reachability near canvas edges in portrait, landscape, and
  compact layouts, including available handedness/system-keyboard modes.
- Exit: geometry and driving values agree; no undriven-side drift, inaccessible
  commit control, invisible input interception, or silent invalid conversion.

### 4. Selection, snapping, constraints, and editing integrity

- Compare endpoint/midpoint/outline/profile selection, blank deselection,
  additive selection, short entities and small profiles at multiple zooms.
- Exercise independent snap toggles, all-off coordinates, visible grid scale,
  guidepoint acquisition, and preference persistence; distinguish temporary
  snapping from persistent constraints.
- Validate common constraint creation/removal, lock, conflicts/rollback, and
  disconnect where supported. Existing relations must survive unrelated edits.
- Exercise basic trim and move/copy integrity, cancellation and coherent undo;
  preserve or explicitly account for affected constraint/dimension references.
- Exit: selected target matches action, no hidden quantization with snaps off,
  and no unexpected geometry jumps, data loss, or dangling references.

### 5. Persistence and sketch-to-solid handoff

- Exit/re-enter/reopen representative edited sketches with dimensions and
  constraints; verify intended visibility and separate sketch identity.
- Compare closed/open profiles, nested holes and construction geometry, then
  extrusion handoff. Open profiles must not masquerade as valid closed regions.
- Run the relevant final regression set on one identified final revision,
  serially, without simultaneous GUI automation. Report all failures/reruns
  accurately; do not sum historical runs into a clean-suite claim.
- Exit: no blocking crash, hang, data-loss, history or core interaction failure.

### 6. Publish acceptance and prepare device handoff

- Update the issue ledger and illustrated Google Doc with paired captions,
  expected/observed results and corrected outcomes, including the previously
  unpublished final gallery-reopen evidence. Verify saved/exported content.
- Publish a coverage matrix: implemented, regression-tested, live-compared,
  documented, device-tested, plus explicit failures/deferrals.
- Identify device build version/revision, artifact location and signing/install
  prerequisites. Verify an installable artifact before calling it a candidate;
  simulator output is not a device build. Do not collect credentials in chat.
- Provide a short physical iPad checklist: Pencil start/snap, draw/finish/cancel,
  dimension entry, selection, constraints, Undo/Redo, rotation and save/reopen.
- Do not merge or claim installation without authorization and verification.

## Evidence and fix loop

For every case: case ID linked to audit record; recipe/settings; reference and
clone captures; expected/observed behavior; verdict (pass/fail/blocked/not run);
source revision; test receipt; publication status; next action. Save evidence in
`reports/openshape3d-core-sketch-milestone-2026-09-08/` under the workspace.

Reproduce in both apps -> fix confirmed discrepancy -> focused meaningful
regression -> paired live recheck -> update ledger and publication -> next case.
Prioritize crashes/data loss first, then history and blocked drawing, then
geometry/constraint correctness, then reachability/discoverability differences.

## Scope and release gate

Advanced patterns, projection linking, ellipse/spline trim, comprehensive units/
variables and non-core dimension capabilities remain in the full audit queue.
Explicitly report any deferred core criterion: a deferral is not a pass. A core
blocker prevents candidate readiness; a reference/license/access limitation is
recorded as blocked rather than inferred from automated clone tests.

Milestone complete only when the core matrix has paired evidence, blocking UI
issues are resolved, relevant final regressions pass, documentation is verified,
and the identified installable build/checklist exists. Physical-input results
remain pending until actually tested. Keep working until that gate or a genuine
external blocker; a batch completion is not the stopping condition.

## Ownership and progress

Resume the existing dedicated “OpenShape3D parity — PR #29” session; do not create
duplicate desktop workers or watchdog jobs. Preserve temporary keep-awake
authorization but never restart, log out, change lock settings, or restart Screen
Sharing. If locked, continue useful independent code/tests/documentation.

Report concrete results and blockers, not reminder-only messages. Maintain
`docs/PARITY_CONTINUATION.md` with actual running state and exact next action.

## September8 execution checkpoint: full-turn boundary

Arc90/270 and native360 conversion sampled; corrected full-circle conversion has
clean25-test regression, live saved-radius migration and clone gallery reopen.
Return next to live history availability immediately after an edit and after
autosave, distinguishing disabled state from input delivery before changing code.
Candidate gate remains open; illustrated publication still blocked.

## September 8, 17:41 execution update

Four-line rectangle normal handle now live-compared through free/locked motion,
history and reopen. Next is axis-aligned rectangle edge/control behavior, then
remaining numeric/selection matrix. Both Docs Saving; no candidate gate claim.

## September 8, 18:46 execution update

Axis-edge controls and selected-side leaders verified; portrait painted-center
Undo correction passes live and focused clean2/2. Saved2x1 editors/reopen pass.
Next: paired per-edge Lock semantics, then remaining numeric/selection matrix.
Leader-side memory remains a known visual difference. Both Docs blocked;
publication and installable-candidate gates remain open.

## September 8, 19:03 execution update

Side-specific rectangle Lock now verified through free/blocked movement,
Undo/Redo, removal and reopened scope; final scoped36/36 clean. Next contextual
Unlock action and constrained-edge colors, then remaining acceptance matrix.
Docs publication remains externally blocked; candidate gate still open.

## September 8, 19:12 execution update

Contextual Unlock now live verified with history and reopened result; clean9/9.
Continue direct arc construction (QA-13 still untouched), retaining edge-color
and compact-menu differences. Publication remains blocked; final artifact/gate
not reached.

## September 8, 19:53 execution update

QA-13 direct arc now sampled but partial: mouse acquisition/completion remains
unresolved, not a pass. QA-38 native four-line edge Disconnect and Undo verified;
clone topology-only action under regression, live movement/reopen pending.
Primitive rectangle edges and midpoint/non-line connections remain open.
Both Docs still blocked; all new screenshots locally indexed. No candidate claim.

20:00 follow-through: four-line edge Disconnect now clean34/34 plus paired
movement/history/gallery reopen. Next remaining connection cases and generic
ring mismatch; publication remains blocked, candidate gate not reached.


## September 8, 22:11 execution update

Publication restored in separate existing-Doc tabs; old stalled tabs preserved.
Circle transform whole-Lock correction4a09b06 clean28/28 pluspairedlive/history/
reopen. Arc translation/rotation Lock correction now11distinctpassingchecks and
pairedlive/reopen. Continue remaining numeric/selection acceptance, including
circle diameter text covering explicit move target, fullsnap/gridmatrix and
primitive/mixedtransformlimits. Finalregression/installableartifact gateopen.

## September 9, 00:04 execution update

Explicit white transform controls, exact axis values, retained re-edits, rotated
local frame and circle frame-only history are implemented with focused regression
and paired live evidence. Settled native history correction cecd1f5 retains the
armed tool while clearing selection, rather than exiting it (earlier interpretation
withdrawn). Clean21/21 and live reselection/Done; illustrated102 images and master38
with correction notes export-verified. Escape keypad-first cancellation now under
regression. Remaining transform candidate/driven annotation visibility, overlap,
rotated direct-drag/Copy/compact coverage and full core matrix remain open.
No installable candidate or physical-device sign-off yet.

## September 9 — QA-13 third-point/chaining update

Native direct Arc now has an unambiguous recipe: two endpoints, a hovered/clicked
third point, then automatic shared-endpoint continuation. OpenShape3D matches the
available click/touch route and has automated hover coverage; final relevant
regression is clean 34/34. Major/minor boundary and tangent-transition cases
remain open, as does physical Pencil input, so QA-13 and the milestone remain
partial.

Prepared [physical iPad A/B checklist](SKETCH_PARITY_DEVICE_AB.md) September9.
Artifact fields explicitly pending; configuration is not installation/signing proof.

## September 9, 01:21 execution update

Near-rail circle diameter target/leader correction has paired live evidence,
final4/4 regression after documented compile/Top-limit failures, live edit/history
and paired reopen. Illustrated116/allfournewhashes and master38 final note
verified. Continue normal circular reselection/manual annotation positioning,
then remaining rotated/mixed/compact and core acceptance. Full visual gate and
identified device artifact remain open; no milestone/candidate completion claim.

## September 9 — manual circle diameter label placement

Free placement now lasts for the current selection; stored diameter placement
is independently undoable and saved relative to the circle center. Fresh paired
free/driven label drag, typed-value inheritance, unchanged geometry, history and
gallery reopen verified. Optional Codable metadata preserves old files and merge.
Initial25/26, immediate-reselection targeted failure, settled targeted1/1:
26 distinct passing checks across runs, not one clean run. No selection-code
change; rapid successive input remains unverified. Scope is head-on circle
diameter labels; default selected orientation, oblique placement and other
dimension types remain open. [Receipt](testing/sketch-parity-circle-label-drag-2026-09-09.md).

## September 9 — default selected-circle outside leader

Paired removal of a driving diameter then reselection confirmed native outside
vertical versus clone interior horizontal. Normal head-on selection now prefers
the outside leader; drawing readouts and manual overrides remain. Clean6/6 plus
followup2/2; initially mistyped omitted selector corrected, not counted. Fresh
clone release/selection/keypad/Ø1/manual override/Undo and paired gallery reopen
verified. Immediate dimension unlock vs clone commit and oblique placement remain
open; fresh native construction input attempts excluded.
[Receipt](testing/sketch-parity-circle-default-leader-2026-09-09.md).

## September 9 — immediate dimension lock action

Unchanged keypad Lock now immediately adds/removes the measured driving size
without moving geometry; changed drafts disable the key. Actual stored state is
shown, with neutral icons. Ordinary numeric commit remains driving. Clean12/12
(9 unit + 3 UI), then a successful tint-only build and live inspection. Paired
line/circle action, draft cancellation, freed radial resize/history and gallery
reopen verified: clone Ø0.992/line0.793, native Ø1000/line1750.6361 retain locks.
First click away dismisses an editor in both apps; separate selection follows.
Rapid radial first attempt excluded; settled repeat counted. Wider numeric/visual
matrix and device artifact remain open.
[Receipt](testing/sketch-parity-dimension-lock-action-2026-09-09.md).

Publication verified: illustrated130 images, all3 final PNG hashes matched;
master38 images with final gallery-reopen and tint notes exported.

## September 9 — alternate Dimension entry for stored sizes

Constrain → Dimension used a suppressed candidate label when a stored size
already existed, leaving no visible keypad. It now reuses the matching stored
label/ID. Clean9/9 (7unit+2UI). Live circleØ1→Ø2, unchanged center, Undo/Redo
and gallery reopen with palette entry verified; native existingØ1000→Ø2000
center/history and final reopened closed-lock editor paired. Native reference
is size editing, not an identical alternate palette. Illustrated135 images/all5
new hashes and master38 final reopen note export-verified.
[Receipt](testing/sketch-parity-dimension-palette-2026-09-09.md).

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

## September 9 — nested circle profile sample

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

[Receipt](testing/sketch-parity-nested-profiles-2026-09-09.md).

## September 9 — named consumed-source rebuild

## Final source-edit result

Both apps Undo restored the old source diameter and bore; Redo restored the
larger source/bore. Both gallery reopens retained enlarged solids. Native
Body02/Sketch03 and cloneExtrude/Sketch2 retained original ownership; no new
sketch was created by named entry. Broader visibility toggle cases remain open.
Existing history/profile-seed regression completed clean5/5 (2+3), serial70997,
/tmp/os3d-consumed-source-20260909.log/.xcresult. Unit tests terminated clone
app after the already captured final reopen; relaunch before more live work.
No code change in this lane.

Illustrated151 images and all4 new PNG hashes verified by DOCX export; master38
final5/5 and gallery-reopen note verified. Evidence/export retained in durable
transform-controls reports. This samples downstream bore rebuild, not full
Sweep/Loft/downstream smoke or all profile topology/device readiness.

[Receipt](testing/sketch-parity-consumed-source-2026-09-09.md).

## September 9 — visible gap closure / hidden-source control

Paired visible20px gap rejects profile selection; explicit closure produces a
profile, Undo/Redo removes/restores it and gallery reopen retains it. Controlled
hidden-source entry/Exit matches native; initial mismatch was differing state,
not a code defect. No new code/tests. Tiny tolerance, touching/duplicate/crossing
cases remain open. [Receipt](testing/sketch-parity-gap-closure-2026-09-09.md).
Publication pending; prior illustrated151/master38 verified.

Final publication: illustrated155 embedded images, all4 new closure/reopen
PNG hashes and corrected prose verified by DOCX export. Master38 retains final
reopen/visibility correction note. Export copies retained locally.

## September 9 — shared boundary / construction rendering

Paired adjacent regions select independently; construction divider merges the
regions. Fixed confirmed oversized model-unit construction dashes with viewport
8/4-point pattern for selected/unselected paths. Clean24/24 construction/profile
checks; live Front/oblique, regular/construction history and final reopen pass.
Multi-scale dash test automated-only: bridge scroll rejected. Curved phase,
point-touch, duplicates/tiny tolerance remain open. Illustrated160/all5 new
hashes and master38 final note export verified. [Receipt](testing/sketch-parity-touching-construction-2026-09-09.md).

## September 9 — duplicate straight boundary correction

Paired duplicate topedge preserved nativeprofile but removed cloneprofile.
Temporary profilegraph now collapses coincident straight boundaries, preserving
editableentities and firstboundaryowner; arcs/splines remain distinct. Initial
2testsfailed; corrected22profile/history/seed +27curve/entity checks passed in
separate cleanruns. Live savedprofile recovered; freshreverseoverlap extrudes;
pairedblockUndo/Redo and finalreopen pass. Earlierduplicate-only liveUndo remains
inconclusive. Partialoverlap/duplicatecurves/pointtouch/tinytolerance open.
Illustrated165 imageplacements/164uniqueassets (reusedidenticalimage), all5
evidencehashes and master38finalnote exportverified. [Receipt](testing/sketch-parity-duplicate-boundary-2026-09-09.md).

## September 9 — point-touch and partial straight overlap

Both apps independently select loops sharing only one vertex. Partially
duplicated top boundaries retain their profile; native interior endpoints and
clone snapped corner-ending sample recorded separately. Clean2/2 precise
geometry checks cover point touch and both partial-overlap directions. No
production change. Paired gallery reopen retains selectable loops and prior
bodies. Illustrated173 placements/all8 new hashes; master38 final note verified.
[Receipt](testing/sketch-parity-point-touch-2026-09-09.md). Remaining topology
and installable-device gate still open.

## September 9 — crossing straight-profile correction

Native bow-tie exposes two triangles; clone exposed none. Temporary straight
intersection splitting now supplies missing graph junctions without changing
editable entities/constraints. Initial red test failed; corrected clean42/42
profile/history/seed/curve run. Live independent triangle selection, extrusion,
Undo/Redo and paired final reopen pass. Illustrated179/all6 new hashes and
master38 final note export verified. Curved intersections excluded; earlier
partial-overlap first-loop fill disappeared during later editing, still open.
[Receipt](testing/sketch-parity-crossing-profiles-2026-09-09.md).

## September 9 — numerical partial-overlap stability

The earlier partial-overlap profile vanished after more constrained drawing.
Read-only saved geometry exposed ~4e-14mm offset in the duplicate segment, not
an open boundary. Exact fixture failed; temporary graph overlap normalization
at existing node precision fixes it without editing geometry. Corrected clean
43/43; live saved recovery, fresh overlap plus continued line Undo/Redo and
paired final reopen pass. Illustrated184/all5 hashes; master38 final note
verified. Initial pass and subsequent failure retained in audit.
[Receipt](testing/sketch-parity-partial-overlap-stability-2026-09-09.md).

## QA-13 endpoint input checkpoint — September 9

Native two endpoint clicks created an arc; clone ignored them. Added the missing
route into existing pending-arc construction. Five distinct regression checks
pass across corrected/targeted runs (initial compile failure and immediate-input
UI failure retained). Fresh live creation/history/reselect/keypad and paired
gallery reopen verified. Illustrated191 placements/new4 hashes and master38
finalnote verified. Default45° versus106.26°, pending feedback and bulge/finish
remain open; not fullQA13. [Receipt](testing/sketch-parity-direct-arc-recheck-2026-09-09.md).

## September 9 — new arc default curvature

Native forward/reverse endpoint inputs produce45° on the directed chord's right
side; clone produced106.26° on the opposite side. Corrected new construction
only; saved arcs unchanged. Clean18/18 construction/analytic/arcUI checks; live
forward/reverse, Undo/Redo and paired gallery reopen verified. Illustrated197
placements/all4 new hashes and master38 final note export verified. Pending
radius/sweep feedback, clipping and Return/chaining still open; not fullQA13.
[Receipt](testing/sketch-parity-arc-default-shape-2026-09-09.md).

## September 9 — pending arc readout checkpoint

Paired pending arcs exposed a missing clone sweep: native shows two radius rays,
a curved angular leader, sweep and endpoint radius; clone showed radius only.
The corrected informational overlay passes focused22/22 and updates both values
during clone midpoint drag. A later isolated native recheck proved the apparent
midpoint drag starts a chained arc, so the earlier native-adjustment
interpretation is withdrawn. Native third-point placement and Return/chaining
remain inconclusive and were not changed. Final combined39/39 passed in one run;
illustrated201/all4 new hashes and master38 final note export verified. QA-13
remains partial.
[Receipt](testing/sketch-parity-arc-pending-feedback-2026-09-09.md).

## September 9 — pending arc cancellation

Native first Escape discards the unfinished arc and disarms Arc while retaining
committed geometry; the next Escape exits sketch mode. Clone initially ignored
Escape with a pending arc. Arc-specific cancellation and a guarded neutral-sketch
fallback now match the paired sequence. The first focused run failed at compile
time in its new fixture; the corrected run passed cleanly 6/6. The exact updated
binary passed the live two-stage repeat with an existing arc retained. QA-13 is
still partial because third-point placement, Return/chaining, major/minor and
tangent transition remain open.
[Receipt](testing/sketch-parity-arc-cancellation-2026-09-09.md).

## September 9 — QA-13 Return checkpoint

Native Return accepts the current/default Arc after its first two endpoints.
OpenShape3D now routes the default keyboard action only in that pending state and
commits through the same shared-endpoint chaining path as a third-point click.
Paired live Return/Escape checks passed; focused 11/11 and final combined 35/35
passed cleanly. Direct construction major/minor boundaries and tangent transition
remain open, as do simulator hover delivery and physical Pencil validation, so
QA-13 and the milestone remain partial. Publication is anonymously export-
verified at 219 illustrated placements (all six new hashes) and 38 master
drawings after restoring one prior chained-arc image displaced during editing.
[Receipt](testing/sketch-parity-arc-return-2026-09-09.md).

## September 9 — QA-13 tangent-transition checkpoint

Paired line-to-arc construction exposed a stored-relationship gap: native
persisted a tangent glyph at the shared endpoint while the clone merely looked
tangent. Endpoint-only arc inference now uses the saved point/angle/toggle
gates, commits with the arc in one Draw history step, and leaves unrelated or
oblique geometry alone. Paired live selection and Undo/Redo passed; focused
31/31 and final combined 63/63 passed cleanly. Three experimental canvas-UI
assertions failed to reselect the arc and were removed rather than counted.
Direct gesture major/minor boundaries, hover delivery and physical Pencil remain
open, so QA-13 and the milestone remain partial. Anonymous exports verify 227
illustrated placements with all eight new hashes and no predecessor loss; the
master remains at 38 drawings with its dated note.
[Receipt](testing/sketch-parity-arc-tangent-transition-2026-09-09.md).

## September 9 — QA-13 direct boundary checkpoint

Controlled native gestures produced direct 90-degree minor, 180-degree
semicircle and 220-degree major arcs. The exact clone build, at a different
screen scale, produced 81.91, 176.03 and 214.93 degrees and restored the major
profile through toolbar Undo/Redo. Direct minor-to-major construction is now
paired; this is behavioral category evidence rather than coordinate equality.
QA-13 remains partial for clone hover delivery and physical Pencil/touch. No
source change or additional automated run was needed; the last relevant
current-revision combined arc suite remains clean 63/63.
[Receipt](testing/sketch-parity-arc-major-minor-boundaries-2026-09-09.md).

## September 9 — QA-56 downstream checkpoint

Paired live circle-profile extrusion, cancellation and solid history now pass.
The exact revision also passed one clean 65/65 serial downstream run covering
two Sweep/Loft UI flows and 63 kernel/feature-graph checks. QA-56 is the first
fully passed case in the retained 56-case inventory. QA-55 sustained use remains not run;
device input remains blocked and the milestone candidate gate is not reached.
[Receipt](testing/sketch-parity-downstream-smoke-2026-09-09.md).
