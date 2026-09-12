# Core-sketch milestone: complete original acceptance map

Starting revision `cd0937d`; September 8, 2026. All 56 original cases retained.
Partial evidence is **not** a case pass. No complete case is promoted to covered by this reconciliation. All device tests remain pending. Existing audit remains unchanged.

| Case | Original scenario | Milestone lane | Current evidence / remaining work |
|---|---|---|---|
| QA-01 | Plane selection | Core — partial, not passed | Origin Front/Right/Top grid availability paired; offset/face/miss matrix open. |
| QA-02 | Entry method | Core — partial, not passed | Ground menu entry only; remaining routes open. |
| QA-03 | Camera angle | Core — partial, not passed | Origin Front/Right/Top normal entry/grid checked; full orbit/angle matrix open. |
| QA-04 | Empty entry | Core — passed | Paired Top/Front/Right empty Exit/two-stage Escape, hidden/visible reference preservation, corrected provisional Items/history and final gallery reopen verified on 0c8c268. Initial6/6 plus revised5/5; illustrated417/master38 export-verified. |
| QA-05 | Line chain | Core — passed | Fresh native A→B→C/Return/B-resume/intentional close/history/five-edge reopen agrees with retained exact-build clone sequence. Current serial3/3 on1fdb6a3; illustrated863/master38 verified, ten exact new hashes plus one visually verified Google-downsampled reopen image. |
| QA-06 | Line cancel | Core — passed | Paired Escape once/twice, Delete/Backspace, released-state Return/double-click, and Line→Arc switching preserve the intended committed geometry. History and gallery reopen are verified; current-tree closure regression is clean 5/5. Hover and physical input remain QA-21/QA-52. |
| QA-07 | Line raw aim | Core — passed | Finite near-horizontal above/below recipe across native/clone scales, signed/reverse and H/V supplements, independent Guide/Auto, history and final reopen verified at eb9b4ab. 35 distinct checks across runs; general snap/hover/device remains separate. |
| QA-08 | Diagonal rectangle | Core — passed | Finite four-quadrant, both sizing-order/lower-left anchor, selected-side/readout, history and saved-reopen recipe closed September10 at e9343a7. Relevant retained regression runs and paired evidence reconciled; illustrated624/master38 verified. Broader input/layout/device cases remain separate. |
| QA-09 | Center rectangle | Core — passed | Finite both-axis-order/center-preservation recipe plus four release directions, center Lock/migration, selected-side/corner lifecycle, history/reopen closed at e9343a7. Relevant29/30+corrected1/1 latest follow-up retained; illustrated624/master38 verified. No universal UI/device claim. |
| QA-10 | Three-point rectangle | Core — passed | Original rotated-baseline/perpendicular-height/each-stage-cancel recipe closed at5014cef with paired forward/reverse slopes, pending numeric/leaders, center/legacy controls, history/reopen. Final36/36; illustrated700/master38 closure note verified. Detailed three-point closure audit retains failures and input/import/device qualifications. |
| QA-11 | Concentric circles | Core — PASSED (September11 finite recipe) | Selected/unselected center distinction, gated saved center relationship, clear controls, paired history/reopen verified. Clean35/35 plus separate6/6; illustrated724. See concentric-closure-audit-2026-09-11.md. |
| QA-12 | Circle dimensions | Core — PASSED (September11 finite recipe) | Persisted Radius/Diameter preference, equivalent geometry, compact/unclipped leaders, reverse creation direction, armed/disarmed numeric edits, direct Unlock, Circle Escape, history and gallery reopen are paired live. Final current-tree closure 22/22; illustrated764/master38 export-verified. Physical Pencil/touch remains under QA-52. |
| QA-13 | Arc construction | Core — PASSED (September 11 finite recipe) | Prescribed endpoints/side, direct minor/semicircle/major construction, third-point/Return/chaining, two-stage cancellation, tangent transition and history are paired live. Final current-tree gate 63/63; persisted R/Ø-aware 90→360 conversion and Undo/Redo are covered. Hover remains QA-21 and physical input QA-52. See arc-closure-audit-2026-09-11.md. |
| QA-14 | Ellipse dimensions | Explicitly deferred | Advanced ellipse-axis coverage; remains in full audit, not passed. |
| QA-15 | Polygon | Core — PASSED (September 11 finite recipe) | Paired 5→65 count edit, exact radius, center/orientation retention, two-step Undo/Redo, profile availability and saved reopen verified. Corrected final current-tree regression 13/13; illustrated772/master38 export-verified. Native side-count badge is creation-only; physical input remains QA-52. |
| QA-16 | Spline | Explicitly deferred | Spline creation/editing; remains in full audit, not passed. |
| QA-17 | Text sketch | Explicitly deferred | Text sketch; remains in full audit, not passed. |
| QA-18 | Drawing on points | Core — PASSED (September 11 finite recipe) | Paired endpoint, line midpoint, existing-circle center, rectangle corner and top-face corner placement; history and clone reopen verified. Constraint-glyph input routing fixed at b19c041; final current-tree gate 13/13; illustrated786/master38 verified. Persistent linking and physical input remain separate lanes. |
| QA-19 | Snap categories | Core — partial, not passed | Raw acquisition-off and Grid-only paired; guidepoint combinations open. |
| QA-20 | Snap zoom | Core — partial | Screen-relative acquisition corrected; native near/far reference + two clone scales, clean37/37. Full zoom/grid matrix open. |
| QA-21 | Snap feedback | Core — partial, not passed | Native Endpoint hover captured; clone idle feedback automated-only, live pointer delivery unresolved. |
| QA-22 | 3D references | Explicitly deferred | Off-plane reference coverage; remains in full audit, not passed. |
| QA-23 | Selection state | Core — PASSED (September 11 finite recipe) | Paired exact endpoint versus short-edge midpoint, outline/profile highlight and blank deselection are reconciled; selected-outline Delete, one-step Undo and clone gallery reopen pass on the current tree. Clean 19/19 baseline. Illustrated publication verified at 796 unique placements with all ten new hashes once and no 786-asset predecessor loss; master roadmap note verified. |
| QA-24 | Multi-selection | Core — partial, not passed | Exact-tree selection baseline is clean 19/19, including three-body marquee/Delete/Undo and Select Through UI workflows. Connected rectangle double-click is paired; native Shift/additive input and independent live seeded-state recovery remain open. |
| QA-25 | Annotation off-state | Core — passed | Fresh paired none/one/several/disconnected saved-label ownership. Clone first+third hides intervening driver; native area selection proves disconnected owners without unrelated labels. Corrected final29/29 ondb230f8; illustrated852/master38 verified, eleven new hashes once/no841 loss. |
| QA-26 | Annotation on-state | Core — passed | Active/other/hidden scope, idle Exit, hidden re-entry and toggle persistence paired. Independent coplanar leak fixed2fdecd6; final29/29 plus changed live/gallery verification. Illustrated841/master38 export verified, six new hashes once and no predecessor loss. |
| QA-27 | Dimension type | Core — passed | Exact paired H30/V40/Absolute50, plain numeric driver replacement, on-label menu, Undo/Redo and gallery reopen verified on3016ac6. Final54/54; illustrated827/master38 export verified with predecessor preservation. Variable-linked/multiple-driver variants remain separate and unverified. |
| QA-28 | Dimension selection matrix | Explicitly deferred | Non-core multi-entity dimension coverage; remains in full audit, not passed. |
| QA-29 | Badge layout | Core — partial live pass | Portrait and landscape edge keypad usable; resize alignment fixed; right-palette/compact open. |
| QA-30 | Rectangle sequence | Core — PASSED (September 11 finite recipe) | Retained paired two-axis sizing plus a clean exact-tree 4/4 width→height numeric/system-keyboard, edge-clearance and history gate. Illustrated publication is verified at 800 unique placements; physical input remains QA-52. |
| QA-31 | Unit conversion | Explicitly deferred | Comprehensive unit formats; remains in full audit, not passed. |
| QA-32 | Expression evaluation | Explicitly deferred | Comprehensive variables/expression semantics; remains in full audit, not passed. |
| QA-33 | Invalid numeric input | Core — partial live pass | Paired zero/negative, empty/division/syntax, correction, click-away/Escape and history sampled Sept9. Selected polygon count2 refusal/3.5 recovery live; current invalid-input/history gate19/19. Native10001 enters unresolved busy processing, so clone10000 is defensive, not verified parity. Diagnosis illustrated803/master38 published; upper bound stays open. |
| QA-34 | Locked/unlocked value | Core — PASSED (September 11 finite recipe) | Locked versus one-time commit, rejected draft, direct Unlock, free resize, exact history and saved reopen are paired/current-tree verified. Final one-owner gate clean 29/29. Broader constraints/transforms/device remain separate cases. |
| QA-35 | Constraint rail | Core — PASSED (September 11 finite recipe) | Model availability matrix plus portrait/landscape disabled guidance, settings access, enabled application and glyph pass clean 30/30; retained paired contextual Lock/Unlock/history/reopen evidence reconciled. Constraint semantics remain QA-36/39. |
| QA-36 | Constraint types | Core — partial, live matrix incomplete | Clean 64/64 current-tree gate directly applies and restores all 11 relation families, with inference/persistence/rail coverage. Retained paired H/V, Lock, Parallel, tangent and concentric evidence exists; Equal Length/Radius and circle/two-line Symmetry now have paired history/reopen checkpoints (final90/90 and76/76, respectively); Perpendicular length/selection now has paired history/reopen and final80/80; remaining fresh all-type live sweep stays open. |
| QA-37 | Selection anchor | Core — partial, not passed | Diagonal/center/three-point numeric anchors and locked-endpoint drag sampled; full constrained matrix open. |
| QA-38 | Disconnect | Core — partial | Four-line edge separation/history/reopen paired; clean34/34. Midpoint/primitive/non-line cases and ring visual difference remain. |
| QA-39 | Conflict and point states | Core — passed | Finite under/fully-defined, point/entity Lock, refusal/rollback, attribution, history and reopen recipe closed September 11; clean 69/69 current-tree gate. |
| QA-40 | Keypad transitions | Core — partial, not passed | Retained paired click-away/tool/toggle/Exit/Escape/history/keyboard-mode evidence; clean 56/56 current-tree gate. Rotation/pan and full physical/system-keyboard matrix remain open. |
| QA-41 | Trim primitives | Core — partial, not passed | Paired line/circle and rectangle-edge samples; clean 37/37 line/circle/arc/rect/polygon, whole/boundary/history gate. Fresh paired arc/rect/polygon gestures remain blocked. |
| QA-42 | Trim curves | Explicitly deferred | Ellipse/spline trim; remains in full audit, not passed. |
| QA-43 | Trim references | Core — partial, not passed | Paired rectangle boundary/profile handoff plus clean 60/60 current-tree affected/surviving reference, profile invalidation and exact Undo gate. Fresh paired driven-reference/history gesture remains blocked. |
| QA-44 | Offset | Explicitly deferred | Offset completeness; remains in full audit, not passed. |
| QA-45 | Move/rotate/copy | Core — partial, not passed | Extensive paired exact-value/local-frame/Copy/Escape/history evidence plus clean 50/50 current-tree direct line/circle/rectangle and mixed line+circle Copy matrix. Fresh paired mixed-selection and compact-layout checks remain open. |
| QA-46 | Pattern | Explicitly deferred | Advanced linked patterns; remains in full audit, not passed. |
| QA-47 | Projection | Explicitly deferred | Projection linking; remains in full audit, not passed. |
| QA-48 | Coplanar sketch identity | Core — passed | Finite independent/new, named continuation, consumed-source edit/rebuild, hidden visibility, history and reopen recipe closed September 11; clean 9/9 current-tree gate. |
| QA-49 | Profile topology | Core — passed | Finite hole/touching/tiny-gap/duplicate/construction-crossing recipe closed September 11 from retained paired evidence and a clean 46/46 current-tree gate. Exhaustive curved intersections remain outside this bounded pass. |
| QA-50 | Sketch-to-solid | Core — passed | Finite exact extrusion/hole/consumed visibility/source rebuild/history recipe closed September 11 from retained paired evidence and a clean 15/15 current-tree gate. Advanced Sweep/Loft breadth remains separate. |
| QA-51 | Save/reopen | Core — passed | Finite geometry/constraint/variable/pattern/annotation/unit persistence recipe closed September 11 from retained paired reopen evidence and a clean 47/47 current-tree archive/UI gate. Physical-device lifecycle remains QA-52. |
| QA-52 | Touch and Pencil | Device-only pending | Physical Pencil/touch requires Jason’s actual device comparison; no simulator substitute. |
| QA-53 | Layout | Core — partial, not passed | Clean current-tree 51/51 covers portrait/landscape, toolbar handedness, panels, accessibility text, edge editors, rail and compact bar. Retained paired label/keypad/radial samples remain valid, but fresh handedness/large-text/panel comparison is capture-blocked and automated-only. |
| QA-54 | Keyboard | Core — partial, not passed | Clean current-tree 84/84 covers Single Key Action persistence, command routing/search UI, numeric focus/recovery, Return, Escape scopes and history. Retained paired keyboard evidence remains valid; fresh native preference switching and physical-key delivery remain unproven. |
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

Tap A-B-C; end open; resume from B; close intentionally. Issues: SK-09.
Result: **PASSED** for the finite desktop recipe, September11. Fresh native
complete sequence/history/reopen matches retained exact-build clone evidence;
current serial3/3 and863/38 publication verified. Bounded native200ms/1px presses
resolved instantaneous bridge click delivery; no physical input claim. See
[September11 line-chain receipt](testing/sketch-parity-line-chain-2026-09-11.md).

### QA-06 — Line cancel

Enter, Escape once/twice, Backspace, double-tap, tool switch. Issues: SK-09. Result: **PASSED** for this finite desktop recipe on September 11. Existing paired live evidence covers every route, committed-geometry preservation, one-step history, tool switching, and gallery reopen. The current-tree serial closure run passed clean 5/5. Pointer hover and physical input remain separate QA-21/QA-52 gates. See [line cancellation receipt](testing/sketch-parity-line-delete-2026-09-10.md).

### QA-07 — Line raw aim

Near-horizontal intent above/below tolerance at several zoom levels. Issues: SK-06; DM-14. Result: PASSED for this finite desktop/native-versus-simulator recipe, September10 at eb9b4ab. Paired near/outside at changed scales, signed/reverse direction, H/V supplements, Guide/Auto independence, history and final saved recovery verified. General snapping relationships, hover and physical input remain separate gates; no universal snap parity claim. Thirtyfive distinct relevant tests pass across retained runs. Evidence: testing/sketch-parity-line-guides-2026-09-10.md.

### QA-08 — Diagonal rectangle

**September10 closure:** PASSED for the finite recipe at `e9343a7`. Earlier partial notes below are historical and superseded only for this recipe. [Closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md) reconciles all required directions/orders, current presentation fixes, test failures/corrections, paired history/reopen and624/master38 verified publication. General layout, other entity/constraint cases and physical input remain separate gates.


All four drag quadrants; native anchor policy; exact width/height. Original first-anchor assumption superseded by paired native lower-left samples. Issues: SK-03; DM-11. Result: PARTIAL — mixed-quadrant sequential sizing, default leader sides, center translation/history and paired saved recovery now live verified September 10. Leader and translation groups each passed clean25/25; four-corner marker correction c634c30 final30/30 and center-only Lock35382d4 final31/31 with paired sizing verified. Direct center-padlock styling/action and asymmetric Lock/Unlock selection lifecycle now verified with final33/33 and paired history/reopen. Selected-free center halo additionally matched with1/1 and live comparison. Partial-edge supporting-line colors now match paired left/top Locks; final36/36, live Unlock/history and clone reopen passed. Native reopen retains Lock/corners but selection clearing remains unresolved in that capture. Side-Lock midpoint glyph removed after paired native visibility comparison; final31/31 and live contextual Unlock/history/reopen passed. Native unselected partial-Lock colors were subsequently recovered with actual-edge then blank selection. Remaining: reconcile finite recipe closure; halo/partial-edge/glyph publication recovered September10 through577 with predecessor-preserving exports. Native latest center-lock reopen recovered and passed after dismissing the retained test-crash dialog. Center relationships beyond Lock remain unsupported and are not generalized as parity. Evidence: testing/sketch-parity-diagonal-anchors-2026-09-08.md and testing/sketch-parity-diagonal-matrix-2026-09-10.md. Historical sign-out resolved; recovered report577/master38 verified.

### QA-09 — Center rectangle

**September10 closure:** PASSED for the finite recipe at `e9343a7`. Earlier partial notes below are historical and superseded only for this recipe. [Closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md) reconciles all required directions/orders, current presentation fixes, test failures/corrections, paired history/reopen and624/master38 verified publication. General layout, other entity/constraint cases and physical input remain separate gates.


Origin anchor; center fixed under both dimensions. Issues: SK-03. Result: PARTIAL — prior height-first and up-left width-first paired; September10 right-up width/height halves also preserve center. Release center halo/direct Lock now verified with26/26 and paired history/reopen. Center-specific leaders corrected with final27/27 and allfour controlled release directions; paired up-left two-axis sizing/history/reopen verified. Four-decimal mm/residual readout correction and unchanged-accept Undo now paired verified;36unit and corrected3/3 after retained numeric failure. Rotated center-lock migration, corner rotation/reselection, parallel-side editors, adjoining corner leaders, history selection and corner-Lock conflict/recovery are now paired, regression-tested and published through546 placements; corner editor open/cancel/refusal/success lifecycle is paired with final14/14. Selected corner outline/hollow markers, allfour single-edge triple readouts and shared-dimension editors now match sampled native. Successful side commit clearsedge/handle and retainsparallelreadouts through history, paired with clean14/14. Remaining: reconcile finite recipe closure with older evidence/publication backlog; broader exact-UI/device equivalence not claimed. Earlier publication backlog remains separately tracked. Evidence: testing/sketch-parity-center-width-first-2026-09-08.md; testing/sketch-parity-center-matrix-2026-09-10.md. Google editing recovered; latest567 placements/master38 export-verified.

### QA-10 — Three-point rectangle

**September10 closure:** PASSED for the original finite recipe at `5014cef`. [Closure audit](testing/sketch-parity-three-point-closure-audit-2026-09-10.md) reconciles paired construction/cancellation and current presentation, clean36/36, history/reopen and700/master38 export verification. Earlier partial notes below remain historical. General layout, keyboard delivery, system-picker import and physical input are separate open work.

Rotated baseline, perpendicular height, cancel at each stage. Issues: SK-03. Result: PARTIAL — historical two-slope anchor/reselection work retained; September10 pending reversed-baseline cancellation/readout paired and corrected. Clean29/29 plus separate3/3; report631/master38 verified. Pending baseline numeric84ca852 and committed Undo disarming c154574 pushed/live-compared; initial23/23+final3/3 and4/4, report642/master38. Fresh center control fixed/paired live, report653/master38; legacy group recovery and remaining completion directions open. Evidence: testing/sketch-parity-three-point-leaders-2026-09-08.md and testing/sketch-parity-three-point-matrix-2026-09-10.md.

### QA-11 — Concentric circles

**September11 closure:** PASSED for the original finite recipe. [Closure audit](testing/sketch-parity-concentric-closure-audit-2026-09-11.md) reconciles selection/input, connected movement, history/reopen and report724. Earlier partial notes below remain historical.

New circle starts at an unselected existing center without edit interception; a freshly selected center remains a move control. Issues: SK-04. Result: PASSED for the finite desktop/simulator recipe at78c7c7c. Selected-center movement, explicit Lock, matched Guidepoints/Auto-Constrain center connection, unobstructed connection glyph, both-circle history and paired saved reopen verified. Clean35/35 plus separate6/6 follow-up; illustrated724/master38 closure verified. See testing/sketch-parity-concentric-closure-audit-2026-09-11.md. Physical input remains unverified. Sole owner: dedicated parity session.

### QA-12 — Circle dimensions

R versus diameter, creation/edit/reopen, no factor-of-two error. Issues: DM-04. Result: PARTIAL. Preference/rail correction944ae3e passed21/21 and pairedR↔Ø edits/history/reopen. Follow-up disarmed numeric selection cleanup passed11/11 after documented center-versus-rim fixture failures; fresh paired commit/Undo/Redo and final nativeR4/cloneØ2 reopen match. Illustrated743/master38 verified. Fresh Always Radius compact leader, armed numeric badge/direct Unlock and Unlock history now paired, clean12/12+10/10; nativeR3/cloneR0.3 final reopen and756/master38 publication verified. Reverse creation and armed cancellation remain. Evidence: testing/sketch-parity-circle-annotation-modes-2026-09-11.md. Owner: dedicated parity session.

### QA-13 — Arc construction

Prescribed endpoints/side, major/minor, tangent transition, cancel. Issues:
SK-10. **September 11 finite-recipe result: PASSED.** Endpoint/default side,
third-point commit, shared-endpoint chaining, Return completion, two-stage
cancellation, tangent transition and direct minor/semicircle/major boundaries
are paired live. Native sampled 90/180/220 degrees; the differently scaled
clone sampled 81.91/176.03/214.93 degrees and restored the major profile through
Undo/Redo. The current-tree numeric workflow additionally verifies R/Ø-aware
90→360 conversion, Undo back to the 90-degree arc and Redo to the selected full
circle. Final exact-tree regression passed cleanly 63/63 in one serial run.
Pointer hover belongs QA-21 and physical Pencil/touch QA-52; neither remains a
QA-13 closure condition. See the
[arc closure audit](testing/sketch-parity-arc-closure-audit-2026-09-11.md) and
its linked paired receipts.

### QA-14 — Ellipse dimensions

Major/minor radii, rotation, independent edit and lock. Issues: DM-05. Result: NOT RUN. Evidence/owner: pending.

### QA-15 — Polygon

Side count boundaries, radius semantics, orientation and exact input. Issues:
SK-02; DM-10. **September 11 finite-recipe result: PASSED.** Native and clone
both retained center, radius, and first-vertex direction through 5→65 count
editing; exact radius edits, two-step Undo/Redo, profile availability, and saved
recovery are paired live. The model boundary test covers 2 refusal, recoverable
divide-by-zero, 3.5→3, 65 acceptance, 10001 refusal without history, stable
identity, and atomic Undo/Redo. Final corrected current-tree regression is clean
13/13. Two earlier clean 12/12 runs omitted the boundary method because their
selectors named the file/wrong declared class and are not represented as
boundary coverage. Illustrated772/master38 publication is export-verified.
Shapr3D's side-count badge is creation-only; reopened count editing is not a
reference requirement. See
[polygon closure audit](testing/sketch-parity-polygon-closure-audit-2026-09-11.md).

### QA-16 — Spline

Fit points, finish/reopen/edit/close; control mode separately. Issues: SK-11. Result: NOT RUN. Evidence/owner: pending.

### QA-17 — Text sketch

Placement, font/height, cancel, profile and reopen; compare editing affordance. Issues: ED-09/10. Result: NOT RUN. Evidence/owner: pending.

### QA-18 — Drawing on points

New shapes at endpoints/midpoints/centers/face corners. Issues: SK-04. Result:
PASSED for the finite placement recipe. Paired endpoint, line-midpoint,
existing-circle-center, rectangle-corner, and top-face-corner initiation plus
geometry-specific Undo/Redo are verified; the clone gallery retains the
face-corner result. Final regression 13/13. Persistent point relationships,
hover, topology editing, and physical Pencil/touch are separate cases. See
[drawing-on-points audit](testing/sketch-parity-drawing-on-points-2026-09-11.md).

### QA-19 — Snap categories

Each category on/off independently; all off truly free. Issues: SK-05. Result: NOT RUN. Evidence/owner: pending.

### QA-20 — Snap zoom

0.1x/1x/10x, tiny and large parts, visible grid agreement. Issues: SK-06. Result: PARTIAL. Screen-relative radius37/37; near/far at original and1.48x clone scales, native reference. Full zoom/grid matrix open; see preplacement-snap receipt.

### QA-21 — Snap feedback

Endpoint versus midpoint versus center versus edge, overlapping candidates. Issues: SK-05/06. Result: PARTIAL. Native Endpoint hover captured; clone idle feedback25unitpasses but live unresolved. Other feedback/overlap cases open.

### QA-22 — 3D references

Off-plane point guides versus actual coincidence; avoid false constraints. Issues: SK-05. Result: NOT RUN. Evidence/owner: pending.

### QA-23 — Selection state

**September 11 closure:** behavior passes for the finite endpoint/midpoint/
outline/profile and blank-deselect recipe. The selected target matches the next action; current-
tree outline Delete removes only that sketch, one Undo restores it, and gallery
reopen retains the profile. Current-tree regression is clean 19/19. The
illustrated report is export-verified at 796 unique placements: all ten new
hashes occur once and all 786 predecessor assets remain. The master roadmap
retains 38 media and one dated closure note. See
[selection-state closure audit](testing/sketch-parity-selection-state-closure-2026-09-11.md).

Point/edge/fill/sketch/body; tool armed versus inactive; blank deselect. Issues:
ED-07. Result: PASSED for the finite desktop/simulator recipe above. Additive
selection, hover, dimension-selection breadth and physical input remain QA-24,
QA-21, QA-28 and QA-52 respectively.

### QA-24 — Multi-selection

September 11 checkpoint: clean 19/19 current-tree baseline covers additive model
routing, window/crossing selection, filters, three-body atomic Delete/Undo, and
Select Through. The test seed did not persist for independent live inspection,
and native Shift/additive input is still unverified, so the case remains partial.
See [multi-selection checkpoint](testing/sketch-parity-multiselection-checkpoint-2026-09-11.md).

Shift/additive, connected double-tap, overlapping geometry, item selection. Issues: ED-07. Result: NOT RUN. Evidence/owner: pending.

### QA-25 — Annotation off-state

Nothing selected, one entity, several entities, disjoint same-sketch geometry.
Issues DM-01/02. Result: **PASS** for saved-annotation ownership on `db230f8`.
Native10/12/8 and clone1/2/3 fixtures are deliberately separate scales/angles.
Both none/one/twoDisconnected/allthree states are paired; clonefirst+third
suppressesintervening2. Native narrowerwindow selectedmiddleendpoint too and
is not counted as exclusion. Syntheticcandidate labels remain QA28.
Initial28/29 UI failure had offscreen20mmfixture; FitView and explicitOFF
preference preserve assertions. Focused1/1 then correctedcombined29/29 clean,
zero failures/skips. Illustrated852 unique assets, elevennewhashesonce, no841
predecessorloss; master38/onenote/noloss. Hardware input remainsQA52.
See [annotation off-state checkpoint](testing/sketch-parity-annotation-off-state-checkpoint-2026-09-11.md).

### QA-26 — Annotation on-state

Active/other/hidden sketches; exit and re-entry; toggle persistence. Issues:
DM-01/02. Result: **PASS** for the finite recipe on `2fdecd6`. Native independent
coplanar Sketch08 suppresses Sketch06's50mm label with AlwaysShowON; Exit restores.
Changed clone saved-gallery reopen retains2mm, independent Sketch2 suppresses it,
Exit restores with unchanged geometry. Earlier paired hidden/re-entry, toggle and
cross-plane evidence retained. Focused21/21, then final combined29/29 clean,
zero failures/skips. Illustrated841 unique images, six new hashes exactly once,
zero835 predecessor loss; master38 and one new note, zero loss. No physical-device
claim. See [annotation on-state checkpoint](testing/sketch-parity-annotation-on-state-checkpoint-2026-09-11.md).

### QA-27 — Dimension type

Sloped 3-4-5 line: horizontal 30, vertical 40, absolute 50. Issues: DM-03.
Result: **PASS** for the finite exact-size recipe on `3016ac6`. Native and
changed clone show H30/V40/Absolute50 on unchanged geometry, including the
plain numeric driving state. Label-menu type changes preserve one driver in
place and clear selection without a keypad. Paired Undo/Redo and gallery reopen
are verified; final combined regression54/54, zero failures/skips. Illustrated
export827 unique media (ten new hashes once, no817 predecessor loss); master38
with one closure note and no media loss. Formula-linked/multiple-driver
variants remain separately unverified, not included in this pass. See
[adaptive dimensions checkpoint](testing/sketch-parity-adaptive-dimensions-checkpoint-2026-09-11.md).

### QA-28 — Dimension selection matrix

Line pair, point pair, point+line, curve pair, ambiguous mixed selections. Issues: DM-13. Result: NOT RUN. Evidence/owner: pending.

### QA-29 — Badge layout

Dense values, overlaps, manual reposition if supported, camera zoom. Issues: DM-06/07. Result: NOT RUN. Evidence/owner: pending.

### QA-30 — Rectangle sequence

Width then height via keyboard and touch, both at screen edge. Issues: DM-11.
Result: **PASSED** for the finite desktop recipe on September 11. Retained paired
two-axis sizing is supplemented by one clean exact-tree 4/4 gate covering width
then height through numeric and system keyboards, near-screen-edge reachability,
adjacent-control retention, first-digit replacement, commit and Undo/Redo.
Anonymous export verifies 800 unique illustrated placements, exactly four new
closure assets and no predecessor loss. Physical touch/Pencil remains QA-52;
dense labels, manual reposition and camera zoom remain QA-29. See
[rectangle sequence closure](testing/sketch-parity-rectangle-sequence-checkpoint-2026-09-11.md).

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

Driving versus one-time size edit; geometry drag after unlock; undo. Issues:
DM-14. Result: **PASSED** for the finite desktop recipe on September 11.
Retained paired driven-refusal, direct Unlock, free-resize, history and saved
reopen evidence is backed by a clean 29/29 current-tree serial gate. Broader
constraint combinations, transforms and physical input remain separate cases.
See [locked-value closure](testing/sketch-parity-locked-value-closure-2026-09-11.md).

### QA-35 — Constraint rail

Enablement for each selected combination; settings access; discoverability.
Issues: SK-01/02. Result: **PASSED** for the finite desktop rail recipe on
September 11. The model availability matrix and portrait/landscape rail workflows
pass clean 30/30, supplemented by retained paired contextual Lock/Unlock,
history and reopen evidence. Constraint correctness remains QA-36/39. See
[constraint rail closure](testing/sketch-parity-constraint-rail-closure-2026-09-11.md).

### QA-36 — Constraint types

H/V, parallel, perpendicular, coincident, midpoint, tangent, concentric, equal,
symmetry. Issues: DM-14. Result: **PARTIAL** — all 11 relation families now have
direct apply/solve/Undo/Redo/serialization coverage in a clean 64/64 gate.
Equal Length/Radius and circle/two-line Symmetry now have fresh paired
application/history/reopen evidence. Final gates90/90,64/64 and76/76 support
those checkpoints. Perpendicular length and selection cleanup has paired
application/history/reopen evidence and final80/80. Midpoint selection cleanup now has paired application/history/reopen and
final82/82; its free-target anchor variant remains open. Remaining all-type
live sweep is still incomplete. See
[constraint types checkpoint](testing/sketch-parity-constraint-types-checkpoint-2026-09-11.md).

### QA-37 — Selection anchor

First/Last, reverse order, existing locks override, repeated solve stability. Issues: DM-08. Result: **PARTIAL** — preference, ordered selection, transient anchoring, history, persistence and portrait/landscape settings pass a clean 44/44 gate. Fresh paired gestures remain live-input blocked. See [selection-anchor checkpoint](testing/sketch-parity-selection-anchor-checkpoint-2026-09-11.md).

### QA-38 — Disconnect

Endpoint and midpoint connections, unrelated constraints survive, undo. Issues: DM-09. Result: **PARTIAL**. Four-line edge Disconnect/move/history/reopen is paired. Midpoint, explicit circle-center connection and primitive-rectangle diagonal-corner semantics now preserve geometry/dimensions/unrelated constraints and history in a clean 58/58 gate; those new cases still need paired live evidence. See [Disconnect receipt](testing/sketch-parity-disconnect-2026-09-08.md).

### QA-39 — Conflict and point states

Under/fully defined, lock point versus entity, refusal and attribution. Issues:
DM-14. Result: **PASSED** for the finite desktop recipe on September 11.
Retained paired point/entity Lock, conflict refusal with unchanged geometry,
Unlock, history and reopen evidence is backed by a clean 69/69 current-tree
serial gate covering state classification, rollback and specific attribution.
The incomplete all-relation live sweep remains QA-36; physical input remains
QA-52. See [conflict and point states closure](testing/sketch-parity-conflict-point-states-closure-2026-09-11.md).

### QA-40 — Keypad transitions

Another/same tool, off, blank tap, Escape, undo, exit, rotate, pan. Issues: SK-12;
DM-12. Result: **PARTIAL**. Retained paired tool/blank/Escape/history and
keyboard/keypad-mode evidence is supplemented by a clean 56/56 current-tree gate.
The initial 54-pass/2-fail run exposed two preference-contaminated model fixtures;
the prerequisites were isolated and the complete set reran clean. Fresh paired
rotation/pan, compact and physical/system-keyboard input remain open. See
[keypad transition checkpoint](testing/sketch-parity-keypad-transitions-checkpoint-2026-09-11.md).

September10 supplement: `1d28849` fixes software-keyboard occlusion with clean2/2
UI tests asserting field/commit above actual keyboard. Live portrait invalid draft,
landscape recovery/commit and saved-source reopen verified. Native Mac keyboard-only
field remains visible; no native-iPad equivalence claim. `ef27d62` corrects dark-UI
annotation contrast and pending material/font; three builds and live paired style
checks, not new automated tests. Illustrated353/master38 verified. Pan/compact and
physical routes remain open, so QA40 is not closed.

### QA-41 — Trim primitives

Line/circle/arc/rect/polygon, boundary versus whole deletion. Issues: ED-03/04.
Result: **PARTIAL**. Retained paired line/circle span and rectangle-edge evidence
is supplemented by a clean 37/37 current-tree primitive/lifecycle/import/UI gate.
Arc and polygon whole-removal plus polygon-edge Undo are now explicit. Fresh
paired arc/rectangle/polygon gestures remain input-blocked, so automated coverage
does not close the case. See
[Trim primitives checkpoint](testing/sketch-parity-trim-primitives-checkpoint-2026-09-11.md).

### QA-42 — Trim curves

Ellipse bounded span; spline capability separately; preserve shape. Issues: ED-03. Result: NOT RUN. Evidence/owner: pending.

### QA-43 — Trim references

Dimensioned/constrained geometry, downstream profile, full undo restoration.
Issues: ED-04. Result: PARTIAL. Retained paired evidence shows a rectangle
boundary removed, its open U profile no longer selectable for extrusion, an
unaffected closed profile still usable, and a surviving side readout retained.
The current tree passes a clean serial 60/60 Trim/reference/profile/import/UI
gate. A production endpoint-based driving dimension on the removed span is
dropped; an unrelated dimension, constraint and construction line survive; the
profile opens; Undo restores the exact sketch, closed profile and valid refs.
The initial focused fixture incorrectly used a documented legacy whole-line ref
and failed 0/1 before correction; no product source changed. Fresh paired
driven-reference and full history gestures remain supported-input blocked, so
automation is not promoted to live parity. Evidence:
[Trim references checkpoint](testing/sketch-parity-trim-references-checkpoint-2026-09-11.md).

### QA-44 — Offset

Single/Chain, nested loop, sign flip, zero/invalid offset, cancel. Issues: ED-11. Result: NOT RUN. Evidence/owner: pending.

### QA-45 — Move/rotate/copy

Exact values, constrained entities, mixed selections, copy on/off, cancel.
Issues: ED-08. Result: PARTIAL. Retained paired evidence covers exact typed axes
and rotation, local-frame re-edit, free and constrained circle/arc behavior,
Copy, Escape, history, accepted-operation reopen and line controls. The current
tree passes a clean serial 50/50 solver/UI gate, now including direct line,
circle and rectangle movement plus a mixed line+circle Copy-off/Copy-on identity
and two-step history matrix. The initial 48/49 baseline failure used free-label
placement as a geometry proxy; a corrected center-control assertion passed 1/1.
The mixed fixture's first 0/1 run found only 8e-11 solver roundoff; exact identity
and history assertions were retained while computed coordinates use 1e-8. No
product source changed. Fresh paired mixed-selection gestures and compact-layout
comparison remain open, so automation is not promoted to live parity. Evidence:
[Move/rotate/copy checkpoint](testing/sketch-parity-move-rotate-copy-checkpoint-2026-09-11.md).

### QA-46 — Pattern

Open/closed selection, linear/circular, quantity/spacing edit, source edit, unlink. Issues: ED-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-47 — Projection

Edge/face/sketch selection, linked/unlinked, source change, cancel. Issues: ED-05. Result: NOT RUN. Evidence/owner: pending.

### QA-48 — Coplanar sketch identity

Create independent, continue existing, edit named item, hidden consumed sketch. Issues: ED-06/10. Result: **PASS (finite desktop recipe)**. Retained paired native/clone evidence covers independent creation, explicit named continuation, hidden/visible identity, consumed-source bore rebuild, Undo/Redo and gallery reopen. Current-tree identity/profile/rebuild/UI gate passed clean 9/9. Overlapping fill hit precedence stays under selection/profile topology rather than identity. Evidence: `testing/sketch-parity-coplanar-identity-closure-2026-09-11.md` plus the September 9 identity and consumed-source receipts.

### QA-49 — Profile topology

Hole, touching loops, tiny gap, duplicate edge, construction crossing. Issues: ED-09. Result: **PASS (finite desktop recipe)**. Retained paired evidence covers gap closure, nested holes, shared/point-touch, duplicate/partial-overlap/crossed straight boundaries, construction exclusion, history and reopen. Current-tree profile/construction/entity/UI gate passed clean 46/46. Exhaustive curved-curve splitting remains outside this bounded pass. Evidence: `testing/sketch-parity-profile-topology-closure-2026-09-11.md` and linked September 9 topology receipts.

### QA-50 — Sketch-to-solid

Exact extrude, correct hole, consumed sketch visibility, edit/rebuild, undo. Issues: ED-09. Result: **PASS (finite desktop recipe)**. Retained paired evidence covers closed and nested profiles, consumed-source bore rebuild, visibility, Undo/Redo and gallery reopen. Current-tree profile/feature-graph/cut/history/UI gate passed clean 15/15. Advanced Sweep/Loft breadth remains separate. Evidence: `testing/sketch-parity-sketch-to-solid-closure-2026-09-11.md` plus the downstream, nested-profile and consumed-source receipts.

### QA-51 — Save/reopen

Geometry, constraints, variable references, pattern links, label state and units. Issues: ED-10. Result: **PASS (finite desktop recipe)**. Retained paired reopen evidence covers core sketch geometry, numeric state, history and consumed-source workflows. A clean current-tree 47/47 archive/UI gate covers cold gallery duplicate/open, reference remapping, constraint/dimension serialization, variables, linked patterns, annotation state, settings and units. Advanced-feature/device lifecycle breadth remains separate. Evidence: `testing/sketch-parity-save-reopen-closure-2026-09-11.md` and linked retained reopen receipts.

### QA-52 — Touch and Pencil

Palm, finger navigation during drawing, Pencil handles, no ghost strokes. Issues: SK-13. Result: NOT RUN. Evidence/owner: pending.

### QA-53 — Layout

Portrait/landscape, left-handed, Items/History open, large text, screen edges. Issues: SK-14. Result: **PARTIAL**. A clean current-tree 51/51 gate covers both orientations, left/right toolbar and constraint-rail placement, Items/History panels, accessibility-extra-extra-extra-large text, lower keyboard and side-rail editor clearance, diameter target reachability, and compact landscape controls. Retained paired label/keypad/radial evidence covers previously compared states; fresh handedness, large-text, and panel permutations remain automated-only because both Peekaboo window capture and direct window capture are blocked. Evidence: `testing/sketch-parity-layout-checkpoint-2026-09-11.md`.

### QA-54 — Keyboard

Hotkey versus search preference, focus in number field, Escape scope, undo/redo. Issues: SK-09/12; DM-12. Result: **PARTIAL**. A clean current-tree 84/84 gate covers persisted Single Key Action, command catalog/dispatch/search, number-field seed and invalid-expression focus recovery, keypad switching, click-away/tool-switch commit, Return completion, tool-specific Escape scopes and history. Retained paired native/clone keyboard workflows remain valid. Fresh native preference switching and physical hardware-key delivery remain unproven; the latter belongs QA-52. Evidence: `testing/sketch-parity-keyboard-checkpoint-2026-09-11.md`.

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

### September10 QA10 closure inventory

Seven passed (QA04/07/08/09/10/55/56), zero failed, one device-blocked (QA52),48 incomplete (37partial11deferred), total56. QA11 sampled result still needs finite closure review.

### September 11 QA12 finite closure

QA11 and QA12 are now finite-recipe passes. Radius and Diameter preference covers
creation, conversion, numeric editing, reverse release direction, compact
selected-state presentation, direct Unlock, Circle Escape, Undo/Redo and gallery
reopen in paired native/clone live checks. The exact QA12 closure tree passed one
clean 22/22 combined regression. The earlier 11-model-pass/1-XCTest-keyboard-
delivery failure is retained and was not relabeled as an automated UI pass; the
same build's Escape product route passed through Peekaboo. Illustrated
publication contains 764 placements with all six closure hashes exactly once and
no predecessor loss; the master retains 38 media and one closure note.

Inventory is **9 passed / 0 failed / 1 device-blocked / 46 incomplete** (35
partial, 11 explicitly deferred), total 56. Updated device installation and
physical Pencil/touch remain unverified; immutable 05be744 IPA is unchanged.

### September 11 QA-15 finite closure

QA-15 is now a finite-recipe pass after paired count/radius, orientation,
history, profile, and reopen verification. The corrected final combined run is
clean 13/13. Illustrated publication contains 772 placements with all eight new
hashes once and no loss from the 764-image QA-12 export; the master retains 38
media and one QA-15 note.

Inventory is **10 passed / 0 failed / 1 device-blocked / 45 incomplete** (34
partial, 11 explicitly deferred), total 56. Updated device installation and
physical Pencil/touch remain unverified; immutable 05be744 IPA is unchanged.

### September 11 QA-27 finite closure

Exact sloped-line H30/V40/Absolute50, numeric driver type conversion, paired
history and saved reopen close QA27 on3016ac6 with final54/54 and verified
827-image illustrated/38-media master publication. Inventory: **23 passed /
0 failed / 1 device-blocked / 32 incomplete**, total56. No device installation
or formula-linked/multiple-driver parity is claimed.

## September 11 QA-26 closure inventory

QA26 closes on2fdecd6 with clean29/29 and paired independent coplanar scope,
saved reopen, Exit and retained toggle/hidden/re-entry evidence. Publication
841/38 verified. Inventory: **24 passed / 0 failed / 1 device-blocked /
31 incomplete**, total56. Updated physical iPad build/install remains pending.

## September 11 QA-25 closure inventory

QA25 finite off-state recipe closes after fresh paired selection evidence,
corrected29/29 and852/38 publication verification. **25 passed / 0 failed /
1 device-blocked / 30 incomplete**, total56. No updated physical installation.


## September11 QA-05 closure inventory

Fresh native complete chain/history/reopen plus retained clone proof andcurrent
serial3/3 close QA05. Illustrated863/master38 verified with no predecessorloss.
**26 passed /0 failed /1 device-blocked /29 incomplete**, total56. iPad unchanged.
