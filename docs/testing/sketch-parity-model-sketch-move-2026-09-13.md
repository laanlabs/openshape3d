# QA24 — model-mode Move/Rotate of selected sketch geometry (2026-09-13)

Closes the "full model-mode 3D transform dispatch/gizmo remains open" class
of QA-24. The clone's Transform > Move was a no-op on sketch entities
selected in model mode (diagnostic of 2026-09-12); the native semantics were
unverified.

## Native observation (Untitled Project, sketch24, Peekaboo-driven)

Recipe: Items row sketch24 → Exit Sketching (six edges stay selected, the
Move/Rotate gizmo is up, info bar "6 edges 21,454.0456 mm") → tap the up
arrow → distance editor at 0 → type 5000, Return.

- The six edges move 5000 mm along the arrow; the selection and its total
  length are unchanged; sketch24 keeps its identity (same Items and History
  rows); History gains **no** new step.
- Downstream re-evaluation: "Plane - Offset 01" (an offset from a planar
  face) and "Sketch 13" on it get warning badges, and Plane 01 drops out of
  Items. Extrusion 05 / part24 is built from Sketch 04, not sketch24, and
  stays put — so a dependent's re-evaluation is observed through the plane,
  not through an extrusion.
- Edit > Undo restores Plane 01 and clears the selection; the probe was run
  twice with identical results, and the document was left as found.
- Not observed: moving a *subset* of a sketch off its plane.

Thirteen captures with SHA-256s in workspace reports
selection/qa24-model-sketch-move-live-2026-09-13/evidence-index.json (local).

## Clone change

- The Move/Rotate gizmo attaches to sketch entities selected in model mode
  (idle, no body/image selected) at their centroid; arrows, plane tiles and
  rings work, typed distance/angle included; Transform > Move (M) keeps it.
- A whole sketch moves as a rigid frame (plane origin and axes; local
  geometry, constraints and dimensions untouched). A subset moves inside its
  plane through the constraint solver (locked/constrained parts refuse with
  the usual notice; a rectangle can't be turned by a non-right angle here).
  Taking a subset off its plane is refused with "Select the whole sketch to
  move it off its plane" — native's behaviour for that case is unobserved and
  a guessed sketch split would be worse than saying so.
- Commits are one undo step including the rebuild of dependents
  (`performWithSketchRebuild`), matching the observed downstream
  re-evaluation; the selection stays, as native's did.

Unit coverage: ModelSketchTransformTests (gizmo placement, typed frame move
with undo/redo, subset in-plane move, refused off-plane subset, typed
rotation about the normal, drag preview + commit, tilting rotation, gizmo
hidden while sketching).

## Result

Gate: ModelSketchTransformTests 6/6 and SelectionUXTests + SelectionTests + ConstraintApplyTests + SketchIdentityTests 112/112, serial on sim AC2FD923 (/tmp/os3d-qa24-sketchmove-unit-20260913.xcresult, -unit2).

Clone live check: paired on the clone at 4347508 (sim AC2FD923): P24 row → Exit keeps 4 edges / 14.00 mm selected with the gizmo up; up arrow → keypad 5 → plane origin (0,5,0), local geometry unchanged, selection kept, undo title "Move", the dependent Extrude rebuilt to y 5..7 in the same step; bridge Undo/Redo restore/reapply. Twenty assets local (selection/qa24-model-sketch-move-live-2026-09-13)
