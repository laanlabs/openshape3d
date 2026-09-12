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


## Equal Length direction correction in progress — September 11 evening

Fresh native Sketch11 Front: unequal nonparallel lines759.3439/657.4091mm,
Auto-constrainingOFF and Last Selected inspected. Box selection and Equal
shortened the upper to657.4091mm, left the lower unchanged, preserved directions,
and showed Equal badges. Undo restored the upper and Redo restored Equal.

Clone fresh Untitled2 Front: raw separate lines3.0996/2.6502mm, acquisitionOFF,
HintsON, Auto-ConstrainOFF, Last Selected inspected. Equal made lengths equal
but rotated the free lower line from10.79° to28.90°. The explicit selection order
differs from native's box route; this is not anchor-order evidence. The confirmed
issue under investigation is unnecessary direction drift during free-line sizing.
`testEqualLengthPreservesFreeLineDirectionsAndHistory` reproduced that drift on
unchanged source: 0/1 passed (two direction assertions), zero skipped, receipt
`/tmp/os3d-qa36-equal-direction-before-20260911.xcresult`.

A narrow explicit-Equal correction reuses transient line-direction preservation
from numeric sizing for the non-anchored ordinary line. If saved relationships
conflict, retry without direction preference, then use the existing anchor
fallback. No angle or Lock is added to the saved sketch. Focused three-case gate
is running; no success is claimed yet. Added saved-point-constraint override
coverage, both anchor preferences, exact history and JSON persistence.

PNG/JSON/logs/summary and hashes are durable under workspace
`reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-equal-live-2026-09-11`.
Changed-build live verification, broader regression, gallery reopen and report
publication remain pending. QA36partial; inventory26/0/1/29, reports863/38.
No current device install or immutableIPA change.

Focused corrected gate completed clean **3/3**, zero failures/skips, at
`/tmp/os3d-qa36-equal-direction-fixed-20260911.xcresult`. The prior failed0/1
receipt remains retained. No runner. This is a WIP source checkpoint: broader
constraint/sizing regression and changed-build paired live remain pending.
