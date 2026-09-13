# QA24 — curved-face and edge selection breadth (2026-09-13)

The last open class of QA-24: what a click selects on curved geometry and
on edges, and what Select Through offers there.

## Native observation (Untitled Project, a probe cylinder, Peekaboo-driven)

Built a cylinder to probe with: circle in sketch24 → Exit → click the fill
("1 face", Extrude - One-Sided) → view rotated up 45° → 20,000 typed on the
pull arrow → "Body 06" (R 50,000 mm). Undone afterwards (two Undo steps
verified, Default View); nine captures with SHA-256s in workspace reports
selection/qa24-curved-edge-live-2026-09-13/evidence-index.json (local).

- **Curved wall click:** "1 face  50,000 mm" (the radius) and the adaptive
  tool chip "Offset Face — drag the arrow to offset the faces inward or
  outward", with a pull arrow on the wall.
- **Rim edge click:** "1 edge  314,159.2654 mm  50,000 mm" (length and
  radius) and "Chamfer/Fillet (F) — drag arrows to chamfer or fillet edges".
- **Select Through This Point on the wall** (right-click menu, pressed via
  accessibility; a synthesized click on the menu row does nothing): "Body 06 ›
  Face - Extrusion 06, Face - Extrusion 06, Body 06; sketch24 › Profile" —
  both wall halves along the ray, the body, and the sketch profile behind.
- The right-click menu itself: Select All, Select Through This Point…,
  Sketch on Face, Section View, Show/Hide, Isolate.

## Clone

- Curved wall click already matched the shape of the native behaviour: a
  plain cylinder's wall arms the radial push/pull (the diameter edit), other
  curved smooth regions select as a face with Move refused ("needs a flat
  face"). Not changed.
- **Select Through** skipped curved faces (kept the body choice only). Now a
  curved hit is a "Face — body" choice keyed by its whole smooth region (the
  clone's cylinder is one face, so it lists once where native lists its two
  halves); choosing it lands where a direct tap lands — a plain cylinder's
  wall arms the radial push/pull, other curved regions select as a face —
  with no geometry edit. Unit test
  SelectionTests.testSelectThroughOffersACurvedWallAndChoosingItArmsTheRadialEdit.
- **Edge click** had no meaning on a body in the clone (edges were only
  pickable after arming Fillet/Chamfer from the Modify group). A tap within
  8 pt of a selectable edge now arms the blend pick with that edge chosen —
  the clone's counterpart of native's Chamfer/Fillet chip — and the info bar
  reads "Edges 1 / Length"; a tap well inside a face still selects the face.
  Not matched: native's radius readout for a circular edge (the clone's
  edges are segments) and native's edge-only selection state without a tool.
  Unit test SelectionTests.testTapNearABodyEdgeArmsFilletOnThatEdge.

## Result

Gate: SelectionTests 12/12, SelectionUXTests 15/15, SelectionUITests.testLongPressShowsSelectThroughPopup 1/1, BlendUITests 4/4 (/tmp/os3d-qa24-curved-edge-20260913.xcresult; SelectionTests re-run /tmp/os3d-qa24-curved-edge3-20260913.xcresult), serial on sim AC2FD923. Nine native assets local; clone live check not run (the chooser and the edge tap are covered by the UI and unit gates above). QA-24 stays partial on native's edge-only selection state and the circular-edge radius readout.
