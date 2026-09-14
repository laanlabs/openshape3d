# QA-43 — Trim references checkpoint

Evidence date: September 11, 2026. Baseline `f352d9a`.

## Retained paired evidence

The September 8 native/clone comparison removes one rectangle boundary in each
app. Both leave the intended open U, retain the other three sides and unrelated
geometry, and keep a surviving-side readout. After exiting the sketch, the open
region is not selectable for extrusion while a separate intact closed profile
is. This is retained paired evidence rather than a new capture claim.

## Current-tree reference and history gate

A new production-representation lifecycle fixture uses endpoint-based line
dimensions around a closed rectangle, a construction cutter and an unrelated
fixed point. Trimming away the driven edge endpoint:

- invalidates the downstream closed profile;
- drops only the dimension whose endpoint was removed;
- preserves the unrelated dimension, fixed constraint and construction entity;
- leaves every constraint/dimension reference valid; and
- restores the exact original sketch, closed profile and references on Undo.

The targeted corrected fixture passed 1/1 at
`/tmp/os3d-qa43-trim-refs-targeted2-20260911.xcresult`. The final one-owner
serial gate passed clean **60/60**, zero failures/skips, at
`/tmp/os3d-qa43-trim-references-final-20260911.xcresult`: 59 Trim,
constraint-lifecycle, profile and import/remap unit/integration checks plus one
real sketch-edit Trim/history UI workflow.

The first targeted attempt is retained at
`/tmp/os3d-qa43-trim-refs-targeted-20260911.xcresult` and failed 0/1 because the
fixture used a legacy `.whole` line reference. A single surviving fragment is
documented to inherit such a ref, so the fixture was corrected to the endpoint
representation produced for current line-length dimensions. No assertion was
weakened and no product source changed.

## Verdict and boundary

QA-43 remains partial. The finite reference/profile/history behavior is covered
on the current tree and its visible topology/profile result has paired retained
evidence, but a fresh paired driven-reference removal and full history gesture
could not be delivered through the supported live canvas route. No new Google
Doc screenshot publication is claimed. Inventory remains **16 passed / 0 failed /
1 device-blocked / 39 incomplete**. The immutable `05be744` IPA is unchanged.
