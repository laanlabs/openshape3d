# QA-13 arc-construction closure audit — 2026-09-11

Revision under test: `9ae0f20` plus the test/documentation changes described
below, on `fix/sketch-parity-foundations` (PR #29).

## Finite acceptance result

QA-13 is **passed for its original finite recipe**: prescribed endpoints and
side, direct minor/semicircle/major construction, line-to-arc tangent
transition, staged cancellation, and history. Pointer hover remains QA-21 and
physical Pencil/touch remains QA-52; neither is inferred from this closure.

Previously export-verified paired live receipts establish:

- two endpoint taps and the default 45-degree branch;
- third-point shaping and shared-endpoint chaining;
- Return completion and two-stage Escape cancellation;
- direct minor, near-semicircle, and major construction categories;
- a saved line-to-arc tangent relationship and glyph; and
- Undo/Redo for the major category and tangent transition.

The September 11 closure gate additionally exercised 90-to-360-degree numeric
conversion on the current tree. The selected 90-degree arc retained its driven
radius; entering `360` produced a full circle with the configured Radius or
Diameter convention. Undo restored the 90-degree arc and radius. Redo restored
the selected full circle and its radial leader.

## Regression result and retained failures

The final exact-tree serial run passed **63/63** in one run:

- 12 `ArcTapConstructionTests`;
- 27 `AutoConstraintEngineTests`;
- 21 `ConstraintResidualTests`; and
- three arc UI workflows covering explicit Copy mode, committed two-tap arc
  editing, and radius/sweep/full-turn history.

Result bundle:
`/tmp/os3d-qa13-final-combined-20260911.xcresult`.

The initial current-tree run passed 62/63 at
`/tmp/os3d-qa13-current-tree2-20260911.xcresult`. Its sole failure was a stale
test expectation that required Diameter even though QA-12's persisted Always
Radius preference validly displayed Radius. Subsequent targeted failures are
retained. They established that:

- the reopened sweep field contained exactly `360` before commit;
- full-turn conversion already succeeded;
- sketch history intentionally clears or restores selection depending on the
  command state; and
- the old construction-time third-point coordinate is not on the arc after a
  90-degree edit.

The final fixture uses the rendered quarter-arc path measured from the retained
attachment, explicitly normalizes the draw tool before geometry selection, and
accepts either persisted radial convention. It does not weaken geometry or
history assertions. The corrected targeted workflow passed at
`/tmp/os3d-qa13-fullturn-final-pass-20260911.xcresult` before the clean combined
gate.

## Evidence and publication

The paired evidence was already published and anonymously export-verified in
the following receipts:

- `sketch-parity-direct-arc-2026-09-08.md`;
- `sketch-parity-arc-default-shape-2026-09-09.md`;
- `sketch-parity-arc-third-point-chaining-2026-09-09.md`;
- `sketch-parity-arc-return-2026-09-09.md`;
- `sketch-parity-arc-cancellation-2026-09-09.md`;
- `sketch-parity-arc-tangent-transition-2026-09-09.md`; and
- `sketch-parity-arc-major-minor-boundaries-2026-09-09.md`.

No new paired screenshot is claimed by this reconciliation. The dated closure
note in the authorized master report was anonymously export-verified exactly
once. The export retains all 38 predecessor media hashes and contains the
updated `12 passed / 0 failed / 1 device-blocked / 43 incomplete` inventory
exactly once. The illustrated report stays at its previously verified
786-image baseline. The verified export and machine-readable comparison are in
`reports/openshape3d-core-sketch-milestone-2026-09-08/arc-closure-audit/`.

## Remaining boundaries

- QA-21 owns live pointer-hover feedback and overlapping-candidate visuals.
- QA-52 owns physical Pencil/touch behavior.
- QA-19's controlled native 3D-face near-threshold pair remains separately
  blocked by native canvas input delivery.
- The immutable `05be744` IPA is unchanged and is not a build of this revision.
