# NEXT — Shapr3D sketch parity (updated 2026-09-06)

Living authority is `docs/STATUS_AND_NEXT_STEPS.md`; the parity evidence and
method are in `docs/SHAPR3D_SKETCH_PARITY.md`. This is the queue.

## Pick up next, in order

1. **Selecting a sketch outside sketch mode should reveal its dimensions.**
   The one KNOWN GAP opened by defaulting "Always Show Dimensions" off (which
   matches Shapr3D). `annotatedSketches` already includes a sketch that has a
   selected entity, so the missing link is that a tap outside sketch mode never
   reaches `selectedSketchEntityIDs`. Then drop the `XCTExpectFailure` in
   `DimensionUITests.testDimensionFollowsTheSelectionAfterExitingTheSketch`.

2. **`SweepLoftUITests` — both tests fail.** Not the annotation overlays
   (restricting them to sketch mode changes nothing) and not the value card.
   `testSweepCircleAlongTwoSegmentLinePath` was already in the original 16, so
   suspect the other in-flight workstreams. Attribute it the same way the
   second-shape hang was attributed — recipe in STATUS.

3. **Re-run the full UI suite for a current number.** The last full run was
   110 tests / 14 failures and PREDATES today's fixes; three of those are now
   known closed. Roughly 57 minutes, `-parallel-testing-enabled NO`.

4. **Remaining Shapr3D sketch gaps**, measured against the running app and
   written up with screenshots in `docs/SHAPR3D_SKETCH_PARITY.md`:
   - **G2** ten dimension tools + the adaptive menu (a circle can only be
     dimensioned Ø today; no way to ask for R).
   - **G3** draggable dimension badge ("Drag the Dimension badge to reposition").
   - **G7** `Disconnect`, and the `Anchored Sketch Entity` (First/Last Selected)
     setting.
   - **G8** spline and sketch-pattern UI — both kernel-complete already, only
     `SketchTool` has no `.spline` case and `patternLinks` is untouched by
     `EditorViewModel`.

5. **Variables menu is only on the sketch dimension field.** Shapr3D puts it in
   every value field; the bar/panel fields use the pad via popover and have none.

6. **Three other uncommitted workstreams rode along in this commit** and are
   unreviewed: blend face-edge selection (bug e07493b5), the shell-crash fix
   (6cb10527), and the subtract feedback (a1ee4e4a). They are interleaved with
   the pad work inside `EditorViewModel` — see STATUS for the hunk split that
   separates them.

## Methods worth reusing (all cost real time to learn)

- **Attributing a regression** when a partial stash will not build: park the
  untracked files that reference uncommitted APIs, keep only the probe test,
  then `git stash push -- openshape3d/ openshape3dTests/ openshape3dUITests/`.
  Leave `project.pbxproj` alone — the target uses filesystem-synchronized
  groups, so parked files just drop out of the build.
- **`git checkout HEAD -- <file>` on uncommitted work is destructive.** Back up
  to a scratch dir first, or use `git stash push -- <paths>`, which is
  recoverable. Dropped stashes survive: `git fsck --unreachable`, then
  `git checkout <sha> -- <paths>`.
- **Profiling a simulator hang:** `sample` cannot resolve simulator processes by
  NAME. Poll
  `pgrep -f "CoreSimulator/Devices/<UDID>.*openshape3d.app/openshape3d"`, then
  `sample <pid> 10 1 -mayDie -file …`. Read its recursion summary first.
- **Testing anything defaults-backed** needs
  `xcrun simctl uninstall <UDID> com.laan.labs.openshape3d` first —
  `OS3D_RESET_STORE` clears the SwiftData store, NOT `UserDefaults`.
- **Driving Shapr3D** (Accessibility is granted): `System Events click at` does
  NOT move the cursor and clicks wherever the pointer already is. Use a CGEvent
  clicker that refuses unless the target app is frontmost and the point is
  inside its window.
- **A UI test that draws** must square the camera first and assert
  "Look at Sketch" is gone; obliquely, a screen-space angle is not the angle on
  the sketch plane. And `startSketchTool` on an already-armed tool TOGGLES IT
  OFF, so the drag orbits instead of drawing.

---

# NEXT — handoff for the new machine (written 2026-08-31)

Snapshot of where things stand after the FreeCAD-hardening merge
([PR #22](https://github.com/laanlabs/openshape3d/pull/22), merge `a3e415f`)
and exactly what to pick up next. The living authority is still
`docs/STATUS_AND_NEXT_STEPS.md` (§4 mission 0 records what just landed);
this file is the short version plus the machine-move checklist.

## 1. New-machine setup checklist — DONE on this machine (2026-08-31)

All four steps below were completed: LFS libs verified real, unit suite green
(**1034 tests, ~18 s** — 21 above the handoff count, from the debug-tooling
tranche the same day, see §2b), FreeCAD re-cloned to
`~/projects/reference/FreeCAD`, and the UDID problem solved for good —
`scripts/run_sim.sh` and the drive skill now resolve the simulator BY NAME.
Two machine quirks worth knowing, both now handled in the scripts:
`xcode-select` points at CommandLineTools here, so every `xcodebuild`/`xcrun`
needs `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (the real fix
is `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`); and
port 8787 is occupied by an unrelated local service, so launch the agent
bridge with `SIMCTL_CHILD_OS3D_AGENT_PORT=8899`.

1. `git lfs install` **before** cloning — `ThirdParty/OCCT.xcframework`'s
   static libs come through LFS (headers are plain files). No OCCT rebuild
   is needed; the README's "not checked in" note predates the LFS setup.
2. Xcode 26+, then run the unit suite to prove the toolchain:
   ```
   xcodebuild test -project openshape3d.xcodeproj -scheme openshape3d \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
     -parallel-testing-enabled NO -only-testing:openshape3dTests
   ```
   Expected: **990+ tests, 0 failures, ~18 s.** (`-parallel-testing-enabled NO`
   always; one simulator, one xcodebuild at a time.)
3. Re-clone the FreeCAD reference (it lives OUTSIDE the repo and does not
   travel with it):
   ```
   git clone --depth 1 --branch 1.0.2 https://github.com/FreeCAD/FreeCAD.git ~/projects/reference/FreeCAD
   git -C ~/projects/reference/FreeCAD fetch --depth 1 origin main:refs/remotes/origin/main
   ```
   Licensing rules for using it are at the top of `docs/FREECAD_PLAYBOOK.md`
   (LGPL → MIT: patterns only, never code).
4. Simulator UDIDs are machine-specific — the UDID baked into
   `.claude/skills/drive-openshape3d` and old notes (`69DB84F4-…`) will be
   wrong here. `xcrun simctl list devices | grep "iPad Pro 13"` for the new
   one; destination-by-name in xcodebuild commands works unchanged.

## 2. In flight — do first

- Both big branches are merged (PR #22 hardening, PR #23 agent-exec) and
  the combined `main` was verified on 2026-08-31: **1013 unit tests,
  0 failures, ~18.6 s**, with `docs/STATUS_AND_NEXT_STEPS.md` carrying
  both new sections. Nothing to re-check there.
- ~~The full **UI suite has not run** since the hardening landed~~ — **RAN
  2026-09-01** covering the debug tranche + topo-naming 1–5a + exec identity
  ops: 104 executed, one long-run flake (clean in isolation), 2
  idle-timeouts, 46m19s. Measurement + reading in STATUS §"test baseline".

## 2b. Debug-tooling tranche — LANDED 2026-08-31 (this machine's first work)

The tutorial-model thread (§4b) kept surfacing kernel bugs that each cost a
hand-built repro, so the FreeCAD mining focus shifted to its DEBUGGING
machinery first. Landed: geometry health report (`GET /v1/check`, FreeCAD's
Check Geometry re-derived), automatic failing-op capture bundles +
`POST /v1/capture` + `scripts/fetch_captures.sh`, replay harness with
committed regression fixtures, and per-feature `evalErrors` in `/v1/state`.
Playbook rows D1–D3; workflow doc **`docs/KERNEL_DEBUG_TOOLING.md`**; STATUS
§4 mission 0c is the record. When the tutorial-model thread resumes, run
`/v1/check?bop=1` the moment a rebuild looks wrong, and promote any capture
bundle a failure leaves behind.

## 3. The next mission: kernel-history topological naming

The biggest remaining user pain ("editing an earlier feature breaks later
ones"). The design is agreed and written: **`docs/TOPO_NAMING_HISTORY_DESIGN.md`**
— element maps built from OCCT's own `Modified()/Generated()/IsDeleted()`
history, layered UNDER `SignatureNaming` (never replacing it), zero
persisted-format change, and identity-based blend-edge targeting as the
payoff. Its prerequisites already landed in PR #22 (boolean result
normalization; deterministic face basis R4-N1; kind veto R4-N4).
Sequencing S/M/L per step is in the doc. **THE MISSION'S CORE IS COMPLETE —
steps 1–5 all landed** (5b on 2026-09-01, d8a39aa: legacy refs earn names
during rebuilds, inside the rebuild's own undo step). **Revolve/sweep
naming landed 2026-09-01 (279a311)** — kernel-side `faceInfo` had already
dissolved the assign-vs-adopt blocker, and the slice's find was an OCCT
full-revolve history gap (`Generated()` hides half a washer's walls;
recovered via the ungated `Revol().Shape(edge)` — see the design doc).
**Replace-face composition landed 2026-09-01** — it is a boolean with a
prism, so it reuses `booleanResultWithAncestry`
(`ReplaceFaceKit.applyBRepWithAncestry`) and composes names exactly like a
boolean; the untouched faces keep their identities (pinned: extend a
slab's top cap, the bottom cap and all four walls stay named).
**Loft naming landed 2026-09-01** — `ThruSections.GeneratedFace` +
FirstShape/LastShape caps, walls named from the first section's profile
(a wall spans all sections, so later-section identities are correctly
deferred). **Every creation and modifier op now composes element names.**
**EdgeRef opportunistic upgrades landed 2026-09-01** — a legacy blend
`EdgeRef` earns its crease name pair on rebuild (from the kernel edge at
its own resolved midpoint, so it only pins what already resolved), riding
the same 5b machinery as FaceRefs. **The topological-naming mission is now
COMPLETE** — nothing deferred remains. The UI suite ran clean over the
whole mission (one long-run flake, passed in isolation).

**Steps 1–5a landed 2026-08-31**
(eleven commits, e1506cd…5730e5e — 5a made blends/shell/deleteFace REPORT
history instead of erasing names: cut → blend → cut keeps identities intact
and a fillet face is named for its crease). What's left of the mission:
**5b opportunistic ref upgrade** (legacy refs gain names during rebuilds —
touches undo/persistence, design it against DocumentSession's command flow
before coding), revolve/sweep/loft naming, and replace-face composition.
**Fillet/chamfer/shell over /v1/exec LANDED** with `GET /v1/edges|/v1/faces`
discovery — the Motorcycle-cover tutorial rebuild (§4b) is now unblocked;
deleteFace/replaceFace over exec are a mechanical follow-on.
Earlier progress detail below is HISTORY:

**Steps 1–4 landed 2026-08-31**
(nine commits, e1506cd…edd0300): face channel, boolean + extrude ancestry,
ElementName + creation-op naming, boolean name composition
(inherit/split-mint/section), name-first FaceRef resolution with the
ambiguity margin, and identity-addressed blends (EdgeRef.faceNames +
blend-by-edge-index — the "rebuild broke my fillet" fix, pinned by a test
where a drifted signature rebinds to the wrong hole without the name and
the right one with it). Old documents load unchanged; legacy refs resolve
exactly as before. Remaining: step 5 (opportunistic ref upgrade so old refs
gain names during rebuilds; modifier-op history so blends/shells stop
erasing downstream names) and revolve/sweep/loft naming (blocked on their
assign-vs-adopt render split). Also still open: wiring fillet/shell over
/v1/exec, which the edge-name vocabulary now makes expressible (§4b).

## 4. Smaller follow-ups, in rough priority order

1. **Sketch conflict diagnosis, stage 2 — LANDED 2026-09-01.** Residual
   attribution: `buildSystem` records residual-row → constraint/dimension
   UUID provenance, `SketchSolverBridge.conflictAttribution(_:)` reports
   every source whose row the solver could not drive to zero, and the
   glyph/dimension overlays paint those red (a11y ids
   `ConstraintGlyphConflict`/`DimensionLabelConflict`). Computed once per
   conflict episode (on the drag path's false→true transition — the
   structural system is drag-invariant), cleared with the chip. Honesty
   caveat, documented on the API: attribution reflects where the LM
   compromise parks the error — every member of a clashing cluster lights
   up (dueling lengths both go red), which is right; but a cluster whose
   compromise happens to satisfy one member (H+V+length: the solver keeps
   the direction and shrinks) flags only the rows still carrying error.
   **Stage 3 LANDED 2026-09-01 too**: add-time diagnosis names the
   partners of a refused add ("Vertical conflicts with Horizontal,
   Distance 100.00 mm — not added"). Implemented as a leave-one-out probe
   (`SketchSolverBridge.conflictPartners`) rather than porting planegcs's
   QR `diagnose()`: one small solve per source, run once at refusal time,
   and the answer is directly actionable — removal of any named partner
   makes the sketch solvable. Multi-clash edge (no single removal
   resolves) and >64-source sketches fall back to stage-2 attribution
   minus the candidate. Both refusal sites (constraint add, dimension
   add/edit) use it. The residual normalization (item 2) made the
   underlying tolerance scale-honest first.
2. **Residual normalization — LANDED 2026-09-01** (playbook S7): the four
   mm² residuals (parallel/perpendicular via raw cross/dot, colinear/
   symmetric via unnormalized directions) now read sin/cos of the angle
   and mm distances respectively; angle stays radians (bounded, 1e-3 rad
   ≈ 0.057° is a sane conflict threshold). No solver-behavior fallout —
   full suite green unchanged.
3. **Trim re-anchor for curved fragments — LANDED 2026-09-01**: a `.whole`
   ref now also transfers across MULTIPLE fragments when every fragment is
   an arc of the same supporting circle (tangency/radius statements stay
   unambiguous — center+radius identical); mixed fragments still drop.
   `sketchPoint` learned rect corners, so a corner-anchored constraint
   survives a rect-explode trim. Pinned in `ConstraintLifecycleTests`.
4. **UI-suite geometry assertions + fuzz harness — LANDED 2026-09-01.**
   `MeasureUITests.testSeededBoxReportsExactGeometryValues` drives the app
   and asserts the 4×4×4 seed's EXACT readout strings (64.00 mm³,
   4.00 × 4.00 × 4.00 mm, 16.00 mm² face, 16.00 mm perimeter) — a kernel or
   tessellation regression now fails a UI test, not just a unit one (R3-D).
   `docs/occt-fuzz-harness.swift.txt` is promoted to
   `openshape3dTests/OCCTFuzzTests.swift` (compiled always so API drift
   breaks the build — it already caught a fillet/extrude signature drift;
   the sweep itself runs only under `TEST_RUNNER_OS3D_FUZZ=1`). Running it
   found and CLOSED four real crash/hang families on attacker-controlled
   deserialize input — inflated section/record counts (hang), out-of-range
   & negative sub-shape refs (segfault), non-finite/hex coordinates, and
   non-text bytes — via one structural pre-gate
   (`OCCTBridge.OS3DPlausibleSectionCounts`, pinned in
   `OCCTSerializationPinTests`). The remaining single-byte-desync class
   (truncated prefixes, `flip-*=9`, one 200k-vertex resource case) is an
   inherited OCCT-reader gap with no clean pre-gate; the harness skips it
   as a LOGGED known-open set and stands as a regression guard for
   everything else. Playbook H2.
5. **Pre-existing review backlog** (unchanged by PR #22, listed in
   `docs/ARCHITECTURE_REVIEW_2026-08-25.md` / STATUS §4.5): off-main
   eval/preview service (S1), scene caching + GPU buffer pooling (S2),
   `ToolLifecycle` registry refactor (S3); Phase-D deferred items
   (transform-as-a-feature, sketch patterns, EdgeRef dimensioning…).
6. **Modeling parity** — `docs/MODELING_PARITY_GOALS.md` §5 sequencing:
   G7 tutorial walls → G8 editable history operands → G9 tool variants,
   with G5 sketch completeness (splines!) in parallel. Note that doc's
   §2/G1/G2 are stale (chamfer/shell are OCCT now, not mesh).

## 4a2. FreeCAD Basic modeling tutorial — REBUILT (2026-09-01)

The FreeCAD beginner tutorial (wiki.freecad.org/Basic_modeling_tutorial)
models an iron angle (an L-section table foot, 750 mm) two ways, and both
must give the identical solid — the built-in cross-check. Both rebuild 1:1
through `/v1/exec` (`scripts/rebuild_freecad_angle.py`): Method 1 (CSG:
box 50×50×750 minus box 40×40×750 at the shared corner) and Method 2
(extrude the L-profile the relative-coordinate Draft wire traces) each land
EXACTLY on 675,000 mm³, agree with each other to 0.000%, and pass
`/v1/check` with zero invalid subshapes. openshape3d has no box primitive
or `rect` entity over exec, so each rectangle is four lines and the profile
is closed line loops (what the ProfileDetector consumes) — no expressivity
gap. Robust to busy/overlapping documents (retested with 6 clutter bodies
and a pre-existing body overlapping the origin corner; still exact).

One caveat WATCHED, not reproduced: the first run (against a stale
many-faced Frame document still loaded from an earlier session) once
returned a 64 mm³ brep=False cut — the OCCT boolean had declined and the
Euclid mesh CSG collapsed on the coincident corner faces. It did NOT
reproduce on a fresh doc, with clutter, or with overlapping origin
geometry, so it was a one-off OCCT hiccup that dropped an operand to
mesh-only. The lesson stands: Euclid CSG on coincident faces is fragile,
and it is only reachable when OCCT declines for a brep body — which the B1
hardening now surfaces as an error rather than silently falling through.

**Also checked: FreeCAD Basic Part Design Tutorial** (a multi-feature part:
pad-symmetric → pocket-through → mirror → pad-reversed → mirror → pocket on
a sloped face → refine). Every operation it uses maps 1:1 onto an
openshape3d exec op, and each produces valid geometry. Verified live: the
base trapezoid solid (bottom 26, right 26, top 5, sloped left → 403 mm²,
padded symmetric to 53 mm) lands EXACTLY on 21,359 mm³; an inline
extrude-subtract pocket removes material cleanly; a mirror across a plane
is valid; `/v1/check` stays at 0 invalid. Full 1:1 of the finished part is
blocked ONLY by the drawing image (external-geometry-relative placements +
final dims live in a raster the text doesn't spell out), NOT by any
openshape3d capability gap. Two exec notes confirmed while doing it:
`feature.extrude` `symmetric:true` extrudes ±distance (total = 2×distance,
so 53 mm total needs distance 26.5); the inline boolean is
`"boolean":"subtract"` + `"booleanTargets":[id]` (a STRING op + id array,
not a nested object — a wrong shape silently defaults to newBody).

**FreeCAD op-coverage matrix (all verified live, health 0 invalid):**
extrude/pad (iron angle 675,000 mm³ & part-design base 21,359 mm³, both
EXACT), boolean cut/pocket (iron angle CSG exact; part-design pocket
removes material), mirror (valid), and revolve — the Basic modeling
tutorial's named alternative to extrude — Pappus-verified (a
rectangular-section ring 150 mm² × 2π × R25 = 23,562 mm³ analytic vs
23,495 measured, 0.285% mesh-tessellation drift on the curved surface;
the 90° sector shows the identical 0.285%, so it is uniform tessellation
under-report, not a geometry error). Conclusion: openshape3d covers every
core FreeCAD modeling operation, with no expressivity gap found.

## 4a3. Real catalogue parts (TraceParts) — REBUILT (2026-09-01)

`scripts/rebuild_traceparts.py` rebuilds three real manufactured parts
through `/v1/exec`, each held to an INDEPENDENT ground truth, and covering
the core op matrix. All three: valid analytic B-rep, 0 invalid subshapes,
correct face topology, <1% volume drift.

- **RÄDER-VOGEL 106/100/036/125/046/5/20** — a grey cast-iron single-flanged
  wheel, a genuine TraceParts product (Casters/wheels › Wheels). One REVOLVE
  of its radial section from the datasheet dimensions (tread Ø100, flange
  Ø125, hub 54, bearing bore Ø42). The killer check: the datasheet's stated
  weight of 2.5 kg — the model masses **2.519 kg (0.7% off)** at cast-iron
  density, the residual being the bearing-bore step and lightening the
  datasheet doesn't dimension. Visually confirmed in the simulator (a clean
  stepped wheel).
- **DIN 934 M16 hex nut** (a TraceParts fastener class) — HEXAGON extrude
  (6-line loop, no polygon entity needed) minus a bore. Exact geometry
  (across-flats 24.00, across-corners 27.71, hex area 498.8), 0.01% volume
  drift; mass 33.6 g vs ~31 g standard (the DIN chamfer + thread a plain
  model omits).
- **EN 1092-1 DN50 PN16 flange** — extrude + central bore + CIRCULAR PATTERN
  of a bolt hole ×4 + boolean. The pattern is the point: exactly 4 holes cut
  (volume matches the 4-hole analytic to 0.03%; a wrong count would be
  1.5%/hole off). Bolt holes visible in the simulator render.

Between them: revolve, polygon extrude, circle extrude, boolean cut,
circular pattern — all producing valid manufactured-part geometry. No
expressivity gap; the exec surface builds real CAD parts to spec.

**Fillet/chamfer stress test on the wheel (2026-09-01)** — the operations
most likely to break on curved revolved geometry held up. Filleting and
chamfering all 8 concentric circular edges of the wheel at once: valid
B-rep, 0 invalid subshapes. Over-size requests (a 5 mm fillet or 20 mm
chamfer on the 10 mm flange, where two blends meet) fail GRACEFULLY with a
typed, actionable error ("N of N edges can't take this size — try a smaller
value or fewer edges"), no crash or hang, app healthy after. This is the
payoff of the session's deadline + typed-failure hardening: the "we get
stuck on complex geometry" scenario now degrades cleanly instead of
wedging. (One process note: the iOS simulator idle-shuts-down between
bursts of exec traffic — an empty /v1/health after a pause means relaunch
the app, not an app crash; the real crash reports this session are the
OS3D_FUZZ sweep's deliberate hostile-input kills.)

## 4b. The reference tutorial-model thread (paused, 2026-08-31)

Goal as posed: import the tutorial models and rebuild them through the app's
own UI, as a real workout for the modeling stack. Where it got to:

- **The reference app's native archive is decoded.** ZIP -> SQLite. Bodies are Parasolid XT and stay
  unreadable (OCCT cannot read Parasolid, no open converter exists), but
  sketches are plain JSON and `HistoryTreeNodes` type 2 is the feature graph.
  `scripts/model_extract.py` dumps a model to a recipe; its docstring holds the
  format notes and the Google Drive ids for all eight models (PR #25).
- **`scripts/rebuild_wheel.py`** rebuilds "4 motorcycle wheel" through
  `/v1/exec` and is a manual regression for that endpoint — it documents the
  expected volumes and why each is right.
- **Triage: only 4 of the 8 models are reachable at all.** Frame, Block casting,
  Motorcycle cover, 4 motorcycle wheel carry sketches + history. Rod clamp /
  Piston / Piston rod are frozen imported solids (one body, zero sketches);
  Motorcycle ships as a Parasolid TEXT `.x_t`. Block casting is unreachable
  anyway — 7 of its 27 steps are `MaterializeImportedBodies`.
- **The Motorcycle cover is REBUILT (2026-09-01)** — `scripts/rebuild_cover.py`
  drives the full main sequence over exec (blank 0.01% off analytic, boss ring
  with its HOLE, fillet 1.8 propagating the whole rim tangent chain, shell 1.3
  bottom-open, tangent nub union), exactly as §3's mission predicted: the
  identity vocabulary made Fillet/Shell expressible. Excluded and why: the two
  10° taper angles (no draft-extrude), the spline engraving (splines never
  become profiles), Import 01 (Parasolid). The rebuild found and fixed THREE
  real bugs in one pass: exec dropped profile HOLES (rings extruded as full
  discs), constructive kernel builders had no deadline (a hang evades capture
  AND wedges the MainActor), and `propagate`'s O(faces×inputs) role pass spun
  for minutes on a tangent-fuse's sliver tessellation (found by SAMPLING the
  wedged pid — see KERNEL_DEBUG_TOOLING). **The wheel reached full-recipe
  1:1 the same day** (bolt holes + Mirror + closing union; the fused wheel
  is exactly 2× its half, asserted in `rebuild_wheel.py`) — only the
  cutter's −5° taper is unexpressed. **The Frame's tube skeleton stands
  too** (`rebuild_frame.py`, first pass all green: derived-plane sketches
  via the extractor's resolved bases, both sweeps over the new
  `feature.sweep`, mirrored stay pair). **The Frame's plate act stands as
  well (2026-09-01)** — Extrusion 03/04 + Mirror 02/03 + Boolean 01, all
  green first run: the unresolved Plane 06 was pinned geometrically
  (mirroring the plate region across y=82.55 lands flush with the slab
  edge), and Boolean 01's op code 2 decoded as SUBTRACT by volume assert
  (slab − 4 window plugs, 0.003% drift — union of coincident slabs would
  have erased the windows). Head tube (Extrusion 05) green too. The probe
  also live-checks naming coverage and surfaced the next gap — mirror
  bodies carried no element names, propagating bare faces through
  booleans — **closed the same day**: `evalMirror`/`evalPattern` copies now
  inherit their source's name map (see the naming design doc; centroid-
  reflection test pins the by-index alignment). After the fix the Frame
  document reads 100% coverage: every face of every body carries a name. Frame
  remaining: Shell 01 + Boolean 02 (Parasolid face refs undecodable and
  geometry does not pin which six faces open — needs the tutorial's visual
  intent); OffsetFace/Align/Import excluded with reasons. Block casting
  stays unreachable (`MaterializeImportedBodies`).

## 5. What PR #22 changed (so new work builds on it, not around it)

- Kernel ops return typed failures: prefer `OCCTKernel.filletResult/
  chamferResult/shellResult/booleanResult/removingFacesResult` in new code;
  the optional variants are compatibility shims.
- Pick tolerances: always `OCCTKernel.matchTolerance(for:)` — never a
  fraction of the body's AABB.
- Boolean results are already unwrapped/unified/validated; a
  body-splitting cut reports `solidCount > 1`.
- Sketch writeback is gated: check `SketchSolverBridge.solveOutcome`'s
  `structuralResidual` before writing solved geometry anywhere new.
- Every mined-from-FreeCAD pattern must get a row in
  `docs/FREECAD_PLAYBOOK.md` (pattern | ref | classification | change |
  defect | test) — keep the ledger honest.

Delete this file once §2 and §3 are underway; STATUS stays the authority.
