# QA-01 — plane picker: curved face refused, planar cap, bare-grid miss (2026-09-13)

Source 3f7080c: `worldFacePlane` declines a curved smooth region (the test
`selectFaceOrBody` already uses), and a refused body tap keeps the plane
picker armed instead of falling through to the ground behind the body — the
rule the Section View picker already follows. Gate: PlaneTests +
SelectionUXTests (new testPlanePickerAcceptsCapRefusesCurvedWallAndFallsBackToGround)
+ PlanesUITests (new testPlanePickerRefusesCurvedWallAndAcceptsCap): 25/25,
0 skipped, one clean serial run (/tmp/os3d-plane-curved-gate-20260913.xcresult).

Driver: Peekaboo real-mouse clicks on the Simulator window, bridge on 8899.
Simulator AC2FD923, OS3D_FRESH + OS3D_DEBUG_SEED_CYLINDER (r 3, h 5).

## Clone before the fix (cf0fbd0 build)

Line armed → picker up (clone-02-picker.png). Tap on the cylinder's front-right
wall started Sketch 1 on a single facet plane — origin [2.87, 2.5, 0.88], yAxis
(−0.29, 0, 0.96) — a sliver the user never meant (clone-03-curved-tap.png).
Bare-grid tap → Sketch 1 on the ground plane (clone-04-miss.png).

## Clone after the fix (3f7080c build, 09:42)

- Curved wall tap → mode stays `pickingSketchPlane`, no sketch created
  (clone-r03-curved-refused.png).
- Top cap tap → Sketch 1 on the cap plane, origin [0, 5, 0], normal ±Y
  (clone-r04-cap.png); Exit with nothing drawn discards it.
- Bare-grid tap → Sketch 1 on the ground plane (clone-r05-miss.png); Exit
  discards it.

## Native

Shapr3D sketches on planar faces only (documented constraint). The picker's
exact response to a curved-face tap was **not observed live** this session:
the audit document's visible bodies (part24, Body 04) are both boxes
(native-05/06), and building a cylinder there by blind clicks kept catching
sketch edges instead of a profile (native-07/08). The clone's stay-armed
fallback is therefore its own Section View rule, not an observed native
behaviour. The bare-grid miss was paired on Sept 12 (native entered its
existing ground Sketch 12; the clone a new ground sketch — the one-sketch-per-
plane difference). Planar-face pick: not re-observed natively this session.

## Result

QA-01's finite recipe — XY/YZ/ZX, planar face, offset construction plane,
curved face, miss — now has clone evidence for every element and paired
evidence for the origin tiles, offset plane, Items plane row and miss. Open
before any promotion: native curved-face and planar-face picks observed live in
one session, and publication of the QA-01 batches. Not a row promotion.

Evidence: ~/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/
planes/qa01-curved-miss-live-2026-09-13/ — 11 assets, evidence-index.json.
**Published 2026-09-13 17:51 UTC:** https://docs.google.com/document/d/1vYOerMVwnegDJRUa2xy2qh2pU04GTQO8DDWIQdcndZU/edit. Acceptance 32/0/1/23; iPad unchanged.
