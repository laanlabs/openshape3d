# QA-30 — Rectangle numeric sequence checkpoint

Evidence date: September 11, 2026. Baseline `6dca210`.

## Current-tree regression

A new edge-positioned center-rectangle workflow enters width with the numeric
keypad, verifies that the adjacent height control remains discoverable, switches
height to the system keyboard, commits it, and verifies Undo/Redo. It supplements
the existing right-edge keypad-clearance and keyboard-mode workflows.

The first targeted run failed before editing because both dimension controls
advertise square minimum touch targets; their frame aspect ratio does not encode
orientation. The fixture now identifies the known right-side height by position
and passed 1/1 at `/tmp/os3d-qa30-sequence-corrected-20260911.xcresult`.

An initial four-workflow run passed all requested tests but Xcode distributed
them across simulator clones and logged a separate runner launch denial. It is
retained but not used as the serial gate. The final run disabled parallel testing
and passed clean 4/4, zero failures/skips, at
`/tmp/os3d-qa30-sequence-serial-20260911.xcresult`:

- edge width keypad → height system keyboard → Undo/Redo;
- right-side height keypad reachability and first-digit replacement;
- lower editor/system-keyboard visibility;
- seed replacement and draft retention across keyboard modes.

## Paired evidence and boundary

The September 8 rectangle-leader receipt contains paired native/clone width then
height sizing, anchors and reachable keypad evidence. September 10 keyboard
receipts cover system-keyboard transitions. A fresh exact-build paired repeat
and new illustrated publication are still blocked by simulator input delivery,
so QA-30 remains partial. Inventory stays 13 passed / 0 failed /
1 device-blocked / 42 incomplete. Immutable `05be744` IPA unchanged.

