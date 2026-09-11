# QA-39 — Conflict and point states closure

Evidence date: September 11, 2026. Baseline `5ea6b8a`.

## Finite recipe

QA-39 asks the desktop pair to distinguish under-defined, constrained and fully
defined geometry; point Lock from whole-entity Lock; and a rejected conflicting
change from a successful edit. A refusal must preserve geometry, identify the
relevant conflict and leave one coherent prior state for Undo.

Retained paired evidence supplies the live comparison. Free, constrained and
locked point colors and controls were sampled across line, circle and rectangle
workflows. The published center-plus-corner Lock case then applies an incompatible
width to already dimensioned, center- and corner-locked rectangles in both apps.
Native and clone reject the edit, preserve the prior dimensions and geometry,
and present the conflict without consuming an extra history step. Direct Unlock
allows the same edit; Undo/Redo and gallery reopen preserve the resulting Lock
and dimension state. Rectangle-side Lock and concentric-center receipts separately
distinguish a point/center Lock from locking the complete entity.

## Current-tree regression

The one-owner serial gate passed clean **69/69**, zero failures/skips, at
`/tmp/os3d-qa39-conflict-states-20260911.xcresult`:

- 7 point-state and 5 definition-cache checks;
- 2 integration, 13 solver-attribution, 6 conflict-polish and 31 constraint-apply
  checks;
- 5 UI workflows covering under-to-fully-defined state, constrained drag,
  immediate dimension Lock/refusal, a free rectangle side and saved-Lock refusal.

The gate verifies exact rollback, conflict partners/messages, point determinacy,
under/fully-defined degrees of freedom, saved-constraint priority and coherent
Undo/Redo. It was one clean run, not a sum of targeted reruns.

## Verdict and boundary

QA-39 passes for this finite desktop recipe. This does not promote the incomplete
all-relation live sweep in QA-36, the selection-anchor gestures in QA-37, every
possible over-constraint combination, or physical Pencil/touch in QA-52. No new
screenshot publication is claimed: the paired conflict sequence was already
export-verified in the illustrated report at 541 placements, with all five batch
hashes once and no predecessor loss; the master retained 38 images and one dated
note. Inventory advances to **16 passed / 0 failed / 1 device-blocked /
39 incomplete**. The immutable `05be744` IPA is unchanged.

## Retained paired receipts

- `sketch-parity-center-matrix-2026-09-10.md` — center plus corner Lock conflict,
  refusal, Unlock, history, reopen and publication verification.
- `sketch-parity-rectangle-side-lock-2026-09-08.md` — side/entity Lock behavior.
- `sketch-parity-concentric-matrix-2026-09-10.md` — center Lock versus radial
  freedom and saved recovery.
