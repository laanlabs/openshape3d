# QA-53 layout checkpoint — September 11, 2026

Evidence date: September 11, 2026. Baseline `470d1f4`.

A clean one-owner current-tree gate passed **51/51**, zero failures/skips:

- 43 model/layout checks across `AppSettingsTests`,
  `SketchLinearDimensionLayoutTests`, `SketchDiameterDimensionLayoutTests`, and
  `GizmoScreenLayoutTests`;
- 8 UI workflows covering portrait/landscape, left/right toolbar side,
  Items/History panels, accessibility-extra-extra-extra-large text, constraint
  rail reachability, lower system-keyboard clearance, a near-rail diameter
  target, and the compact landscape extrusion bar.

Result: `/tmp/os3d-qa53-layout-final4-20260911.xcresult`
Log: `/tmp/os3d-qa53-layout-final4-20260911.log`

## Retained failures and corrections

- The first handedness attempt opened the sketch constraint-settings sheet rather
  than global Settings. The corrected workflow uses `SettingsButton`, normalizes
  the persisted preference to Left, verifies both orientations, flips to Right,
  verifies both orientations, and restores Left.
- Two combined runs exposed test isolation issues: a persisted Right preference
  and a still-settling landscape-to-portrait transition. The final fixture
  normalizes the preference and allows the requested orientation to settle
  before launch.
- The near-rail diameter workflow carried pre-`5436e46` assumptions that numeric
  commit and history retained circle selection. The corrected test requires the
  native-matching selection clear, deliberately reselects the measured rim, and
  then verifies committed/restored geometry and moved-annotation history. Its
  final focused rerun passed 1/1 before the clean combined gate.
- One mistyped diagnostic destination (`...435F://BFD1A16`) was interrupted before
  it selected a simulator or ran a test. It is excluded from evidence.

No product source changed in this checkpoint.

## Live-evidence boundary

Retained paired portrait/landscape radial, dimension-label, keypad and edge-
clearance screenshots remain valid for those previously compared states. Fresh
Peekaboo discovery recovered after the suite, but window capture failed for both
Simulator and Shapr3D with `Web-focus detection returned without its required
mutation outcome`; direct `screencapture -l` also produced no image. Therefore
handedness, accessibility-text and open-panel permutations remain automated-only,
and QA-53 stays **partial** rather than passed.

Inventory remains **20 passed / 0 failed / 1 device-blocked / 35 incomplete**.
Physical Pencil/touch remains QA-52. The immutable `05be744` IPA is unchanged.
