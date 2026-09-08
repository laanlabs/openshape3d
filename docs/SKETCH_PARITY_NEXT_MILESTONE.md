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
