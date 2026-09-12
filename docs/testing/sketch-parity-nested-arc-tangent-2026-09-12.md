# QA-36 fully nested arc/circle Tangent — September 12, 2026

Baselinefb3c5c8. Native lower arc550650,R11849.9336mm/180degrees and fully
nested circle550660,R6000 accept Tangent: arc moves up to~550640, circle fixed.
Center distance2962.4786 is below radiusdifference5849.9336. Arc value retained.
Short10/15px Circle strokes created no circle and are excluded; settled20px
stroke produced verifiedR6000. Native history/reopen pending.
Clone matching arc250700/r40,circle250710/r20 selects both but disables Tangent.
Before0/1; bounded larger-arc fully nested nonconcentric eligibility fix;
existing internalContact branch/solver unchanged. Focused5/5 clean, zero failures
or skips, across nested/deep/shallow/offspan/boundary-refusal. New test preserves
arc radius/sweep, preferred circle, no dimensions, JSON and exact Undo/Redo.
Coincident centers, radiusdifference/maxradius boundaries, smaller-arc deep/nested,
and arc-arc remain unverified/disabled. Combined102 and changed paired live/
history/reopen/publication pending. Reports1051/master38; QA36partial26/0/1/29.
iPad/immutable05be744 unchanged. Durable constraint-types/
qa36-nested-arc-tangent-live-2026-09-12.
