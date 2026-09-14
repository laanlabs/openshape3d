# QA-03 — camera angle: entry alignment, orbit while sketching, normal view, edge-on (2026-09-13)

Source 7307177; no source change for this case. Definition (audit 04.md): "0/45/85
degrees, normal view action, orbit while sketch remains active."

Driver: camera changes by command on both sides — clone bridge `view.isometric` /
`view.front`, native View > Rotate View > Rotate Up by 45° and View > Front —
because Peekaboo drags/swipes do not reach the Simulator as touch drags. Gesture
orbit itself is therefore not exercised here (physical input remains QA-52).
Native's model-mode Sketch button ignores synthesized clicks with nothing
selected; it was pressed through its accessibility action.

## Paired

- **Entry alignment.** Clone: Line armed from an isometric view, bare-grid tap →
  ground sketch, camera flies head-on (cube "Top"), no Look at Sketch offered
  (clone-01-entry.png). Native: Sketch → tool list "No active plane" → grid tap
  → new Sketch 14 with the view aligned to the picked plane's normal (cube
  "Bottom", Line tip shown) (native-09/10). Both align on entry.
- **Orbit while sketching.** Clone: tool off, `view.isometric` → sketch stays
  active ("Drag to orbit — pick a tool to draw", Exit Sketching), grid follows
  the plane, "Look at Sketch" appears (clone-06-iso-insketch.png). Native:
  Rotate Up by 45° → Exit Sketching still present, "Normal to Sketch" appears
  (native-11-rot45.png). Both keep the sketch active and offer the realign
  action.
- **Normal view action.** Clone: Look at Sketch → head-on again, button gone
  (clone-07-lookat.png). Native: Normal to Sketch → button gone (native-12).

## Clone only

- **Edge-on (90°).** `view.front` on the ground sketch → the plane is a line,
  Look at Sketch offered (clone-08-front-edgeon.png). Line armed, two canvas
  taps → no entity created (the ray is parallel to the plane; no point lands)
  (clone-09-edgeon-taps.png). An implicit refusal; `grazingSketchAngle` (80°)
  is declared but unused, so there is no explicit grazing rule.

## Not observed / limitations

- Native edge-on drawing: not reachable by a named view — see the confirmed
  rule below. No Line placed at edge-on natively.
- 85° is unreachable by command on either side (native rotates in 15°/45°
  steps, the clone only has standard views); 45° (native) / isometric (clone)
  and 90° (clone) were used instead.
- Native one-sketch-per-plane note from earlier receipts: here the grid pick
  created a new Sketch 14 rather than continuing Sketch 12 — the picked plane
  was not isolated (the view had been rotated), so no identity claim either way.

## Confirmed 11:05 EDT — named views while sketching (seven isolated trials)

Each trial: Sketch (AX press) → grid tap → new Sketch 14 on the ground, Top
view → one View-menu command → immediate accessibility read
(native-trial-*.png).

| Command | Result |
|---|---|
| View > Front | **sketch ended** (model mode, empty Sketch 14 discarded) |
| View > Right | **sketch ended** |
| View > Default View (oblique home) | **sketch ended** |
| View > Top (the sketch's own normal view) | stays in sketch |
| View > Bottom (its underside) | stays in sketch |
| Rotate View > Rotate Up 45° | stays, Normal to Sketch offered |
| Rotate Up 45° twice (90°, edge-on by rotation) | stays, Normal to Sketch offered |

Rule: a **named view that is not the active sketch's head-on view (or its
underside) ends the sketch; free rotation never does.** The clone kept the
sketch on `view.front` with the plane edge-on and Line taps placing nothing
(clone-08/09) — a dead state native never enters. Decision: match native in
`applyStandardView` (Views menu and bridge `view.*` both route through it);
Look at Sketch stays for free orbit.

**Fixed at dcee869.** `StandardView.viewAxis`/`isHeadOn(to:)`; a named view
that is not the active plane's head-on view or its underside finishes the
sketch. Gate: PlaneTests + CameraTests + SelectionUXTests (new
testNamedViewEndsSketchUnlessHeadOn) + PlanesUITests (rewritten
testNamedViewsWhileSketchingKeepOrEndTheSketch: Top keeps, orbit drag offers
Look at Sketch, Isometric ends) — 38/38, 0 skipped, one clean serial run
(/tmp/os3d-namedview-gate-20260913.xcresult). Clone live on the 10:23 build:
ground sketch → view.top keeps, view.bottom keeps, view.front ends (empty
sketch discarded), re-entered from isometric → view.isometric ends
(clone-r-bottom-stays / clone-r-front-ends / clone-r-iso-ends). Not covered:
orientation-cube taps (they do not route through applyStandardView) and
native's response to a cube tap — open.

## Result

QA-03 finite recipe: entry alignment, orbit-while-active and normal-view action
are paired; edge-on is clone-only; 85° substituted. Partial; no promotion.
Evidence: …/planes/qa03-camera-angle-live-2026-09-13/ — 13 assets,
evidence-index.json (24 assets after the trials and the dcee869 re-check).
**Published 2026-09-13 17:51 UTC:** https://docs.google.com/document/d/1V1VX8Bivj-Xwj3FxhFxXYf_Kx-_dvRvk9a3dXLwNdDU/edit. 32/0/1/23; iPad unchanged.
