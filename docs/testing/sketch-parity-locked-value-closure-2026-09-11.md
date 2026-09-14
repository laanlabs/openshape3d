# QA-34 — Locked/unlocked value closure

Evidence date: September 11, 2026. Baseline `526e015`.

## Finite recipe

The original QA-34 recipe asks for a driving value versus a one-time size edit,
geometry drag after Unlock, and coherent Undo. Retained paired circle and line
evidence already verifies driven refusal, direct Unlock, free resize, Undo/Redo
and gallery reopen. The current-tree model gate distinguishes the two commit
modes explicitly: locked commit stores a driving dimension; unlocked commit
resizes to the same exact value without storing a dimension. Fresh edit sessions
default back to locked.

The UI workflow commits a circle value, requires the intended selection cleanup,
reselects it, rejects locking a changed draft, performs immediate Unlock on the
unchanged value, resizes the freed radius and restores it with one Undo.

## Regression history

The first combined run passed five radial solver checks but the UI fixture still
expected a radius handle immediately after a successful numeric commit. QA-12
intentionally clears that selection. A first correction still relied on a generic
point marker not present in this state. The final fixture records the known circle
center and rendered radial distance before commit, requires cleanup, and reselects
the rim explicitly. No product source changed.

The corrected UI target passed 1/1 at
`/tmp/os3d-qa34-lock-ui-corrected2-20260911.xcresult`. The final one-owner serial
run passed clean 29/29, zero failures/skips, at
`/tmp/os3d-qa34-locked-values-final-20260911.xcresult`:

- 20 `DimensionKeypadCommitTests`;
- 3 `NumericKeypadTextTests`;
- 5 `SketchRadialDragTests`;
- 1 immediate Lock/Unlock/free-resize UI workflow.

## Verdict and boundary

QA-34 passes for this finite desktop recipe. It does not claim every constraint
combination, transform lock, physical Pencil/touch route, or comprehensive
dimension capability; those remain QA-35/36/37/39/45/52. No new screenshot
publication is claimed because closure reconciles already published paired
evidence. Inventory advances to 14 passed / 0 failed / 1 device-blocked /
41 incomplete. The immutable `05be744` IPA is unchanged.

