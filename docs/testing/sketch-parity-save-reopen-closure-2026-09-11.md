# QA-51 save/reopen closure — September 11, 2026

## Verdict

QA-51 passes its finite desktop recipe on `3530d16`: geometry, constraints,
variable references, pattern links, annotation state and display units survive
their prescribed serialization or gallery-reopen path.

Retained paired native/clone evidence already covers gallery reopen for numeric
line, rectangle, circle, arc, polygon, coplanar-sketch, profile and consumed-
source workflows, including history and reconstructed selection/readout state
where the native workflow retains it. The illustrated and master reports already
contain and export-verify those screenshots; this closure claims no duplicate
publication.

## Current-tree regression

One clean serial run passed **47/47** with zero failures/skips:

- 4 UI workflows: cold gallery duplicate/open, persisted snapping settings,
  saved-unit relabeling and variable creation/evaluation.
- 5 project-archive checks: equality, independent import, cross-blob reference
  remapping, binary-blob preservation and invalid/newer-version refusal.
- 7 persisted feature/variable bridge checks.
- 10 linked-pattern identity, regeneration, unlink and Codable checks.
- 17 annotation, dimension, constraint-glyph, visibility and display-unit
  persistence checks.
- 1 constraint/dimension Codable round-trip and 3 variable fan-out/history
  checks.

The gallery UI workflow incurred two 60-second animation-idle waits around its
long-press/duplicate route. It completed successfully; those waits are retained
as timing evidence and are not described as product-performance measurements.

Artifacts:

- `/tmp/os3d-qa51-persistence-final-20260911.xcresult`
- `/tmp/os3d-qa51-persistence-final-20260911.log`

## Boundaries

This is a bounded desktop persistence pass, not an exhaustive guarantee for
every advanced feature link or future archive version. Physical-device storage,
Pencil/touch and lifecycle behavior remain QA-52. The immutable `05be744` IPA is
unchanged.

Acceptance inventory advances to **20 passed / 0 failed / 1 device-blocked /
35 incomplete** (24 partial, 11 explicitly deferred), total 56.
