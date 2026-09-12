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

September 11 QA26 on-state closure: independent coplanar reference dimensions
must be suppressed while another sketch is edited, not just other-plane values.
`2fdecd6` scopes persistent dimensions by active sketch identity and preserves
idle visible-sketch labels plus active-hidden re-entry. Paired scope/Exit and
gallery reopen verified; focused21/21 then final29/29, illustrated841/master38.
QA25's broader off-state selection matrix remains separate and incomplete.

September 11 QA25 off-state finite selection recipe now verified: none/one/
several/disconnected saved owners paired, corrected29/29 ondb230f8, illustrated
852/master38 verified. Native mouse replacement versus clone additive taps is
recorded; area selection supplies native disconnected sets. Synthetic candidate
measurements remain QA28; offscreen layout remains QA29, physical input QA52.

### DM-03 · Absolute/horizontal/vertical distance choice is missing

**Finite QA-27 recipe verified; final54/54 plus paired exact-size/history/reopen** · P1

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Add a distance-type chooser and preserve the chosen kind through editing/save/undo.

Acceptance: The same reference points can show the three distinct intended measurements; choosing a type changes the driving constraint rather than only the displayed text.

September 11 checkpoint: a sloped single line now exposes Absolute,
Horizontal and Vertical Dimension actions, while axis-aligned lines retain the
unambiguous direct action. A 3-4-5 model recipe verifies all three stored kinds,
Undo/Redo and JSON persistence; the UI verifies menu choice, replacement,
commit and history. Final serial result is clean 18/18. Fresh paired live
capture and illustrated publication remain blocked by simulator input delivery,
so DM-03/QA-27 is not promoted. See
[adaptive-dimensions checkpoint](testing/sketch-parity-adaptive-dimensions-checkpoint-2026-09-11.md).

September 11 later checkpoint: `bbbfd2b` adds the native-observed label-adjacent
display-only badge for undriven lines. Final53/53 and paired menu/projections,
history and clone reopen verified; illustrated813/master38 publication verified.
Immediate choice deselection subsequently passed2/2 and live verification
with817-image follow-up publication. Exact live30/40/50 and driven variants remain open;
QA27 stays partial. Display choice and driving-dimension editing are distinct.

September11 final: `3016ac6` extends the badge to one plain numeric driver,
replacing kind/value atomically while preserving ID/references/geometry. Paired
native/clone exactH30/V40/Absolute50, Undo/Redo and gallery reopen verified.
Final combined54/54 (zero fail/skip). Illustrated827/master38 exports verified,
all ten new hashes once and no predecessor loss. Finite QA27 passed; formulas
and multiple matching drivers remain excluded pending specific evidence.

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

**Partial — implemented and clean 44/44; fresh paired gestures open** · P1

Evidence: [selection-anchor checkpoint](testing/sketch-parity-selection-anchor-checkpoint-2026-09-11.md). The persisted First Selected / Last Selected setting, ordered entity selection, transient solve anchor, reversed-order behavior, Undo/Redo, and saved-constraint priority pass model, settings, and portrait/landscape UI coverage. Official Shapr3D documentation supplies the reference semantics.

Next: Repeat both selection orders in native and the exact clone build once supported live canvas input is restored; capture the kept/moved entities and publish paired evidence without duplicates.

Acceptance: The specified anchor remains in place unless an existing constraint requires otherwise; reversing order has the expected result; undo restores all positions.

### DM-09 · Disconnect action is absent

**Partial — breadth implemented/tested; fresh paired cases open** · P1

Evidence: [Disconnect receipt](testing/sketch-parity-disconnect-2026-09-08.md): native and clone detached edge movement, Undo/Redo and gallery-reopened disconnection captured. Corrected clean34/34 after initial compile-only failure. Point-only/proximity/reconnection/import/trim covered automatically. Persisted endpoint exclusions prevent silent proximity rejoining; dimensions/other relations retained.

September 11 automation adds Midpoint, explicit circle-center Coincident and primitive-rectangle diagonal-corner Disconnect without decomposing geometry. Dimensions, unrelated Equal Length, history, serialized exclusion markers, merge and Trim integrity pass a clean 58/58 gate. Next: paired live repetition of those three new connection forms. Single-line default ring and Copy proximity coupling are corrected (see [line-control receipt](testing/sketch-parity-line-selection-controls-2026-09-08.md)); explicit white axes versus blue ring remains.

Acceptance: The chosen connection breaks without deleting geometry, other constraints survive, and undo restores the connection.

### DM-10 · Numeric entry supports only a subset of explicit unit tokens

**Queued — implementation needed** · P2

Evidence: CODE-CONFIRMED GAP — reference from live UI or official documentation

Next: Unify unit-aware parsing and formatting, with typed units overriding display units; reject incompatible dimensional units clearly.

Acceptance: Supported explicit units convert once and correctly; unsupported strings never silently become a different length; formulas preserve semantic units.

### DM-11 · Rectangle width-to-height numeric flow needs keyboard and touch A/B

**Current-tree sequence passes clean 4/4; fresh live repeat pending** · P1

Evidence: VERIFY — candidate discrepancy, not reproduced

Next: Implement explicit next-field behavior, visible width/height focus and correct anchor preservation.

Acceptance: 40 by 25 can be entered without closing and rediscovering a second control; geometry and persisted driving dimensions both match.

September 11 checkpoint: an edge-positioned rectangle accepts width through the
numeric keypad, retains the adjacent height control, accepts height through the
system keyboard, and restores each step through Undo/Redo. The related serial
gate passes clean 4/4. Retained paired sizing evidence exists, but fresh
exact-build live/publication remains input-delivery blocked; QA-30 is not
promoted. See
[rectangle sequence checkpoint](testing/sketch-parity-rectangle-sequence-checkpoint-2026-09-11.md).

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

**Finite core recipe verified; broader relation matrix remains** · P1

Evidence: paired live conflict/Lock/history evidence plus clean 69/69 QA-39 gate

Next: Complete QA-36's fresh all-relation live sweep and remaining physical-input
coverage; retain QA-39's verified refusal/rollback and point/entity Lock boundary.

Acceptance: No unexpected geometry jump or broken existing constraint; conflict identifies relevant controls; undo leaves one coherent prior state.

September 11 Equal checkpoint: `696e8cd` fixes confirmed free-line direction
drift during Equal sizing while preserving saved-constraint precedence. Final
90/90 clean; paired exact sizing/history/gallery reopen verified, illustrated
873/master38 publication verified. QA36 remains partial for Equal Radius,
Symmetric and the remaining relation sweep. See the
[constraint-types receipt](testing/sketch-parity-constraint-types-checkpoint-2026-09-11.md).

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

### September10 — center-specific dimension leader directions

Fresh four-quadrant native checks establish width opposite vertical drag and
height toward horizontal drag (not diagonal rectangle's rule). Persisted center
creation-direction variants preserve solver center sizing and selected-edge
overrides. Corrected final27/27, live allfour clone releases, paired two-axis
size/history and saved recovery verified. Earlier passing incorrect expectation
withdrawn in receipt. QA09 remains partial; half-tie display0.435→0.434 after
height edit remains separate numeric diagnosis. Google publication blocked.
Evidence: `testing/sketch-parity-center-matrix-2026-09-10.md`.

### September10: center sizing readout precision and unchanged accept

Compact millimeter labels now expose four decimals, matching native0.4345.
Numerical solver residuals no longer flip a satisfied dimension across a rounding
tie. Paired height edits/history and clone saved recovery retain0.4345.
Unchanged driving-dimension acceptance now skips redundant update/solve/history;
paired native and live clone Undo/Redo pass. Clean36 unit checks, then retained
1pass/1failure numeric run, corrected3/3. QA09 still partial (constraints, broad
UI and signed-out publication remain). Receipt: testing/sketch-parity-center-matrix-2026-09-10.md.

### September10 QA09: confirmed locked-center rotation gap

Native centerrectangle with centerLock and both2mm sizes remains rotatable by
cornerdrag; center/sizes preserved, cornersblue, Auto-constrainingON. Clone
centerLock + bothsizes marksfullyconstrained and refuses analogouscornerdrag.
Do not patchcolor alone: axisrect representation has no orientation, and naive
4lineconversion would invalidate center/dimensionreferences. Scoped migration
needs validated reference remapping, dimensions, constraints, history/persistence
and controls. Native rotation undone; clone unchanged. Receipt center-matrix.
QA09 stayspartial; this is a blocking behavior difference, notfullparity.

QA09 rotation integrity: explicitgizmorotation deleted primitivecenterLock and
bothdimensions duringdecomposition (savedJSONconfirmed). Interimguardnowrefuses
referencedprimitive-rectangle rotation, retainsintent/history. Clean12/12 andlive
refusal/Itemsretention verified. This fixesdata loss, NOTnative rotationalfreedom;
safe migration remains blocking. Receipt center-matrixSeptember10.

## September 10 — Center-locked rectangle rotation integrity

Native permits direct corner rotation with a fixed center and two driving sizes.
Safe center-rectangle migration now uses four constrained lines with retained
center/dimension IDs and arithmetic source; one Undo restores the primitive.
Persisted ordered edge identity survives attached branches and is remapped on
project insertion. Deleting a defining edge removes dependent center references
in the same undoable edit. Canonical endpoint distance refs avoid duplicate or
ignored sizes; center-locked numeric edits preserve direction transiently.
Paired rotation/size/center checks and final gallery reopen verified; final
related regression clean **74/74** after retained red/fixture failures. See
[center matrix receipt](testing/sketch-parity-center-matrix-2026-09-10.md).
Illustrated report now472 placements/470media; all6new hashes and predecessor
text/images verified. Earlier publication backlog still pending. QA-09 remains
partial: ring/glyph/selection presentation, broader references and device inputs
are not closed. Unsupported referenced diagonal rectangles remain protected by
refusal. Immutable05be744 IPA unchanged; no new readiness claim.

## September 10 — Rotated center rectangle explicit controls

`dcb69b3`: after center-rectangle migration, require explicit Move/Rotate rather
than a default ring. Clean3/3 and live rotation/controls/geometry history/reopen
verified. Illustrated481/master38 publication verified without prior loss.
Native internal relation visibility comparison confirms another presentation
gap; its correction is under regression, not yet live-verified. QA09 remains
partial; immutableIPA unchanged. See center-matrix receipt.

## September 10 — Migrated rectangle structural badges

Suppress implicit parallel/perpendicular/coincident badge cluster for saved
migrated rectangle groups; keep model/Items rules, explicit rule selection and
conflict visibility. CenterLock uses existing control. Clean12/12 after compile-
only failure; live edge/centerUnlock/movement/history/Items-rule/reopen verified.
Illustrated490/master38 export verified. Selected-edge dual saved dimensions
remain a confirmed follow-up; no QA09 closure.

## September 10 — Single-side saved rectangle readouts

Saved migrated center rectangle exposes both driving sizes when one edge is
selected; no duplicate opposite-side candidate. Matching size leader follows
selectedparallel side without modifying drivingrefs/measurement. Final13/13
includesall4side edit/Undo anddivergentoppositeside guard. Paired live height
edits/history/finalreopen plusfinalbuildsavedreadoutverified. Earlierfixture
andcompile-only failures retained. Editoropening stillresetsselectedoppositeside
todrivingedge; nativecomparisonpending. No fullQA09/deviceclaim.

Selected-side editor correction: clean13/13, paired open/Escape and sizing
history, final gallery reopen verified. Illustrated513 placements/all4postfix
hashes plus5diagnosis hashes/no predecessor loss; master38 dated note and full
prior text/images verified. Exports `/tmp/os3d-qa09-editor-fixed-published.docx`
and `editor-fixed-master.docx`. Native opposite-side annotation distinction
remains open; QA09/inventory unchanged. See center-matrix September10 receipt.

Migrated endpoint-drag selection cleanup: red1test/2assertions followed by
clean14/14; paired live cornerrotation/history/finalreopen. No default ring or
zero candidate; endpoint-vs-edge selection appearance remains open. Illustrated
524/all5newhashes/no predecessor loss and master38 dated note/text/images
verified in `/tmp/os3d-qa09-cornerfix-{published,master}.docx`. Receipt/evidence
center-matrix September10. Inventory unchanged4passed/1blocked/51incomplete.

Selected migrated endpoint and adjoining leaders: final clean14/14 in
`/tmp/os3d-qa09-corner-leaders-20260910.xcresult` after initialmarker14/14.
All8endpointreferences retain savedrefs/values and attachbothleaders tocorner.
Paired oppositecorner pointer-away samples verifyorangehalo/noedgehandle/ring
andadjoiningsides. Nativeadditional4mmannotation remains. Exact-buildclone
relaunch/galleryItems retains1.9795×0.5/centerLock; finalnativegallery8×4.
Illustrated530/all6hashes/no predecessor text/image loss; master38datednote
verified: `/tmp/os3d-qa09-pointleaders-{published,master}.docx`. Remaining
historyselection-clearing, extraannotation and broaderQA09 stillopen.

### September 10 — migrated corner history selection

Confirmed native clears the selected corner/readouts through rotation Undo/Redo;
clone retained them. Narrow history preparation cleanup passes first clean14/14
and live Undo/Redo, reselect and gallery reopen. Geometry and saved dimensions
unchanged. Illustrated536/master38 export verified; QA-09 remains partial.
Receipt: `testing/sketch-parity-center-matrix-2026-09-10.md`.

### September 10 — nonblocking dimension constraint refusal

Paired center+corner Lock refuses conflicting width without geometry changes;
clone modal differed from native notice. Dimension refusal now uses the notice.
First clean7/7 includes exact rollback/no extra history. Paired Unlock/recovery,
Undo/Redo and gallery reopen passed. Illustrated541/all5 hashes/master38 verified.
Corner editor selection and Lock point glyph remain open; QA-09 partial.

### September 10 — corner dimension editor selection lifecycle

Migratedcorner staysselected through distanceeditor open/Escape/refusal; valid
commit clearsit, matchingpairednative. No wholeedgehandle introduced. Initial
14/14 thenfinal14/14; livecommit/history andclonegalleryreopen passed. Published
546/all5hashes/master38. Nativebadgeoutline/oppositereadout and lockedcornerglyph
remainopen. Fullreceipt center-matrix September10; QA09partial.

### September 10 — migrated locked-corner marker parity

Validfourline savedrectangle endpoints nowretain hollowcornerstyle; default
endpointLockglyph no longer coverspoint. Explicitinspection/conflict remains.
Firstclean14/14 andpairedliveLock/Unlock/history/reopen. Published551/all5hashes
/master38. Unrelatedlinemarkersunchanged; selecteddimensionoutline/opposite
annotationremainopen. QA09partial; receiptcenter-matrixSeptember10.

### September 10 — selected corner-size outline

Selected saved rectangle size gets native white/blue outline after Escape while
its corner remains selected; reselection returns plain text. First clean14/14
and paired live states verified; no geometry edits. Published555/all4hashes and
master38. Native extra opposite-side annotation remains under diagnosis.


## Migrated rectangle adjacent readouts — September 10

Selected single side exposes selected length and both adjacent lengths, matching
four native side samples. Extra label shares saved dimension/solver refs; editor
preserves original edge selection. Corner remains two. Clean14/14, live aliases,
width edit/history and paired reopen; illustrated561/master38 verified. QA09
partial: selected-edge commit/history lifecycle remains separately open.


## Migrated side-size commit/history selection — September 10

Successful size commit clears selected migrated edge/handle and retains both
parallel presentations of selected saved size through Undo/Redo. Cancel/refusal
retainselection. Clean14/14, pairedcommit/history and finalgalleryreopen;
illustrated567/master38 with all6hashes and no predecessorloss verified.

## September 10 — axis selected-size commit cleanup

Successful explicit axis-rectangle side size commits now clear entity/handle
selection and retain the edited dimension on the chosen side through history.
Cancel/refusal paths are unchanged. Initial 41/42 exposed erased side metadata;
corrected same-set rerun passed 42/42. Live right commit/Undo/Redo, left cancel
and commit, and paired gallery reopen are captured. Fresh native center first
commit matches this lifecycle; previously dimensioned opposite-side extra
labels remain a separate open visual case. Illustrated608/master38 publication
verified. [Closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md).

## September 10 — axis adjacent and saved-side readouts

Selected axis sides now choose the preceding adjacent edge for the other size.
Committed sides persist as optional presentation metadata; aliases share the
same dimension/refs, including after an opposite-side edit. Initial41/41, then
59/59 plus storage1/1 passed separately; live history exposed stale placement,
corrected in final59/59. Paired latest Undo/Redo and gallery reopen passed.
Illustrated616/master38 verified. Legacy unknown sides retain defaults; no
invented metadata or solver equations. Bottom keypad/transform-chip overlap
remains the next confirmed UI gap. See rectangle closure audit.

## September10 — Axis editor clearance and reselection

Dimension editing hides unrelated sketch Move/Rotate/Copy controls so they do not
cover the keypad. Axis-edge toggle checks actual entity selection, not retained
annotation-side metadata; after a successful size commit, same-edge reselection
works again. Live bottom-width entry, same-edge handle, Undo/Redo and paired
saved reopen verified. Regression29/30 plus corrected center-rotation1/1; retained
fixture failures and evidence in [rectangle closure audit](testing/sketch-parity-rectangle-closure-audit-2026-09-10.md).
Illustrated624/master38 export verified; no new IPA/device claim.

## September10 — Three-point pending measurement and Escape

Released three-point baseline readout no longer intersects its leader; scoped
white/blue outline and offset preserve geometry and hit routing. Rectangle was
missing from keyboard Escape registration despite a visible Cancel button.
Added guarded unfinished-clear then idle-disarm lifecycle, with dimension editor
priority preserved. Paired live pending cancellation/disarm retains committed
geometry. Clean29/29 and separate3/3 readout run; [receipt](testing/sketch-parity-three-point-matrix-2026-09-10.md).
Pending numeric interaction and broader QA10 direction/visual criteria remain open.

### September 10 — pending three-point baseline keyboard sizing

Valid native two-tap baseline accepts bare digit entry before the third point.
Clone now opens the existing numeric field with hardware focus; Return sizes
the pending baseline around the first point, with geometry and optional driving
dimension committed together only on completion. Cancellation drops the draft.
Moved live measurements below the opaque editor after live overlap diagnosis.
Clean23/23 plus final3/3. Paired one-step geometry Undo/Redo and gallery reopen
retain native15×7 and clone1.5×0.9664. QA-10 remains partial: release selection
and native Undo disarming versus clone tool retention remain open. Receipt:
[three-point matrix](testing/sketch-parity-three-point-matrix-2026-09-10.md).
Illustrated640 placements (five final hashes present; completion duplicated),
master38 dated note, predecessor image counts and ordered text preserved.

September10 followup: committed three-point Undo now disarms Rectangle, with
Redo retaining disarmed state; pending cancellation stays separate. Clean4/4
and paired live geometry/tool-state evidence. Illustrated642/master38 verified.
Release-center selection remains open; see current three-point matrix receipt.

### September10 — fresh three-point rectangle center controls

Persist ordered four-line identity without center-sizing intent/automaticLock.
Release nowselectscenter,showsdirectpadlock/twosizes andhidesimplicitglyphcluster.
DirectLock affectscenteronly,clearsselection; Unlockretainsfreehalo. Paired
translation/history andsavedcentercontrol verified. Historyclearscenterselection;
center-rectangleparallelannotationaliases donotapplytothreepointgroups.
Initial32/33caughtrealoverlock, corrected33/33, existing3/3, history5/5, final6/6
separateruns. Illustrated653/all7hashes/master38 verified; legacygroupless
rectanglesandremainingcompletiondirections remainopen inQA10. See currentreceipt.

## September 10 pending three-point baseline color

Released pending baseline now uses native orange; other construction previews
and committed geometry retain their colors. Clean4/4 and paired live draft
cancellation/completion evidence, illustrated660/master38 export-verified.
Legacy group recovery is dirty/tested51/51 but live controlled import blocked;
not counted as live parity. QA10 remains partial; inventory6/0/1/49 unchanged.

## September 10 conservative legacy three-point identity recovery

Decode restores ordered control identity only for isolated four-line rectangles
with the full directed original seven-constraint signature. Existing groups and
sizing intent are preserved; disconnected/incomplete/branched/external/pattern
ambiguities decline recovery. No geometry/dimension mutation. Clean54/54 after
retained compile-only fixture error and41/51 earlier passes. Controlled legacy
archive fixture (production importer via temporary diagnostic, not file-picker
acceptance) passed live center Lock/Unlock/move/history/reopen; native reference
repeated. Illustrated667/master38 verified. QA10 still partial.

## September 10 pending three-point leader layout

Paired100/200pixel native baselines retain fixedleader spacing andselectedvalue
outsideleader. Clone proportionaloffset/insidevalue corrected to completed-
rectangle100applicationpoint spacing/outervalue24points. Prior toward-geometry
interpretation withdrawn. Clean5/5 andlive two lengths/typed1.5/Return/completion/
history/galleryreopen verified. Illustrated677/master38 verified. No exact
macOS/physical-iPad pixelsignoff; directlabelactivation remainsuntested.

### September 10 — pending three-point direction/precision correction

Released baseline now uses four-decimal compact precision and positions its value above the readable leader in either horizontal direction. Prior universal outside interpretation withdrawn; fixed screen-space spacing retained. Clean final5/5, paired completion/history/reopen; clone synthetic keyboard delivery did not act, toolbar verified. Illustrated687/all4finalhashes/master38 verified. QA10 remains partial. See three-point-matrix receipt.

### September10 QA10 finite recipe closure

Original rotatedbaseline/perpendicularheight/each-stagecancellation now paired, including reverse slopes and settled native firstpoint hover/Escape. Product5014cef pushed; final36/36 and illustrated700/master38 closure note verified. Full audit in testing/sketch-parity-three-point-closure-audit-2026-09-10.md. Inventory7passed/0failed/1deviceblocked/48incomplete; nextQA11concentric initiation. General keyboard/layout/import/device gates remain. Immutable05be744IPA unchanged.

### September10 QA11 center-selection distinction

Native freshcirclecenter is selected/Lockable and dragsgeometry; unselectedcenter startsconcentric. Clone freshcenter insteadhollow anddiameterhitarea stole drag. Scopedrelease/centercontrol/hitexclusion draft passesinitial10/10 andlivemove; lifecyclefollowup8/2 caughtoverbroadreadoutcleanup, same10rerunpending. Detailedconcentric-matrixreceipt preservesoldsamplepass andnewdiagnosis. Publication705 verified; notclosed.

QA11 follow-up September11: narrowed lifecycle clean10/10; selected equal-center target correction clean11/11. Live release/move/Undo/Lock/reopen verified; illustrated711/all6hashes. Matched snapping relationships remain open. See concentric receipt.

## September11 QA11 finite closure

Selected/unselectedcenterinitiation, savedconnection/clearlinkcontrol, paired
movement/history/reopen nowverified. Clean35/35 plusseparatefinal6/6; illustrated
724/all9hashes/no715loss. Finalclone1.4852/.8645; native16.0041/9.3357. Draft
.8708 unverifiedvaluewithdrawn/corrected. Nativepopoverblockedhistory excluded;
cleanrepeatpassed. Inventory8/0/1/47 (36partial11deferred). Audit
testing/sketch-parity-concentric-closure-audit-2026-09-11.md. No runner.
Exactnext commit/pushconnection+glyphclosure, thenQA12radius/diameter modes.
Cloneinnerselectedat460720; nativeinnerselectedat726422, bothtooloff.
Masterclosureinsertedonce/exportverificationpending; IPAunchanged.

## September 11 — Circular annotation preference and radius clearance

DM-04/QA-12: persisted Always Radius / Radius and Diameter preference now
converts circle labels/edit seeds without resizing or duplicating driving
dimensions. Real edits retain dimension identity; unchanged converted seed
preserves saved expression/history. Live nativeR5↔Ø10 and cloneR1↔Ø2,
center preservation, Undo/Redo and gallery reopen verified. Radius leader
now reserves side-control/text space after liveR1.5 rail obstruction. Final
relevant21/21 clean, earlier persisted-preference fixture failure retained.
QA12 remains partial for numeric-circle selection cleanup and remaining
creation-mode checks. Receipt: testing/sketch-parity-circle-annotation-modes-2026-09-11.md.

QA12 follow-up: disarmed-circle successful numeric commits and numeric
Undo/Redo now clear selected rim/readout, matching paired nativeR5→R4 and
cloneØ3→Ø2. Free radial/explicittransform excluded. Final11/11 clean after
retained selection-fixture failures; paired savedR4/Ø2 recovery verified.
Armedcreation/numeric matrix remains open; see samecircle-annotationreceipt.

QA12 armed follow-up: compact fresh radius leader, selected numeric radius badge
and direct dimension Unlock now paired live. Unlock preserves size; its Undo/Redo
clears selection/disarms Circle. Final12/12 controls plus10/10 history clean;
prior11/12 fixture failure retained. Paired nativeR3/cloneR.3 gallery reopen
verified. Illustrated756/all9hashes/master38 verified. Reverse creation/cancel
remain; no QA12 closure yet. See circle-annotation-modes receipt.

QA12 closure September11: Always Radius creation now persists its release
direction as presentation-only sketch metadata, so reverse/vertical/diagonal
leaders retain their creation side through sizing, history, decoding and gallery
reopen. Circle Escape has the same no-history cancellation route as the other
sketch tools: it clears pending input and disarms Circle while retaining the
completed geometry and selected radius badge. Legacy sketches decode with no
direction metadata and keep prior behavior. Paired native/clone reverse release,
R3/R0.3 sizing, Escape, Undo/Redo and reopen passed live. Final relevant current-
tree regression passed cleanly 22/22. The earlier XCTest Escape injection failure
is retained as an input-delivery limitation, not counted as UI evidence; exact-
build Peekaboo verification passed. Illustrated764/all six closure hashes and
master38/one note export-verified. QA12 is closed; inventory9/0/1/46. Physical
Pencil/touch and updated device installation remain separate gates.

## September 11 — QA-15 polygon finite closure

The current implementation retains polygon identity, center, radius, side
count, and first-vertex rotation while editing the post-creation count or
radius. Count edits are dimensionless and atomic: invalid lower/upper bounds and
divide-by-zero do not add history; fractional values truncate consistently;
Undo/Redo restores the complete prior entity. Release still retains both
readouts without forcing the keypad, and a closed polygon remains available as
a profile.

Paired live checks verified 5→65 count edits, exact radius changes, two-step
Undo/Redo, and gallery reopen. Native's count badge is only available
immediately after creation, so the clone's retained primitive identity after
reopen is not used to demand a native control that does not exist. The final
corrected combined regression passed 13/13. Two earlier 12/12 runs omitted the
boundary method because their selectors named the source file/wrong declared
class; they remain recorded, not promoted. Illustrated772/master38 publication
is export-verified. QA-15 is closed only for its finite recipe; constraints,
hover, and physical Pencil/touch remain separate acceptance lanes.

## September 11 — QA-18 midpoint input-routing checkpoint

Native Shapr3D and OpenShape3D now both start a Circle at an existing
horizontal-line midpoint, retain the source line, and preserve the resulting
geometry through Undo/Redo. The corrected clone also retains the profile after
gallery reopen. The confirmed clone failure was presentation hit routing: the
visible H constraint glyph intercepted a stroke while Circle was armed.
Ordinary constraint glyphs now remain visible but do not hit-test while a
drawing tool owns the canvas; dedicated center Lock controls remain separately
interactive. The corrected focused run is clean 2/2. Its preceding 0/2 run is
retained as a fixture failure because it assumed diameter labels while the
saved Always Radius preference correctly produced radius labels. QA-18 remains
partial until face-corner initiation is paired; this checkpoint does not infer
a persistent midpoint relationship or change the 10/0/1/45 inventory.

## September 11 — QA-18 drawing-on-points closure

The same corrected build was exercised on a newly extruded top face in both
apps. Circle initiation at the corresponding face vertex succeeds; Undo removes
only the circle, Redo restores it, and the clone gallery reopens with the circle
still centered on that face corner. Together with the already paired endpoint,
existing-circle-center, rectangle-corner, and line-midpoint cases, this closes
the finite QA-18 placement recipe. A single final serial run passed 13/13:
`FaceSnapTests`, the sketch-on-face downstream workflow, and the two armed-
Circle point-routing workflows. Illustrated publication is verified at 786
media with all seven closure hashes once and no loss from 779; master remains
38 media. Inventory is 11/0/1/44. This does not claim persistent midpoint
linking, topology editing, hover, or physical Pencil/touch parity.

## September 11 — QA-13 finite arc closure reconciliation

The original SK-10/QA-13 recipe is now closed without absorbing separate hover
or device lanes. Existing paired evidence covers endpoint/default-side input,
third-point shaping, Return, shared-endpoint chaining, two-stage cancellation,
direct minor/semicircle/major categories, and inferred line-to-arc tangency.
The current-tree UI gate additionally proves persisted Radius/Diameter-aware
90→360 conversion with Undo restoring the 90-degree arc and Redo restoring the
selected full circle. The final serial regression passed 63/63. The preceding
62/63 run and targeted fixture failures are retained; they were caused by a
stale Diameter-only expectation, draw-tool state, and coordinates that no
longer lay on the edited arc—not product failures. Inventory advances to
12 passed / 0 failed / 1 device-blocked / 43 incomplete. Pointer hover remains
QA-21, physical Pencil/touch QA-52, and QA-19's native threshold pair remains
blocked by desktop input delivery. See the September 11 arc closure audit.

## September 11 — QA-05 Return/resume checkpoint

Return now finishes an open polyline without disarming Line or changing committed history, and a subsequent endpoint tap starts a fresh chain at that saved endpoint. The corrected exact-tree LineChain suite passes clean 3/3, including strengthened exact history counts and order-independent snap settings. Exact-build live clone A→B→C, Return, B→D→E→B, closing-edge Undo/Redo, and gallery reopen passed. Fresh native Line entry and the Return/Escape/Delete prompt are captured, while native canvas clicks remain a desktop input-delivery blocker. QA-05 therefore remains partial and inventory remains 12/0/1/43. See testing/sketch-parity-line-chain-2026-09-11.md.

## September 11 — QA-06 finite cancellation closure

The retained paired evidence covers Escape once/twice, Delete/Backspace,
released-state Return/double-click, Line→Arc switching, exact history and gallery
reopen. A current-tree serial closure run passed clean 5/5 at
`/tmp/os3d-qa06-closure-combined-20260911.xcresult`. QA-06 is closed only for
this finite recipe; hover remains QA-21, physical input QA-52, and QA-05's fresh
native chain remains input-delivery blocked. Inventory advances to 13/0/1/42.
See testing/sketch-parity-line-delete-2026-09-10.md.

## September 11 — QA-23 finite selection-state closure

Retained paired evidence covers exact endpoint versus short-edge midpoint,
outline/profile selection, and blank deselection. Exact-build clone profile and
outline selection, selected-outline Delete, one-step Undo, and gallery reopen
were repeated live. The current-tree selection/hit-priority baseline is clean
19/19. The illustrated append did not persist and anonymous export remains at
786 media, so QA-23 is closure-ready but not promoted; inventory remains
13/0/1/42. Additive selection, hover,
comprehensive dimension selection, and physical input remain separate lanes.
See testing/sketch-parity-selection-state-closure-2026-09-11.md.

## September 11 — QA-24/25 selection and annotation checkpoints

QA-24 has a clean 19/19 current-tree automation baseline for additive selection,
window/crossing marquee, filters, three-body atomic Delete/Undo, and Select
Through. Native Shift/additive and an independent live seeded-state repeat are
still open, so the case is not promoted.

QA-25's final current-tree gate passes clean 23/23 for saved annotation ownership
with Always Show Dimensions off: none, one, several, and disjoint same-sketch
selection. The initial saved-preference fixture failure and an expected synthetic
0-degree selection candidate are retained separately. Fresh paired live capture
remains blocked because resolved Peekaboo foreground events do not reach the
Simulator canvas after scoped Peekaboo and simulator restarts. Publication is
also pending. Inventory remains 13/0/1/42. See the QA-24 and QA-25 September 11
checkpoints under `docs/testing/`.

## September 11 — QA-33 upper-count diagnosis reconciled

Completed exact-tree19/19 gate verified without rerun. Native10001 remains an
unresolved busy operation, not an accepted count or verified refusal; clone10000
ceiling is defensive. Illustrated803 media (+3/no predecessor loss) and master38
with one dated note are export-verified. QA33 remains partial, inventory22/0/1/33.
See [invalid-input receipt](testing/sketch-parity-invalid-recovery-2026-09-09.md).


## September11 evening — QA05 line-chain closure

Fresh native open A→B→C, Return, B-resume→D→E→B, closing-edge Undo/Redo,
filled profile and saved five-edge reopen now agree with retained exact-build
clone evidence. Current1fdb6a3 serialLineChain gate3/3; no new product change.
Illustrated863/master38 verified, ten source hashes plus one visuallyverified
Google-downsampled clone reopen and no852 predecessorloss. QA05 finite PASS;
inventory26/0/1/29. Physical/hover remain separate. See line-chain receipt.


### September 12 QA36 Symmetry paired checkpoint

`5a3687e`: circle operands→Symmetry→axis selection, cancellation, atomic solve,
history and gallery persistence verified in changed clone and native. Final
serial64/64 zero failures/skips; illustrated891/master38 publication verified
with ten hashes once and no predecessor loss. QA36 remains partial: settled
native history-axis selection, independently unequal native radii and other
Symmetry element types remain open. Inventory26/0/1/29; iPad unchanged. See
[constraint receipt](testing/sketch-parity-constraint-types-checkpoint-2026-09-11.md).


### September 12 two-line Symmetry paired checkpoint

`bcc70c1` adds two-line axis picking with persistent endpoint correspondence;
`ebf4c37` verifies final76/76. Fresh matched Last Selected application, Undo/Redo
and gallery reopen preserve the fixed operand/axis and reflected line in both
apps. Illustrated903/master38 verified, eight hashes once/no predecessor loss.
QA36 remains partial for the remaining relation sweep; inventory26/0/1/29.
See the constraint-types checkpoint for exact fixture values and evidence paths.


### September 12 Perpendicular length correction

`fd16cee` fixes paired free-line length blowup during Perpendicular. Before0/1
reproduced; focused4/4 and final78/78 pass. Changed live90degree application,
Undo/Redo and gallery reopening preserve1.2291mm; native preserves70.8204mm
in its fixture. Illustrated911/master38 verified with eight hashes once/no loss.
Selection cleanup and unconstrained placement remain explicit follow-ups;
QA36partial26/0/1/29, iPad unchanged.


### September 12 Perpendicular selection follow-up

`3a337c2` scopes successful application/history deselection to Perpendicular;
refusal retains operands. Final80/80 and changed live apply/Undo/Redo/gallery
reopen pass; exact1.2291mm/glyph persist. Illustrated915/master38 verified,
four hashes once/no predecessor loss. Earlier selection gap is superseded;
unconstrained free-line placement still differs. QA36partial26/0/1/29.


### September 12 Midpoint selection follow-up

Source9659fec/test279a34b: final82/82 zero fail/skip, paired successful apply,
selected history and gallery reopening. Refusal retains operands. Native
319.7689mm target and clone1.2371mm target/saved Midpoint persist; free-target
anchor/placement difference remains explicitly open. Illustrated925/master38,
ten hashes once/headings once/no predecessor loss. QA36partial26/0/1/29;
no runner, iPad unchanged. Next point-plus-line Coincident comparison.


### September 12 Coincident point-on-line capability

Sourceaabbf7f enables one selected point plus a distinct line, using existing
point+whole-line lowering and scoped successful/history deselection. Own-line
point rejected; locked refusal retains operands. Final84/84 and fresh paired
extension projection/history/reopen pass, target159.8835mm native/1.2371mm clone
preserved. Illustrated935/master38 verified, ten hashes once/no predecessor loss.
QA36partial26/0/1/29; next manual Tangent sweep, no iPad claim.

## Tangent application correction — September 12, 2026

QA-36 remains partial. A fresh native/clone comparison confirmed free-circle
Tangent application could resize and move the clone circle far along a nearly
horizontal target. Source `b8cf6b7` adds an application-only radius/projection
preference with saved-constraint fallback and native-observed selection cleanup.
Final86/86 passed after focused1/1 and expanded2/2. Changed-build application,
selected Undo/Redo and both gallery reopenings verified; illustrated945/master38
retain all predecessor media and ten new hashes exactly once. [Tangent receipt](testing/sketch-parity-tangent-application-2026-09-12.md)
records exact persisted geometry, Undo restoration and the evidence boundary.


## Fixed-circle Tangent line preservation — September 12, 2026

Source `2b89368` fixes the reverse case: a driving-size, center-locked circle
previously displaced and lengthened its free tangent line. Application-only
length/endpoint preferences yield to saved relationships and persist no extra
constraints. Final87/87 passed, with changed-build paired exact line values,
Undo/Redo and both gallery reopenings. Illustrated955/master38 verified, ten
hashes once/no predecessor loss. QA36 remains partial26/0/1/29. [Reverse Tangent
receipt](testing/sketch-parity-tangent-reverse-2026-09-12.md).

## Concentric selection cleanup — September 12, 2026

Source `2e84f84` clears successful Concentric application and history operands;
refusal preserves selection. No geometry solver change. Final **88/88** in one
serial run plus paired exact radii, selected history and both gallery reopenings.
Illustrated965/master38 verified, ten new hashes once and no predecessor loss.
[Concentric receipt](testing/sketch-parity-concentric-application-2026-09-12.md).
QA36 remains partial; external two-circle Tangent is recorded below.

## External circle Tangent — September 12, 2026

Source `becd8ed` adds separated full-circle external contact with fixed-center
safe solver seeding and transient radius preservation. Final90/90 passes in one
serial run. Fresh native/changed-clone application, exact radii, geometry history
and both gallery reopenings pass. Illustrated975/master38 exports verified:
ten new hashes once, no predecessor loss. Nested/overlap/arc pairs remain disabled;
native Redo highlight detail unresolved. QA36partial26/0/1/29. [Receipt](testing/sketch-parity-circle-tangent-2026-09-12.md).

## Nested circle Tangent — September 12, 2026

Source5f4ab54 persists the internal/external circle contact branch, with legacy
nil preserving external behavior and import remap retaining metadata. Native and
changed clone preserve radii/inner center, apply internal contact, and pass
geometry Undo/Redo and both gallery reopenings. Final93/93 clean in one serial
run. Illustrated985/master38 verified, ten hashes once/no predecessor loss.
Native Redo highlight and intersecting/arc variants remain open; QA36partial.
[Receipt](testing/sketch-parity-nested-tangent-2026-09-12.md).

### September 12 — intersecting-circle Tangent paired checkpoint

Source76dd2b0, final94/94 clean. Native shallow/deep overlap resolves to
external/internal contact respectively; changed clone preserves both radii,
second center, geometry Undo/Redo and gallery reopening. Native deep history
and both reopened branches verified. Illustrated996/master38, eleven new
hashes once/no predecessor loss. Receipt:
[intersecting-circle Tangent](testing/sketch-parity-overlap-tangent-2026-09-12.md).
QA36 remains partial: exact halfway/equal-radius overlap and arc pairs are not
freshly paired. Inventory26/0/1/29; physical iPad unchanged.

### September 12 — equal-radius internal Tangent paired checkpoint

Source5ddba88 permits internal zero-distance contact without deleting either
circle. Final95/95 clean, paired native/changed-clone geometry history and gallery
reopen verified; saved clone retains two IDs and two Ø1 dimensions. Illustrated
1005/master38, nine hashes once/no predecessor loss. QA36partial26/0/1/29;
exact halfway, initially coincident and arc variants remain unverified.
[Receipt](testing/sketch-parity-equal-contact-2026-09-12.md).

### September 12 — already-concentric equal circles accept Tangent

Sourcec6dee5d, final96/96 clean. Native/changed clone relation addition without
geometry change, constraint Undo/Redo and both gallery reopenings verified.
Clone saved identities, Concentric/internal Tangent and two Ø1 values retained.
Illustrated1014/master38, nine hashes once/no predecessor loss. Clone uses
Exit→Select marquee→Done→Items reopen to select both coincident edges; native
uses in-sketch box. This UI-route difference remains open. QA36partial26/0/1/29.
[Receipt](testing/sketch-parity-initial-coincident-2026-09-12.md).

### September 12 — free arc/circle external Tangent

Source108eec3; final98/98 clean, no failures/skips. Native/changed-clone
visible-span external contact preserves arc radius/sweep and preferred circle;
Undo/Redo and both gallery reopenings verified. Clone drawn180.02degrees stays
180.02degrees; model test exact180. Saved external contact residual0.0.
Illustrated1023/master38, nine hashes once/no predecessor loss. Off-span,
overlapping/nested arc/circle and arc–arc remain unsupported/unverified.
QA36partial26/0/1/29. [Receipt](testing/sketch-parity-arc-circle-tangent-2026-09-12.md).


### September 12 — off-span arc/circle Tangent

Sources49ac92e/007181c enable separated supporting-circle contact beyond the
visible arc and scope its complementary dashed guide to annotation visibility.
Corrected final99/99 clean. Paired geometry/history/both reopenings and settled
none/arc/circle guide states verified. Clone R0.4947/179.59degrees preserved;
saved externalContact residual0.0, no added dimensions. Immediate native
postapply transient timing remains unclaimed. Illustrated1033/master38, ten
hashes once/no predecessor loss. Overlapping/nested arc-circle and arc-arc
remain unverified; QA36partial26/0/1/29.
[Receipt](testing/sketch-parity-offspan-tangent-2026-09-12.md).
