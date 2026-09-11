# QA-25 — Annotation off-state checkpoint

Evidence date: September 11, 2026. Baseline `f70d15d`.

## Regression

The final current-tree run passed clean 23/23, zero failures/skips:

- 15 `SketchAnnotationVisibilityTests`
- 7 `SketchParityFoundationTests`
- `DimensionUITests.testDimensionFollowsTheSelectionAfterExitingTheSketch`

Result: `/tmp/os3d-qa25-annotation-final-20260911.xcresult`.

The first 22-case run had one fixture-state failure: the radius/diameter test
inherited the saved circular-annotation preference. The fixture now saves,
controls and restores that preference; the corrected 22/22 run is
`/tmp/os3d-qa25-annotation-corrected-20260911.xcresult`. A new several/disjoint
selection check initially observed the expected two saved lengths plus a
synthetic 0-degree selection candidate. That candidate belongs to QA-28, not a
hidden saved annotation. The assertion was narrowed to persisted dimensions,
passed 1/1, and is included in the final clean 23-case run.

The matrix now proves that with Always Show Dimensions off: nothing selected
shows no saved dimensions; selecting one entity shows its own dimension;
selecting several entities shows only their dimensions; and a disjoint
same-sketch selection does not expose the intervening entity's dimension.

## Live status and boundary

Retained paired evidence proves the completed-line and rectangle selection
states, and current automation proves the full ownership matrix. A new exact-build
live pass could not be completed: after the tests, the simulator rendered and
relaunched normally, but foreground Peekaboo clicks resolved to the Simulator
window without reaching its Sketch control or canvas. Restarting only the
Peekaboo app and then only the affected simulator did not restore input delivery.
Shapr3D, Chrome/report tabs, simulator data, and Mac security settings were not
changed.

QA-25 therefore remains partial. It must not be promoted until the fresh paired
none/one/several/disjoint screenshots are captured and the illustrated report is
saved and export-verified. QA-28 owns synthetic dimension candidates. Physical
Pencil/touch remains QA-52. Inventory stays 13 passed / 0 failed /
1 device-blocked / 42 incomplete, and the immutable `05be744` IPA is unchanged.
