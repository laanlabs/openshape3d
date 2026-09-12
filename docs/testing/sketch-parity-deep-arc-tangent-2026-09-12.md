# QA-36 deep arc/circle overlap — September 12, 2026

Baseline5e7cd12. Native lower arc760600,R11267.1795mm/180degrees with circle
760625,R6000 accepts Tangent; arc moves down to~760606 for internal contact,
circle remains fixed. Clone lower arc450700/r40 and circle450725/r20 selects
both but Tangent disabled. Before test failed0/1 with six assertions.

Bounded fix enables larger-arc deep intersection (radius difference < center
distance < arc radius) and persists internalContact. Existing external branch
and full-circle branches unchanged. Fully nested, exact midpoint, smaller-arc
deep pairs and arc-arc remain unverified/disabled. Solver unchanged.
Focused4/4 clean: deep, shallow, off-span, boundary/refusal. Deep test preserves
radius/sweep, fixed preferred circle, no dimensions, JSON and exact Undo/Redo.
Combined gate and changed-build paired history/reopen/publication pending.
Reports1042/master38 unchanged; QA36partial26/0/1/29; iPad unchanged.

Final101/101 clean, zero failures/skips, on568f9da. Changed clone live with
LastSelected and acquisition/Auto off: arc450700→450705, circle450725 fixed.
R0.4947/179.59degrees unchanged across apply/Undo/reopen. Saved arc radius
0.49468029796547497, sweep179.58773845907646, circle radius0.24724221229553223;
internal residual1.3877787807814457e-16, no dimensions. Native Undo/Redo and
reopen retain R11267.1795/180degrees and fixed circle. Reopened native arc762572,
circle762590. Coordinate trial-Skip click did not dismiss; identified Skip control
successfully dismissed, then sketch/top reentry verified. No trial activated.
Nine image publication and master note inserted; export verification pending.
No runner; source unchanged after final101.

Publication verified1051unique/master38, all nine source hashes exactly once,
headingsonce, zero predecessor loss. DOCX exports/manifests/verification JSON
retained with captures and test receipts. QA36partial26/0/1/29 unchanged.
