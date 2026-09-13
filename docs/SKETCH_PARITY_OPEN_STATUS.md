# OpenShape3D — unfinished-work status

Last reconciled: **2026-09-13, 16:30 EDT QA-29 badge-layout checkpoint**. Source checkpoint: **273f0c4** (badge/keypad clear of side controls; d2ff046 exec ceiling). Source checkpoint: **d2ff046** (exec side-count ceiling). Source checkpoint: **0cb0a2a** (compact palette reachability; d790646 Move/Rotate for any selection; 6ac3250 Space; dcee869 named views; 3f7080c curved face). Source checkpoint: **3f7080c** (curved face refused by the plane picker; cf0fbd0 row highlight/readout; cf3b875 plane selection); prior **605511b**, fixture **0e86c6b**.
Owner: **Claude Code session** (handed over 2026-09-13). OpenClaw parity work is **paused** by Jason — automation `3eced82f` disabled, dashboard parity session idle; see AGENTS.md. This is the current open-work register, not the historical mission log.

**33 passed / 0 failed / 22 incomplete / 1 device-blocked = 56 acceptance cases.**
The 22 incomplete cases comprise 11 partial core cases and 11 explicitly deferred cases.
A passed finite recipe is not full feature parity. Automated passes do not replace paired live checks or physical-device proof.

## Current work — not yet complete

- **QA-24 Items selection:** 0cc5d6c final52/52 and paired owned-selection/Exit/Rename/history/reopen are published.
- **QA-24 model-mode summary:** source605511b plus fixture0e86c6b final47/47; fresh native and changed clone count/length/blank comparisons, clone history/reopen verified. Ten assets published; source and tests pushed.
- **Next core:** QA-01 plane-picker miss/face recipe. Native model-mode 3D sketch Move/Rotate diagnostic remains open:5000 submission accepted, clone Move no-op, ownership/downstream semantics unverified; local evidence queued for publication. Clone summary now works, but gizmo and 3D transform dispatch remain absent. Curved-face/edge overlap and remaining item classes remain open.
- **Actual owner:** Claude Code session; no test runner active; OpenClaw paused. Native500mm and clone0.5mm planes and offset-line creation/history/reopen verified. Serial PlaneTests + four PlanesUITests gate collected: **11/11 passed, 0 skipped, one clean run** at 0e86c6b source (`/tmp/os3d-qa01-plane-gate-20260913.xcresult`). Plane Items click fixed at **cf3b875** (`selectItemPlane`: highlight, Sketch-on-plane, Delete, yields to other selection/tap/undo); regression 24/24, one clean serial run (`/tmp/os3d-plane-select-gate-20260913.xcresult`). Paired live check done 09:10 EDT (native Plane 01 row → Sketch enters Sketch 13 on the plane; clone Plane 1 row → Line enters Sketch 1 on the y=6 offset plane, no picker; ten assets, local only — see testing/sketch-parity-plane-item-selection-2026-09-13.md). Row highlight + "1 plane" readout gap closed at **cf0fbd0** (25/25, one clean serial run; paired re-run 09:28 EDT, 18 assets local). Remaining difference: native one-sketch-per-plane vs clone new sketch (coplanar-identity lane). Curved-face pick refused at **3f7080c** (picker stays armed; 25/25 one clean serial run; clone live wall/cap/miss on the build, 11 assets local — see testing/sketch-parity-plane-picker-curved-miss-2026-09-13.md). **Native curved-face and planar-face picks not observed live this session** (audit doc shows only boxes); miss paired Sept 12. Published in the Evidence Appendix (QA-01 docs 1–2); the twelve Sept 12 offset assets remain unpublished.
- **Reports:** illustrated1,302 unique media/1,305 placements; ten new hashes once, no predecessor loss. Master38, one new note/no loss. **2026-09-13 session evidence published as a separate Evidence Appendix** (five Google Docs, 70 captioned images with per-original SHA-256, plus an index: https://docs.google.com/document/d/1OMSu149SkUIDJLCFyifQtRQ9_A40e9zonxq57qh1TJw/edit); the appendix is not inserted into the illustrated report (that document is owned by another account and the connector cannot edit it) — link it from the roadmap doc manually. Still unpublished: the twelve Sept 12 offset-plane assets (qa01-offset-live-2026-09-12).

## Every unfinished original acceptance case

Each entry preserves the matrix's current evidence and remaining scope. Deferred means unfinished, not passed or silently removed. Owner is the dedicated parity session unless stated otherwise.

### QA-01 — Plane selection

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Origin Front/Right/Top grid availability paired. Face-offset creation, offset sketch entry, line history and both reopenings paired at differing scales; plane regression 11/11 passed (0e86c6b), publication pending. Plane Items selection implemented at cf3b875 (regression 24/24; paired live 2026-09-13) and its row highlight/"1 plane" readout at cf0fbd0 (25/25; paired re-run); curved face refused at 3f7080c (clone live; native response not observed), bare-grid miss paired Sept 12 (ground; one-sketch-per-plane difference). Open before promotion: native curved/planar-face pick observation in one session, and publication.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-02 — Entry method

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** 2026-09-13: Sketch menu → plane paired (QA-01 lanes); selected face → Sketch paired (native face click then Sketch entered directly, no plane prompt; clone PlanesUITests + live cap); existing item paired/published under QA-24/41; hover + Space native-observed (grid and face) and implemented at 6ac3250 (81/81) — live clone delivery blocked: the simulator produces no pointer hover from synthetic moves (QA-21 limitation; physical device QA-52). See testing/sketch-parity-entry-routes-2026-09-13.md.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-03 — Camera angle

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Origin Front/Right/Top normal entry/grid checked. 2026-09-13 paired: entry alignment (both align to the plane normal), orbit while sketching by view command (clone Look at Sketch / native Normal to Sketch, sketch stays active), normal-view action realigns. Clone-only: edge-on 90° places nothing (implicit; `grazingSketchAngle` unused). Confirmed 11:05 EDT over seven isolated trials: a native named view that is not the sketch's head-on view or its underside (Front, Right, Default View) ends the sketch; Top/Bottom and any Rotate View keep it. Clone matched at **dcee869** (`applyStandardView` ends the sketch unless the view is head-on/underside; 38/38 one clean serial run; live re-check Top/Bottom keep, Front/Isometric end). Open: orientation-cube taps do not route through it and native's cube-tap response is unobserved. 85° unreachable by command; gesture orbit not driven (QA-52). Regression: PlanesUITests.testStandardViewWhileSketchingOffersLookAtSketch (Views > Isometric mid-sketch offers Look at Sketch, sketch stays active, tap realigns), PlaneTests + PlanesUITests 13/13 one clean serial run. See testing/sketch-parity-camera-angle-2026-09-13.md.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-14 — Ellipse dimensions

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Advanced ellipse-axis coverage; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-16 — Spline

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Spline creation/editing; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-17 — Text sketch

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Text sketch; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-19 — Snap categories

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Raw acquisition-off and Grid-only paired; guidepoint combinations open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-20 — Snap zoom

- **Status:** Core — partial.
- **Evidence / remaining work:** Screen-relative acquisition corrected; native near/far reference + two clone scales, clean37/37. Full zoom/grid matrix open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-21 — Snap feedback

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Native Endpoint hover captured; clone idle feedback automated-only, live pointer delivery unresolved.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-22 — 3D references

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Off-plane reference coverage; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-24 — Multi-selection

- **Status:** Core — partial, not passed.
- **Latest:** owned Items selection/history and model-mode count/length now paired and published at1302unique1305placements/master38. Full model-mode 3D transform dispatch/gizmo remains open.
- **Evidence / remaining work:** Typed planar-face/body/profile chooser on ab6fb2d passed 26/26; changed live face/profile dispatch, Cancel and gallery recovery of three boxes plus circle verified. Body-name/Rename correction b5bff74 final46/46 plus paired history/reopen; illustrated1271unique/1274placements/master38 verified. Connected rectangle and later constraint additive routes retained; native Profile identity confirmed by accessibility selection; broader curved-face/edge selection remains open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-28 — Dimension selection matrix

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Non-core multi-entity dimension coverage; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-29 — Badge layout

- **Status:** Core — partial live pass.
- **Evidence / remaining work:** Portrait and landscape edge keypad usable; resize alignment fixed. 2026-09-13 at 273f0c4: right-palette badge-under-palette fixed (linear badges clamp between rail and palette) and compact keypad overlap fixed (size-class rail inset); regression on both (iPad forced-right test; compact suite 4/4). Open: dense values, manual reposition, camera zoom, and three pre-existing DimensionUITests failures (below). See testing/sketch-parity-badge-layout-2026-09-13.md.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-31 — Unit conversion

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Comprehensive unit formats; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-32 — Expression evaluation

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Comprehensive variables/expression semantics; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-40 — Keypad transitions

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Retained click-away/tool/toggle/Exit/Escape/history evidence plus paired blocked/unblocked cube drag on5676bd0 with final57/57 and illustrated1237/master38. Native pan: seven input classes tried 2026-09-13 (plain/⇧/⌘/⌥ drags, wheel and trackpad-style scrolls, arrows) — none pans through Peekaboo (⌘+arrow rotates 15°); Shapr3D pans on the middle button / two-finger gesture, neither postable here — moved to QA-52 with the inventory. Clone rule inventory recorded (cube blocked, tap = click-away, one-finger drag and two-finger pan not gated; native unobserved). See testing/sketch-parity-keypad-pan-2026-09-13.md.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-42 — Trim curves

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Ellipse/spline trim; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-44 — Offset

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Offset completeness; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-45 — Move/rotate/copy

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Extensive paired exact-value/local-frame/Copy/Escape/history evidence plus clean 50/50 current-tree direct line/circle/rectangle and mixed line+circle Copy matrix. 2026-09-13: mixed selection had no exact-value route in the clone (drag gizmo only) — fixed at d790646 (Move/Rotate pill for any selection; 84/84 one clean serial run), typed X on line+circle verified live with Undo/Redo; native mixed selection still supported-input blocked (click replaces, shift-drag clears). Compact layout: transform-control check still open — the drawn line could not be selected at compact width in XCUITest (two routes, three runs; diagnose selection vs harness); see testing/sketch-parity-mixed-transform-2026-09-13.md.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-46 — Pattern

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Advanced linked patterns; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-47 — Projection

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Projection linking; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-52 — Touch and Pencil

- **Status:** Device-only pending.
- **Evidence / remaining work:** Physical Pencil/touch requires Jason’s actual device comparison; no simulator substitute.
- **Closure required:** Updated-build physical iPad/Pencil/touch comparison with recorded results; owner: parity session for build/install preparation, Jason for physical input verification.

### QA-53 — Layout

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** 2026-09-13 compact (iPhone 17 Pro): testExtrudeBarIsUsableAtCompactWidth failed on the branch — measured, the bar no longer covers the palette; nine entries (Axis and Material were added) exceed the ~487 pt available above the info strip + bar, so the palette scrolls and Delete sat below the clip edge. Fixed at 0cb0a2a: tighter column tried before scrolling, palette identifier on the scrolling variant, test requires Delete reachable directly or by one palette scroll; compact suite 3/3, iPad Planes + SketchTransform 10/10. See testing/sketch-parity-compact-palette-2026-09-13.md. Compact sketch Move/Rotate check still open. Panel/palette correction4b6a78f passed final50/50 and changed live both-panel/inward-flyout/plane-choice checks; illustrated1247/master38 published89dbafc. Retained51/51 layout baseline remains valid. Native Mac lacks the same handedness/large-text controls; physical iPad variants remain unverified.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

## Cross-cutting build, device, and handoff work

- [ ] Finish all remaining core acceptance and blocking visual/interaction differences, or record an explicit user-accepted scope exception. Do not drop deferred full-parity work.
- [ ] Reconcile current WIP and preserve all project changes in reviewable commits/pushes, with incomplete testing explicitly labeled. Exclude unrelated identity/memory files and secrets.
- [ ] Run and record final relevant **same-revision** regression for the refreshed candidate, including unresolved failures/skips. Old 05be744 results do not validate newer changes.
- [ ] Produce a new signed iPad archive/IPA including the newer fixes. Record source revision, size/hash, platform, signature and provisioning verification.
- [ ] Verify present device connection and eligibility at installation time. Jason previously reported the iPad connected, and prior read-only profile matching succeeded; neither proves a current connection or installation.
- [ ] Install and launch the updated build on the actual iPad through the supported device workflow; retain evidence. **Updated installation is not verified.**
- [ ] Refresh the short [device A/B checklist](SKETCH_PARITY_DEVICE_AB.md) against the new candidate and known differences.
- [ ] Complete physical Pencil, touch, gesture, hardware-keyboard, orientation/handedness/accessibility layout and lifecycle checks (QA-52). Simulator mouse/keyboard evidence is insufficient.
- [ ] Resolve device findings, repeat affected regression and refresh the artifact as necessary.
- [ ] Verify outstanding screenshot/report uploads by export, matching hashes and preserving predecessor text/media. Reconcile the historical publication queue rather than re-uploading already recovered evidence.
- [ ] Publish a final readiness summary identifying the exact tested build, completed scope, deferred scope, known limitations and device results. No full-parity/release claim from a comparison build.
- [ ] PR review/merge/release remains a separate disposition; do not merge or release merely because this checklist exists.

**Existing artifact:** immutable `05be744` development IPA is retained. It excludes the many subsequent fixes. Its historical 1,595-pass/3-skip regression and signing receipts are not current-build readiness evidence.

## Limitations excluded from finite passes — still tracked

These are not additional acceptance-count rows. They must not disappear because their related finite case is passed.

- QA-33: polygon side count is capped at 10,000 on both the keypad and exec paths while native has no cap (quadratic slowdown, 10,001 ≈ 22 min). **Accepted scope exception, Jason 2026-09-13.**
- QA-01: the clone keeps the picker armed after a refused curved-face tap by its own Section View rule; native's response to that tap is unobserved (audit document has no curved body in view).
- QA-02: hover + Space is unit-proven only — the simulator delivers no pointer hover from Peekaboo moves or "Send Pointer to Device"; live proof needs a physical trackpad/Pencil (QA-52). The native face selection in native-05 is inferred from the missing plane prompt, not a visible highlight.
- QA-03: 85° entry/orbit unreachable by command on either side (45°/isometric and 90° used); native edge-on drawing unobserved; gesture orbit not driven through Peekaboo (physical input stays QA-52).
- QA-27: variable-linked and multiple-driver dimension-type variants remain unverified (also related to QA-28/32).
- QA-43: legacy nil reference ownership retains old behavior; duplicate-label styling was excluded from closure.
- QA-49: exhaustive curved intersections/topology are outside the bounded pass (related QA-42).
- QA-50/56: advanced downstream Sweep/Loft breadth is outside the simple sketch-to-solid smoke closure.
- QA-54: synthetic XCTest Escape delivery has a retained limitation; physical hardware delivery remains QA-52, not proven by foreground desktop input.
- QA-41: the historical immediate-native-reopen discrepancy is distinct from the verified explicit Exit/save route.
- QA-10 legacy recovery: controlled production-import diagnostic/gallery validation did not establish the system-file-picker import route; retain that route as unverified until explicitly tested.
- Manual label placement outside the sampled head-on circle case, oblique placement, other dimension kinds and rapid successive-input variants require coverage in the remaining annotation/layout/dimension lanes.
- Full UI parity still requires the outstanding drawing/selected/unselected/editor states, leaders, handles, highlights, icons and keypad matrix; geometry-only passes do not close those visual requirements.
- Historical receipt caveats not yet independently reconciled stay **unverified**, not assumed fixed. The owning session must reconcile additional exclusions into this section when reading a receipt.

## Blockers and next actions

- **Device evidence:** build/install work is still outstanding; do not repeatedly attribute this solely to Jason. He already reported the iPad connected.
- **Simulator baseline:** the parity iPad's app-container plist persisted paletteOnRight=true and alwaysRadius (Sept 11 handedness runs) until 2026-09-13 16:00 — layout evidence captured before then shows the palette on the right for that reason; check the plist before trusting layout captures.
- **Input/capture:** several historical cases were blocked by supported input/capture delivery. GUI work has subsequently recovered in parts. Re-test each remaining route; do not propagate a global stale blocker or infer an app failure from tool delivery.
- **QA-33 polygon bound:** resolved 2026-09-13 — native has no limit and degrades quadratically (3,000 sides ≈ 2 min); the clone's 10,000 ceiling is a deliberate guard, accepted by Jason 2026-09-13 as a scope exception.
- **Publication:** Items selection batch is published and verified; model-mode summary correction is also paired and publication-verified. Older queue entries include recovered material and require reconciliation, not blind duplication.

## Update contract

Requested by Jason on September 12: keep a full unfinished-work list updated.

At **every meaningful checkpoint**, and before a checkpoint commit/push or handoff:

1. Reconcile this document with the acceptance matrix, latest continuation entry, current diff and new receipts.
2. Add each newly confirmed bug, incomplete test/live check, publication step and blocker immediately, including owner and next action.
3. Distinguish implementation, regression, paired live, publication and physical-device completion. Record source revision and exact final results; do not sum separate runs into one clean gate.
4. On closure, update the matrix and totals together; move the case out of the unfinished list only when its finite evidence is verified. Keep exclusions here or in their explicit open lane.
5. Update candidate/build/install status independently. Link receipts instead of copying the historical log into this current register.
6. Preserve a brief change log below. The dedicated parity session owns routine maintenance; parent status/heartbeat checks should consult this file and flag stale or inconsistent entries.

## Sources

- [All 56 acceptance cases](SKETCH_PARITY_ACCEPTANCE_MATRIX.md)
- [Latest operational checkpoint](PARITY_CONTINUATION.md)
- [Milestone requirements](SKETCH_PARITY_NEXT_MILESTONE.md)
- [Implementation ledger](SKETCH_PARITY_IMPLEMENTATION.md)
- [Device checklist and historical artifact](SKETCH_PARITY_DEVICE_AB.md)
- [Publication recovery queue](testing/sketch-parity-publication-pending-2026-09-10.md)
- [PR #29](https://github.com/laanlabs/openshape3d/pull/29)
- [QA-33 polygon-bound appendix, 2026-09-13](https://docs.google.com/document/d/1oplNFZXivCEu3pKEFR3VTM8vEvGUsDHTZjeVmMUYhzI/edit)
- [Evidence Appendix index, 2026-09-13](https://docs.google.com/document/d/1OMSu149SkUIDJLCFyifQtRQ9_A40e9zonxq57qh1TJw/edit)

## Change log

- 2026-09-13 (16:30): QA-29 right-palette badge and compact keypad overlaps fixed at 273f0c4 (iPad forced-right test green; compact suite 4/4). **Confirmed pre-existing bugs (not from today's changes; fail at 0e86c6b too):** DimensionUITests testLineDistanceTypeBadgeChangesReadoutWithoutOpeningKeypad, testNearRailCircleDiameterTargetRemainsReachable, testConnectedCircleGlyphDoesNotInterceptCenterDrag — tap-to-reselect after an edit / short centre drag; owner Claude Code session, next: reproduce tap-to-reselect live. Simulator carried a persisted paletteOnRight=true from Sept 11; cleared. 6 assets local.
- 2026-09-13 (15:45): **QA-33 promoted to passed** — finite recipe complete, native bound measured, 10,000-side ceiling accepted by Jason as a scope exception (kept in the excluded-limitations list), appendix doc published. Totals 33/0/22/1.
- 2026-09-13 (15:15): QA-40 pan-while-keypad: native pan not deliverable (seven input classes tried, inventory in the receipt) — moved to QA-52; clone rule inventory recorded; no source change.
- 2026-09-13 (15:00): QA-33 native side-count bound measured to completion (1,000/2,000/3,000 sides: ~10/47/119 s, no refusal, quadratic); clone ceiling kept and extended to the exec path (10,001 was accepted there). Divergence recorded for acceptance. 6 assets local.
- 2026-09-13 (14:00): Published the session's five evidence folders (70 images) as Google Docs via the user's Drive plus an index doc; receipts and evidence indexes carry the links. Roadmap doc not edited (other owner). Twelve Sept 12 offset assets still unpublished. No promotion.
- 2026-09-13 (13:30): QA-53 compact extrude-bar failure measured and resolved (palette scrolls; tighter column; test asserts reachability), compact suite 3/3; receipt added. No promotion.
- 2026-09-13 (13:10): QA-45 mixed selection had no exact-value route — fixed at d790646, 84/84, live typed move + Undo/Redo verified; native mixed selection input-blocked. Compact: extrude bar covers Delete on iPhone 17 Pro (confirmed, QA-53); sketch-transform compact check open. 11 assets local. No promotion.
- 2026-09-13 (12:15): QA-02 entry routes: Space = sketch on hovered plane implemented at 6ac3250 after native observation (grid and face); face → Sketch paired; menu and item routes cited. 81/81 one clean run. Live Space blocked by simulator hover delivery — recorded. 8 assets local. No promotion.
- 2026-09-13 (11:30): Native named-view rule confirmed over seven isolated trials (Front/Right/Default View end the sketch; Top/Bottom and Rotate View keep it) and matched in the clone at dcee869; 38/38 one clean serial run; clone live re-check on the build. 24 QA-03 assets local/unpublished. No promotion.
- 2026-09-13 (10:45): QA-03 camera angle paired by view command in both apps (entry alignment, orbit-while-active, normal-view action); edge-on clone-only; 13 assets local/unpublished. New Look-at-Sketch UI regression, 13/13 one clean serial run. No source change; no promotion. Difference to confirm: native View > Front ended the sketch (one observation).
- 2026-09-13 (10:00): Plane picker refuses curved faces at 3f7080c (was sketching on a facet sliver); 25/25 one clean serial run; clone live wall/cap/miss re-verified, 11 assets local. Native curved/planar-face pick not observed — recorded as open. QA-01 finite recipe now has evidence for every element; no promotion; totals unchanged.
- 2026-09-13 (09:30): Items plane row highlight + "1 plane" readout at cf0fbd0; 25/25 one clean serial run; paired re-run in both apps, 18 assets local/unpublished. Gap closed; no promotion; totals unchanged.
- 2026-09-13 (09:15): QA-01 plane-row selection → Sketch paired live in both apps; ten assets indexed locally, unpublished. New gap: clone has no Items row highlight or "1 plane" readout. No promotion; totals unchanged.
- 2026-09-13 (09:00): QA-01 Items plane-row selection fixed at cf3b875 (was an empty handler); regression 24/24 one clean serial run; paired live check and publication still pending, no row promotion. Totals unchanged.
- 2026-09-13: Handoff to Claude Code. Collected the pending QA-01 plane gate (11/11, clean serial run); re-tallied the matrix (32 passed / 12 partial / 11 deferred / 1 device = 56, unchanged). OpenClaw parity work paused at Jason's request (automation `3eced82f` disabled, heartbeat off, dashboard session idle since 00:14 EDT).
- 2026-09-12: Created from all 56 matrix rows and current 0cc5d6c checkpoint; enumerated all 24 not-passed cases, current Items WIP, release/device/publication gates and finite-pass exclusions. Owner reconciliation of any additional receipt-level caveats is ongoing.
