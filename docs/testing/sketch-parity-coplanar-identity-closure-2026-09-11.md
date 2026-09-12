# QA-48 coplanar sketch identity closure — September 11, 2026

## Verdict

QA-48 passes its finite desktop recipe on `ce361cb`: create an independent
coplanar sketch, explicitly continue a named existing sketch, edit a named
consumed source without creating a replacement identity, and preserve hidden
consumed-sketch identity through history and reopen.

This closure reconciles retained paired evidence rather than claiming a new
live comparison. Native and clone evidence in
`sketch-parity-coplanar-identity-2026-09-09.md` shows independent creation,
named continuation, visibility and gallery reopen. The paired consumed-source
receipt shows named source editing, downstream bore rebuild, Undo/Redo and
gallery reopen with the same sketch ownership. Those screenshots were already
export-verified in the illustrated and master reports; no duplicate publication
is claimed here.

## Current-tree regression

One clean, serial, same-tree run passed **9/9** with zero failures/skips:

- 5 `SketchIdentityTests` cases: independent ownership, empty/hidden source,
  Items-row/history identity, explicit named continuation, and inactive profile
  presentation.
- 2 `HistoryProfileEditTests` cases: profile retarget and cancel/history.
- 1 `FeatureGraphEvalTests` case: dependent solid rebuild after source-sketch
  editing.
- 1 `PlanesUITests` workflow: two separate coplanar items followed by explicit
  continuation of the named first item.

Artifacts:

- `/tmp/os3d-qa48-identity-final-20260911.xcresult`
- `/tmp/os3d-qa48-identity-final-20260911.log`

The first attempted combined gate is retained but not counted. Xcode denied a
temporary cloned-runner launch; after scoped recovery, the broader Items
rename/delete workflow later stopped at its context-menu animation. The already
completed unit checks were 8/8, but that interrupted run is not represented as
clean. The final 9/9 run targets QA-48 directly.

## Boundaries

Overlapping coplanar fill hit precedence remains a selection/profile-choice
variant under QA-23/49, not part of the QA-48 identity recipe. QA-48 does not
claim projection linking, Sweep/Loft completeness, physical Pencil/touch, or an
updated device installation. The immutable `05be744` IPA remains unchanged.

Acceptance inventory advances to **17 passed / 0 failed / 1 device-blocked /
38 incomplete** (27 partial, 11 explicitly deferred), total 56.
