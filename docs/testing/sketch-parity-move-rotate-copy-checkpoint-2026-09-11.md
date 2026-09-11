# QA-45 — Move/rotate/copy checkpoint

Evidence date: September 11, 2026. Baseline `28af98c`.

## Retained paired evidence

Prior native/clone comparisons cover exact axis and rotation values, single-arc
visible-bounds pivot, retained absolute re-edit, rotated local axes, free versus
locked circle/arc refusal, line controls, Copy, keypad-first Escape, Undo/Redo,
accepted-operation exit and gallery reopen. This checkpoint reuses those
export-verified captures and does not claim a duplicate publication.

## Current-tree gate

The final one-owner serial gate passed clean **50/50**, zero failures/skips, at
`/tmp/os3d-qa45-transform-final-20260911.xcresult`:

- 42 constraint/transform model and project-geometry checks;
- 8 UI workflows for typed axes, cancel/history, direct line/circle/rectangle
  movement, explicit controls, Copy, profile retention and constrained refusal.

A new mixed-selection case verifies that a line and circle move together with
Copy off; Copy on retains both sources and moves independent duplicates; Undo
first restores the copy to its creation position, then removes the mixed copy;
Redo restores both steps. Entity identity and snapshot history remain exact.

The initial baseline passed 48/49 and failed only because one UI assertion used
the free diameter label position as a proxy for circle geometry; release versus
reselection legitimately changes that label layout. The corrected painted-center
assertion passed targeted 1/1 at
`/tmp/os3d-qa45-axis-corrected-20260911.xcresult`. The first mixed fixture run
failed 0/1 on computed differences near 8e-11; the corrected 1e-8 coordinate
tolerance passed 1/1 at
`/tmp/os3d-qa45-mixed-targeted2-20260911.xcresult` while identity, source
preservation and Undo snapshots remain exact. No product source changed.

## Verdict and boundary

QA-45 remains partial. The finite current-tree behavior and most visible states
have paired evidence, but a fresh paired mixed primitive selection and compact
viewport control-layout comparison remain supported-input blocked. No new Google
Doc screenshot publication is claimed. Inventory remains **16 passed / 0 failed /
1 device-blocked / 39 incomplete**. The immutable `05be744` IPA is unchanged.
