# Selection and trimmed-profile references — September8,2026

Revision966b0c0; exclusive Peekaboo, native Front and simulator Top landscape.
Evidence root workspace/reports/openshape3d-core-sketch-milestone-2026-09-08,
subfolders selection and trim. No new product change or test run in this sample.

Native plain click on second disjoint line replaces selection (711.8311mm only).
Clone plain click adds second to first (total6.69mm). native-nearequal-selection-
second.png / clone-plain-select-second.png. Mouse-native versus simulated touch
input modes differ; leave as known difference pending physical touch/pointer check,
not a proven iPad defect and not a basis to remove additive touch selection.

Native double-click on rectangle top selects4edges,total1500mm. Clone diagonal
rectangle selects entire rect; separately, a three-point rectangle built from4
ordinary lines double-click selects all4,total8.39mm, both dimensions3.003/1.192.
Other disjoint geometry unchanged. native-connected-double.png,
clone-connected-double.png, clone-connected-four-lines.png. The attempted manually
joined3line fixture was created with guidepoints off and selected only one line;
visually nearby endpoints do not prove shared topology. clone-connected-three-
lines.png retained as inconclusive, not a failure attributed to connected selection.

Trim top edge: native rectangle200–373,y267–311 becomes open U; clone rotated
rectangle500,249→681,269→673,341→493,321 becomes open U. Three remaining sides and
unrelated geometry unchanged. Clone toast reports4constraints on trimmed span
removed. Reselect left side retains native150mm, clone1.192mm. native/clone-
rectangle-edge-trim.png and native/clone-rectangle-surviving-edge.png. This samples
reference cleanup without visible conflict; does not prove every driven dimension,
linked reference, Undo/Redo or all trim primitive combinations. Full audit retained.

Google Doc still Saving/editing temporarily disabled at09:55. New selection/trim
images not inserted. Existing six snap/lock images locally visible but anonymous
export last verified76. Preserve tab and local evidence; publication pending.

Open/closed handoff: after exit sketch, native openU interior286,290 does nothing,
intact right rectangle773,295 selects face and offers Extrude. Clone openU interior
586,295 does nothing; intact diagonal590,550 enters zero-distance Extrude panel.
Cancelled clone preview viaCancel755,641; inspected return to modeling, no solid
created. native/clone-open-profile-handoff.png and closed-profile-handoff.png under
trim. This is topology/handoff only, not a completed extrusion/persistence test.
