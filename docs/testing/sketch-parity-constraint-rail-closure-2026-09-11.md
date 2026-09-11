# QA-35 — Constraint rail closure

Evidence date: September 11, 2026. Baseline `18be00f`.

## Finite recipe and evidence

The original QA-35 recipe requires adaptive enablement for selected combinations,
settings access and discoverability. The model matrix covers two and three lines,
two circles, line+circle, point+line and two-point selections, including truthful
disabled relations. The UI covers portrait and landscape rails, disabled Parallel
guidance, one-tap constraint settings, restored snap preference, enabled Parallel
for a two-line selection and its visible applied glyph.

Retained paired evidence covers the visible expanded rail, contextual Lock versus
Unlock, other-lock preservation, one-step history and gallery reopen. The finite
rail recipe does not own whether every constraint solves correctly; those
semantics remain QA-36/39.

## Regression history

The initial combined run passed both UI workflows but exposed three unit fixtures
whose saved-dimension assertions inherited the persisted Always Show Dimensions
preference. Those fixtures now save, set and restore their visibility prerequisite.
No product source changed. The corrected one-owner run passed clean 30/30, zero
failures/skips, at
`/tmp/os3d-qa35-constraint-rail-corrected-20260911.xcresult`:

- 28 `ConstraintApplyTests`;
- 2 portrait/landscape `ConstraintRailUITests`.

## Verdict and boundary

QA-35 passes for the finite desktop rail recipe. Comprehensive constraint solve,
conflict attribution, transform, hover and physical Pencil/touch remain their
separate acceptance cases. Closure reconciles already published paired evidence;
no new screenshot publication is claimed. Inventory advances to 15 passed /
0 failed / 1 device-blocked / 40 incomplete. Immutable `05be744` IPA unchanged.

