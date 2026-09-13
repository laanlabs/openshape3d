# OpenShape3D — unfinished-work status

Last reconciled: **2026-09-12, 23:18 EDT paired checkpoint**. Source checkpoint: **0cc5d6c**.
Owner: dedicated OpenShape3D parity / PR #29 session. This is the current open-work register, not the historical mission log.

**32 passed / 0 failed / 23 incomplete / 1 device-blocked = 56 acceptance cases.**
The 23 incomplete cases comprise 12 partial core cases and 11 explicitly deferred cases.
A passed finite recipe is not full feature parity. Automated passes do not replace paired live checks or physical-device proof.

## Current work — not yet complete

- **QA-24 Items selection:** source 0cc5d6c is pushed; final 52/52 (43 model + 9 UI) passed. Changed-build named-sketch all-entity selection, untouched Exit retention, Rename Undo/Redo deselection, gallery reopening and publication are verified. Native model-mode gizmo/transform dispatch remains the next paired comparison. Do not count this as a completed QA-24 case.
- **QA-24 broader selection:** curved-face/edge overlap and remaining multi-selection coverage remain open even when the Items fix passes.
- Latest checkpoint verified no test runner; next is the model-mode gizmo comparison; this is a snapshot, not a claim about current process activity.
- Latest verified report baseline: illustrated 1,292 unique images / 1,295 placements; master 38 media. Eight Items assets verified exactly once with no predecessor loss; master note verified.

## Every unfinished original acceptance case

Each entry preserves the matrix's current evidence and remaining scope. Deferred means unfinished, not passed or silently removed. Owner is the dedicated parity session unless stated otherwise.

### QA-01 — Plane selection

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Origin Front/Right/Top grid availability paired; offset/face/miss matrix open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-02 — Entry method

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Ground menu entry only; remaining routes open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-03 — Camera angle

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Origin Front/Right/Top normal entry/grid checked; full orbit/angle matrix open.
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
- **Evidence / remaining work:** Typed planar-face/body/profile chooser on ab6fb2d passed 26/26; changed live face/profile dispatch, Cancel and gallery recovery of three boxes plus circle verified. Body-name/Rename correction b5bff74 final46/46 plus paired history/reopen; illustrated1271unique/1274placements/master38 verified. Connected rectangle and later constraint additive routes retained; native Profile identity confirmed by accessibility selection; broader curved-face/edge selection remains open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-28 — Dimension selection matrix

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Non-core multi-entity dimension coverage; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-29 — Badge layout

- **Status:** Core — partial live pass.
- **Evidence / remaining work:** Portrait and landscape edge keypad usable; resize alignment fixed; right-palette/compact open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-31 — Unit conversion

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Comprehensive unit formats; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-32 — Expression evaluation

- **Status:** Explicitly deferred.
- **Evidence / remaining work:** Comprehensive variables/expression semantics; remains in full audit, not passed.
- **Closure required:** Retain in the full-parity backlog; define and execute the complete feature acceptance recipe when this deferred lane is taken up. No completion claim.

### QA-33 — Invalid numeric input

- **Status:** Core — partial live pass.
- **Evidence / remaining work:** Paired zero/negative, empty/division/syntax, correction, click-away/Escape and history sampled Sept9. Selected polygon count2 refusal/3.5 recovery live; current invalid-input/history gate19/19. Native10001 enters unresolved busy processing, so clone10000 is defensive, not verified parity. Diagnosis illustrated803/master38 published; upper bound stays open.
- **Closure required:** Complete the stated remaining recipe, retain regression and paired live/history/reopen evidence where applicable, and verify publication before promoting the matrix row.

### QA-40 — Keypad transitions

- **Status:** Core — partial, not passed.
- **Evidence / remaining work:** Retained click-away/tool/toggle/Exit/Escape/history evidence plus paired blocked/unblocked cube drag on5676bd0 with final57/57 and illustrated1237/master38. Native pan delivery remains unresolved; physical input is QA52.
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
- **Evidence / remaining work:** Extensive paired exact-value/local-frame/Copy/Escape/history evidence plus clean 50/50 current-tree direct line/circle/rectangle and mixed line+circle Copy matrix. Fresh paired mixed-selection and compact-layout checks remain open.
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
- **Evidence / remaining work:** Panel/palette correction4b6a78f passed final50/50 and changed live both-panel/inward-flyout/plane-choice checks; illustrated1247/master38 published89dbafc. Retained51/51 layout baseline remains valid. Native Mac lacks the same handedness/large-text controls; physical iPad variants remain unverified.
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
- **Input/capture:** several historical cases were blocked by supported input/capture delivery. GUI work has subsequently recovered in parts. Re-test each remaining route; do not propagate a global stale blocker or infer an app failure from tool delivery.
- **QA-33 polygon bound:** native 10,001-side processing did not establish a safe native upper limit. Clone 10,000 ceiling is defensive, not parity evidence.
- **Publication:** current Items batch awaits final live/export evidence. Older queue entries include recovered material and require reconciliation, not blind duplication.

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

## Change log

- 2026-09-12: Created from all 56 matrix rows and current 0cc5d6c checkpoint; enumerated all 24 not-passed cases, current Items WIP, release/device/publication gates and finite-pass exclusions. Owner reconciliation of any additional receipt-level caveats is ongoing.
