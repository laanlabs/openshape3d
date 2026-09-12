# QA-37 — Selection anchor checkpoint

Evidence date: September 11, 2026. Baseline `ffc3867`.

## Reference and implementation

Shapr3D's official Constraint Settings documentation defines an **Anchored
Sketch Entity** preference with **First Selected** and **Last Selected**
behaviors. Existing constraints take priority over that preference:
<https://support.shapr3d.com/hc/en-us/articles/7394385784476-Constraint-Settings>.

OpenShape3D now persists the same two choices in the Constraints sheet and tracks
sketch-entity selection order independently from membership. Explicit constraint
application adds the preferred whole entity as a transient solve anchor only; it
is not stored as a Lock constraint. If that preference conflicts with an existing
constraint, the solver retries without the transient anchor, preserving the saved
constraint as the authority.

The deterministic matrix covers first/last preference, normal/reversed selection
order, repeated solve stability, Undo/Redo and an existing Lock override. App
settings tests cover default and persistence. Portrait and landscape UI workflows
verify both segmented choices remain reachable without regressing the established
grid-off/two-line Parallel application.

## Regression history

- `/tmp/os3d-qa37-anchor-targeted-20260911.xcresult`: compile-only failure from
  invalid SwiftUI `Section` shorthand; no test ran.
- `/tmp/os3d-qa37-anchor-targeted2-20260911.xcresult`: compile-only fixture
  failure from a shadowed/read-only document reference; no test ran.
- `/tmp/os3d-qa37-anchor-targeted3-20260911.xcresult`: corrected anchor model
  target passed 1/1.
- `/tmp/os3d-qa37-anchor-final-20260911.xcresult`: 40/44; two model fixtures
  inherited a saved circular-annotation preference and two UI queries treated a
  segmented control as static text.
- `/tmp/os3d-qa37-anchor-final2-20260911.xcresult`: 42 model/settings tests
  passed; both UI workflows exposed that the new section displaced the old
  landscape Grid control.
- `/tmp/os3d-qa37-anchor-ui-final-20260911.xcresult` and
  `/tmp/os3d-qa37-anchor-ui-final2-20260911.xcresult`: fixture-only selection
  failures after Grid was no longer actually disabled.
- `/tmp/os3d-qa37-anchor-ui-final3-20260911.xcresult`: portrait passed;
  landscape could not scroll to the new picker.
- `/tmp/os3d-qa37-anchor-ui-final4-20260911.xcresult`: portrait passed;
  landscape reached but did not hit the off-screen Grid switch.
- `/tmp/os3d-qa37-anchor-landscape-20260911.xcresult`: corrected landscape
  workflow passed 1/1 using the Form's actual collection view.
- `/tmp/os3d-qa37-anchor-final3-20260911.xcresult`: final one-owner gate passed
  clean **44/44**, zero failures/skips: 12 `AppSettingsTests`, 30
  `ConstraintApplyTests`, and 2 portrait/landscape `ConstraintRailUITests`.

No product assertion was weakened to obtain the final result.

## Boundary

The behavior is implemented and regression-tested. Official documentation is the
reference for the setting semantics; fresh paired native/clone gesture evidence
is still unavailable because supported live canvas input delivery remains
blocked. The default-choice parity is therefore not claimed from desktop live
evidence, and Google Docs publication has no new screenshot pair to add.

QA-37 remains partial. Acceptance inventory remains **15 passed / 0 failed /
1 device-blocked / 40 incomplete**. The immutable `05be744` IPA is unchanged;
no current-revision device installation or physical Pencil result is claimed.

## Fresh native comparison attempt — September 11 evening

At `d5fc3fe`, new Front-plane Sketch 11 contains two separate nonparallel
lines. Auto-constraining OFF and both First Selected / Last Selected choices
were directly inspected and the setting switched successfully. Body 04 remains
visible behind the fixture; attempted body hiding did not take effect.

The generic Sketch query matched a menu and failed. Targeting its observed AX
control entered Sketch 11. App-targeted strokes and foreground Escape worked;
untargeted strokes/background keys sometimes reported success without visible
change. Shift-modified 1px and stationary drags replaced, rather than extended,
the selected line. Native's documented multi-selection gesture remains
Shift-click; these delivery attempts do not establish that gesture.

A selection box acquired both lines. Parallel under First Selected preserved the
lower line and rotated the upper; Undo restored the original pair. Repeating
the same lower-line selection/box sequence under visibly selected Last Selected
produced the same geometry. Therefore box selection does not establish the
required ordered-selection semantics here. The intermediate interpretation that
this proved First Selected is withdrawn. No clone defect or parity pass follows
from these samples. Explicit order, reverse order and Lock override remain open.

All native PNG/JSON and SHA-256 inventory are retained at
`reports/openshape3d-core-sketch-milestone-2026-09-08/selection-anchor/qa37-live-2026-09-11`
under the OpenClaw workspace. No new tests or product changes were needed for
this input diagnosis. No new report publication; verified baseline remains
863 illustrated / 38 master assets. QA37 remains partial, inventory26/0/1/29.
Native is parked after Last Selected Parallel; Undo restores the two-line fixture.
Next independently actionable comparison: QA36 Equal on this two-line fixture,
which needs membership but not explicit click ordering. iPad unchanged.

## September12 explicit-order retry

At b4462ec, fresh native upper800560→900550 length70,912.4119mm and
lower800620→900640 length71,957.8636mm. AutoOFF and First Selected
visually verified. Selecting upper then Shift-box containing only lower
replaced selection; stationary Shift drags did nothing; one-pixel Shift drag
selected upper alone. All observed as one edge, never two ordered operands.
No constraint applied and no native/clone order conclusion. Exact-order route
remains input-blocked, not a product failure. No source change or test rerun.
Durable selection-anchor/qa37-order-live-2026-09-12 preserves PNG/actions/index.
Next QA38 midpoint Disconnect, independent of ordered selection. Inventory
27/0/1/28; reports1129/master38; no runner; iPad unchanged.
