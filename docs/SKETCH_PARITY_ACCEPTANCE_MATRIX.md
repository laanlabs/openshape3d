# Core-sketch milestone: complete original acceptance map

Starting revision `cd0937d`; September 8, 2026. All 56 original cases retained.
Partial evidence is **not** a case pass. No complete case is promoted to covered by this reconciliation. All device tests remain pending. Existing audit remains unchanged.

| Case | Original scenario | Milestone lane | Current evidence / remaining work |
|---|---|---|---|
| QA-01 | Plane selection | Core — partial, not passed | Origin Front/Right/Top grid availability paired; offset/face/miss matrix open. |
| QA-02 | Entry method | Core — partial, not passed | Ground menu entry only; remaining routes open. |
| QA-03 | Camera angle | Core — partial, not passed | Origin Front/Right/Top normal entry/grid checked; full orbit/angle matrix open. |
| QA-04 | Empty entry | Core — partial, not passed | Empty Front exit removes new sketch in both apps; other cancel/visibility variants open. |
| QA-05 | Line chain | Core — not run | Paired acceptance outstanding. |
| QA-06 | Line cancel | Core — not run | Paired acceptance outstanding. |
| QA-07 | Line raw aim | Core — not run | Paired acceptance outstanding. |
| QA-08 | Diagonal rectangle | Core — partial, not passed | Down-right half-width anchor paired; other quadrants/order open. |
| QA-09 | Center rectangle | Core — partial, not passed | Sequential center height/width paired; reverse order open. |
| QA-10 | Three-point rectangle | Core — partial, not passed | Rotated sizing and reselection paired; cancel/direction matrix open. |
| QA-11 | Concentric circles | Core — not run | Paired acceptance outstanding. |
| QA-12 | Circle dimensions | Core — not run | Paired acceptance outstanding. |
| QA-13 | Arc construction | Core — not run | Paired acceptance outstanding. |
| QA-14 | Ellipse dimensions | Explicitly deferred | Advanced ellipse-axis coverage; remains in full audit, not passed. |
| QA-15 | Polygon | Core — not run | Paired acceptance outstanding. |
| QA-16 | Spline | Explicitly deferred | Spline creation/editing; remains in full audit, not passed. |
| QA-17 | Text sketch | Explicitly deferred | Text sketch; remains in full audit, not passed. |
| QA-18 | Drawing on points | Core — partial, not passed | Circle-at-rectangle-corner paired only. |
| QA-19 | Snap categories | Core — not run | Paired acceptance outstanding. |
| QA-20 | Snap zoom | Core — not run | Paired acceptance outstanding. |
| QA-21 | Snap feedback | Core — not run | Paired acceptance outstanding. |
| QA-22 | 3D references | Explicitly deferred | Off-plane reference coverage; remains in full audit, not passed. |
| QA-23 | Selection state | Core — not run | Paired acceptance outstanding. |
| QA-24 | Multi-selection | Core — not run | Paired acceptance outstanding. |
| QA-25 | Annotation off-state | Core — partial, not passed | Completed horizontal line and rectangle badges paired; full selection matrix open. |
| QA-26 | Annotation on-state | Core — not run | Paired acceptance outstanding. |
| QA-27 | Dimension type | Core — not run | Paired acceptance outstanding. |
| QA-28 | Dimension selection matrix | Explicitly deferred | Non-core multi-entity dimension coverage; remains in full audit, not passed. |
| QA-29 | Badge layout | Core — not run | Paired acceptance outstanding. |
| QA-30 | Rectangle sequence | Core — partial, not passed | Center and three-point two-axis edits paired; keyboard/edge matrix open. |
| QA-31 | Unit conversion | Explicitly deferred | Comprehensive unit formats; remains in full audit, not passed. |
| QA-32 | Expression evaluation | Explicitly deferred | Comprehensive variables/expression semantics; remains in full audit, not passed. |
| QA-33 | Invalid numeric input | Core — not run | Paired acceptance outstanding. |
| QA-34 | Locked/unlocked value | Core — not run | Paired acceptance outstanding. |
| QA-35 | Constraint rail | Core — not run | Paired acceptance outstanding. |
| QA-36 | Constraint types | Core — not run | Paired acceptance outstanding. |
| QA-37 | Selection anchor | Core — not run | Paired acceptance outstanding. |
| QA-38 | Disconnect | Core — not run | Paired acceptance outstanding. |
| QA-39 | Conflict and point states | Core — not run | Paired acceptance outstanding. |
| QA-40 | Keypad transitions | Core — partial, not passed | Tool-switch regressions passed historically; full paired transition matrix open. |
| QA-41 | Trim primitives | Core — not run | Paired acceptance outstanding. |
| QA-42 | Trim curves | Explicitly deferred | Ellipse/spline trim; remains in full audit, not passed. |
| QA-43 | Trim references | Core — not run | Paired acceptance outstanding. |
| QA-44 | Offset | Explicitly deferred | Offset completeness; remains in full audit, not passed. |
| QA-45 | Move/rotate/copy | Core — not run | Paired acceptance outstanding. |
| QA-46 | Pattern | Explicitly deferred | Advanced linked patterns; remains in full audit, not passed. |
| QA-47 | Projection | Explicitly deferred | Projection linking; remains in full audit, not passed. |
| QA-48 | Coplanar sketch identity | Core — not run | Paired acceptance outstanding. |
| QA-49 | Profile topology | Core — not run | Paired acceptance outstanding. |
| QA-50 | Sketch-to-solid | Core — not run | Paired acceptance outstanding. |
| QA-51 | Save/reopen | Core — partial, not passed | Three-point values retained after paired reopen; broader state matrix open. |
| QA-52 | Touch and Pencil | Device-only pending | Physical Pencil/touch requires Jason’s actual device comparison; no simulator substitute. |
| QA-53 | Layout | Core — not run | Paired acceptance outstanding. |
| QA-54 | Keyboard | Core — blocked live | Native keyboard Undo/Redo segment restoration observed today; clone toolbar and keyboard no-op unresolved. |
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

All four drag quadrants; first anchor preserved; exact width/height. Issues: SK-03; DM-11. Result: NOT RUN. Evidence/owner: pending.

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
