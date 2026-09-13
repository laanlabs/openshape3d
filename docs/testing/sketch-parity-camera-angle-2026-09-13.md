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

- Native edge-on drawing: not reachable — native-13, captured immediately after
  View > Front with no other input, is already in model mode with the empty
  Sketch 14 discarded: a **standard view command ends the sketch in native**,
  whereas the clone's `view.front` keeps the sketch active (clone-08). One
  observation; recorded as a difference to confirm, not fixed. No Line placed.
- 85° is unreachable by command on either side (native rotates in 15°/45°
  steps, the clone only has standard views); 45° (native) / isometric (clone)
  and 90° (clone) were used instead.
- Native one-sketch-per-plane note from earlier receipts: here the grid pick
  created a new Sketch 14 rather than continuing Sketch 12 — the picked plane
  was not isolated (the view had been rotated), so no identity claim either way.

## Result

QA-03 finite recipe: entry alignment, orbit-while-active and normal-view action
are paired; edge-on is clone-only; 85° substituted. Partial; no promotion.
Evidence: …/planes/qa03-camera-angle-live-2026-09-13/ — 13 assets,
evidence-index.json. Local only; publication pending. 32/0/1/23; iPad unchanged.
