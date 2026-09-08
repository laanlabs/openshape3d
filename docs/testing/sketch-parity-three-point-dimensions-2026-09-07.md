# Three-point rectangle readouts — September 7, 2026

Changes after `5fd1240` on PR29. Dual readouts and selected three-point height anchoring live-verified; history and baseline-edit parity remain open.

## Paired reference evidence

Native Shapr3D: first drag establishes oblique baseline; second drag completes rectangle. Both baseline308.0584mm and height167.1761mm remain visible without automatic keypad. Explicit height badge opens keypad; entering100 changes height. In this sample original baseline moved and opposite edge stayed fixed; do not assert that native typed three-point height always pins its original baseline. Other settings/anchor rules need further comparison.

Clone5fd1240: two drags complete four-line constrained rectangle; baseline keypad opens automatically, height badge is absent. Captured paired PNG/JSON in `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/three-point-2212/`.

## Implementation under test

Select all four completed sides, no automatic keypad. Recognize a closed rectangular four-line selection, including reordered/reversed endpoints, and expose two adjacent line-length candidates. Retain the rectangular selection when opening either badge, so the second remains reachable after commit. No new storage representation; ordinary constraints and driving dimensions remain responsible for geometry. This does not introduce or claim a new three-point anchor rule.

Serial regression passed: `/tmp/os3d-three-point-dimensions-20260907.xcresult`, log same prefix. Includes rectangle construction, rectangle UI and dimension UI; added shuffled/reversed/reloaded recognition and nonrectangle rejection, height editing with both badges retained and undo/redo. One clean run: 22/22 passed (12 construction unit + 10 rectangle/dimension UI). Additional TwoShapeReproUITests run now active at `/tmp/os3d-three-point-switch-20260907.xcresult`; fixtures explicitly open rectangle badges before testing pending-editor dismissal. Desktop interactions paused during UI tests. Google Docs publication pending this feature.

## Live post-fix recheck (22:24–22:29 EDT)

Completed oblique rectangle shows baseline3.041mm and height1.069mm, no auto-keypad. Explicit height opens fully reachable keypad near bottom/right. Correctly targeted first0 replaces seed; subsequent decimal and5 give0.5; commit retains both badges and height0.5. Baseline changes to3.064mm and geometry translates/rotates slightly: undriven-axis preservation remains unresolved, not signed off. Initial manual attempt used the sign-key coordinate instead of zero and produced a validation alert; discarded as input error. Screenshots/JSON copied to the same evidence directory (`three-fixed-*`, `three-height-*`).

Repeated live toolbar Undo clicks, with/without auto-focus, did not visibly restore geometry; no product diagnosis yet. Existing UI assertion only checked two badges after Undo, insufficient to prove restoration. Strengthened it to reject the edited1mm readout after Undo; targeted run `/tmp/os3d-three-point-undo-20260907.xcresult` active. No Peekaboo during this run. TwoShapeReproUITests passed2/2 in a clean serial run. Publication pending these new findings.

## Confirmed anchor gap and focused correction

Native isolated sample (away from existing profiles) baseline276.5863mm / height135.5815mm, then typed50mm: far baseline endpoints remained at approximately(664,313),(833,351); original baseline moved parallel toward it. Native Cmd-Z restored original height; Cmd-Shift-Z restored50mm, captured PNG/JSON `native-isolated-*`. This confirms height sizing should not drift the undriven side length/direction for this workflow.

New transient height preference fixes the far baseline during the solve for recognized selected three-point rectangles. It is not stored as a Lock. Explicit constraints take priority: failed preferred solve falls back to ordinary solving. Baseline editing remains unchanged pending its own comparison. Focused run `/tmp/os3d-three-point-anchor-20260907.xcresult` passed14/14 (13 geometry +1 height/undo/redo UI) in one clean run. Post-anchor-fix live comparison pending. Strengthened pre-anchor undo run also passed1/1; live toolbar discrepancy remains open.

## Post-anchor live verification (22:38 EDT)

Repeated same clone lower-right workflow: baseline3.041/height1.069mm → height0.5mm. Baseline remains3.041mm, far-edge endpoints remain at window coordinates(206,784),(449,825), original baseline moves parallel toward it. Both badges remain visible. This matches the isolated native height workflow. `anchor-live-complete.png`, `anchor-live-entry05.png`, `anchor-live-committed05.png` and JSON retained locally. Live Undo remains unresolved: window-relative, global foreground and longer-press inputs did not change visible geometry; automated stronger Undo/Redo passes. Do not classify the entire history workflow as live-verified.

Illustrated Doc interim exported and verified28inline images plus follow-up text; `published-threepoint-interim.docx`. Corrected result publication follows. Baseline edit and all-signed-angle/reselected-height lifecycle still require live comparison.

Final illustrated export verified29inline images and corrected-outcome section; `published-threepoint-final.docx` and `publication.json`. Simulator executable SHA256 `990cc2dd9b4dbd1a1935412e5bd31ee02c3f963e5b94d9188162adba10501ef8`. Not a physical-iPad build.

## Reselected baseline follow-up (22:49 EDT, after06af705)

Coordinate-targeted Undo diagnostic passed1/1 at `/tmp/os3d-toolbar-undo-diagnosis-20260907.xcresult`; AX Undo frame(347,36,39.5,36) in1032×1376 window maps to the same live icon center(253,118). Temporary diagnostic removed. Additional global synthOnly/window-ID live attempts still showed no change; no undo product change justified. Master roadmap06af705 update exported and verified in `master-roadmap-published.txt`.

Paired baseline reselect: native276.5863→140mm after height50 keeps left endpoints(671,283),(664,313) and orientation. Clone selected baseline2.062→1mm on reloaded height1 rectangle rotates to almost horizontal, left side translates. Captures `native-baseline-*`, `clone-baseline-*` confirm gap. New component recovery finds exactly4connected rectangular lines from a single edge, rejects branches/larger components, and retains document order. Baseline prefers left edge; height prefers far baseline even after single-edge reselection. Existing constraints still override. Under test; not live signed off. Serial `/tmp/os3d-three-point-reselection-20260907.xcresult` running, geometry+rectangleUI.

Reselection regression finished22:53 EDT:21/21 passed (14geometry+7rectangleUI), one clean run. Only subsequent source edit is a solver comment clarifying baseline/height scope; no behavior change. Live repeat underway.

## Reselection live sign-off (23:03 EDT)

Fresh clone baseline3.041→1.5 keeps left endpoints(221,698),(206,784) and direction, matching native276.5863→140. Clear selection/reselect right edge height1.069→0.5 keeps far baseline endpoints(206,784),(326,804); baseline reselect still1.5mm. Back to gallery/reopen: both1.5 and0.5 readouts retained. Native home/recents/reopen and double-click sketch retained140/50mm. Captures `reselect-*`, `native-reopen-*`. Native prompted upgrade on reopen; dismissed via Skip & Use Limited Version, no purchase/trial started.

Illustrated Doc exported with33inline images and corrected baseline/sequence prose (`published-reselection-final.docx`). Reopen evidence retained locally; publication of final reopen note pending. Current simulator executable SHA25670781f75b6bd975f604b9a5fb847a8cef48f4a8a3ffe26f26c0062359c162810. Not physical-iPad build. Next: gallery-reopened Undo diagnostic, then core plane/line/cancel matrix. Live Undo still unverified; no source change for it.
