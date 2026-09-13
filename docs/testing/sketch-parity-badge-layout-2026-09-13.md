# QA-29 — badge layout: right-hand palette and compact width (2026-09-13)

Open items from the register: "right-palette/compact open". Clone-only lane —
Shapr3D has no toolbar-side setting and no phone layout.

## Right-hand palette (iPad)

Before: with the toolbar on the right, a line running under the palette put
its length badge there too — the badge is placed at the dimension line's
midpoint with no canvas clamp (clone-02, live: "Length 5.00 mm" in the info bar,
no badge anywhere on screen). Fixed at **273f0c4**: linear badges slide along
their dimension line to stay between the constraint rail and the palette on
whichever side each sits (`badgeWithinCanvas`). After: the badge sits beside
the palette and its keypad opens clear of it and commits (clone-04/05/06,
XCTest attachments from DimensionUITests.testEdgeKeypadStaysClearOfRightHandPalette,
which forces the side with `-os3d.paletteOnRight YES`).

## Compact width (iPhone 17 Pro, 402 × 874)

Before: the keypad opened under the left palette (its x 24.75 against a palette
ending at 68). Cause: the editor's rail inset assumed the full 184-pt constraint
rail, which the phone layout replaces with a 44-pt menu, so 96 + 184 left no
room and the editor centred over the palette. Fixed at 273f0c4: the overlay's
rail inset is size-class aware (72 pt at compact) for the badge clamp, the
editor and the keypad bounds. CompactWidthBarUITests.testEdgeKeypadIsUsableAtCompactWidth
added; compact suite 4/4, one clean run.

## Simulator preference finding

The parity iPad simulator's app container carried `os3d.paletteOnRight = true`
and `os3d.circularAnnotations = alwaysRadius` from the Sept 11 handedness
runs (`simctl … defaults read` does not see the sandboxed plist). Every live
capture today therefore showed the palette on the right, and five
DimensionUITests failed for that reason alone. Both keys were removed
(backup kept in the session scratchpad) and the affected tests rerun.

## Pre-existing failures found, not fixed

With the baseline preference restored and independently of this change (they
fail identically with the overlay change stashed, and two of them also fail at
the handoff commit 0e86c6b), three DimensionUITests fail on the branch:

- testLineDistanceTypeBadgeChangesReadoutWithoutOpeningKeypad — after
  switching the badge to "horizontal", tapping the line does not reselect it.
- testNearRailCircleDiameterTargetRemainsReachable — after committing Ø1,
  tapping the new rim does not reselect the circle (at 0e86c6b it fails
  earlier, on the rail-clearance assertion).
- testConnectedCircleGlyphDoesNotInterceptCenterDrag — the centre drag moves
  the connected circles less than the test expects (553 vs 573 pt).

Two share a pattern — tap-to-reselect sketch geometry after an edit — worth
one investigation. Logged under QA-23/QA-29 with owner and next action.

## Result

Right-palette and compact badge/keypad layout are fixed and covered by
regression; QA-29 remains partial on the audit's other items (dense values,
manual reposition, camera zoom) and the three pre-existing failures.
Evidence: …/layout/qa29-right-palette-compact-2026-09-13/ — 6 assets,
evidence-index.json. Local only. 33/0/1/22; iPad unchanged.
