# Physical iPad A/B checklist — candidate preparation

**Not released to device testing yet.** Candidate revision/archive, signing,
minimum OS and artifact checksum must be filled from the final build receipt.
The September3 archive in APP_STORE_READINESS is historical, not this candidate.
No physical installation or Pencil result is implied by simulator evidence.

Use a disposable design in each app. Match units, plane and acquisition/automatic
constraint settings; compare behavior rather than screen pixels across zoom levels.
For each step record pass/fail, app/build, finger versus Pencil, and before/after
screenshots. Keep the original design when a result differs.

1. Enter Top, Front and Right sketches. Confirm grid/axes, readable controls and
   return to the gallery. Cancel an empty sketch and check no unwanted item remains.
2. Draw a line with Pencil, then a tap-chain. Finish and cancel a continuation;
   committed segments must remain. Repeat with finger and with hardware Escape
   if available; Pencil hover must be tested on supported hardware separately.
3. Draw diagonal rectangles in both drag directions and a center rectangle.
   Type width then height, reverse that order, and watch the anchor/center.
4. Draw a rotated three-point rectangle. Edit each side immediately and after
   reselecting it. Check direction, undriven size and unrelated geometry.
5. Draw a circle from an existing point/center. Edit diameter; trim a span to an
   arc, edit radius and sweep90/270/360. Full360 should become a circle.
6. Test numeric first-digit replacement, decimal/operator entry, invalid zero,
   explicit cancellation and blank/tool-switch commit. Repeat near screen edges
   in both orientations; commit and delete keys must remain reachable.
7. Lock one endpoint of a horizontal line and drag the other diagonally. Motion
   should remain on the allowed axis; remove the lock and test free movement.
8. Compare acquisition off, Grid only and guidepoints. Near-equal lines should
   remain independent with Equal inference off. Verify saved settings after reopen.
9. Select points, edges and connected rectangles; clear and multi-select. Compare
   touch behavior directly, not native macOS mouse modifier assumptions.
10. Trim crossing lines and a rectangle side. Surviving geometry/dimensions must
    remain coherent; an open profile must not offer a closed-profile extrusion.
11. Undo/Redo creation, dimensions and trim; inspect geometry, not only selection.
    Repeat after waiting for autosave. Save, gallery-reopen and cold-launch again;
    verify sizes, constraints and profile availability.
12. Extrude an intact closed profile, cancel a second preview, save/reopen the
    resulting solid. Check rendering, selection and responsiveness on the device.

## Known differences / unresolved before candidate

- Arc sweep now uses a curved leader (1f211e5); small-label overlap and broader
  angle/orientation coverage remain open, not the obsolete dashed-chord gap.
- Arc endpoint welding/reference matrix and broader core acceptance remain open.
- Some native mouse selection behavior differs from simulated touch; physical
  touch/Pencil must decide that comparison.
- Line Escape now passes paired live two-stage cancellation; other cancel states open.
- Earlier live history no-response cause unknown; later paired creation/dimension
  repeats succeeded without history-code changes. Retest on the physical device.
- Both Google Docs are blocked in Saving: illustrated76 verified images,
  master36 verified images with unsynced insertions preserved. New evidence is
  indexed locally; publication and final-revision regression remain pending.
- Four-line rectangle white normal controls, saved-lock refusal and history
  passed paired live checks (378715b). Axis-aligned edge controls are under
  regression; per-edge constraint semantics and driven translation need care.
- Circle/arc contextual radial controls are implemented and live-compared;
  broader control/label/glyph and non-line constrained-transform coverage remains.

A readiness notice requires an identified installable artifact and the remaining
core gate; this checklist alone is not that notice.
