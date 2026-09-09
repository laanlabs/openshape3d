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

**Queued — verify first** · P1

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
