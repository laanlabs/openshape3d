# Direct sketch comparison — September 7, 2026

## Method and scope

After the user unlocked the Mac at 08:31 EDT, both applications were operated visibly through Peekaboo. Temporary four-hour caffeinate assertions prevent idle display/system sleep and assert user activity; no permanent lock settings changed. Earlier 08:07 lock blockage is resolved.

Reference: installed native Shapr3D 26.121.0, Limited Access banner, new Untitled Project. Clone: OpenShape3D at f1dfa0a, dedicated os3d-parity-sept7 iPad Pro 13-inch M5 simulator, iOS 26.5, portrait, new Untitled 3. Reference input is Mac mouse; clone input is mouse-simulated touch. This is not physical Pencil or same-device parity certification. Always Show Dimensions and Always Show Constraints were OFF in both apps. Coordinates below are screenshot pixels, not CAD units.

## Confirmed discrepancies and fixes

### P1 — Diagonal rectangle width edit moves its first corner (SK-03)

Draw a diagonal rectangle, finish, then reduce its width. Shapr3D keeps the first corner fixed: left edge x419 before and after 370→200 mm. Clone resizes around the center: left edge moves x140→160 and right edge x262→241 when width changes 1.5→1 mm. Height remains unchanged.

Fix: carry construction-anchor intent through numeric dimension edits; a diagonal rectangle must preserve its original first corner. Do not impose this behavior on center rectangles. Acceptance: exercise all four drag directions, both width and height edits, undo/redo and save/reopen.

Evidence: live-shapr-diagonal.png, live-shapr-diagonal-sized.png, live-sim-diagonal-before.png, live-sim-diagonal-sized.png.

### P1 — Sketch entry leaves the clone camera oblique (SK-07 / SK-08)

Shapr3D Sketch → ground plane tile immediately enters a normal Top view with a grid. Clone explicitly reports “Sketching on ground plane” after blank-ground selection but remains oblique until Look at Sketch is pressed. An earlier clone tile pick selected Front rather than the intended ground plane; after Look at Sketch, Front had no visible grid. Treat tile occlusion and missing Front grid as follow-up investigations, not proof that the earlier pick was ground.

Fix: normalize the camera on successful sketch-plane entry, preserve a clearly indicated active plane, and verify usable grids in all plane orientations. Acceptance: repeat explicit XY/XZ/YZ tiles and ground fallback independently.

Evidence: live-shapr-plane.png, live-shapr-entry.png, live-sim-ground.png, live-sim-entry.png, live-sim-top.png.

### P1 — Line length readout disappears after creation (DM-02)

After horizontal drag/release, Shapr3D retains the new line’s length badge and witness lines without opening a keypad. Clone displays the line but no length badge. Both Always Show switches were OFF in each app.

Fix: retain the newly created entity’s appropriate selection/annotation state until the next meaningful action. Acceptance: draw line, inspect/edit retained length, start next entity, deselect, exit and reselect with visibility OFF and ON.

Evidence: live-shapr-dragged.png, live-sim-line-drawn.png, live-shapr-constraint-settings.png, live-sim-constraint-settings.png.

### P1 — Keypad opening and placement obstruct drawing (DM-12)

Clone automatically opens numeric input after center/diagonal/three-point rectangles and circle completion; Shapr3D leaves dimensional badges visible and opens input when a badge is chosen in the tested mouse workflow. Clone’s diagonal rectangle keypad covers the entire small rectangle; its center-rectangle input appears far above the geometry. Reference input is adjacent to the chosen badge.

Fix: establish an input-device-aware activation policy and collision-aware placement that keeps the edited shape visible. Acceptance: small and large geometry near every screen edge, both orientations, keyboard dismissal and tool switching. Automatic input behavior should be validated on physical iPad before declaring universal reference behavior.

Evidence: live-shapr-center.png, live-shapr-center-edit.png, live-sim-center.png, live-sim-diagonal-edit.png.

### P2 — Three-point rectangle completion exposes only the baseline dimension (SK-03)

Both apps construct a rotated rectangle using a baseline drag followed by a perpendicular-height drag. Shapr3D exposes both side dimensions after completion. Clone selects the baseline and opens only its length input; an equivalent height readout is not visible.

Fix: expose baseline and perpendicular height in the completed construction flow, with independent editable targets and anchor preservation.

Evidence: live-shapr-three-baseline.png, live-shapr-three-complete.png, live-sim-three-baseline.png, live-sim-three-complete.png.

## Behaviors that matched in the tested cases

- Center rectangle width edit preserves the center: Shapr3D center x≈901.5 before/after 480→200 mm; clone center x≈342 before/after 3→1.5 mm. This corrects the earlier unverified concern for this one-axis case; two-axis and other-direction coverage remains open. Evidence: live-shapr-center.png, live-shapr-center-sized.png, live-sim-center.png, live-sim-center-sized.png.
- Starting a circle at an existing rectangle corner creates a circle without moving the rectangle in both apps. Persistent coincidence/associativity was not tested. Evidence: live-shapr-circle-corner.png, live-sim-circle-corner.png.
- Three-point baseline-plus-height construction completes in both apps. This is construction parity, not full editing parity.
- Exiting sketch mode hides dimensions in both apps. Profile/grid styling differs; extrusion routing was not exercised in this pass. Evidence: live-shapr-exit.png, live-sim-exit.png.

## Open investigations — not signed off

Shapr3D Cmd-Z removes the whole three-point rectangle and Cmd-Shift-Z restores it. Clone toolbar Undo clicks did not visibly remove the rectangle, including after closing numeric input and exiting sketch. The final click receipt resolves to the expected simulator window and toolbar coordinate, but an independent input route is still needed to distinguish app behavior from simulator/automation delivery. Do not claim clone live atomic undo passed or diagnose a keypad-specific defect from these attempts. Existing automated undo tests are separate regression evidence.

Click-click line placement was not reliably established; no unsupported-gesture claim is made. Remaining paired recipes: half-finished cancellation, selection midpoint/endpoint and additive selection, constraint actions, dimension reopen, zoom/hit-target matrix, profile interior extrusion, physical Pencil/mouse parity, persistence, and all rectangle directions/two-axis entry.

## Evidence and follow-through

App-specific PNG screenshots and corresponding Peekaboo snapshot JSON are retained in the sibling evidence directory. No whole-desktop screenshots are included. No application source was changed in this comparison pass. Next implementation priority is the confirmed diagonal-anchor bug, followed by sketch-entry camera and post-draw annotations. Automated clone tests do not substitute for repeating these reference comparisons after each fix.

Local evidence archive: `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/evidence/`.
