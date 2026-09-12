# Physical iPad A/B checklist — provisioned-device candidate handoff

Prepared September 9, 2026. Revision `05be744` is the identified core-sketch
comparison candidate for a provisioned physical iPad. It is not a release build
or a full-parity claim. Core visual and interaction coverage remains partial in
[the full matrix](SKETCH_PARITY_ACCEPTANCE_MATRIX.md), and no physical install,
touch or Pencil result may be inferred from mouse-operated simulator captures.

## Artifact gate

| Field | Verified state |
|---|---|
| Source | PR #29, `fix/sketch-parity-foundations`, revision `05be744` |
| Bundle | `com.laan.labs.openshape3d` |
| Version | 1.0 (1) |
| Platform | `iPhoneOS`, arm64, minimum iOS 17.0 |
| Signing | Apple Development, team `34FWY7G2HB`; archive signature and Designated Requirement verified |
| Provisioning | Existing team profile, 81 device entries, expires 2027-07-21; the target iPad must already be included |
| Device artifact | `OpenShape3D-SketchParity-05be744.ipa`, 16,876,597 bytes |
| SHA-256 | `b0f512efc9a22ed5f23dcefe3567f2dfe727e6ed1821fd782fa10d212ba6d65c` |
| Durable copy | `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/final-gate/OpenShape3D-SketchParity-05be744.ipa` |
| Build receipt | Adjacent `device-artifact-05be744.txt`; archive/export logs retained under `/tmp` |
| Installation | Not performed or implied |

The exact source revision passed the final serial regression: 1,598 total,
1,595 passed, zero failed and three skipped. Before testing, confirm the target
iPad is in the recorded profile and install through the normal host-owned Xcode
or device-management flow. Any device or account setup must use normal host-owned
UI; never collect credentials in chat.

## Set up a comparable pair

Record iPad model/OS, Pencil model, app versions, handedness, orientation, units,
snap settings and Auto-Constrain. Use separate disposable designs in both apps.
Match screen scale approximately; compare dimension values and anchors, not raw
pixel distances. Capture failures before changing settings or geometry.

## Short test sequence

1. **Plane and input:** enter an empty Front sketch, then Top. Confirm grid and
   axes, Pencil start location, finger navigation and no accidental geometry.
2. **Line:** draw a three-segment chain, intentionally close another profile,
   finish an open chain and cancel a pending segment. Check retained committed
   segments and explicit length entry. Sample start snapping near/far from an endpoint.
3. **Circle/arc:** draw on an existing center; edit diameter/radius and arc sweep.
   Check center/geometry preservation, readable leaders, radial control and
   refusal when a saved driving size prevents resizing.
4. **Rectangles:** diagonal, center and three-point. Enter width then height,
   repeat reverse drag, and verify the recorded anchor policy. Check all keypad
   controls near both canvas edges in portrait and landscape.
5. **Selection/constraints:** tap edge, endpoint and blank canvas; lock one
   endpoint/rectangle side, drag a free direction, then Unlock. Confirm only the
   intended geometry changes and unavailable actions do not masquerade as success.
6. **Move/Rotate/Copy:** use white controls, enter an exact axis value, rotate then
   move on the rotated axis, re-edit the value and Copy. Check dimensions remain
   correct, free readouts do not obscure controls, and Undo/Redo restore geometry.
7. **Cancellation/history:** cancel an uncommitted numeric value, exit the tool,
   Undo/Redo after autosave and after opening a saved design. If a hardware keyboard
   is attached, check keypad-first Escape separately from Pencil/touch controls.
8. **Persistence/profile:** save and reopen. Verify typed sizes/constraints and
   separate sketch identity. Extrude one closed profile; an open profile must not
   offer the same closed-region result. Reopen again and inspect sketch and solid.

For each step record native result, clone result, screenshot/video reference and
pass/fail/blocked. Any missed Pencil input, crash, lost geometry, wrong anchor or
unreachable control is a failure, not a simulator-equivalent pass. Return results
to the existing audit; this short checklist does not replace its 56 scenarios.
