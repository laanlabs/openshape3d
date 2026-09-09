# Disconnect — September 8, 2026

Baseline a6fda2b pushed. QA-38 is partial, not complete.

## Paired diagnosis

Native main Untitled Project, Front Sketch02, selected top of four-line rectangle:
1200 mm baseline / 600 mm height. Disconnect clears selection without moving
geometry. Reselect loses rectangle normal handle and retains 1200 mm readout.
Body drag moves top endpoints (779,230)/(838,246) to (779,205)/(838,222), other
three sides unchanged. Cmd-Z restores position; second Cmd-Z restores connections,
normal handle and both rectangle dimensions. Reference is not the view-rotation
buttons. Units restored to mm after isolated arc investigation.

Clone fresh three-point rectangle baseline (250,620)→(450,660), opposite edge
(230,720)→(430,760), reads2.527×1.265 mm. Reselected top has normal handle;
rail and More contain no Disconnect. Eight diagnosis screenshots copied to
milestone evidence `disconnect-ui/` and indexed; all LOCAL ONLY.

## Implementation under verification

Selected ordinary lines/endpoints remove relevant Coincident constraints in one
history action, retaining dimensions and unrelated relations. Persisted detached
endpoint refs suppress proximity welding; explicit Coincident reconnects them.
Legacy decode defaults empty. Rectangle-handle/readout/anchor recovery checks
connection state, not geometric closure alone. Import remaps refs; delete and
trim preserve their integrity and Undo. Primitive rectangle edges, midpoint and
non-line connection semantics remain outside this initial scope.

Initial /tmp/os3d-disconnect-20260908.xcresult failed compilation because new
tests omitted required solver arguments. No tests executed. Corrected run
/tmp/os3d-disconnect-fixed-tests-20260908.xcresult, exec50274, currently owns
simulator exclusively: ConstraintApply, ProjectMerge, Trim, Disconnect UI and
existing rectangle normal-handle UI. Post-fix live comparison pending.

19:51 EDT both Docs still Saving/editing disabled. Preserve unsynced tabs and
recovery files; no duplicate insertion. Candidate gate remains open.

## Verified four-line edge correction, 20:00 EDT

Corrected exec50274 finished0: clean34/34 (32unit+2UI). First run was a
compile-only failure, not a failing-test run. Live clone top endpoints
(250,350)/(450,390) move to (250,320)/(450,360); other three sides remain
fixed, length2.527mm unchanged. Single painted Undo restores move; second
Undo restores rectangle handle/connections. Two Redos reapply both.

Gallery-reopen test deliberately saves while detached endpoints still TOUCH:
Undo move only, back to gallery, reopen Untitled2, Sketch1 icon enters Front.
Two Coincident plus two Parallel/one Perpendicular retained in Items. Reselect
has no rectangle handle, Disconnect disabled, length2.527mm; fresh body drag
moves only detached edge. Native Redo Disconnect only, gallery reopen via
first card double-click, trial Skip AX25, refocus/repeat Cmd2, selectedge:
1200mm, orange endpoint halos, no rectangle handle. Body drag independently
moves top again to779205/838222; other3sidesfixed. Paired persistence verified.

Ten post-fix/reopen screenshots copied/indexed. Clone generic transform ring
appears on detached line whereas native sample has no ring. This is an OPEN
visual difference, not accepted parity. Midpoint, primitive rectangle and
non-line Disconnect remain open. Unit tests additionally cover point-only
proximity detachment, explicit reconnection, legacy decode, import, trim/delete;
these extra cases are automated-only, not paired live.

Both Docs still blocked; no new publication claimed. No runner remains active.
