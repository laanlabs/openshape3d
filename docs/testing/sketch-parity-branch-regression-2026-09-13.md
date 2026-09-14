# Branch-wide regression after the 2026-09-13 changes

Full serial run of the unit and UI suites on sim AC2FD923 (os3d-parity-sept7,
iPad Pro 13-inch M5, iOS 26.5) at dbbbc0a, before merge:
/tmp/os3d-full-suite-20260913.xcresult, 111 minutes.

- Unit: **1611 executed, 0 failures, 1 skipped**.
- UI: **185 executed, 171 passed, 10 failed, 4 skipped**.

## The ten UI failures and their causes

Nine share one cause: **UI tests share the app's UserDefaults across
launches**, and `OS3D_RESET_STORE` wiped only the SwiftData store. A
preference one test flips leaks into every later launch: the constraint-rail
tests leave `anchoredSketchEntity = lastSelected`, `snapToGrid = false` and
`circularAnnotations = alwaysRadius` behind (the simulator's plist showed all
three after the run), and later circle and selection tests then fail in ways
the same test passes alone — "R1 mm" where "Ø1 mm" is expected, a symmetry
rail that never enables because the second tap does not join the selection,
a parallel rail likewise:

- ConstraintRailUITests: testCircleSymmetryChoosesAxisAfterOperandsAndCancels,
  testCoincidentPointOnLineAppliesAndHistoryDeselects,
  testLineSymmetryChoosesAxisAfterOperandsAndCancels
- DimensionUITests: testFreshCircleCenterDragMovesGeometryNotDiameterAnnotation,
  testNearRailCircleDiameterTargetRemainsReachable
- ParityWalkthroughUITests.testWalkthrough10ConstraintsAndStates
- RectangleWorkflowUITests.testArmedCircleDrawsAtHorizontalLineMidpointThroughConstraintBadge
- SketchParityStepsUITests.testCircleIsDimensionedAsADiameter
- MeshUnitPromptUITests.testPromptPreviewsAndAppliesChosenUnit (a 2 s wait on
  the result row; re-run with the others)

Fix: `OS3D_RESET_STORE` now also removes the app's persistent defaults
domain at launch, before any setting is read, so every test that asks for a
fresh store also starts from the shipped defaults. Launch arguments still
apply (argument domain); a test that relaunches WITHOUT the flag keeps what
it set, which is what the two SettingsUITests persistence tests check. This
is the same hazard that had `paletteOnRight = true` persisted earlier today.

One is a regression from today's edge-tap slice:
CylinderGrowShotUITests.testCylinderSideOpensDiameterBar — in the Front
view the centre tap on a 2 mm-tall cylinder wall sat inside the 8 pt edge
target of the cap rims, so the tap armed Fillet with every wall edge ("158
edges selected" on the contact sheet) instead of the radial Diameter bar.
Tightening the target to 5 pt and counting only sharp dihedrals (≥ 45°) was
not enough on its own — viewed edge-on the rims are exactly where a wall tap
lands (second contact sheet, same outcome). Fix (b4a1bb0): the plain-tap
edge target applies only when the tapped face is flat — a tap on a curved
wall is the wall; the native rim click paired on 2026-09-13 was made from
the cap side, which still routes to the edge — and the distance is measured
on screen through the live camera. The 5 pt / sharp-edge tightenings stay.
New unit test: SelectionTests.testTapOnACylinderWallMidHeightArmsTheRadialEditNotAFillet.

Nine were listed above as one cause; the targeted re-run below shows two of
the three ConstraintRail tests and the mesh-unit prompt were not — they fail
identically at 0e86c6b (the branch before today's slices, "test: correct
primitive selection fixture labels", 2026-09-12), so they are pre-existing.

## The three pre-existing failures

- **Symmetry rail ×2 (WIP QA-36, 006bf4b):** grid snapping, the same cause
  as the three DimensionUITests fixed earlier today. The recordings show
  the circle test's first 62 pt drag snapping its centre and its rim to
  the same 0.5 mm grid point (67.5 pt at this zoom) — no circle — and the
  line test's two drags snapping onto the grid so the "add the first
  operand" tap at the intended midpoint missed the line; the Symmetric
  button then stayed disabled with one operand selected. Fix (ad135ba): the
  tests launch with `-os3d.snapToGrid NO`; the axis pick, cancel, apply
  and glyph assertions are unchanged.
- **Mesh unit prompt:** the "Imported size" row sat below the fold of the
  iPad form sheet — the list shows the five unit rows and nothing under
  them without scrolling (the hierarchy reports two scroll pages), so the
  off-screen row was not in the hierarchy. Fix (05bbf71): the row moved into
  the top section with the file facts, where the consequence of the
  choice stays in view.

## Result

Targeted serial re-runs on the same simulator after the fixes (the full
suite is not re-run; the fixes touch a DEBUG launch flag, one UI test's
relaunch and the plain-tap edge routing, whose owning suites are below):

| Run | Bundle | Outcome |
|---|---|---|
| The ten failing tests after the defaults reset (fa7f22b) | /tmp/os3d-regress-fix-20260913.xcresult | Six pass: coincident point-on-line, both DimensionUITests, walkthrough 10, the rectangle circle badge, the circle-diameter step. Both symmetry tests, the mesh-unit prompt and the cylinder still fail. SettingsUITests.testSnappingControlsPersistAcrossLaunch newly failed because its relaunch carried the reset flag — the test now relaunches without it |
| Snapping persistence + cylinder + SelectionTests, with 5 pt and sharp edges only | /tmp/os3d-cyl-fix-20260913.xcresult | 14/15: snapping persistence passes, SelectionTests 13/13; the cylinder still routed to Fillet |
| Cylinder + BlendUITests + SelectionTests after the flat-face guard (b4a1bb0) | /tmp/os3d-cyl-fix2-20260913.xcresult | CylinderGrowShotUITests 1/1, BlendUITests 4/4, SelectionTests 13/13 |
| Attribution at 0e86c6b (detached worktree /tmp/os3d-attrib-wt, since removed) | run on the same simulator | testCircleSymmetryChoosesAxisAfterOperandsAndCancels, testLineSymmetryChoosesAxisAfterOperandsAndCancels (added by the WIP QA-36 commit 006bf4b; the recording shows the first circle drag drawing nothing) and MeshUnitPromptUITests.testPromptPreviewsAndAppliesChosenUnit (result row not found within 2 s, line 60) fail identically; the cylinder test passes there, which is what marked it as today's regression |

| The three pre-existing after 05bbf71 / ad135ba | /tmp/os3d-preexist-20260913.xcresult | 3/3: both symmetry tests and the mesh-unit prompt pass |

Net: **all ten fixed and verified** — six by the defaults reset, the
cylinder by the edge-routing fix, two by drawing without grid snapping,
one by the sheet layout. Because the defaults reset changes every UI
launch, the full serial suite is re-run at the final state
(/tmp/os3d-full-suite2-20260913.xcresult, started 2026-09-13 20:40);
its result is recorded below when it completes.

## Full-suite re-run at the final state

FULLSUITE2_PLACEHOLDER
