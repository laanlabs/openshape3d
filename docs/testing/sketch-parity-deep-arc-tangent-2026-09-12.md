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
