# Sketch parity implementation ledger

Started 2026-09-07 from `88b0478d873ffc5efe71f086f84f529b6ca032a4`.

This is the implementation follow-through for the September 6 audit, not a claim that every suspected mismatch is a confirmed defect. The audit has 42 records: 19 confirmed gaps, 8 code risks requiring A/B, and 15 verification investigations.

## First implementation: selection, snapping and editor lifecycle

- **DM-01:** Plain model-mode outline taps select visible sketch geometry and recover its committed dimensions. Profile interiors retain extrusion routing. Ray picking respects nearer bodies/images and hidden sketches.
- **DM-02:** With Always Show off, filter individual dimensions/constraints by selected entities or point references. Explicitly selected glyphs and dimensions being edited stay visible. Opening an external dimension preserves its defining selection.
- **DM-16:** Dated corrections distinguish current defaults from historical entries and withdraw the mistaken ten-tool 2D Drawings requirement.
- **SK-12 / part of DM-12:** Clear pending numeric input when toggling a drawing tool off, exiting sketch mode, selecting other geometry, or starting another viewport stroke. Switching tools already cleared it.
- **SK-05, partial:** Persistent Grid, Sketch Guidepoints, Face Guidepoints, and Snapping Hints controls in Settings and the constraint sheet. Grid-off also disables along-face-edge quantization and translation grid capture; guidepoint-off disables near-start chain capture. Point inference/drop-to-weld respects guidepoint preferences and Auto-Constrain. Off-plane 3D guidepoints and independently configurable sketch guidelines remain open.

No new geometry storage format; model changes still use existing undoable document commands. Defaults preserve prior snapping behavior. Original checkout remains untouched.

## Second implementation: rectangle construction and drawing intent

- **SK-01:** Adaptive opposite-side constraint rail: seven common relations, disabled-state prerequisites, one-tap settings, and remaining relations in More. Compact windows fall back to a menu. Existing Constrain palette group remains available.
- **SK-02, partial:** “Rect” now reads “Rectangle”; rectangle subtype selection is explicit. Other palette vocabulary/extension hierarchy remains open.
- **SK-03, partial:** Diagonal, center and three-point construction, stage-specific guidance, anchor marker, preview/readouts, cancel, and atomic rectangle undo. Three-point rectangles persist as four lines with closure/parallel/perpendicular constraints; no storage migration. Center construction reflects the drag about the initial center, but subsequent dimension-edit anchor preservation and complete typed two-axis workflows are still open.
- **SK-04, partial:** Armed drawing tools own new strokes on existing geometry; toggle the tool off to manipulate entities or the gizmo. Selection gizmo/copy affordances are hidden while drawing. Pencil/mouse-specific parity still needs direct A/B.
- **SK-06, partial:** Outline acquisition uses 16 screen points and control-point acquisition uses 24, without old model-unit floors. Zoomed small-profile interiors remain extrudable and short-line middles are not swallowed by endpoint targets. Snap capture and grid resolution remain open.

Verification includes a combined regression run and a targeted annotation-spacing correction rerun; see [rectangle/constraint receipt](testing/sketch-parity-rectangles-2026-09-07.md).

## Direct reference verification — 2026-09-07

Both apps were operated live after desktop unlock. [Paired workflow receipt](testing/sketch-parity-live-2026-09-07.md) confirms diagonal rectangle anchor drift, sketch-entry camera, post-draw line annotation and keypad differences. Center-rectangle one-axis width anchoring and circle-at-corner drawing matched in the tested cases. Clone live Undo remains an investigation; automated tests are not reference sign-off.

## Noon follow-through

[Illustrated live Google Doc](https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit): 16 embedded screenshots, public-link reader access verified. **SK-07 partial fix:** sketch entry now automatically aligns to the chosen plane. Build and one focused center-rectangle UI regression passed without manual Look at Sketch. Fresh direct A/B and all-plane coverage remain open because desktop access is currently locked.

## Locked-desktop follow-through: rectangle sizing

New axis-aligned rectangles now retain center/first-corner intent through save/reload and creation undo/redo. Direct diagonal width/height edits prefer the original corner; explicit constraints override that preference if incompatible. Legacy rectangles keep their previous behavior. [Anchor implementation and verification](testing/sketch-parity-rectangle-anchors-2026-09-07.md). The combined run passed 19 tests (11 unit + 8 UI), with no failures or skips; fresh live sign-off remains pending unlock.

## Evening paired recheck and numeric-input corrections in progress

[Live recheck receipt](testing/sketch-parity-live-recheck-2026-09-07.md): paired horizontal line-release/readout and down/right diagonal half-width anchor cases match. Native center half-height retained its center; clone height editing exposed a keypad/constraint-rail obstruction before center sign-off. Rectangle automatic keypad and seeded-value append mismatch also confirmed live.

Corrections implemented and tested: axis-aligned rectangle readouts without auto-keypad, selected initial numeric value, full-editor placement clear of side chrome. Combined regression 18/20 passed; both failing inferred-tap tests passed with explicit visible-center taps matching the live input (20 distinct checks across runs, not one clean combined run). Fresh live clone center height then width edits preserve the center and the keypad clears the rail; paired native center sizing also preserves the center. All directions, compact/landscape/left-handed/system-keyboard and Pencil remain open. Illustrated Google Doc contains both interim findings and post-fix addendum; local receipt tracks image export verification.

## Verification

- Second batch: **60 distinct tests verified** across combined regression (58/60 passed) and final targeted correction (9/9 passed, including both repaired failures). This is not one clean combined run; see [second-batch receipt](testing/sketch-parity-rectangles-2026-09-07.md).

- Build-for-testing: passed on Xcode/iOS 26.5, iPad Pro 13-inch (M5) simulator.
- Focused pure tests: **40 passed, 0 failed** (AppSettingsTests, FaceSnapTests, SnapKindTests, SketchParityFoundationTests).
- Final combined run: **40 unit + 7 UI tests passed, 0 failures** on 2026-09-07. See [verification receipt](testing/sketch-parity-foundations-2026-09-07.md).
- No Pencil, real-device, portrait/landscape matrix, or full 56-case audit QA sign-off implied.

## Full issue queue

The original Google Docs retain the reproduction steps, reference evidence, target behavior and acceptance criteria. Entries below preserve the full queue so this first batch does not silently narrow the task.

[Master audit roadmap](https://docs.google.com/document/d/1LyptlUULQ6e4yWiBz9QBMgxvZKoft6bhAhISfRvHXdE/edit) · [Sketch workflow](https://docs.google.com/document/d/1g19SoYqNt1zQ4_nFguoa-hj8p7y6eGVPVrNJJy8uxnw/edit) · [Dimensions](https://docs.google.com/document/d/1xg-Puj2BHGHEEkWAPiDToSV8nvuxHh22EVuVgIGp1Wg/edit) · [Editing](https://docs.google.com/document/d/1JPSfjSjzEH3jUA5TvdWqksHo6Vv0Azbw_8QYximABiQ/edit) · [QA](https://docs.google.com/document/d/1F-gA5AEbe2y0AcEJ0GWZhWp4_Ba5vvFOehZ3l7rb-qI/edit)

All five audit documents are readable without signing in (public-link Viewer access, verified 2026-09-07).

### SK-01 · Constraint controls are buried instead of continuously discoverable

**Implemented; portrait/landscape common-action workflow verified** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Verify compact-window and left-handed layouts, remaining relation actions and accessibility beyond the tested portrait/landscape common-action path.

Acceptance: On iPad landscape each common relation takes one visible action after selection; disabled tools explain their prerequisites; portrait remains reachable.

### SK-02 · Sketch palette hierarchy and vocabulary do not match

**Partially implemented; remaining acceptance open** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Rename Rect/Offset/Construct where space permits; add subtype affordances and intentional overflow. Keep extensions such as Symbols secondary.

Acceptance: All basic tools are discoverable by the same vocabulary, and overflow does not depend on scrolling past unrelated extensions.

### SK-03 · Center and three-point rectangle modes are missing

**Partially implemented; remaining acceptance open** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Extend paired diagonal anchor coverage beyond the tested down/right width case and complete three-point height / two-axis placement; axis-aligned sequential badge edits and center preservation were live-compared. A/B physical Pencil/mouse and external auto-relations. Subtypes, previews, internal rectangular constraints and ordinary-entity persistence are implemented.

Acceptance: Center stays fixed when sizing a center rectangle; diagonal typed sizes prefer normalized lower-left (September8 reverse-drag reference correction); three-point uses the chosen baseline and perpendicular height. Undo removes one complete rectangle.

### SK-04 · Starting a new shape on existing geometry is intercepted as editing

**Partially implemented; input-device A/B still open** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Define hit-test precedence by tool and input device; separate a drawing anchor from an edit handle. Show intent in the cursor/preview.

Acceptance: Each requested new entity can start at a snap point without moving old geometry; editing remains available through a clear selection state.

### SK-05 · Snapping cannot be switched off or configured by category

**Partially implemented; remaining acceptance open** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Introduce explicit snap preferences; pass them into every stroke/tap/drag snap call and distinguish snapping from adding a persistent relation.

Acceptance: With all snaps off, committed coordinates follow input without grid rounding. Each category toggle affects only that category and survives relaunch.

### SK-06 · Grid spacing and acquisition tolerance are fixed in model units

**Partially implemented; sketch snapping/grid acceptance open** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Evidence update: [screen-relative snap receipt](testing/sketch-parity-preplacement-snap-2026-09-08.md), clean37/37 plus live near/far at two clone scales and native far/near reference. Camera-relative12UI-point acquisition implemented; idle-line hover feedback is automated-only.

Next: Complete full zoom/overlap matrix, line closure thresholds and visible/locked grid agreement; resolve simulator hover/switch-click and left-edge input samples.

Acceptance: Zoom does not unexpectedly close a different segment or make endpoints impossible to acquire; displayed resolution matches actual snap steps.

### SK-07 · Sketch entry preserves oblique view; normalize entry behavior

**Implemented for plane entry; ground workflow live-compared, matrix open** · P1

Evidence: Morning paired oblique-entry defect; automatic alignment implemented in `6e37943`. Evening settled ground-entry/re-entry paired captures verify the tested case.

Next: Complete non-ground planes and entry-method camera comparison; do not generalize the ground result to the whole matrix.

Acceptance: Each entry recipe has repeatable camera behavior; user can reach a normal view without losing geometry; docs match the actual contract.

### SK-08 · Plane picking silently falls back to ground

**Queued — verify first** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Preview/highlight target plane, clearly name it, and either confirm intentional grid entry or remain in picker on ambiguous misses.

Acceptance: No ambiguous face miss silently creates geometry on an unintended plane; cancel leaves no empty persistent sketch.

### SK-09 · Line-chain finish, cancel and resume need a device-specific contract

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Centralize chain transitions, preview cancellation and end-point commitment; document which action ends only the segment versus the tool.

Acceptance: No ghost segment, duplicate endpoint, unwanted loop or accidental camera orbit; undo removes the last intended operation.

### SK-10 · Arc creation uses a chord/bulge workflow with no subtype chooser

**Queued — verify first** · P2

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Add explicit stage prompts and required variants only after the A/B; keep preview versus committed arc states distinct.

Acceptance: Prescribed endpoints and arc side are predictable; cancellation produces no stray arc; radius edit preserves the intended branch.

### SK-11 · Spline drawing is not available through the normal sketch UI

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Wire fit-point creation first; assess the additional model work needed for control-point splines rather than claiming all variants are kernel-complete.

Acceptance: Create, finish, reopen, edit and undo a fit spline through normal UI; supported closed splines form profiles; unsupported variants are not advertised.

### SK-12 · Tool-off gesture may leave the numeric card or unexpected navigation state

**Implemented; focused regression checks passed** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Apply a shared transient-state cleanup contract to switch, toggle-off, cancel, exit and keyboard paths.

Acceptance: No orphan keypad intercepts drawing/navigation; state changes are visible; committed geometry is not lost.

### SK-13 · Touch, Pencil and trackpad gesture arbitration needs direct testing

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Create an input-device behavior matrix and improve arbitration only where the A/B differs.

Acceptance: Navigation never commits a stroke; Pencil drawing never unintentionally orbits; tool state survives pan/zoom.

### SK-14 · Small-screen overflow, handedness and labels need a layout audit

**Queued — verify first** · P2

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Define breakpoints and non-overlap zones; use intentional More groups rather than uncontrolled vertical growth.

Acceptance: All active-tool controls and exit/cancel remain visible or one clear overflow action away; no clipped interactive targets.

### DM-01 · Selected sketches outside sketch mode do not reveal dimensions

**Implemented; focused regression checks passed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Route sketch selection in modeling mode and annotation selection ownership consistently; do not solve this by turning Always Show on globally.

Acceptance: The selected geometry shows its value; deselect hides it; tapping the badge opens the correct sketch; remove the expected-failure marker after a real pass.

### DM-02 · Visibility off still exposes all annotations of the active sketch

**Implemented; focused regression checks passed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Filter dimension and constraint glyphs by selection relationship, with separate always-show policies and candidate labels.

Acceptance: Off does not flood the active sketch with unrelated locked values; on reveals the documented set; editing badges remain usable.

### DM-03 · Absolute/horizontal/vertical distance choice is missing

**Queued — implementation needed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Add a distance-type chooser and preserve the chosen kind through editing/save/undo.

Acceptance: The same reference points can show the three distinct intended measurements; choosing a type changes the driving constraint rather than only the displayed text.

### DM-04 · Circle radius versus diameter preference is missing

**Queued — implementation needed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Implement the reference circular-annotation preference and map edits to the correct radius/diameter semantics.

Acceptance: R10 and diameter 20 yield the same geometry, labels are explicit, and switching annotation style never doubles/halves existing geometry.

### DM-05 · Ellipse major/minor dimensions are not exposed

**Queued — implementation needed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Add ellipse-axis dimension references, candidates and solver support as required; assess the model seam before implementing only labels.

Acceptance: Both axes can be independently driven, remain attached after rotation and survive reopen with correct units.

### DM-06 · Dimension labels cannot be repositioned

**Queued — verify first** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Store annotation layout independently of constraint values and geometry; distinguish a drag from a tap-to-edit.

Acceptance: A dragged badge changes only layout, leader remains attached, position survives reopen, and dense values remain reachable.

### DM-07 · Committed dimension graphics are generic dashed segments

**Queued — verify first** · P2

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Define sketch annotation geometry per dimension type and maintain contrast/occlusion rules.

Acceptance: Each value unambiguously identifies what it measures; angular geometry is not rendered as a misleading linear span.

### DM-08 · Anchored Sketch Entity selection-order setting is absent

**Queued — implementation needed** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Track ordered selection in addition to membership; pass anchor preference into solving/drag intent.

Acceptance: The specified anchor remains in place unless an existing constraint requires otherwise; reversing order has the expected result; undo restores all positions.

### DM-09 · Disconnect action is absent

**Partial — four-line edge verified; remaining connections open** · P1

Evidence: [Disconnect receipt](testing/sketch-parity-disconnect-2026-09-08.md): native and clone detached edge movement, Undo/Redo and gallery-reopened disconnection captured. Corrected clean34/34 after initial compile-only failure. Point-only/proximity/reconnection/import/trim covered automatically. Persisted endpoint exclusions prevent silent proximity rejoining; dimensions/other relations retained.

Next: Paired midpoint, primitive-rectangle and non-line connection checks. Single-line default ring and Copy proximity coupling corrected (see [line-control receipt](testing/sketch-parity-line-selection-controls-2026-09-08.md)); explicit white axes versus blue ring remains. Publication recovered in separate existing-Doc tabs (master38/illustrated78 verified before latest line additions); old unsynced tabs preserved.

Acceptance: The chosen connection breaks without deleting geometry, other constraints survive, and undo restores the connection.

### DM-10 · Numeric entry supports only a subset of explicit unit tokens

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Unify unit-aware parsing and formatting, with typed units overriding display units; reject incompatible dimensional units clearly.

Acceptance: Supported explicit units convert once and correctly; unsupported strings never silently become a different length; formulas preserve semantic units.

### DM-11 · Rectangle width-to-height numeric flow needs keyboard and touch A/B

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Implement explicit next-field behavior, visible width/height focus and correct anchor preservation.

Acceptance: 40 by 25 can be entered without closing and rediscovering a second control; geometry and persisted driving dimensions both match.

### DM-12 · Value-card footprint and close/commit semantics need a full transition audit

**Partially implemented; remaining acceptance open** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Keep editor identity stable, define dismissal/commit policy for each event and ensure inactive overlays stop hit-testing.

Acceptance: No hang, gallery return, lost geometry or invisible blocked region across the transition matrix. Treat any reproduction as P0.

### DM-13 · Curve-angle and multi-entity dimension coverage needs a capability matrix

**Queued — verify first** · P2

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Publish the matrix of selection to supported measurement, then fill verified gaps with solver-backed implementations.

Acceptance: Every enabled option has valid references and a truthful preview; unsupported combinations explain why rather than guessing an angle.

### DM-14 · Constraint drag, lock and conflict behavior need end-to-end validation

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Validate refusal/rollback, selected conflict attribution, point versus whole-entity locks and drag-created relations.

Acceptance: No unexpected geometry jump or broken existing constraint; conflict identifies relevant controls; undo leaves one coherent prior state.

### DM-15 · Variables affordance is inconsistent across numeric fields

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Extract shared variable insertion and input-state handling while retaining length/angle/count distinctions.

Acceptance: Variable entry does not require an undiscoverable keyboard workaround in one field; all relevant fields resolve and validate consistently.

### DM-16 · Visibility and camera documentation contradicts current source

**Implemented — dated corrections in README, NEXT, STATUS, and historical parity notes** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Append a dated correction with current baseline; mark historical entries historical; remove the ten sketch-dimension-tools assumption.

Acceptance: A developer cannot mistake an old defect/default or 2D drawing feature for a current sketch requirement.

### ED-01 · Sketch Pattern is reached through an extrude profile, not sketch selection

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Add sketch-selection entry and shared pattern parameters; reuse existing transform preview and core where appropriate.

Acceptance: Open and closed sketch entities can be patterned from sketch mode with preview/count/spacing controls and one undo.

### ED-02 · Sketch patterns commit detached copies rather than an editable pattern relation

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Wire persistent pattern relation and edit UI, define source/member behavior and explicit unlinking. Verify existing core behavior instead of replacing it blindly.

Acceptance: Pattern parameters remain editable after reopen; documented source edits propagate; unlink leaves intentional independent geometry; undo restores the relation.

### ED-03 · Trim does not handle ellipse or spline entities

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Implement shape-preserving ellipse trim and required representation; determine supported spline trim semantics before adding it.

Acceptance: Ellipse remainder matches the original curve, profiles update and undo restores it. Unsupported spline trim shows clear feedback instead of silent no-op.

### ED-04 · Trim must preserve constraint references or explain their removal

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Audit trim-command reference rewriting, profile identity and user feedback for invalidated relations.

Acceptance: No dangling references or unrelated constraint loss; invalidated dimensions are handled explicitly; undo reconstructs geometry plus references.

### ED-05 · Project always flattens a whole tapped body into unlinked entities

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Add selection granularity and linked/unlinked semantics through existing feature/reference architecture; do not confuse sketch projection with surface edge-splitting.

Acceptance: Only chosen items project; linked output updates after source changes; unlinked geometry remains independent; cancel adds nothing.

### ED-06 · Every coincident plane reuses the first existing sketch

**Confirmed and corrected; sampled paired identity/visibility/reopen verified** · P1

Evidence: CODE-CONFIRMED RISK — exact reference gesture needs A/B

Next: Make sketch identity explicit in entry intent; preserve continue versus new rules and selected-history context.

Acceptance: User can intentionally create a separate coplanar sketch and deliberately edit a specific existing one; no geometry silently joins the wrong item.

### ED-07 · Selection precedence and additive selection need an A/B matrix

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Write explicit hit priority and additive/replacement rules for each mode/input; highlight before destructive actions.

Acceptance: The visible highlight matches the next action, blank deselection is consistent, and Delete never affects an unexpected entity class.

### ED-08 · Sketch move/rotate and copy need design-intent verification

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Audit copy of internal relations versus external constraints, center placement, typed values and mode exit.

Acceptance: One operation gives one coherent undo; no unintended constraint links to originals; cancellation leaves no clones.

### ED-09 · Closed-profile detection and sketch-to-extrude handoff need usability acceptance

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Validate closure feedback, region highlighting, boundary selection, nested holes and hidden-sketch discoverability.

Acceptance: The valid region extrudes with the intended hole; invalid/open regions do not pretend to be closed; construction geometry does not create material.

### ED-10 · Sketch exit, re-entry, hidden state and persistence need a single contract

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Clarify unit ownership and view-state persistence; avoid turning a visual edit into unexpected permanent state.

Acceptance: Reopen reproduces intended geometry and values; temporary editing visibility does not unpredictably affect unrelated sketches/projects.

### ED-11 · Offset, construction and symmetry require interaction tests, not missing-feature tickets

**Queued — verify first** · P2

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Compare selection/preview/sign/commit rules and add only evidenced fixes.

Acceptance: No duplicate geometry on cancel, dimension sign is explicit, construction changes profile fill appropriately, symmetry remains intentional.

### ED-12 · Crash regressions and test baselines must be separated from feature gaps

**Queued — verify first** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Keep a regression ledger and promote a reproduced hang/data loss to P0. Do not reopen fixed bugs based on stale prose.

Acceptance: Current focused sketch checks pass without expected failures for release-critical behavior; failures have a minimal UI reproduction and owner.

## Reference correction

Do not implement the previously documented “ten missing sketch dimension tools” from `SHAPR3D_SKETCH_PARITY.md` as a sketch requirement: that evidence came from **2D Drawings**, a different workspace. Draggable-label sketch parity also needs an actual sketch reference before design work. Native Shapr3D was accessible during this audit; older notes claiming desktop automation was unavailable are historical.

## Late-evening three-point follow-up (September7,22:40 EDT)

SK-03: paired live three-point completion now keeps two badges, no automatic keypad; explicit height editing retains selection and both readouts. Confirmed clone undriven-side drift corrected for selected three-point height edits using a transient far-baseline preference, with explicit constraints taking priority. Native isolated135.5815→50mm and clone1.069→0.5mm keep the far baseline fixed; clone baseline stays3.041mm. [Detailed receipt](testing/sketch-parity-three-point-dimensions-2026-09-07.md). Clean22-check initial run +2tool-switch checks; stronger undo check1/1; post-anchor focused14/14. Not one combined latest all-suite run. Illustrated Doc verified29inline images. Live clone toolbar undo still has no observed restoration despite stronger automated assertion passing; remains open alongside baseline editing/reselection, compact/landscape/device checks. No iPad-ready claim.

### Three-point reselection continuation (23:03 EDT)

Confirmed native baseline shrink keeps left side, clone previously rotated/translated after single-edge reselect. Component recovery now supports reselected/reloaded isolated four-line rectangles, with baseline-left/height-far transient sizing preferences and explicit-constraint fallback. Paired live baseline/height sequence and gallery save/reopen retained clone1.5/0.5mm and native140/50mm. Clean21/21 regression (14geometry+7UI). Illustrated Doc33images verified; latest reopen evidence local. See three-point receipt for limits and unresolved live Undo.


## September 8 core-sketch milestone start

[Detailed ordered plan](SKETCH_PARITY_NEXT_MILESTONE.md) and [all 56 original QA scenarios](SKETCH_PARITY_ACCEPTANCE_MATRIX.md) retained alongside all 42 issues. [Start receipt](testing/sketch-parity-milestone-start-2026-09-08.md) distinguishes current Peekaboo no-op/input uncertainty from history logic. Fresh clone toolbar/keyboard Undo leaves rectangle unchanged; native keyboard Undo/Redo restores prior segment. No source fix inferred. Clean diagnostic run: gallery-profile history plus line-chain history 2/2 passed on cd0937d. Not live paired history sign-off, not final candidate regression. Current source unchanged; device candidate not ready.


### September 8: non-ground grid correction

SK-07 / QA-01–04: paired Front entry exposed invisible clone grid (shader fixed
to ground). Active sketch plane now supplies grid origin/basis and grazing normal.
Clean21/21 plane/camera/UI regression. Live Front and Right now show grid/axes;
Top retained. Empty Front exit leaves no sketch in both apps.
[Grid receipt](testing/sketch-parity-plane-grid-2026-09-08.md). Offset/face,
full entry/cancel and drawing coverage remain open. No geometry/snapping changes.


### September 8: circle release/readout correction

SK-04 / QA-12/18: paired circle-at-line-endpoint preserves source geometry;
clone auto-keypad differed from native retained diameter. Circle release now
keeps readout without numeric entry. Clean4/4 focused UI regression; live explicit
edit native420→200 and clone2.236→1 preserves center/line. Polygon unchanged.
[Line/circle receipt](testing/sketch-parity-line-circle-2026-09-08.md). Concentric
initiation and radius-mode matrix remain open. Live line Escape/history delivery
remains blocked; not addressed by this circle fix, not candidate-ready.


### September 8: diagonal anchor reference correction (verified samples)

SK-03 / QA-08: native up-left width holds left side (Top and empty Front plane),
and down/right height holds bottom edge. Clone stored-first-corner preference
differs. Earlier width-only down/right evidence did NOT establish first-corner
behavior across quadrants; that broad conclusion is superseded, not erased.
[New paired diagnosis and correction](testing/sketch-parity-diagonal-anchors-2026-09-08.md).
Lower-left transient preference implemented; clean22/22 regressions passed.
Live reverse-width and down/right-height rechecks match native; Doc58images and
master roadmap publication verified. Remaining quadrant/layout matrix stays open.
Center, legacy and explicit-constraint fallback retained.

### September 8: numeric click-away correction (verified samples)

SK-12 / DM-11–12: native zero-width rejection preserves geometry, as does clone
(modal vs inline warning differs). Native Escape cancels but blank click accepts
a changed dimension; clone blank click/tool activation discarded it. Narrow
click-away/tool-activation correction live verified; explicit cancellation remains
separate. [Paired evidence](testing/sketch-parity-numeric-dismissal-2026-09-08.md).
First run3passed/1new-test-failed at immediate dismissal assertion; targeted
bounded-wait diagnostic1/1 passed (not one combined clean run). Live2→3 blank
click and3→4 tool switch pass; invalid0 still preserves4×1.5. Doc64images and
corrected hashes verified. Landscape/compact and live Escape delivery remain open.

### September8: viewport resize redraw (verified live)

Rotation stretched a stale Metal frame while dimension/point overlays updated;
scene action repaired it. Native window-corner resize kept aspect and markers
aligned. Renderer requests redraw after drawable size change. Clean15/15 Camera/
Dimension tests; live portrait→landscape→portrait with no intervening canvas
refresh now aligned. [Receipt](testing/sketch-parity-resize-rendering-2026-09-08.md).
Landscape/compact keypad reachability and full device input remain open.

### September8: constrained endpoint drag (paired verified sample)

QA36/37/39 / ED08: native locked-left horizontal line permits diagonal pointer
motion projected along its free axis; clone falsely rejected with conflict.
Transient pointer preference now projects back onto saved structural constraints.
14unit checks passed, then exact locked-line UI1/1 passed after correcting older
fixtures. Actual endpoint Undo/Redo restoration checked; temporary toolbar title
values were stale and removed. Live3→3.5mm keeps locked endpoint/direction and
matches native repeat. [Receipt](testing/sketch-parity-constrained-drag-2026-09-08.md).
Full selection/constraint matrix and live toolbar input remain open.

### September8: snap/trim acceptance and automatic equality

Lock removal, acquisition off, Grid-only placement and crossing-line/circle span
Trim sampled in both apps; broader reference/history coverage open. Clone settings
survive gallery reopen (clone-only). Near-equal default strokes auto-linked Equal
and moved prior geometry; native sampled lengths stayed independent. New settings
now require explicit Equal inference opt-in, preserving stored preference/manual
Equal. Clean33/33 inference/lifecycle tests and live Equal-off repeat retain first
3.306mm while second3.385mm stays distinct. [Receipt](testing/sketch-parity-equal-inference-2026-09-08.md).
Google Doc Saving/editing-disabled blocks publication; six earlier snap images
visible locally but export remains76. Trim/equality evidence local, not published.

### September8: arc sweep dimension (paired functional correction)

Native trimmed arcs exposeR plus editable sweep; clone showedR only. Arc sweep
scalar and editable angular badge added, preserving starting direction/center/radius;
whole-arc Lock guards conflicting edits. Existing two-line angles unchanged.
28unit+4existingUI passes, corrected arcUI1pass after selecting fixture; not one
clean combined run. Live90/270 and paired gallery reopen pass sampled workflow.
[Receipt](testing/sketch-parity-arc-sweep-2026-09-08.md). Dashed chord annotation
versus native curved leader and arc endpoint welding remain known limitations.
Google publication remains blocked at76verifiedimages; new screenshots local.

### September8: full-turn arc boundary conversion

Native360° converts an arc into a circle; clone previously rejected it. Conversion
now retains entity identity, removes obsolete sweep dimensions and migrates saved
radius to diameter. Clean25/25 focused tests; paired conversion and clone-only
reopen verified (R0.5→Ø1), crossing line unchanged. [Receipt](testing/sketch-parity-arc-full-circle-2026-09-08.md).
No endpoint-reference or full numeric-matrix sign-off. New images local; illustrated
publication remains blocked at76verified images.

### September8: live history blocker narrowed

On de2756c, creation and dimension Undo/Redo now restore actual geometry in both
apps; clone toolbar and CmdZ succeed after autosave. No history code changed;
earlier failures retained, cause unknown. [Receipt](testing/sketch-parity-history-live-repeat-2026-09-08.md).
Separate line Escape gap confirmed: native clears unfinished preview, clone keeps
pending anchor and had no binding. Scoped correction under test, live repeat pending.
Master continuation status verified by anonymous export; illustrated still blocked.

### September8: numeric Escape cancellation

Existing cancelDimensionEdit now has Escape binding prioritized over linecancel.
Clean5/5UI; pairedlive draftdiscard restoresoriginalvalue withoutgeometrychange,
cloneLine remainsarmed, reopeningseedoriginal. [Receipt](testing/sketch-parity-dimension-escape-2026-09-08.md).
Prior b6ad760 lineEscape pairedscreenshots are now exported/hashverified in the
existing masterroadmap as publicationfallback; illustratedunsyncedtab preserved.
NumericEscapeimages local pending publication; broadernumericmatrixnotcomplete.

### September8: polygon release and downstream persistence

Polygon release now retains radius without forcing a keypad, matching native.
Clean1/1 strengthened profile UI test; paired explicit radius edits, actual
nonzero extrusion and gallery-reopened solids verified. QA15/50/51 remain partial;
side-count editing and full on-canvas visual parity are not signed off.
[Receipt](testing/sketch-parity-polygon-release-2026-09-08.md). Master publication
pending; illustrated unsynced tab preserved at76 verified images.

Publication: existing master roadmap now6 embedded PNGs, including both polygon
reopen captures verified by exact SHA256 in anonymous DOCX export. Historical
heading inspected intact. master-polygon-publication.json/master-polygon.docx
retained locally. Original illustrated tab remains unsynced76; not conflated.

### September8: arc sweep on-canvas annotation

Replaced arc-only dashed endpoint chord with curved sweep leader, radial
extensions, arrowheads and plain tangent-aligned angle text. Native180/90/270
paired evidence; intermediate leader live all three, final text live180/270.
Two successive clean1/1 focused UI runs, not a combined suite. No solver/storage
change. Selection color, blue manipulation ring, radius leader and other-shape
annotation mismatches remain blocking.
[Receipt](testing/sketch-parity-arc-annotation-2026-09-08.md).

### September8: selected sketch edge contrast

Native selectedline/arc orange versus cloneazure confirmed. Selected geometry
now orange; pending previews/manipulation controls remain separate. Build passed;
live line/arc select-deselect restored blue withoutgeometry/valuechange. No new
automatedtest claim for purecolor correction. Endpoint halos, ring and other
leaders remain open. [Receipt](testing/sketch-parity-selection-highlight-2026-09-08.md).

### September8: standalone line dimension leaders

Offsetblackleaders/arrows/plainuprighttext replace dashedgeometryoverlays for
standalone lines. Nativehorizontalbelow/verticalleft paired; finalclonevertical
andhorizontalplacement/keypad/3mmcommit verified. Armeddrawingblue preserved.
Initial5/5UI passed but liveverticalprojectionfailure exposed sign sensitivity;
correctedlayout then clean3unit+1UI and live repeat passed. Rectangleloops and
point-to-point layout unchanged; broaderannotation/gizmo gateopen.
[Receipt](testing/sketch-parity-linear-annotation-2026-09-08.md).

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

### September 8 - selected-side leaders and portrait history target

Top/right dimensions now follow the selected edge. Custom44pt history content
fixes the reproduced portrait painted-center Undo miss; final focused clean2/2
and live one-click Undo/Redo pass. Top/right edits and gallery reopen retain2x1.
History logic unchanged. Prior failed diagnoses retained in axis-edge receipt.
Other-axis leader-side memory and per-edge Lock semantics remain open.
Both Docs blocked; post-fix evidence indexed locally, publication pending.

### September 8 - persisted rectangle side Lock

Selected side Lock now pins only that edge; legacy whole locks unchanged.
Clean23/23 initial and36/36 follow-up, including import scope and point-state
checks. Paired free opposite-edge movement/removal; clone locked-side refusal,
Undo/Redo and gallery-reopened scope verified. Native reopened unlocked values
retained. Rail Unlock toggle and edge colors remain open. Docs blocked;
local evidence indexed. See [side-Lock receipt](testing/sketch-parity-rectangle-side-lock-2026-09-08.md).

### September 8 - contextual Unlock action

Expanded rail now offers Unlock for explicitly locked selected operands;
unrelated refs in multi-operand locks remain intact. Clean9/9 and live label,
glyph, one-step history, freed movement and gallery-reopen checks pass. Compact
menu shares action but remains live-unsampled. Side-Lock receipt retains paired
native reference and failures/history. Constrained-edge colors remain different;
next untouched core recipe is direct arc construction (QA-13). Docs blocked.


### September 8 — circle explicit transform Lock enforcement

Paired native refused a locked circle translation while clone moved it with Lock
still attached. Line/circle gizmo intent now solves original saved constraints.
Clean28/28; live refusal, Unlock/move, Undo/Redo and relock/gallery-reopen/refusal
verified. Native reopen retains diameter/Lock. Other primitive transforms and
label/handle interference remain open. See [circle-transform receipt](testing/sketch-parity-circle-transform-lock-2026-09-08.md).


### September 8 — whole-arc transform Lock enforcement

Native lockedarc refused translation and45°rotation; clone acceptedboth withLock.
Arc transform now solvescenter and preserveswhole-Lock startingorientation.
Free rotation/move retainsradius/sweep; liveUndoRedo/relock/reopen/refusal and
nativepersistedLock verified.11 distinctpassingchecks (initialanglefixturefailure,
correctedtargetedrerun), notcleancombined. Endpointwelding/otherprimitivepathsopen.
See [arc-transform receipt](testing/sketch-parity-arc-transform-lock-2026-09-08.md).


### September 8 — explicit circle diameter/move-target clearance

Freecirclecenterdrag was intercepted by44ptdiameterbutton; offsetdragworked.
Native retainsdrivenØ in explicitmode, so readoutkept. Mode-only60pt textoffset
clearscenter; normal20pt unchanged. Clean2/2 pluslivecenterdrag/history/editor/
reopen. Fulltransformcontrolstyle remainsopen. Circle-transform receiptupdated.

## Explicit transform controls and initial arc pivot — September 8

White directional X/Y/rotation controls and exact numeric entry replace the
explicit-mode ring; center drag and Copy retained. Single-arc rotation uses exact
visible bounds for its initial pivot. Clean 16/16 focused regression, live typed
Y/45-degree rotation/history/Copy and gallery reopen captured. Earlier failures
remain in the [transform receipt](testing/sketch-parity-explicit-transform-controls-2026-09-08.md).
Illustrated 92 images and master final-reopen note export-verified. Retained
operation values, pivot and rotated local control frame remain blocking gaps.

Retained transform values follow-up: clean17/17 and live absolute45→90 re-edit
around original pivot, Undo45/Redo90, clone gallery reopen verified. Native
immediate Home after Redo reverted the transform: acceptance/exit investigation
open, not paired persistence sign-off. Illustrated94 images verified. Rotated
local frame and post-history mode still differ. See same transform receipt.

## Local transform axes and history mode — September8

Confirmed native45-degree rotation changes subsequent X movement direction;
clone world-axis movement corrected. Retained local frame drives arrows and
numeric movement; translated pivot stays coherent. Tangent rotation glyph and
Undo/Redo closing explicit controls corrected. Clean19/19 final regression, live
diagonal X/history and accepted-operation paired gallery reopen verified.
Illustrated98 images/new4 hashes and master final note exported. Full receipt
remains [explicit transforms](testing/sketch-parity-explicit-transform-controls-2026-09-08.md).
Remaining annotations, direct rotated drags, symmetric circle frame and full
numeric/selection/device-candidate acceptance stay open.

Circle frame-only transform: native45 retains local frame/value despite unchanged
circle geometry. Clone now records this accepted operation without geometric
perturbation; Undo consumes it rather than prior creation. Clean19/19 plus live
frame/X/history/reopen verified; illustrated100/new2 hashes and master note
exported. Transform rail and annotation overlap/clipping remain next gaps.

## Settled explicit-transform history correction — September 8

Native Undo/Redo clear selection and operation handles while keeping Move/Rotate
armed; reselecting resumes controls. This corrects the prior mode-exit claim.
Clone now retains the armed tool/Done, clears selection/value on history, and
hides the constraint rail during explicit transforms as native does. Clean21/21
plus live Undo/Redo, reselection and Done verified. Normal circle annotation
clipping, explicit Escape and remaining visual matrix stay open. See the
[transform receipt](testing/sketch-parity-explicit-transform-controls-2026-09-08.md).

## Explicit-transform Escape — September 9

Confirmed native keypad-first Escape now implemented: cancel uncommitted numeric
entry first, then exit Move/Rotate without changing geometry. Works with empty
selection after Undo as well. Clean2/2 supplemental numeric/history+Copy UI
checks; actual hardware key verified live, with gallery reopen preserving the
original circle. [Receipt](testing/sketch-parity-explicit-transform-controls-2026-09-08.md).

## Circular transform readout visibility — September 9

Temporary circle/arc size readouts now hide during explicit Move/Rotate; saved
driving dimensions remain visible and editable. Normal selection restores free
readouts. Clean27/27 (19unit+8UI), paired free/driven circle/arc cases, saved editor
access and gallery reopen verified. Illustrated108/new4 PNG hashes verified;
normal radial-handle coordinate offset remains a separate blocking visual gap.
See [transform receipt](testing/sketch-parity-explicit-transform-controls-2026-09-08.md).

## Radial handle viewport origin — September 9

Circle/arc radial overlays now share the viewport's full-bleed coordinate origin.
This removes a safe-area offset that placed handles inside geometry/over text.
Clean2/2 strengthened outside-rim+resize/history tests; paired normal placement
and clone live portrait/landscape resize, driven refusal and reopen verified.
Fresh native radial-drag delivery limitation explicitly retained, not a new
native resize pass. [Receipt](testing/sketch-parity-radial-origin-2026-09-09.md).

## September 9 — near-rail diameter annotation

[Edge-layout receipt](testing/sketch-parity-diameter-edge-2026-09-09.md): exact
native/clone translations expose a clone diameter touch target behind the rail.
Head-on edge fallback uses an outside vertical leader and matching rotated target;
roomy horizontal release layout stays unchanged. Initial layout4/4 + target1/1
and live keypad/value/history/reopen passed. Final native outside-arrow/text
refinement4/4 passed; added oblique-projection guard had a compile-only type
failure, corrected and under rerun. Final live rendering/publication pending.
Normal reselection/manual annotation orientation and oblique edge layout remain
open; no complete visual-gate or device-ready claim.

Final guard run clean4/4 after compile-only type correction and Top1degree-limit
UI failure; all history retained in receipt. Final live saved Top Ø1 outside
arrows/top-to-bottom text and explicit keypad checked; prior fresh Front value/
history and paired gallery reopen checked. Final publication underway.

Illustrated116/allfournewhashes and master38 final gallery-reopen note verified.

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

## September 9 — point-touch and partial straight overlap

Both apps independently select loops sharing only one vertex. Partially
duplicated top boundaries retain their profile; native interior endpoints and
clone snapped corner-ending sample recorded separately. Clean2/2 precise
geometry checks cover point touch and both partial-overlap directions. No
production change. Paired gallery reopen retains selectable loops and prior
bodies. Illustrated173 placements/all8 new hashes; master38 final note verified.
[Receipt](testing/sketch-parity-point-touch-2026-09-09.md). Remaining topology
and installable-device gate still open.

## September 9 — crossing straight-profile correction

Native bow-tie exposes two triangles; clone exposed none. Temporary straight
intersection splitting now supplies missing graph junctions without changing
editable entities/constraints. Initial red test failed; corrected clean42/42
profile/history/seed/curve run. Live independent triangle selection, extrusion,
Undo/Redo and paired final reopen pass. Illustrated179/all6 new hashes and
master38 final note export verified. Curved intersections excluded; earlier
partial-overlap first-loop fill disappeared during later editing, still open.
[Receipt](testing/sketch-parity-crossing-profiles-2026-09-09.md).

## September 9 — numerical partial-overlap stability

The earlier partial-overlap profile vanished after more constrained drawing.
Read-only saved geometry exposed ~4e-14mm offset in the duplicate segment, not
an open boundary. Exact fixture failed; temporary graph overlap normalization
at existing node precision fixes it without editing geometry. Corrected clean
43/43; live saved recovery, fresh overlap plus continued line Undo/Redo and
paired final reopen pass. Illustrated184/all5 hashes; master38 final note
verified. Initial pass and subsequent failure retained in audit.
[Receipt](testing/sketch-parity-partial-overlap-stability-2026-09-09.md).

## Direct arc two-click construction — September 9

Native two endpoint clicks created an arc; clone ignored them. Added the missing
route into existing pending-arc construction. Five distinct regression checks
pass across corrected/targeted runs (initial compile failure and immediate-input
UI failure retained). Fresh live creation/history/reselect/keypad and paired
gallery reopen verified. Illustrated191 placements/new4 hashes and master38
finalnote verified. Default45° versus106.26°, pending feedback and bulge/finish
remain open; not fullQA13. [Receipt](testing/sketch-parity-direct-arc-recheck-2026-09-09.md).

## September 9 — new arc default curvature

Native forward/reverse endpoint inputs produce45° on the directed chord's right
side; clone produced106.26° on the opposite side. Corrected new construction
only; saved arcs unchanged. Clean18/18 construction/analytic/arcUI checks; live
forward/reverse, Undo/Redo and paired gallery reopen verified. Illustrated197
placements/all4 new hashes and master38 final note export verified. Pending
radius/sweep feedback, clipping and Return/chaining still open; not fullQA13.
[Receipt](testing/sketch-parity-arc-default-shape-2026-09-09.md).

## September 9 — pending arc defining readouts

Native provisional arcs expose radius and sweep with two radius rays and a
curved angular leader; clone exposed radius only. Added informational pending
radius/sweep descriptors and native-style live leaders without changing commit
semantics. Focused22/22 and final combined39/39 clean; paired initial pending
states and clone midpoint adjustment were live-inspected. A later isolated
native recheck proved the apparent midpoint drag starts a chained arc, so the
earlier native-adjustment interpretation is withdrawn. Illustrated201/all4 new
hashes and master38 note verified. Native third-point placement, Return/chaining
and major/minor remain inconclusive, so QA-13 is partial.
[Receipt](testing/sketch-parity-arc-pending-feedback-2026-09-09.md).

## September 9 — pending arc cancellation

The clone had no Escape route for an armed Arc and left an unfinished preview
onscreen. `cancelArcInput()` now discards first/two-endpoint transient state,
clears guides and snap feedback, and disarms without committing or mutating
history. A guarded neutral-sketch Escape exits sketch mode only when no tool,
selection or contextual operation owns the key. Corrected focused construction
tests passed 6/6 after one recorded compile-only fixture failure. The installed
binary then matched native live: first Escape retained only the committed arc;
second Escape exited sketching.
[Receipt](testing/sketch-parity-arc-cancellation-2026-09-09.md).

## September 9 — arc third point and chained continuation

An isolated native recheck established the actual direct-Arc contract: pointer
hover chooses the third point, click commits it, and the prior endpoint
automatically starts the next chained arc. The clone now updates pending sagitta
from hover or a touch-only third tap, retains the second endpoint as the next
anchor, previews the next arc without premature commit, and cancels that
transient chain without history mutation. Final current-revision regression
passed cleanly 34/34 after recording and correcting obsolete UI fixture
assumptions. Exact-binary live clicks verified third-point shaping and shared
endpoint continuation; simulator hover delivery remains automated-only.
Illustrated publication is export-verified at 213 placements with six new
paired captures; the master remains at 38 images.
[Receipt](testing/sketch-parity-arc-third-point-chaining-2026-09-09.md).

## September 9 — Arc Return completion

Native Return accepts the current/default Arc after two endpoints and preserves
it through the following Escape. The clone now registers Return only for that
pending state and commits through the chained third-point path. Focused 11/11
and final current-revision combined 35/35 passed cleanly; paired live keyboard
checks retained the committed arc and shared endpoint. Direct construction
major/minor boundaries, tangent transition, simulator hover delivery and
physical Pencil input remain open. Anonymous exports verify the illustrated
report at 219 placements with all six new image hashes and the master roadmap at
38 drawings; a displaced prior chained-arc image was restored from the previous
verified export before publication was counted.
[Receipt](testing/sketch-parity-arc-return-2026-09-09.md).

## September 9 — arc endpoint tangent transition

Native endpoint Arc construction persisted a Tangent relationship to the
connected horizontal line; the same-shaped clone geometry had no relationship
or glyph. Final third-point commit now performs endpoint-only arc tangent
inference through the saved point/angle gates, rejects oblique/interior/disabled
cases, and commits the arc plus accepted relationship as one Draw history step.
Paired live selection showed the clone `T` glyph; Undo removed only the arc and
constraint, and Redo restored them. Focused inference/construction passed 31/31;
the final combined solver/construction/existing-arc-UI run passed cleanly 63/63.
Three experimental UI attempts selected the connected line rather than the arc
and were removed instead of counted. Direct gesture major/minor boundaries,
simulator hover delivery and physical Pencil remain open, so QA-13 is partial.
Anonymous exports verify the illustrated report at 227 placements with all
eight new hashes and every prior unique image retained; the master remains at
38 drawings with its dated tangent note.
[Receipt](testing/sketch-parity-arc-tangent-transition-2026-09-09.md).

## September 9 — direct arc major/minor boundaries

A controlled two-endpoint drag plus third-point click established direct native
minor, semicircle and major construction at 90, 180 and 220 degrees. The exact
clone build exercised the same three regions at a different viewport scale and
reported 81.91, 176.03 and 214.93 degrees. Clone Undo removed only the sampled
major arc and Redo restored the closed profile. This closes the direct gesture
boundary item without claiming pixel-coordinate equivalence. QA-13 remains
partial because clone hover is automated-only and physical Pencil/touch is not
tested. No product source changed; the last relevant current-revision suite is
the clean 63/63 arc tangent combined run.
[Receipt](testing/sketch-parity-arc-major-minor-boundaries-2026-09-09.md).

## September 9 — QA-56 downstream smoke

Native and clone each carried an isolated circle from a selectable closed
profile through extrusion commit and solid Undo/Redo. The clone also canceled a
first preview without mutating the profile. A single current-revision serial
run passed 65/65: two Sweep/Loft UI workflows and 63 kernel/feature-graph tests.
QA-56 is promoted to passed without claiming advanced downstream parity,
identical dimensions, or physical-device input.
[Receipt](testing/sketch-parity-downstream-smoke-2026-09-09.md).

## September 9 — QA-55 sustained use

Paired ten-cycle rectangle/circle/line construction and history completed
without a visible hang. Dense projects survived gallery reopen; the clone also
survived host closure during a 71/71 focused profile/cache/constraint/
construction/selection regression and exact-build relaunch. Native circle
release required a 0.7-second settle before switching tools. Logged automation
wall times are orchestration evidence, not a product-speed comparison.
[Receipt](testing/sketch-parity-sustained-use-2026-09-09.md).

## September 9 — final regression gate triage

The first full serial run exposed nine deterministic failures after 1,586 passes
and three skips. All nine reproduced together rather than being dismissed as
long-run state. One product issue was confirmed: arming Chamfer/Fillet retained
the ordinary body transform gizmo over the edge-picking viewport. The tool now
retains its source body ID while clearing ordinary selection. The remaining
failures were stale or invalid rendered targeting in UI fixtures (face-interior
blend taps, offscreen Bug Report attachment control and fixed-fraction Offset
taps). All nine pass together cleanly, and the final same-working-tree full run
passes 1,598 total: 1,595 passed, 0 failed and 3 skipped. Exact-build clone live
smoke confirms neutral no-gizmo Blend activation and real edge acquisition;
native whole-body activation is retained as a downstream workflow difference,
not core-sketch parity evidence. See
[final regression receipt](testing/sketch-parity-final-regression-2026-09-09.md).

## September 9 — exact-revision device handoff

Revision `05be744` is pushed and archived as a development-signed iPhoneOS/arm64
build. The exported 1.0 (1) IPA is 16,876,597 bytes with SHA-256
`b0f512efc9a22ed5f23dcefe3567f2dfe727e6ed1821fd782fa10d212ba6d65c`.
Strict code-signature and Designated Requirement checks pass; the existing team
profile contains 81 provisioned-device entries and expires 2027-07-21. This is
an installable comparison artifact only for devices already in that profile.
No physical installation, Pencil/touch result, full parity, or release readiness
is claimed. See [the device A/B handoff](SKETCH_PARITY_DEVICE_AB.md) and
[final regression receipt](testing/sketch-parity-final-regression-2026-09-09.md).
The final illustrated Google Doc export verifies 265 image placements / 263
unique media, including each of five new final-gate screenshot hashes once. The
master roadmap export retains 38 drawings and exactly one final candidate note.

## September 9 — numeric-refusal continuation after candidate handoff

QA33 current paired zero input confirms native nonmodal warning versus clone
blocking alert. Dimension parse/range refusals now use transient notices; geometry
and solver-conflict rules unchanged. Clean8/8 keypad commit checks plus live zero
refusal, valid recovery and one-step Undo. QA33/40 remain partial, styling differences
retained; publication pending. [Receipt](testing/sketch-parity-invalid-recovery-2026-09-09.md).
Immutable05be744 IPA preserved; continued work is not included in that artifact.

Follow-up: malformed expressions retain the keypad with field-anchored yellow
feedback cleared on edit. Explicit submit retains invalid drafts; click-away
discards them with a transient warning. Latest combined9/9 and paired live
click-away/Escape passed. Illustrated274/master38 verified; last dismissal
addendum pending. Specific parser wording/indicator and full QA33/40 remain open.

## September9 — selected polygon count continuation

Native on-canvas side count edits existing topology; clone only had future-default
Sides field. Separate count annotation/editor now implemented, preserving
center/radius/rotation/entity identity and using atomic dependent sketch rebuild.
Polygon radius leader uses first-vertex direction/plain annotation. Live2 refusal,
3.5->3 andUndo6/Redo3 passed; odd-polygon count position refined and expanded UI
run pending. Corrected keypad9/9 after one fixture failure; no overlapping sums.
Exact native upper limit/system keyboard and same-state control visual audit
remain open. [Receipt](testing/sketch-parity-invalid-recovery-2026-09-09.md).
Specific diagnostics publication281/all3hashes/no loss verified; polygon inserts
await export verification. Immutable05be744 IPA unchanged.

Final count follow-up: clean11/11, refined opposite-edge label live verified,
paired geometry reopen preserved; native reopens as selected edges whereas clone
retains polygon count/radius edit identity. Illustrated288/all3finalhashes/no loss
and master38dated-note export verified. Next system-keyboard matrix.

## September10 — keyboard-route recovery

Confirmed native first-key seed replacement/123 toggle differed from clone
append/no-return control. Fixed untouched-seed focus selection, return-to-pad
while preserving real drafts, variables visibility, and same-session focus
after rejected Return. Final clean11/11 (9unit+2UI), after retained red append
and first-fix focus failures. Live first input, both routes, invalid immediate
recovery, commit and Undo passed paired. Formula indicator, mode persistence
and sampled line-anchor difference remain separate open comparisons.
[Receipt](testing/sketch-parity-system-keyboard-2026-09-09.md). Diagnosis292verified;
final6images inserted once, export pending. ImmutableIPA unchanged.

Keyboard final publication verified298placements/all6hashes/no predecessorloss;
master38datednote and predecessor retained. No full-row closure; controlled
line-anchor comparison follows.


## September10 — fresh line length anchor

Paired forward/reverse creation: native first numeric length holds the drawing
start, clone center-shrinks. Native reselection changes reverse-line anchor to
left; no blanket rule inferred. Creation-only standalone H/V-constrained first
size preference implemented, savedconstraint fallback/no persistedLock. Freeangle,
reselection and connected-line sizing remain open. Initial33checks31pass/2failed
cases retained (wrong keypadoperatorID; free-sloped direction), corrected UI
forward/reverse/history passes; combined result/live post-fix pending.
[Receipt](testing/sketch-parity-line-sizing-anchor-2026-09-10.md).
Illustrated302 placements/new4hashes once/no predecessorloss verified; master38
unchanged. Immutable05be744IPA excludes this change; no acceptance-row closure.

Final corrected combined33/33 clean. Exact-build live forward/reverse startanchor,
Undo/Redo and paired savedlength reopen passed. Clone continuation persisted;
native attempted joinedsegment inconclusive and not counted. Illustrated306/all4
finalhashes/no predecessorloss verified. Masterdated note appended, exportpending.

Master38 placements/newdatedheading once/prior keyboard note and media retained;
export verified /tmp/os3d-anchor-master.docx.

## September 10 — retained scalar arithmetic (QA33/40 partial)

Native numeric edits retain arithmetic, reopen it, and display gray italic f(x).
Clone formerly retained only the result. Optional explicit-unit displayExpression
now preserves scalar source separately from named-variable formulas; plain numbers
clear it, Undo/Redo restores it, and import/radius-to-diameter conversion retain it.
Live gray marker contrast, relaunch/gallery reopen and paired plain-value/history
checks pass. Initial 16/16, leading-equals 15/15, final import-inclusive clean31/31.
Unit-switch semantics are automated-only; no full case or device parity closure.
See [scalar expression receipt](testing/sketch-parity-scalar-expression-2026-09-10.md).

## September10 — editor-session keyboard preference (QA40 partial)

Native remembers keyboard-only/keypad choice after dimension dismissal. Clone
reset on every edit. Preference now belongs to EditorViewModel; reopened keyboard
editor receives focus and its untouched seed remains selected. Paired same-label
Escape/reopen and123switch-back pass. Final explicit-commit lifecycle11/11 follows
a corrected seed-append failure and a retained synthetic-XCTest-Escape discrepancy
(live Escape passes). No cross-launch preference or physical-input claim.
See [keyboard preference receipt](testing/sketch-parity-keyboard-preference-2026-09-10.md).

## September10 — explicit-unit scalar source

Native2cm→20mm and explicit20mm preserve enteredunittext withf(x); clone converted
correctly but discarded it. Retention now includes explicit-unit numbers, while
bare numbers clear source. Clean16/16; paired source/bare-value/history and both
galleryreopens retain native20mm/clone0.1cm. Display-unit switching remains
automated-only. [Receipt](testing/sketch-parity-explicit-unit-source-2026-09-10.md).

## September 10 — mixed-unit additive lengths (QA33 partial)

Native `1 cm + 2 mm`→12mm; clone equivalent previously produced syntax warning.
Fully-qualified mm/cm/m additive lengths now convert per term, retain source and
f(x), and avoid variable-formula/double-conversion paths. Clean27/27 parser/keypad
checks; paired commit/source/UndoRedo and clone gallery reopen pass. No arbitrary
dimensional algebra or native gallery repeat claim. Illustrated332 verified with
allfour hashes/no predecessor loss. Receipt: testing/sketch-parity-mixed-unit-2026-09-10.md.

## September 10 — angle units cannot resize lengths (QA33 partial)

Native rejects10deg in length field; clone previously silently converted1deg to1mm.
Length commit now refuses degree suffix before dismissing/mutating, preserving
draft with matching diagnostic. Clean28/28 and paired rejection/valid recovery
verified. Clone SelectAll delivery anomaly excluded; explicit deletion succeeds.
Receipt testing/sketch-parity-unit-type-2026-09-10.md. Publication verified at336 images.
Reciprocal length-in-angle input remains next; no physicalinputclaim.

## September 10 — reciprocal length-in-angle refusal (QA33 partial)

Native45degree arc refuses10mm; clone previously shortened to10degrees. Reciprocal
pre-mutation unit check preserves draft/geometry with matching diagnostic. Clean33/33
parser/keypad/arc tests and paired rejection/90degree validrecovery verified.
Illustrated341/all5hashes and master38 note verified. Receipt testing/sketch-parity-angle-type-2026-09-10.md.
Separate lower-field occlusion behind iPad keyboard captured; placementfix isnext.

## September 10 — keyboard occlusion (QA40 partial)

Confirmed lower arc angleeditor hiddenbehind iPadsoftwarekeyboard. Container-only
safeareaignore leaves editorheight keyboard-aware; fullcanvasgeometryunchanged.
Clean2/2 UI with actualkeyboardvisibility/commit assertions; liveportraitwarning,
landscaperotation/draftrecovery/visible90degreecommit andgallerysource-reopen pass.
NativeMac keyboard-onlyfieldvisible; physicaliPadcomparison stillunverified.
Receipt testing/sketch-parity-keyboard-occlusion-2026-09-10.md; siximages inserted
once; export verified at347 images and master38 note. Next annotationcontrast/theme audit.

## September 10 — light-canvas annotation contrast

Dark UI resolved semantic foreground to white despite the fixed light Metal canvas.
Persistent leaders/text now remain black; paired selected arc and live isolated
line/circle/rectangle release checks confirm readability. Pending arc dark material
badges differed from native plain text; removed material and aligned font with
completed dimensions. Three serial builds passed and final pending45degree live
repeat passed. No new automated-test or physical-iPad claim; broader placement and
scale differences remain. Receipt: testing/sketch-parity-annotation-contrast-2026-09-10.md.

## September 10 — explicit inch conversion (QA31 partial)

Native1in→25.4mm; clone0.05in silently became0.05mm. Keyboard-only suffix mapping
now converts to1.27mm and retains source rather than a spurious variableformula.
Clean33/33, live corrected conversion, paired source/history and clonegallery
reopen verified. Feet/quote/mixedimperial remain open. Illustrated357/all4 hashes
and master38 verified. Receipt testing/sketch-parity-imperial-unit-2026-09-10.md.

## September 10 — explicit feet and quoted-keyboard refusal

Native0.05ft→15.24mm, clone0.0025ft wrongly treated asmm. Keyboard ftmapping now
converts0.762mm with source/history retention. Clean34/34, pairedsource/history
and clonegalleryreopen pass. Quotedkeyboardroute syntaxrefusal andvalidin recovery
match; smartpunctuation scope explicit, no universalquoteclaim. Illustrated363/all6
hashes/master38 verified. Receipts testing/sketch-parity-feet-unit-2026-09-10.md
and testing/sketch-parity-quoted-inch-2026-09-10.md. Mixedimperial remainsopen.

### September 10: mixed imperial additive length source

Native accepts feet+inches; clone now converts fully qualified additive terms
without treating the unit suffix as a variable. Clean35/35; paired source/history
and clone gallery reopen verified. Illustrated368/master38 export-verified.
Receipt: testing/sketch-parity-mixed-imperial-2026-09-10.md. Narrow expression
field remains a visible difference; no full QA closure or updated IPA claim.

### September 10: complete ordinary expression field

The input grows with text within96–320pt instead of clipping every source at96pt.
Clean2/2 keyboard/keypad UI checks; paired native source switching and clone
portrait/landscape/source commit plus saved reopen inspected. Illustrated373/all5
hashes and master38/final reopen note verified. Theme differences retained.
Receipt: testing/sketch-parity-expression-field-width-2026-09-10.md.

### September 10: imperial compact annotation notation

Paired cm/in/ft display changes preserve source and geometry. Native uses quote/
apostrophe imperial annotations with four-decimal feet; corrected clone compact
formatter matches sampled notation, leaving input tokens and model units unchanged.
Clean45/45, live corrected readouts and paired gallery source/unit reopen;
illustrated380/all7 hashes/master38 verified. Next keypad ft/in row; Settings
icon-center delivery remains open. Receipt testing/sketch-parity-display-units-2026-09-10.md.

### September 10: imperial keypad unit family

Native ft/in/deg row now available when clone display unit is inch/foot. Metric
keys retained otherwise; full token recognition unchanged. Clean22/22 combined
UI/keypad tests, pairedft-key commits/UndoRedo and clone savedsource/reopen.
Illustrated384/all4 hashes/master38 verified. Untouched rounded-seed no-op next;
Settings target gap retained. Receipt testing/sketch-parity-imperial-keypad-2026-09-10.md.

### September 10: exact untouched dimension seed

[Rounded-seed receipt](testing/sketch-parity-rounded-seed-2026-09-10.md).
Native preserves measured20mm when accepting roundedFoot text; clone drifted.
Exact mm/degrees now retained separately from rounded field text; edited drafts/
expressions still evaluate normally. Red1 then corrected21 and final combined23/23.
Live clone2mm preserved through untouched0.007ft acceptance, lockUndoRedo and
gallery reopen. Native untouched-commit history remains distinct/unconfirmed;
no blanket history-equivalence claim. Illustrated391/all7/no loss;master38 verified.
Settings icon-center input and same-theme comparison next; acceptance unchanged.

### September 10: Settings icon-center target

[Settings target receipt](testing/sketch-parity-settings-target-2026-09-10.md).
Visiblecenter ignored, +9px worked. Explicit44pt content target corrects live
portrait model/sketch and landscapecenter access. UIKitexternaltoolbarheight36;
initialtestheightassumption corrected, then centerbehaviorpassed1/1; separate
imperialworkflow1pass. Illustrated396/all5/no loss/master38 verified. Lighttheme
comparison now underway; no fullsettingspanel/nativeplatform equivalence claim.

## September 10 — Numeric editor proportions and occlusion

Confirmed matched-Light discrepancy: clone short fields were narrow/small and
endpoint markers painted over keypad keys. Increased field type/minimum width,
made surfaces opaque and placed informational point markers below editors.
Initial four UI checks passed but live short-line evidence exposed the remaining
layer issue; revised three checks passed after correction. Paired numeric edits,
Undo/Redo and saved gallery reopen verified; Light/Dark and system-keyboard
coverage inspected in clone. Illustrated 403 placements/all seven hashes/no
predecessor loss and master 38/reopen note export-verified. Platform scaling and
physical input remain unverified; immutable IPA unchanged.
[Full receipt](testing/sketch-parity-field-surfaces-2026-09-10.md).

## September 10 — Provisional Items presentation

QA-04 exposed a visible distinction: native omits empty new sketch context from
Items; clone listed it immediately. Filter only the current provisional empty
entry. First geometry reveals its row; Undo hides it again and Redo restores it,
with underlying history identity preserved. Persisted empty sketches remain
listed. Initial6/6 identity/Items checks, then refined5/5 identity after native
history comparison corrected the initial row-retention interpretation. Live
final first-line history, paired Right empty Exit/Escape, hidden-sketch integrity
and both gallery reopens verified. Full QA-04 remains partial for isolated Top
and remaining exact-build variants.
[Receipt](testing/sketch-parity-empty-entry-2026-09-10.md).

## September 10 — Empty-entry acceptance closed

QA-04 Top/Front/Right empty entry, Exit/two-stage Escape, existing visible/hidden
item preservation, first-line Items/history and final gallery reopen verified
in native and tested clone. Scoped product fix0c8c268; initial6/6 plus revised
5/5. Illustrated417/all6closurehashes/no predecessorloss and master38 verified.
Inventory3passed/0failed/1deviceblocked/52incomplete (41partial/11deferred).
Continue QA-06 remaining Backspace/double-click/tool-switch cancellation routes;
no device-ready/full-parity claim. Receipt testing/sketch-parity-empty-entry-2026-09-10.md.

## September 10 — QA-06 Line Delete shortcut

Native released-line Delete disarms Line without deleting committed geometry.
Clone previously left Line armed; missing bare Delete route is corrected, only
while Line is active and no dimension editor owns the key. Clean corrected 3/3
(two state/history unit checks, tap-chain UI) follows one compile-only fixture
failure. Actual key, one-step Undo/Redo, Line→Arc and paired saved reopen verified.
Pending native hover, Return and double-click routes remain open; QA-06 partial.
[Receipt](testing/sketch-parity-line-delete-2026-09-10.md).

## September 10 — independent directional acquisition

SK-05/QA-07 partial correction: persisted Sketch Guide Lines now controls line
near-axis acquisition independently of Auto-Constrain. Guide-off/Auto-on retains
raw shallow aim; guide-on/Auto-off snaps without saved H/V. Paired live cases,
history and gallery reopen verified; combined35/35 regression passed. Other
directional relations and second-scale matrix remain open. Illustrated434 and
master38 dated note export-verified. See [receipt](testing/sketch-parity-line-guides-2026-09-10.md).

## September 10 — screen-distance line guide correction

QA07 confirmed short-line gap: native acquires4point near-axis deviations even
when their angle exceeds1degree; clone now uses4logicalscreenpoints for line
H/V guides and the corresponding raw-aim saved-relation gate. Other inference
tolerances retained; tiny Float boundary allowance doesnot expand visibleband.
Thirtyfive distinct checks pass across combined34/35 plus finalSettings1/1,
with earlier failed runs retained. Live short H/V near/outside, changedFit scale,
AutoOFF/no relation andAutoON/H, one-step history and pairedgalleryreopen passed.
Remaining signed/reverse variants keepQA07partial. See line-guides receipt.

## September 10 — diagonal default annotation sides

QA08 mixed-quadrant live checks confirm lower-left sizing for down-left sequential
width/height edits, but two default leader sides differ visibly. Native down-left
width is above; up-right height is right. Clone used bottom/left universally.
Creation-direction leader selection implemented using existing persisted corner
metadata; explicit selected edges, center/legacy defaults and sizing solver are
unchanged. Regression running; live post-fix and publication verification pending.
See [diagonal matrix receipt](testing/sketch-parity-diagonal-matrix-2026-09-10.md).

QA08 leader correction follow-up: clean25/25, pairedchangedleaderpositions,
height-firstsequentialdimensions, widthUndo/Redo andgalleryreopen verified.
Clone explicitoppositeedgeleaderoverride passeslive. Diagnosis466exportverified;
postfixpublication blockedbyGoogle signedout/read-only state. Localreceipt
retains evidence andexactrecoveryrequirement. QA08 remains partial.

## September 10 — rectangle center translation control

Confirmed native center drag translates a rectangle while clone center drag
orbited the camera. Added a visible center dot, center acquisition, and rigid
translation projected against saved constraints. Temporary size equations do
not become saved dimensions; explicit Move/Rotate remains available. A refused
drag displays the existing constraint notice and adds no numerical-noise Undo.
Final clean 25/25 plus live free/driven movement, history, locked refusal,
Unlock and paired gallery recovery passed. Center-point selection/Lock scope
and two missing corner markers remain open. Publication blocked by Google
sign-out; evidence retained locally. See diagonal-matrix and publication-pending
receipts dated September 10. Immutable candidate IPA unchanged.

### Rectangle corner correction verified (September 10)

Final regression clean **30/30**, zero skipped/failed, at
`/tmp/os3d-qa08-corner-final-20260910.xcresult`: six point-state tests,
23 rectangle geometry tests, one center drag/history UI workflow. Prior31/31
included one additional UI workflow before final styling; do not combine counts.
Only indentation changed after the final build.

Exact-build live clone shows four light hollow corners; left-edge Lock produces
two green left corners and two blue right corners, matching the native sampled
point-state convention. Whole Lock shows all four green hollow. Clone toolbar
Undo returns all corners blue; Redo restores partial green without geometry
movement. Gallery reopen retains partial Lock and marker states. Native latest
hotkey Undo sample reselected the edge but did not visibly clear Lock; therefore
that particular native history repeat is inconclusive, not a paired history pass.
Native partially constrained edge colors still differ from clone and remain open.
Center-point selection/Lock scope remains open; QA08 remains partial.

Final captures: `native-corners-left-locked`, `final-partial`, `final-undo`,
`final-redo`, `final-reopen-state` under the os3d-qa08 prefix in diagonal-matrix.
All copied and hashed locally. Google signed-out blocker persists; no new
publication claim beyond illustrated466/master38. Immutable05be744IPA untouched.

### Center-only rectangle Lock correction — September 10

Native center Lock permits width18→9 about the unchanged midpoint while height12
remains. Clone now selects only the center point (mouse and touch drag-start),
saves a center-scoped Lock, and lowers it to a fixed-midpoint equation without
new rectangle variables. Unsupported derived-center relationships stay disabled.
Center colors show selection/Lock; local glyph is offset below the drag target.
Final clean31/31 at `/tmp/os3d-qa08-center-lock-final2-20260910.xcresult`, after
retained kernel/UI failures and fixture corrections. Exact-build live clone
width0.957→0.5 preserves midpoint/height1.736; Undo/Redo, locked refusal, Unlock
translation40×20, relock and gallery reopen all captured. Native resize is live
compared; latest native reopen remains pending at trial modal7759 because supported
focus/capture routes are inconsistent. No native persistence failure claimed.
Publication remains queued, not verified: Google signed-out, last illustrated466 /
master38. Immutable05be744IPA unchanged. QA08 remains partial; wider selection,
constraint icon styling/visibility and other acceptance cases remain open.

### September10: direct rectangle center padlock

QA08 remainspartial. Replaced generic center-Lock emoji badge with selected-center plain black direct toggle. Shared projected bounds route touch through Metal as well as SwiftUI mouse action. DirectLock finishes selection; Unlock retains it, matching two native repetitions. Final clean33/33 plus paired lifecycle, unchanged corners, Undo/Redo and galleryreopen verified. Full failed-attempt audit: `testing/sketch-parity-diagonal-matrix-2026-09-10.md`; signed-out Google publication queued in `testing/sketch-parity-publication-pending-2026-09-10.md`. Inventory4passed/0failed/1deviceblocked/51incomplete. No device readiness/IPA change.

September10 follow-up: selected-free rectanglecenter halo added after pointer-away native/clonecomparison; lockedcenter remainsplain. ExistingcenterUI1/1 and exact-build live passed; hitgeometry unchanged. QA08partial/Googlequeued/IPAunchanged. See same diagonal-matrix receipt.

September10: axis-rectangle supporting-edge colors corrected using cached nullspace coordinates. Left/top partial-Lock native samples and clone selected/unselected/Unlock/history/reopen verified; final36/36 clean. Native finalreopen retains locked corners; deselection capture unresolved. QA08 remains partial for other glyph visibility/publication. Same receipt and local queue,466/master38 last published.

September10: axisrect sideLock midpointglyph suppressed after paired selectededge/AlwaysShowConstraints comparison; contextualUnlock/history preserved, final31/31 after staleinchfixturecorrection, livefinalreopenpassed. Native visibilitypreference restored. QA08partial/publicationblocked. Same diagonal-matrixreceipt.

### September10 — center rectangle release control

Fresh center rectangles now select their center on release (tap and drag),
retaining width/height readouts and direct center padlock while the tool stays
armed. Lock clears both selection sets; native paired release/Lock/history
and saved recovery verified. Final combined26/26 after a retained readout
regression and corrected selector. QA09 remains partial for direction-dependent
leaders and remaining matrix; Google publication blocked by sign-out. Receipt:
`testing/sketch-parity-center-matrix-2026-09-10.md`.
