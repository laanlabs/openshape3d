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
