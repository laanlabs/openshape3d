# QA-27 — Adaptive linear dimensions checkpoint

Evidence date: September 11, 2026. Baseline `89bb2f0`.

## Confirmed gap and implementation

A selected sloped line previously exposed only its absolute length. The
Dimension action now offers Absolute, Horizontal and Vertical measurements for
a genuinely sloped single-line selection. Axis-aligned lines retain the direct,
unambiguous Absolute action. The chosen kind is used for measurement, stored
dimension lookup, editing and persistence rather than merely changing label
text.

The 3-4-5 model recipe verifies 50 mm absolute, 30 mm horizontal and 40 mm
vertical dimensions independently. Each commit leaves geometry unchanged,
survives JSON round-trip, is removed by Undo and restored by Redo. The UI recipe
verifies all three choices, a fresh first-digit replacement session, a 1 mm
horizontal commit, Undo to an undriven measurement, and Redo restoration.

## Regression history

- Model recipe: clean 1/1 at
  `/tmp/os3d-qa27-dimension-kinds-20260911.xcresult`.
- Initial UI run failed because the test's `Horizontal` title matched both the
  adaptive menu and constraint rail. Unique accessibility identifiers corrected
  the fixture; the corrected menu run passed 1/1 at
  `/tmp/os3d-qa27-dimension-menu-ui-corrected-20260911.xcresult`.
- The first 18-case combined run passed all 17 model cases but expected Undo to
  hide the selected line's candidate. The second expected the horizontal seed,
  while the app correctly returned to the default absolute undriven candidate.
  Both assertion failures are retained.
- Final current-tree serial result is clean 18/18, zero failures/skips, at
  `/tmp/os3d-qa27-dimension-final2-20260911.xcresult`.

## Boundary

Fresh paired live comparison and screenshot publication are still blocked by
the simulator input-delivery failure. Repository reference material establishes
the adaptive-dimension requirement, but no new native sloped-line menu capture
is claimed here. QA-27 remains partial; inventory stays 13 passed / 0 failed /
1 device-blocked / 42 incomplete. The immutable `05be744` IPA is unchanged.

