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
