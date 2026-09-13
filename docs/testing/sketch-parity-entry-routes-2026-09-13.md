# QA-02 — entry method: Sketch menu, selected face, existing item, hover + Space (2026-09-13)

Definition (audit 04.md): "Sketch menu, selected face, existing item, keyboard
hover/Space." Source 6ac3250 for the Space route; the other routes are unchanged.

## Routes

- **Sketch menu → plane.** Paired under QA-01: origin tiles (Sept 8 grid
  receipt), offset plane, Items plane row, bare-grid miss, curved-face refusal
  (today). Native: Sketch → tool list "No active plane" → grid tap.
- **Selected face → Sketch.** Clone: PlanesUITests.testSketchOnFaceThenExtrudeNewBody
  and today's live cap tap (QA-01 receipt). Native today: box top face clicked
  in the zoomed Top view, then Sketch (AX press) entered Sketch 14 directly
  with no plane prompt (native-05/06) — the prompt only disappears with a plane
  already chosen; from directly above the selected face is not visually
  distinct, so the selection is inferred from the missing prompt.
- **Existing item.** Paired and published under QA-24 (Items sketch row,
  0cc5d6c) and QA-41 (outline / explicit Exit route). Nothing new today.
- **Keyboard hover + Space.** Native: with nothing selected, Space with the
  pointer over the grid started a sketch there with Line armed (native-01-
  space-grid.png); over the box top face likewise (native-04-space-face.png).
  Clone before: Space was bound to an unrouted "Zoom to Selection" (a spec
  reading the reference app does not bear out); it did nothing. Clone at
  **6ac3250**: the viewport keeps the last hover ray, and a routed
  `sketch.onHoveredPlane` (chord Space) runs the plane picker on it — tiles,
  construction planes, planar faces and the bare grid start a Line sketch;
  nothing hovered, or a curved wall, is a no-op with no picker left behind.
  Gate: CommandDispatch/Registry/Search, AgentRouter, SelectionUXTests (new
  testSpaceStartsSketchOnHoveredPlaneOrFace), PlaneTests — 81/81, one clean
  run. The bridge now advertises 38 routed commands.

## Live limitation — hover never reaches the simulator app

Space is delivered (the bare `x` key opens Command Search through the same
path), but `hoverRay` stays nil: Peekaboo `move` (app-relative, global,
smooth) and Simulator "I/O > Input > Send Pointer to Device" all produced no
UIHoverGestureRecognizer event, so Space was a no-op live (clone-01/02/03,
diag-01). This is the QA-21 "live pointer delivery unresolved" limitation;
the route is unit-proven here and needs a physical trackpad/Pencil hover
(QA-52) for live evidence.

## Result

All four routes have evidence; three are paired live, the fourth is native-
observed and clone-unit-proven with live delivery blocked by the environment.
Partial; no promotion. Evidence: …/planes/qa02-entry-routes-live-2026-09-13/
— 8 assets, evidence-index.json. **Published 2026-09-13 17:51 UTC:** https://docs.google.com/document/d/1NEY0MdGsrW1dRMJA_Kg81_k_R6WP9twuV0IK-Wl-WkA/edit. 32/0/1/23; iPad unchanged.
