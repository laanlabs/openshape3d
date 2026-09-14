# QA-54 keyboard checkpoint — September 11, 2026

Evidence date: September 11, 2026. Baseline `80dfdc9`.

A clean one-owner current-tree gate passed **84/84**, zero failures/skips:

- 76 unit/model checks across application settings, command registry, command
  search, command dispatch, Circle input, rectangle cancellation and Arc input;
- 8 UI workflows across Command Search results/refusal/dismissal, persisted
  Single Key Action selection, system-keyboard seed replacement and invalid-
  expression focus recovery, click-away/tool-switch commit, and Return-driven
  line-chain completion/history.

Result: `/tmp/os3d-qa54-keyboard-final-20260911.xcresult`
Log: `/tmp/os3d-qa54-keyboard-final-20260911.log`

The new Single Key Action UI test selects Command Search, relaunches an editor
without resetting preferences, proves the persisted selection, and restores
Hotkeys. Its first attempt reopened into the gallery and incorrectly required an
editor-only Command Search button; that fixture failure is retained and excluded.
The corrected focused run passed 1/1 before the clean combined gate.

Retained paired September 9–11 evidence covers native and clone number-field
seed replacement, invalid Return with immediate focus recovery, 123/keypad
switching, arithmetic draft retention, Return commit, toolbar/Cmd-Z history,
line/arc/circle/rectangle Escape scope, and line Return completion. The current
run supplements rather than replaces those comparisons.

QA-54 remains **partial**: native Single Key Action preference switching was not
freshly observed in this checkpoint, and actual physical keyboard/Pencil input
belongs to QA-52. Peekaboo accessibility observation recovered, but foreground
hotkey/window capture delivery remained nonresponsive and was not counted.

Inventory remains **20 passed / 0 failed / 1 device-blocked / 35 incomplete**.
The immutable `05be744` IPA is unchanged.
