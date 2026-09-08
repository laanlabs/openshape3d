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
