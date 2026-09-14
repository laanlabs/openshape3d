# Rectangle sizing anchors — September 7, 2026

## Reference

The earlier [live paired comparison](sketch-parity-live-2026-09-07.md) showed Shapr3D retaining the first corner when changing a diagonal rectangle's width, while the clone resized about its center. The center-rectangle case already matched. This implementation uses that captured evidence; no new live reference comparison is claimed while the Mac is locked.

## Implementation

- New axis-aligned rectangles record center versus first-corner intent, including all four drag quadrants, in an optional per-sketch map. The `.rect` entity wire format is unchanged. Older documents decode without this map and retain their existing sizing behavior because the original corner cannot be recovered reliably.
- Creation and anchor metadata share the same undo command. Redo restores both. Anchors refer to the current normalized bounds, not an absolute world position, so translating a rectangle does not leave a stale anchor location.
- Direct width/height editing temporarily fixes the two coordinates of the original corner in the solver. Mixed quadrants use coordinates from different normalized endpoints. This creates no permanent Lock constraint and ordinary dragging is unchanged.
- Explicit structural constraints take priority: if the corner-preserving solve cannot satisfy them, use the ordinary dimension solve. Existing conflict rejection remains in place.
- Center rectangles retain their existing symmetric solve. Three-point rectangles remain four constrained lines and are not changed by this patch.

## Verification

- Construction/anchor unit suite: 11 passed, including all quadrants, sequential shrinking/growing width and height after JSON reload, center and legacy behavior, creation undo/redo, translated bounds, and explicit Lock precedence.
- Simulator dimension/rectangle UI suite: 8 passed, including the new diagonal half-width/first-corner profile test, all three dimension tests, center and three-point construction, drawing at an existing corner, and rectangle undo/redo.
- Final combined run: **19 tests passed, 0 failures, 0 skips**, completed at 14:23 EDT. [Machine-readable summary](rectangle-anchor-test-summary-2026-09-07.json).
- Simulator screenshot retained in workspace `reports/openshape3d-live-comparison-2026-09-07/rectangle-anchor-simulator/`; this is clone-only automated evidence, not a fresh Shapr3D comparison.
- Result bundle: `/tmp/os3d-rectangle-anchors-v3-20260907.xcresult`.
- Two initial compilation attempts were corrected before tests ran (an over-broad replacement and a test fixture initializer); neither is counted as a passing run.

## Still open

Fresh two-app visual sign-off after unlock; complete two-axis numeric placement; three-point height editing/anchor parity; keypad obstruction; propagation of construction intent through copy/mirror/rotation and other topology-changing operations. This patch addresses newly drawn axis-aligned rectangles and direct dimension edits, not the full rectangle workflow matrix. Imported/legacy rectangles without intent keep their existing behavior.

No Mac restart, logout, remote-service restart, or lock-setting changes were performed.
