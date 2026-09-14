# QA-41 — Trim primitives checkpoint

Evidence date: September 11, 2026. Baseline `c4b74c6`.

## Current coverage

Retained paired live evidence verifies crossing-line tail removal and a circle
split into the intended complementary arc, with unrelated crossing geometry
unchanged. A separate paired rectangle receipt verifies removal of one boundary,
the remaining open U profile, surviving-side measurement and closed/open profile
handoff behavior.

The current-tree matrix now covers line middle/tail/whole removal, circle span and
whole removal, arc span and whole removal, rectangle explosion/boundary removal,
and polygon-edge removal. The polygon remains five ordinary connected lines, so
Trim removes only the chosen edge rather than deleting the other four boundaries.
Undo restores the exact loop.

## Regression

The one-owner serial gate passed clean **37/37**, zero failures/skips, at
`/tmp/os3d-qa41-trim-primitives-20260911.xcresult`:

- 10 primitive Trim geometry/command checks;
- 9 constraint/dimension lifecycle checks;
- 17 project-import/remap checks;
- 1 real endpoint-drag, Trim and exact four-step Undo UI workflow.

No product source changed. Two missing primitive assertions were added for whole
arc removal and polygon-boundary removal/Undo.

## Verdict and boundary

QA-41 remains partial. The changed model matrix is complete for the finite
primitive list and line/circle have paired live comparison, but fresh paired arc,
rectangle and polygon Trim gestures remain blocked by supported canvas input.
Those automated checks are not promoted to live parity. Reference ownership is
tracked separately in QA-43; ellipse/spline behavior remains QA-42. Inventory
stays **16 passed / 0 failed / 1 device-blocked / 39 incomplete**. No new
screenshot publication is claimed and the immutable `05be744` IPA is unchanged.
