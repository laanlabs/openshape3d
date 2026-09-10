# QA-06 — Line Delete and remaining cancellation routes

Evidence date: September 10, 2026. Baseline c186931. Work in progress.

## Paired diagnosis

Native Shapr3D Front sketch: horizontal drag committed 17.2694 mm. Endpoint
click/hover, including synthOnly, did not yield a visible continuation. Moving
blue guide/cursor point is not proof of a latched start. Those attempts are
inconclusive for pending-preview cancellation. Delete then disarmed Line while
preserving the segment. Rearming Line and switching to Arc preserved geometry.

A fresh native drag→Delete repeat (no intermediate canvas taps) again disarmed
Line and retained both committed segments. See native-repeat-release/delete.
Clone Front sketch: released 2 mm horizontal line retains readout; Delete leaves
Line armed and geometry unchanged. See clone-release/delete. Different scales
and desktop versus simulator input are explicit; no physical-device claim.

Setup: clone double-click Items name entered rename rather than sketch editing;
Return dismissed unchanged. Palette Line and visible Front plane used instead.
Native View/hover setup attempts retained, not counted as app failures.

## Correction under test

CommandShortcutsView registers bare Delete only in the Line/no-dimension branch.
EditorViewModel.deleteLineInput guards mode/editor and uses existing tool-disarm
cleanup. Committed geometry/history must remain unchanged. Escape unaffected.
New LineDeleteInputTests cover pending continuation, first point, Undo/Redo and
numeric edit guard. Existing LineChainUITests selected alongside them.
Runner exec87370; /tmp/os3d-line-delete-20260910.xcresult and .log.
Result and live post-fix pending. No publication or acceptance closure yet.

Initial run failed at test compilation: fixture used nonexistent DimensionKind.length; corrected to .distance. No tests ran. Retained initial log/result.

## Corrected result and live repeat

Corrected serial run passed clean 3/3 (two unit, one tap-chain UI), zero failed/skipped:
/tmp/os3d-line-delete-corrected-20260910.xcresult, exec3732 exit0.
Actual Delete key now disarms clone Line while retaining the 2mm segment.
One toolbar Undo removes it and Redo restores it; Line→Arc preserves it.
Clone gallery reopen retains the line. Native post-Delete CmdZ removes only the
last segment, CmdShiftZ restores it. Native final reopen pending inspection.
First clone post-build setup used a shifted toolbar coordinate and exited sketch;
that drag/keypress attempt is excluded. Valid repeat starts from inspected Top
Line mode (fixed-valid-release/delete). Native Front versus clone Top are
plane-local horizontal samples, not an exact viewport/physical-device match.

Diagnosis export verified 421 placements, all four new image hashes once, no
predecessor loss versus417. /tmp/os3d-line-delete-diagnosis.docx. Final correction
publication pending; master remains38. Local line-delete/ evidence and hashes.

Native final reopen inspected after Skip & Use Limited Version: both new segments
and older line remain. No purchase. /tmp/os3d-qa06-native-reopen-final.png.

Final publication verified: illustrated425 placements, all eight diagnosis/correction
hashes exactly once, no predecessor loss versus417/421. Master38 media, new
dated note once and final paired gallery-reopen wording once. Exports:
/tmp/os3d-line-delete-final.docx and /tmp/os3d-line-delete-master.docx.
QA06 remains partial; counts unchanged3/0/1/52. Immutable IPA unchanged.

## Released-state Return/double-click follow-up (68e97b3)

Native fresh20.8168mm and clone fresh2mm horizontal drag: Return leaves Line armed
and committed geometry unchanged. Double-clicking the released endpoint also
leaves tool/readout/geometry unchanged in both samples. These observations do
not prove pending completion, since neither app had a visible pending segment.
Native initial named-item entry retained whole-sketch selection; the first drag
was ignored and is excluded. Escape/blank deselection then valid fresh drag was
inspected before Return. Evidence: return-valid-release/after and double-native-
after; clone return-clone-release/after and double-clone-after, under /tmp/os3d-qa06-.
No product change or additional test needed for this read-only sample. New
follow-up screenshots are local-only; last verified published image count425.
Controlled native pending preview remains an input-route limitation, not an app
failure or a reason to change Return semantics speculatively. Continue independent
QA07 near-horizontal tolerance/zoom acceptance.
