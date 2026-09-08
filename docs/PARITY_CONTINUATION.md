# Parity continuation checkpoint

Updated September7,2026,23:03 EDT during dedicated active work.

## Revision / execution ownership

Branch `fix/sketch-parity-foundations`, PR https://github.com/laanlabs/openshape3d/pull/29. HEAD06af705 pushed; baseline/reselection correction dirty in EditorViewModel.swift, RectangleConstruction.swift, RectangleConstructionTests.swift, receipt/checkpoint. Inspect actual HEAD/status. This dedicated session owns desktop; No xcodebuild running; reselection run21/21 passed. Dedicated session owns serial Peekaboo. No duplicate workers. Simulator os3d-parity-sept7, UDID AC2FD923-1661-435F-BF47-3E9DF30D1A16. Latest installed simulator executable SHA256990cc2dd9b4dbd1a1935412e5bd31ee02c3f963e5b94d9188162adba10501ef8, app `/tmp/os3d-parity-derived/Build/Products/Debug-iphonesimulator/openshape3d.app`.

Changed files: EditorViewModel.swift, RectangleConstruction.swift, SketchSolverBridge.swift; RectangleConstructionTests.swift, RectangleWorkflowUITests.swift, TwoShapeReproUITests.swift; ledger, this checkpoint, three-point receipt. No merge. Simulator build is NOT a physical-iPad candidate.

## Verified

Previous5fd1240: paired completed horizontal-line badge/keypad, down-right diagonal half-width first-corner, center sequential two-axis center preservation; first digit replaces seed; measured keypad clear of rail. Prior20distinct passing checks across failing/targeted reruns, not one clean20. Receipt `docs/testing/sketch-parity-live-recheck-2026-09-07.md`.

New three-point work: completion leaves baseline/height badges, no automatic keypad; explicit height retains both. Live initial height1.069→0.5 changed baseline3.041→3.064; isolated native135.5815→50 preserved far baseline. Corrected transient far-edge preference now clone1.069→0.5 with baseline3.041 unchanged, endpoints(206,784),(449,825) fixed. Explicit constraints override preference; no extra persisted Lock. Baseline editing unchanged, not signed off.

Tests: initial clean22/22 (12geometry+10UI), tool-switch2/2, stronger undo1/1, final anchor-focused14/14 (13geometry+1UI), all clean individual runs. Stronger undo requires removal of edited1mm after Undo, then restoration after Redo. No full latest all-suite claim.

Evidence folder `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/three-point-2212/`, native-isolated / anchor-live PNG+JSON, exported DOCX, publication.json. Illustrated Doc now33images verified; https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit verified29inline images + corrected section. Master roadmap06af705 summary exported and verified. Local receipt `docs/testing/sketch-parity-three-point-dimensions-2026-09-07.md`.

## Exact next action / unresolved issue

Reselection correction live verified and being committed; inspect actual git state. Next run gallery-reopened Undo test, since previous passing tests enter newly created projects. Native reselected baseline276.5863→140 keeps left side; clone2.062→1 rotates and translates. Component recovery from single edge and preferred left-side baseline correction dirty. Live repeat after run.06af705 pushed. Continue live clone toolbar Undo discrepancy: repeated window-relative/global foreground clicks at undo icon, with/without auto-focus and long press, produced no visible restoration, even after exiting sketch; automated stronger Undo passes. Do not claim live history parity. Native Cmd-Z/Cmd-Shift-Z visually restores/reapplies height. Need distinguish simulator delivery/toolbar hit-testing from product logic before fixing. Current clone selected lower three-point rectangle height0.5; native isolated center-upper rectangle height50 after Redo.

Then paired baseline edit and reselection, remaining diagonal sequential height/all quadrants; live cancellation, selection/constraints/snapping, persistence/exit-reentry. Compact, landscape, left-handed/system-keyboard and physical Pencil remain open. Prepare identified installable iPad build/checklist only after readiness criteria; not reached.

No external blocker. Continue concrete work; not a batch-only stop. Existing watchdog3eced82f-bc37-4bcf-9f42-518d25e7558c every30min, no duplicate jobs. No restart/logout/lock/Screen Sharing changes, no secrets. Peekaboo bridge `/Users/thelodgestudio/Library/Application Support/Peekaboo/bridge.sock`; one owner, no desktop actions during UI tests. Screenshots of app alone do not prove foreground delivery; inspect full screen for routing concerns.

Undo coordinate diagnostic passed1/1 with frame matching live icon; temporary test removed. Native/clone baseline comparison captures retained in three-point-2212. No undo source change justified.

Reselection baseline3.041→1.5 and height1.069→0.5 verified fixed adjacent side/direction; clone gallery reopen1.5/0.5, native140/50 retained. Latest executable SHA25670781f75b6bd975f604b9a5fb847a8cef48f4a8a3ffe26f26c0062359c162810. No tests currently running. Native open sketch selected140/50 rectangle; clone open sketch selected0.5-height.
