# Rectangle construction and constraint rail — verification receipt

## Scope

Second batch on `fix/sketch-parity-foundations`, following `bbec8c5`; draft PR 29. Original checkout is unchanged.

Reference: [Shapr3D Rectangle help](https://support.shapr3d.com/hc/en-us/articles/7874319307804-Rectangle), checked September 7, 2026. Center uses center-to-corner input; diagonal uses opposite corners; three-point uses a baseline and perpendicular height.

## Covered behavior

- Pure center reflection in all quadrants, diagonal degeneracy, rotated signed heights and rejection of zero baseline/height.
- Three-point geometry forms a closed profile; dimension solving retains closure/orthogonality and Codable round trips preserve the sketch.
- Zoomed profile interiors remain separate from outline targets; short-line middles select entities rather than endpoints across camera scales.
- Center and dragged three-point rectangles open numeric entry and provide an extrudable region.
- Three-point tap placement, cancellation without stray geometry, single-step undo and redo.
- A circle stroke beginning on an existing rectangle corner draws a circle rather than moving the rectangle.
- Common constraint actions/prerequisites and settings are visible in iPad portrait and landscape. Selecting two lines enables Parallel; applying it produces a constraint glyph.

## Final verification

**60 distinct tests verified across the combined run and correction rerun: 47 unit + 13 UI.**

The combined run completed with **58 passed / 2 failed** (both line dimension entry). Restoring badge clearance fixed both. The final targeted correction run passed **9/9 UI tests, 0 failures or skips**, ending September 7 at 07:07:58 EDT, xcodebuild exit 0 / TEST SUCCEEDED. It repeated all three dimension tests, four rectangle tests and two tool-transition tests. This is not a claim of a single clean combined 60-test run. Unaffected pure tests, constraint-rail portrait/landscape, snapping persistence and polygon/ellipse profile checks passed in the combined run.

Local receipts: `/tmp/os3d-parity-batch2-final.xcresult` (combined) and `/tmp/os3d-parity-batch2-correction.xcresult` (final correction); logs and JSON summaries use the same prefixes. No runtime source changes followed the final correction run. Serial iOS 26.5 / iPad Pro 13-inch M5 simulator; isolated `os3d-parity-sept7` destination, Xcode developer directory `/Applications/Xcode.app/Contents/Developer`.

## Failures found and resolved

- Rectangle options initially overlapped the sketch status pill; put both in a vertical stack.
- The visible “Rectangle” rename required the shared legacy `Rect` test helper to use the new text; the old button identifier remains compatible.
- Rail container identifiers overrode child identifiers in SwiftUI; removed the container identifier and retained per-action identifiers.
- Fixed model-unit pick floors swallowed small-profile interiors and short-line midpoints. Acquisition now uses screen-sized edge/control-point targets with a numerical epsilon floor only.
- Hiding the armed-draw gizmo also removed the central annotation offset and regressed line dimension entry. Retain badge clearance from the selection anchor even while the gizmo is hidden.
- Rectangle state cleanup initially cleared inferred constraints before diagonal commit; cleanup now follows the undoable commit.
- XCTest point sequences now await stage/selection changes rather than assuming tap recognition is synchronous. The constraint fixture temporarily disables grid snapping for deterministic input coordinates and restores it after drawing.

## Known limits

- Center remains fixed during construction, not guaranteed during later typed dimension edits. Diagonal first-corner retention after editing also needs verification.
- Three-point rectangles are four related ordinary lines, not a new grouped parametric rectangle type. Initial length input opens on the baseline; complete two-axis typed placement remains open.
- Center/three-point placement uses existing snapping but does not infer external relations automatically; internal rectangular relations are persisted for three-point construction.
- No physical Pencil, mouse/trackpad, compact-window or left-handed layout matrix sign-off. Hover previews are implemented but not physically verified.
- Constraint rail does not replace the legacy Constrain group in this batch.
- Model/sketch edge and control-point picking are screen-scaled; this is not a fix for snap capture or grid resolution.
- This is not all 42 issues or all 56 planned audit scenarios completed.

## Reproduction

Run the first-batch command from [the foundations receipt](sketch-parity-foundations-2026-09-07.md), adding:

```sh
-only-testing:openshape3dTests/RectangleConstructionTests \
-only-testing:openshape3dUITests/RectangleWorkflowUITests \
-only-testing:openshape3dUITests/ConstraintRailUITests
```

The final correction run used the same project/scheme/destination/serial flags and selected `DimensionUITests`, `RectangleWorkflowUITests`, and `TwoShapeReproUITests` only.
