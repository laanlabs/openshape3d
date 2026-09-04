# Status & Next Steps — Handoff Notes

Last updated: 2026-09-03 (SOLIDWORKS practice-problem campaign — extrude end
conditions, B-rep touch commits, draft of an existing face; see the mission
log just below, and **§4c for the campaign's state and how to resume it**).
This is the living handoff document: what is DONE, how the newest subsystems
work, the dev workflow, and the prioritized next missions.
Companions: `IMPLEMENTATION_PLAN.md` (original phase plan),
`PARITY_SPEC.md` (feature spec), `PHASE_D_DESIGN.md` (feature-graph
design), `FREECAD_PLAYBOOK.md` (the FreeCAD-derived hardening ledger),
`TOPO_NAMING_HISTORY_DESIGN.md` (element-naming design, now complete), and
`AGENT_CONTROL.md` (the `/v1/exec` scripting surface).

## Mission log — 2026-09-04 (landed, 1264/1264 green)

- **Dragging a filleted body killed the app, found and fixed (2026-09-04).**
  Reported from a live Catalyst session: a drag on a plane trapped the
  process with `Duplicate values for key: '3'`
  (`Dictionary(uniqueKeysWithValues:)`) in `FeatureGraph.evalEdgeBlend`, on
  the rebuild `endMove()` kicks off. The blend node held **158 EdgeRefs over
  2 kernel edges**: the picker selects MESH SEGMENTS, one tap on a
  tessellated rim takes the whole tangent chain, and every segment mints the
  SAME `EdgeName` — so the resolved indices repeat and `edgeParents`, keyed
  by edge index, trapped on the second copy. The kernel had always deduped
  (`std::set` in `OS3DBlendByIndices`); only the Swift naming step assumed
  one ref per edge. Fix: dedupe the resolved indices, preserving pick order,
  and drive both the kernel call and the name composition from that.
  `ElementNamingTests.testRepeatedRefsForOneCreaseBlendItOnce` pins it (one
  crease → exactly ONE chamfer face); reverting just the dedupe reproduces
  the same fatal error. Re-verified live: r8×10 cylinder, one rim tap = "158
  edges selected", fillet applied, then two ground-plane moves — both
  rebuilds clean, volume steady at 2000.13 mm³, `/v1/check` 0 invalid.

- **Face drags ran at ~3 fps on blended bodies; fixed (2026-09-04).** The
  second bug from the drag session, found by asking which gesture was slow:
  a FACE drag, not a body drag. `EditorViewModel.updateMove` previewed each
  frame by deforming through Euclid — `KernelOps.moveFace` rebuilds every
  `Euclid.Polygon`, `makeWatertight()` welds the result, `translated(by:)`
  copies it again, then `Body(euclidMesh:)` converts back to render buffers
  and re-extracts the edge set. Measured per frame on an r8xh10 cylinder with
  both rims filleted (13,268 polygons): classify 19.5 ms + rebuild 152.7 +
  watertight 83.7 + translate 84.3 + renderMesh 15.6 + edges 12.8 = ~370 ms,
  about 3 fps. (A plain box is 0.28 ms, which is why this only bit on curved
  or blended geometry.) The first attempt — caching the vertex
  classification — was wrong: it only removed the 19.5 ms, and the
  measurement said so. The preview only has to LOOK right, so it now
  translates the picked vertices of the source's render buffers and reuses
  the cached edge set: **363 ms -> 0.039 ms, 9,206x**, verified live by
  shearing a cylinder (cap area held at 201.01 mm², volume 2010.62 ->
  2010.09). The COMMIT still runs the real Euclid deform, so the geometry
  that lands in the document is unchanged. Face scale got the same treatment;
  face ROTATE still deforms per frame, but its cost is subdivision (n² per
  deformed triangle under a 40k budget), a different fix.
  `FaceMovePerfTests` guards the frame budget and pins the render-buffer
  classifier against the Euclid one.

- **A face-picking "bug" that was not one (2026-09-04).** Reported here first
  as a real defect: on a tangent-filleted body the picker looked like it
  merged every kernel face into one 860.60 mm² "curved face", leaving the
  flat cap unselectable. It does not. Isometric taps aimed at the cap had
  been landing on the curved WALL, which correctly reports its whole
  tangent-connected region; a top-view tap on the same live body selects the
  cap at 155.63 mm² (perimeter 44.23 ≈ 2π·7). The offline picture agrees: at
  a cap seed the coplanar patch covers its entire kernel face and
  `smoothRegion` reports NOT curved, so the picker's curved-region branch
  never fires. A speculative fix (prefer a planar patch that covers its whole
  kernel face) was written, measured against reality, and REVERTED —
  it guarded a case that does not occur and cost a full tessellation per tap.
  `FacePickUnderBlendTests` keeps the characterisation so the question does
  not have to be re-asked.

- **Build-warning sweep: 125 -> 10 (2026-09-04).** A clean Catalyst build
  (the config the drag crash was reported from) carried 125 warnings. Four
  fixes cleared 115 of them. (1) 55 were `-Wdocumentation` inside the
  VENDORED OCCT headers (44 from `StepData_ConfParameters.hxx` alone) and
  none in our own bridge header, so the app target sets
  `CLANG_WARN_DOCUMENTATION_COMMENTS = NO` — the project-level `YES` still
  covers every other target. (2) 50 were gotcha 6 again — MainActor default
  isolation, helpers never marked `nonisolated` — and collapsed to FIVE
  annotations: `EvalState` (37 call sites on its own), the private `Data`
  byte-reinterpret extension, `BooleanIntent.Op.kernelKind`,
  `HistoryPanelView.fmt`, and `CommandRegistry`'s catalog lookups. All are
  pure values; Swift 6 would have made every one a hard error. (3) Two dead
  `case nil:` arms on a non-optional `Result` (the sweep and draft-extrude
  hole cuts) deleted — unreachable since `booleanResultWithAncestry` stopped
  returning an Optional, and `.failure` already reports better. (4) A REAL
  race: `CancelToken` was `@unchecked Sendable` around a bare mutable `Bool`,
  written on the main actor and read from Euclid's CSG worker threads
  (`KernelOps.boolean` passed the getter in un-`@Sendable`). It is now an
  `OSAllocatedUnfairLock` and the closure is `@Sendable`, so the conformance
  is checked rather than asserted. A follow-up pass took the last five of
  ours: two `var`->`let`, a no-op `try` on the non-throwing
  `AgentExec.entity`, the `[weak self]` capture Swift 6 rejects (strongify
  BEFORE the actor hop), and the AppIcon set's 20 "unassigned children" —
  which turned out to be a full watchOS icon family, entries AND pngs, in a
  project whose `SUPPORTED_PLATFORMS` is `iphoneos iphonesimulator macosx`
  with no watch target anywhere. **125 -> 5, and all five left are outside
  our sources**: 3 ld search-path lines (an Xcode Metal-toolchain cryptex
  path), the vendored OCCT `sprintf` deprecation, and an AppIntents note.

## Mission log — 2026-09-03 (landed, all committed and pushed, 1263/1263 green)

- **SOLIDWORKS practice-problem database, first pass (2026-09-03).** The
  365-sheet database (18 levels, each sheet printing the part's volume)
  gets a runner: `scripts/swpp/kit.py` drives the app through the agent
  bridge with palette-equivalent operations, in a fresh document per
  problem, and scores the body volume against the sheet to 0.5 %;
  `levelN.py` hold the recipes read off the sheets, `results.jsonl` the
  ledger, `report.py` the summary (`docs/SWPP_PRACTICE_PROBLEMS.md`).
  First pass: 29 sheets across levels 1, 2, 4, 6, 7, 8 and 11, 25 pass,
  4 fail — every fail a two-reading drawing whose printed volume picks
  the reading the drawing does not show, none a kernel fault; 0 feature
  errors over ~180 recorded features (extrude/cut/union, arcs,
  ellipses, polygons, slots, fillets, chamfers, revolve, open and closed
  sweeps, mirror, linear/circular patterns, multi-tool subtract). One
  sheet (2.13) built entirely by touch, info bar 8009.08 vs 8009. The
  campaign's capability gaps against the database, for the roadmap:
  extrude end conditions (up to surface / next / through all — Level 2
  and every rib), feature patterns (patterns act on bodies), hole
  wizard, angled reference planes, sketch patterns and global variables,
  draft of existing faces, loft profile normals. Sheets are fetched to
  the scratchpad from the database's `/api/headless/problems` index
  (some are zips; the server throttles after ~150 downloads).
  Second pass (same day): 43 sheets, 35 pass; and the first gap closed —
  **extrude end conditions**: `ExtrudeEndKit` resolves Through All (the
  targets' extent along the normal + 1 mm) and Up To Next (the first
  face a ray from the profile centroid hits, the sketch's own face
  skipped) into the node's distance at commit time, from the bodies'
  world-space render meshes. Reached from the Extrude bar's new End menu
  (the value lands in the Distance field, still editable) and from the
  agent (`feature.extrude` `"end"`, the distance's sign giving the
  direction). The node stays a plain distance, so the History row and
  every downstream consumer are unchanged; a live re-evaluating end
  condition is the next step if the sheets need it.
  `ExtrudeEndKitTests`, `testExtrudeEndConditionReplacesTheDistance`.
  Third pass (2026-09-03, by touch on the simulator): the End menu
  checked with the fingers — a 25 mm circle on a block's top face, `-1`
  typed, End › Up To Next writes −20 into the field, Extrude cuts it —
  and that check found the campaign's biggest UI finding: **every
  touch-committed create tool left a MESH-ONLY body.** `commitToolResult`
  did the boolean in Euclid, replaced the body with that mesh and
  appended the feature node without evaluating it, so the hole was a
  48-gon (0.29 % small), `brep: false`, no STEP, mesh-path blends —
  while the same node over the agent bridge was exact, because the
  bridge calls `rebuildFrom`. Now both commit paths (boolean and
  stand-alone) go through `session.recordAndRebuild` (which grew an
  `extra:` for the sketch auto-hides, same undo step); the Euclid result
  stays the fallback when the replay reports an error, and the path for
  multi-body cuts and non-feature targets. Live after the fix: the cut
  reads 80730.09 (analytic) with `brep: true`, and a stand-alone
  cylinder 19634.95, both `/v1/check` clean. Rebuilt sheet volumes from
  the runner were never affected (bridge path); touch-built ones (2.13's
  8009.08) were exact only because they had no round edges.
  Fourth pass (2026-09-03, later): 65 sheets attempted, 57 pass, and 54
  more read and set aside with a reason each (`scripts/swpp/deferred.json`,
  a table in the doc and the report page). Levels 3, 5 and 16 are the
  ones to know about: **every Level 5 sheet built (5.1, 5.2, 5.9, 5.13,
  5.14, 5.16) needed a plane at an angle**, which the runner gives the
  bridge as an explicit basis (`plane_at`) — the UI still has no
  angled-plane tool, so this is a capability the app has and the palette
  does not expose; Level 3's sketch patterns are laid out by the recipe
  as one polygon (rack teeth, heat-sink fins, gear lobes) and pass to the
  mm³; Level 16's equation sheets print several volumes, so
  `run_problem` now scores every configuration of a sheet in one row
  (`meta["configs"]`, 9 configurations across 16.2–16.5 all within
  0.01 %). Runner additions: `_lobed_outline`/`_lobes_concave` (tangent
  arc outlines), `_fillet_path` (sweep spines with R bends as chords),
  lettered sheet ids sort. Reading, not the app, is what stops the
  count: the deferred sheets are drawings whose callouts don't fix the
  geometry or whose printed volume no reading matches.

- **Draft of an existing face (2026-09-03).** The next capability gap the
  sheets named (Level 12's "ALL DRAFT 5°", Levels 13's shelled castings):
  `KernelOps.draftFace` tapers a resolved planar face about the line where
  it meets a world NEUTRAL PLANE. It is a **shear, not a rotation**, and
  that is the whole design: the first version routed through `rotateFace`
  with a pivot and failed its own tests, because a rigid rotation carries
  the wall's top edge along an ARC — the edge drops by h(1 − cos θ), which
  drags the adjacent top face out of plane and shortens the part. Draft
  must leave every neighbouring face exactly where it is, so each vertex
  moves within its own height instead: `p' = p − tanθ · h · f⊥`, where h is
  the height above the neutral plane and f⊥ the face normal with the
  neutral direction removed. Points on the neutral plane do not move and
  the wall meets the top face h·tanθ in — the number a draft callout means.
  Recorded as a `.draftFace` graph node (History row "Draft Face 5°"), and
  driven over the bridge by `feature.draftFace` {face, angleDegrees,
  neutralOrigin, neutralNormal}. Live: one wall of a 100 × 60 × 20 block at
  5° removes 1049.86 mm³ against the closed form's 1049.86.
  **Known limit:** like every other face-deformation op (move/scale/rotate
  face), it works on the Euclid mesh, so the drafted body comes back
  mesh-only — `/v1/check` reports no brep. An OCCT `BRepOffsetAPI_DraftAngle`
  path is the follow-up if a sheet needs an exact drafted casting.
  `DraftFaceTests` (6): the wedge ½h²·tanθ·d, the sign, the four-wall
  frustum, and the refusal when the face is parallel to the neutral plane.

- **Two TraceParts composite robots rebuilt THROUGH THE UI (2026-09-03;
  suite 1250/1250).** ROKAE CMR-ST600-CR12-C (chassis 950 × 630 × 768 from
  its TraceParts spec table, CR12 arm at the 1,434 mm datasheet reach) and
  Lebai LM3 UP (535 × 450 × 1200 standby envelope, LM3 arm at 638 mm reach).
  TraceParts' 3D viewer and STEP sit behind a sign-in, so the shapes are
  proportioned from the catalogue images and every dimension that exists
  in public is exact. The chassis block of each was built BY TOUCH on the
  simulator (Sketch › Rect drag, the rect's width and height typed as
  dimensions, Extrude with a typed distance, the History row's distance
  field), then `scripts/rebuild_composite_robots.py` adopts that body by
  its bounding box and carries on with the same palette operations
  (fillets, chamfer, draft extrude, subtract, union ×n, Transform › Rotate
  for the arm pose), checking every primitive's volume against its
  analytic and every union for growth; both documents end at 0 invalid
  B-reps with the chassis footprints exact to the mm. The touch pass
  found five real app errors, all fixed the same day (gotchas 34–38): a
  Rect-tool rectangle could not be dimensioned at all, every in-place
  feature dropped a moved body's placement, `/v1/edges` and `/v1/faces`
  reported local coordinates against world-space bounds, the extrude
  bar's Distance field silently commits its stale value from a button
  tap, and Zoom to Fit ignores sketches. Report:
  `docs/COMPOSITE_ROBOTS_UI_REPORT.md` (the published page's source).

- **Rebuild regression retest + first HOLLOW-CASTING part (2026-09-01, late;
  suite 1128/1128).** Every prior rebuild script passes again in a fresh
  document (TraceParts wheel/nut/flange ALL PASS; FreeCAD angle exact both
  ways; wheel mirror+union 0.000%). Two scripts had read result bodies
  POSITIONALLY (`bodies[0]`) and false-failed in a non-fresh document — the
  volume they printed was a leftover body while the real result in the same
  output was exactly right; fixed to read by id (a79c7eb). New:
  `scripts/rebuild_doorlock_zn.py` — item Industrietechnik **Door Lock 6-8
  Zn** (TraceParts door-locks TP01009002003, art. 0.0.488.45) rebuilt from
  its item24 dimensional drawing: die-cast housing extruded to the drawn
  53×64.5×30 envelope then SHELLED to a 3 mm wall with the mounting face
  left open (chosen by kernel face normal via `/v1/faces`, not a guessed
  index), swivel-lever/top-bump/cylinder-boss unions, Ø17 bore; strike
  plate 49.3×56 with 6.2 flange, catch boss to 10, two mounting holes and
  the latch slot. Envelope exact, shell volume = analytic to the mm³,
  assembly **550 g vs the 560 g datasheet (1.7%)** with the wall thickness
  the only assumption. Identical on three runs, including inside a heavy
  document. Second complex part from the same category: **Ganter GN 115
  lockable latch, type LCG** (`scripts/rebuild_ganter_gn115.py`), rebuilt
  from its standard sheet (d = 32 collar, 28 body, 19×45 arm, 100×32
  L-handle) — a REVOLVED housing with the bore carried in the profile, a
  unioned L-handle, and the steel latch arm as its own body so the mass
  check is per material: **251 g vs the 250 g catalogue weight (0.3%)**,
  0 invalid, all B-reps (handle thickness the one stated assumption). By
  contrast item's Door Lock 8 (PA-GF, ribbed moulding, only a pictorial
  drawing) was judged NOT verifiable from public data and deliberately not
  rebuilt — a plain shell of its envelope would land ±50% on mass, which
  is a guess, not a check. Draft/taper extrude also landed earlier today
  (three slices, `DRAFT_TAPER_DESIGN.md`).
- **Volume readback is now B-rep-exact.** The real-part pass exposed that
  every curved part read ~0.3% low (wheel, latch housing, drafted cone —
  0.27–0.29% each): the reported volume was integrated over the render
  mesh, an inscribed tessellation. `MeasureKit.volume(of:)` now prefers the
  B-rep's `BRepGProp` volume (mesh fallback when there is none), and both
  the info bar and `/v1/state.volumeMM3` use it — so a cylinder reads
  π·r²·h to the mm³ and the "accurate" claim no longer carries a faceting
  asterisk. Pinned by `BRepVolumeReadbackTests`.
- **MEASURED: evaluation is not incremental across independent bodies.**
  With the 60M mm³ wheel chain sitting in the document, each of the lock's
  ~14 exec ops cost ~13 s (whole rebuild ~3 min vs ~4 s in a fresh document)
  and RSS climbed 253 MB → 1.6 GB: every op re-evaluates unrelated upstream
  chains. **FIXED the same day — memoised replay** (`INCREMENTAL_EVAL_DESIGN.md`,
  slices 1+2, `EvalCache.swift`): each node is fingerprinted from its kind,
  its referenced sketches/planes and the stamps of the bodies it consumes
  (a Merkle chain over producer fingerprints), and an unchanged node is
  spliced from its journaled delta instead of re-run; the session then skips
  the `ReplaceBodyCommand` for bodies whose revision is unchanged, so the
  GPU does not rebuild them either, and the read-only replays (error
  refresh on load/undo/redo, edit previews) use a discarded copy of the
  memo. Same document, same script: the heavy-document trivial extrude went
  **18–21 s → 0.04 s (~500×)**, RSS per op **+70 MB → +0.2 MB**, undo
  **full replay → 0.04 s**. Correctness rests on `consumedBodyIDs`
  enumerating every body a kind reads — an op that reads an undeclared
  body must declare it or run uncached (gotcha 19). **Gated by the full UI
  suite (2026-09-02): 105 tests, 2 skipped, 1 failure — and that one was
  `DeleteFaceUITests` pinned to the old faceted 524.62 mm³; with the B-rep-
  exact 524.60 it passes (1a4d332).** No regression from the memo anywhere.
  Then **off-main eval slice 0** (`OFF_MAIN_EVAL_DESIGN.md`): the rebuild
  planner — replay, diff, commands — extracted from `performRebuild` as a
  pure function (`RebuildPlanner.plan`) so the diff semantics are unit-
  tested as values for the first time (`RebuildPlannerTests`, 7 cases,
  incl. "unchanged rebuild → no commands"); verbatim, zero behaviour
  change, 1146/1146. It is the seam the detached evaluate needs.
  Then **draft/taper slice 3, arcs** (`DRAFT_TAPER_DESIGN.md`): rounded
  profiles — slots, rounded rectangles — now draft EXACTLY via
  `SegmentOffset` (lines shift, arcs stay concentric, tangent joints
  sealed, line–line corners mitred; both loft sections on the segments
  channel so arc walls are true cones). Closed-form acceptance: the
  drafted slot matches Steiner's A₀h − P₀·tanθ·h²/2 + π·tan²θ·h³/3 from
  the B-rep to 1e-4. Non-tangent arc joints fall back to the polygon path
  by design. 1154/1154. And **composed hole-wall naming**: the holed draft
  now lofts each bore with a history, names it from its hole profile, and
  composes through every subtraction exactly as `evalBoolean` does — a
  drafted bore's walls resolve by identity (`profileWall(entity: hole)`),
  closing the topological-naming mission's last "relabels by geometry"
  case. Then the last gap: **non-tangent arc joints** trim or extend both
  offset pieces to their carriers' nearest intersection (line–arc via
  line–circle, arc–arc via circle–circle) and re-derive the arc's mid,
  refusing only when the carriers no longer meet — pinned by a "D" and a
  lens in closed form. **Draft/taper (playbook M1) is complete for every
  line/arc profile.** 1156/1156.
  Then **spline-as-profile slice 0** (`SPLINE_PROFILE_DESIGN.md`):
  `CatmullRomBezier` — the exact cubic Bézier spans of the centripetal
  Catmull–Rom the sketch draws (so the kernel can build the SAME curve, no
  shape change for existing sketches) plus a Gauss-exact closed area;
  pinned against `splinePoints` to 1e-9. 1161/1161.
  **Slice 1 landed the same day:** a sketch spline is an exact profile end
  to end — one `Geom_BSplineCurve` edge assembled directly from the Bézier
  chain, `ProfileDetector` making splines participate (a `.spline` entity
  had been ignored entirely — not a profile at all), one smooth wall named
  by the entity, draft falling back to the polygon path. Pinned pole for
  pole against the kernel and by exact volume (closed form, 1e-6). **And a
  finding: `BRepGProp`'s default volume rule is inexact on B-spline
  geometry** (0.4–1.3% depending on parameterisation alone); `OS3DVolume`
  now uses Gauss–Kronrod per knot span and matches to twelve figures —
  gotcha 20. 1166/1166. **Slice 2 landed too:** blends on the spline wall
  build or refuse typed across every edge and radius, a rim fillet adds a
  blend face, a chamfer builds, oversize and out-of-range edge indices
  refuse typed (`SplineBlendStressTests`). 1170/1170. Slice 3 (a real
  splined part) remains.
- **Curved sweeps were wrong; fixed (2026-09-02).** Asked to build a
  Helicoil (a diamond-section wire swept along a helix), the sweep's B-rep
  came out at 0.8% of its volume — valid per BRepCheck, right-looking in
  the mesh. Minimal probes showed V/(A·L) = mean cos(chord angle):
  `BRepOffsetAPI_MakePipe` translates the profile along a polyline without
  turning it. `sweptShape` now uses `MakePipeShell` with mitred corners
  and a section rotated normal to the spine by our own transform (so the
  history survives), and a polyline sweep encloses exactly A·L
  (`SweepSpineTests`: quarter arc, 90° corner, bends, radii). Gotcha 21
  has the three traps. 1175/1175. **Then the exact helix landed:**
  `FeatureKind.sweep` gains an optional `HelixSpec` (axis, reference
  direction, radius, pitch, turns, start angle) — the B-rep sweeps along a
  true helix edge (a line in a cylinder's (angle, height) parameter space,
  Frenet mode) while the render polyline is sampled from the same spec;
  `feature.sweep` accepts `"helix"`. By Pappus a helical sweep is exactly
  section area × turns·√((2πr)²+p²): `testExactHelixSweepIsAreaTimesTrueLength`
  (two caps + four helicoidal walls, 1e-5), and the HELICOIL rebuild
  (`rebuild_helicoil.py`, exact mode) matches to 1e-4. Documents written
  before helices decode with `helix` absent. 1176/1176.
- **2026-09-02 — BEG 55 tapping-unit lineup (E2 Systems, TraceParts
  90-29052019-034131), `scripts/rebuild_beg55.py`.** The "product" is eight
  variants 200 mm apart (Ø150/Ø178 octagonal motor × drive train behind or
  mirrored to the front about z = 42 × plain Ø52 nose or Ø64 collet chuck),
  nine parts each — 72 reference parts, 112,982 triangles. The TraceParts
  preview archive was not fetched; the reference is the product page's own three.js viewer:
  its WebGL draw calls were intercepted for one frame and every position
  buffer read back (world mm, one modelView for all draws), then bounding
  boxes, signed volumes, and plane-cut section polygons (chained, DP 0.4 mm)
  were computed in-page. Every profile in the rebuild comes from those
  sections. Result (`beg55_report.json`, report artifact "BEG 55 Rebuild"):
  bracket −0.07 %, feed housing +0.4 %, switch box −1.2 %, quills +1 %,
  motors +2.2/+2.5 %, body +4.3 % (the belt housing modelled solid), valve
  +4.9 %, plate +6.3 %, belt-cover ring −10/−16 % (not a body of revolution);
  total +2.3 %; envelopes exact (≤ 0.7 mm) on all but the cover (4.8 mm
  behind; 15 mm on the front-mounted units, where the reference cover is
  rotated 90° — its ears sit along y, the mirror keeps them along x);
  72 bodies, all analytic, 0 invalid. Then, with the user's OK, the
  manufacturer's dimension sheet (`beg55-1200.pdf`, 294 KB, one page, no
  text layer — the site 403s plain http, https with browser headers works;
  read by eye at 3400 px) was fetched and 19 callouts compared, datum = the
  housing front face: 12 exact to the millimetre (width 140, A 150/178, axis
  heights 72/237.7, feed top 148.5, width 76, Ø52/64/70, boss 3, flange 183,
  T-slot 7/5.5/19.5, stop rod 21.5/42); body back −0.2, switch box −2,
  overall height +2.7 (the sheet's 360 is the Ø178 terminal-box top), quill
  45 vs the 43–47 stroke, bracket back −5.7 (the 459 likely runs to a cover
  plate the CAD omits), motor B +9 (B excludes the 9 mm front cap). The CAD
  and the rebuild agree with the sheet identically — the rebuild's profiles
  came from the CAD. **Then transform-as-a-feature (2026-09-02, `3f3c4ca`):**
  `FeatureKind.transform` had been a "tranche 2" eval error; `evalTransform`
  now composes the delta onto the body's placement (as a pattern instance
  carries one — no kernel call, analytic solid + element names kept, same
  id, revision bumped so the session replaces the render; scale refused),
  and `feature.transform {bodyID, translation, rotationDegrees, rotationAxis,
  rotationCenter}` exposes it (rotation about a centre folded in as
  T·R·T⁻¹; identity refused). **The interactive half landed the same evening:**
  the Move / numeric move / Rotate / Translate / Align tools commit through
  `EditorViewModel.commitTransforms`, which turns every feature-owned body's
  move into a `.transform` node (delta = after ∘ before⁻¹,
  `Transform3D.delta(from:to:)`) appended and rebuilt in ONE undo step
  (`DocumentSession.recordAndRebuild` — the appends ride as the rebuild
  composite's leading commands); the live preview's outside-the-stack
  mutation is put back first so the composite's "before" is the true before.
  The design worry (a body moved twice) dissolved on reading
  `RebuildPlanner`: it never preserved a document-level transform — a gizmo
  move was simply LOST on the next parameter edit (its own "tranche-1
  limitation" note) — so the node fixes a real bug. Bodies with no producing
  feature (imports) and the Scale tool keep `TransformBodiesCommand`.
  `testTransformDeltaComposesBackToAfterAndDrivesANode`;
  `GizmoFlowUITests.testGizmoDragCreatesUndoableMove` still passes. 1209/1209.
  **Scale followed:** the node's composition is a similarity now (rotation
  R_δ·R_b, scale s_δ·s_b, translation R_δ·(s_δ·t_b)+t_δ); the B-rep placement
  already carried scale (the full matrix into `gp_Trsf::SetValues`) and the
  volume is cubic, so nothing else moved. `feature.transform` takes `scale`
  (about `rotationCenter`, `bad_scale` ≤ 0) and the Scale tool commits nodes
  like the others — its "scale about the body's pivot" is exactly
  delta = (I, f, t − f·t). `testTransformNodeScalesTheBody` (×2 → 8× volume). **Then the draft's consumed edges (`6ae1699`):**
  `ProfileOffset.offsetLoop` refused any outline whose short edges an inward
  offset consumed (every 2 mm corner cut under a 14 mm draft — measured
  outlines are full of them). Each run of consumed edges now collapses onto
  the meeting point of its surviving neighbours' carriers, keeping the vertex
  count (the draft lofts edge-for-edge) with the run's vertices 1e-3 apart,
  so the wall over a consumed edge is a sliver; survivors that still reverse,
  or fewer than three, stay nil. Pinned by the prismoid-exact volume of a
  drafted chamfered outline (45,306.67 mm³). 1186/1186. The exact
  line/arc path got the same rule (`a49705c`): consumed line pieces collapse
  onto the meeting point of the neighbouring carriers with both joints ON
  those carriers, so a rounded-and-chamfered outline keeps its exact conical
  arc walls when the draft eats the chamfers (8 mm inward still refuses).
  1188/1188. **Then plane sections (`588b77e`):** `OCCTKernel.sectionPolylines`
  (bridge: `BRepAlgoAPI_Section` with approximation, each section edge as a
  polyline in its own direction — a line as two ends, a curve sampled at a
  chord deflection) + `SectionKit` (pure: chain the pieces into loops in the
  plane frame, merge collinear runs, sign the shoelace areas, largest first)
  + `GET /v1/section?body=&normal=&origin=&xAxis=&deflection=` on the body's
  PLACED solid. The drawing view — a rebuild can now be checked
  section-for-section against a reference cut (the BEG 55 comparison had to
  section the reference by hand and the rebuild by envelope). Pinned on a
  box across/oblique/clear, a 96-gon prism, and a true cylinder (the exact
  uniform N-gon at a 0.002 mm chord; along the axis a 10×8 rectangle).
  1196/1196. **Then exact face areas (`32ad9e2`, gotcha 23):** both
  `BRepGProp::SurfaceProperties` rules are off on a B-spline wall (+1.3 % /
  −4.6 %), so `faceInfoOfShape:` integrates untrimmed iso-rectangular faces
  per knot span itself (10-point Gauss–Legendre on |∂S/∂u × ∂S/∂v|), planes
  by the adaptive rule; pinned to 1e-6 against the Bézier perimeter × height.
  **Then holed-sweep naming (`55c53dc`):** `evalSweep` sweeps the outer alone
  and each hole as its own tube, subtracts with ancestry and composes the
  names through every cut (the drafted bore's pattern), so a holed sweep's
  bore walls are named by the hole entity instead of coming out nameless
  from the bridge's in-sweep cut. 1197/1197. **Then spline slice 3 and two
  hangs (`9ae2573`, `070b29f`):** the catalogue lever picked for a splined
  outline (Fixtureworks WL100) proved to be lines and arcs, so the real
  spline part is a plate cam with a cycloidal law — one closed 72-point
  spline plus a Ø10 bore, 8 thick (`rebuild_cycloidal_cam.py`). It hung the
  app twice for minutes, both times in Euclid CSG, never the kernel
  (gotcha 24): the sketch fill's `Mesh.fill([paths])` union on the
  MainActor, and the extrude's render prism subtracting the bore by BSP
  before OCCT was asked. Fixed with `PolygonTriangulator` (hole bridging +
  ear clipping, 5 ms on the 1,152-sample outline) and kernel-first extrudes
  (Euclid only as the fallback; the boolean-into-target tool built lazily).
  Live: 2 s, B-rep 17,083.915 mm³ = the interpolating spline's Gauss-exact
  area × 8 less the bore to 1.8e-8, −0.0003 % against the true cam (the 5°
  sampling), 4 faces, 0 invalid. 1203/1203. **Then the holed sweep's render
  mesh (`9310d3d`):** its BSP subtract of the hole cutters (the same hazard,
  and `emitFullSolid` keeps the Euclid render on purpose) replaced by walls
  for the outer (CCW) and every hole (CW) through the shared transported
  frames (`sweepFrames`) plus `PolygonTriangulator` caps — the 1,152-sample
  outline with a bore sweeps in 0.1 s to the exact prism volume, and a holed
  sweep round a mitred corner stays watertight. 1205/1205. **Then the loft
  (`81e54ed`):** Euclid's loft over subpaths is a symmetric difference, and
  even its capped single-loop tube took 18 s on a thousand-gon; the kit now
  builds every loop family as ring-to-ring quads with its own start
  alignment, inverts the hole tubes, caps with `PolygonTriangulator`, and
  settles orientation by the signed volume — a square ring lofts to the
  exact hollow frustum, the dense holed outline in well under a second.
  That builder is now the only render path for sweeps and lofts. 1207/1207.
  Landed on the way:
  `/v1/state` bodies now carry `bounds` (mesh min/max, mm); `feature.mirror`
  `keepOriginal:false` now CONSUMES the source (it was a documented no-op —
  `testMirrorWithoutKeepOriginalConsumesTheSource`); a draft extrude refuses
  offsets that eat a profile's short segments ("offsets the profile into
  itself" — the plate outline's 2 mm corners), so drafted slabs use a clean
  rectangle. Found (fixed the same day, next entry): `feature.loft` between
  two similar octagons on parallel planes KILLED the app (connection closed,
  no .ips) — the octagonal motor frustums use draft extrudes instead. Also:
  a headless-booted simulator gets shut down by later xcodebuild runs — boot
  it under Simulator.app (`open -a Simulator --args -CurrentDeviceUDID …`).
  1179/1179.
- **The loft-union app death, found and fixed (2026-09-02).** Reproduced
  as pure values in `LoftOctagonTests` (the BEG 55 end cap: two similar
  octagons on z = 73 / z = 98 lofted and unioned into the octagonal body
  extruded from z = 98): the kernel loft alone and the graph loft as a NEW
  body were fine; the union died. Not in the kernel at all — the stack
  (SIGTRAP hook, gotcha 23) ended in Euclid's `Mesh.triangulate()` under
  `EuclidBridge.renderMesh(from:)` while `emitFullSolid` built the result
  body from the EUCLID union it still ran unconditionally before assigning
  OCCT's brep over it. The two coincident caps disagree at the 1e-6 level
  (the target's CSG mesh is rebuilt from Float32 render buffers, the
  tool's is Double), the BSP clip left a loft wall with four vertices
  5e-7 mm apart, its triangulation dropped the sliver, and Euclid's own
  `assert` on the watertight claim it carries onto the triangulated mesh
  trapped the process. Two fixes: (1) the revolve/sweep/loft boolean branch
  is now OCCT-first — `composedBooleanResultWithAncestry`, adopt the fused
  solid, compose names through the ancestry, Euclid only when OCCT declines
  — the order `evalExtrude`'s boolean branch and `evalBoolean` already had,
  so the analytic case never touches the Euclid CSG (and a target with a
  non-identity transform is now placed before the fuse, which the old
  assign path skipped); (2) `EuclidBridge.triangles(of:)` triangulates
  polygon by polygon so the render, STL and twist conversions are pure
  functions of the geometry and can never trip that assertion — pinned by
  `testAMeshUnionWithCoincidentCapsConvertsToARenderMeshWithoutTrapping`,
  which traps without it. The union now reads B-rep-exact (prism +
  frustum to 1e-2 %) with kernel-face names. `rebuild_beg55.py` is back on
  lofts for the motor frustums (end section = the body octagon scaled about
  the axis): full lineup rerun, 72 bodies, 0 invalid, all B-rep, total
  +2.29 % vs reference (motors +2.45/+2.11 %, the other 64 parts byte-
  identical to the draft-extrude run). Running it alongside another
  session's UI suite on the same Mac shut the simulator down twice under
  the app (SimRenderServer trap, no app crash) — the run that counts was
  on a second booted iPad with `OS3D_AGENT_PORT=8901`, `OS3D_PORT=8901`.
  1183/1183 (1 fuzz test skipped by design).
- Two app deaths mid-exec during this pass did NOT reproduce under
  controlled repeats (fresh doc ×2, then the heavy doc, all monitored):
  no crash report, no jetsam, RSS modest; the simulator-control helper
  segfaulted in the same window. Filed as transient/external, not an app
  bug — but see gotcha 17, which is the one way to kill the live app on
  purpose.
- **Topological-naming mission COMPLETE.** Every creation op (primitive,
  extrude, revolve, sweep, loft, boolean) and every modifier (fillet,
  chamfer, shell, push/pull, delete/replace-face, mirror, pattern) composes
  element names; both FaceRefs and EdgeRefs opportunistically upgrade legacy
  refs to identity. Revolve/sweep/loft naming and the EdgeRef upgrade were
  the final deferrals. See `TOPO_NAMING_HISTORY_DESIGN.md`.
- **Real-part validation.** openshape3d builds real CAD parts to spec,
  verified against independent ground truth across three sources:
  FreeCAD tutorials (iron angle exact both ways; op-coverage matrix,
  `scripts/rebuild_freecad_angle.py`), TraceParts catalogue parts (a
  RÄDER-VOGEL cast-iron wheel matched its datasheet weight to 0.7%; a
  hex nut and bolt-circle flange to exact volumes — `rebuild_traceparts.py`),
  and the reference app models. A published comparison artifact shows five of them
  reference-vs-render. Fillet/chamfer stress tests on curved revolved
  geometry are robust (valid or graceful typed failure, never crash/hang).
- **`/v1/exec` scripting surface COMPLETE.** Now exposes every FeatureKind
  that has a live tool: all construction ops, all modifiers, the full
  direct-modeling face family (push/pull, move/scale/rotate face), mirror,
  pattern, and all seven sketch entity kinds (line/circle/arc/spline/rect/
  polygon/ellipse). Also hardened: a wrong-typed `boolean` intent is refused
  (`bad_boolean_type`) instead of silently making a stray body. Only
  `primitive` (covered by sketch+extrude) remains unexposed —
  `feature.transform` landed 2026-09-02 (below). See `AGENT_CONTROL.md`.
- **Sketch conflict diagnosis stages 2–3 + scale-free residuals** (playbook
  S6/S7): the conflict chip now names WHICH constraints clash (red glyphs)
  and add-time refusals name the clashing partners; the four mm² residuals
  read sin/cos/mm so the conflict gate is scale-honest.

What is left after 2026-09-02 (everything else in this list of missions
landed — draft/taper incl. consumed edges, memoised replay, spline-as-profile
through slice 3, transform-as-a-feature on both the API and the tools,
plane sections, exact face areas, holed-sweep naming, CSG-free render meshes):

- **Off-main eval, S1b slices 1–3** (`OFF_MAIN_EVAL_DESIGN.md`) — the
  true async contract; attended work, its own design pass.
- **G8 — every feature parameter editable in History**
  (`MODELING_PARITY_GOALS.md` §G8, the next roadmap item after the round-1
  list): the SCALAR slice landed 2026-09-02 (late) — every kind's scalars as
  labelled unit fields in the row (`FeatureScalar`, `editFeatureScalar`,
  `HistoryScalarEditTests`) — and the OPTION slice right after (symmetric,
  keep-original switches, boolean type menu: `FeatureOption`,
  `setFeatureOption`, `HistoryOptionEditTests`); then the first REFERENCE
  slice — "Edit Faces" on shell and delete-face rows, the blend rows'
  "Edit Edges" pattern generalised (`beginReferenceEdit`,
  `HistoryFaceEditTests`), and "Edit Tool" on boolean rows
  (`beginBooleanEdit`, `HistoryBooleanEditTests`), the repair flow for
  all of them: an errored row shows its re-pick inline under the error
  (`HistoryRepair-<name>`), and "Edit Body" on mirror / pattern /
  transform rows through a generic body-pick mode
  (`pickingFeatureBody`, `HistoryBodyEditTests`), and "Edit Face" on
  push-pull / move / scale / rotate-face rows (`pickingFeatureFace`,
  `HistoryFaceOperandEditTests`), and "Edit Profile" on extrude / draft
  / revolve / sweep rows (`pickingFeatureProfile`,
  `HistoryProfileEditTests`). Every reference family now has a re-pick
  except: a loft's sections, a revolve's axis, the creators' boolean
  intent (new body → subtract needs a target pick), and the radial
  push/pull's cylindrical face; then G9's per-tool variants sit on top.
- **Exact-copy review of the rebuilt parts (2026-09-02, late):** wheel,
  cover, door lock, GN 115, helicoil, cam, FreeCAD angle, TraceParts nut
  and flange, BEG 55 lineup. App-side blockers the scripts recorded were
  all capabilities that have since landed: the wheel's conical cutters and
  the cover's two 10° drafts are on their recipes now (and exposed gotcha
  29 on the way). Left, and NOT app errors: the cover's engraving spline
  and the frame's face-offset / align / shell operands need values only
  the imported recipes hold (not on this machine); the BEG 55 volume
  deviations (cover −9.5 %, plate +6.3 %) are modelling depth against a
  tessellated capture with no drawing behind it. The Tufts CAD-modeling
  tutorial's Coca-Cola bottle (`scripts/rebuild_coke_bottle.py`: the
  traced profile read from the tutorial's own sketch screenshot, 230 tall,
  base r28; revolve to 0.05 % of Pappus, 1.5 mm shell with the mouth open,
  two lip fillets) took gotchas 30–33 to get through — a resolver hang, a
  cap normal, C0 splines and the outward shell — all real app errors.
  Next day (2026-09-03) the two TraceParts composite robots
  (`scripts/rebuild_composite_robots.py`, chassis blocks built by touch)
  added gotchas 34–38 the same way; what is NOT exact there is the arm
  link geometry, which no public drawing gives (scaled to the published
  reach), and the ROKAE arm's mounting position, read off a 456-px image.
- ~~Scale as a node~~ — landed 2026-09-02 (below): the composition carries a
  uniform scale (`Transform3D.composed(onto:)`, `delta(from:to:)`), the
  B-rep placement already did (`gp_Trsf::SetValues` admits it), the volume
  is cubic; `feature.transform` takes `scale`, the Scale tool records nodes.
- ~~Consumed ARCS in `SegmentOffset`~~ — landed 2026-09-02: an arc whose
  offset radius vanishes is consumed up front, the joint pass runs between
  survivors with ε-stubs across any consumed run, and reversed survivor
  lines join the set on a repeat pass (carriers are immutable, so the pass
  is idempotent). A rounded rectangle drafts past its corner radius to sharp
  corners; the slot past its semicircles still refuses (two parallel
  survivors never meet).
- **Scene caching (S2) / `ToolLifecycle` registry (S3)** — S2's first slice
  landed 2026-09-02 (late): a scene-build probe (30 bodies + a 150-line
  welded sketch) put the IDLE scene at 0.2 ms and the SKETCHING scene at
  1,495 ms — all of it `SketchSolverBridge.entityStates`, the Jacobian
  null-space analysis (cubic: numeric Jacobian, JᵀJ, Jacobi eigen on a
  600×600), run inside `scene` on every viewport update and AGAIN by the
  status chip's `sketchDefinitionStatus` on every editor body. Now one
  `SketchSolverBridge.definitionReport` (states + DOF from a single solve)
  is memoised on the SKETCH VALUE in `EditorViewModel.sketchDefinitionReport`
  and computed on a detached task, latest-wins (drag ticks coalesce); the
  scene reads the previous report until the new one bumps
  `sketchDefinitionEpoch`. `SketchDefinitionCacheTests` pins one solve per
  sketch value, coalescing, colours/DOF, and a <0.2 s scene build with the
  150-line sketch open (was 1.5 s). The DRAG tick was the same story
  (`solveOutcome` = the LM solve + the analysis, 1,700 ms at 150 lines):
  the solver's dense kernels — the Cholesky per LM attempt, the Jacobi SVD
  for DOF after every solve, the Jacobi eigen for the null space — now run
  on Accelerate's LAPACK through a C shim (`OS3DLinearAlgebra.c`, Fortran
  ABI prototypes declared locally because clang modules ignore a file-local
  `ACCELERATE_NEW_LAPACK`), the analysis Jacobian uses the constraints'
  `variableIndices` instead of re-evaluating every constraint per variable,
  and a drag remembers its structural DOF after the first tick
  (`knownDOF`). 150 lines: tick 1,700 → 70 ms, bare solve 930 → 18 ms;
  50 lines: 81 → 9 ms (`LinearAlgebraTests`, `DragTickDOFTests`; the pure
  Swift routines stay as `*Reference` fallbacks). What is left in a tick is
  the LM iteration count itself — a sparse solver is the next step if a
  sketch ever needs it. Still open in S2: the renderer's per-frame
  `makeBuffer` for sketch-line/fill batches (orbit frames), preview bodies
  re-uploading all buffers per tick, measurement caching; S3 untouched.
  Gotcha 26 below.

**Current test baseline (2026-09-03, evening): 1263 unit tests in ~24s** —
`ExtrudeEndKitTests` (6, Through All / Up To Next) and `DraftFaceTests` (6,
draft of an existing face) on top of the previous line:
**(2026-09-03): 1250 unit tests in ~27s** — the rect
width/height dimension solve and the fillet-keeps-placement regression on
top of the previous line: **(2026-09-02, evening): 1248 unit tests in ~21s** — the
day added the exact helix spine, the BEG 55 lineup's bounds/mirror fixes,
transform-as-a-feature, consumed-edge drafts on both offset paths, plane
sections (`SectionKit`, `KernelSectionTests`), the exact face areas, and the
loft-union crash fix (`LoftOctagonTests`, merged from its own branch).
Earlier that day: **1170 unit tests in ~20s** (draft/taper incl.
arc profiles and non-tangent joints, spline profiles with exact B-spline walls, B-rep volume readback, memoised replay, rebuild planner all added on 2026-09-01/02; the
previous line follows) — **(2026-09-01): 1115 unit tests in ~17s** (1 skipped:
the on-demand `OCCTFuzzTests` hostile-input sweep, run with
`TEST_RUNNER_OS3D_FUZZ=1`). Earlier this session: 1086 → the naming
completions, real-part regressions, exec expansion, and conflict-diagnosis
work added the rest. Historical: 1013 after the FreeCAD-hardening tranches,
920 on 2026-08-30 (down from ~100 s once booleans stopped running both
kernels, §3b). Prior baseline paragraph, for the record:

**(historical) Current test baseline (2026-09-01): 1086 unit tests in ~17s** — the
debug-tooling tranche (§4 mission 0c) added 21, topo-naming steps 1–5a added
~35 (ancestry, element naming, name-first resolve, identity blends,
modifier-op history), the exec identity ops most of the rest, and
revolve/sweep naming (landed 2026-09-01, commit 279a311 — including the
OCCT full-revolve `Generated()` gap and its `Revol().Shape(edge)` recovery,
see `TOPO_NAMING_HISTORY_DESIGN.md`) the last 4, on top of the 1013 the
FreeCAD-hardening tranches left. Previous baseline (2026-08-30):
920 unit tests in 18s — down from ~100 s after booleans stopped running both
kernels (see §3b). **Full UI suite last measured 2026-09-02** (105 tests in 46.5 min after the memoised replay: 104 green + the DeleteFace expectation corrected to the B-rep-exact volume; previously 2026-09-01) (covering all
of the above): 104 executed, 2 skipped, 46m19s — 1 failure
(`DragSolveUITests.testDragTopCornerKeepsHorizontalEdgeAndCoalesces`, passed
clean in isolation immediately after: the documented long-run-flake pattern,
and a sketch-solver test unrelated to the naming work), 2 idle-timeouts,
0 field-clear retries. The ~2 min over the prior 44m28s tracks the two 60 s
idle-waits plus one more executed test. The skips are
`CompactWidthBarUITests`, which skip by design on the iPad destination.

UI wall clock is flat across the whole of mission 2 (44m18s → 44m10s →
44m28s): it added 29 unit tests and no UI tests. The run before THAT was 43m14s, and the minute
it gained was the four `CommandSearchUITests` (~41s in isolation) — worth
checking rather than assuming, since that commit registers keyboard shortcuts,
and a keyboard change is what once took a suite from 41 to 78 minutes while
still reporting green (the ⌘A trap below).

The STEP-interchange commit before it ran the UI suite CLEAN TWICE IN A ROW
(96 executed, 42m29s each). Two runs, not one, was the point there: run 1's
build predated three late edits, and a run that does not test what you commit
proves nothing about what you commit.

Two runs, not one, is the point: the three runs before the fixes each surfaced
a DIFFERENT pair of failures, so a single green run proved nothing. Four other
numbers are worth reading alongside the pass count, because a green suite hid a
regression once already (see the ⌘A trap below) — all four were clean on both
runs above:

| Signal | Healthy | Why it matters |
|---|---|---|
| wall clock | ~42m | 78m with ⌘A firing Select All — and still green |
| `animations complete notification not received` | 0 | each one is a 60s idle-wait timeout |
| `OS3D_BUG field held` | 0 | the field-clear self-heal is not having to paper over anything |
| projects in the store | 1, before and after | it used to climb ~95 per run |

**The four long-serial-run flakes are fixed** (2026-08-28) — see "Flaky UI
tests: what they actually were" below. They were bad tests, not bad app code,
with one exception that was a real accessibility bug. Runs now also start from
an empty store (`OS3D_RESET_STORE`), so the suite no longer degrades as it goes.

Historical counts appear in the dated sections below — those are snapshots,
not the baseline.

**Sections dated in the past are history.** §1 and §4 are the only two that
claim to describe the present; if you find them disagreeing with the code,
the code wins — fix them in the same commit.

---

## 1. Where the project stands

| Phase | Status |
|---|---|
| **A** — planes, sketch tools, revolve, transform, items, views, IO | ✅ done |
| **B** — sweep, loft, split, pattern, offset, text, project, section, display, selection, materials, symbols | ✅ done |
| **C** — 2D constraint solver (Levenberg–Marquardt), dimensions, auto-constrain, DOF coloring, sketch mirror | ✅ done |
| **D** — parametric feature graph: topo naming, all creation ops, sketch associativity, variables/expressions, pattern-as-feature, rollback, **reorder + suppress** | ✅ done (tranches 1–6) |
| **E** — edge blends: chamfer/fillet, multi-edge, live preview, drag-to-size arrow | ✅ tranches 1–3 done |
| **E4** — Shell (face-removal + whole-body) | ✅ done — `FeatureKind.shell`, `KernelShellTests`/`FeatureShellEvalTests`/`ShellUITests` |
| **F (B-rep)** — OpenCASCADE port | ✅ largely landed — see §4 F for what is left |
| **STEP interchange** — exact-B-rep import/export | ✅ done 2026-08-29 — `STEPKit`, §4.1b |
| **Delete Face** — OCCT defeaturing, live | ✅ done 2026-08-29 — `DeleteFaceKit`, §4.1c |
| **Replace Face** — extend/trim a face onto a plane | ✅ done 2026-08-29 — `FeatureKind.replaceFace`, §4.1d |
| **Command Search** — fuzzy command launcher | ✅ done 2026-08-29 — `CommandSearchView`, §4.1e |

**The kernel seam has moved (re-audited 2026-08-28).** OCCT is no longer a
spike: when `OCCTKernel.useOCCTAsSourceOfTruth` is on and a body carries a
`brep`, extrude, boolean, **fillet, chamfer, shell and delete-face** all run
through OCCT (`FeatureGraph` for the parametric path, `EditorViewModel` for
the live preview), and breps persist through `DocumentSession`
(`OCCTKernel.serialize/deserialize`). The Euclid mesh blend is now the
**legacy fallback for brep-less bodies only** — a brep body whose OCCT blend
fails ERRORS rather than degrading to it (FeatureGraph ~L836 explains why:
the mesh path ships spiky facets on analytic solids and desyncs render from
brep). Read that comment before touching either path.

**Architecture review (2026-08-25): `ARCHITECTURE_REVIEW_2026-08-25.md`** —
four-pass deep review; criticals: silent data loss on save of undecodable
rows, no schema versioning, undo-stomp from armed transform tools, and the
path-dependent Euclid-vs-OCCT kernel seam. Read it before the next tranche.
**Same-day fix pass:** all four criticals fixed (C4 largely — see the fix
table in the review doc), plus the S3 lifecycle bugs, S6 composite undo,
the OCCT exception barrier, the `pullArrowState` orbit-perf fix, and every
ship-config item (privacy manifest, iOS 17.0 target, display name,
encryption key, `#if DEBUG` hooks).

**Round 2 (same day, deeper + adversarial):** fixed two crash-on-input
classes — an `Int32` weld-key trap at **20 sites in 6 files** (including
both importers: any model past ±21 m or containing a NaN crashed on
import/tap) and `MeshBlob.decode` accepting out-of-range indices (a shared
`.os3d` could crash on open). The adversarial pass over round 1's own fixes
found and closed three real gaps in them: C1 leaked at column granularity
(brep/material/primitive blobs were still being nil-ed over), C3's guard
covered only 3 of 8 history-mutating entry points, and the ghost-preview fix
missed the History-panel delete. **Read the R2 open list before the next
tranche** — it includes two criticals (a radial cylinder drag silently
deleting features; sketch delete/trim orphaning constraints so a driving
dimension quietly stops driving) and an unvalidated-solver-writeback issue.
Still open from round 1, in rough order: off-main eval/preview service (S1),
full scene caching + GPU buffer pooling (S2), `ToolLifecycle` registry
refactor (S3), ref-resolution margin checks (S4), relative epsilons (S5).
**2026-09-02:** the "don't recompute" layer under S1/S2 landed as the
memoised replay (`INCREMENTAL_EVAL_DESIGN.md`: heavy-document op 18 s →
0.04 s, RSS flat); S1 itself is designed in `OFF_MAIN_EVAL_DESIGN.md` —
recommended first slice S1a, a synchronous facade over a detached evaluate,
because `performRebuild` has 9 session callers and 17 external call sites
that all read results immediately.

Also landed recently (all on `main`): context-sensitive direct-touch tool
palette with flyout groups; extrude gizmo = SF Symbol `arrow.up.and.down` +
value pill; drag-reorder of History rows; bug-hunt regression tests.

Sketch/select UX pass (2026-07-21):
- **Orbit mid-sketch**: `EditorMode.sketching`'s tool is now OPTIONAL. Tapping
  the active sketch tool deselects it (same toggle pattern as CreateTool);
  with no tool armed, empty-space drags orbit (taps still select, drags on
  entities/gizmo still edit), so a plane can be sketched from any angle —
  the existing "Look at Sketch" pill button restores head-on. Re-opening a
  sketch from Items now starts with no tool armed.
- **Profile tap arms extrude at 0 mm** (`startExtrude`): pull arrow + bar
  only, no default 2 mm slab; committing at 0 cancels. UI tests type a height
  via the shared `typeExtrudeHeight(_:)` helper (`PullArrowTestSupport`).
- **Select mode selects sketch entities**: tap fallback
  (`toggleSketchEntityUnderRay`) + marquee candidates now built for the
  Sketches-only filter too (was `filter == .bodiesAndSketchEntities`).
- **Consumed sketches auto-hide again (2026-08-25, reversing 2026-07-21)** —
  the user ruled the stay-visible behavior a bug vs the reference app: a tool that
  makes a body now hides every sketch that fed it (profile + loft sections +
  sweep spine) via `consumedSketchHideCommands`, in the same undo step. The
  Items eye (a11y value "hidden"/"visible") brings a sketch back.
- **Delete works on Select-mode sketch picks** (`deleteSelection`): selected
  sketch entities delete outside sketch mode too (bodies + entities in one
  undo step); the palette Delete button enables for them; a plain tap
  elsewhere clears a stale sketch-entity highlight.
- **Extrude no longer grabs flush neighbors** (`commitToolResult`): the
  auto-boolean "touch" test now requires real overlap VOLUME
  (`KernelOps.volume(of:)` on the intersection > 1e-4) instead of any
  intersection polygon — bodies sharing a flush wall produced zero-volume
  slivers that falsely counted as touching. Covered by
  `PushPullKernelTests.testFlushPrismsHaveNoIntersectionVolume`.
- **Orientation Cube = universal orbit control** (`ViewportView.
  gestureDragBegan`): a drag starting on the cube orbits the camera in every
  mode (checked before all mode-specific drag handling); a tap still snaps to
  the view. See spec §7.2.

### the reference app tutorial + manual parity audit (2026-08-26/27)

Drove the "Introducing the reference app basics" starter series against the app on the
iPad sim, then read the official 343-page manual (pages 77–259 = sketching +
modeling) tool-by-tool. Full write-up in `MODELING_PARITY_GOALS.md` §2 and
goals G7–G9. Headlines:

- `PARITY_SPEC.md` is accurate — every manual tool maps to a spec
  section, and the statuses spot-checked against code were all correct.
- **The gap is depth, not breadth**: nearly every tool exists, but only as its
  default path. That became G9 (tool variants/options) and G8 (History exposes
  only four editable scalars, no reference pickers — so a feature's geometry is
  parametric while its inputs are frozen at creation time).
- Landed from the audit: the invisible-panel-label fix (see gotcha 10 — it had
  never been applied to the three side panels), hotkey routing
  (`CommandRegistry` was dead code with zero non-test references),
  **Offset Edge in sketch mode** (G7.1), and **construction axes** (§6.2).
- **Construction axes** are the first new SwiftData model type since Phase D.
  `PersistedAxis` was added the same way `PersistedFeature`/`PersistedVariable`
  were — a defaulted `@Relationship` on `Project`, no `VersionedSchema` —
  and lightweight migration was verified against the existing 95-project
  simulator store. Keep using that route for new row types.

**Baseline at the time of that audit: 797 unit tests, ~85 UI tests — all green**
(current numbers are in the header). Two UI tests
(`FaceFlowUITests/testTypeNegativeIntoArrowPill`,
`SweepLoftUITests/testSweepCircleAlongTwoSegmentLinePath`) are long-run flaky
(pass in isolation) — rerun individually before suspecting a regression.
`HistoryReorderUITests/testDragReorderTwoExtrudes` fails outright as of
2026-09-03 ("Not hittable: HistoryRow-Extrude" at the press-and-drag, both
rows visibly present) — on HEAD before the touch-commit change too, verified
by stashing; it is a pre-existing break, not a regression of that work.

**If the whole test target dies at bootstrap** with *"Early unexpected exit …
Test crashed with signal bus before establishing connection"*, and the app also
refuses `simctl launch` with `SBMainWorkspace` denials, suspect a **wedged
simulator, not your code** — confirm by stashing and launching a known-good
build, then `simctl shutdown` + `boot`. Do NOT `erase`: it destroys the saved
designs. (Hit 2026-08-27 after a long driving session.)

### Rotate orbit + exact angle (2026-08-28)

The rotate half of the same parity pass — `RotationOrbitOverlay`, the twin of
`MoveDistanceOverlay`.

- **Grabbing a rotation arc raises the orbit**: the full circle of that
  rotation, dashed, drawn in the ring's own plane at a radius that clears the
  selection (`rotationOrbitRadius` — the body's bounding radius + 8%, floored
  against the gizmo's own size), with the swept slice solid on top of it. The
  sweep starts where the drag was grabbed (`GizmoDragSession.ringStartAngle`),
  so the arc grows from under the finger.
- **The angle rides the arc**: a live pill at the sweep's leading end, stepping
  in the same 5° snap the drag applies (verified on device: −5°, −10°, … −35°).
- **Tapping an arc types an exact angle** — the rotate twin of tapping an
  arrow. `commitAngleRotate` skips the 5° snap (a typed angle is meant
  literally), goes through `beginMove`/`applyRotation`/`endMove` so it lands as
  ONE undoable step, and honours a repositioned pivot. Verified: typing 45 on a
  4 mm box gives bounds 5.66 × 5.66 × 4.00 = 4√2, exactly.
- `updateRotation` is now a snapping front end over a shared `applyRotation`,
  which is what let the typed path reuse the drag's tested math.
- The pill is clamped into the viewport and, while typing, into the top ~42% of
  it: the orbit is drawn at the BODY's radius, so its rim regularly projects
  off-screen, and the software keyboard owns the bottom half. That radius is
  also why the whole control only reads properly when the body is NOT filling
  the viewport — zoomed right in, the rim and the swept arc leave the screen
  and the clamped pill is all that survives. The reference app has the same property.
- A mid-drag capture of the finished control (orbit + swept arc + live pill +
  highlighted handle) was taken on the iPad sim; it lives at
  `marketing/screenshots/feature-rotate-orbit-mid-drag.png`, which is in the
  **gitignored** `marketing/` tree — a fresh clone will not have it, so re-shoot
  it with the recipe in §3 if you need it.

### Move gizmo parity pass (2026-08-28)

Driven from side-by-side screenshots of the reference app's move control. Everything
lives in `GizmoScreenLayout` (the one source of truth for where handles are)
+ `MoveGizmoOverlay` (drawing) + `ViewportView` (gestures).

- **Plane handles are tiles that lie IN their plane.** `planeCornersLocal` /
  `planeQuad` project the four corners of the tile's square, so the drawn
  shape is a parallelogram that leans with the model and shows which way it
  drags. The hit test uses that same quad: a tap INSIDE it grabs that plane
  outright — before the arrows, and exempt from the pivot dead zone. A tile
  seen edge-on is dropped from BOTH drawing and hit testing
  (`visiblePlaneQuads`), so what is drawn is exactly what is grabbable.
- **Root cause of "the squares don't drag in their plane":** the rotation
  arcs' deliberately fat 50pt touch band reached all the way back over the
  tiles, so a near-miss on a skinny tile became a ROTATION (which snaps in 5°
  steps — it read as the body swinging instead of sliding). Ring hits are now
  rejected inside `ringInnerFraction` (0.75) of the arc's own projected
  radius, and the band never exceeds 0.35 × that radius. Tiles also grew
  (`GizmoGeometry.planeMax` 0.34 → 0.38).
- **Tap the pivot to reposition the control.** The dot becomes a violet
  crosshair; dragging it slides the gizmo on the camera-facing plane while
  the model stays put (`gizmoPivotOffset`, scoped to the current selection by
  `GizmoPivotOwner` so a new selection never inherits a stale drop). A
  repositioned pivot is also the rotation centre. Drag-to-reposition is
  gated on the arming tap, so ordinary drags near the centre are unchanged.
- **Distance pill rides the handle** (`MoveDistanceOverlay`, twin of
  `ExtrudeGizmoOverlay`): live distance while dragging a handle, and tapping
  an arrow opens an inline field (Enter commits, ✕ cancels). The old
  bottom-bar `axisMoveBar` was removed — one input, where the user is looking.
- **Debug hook:** `OS3D_GIZMO_DEBUG=1` prints the grabbed part and each world
  delta (`ViewportView.gizmoDebug`, DEBUG-only, flag read once). It is what
  turned "doesn't lock to the plane" into the ring-band finding in minutes —
  reach for it before theorising about gizmo reports.

**811 unit tests green after this pass, and the user confirmed the gizmo on
device (2026-08-28)** — plane tiles, the on-arrow distance field and the
crosshair pivot are all accepted behaviour now. Treat changes to
`GizmoScreenLayout`'s tolerances as changes to tested, signed-off behaviour.

---

## 2. Architecture of the newest subsystems (Phase E blends)

> **Read §1's kernel-seam note first.** What follows describes the **mesh**
> blend, which is now the fallback for brep-less bodies: a body with a `brep`
> blends through OCCT instead (tangent chains and rolling-ball corners come
> free there — the "known v1 gaps" below are the MESH path's gaps). The
> selection, preview, command and UI plumbing described here is shared by both
> paths, which is why it is still the thing to read.

The mesh-domain chamfer/fillet the spec §4.3 blesses for prismatic edges.
Everything routes through the same three seams as the rest of the app:
`KernelOps` (geometry), `DocumentCommand` (mutation), `EditorViewModel`
(state machine).

- `openshape3d/Kernel/EdgeTopology.swift` — `SelectableEdge` (endpoints + the
  two adjacent face normals + convexity); `selectableEdges(from:)` welds
  positions and merges collinear same-face-pair creases into maximal straight
  edges; `signature(of:)` / `resolve(_:in:sizeScale:)` re-find an edge after a
  rebuild (adjacent-face-normal PAIR dominates the score).
- `openshape3d/Kernel/KernelOps.swift` — `chamferEdge` (subtract a triangular
  corner-wedge prism), `filletEdge` (subtract the corner parallelogram MINUS a
  tangent cylinder **centered on the edge** — Euclid's `extrude` is centered,
  so the cylinder must be too).
- `openshape3d/Model/FeatureRefs.swift` — `EdgeRef`/`EdgeSignature`.
- `openshape3d/Model/FeatureGraph.swift` — `FeatureKind.chamfer/.fillet`,
  `evalEdgeBlend`: resolves `EdgeRef`s against the **input** body (a blend
  destroys the edge it names), errors → History badge. JSON-Codable kinds, so
  no schema migration was needed.
- `openshape3d/Editor/EditorViewModel.swift` — blend section:
  `beginBlend/handleBlendEdgeTap/commitBlend/cancelBlend`, live `blendPreview`
  (recomputed on edge toggle + `blendValue` didSet, rendered IN PLACE of the
  source body, high-bit GPU-cache revision `(1<<62)|n`),
  `beginBlendDrag/updateBlendDrag/endBlendDrag`, `resetBlendState()` (state
  only — **never mutates `selection`**; wired into `cancelTransientPicks` and
  `sanitizeAfterHistoryChange`).
- `openshape3d/UI/ViewportView.swift` — `.pickingBlendEdges` drag branch:
  geometric screen-space arrow grab (same as face push/pull); drag delta
  projects onto the arrow's **on-screen** direction × `worldUnitsPerPoint`.
- `openshape3d/UI/EditorView.swift` — `blendBar` replaces `NumericInputBar`
  in the bottom stack while picking (never two bottom overlays — see gotchas).
- Arrow rendering is free: publishing `scene.pullArrow` during the pick makes
  `ExtrudeGizmoOverlay` draw the handle; `extrudeArrowLabel` is nil in blend
  mode so no extrude pill appears. `isValid=false` (preview ate the body)
  renders it red, and `canCommitBlend` disables Apply.

Tests: `openshape3dTests/KernelBlendTests.swift` (exact volumes),
`openshape3dTests/FeatureBlendEvalTests.swift` (parametric eval, edit-rebuild,
multi-edge additivity, error surfacing),
`openshape3dUITests/BlendUITests.swift` (4 end-to-end flows incl. drag).

### Known v1 gaps of the MESH path (deliberate, documented)
- Corners where 3+ blended edges meet are best-effort (sequential CSG order).
- Concave edges unsupported (material-removal only; concave needs additive fill).
- No tangent-chain auto-propagation (spec: picking 2 edges of a chain rounds
  the whole chain).
- One body per blend feature.
- Fillet cross-section is a prismatic quarter-round (true rolling-ball corners
  and G2 need the B-rep kernel).

---

## 2b. Platforms — iPhone, iPad, and desktop (Mac Catalyst)

The app is universal (`TARGETED_DEVICE_FAMILY = "1,2"`) and builds for the Mac
through **Mac Catalyst** (`SUPPORTS_MACCATALYST = YES`).

**The one prerequisite is an OCCT Catalyst slice**, and it is already in the
repo: `ThirdParty/OCCT.xcframework` is COMMITTED (the static libs via Git LFS,
see `.gitattributes`), so a fresh checkout builds for iOS *and* Mac without
running the build script. Without a `ios-arm64-maccatalyst` slice the Mac build
fails at link with *"no library for this platform was found"* — that is the
only thing that was missing; the whole Swift/Obj-C++ tree compiles for Catalyst
unchanged.

Cost of carrying it: ~140 MB of static lib (LFS) plus the slice's own copy of
the OCCT headers (an xcframework duplicates headers per slice).

To REBUILD the slice — or add another platform — without rebuilding the iOS
ones (an xcframework assembly replaces the framework, so a Catalyst-only run
would otherwise delete them):

```
OCCT_SRC=/path/to/OCCT-7_8_1 \
IOS_TOOLCHAIN=/path/to/ios.toolchain.cmake \
PLATFORMS="MAC_CATALYST_ARM64" REUSE_EXISTING_SLICES=1 \
scripts/build_occt_ios.sh
```

`REUSE_EXISTING_SLICES=1` harvests the existing slices' libs and headers first
and folds them into the new framework. `DEPLOYMENT_TARGET` is an iOS version
(Catalyst is versioned on the iOS scale) and must stay ≤ the app's
`IPHONEOS_DEPLOYMENT_TARGET`.

Build/run for the Mac:

```
xcodebuild build -scheme openshape3d -destination 'platform=macOS,variant=Mac Catalyst'
```

Notes:
- **visionOS was removed** from `SUPPORTED_PLATFORMS`/`TARGETED_DEVICE_FAMILY`.
  It was declared but the platform isn't installed, so it only produced
  destinations that failed to resolve — which broke plain `-destination`
  commands. Re-add deliberately if visionOS is ever a target.
- **"Designed for iPad"** is the zero-work alternative: Apple Silicon Macs run
  the unmodified iOS build, no Catalyst slice needed
  (`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` is already YES). It ships as a
  checkbox in App Store Connect, but gives an iPad-shaped window rather than a
  Mac app.
- AR Quick Look degrades to a plain 3D preview on Catalyst (AR needs a device);
  `QLPreviewController` itself is available, so nothing is guarded out.
- The Catalyst window has a 900×620 floor (`macWindowSizing`) so the layout
  stays in its regular-width form instead of collapsing to the compact bars.

## 3. Dev workflow essentials

- Simulator UDID: `69DB84F4-607C-46F2-9089-3E8C0770B4A9` (iPad). Ad-hoc
  screenshots: `scripts/run_sim.sh`.
- Build: `xcodebuild build -scheme openshape3d -destination 'platform=iOS Simulator,id=69DB84F4-...'`
- Tests (always `-parallel-testing-enabled NO`):
  - unit: `-only-testing:openshape3dTests`
  - UI: `-only-testing:openshape3dUITests/<Class>[/<test>]`
- UI-test helpers in `openshape3dUITests/PullArrowTestSupport.swift`:
  `startSketchTool(app,"Rect")`, `tapPaletteTool(app, group:"Modify", id:/label:)`
  (opens the flyout only if the tool isn't already hittable), `dragPullArrow`.
  Fresh-document launch: `app.launchEnvironment["OS3D_FRESH"] = "1"`.
- Verification hooks: `SelectionInfoBar` rows (Volume/Bounds/Area/Edges…),
  History ids `HistoryRow-<name>` / `HistoryError-<name>` /
  `HistorySuppress-<name>` / `HistoryDistanceField`, Items `ItemRow-*`, error
  alert title "Something Went Wrong".

### Debug env hooks (all `#if DEBUG`; prefix `SIMCTL_CHILD_` for `simctl`)

| Var | What it does |
|---|---|
| `OS3D_FRESH` | Open a brand-new document instead of the gallery/last file |
| `OS3D_AUTO_OPEN` | Open the most recent document straight away |
| `OS3D_DEBUG_SEED` | Seed a 4 mm box, **selected** (`.editingPrimitive`) — the fastest way to a live move gizmo |
| `OS3D_DEBUG_SEED_CYLINDER` | Circle extrude via OCCT (a TRUE smooth cylinder), `brep` and all — it calls `adoptBRep` exactly like `evalExtrude` |
| `OS3D_DEBUG_SEED_BOOLEAN` | Cylinder − cylinder, staying round through the brep path |
| `OS3D_DEBUG_SEED_HOLE` | 10×10×6 box with a Ø4 through-hole (524.60 mm³ B-rep-exact; the mesh read 524.62 before 2026-09-02) — the only seed with a CYLINDRICAL face, so the one Delete Face needs |
| `OS3D_DEBUG_SEED_STEP` | Stepped block, low half to y=6 and high half to y=12 (1800 mm³) — two PARALLEL faces at different heights, which is the pair Replace Face needs and no single-box seed can offer |
| `OS3D_DEBUG_SEED_PRIMBOOL` | Cylinder primitive − box primitive (mixed analytic boolean) |
| `OS3D_DEBUG_SEED_IMAGE` | Reference image on the ground plane, left unselected |
| `OS3D_GIZMO_DEBUG` | Print the gizmo part each drag grabs, its world delta, and the rotation pill's live value |
| `OS3D_RESET_STORE` | **Destructive.** Delete the SwiftData store before it opens — the app starts with zero projects. Every UI test sets it (see below); do not put it in a shell profile or a scheme you also model in. |
| `OS3D_AGENT` / `OS3D_AGENT_PORT` | Loopback control channel for driving the app from Claude (`Agent/`). Health, command catalog, editor state (incl. per-feature `evalErrors`), `POST /v1/command`, `POST /v1/exec`, `GET /v1/check` (geometry health), `POST /v1/capture` (repro snapshot), and a PNG of the viewport. Clients: `.claude/skills/drive-openshape3d/` (Claude Code, via curl) and `scripts/mcp_openshape3d.py` (Claude Desktop). Protocol: **`docs/AGENT_CONTROL.md`**. NOTE: another local service may squat port 8787 (it did on this machine) — the app then binds IPv6 only and curl answers from the wrong server; launch with `OS3D_AGENT_PORT=8899`. |
| `OS3D_KERNEL_CAPTURE` | Failing kernel ops auto-dump their inputs + params as replayable bundles to `Documents/KernelCaptures` (`=0` disables; default ON in the app, OFF under XCTest). Pull with `scripts/fetch_captures.sh`; promote to `openshape3dTests/Fixtures/Captures`. **`docs/KERNEL_DEBUG_TOOLING.md`** is the workflow. |

To read `print()` output from a hook, launch through a console pty:

```
SIMCTL_CHILD_OS3D_FRESH=1 SIMCTL_CHILD_OS3D_DEBUG_SEED=1 \
SIMCTL_CHILD_OS3D_GIZMO_DEBUG=1 \
xcrun simctl launch --console-pty 69DB84F4-607C-46F2-9089-3E8C0770B4A9 \
  com.laan.labs.openshape3d > /tmp/os3d.log 2>&1 &
```

That loop — seed, drive the sim with taps/swipes, read the log — is how the
"plane squares don't drag in their plane" report was diagnosed in minutes
after a long stretch of theorising. Reach for it early.

Do NOT background a `--console-pty` launch from inside an agent tool call: the
call's process group is killed when it returns, the pty closes, and the app dies
with it — presenting a minute later as an inexplicable "connection refused" from
the agent bridge. Plain `simctl launch` survives indefinitely (verified: 80s+
idle, repeated requests). Interactively it is fine; the pty outlives your shell.

### Flaky UI tests: what they actually were (2026-08-28)

Four tests failed only inside the 40-minute serial run and passed in isolation.
None of them was a race in the app. Three were bad tests, one was a real
accessibility bug, and the long run was only ever the thing that exposed them.

- **The store grows all run.** Every test launches with `OS3D_FRESH`, which
  creates a document and never removes it — the store was at **541 projects**,
  climbing ~95 per full run. A bigger store slows launch and save, which shifts
  focus and gesture timing. That is the mechanism behind "only in the long
  run": the FaceFlow bug below went from a rare flake to 3-in-5 IN ISOLATION
  once the store had filled up. `OS3D_RESET_STORE` (wired into all 66
  `OS3D_FRESH` launch sites) pins it at 1 project. Costs one 83s wipe the first
  time; per-test timing is unchanged.

- **Numeric fields arrive PRE-FILLED, and nothing was clearing them.** The
  extrude Distance field and the arrow pill both open holding the current
  value. Typing "-3" into a field holding "0" gave "0-3" (which the expression
  evaluator computes as -3 — right by luck) or "-30" (30 mm into a 4 mm box:
  refused, no command), depending on where the tap put the caret. The failure
  then surfaced ten lines later as "typing a negative should commit an inward
  push", blaming the commit. `replaceText` now clears first and verifies what
  landed. Every test that types a height went through the same trap — a "2"
  landing as "20" extrudes 20 mm and still commits, so it would have PASSED
  while building the wrong geometry.

- **`HistoryRow-<name>` cannot tell two extrudes apart.** Both features are
  named "Extrude", so the identifiers are identical and a reorder is invisible
  to a test. The two extrudes are now given different heights and the row's own
  distance field is read instead. The reorder is waited for and retried once;
  when it silently did not happen, the Undo undid the previous EXTRUDE and the
  test failed at the very end with "1 row" and no clue why.

- **A container `accessibilityIdentifier` hid every sketch point marker** —
  gotcha 2, in the wild. `SketchPointStateOverlay` had one, which collapses the
  overlay into a single element, so no test could tell whether a stroke had
  landed. Fixed with `accessibilityElement(children: .contain)`, the pattern
  `HistoryPanelView`'s rows already use.

- **Duplicate `Constraint_*` buttons.** The Constrain flyout and the Constrain
  MENU both carry them, so a frame with both up makes the query ambiguous
  ("Multiple matching elements found"). Drive-the-UI lookups in that test use
  `.firstMatch`.

#### Two traps when typing into a field from a UI test

Both of these cost a full suite run to find, and neither fails in a way that
points at itself:

1. **Never `typeKey("a", modifierFlags: .command)`.** ⌘A is the app's own
   Select All hotkey (`CommandRegistry` "edit.selectAll"), and shortcuts reach
   the app whether or not a text field has focus — that is what
   `CommandShortcutsView` is for. The app then never reports idle and XCTest
   waits its full 60s for animations on EVERY field edit: the suite went from
   41 to 78 minutes while still passing, one test going 66s → 847s. A green run
   is not enough; check the wall clock.
2. **Never `XCUIKeyboardKey.forwardDelete`.** iOS text input does not interpret
   it — it is typed in as an invisible character, so the field holds
   "2\u{F728}…" and you get `("2") is not equal to ("2")`.

   What works: tap the field's TRAILING edge (`coordinate(withNormalizedOffset:
   CGVector(dx: 0.95, dy: 0.5))`) so the caret lands after the last character,
   then backspace it empty. `field.tap()` hits the centre, and at caret
   position 0 backspaces delete nothing.

### Screenshotting a gesture MID-drag

Verifying a live overlay (the rotation orbit, the drag pill, a preview) means
catching a frame while a finger is still down. Two things make that harder than
it looks, both learned the slow way:

1. **A slow `swipe` is a LONG PRESS, not a drag.** Stretching a swipe to
   several seconds to leave room for a screenshot pops the Select Through menu
   instead: the touch sits still long enough for the long-press recogniser.
   Drive it with `touch_path` and keep every point moving — the movement is
   what cancels the long press.
2. **A single timed screenshot loses the race.** The tool call that starts the
   gesture has its own dispatch latency, so a `sleep N && screenshot` scheduled
   beforehand usually fires before the finger is down. Take a BURST and pick
   the frame:

```
for i in 1 2 3 4 5 6 7 8; do
  xcrun simctl io <UDID> screenshot frames/f$i.png; sleep 0.7
done
```

Identical file sizes = identical frames = the gesture had not started yet; the
first differing frame is the one you want.

### Gotchas that will bite you
1. **SwiftData in XCTest**: any in-process `ModelContainer` with the 7-type
   `PersistedFeature` schema crashes deterministically (malloc double-free).
   Never unit-test `DocumentSession`; use pure `DesignDocument` values +
   `FeatureGraph.evaluate` (see `FeatureGraphEvalTests`) and UI tests.
2. **a11y containers**: an `.accessibilityIdentifier` on a container HStack
   collapses it into ONE element and hides every child control from XCUITest.
   Ids go on leaf buttons/fields only — or put
   `.accessibilityElement(children: .contain)` BEFORE the identifier when the
   container itself needs one. This has bitten three times (the blend bar, then
   `SketchPointStateOverlay`, then `CommandSearchView`), and it never looks
   like an a11y problem: the symptom is a child query returning nothing while
   the container answers to the child's TYPE — the search field came back as
   `textFields["CommandSearchPanel"]`. If a leaf identifier "doesn't exist",
   dump `app.textFields.allElementsBoundByIndex.map(\.identifier)` before
   assuming the view is missing.
3. **Bottom overlays**: `EditorView` has a single bottom `.overlay` VStack
   (info strip + input bar). Add bars INSIDE it (conditionally), never as a
   second `.overlay(alignment: .bottom)` — they cover each other.
4. **SourceKit noise**: per-file diagnostics ("Cannot find type …", "No such
   module XCTest") are cross-file/-target indexing noise. `xcodebuild` is the
   authority.
5. **GPU mesh cache** keys on `(BodyID, meshRevision)` — any transient preview
   body must bump a revision (use a high-bit counter to avoid colliding with
   document revisions).
6. **`MainActor` default isolation** (`SWIFT_DEFAULT_ACTOR_ISOLATION`):
   kernel/graph types must be explicitly `nonisolated` (nested enums too).
7. **Selection mutation**: `deleteSelection` deletes whatever is in
   `selection` — internal cleanup paths must never write to `selection`
   (that's why `resetBlendState` exists apart from `cancelBlend`).
8. **Isolated-deinit double-free**: with `SWIFT_DEFAULT_ACTOR_ISOLATION =
   MainActor`, an implicitly-`@MainActor` `@Observable` class gets a
   MainActor-*isolated* `deinit` (SE-0371). Deallocating one routes through
   `swift_task_deinitOnExecutorImpl`, which double-frees on the current
   toolchain (Xcode 26.2 / Swift 6.2) — deterministic malloc crash whenever a
   test lets such an instance go out of scope (bit `AppSettings`). Fix: give
   the class an explicit `nonisolated deinit {}` (no teardown work to isolate).
9. **Bottom bars are size-class adaptive**: every contextual bar goes through
   `AdaptiveBar` (`UI/AdaptiveBar.swift`) — one row at regular width; stacked
   scrollable rows (controls / actions / optional footer) at compact width;
   and back to a *single* scrolling row when the height is also compact
   (landscape phone), where three stacked rows cost over half the screen and
   scroll most of the tool palette out of reach.
   Build new bars with it rather than a bare `HStack`: at iPhone width a fixed
   HStack compresses each label to its minimum and wraps it one character per
   line. Keep button titles as words — the UI suite matches several by title
   (`buttons["Extrude"]`, `["Cancel"]`, `["Revolve"]`, `["Done"]`), so
   icon-only compact labels would break those tests.
10. **Hierarchical `.secondary` disappears inside a `ScrollView` over a
   material.** `.foregroundStyle(.secondary)` is a *hierarchical* style, drawn
   with vibrancy against `.regularMaterial`; vibrancy does not composite inside
   a ScrollView, so the text renders fully transparent while still taking its
   layout width (the bars read "Box [4] [4] [4]" with no W/D/H). `Color
   .secondary` is hierarchical too and is NOT an escape hatch. Use the concrete
   `.barLabel` (`Color(uiColor: .secondaryLabel)`) for bar captions and for
   `.tint` on off-state bar buttons. This is invisible to XCUITest — a
   transparent label still `exists` and is `isHittable` — so it needs a visual
   check, not a test.
11. **Advisory copy in a bar goes through `BarHint`**, which renders nothing at
   compact width. A hint is the least important thing in the row and the most
   expensive: "Drag the arrow, or type a distance" pushed Offset Plane's own
   Distance field off the right edge. Controls too wide to share a compact row
   (the Pattern pickers, the image Opacity slider) move to the footer instead —
   pass `showsFooter: isCompact`, because an `if` inside the footer builder
   yields `_ConditionalContent`, not `EmptyView`, and would still claim the
   row's stack spacing at regular width.
12. **Gizmo handles share screen space — every new touch band steals from a
   neighbour.** `GizmoScreenLayout.hitTest` resolves arrows, plane tiles and
   rotation arcs against tolerances that are all far larger than the drawn
   art, so a generous band added for one handle silently eats another's
   near-misses (the rotation arcs' 50pt band reached back over the plane
   tiles, turning a tile near-miss into a 5°-snapped rotation — it read as
   "the square doesn't drag in its plane"). When you add or widen a handle:
   bound the band by that handle's OWN projected size, and copy
   `testAGrabNearThePlaneTilesIsNeverARotation` — a radial sweep asserting no
   grab in one handle's neighbourhood resolves to a different kind.
13. **Bottom-edge insets must be measured, not hardcoded.** The palette and the
   bottom corner chips inset above the bars via `bottomBarInset`, fed by
   `BottomBarHeightKey`. The old fixed 96pt assumed an iPad-height bar and let
   the Copy badge sit on top of a taller compact bar.
14. **Only the LAST `.fileImporter` in a chain is alive.** Stack two on one
   view and the earlier one silently stops presenting — no error, no log, the
   button just does nothing. `EditorView` had four (STL, DXF, STEP, image), so
   STL and DXF import were dead for as long as the image importer sat below
   them, and the menu-listing tests passed the whole time because the entries
   existed. A second importer bound to `.constant(false)` is enough to break
   the first, so this is about the modifier's presence, not its state. There is
   now exactly ONE, switched by `EditorView.ImportRequest`; keep it that way
   (`ImportPickerUITests` fails the moment a second appears).
15. **`.step`, `.stp`, `.dxf` and `.os3d` have no system UTI** — measured, by
   printing the identifiers: `UTType(filenameExtension:)` returns a `dyn.…`
   placeholder for each, while `.stl` gets the real
   `public.standard-tesselated-geometry-format`. A dynamic type is fine for
   STAMPING an export (the saved `.step` file opens and reads back correctly)
   but is not something a file provider can match, so the importers pair it
   with `.data` — which is why `.os3d` already did, and the tell that this bit
   someone before. The cost is that those pickers list every file rather than
   only readable ones. The real fix is a `UTImportedTypeDeclarations` block,
   which needs the app off `GENERATE_INFOPLIST_FILE` first: with that setting
   on, Xcode ignores `INFOPLIST_FILE` outright and the keys never reach the
   built bundle (tried it — the declaration was simply absent).
16. **One simulator, one `xcodebuild` at a time.** Running a second
   `xcodebuild test` (or a plain `build`, which reinstalls the app) against a
   destination that already has a suite running corrupts BOTH. Measured
   2026-08-30, cost one 44-minute UI run: the interference showed up in the
   second run's output as `Error getting main window Unknown kAXError value
   -25218` with element queries returning `(null)`, and in the UI suite as a
   lone `FaceFlowUITests.testSelectFaceAndPull` failure that reads exactly
   like a real regression. Kill and re-run on a quiet simulator; do not try to
   interpret the results. Note the failure did NOT look like a crash, which is
   what makes it expensive — and do not use the `kAXErrorServerNotFound`
   count as the tell, since a healthy run emits those too.

17. **Running the unit suite kills the live agent app.** The test host IS
    `openshape3d.app`: `xcodebuild test` reinstalls and relaunches it, so any
    `/v1/exec` session in flight dies with "remote end closed connection
    without response" — no crash report, no `[agent]` log line, nothing to
    debug. Never run the suite (even `run_in_background`) while driving the
    live app; sequence them, and relaunch with `SIMCTL_CHILD_OS3D_AGENT=1`
    afterwards. Also: `OS3D_AGENT_PORT` alone does nothing — the listener
    is gated on `OS3D_AGENT` being set at all.

18. **`seedPoint` selects ONE profile region.** Two circles in one sketch
    under a single seed extrude (or cut) only the seeded one, silently. Cut
    several holes with one seeded extrude each, or `feature.pattern` on one
    cutter. It cost the door-lock rebuild exactly one hole's 206 mm³ before
    it seeded each. Corollary for rebuild scripts: read result bodies BY ID
    (`producedBodyIDs`, or the boolean's target id) — never `bodies[0]`,
    which reads whatever leftover body sits first in a non-fresh document.

19. **The replay memo is only as correct as `consumedBodyIDs`.** A node is
    spliced from `EvalCache` (skipped, not re-run) whenever its kind, its
    referenced sketches/planes and the stamps of the bodies it CONSUMES are
    unchanged — so an eval that reads a body it does not declare would be
    silently stale when only that body changed. Every kind's inputs are read
    straight off its refs in `FeatureNode.consumedBodyIDs`; when you add a
    kind, or make an existing eval read another body (a second target, a
    reference face on a different body), declare it there. If it genuinely
    cannot be enumerated, leave the node out of the memo (always re-run) —
    correct-by-default. `IncrementalEvalTests` pins the contract on a
    boolean graph; add a case there for any new consumer relationship.

20. **`BRepGProp::VolumeProperties`' default rule is NOT exact on B-spline
    geometry.** Its fixed-order Gauss integration is exact for planar and
    analytic faces but not across a B-spline's knot spans: a spline-walled
    extrude read 0.4% high with one parameterisation of the SAME curve and
    1.3% high with another, and the `Eps` "adaptive" overload read 0.3% low.
    `OS3DVolume` (the source of `MeasureKit.volume(of:)`, the info bar and
    `/v1/state.volumeMM3`) now uses `VolumePropertiesGK(…, Eps 1e-7,
    IsUseSpan: true)` — Gauss–Kronrod per span — and matches closed forms to
    twelve figures. It costs ~2 s across the 1166-test suite. Anything that
    integrates a B-spline face elsewhere has the same exposure:
    `faceInfoOfShape:`'s `SurfaceProperties(face, props)` areas are still
    the default rule (they feed identification heuristics, not checks) — use
    the GK/`IsUseSpan` form before trusting a B-spline face area.

21. **`BRepOffsetAPI_MakePipe` along a polyline does not turn the profile.**
    Found building a Helicoil (2026-09-02): the sweep's B-rep came out at
    0.8% of its expected volume while BRepCheck called it valid and the mesh
    sweep looked right. MakePipe TRANSLATES the profile along each spine
    edge without re-orienting it, so on a curved spine every chord is a
    skewed prism with an oblique section — measured V/(A·L) equals the mean
    of cos(chord angle): 0.69 for a 9-chord quarter arc, 0.5 for one 90°
    corner, ~0 around a full turn. `sweptShape` now uses
    `BRepOffsetAPI_MakePipeShell` with `RightCorner` transitions (mitred
    polyline corners, section kept normal: exactly A·L) — with three
    details that each cost a round: (a) do NOT use its `WithCorrection` /
    `WithContact`: they sweep a transformed COPY of the profile and key the
    history by the copy's edges, so face ancestry vanishes — rotate the
    section normal to the spine yourself and keep the edge map;
    (b) after `MakeSolid` its `FirstShape/LastShape` are the cap FACES, use
    them directly; (c) never find a cap by "the face containing the section
    wire's edges" — a one-edge circular section's only edge is shared with
    the wall beside the cap, and the wall gets found first (every face then
    carries two names and the naming drops them all). `SweepSpineTests`
    pins the volumes; `testASweepSiblingFaceMintsInsteadOfDuplicating` the
    history.

22. **A failed `build-for-testing` leaves the PREVIOUS test bundle in place,
    and `test-without-building` then runs it — green, against stale code.**
    Bitten 2026-09-02: a new test with a type error failed to compile, the
    suite step "passed 1176/1176" (the old bundle, without the new tests),
    and a gate that only looked at the test output let a commit through
    with an uncompilable test. Any gate must check the BUILD step's result
    (grep `error:` / `BUILD FAILED` in its log and stop) before trusting a
    test run, and should assert the expected test COUNT, not just zero
    failures — a count that did not grow is the tell.

23. **`BRepGProp::SurfaceProperties` is wrong on a B-spline wall BOTH ways,
    and neither rule has the volume's `IsUseSpan`.** Measured 2026-09-02 on
    a closed-spline extrude (wall = perimeter × height = 1458.24, caps =
    1641.44, tessellation 1457.1 as the independent third estimate): the
    default rule (Gauss order from degree and knot count) reads the wall
    +1.3 % (1477.2) and the planar caps 0.014 % off along their spline
    boundary; the adaptive `SurfaceProperties(face, props, 1e-7)` reads the
    caps to 1e-7 but the wall −4.6 % (1391.8). Neither splits at knots. So
    `faceInfoOfShape:` now does what `VolumePropertiesGK(…, IsUseSpan)` did
    for volumes, itself: an untrimmed iso-rectangular face (every wall of an
    extrude or revolve, any unpierced B-spline face) is integrated per KNOT
    SPAN with 10-point Gauss–Legendre on |∂S/∂u × ∂S/∂v|
    (`OS3DSpanExactArea`, knots from the surface, its extrusion basis curve,
    or its revolution basis curve); planes take the adaptive rule; only a
    trimmed curved face is left to the default. Face areas are identity
    signatures. `testClosedSplineExtrudesToOneSmoothWall` pins wall and caps
    to 1e-6. A trap inside the trap: a `tail -3` on the test output hid the
    wall's failure line behind the two caps' for one round.

24. **Euclid CSG on a dense outline is not slow, it is UNBOUNDED — and two
    of them were on the main path (2026-09-02).** A 72-point closed spline
    with a Ø10 bore (a cycloidal cam) wedged the app for minutes twice, with
    `/v1/health` alive and `/v1/state` dead: (a) the sketch FILL overlay,
    `SketchTessellator.fillTriangles` → `Euclid.Mesh.fill([paths])`, a BSP
    union of the filled loops (a subpath fill is a symmetric difference,
    same thing) inside `EditorViewModel.scene` on the MainActor; (b) the
    extrude's render mesh, `KernelOps.extrude` subtracting the bore by BSP
    before OCCT was even asked, then thrown away by `adoptBRep`. The spline's
    1,152 samples make the coplanar detessellation quadratic-plus. Fixes: a
    real 2D triangulation for the fill (`PolygonTriangulator`, hole bridging
    + ear clipping, 5 ms) and kernel-first extrudes with the Euclid prism only
    as the fallback (the boolean-into-target tool is built lazily). The
    signal to remember: `sample <pid> 3` on the simulator app shows the hot
    frames — both times it was `Euclid … BSP.clip / coplanarDetessellate`,
    never the kernel. The holed SWEEP's render mesh (`SweepLoftKit.sweep`,
    which `emitFullSolid` keeps on purpose — adopting OCCT's revolve
    tessellation made the naming pass unusable) had the same BSP subtract;
    since `9310d3d` it sweeps outer and holes as walls through the shared
    frames and triangulates the caps with holes — no boolean. The LOFT
    (`Euclid.Mesh.loft` over subpaths = a symmetric difference; even its
    single-loop tube spends 18 s tessellating a thousand-gon cap) followed
    in `81e54ed`: ring-to-ring tubes built here with start alignment, holes
    inverted, `PolygonTriangulator` caps, orientation by signed volume —
    and since then that builder is the ONLY path for sweeps and lofts,
    holes or not. Nothing on the render path calls a Euclid boolean now
    except the extrude fallback, which runs only when OCCT declined.

25. **A Swift `assert` trap writes NO crash report in the simulator, and
    the app's only symptom is a closed connection.** The loft-union death
    (2026-09-02) left no .ips, nothing in the unified log, and `/v1/exec`
    simply hung up. It was Euclid's `assert(isWatertight == nil ||
    isWatertight == polygons.areWatertight)` in `Mesh.Storage.init` — Debug
    only, so a Release build would have shipped the bad claim instead. To
    get a stack out of XCTest: `signal(SIGTRAP) { _ in backtrace… }` with
    `backtrace_symbols_fd` at the top of the reproducing test, then pipe
    the xcodebuild log through `swift demangle`. Attaching lldb to the test
    host does NOT work — xcodebuild SIGTERMs the stalled host. Corollary
    for Euclid: `Mesh.triangulate()` and `detessellate()` carry the source
    mesh's cached watertight claim onto a mesh with DIFFERENT polygons and
    assert it — a CSG result that is watertight as polygons but loses a
    sliver triangle under triangulation trips it. Convert through
    `EuclidBridge.triangles(of:)`, never `mesh.triangulate()`. And the
    third Euclid boolean gotcha 24 did not list: `emitFullSolid`'s
    boolean branch (a revolve/sweep/loft unioned or cut INTO a body) ran
    `KernelOps.boolean` unconditionally and only then assigned OCCT's brep
    over it — that union is where this trap fired. It is OCCT-first now,
    with the Euclid CSG only when an operand is mesh-only.

26. **Never solve a sketch inside a getter SwiftUI evaluates.** The
    definition-state solve (`SketchSolverBridge.definitionReport`, formerly
    `entityStates` + a second `solve` for the chip's DOF) is a Jacobian
    null-space analysis — cubic in the variable count, 1.5 s for 150
    welded lines in Debug — and it sat inside `EditorViewModel.scene`
    (every viewport update while sketching: hover, selection, each drag
    tick) and `sketchDefinitionStatus` (every editor body). Nothing in the
    agent scripts felt it, because `/v1/exec` never enters sketching mode;
    a probe test found it (`vm.scene` timed idle vs sketching). Read
    `sketchDefinitionReport(for:)` — memoised on the sketch VALUE, solved
    on a detached task, latest wins, previous report served meanwhile,
    `sketchDefinitionEpoch` bumps when it lands; tests
    `await vm.settleSketchDefinition()`. The same rule holds for anything
    else superlinear the scene might grow: measure with a 150-entity
    sketch before it ships (`SketchDefinitionCacheTests` keeps the 0.2 s
    bound). Two corollaries from the same evening: (a) "tiny matrices,
    pure Swift" stopped being true — the solver's Cholesky/SVD/eigen are
    LAPACK now (`OS3DLinearAlgebra.c`), 16–50× on a 600-variable system;
    (b) `#include <Accelerate/Accelerate.h>` in a .c file with a local
    `#define ACCELERATE_NEW_LAPACK` does NOT select the new interface —
    clang modules build the framework header once, without your macro
    (the error is `__LAPACK_int` undeclared). Declare the Fortran-ABI
    prototypes yourself (`dposv_` & co., `int` by reference) and let the
    Swift `import Accelerate` link the framework.

27. **A `.switch` Toggle inside a row that selects on a whole-area
    `onTapGesture` never fires — the row wins the touch and SELECTS the
    feature instead.** Found live on the History rows' first option
    switches (2026-09-02): the tap put the body into selection mode with
    the gizmo up. `Button`s in the same row (eye, trash, the field commit
    ticks) and a `.menu` Picker DO win, so options render through a
    Button-backed checkbox `ToggleStyle` (`HistoryCheckboxToggleStyle`),
    with `accessibilityValue` "on"/"off" so the UI test can read the state
    the row re-derives from the document. Same rule for anything else that
    goes into a tappable row: make it a Button, or it is a selection tap.

28. **The memo's `adopt` must only touch the LAST node that put a body id.**
    Found live through the new repair flow (2026-09-02): delete the node
    that made a subtract's tool → the subtract errors, fine — but the plate
    kept the OLD pocket, and re-picking the tool cut the pocketed plate
    again (10,191 → 8,911 instead of 9,551). `EvalCache.adopt` rewrote
    EVERY cached `.put` of a body id with the document's final body, so
    after an in-place op (boolean / blend / shell / push-pull re-put their
    target's id) the PRODUCER node's cached output was the already-cut
    body, and every later splice started from it. `adopt(_:order:)` now
    adopts only where the node is the last putter of that id in replay
    order; earlier putters keep their own snapshots (they are intermediate
    state, never diffed against the document unless a downstream node goes
    away — when their snapshot is exactly what must come back).
    `HistoryBooleanRepairReplayTests` pins subtract → delete the tool's
    node (8,000 again) → re-pick (8,000 − the new overlap only).

29. **A three-section OCCT loft is SMOOTH unless you say `ruled` — and a
    symmetric draft is three sections.** Found by putting the recipe's −5°
    taper back on the wheel's cutters (2026-09-02): the conical holes
    removed 5.5 % more than the dish integral said. A one-way draft was the
    exact frustum, but the symmetric one (offset, base, offset) came out
    6.5 % over: `BRepOffsetAPI_ThruSections(solid, ruled = false)` fits a
    B-spline surface THROUGH the middle section, so the walls bulge. The
    render loft was always piecewise (ring quads), which is why
    `testSymmetricDraftIsTwoFrustumsBackToBack` never noticed — it measured
    the mesh; it measures the B-rep now too. `loftSolid(sections:ruled:)`
    passes `ruled: symmetric` from the draft eval (user lofts stay smooth),
    and the ruled history names EVERY band's walls from its section's
    edges, not just the first's. After the fix: the probe's symmetric
    frustums to 0.0 %, the wheel's two conical hole sets to 0.04 %, the
    cover's drafted boss band to the Steiner integral to 0.00 %.

30. **`SignatureNaming.resolve` rescanned the whole face table per
    candidate.** Found shelling a revolved spline bottle (2026-09-02): the
    open-face lookup sat in `roleFromTable` for minutes — the revolved
    B-spline wall enumerates into tens of thousands of facet faces, and
    the role boost scanned every table entry for every candidate. The
    table's rows align with `enumerate`, so the role is an index lookup
    now; the scan survives only under `propagateBudget`
    (`SignatureNamingScaleTests`, a 20k-facet lathe resolves in < 3 s).
    The symptom to recognise: `/v1/health` alive, `/v1/state` dead, and
    `sample` shows `SignatureNaming.score` — not the kernel.

31. **A revolved cap's face-info normal pointed INTO the body.** The
    plane axis flipped by the orientation flag is wrong for a face whose
    location mirrors (MakeRevol's caps); a `FaceRef` minted from
    `/v1/faces` then carried an inward normal and never resolved ("shell
    open face did not resolve"). `faceInfoOfShape:` uses the oriented
    `BRepGProp_Face` normal — the one the volume integral uses. A box was
    always right, which is why nothing noticed
    (`testFaceInfoOfARevolvedCylinderHasOutwardCaps`).

32. **A sketch spline reached the kernel as a C0 B-spline, and OCCT will
    not offset C0.** The Bézier chain had uniform knots at full
    multiplicity; the geometry is tangent-continuous but the knot
    structure says C0, and `BRepOffset` refused every wall with
    `C0Geometry` — no revolved or extruded spline body could be shelled,
    smooth vase included. `OS3DSplineEdge` now spaces the knots by the
    centripetal parameters the tangents were derived with (parametric
    C1) and lowers each joint's multiplicity; a joint that stays C0 (an
    OPEN spline's straight end spans meet the curve at a corner) becomes
    an EDGE boundary in `SegWire` (a straight piece is a line edge — it
    extrudes to a plane), and `Profile.boundaryIdentity` expands the
    entity list the same way so every piece still names its spline
    (occurrence 0/1/2). The bridge's offset refusal now names OCCT's
    error code, which is how this was found.

33. **Shell thickness is SIGNED now: negative grows the wall outward.**
    The tutorial's own escape for a profile whose grooves are tighter
    than any inward wall. The bridge offsets by the sign, retries the
    Intersection join when the Arc join fails, and validates that the
    material moved the right way; OCCT's outward offset ROUNDS the outer
    edges and corners (arc joins), which the analytic in
    `testNegativeThicknessShellsOutward` accounts for. Exec accepts a
    non-zero thickness; the History field takes a negative value.

34. **A Rect-tool rectangle could not be dimensioned at all.** A rect is
    ONE sketch entity whose only solver points are its two corners, and
    the dimension candidate only knew lines, points and radii — select a
    rect and the palette's Dimension stayed grey. Now `DimensionKind`
    has `.horizontal` / `.vertical` (an `AxisDistanceConstraint` between
    two points along one axis, sign captured as drawn so the box never
    flips through zero), a selected rect offers its width as the palette
    candidate and its height as a second label, and both fields take the
    evaluator's arithmetic ("0.5*0+230" is the quickest way to replace a
    pre-filled value from a hardware keyboard, which cannot select-all).
    `testRectWidthAndHeightDimensionsDriveItsCorners`.

35. **Every in-place feature rebuilt its body with `transform: .identity`,
    so the first fillet after a Transform › Move snapped the body back to
    where it was drawn.** Fillet, chamfer, shell, delete/replace face and
    the face pushes all consumed a LOCAL brep and emitted an identity
    placement; booleans and extrude-into-target bake placements and were
    fine. The ROKAE deck (moved 154 mm up onto the axes, then rounded)
    landed back at sketch height and the lidar-notch cut that followed
    removed nothing. They keep `body.transform` now
    (`testFilletAfterAMoveKeepsThePlacement`). Note a reopened document
    shows the PERSISTED bodies until something re-evaluates the graph.

36. **`/v1/edges` midpoints and `/v1/faces` centroids/normals were LOCAL
    while `/v1/state` bounds are world.** After a move the two disagreed
    by exactly the move, and "the vertical edges between y=40 and 270"
    matched nothing. Both endpoints now apply the body's placement
    (normals through its rotation).

37. **The extrude bar's Distance field WAS a formatted numeric field: it
    took no arithmetic, and a tap on the Extrude button committed whatever
    value the model already held, not the text still in the field**
    ("0*0+630" + Extrude yielded a silent zero-distance no-op with no
    error). Fixed 2026-09-03: the field is text, evaluates through
    `ExpressionEvaluator` like the arrow pill, the dimension field and
    the History rows, mirrors an arrow drag while unfocused, and the
    Extrude button applies the pending text first (or refuses with
    "Couldn't read … as a distance" rather than committing stale state).
    Still true: with Symmetric on, Distance is PER SIDE (630 gave a
    1,260 mm body; the History row's "630/2" fixed it).

38. **Zoom to Fit frames bodies only (`worldBounds` iterates bodies), so a
    950 mm sketch on an empty document stays off-screen; Look at Sketch
    keeps the zoom.** Pinch out to reach a far dimension label, or use
    the palette's Dimension button, whose field opens focused even when
    the label itself is off-screen. Live-driving notes that are not app
    errors: the undo stack holds 50 entries (an agent build of ~60
    commands cannot be fully undone — adopt or delete the remainder),
    OCCT's fuse refuses two configurations a person will hit posing arm
    links — a link end face lying in a plane through its joint housing's
    axis, and a link whose diameter equals the housing's length (tangent
    to both end caps); starting each link 10 mm past the axis and keeping
    housings a few mm larger than their links joins every time — and a
    boolean that OCCT refuses leaves the target's volume EXACTLY as it
    was, so a union check must demand growth, not a ratio.

39. **The profile detector needs loop junctions to coincide to better
    than ~1e-5 mm, and a self-crossing loop is refused outright.** Both
    surfaced building practice-problem frames from computed arcs: an arc
    whose end angle was off by 0.0001° left a 1e-5 mm gap and the extrude
    reported "profile unresolved"; two R6 sketch fillets on a 5.9 mm edge
    (tangent points crossing) did the same. Touch-drawn sketches snap
    exactly, so the UI never sees the first case; agent callers computing
    arcs must derive endpoints from the same numbers the lines use. The
    refusal of an impossible fillet pair is correct behaviour, just
    silent — the message could name the crossing entities.

40. **A touch-committed create tool used to land the Euclid preview mesh
    as the body.** `commitToolResult`/`addStandaloneToolBody` appended
    the feature node but never evaluated it, so the document body was
    mesh-only until a History edit replayed the graph (2026-09-03, found
    by `/v1/check` after a touch cut: `brep: false`, hole a 48-gon).
    Both now `recordAndRebuild`; if you add a create tool, commit
    through the graph and keep the mesh as the fallback, not the result.

41. **Two camera commands in the same instant cancel each other.**
    `animateToStandardView` and `fitScene` share one `CameraAnimator`;
    the second call invalidates the first's display link and computes
    its target from the camera as it is NOW, so `view.top` immediately
    followed by `view.fit` over the bridge leaves the old orientation,
    fitted. Pause ~0.5 s between them (the runner does). A fit that
    chains after a pending standard view is the proper fix.

42. **`scripts/swpp/kit.py`'s `Sketch` sends its entities only when a
    feature consumes it or `commit()` is called.** A sketch built for a
    touch check without either exists in the app as an EMPTY sketch: no
    lines drawn, nothing to tap, and the tap falls through to whatever
    consumed sketch shares the screen point (the base rect at y=0 stole
    two probes before this was noticed).

---

## 4. Next missions (prioritized)

> **Re-audited against the code on 2026-08-28.** The list below used to open
> with "E4 — Shell (recommended next)"; Shell shipped (`FeatureKind.shell`,
> `shellThickness` UI, `KernelShellTests` / `FeatureShellEvalTests` /
> `ShellUITests`), as did most of the B-rep port that F describes as a spike.
> What remains is ranked here.

### 0. FreeCAD-reference hardening — ✅ TRANCHES 1+2 DONE (2026-08-31)

FreeCAD (the largest open-source OCCT consumer) is now a local reference
checkout; `docs/FREECAD_PLAYBOOK.md` is the ledger — pattern, FreeCAD source
ref, licensing classification (reference-not-copy; FreeCAD is LGPL, we are
MIT), the change here, the defect closed, the pinning test. Landed:

- **Typed kernel diagnostics** (`OCCTOpStatus`/`OCCTOpError`): every mutating
  bridge op says WHY it failed; `Result` variants beside the old `?` shims.
- **Fillet/chamfer** (the top user pain): edge pre-qualification (seam/
  degenerate/tangent picks refused with the reason), `NbFaultyContours` +
  per-edge `Generated()` checks — a partial build is DISCARDED (R4-O4), the
  Ø10-rim r=6 crash is a typed error, and the drag is clamped to a
  kernel-derived max radius (bisection over real checked builds) shown in the
  blend bar.
- **Booleans**: analyzer pre-check on operands (+1 heal), non-destructive
  builder, auto-fuzzy from combined extent (one 10× retry), single-solid
  unwrap + `UnifySameDomain` + validation before storing (R4-O3); a
  body-splitting cut is REPORTED (`solidCount`); OCCT-owned failures surface
  as node errors instead of silently degrading to the Euclid mesh.
- **Closed-hollow shell actually works now** (offset+cut — `BySimple` never
  worked and the mesh fallback was covering for it); shell validates and
  must REMOVE material; brep bodies error rather than degrade to the
  clamping mesh inset (R3-E).
- **Tolerances** (S5): `OCCTKernel.matchTolerance` — deflection-derived +
  per-shape `ShapeAnalysis_ShapeTolerance`, replacing all four AABB-scaled
  sites (the thin-plate mistargeting class).
- **Face targeting** (R4-O2): exact `BRepExtrema_DistShapeShape` to the
  trimmed face; the 5×5 UV-bbox grid is gone.
- **Hang containment** (H1): mesher/read deadline via a progress indicator,
  heal-and-validate at the STEP and blob trust boundaries, finite-bounds
  gates at op entries. **Persistence** (R4-O5): brep blobs written without
  triangulation at pinned `TopTools_FormatVersion_VERSION_2`.
- **Sketch integrity** (R2-2/R2-3): solver writeback gated on the structural
  residual (conflicts spring back + red "Constraints conflict" chip; the
  variable-driven solve keeps prior geometry); delete cascades constraints/
  dimensions in the same undo step; trim re-anchors onto surviving fragments
  and visibly drops the rest; `Sketch.validateConstraintRefs()` for tests.
- **Badges on load/undo** (R4-N6/S6): `DocumentSession.refreshEvalErrors()` —
  an errors-only replay after `load()`/`undo()`/`redo()`.
- **Naming prerequisites** (R4-N1/N4): deterministic face basis (outer loop
  by area, canonical start vertex — kills "moves replay rotated after
  relaunch") and `resolve` now hard-vetoes surface-kind mismatches.
- **Oracle tests** (R3-D): `GeometryOracleTests` — exact analytic volumes
  (incl. a Pappus-derived rim fillet) so wrong-but-non-empty can't pass.

### 0c. Debug tooling — ✅ DONE (2026-08-31)

Motivated by the tutorial-model thread (§4b of NEXT.md): every complex
rebuild surfaces a kernel bug, and each bug cost a hand-built repro. Mined
FreeCAD's debugging machinery and landed the three patterns that shorten the
loop (playbook rows D1–D3; **`docs/KERNEL_DEBUG_TOOLING.md`** is the
worked workflow):

- **Geometry health report** (`OCCTKernel.healthReport` / `GET /v1/check`):
  FreeCAD's Check Geometry re-derived — per-subshape `BRepCheck` faults with
  "Face3"-style names (self AND in-context statuses), tolerance min/avg/max,
  free boundary loops, counts, volume, opt-in BOP self-intersection check
  (only on BRepCheck-clean shapes, on a copy, under the kernel deadline).
- **Failing-op capture** (`KernelCapture`): every `*Result` failure dumps its
  input breps + manifest (op, params, typed error, per-input health) as a
  bundle; `POST /v1/capture` snapshots on demand;
  `scripts/fetch_captures.sh` pulls them; newest-20 retention.
- **Capture replay + fixtures** (`KernelCaptureReplay`,
  `KernelCaptureReplayTests`): a bundle replays through the SAME kernel entry
  points (inputs loaded RAW — no heal), and a committed bundle with an
  `expect` block is a permanent regression test. Seed fixture:
  `overradius-fillet-d10-rim`.
- `/v1/state` now carries per-feature `evalErrors`, so driving sessions see
  which feature broke without exec replies.

Three traps encoded on the way: synchronized-group resources FLAT-COPY (two
fixture `manifest.json`s break the build — Fixtures/ is pbxproj-excluded and
read via `#filePath`); replay must use `rawShapeFromSerialized:` because the
normal deserialize path heals what it reads; and `TopExp_Explorer` counts
shared sub-shapes once per parent (a box "has" 24 edges) — counts use
`TopExp::MapShapes`.

**Next mission from this line of work:** kernel-history topological naming —
design agreed and written up in `docs/TOPO_NAMING_HISTORY_DESIGN.md`
(element maps from OCCT's own `Modified()/Generated()` history layered UNDER
`SignatureNaming`, zero persisted-format change, identity-based blend-edge
targeting). Its prerequisites (boolean normalization, S4 determinism) are
now in. Smaller follow-ups: residual attribution → red per-constraint
glyphs, then rank-based add-time conflict diagnosis; trim re-anchor for
arc/circle fragments beyond the point-weld rule.

### 1. Wire the backends that have no UI — ✅ COMPLETE (2026-08-29)

Every item in this mission is done: STEP interchange (§1b), Delete Face (§1c),
Replace Face (§1d) and the Command Search launcher (§1e). Mission 2 followed on
2026-08-30, arcs and ellipses included, so sketch profiles now reach the kernel
exactly.

That makes **mission 3 (blend polish) the top of the list** — but read its own
text before starting. Two of its three items buy nothing for a body with a
`brep`, and §2 is the argument for letting them die with the mesh path rather
than building them.

The pattern is worth keeping in mind for the next one: all four were tested
kernels with no caller, and in all four cases wiring them up surfaced a bug in
the surrounding UI rather than in the kernel — dead `.fileImporter`s, a hole
wall that could not be selected, a fuse that left a seam, an a11y container
that swallowed its children.

- ~~**STEP import/export**~~ — **DONE 2026-08-29**, see below.
- ~~**Delete Face / Replace Face**~~ — **BOTH DONE 2026-08-29**, §1c and §1d.
- ~~**Command Search launcher**~~ — **DONE 2026-08-29**, see §1e.

### 1b. STEP interchange — DONE (2026-08-29)

`STEPKit` (`Kernel/STEPKit.swift`) sits on top of `OCCTKernel.writeSTEP` /
`readSTEP`; `EditorViewModel.exportSTEP()` / `importSTEP(data:fileName:)` wire
it to the Export and Import menus. Unlike every other export we offer, STEP
carries the EXACT B-rep — verified in the Simulator, not inferred: a cylinder
exported to `CYLINDRICAL_SURFACE('',#33,3.)` in millimetres, re-imported as an
analytic body, and exported AGAIN to the same single cylindrical surface. No
hop degrades to triangles.

Three things worth knowing before touching it:

- **Mesh-only bodies are skipped, by name.** A body with no `brep` (an imported
  STL, anything the mesh path built) has no analytic geometry to write, and
  triangulating it into a format whose whole value is that it is not triangles
  would be a lie. `STEPKit.ExportOutcome` reports the skipped names; the UI
  shows a notice for a partial export and an error when nothing is analytic.
- **Body transforms are baked in.** A `brep` lives in body-local space and flat
  STEP has no per-solid placement, so a moved body would otherwise export back
  at the origin — silently wrong, and only visible in another CAD tool
  (`testBodyTransformIsBakedIntoTheExportedSolid`).
- **Wiring it uncovered two UI traps, both pre-existing**, now gotchas 14 and
  15: every Import-menu picker was dead except the last one in the chain (so
  STL and DXF import had quietly never worked — that is the bug to be sorry
  about, not the missing STEP entry), and STEP/DXF have no system UTI.
  `ImportPickerUITests` guards the first, and fails if a second `.fileImporter`
  is ever added back.

`OS3D_DEBUG_SEED_CYLINDER` was also fixed in the same pass: it built a smooth
render mesh via `cylinderRenderMesh` and never called `adoptBRep`, so the
seeded body LOOKED like a real extrude while carrying no `brep` at all. It now
mirrors `evalExtrude` properly. A debug seed that behaves differently from the
app is worse than no seed — this one sent me hunting a STEP bug that did not
exist.

### 1c. Delete Face — DONE (2026-08-29)

`FeatureGraph.evalDeleteFace` (OCCT defeaturing) shipped with the B-rep port
and had no way in. `DeleteFaceKit` + a `.pickingDeleteFaces` mode now give it
one: arm Delete Face in Modify, tap faces, Apply. It is modelled on Shell —
same single-body pick, same live preview swapped in for the source, same
"reuse the preview at commit" rule — and records a `.deleteFace` node for a
feature-owned body so it replays.

- **It had to be a picking MODE, not an action on the current selection.** A
  hole's wall is the face worth deleting, and tapping one today routes to
  `beginCylinderRadial` or falls through to whole-body select, so the face
  never becomes selectable. This is also why the tool handles cylindrical
  faces at all: `DeleteFaceKit.target(in:seedTriangle:)` prefers the cylinder
  over the coplanar sliver `planarFace` returns on a curved surface.
- **The sample point is the whole trick.** OCCT is told WHICH face to remove
  by a point lying on it. The obvious centroid-of-triangles lands on a
  cylinder's AXIS — inside the solid — and removes nothing or the wrong face.
  `DeleteFaceKit` steps out to the surface at mid-height instead, matching
  what `evalDeleteFace` already did for replay.
- **Signatures are minted by `SignatureNaming`, not re-derived.** The live
  pick's `FaceRef` has to match what a rebuild enumerates, so the two private
  `signature(planar:)` / `signature(cylinder:)` builders are now internal and
  shared. Two copies of those formulas would drift, and the symptom would be
  "delete face forgets its face after a rebuild".
- **Refusals are visible.** No brep → a notice saying so (a mesh has no
  surfaces to extend). A pick OCCT cannot close → the bar says "The
  surrounding faces can't heal that" and Apply stays off, because §4.16 is
  explicit that some deletions legitimately leave a sheet body.

Verified on numbers, not screenshots: the `OS3D_DEBUG_SEED_HOLE` body is a
10 × 10 × 6 box with a Ø4 through-hole, 524.60 mm³ (B-rep-exact; the faceted mesh read 524.62 before 2026-09-02). Deleting the hole's wall
takes it to **600.00 mm³ — exactly the full box** — and one undo puts it back.
`DeleteFaceUITests` asserts both numbers; `DeleteFaceKitTests` proves the same
heal at the kernel level (cylindrical faces 1 → 0, planar 6).

### 1d. Replace Face — DONE (2026-08-29)

`ReplaceFaceKit` was fully built and tested with no callers. It now has a
`FeatureKind.replaceFace`, an `evalReplaceFace`, and a `.pickingReplaceFace`
two-stage pick: tap the face to move, tap the face to move it onto, Flip if the
side is ambiguous, Apply.

- **The kit was Euclid-only, and that mattered.** Running an analytic body
  through its mesh booleans hands back a body with no `brep` — the shape still
  renders correctly and only degrades at the next save, which is exactly the
  C4 failure from the 2026-08-25 review. `sweptBRep` / `applyBRep` build the
  prism in OCCT and boolean it there; `sweptZRange` is shared with the Euclid
  path so the two can never disagree about which side the material goes.
- **The fuse leaves a seam, and the test caught it.** An extend meets the body
  ON the replaced face, so `BRepAlgoAPI_Fuse` returns BOTH coplanar faces plus
  the seam edge: a box extended by 6 mm came back with TEN planar faces instead
  of six. Right shape, wrong topology — and those extra edges are selectable
  and blendable by the user. Fixed with a new `OCCTKernel.unified` wrapping
  `ShapeUpgrade_UnifySameDomain`, applied to the replace result. It is a
  separate bridge call on purpose: folding it into `booleanOfShape` would
  change every existing boolean.
- **The target is a PLANE, not a `FaceRef`** — the v1 limitation worth knowing.
  The replace is associative to the face it MOVES (that rebuilds with its body)
  but not to the face it moves TO. `sweep` stores its spine the same way, for
  the same reason: a ref needs an owning body, and the target is routinely on a
  different one.
- **Cross-body targets convert through both transforms.** `convertPlane`
  rotates the normal and translates the origin separately; comparing a plane
  from one body's local space against a face in another's is a mistake that
  only shows up once two bodies are far apart.
- **Refusals reach the bar verbatim.** "The target face isn't parallel to the
  one being replaced" is a real geometric answer — the gap varies across the
  face, so one prism would be wrong everywhere but a line. `FeatureGraph
  .replaceRefusalText` is shared by replay and the live tool so both say it the
  same way.

Verified on numbers: `OS3D_DEBUG_SEED_STEP` is a stepped block (low half to
y = 6, high half to y = 12) at 1800 mm³. Replacing the low step's top onto the
high step's plane gives **2400.00 mm³, bounds 20 × 12 × 10** — one solid box —
and undo restores the step. `ReplaceFaceUITests` asserts that and the
not-parallel refusal; `ReplaceFaceBRepTests` and `ReplaceFaceEvalTests` pin the
analytic face counts, the two paths agreeing with each other, and the FaceRef
still resolving after an upstream edit.

### 1e. Command Search launcher — DONE (2026-08-29)

`CommandRegistry` has carried the fuzzy matcher, the recents list and the
Single Key Action flag since the hotkey pass, with no view that opened any of
it. `CommandSearchView` + `EditorViewModel.commandSearchActive` do now: the
toolbar's magnifier, `X`, or `⌘F` open a panel; type, Enter or tap runs.

- **It only offers commands that can actually run.** The catalog names 61
  commands; `runCommand` routes 39 of them. `CommandRegistry.launchableCommands`
  is the intersection minus the launcher itself, and `CommandSearchTests` pins
  it to `routableIDs` so a catalog entry can never appear in the launcher
  without a route. A result that does nothing when chosen is the same silent
  failure as a dead hotkey and harder to explain, because the user just read
  the name off a list. `unroutedChordedCommands` still tracks the gap.
- **A toolbar button, not only the chords.** X and ⌘F need a hardware
  keyboard; most iPads do not have one, and a launcher nobody can open is not
  a feature.
- **A command that is real but not applicable keeps the panel open** and says
  so in orange ("'Circle' isn't available right now" with no sketch open).
  Closing on a keystroke that did nothing is what makes a launcher feel broken.
- **Single Key Action is now real** (spec §8.4, `AppSettings.singleKeyAction`,
  Settings ▸ Interface). On `.commandSearch`, `CommandShortcutsView` stops
  registering bare-letter hotkeys and registers a–z instead, each opening the
  launcher PRE-TYPED with that letter — registering the whole alphabet rather
  than only the letters that happen to be hotkeys is what makes the setting
  mean what it says. Chorded shortcuts are untouched either way. A focused text
  field still wins, because the first responder is consulted first.
- **Routed two commands while here**: `model.deleteFace` and
  `model.replaceFace`, whose tools shipped earlier the same day. Without that
  the launcher would list two tools visible in the Modify palette that it could
  not start.

Gotcha 2 bit for the THIRD time on the way in: `.accessibilityIdentifier` on
the panel container collapsed it into one element, and the search field came
back as `textFields["CommandSearchPanel"]` while `CommandSearchField` did not
exist at all. `.accessibilityElement(children: .contain)` before the identifier
is the fix, as it was for `SketchPointStateOverlay`.

### 2. B-rep follow-through — DONE (2026-08-30)

The description this section carried was two-thirds stale, which is worth
recording as its own lesson: **polygonal profiles** and **extrude-into-target
boolean** were already analytic — the first since the port (`extrudeShape`
builds a `PolyWire` prism for any outer loop), the second wherever the target
body has a `brep` (`evalExtrude` composes the cut/fuse in OCCT). Reading the
doc would have had you rewrite two working paths. Testing first found the two
that were genuinely mesh-bound.

**Analytic holes.** `extrudeShape` took `isCircle` for the OUTER loop only;
every hole went through `PolyWire`. A 20×20 plate with a Ø8 hole came back
with **0 cylindrical faces and 70 planar** — 64 of them the faceted bore. It
looks round and is not: a fillet around the rim has 64 segments to chase, and
STEP exports 64 planes. The bridge now takes `holeCircles:` (3 doubles per
hole — cx, cy, r; **r ≤ 0 means "this one is a polyline"**, which is how one
array carries both kinds), `OCCTKernel.ExtrudeHole`/`CircleSpec` wrap it, and
`extrudeHoles(_:)` maps a `Profile`'s inner loops. Both `evalExtrude` brep
branches feed it.

**Multi-profile extrudes.** Both call sites guarded on `extras.isEmpty`, so
selecting a SECOND region and pulling silently produced a mesh-only body —
a cliff with no reason behind it, since a union of prisms is just a union of
prisms. `OCCTKernel.extrudeSolid(outer:holes:extras:…)` fuses them and applies
`unified()`, because touching regions leave the same coplanar seam Replace
Face hit (§1d).

Verified in `AnalyticHoleTests` (8), and falsified: with the circle branch
disabled, five of them fail with exactly the numbers above. `testAWasherIs
TwoCylinders` is the sharpest of them — a washer had an analytic outer wall
and a 64-facet bore, so the shape was half-exact and looked entirely round.

**Arcs — DONE 2026-08-30, and cheaper than this section predicted.** The
paragraph that used to sit here said `Profile` would have to carry per-segment
curve data, rippling through `ProfileDetector`, `KernelOps.extrude`,
area/centroid/contains and face signatures. That was the wrong shape of fix.
`loop` is left EXACTLY as it was — still the tessellated truth every mesh-side
consumer reads — and the exact boundary rides alongside it in
`Profile.segments`, which only the B-rep path consults. Nothing downstream of
the sketch changed representation, so no consumer had to be revisited.

Three details worth keeping:

- **An arc is stored as three points, not a centre and an angle pair.** The
  face traversal walks a chain in whichever direction the loop needs, and an
  orientation convention is precisely the thing that silently sign-flips when
  it does. `GC_MakeArcOfCircle(start, mid, end)` takes the points in traversal
  order and reconstructs the circle itself, so there is no winding flag to get
  backwards. The mid point is an interior SAMPLE from `arcPoints`, which is on
  the true arc by construction.
- **Only loops that contain an arc get segments.** A polygon is already exact
  as a polyline — OCCT builds the same wire either way — so filling this in
  for one would be a second description of identical geometry and a second
  thing to keep in step.
- **Every fallback is per-wire, not per-solid.** Bad segments fall back to the
  polyline for that boundary alone (`SegWire` returns a null wire), and a
  circle still wins over both.

`AnalyticArcTests` (11), falsified by forcing the bridge's arc branch off:
9 fail, a slot reporting 0 cylindrical faces and 6 planar instead of 2 and 4.
That run also caught a test of my own that was weaker than it looked —
`testReversedSketchOrderGivesTheSameSolid` compared the two solids only to
each OTHER, so it passed while both were faceted; it now pins both counts to 2.

**Consequence worth knowing before opening an old document**: a slot wall that
used to be ~20 planar facets is now one cylindrical face, so a `FaceRef` minted
against one of those facets resolves against a cylinder on the next rebuild.
This is the same swap the hole fix made (64 facets → 1 cylinder) and
`SignatureNaming` handles cylinders as first-class, but it IS a geometry change
to bodies that already exist.

**Ellipses — DONE 2026-08-30, and they closed the list.** `detectProfiles`
flattened `.ellipse` to 48 straight segments and emitted `.polygonal`, which
threw the semi-axes away at the very first step; the profile then reached OCCT
as a 48-sided prism, about 0.27% under the true area — small enough to look
right and wrong everywhere it matters.

An ellipse cannot use the arc side-channel, because three points determine a
circle and not an ellipse. So `CircleSpec` became **`ConicSpec`** — centre,
two semi-axes, rotation — and a circle is now the case where the semi-axes are
equal. One concept rather than two: to every caller these are the same thing,
"this whole loop is a curve OCCT can build exactly, so ignore the polyline".
`extrudeShape` lost `isCircle` / `circleCenter` / `circleRadius` in the swap
and takes one optional `outerConic` instead, which is why most call sites got
three arguments shorter.

Two traps, both encoded in tests:

- **`gp_Elips` demands its MAJOR radius first** and refuses major < minor,
  while a sketch's semi-axes are in no particular order — a tall ellipse is as
  ordinary as a wide one. The bridge picks the larger and turns the reference
  direction a quarter turn when that is the y semi-axis
  (`testATallEllipseIsBuiltAsReadilyAsAWideOne`).
- **Equal semi-axes must build a `gp_Circ`**, not a degenerate `gp_Elips` —
  and that is also what keeps a round hole reporting as a cylindrical face
  rather than a surface of extrusion.

Note for anyone reading face counts: an extruded ellipse is a surface of
LINEAR EXTRUSION, so `faceTypeCounts` reports it under `other`, not
`cylindrical`. Only a true cylinder is cylindrical.

`AnalyticEllipseTests` (10), falsified by emitting `.polygonal` again: 8 fail,
the faceted solid measuring 375.92 mm³ against the exact 376.99. That number
is also where the tolerance comes from — the render mesh is a tessellation of
the exact solid and sits ~0.04% under it, while a 48-gon sits ~0.27% under, so
the assertions use a tolerance BETWEEN the two. A tighter one would only be
measuring the tessellator. The same run caught
`testRotationIsCarriedThrough` passing while faceted (a rotated 48-gon has
nearly the same bounding box); it now pins the exact wall too.

**Profile geometry is now exact end to end**: circles, rects, polygons,
line/arc chains and ellipses all reach OCCT as the curves they were drawn as.
Splines never become profiles at all, so there is nothing left to convert
here — the next inexactness lives elsewhere.

### 3. Blend polish (E5) — COMPLETE 2026-08-30 (item 1 was already built)

**The ranking argument this section used to make was wrong, and it is worth
knowing why.** It said these items "only buy anything for brep-less bodies",
implying the mesh path was about to die. But `evalRevolve`, `evalSweep`,
`evalLoft`, `evalPattern` and `evalMirror` do not produce a `brep` at all —
checked one at a time, not inferred. A revolved body is one of the commonest
things a user makes, and every blend on one runs on the mesh path. The mesh
blend is load-bearing and will stay so until those five ops get OCCT paths of
their own (which is the better long-term fix, and a mission in its own right).

- ~~**Tangent-chain propagation**~~ — **ALREADY BUILT**, and was when this list
  was written. `EditorViewModel.handleBlendEdgeTap` expands a tap through
  `EdgeTopology.smoothChain` to the whole tangent-continuous chain and toggles
  it as a unit; `KernelOps.blendEdges` then sweeps a multi-segment chain as ONE
  mitred tool rather than piling up per-segment wedges. `KernelBlendTests`
  covers both halves. Nothing to do here.
- ~~**Concave edges**~~ — **DONE 2026-08-30**, see below.
- ~~**History edge re-pick**~~ — **DONE 2026-08-30**, see below.

Mission 3 is complete.

#### History edge re-pick — DONE (2026-08-30)

"Edit Edges" on a chamfer/fillet row re-enters `.pickingBlendEdges` with the
feature's existing edges already selected, and applying EDITS the node
(`session.editFeature`) instead of replacing the body and appending a second
blend on top of the first.

The one real difficulty is that a blend replaces its body IN PLACE. By the time
the user asks to edit the feature, the body under that `BodyID` already carries
the blend, so re-picking against it would offer the rounded rim rather than the
sharp edges the feature names, and the preview would blend an already-blended
body. `DocumentSession.inputBody(for:bodyID:)` recovers the input by replaying
a copy of the graph with `rollbackIndex` set to the node's own index. It feeds
that replay a LOCAL revision counter: the result is a transient preview source
and must not consume revisions the real document will hand out later.

Three traps, none of them visible to a geometry assertion:

- **`resetBlendState` must clear the edit state.** `commitBlend` branches on
  `blendEditingFeature`, so a CANCELLED edit that left it set would make the
  next fresh blend silently overwrite the edges of the last feature opened from
  the panel.
- **The tap handler must pick against the recovered body**, not the document's.
- **Deselecting every edge must preview the UN-blended body.** Falling through
  to a nil preview shows the document's copy, which still has the old blend on
  it, so clearing the selection would look like it did nothing.

Testing, and its limits, measured rather than assumed:

- `BlendEditEvalTests` (6) covers the MECHANISM as pure values — truncation
  recovers the sharp box, stored EdgeRefs resolve against it, two disjoint
  edges remove exactly twice one (proving each replay starts from the sharp
  box rather than compounding). It does NOT cover the wiring.
- `BlendEditUITests` (1) covers the wiring, and the assertion that matters is
  the ROW COUNT: two 1 mm fillets of one edge look much like one, so
  "edit versus append" is invisible to geometry and shows up only as a second
  History row. Falsified — forcing the append path fails it.
- **A gap worth knowing**: `BodyRef.producer` is never read anywhere (eval
  resolves bodies by `bodyID` alone), so nothing tests it and nothing can. It
  is provenance metadata only. Do not assume a wrong `producer` will surface.

Caution for whoever writes the next History UI test: `HistoryButton` TOGGLES.
Tapping it when the panel is already open closes it, and the row query then
returns zero — which reads exactly like the feature having been destroyed.

#### Concave edges — DONE (2026-08-30)

A concave blend FILLS the internal corner instead of cutting it away, so the
tool is unioned rather than subtracted. Concave edges were classified from the
start (`SelectableEdge.isConvex`) and then discarded twice — once in the tap
handler, once in replay — so an inside corner was not merely unsupported, it
was UNPICKABLE: the tap fell through to the nearest convex edge elsewhere on
the body, which reads as a mis-hit rather than a missing feature.

Three things to know:

- **One sign carries the whole difference.** The tangent test that orients the
  wedge (`dot(tA, nB) > 0`) is calibrated for convex edges and inverts for
  concave ones. Measured failure mode, by running the new tests against the old
  rule: the wedge lands entirely INSIDE the solid, so the union is a silent
  no-op — the blend does nothing and the volume does not move. It does not
  produce wrong geometry, it produces no geometry.
- **A unioned tool must not overshoot the edge ends.** A subtracted one
  deliberately does (the cut runs clean past the edge); the same overshoot on a
  union stands proud of the end faces as two small tabs.
- **Convex and concave edges are chained separately** in `blendEdges`. They are
  never continuations of one another even when they meet end to end, and a
  mixed chain would be swept as one solid and then applied one way for both.

`ConcaveBlendTests` (8) on an L-beam with exactly one inside corner. Note one
honest limit recorded in the file: `testFillingDoesNotGrowTheBoundingBox` does
NOT catch the sign error — under falsification the union is a no-op, so the box
is unchanged and that test passes. `testConcaveFilletFillsTheCorner` is what
fails. The box test guards the opposite mistake, a tool escaping the notch.

### 3b. Revolve / sweep / loft as B-rep — DONE (2026-08-30)

These three were the last ops producing MESH-ONLY bodies, and the cost did not
announce itself: a revolved body could not be exported to STEP at all, every
blend on one ran the mesh path (~170× slower than OCCT, and the site of the
over-radius crash), and a boolean against one went faceted. Pattern and mirror
were fixed first (they are placements, so a pattern copy just shares the
source's handle); these three needed real construction.

All three build on the SAME profile face an extrude does — `OS3DProfileFace`,
factored out of `extrudedShapeWithOuterLoop:` — so a circle revolved is a real
torus rather than 48 flat strips. Sharing that face is the point: a circle that
stayed round when extruded and went faceted when revolved would be exactly the
inconsistency this work exists to remove.

Three things to know before touching it:

- **The graph stores revolve angles in DEGREES, OCCT wants RADIANS.**
  `KernelOps.revolve` ends in `intersectWithWedge(solid, degrees:)`. Passing 360
  straight through does NOT fail loudly — a 360-radian revolve still closes into
  a full solid — so the mistake looks correct. The parameter is named
  `angleRadians` for that reason.
- **`RevolveAxis` is 2D in the SKETCH PLANE**, not a world axis; lift it through
  the plane basis before handing it to OCCT.
- **A loft section with HOLES has no ThruSections equivalent** (one wire per
  section), so those keep the mesh result rather than silently losing the inner
  loop. Pinned by a test.

**The brep is ASSIGNED, not adopted, and that is deliberate.** Adopting would
replace the render with OCCT's tessellation, which for a revolved circle is
49,928 triangles against the Euclid mesh's 4,608 — measured. See the naming
finding below for why that matters. Assigning still gets everything this work is
for: STEP export, analytic fillets, OCCT booleans. Same split the box primitive
already used.

`RevolveSweepLoftBrepTests` (6), falsified by returning nil from all three
builders: 5 fail, the survivor being the negative test that a holed loft STAYS
mesh-only.

#### Face enumeration was O(n²) — FIXED (2026-08-30)

`faceTable` took **~65 SECONDS** on a 4,608-triangle torus, so revolving a
circle was a minute-long hang on a completely ordinary operation. Found while
giving revolve a B-rep, but entirely pre-existing: the mesh path had always done
this. Now **96 ms**, a 680× improvement, with the face GROUPING unchanged.

Two compounding causes, and the first fix alone was not enough:

- `planarFace`, `smoothRegion` and `cylindricalFace` each rebuilt the whole
  edge→triangle map, while `enumerateFaces` calls them once per unclaimed
  triangle. Sharing one map: 65 s → **41 s**.
- `cylindricalFace` floods the entire SMOOTH COMPONENT before deciding whether a
  cylinder fits. A torus is one smooth component of 4,608 triangles that no
  cylinder fits, so the old code flooded all of them once per seed — 2,304 times
  over. The verdict cannot differ between seeds inside one component, so one
  refusal now settles it for the whole component: 41 s → **96 ms**.

**Why the grouping assertion in the test matters more than the timing one.**
Face enumeration feeds topological naming. Had this refactor changed WHICH
triangles group into a face, every stored `FaceRef` in every saved document
would resolve differently — a silent, unbounded regression that no timing test
would catch. `FaceEnumerationScalingTests` pins the torus entry count (2304),
the box (6 planar), and the cylinder (2 planar + 1 cylindrical) for that reason.

The per-seed entry points still build their own map when none is shared, so the
~30 external callers are unaffected.

#### Booleans ran BOTH kernels and threw one away — FIXED (2026-08-30)

Chased down from "three `DeleteFaceEvalTests` cases sit at ~14 s each". It was
never delete-face: the tell was `testEmptyFaceListIsRejected`, which asserts an
error and does no geometry, taking 6.8 s. The cost was in the shared FIXTURE.

`evalBoolean` ran the Euclid mesh CSG first and the OCCT boolean second — and
`adoptBRep` replaces render, edges AND euclid from OCCT's tessellation, so the
mesh result was computed in full and discarded whenever both operands were
analytic. Measured on a 10 mm box minus a Ø4 cylinder:

| stage | time |
|---|---|
| whole graph evaluate | 7028 ms |
| OCCT boolean | **1 ms** |
| tessellate | 10 ms |
| faceTable | 7 ms |
| **Euclid CSG subtract** | **4877 ms** |

Trying OCCT first and falling back only when it declines: **7028 ms → 74 ms**.
The body is byte-identical (648 triangles, 6 planar + 1 cylindrical).

This was never a test-only problem — every boolean on analytic bodies in the
app paid it, and booleans are core modelling. Knock-on effect on the suite:

**Full unit suite 100.6 s → 18.3 s.** The slowest `DeleteFaceEvalTests` case
went 14.19 s → 0.46 s. That is also the likeliest explanation for the
intermittent runner deaths recorded under gotcha 16 — those tests sat close
enough to the per-test timeout to trip it on a loaded machine.

`BooleanKernelChoiceTests` pins the geometry (exact volume and face counts),
the timing ceiling, and that a genuinely mesh-only operand still booleans
through Euclid.

### 4. F — OpenCASCADE B-rep port (mostly landed; this is its design record)
Behind the existing `KernelOps` facade (see `IMPLEMENTATION_PLAN.md` Phase E
section for scope): OCCT compiled for iOS, solids become B-rep, Euclid stays
the render/preview path. Unlocks true fillets (tangent chains, rolling-ball
corners, G2), robust booleans, shell/offset-face quality. Start with a spike:
build OCCT.xcframework, round-trip one box through
`BRepPrimAPI_MakeBox` → mesh → `RenderMesh`.
**Concrete ordered scope + spike/kill-criteria: `docs/OCCT_BREP_PORT_DESIGN.md`.**
This is what fixes extruded circles rendering as 48-gon prisms (no mesh-side fix
exists — the representation itself must become analytic).
**M0 spike + M1 wiring DONE (2026-07-22):** OCCT 7.8.1 cross-built for iOS
(`scripts/build_occt_ios.sh` → `ThirdParty/OCCT.xcframework`, modeling-only
~74 MB/arch — **committed to the repo via Git LFS**, see §2b; the "gitignored"
claim that used to sit here was stale, a fresh checkout builds without running
the script). OCCT is now **linked into the app** and callable
from Swift via `OCCTKernel` (Obj-C++ `OCCTBridge` behind a dedicated bridging
header — NOT `ShaderTypes.h`, which Metal shares). `openshape3dTests/
OCCTKernelTests` proves it in-suite (extruded circle = 1 analytic cylinder);
**full suite 499 green**. STEP/IGES deferred (build-flag flip; ~doubles the lib).
**A circle extrude now renders as a TRUE smooth cylinder** (OCCT analytic
tessellation + surface normals), visually confirmed on-device — behind
`OCCTKernel.renderCircleExtrudesWithOCCT`, Euclid still owns CSG. Seed a demo
with `SIMCTL_CHILD_OS3D_FRESH=1 SIMCTL_CHILD_OS3D_DEBUG_SEED_CYLINDER=1`.
**OCCT is now the source of truth for circle extrude + boolean:** `Body.brep`
(`BRepHandle`) carries the analytic solid; `evalBoolean` composes breps
(`BRepAlgoAPI_Fuse/Cut/Common`) and renders smooth — so a cylinder MINUS a
cylinder stays round (verified on-device: `SIMCTL_CHILD_OS3D_DEBUG_SEED_BOOLEAN=1`).
Euclid still computes CSG → suite 500 green. Repro: `scripts/run_occt_spike.sh`.

**Since then (verified in the code 2026-08-28), the rest of that "next" list
landed except the first three items:** B-rep persistence ships
(`DocumentSession` ↔ `OCCTKernel.serialize/deserialize`), and fillet, chamfer,
shell and delete-face all run on the brep in both `FeatureGraph` and
`EditorViewModel`. Still Euclid-first: general (polygonal/arc) profiles as
B-rep source, analytic holes, extrude-into-target boolean — see mission 2.
STEP is no longer a build-flag question either: the bridge is compiled in and
just needs UI (mission 1).

### 4c. SOLIDWORKS practice-problem campaign — IN PROGRESS (2026-09-03)

The 365-sheet practice database at solidworks.com/solution/education/
practice-problems, every sheet printing the finished part's volume, used as
an outside-in parity harness: read the drawing, build it, score the body's
volume against the printed number to 0.5 %.

**Where it stands.** 68 sheets attempted, 60 pass, 8 fail (every fail a
drawing that admits two readings whose printed volume picks the one not
drawn — none a kernel fault). A further 78 sheets were read and set aside
with a written reason each, in `scripts/swpp/deferred.json`.

| Level | Title | Sheets | Attempted | Pass |
|---|---|---|---|---|
| 1 | Basic Sketch & Extrusion | 20 | 14 | 12 |
| 2 | Sketch Tools & End Conditions | 20 | 9 | 8 |
| 3 | Global Variables & Sketch Patterns | 8 | 6 | 6 |
| 4 | Extrude Cut & Fillet/Chamfer | 70 | 10 | 7 |
| 5 | Reference Geometry | 15 | 6 | 6 |
| 6 | Revolve Boss/Cut | 20 | 7 | 5 |
| 7 | Feature Patterning | 48 | 6 | 6 |
| 8 | Sweep Boss/Cut | 14 | 3 | 3 |
| 11 | Hole Wizard | 12 | 3 | 3 |
| 16 | Global Variables, Equations, Link Values | 7 | 4 | 4 |

**How to run it.** `scripts/swpp/` is self-contained. `kit.py` drives the
live app over the agent bridge with palette-equivalent operations in a fresh
document per problem; `levelN.py` hold the recipes read off the sheets;
`run.py 6.1 level:5 all` runs them; `results.jsonl` is the ledger (latest row
per problem wins); `report.py` regenerates the table in
`docs/SWPP_PRACTICE_PROBLEMS.md`. A sheet printing several volumes (Level 16
equations/configurations) registers `meta["configs"] = [(label, volume), …]`
and its build returns one body-id list per configuration; all of them score
in one ledger row.

**The sheet PDFs are NOT in the repo.** They were fetched to a scratchpad
from the database's `/api/headless/problems` index (some entries are zips;
the server throttles after roughly 150 downloads). Re-fetch them before the
next pass — a recipe can be re-run without its sheet, but a NEW sheet cannot
be read without one.

**What to do next, in order.**

1. **Level 4 is the biggest untouched pool** — 70 sheets, 10 attempted. It
   needs no capability the app lacks (extrude, cut, fillet, chamfer), so it
   is the cheapest way to raise coverage.
2. **Level 7** (48 sheets, 6 attempted) likewise: patterns of bodies plus a
   subtract stand in for feature patterns.
3. **Capability gaps still open**, ranked by how many sheets they block:
   feature patterns (a patterned cut is three steps here, not one); no hole
   wizard (counterbores are stacked cylinders with typed standard sizes);
   angled reference planes exist over the bridge but the palette has no tool
   for them, so a Level 5 sheet cannot be built by touch; sketch patterns and
   named global variables (the recipe lays a pattern out as one polygon
   instead); loft normal-to-profile; assemblies/configurations/interference
   (Levels 9, 15, 17) are outside a single-part modeller.
4. **Draft returns a mesh-only body** (see the draft entry in the mission
   log). A `BRepOffsetAPI_DraftAngle` path would let a drafted casting be
   filleted analytically and exported; Level 13 wants it.
5. Some sheets need a **provided START part** (14.4, 14.8, 16.7) that the
   sheet set does not include. They stay deferred unless those parts surface.

**Reading, not the app, is what stops the count.** The deferred list is the
honest record of that: drawings whose callouts do not fix the geometry, or
whose printed volume no reading reproduces. Before writing a recipe, check a
hand-computed volume against the sheet — a plausible-looking solid that is
2 % out is almost always a misread drawing, and chasing it in the kernel
wastes the pass.

Report page (regenerate with the scratchpad's `make_swpp_report.py`):
https://claude.ai/code/artifact/3633bcd3-4ab6-498f-b940-35894880b105

### 5. Deferred backlog (from Phase D)
- Transform-as-a-feature — **design blocker documented** in
  `PHASE_D_DESIGN.md` / memory: eval emits world-space+identity meshes while
  live tools store localized-mesh+pivot; needs an eval-representation rework
  (dedicated tranche).
- Sketch patterns, EdgeRef-based dimensioning, MaterialTagNaming (needs OS3D
  v2 blob format), linked copies, PrimitiveSpec-dim variables, full unit
  conversion.

---

## 4b. Retrospectives — passes already done (not missions)

These record what a review covered and what it deliberately left. Anything
still open from them is promoted into §4 above; read these for the reasoning,
not for a task list.

### Agent exec endpoint + the reference app recipe extraction (2026-08-31)

`POST /v1/exec` (`openshape3d/Agent/AgentExec.swift`), the parameterized half
`/v1/command` could not provide: one request carries an operation AND its
numbers. Ops: `sketch.create`, `sketch.addEntities`, and
`feature.extrude/revolve/pattern/mirror/boolean`. Protocol reference is
`docs/AGENT_CONTROL.md`.

It goes to `DocumentCommand` + `FeatureKind`, NOT the interactive tool state
machine, so an exec'd model replays through the same graph as a hand-built one.
Profiles resolve by SEED POINT via `ProfileDetector` — callers never enumerate
loop entity ids. Parsing is pure and unit-tested (23 tests); only the main-actor
hop is in `AgentBridge`, per gotcha 1.

**Three traps this pass hit, all worth remembering:**

1. **`FeatureKind.revolve`'s `Expr` is in DEGREES.** `FeatureGraph` converts to
   radians once at the OCCT boundary (`angle.value * .pi / 180`). Converting on
   the way in as well gave a 6.28-DEGREE revolve that rendered as a completely
   plausible solid. Caught only because a Pappus hand-check disagreed by 60x.
   Cross-check a new solid's VOLUME against an independent estimate; "it looks
   right" does not discriminate here.
2. **A boolean adds no body** — it replaces its target in place. Judging success
   by "did a new body id appear" reports a working subtract as a no-op.
3. **`rebuildFrom` bumps `meshRevision` on nodes it did not semantically
   touch**, so revision-diffing cannot tell you a feature failed either. The
   reliable signal is `lastEvalErrors[node.id]`.

**the reference app's native archive is readable** — see the file-format memory. ZIP →
SQLite. Bodies are Parasolid XT (OCCT cannot read it, and no open converter
exists), but `SketchCurves.Data` is plain JSON and `HistoryTreeNodes` type 2 is
the feature graph, with type-3 literals decoding as `<uint32 tag><payload>`
where tag 3 + 8 bytes is a double in METRES. An extractor lives in the session
scratchpad (the extractor script), not in the repo.

Of the 8 tutorial models, only 4 carry sketches + history (Frame, Block casting,
Motorcycle cover, 4 motorcycle wheel); Rod clamp / Piston / Piston rod are
frozen imported solids with no history at all, and Motorcycle ships as a
Parasolid TEXT `.x_t`. Block casting is unreachable regardless — 7 of its 27
steps are `MaterializeImportedBodies`.

**Rebuilt from its extracted recipe:** the 4-motorcycle-wheel revolve (34,775,356
mm3, vs a 36.4M straight-line Pappus estimate — correctly lower because the
profile's large arc bulges inward), then a 63.5 mm cutter, circular-patterned 5x
about the axle and subtracted. Still NOT done on that model: the recipe's Mirror
and second Boolean, and the smaller 12.7 mm bolt-hole circle.

**What exec still cannot do:** fillet, chamfer, shell and the face ops all take
`EdgeRef`/`FaceRef` — topological signatures, not numbers — so they need a way
to NAME an edge or face over the wire. That is a design question, not a
mechanical addition. `Align` has no `FeatureKind` at all.

### the reference app UI parity review (2026-07-23)

A pass over the sketch and solid-modeling UI against the reference app, driving the app
on the iPad sim and comparing on screen:

- **Live sketch dimensions** while drawing (`LiveDimensionKit` +
  `SketchLiveDimensionOverlay`): width/height on a rectangle, Ø on a circle
  (ticked where it meets the curve), length/R for line/arc.
- **Draw from the current camera** — entering a sketch no longer snaps
  head-on; it only re-aims from a grazing (>80°) view. Look at Sketch is
  recomputed on entry so it appears from an angled view.
- **Orientation-cube face names** (Top/Front/Right…), fading as faces turn away.
- **Overlay alignment fix** — every projected overlay was ~85pt low (Metal
  viewport full-bleed vs safe-area-inset SwiftUI overlay); all now
  `.ignoresSafeArea()` and re-publish the camera on layout/resize.
- **Named snap chip** (`SnapChipOverlay`) + typed snapping
  (`SnapEngine.SnapKind`): Endpoint/Midpoint/Center, ranked; rectangles gained
  edge-midpoint and centre snaps.
- **Selection accent orange → the reference app blue** (with the user's sign-off), kept
  distinct from the under-defined blue.

Remaining parity gaps noted but NOT yet done: the sketch grid is drawn
on the world ground plane only (the reference app re-orients it to the active sketch
plane); mid-draw numeric entry into the live dimension; rectangle dimensions
pinning to the drag-facing sides.

### Spec §1–§12 gap sweep (2026-07-22) — suite 658 green

Every ❌ in `PARITY_SPEC.md` through §12 was re-audited and closed
except §7.5 (SpaceMouse/Wacom — needs a vendor SDK and physical hardware, so
it cannot be built or tested here). Each landed as a tested backend with the
UI wiring called out as missing in its spec entry:

| § | What shipped | Where |
|---|---|---|
| 1.2 | Automatic line/arc from a pen stroke; wiggle toggles it | `StrokeClassifier` |
| 2.4 | Re-host a sketch on another plane | `ChangeSketchPlaneCommand` |
| 2.5 | Live sketch pattern link (edit seed → instances follow) | `SketchPatternLink` |
| 4.12 | Replace Face: extend/trim onto a parallel plane | `ReplaceFaceKit` |
| 4.13 | Offset Edge (3D), Single + Chain | `EdgeOffsetKit` |
| 4.15 | Wrap & Emboss onto a cylinder, no stretch | `WrapKit` |
| 4.16 | Delete Face + surface healing (OCCT defeaturing) | `FeatureGraph.evalDeleteFace` |
| 6.5 | Insert Project WITH editable history | `ProjectMergeKit` |
| 8.4 | Hotkeys + fuzzy Command Search | `CommandRegistry` |
| 12.1 | OBJ import (round-trips `OBJExporter`) | `OBJImporter` |

Stale statuses corrected in the same pass: §4.14 (ships as §1.13's 3D entry
point), §6.4 (import exists), §17 (Settings ships).

**Next (promoted to §4 mission 1 — still true a month later, and STEP joined
the list):** these are backends without UI. The highest-value follow-on is
wiring them into the palette/gizmo layer — Delete Face and Replace Face are single
gestures on an existing face selection, and Command Search needs only a
UIKit key-command bridge plus a launcher sheet.

---

## 5. Conventions for the next session

- One tranche = backend (pure, unit-tested) → UI → UI test → full-suite gate →
  commit. Keep commits per tranche with detailed messages (see `git log`).
- New geometry ops: `nonisolated` statics on `KernelOps`, end in
  `.makeWatertight()`, unit-test exact volumes on a cube first.
- New feature kinds: add the case + eval + arms in `HistoryPanelView.iconName`,
  `distanceValue`, `EditorViewModel.kindLabel`, `kind(_:replacingExpr:)` —
  the compiler's exhaustive-switch errors will walk you through them.
- Update this file at the end of each mission — and when you touch §1 or §4,
  re-audit them against the CODE, not against what this file last said. Both
  drifted for a month here: §1 called the B-rep port "not started" while OCCT
  was running fillet/chamfer/shell/delete-face, and §4's top mission (Shell)
  had already shipped with three test files. A grep for the type or the test
  file is a ten-second check that keeps the next session from building
  something twice.
