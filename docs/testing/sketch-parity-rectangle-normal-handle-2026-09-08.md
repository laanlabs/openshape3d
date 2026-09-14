# Rectangle normal handle - September8,2026

Baseline fdca5f9. Paired free native rectangle edge arrow moves selected
edge normally, holding opposite side. Clone default blue ring/diamond is
visually different; integrity fixed separately. Native standalone horizontal
line did not show this arrow in sampled state, so correction is isolated
four-line rectangle edge only, not every line or axis-aligned rect entity.

Locked native right edge stays fixed and shows refusal notice. Clone locked
right edge stays fixed but silently. Paired screenshots os3d-edge-lock-*.png.

Implemented white outward-normal arrow30logicalpoints from edge midpoint,
44target, existing Move/Rotate/Copy explicit. Drag targets both selected edge
endpoints with transient opposite-edge lock; original saved constraints win.
Whole-sketch coalesced history/rebuild retained. Added refusal feedback for
normal handle and blocked all-line generic transforms.
Serial9174 owns simulator:19construction plus new normal-handle UI, explicit
gizmo closed-profile UI and arcCopy compatibility. /tmp/os3d-rectangle-normal-handle-20260908.log/.xcresult.
Live post-fix pending. Both Docs Saving, local evidence retained unpublished.

Initial9174 completed65:19geometry plus arcCopy and explicit-gizmo profile
passed (21passes); newhandle UI failed its query before movement. Captured
AX hierarchy identifies SketchRectangleEdgeHandle as Image, not Other.
Changed test to query any matching descendant, consistent with radial tests.
Targeted16213 owns simulator; no product changes for query failure.

Targeted16213 passed1/1: movement, UndoRedo, saved-lock refusal and notice.
Total22 distinct passes across initial21pass/1queryfailure and targetedpass,
not one clean combined run. Orientation99597 briefly ownsdesktop; live next.

## Live post-fix verification, 17:41 EDT

No test worker active. Clone baseline (500,470)-(650,510) moved via white
normal arrow to approximately (507,442)-(657,482); opposite edge
(480,542)-(630,582) stayed fixed and width stayed 2.565 mm. Native prior
normal-arrow sample likewise held its opposite edge and 1200 mm baseline.
Inspected Undo and Redo screenshots restore/reapply the clone edge movement.
Lock then arrow drag keeps geometry fixed and displays refusal notice, matching
the native locked-edge sample. Explicit Move/Rotate replaces the white arrow
with the generic control; Done exits that mode. Copy compatibility is regression-
tested, not newly exercised live in this locked fixture.

Gallery reopen retains the closed profile (interior click opens Extrude;
cancelled without creating a body), saved Lock, 2.565 mm length and white
handle on reselection. Native paired reopen already captured in the preceding
line-gizmo-integrity receipt. No physical-device claim.

Both Docs checked again at 17:41: Saving. Do not reload or duplicate pending
insertions. Nine corrected PNGs copied to local rectangle-ui evidence directory
and embedded in visual-corrections-2026-09-08.md. Publication pending.
Axis-aligned rect entities, generic-control styling and non-line constrained
transforms remain separate acceptance work.
