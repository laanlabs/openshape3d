# QA-38 Midpoint Disconnect — September 12, 2026

Partial, base5228ae6/sourcec73f126. Native saved Midpoint fixture from QA36:
point758410, source758355→758410, target704410→813410. Disconnect clears
connection/selection with no geometry movement. Point then drags to788400,
source other endpoint/target unchanged. Native remains moved; two-step history
and reopening pending.

Clone source350600→350650,target300700→400700, explicitMidpoint extends
source350600→350700. Saved JSON verifies Midpoint, unrelatedParallel/Perp.
Disconnect removes onlyMidpoint and retains exact entities. Initial quick
point-input/drag misses are not geometry failure; settled point selection
then drag moves endpoint380690 independently, but retains selected point plus
parent edge, causing a spurious0mm point-to-own-line label and ring. Edge-first
movement also works. Native point-only selection remains point-only.

Before regression0/1 reproduces exactly two selection/zero-label failures.
Independent endpoint position, target preservation, exact two-step Undo/Redo
and JSON pass. Correction scopes existing point-only drag selection to an
already-selected ordinary line endpoint as well as migrated rectangle corners.
No solver, saved geometry, Disconnect semantics or schema change.
Focused2/2 passed clean; final regression and changed live/history/reopen/publication
pending. No acceptance promotion. Inventory27/0/1/28, reports1129/master38.
Durable disconnect/qa38-midpoint-live-2026-09-12 contains PNG/actions/before/
detached JSON. Logs/xcresults /tmp/os3d-qa38-point-drag-{before,focused}-20260912.
Immutable05be744/iPad unchanged.
