# Arc Return completion — September 9

Baseline `bad0948`; native Shapr3D in the saved Sketch04 and OpenShape3D on
`os3d-unit`. This receipt covers hardware Return after the first two Arc
endpoints. It does not close direct major/minor construction, tangent transition,
simulator hover delivery, or physical Pencil/touch acceptance.

## Paired result

Native two endpoint clicks exposed the default `45°` pending arc. The first
Return changed the active dimension focus but did not remove the geometry; a
second clean sample followed by one Escape retained the arc, establishing that
Return accepted it rather than cancelling it. Arc remained available for
continuation.

Before this correction the clone had no Return shortcut for the pending Arc.
`CommandShortcutsView` now registers the default action only while Arc has two
pending endpoints and no dimension editor owns Return. `finishArcInput()` commits
the current/default shape through the same chained path as a third-point click,
retaining the second endpoint as the next shared anchor.

On the exact built clone, two endpoint taps showed the default radius and `45°`
sweep. Return removed the construction rays/readouts and left the blue committed
arc plus its chain anchor; Escape then disarmed Arc without deleting that arc.
This is paired live evidence through the available desktop/simulator keyboard
route, not physical iPad evidence.

## Regression

- Focused `ArcTapConstructionTests` passed cleanly 11/11, including the new
  default-arc Return commit and shared-endpoint continuation assertion:
  `/tmp/os3d-arc-return-focused-20260909.xcresult`.
- Final current-revision combined run passed cleanly 35/35: 11 arc construction,
  21 live-dimension and three arc UI workflows:
  `/tmp/os3d-arc-return-combined-final2-20260909.xcresult`.
- An initial command containing a disallowed cleanup operation was rejected
  before `xcodebuild` launched. It ran no tests and is not a product failure.

## Excluded boundary attempts

Several later native clicks/drags advanced into a chained arc before a controlled
minor/semicircle/major third point could be established. Those screenshots are
not counted as boundary evidence. The existing typed `180°`/`270°` edit evidence
remains valid, but direct construction boundaries and tangent transition remain
open in QA-13.

Six paired screenshots and `SHA256SUMS` are retained under
`reports/openshape3d-core-sketch-milestone-2026-09-08/arc-return/`. Google Docs
publication is anonymously export-verified: the illustrated report contains
219 drawing placements and all six new PNGs match their exported media bytes;
the master roadmap remains at 38 drawings and includes the dated Return note.
The publication workflow initially displaced one prior chained-arc screenshot;
the exported predecessor identified the exact missing asset, which was restored
with its original caption before the final count. Verification artifacts are
`os3d-arc-return-illustrated.docx`, `os3d-arc-return-master.docx`, and
`publication-verification.json` in the same evidence directory.
