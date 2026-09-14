# QA-50 sketch-to-solid closure — September 11, 2026

## Verdict

QA-50 passes its finite desktop recipe on `3ceb192`: exact extrusion, correct
hole, consumed-sketch visibility, source edit/downstream rebuild, and coherent
Undo/Redo.

Retained paired evidence includes closed-profile extrusion and solid Undo/Redo,
nested-hole bore creation/history/reopen, duplicate/bow-tie profile handoff, and
named consumed-source diameter editing with bore rebuild, visibility, history
and gallery reopen. The illustrated and master reports already contain and
export-verify those screenshots; this closure claims no duplicate publication.

## Current-tree regression

One clean serial run passed **15/15** with zero failures/skips:

- 3 profile extrusion checks: exact rectangle, negative direction and nested
  hole.
- 5 feature-graph checks: complete pipeline, distance/downstream rebuild,
  stable body identity, coplanar through-subtract and source-sketch rebuild.
- 2 on-face cut checks: pocket versus through-hole.
- 2 profile-history checks: retarget/replay and cancel.
- 3 UI workflows: rectangle-with-hole extrusion, direct profile extrusion and
  editable History feature state.

Artifacts:

- `/tmp/os3d-qa50-solid-final-20260911.xcresult`
- `/tmp/os3d-qa50-solid-final-20260911.log`

## Boundaries

Advanced Sweep/Loft breadth remains outside this finite case (QA-56 retains its
own smoke evidence). Comprehensive cold-launch state belongs to QA-51, and
physical Pencil/touch remains QA-52. The immutable `05be744` IPA is unchanged.

Acceptance inventory advances to **19 passed / 0 failed / 1 device-blocked /
36 incomplete** (25 partial, 11 explicitly deferred), total 56.
