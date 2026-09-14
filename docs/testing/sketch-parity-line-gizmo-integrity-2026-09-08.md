# Line control transform integrity - September 8, 2026

Baseline b41b8ca. Native standalone horizontal line has no directional arrow
in sampled selection; isolated rectangle edge does. Native top edge
(590,192)/(690,220), bottom(576,241)/(676,270), baseline1200/height600:
white arrow at(646,189) dragged(+8,-28) moves top to(598,164)/(698,192),
bottom unchanged, height937.3093 and baseline1200. Rectangle stays closed.

Clone selected isolated three-point baseline500,470 to650,510: default blue
ring/diamond, no white arrow. Center diamond575,490 dragged(+8,-28) moves
only baseline to508,442/658,482; adjacent sides still terminate500,470 and
650,510. This visibly disconnects the rectangle while constraints remain.
Higher priority than control styling. Screenshots under rectangle-ui/
os3d-edge-handle-{native,clone}-{selected,moved}.png.

Correction routes all-line gizmo transforms through original structural
system, with transient targets for both endpoints of each selected line.
Projects pointer intent onto saved constraints; original fixed variable values
and welded junctions retained. Updates entire sketch in one undo command;
dependent profiles rebuild/save on release. Non-line transform paths remain
unchanged and are not covered by this scoped integrity claim.

Serial62340 owns simulator: construction tests plus sketch-move UI and arc
Copy UI compatibility. /tmp/os3d-line-gizmo-integrity-20260908.log/.xcresult.
Post-fix live comparison pending. No white-arrow implementation yet. Both
Docs Saving blocked; local evidence retained, no publication claim.

Initial62340 completed0 clean20/20:18geometry plus sketch move and arcCopy
UI checks. Additional focused47416 UI regression now tests the actual
reported failure: move one rectangle edge then select the interior as an
extrudable profile. No product changes after the clean20 run.

Focused47416 passed1/1: single-edge gizmo move leaves an extrudable closed
profile. This supplements the clean20/20 initial run. Live recheck pending;
orientation75089 briefly owns desktop, no test runner active.

Final live clone repeats the exact center drag(+8,-28): baseline508,442 to
658,482 remains joined to sides; bottom481,543/630,583 remains in place
within screenshot precision. Baseline remains2.565. Undo restoresoriginal
500,470/650,510; Redo restoresconnected result. Gallery reopen preserves
a filled closed profile; tapping interior offers extrusion (then cancelled).
Native gallery reopen preserves1200 baseline and937.3093height after its
arrow drag. Trial prompt dismissed via freshly inspected Skip button, no
purchase. Native camera refit changed screen scale; values inspected.
Saved-lock preservation remains automated-verified, live refusal pending.
Default control appearance and non-line constrained transforms remain open.
No tests/build/Peekaboo workers active. Both Docs Saving; final paired
reopen evidence localonly, publication not verified.
