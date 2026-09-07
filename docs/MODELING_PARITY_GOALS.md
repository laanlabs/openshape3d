# Modeling Parity Goals — Sketch + Solid

**Purpose.** A single ordered plan for reaching the reference app parity on the *modeling
core*: sketching, constraints, and solid feature operations. This is the "what
we're building next and when we can call it done" doc.

**Relationship to the other docs — read this first.**

| Doc | Role |
|---|---|
| `PARITY_SPEC.md` | The **feature-by-feature audit**: every the reference app behaviour, its status, and its feasibility marker. The source of truth for *what a feature must do*. |
| `IMPLEMENTATION_PLAN.md` | Phase sequencing for the whole app (incl. platform/services). |
| `OCCT_BREP_PORT_DESIGN.md` | How the B-rep kernel is being introduced. |
| `SHAPR3D_SKETCH_PARITY.md` | Sketch + dimension gaps measured against the **shipped Shapr3D binary** (its own strings and UI recordings), with screenshots. Where this doc says what to build, that one shows what the reference actually does. |
| **This doc** | Ordered **goals with acceptance criteria** for the modeling core only. |

Do not restate behaviour here — cite the spec section (e.g. §4.3) and state the
*goal* and *how we'll know it's done*.

---

## 1. Scope

**In scope:** sketch tools, sketch constraints/dimensions, solid creation
(extrude/revolve/sweep/loft), solid modification (fillet, chamfer, shell, offset
face, draft-adjacent face ops), booleans, patterns/mirror, and the interchange
formats that make the modeling core usable in a real workflow (STEP).

**Explicitly out of scope here:** rendering/visualization polish, drawings,
collaboration/sync, AR, gallery/document management. Those live in
`IMPLEMENTATION_PLAN.md`.

**Definition of "main functionality parity".** A user can complete a realistic
mechanical part end-to-end without hitting a wall:

> sketch a constrained profile → extrude/revolve it → boolean it against other
> bodies → fillet and chamfer the edges that matter → shell it → export STEP,

with results that are **exact** (analytic surfaces, not visibly faceted) and
**parametric** (editing any history step rebuilds downstream correctly).

---

## 2. Where we stand

**Sketch.** Line, rect, circle, arc, ellipse, polygon, trim, text, project are
implemented. A Levenberg–Marquardt constraint solver ships with 13 geometric
constraints (coincident, horizontal, vertical, parallel, perpendicular, equal
length/radius, concentric, midpoint, symmetric, tangent, colinear, fixed) plus
dimensional constraints, DOF colouring, and auto-constrain.

**Solid.** Primitives, extrude, revolve, sweep, loft, booleans, push/pull,
pattern, mirror, split all evaluate through the parametric feature graph with
topological naming (a `FaceRef` survives a rebuild). Chamfer/fillet and shell
exist in the **mesh domain** with documented v1 gaps.

**Kernel.** OCCT is now the source of truth for extrude, primitives, and
booleans between B-rep bodies; Euclid owns everything else. See
`OCCT_BREP_PORT_DESIGN.md` for the current split and limitations.

**The gating problem.** Ops not yet ported to OCCT **drop the brep**, so a
filleted or shelled cylinder reverts to a faceted mesh body. Until the
modification ops are ported, exactness doesn't survive a real modeling session.
This is why G1–G3 come first.

### Reality check — driven against the reference app's own tutorials and manual (2026-08-26)

The reference app's introductory motorcycle-cover tutorial series (parts 2–4:
"Creating complex shapes", "Create basic 3D geometry", "Modify features with
Design History") was driven step-by-step against our app on the iPad simulator.
It is a good parity yardstick because it is the *first* thing a new user of
that app does, so anything missing there is a wall, not a nicety.

**Held up:** dimension-on-select with typed values driving the solver
(with one hole until 2026-09-03: a Rect-tool rectangle offered no
dimension at all — its solver points are two corners, so width/height are
the new `.horizontal`/`.vertical` axis-distance kinds, one label per side);
the constraint menu with hotkey letters and context-sensitive enablement;
auto-constraints while drawing (`H` badge); tap-a-profile → pull arrow with
live drag and a typed distance; the boolean-result selector
(`Auto / New Body / Union / Subtract / Intersect`); sketch-on-a-model-face;
Shell with face picking and a live hollow preview; Fillet with live preview and
a drag handle; sketch Text with font + height; named/isometric views; and the
History panel's rename / suppress / delete / roll-back / inline parameter edit.

A second pass (same day) covered the two earlier hands-on entries —
"Grid and sketch settings" and "Introduction to 2D sketch tools and settings".
More held up there: a fresh sketch **auto-arms Line** exactly as the video
shows; marquee **window vs crossing by drag direction** is implemented; the
Shift+letter constraint hotkeys were already wired; auto-constrain has
per-inference toggles and an angle tolerance. (The two remaining series
entries — its "Basics" and "Get started" overview articles —
are narration only, with no steps to reproduce.)

**Walls hit** — these became G7:

| Tutorial step | Gap |
|---|---|
| "click the offset edge tool, select a model edge, drag it in, key in a half inch" (used twice) | ~~Offset Edge had no UI at all~~ **shipped 2026-08-27**, see G7.1 (distance is typed, not dragged) |
| "add draft to this using the curved arrow and key in 10" (used twice) | no draft angle on extrude *(§4.1 already records this)* |
| "select the sketch plane and shift-select the extrude … drag these up the tree" | History rows are individually draggable only — no multi-select *(§10.1)* |
| "click on circle or use C on the keyboard", "I'm using the A key", "the T hotkey" | ~~no per-tool hotkeys; `CommandRegistry` was dead code~~ **fixed 2026-08-26**, see G7.0 |
| several minutes in snap / grid / units / circular-annotation settings | our Settings sheet has four rows *(§17)* — see G7.4 |

**Cosmetic bug found and fixed the same day:** `HistoryPanelView`,
`ItemsPanelView`, and `VariablesPanelView` are each
`ScrollView { … }.background(.regularMaterial)` and still used hierarchical
`.secondary`/`.tertiary`, so their section headers, row icons, trash buttons,
and unit captions rendered **fully transparent** — the History panel read as a
bare "Extrude / 1 / Shell / 0.3". This is the gotcha the `.barLabel` colour in
`AdaptiveBar.swift` was introduced for; it had only ever been applied to the
bottom bars. All three panels now use `.barLabel` / `.barLabelDim`. Note this
class of bug is **invisible to XCUITest** — a transparent label still `exists`
and is `isHittable` — so it needs a visual check.

---

## 3. Goals

Each goal states the target, the kernel work, and **acceptance criteria** that
should become tests.

### G1 — Fillet & Chamfer on B-rep *(spec §4.3)* — **fillet landed 2026-07-22; chamfer pending**

**Done:** `OCCTBridge.filletedShape:atWorldPoints:radius:tolerance:` wraps
`BRepFilletAPI_MakeFillet`; `evalEdgeBlend` uses it whenever the body carries a
`brep`, and falls back to the mesh blend when OCCT can't build the round (e.g.
radius too large). Edge mapping works by sampling each analytic edge and
matching against the picked mesh-edge midpoints — which means **tangent-chain
propagation came for free**: a tessellated rim is many mesh segments but ONE
analytic edge, so picking a single segment rounds the whole circle. Verified by
`testFilletingACylinderRimStaysAnalytic` (wall survives as one cylindrical
face, blend adds a curved face, result still tessellates finely).

**Still to do:** chamfer on `BRepFilletAPI_MakeChamfer` (needs the edge's
adjacent face), concave edges, and surfacing the max-valid-radius in the drag
feedback from OCCT rather than the mesh heuristic.


The original motivation for the whole port, and the biggest visible gap: today a
fillet on a cylinder throws away the analytic geometry.

- `BRepFilletAPI_MakeFillet` / `MakeChamfer` replace the mesh-domain blend.
- **Hard part:** mapping a user-selected *mesh* edge to an OCCT `TopoDS_Edge`.
  Plan: match on edge geometry (endpoints + adjacent-face normals) against the
  brep's edges, reusing the signature idea already in `EdgeTopology`.
- Tangent-chain propagation (§4.3: selecting one edge of a tangent chain rounds
  the whole chain) becomes natural — OCCT knows the topology.
- Concave edges, and corners where 3+ blended edges meet, stop being
  best-effort.

**Acceptance**
- Filleting the top rim of a cylinder yields a body whose side is still ONE
  cylindrical face and whose blend is a torus face — asserted via face-type
  counts, not pixels.
- The result **retains its brep** (a subsequent boolean stays analytic).
- Variable-radius and G2 are explicitly *not* required (partial in OCCT).
- Existing blend UI (multi-edge pick, live preview, drag-to-size arrow, red/blue
  validity) keeps working unchanged.

### G2 — Shell on B-rep *(spec §4.4)* — **kernel landed 2026-07-22; wiring pending**

**Done (kernel):** `OCCTBridge.shelledShape:atWorldPoints:thickness:tolerance:`
wraps `BRepOffsetAPI_MakeThickSolid`, supporting both face-removal (points pick
the faces to open) and whole-body hollow (empty selection). Verified by
`testShellingACylinderProducesATube` — shelling a cylinder yields **two
concentric cylindrical faces**, precisely the case the mesh inset gets wrong.

**Still to do:** route `evalShell` through it (see the note in §Sequencing about
the blend/shell eval wiring), and drive the red/blue drag feedback from OCCT's
valid-thickness range rather than the mesh heuristic.

### G3 — Remaining solid creators on B-rep *(spec §4.10, §4.11, §4.5)*

Revolve (`BRepPrimAPI_MakeRevol`), sweep (`BRepOffsetAPI_MakePipe`), loft
(`BRepOffsetAPI_ThruSections`). Also the two extrude paths still on Euclid:
extrude-into-target booleans, and multi-profile extrudes.

**Why it matters:** every creator must produce a brep, or downstream ops silently
fall back to mesh. This is what makes "OCCT is the source of truth" true rather
than aspirational.

**Acceptance:** a revolved profile has analytic faces; every creation op sets
`Body.brep`; a chain (revolve → boolean → fillet) stays analytic throughout.

### G4 — Direct-modeling face ops *(spec §4.2, §4.12, §4.16, §4.13)*

Offset Face (incl. curved faces with adjacent-face extension/trimming), Replace
Face, Delete Face with healing (OCCT defeaturing / `RemoveFeatures`), Offset
Edge in 3D. These are what make it feel like *direct* modeling rather than
history-only modeling.

**Delete Face: ✅ done 2026-08-29** — `DeleteFaceKit` + the
`.pickingDeleteFaces` mode; see `STATUS_AND_NEXT_STEPS.md` §4.1c. Deleting a
Ø4 through-hole's wall from a 10 × 10 × 6 box returns it to exactly 600.00 mm³.

**Replace Face: ✅ done 2026-08-29** — `FeatureKind.replaceFace` +
`.pickingReplaceFace`; see `STATUS_AND_NEXT_STEPS.md` §4.1d. Replacing a
stepped block's low top face onto the high step's plane makes one solid box
(1800 → 2400.00 mm³). The kit gained an analytic path (`applyBRep`) so a B-rep
body is not degraded to mesh, and the coplanar seam the fuse leaves is removed
with a new `OCCTKernel.unified`.

What is left in G4: **Offset Face** on curved faces, and **Offset Edge in 3D**.

**Acceptance:** deleting a fillet face heals the surrounding faces back to a
valid solid; offsetting a cylindrical face changes its radius rather than
faceting it.

### G5 — Sketch completeness *(spec §1.x, §2.x, §3.x)*

The remaining gaps in the sketch half, ordered by how often they block real work:

1. **Spline (fit / control points)** *(§1.4)* — **kernel done, UI missing.**
   `SketchEntity.spline` exists with centripetal Catmull–Rom tessellation,
   profile detection, transforms and mirror (see `SPLINE_PROFILE_DESIGN.md`);
   what is absent is a `.spline` case in `SketchTool` — the only non-test
   construction site today is the agent API. Solver integration for tangency is
   still genuinely open.
2. ~~**Offset Edge in sketch mode** *(§1.9)*~~ — **done 2026-08-27** as G7.1.
3. **Sketch pattern (linear/circular) + the pattern constraint** *(§1.11, §2.5)* —
   also **kernel done, UI missing**: `SketchPatternLink` is a complete type with
   tests, but `patternLinks` is untouched by `EditorViewModel`.
4. **Line/Arc pen mode** *(§1.2)* — drag-to-arc continuation, a core the reference app
   input idiom.
5. **Helix** *(§1.17)* — pairs with sweep for threads.
6. Snapping/guides and notable-point polish *(§2.6, §2.7)*.

**Acceptance:** a spline can be drawn, dimensioned, constrained tangent to an
adjacent line, and extruded; sketches reach a fully-defined (green) state.

### G6 — STEP interchange *(spec §12.1, §12.2)* — ✅ DONE 2026-08-29

STEP import/export via OCCT DataExchange — the format that makes the app usable
alongside other CAD. `Kernel/STEPKit.swift` + the Import/Export menu entries;
see `STATUS_AND_NEXT_STEPS.md` §4.1b for the three things worth knowing.

**The cost was already paid.** This section used to warn that `DataExchange` +
XDE is "a one-line flip in `scripts/build_occt_ios.sh`" that doubles the
library. Both toolkits have been ON since the port (script L99–104), and the
committed `libOCCT-OS64.a` is 142 MB — the post-flip size. Nothing to decide.

**Acceptance — met.** `OCCTKernelTests.testSTEPRoundTripPreservesAnalyticTopology`
round-trips a FILLETED cylinder with its planar, cylindrical and blend faces
intact; `STEPKitTests` covers the document layer; and on-device a cylinder
exported to `CYLINDRICAL_SURFACE('',#33,3.)` in mm, re-imported analytic, and
re-exported to the same single cylindrical surface (Simulator, not a device).

### G7 — Close the starter-tutorial walls *(spec §1.9, §4.1, §8.4, §10.1, §17)*

The gaps that stop a new user completing the reference app getting-started series
(see the walkthrough in §2). All of them are **UI/feature work, not kernel
work**, so this goal is independent of G1–G4 and can run in parallel.

**Done**

0. ~~**Hotkeys** *(§8.4)*~~ — **landed 2026-08-26.** `CommandRegistry` was a
   fully-tested catalog with *zero references outside its own test target*:
   every hotkey in it was dead, while the tutorials lean on "press C for
   circle, A for arc, T for trim" throughout. Now routed —
   `CommandDispatch.swift` maps 34 catalog ids onto existing view-model entry
   points, and `CommandShortcutsView` registers the chords.
   Two things worth remembering:
   - The chords ride on **zero-sized buttons carrying `.keyboardShortcut`**,
     not `onKeyPress`. `.keyboardShortcut` lowers to a `UIKeyCommand` that
     UIKit consults app-wide on the responder chain, so it does not need the
     Metal viewport to hold focus — which it cannot reliably take. It is also
     already the pattern the constraint hotkeys use in `ToolPaletteView`.
   - Because the **first responder wins first**, a focused text field still
     receives plain letters: verified on device by typing "cat" into a History
     rename field and getting "cat", not Circle → Arc → Text.
   - Every hotkey guard mirrors the palette's own `enabled` condition, so a
     key can never reach a state the equivalent button would have refused.
   - `CommandRegistry.unroutedChordedCommands` names what still has a chord but
     no entry point (Insert Image, Offset, Command Search, the project/import
     commands, Select All, Zoom to Selection); a test pins that list, so adding
     a chorded command without routing it fails loudly instead of shipping a
     key that quietly does nothing.

**Remaining**

1. ~~**Offset Edge in the sketch palette** *(§1.9)*~~ — **landed 2026-08-27.**
   "Offset" in the sketch palette (hotkey **O**) arms a pick mode with the
   Single/Chain type, a signed distance, a live preview, and Apply; committing
   keeps the tool armed for the next offset. The Single-vs-Chain expansion is
   a pure static (`SketchOffset.entitiesToOffset`) so it is unit-testable
   without an `EditorViewModel`. **Still missing:** the drag gizmo (the
   distance is typed, as with Shell) and loop-arrow disambiguation when the
   picked item is shared by several loops — today the sign of the distance
   picks the side. Offset Edge **(3D)** *(§4.13, `EdgeOffsetKit`)* is still
   kernel-only and belongs to G4.
2. **Draft angle on extrude** *(§4.1)* — a second, curved handle on the pull
   gizmo plus an angle field in the extrude bar; the tapered prism is a kernel
   op on both the Euclid and OCCT paths (`BRepPrimAPI_MakePrism` has no draft;
   expect `BRepOffsetAPI_DraftAngle` or a lofted-profile construction).
3. **Multi-select + group reorder in History** *(§10.1)* — rows are
   individually `.draggable` with a single-UUID payload; the tutorial's key
   move is selecting a sketch *and* its extrude and dragging both above the
   shell in one gesture.
4. **The Settings sheet is far thinner than the reference app's** *(§17)* — ours is
   Units / Theme / Toolbar Side / Anti-Aliasing. "Grid and sketch settings" and
   "Introduction to 2D sketch tools" spend roughly three minutes in settings we
   do not have:
   - **snap toggles** — snap-to-grid, sketch guidelines, sketch guide points,
     snapping hints. `SnapEngine` implements all four behaviours; none is
     switchable.
   - **grid position** (XY / XZ / ZX) and **grid-locked-size while zooming**.
   - **circular annotations**: radius-always vs radius-and-diameter. This is
     the *named source* of the Ø-vs-R divergence below — the reference app's default
     reserves diameter for full circles and radius for arcs.
   - **fractional inches** and **degree format** (fractional / decimal).
   - orthographic↔perspective as a **slider**, where we have a binary toggle.
5. **Grid does not re-orient to the active sketch plane** — it stays on the
   world ground plane. The reference app moves the grid onto the sketch plane on entry
   and back on exit. Already noted in `STATUS_AND_NEXT_STEPS.md`; recorded here
   because the tutorial makes it a first-five-minutes observation.

**Lower-priority divergences found in the same pass** (record, don't schedule):
a selected full circle reports **Radius** where the reference app reports **Ø** — and we
already draw Ø in the live sketch overlay, so we are inconsistent with
ourselves (see item 4 for the setting that governs it); sketch Text is a modal
sheet rather than live-on-canvas with the move/rotate/reference-point pad;
Shell thickness has a field but no drag handle, unlike the blend arrow; Items
and History are mirrored relative to the reference app (it puts Items left / History
right, and our Toolbar Side setting only moves the palette); renaming a design
is gallery-only, where the reference app renames from the editor's upper-left title.

**Audited against the official manual (2026-08-26).** The 343-page the reference app
manual PDF (pages 77–259 are sketching + modeling) was read tool-by-tool
against this repo. Two things worth recording:

1. **`PARITY_SPEC.md` is accurate and complete in its coverage.** Every
   tool in the manual's Sketch / Constraints / Insert / Construct / Transform /
   Tools menus maps onto an existing spec section — there are no unaudited
   features — and the statuses spot-checked (§1.4 spline, §1.9 offset edge,
   §4.4 shell, §6.1/§6.2 construction geometry, §8.4 hotkeys) were all correct,
   including the careful distinction in §1.4 between the spline *entity* (which
   ships through the whole pipeline) and the spline *drawing tool* (which does
   not). Trust that doc.
2. **The gap is depth, not breadth.** Nearly every tool exists in some form;
   what is missing is each tool's *variants and options*. That is a different
   shape of work from G1–G7 and produced two new goals, G8 and G9.

**One claim to re-check rather than act on.** The "Grid and sketch settings"
video says the reference app squares the view to the sketch plane on entry, whereas
`STATUS_AND_NEXT_STEPS.md` records our "draw from the current camera" behaviour
as a *parity improvement*. The videos are two years old; confirm against
current the reference app before treating either reading as settled.

**Acceptance**
- The "Create basic 3D geometry" tutorial can be followed end-to-end in the app
  without substituting a different tool for any step.
- Offsetting a model edge into a sketch, extruding the loop with 10° of draft,
  and reordering that extrude above the shell all survive a save/reload and a
  parametric rebuild.
- Every sketch and modeling hotkey the tutorials press does what the video
  shows, and no hotkey fires while a text field has focus.

### G8 — Every feature's operands and options editable in History *(spec §10.1)*

**The structural modeling gap, and the one the manual makes impossible to
miss.** Every the reference app tool's History card exposes its full parameter set,
including its *references*: Extrude shows Profile / Sides / Extent / Draft
Angle / Start / Result + Target; Union shows Target / Tool / Type / Keep
Target Bodies / Keep Tool Bodies; Sweep shows Profile / Path / Profile
Position / Orientation / Twist / Scale / Corner type. Each reference row is a
live `Edit…` / `Select…` picker, so "re-pick the profile this extrude uses" is
a first-class edit — and the manual's own repair flows depend on it
("remove the missing face from a Face Offset selection", "re-select the
original face to fix a broken Shell").

We already have the hard half. `FeatureKind` stores real operand references —
`ProfileRef`, `AxisRef`, `PlaneRef`, `BodyRef`, `FaceRef`, `EdgeRef` — and
topological naming re-resolves them across a rebuild. What is missing is the
UI: `HistoryPanelView` exposes exactly **four** editable scalars (distance,
pattern count / spacing / angle) and no reference pickers or option controls
at all. So a feature's geometry is parametric while its inputs are frozen at
creation time.

**Progress 2026-09-02 — the scalar slice.** Every scalar a feature has is now
an inline, labelled, unit-tagged field in its History row: extrude and
push/pull distance, draft extrude distance AND draft angle, revolve angle,
chamfer setback, fillet radius, shell thickness, face-scale factor,
face-rotate angle (shown in degrees, stored in the kernel's radians), plus
the pattern count/spacing/angle that were already there. The row model
carries `[FeatureScalar]` (`EditorViewModel.scalars(of:)`), the panel renders
one field per scalar, and `editFeatureScalar(_:key:value:)` rewrites the
node's `Expr` through `session.editFeature` (one undo step, rebuild
downstream). Before this the panel showed a bare "mm" field for five kinds
and nothing for the other four. **The option slice followed the same
evening:** `[FeatureOption]` on the row (`options(of:)`) — extrude and draft
extrude *Symmetric*, mirror *Keep original* as switches, a boolean node's
*Type* (Union / Subtract / Intersect) as a menu — through
`setFeatureOption(_:key:toggle:)` / `(_:key:choice:)`, operands untouched,
one undo step each (`HistoryOptionEditTests`). Verified live: the Type menu
turned a union into a subtract (volume dropped by the peg's 1,000 mm³), the
Symmetric checkbox rebuilt the draft both ways; the switches had to become
Button-backed checkboxes because the row's select tap beat a `.switch`
(STATUS gotcha 27), and `HistoryPanelUITests` now flips one. **Reference
rows, first slice (same evening):** the context menu's *Edit Edges* on a
blend generalised to *Edit Faces* on shell and delete-face rows
(`referenceEditLabel` / `beginReferenceEdit` → `beginShellEdit`,
`beginDeleteFaceEdit`): the pick re-enters seeded with the faces the node
has, resolved by `SignatureNaming` against the body the feature CONSUMED
(`DocumentSession.inputBody` replays it — the document's copy is already
hollow / healed), the preview re-shells that input, taps on other bodies are
ignored while editing, and Apply rewrites the node in place through
`session.editFeature` (one undo step, never a second node).
`HistoryFaceEditTests` drives a feature-owned box through shell → Edit
Faces → second face → commit (cavity 6×6×8 → 8×8×6) → undo. **Edit Tool** on a
boolean row followed (`beginBooleanEdit`): the tool pick re-enters on the
node's own target, the next tapped body becomes the tool (refused if it is
not feature-produced or was created AFTER the boolean — replay order), and
the rebuild does the CSG; `HistoryBooleanEditTests` re-picks a union's tool
from a far box to an overlapping one (1000 → 1500 mm³) and undoes it. Note
for tests: a rebuild drops document-level transforms by design, so a
primitive node must carry its PLACEMENT to replay anywhere but the origin.
**The repair flow** for those kinds is the same action surfaced where the
failure is: a row with an error badge shows its reference edit as an inline
orange button under the error text (`HistoryRepair-<name>`), so a blend,
shell, delete-face or boolean whose reference went stale is fixed by tapping
Edit Edges / Edit Faces / Edit Tool right there — the loop §18's error badge
specifies. **Edit Body** on mirror / pattern / transform rows followed
(`EditorMode.pickingFeatureBody`, `beginFeatureBodyEdit`): a generic body
pick with its own status pill ("Tap the body for Mirror"), the same
feature-produced / created-before rules as a boolean's tool, the node's
operand rewritten with its options and delta untouched
(`HistoryBodyEditTests`: a mirror re-sourced from A to B replays across the
plane at B; a transform re-targeted; a late body refused; cancel inert).
**Edit Face** on push/pull / move / scale / rotate-face rows closed the
operand set (`pickingFeatureFace`, `beginFeatureFaceEdit`): the tap is
re-resolved on the CONSUMED body (the document's copy already carries the
push), the planar `FaceRef` is minted with the tools' own signature and box
role, the node keeps its distance / delta / factor / angle; a radial
push/pull (cylindrical face) refuses for now. `HistoryFaceOperandEditTests`
moves a push from a box's top to its +x side and watches the bounds swap.
**Edit Profile** on extrude / draft extrude / revolve / sweep rows completed
the operand set (`pickingFeatureProfile`, `beginFeatureProfileEdit`): the
tap resolves a sketch fill through the same `profileHit` the tools use —
hidden sketches included, since a consumed sketch usually is — mints the
`ProfileRef` + sketch `PlaneRef` the extrude commit mints, and rewrites the
node with its distance / angle / options kept (extra profiles dropped: the
re-pick is one region; the same region again just ends the pick).
`HistoryProfileEditTests` points an extrude from one rectangle at another
and watches its bounds move. Still open in G8: the
reference rows (re-pick profile / body / faces / edges), the boolean
INTENT of extrude / revolve / sweep / loft (changing new-body → subtract
needs a target pick, so it belongs with the reference rows), and the
stale-reference repair flow.

**Acceptance**
- Every `FeatureKind` case renders its full parameter set in its History row.
- Reference rows re-enter the matching pick mode, and committing re-resolves
  and rebuilds downstream.
- A feature whose reference went stale offers the re-pick as the repair, which
  is what closes the loop with the error badge §18 already specifies.

### G9 — Tool variants and options *(spec §1.x, §4.x, §5.x)*

Breadth exists; depth does not. Each row below is the *default path only* in
our app. Ordered roughly by how often the manual reaches for them.

| Tool | Missing variants / options |
|---|---|
| Extrude *(§4.1)* | **Extent**: To Object, Through All (+Flip); **Start**: Offset (start/end), From Plane; Draft Angle (G7.2); explicit boolean Target picker |
| Chamfer/Fillet *(§4.3)* | Chamfer 2-distance; Fillet **Chordal**; **Corner** Rolling Ball vs Setback; **Continuity** G1/G2; profile slider + magnitude (−1…1); Overflow (Auto/Cliff/Smooth/Notch); Include Tangent Edges toggle; Y-shaped blend |
| Booleans *(§4.6–4.8)* | **Keep Target Bodies / Keep Tool Bodies** (the reference app's All / Modified / Removed / None); switching Type after the fact |
| Offset Face *(§4.2)* | **Distance Type**: Radius/Diameter, **Total** (with opposite-face pick), Offset; automatic tangent-face inclusion |
| Shell *(§4.4)* | ~~Direction outward~~ **landed 2026-09-02** as a signed thickness (negative = outward; exec + History field; the Shell bar still enters inward only) |
| Sweep *(§4.11)* | Profile Position (Auto / path intersection / closest point / closest endpoint); Orientation (normal-to-path vs parallel); Twist; Scale; Corner type (mitre/round) |
| Loft *(§4.5)* | **Guide curves**; **connection points** (vertex mapping / de-twisting); Periodic Loft; start/end tangent continuity + magnitude |
| Split Body *(§4.9)* | Multiple cutters at once; sketch profiles, body faces/edges, images, and a body's own face as cutters; Keep Originals |
| Revolve *(§4.10)* | **Height** → helical bodies (coils, springs, threads) directly from Revolve; ours needs the separate Helix tool |
| Rectangle *(§1.5)* | Center and Three-point variants (Diagonal only today) |
| Polygon *(§1.8)* | Pre-defined Triangle/Pentagon/Hexagon/Octagon menu |
| Circle / Ellipse / Polygon / Rectangle *(§2.2)* | **Type-ahead numeric entry**: typing a value mid-draw, before placing the second point |
| Text *(§1.12)* | **Alignment** setting; gizmo positioning pass after Continue |
| Constraints *(§3.2)* | **Disconnect** (break connected points, dropping their coincident/midpoint constraints); **Anchored Sketch Entity** (First/Last Selected) setting; Always Show Constraints / Always Show Dimensions toggles |

**Not in this table because they already have goals:** spline drawing (G5.1),
sketch Pattern (G5.3), construction planes (§6.1 — still Offset-only),
Replace Face / Offset Edge 3D / Wrap & Emboss (G4, all kernel-only).
**Construction axes (§6.2) shipped 2026-08-27** — document entity,
persistence, rendering, Items, an inference-based Add Axis tool, and use as a
Revolve operand; only Through-2-Points remains.

**Acceptance:** for each row, the variant is reachable from the tool's own bar
(not only from History), and round-trips through save/reload and a rebuild.

---

## 4. Cross-cutting requirements

These apply to every goal above and are easy to forget:

- **Brep preservation.** Any ported op MUST set `Body.brep` on its result, or it
  silently regresses exactness for everything downstream. Treat "result has a
  brep" as part of each op's acceptance.
- **Parametric integrity.** Every op is a `FeatureKind` node; editing a
  parameter must rebuild downstream and re-resolve `FaceRef`/`EdgeRef` against
  the new geometry.
- **Validity feedback** *(spec §18)*. Operations that can fail (fillet radius too
  large, shell thickness out of range) show the red/blue live feedback and a
  recoverable failure message — not a silent no-op.
- **Persistence.** New analytic geometry must survive save/reload, and the
  `.os3d` archive needs the brep blob (currently missing).
- **Performance.** OCCT booleans/blends are slower than mesh. Keep Euclid for
  live drag previews; run exact kernel work off the main actor with progress and
  cancellation on anything that can take >100 ms.
- **Fallback.** If an OCCT op fails, fall back to the Euclid path rather than
  failing the user's action, and surface that the result is approximate.

---

## 5. Sequencing

```
G1 Fillet/Chamfer ──► G2 Shell ──► G3 Remaining creators ──► G4 Face ops
                                          │
G5 Sketch completeness (parallel track) ──┘──► G6 STEP

G7 Starter-tutorial walls ── independent, do first (UI-only, unblocks new users)

G8 Editable history params ──► G9 Tool variants and options
```

G1–G3 are the critical path: they make exactness survive a modeling session.
G5 is independent of the kernel work and can proceed in parallel. G4 depends on
robust B-rep topology, so it follows G3. G6 last, so the size cost is paid only
once the modeling core justifies it.

**G7 jumps the queue** despite not being on the exactness path: it is cheap
(UI wiring over backends that already exist and are tested) and it is the
difference between a new user completing the getting-started tutorial and
hitting a wall on step one. Exactness matters to the user who stays; G7 decides
whether they get that far.

**G8 comes before G9, and the order is not arbitrary.** Most of G9's options
are per-feature parameters, so G8's parameter-rendering layer is the surface
they get added to — building it first means each G9 row is "add a case", not
"add a case and invent a place to put it". G8 also stands on its own: without
it a feature's inputs are frozen at creation time, which is the difference
between a history that records what you did and one you can actually edit.

Both are independent of the kernel track. Sequenced after G7, since a tool the
user cannot reach at all outranks an option on a tool they can.

**Milestone definition of done for "modeling core parity":** the end-to-end
scenario in §1 completes with analytic results and a clean parametric rebuild —
i.e. G1–G4 plus the top three items of G5. **G7 is the separate "a beginner can
finish the official tutorial" bar**, and is worth tracking on its own.

**Three bars, not one.** Keeping them apart stops "are we at parity?" from
collapsing into a single unanswerable question:

| Bar | Means | Gated by |
|---|---|---|
| **Reachable** | every tool in the manual has a UI entry point | G7 + the kernel-only tools in G4/G5 |
| **Exact** | results are analytic and survive a rebuild | G1–G4 |
| **Complete** | each tool's variants and options are all there | G8 + G9 |

Today we are strongest on *reachable*, mid on *exact*, and weakest on
*complete* — see the manual audit in §2.

---

## 6. Non-goals (deliberate gaps)

Called out so they don't get mistaken for oversights:

- **Variable-radius and G2 blends** — partial in OCCT; accept the gap.
- **Parasolid-grade boolean robustness on dirty imported geometry** — OCCT is
  weaker here; mitigate with shape healing and the Euclid fallback.
- **Wrap & Emboss** *(§4.15)*, **Replace Face on complex surfaces** — deferred
  until the core above is solid.
- Anything outside the modeling core (drawings, sync, AR, collaboration).
