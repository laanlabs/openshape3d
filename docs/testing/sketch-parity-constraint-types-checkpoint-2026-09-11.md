# QA-36 — Constraint types checkpoint

Evidence date: September 11, 2026. Baseline `5d31097`.

## Added finite application matrix

A new model recipe directly applies Horizontal, Vertical, Parallel,
Perpendicular, Coincident, Midpoint, Tangent, Concentric, Equal Length,
Equal Radius and Symmetric constraints to valid selections. Every relation must
enable, be stored, solve within the structural residual tolerance, survive JSON
round-trip, disappear through Undo and return through Redo.

The first attempt was compile-only because the test referenced the view model's
nested point-selection type without qualification. No test ran. The corrected
target passed 1/1 at
`/tmp/os3d-qa36-constraint-types-compiled-20260911.xcresult`.

## Final regression

The final one-owner gate passed clean 64/64, zero failures/skips, at
`/tmp/os3d-qa36-constraint-types-final-20260911.xcresult`:

- 28 `ConstraintApplyTests`, including the 11-relation matrix;
- 28 `AutoConstraintEngineTests`;
- 6 `ConstraintPolishTests`;
- 2 portrait/landscape `ConstraintRailUITests`.

This covers explicit application, adaptive availability, inference gates,
over-constraint refusal, deletion/history, serialization and visible rail entry.

## Boundary

Retained paired evidence covers H/V, point Lock, Parallel, tangent and concentric
workflows, but current paired live evidence is incomplete for Equal Length,
Equal Radius, Symmetric and a fresh exact-build sweep of every relation. The
simulator input-delivery blocker prevents that repeat. QA-36 remains partial;
inventory stays 15 passed / 0 failed / 1 device-blocked / 40 incomplete.
Immutable `05be744` IPA unchanged.

