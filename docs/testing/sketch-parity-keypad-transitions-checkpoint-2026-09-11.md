# QA-40 — Keypad transitions checkpoint

Evidence date: September 11, 2026. Baseline `1e42243`.

## Covered transition set

Retained paired evidence covers explicit dimension opening, initial replacement,
Escape cancellation with unchanged geometry, blank-click commit/refusal, another
tool, the same tool toggled off, Exit Sketch, Undo/Redo and switching between the
numeric keypad and system-keyboard editor. Existing transform receipts separately
cover keypad-first Escape followed by tool exit.

The current-tree UI set verifies click-away commit and invalid refusal without an
orphan tap, another-tool commit, tool reachability after release, same-tool
toggle-off, Exit Sketch, second-shape input, Undo/Redo, keyboard/keypad draft
retention and immediate correction after invalid Return.

## Regression history

The first combined run executed 56 tests: 54 passed and two model tests failed,
while all five UI workflows passed. The failures were deterministic global-
preference contamination rather than transition behavior:

- persisted Grid snapping quantized the oblique circle-direction fixture;
- persisted Sketch Guidepoints off prevented the tangent-transition fixture from
  inferring its requested relationship.

The tests now declare and restore those prerequisites. The focused correction
passed 2/2 at
`/tmp/os3d-qa40-pref-fixtures-targeted-20260911.xcresult`. The complete same-set
rerun then passed clean **56/56**, zero failures/skips, at
`/tmp/os3d-qa40-keypad-transitions-final-20260911.xcresult`: 51 model checks and
five UI workflows.

## Verdict and boundary

QA-40 remains partial. The covered transitions are stable and no product source
changed, but a fresh paired rotation/pan interaction and comprehensive physical or
system-keyboard input matrix remain open. The known supported live-canvas delivery
blocker is not reclassified as an application failure. Inventory remains
**16 passed / 0 failed / 1 device-blocked / 39 incomplete**. No new screenshot
publication is claimed; the immutable `05be744` IPA is unchanged.
