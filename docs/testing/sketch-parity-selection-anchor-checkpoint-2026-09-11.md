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
