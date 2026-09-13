# QA-01 — Items plane-row selection, paired live check (2026-09-13)

Source cf3b875 (Items plane row selects the plane), docs 0de9c16. Regression
before the live check: PlaneTests + SelectionUXTests + ItemsUITests +
PlanesUITests 24/24, 0 skipped, one clean serial run
(/tmp/os3d-plane-select-gate-20260913.xcresult).

Driver: Peekaboo 3.9.6 clicks on the Mac windows (`--foreground
--input-strategy synthOnly`; background AX presses do not reach the Simulator
viewport), bridge on 127.0.0.1:8899 for state. Simulator AC2FD923
(os3d-parity-sept7, iPad Pro 13-inch M5, iOS 26.5), branch build 08:50:53,
launched OS3D_FRESH + OS3D_DEBUG_SEED (4 mm box). Native: Shapr3D macOS,
Untitled Project with Plane 01 (offset 500 mm) and Sketch 13.

## Native (reference)

1. Exit Sketching from Sketch 13 → model mode; Sketch 13 stays selected
   ("1 edge").
2. Click Items row "Plane 01" → row highlighted, info bar "1 plane", History
   "Related to Selection" filters to Plane - Offset 01 (native-02-plane.png).
3. Click Sketch → enters sketching on that plane immediately, no plane picker.
   Native re-enters the plane's existing Sketch 13 (one sketch per plane)
   (native-03-sketch.png). View stayed Top (plane parallel to Top), so no
   camera-move comparison from this state.

## Clone

1. Tap box top face → face bar → Offset Plane (default 2 mm) → Add Plane →
   Plane 1 at y = 6 above the 4 mm box (undo title "Offset Plane").
2. Items → click "Plane 1" row → plane quad switches to the accent fill and
   border; mode stays idle (clone-05-planeselected.png, clone-05-viewport.png).
3. Sketch → Line → mode `sketching`, "Sketching on plane" pill, head-on view,
   Line armed, no plane picker. /v1/sketches: Sketch 1 plane origin [0,6,0],
   xAxis [0,0,1], yAxis [1,0,0] — the offset plane (clone-07-sketch.png,
   clone-07-state.json).
4. Exit Sketching with nothing drawn → empty provisional sketch discarded
   (sketchCount 0, undo title still "Offset Plane"), Plane 1 retained
   (clone-08-exit-items.png). Existing QA-04 empty-exit rule; no native
   counterpart here because native re-entered a non-empty sketch.

## Result

Plane-row selection → Sketch-on-plane is paired: both apps select the plane
from its Items row and Sketch enters that plane without the picker. This is a
partial QA-01 recipe, not a row promotion.

Observed differences, recorded and not fixed here:

- Native highlights the Items row and reports "1 plane" in the info bar; the
  clone highlights only the viewport quad — no row highlight, no readout.
- Native continues the plane's existing sketch; the clone creates a new sketch
  per entry (documented coplanar-identity rule,
  PlanesUITests.testCoplanarNewSketchAndNamedContinuationStaySeparate). Did
  not manifest here — the clone had no prior sketch on the plane.

Evidence: ~/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/
planes/qa01-plane-item-live-2026-09-13/ — 10 assets, evidence-index.json
(sha256 per asset). Local only; publication pending. QA-01 stays partial:
curved-face and controlled-miss matrix open; the twelve earlier offset assets
also remain unpublished. Acceptance 32/0/1/23; iPad unchanged.

## Re-run after cf0fbd0 — row highlight and "1 plane" readout (09:28 EDT)

Same sequence on the 09:19 branch build (cf0fbd0). Regression before the
re-run: PlaneTests + SelectionUXTests + ItemsUITests (new
testPlaneRowSelectsPlaneReadsOnePlaneAndSketchStartsOnIt) + PlanesUITests
25/25, 0 skipped, one clean serial run
(/tmp/os3d-plane-row-gate-20260913.xcresult).

- Clone: Plane 1 row → row tinted with the accent (blue text, the
  constraint-row idiom), plane quad accent, info bar "Selected 1 plane";
  bridge measurements [("Selected", "1 plane")] (clone-r05-planeselected.png,
  clone-r05-viewport.png). Sketch → Line → sketching on Sketch 1 at [0,6,0],
  readout cleared (clone-r07-sketch.png); Exit discards the empty sketch
  (clone-r08-exit-items.png).
- Native: Plane 01 row → solid accent row, "1 plane" (native-r02-plane.png);
  Sketch → Sketch 13 on the plane (native-r03-sketch.png).

Row highlight and readout gap closed. Remaining styling nuance, recorded but
not tracked as a gap: native paints the row solid accent with white text and
the bare "1 plane"; the clone uses its light-tint/blue-text row idiom and the
labelled "Selected 1 plane". The one-sketch-per-plane difference is unchanged.
Evidence appended to the same folder (index regenerated, 18 assets).
**Published 2026-09-13 17:51 UTC:** https://docs.google.com/document/d/192lJUc0-2Nr8tJUIrtHJeu0Oue2UzhjZws91cwbkOks/edit (16 images, captioned, SHA-256 per original).
