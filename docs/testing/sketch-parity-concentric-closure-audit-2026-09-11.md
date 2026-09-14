# QA11 finite concentric-circle closure — September 11, 2026

## Scope and result

PASSED for the original recipe: start a new circle at an existing unselected center without editing the existing circle or its label. A selected center instead remains a move control. This does not close QA12 radius/diameter modes, general annotation parity, or physical input.

## Paired evidence

- Native fresh circle selects its center/Lock; center drag moves geometry. Clone release/center-hit/history correction `ca4663e` matches. Unselected-center drawing creates the second circle.
- With Guidepoints and Auto-Constrain/point inference enabled, native saves the center connection. Clone previously only snapped position. Exact acquired circle-center coincidence now enters the same Draw step, respecting settings and the existing conflict guard.
- Initial live connection glyph blocked center dragging despite passing geometry tests. Its plain link control is now below-left of center, clear of center and Lock. The final live pair moves together by30/40screenpixels with sizes unchanged.
- Native clean Undo/Redo restores both centers and clears selection. Clone toolbar Undo/Redo does the same. Earlier native attempts with the settings popover open are excluded; resumed window-relative/global-coordinate mistakes are also excluded.
- Final gallery recovery retains native outer16.0041/inner9.3357 and clone outer1.4852/inner0.8645 with shared centers. A draft0.8708 inner value was unverified, explicitly withdrawn, and corrected from the isolated saved rim readout. Multi-selection screenshot is not a size readout.

## Regression history

- Center lifecycle initial8pass/2fail exposed over-broad readout cleanup; corrected10/10.
- Selected equal-center target follow-up11/11.
- Connection units/inference32/32, then combined35/35 with circle UI.
- Later glyph placement plus explicit connected-center UI follow-up6/6, separately; not one combined41-test run.
- New UI verifies settings, nonoverlap, both-center displacement and Undo/Redo. Units verify atomic Draw/relation history and disabled Guidepoints/Auto-Constrain behavior.

Results: `/tmp/os3d-qa11-connection-final-20260911.xcresult` and `/tmp/os3d-qa11-connection-glyph-20260911.xcresult`.

## Publication and preserved evidence

Illustrated report724 placements: all9 final hashes once, no715 predecessor image or ordered-text loss; diagnosis715 and714 retained. Master closure export verification is recorded in the continuation receipt. Local screenshots, hashes and exports are in the milestone report's `concentric-matrix/` folder. Detailed chronology: [matrix receipt](sketch-parity-concentric-matrix-2026-09-10.md).

## Remaining gates

Inventory8passed/0failed/1deviceblocked/47incomplete (36partial11deferred), total56. QA12 numeric modes and broader visual acceptance continue. Immutable05be744IPA unchanged; newer changes are not claimed installed or physically tested. No merge/full-parity claim.
