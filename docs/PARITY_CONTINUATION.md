# Parity continuation checkpoint

Updated September 7, 2026, 22:10 EDT during dedicated active work.

## Revision and execution

- Branch `fix/sketch-parity-foundations`, draft PR https://github.com/laanlabs/openshape3d/pull/29; changes based on `5689ce6`, being committed with this checkpoint. Inspect actual HEAD/status on continuation.
- Dedicated session owns desktop exclusively. No xcodebuild/UI-test process currently running; all diagnostic runs completed. Active interactive Peekaboo/documentation work, not a separate background worker. Check processes before resuming.
- Source changes: EditorViewModel.swift, NumericKeypad.swift, SketchDimensionOverlay.swift. Test change: RectangleWorkflowUITests.swift. Receipt: `docs/testing/sketch-parity-live-recheck-2026-09-07.md`. No original-checkout edits, no merge.

## Verified results

- Paired horizontal completed-line readout persists without auto-keypad; explicit badge opens pad in both apps.
- Paired down/right diagonal half-width keeps first corner (native350→175mm; clone3→1.5mm).
- Corrected axis-aligned rectangle release keeps both badges without automatic keypad. First numeric digit replaces seed; subsequent digits append. Full measured editor is kept clear of palette/rail.
- Fresh clone center2×1→2×0.5→1×0.5mm preserves center, right-side keypad fully usable. Native180×100→180×50→90×50mm preserves center; native needed reselection/tool interaction to recover width after height commit. Not identical command lifecycle.
- Installed/final simulator executable SHA256 `9f07455e7d9a91fee48acec6302fc09c1b84eb680fb3c77467cd5509e906fa45`; build at `/tmp/os3d-parity-derived/Build/Products/Debug-iphonesimulator/openshape3d.app`. Simulator build, NOT an iPad installable candidate.
- Tests: initial compile failure corrected. Combined v2 18/20 passed; two rectangle inferred-tap failures repeated in diagnostic attempts. Live center and padded-edge taps worked. Ineffective hit-shape changes removed. Explicit-center targeted rerun passed2/2 at22:00 (`/tmp/os3d-keypad-center-target-20260907.xcresult`). Thus20 distinct passing checks across runs, NOT a single clean combined run.
- Evidence: `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/recheck-2133/` PNG/JSON, exported DOCX and publication.json. Existing illustrated Google Doc updated with interim and post-fix findings: https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit . Check latest publication receipt for verified image count.

## Exact next action

Finish verifying post-fix Doc image export / commit and push reviewable correction; then directly operate native three-point rectangle baseline+height and clone equivalent. Compare completed readouts, explicit height access, auto-keypad and one-step undo; capture before implementation. Native currently center tool/subtype flyout in existing test sketch; clone existing test sketch with new center1×0.5mm near upper-right.

## Remaining queue and limits

1. Three-point height access/auto-keypad, typed placement; diagonal sequential height/all quadrants.
2. Live undo/redo, tap placement/cancel, selection, constraints, snapping, persistence and exit/reentry core matrix.
3. Compact, landscape, left-handed and system-keyboard editor placement remain unverified. Padded hit-target matrix remains open despite successful live sample.
4. Update master audit crosslinks/status and preserve screenshot-backed existing Docs.
5. Identified installable physical-iPad build, short A/B checklist, known differences; readiness not reached. Pencil/touch cannot be verified in simulator.

No external blocker. Do not stop at this completed correction. Existing watchdog `3eced82f-bc37-4bcf-9f42-518d25e7558c` every30minutes, no duplicate jobs/workers. No restart/logout/lock/Screen Sharing changes or secrets. Peekaboo GUI bridge path `/Users/thelodgestudio/Library/Application Support/Peekaboo/bridge.sock`; switch target app explicitly and use foreground delivery. `--no-auto-focus` avoids repeated focus delay after a verified switch; inspect screenshots after actions and camera settling.
