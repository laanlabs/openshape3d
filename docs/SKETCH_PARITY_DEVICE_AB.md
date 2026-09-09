# Physical iPad A/B checklist — preparation, not a release candidate

Prepared September 9, 2026. **Not ready for device testing yet.** Core visual and
interaction acceptance remains open in [the full matrix](SKETCH_PARITY_ACCEPTANCE_MATRIX.md).
Do not infer physical Pencil results from mouse-operated simulator captures.

## Artifact gate

| Field | Verified state |
|---|---|
| Source | PR #29, `fix/sketch-parity-foundations`; final candidate revision pending |
| Bundle | `com.laan.labs.openshape3d` in project configuration |
| Version | Project configuration 1.0 (1); final artifact version pending |
| Platform | App target includes iPhone/iPad, minimum iOS 17.0; configuration only |
| Signing | Automatic signing configured; valid device provisioning not yet verified |
| Device artifact | Not produced or verified; simulator `.app` is not installable on iPad |
| Artifact hash / receipt | Pending final single-revision build and inspection |
| Installation | Not performed or implied |

Before release: identify the final revision, pass relevant serial regressions,
close blocking paired UI gaps, build an actual device artifact, inspect its
platform/signature/provisioning and record its path and hash. Any device or
account setup must use normal host-owned UI; never collect credentials in chat.

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
