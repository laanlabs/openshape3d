# Core-sketch milestone: complete original acceptance map

Starting revision `cd0937d`; September 8, 2026. All 56 original cases retained.
Partial evidence is **not** a case pass. No complete case is promoted to covered by this reconciliation. All device tests remain pending. Existing audit remains unchanged.

| Case | Original scenario | Milestone lane | Current evidence / remaining work |
|---|---|---|---|
| QA-01 | Plane selection | Core — partial, not passed | Origin Front/Right/Top grid availability paired; offset/face/miss matrix open. |
| QA-02 | Entry method | Core — partial, not passed | Ground menu entry only; remaining routes open. |
| QA-03 | Camera angle | Core — partial, not passed | Origin Front/Right/Top normal entry/grid checked; full orbit/angle matrix open. |
| QA-04 | Empty entry | Core — partial, not passed | Empty Front exit removes new sketch in both apps; other cancel/visibility variants open. |
| QA-05 | Line chain | Core — partial, not passed | Horizontal drag/readout paired; live clone next-preview delivery unresolved. |
| QA-06 | Line cancel | Core — partial, not passed | Two-stage Escape corrected and paired live, committed line retained; clean12/12 regressions. Backspace/double-tap/tool-switch matrix open. |
| QA-07 | Line raw aim | Core — partial, not passed | Acquisition-off/Auto-off slight slope sampled paired; all-angle matrix open. |
| QA-08 | Diagonal rectangle | Core — partial live pass | Lower-left correction: clean22/22, reverse-width and down/right-height live pass; remaining matrix open. |
| QA-09 | Center rectangle | Core — partial, not passed | Center height-first and reverse-drag width-first paired, center retained; full quadrant/constraint matrix open. |
| QA-10 | Three-point rectangle | Core — partial, not passed | Rotated sizing/reselection and first-point/height-stage cancellation paired; direction matrix open. |
| QA-11 | Concentric circles | Sampled live recipe passed | Top/mouse existing-center initiation preserves inner circle and line; Pencil pending. |
| QA-12 | Circle dimensions | Core — partial, not passed | Diameter release/keypad/center-preserving edit paired; radius-mode matrix open. |
| QA-13 | Arc construction | Core — not run | Paired acceptance outstanding. |
| QA-14 | Ellipse dimensions | Explicitly deferred | Advanced ellipse-axis coverage; remains in full audit, not passed. |
| QA-15 | Polygon | Core — not run | Paired acceptance outstanding. |
| QA-16 | Spline | Explicitly deferred | Spline creation/editing; remains in full audit, not passed. |
| QA-17 | Text sketch | Explicitly deferred | Text sketch; remains in full audit, not passed. |
| QA-18 | Drawing on points | Core — partial, not passed | Circle-at-rectangle-corner, line endpoint and existing circle center paired. |
| QA-19 | Snap categories | Core — partial, not passed | Raw acquisition-off and Grid-only paired; guidepoint combinations open. |
| QA-20 | Snap zoom | Core — not run | Paired acceptance outstanding. |
| QA-21 | Snap feedback | Core — not run | Paired acceptance outstanding. |
| QA-22 | 3D references | Explicitly deferred | Off-plane reference coverage; remains in full audit, not passed. |
| QA-23 | Selection state | Core — partial, not passed | Point/edge, blank deselect and connected rectangle samples; other entity/tool states open. |
| QA-24 | Multi-selection | Core — partial, not passed | Connected rectangle double-click paired; mouse/touch additive difference recorded. |
| QA-25 | Annotation off-state | Core — partial, not passed | Completed horizontal line and rectangle badges paired; full selection matrix open. |
| QA-26 | Annotation on-state | Core — not run | Paired acceptance outstanding. |
| QA-27 | Dimension type | Core — partial, not passed | Line/rectangle/circle radius-diameter and arc sweep samples; full type matrix open. |
| QA-28 | Dimension selection matrix | Explicitly deferred | Non-core multi-entity dimension coverage; remains in full audit, not passed. |
| QA-29 | Badge layout | Core — partial live pass | Portrait and landscape edge keypad usable; resize alignment fixed; right-palette/compact open. |
| QA-30 | Rectangle sequence | Core — partial, not passed | Center and three-point two-axis edits paired; keyboard/edge matrix open. |
| QA-31 | Unit conversion | Explicitly deferred | Comprehensive unit formats; remains in full audit, not passed. |
| QA-32 | Expression evaluation | Explicitly deferred | Comprehensive variables/expression semantics; remains in full audit, not passed. |
| QA-33 | Invalid numeric input | Core — partial live pass | Zero width rejects without mutation in both apps; remaining invalid forms open. |
| QA-34 | Locked/unlocked value | Core — not run | Paired acceptance outstanding. |
| QA-35 | Constraint rail | Core — partial, not passed | Lock removal and inference toggles sampled; rail matrix open. |
| QA-36 | Constraint types | Core — partial, not passed | H/V plus point Lock constrained drag and inference samples; other relations open. |
| QA-37 | Selection anchor | Core — partial, not passed | Diagonal/center/three-point numeric anchors and locked-endpoint drag sampled; full constrained matrix open. |
| QA-38 | Disconnect | Core — not run | Paired acceptance outstanding. |
| QA-39 | Conflict and point states | Core — partial, not passed | False constrained-drag conflict corrected; other conflict/DOF combinations open. |
| QA-40 | Keypad transitions | Core — partial, not passed | Click-away/tool activation commit corrected and paired; numeric Escape draftdiscard now paired; full systemkeyboard matrix open. |
| QA-41 | Trim primitives | Core — partial, not passed | Paired crossing-line/circle span removal; remaining primitives/history open. |
| QA-42 | Trim curves | Explicitly deferred | Ellipse/spline trim; remains in full audit, not passed. |
| QA-43 | Trim references | Core — partial, not passed | Rectangle edge removal/surviving side readout paired; driven/reference/history matrix open. |
| QA-44 | Offset | Explicitly deferred | Offset completeness; remains in full audit, not passed. |
| QA-45 | Move/rotate/copy | Core — not run | Paired acceptance outstanding. |
| QA-46 | Pattern | Explicitly deferred | Advanced linked patterns; remains in full audit, not passed. |
| QA-47 | Projection | Explicitly deferred | Projection linking; remains in full audit, not passed. |
| QA-48 | Coplanar sketch identity | Core — not run | Paired acceptance outstanding. |
| QA-49 | Profile topology | Core — partial, not passed | Trimmed open U versus intact rectangle handoff paired; nested/self-intersection open. |
| QA-50 | Sketch-to-solid | Core — partial, not passed | Closed rectangle offers extrusion; zero-distance preview cancelled; actual solid build open. |
| QA-51 | Save/reopen | Core — partial, not passed | Three-point values retained after paired reopen; broader state matrix open. |
| QA-52 | Touch and Pencil | Device-only pending | Physical Pencil/touch requires Jason’s actual device comparison; no simulator substitute. |
| QA-53 | Layout | Core — not run | Paired acceptance outstanding. |
| QA-54 | Keyboard | Core — partial, not passed | de2756c live creation/dimension Undo/Redo paired; clone toolbar/CmdZ work after autosave. Line Escape corrected and paired; other focus states open. |
| QA-55 | Sustained use | Core — not run | Paired acceptance outstanding. |
| QA-56 | Downstream smoke | Core — not run | Paired acceptance outstanding. |

## Original recipes (preserved)

### QA-01 — Plane selection

XY/YZ/ZX, planar face, offset construction plane, curved face and miss. Issues: SK-07/08. Result: NOT RUN. Evidence/owner: pending.

### QA-02 — Entry method

Sketch menu, selected face, existing item, keyboard hover/Space. Issues: SK-07. Result: NOT RUN. Evidence/owner: pending.

### QA-03 — Camera angle

0/45/85 degrees, normal view action, orbit while sketch remains active. Issues: SK-07. Result: NOT RUN. Evidence/owner: pending.

### QA-04 — Empty entry

Start then cancel; no persistent empty sketch or unintended visibility change. Issues: SK-08; ED-10. Result: NOT RUN. Evidence/owner: pending.

### QA-05 — Line chain

Tap A-B-C; end open; resume from B; close intentionally. Issues: SK-09. Result: NOT RUN. Evidence/owner: pending.

### QA-06 — Line cancel

Enter, Escape once/twice, Backspace, double-tap, tool switch. Issues: SK-09. Result: NOT RUN. Evidence/owner: pending.

### QA-07 — Line raw aim

Near-horizontal intent above/below tolerance at several zoom levels. Issues: SK-06; DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-08 — Diagonal rectangle

All four drag quadrants; native anchor policy; exact width/height. Original first-anchor assumption superseded by paired native lower-left samples. Issues: SK-03; DM-11. Result: PARTIAL — reverse-width/down-right-height corrected and live verified; all quadrants regression-tested, full live matrix pending. Evidence: testing/sketch-parity-diagonal-anchors-2026-09-08.md.

### QA-09 — Center rectangle

Origin anchor; center fixed under both dimensions. Issues: SK-03. Result: NOT RUN. Evidence/owner: pending.

### QA-10 — Three-point rectangle

Rotated baseline, perpendicular height, cancel at each stage. Issues: SK-03. Result: NOT RUN. Evidence/owner: pending.

### QA-11 — Concentric circles

New circle starts at existing center without edit interception. Issues: SK-04. Result: NOT RUN. Evidence/owner: pending.

### QA-12 — Circle dimensions

R versus diameter, creation/edit/reopen, no factor-of-two error. Issues: DM-04. Result: NOT RUN. Evidence/owner: pending.

### QA-13 — Arc construction

Prescribed endpoints/side, major/minor, tangent transition, cancel. Issues: SK-10. Result: NOT RUN. Evidence/owner: pending.

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

0.1x/1x/10x, tiny and large parts, visible grid agreement. Issues: SK-06. Result: NOT RUN. Evidence/owner: pending.

### QA-21 — Snap feedback

Endpoint versus midpoint versus center versus edge, overlapping candidates. Issues: SK-05/06. Result: NOT RUN. Evidence/owner: pending.

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

mm/cm/m/inches; explicit suffix; display-unit change; imperial forms. Issues: DM-10. Result: NOT RUN. Evidence/owner: pending.

### QA-32 — Expression evaluation

25.4/2, parentheses, negative values, variable insertion; type mismatch. Issues: DM-10/15. Result: NOT RUN. Evidence/owner: pending.

### QA-33 — Invalid numeric input

Empty, malformed, zero/negative size, division by zero, out-of-range count. Issues: DM-10/12. Result: NOT RUN. Evidence/owner: pending.

### QA-34 — Locked/unlocked value

Driving versus one-time size edit; geometry drag after unlock; undo. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-35 — Constraint rail

Enablement for each selected combination; settings access; discoverability. Issues: SK-01/02. Result: NOT RUN. Evidence/owner: pending.

### QA-36 — Constraint types

H/V, parallel, perpendicular, coincident, midpoint, tangent, concentric, equal, symmetry. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-37 — Selection anchor

First/Last, reverse order, existing locks override, repeated solve stability. Issues: DM-08. Result: NOT RUN. Evidence/owner: pending.

### QA-38 — Disconnect

Endpoint and midpoint connections, unrelated constraints survive, undo. Issues: DM-09. Result: NOT RUN. Evidence/owner: pending.

### QA-39 — Conflict and point states

Under/fully defined, lock point versus entity, refusal and attribution. Issues: DM-14. Result: NOT RUN. Evidence/owner: pending.

### QA-40 — Keypad transitions

Another/same tool, off, blank tap, Escape, undo, exit, rotate, pan. Issues: SK-12; DM-12. Result: NOT RUN. Evidence/owner: pending.

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

Repeat golden path ten times, then dense sketch; log latency/hangs, not only screenshots. Issues: ED-12. Result: NOT RUN. Evidence/owner: pending.

### QA-56 — Downstream smoke

Existing SweepLoft failures separately attributed; no claim that sketch work fixed them. Issues: ED-12. Result: NOT RUN. Evidence/owner: pending.

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
