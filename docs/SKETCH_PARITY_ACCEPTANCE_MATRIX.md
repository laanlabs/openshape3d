# Core-sketch milestone: complete original acceptance map

Starting revision `cd0937d`; September 8, 2026. All 56 original cases retained.
Partial evidence is **not** a case pass. No complete case is promoted to covered by this reconciliation. All device tests remain pending. Existing audit remains unchanged.

| Case | Original scenario | Milestone lane | Current evidence / remaining work |
|---|---|---|---|
| QA-01 | Plane selection | Core — partial, not passed | Origin Front/Right/Top grid availability paired; offset/face/miss matrix open. |
| QA-02 | Entry method | Core — partial, not passed | Ground menu entry only; remaining routes open. |
| QA-03 | Camera angle | Core — partial, not passed | Origin Front/Right/Top normal entry/grid checked; full orbit/angle matrix open. |
| QA-04 | Empty entry | Core — passed | Paired Top/Front/Right empty Exit/two-stage Escape, hidden/visible reference preservation, corrected provisional Items/history and final gallery reopen verified on 0c8c268. Initial6/6 plus revised5/5; illustrated417/master38 export-verified. |
| QA-05 | Line chain | Core — partial, not passed | Horizontal drag/readout paired; live clone next-preview delivery unresolved. |
| QA-06 | Line cancel | Core — partial, not passed | Two-stage Escape corrected and paired live, committed line retained; clean12/12 regressions. Released-line Delete corrected and paired with one-step history/reopen; Line→Arc retains geometry. Pending-preview, Return and double-tap routes open. |
| QA-07 | Line raw aim | Core — passed | Finite near-horizontal above/below recipe across native/clone scales, signed/reverse and H/V supplements, independent Guide/Auto, history and final reopen verified at eb9b4ab. 35 distinct checks across runs; general snap/hover/device remains separate. |
| QA-08 | Diagonal rectangle | Core — passed | Finite four-quadrant, both sizing-order/lower-left anchor, selected-side/readout, history and saved-reopen recipe closed September10 at e9343a7. Relevant retained regression runs and paired evidence reconciled; illustrated624/master38 verified. Broader input/layout/device cases remain separate. |
| QA-09 | Center rectangle | Core — passed | Finite both-axis-order/center-preservation recipe plus four release directions, center Lock/migration, selected-side/corner lifecycle, history/reopen closed at e9343a7. Relevant29/30+corrected1/1 latest follow-up retained; illustrated624/master38 verified. No universal UI/device claim. |
| QA-10 | Three-point rectangle | Core — partial, not passed | Rotated sizing/reselection retained. September10 reverse-baseline Escape omission corrected: first cancels placement, second disarms, paired live; readout strike-through removed. Clean29/29 plus separate3/3; illustrated631/master38 verified. Pending numeric interaction and completion directions remain open. |
| QA-11 | Concentric circles | Sampled live recipe passed | Top/mouse existing-center initiation preserves inner circle and line; Pencil pending. |
| QA-12 | Circle dimensions | Core — partial, not passed | Diameter release/keypad/center-preserving edit paired; radius-mode matrix open. |
| QA-13 | Arc construction | Core — partial, not passed | Two endpoint taps/default45°, radius+sweep presentation, third-point placement, Return completion, chained shared endpoint, two-stage Escape cancellation, line-to-arc tangent transition and direct minor/semicircle/major gesture boundaries paired; clone hover path is automated-only and physical Pencil/touch remains unverified (direct-arc/default-shape/pending-feedback/arc-cancellation/third-point/chaining/Return/tangent/boundary receipts). |
| QA-14 | Ellipse dimensions | Explicitly deferred | Advanced ellipse-axis coverage; remains in full audit, not passed. |
| QA-15 | Polygon | Core - partial, not passed | Release/radius/profile plus Sept9 selected-count2 refusal,3.5→3,Undo/Redo and geometry reopen sampled; reopened edit identity and broader count/constraint matrix open. |
| QA-16 | Spline | Explicitly deferred | Spline creation/editing; remains in full audit, not passed. |
| QA-17 | Text sketch | Explicitly deferred | Text sketch; remains in full audit, not passed. |
| QA-18 | Drawing on points | Core — partial, not passed | Circle-at-rectangle-corner, line endpoint and existing circle center paired. |
| QA-19 | Snap categories | Core — partial, not passed | Raw acquisition-off and Grid-only paired; guidepoint combinations open. |
| QA-20 | Snap zoom | Core — partial | Screen-relative acquisition corrected; native near/far reference + two clone scales, clean37/37. Full zoom/grid matrix open. |
| QA-21 | Snap feedback | Core — partial, not passed | Native Endpoint hover captured; clone idle feedback automated-only, live pointer delivery unresolved. |
| QA-22 | 3D references | Explicitly deferred | Off-plane reference coverage; remains in full audit, not passed. |
| QA-23 | Selection state | Core — partial, not passed | Point/edge, blank deselect and connected rectangle samples; other entity/tool states open. |
| QA-24 | Multi-selection | Core — partial, not passed | Connected rectangle double-click paired; mouse/touch additive difference recorded. |
| QA-25 | Annotation off-state | Core — partial, not passed | Completed horizontal line and rectangle badges paired; full selection matrix open. |
| QA-26 | Annotation on-state | Core - partial, not passed | Orange selection, offset line/rectangle leaders, full circle diameter and curved arc annotation sampled paired; glyph/control and selected-side layout matrix open. |
| QA-27 | Dimension type | Core — partial, not passed | Line/rectangle/circle radius-diameter and arc sweep samples; full type matrix open. |
| QA-28 | Dimension selection matrix | Explicitly deferred | Non-core multi-entity dimension coverage; remains in full audit, not passed. |
| QA-29 | Badge layout | Core — partial live pass | Portrait and landscape edge keypad usable; resize alignment fixed; right-palette/compact open. |
| QA-30 | Rectangle sequence | Core — partial, not passed | Center and three-point two-axis edits paired; keyboard/edge matrix open. |
| QA-31 | Unit conversion | Explicitly deferred | Comprehensive unit formats; remains in full audit, not passed. |
| QA-32 | Expression evaluation | Explicitly deferred | Comprehensive variables/expression semantics; remains in full audit, not passed. |
| QA-33 | Invalid numeric input | Core — partial live pass | Paired zero/negative, empty/division/syntax, correction, click-away/Escape and history sampled Sept9. Selected polygon count2 refusal/3.5 recovery live; upper limits/system keyboard remain open. |
| QA-34 | Locked/unlocked value | Core - partial, not passed | Driven circle/arc refusal, axis driven translation and persisted side-Lock paired; broader value-lock matrix open. |
| QA-35 | Constraint rail | Core — partial, not passed | Contextual Unlock expanded rail, retained other locks, Undo/Redo and reopen sampled; compact/full rail matrix open. |
| QA-36 | Constraint types | Core — partial, not passed | H/V plus point Lock constrained drag and inference samples; other relations open. |
| QA-37 | Selection anchor | Core — partial, not passed | Diagonal/center/three-point numeric anchors and locked-endpoint drag sampled; full constrained matrix open. |
| QA-38 | Disconnect | Core — partial | Four-line edge separation/history/reopen paired; clean34/34. Midpoint/primitive/non-line cases and ring visual difference remain. |
| QA-39 | Conflict and point states | Core — partial, not passed | False constrained-drag conflict corrected; other conflict/DOF combinations open. |
| QA-40 | Keypad transitions | Core — partial, not passed | Click-away/tool activation and dimension Escape paired; explicit-transform keypad-first Escape and subsequent tool exit live verified (4d6e64e). Full system-keyboard matrix open. |
| QA-41 | Trim primitives | Core — partial, not passed | Paired crossing-line/circle span removal; remaining primitives/history open. |
| QA-42 | Trim curves | Explicitly deferred | Ellipse/spline trim; remains in full audit, not passed. |
| QA-43 | Trim references | Core — partial, not passed | Rectangle edge removal/surviving side readout paired; driven/reference/history matrix open. |
| QA-44 | Offset | Explicitly deferred | Offset completeness; remains in full audit, not passed. |
| QA-45 | Move/rotate/copy | Core - partial, not passed | White exact-axis/rotation controls, retained re-edit/local frame, circle frame-only history, armed reselection and Escape paired; direct-drag/compact/mixed-selection matrix remains open. |
| QA-46 | Pattern | Explicitly deferred | Advanced linked patterns; remains in full audit, not passed. |
| QA-47 | Projection | Explicitly deferred | Projection linking; remains in full audit, not passed. |
| QA-48 | Coplanar sketch identity | Core — partial live pass | New coplanar versus named continuation corrected; independent visibility and paired reopen verified. Consumed named entry/bore rebuild/history/reopen sampled; overlapping selection variants open. |
| QA-49 | Profile topology | Core — partial, not passed | Paired visible-gap closure, nested holes, shared/point-touch boundaries, duplicate/partial-overlap and straight bow-tie regions/history/reopen verified through 3ca4c2d. Curved intersections and tiny thresholds unverified; not complete topology coverage. |
| QA-50 | Sketch-to-solid | Core — partial, not passed | Pentagon, nested-hole bore, duplicate-boundary block and bow-tie triangle extrusion/history/reopen paired. Consumed source bore rebuild paired; Sweep/Loft smoke remains open. |
| QA-51 | Save/reopen | Core - partial, not passed | Paired numeric/radial/rectangle reopen samples retain geometry; latest locked rectangle profile/handle retained. Cold launch and broader downstream state open. |
| QA-52 | Touch and Pencil | Device-only pending | Physical Pencil/touch requires Jason’s actual device comparison; no simulator substitute. |
| QA-53 | Layout | Core - partial, not passed | Near-rail circle diameter target/leader corrected; paired labels/keypad and reopen, final4/4 after documented guard failures. Landscape radial samples retained; handedness/oblique/manual-placement matrix open. |
| QA-54 | Keyboard | Core — partial, not passed | de2756c live creation/dimension Undo/Redo paired; clone toolbar/CmdZ work after autosave. Line Escape corrected and paired; other focus states open. |
| QA-55 | Sustained use | Core — passed | Ten paired rectangle/circle/line cycles, history, dense-state reopen and clone post-test relaunch passed without a hang; clean 71/71 focused load regression. Automation wall time is not a product benchmark (sustained-use receipt). |
| QA-56 | Downstream smoke | Core — passed | Paired circle-profile extrusion/cancel/history workflow and clean current-revision 65/65 Sweep/Loft/kernel regression; advanced feature parity and device input are not claimed (downstream-smoke receipt). |

## Original recipes (preserved)

### QA-01 — Plane selection

XY/YZ/ZX, planar face, offset construction plane, curved face and miss. Issues: SK-07/08. Result: NOT RUN. Evidence/owner: pending.

### QA-02 — Entry method

Sketch menu, selected face, existing item, keyboard hover/Space. Issues: SK-07. Result: NOT RUN. Evidence/owner: pending.

### QA-03 — Camera angle

0/45/85 degrees, normal view action, orbit while sketch remains active. Issues: SK-07. Result: NOT RUN. Evidence/owner: pending.

### QA-04 — Empty entry

Start then cancel; no persistent empty sketch or unintended visibility change. Issues: SK-08; ED-10. Original result: NOT RUN. September10 result: PASSED for the finite Top/Front/Right Exit/Escape and visibility/reopen recipe; see [empty-entry receipt](testing/sketch-parity-empty-entry-2026-09-10.md). Physical input is not implied.

### QA-05 — Line chain

Tap A-B-C; end open; resume from B; close intentionally. Issues: SK-09. Result: NOT RUN. Evidence/owner: pending.

### QA-06 — Line cancel

Enter, Escape once/twice, Backspace, double-tap, tool switch. Issues: SK-09. Result: NOT RUN. Evidence/owner: pending.

### QA-07 — Line raw aim

Near-horizontal intent above/below tolerance at several zoom levels. Issues: SK-06; DM-14. Result: PASSED for this finite desktop/native-versus-simulator recipe, September10 at eb9b4ab. Paired near/outside at changed scales, signed/reverse direction, H/V supplements, Guide/Auto independence, history and final saved recovery verified. General snapping relationships, hover and physical input remain separate gates; no universal snap parity claim. Thirtyfive distinct relevant tests pass across retained runs. Evidence: testing/sketch-parity-line-guides-2026-09-10.md.

### QA-08 — Diagonal rectangle

**September10 closure:** PASSED for the finite recipe at `e9343a7`. Earlier partial notes below are historical and superseded only for this recipe. [Closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md) reconciles all required directions/orders, current presentation fixes, test failures/corrections, paired history/reopen and624/master38 verified publication. General layout, other entity/constraint cases and physical input remain separate gates.


All four drag quadrants; native anchor policy; exact width/height. Original first-anchor assumption superseded by paired native lower-left samples. Issues: SK-03; DM-11. Result: PARTIAL — mixed-quadrant sequential sizing, default leader sides, center translation/history and paired saved recovery now live verified September 10. Leader and translation groups each passed clean25/25; four-corner marker correction c634c30 final30/30 and center-only Lock35382d4 final31/31 with paired sizing verified. Direct center-padlock styling/action and asymmetric Lock/Unlock selection lifecycle now verified with final33/33 and paired history/reopen. Selected-free center halo additionally matched with1/1 and live comparison. Partial-edge supporting-line colors now match paired left/top Locks; final36/36, live Unlock/history and clone reopen passed. Native reopen retains Lock/corners but selection clearing remains unresolved in that capture. Side-Lock midpoint glyph removed after paired native visibility comparison; final31/31 and live contextual Unlock/history/reopen passed. Native unselected partial-Lock colors were subsequently recovered with actual-edge then blank selection. Remaining: reconcile finite recipe closure; halo/partial-edge/glyph publication recovered September10 through577 with predecessor-preserving exports. Native latest center-lock reopen recovered and passed after dismissing the retained test-crash dialog. Center relationships beyond Lock remain unsupported and are not generalized as parity. Evidence: testing/sketch-parity-diagonal-anchors-2026-09-08.md and testing/sketch-parity-diagonal-matrix-2026-09-10.md. Historical sign-out resolved; recovered report577/master38 verified.

### QA-09 — Center rectangle

**September10 closure:** PASSED for the finite recipe at `e9343a7`. Earlier partial notes below are historical and superseded only for this recipe. [Closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md) reconciles all required directions/orders, current presentation fixes, test failures/corrections, paired history/reopen and624/master38 verified publication. General layout, other entity/constraint cases and physical input remain separate gates.


Origin anchor; center fixed under both dimensions. Issues: SK-03. Result: PARTIAL — prior height-first and up-left width-first paired; September10 right-up width/height halves also preserve center. Release center halo/direct Lock now verified with26/26 and paired history/reopen. Center-specific leaders corrected with final27/27 and allfour controlled release directions; paired up-left two-axis sizing/history/reopen verified. Four-decimal mm/residual readout correction and unchanged-accept Undo now paired verified;36unit and corrected3/3 after retained numeric failure. Rotated center-lock migration, corner rotation/reselection, parallel-side editors, adjoining corner leaders, history selection and corner-Lock conflict/recovery are now paired, regression-tested and published through546 placements; corner editor open/cancel/refusal/success lifecycle is paired with final14/14. Selected corner outline/hollow markers, allfour single-edge triple readouts and shared-dimension editors now match sampled native. Successful side commit clearsedge/handle and retainsparallelreadouts through history, paired with clean14/14. Remaining: reconcile finite recipe closure with older evidence/publication backlog; broader exact-UI/device equivalence not claimed. Earlier publication backlog remains separately tracked. Evidence: testing/sketch-parity-center-width-first-2026-09-08.md; testing/sketch-parity-center-matrix-2026-09-10.md. Google editing recovered; latest567 placements/master38 export-verified.

### QA-10 — Three-point rectangle

Rotated baseline, perpendicular height, cancel at each stage. Issues: SK-03. Result: PARTIAL — historical two-slope anchor/reselection work retained; September10 pending reversed-baseline cancellation/readout paired and corrected. Clean29/29 plus separate3/3; report631/master38 verified. Pending numeric interaction and remaining completion directions open. Evidence: testing/sketch-parity-three-point-leaders-2026-09-08.md and testing/sketch-parity-three-point-matrix-2026-09-10.md.

### QA-11 — Concentric circles

New circle starts at existing center without edit interception. Issues: SK-04. Result: NOT RUN. Evidence/owner: pending.

### QA-12 — Circle dimensions

R versus diameter, creation/edit/reopen, no factor-of-two error. Issues: DM-04. Result: NOT RUN. Evidence/owner: pending.

### QA-13 — Arc construction

Prescribed endpoints/side, major/minor, tangent transition, cancel. Issues:
SK-10. Result: PARTIAL — endpoint/default side, third-point commit, chained
shared endpoint, Return completion, cancellation, tangent transition and direct
minor/semicircle/major boundaries are paired. Native sampled 90/180/220 degrees;
the differently scaled clone sampled 81.91/176.03/214.93 degrees and restored
the major profile through Undo/Redo. Clone hover is automated-only and physical
Pencil/touch remains unverified. Evidence: [boundary receipt](testing/sketch-parity-arc-major-minor-boundaries-2026-09-09.md),
[Return receipt](testing/sketch-parity-arc-return-2026-09-09.md),
[third-point/chaining receipt](testing/sketch-parity-arc-third-point-chaining-2026-09-09.md)
and linked earlier arc receipts.

### QA-14 — Ellipse dimensions

Major/minor radii, rotation, independent edit and lock. Issues: DM-05. Result: NOT RUN. Evidence/owner: pending.

### QA-15 — Polygon

Side count boundaries, radius semantics, orientation and exact input. Issues: SK-02; DM-10. Result: NOT RUN. Evidence/owner: pending.

### QA-16 — Spline

Fit points, finish/reopen/edit/close; control mode separately. Issues: SK-11. Result: NOT RUN. Evidence/owner: pending.

### QA-17 — Text sketch

Placement, font/height, cancel, profile and reopen; compare editing affordance. Issues: ED-09/10. Result: NOT RUN. Evidence/owner: pending.

### QA-18 — Drawing on points

New shapes at endpoints/midpoints/centers/face corners. Issues: SK-04. Result: NOT RUN. Evidence/owner: pending.

### QA-19 — Snap categories

Each category on/off independently; all off truly free. Issues: SK-05. Result: NOT RUN. Evidence/owner: pending.

### QA-20 — Snap zoom

0.1x/1x/10x, tiny and large parts, visible grid agreement. Issues: SK-06. Result: PARTIAL. Screen-relative radius37/37; near/far at original and1.48x clone scales, native reference. Full zoom/grid matrix open; see preplacement-snap receipt.

### QA-21 — Snap feedback

Endpoint versus midpoint versus center versus edge, overlapping candidates. Issues: SK-05/06. Result: PARTIAL. Native Endpoint hover captured; clone idle feedback25unitpasses but live unresolved. Other feedback/overlap cases open.

### QA-22 — 3D references

Off-plane point guides versus actual coincidence; avoid false constraints. Issues: SK-05. Result: NOT RUN. Evidence/owner: pending.

### QA-23 — Selection state

Point/edge/fill/sketch/body; tool armed versus inactive; blank deselect. Issues: ED-07. Result: NOT RUN. Evidence/owner: pending.

### QA-24 — Multi-selection

Shift/additive, connected double-tap, overlapping geometry, item selection. Issues: ED-07. Result: NOT RUN. Evidence/owner: pending.

### QA-25 — Annotation off-state

Nothing selected, one entity, several entities, disjoint same-sketch geometry. Issues: DM-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-26 — Annotation on-state

Active/other/hidden sketches; exit and re-entry; toggle persistence. Issues: DM-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-27 — Dimension type

Sloped 3-4-5 line: horizontal 30, vertical 40, absolute 50. Issues: DM-03. Result: NOT RUN. Evidence/owner: pending.

### QA-28 — Dimension selection matrix

Line pair, point pair, point+line, curve pair, ambiguous mixed selections. Issues: DM-13. Result: NOT RUN. Evidence/owner: pending.

### QA-29 — Badge layout

Dense values, overlaps, manual reposition if supported, camera zoom. Issues: DM-06/07. Result: NOT RUN. Evidence/owner: pending.

### QA-30 — Rectangle sequence

Width then height via keyboard and touch, both at screen edge. Issues: DM-11. Result: NOT RUN. Evidence/owner: pending.

### QA-31 — Unit conversion

mm/cm/m/inches; explicit suffix; display-unit change; imperial forms. Issues: DM-10.
Result: comprehensive acceptance remains deferred, not passed. September10 sampled
metric source retention, explicit inches/feet and mixed feet+inches now have paired
live result/source/history and clone saved-reopen evidence. Latest mixed run35/35;
illustrated368/master38 export-verified. Quoted-inch keyboard route refused in both
apps, but smart punctuation leaves exact ASCII/Unicode coverage unverified. Physical
touch, all imperial formats and complete display-setting matrix remain open.
Receipts: testing/sketch-parity-imperial-unit-2026-09-10.md,
testing/sketch-parity-feet-unit-2026-09-10.md,
testing/sketch-parity-quoted-inch-2026-09-10.md,
testing/sketch-parity-mixed-imperial-2026-09-10.md.

### QA-32 — Expression evaluation

25.4/2, parentheses, negative values, variable insertion; type mismatch. Issues: DM-10/15. Result: NOT RUN. Evidence/owner: pending.

### QA-33 — Invalid numeric input

Empty, malformed, zero/negative size, division by zero, out-of-range count. Issues: DM-10/12. Result: PARTIAL. September9 paired zero/negative, empty/division/syntax retention, valid recovery, click-away/Escape and Undo captured. Parser/keypad clean22/22 at8eb45f9. Selected-polygon count2 refusal and3.5->3 recovery/history live; corrected9/9 after a fixture failure, expanded final11/11. Native high-count frames lagged; exact upper limit and system-keyboard layouts remain open. Sept10 keyboard seed/toggle/invalid-Return immediate recovery and Undo passed paired with final11/11; Sept10 scalar arithmetic retention/f(x), plain replacement and history passed paired at7a5c618 (final31/31); explicit-unit/display-unit source stability and import are automated-only. Keyboard-mode preference same-label Escape/reopen and123switch-back passed paired; final explicit-commit11/11 follows two retained failures (seedappend corrected; syntheticEscape differs from live). Full layouts/upper limits remain open. Evidence: testing/sketch-parity-invalid-recovery-2026-09-09.md and testing/sketch-parity-system-keyboard-2026-09-09.md.

### QA-34 — Locked/unlocked value

Driving versus one-time size edit; geometry drag after unlock; undo. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-35 — Constraint rail

Enablement for each selected combination; settings access; discoverability. Issues: SK-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-36 — Constraint types

H/V, parallel, perpendicular, coincident, midpoint, tangent, concentric, equal, symmetry. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-37 — Selection anchor

First/Last, reverse order, existing locks override, repeated solve stability. Issues: DM-08. Result: NOT RUN. Evidence/owner: pending.

### QA-38 — Disconnect

Endpoint and midpoint connections, unrelated constraints survive, undo. Issues: DM-09. Result: PARTIAL. Four-line edge Disconnect/move/history/reopen paired and corrected clean34/34 (disconnect receipt). Primitive rectangles/midpoints/non-line cases remain open.

### QA-39 — Conflict and point states

Under/fully defined, lock point versus entity, refusal and attribution. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-40 — Keypad transitions

Another/same tool, off, blank tap, Escape, undo, exit, rotate, pan. Issues: SK-12; DM-12. Result: PARTIAL (historical NOT RUN superseded). Prior tool/blank/Escape coverage in ledger. Sept10 same-dimension keyboard/keypad preference, seed replacement and live Escape captured paired; explicit-commit lifecycle11/11. Synthetic XCTest Escape discrepancy retained. Full rotation/pan/compact/device-input matrix remains open. Evidence: testing/sketch-parity-keyboard-preference-2026-09-10.md.

September10 supplement: `1d28849` fixes software-keyboard occlusion with clean2/2
UI tests asserting field/commit above actual keyboard. Live portrait invalid draft,
landscape recovery/commit and saved-source reopen verified. Native Mac keyboard-only
field remains visible; no native-iPad equivalence claim. `ef27d62` corrects dark-UI
annotation contrast and pending material/font; three builds and live paired style
checks, not new automated tests. Illustrated353/master38 verified. Pan/compact and
physical routes remain open, so QA40 is not closed.

### QA-41 — Trim primitives

Line/circle/arc/rect/polygon, boundary versus whole deletion. Issues: ED-03/04. Result: NOT RUN. Evidence/owner: pending.

### QA-42 — Trim curves

Ellipse bounded span; spline capability separately; preserve shape. Issues: ED-03. Result: NOT RUN. Evidence/owner: pending.

### QA-43 — Trim references

Dimensioned/constrained geometry, downstream profile, full undo restoration. Issues: ED-04. Result: NOT RUN. Evidence/owner: pending.

### QA-44 — Offset

Single/Chain, nested loop, sign flip, zero/invalid offset, cancel. Issues: ED-11. Result: NOT RUN. Evidence/owner: pending.

### QA-45 — Move/rotate/copy

Exact values, constrained entities, mixed selections, copy on/off, cancel. Issues: ED-08. Result: NOT RUN. Evidence/owner: pending.

### QA-46 — Pattern

Open/closed selection, linear/circular, quantity/spacing edit, source edit, unlink. Issues: ED-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-47 — Projection

Edge/face/sketch selection, linked/unlinked, source change, cancel. Issues: ED-05. Result: NOT RUN. Evidence/owner: pending.

### QA-48 — Coplanar sketch identity

Create independent, continue existing, edit named item, hidden consumed sketch. Issues: ED-06/10. Result: NOT RUN. Evidence/owner: pending.

### QA-49 — Profile topology

Hole, touching loops, tiny gap, duplicate edge, construction crossing. Issues: ED-09. Result: NOT RUN. Evidence/owner: pending.

### QA-50 — Sketch-to-solid

Exact extrude, correct hole, consumed sketch visibility, edit/rebuild, undo. Issues: ED-09. Result: NOT RUN. Evidence/owner: pending.

### QA-51 — Save/reopen

Geometry, constraints, variable references, pattern links, label state and units. Issues: ED-10. Result: NOT RUN. Evidence/owner: pending.

### QA-52 — Touch and Pencil

Palm, finger navigation during drawing, Pencil handles, no ghost strokes. Issues: SK-13. Result: NOT RUN. Evidence/owner: pending.

### QA-53 — Layout

Portrait/landscape, left-handed, Items/History open, large text, screen edges. Issues: SK-14. Result: NOT RUN. Evidence/owner: pending.

### QA-54 — Keyboard

Hotkey versus search preference, focus in number field, Escape scope, undo/redo. Issues: SK-09/12; DM-12. Result: NOT RUN. Evidence/owner: pending.

### QA-55 — Sustained use

Repeat golden path ten times, then dense sketch; log latency/hangs, not only
screenshots. Issues: ED-12. Result: PASS — paired ten-cycle
rectangle/circle/line construction, history and dense-state gallery reopen.
OpenShape3D also retained the project through unit-test host closure and
relaunch. No visible hang. Wall-clock automation timings are logged but are not
a native-versus-clone performance comparison. Physical Pencil/touch endurance
remains QA-52. Evidence:
[sustained-use receipt](testing/sketch-parity-sustained-use-2026-09-09.md).

### QA-56 — Downstream smoke

Existing SweepLoft failures separately attributed; no claim that sketch work
fixed them. Issues: ED-12. Result: PASS — paired circle-profile extrusion and
solid Undo/Redo; clone preview cancellation; clean 65/65 Sweep/Loft UI, kernel
and feature-graph regression on the same revision. Advanced feature parity and
physical-device input are not claimed. Evidence:
[downstream-smoke receipt](testing/sketch-parity-downstream-smoke-2026-09-09.md).

## Evidence dimensions

Implementation/regression/live/publication are tracked independently in `SKETCH_PARITY_IMPLEMENTATION.md` and receipts. Historical rectangle/readout tests are not a final candidate regression. Today’s history diagnosis is in `testing/sketch-parity-milestone-start-2026-09-08.md`. No installable physical-device artifact identified yet.

## September8 numeric/layout evidence

QA29/30/33/40 partial updates: numeric-dismissal receipt records zero rejection,
click-away vs Escape,3/4mm live correction and regression history. Resize-rendering
receipt records clean15/15 and paired resize alignment fix. Edge-layout receipt
records landscape keypad/half-height samples and verified72image publication.
These do not complete compact/system-keyboard/right-palette or all numeric cases.

## September8 constrained-edit evidence

QA23/35/36/37/39 partial: endpoint selection, point Lock, free-axis diagonal drag
compared live. Confirmed clone false conflict corrected; fixed endpoint retained.
See constrained-drag receipt for14unit passes plus corrected1UI pass (not a single
combined run), actual geometry history assertions, failed fixture diagnostics and
live evidence. Broader relation/selection/history matrix remains open.

### September8 selection/snapping/trim continuation

QA19/23/35 partial: paired Lock removal and acquisition-off/Grid-only placement;
clone-only gallery settings persistence. QA41 partial: crossing-line tail and
circle upper span removal preserve crossing/source geometry in sampled cases.
QA35: near-equal default inference opt-in correction,33/33 tests and live Equal-off
independent lengths. Saved preferences deliberately retained. Receipts snap-lock,
trim, equal-inference dated2026-09-08. Google publication blocked, not verified.

QA24/43 continuation: connected4line rectangle double selection and top-edge Trim
paired; surviving side readouts stable. Plain native mouse replaces vs simulated
touch additive selection recorded without speculative change. Receipt selection-
trimrefs-2026-09-08; publication blocked.

Arc sweep correction:90/270/R coexistence and paired gallery reopen sampled;
33distinct checks pass across initial/targeted runs. Native curved vs clone dashed
angle annotation remains different. Full boundary/construction/tangent coverage
open. Receipt arc-sweep-2026-09-08; publication blocked.

September8 de2756c continuation: [live history repeat](testing/sketch-parity-history-live-repeat-2026-09-08.md)
now verifies actual creation/dimension Undo/Redo in both apps, including clone
afterautosave. Earlier no-response cause unknown, no speculative history changes.
Line Escape missing binding confirmed and under regression; not yet passed.
[Fullturn conversion](testing/sketch-parity-arc-full-circle-2026-09-08.md) clean25/25,
paired conversion plus clone-only reopen. No whole-case promotion.

## September8 polygon/profile sample

QA15/50/51 PARTIAL: paired retained radius/no automatic editor, explicit radius
edit, nonzero pentagonal extrusion and visibly retained solid after gallery reopen.
Clean1/1 UI regression supplements live evidence. Existing side-count editing,
holes/rebuild and full persistence matrix are open. See
[polygon receipt](testing/sketch-parity-polygon-release-2026-09-08.md).

### September 8 — scoped circle diameter/interior visual correction

Full diameter leader/arrows/plain text replaces half-radius badge; active sketch
regions stay unfilled while armed extrusion selection still fills. Paired
rightward-release evidence and clone Ø2 edit/1 mm cylinder captured. Clean 2/2
circle/profile UI tests. Master roadmap 16 images export-verified. Native
reselected annotation can extend vertically outside circle; placement, blue
manipulation ring, radius/polygon/rectangle leaders remain open. Not a full
visual acceptance or candidate claim. See
[receipt](testing/sketch-parity-diameter-annotation-2026-09-08.md).

### September 8 — arc radius annotation

Arc-only radius leader now follows start endpoint outward with arrow/plain
upright text; viewport extension shortened near edges. Paired right semicircle
R310→400 native and R0.662→1 clone preserve180°/center/crossing line. Clean
strengthened arc UI1/1: radius entry plus sweep/history/fullturn. Master20
images export-verified. Native clears selection after commit, clone retains;
blue full ring, arbitrary annotation placement and input-delivery anomalies
remain open. [Receipt](testing/sketch-parity-radius-leader-2026-09-08.md).

### September 8 — selected single-arc radial control

Default white radial handle replaces the full blue transform ring for a single
arc. Explicit Move/Rotate retains rotation; saved driving constraints take
priority over radial intent. Paired free/driven behavior, clone Undo/Redo and
final resize/rotation/gallery reopen captured. Two unit and two distinct UI
checks passed across initial/targeted runs, not one combined clean run. Final
blocked-drag notice is automated-verified; Copy-mode interaction and full
transform styling remain open. Master export verifies25 embedded images,
including exact corrected resize and paired reopen PNGs. No candidate claim.
[Receipt](testing/sketch-parity-radial-handle-2026-09-08.md).

### September8 — arc Copy mode continuation

Explicit Move/Rotate now survives copied selection IDs. Clean1/1 focused UI
checks mode/radius/copiedposition UndoRedo. Paired native/clone Copy plus final
clone secondmove/Undo captured. Master28images exactexportverified. Persistent
Copy arming and general transform/label styling remain open, not full Copy
acceptance. [Receipt](testing/sketch-parity-arc-copy-mode-2026-09-08.md).

### September8 — selected circle radial sizing

Single-circle radial handle replaces defaultbluefullring; explicitMoveRotate
retained. Paired freecenter-preserving resize anddrivendiameterrefusal notice,
clone UndoRedo andpairedgalleryreopen captured. Clean6/6 (3solver,3UI) passed.
Master35images exactexportverified including5corrected/refusal/reopen PNGs.
Diameterleaderdirection, broadercontrols/layout matrix remainopen. Notwhole
QA12/oncanvas/devicepass. [Receipt](testing/sketch-parity-circle-radial-handle-2026-09-08.md).

### September8 — axis-aligned rectangle leaders

Completed width/height now offsetblackleaders/arrows/plaintext below/left.
Clean5/5 layout+rectangleUI; live2x1 edits retainlowerleft andusablekeypads.
Native2000x1000 pairedanchor/editorresult captured. Selectedrectangle still
showsgenericbluering: separateopen visualgap, notfullacceptance. MasterDoc
Savingblocked36verifiedimages, clone diagnosisinsertpending andfinalscreens
localonly. [Receipt](testing/sketch-parity-rectangle-leaders-2026-09-08.md).

### September8 — three-point outside leaders; new anchor discrepancy

Recoveredrectinterior chooses outwardsolidleaders/plainrotatedtext. Clean6/6
layout+UI andlivebothkeypads/retaineddimensions. Nativeheightthenbaseline
sampleheldRIGHTside whenbaseline shortened; cloneheldLEFT. Newgeometry
gapopen—do notclaimsequentialanchorparity. BothDocsblocked, localindex
containscorrected screenshots. [Receipt](testing/sketch-parity-three-point-leaders-2026-09-08.md).

### September 8 - slope-dependent three-point baseline anchor

Paired native samples hold the lower adjacent side across opposite slopes
and reversed construction. Clone preference corrected in cfc7fd5 for either
baseline edge. Clean17/17 and live both slopes, Undo/Redo, sequential height
edit. Reopened baseline verified; short height-edge selection remains open.
Both Docs blocked; local screenshots retained. Not full on-canvas acceptance.
See three-point-leaders receipt for complete history.

### September 8 - short edge versus endpoint selection

Tap-only point picking now preserves the middle of short lines. Native26px
edge midpoint selects height; clone30px edge now does likewise and opens
its0.52mm editor. Exact endpoint selection retained in both.16unit passes
plus targeted UI pass after two setup/timing failures, not combined clean
run. Generic ring/glyph styling remains open. Both Docs blocked, local
images retained. See short-edge-selection receipt.

### September8 - connected line-control transform integrity

Confirmed clone center-control movement disconnected a rectangle baseline
from saved coincident sides. All-line gizmo transforms now solve original
structural constraints and update whole sketch; dependent profiles rebuild.
Clean20/20 plus targeted profile UI1/1, live move/UndoRedo/closed-profile
and paired reopen. Saved locks automated-only; non-line transforms and
white directional controls remain open. Both Docs blocked, local evidence
retained. See line-gizmo-integrity receipt; not full transform acceptance.

### September 8 - rectangle normal edge handle

Isolated four-line rectangle edge now has a white outward-normal resize handle;
explicit Move/Rotate/Copy retained. Live free movement holds the opposite edge,
Undo/Redo restores geometry, and saved Lock refuses with notice. Gallery reopen
retains 2.565 mm, Lock, handle and an extrudable closed profile. 22 distinct
checks pass across initial 21-pass/1-query-failure run and targeted UI pass,
not a clean combined run. Both Docs remain Saving; corrected images local only.
Axis-aligned rect controls and non-line transforms remain open.
See [normal-handle receipt](testing/sketch-parity-rectangle-normal-handle-2026-09-08.md).

### September 8 - axis-aligned rectangle edge controls

Edge-specific orange highlight/white normal handle added without decomposing
stored rectangles. Clean32/32 (20geometry,12UI). Live free top resize and
Undo/Redo, driven-height translation, right-edge resize and paired gallery
reopen verified. Clone2.977x1 remains extrudable. Native per-edge Lock versus
clone whole-rect Lock and selected-side leader placement remain open, not
full rectangle acceptance. Both Docs blocked; corrected screenshots local.
See [axis-edge receipt](testing/sketch-parity-axis-edge-controls-2026-09-08.md).

### September 9 — explicit transform/history/keyboard updates

QA40/45/51/54 remain partial: white exact controls, retained absolute re-edit,
rotated local axes, frame-only circle history, settled history/reselection and
keypad-first Escape have focused tests and paired live receipts. cecd1f5 corrects
prior native mode-exit interpretation: history clears selection but tool stays
armed. 4d6e64e Escape clean2/2 plus live selected/unselected exit and clone
reopen. Illustrated104 images/new2 hashes and master38 final notes verified.
Temporary circular readout visibility correction is under regression, not yet
live signed off. Full geometry/annotation/compact/direct-drag acceptance and
installable-candidate gate stay open. Original recipes retained unchanged.

## September 9 — manual circle diameter label placement

Free placement now lasts for the current selection; stored diameter placement
is independently undoable and saved relative to the circle center. Fresh paired
free/driven label drag, typed-value inheritance, unchanged geometry, history and
gallery reopen verified. Optional Codable metadata preserves old files and merge.
Initial25/26, immediate-reselection targeted failure, settled targeted1/1:
26 distinct passing checks across runs, not one clean run. No selection-code
change; rapid successive input remains unverified. Scope is head-on circle
diameter labels; default selected orientation, oblique placement and other
dimension types remain open. [Receipt](testing/sketch-parity-circle-label-drag-2026-09-09.md).

## September 9 — default selected-circle outside leader

Paired removal of a driving diameter then reselection confirmed native outside
vertical versus clone interior horizontal. Normal head-on selection now prefers
the outside leader; drawing readouts and manual overrides remain. Clean6/6 plus
followup2/2; initially mistyped omitted selector corrected, not counted. Fresh
clone release/selection/keypad/Ø1/manual override/Undo and paired gallery reopen
verified. Immediate dimension unlock vs clone commit and oblique placement remain
open; fresh native construction input attempts excluded.
[Receipt](testing/sketch-parity-circle-default-leader-2026-09-09.md).

## September 9 — immediate dimension lock action

Unchanged keypad Lock now immediately adds/removes the measured driving size
without moving geometry; changed drafts disable the key. Actual stored state is
shown, with neutral icons. Ordinary numeric commit remains driving. Clean12/12
(9 unit + 3 UI), then a successful tint-only build and live inspection. Paired
line/circle action, draft cancellation, freed radial resize/history and gallery
reopen verified: clone Ø0.992/line0.793, native Ø1000/line1750.6361 retain locks.
First click away dismisses an editor in both apps; separate selection follows.
Rapid radial first attempt excluded; settled repeat counted. Wider numeric/visual
matrix and device artifact remain open.
[Receipt](testing/sketch-parity-dimension-lock-action-2026-09-09.md).

Publication verified: illustrated130 images, all3 final PNG hashes matched;
master38 images with final gallery-reopen and tint notes exported.

## September 9 — alternate Dimension entry for stored sizes

Constrain → Dimension used a suppressed candidate label when a stored size
already existed, leaving no visible keypad. It now reuses the matching stored
label/ID. Clean9/9 (7unit+2UI). Live circleØ1→Ø2, unchanged center, Undo/Redo
and gallery reopen with palette entry verified; native existingØ1000→Ø2000
center/history and final reopened closed-lock editor paired. Native reference
is size editing, not an identical alternate palette. Illustrated135 images/all5
new hashes and master38 final reopen note export-verified.
[Receipt](testing/sketch-parity-dimension-palette-2026-09-09.md).

## September 9 — independent coplanar sketch identity (f4319dd)

Paired native unselected Front entry creates03 independently of02; clone first-
coincident reuse incorrectly joined new geometry to1. Plane-based creation now
allocates a new identity; explicit named item/outline continuation is retained.
Corrected16/16 (12unit+4UI); initial missing-helper compilation failure ran no
tests. Live independent circle1/line2, named edit, independent visibility and
paired gallery reopen with hidden old/visible new sketch verified. Consumed/
overlapping selection/downstream variants remain open.
[Receipt](testing/sketch-parity-coplanar-identity-2026-09-09.md).

Illustrated142 images/all4 final hashes and master38 final note verified.

Inactive profile blue-fill gap now under separate focused regression4410;
rendering keeps all unselected profiles clear during sketching, while preserving
model-mode extrusion fills. No live post-fix claim yet.

## September 9 — inactive reference profile fill verified

Focused serial4410 completed clean6/6 (4 SketchIdentity unit + 2 Plane UI).
No runner remains. Fresh live Front circle1/line2: inactive circle clear during
Sketch2 editing; Exit restores profile fill; interior selection offers Extrude,
cancelled without creating a body. Gallery reopen retains two items and clear
reference while explicitly reopening2. Native reopened03 likewise shows old02
clear; normalized Front screenshot inspected. Reference color/style differences
remain outside this fill correction. Consumed/overlap/downstream cases remain open.

Illustrated145 images and all3 new PNG hashes verified by anonymous DOCX export;
master38 final reopen note verified. Evidence os3d-reference-fill-native-front.png,
os3d-reference-fill-final-reopen.png, os3d-reference-fill-extrude.png and exports
retained in workspace reports/openshape3d-core-sketch-milestone-2026-09-08/
transform-controls. No iPad-ready claim.

## September 9 — nested circle profile sample

## Final sampled nested-profile result

Native double-click view cube exposes default oblique view; reselect annulus
and click0mm badge. Typed500 and committed: Body02 with visible bore. Undo
removesBody02, Redo restores; gallery reopen retains body/bore. Clone Undo
removes its offset-hole solid, Redo restores; gallery reopen retains it in
oblique view. Images inspected. Native concentric and clone offset samples
are different geometries: paired result is nested-region/extrusion/history/
persistence behavior, not equal dimensions or complete topology acceptance.

Existing ProfileTests completed clean15/15, including through-hole ray probe,
/tmp/os3d-nested-profile-20260909.log/.xcresult, serial41439 completed0. No
implementation changes in this lane. Illustrated147 images with both final
reopen PNG hashes matched; master38 final15/15 note verified. Exports/evidence
copied to durable transform-controls report. Touching loops, tiny gaps,
duplicate edges, downstream rebuild and device artifact remain open.

[Receipt](testing/sketch-parity-nested-profiles-2026-09-09.md).

## September 9 — named consumed-source rebuild

## Final source-edit result

Both apps Undo restored the old source diameter and bore; Redo restored the
larger source/bore. Both gallery reopens retained enlarged solids. Native
Body02/Sketch03 and cloneExtrude/Sketch2 retained original ownership; no new
sketch was created by named entry. Broader visibility toggle cases remain open.
Existing history/profile-seed regression completed clean5/5 (2+3), serial70997,
/tmp/os3d-consumed-source-20260909.log/.xcresult. Unit tests terminated clone
app after the already captured final reopen; relaunch before more live work.
No code change in this lane.

Illustrated151 images and all4 new PNG hashes verified by DOCX export; master38
final5/5 and gallery-reopen note verified. Evidence/export retained in durable
transform-controls reports. This samples downstream bore rebuild, not full
Sweep/Loft/downstream smoke or all profile topology/device readiness.

[Receipt](testing/sketch-parity-consumed-source-2026-09-09.md).

## September 9 — visible gap closure / hidden-source control

Paired visible20px gap rejects profile selection; explicit closure produces a
profile, Undo/Redo removes/restores it and gallery reopen retains it. Controlled
hidden-source entry/Exit matches native; initial mismatch was differing state,
not a code defect. No new code/tests. Tiny tolerance, touching/duplicate/crossing
cases remain open. [Receipt](testing/sketch-parity-gap-closure-2026-09-09.md).
Publication pending; prior illustrated151/master38 verified.

Final publication: illustrated155 embedded images, all4 new closure/reopen
PNG hashes and corrected prose verified by DOCX export. Master38 retains final
reopen/visibility correction note. Export copies retained locally.

## September 9 — shared boundary / construction rendering

Paired adjacent regions select independently; construction divider merges the
regions. Fixed confirmed oversized model-unit construction dashes with viewport
8/4-point pattern for selected/unselected paths. Clean24/24 construction/profile
checks; live Front/oblique, regular/construction history and final reopen pass.
Multi-scale dash test automated-only: bridge scroll rejected. Curved phase,
point-touch, duplicates/tiny tolerance remain open. Illustrated160/all5 new
hashes and master38 final note export verified. [Receipt](testing/sketch-parity-touching-construction-2026-09-09.md).

## September 9 — duplicate straight boundary correction

Paired duplicate topedge preserved nativeprofile but removed cloneprofile.
Temporary profilegraph now collapses coincident straight boundaries, preserving
editableentities and firstboundaryowner; arcs/splines remain distinct. Initial
2testsfailed; corrected22profile/history/seed +27curve/entity checks passed in
separate cleanruns. Live savedprofile recovered; freshreverseoverlap extrudes;
pairedblockUndo/Redo and finalreopen pass. Earlierduplicate-only liveUndo remains
inconclusive. Partialoverlap/duplicatecurves/pointtouch/tinytolerance open.
Illustrated165 imageplacements/164uniqueassets (reusedidenticalimage), all5
evidencehashes and master38finalnote exportverified. [Receipt](testing/sketch-parity-duplicate-boundary-2026-09-09.md).

## September 10 acceptance inventory update

QA-04, QA-07, QA-08 and QA-09 finite recipes are passed after paired final repeats and publication.
Together with QA-55/QA-56, six cases are closed.
**6 passed / 0 failed / 1 device-blocked / 49 incomplete** (38 partial, 11
explicitly deferred), total56. Historical partial evidence remains above/in
receipts. No full UI parity or updated device candidate claim.
