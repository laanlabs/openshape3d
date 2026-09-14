# QA-30 — Rectangle numeric sequence checkpoint

Evidence date: September 11, 2026. Closure baseline `681811e`.

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
`/tmp/os3d-qa30-sequence-serial-20260911.xcresult`. The exact closure tree was rerun serially and also passed clean 4/4, zero failures/skips, at
`/tmp/os3d-qa30-sequence-final-20260911.xcresult`:

- edge width keypad → height system keyboard → Undo/Redo;
- right-side height keypad reachability and first-digit replacement;
- lower editor/system-keyboard visibility;
- seed replacement and draft retention across keyboard modes.

## Paired evidence and boundary

The September 8 rectangle-leader receipt contains paired native/clone width then
height sizing, anchors and reachable keypad evidence. September 10 keyboard
receipts cover system-keyboard transitions. The exact closure tree adds inspected
current-build captures for edge width, adjacent height, near-rail keypad clearance,
lower system-keyboard clearance and mixed-source draft retention.

Publication is verified through anonymous TXT/DOCX export. The illustrated report
contains one QA-30 heading and verdict, 800 unique image placements, exactly four
new exported closure assets, and zero loss from the prior 796 assets. The master
roadmap retains 38 media and contains one dated QA-30 note. The durable manifest is
`reports/openshape3d-core-sketch-milestone-2026-09-08/rectangle-sequence-qa30/publication-verification-2026-09-11.json`.

QA-30 passes for this finite desktop recipe. Inventory advances to **22 passed /
0 failed / 1 device-blocked / 33 incomplete**. Physical touch/Pencil remains
QA-52; dense labels, manual reposition and camera zoom remain QA-29. Immutable
`05be744` IPA unchanged.

