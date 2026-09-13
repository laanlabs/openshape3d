# QA24 model-mode sketch transform diagnostic — September 12, 2026

On native, named sketch24 entry/Exit selects six edges, exposes3D MoveRotate.
Clicking upward screen-space axis opens0numeric editor. Typed5000Return commits
with six-edge total21,454.0456mm unchanged; menuUndo/Redo invoked and selection
cleared. FinalUndo restores pre-probe state. The first Undo capture was during
animation; do not treat it as precise positional proof. Moved geometry is small
at this camera scale; ownership/downstream behavior is not yet established.

Changed clone0e86c6b selects two named edges in model mode, summaryworks, but
Transform>Move has no effect. Code beginTranslatePick guards bodyselection,
not selectedSketchEntityIDs. No model-transform fix attempted. Existing
ChangeSketchPlaneCommand is not assumed equivalent: it rebuilds downstream
solids. 3D sketch transform ownership/Copy/rotation/history remain open.

Evidence os3d-qa24-model-transform-* PNG/JSON is copied to durable workspace
reports selection/qa24-through-live-2026-09-12; diagnosis publication queued,
not counted in latest1302unique/1305placements/master38. No runner.
Next core QA01 ambiguous plane miss/face recipe, retaining this separate gap.
QA24partial32/0/1/23;iPadunchanged.
