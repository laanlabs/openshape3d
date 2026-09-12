# QA-36 finite constraint-family closure — September 12, 2026

Status: **PASSED for the finite desktop recipe.** Source `c73f126`,
paired checkpoint `3d734bb`. No new source changes or repeated tests.

## Finite coverage

The original recipe names Horizontal, Vertical, Parallel, Perpendicular,
Coincident, Midpoint, Tangent, Concentric, Equal and Symmetry. Equal is split
into line length and circle radius, yielding eleven model families. Each row
below has paired apply/geometry, Undo/Redo and saved reopening evidence.
Different fixture scales are deliberate; this is not a pixel-identical claim.

| Family | Paired receipt | Retained gate | Illustrated checkpoint |
|---|---|---|---|
| Horizontal | [Horizontal](sketch-parity-horizontal-alignment-2026-09-12.md) | 108/108 | 1099 |
| Vertical | [Vertical](sketch-parity-vertical-alignment-2026-09-12.md) | 110/110 | 1109 |
| Parallel | [Parallel](sketch-parity-parallel-alignment-2026-09-12.md) | 112/112 | 1119 |
| Perpendicular | [Supporting pivot](sketch-parity-perpendicular-placement-2026-09-12.md) | 114/114 | 1129 |
| Coincident | [Family checkpoint, Coincident completion](sketch-parity-constraint-types-checkpoint-2026-09-11.md#coincident-changed-build-pairedpublication-gate) | 84/84 | 935 |
| Midpoint | [Family checkpoint](sketch-parity-constraint-types-checkpoint-2026-09-11.md#midpoint-changed-build-live-and-publication-verification), [free target](sketch-parity-midpoint-anchor-2026-09-12.md) | 82/82, 106/106 separate | 925, 1089 |
| Tangent | [Line/circle](sketch-parity-tangent-application-2026-09-12.md), [fixed circle](sketch-parity-tangent-reverse-2026-09-12.md) | 86/86, 87/87 separate | 945, 955 |
| Concentric | [Manual Concentric](sketch-parity-concentric-application-2026-09-12.md) | 88/88 | 965 |
| Equal Length | [Equal completion](sketch-parity-constraint-types-checkpoint-2026-09-11.md#equal-publication-verified) | 90/90 | 873 |
| Equal Radius | [Equal Radius](sketch-parity-constraint-types-checkpoint-2026-09-11.md#equal-radius-paired-checkpoint--september-11-late-evening) | same 90/90 reused | 881 |
| Symmetric | [Two-line completion](sketch-parity-constraint-types-checkpoint-2026-09-11.md#two-line-changed-build-paired-verification-and-publication), circle follow-up | 76/76, prior 64/64 | 903, 895 |

## Current-source gate

`/tmp/os3d-qa36-perp-placement-final-20260912.xcresult`: **114/114**,
zero failures/skips, one serial run on c73f126 (107 model/integration +7 UI).
`testFiniteConstraintTypeMatrixAppliesAndRestoresHistory` directly applies all
eleven, checks availability and saved kind/residual, exact Undo/Redo and JSON
round-trip. Additional application/merge/polish/Trim and rail workflows guard
confirmed fixes. This current gate supplements retained changed-build paired
receipts; it is not a claim that eleven new live workflows ran on c73f126 today.
Preserved before failures and corrected targeted runs remain in each receipt.

## Publication and boundaries

Latest illustrated export1129 retains every media hash from each family's
verified predecessor (873,881,903,925,935,945,965,1099,1109,1119).
Master38 retained. No duplicate screenshots are needed for this reconciliation.
Final dated reconciliation-note verification will be recorded below.

This bounded family pass does not close QA37 First/Last/reverse order/Locks/
repeated solves, QA38 Disconnect variants, coincident-edge selection routing,
unobserved arc-arc/tangent-boundary combinations, hover/physical key delivery,
or Pencil/touch. Those limitations remain explicitly open in their receipts.
Native hover highlight is not selected-state evidence. No universal solver or
all-geometries parity claim. iPad/immutable05be744 unchanged.

## Closure publication verified

Both exports contain the dated closure heading exactly once. Illustrated1129
and master38 media Counters exactly equal the verified predecessors; no images
added, duplicated or lost. Durable `constraint-types/qa36-family-closure-2026-09-12`
contains both after DOCX and publication-verification.json. Inventory now
**27 passed /0 failed /1 device-blocked /28 incomplete**, total56.
