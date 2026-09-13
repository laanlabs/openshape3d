# QA29 — dense values, manual reposition, camera zoom (2026-09-13)

The three items QA-29 still listed after the badge/keypad layout fixes.

## Native observation (Untitled Project, sketch24, Peekaboo-driven)

- **Dense values.** A drawn line read "164,058.8074 mm" on canvas; typing
  123456.7891 into its label committed and, on reselect, the label read
  "123,456.7891 mm": every decimal kept, thousands grouped, the text centred
  above the dimension line at constant size even where it is wider than the
  witness span. The info bar reads the same digits.
- **Manual reposition.** Corrected later the same day (the first drags had
  used window coordinates where `peekaboo drag` takes screen coordinates,
  so they landed on empty canvas and merely deselected): dragging a line's
  label DOES move its dimension leader, with the geometry untouched. For a
  measured label the placement lasts for the selection (deselect/reselect
  returns it to the default); for a driving dimension (100,000 typed) the
  dragged placement survives deselect/reselect and one Undo reverts it.
  The circle-label drag with correct coordinates was not repeated; its
  measured/driving rule is assumed to match.
- **Camera zoom.** Scroll up zooms out (grid 5,000 → 10,000 mm), scroll down
  in. Geometry scales; labels keep their screen size and follow their
  geometry, leaving the viewport with it — native does not clamp a label
  into view.
- Probe geometry undone (Edit > Undo ×3), sketch exited, Default View; the
  document is as found. Fifteen captures with SHA-256s in workspace reports
  layout/qa29-dense-zoom-live-2026-09-13/evidence-index.json (local).

## Clone

- **Defect found and fixed:** `DisplayUnit.compactLengthString` formatted
  canvas labels with `%g`, which caps at six significant digits — the same
  123456.7891 mm read "123457 mm" (and 1234.5678 mm read "1234.57 mm").
  Labels now keep up to four decimals (three for cm/m) and group thousands:
  "123,456.7891 mm", "R 50,000 mm". Unit test
  AppSettingsTests.testCompactLengthKeepsDenseValuesAndGroupsThousands; the
  existing compact-length expectations are unchanged.
- **Manual reposition (defect found and fixed):** the clone had drag-to-
  reposition only for diameter labels; linear labels had none. Linear labels
  now drag the same way (`moveDimensionLabel`, the diameter path generalised):
  measured placement lasts for the selection, a driving dimension's placement
  is saved and undoable (`labelOffset`), geometry never moves. Unit test
  ConstraintApplyTests.testLinearLabelPlacementTransientThenSavedUndoableWithoutGeometryChange;
  UI test DimensionUITests.testLinearLabelDragMovesLeaderOnlyAndPersistsOnceDriving.
  Gate: ConstraintApplyTests 81/81 and DimensionUITests testLinearLabelDragMovesLeaderOnlyAndPersistsOnceDriving + testNearRailCircleDiameterTargetRemainsReachable 2/2 (/tmp/os3d-split-label-20260913.xcresult, unit re-run /tmp/os3d-split-label2-20260913.xcresult).
- **Camera zoom:** labels are screen-sized SwiftUI text and follow their
  geometry; the clone additionally clamps a linear badge inside the canvas
  (badgeWithinCanvas, the right-palette fix) where native lets it leave —
  a deliberate reachability difference, recorded, not changed.
- UI test DimensionUITests.testDenseValueReadsInFullOnCanvas pins the full
  dense label ("123,456.7891 mm"), inside the canvas and clear of the palette
  and rail. The clone's zoom could not be exercised in XCUITest: its
  synthesized pinch lands as a one-finger orbit on this viewport (the run's
  recording shows the sketch tilting and the label going with it — the
  orbit recognizer is capped at one touch, so this is a harness artefact,
  not a device behaviour). Clone zoom stays a device/live item.
- Info bar: native reads the same digits as the label ("123,456.7891 mm");
  the clone's info bar keeps its two-decimal readout ("123456.79 mm") —
  observed, not changed here (the count/length rows were paired earlier).

## Result

Gate: AppSettingsTests 14/14 (/tmp/os3d-qa29-dense-20260913.xcresult) and DimensionUITests.testDenseValueReadsInFullOnCanvas 1/1 (/tmp/os3d-qa29-dense3-20260913.xcresult), serial on sim AC2FD923. Sixteen assets local (15 native, 1 clone). QA-29 stays partial only on the native circle-label reposition observation and a live clone zoom (device).
