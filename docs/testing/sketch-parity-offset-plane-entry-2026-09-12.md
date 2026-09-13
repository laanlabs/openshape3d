# QA01 offset plane entry — partial live checkpoint

Source fd254e9 (unchanged). No test runner or new automated result.

Native created a 500 mm face-offset Plane 01, selected it from Items and entered
Sketch 13. Settled screenshot confirms normal Top grid alignment. Clone created
a 1 mm extrusion, then a 0.5 mm face-offset Plane 1 and entered it through
Sketch > Line > visible construction-plane canvas pick. These fixtures differ
in scale and existing contents; this is workflow, not pixel/size equivalence.

Clone numeric offset draft initially appended to default 2 (20.5); it was cleared
through keypad backspace and corrected to .5 before commit. No incorrect plane
was committed. Native entered 500 directly in its selected field.

Confirmed separate difference: clone Plane Items name click has no visible effect,
and ItemsPanelView's plane onSelect is empty. Native selects its plane and offers
Sketch/Move Rotate. No source change is justified for canvas acquisition, which
works. Full plane item selection/transform semantics remain open.

Blank-grid picker probes chose native existing Sketch12 and clone ground plane;
state differences prevent claiming full miss parity. Curved-face rejection,
plane history and saved reopening remain to be verified. Both apps currently have
empty offset sketches with Line armed. Next create a line and check history/reopen.

Evidence: workspace reports/openshape3d-core-sketch-milestone-2026-09-08/planes/
qa01-offset-live-2026-09-12/evidence-index.json. Local only; publication queued.
Illustrated1302 unique/1305 placements, master38 unchanged. QA01 partial;
acceptance32/0/1/23, physical iPad unchanged.

## September 13 — paired offset sketch history and reopening

Clone created a 1.5 mm line as Sketch3 on the offset plane. Undo removed the line
and its empty item while retaining Plane1/body; Redo restored it. Gallery reopen
retained Plane1, body, and Sketch3; named Sketch3 entry showed the same 1.5 mm
line in the plane-aligned view.

Native created a 7,761.9858 mm line as Sketch13. The initial Edit>Undo request
while Line was active returned explicitly disabled; no success is claimed for
that attempt. Exit via the icon then model-mode Edit>Undo removed the line and
Sketch13 item, retaining Plane01; Redo restored it. After gallery reopen, the
limited-version modal was dismissed by its Skip button (no subscription), and
named Sketch13 entry showed one edge at 7,761.9858 mm with related Plane-Offset01
history. Normal to Sketch alignedTop after the camera animation settled.

Current-source PlaneTests plus all four PlanesUITests workflows ran serially at
/tmp/os3d-qa01-plane-gate-20260913.xcresult (source 0e86c6b, sim AC2FD923):
**11/11 passed, 0 failed, 0 skipped**, one clean run, finished 00:12 EDT Sept 13.
Twelve distinct unpublished screenshots are prepared in offset-assets.json.
Plane-item selection and curved-face/miss boundaries remain open.
