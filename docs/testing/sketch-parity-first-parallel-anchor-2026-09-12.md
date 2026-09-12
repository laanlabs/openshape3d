# QA37 First Selected Parallel — September 12, 2026

## Confirmed paired gap

Baseline source13badd6 / checkpoint729f4b3. Native First Selected,
Auto-constraining off: lower960650→1060670 selected before upper960600→1060580.
Parallel preserves lower and rotates upper about its first endpoint to1060620.
Undo and reverse selection preserve upper and rotate lower to1060630. Both
applications clear selection after apply. Native lengths approximately99879mm.

Clone First Selected/Auto-Constrain off/all four acquisition snaps off:
lower200700→300720 and upper200650→300630, ordinary additive second tap.
First line remains exact; second length1.2619028082→0.3912311496mm, its first
endpoint moves0.4565192990mm. Saved sketch JSON confirms geometry independently
of the camera. A preceding Shift-box rotated the clone camera rather than
selecting; excluded as input-route mismatch, retained screenshot. No geometry
was changed by that camera gesture. Native initial one-edge attempt excluded.

## Regression and implementation

Before0/1 (three assertions): moving start/end/length fail, anchor/history pass.
/tmp/os3d-qa37-first-before-20260912.{log,xcresult}.

Scoped fix maps moving/anchor indices from First/Last Selected in existing
parallelPlacement. Existing saved-system projection and fallback unchanged;
no persisted preference constraints or dimensions. Focused4/4 and expanded6/6 both clean, zero failures/skips. Expanded gate adds
reverse native geometry and First Selected locked-endpoint/driving-length preservation.
Exact Undo/Redo and JSON assertions retained.

## Evidence and boundaries

Durable evidence: /Users/thelodgestudio/.openclaw/workspace/reports/
openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa37-anchor-live-2026-09-12.
Changed-build live, reverse-order/Lock override matrix, final regression and
publication pending. QA37 remains partial. Inventory30/0/1/25; illustrated1184,
master38. iPad and immutable05be744 unchanged.
