# Completed-line readout — September 7, 2026

## Reference and implementation

The earlier [live comparison](sketch-parity-live-2026-09-07.md) confirmed that Shapr3D retains a completed line's length readout with Always Show Dimensions disabled. OpenShape3D previously cleared that readout on release.

The shared drag/tap-chain commit path now selects the newly committed line and clears old point selections. Existing annotation rendering provides the measured length; no keypad is opened automatically and no extra undo command is added. Subsequent selection taps still toggle membership normally.

## Verification

- `DimensionUITests`: 3/3 passed, including immediate badge visibility without a selection tap, no automatic field, typed length, exact draw/edit undo count, circle sizing, and external sketch dimension recovery.
- Receipt: `/tmp/os3d-line-readout-20260907.xcresult`.
- Line-chain, both constraint-rail orientations and lock-state regressions: 4/4 passed; `/tmp/os3d-line-selection-20260907.xcresult`.
- Total: seven passing UI checks across two runs. Legacy `ConstraintApplyUITests` and the line-readout case in `SketchParityStepsUITests` were adjusted for automatic selection but not run in this batch.
- Desktop remains locked. No new Peekaboo actions, reference screenshots, or live two-app sign-off are claimed. Google Docs still contain the earlier paired evidence; this is a source/test update.

## Next: rectangle anchor persistence

`RectangleConstruction.axisAligned` normalizes both center and diagonal construction into `.rect(id:min:max:)`. This loses both the creation variant and the original corner quadrant. `commitDimensionEdit` then solves without a movement anchor. Inferring the original first corner from `min` would be wrong for three of the four drag quadrants, and treating all rectangles as first-corner anchored would regress the center case that matched in live testing.

The fix needs backward-compatible persisted creation intent, recorded atomically with construction and restored by undo/reload; dimension solving must respect that anchor without moving unrelated constrained geometry. Old rectangles cannot have their original creation intent recovered reliably. Cover four quadrants, width and height, center preservation, save/reload, undo/redo and constraint conflicts before live A/B verification.
