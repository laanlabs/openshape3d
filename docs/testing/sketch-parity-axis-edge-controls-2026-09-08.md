# Axis-aligned rectangle edge controls - September 8, 2026

Baseline 378715b pushed. Paired selection: native top edge orange with white
normal handle; clone top tap selects entire axis-aligned rect and blue ring.
Native driven 2000 x 1000 sample moved top254->224 and bottom314->284 under
30px upward arrow drag: translation, not refusal or resizing. Fresh native
rectangle top560/bottom619 moved top->530 while bottom stayed619; height
1000->1504.6161, width2000 unchanged. These are distinct constraint states.

Implemented axis-edge sub-selection for contextual highlight/normal handle,
without decomposing stored rects or dropping dimensions. Other-side tap changes
selected edge, same-side tap deselects. Whole-rect operations remain stored on
the rect entity; edge-specific constraint semantics are not newly claimed.
Free normal movement prefers unchanged opposite side. A saved axis dimension
prefers translating both bounds. Original structural solve/locks remain binding.
Explicit Move/Rotate/Copy stays available.

Serial exec76586 owns simulator: RectangleConstructionTests and full
RectangleWorkflowUITests; /tmp/os3d-axis-edge-controls-20260908.log/.xcresult.
Initial compilation/tests in progress; live post-fix pending. Native1924
FrontSketch02 fresh rect top890530->1009530, bottom890619->1009619.
Clone fixtures will be reset by tests.
Both Docs Saving; five diagnosis images copied/indexed locally, not published.
Selected-side dimension leader placement and true per-edge Lock semantics
remain separate acceptance gaps; this is not full rectangle parity.

Progress: 20 geometry checks passed; axis-edge UI movement/side change/history/explicit-mode check passed, as did gallery-history and prior normal-handle/lock coverage. Remaining rectangle UI cases still running. Docs read-only alert confirms editing temporarily disabled while Saving, despite navigator.onLine=true; tabs preserved.

Clean regression completed exit0: 20 geometry +12 rectangle UI =32/32 in one run. Serial76586 collected; orientation/relaunch41484 owns desktop briefly, then live post-fix. No product edits made during the run.

## Live correction and persistence

Clone top300->270, bottom370 fixed: height1.155->1.649, width2.479 unchanged.
Undo/Redo restored/reapplied that geometry. Typed height1 then top-edge drag
shifted top309->279 AND bottom370->340, retaining1mm and2.479mm. This matches
separate native free-resize and driven-translation samples. Right edge then
moved350->380, left200 fixed, width2.479->2.977 and height1 retained. Native
right edge1009->1039 held left890 and height1504.6161, width2000->2504.6139.

Paired gallery reopen retains native2504.6139 x1504.6161 and clone2.977 x1.
Clone interior opens Extrude after reopen; cancelled without creating a body.
Reselection retains white right-edge control and edge-only highlight. The
clone saved whole-rect Lock behavior is geometry-tested, not equivalent to
native per-edge Lock. No live axis Lock acceptance claim.

One capture read was attempted before its long command completed; after
collecting73262, image inspected normally. Native trial modal skipped by
AXelem25, no purchase. First post-modal Cmd2 did not align; explicit foreground
Cmd2 did, and final native values inspected after sketch entry/reselection.

13 corrected/reopen PNGs copied and indexed locally. Both Docs still blocked;
no claim these are published. Next: selected-side leader placement and the
per-edge constraint semantics gap. No worker active; source ready to commit.

## Selected-side leader follow-up

Native top width and right height leaders follow selected edge; clone remained
below/left. Scoped geometry anchor/outward-center correction implemented.
Initial focused86907 completed65: keypad1pass, axis UI failed immediate Undo
frame assertion (475.5 versus520.5); selected top label position passed. No
history source change. Diagnostic adds before/after captures and waits up to3s
for actual restored frame, without retrying Undo. Publication still blocked.

Leader diagnostic27147 failed even with3s restoration wait. Before/after video frames show unchanged geometry and disabled Redo. Temporary OS3D_AXIS_DIAG NSLog traces added at normal-drag end and Undo entry to distinguish action delivery/lifecycle; serial23934 runs targeted case. Remove temporary traces before final commit. No passing history claim for leader build.

File trace42659 confirms normal drag deltas and end callback; no Undo entry after synthesized toolbar tap. Not a history-state failure. Hit-test diagnostic6340 adds temporary UIKit window hit chain at the recorded toolbar coordinate; source traces/import/helper must be removed before final commit.

Hit trace6340 reached _UIButtonBarButton at366.75,54 inside UIKitNavigationBar,
not the dimension overlay. Several AnimationView ancestors had non-identity
scale frames0.3s after drag; single immediate tap did not enter Undo. Checking
a1s pre-tap settle to avoid that native toolbar transition; still exactly ONE
Undo tap, then actual geometry restoration required. Temporary UIKit/cache
tracing removed. Serial98785 runs both leader and keypad workflows. The toolbar
animation explanation remains an inference pending this result, not proven
by hit-testing alone. Trace copied to /tmp/os3d-axis-leader-hittrace.txt.

Settled98785 failed axis Undo again; keypad passed. Pre-tap1s wait does NOT support the toolbar-animation explanation. Source instrumentation removed. Returning to live reproduction before further source changes; no successful leader-build history claim.

Live reproduction: first post-orientation setup click did not create a new
project; excluded that attempt, explicitly refocused and inspected new Untitled2
Front before drawing. Corrected top leader above rectangle; live landscape
free resize and Undo restore geometry. Portrait orientation preserves state;
Redo at286118 works. Undo icon center253118 does not restore; slight-right
262118 does. This confirms a tap-location issue, not an undo-stack issue.
Six evidence images locally indexed. Adding explicit44pt rectangular Label
targets to Undo/Redo toolbar buttons; serial35521 runs leader/Undo and keypad.
Removed unsupported pre-Undo animation sleep; no retry/offset in test.

Explicit Label-frame run35521 passed clean2/2, but live portrait icon-center
253118 still missed; right-offset262118 worked. Installed and derived debug
dylib hashes match bece64ac51585d8952f36b87f9ac0fc48395c65f1783cdefc3c62469254fbaaa.
Not a stale binary; do not claim live fix. Replacing extracted system Label
with custom44pt ZStack image/contentShape for aligned painted/touch region;
serial7585 runs original center-tap test and keypad again. History logic untouched.

Custom-content run7585 passed clean2/2 (axis33.275s, keypad24.640s). Live portrait fresh Untitled2 Front: top350→320/bottom500fixed; height1.859→2.229, width2.477. Single painted-center Undo237118 restores top350/height1.859; single Redo280118 reapplies. Top editor commits width2; right selected height leader is right, editor fully reachable and commits1. Gallery reopen and sketch reselection retain2x1. Double-clicking Items name selected text; sketch icon entered editing, no data change. Ten post-fix screenshots copied/indexed locally. No trace/helper/UIKit import remains; no history logic changed. This is a clean final focused run following documented failures, not an all-suite final run. Native prior top/right leader and working history references retained. Remaining difference: clone returns width leader below on right selection instead of retaining previous top placement. Both Docs blocked; fresh18:37 exports remain76/36.
