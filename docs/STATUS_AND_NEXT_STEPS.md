# Status & Next Steps — Handoff Notes

> **Current unfinished-work register:** [Sketch parity open status](SKETCH_PARITY_OPEN_STATUS.md). Maintained at every meaningful checkpoint; older mission logs below are historical.

Last updated: 2026-09-17 — welcome screen, bundled sample designs (Demos folder) and App Store preview videos at 886 × 1920 / 1200 × 1600; camera / material / phone safe-area / constraint-sheet fixes (#37–#40); full UI suite on main has no known failures; all twelve App Store screenshots reshot for the new framing; medium-detent sheet tap probe (no other sheet drops taps); Settings reachable on iPhone; switch-tap probe on iPhone (no taps lost, not even in the control); SOLIDWORKS practice problems rerun on main (170 / 202, unchanged); Shell tool opens holed faces, 13.9 over-hollow finding stale; lateral-edge fillet finding stale; practice-problem round 6 (181 / 215 pass, four bugs confirmed); Settings reachable at any width (the iPad mini in portrait lost it too); edge convexity and collinear edge merging fixed (round 6 bug 3); crossing outlines split into real regions (round 6's bug 1); curved-edge midpoints in /v1/edges stable (practice problems 181 / 215, unchanged); render mesh no longer fails validity (round 6's bug 2), heal-loosened booleans refused; a bridge feature is one undo step (round 6's bug 4); 7.29 at 0.00 % (R1 on every edge but the hole rims); practice problems 182 / 215 on merged main (18.3's tube fillet built 0.001 mm off tangent); shell refusals traced (18.3 fixed by the tube offset, 13.9A an OCCT offset limit); a shell over a fillet no longer refused as C0Geometry (18.23's refusals traced); fillets OCCT built no longer refused per edge (practice problems 183 / 215: 13.3 passes, 18.5A / 18.5B with their full R5 sets, 18.5B at −0.001 %); the fillet drag's size probe looks past a failed tiny size; 18.9A's refused sphere/diamond blend traced to a drawn tangency (recipe unchanged); practice problems rerun on main after the shell and fillet fixes (183 / 215, identical); the boolean's face merge no longer corrupts its operands (18.19 cut in drawing order); see the newest mission log, the register above, and
[full 42-issue implementation ledger](SKETCH_PARITY_IMPLEMENTATION.md).
This is the living handoff document: what is DONE, how the newest subsystems
work, the dev workflow, and the prioritized next missions.
Companions: `IMPLEMENTATION_PLAN.md` (original phase plan),
`PARITY_SPEC.md` (feature spec), `PHASE_D_DESIGN.md` (feature-graph
design), `FREECAD_PLAYBOOK.md` (the FreeCAD-derived hardening ledger),
`TOPO_NAMING_HISTORY_DESIGN.md` (element-naming design, now complete), and
`AGENT_CONTROL.md` (the `/v1/exec` scripting surface).

## Mission log — 2026-09-17, the boolean's face merge corrupted its operands

- **What 18.19's "coincident-cylinder pcurve" really was.** Replayed from
  its fixture, the window cut after the Ø13 boss builds VALID. The bad
  pcurve comes from the step after it: `ShapeUpgrade_UnifySameDomain`
  merging same-domain faces. It merged no face, left the boss face
  unorientable (`invalidCurveOnClosedSurface`), and rewrote the edges of
  the shape it was given in place (safe-input mode does not stop that).
  Merging edges only is harmless. The earlier diagnosis blamed the cut
  because the raw result had been checked after the merge had already
  changed it.
- **It corrupted stored bodies.** A boolean result shares its untouched
  sub-shapes with the operands. With the window cut first (the recipe's
  workaround) and the Ø6 bore through the boss next, the merge rewrote
  edges shared with the TARGET body: the stored part turned invalid, the
  heal passed the cut with a 12.9 mm tolerance (the loosened-heal guard
  compares with the part's own loosened tolerance, so it let it through),
  and every later cut removed nothing, reported ok. Any boolean where the
  merge touched shared edges could have changed its operand this way.
- **Fix (`booleanOfShape:`).** The merge runs on a topology copy of the
  result (keeping its render mesh, so untouched faces need no new
  tessellation), so neither the result nor the operands can change under
  it. When the merged copy is invalid and the unmerged result is valid,
  the boolean returns the unmerged result. Ancestry maps through the copy,
  so an untouched face is still reported as `same`.
- **Checked.** Fixtures `coincident-boss-arc-window-cut` (now expect
  success, 3 545.524 mm³) and `boss-bore-face-merge` (the bore cut,
  3 291.055). `BooleanFaceMergeTests`:
  - the window cut is valid, exact and tight (tolerance under 1e-3);
  - a later cut removes exactly what it overlaps;
  - the bore cut leaves its target body valid, and repeats identically;
  - the unmerged boss faces keep R6.5 ancestors;
  - with the fallback off, the loosened heal is still refused.
  All but the last fail on main's bridge. The full unit suite passes
  (1681 tests, 0 failures, including `ShapeAncestryTests` and
  `ElementNamingTests`).
- **Practice problems.** 18.19 is now built in drawing order (window cut
  after the boss) and gives 3 109.645 mm³, the same as the workaround.
  Every cut removes material and the tolerance stays at 1.33e-5. All 215
  recipes rerun on the fix: every recorded field identical to the ledger
  (183 pass). Only 18.19's row is committed.

## Mission log — 2026-09-17, practice problems on main after the shell and fillet fixes

- **All 215 recipes rerun on `main` after #60, #62, #63 and #65** (the
  C0 split for shells, the per-edge fillet credit, the fillet size probe,
  and 18.9A's docs; #61's welcome screen and sample designs are in the
  build too). Those PRs had each rerun only the recipes they obviously
  touch; this is the whole set on the combined build.
- **Identical to the ledger.** 183 pass and 32 fail, the same problems.
  For all 215, every recorded field matches: volume (exact, not just to
  the thousandth), status, health flag, per-configuration results, eval
  errors and recorded feature count. Rows come from one app instance on
  os3d-runner-A (documents Untitled 130 to 344, consecutive). The whole
  run took 18.9 minutes of build time.
- The ledger rows are committed; the report is unchanged.

## Mission log — 2026-09-17, 18.9A's sphere/diamond blend: a drawn tangency, no stable offset

- **Why it is refused.** The diamond boss's Ø24 lobes sit on a Ø46 circle,
  so they reach 23 + 12 = 35: exactly the R35 cup sphere, which they touch
  at the rim. The arm's outline also ends on the Ø70 circle. Drawn like
  that, the union carries a 0.00214 mm tolerance and the sphere/diamond R3
  comes back invalid (applied first) or fails every contour (applied last).
- **Offsets.** Moving the lobe centres in 0.001 mm lets that blend build
  (+48.722 mm³; the note estimated +50), but the recipe reuses the lobe
  centre for the arm outline and the channel, so the arm-wall group then
  fails. Shrinking the lobe radius breaks the channel corner the recipe
  computes from r 12. Growing the sphere is the clean change. The whole
  set, sphere/diamond included, builds at +0.002, +0.01 and +0.05 mm.
  At +0.001, +0.005 and +0.02 mm the arm-wall group comes back invalid.
  Replayed offline at +0.001 mm, that fillet builds with no faulty contour
  but leaves a 0.19 mm² sliver face on the sphere with a self-intersecting
  wire, which `ShapeFix` does not repair. So it is a real invalid result,
  not a false refusal.
- **Decision: the recipe keeps the drawn tangency.** An offset picked
  because it happens to build, with its neighbours failing, is fitting to
  kernel noise. The blend would also move the part away from the printed
  volume (+0.23 % to about +0.27 %; still a pass). The note says all this.
  18.3's and 18.5A/B's 0.001 mm offsets were not probed at other sizes the
  same way; their blends converged as the gap closed.
- No code change.

## Mission log — 2026-09-17, the fillet drag's size probe looks past a failed tiny size

- **What was wrong.** `maxFilletRadiusForShape:` (the ceiling a fillet
  drag is clamped to, computed once as the drag starts) tries the
  bracket, then one tiny size (min(1 % of the bracket, 0.05 mm)), and
  returned 0 when both failed. Whether a size builds is not monotonic: on
  18.5A's port/body chain R0.05 fails validity, R0.1 to R5 build and R8
  and R10 fail. With 0 the editor leaves the drag unclamped
  (`blendDragMax` nil), so it could run past every size that builds and
  lean on the preview's typed errors.
- **Fix.** When the tiny size fails too, halve down from the bracket and
  take the first size that builds as the lower end, the size above it as
  the upper end, then bisect as before. All of those extra builds share
  one kernel deadline (5 s), because the probe runs on the main thread;
  `OS3DFilletBuilds` takes the remaining time as its deadline. The chain
  now reports 7.773 mm in 0.36 s (0 on main), and R7.773 builds.
- **Checked.** `FilletChainCreditTests.testTheRadiusProbeLooksPastAFailedTinySize`
  (still fails at R0.05, the probe reports at least 5, and the reported
  size builds) fails on main's bridge; `BlendStressTests`' probe tests
  still pass.

## Mission log — 2026-09-16, fillets OCCT built were refused per edge; 13.3 passes, 18.5A/B get their full R5 sets

- **The bridge refused fillets OCCT had built.** After a fillet builds,
  `OS3DFinishBlend` requires each requested edge to report generated faces
  (`Generated()`), in case an edge was quietly dropped. ChFi3d credits a
  tangent chain's blend faces to some of its edges only. On 18.5A's port
  junctions, 6 of 22 edges generate nothing. Offline, the build had no
  faulty contour, the result was valid (425 574.150 mm³), and every one
  of the 22 edges was gone from the result. The app refused it as "6 of
  22 edges can't take this size", and the port/body chain alone as "2 of
  5". The drag-clamp probe (`OS3DFilletBuilds`) ran the same check, so it
  found no radius at all for such a chain.
- **Fix.** `OS3DEdgeBlended`: an edge is blended if it generated faces,
  or if it is gone from the result with no modified image. A dropped edge
  is still in the result, and an edge a neighbouring blend only trimmed
  has a modified image, so both are still refused. The finish path (fillet
  and chamfer) and the probe share it.
- **The other half was the drawing's tangency.** 18.5A/B's diamond ports
  have their top ridge (R10 about 58 + 19) touching the dome crown at 87.
  Drawn exactly, ChFi3d itself fails every junction chain that reaches the
  crown (contour status Error). With the port bosses 0.001 mm lower, as 18.3's tube is, every
  junction builds as one fillet. The blend converges as the gap closes
  (18.5A +2 289.322 / +2 289.059 / +2 289.018 mm³ at 0.1 / 0.01 / 0.001 mm;
  18.5B +703.308 / +702.771 / +702.671). One fillet over all junctions
  (22 edges for A, 25 for B) is also what SOLIDWORKS' single feature does.
- **Results.** 18.5A 225 702.170 (+0.31 %, was +0.11 % with most blends
  missing, and the round-6 note estimated +0.35 to +0.6 % with them).
  18.5B 218 743.990 (−0.001 %, was −0.23 %), so the reading was right
  and only the blends were missing. **13.3 now passes** (+0.40 %, was a
  +0.71 % fail): its recipe skips a refused fillet, and the cup's bottom
  R2 was one of these. Built, it removes 133.673 mm³ against a hand
  133.78. Practice problems 183 / 215 pass, 118 within 0.01 %. The other
  recipes that catch a fillet refusal (6.7, 11.4, 13.1) and 18.9A rerun
  identical. 18.9A's sphere/diamond fillet is a different case: first it
  builds an invalid solid, last OCCT fails the contours, unchanged by this.
- **Checked.** Fixture `port-junction-fillet-chain-credit` (all 22 edges,
  R5, expect 425 574.150) and `FilletChainCreditTests` (the port/body
  chain, all junctions, the radius probe on the port/port chain, and R20
  still refused as a partial result). All but the R20 test fail on main's
  bridge. Full unit suite 1671 / 0 failures.
- **Found:** the radius probe starts from a 0.05 mm build and returns 0
  when that fails. On 18.5A's port/body chain R0.05 fails validity while
  R0.1 to R5 build, so that drag went unclamped. (Fixed next; see "the
  fillet drag's size probe".)

## Mission log — 2026-09-16, welcome screen, bundled sample designs, App Store previews

- **Welcome sheet** (`UI/WelcomeView.swift`): shown once per install from
  the gallery (`AppSettings.hasSeenWelcome`, marked as soon as it appears),
  again from Gallery › … › Welcome…. App icon, four feature rows, the
  sample list with baked thumbnails, and two pinned exits: **Add Sample
  Designs** and **Start a Blank Design**. Page-sized on the iPad (the form
  sheet was too short and opened scrolled to its end; iOS 17 keeps the
  form), actions pinned with `safeAreaInset` so the way in is on screen
  on a phone without scrolling. DEBUG hooks: `OS3D_WELCOME` forces it;
  `OS3D_FRESH` / `OS3D_AUTO_OPEN` / `OS3D_RESET_STORE` suppress it without
  marking it seen, so every existing UI test still starts where it did.
- **Sample designs** (`Model/SampleDesigns.swift`, `openshape3d/Demos/`):
  four `.os3d` archives — Motorcycle Wheel, Mounting Plate, Glass Bottle,
  Plate Cam — baked from the live app by `scripts/demo_models.py` (the
  screenshot scenes plus the cycloidal cam) through the new
  **`GET /v1/archive`** bridge route, which saves, refreshes the thumbnail
  and returns the archive bytes. Installed into a top-level **Demos**
  folder from the welcome sheet or Gallery › … › Add Sample Designs;
  idempotent by name, so a deleted sample comes back and nothing
  duplicates. Bundled archives import with `trustingBRep: true` — the
  user-file path still drops the OCCT blob (the unhardened reader) — so a
  sample opens analytic, with its full feature history. Newest lists
  first, so the install runs in reverse catalog order and the wheel is
  the first card. The four archives add ~8.7 MB to the bundle.
- **App preview videos**: `scripts/preview_video.py iphone|ipad`. The taps
  are an XCUITest (`PreviewTakeUITests`, skipped unless the runner has
  `OS3D_PREVIEW_TAKE=1`) that the script remote-controls over a small
  HTTP loop, so they land by element identity; camera and modelling go
  over the bridge; `simctl io recordVideo` records at native size and
  ffmpeg encodes to the sizes App Store Connect accepts — **886 × 1920 for
  every current iPhone (not the 1320 × 2868 screenshot size), 1200 × 1600
  for every current iPad** — 30 fps H.264 ~10 Mbps, silent stereo AAC,
  29.5 s, portrait like the screenshots. Details in
  `docs/APP_STORE_READINESS.md`.
- **Lessons.** (1) Peekaboo clicks on a Simulator window go to whichever
  window is on top at that screen point; with several sessions' devices
  overlapping, a phone tap silently landed on another session's iPhone
  and my window could not be moved or raised (peekaboo refuses window
  mutation; System Events -10006). Hence the XCUITest driver. (2) Two
  simulators launched with `OS3D_AGENT_PORT=8899` share the Mac loopback:
  the second app never binds, and `/v1/state` answers for the other
  device — terminate the other instance first. (3) The phone simulator
  can be rotated or force-quit by another session's Simulator menu use;
  the test pins portrait. (4) `Bundle.main` flattens the `Demos/` folder
  (synchronized group, not a folder reference): look up resources with
  and without the subdirectory.
- Tests: `SampleDesignsTests` (archives decode with bodies, history and
  breps; the install/welcome decisions), `WelcomeUITests` (forced sheet →
  Demos folder → a sample opens; idempotent re-add; Welcome… reopens;
  suppressed under `OS3D_RESET_STORE`).

## Mission log — 2026-09-16, shells over fillets: split at C0 knots; 18.23's refusals traced

- **A body with a fillet over a curved junction could not be shelled.**
  OCCT approximates such a blend as a B-spline face with C0 knots, and C0
  edge curves, where the rolling ball crosses from one support face to the
  next. `BRepOffset` refuses any C0 geometry before it tries a join, so
  every shell failed with "OCCT offset: C0Geometry". Found on 18.23 with a
  straight neck: flange, dome, neck, a Ø22 pipe, R3 on the pipe junction
  (over the dome sphere, its blend torus and the neck), then shell 3 open
  at the flange, neck top and pipe end. A plain T-pipe's junction fillet
  has no C0 knot and always shelled.
- **Fix (`shelledShape:`).** When the arc-join offset fails with
  C0Geometry, `OS3DSplitAtC0` splits the body at its C0 knots
  (`ShapeUpgrade_ShapeDivideContinuity`, C1 criteria, no point moves) and
  the offset runs again with arc joins on the split copy. Intersection
  joins on the split body build but do not heal, so they are not retried.
  The offset of a split body has edges with a wrong SameRange flag
  (`invalidSameRangeFlag`). `ShapeFix` repaired them but rebuilt every
  face and dropped all ancestry (`truncatedByHeal`, no "same" rows), so
  `BRepLib::SameRange` now sets the flags in place, only on edges the
  offset made. Ancestry is composed through the split
  (`OS3DCollectMakerHistoryThrough`): pieces of a split face are "modified"
  from it, and everything the offset made of a piece is credited to the
  source face. The enclosed hollow (no openings: offset the whole solid,
  cut the copy out) gets the same split. Every other shell takes the old
  path.
- **Checked.** The straight-neck body shells to 33 324.749 mm³ at 3 mm and
  23 034.235 at 2, valid with no heal. Offline, every sampled inner-wall
  point is exactly the thickness from the outer surface, except near the
  three openings, where the open face itself is nearer; none is farther.
  The enclosed hollow comes out 44 331.346, the open shell plus its three
  3 mm caps (flange cavity outline, Ø19 and Ø16 discs) to 0.16 mm³. Pinned
  by the fixture `filleted-pipe-junction-shell-c0` and
  `ShellOverFilletTests` (both volumes, the enclosed hollow, and ancestry
  for every input face including the split blend), which fail on main's
  bridge; the enclosed-hollow test fails with only that branch's retry
  disabled. Full unit suite 1667 / 0 failures. 13.1, 13.5, 15.4A–D, 18.3 and 18.23 rerun on the fix:
  every volume identical to the ledger.
- **18.23 still fails (+0.77 %), for two traced reasons.**
  - *The shell.* The recipe's body now gets past C0 and is refused with
    UnknownError: the arc join round the pipe junction fails where it meets
    the S step, whose convex R3 offsets to zero radius at t = 3. The body
    builds at t = 2.9 and without the pipe. A sharp step with the pipe top
    in the step plane fails too, and builds with the pipe 0.1 lower.
  - *The fillet.* R3 on the pipe junction over the S step is refused
    whatever the pipe height (y 23 to 24): the ball's contact has to jump
    from the neck to the convex R3 across the concave R3, which ChFi3d does
    not do. R1 builds; R2.9 and R3.1 do not.
  The explicit cavity and the fillet-before-the-cup order stay; the
  recipe comments and the note now say why.

## Mission log — 2026-09-16, shell refusals: 18.3 was the tangent tube, 13.9A is OCCT's offset

- **18.3's shell refusal is gone.** With the cross tube 0.001 mm below
  tangent (the change that let its R3 fillet build), `feature.shell` on the
  outer body, open at the bottom and both tube ends, builds (28 553.197 mm³).
  The recipe still cuts its cavity explicitly: a true shell leaves a tube
  wall inside the cavity, which Section B-B does not show.
- **13.9A's shell is refused correctly.** Retried with the hull and pockets
  as exact arcs instead of polylines (disc + hull extruded and unioned, so
  no tangent hole face): the body before the shell is valid, 703 449 mm³
  against the hand 703 427, and the shell is still refused. Replayed from its
  capture with every `MakeThickSolidByJoin` option: arc joins give an invalid
  123 568 mm³ at any tolerance, with self-intersection on or with internal
  edges removed; intersection joins give an invalid 682 997 (unorientable
  and badly oriented faces); either with the intersection flag is not done.
  A plausible shell is 417–446k. The band and tube walls are thinner than
  twice the wall (the recipe's own comment), so their inward offsets cross,
  which the thick-solid offset does not handle. The explicit cavity stays.
- **13.9B's shell "builds", but don't trust it.** With exact arcs the app's
  Shell returns a valid 175 991 mm³ for D = 80, t = 7, far below every
  reading (420–448k) and removing three times what the explicit cavity
  does. There is no hand figure for a true shell of that body, so this is
  unverified rather than wrong; it is noted and not used. A shell whose
  offsets cross can evidently come back valid, which the volume-direction
  check (`the shell removed no material`) cannot catch.
- No code change; notes for 13.9A, 13.9B and 18.3 updated.

## Mission log — 2026-09-16, practice problems on merged main; 18.3 passes

- **All 215 recipes rerun on `main` after #53–#56.** 181 pass, the same set as
  the ledger, every health flag the same and all 215 volumes identical to the
  thousandth (4.41 included). The four round-6 fixes had each been rerun on
  their own branch; this is the combined build.
- **18.3 passes: 27 787.186 mm³ against 27 786.2 (+0.004 %), was −1.63 %.**
  Its missing volume was the R3 fillet where the Ø26 cross tube meets the
  link's waist walls, refused in every order with "TopoDS_Vertex hasn't
  gp_Pnt". Traced on a capture: the input body is sound (no edge lacks a
  vertex; the two tangency vertices at (0, 30, ±5.96), where the tube's top
  line meets the R6 round and the top face, carry 0.002 and 0.0001 mm
  tolerances). The blend runs round the tube/wall junction and its width
  goes to zero where the tube touches the top face; `ChFi3d` cannot end a
  blend that vanishes. Rational and polynomial fillet shapes, `ShapeFix`,
  unify and a fresh copy all throw the same; quasi-angular just fails.
- **The recipe builds the tube 0.001 mm below tangent.** The blend then has
  a tiny end and builds, and it has converged by then (per side:
  +238.247 mm³ with the tube 2 mm down, +227.67 at 0.2, +226.474 at 0.01,
  +226.418 at 0.001, refused at 0). One edge per side is enough: the blend
  follows each side's tangent chain, and passing every junction edge at once
  is refused ("1 of 6 edges can't take this size"). 18.3 went from 27 334.406
  to 27 787.186, +452.78, twice the per-side figure. Round 6's other
  refusals are unchanged (13.9A and 18.3 shells, 18.5A port blends, 18.23).
- **Tally: 182 / 215 pass**, 117 of them within 0.01 % with #57's 7.29.

## Mission log — 2026-09-16, 7.29 hits the sheet: R1 on every edge but the hole rims

- **7.29 now builds 103 384.272 mm³ against the sheet's 103 384 (0.00 %)**,
  on three runs of `run.py` (ledger rows appended) and three launches of a
  probe script, all on `main` (916e2a7) on `os3d-test`. Since #54 it had
  built 103 536.058 (+0.147 %) every time.
- **Why the old launches differed.** On the pre-#54 app (8787b0f), seven
  launches of a script that printed the R1 fillet's picks found them.
  Every launch took the eight outer-face outline edges. Some launches also
  took inner end arcs (post-R2 edges 19, 34, 36, 52). The predicate's
  second clause was meant for inner straight edges longer than 70 mm, and
  there are none: the web splits each into two 32.5 mm pieces. An inner
  arc (78.5 mm) passed that clause whenever its reported midpoint happened
  to land near z = ±25. After the R2 fillets, each inner arc belongs to a
  loop of smoothly joined edges: top inner arc, inner straights, R2 arc,
  the web's vertical corner, then the bottom plate's side, and back. OCCT
  rounds a picked edge's whole smooth chain, so each extra arc took its
  loop (75.893 mm³ each):

  | Picks | Loops rounded | Volume (mm³) |
  |---|---|---|
  | 8 (outer outlines) | none | 103 536.058 |
  | 9 or 10 (arcs on one side) | one | 103 460.165 |
  | 10 (arcs on both sides) | both | 103 384.272 |

  So the sheet's value is R1 on every edge except the hole rims: both faces'
  outlines of both plates and the web's four vertical corners. A hand
  estimate agrees: base 103 495.6, R2s +171.7, R1 on about 1328 mm of edge
  −285.1, total about 103 382.
- **Fix (`level7.p7_29`):** R1 picks every convex edge on a plate face
  (|y| = 17.5 or 27.5) at least 24.5 from the slot's axis (a hole rim is
  15), plus the web's vertical corners. That is 24 edges, the same set on
  every launch, and the body checks healthy. It relies on #54's stable
  midpoints. It names each loop's arcs, straights and web corners; the short
  R2 arcs between them are not picked, and they come in through OCCT
  rounding the whole chain.
- **Ledger and report:** three 7.29 rows appended to `results.jsonl`;
  `notes.json` and 7.29's row in `docs/SWPP_PRACTICE_PROBLEMS.md` updated;
  passes within 0.01 % go from 115 to 116. The overall count is unchanged at
  181 / 215.

## Mission log — 2026-09-16, a bridge feature is one undo step

- **Round 6's bug 4 is fixed.** The bridge recorded a feature with
  `session.record` and then `rebuildFrom`: two undo steps when the feature
  built, but ONE when it failed, because a rebuild that changes no body
  commits nothing. Every reply said `undoSteps: 2`, so a caller undoing twice
  after a failure also reverted the feature before it. `AgentBridge.record`
  now commits through `DocumentSession.recordAndRebuild`, the path the
  interactive tools use: append and rebuild in one composite, one undo step
  whether the feature builds or not, `undoSteps: 1`, and `undoTitle` is the
  feature's name ("Fillet", not "Add Feature").
- **Scripts that assumed two steps.** `level13.undo()` now undoes once; 13.1
  and 13.3 call it after a refused fillet, with `undo(2)` until now. 13.3's
  cup fillet is refused on every run ("2 of 8 edges"), and its volume is
  unchanged with one undo (see the rerun below), so that partial failure had
  recorded two steps; a clean refusal there would have taken the shell cut
  with it. `rebuild_cover.py` undoes its refused tangent union once.
  AGENT_CONTROL.md says one step and why it used to be two.
- **Verification.** `FeatureCommitUndoTests`: a feature that builds and one
  that fails are each one step; one undo removes exactly the failed node and
  the next removes the first feature with its body. In the app (iPad
  simulator), round 6's repro: union two cubes, R15 fillet fails,
  `undoSteps: 1`, one undo is back to the union (3 features, 2000 mm³); an R1
  fillet (−2.146 mm³, the exact (1 − π/4)·10) and one undo is back to 2000.
  Full unit suite: 1659 tests, 1 skipped, 0 failures. All 215
  practice-problem recipes rerun: the same 181 pass as `main`'s ledger,
  every health flag the same, 214 volumes identical to the thousandth, and
  4.41 off by 0.001 mm³ again (it alternates between 110 002.137 and .138
  from run to run).

## Mission log — 2026-09-16, render mesh no longer fails validity; heal-loosened booleans refused

- **Round 6's bug 2 is fixed: the tangent pocket was never invalid.** Its
  cut is exact (188.986 mm³ removed, the hand integral of the pocket
  region) and passes `BRepCheck_Analyzer`, until the app meshes it for
  display. `TessellateShape` runs `BRepMesh_IncrementalMesh` on the stored
  shape, which writes the triangulation into it, and for this body the
  mesher wrote an edge polygon the analyzer rejects (Edge21
  `invalidPolygonOnTriangulation`). Every validity gate then read the body
  as invalid: `/v1/check`, and the boolean operand gate that refused the
  next cut ("the target solid is invalid"). A kernel test pins it: meshing
  the TARGET is harmless, meshing the RESULT makes it "invalid" (2×2 table,
  same volume in all four).
- **What changed.** `OS3DIsValid` in `OCCTBridge.mm`: when a shape fails the
  analyzer and carries a triangulation, it is judged again as a mesh-free
  copy (`BRepBuilderAPI_Copy` sharing its geometry). Every gate goes through
  it: the post-op heal-and-validate, the boolean operand gate, the fillet
  probe; the health report analyzes the mesh-free copy too. Documents are
  written without triangulation, so reloaded bodies never had this problem.
  `TangentPocketValidityTests` (2 tests): the meshed pocket checks valid with
  the exact volume, and the next boolean accepts it. A control run with the
  mesh-free check disabled fails both, with the exact bug-2 messages.
- **The fix unmasked a second bug, now refused instead of silent.** 18.19's
  window pocket cut AFTER its boss (the drawn order, which agent B avoided)
  used to fail loudly on the next op. With validity fixed, the window cut
  and four later cuts all "succeeded", and those four removed nothing: the
  body stayed at 3 545.524 mm³ while its max tolerance climbed 12.9 → 77 mm.
  Traced on the captured operands: OCCT's boolean gives the coincident R6.5
  floor edge (on the boss cylinder) a pcurve 11.5 mm off on the boss face,
  leaving that face `UnorientableShape`, an invalid result; `ShapeFix_Shape`
  then "heals" it with a 12.87 mm tolerance, which passes BRepCheck with the
  right volume. No fuzzy value (0 to 0.01 mm), OBB or glue mode avoids it.
  Rebuilding the pcurve by projection makes it exact (2e-15) but the face
  stays unorientable, and the edge is shared with an operand, so a repair
  was not pursued.
- **The guard: a heal may not loosen a boolean result to part size.** When
  the heal ran and the result's max tolerance exceeds 1% of its size and ten
  times what it (and the operands) carried before, the boolean refuses: "the
  result could only be repaired by loosening its tolerance to 12.9 mm, too
  loose to build on". The first version refused ANY result that loose, and
  the practice-problem rerun caught it refusing 15.6's bent pin (PIN.3):
  OCCT's own union there is valid with a 2.44 mm tolerance (2.58 in the
  app), and cross-holes drilled near and far from the bend remove exactly
  the reference volume, so it is fine to build on. Both cases are replay
  fixtures now: `coincident-boss-arc-window-cut` (expect the refusal; a
  control without the guard replays it as "valid result") and
  `loose-tolerance-bent-pin-union` (expect success, 4 758.095 mm³; the first
  guard fails it). The 18.19 recipe keeps cutting the window first
  (3 109.645 mm³, unchanged).
- **Still open:** the coincident-cylinder pcurve itself; a fix that makes
  that cut succeed should flip its fixture to `success`, volume 3 545.524.
  (Fixed 2026-09-17: the pcurve came from the face merge after the cut,
  not the cut; see "the boolean's face merge corrupted its operands".)
  Round 6's other kernel refusals were retried on this build in case they
  were the same mesh artifact; they are not, and fail as before: 13.9A's
  and 18.3's shells ("the shelled solid failed validity checking") and
  18.5A's port/body blends ("this size is too large", "TopoDS_Vertex
  hasn't gp_Pnt"). Other ops' heals (fillet, shell, draft) could loosen a
  result the same way; no case has been seen, and they are not guarded.
- **Capture tooling:** `/v1/capture` wrote one file per body NAME, so two
  bodies called "Extrude" became one `Extrude.brep` while the manifest listed
  both. Files are now `Extrude.brep`, `Extrude-2.brep`; a test pins it.
- **Verification.** Full unit suite: 1658 tests, 1 skipped, 0 failures
  (`ShapeHealthTests` also checks a meshed invalid shape reports the same
  named findings as the plain one). In the app (iPad simulator): round 6's
  repro checks valid after the cut; 18.19 in drawn order is refused at the
  window cut; 15.6 and 18.19 pass. All 215 practice-problem recipes rerun
  on the final build: 181 pass, the same 181 as `main`'s ledger, every
  health flag the same, and 214 volumes identical to the thousandth; 4.41
  moved by 0.001 mm³ (110 002.137 → .138).

## Mission log — 2026-09-16, stable `/v1/edges` midpoints for curved edges

- **A curved edge's midpoint is now the kernel's, and the same on every
  launch.** `/v1/edges` used to keep the midpoint of the FIRST mesh segment
  that mapped to a kernel edge. `EdgeTopology.selectableEdges` returns
  segments in Swift dictionary order, which is seeded per process, so an
  arc's midpoint moved between launches of the same build (gotcha in the
  entry below). It was also a chord midpoint, slightly inside the curve.
  Now a new kernel query, `OCCTBridge.edgeMidpoints(of:)`, returns the
  point halfway along each edge's curve by arc length
  (`GCPnts_AbscissaPoint`). `OCCTKernel.edgeGeometry` builds each
  `/v1/edges` row from that midpoint, the mesh lengths summed in sorted
  order, and the convexity of the segment nearest the midpoint, so nothing
  depends on the order the segments come in. The bridge now just calls it.
  Which edges get a midpoint at all is still decided mesh-side, so tangent
  joins still have none. `lengthMM` is unchanged: summed chords, a hair
  short of a true arc (a Ø15 rim reads 47.121 against 47.124).
- **Live, sharp 4.5 profile:** two launches of the fixed app (different
  PIDs) gave identical script output (midpoints printed to three
  decimals). Against the pre-fix run only the curved edges moved, and
  mirrored pairs now agree: the lug-arc caps #18/#19 read
  (30.421, 54.567, ±21.5), on the R15 arc about the lug centre (34, 40),
  and the hole rims #32/#33 read (26.5, 40.0, ±21.5), on the Ø15 circle.
  That these are the arcs' middles is what the unit tests check; it was not
  worked out for 4.5. Straight edges are unchanged to three decimals, and so are
  the volumes and the bridge R5.
- **Tests:** `EdgeMidpointTests` (4), on an OCCT stadium plate with a round
  hole. They check that every midpoint lies on its own kernel edge (within
  1e-6), that arc midpoints sit at the angular middle and straight ones at
  the segment middle, that the rim midpoint is on the circle, and that
  reordering the mesh edges (reversed, rotated, sorted) gives an identical
  result. A fourth test checks the fixture has curved edges built from
  several segments. With `edgeGeometry` temporarily set back to the old
  first-segment rule, three of the four failed. Full unit suite: 1646
  executed, 1 skipped, 0 failures.
- **Practice problems, all 215 recipes against the fixed app** (a scratch
  copy of `scripts/swpp`, so the repo ledger is untouched; `os3d-test`,
  18.4 min): every problem matches its latest `results.jsonl` row, in
  status and in volume to within 0.01 mm³. 181 pass, 0 errors. Those rows
  predate #51, so this also shows #51's `EdgeTopology` changes moved no
  practice-problem result. That campaign ran before #53 merged. On the
  merge with #53 the full unit suite passes (1658 executed, 1 skipped,
  0 failures), and 7.29 was run as below.
- **7.29 is no longer flaky.** #53's log (next entry) found 7.29 varying
  run to run: its R1 predicate picks R25 arc edges by midpoint. On the
  pre-fix app (8787b0f), five fresh launches gave three volumes:
  103 536.058 three times, 103 384.272 and 103 460.165. On the fix (merged
  with #53), fifteen fresh launches all gave 103 536.058 (+0.147 %, a
  pass). It is deterministic now, but on the +0.147 % selection rather than
  the 0.0 % one some launches used to hit (103 384.272, sheet 103 384).
  Getting that one every time means revisiting the recipe's R1 predicate,
  which was not done here. **Done later on 2026-09-16** ("7.29 hits the
  sheet" above): 103 384.272 on every run.

## Mission log — 2026-09-16, crossing outlines split into real regions

- **Round 6's bug 1 is fixed: two crossing circles give a lens and two
  crescents.** The cause was two gaps in `ProfileDetector`. Circles,
  rectangles and polygons were always emitted whole, never split where
  other outlines cross them; and `holes(of:)` took any smaller profile
  whose CENTROID lay inside the outer one for a hole. A circle crossing
  the outer boundary became a hole, so the face got an inner wire through
  its outer wire: an invalid solid with the whole circle subtracted.
- **What changed.**
  - `splitCrossedClosedShapes` re-expresses every circle, rectangle and
    polygon that other outlines (lines, arcs, circles, rects, polygons)
    split at two or more points as arcs and lines for the face walker:
    circles become arcs between the split angles, rects and polygons their
    sides.
  - The face walker now splits arcs, not just lines, where lines and other
    arcs cross them, from the arc's exact geometry rather than its
    tessellation. A computed crossing snaps to an existing chain end within
    the weld tolerance, so every chain through one crossing shares one
    exact point. The split arcs keep exact start / mid / end, so OCCT still
    gets true circular edges.
  - **Crossing splits, touching doesn't** (`splits(at:side:others:)`). At
    each meeting point the other outlines are probed a 0.1 µm step either
    way: they split the curve if they arrive from both sides (a crossing)
    or with an odd count of ends and passes (a line ending on it, so two
    radii cut a slice out of a circle). An even number from one side only
    touch it and leave it whole, as before this change. That covers a hole
    tangent to its boundary, a circle in a rect's corner touching both
    sides, and practice problem 13.9's hull of tube chords whose vertices
    sit on its Ø200 rim. Splitting at touches was tried first: at a touch
    the region between the two curves tapers to a cusp, the two
    tessellations cross inside it, and the self-intersecting loop is
    dropped. The full rerun caught it: 13.9A/B's "everything outside the
    hull" cut picked up the whole front half of the disc and fell from
    417 020 to 239 845 mm³.
  - The face walker orders the edges leaving a node by the exact arc a
    short step along, not by the first tessellation chord, which leans
    half a step (3.75° at 48 per turn) off the tangent. With 13.9's touch
    points split (spokes added outside the rim), the chord order put a
    7.5° rim chord past a 5° tube chord and the walk produced one region
    of 31 333 mm² over the whole disc; exact order produces none bigger
    than a lobe. A control run with chord order fails that test.
  - `holes(of:)` tests a point guaranteed inside the candidate
    (`interiorPoint`) rather than its vertex average, which on a C-shaped
    crescent falls in the neighbouring lens. Boundaries that cross are not
    holes; after the split only a boundary with an ellipse or a spline in
    it can still cross, so only those pairs go through the chord-crossing
    test. (Requiring every tessellation vertex inside and no chord
    crossings, as a first cut did, dropped holes tangent to their boundary:
    the tangent vertex sits on the boundary, and the chords cross at most
    angles.)
  - Ellipses and splines are still not split. A profile whose boundary
    crosses one is left out of `profiles(at:)`, so the pick and a rebuild
    refuse ("extrude profile unresolved") instead of building the wrong
    solid.
- **Verification.**
  - `ProfileCrossingOutlineTests` (12 tests): the crossing-circle lens and
    crescents; the crescent extruded to (π·40² − lens)·5 within 0.01 mm³
    with a valid health report; a line across a circle (two regions); a
    rectangle crossed by a circle (three); nested shapes that don't cross
    stay standalone holes; a circle touched at one point stays whole;
    holes tangent to a circle (at 0° and 37°) or a rect side stay holes; a
    circle touching two rect sides stays a hole; two radii cut a slice;
    13.9's hull, as chords and as arcs, stays a hole of its rim, and with
    its touch points split no region over the whole disc appears; no region
    of a crossing arrangement is a hole of another; an ellipse crossing a
    circle is never a hole and is refused. Full unit suite: 1646 tests,
    1 skipped, 0 failures.
  - In the app (final build, iPad simulator), round 6's repro: circle r40
    at the origin and r18 at (0, 24) on `front(0)`, region at (0, −20),
    5 deep → 20 188.652 mm³, `/v1/check` valid (was 20 043.361, invalid).
    A line across a circle: the lower region extrudes to 1 174.460 mm³, the
    exact figure, valid. Two radii: the quarter slice, 392.699 mm³, exact,
    valid. An ellipse crossing a circle: refused, no body. 13.9A's
    outside-the-hull cut: 1 339 585.008 mm³ left, valid.
  - 18.8A/B's recipe had worked around this bug (a full-disc cut, the rings
    added back, the bores re-cut). Built as one region cut instead, the
    volumes match to the thousandth before and after the R1 fillets
    (91 680.142 and 87 724.070 mm³), with the same edge counts and 8
    features instead of 14; `round6_b._build_18_8` now does that.
  - All 215 practice-problem recipes rerun on the iPad simulator against
    the final build: 181 / 215 pass, the same 181 as before, and every
    volume and health flag is identical to the pre-change ledger (0
    differences over 215). Two earlier reruns on intermediate builds are
    what caught the tangent-touch regression above.
- **New finding (not fixed): a hole tangent to its boundary gives the right
  volume but an invalid solid.** Circle r10 with a circle r5 tangent inside
  it at 37°, ring region, 5 deep: 1 178.097 mm³ (exact) but `/v1/check`
  flags `intersectingWires`, because the hole's wire touches the outer wire.
  A 20 × 20 rect with a Ø10 hole tangent to one side, or to two, does the
  same (1 607.301 mm³). This branch hands the kernel what `main` did for
  these sketches (touching shapes are not split, the hole is found as
  before), but it was not re-run on `main`. 13.9's hull, which touches its
  rim only at polyline vertices, checks valid. A fix would give the face
  one wire through the touching point, or merge the wires there; splitting
  at touches would also need the tessellation cusp handled.
- **Gotcha: another session's app can answer your bridge port.** Midway
  through a rerun another session launched the app on `os3d-test` with
  port 8899. The iPad app, relaunched for the next problem, could not bind,
  and `relaunch_fresh` accepted the other app's fresh document as its own:
  6.9 was built and ledgered in the wrong simulator (its row was dropped).
  `relaunch_fresh` now reads the pid `simctl launch` prints and waits for
  `/v1/health` to answer from that pid, naming the other pid when it
  doesn't. `lsof -nP -iTCP:<port> -sTCP:LISTEN` shows who holds a port;
  the process path names the simulator. These reruns used port 8911.
- **7.29 is flaky, not changed.** **Explained and fixed later on
  2026-09-16:** unstable `/v1/edges` midpoints for curved edges ("stable
  `/v1/edges` midpoints for curved edges" above); 7.29 now gives
  103 536.058 on every launch. Its R1 predicate picks R25 arc edges by
  midpoint, and which halves match varies run to run: 103 460.165
  (2026-09-03), 103 536.058 (later rows), 103 384.272 in a probe today. It
  passes at all three.

## Mission log — 2026-09-16, edge convexity and collinear edge merging

- **Round 6's bug 3 is fixed, and a second bug in the same function with
  it.** Both live in `EdgeTopology.selectableEdges`, the mesh-side edge
  list behind `/v1/edges`' midpoint, length and `convex`, the interactive
  blend pick and blend replay.
  1. **Convexity.** An edge was called convex when its outward bisector
     pointed away from the average of ALL the mesh's vertices. That test
     only holds for a convex solid. It called a T-beam's inside corners
     convex and a pocket's rim edges concave. Now it is decided locally from
     the triangle winding: with outward normals, face A walks a convex edge
     along `nA × nB`. The old test is kept only as the fallback for an edge
     whose two triangles are wound the same way.
  2. **Collinear merging.** Crease pieces sharing a line and a face pair
     were merged into ONE span from the bucket's extremes, even across a
     gap. The T's two bar-underside edges became one 30 mm "edge" across the
     stem. `/v1/edges` maps each mesh edge to a kernel edge by its midpoint,
     and that midpoint lies on no kernel edge. So the real edges got no
     midpoint, length or convexity. Now only touching or overlapping pieces
     merge, as the function's comment always said, and convex and concave
     pieces never share a span.
- **Before and after, same script, over the bridge** (fixed build on
  `os3d-test`; `main`'s EdgeTopology and bridge on `os3d-touch`, from the
  main checkout's build of `2e35560`, whose only local change was another
  session's uncommitted `ProfileDetector` edit):

  | Body | Build | Kernel edges | Without mesh data | Concave |
  |---|---|---|---|---|
  | T, 8 000 mm³ | `main` | 24 | 4 (the bar undersides) | none |
  | T | fix | 24 | 0 | 2, the inside corners (5, 20) |
  | 4.5 recipe, 107 922.674 mm³ | `main` | 76 | 28 | 4, two of them wrong |
  | 4.5 recipe | fix | 76 | 12 | 6 |

  On 4.5, `main` called edges 47 and 69 concave. They are where each
  rail's inner wall meets the lug's round top, an outside corner. The fix
  marks them convex. Its six concave edges are the four Detail A step
  corners (x = 6 and 119, one per rail) and the two channel-floor corners.
  The 16 edges it recovers all sit at the y = 18 step, merged across the
  channel or along the profile on `main`. The 12 still without data run
  through consecutive faces (5–11, 21–27), consistent with tangent joins,
  which have no crease; they were not inspected one by one.
- **The fillet log's "other four" edges were the y = 18 ledges (confirmed
  after #51 merged).** The sharp 4.5 profile was rebuilt over the bridge:
  the recipe's sketch with sharp corners at (125, h) and (0, h), h = 27.213,
  extruded 43 on `front(-21.5)`. Two apps from one tree, `main` (8787b0f)
  and `main` with `EdgeTopology.swift` put back to 55ed21b, on a freshly
  booted `os3d-test`, same script. Both matched the fillet log: the
  recipe's sketch-fillet profile gives 208 792.537 mm³, the sharp profile
  208 924.295, and a bridge R5 on its two lateral corners (#11, #20) brings
  it to 208 792.537.

  | Build | Kernel edges | Without mesh data | Concave |
  |---|---|---|---|
  | before #51 | 32 | 6: #9, #10, #27, #28, #14, #17 | none |
  | after #51 | 32 | 2: #14, #17 | #5, #26 |

  #9/#10 and #27/#28 are the cap edges of the two ledges (faces 3 and 9,
  both facing −y at y = 18). Mesh-side they shared one line and one face
  pair with each cap, so they merged into one 125 mm span that matched
  neither. After #51 they read 6 mm, convex, at (122, 18, ±21.5) and
  (3, 18, ±21.5). #14 and #17 are the tangent joins into the lug arc, as
  the log said. #5 and #26 are the inside corners at (119, 18) and (6, 18),
  which the old test called convex.
- **Gotcha, not caused by #51: a curved edge's `/v1/edges` midpoint
  changes between launches.** **Fixed later on 2026-09-16** ("stable
  `/v1/edges` midpoints for curved edges" above); the rest of this bullet
  describes the old behaviour. Relaunching the SAME after-#51 app and
  rerunning the script moved the midpoints of the lug-arc and hole-rim cap
  edges (#18: (30.706, 54.631) then (29.579, 54.331); #32: (29.079, 45.658)
  then (26.926, 37.513)), while every length stayed the same. The bridge
  keeps the first tessellation segment that maps to a kernel edge, and
  `selectableEdges` returns them in Swift dictionary order, which is seeded
  per process. Straight edges have one segment and are stable. Do not pick
  an arc edge with `kit.edges_near` on its reported midpoint; use
  `level4._edges_between` or its length.
- **What the wrong flag touched.** `/v1/edges`' `convex`, and the mesh
  blend path (`KernelOps.blendEdges`, bodies without a brep): a misread
  edge is cut when it should be filled, or the other way round. OCCT
  fillets and chamfers (every brep body, and the bridge's `edges` indices)
  do not read it, and the tap pick does not filter on it (it did before
  2026-08-30). The merge bug also reaches the interactive pick on brep
  bodies, whose blend is placed at the picked edge's midpoint: a span
  across a gap would miss every kernel edge. That was not tried in the
  app.
- **Tests:** `EdgeConvexityTests` (8). The oracle is point containment, not
  the classifier: a point just above face A's plane and below face B's is
  in the solid exactly when the edge is concave. Every edge is checked on
  a T-beam, an L-beam, a U-channel and a pocketed block built with Euclid,
  and on a T and a pocketed block built and tessellated by OCCT. The
  T-beams also assert 24 edges. The Euclid tests, run on `main` before the
  fix, failed the way the bugs predict (T inside corners convex, two
  pocket rims concave, 22 edges instead of 24); the L-beam and U-channel
  passed there too, by the luck of where their centroids fall. The OCCT
  tests were added after the convexity change and first caught the merge
  bug (the T's 30 mm span). With the fix: the
  blend, concave, fillet-fallback, blend-edit, stress and element-naming
  classes pass (84 tests), and the full unit suite passes on `os3d-unit`
  (1642 executed, 1 skipped, 0 failures).

## Mission log — 2026-09-16, Settings reachable at any width (iPad mini portrait)

- **#44's size-class branch missed the iPad mini.** Checked on `main`
  (c9a9ee6) with a throwaway toolbar probe, each run on a freshly booted
  simulator:

  | Device, orientation | Width, class | Toolbar | Settings |
  |---|---|---|---|
  | iPhone 17 Pro, portrait | 402, compact | "…" menu | row present, opens |
  | iPhone 17 Pro, landscape | 874, compact | everything fits | 41.3 pt `Label` in the bar, opens |
  | iPhone 17 Pro Max, landscape | 956, regular | everything fits | 58 pt gear in the bar, opens |
  | iPad mini (A17 Pro), landscape | 1133, regular | everything fits | 58 pt gear in the bar, opens |
  | **iPad mini (A17 Pro), portrait** | **744, regular** | **"…" holds Report a Bug only** | **missing, cannot be opened** |

  The menu fills up whenever the bar is too narrow, whatever the size
  class. At regular width #44 kept the icon-only gear, and the menu drops
  it, just as it did on the iPhone. **The 11" iPads fit, with little
  room to spare.** With the fix, the new test tapped the gear in the bar
  in portrait on the iPad Pro 11" (M5, 834 pt) and the iPad Air 11" (M4,
  820 pt), and passed in both orientations. On the Pro 11" in portrait
  about 37 pt separates the back button from the toolbar capsule
  (screenshot), less than one item's width, so another toolbar item would
  likely fold both. `main` was not run on either; its regular-width gear
  is the same 58 pt item, so it should fit the same way. Split View windows
  were not tried.
- **What each place needs.** Measured on the iPad mini with trial
  labels as extra toolbar items. The menu includes any item whose label
  contains a `Text`, even an invisible one. It ignores
  `.accessibilityLabel`. The bar renders every `Label` (a plain one, one
  with a custom `LabelStyle`, one whose icon is the 44 pt `ZStack`) as a
  native 41.5 pt item, which fails
  `testSettingsCenterTargetOpensInBothOrientations` (width ≥ 44). A
  `Label` with `.buttonStyle(.plain)` came out 27.5 pt and missed every
  tap. The 6c8ffaf centre miss reproduced: as the group's last item, a
  `Label` gear (icon = the clear 44 pt `ZStack`) did not open on two taps
  at its exact centre, while taps 9 pt either side did. Report a Bug, next
  to it, opened at all three points. Mechanism unconfirmed.
- **Fix (`EditorView`): no branch.** The gear is the 44 pt `ZStack` #44
  kept for regular width, plus `Text("Settings").opacity(0).frame(width: 0)`.
  In the bar it is the same 58 pt custom item. In the menu the row reads
  "Settings" with the gear icon, under Report a Bug.
- **Verified after the fix:** iPad mini portrait, a Settings row that
  opens; landscape, 58 pt in the bar, opens on a centre tap. iPhone 17 Pro
  portrait, Settings is the menu's last row; landscape, 58 pt in the bar
  (now the custom item, not the 41.3 pt `Label`), opens on a centre tap.
  iPad Pro 13" (`os3d-test`), all 8 `SettingsUITests` pass in 371 s,
  including the 44 pt guard, and the gear is 58 pt in both orientations.
  Mac Catalyst was not built.
- **Test:** `SettingsUITests.testSettingsOpensFromToolbarAtAnyWidthInBothOrientations`
  replaces `CompactWidthBarUITests.testSettingsIsReachableAtCompactWidth`.
  That test skipped above 500 pt, so it could not catch the iPad mini. The
  new one never skips. In each orientation it taps the gear if it is in
  the bar, otherwise opens "…" and taps the row by title, and asserts that
  the sheet opens. It passed on the iPad mini, the iPhone 17 Pro and the
  iPad Pro 13". The probe that found the bug takes the same steps and failed
  on `main` at the missing row. The new test itself was not run on `main`.
  The regular suite runs on the iPad Pro 13", which never takes the menu
  path: run this test on an iPhone or the iPad mini after touching the
  toolbar.
- **Switch probe, iPhone 17 Pro: nothing to probe.**
  `SheetDetentTapUITests.testSettingsGridSwitch` (`TEST_RUNNER_OS3D_SHEET_PROBE=1`)
  skipped. At the medium stop the form spans 415–866 pt, and the Grid row
  is not on screen (its row is not in the hierarchy yet). Grid is the
  first switch in Settings, so no switch shows at medium on this phone,
  the same as on the iPad. With #45's 0 of 90 on the Pro Max (inherited,
  not rerun), Settings keeps `[.medium, .large]`.

## Mission log — 2026-09-16, practice problems round 6 (three parallel agents)

- **19 untried sheets, 3 agents, 13 built: 11 pass, 2 fail, 6 unbuildable.**
  The batch was the 19 readable sheets fetched on 2026-09-05 and never
  attempted. Each agent ran on its own simulator (`os3d-runner-A/B/C`,
  ports 8901–8903) and wrote its recipes in its own module
  (`scripts/swpp/round6_{a,b,c}.py`, which `run.py` now loads after the
  levels). Shared files (notes, deferred list, docs) were updated afterwards
  from the agents' reports. Every result was checked against
  `results.jsonl`, and all 13 builds were then re-run through `run.py` on the
  iPad simulator with identical volumes.

  | Result | Sheets |
  |---|---|
  | pass | 7.23 (−0.04 %), 15.8 (four configs, ≤ 0.01 %), 18.8A (−0.43 %), 18.8B (−0.39 %), 18.10 (+0.18 %), 18.15 (+0.03 %), 18.19 (+0.04 %), 18.22 (+0.30 %) |
  | pass, fillets incomplete | 18.5A (+0.11 %, **doubtful**), 18.5B (−0.23 %), 18.9A (+0.23 %) |
  | fail | 18.3 (−1.63 %), 18.23 (+0.77 %) |
  | unbuildable | 17.3C, 17.6B, 17.7B (centre-of-mass motion studies), 17.5C (part shown only as a screenshot), 18.6B, 18.12B (edit parts whose A drawings haven't been read) |

  18.5A's kernel refused the port/body and port/dome R5 blends in every
  order; with them at their separately measured sizes the reading would
  land around +0.35 to +0.6 %, so its pass may not survive. 18.3 fails only
  on the R3 fillet where its tube is tangent to the top face: moved 2 mm
  down, the same fillet builds and would bring it within about ±0.2 %. That
  tangent-contact fillet refusal is the most useful kernel case to reduce
  next. (Done: 18.3 passes with the tube 0.001 mm below tangent; see
  "practice problems on merged main; 18.3 passes" above. 18.5A and 18.5B
  have their full R5 sets too, +0.31 % and −0.001 %; see "fillets OCCT
  built were refused per edge".)
- **Four bugs found by the agents, each reproduced again here in a fresh
  document on the iPad simulator:**
  1. **Region extrude with crossing circles is wrong and invalid, but reported
     ok.** Sketch on `front(0)`: circle r40 at (0, 0), circle r18 at (0, 24);
     extrude the region seeded at (0, −20), 5 deep. Got 20 043.361 mm³, which
     is the whole small disc removed; the true region is 20 188.652. `/v1/check`:
     invalid, `intersectingWires`. As a cut the tool is refused ("tool solid is
     invalid"). **Fixed; see "crossing outlines split into real regions" above.**
  2. **A pocket whose R1 corners are tangent to an existing boss leaves an
     invalid body, reported ok.** Plate `rect(−15, −10, 15, 15)` × 7, a Ø13 × 9
     boss unioned, then a pocket on `front(7)` (sides x = ±4, top y = 11, bottom
     the boss arc, R1 corners) cut 5 deep: no eval error, 188.986 mm³ removed,
     `/v1/check` invalid (`invalidPolygonOnTriangulation`); the next boolean is
     refused ("target solid is invalid"). Agent B's exact script:
     `round6_b._corner` / `_arc_short` build the outline.
     **Fixed 2026-09-16** ("render mesh no longer fails validity; heal-loosened booleans refused" above): the
     solid was sound, its render mesh was not.
  3. **`/v1/edges` reports concave edges as convex.** A T-shaped profile
     extruded 20: the two inside corners at (±5, 10) come back
     `convex: true`; the other ten 20 mm edges, all convex, are
     correctly `true`. The likely
     cause is `EdgeTopology.isConvexEdge`, which judges by the normal
     bisector against the mesh's vertex centroid; the tap-to-pick path for
     fillet/chamfer also relies on convexity, so it may be affected.
     **Fixed 2026-09-16** ("edge convexity and collinear edge merging"
     above). The cause was that centroid test. The tap pick does not filter
     on convexity; the mesh blend path for bodies without a brep reads it.
  4. **The bridge over-reports `undoSteps` for a failed feature.** Union two
     cubes, then a fillet that fails: the reply says `undoSteps: 2`, but one
     undo already removes the feature (undo title "Add Feature") and a second
     undo reverts the union. `AgentBridge.record` hard-codes 2. The note merged
     in #48 ("undo `undoSteps` times") is corrected in AGENT_CONTROL.md.
     **Fixed 2026-09-16** ("a bridge feature is one undo step" above).
- **Getting the sheets.** The 2026-09-05 PDFs had lived in a deleted
  scratchpad. The SOLIDWORKS CDN (Akamai) now refuses scripted downloads:
  curl connects and sends the request, then the server stalls and later
  resets the connection; its homepage and `robots.txt` behave the same.
  The sheets were saved through the browser instead, one save dialog each.
- **`run.py` loads more strictly.** It used to skip a level module whenever
  anything inside it failed to import, silently dropping that level's
  recipes. It now skips only levels that don't exist, raises on a real
  import error, and refuses a problem registered twice. All 215 recipes load.

## Mission log — 2026-09-16, Fillet: lateral-edge finding stale; bridge undo gotcha

- **Sharp lateral edges fillet over the bridge on `main`.** The
  2026-09-04/05 log said the corner edges parallel to an extrusion have no
  mesh-side signature, so `feature.fillet` refuses them with
  `unaddressable_edge` and every "R n TYP" corner needs a sketch fillet.
  On a plain 20 × 10 × 5 extruded rectangle, R1 on a vertical edge removes
  1.073 mm³, exactly (1 − π/4) · 1² · 5. On practice problem 4.5's own
  profile, whose recipe carries the sketch-fillet workaround: the recipe's
  sketch-fillet corners extruded 43 give 208 792.537 mm³; the same profile
  with SHARP corners, extruded, with a bridge R5 on the two lateral corner
  edges (#11, #20, both listed with midpoint and length) gives
  208 792.537 mm³, a difference of 0.000. A cylinder's rim fillets too
  (Ø20 × 10, R1: 3141.593 → 3128.410, matching Pappus). The September
  build was not re-tested for this one.
- **Not every lateral edge carries mesh-side data.** On that sharp 4.5
  profile, 6 of 32 edges list no midpoint or length. Two join profile walls
  that meet TANGENTLY (the lines into the lug arc): no crease, nothing to
  fillet, so that is correct. The other four were not identified, and
  `level4._edges_between` (edges picked by their adjacent faces) is still
  the way to address such edges. **Later on 2026-09-16:** confirmed as the
  cap edges of the y = 18 ledges (#9, #10, #27, #28), lost to the
  collinear-merge bug fixed in #51 ("edge convexity and collinear edge
  merging" above); after #51 only the two tangent joins lack data. 4.7's lug-junction R2s, noted as
  impossible over the bridge, were not re-tested.
- **Gotcha: undo a bridge feature twice** (superseded 2026-09-16: a bridge
  feature is now one undo step; see that log above). A feature exec lands as two undo
  steps (`undoSteps: 2`, docs/AGENT_CONTROL.md). ONE undo reverts the
  rebuild but leaves the feature in History, so the body shows the old
  volume while the graph still holds the feature. The next feature then
  builds on that mismatch: after fillet #3 → one undo → fillet #1, the box
  lost 7.344 mm³ (the whole corner, #1 + #3 + #11) instead of 1.073, with
  the feature count at 3 instead of 2. With two undos the same sequence is
  exact. It cost a false bug report here and briefly cast doubt on the
  Shell fix's in-app check, which was then re-run clean (holed box, tool
  Apply: 187.094 mm³, 3 features, `/v1/check` 0 invalid). Interactive
  tools record features differently and do not hit this.

## Mission log — 2026-09-16, Shell: stale over-hollow finding; the Shell tool opens holed faces

- **The logged Shell over-hollow doesn't happen, on `main` or on the
  2026-09-05 build.** The 2026-09-04/05 log recorded `feature.shell` on
  the 13.9 hub removing 517k mm³ where the offset cavity is 286k, with
  brep true and a clean check. Rebuilt three ways on `main` (13.9A: no
  shell 703 263.8 mm³; the recipe's explicit cavity 417 020.2, so
  286 243.6 removed), the app's Shell is refused: "the shelled solid failed
  validity checking". The app built at `9ece43d` (2026-09-05, which
  contains the commit that wrote the note) gives identical numbers and the
  same refusal. The validity check (`OS3DHealAndValidate`) and the rule
  that a B-rep body whose OCCT shell fails errors instead of falling back
  to the mesh inset both date from 2026-08-31 (`069be64`), before the note,
  and `OCCTBridge.mm` is unchanged since 2026-09-05. So no committed build
  returned 517k; it most likely came from a worker's uncommitted state.
  What remains is a capability gap: Shell cannot hollow this hub, and the
  recipe keeps its explicit cavity.
- **The Shell tool could not open a face with a hole in it.** The live
  preview (`EditorViewModel.shelledBody`) identified each open face to
  OCCT by the centroid of its outline. The outline is the OUTER boundary,
  so on a holed face that centroid lies in the hole: OCCT refused the
  pick, the preview stayed empty and Apply stayed disabled, while the same
  shell built over the bridge. The evaluator was fixed for exactly this on
  2026-09-04 (`e405820`); the tool was not. Reproduced on the iPad
  simulator on a 10 × 10 × 6 box with a Ø4 through-hole and a 0.5 mm wall:
  a plain side face previewed with Apply enabled; the holed face gave no
  preview and Apply stayed disabled; over the bridge the holed face shelled
  to 187.09 mm³ (hand-computed 187.09). Now
  `EditorViewModel.shellOpenPoints` hands OCCT the evaluator's point
  (`FeatureGraph.pointOnPlanarFace`), so the preview and the feature it
  commits pick faces the same way. After the fix the holed face previews
  and Apply commits 187.09 mm³ with no eval errors. Test:
  `PlanarFacePickPointTests.testShellToolOpenPointsHollowAHoledFace` (the
  tool's point shells to the analytic volume; the old outline centroid is
  refused). `FeatureShellEvalTests` + `PlanarFacePickPointTests`: 7 of 7.
- **Gotcha (tool behaviour, unchanged):** the first tap on a body with the
  Shell tool sets the thickness to `defaultShellThickness` (2 mm, capped at
  a quarter of the body's smallest extent), replacing any value typed
  before it. Pick the body, then type the wall. It cost several rounds
  here: the replaced 1.5 mm is too thick for the test part and disabled
  Apply on every face, which looked like the bug.

## Mission log — 2026-09-16, SOLIDWORKS practice problems rerun on main

- **All 202 practice problems rerun on `main` (5e0f9c3): 170 pass, the
  same as on 2026-09-05.** 55 commits had changed the kernel, the model
  and the agent bridge since the last run. Once 11.5 was fixed (below), no
  problem went from pass to fail or from fail to pass, and the 32 fails are
  the same sheets. Builds took 15.0 min, against 14.0.
- **11.5 was a harness failure, not an app regression.** The first pass
  scored 169, because 11.5 stopped with `No module named 'geo115'` before
  building anything. Its recipe imported the cam-plate outline helper from
  a 2026-09-04 worker's scratchpad, which has since been deleted, and the
  helper was never committed. It was recovered verbatim from that worker's
  transcript (written two minutes before 11.5's 2026-09-04 pass and not
  changed after) and is now `scripts/swpp/geo115.py`. Its self-check gives
  1831.930 mm³, and the app builds 1831.927 mm³ (+0.237 %), identical to
  September. No other recipe imports code from outside the repo.
  **Gotcha:** a recipe that imports from a scratchpad works until the
  scratchpad is cleaned up. Keep helpers in `scripts/swpp/`.
- **One pass moved: 7.29** (two plates, a web, mirror, union, R2 and R1
  fillets) went from +0.074 % to +0.147 % (103 460 → 103 536 mm³), the
  same to the cubic millimetre on two reruns. That is still well inside the
  0.5 % band. The commit that changed it was not traced.
- **Ledger:** the rows are appended to `scripts/swpp/results.jsonl`: the
  202 of the rerun, then 11.5 once and 7.29 twice.

## Mission log — 2026-09-16, switch-tap probe on iPhone

- **On a phone, no switch dropped a tap, not even in the positive
  control.** With #44, Settings opens on a phone, so
  `SheetDetentTapUITests` could run on the iPhone 17 Pro Max simulator.
  Taps lost at the medium stop:

  | Sheet | Target | Lost |
  |---|---|---|
  | Constraint settings, `[.medium, .large]` restored for the run (positive control) | Grid switch | 0 of 45 |
  | Constraint settings, same | Always Show Dimensions switch (top of form) | 0 of 30 |
  | Main Settings, `[.medium, .large]` | Grid switch, flush with the bottom edge | 0 of 90 |
  | Main Settings | Units segmented control | 0 of 30 |
  | Main Settings | Circular Annotations menu | 0 of 30 |

  The same control lost 17 of 60 and 3 of 30 on `os3d-runner-B`, and 2
  of 15 and 1 of 15 on `os3d-test` (both iPad Pro 13" simulators). The
  control and Main Settings' Grid switch ran in the same sessions.
- **The control really sat at its medium stop.** In every trial of both
  sheets the grabber read "Half" and the sheet's top edge was at
  470.4 pt, and no sheet left its first stop. The iPad's medium stop is
  different: a centred 580×364 pt card whose grabber reads "Collapsed".
- **So, as measured, the effect is iPad-only, and Settings keeps its
  detents on the phone.** The mechanism is still unconfirmed. Caveats:
  because nothing drops taps on the phone, the probe cannot show that it
  would catch a loss there; and this is one phone model, in a simulator.
- **Probe fixes.** `openSettings` and `openConstraintSettings` reach both
  sheets on either device. On a phone they go through the toolbar's "…"
  menu and the rail's compact menu (`ConstraintRailMenu`, which replaces
  the rail and its gear at compact width), finding rows by title (gotcha
  58). The Grid switch visibility check allows a point of slack: on the
  phone the row ends flush with the sheet at 948 pt, and a 1e-13
  floating-point difference skipped the test with the switch on screen.
  `probeSwitch` now fails when its switch is below the fold, instead of
  logging taps that miss the sheet as lost.

## Mission log — 2026-09-16, Settings reachable on iPhone

- **Settings could not be opened on an iPhone at all.** At compact width
  the editor's primary toolbar group collapses into a "…" overflow menu,
  which builds each row from the item's `Label` title. `SettingsButton`,
  the only route to Settings, was a `ZStack { Color.clear; Image }` with
  only `.accessibilityLabel("Settings")`. With no title, the overflow
  dropped it: on the iPhone 17 Pro Max simulator the menu held History,
  Variables, Items, Import, Export, Command Search and Report a Bug, and
  nothing else. Found by the medium-detent probe (entry below).
- **Fix: branch on size class** (`EditorView`). Compact renders
  `Label("Settings", systemImage: "gearshape")`, and the menu now ends with
  Settings. Regular keeps the previous 44 pt `ZStack` unchanged, because a
  `Label` cannot carry that target (gotcha 58). 6c8ffaf added the 44 pt
  surface after taps on the gear's own centre missed;
  `testSettingsCenterTargetOpensInBothOrientations` guards it.
- **No single shape does both.** A `Label` with an outer 44 pt frame
  fixed the phone (Settings appeared in the menu) but measured 41.5 pt on
  the iPad and failed that guard (width ≥ 44). A `Label` inside the
  `Color.clear` `ZStack` also measured 41.5 pt. The guard passes on
  unmodified main (19.8 s), so the change caused the failure, not the
  test. The shipped compact branch is a bare `Label`, verified on the
  phone only; the iPad never runs it.
- **Regression test:**
  `CompactWidthBarUITests.testSettingsIsReachableAtCompactWidth` opens "…",
  taps the Settings row and asserts the sheet opens; it skips at regular
  width. It finds the row by title, since the row carries no identifier
  (gotcha 58). **Superseded later on 2026-09-16:** the size-class branch
  still lost Settings on the iPad mini in portrait, which is regular width.
  The branch and this test were replaced (see "Settings reachable at any
  width" above).
- **Verified:** on the iPhone 17 Pro Max the new test passed (11.0 s). On
  the iPad Pro 13" all 7 `SettingsUITests` passed (348 s) and the new test
  skipped (window 1032 pt). The regular branch is the previous code
  unchanged, so the other iPad callers of `SettingsButton`
  (`DimensionUITests`, `SheetDetentTapUITests`) were not rerun.
- **Then open, now answered: Settings' switches at a phone's medium
  detent.** `SheetDetentTapUITests.testSettingsGridSwitch` opened Settings
  with `app.buttons["SettingsButton"]`, which matches nothing on a phone
  (the overflow row has no identifier). Routed through "…" by title and
  run on the iPhone, it lost no taps, and neither did the positive control
  (entry above).

## Mission log — 2026-09-15, medium-detent sheet tap probe

Follow-up to #40, which fixed the constraint settings sheet's dropped taps by
removing its detents. The question here: which of the other detented sheets
drop taps at their medium stop?

- **Probe.** `SheetDetentTapUITests` (new, opt-in:
  `TEST_RUNNER_OS3D_SHEET_PROBE=1`, about 35 min for the class at two
  iterations). Each test opens one sheet at its medium stop without
  swiping. It then taps one control, the lowest visible one unless the
  table notes otherwise, 15 times at a fixed window point. It records
  whether each tap took and whether the sheet stayed at medium. The taps
  use window points because a swipe expands a medium sheet and hides the
  bug, and an element tap may scroll, which does the same. Runs were on a
  freshly booted `os3d-runner-B` (iPad Pro 13", iOS 26.5, portrait). On
  this iPad every sheet at its medium stop, with one detent or two, is the
  same centred 580×364 pt card (bottom edge at y = 1008). The two-detent
  ones carry a "Sheet Grabber" that reads Collapsed. No sheet left its
  first stop in any trial.
- **Taps lost at the medium stop**, per target:

  | Sheet | Detents | Target | Lost |
  |---|---|---|---|
  | Constraint settings, before #40 (positive control) | medium, large | Grid switch, bottom edge | 17 of 60 |
  | Constraint settings, before #40 | medium, large | Always Show Dimensions switch, TOP of the form | 3 of 30 |
  | Main Settings | medium, large | Circular Annotations menu (lowest visible) | 0 of 30 |
  | Main Settings | medium, large | Units segmented control (top) | 0 of 30 |
  | Material | medium, large | Color well, on the bottom edge | 0 of 30 |
  | Gallery "Move to Folder" | medium, large | F04 row, on the bottom edge | 0 of 37 |
  | Text | medium | Font menu | 0 of 30 |
  | Helix options | medium | Turns field (opens the number pad) | 0 of 30 |
  | Screenshot options | medium | Show Grid switch | 0 of 30 |
  | GLB/OBJ export options | medium | Separate File per Body switch | 0 of 30 |

  The constraint rows ran with that sheet's `[.medium, .large]` restored
  for the run, in the same runs as the other sheets. The losses come in
  streaks: one block of 15 lost 11 taps in a row and then took the rest,
  while other blocks lost none. So a clean block of 15 proves little on
  its own; compare against the control in the same session. Every lost
  tap was delivered: XCUITest synthesized it at the right point, and the
  app went idle within half a second.
- **Only runs outside the disk-full window count.** The Mac's disk filled
  between about 19:00 and 20:00 UTC (see the next entry). The table uses
  only the runs before and after it (18:23–18:54 and from 21:51 UTC).
  Runs inside the window pointed the same way (switch taps lost, nothing
  else) but are left out.
- **#40 holds.** On `ad9f1b0` (main with #40) the constraint sheet opens
  full height, with no grabber, and lost 0 of 30 taps on the Grid switch
  and 0 of 30 on the top switch. Without `TEST_RUNNER_OS3D_SHEET_PROBE`
  the probe's 11 tests all skip (0 failures, about 1 s), so it adds no time
  to the regular UI suite — confirmed on `os3d-test`: 11 executed, 11
  skipped, 0 failures in 0.7 s.
- **Reproduced on a second simulator before landing.** The table above was
  measured on `os3d-runner-B`. Restoring `[.medium, .large]` on the
  constraint sheet on `os3d-test` and rerunning the two positive controls
  lost 2 of 15 on the Grid switch and 1 of 15 on the top switch (the sheet
  stayed at its first stop in all 30 trials). Lower rates than the original
  runs, as the streakiness predicts, but the same effect on different
  hardware — and an independent reproduction of the finding that the TOP
  switch loses taps, which is what rules out a bottom-edge explanation.
  The probe therefore catches the bug it claims to, rather than only
  passing where #40 already fixed it.
- **Finding: it is not a bottom-edge effect, and not any control.** Taps
  are lost only when both of these hold: the control is a `Toggle`
  (UISwitch), and the sheet sits at a medium stop it can still resize
  from. The constraint sheet's top switch lost taps as well as its bottom
  Grid switch. Switches in the one-stop `[.medium]` sheets lost none
  (0 of 60). Menus, a colour well, list rows and a segmented control in
  the two-stop sheets lost none, even on the bottom edge (0 of 127). The
  mechanism is unconfirmed. The likely candidate is the switch's own
  drag-to-toggle tracking competing with the sheet's resize gesture.
  #40's code comment ("switches near its bottom edge") is corrected to
  match.
- **No sheet needs a fix on the iPad.** None of the remaining two-stop
  sheets shows a switch at its medium stop. Main Settings' snapping
  switches sit below the fold (the Grid row starts at y 1081, the card
  ends at 1008), so they can only be reached by expanding the sheet, and
  the #40 diagnostic lost none there at full height. The detents stay:
  Settings, Material and the move picker keep their resizable half-height
  presentation.
- **iPhone: Settings is unreachable, which is a separate bug.** On an
  iPhone 17 Pro simulator the editor's toolbar collapses into a "…"
  overflow menu, and Settings is not in it (History, Variables, Items,
  Import, Export, Command Search, Report a Bug). `SettingsButton` is the
  only route and has an icon-only custom label; that is presumably why the
  overflow drops it. Once Settings is reachable there, a phone's
  half-height sheet will probably show the snapping switches, the case
  that loses taps. Then run `testSettingsGridSwitch` on the phone (it
  skips on the iPad, where the switch is below the fold) and drop
  Settings' detents if it loses taps. **Reachability fixed 2026-09-16**
  (entry above); the probe test still needs routing through "…" before
  it can open Settings on a phone.
- **Harness notes.** A long-press context menu in the gallery leaves the
  app never idle, so XCUITest waits 60 s after the press and again after
  the menu tap (about 2 min per trial). The probe opens the move picker
  from Select mode instead. `-test-iterations N` runs each test N times
  back to back.

## Mission log — 2026-09-15, full UI suite after #37–#39

- **Full UI suite on `fix/phone-palette-safe-area`** (0da9c88, on top of
  #37 and #38): 189 executed, 181 passed, 4 skipped, 4 failed, in 115 min
  on a freshly booted `os3d-test`. The 4 skips are the
  `CompactWidthBarUITests` phone-width tests, which skip on the iPad, so
  the #39 safe area has no UI coverage (unit tests and the live iPhone
  check only).
- **Three failures were #37's framing, not the app.** `DeleteFaceUITests`,
  `MeasureUITests.testMeasureTwoPointsShowsDistance` and
  `PlanesUITests.testPlanePickerRefusesCurvedWallAndAcceptsCap` tap fixed
  normalized points on a seeded model fitted at open. Zoom to Fit now
  respects the portrait aspect: on the 13" iPad (0.75) the model fits
  1/0.75 farther away, so every fitted point sits 0.75× as far from the
  screen centre. All three pass on `bfe822d` (before #37). Their points
  are rescaled (new = 0.5 + (old − 0.5) · 0.75), and the three classes
  now pass in full (10/10). **Gotcha:** a UI test that taps a fitted seed
  at fixed coordinates is tied to the fit; change the fit, rescale the
  taps.
- **The fourth predated this work and was a real app bug, fixed the same
  day.** `ConstraintRailUITests.testMidpointApplicationAndHistoryDeselectMixedOperands`
  (it also fails on `bfe822d`) was the constraint settings sheet's Grid
  switch ignoring taps. By hand in the simulator it ignored 1 of 2. With
  the app instrumented, a lost tap never reached `AppSettings.snapToGrid`
  (no set, no revert), and the sheet was not re-rendering. The cause was
  the sheet's half-height detent. Sheet taps lost per diagnostic run:
  - `[.medium, .large]`: 2 of 15 and 4 of 15;
  - plus `.presentationContentInteraction(.scrolls)`: 1 of 30;
  - no detents: 0 of 15.

  The same switch in main Settings lost none, but the test had swiped that
  sheet up to full height. The constraint sheet now opens full height (no
  detents), and the midpoint test, with its original single tap, passed
  8 of 8. The four classes that use the sheet (ConstraintRail, Dimension,
  LineChain, Settings) pass 43 of 43. **Gotcha** (narrowed the same day
  by the tap probe above): what drops taps is a switch in a sheet that
  can still resize from its medium stop, wherever the switch sits. It is
  not a control near the bottom edge. Menus, buttons, list rows, a colour
  well and a segmented control in those sheets lost none (gotcha 57).
  None of the other `[.medium, .large]` sheets shows a switch at medium,
  so none needed a fix.
- **Full UI suite on `main` after #37–#40 (ad9f1b0): no known failures.**
  The first run crashed partway (`xcodebuild` exit 133) when the Mac's
  disk filled, and three tests failed around then: the SweepLoft circle
  sweep, TwoShapeRepro draw-switch-draw and VariablesPanel. None had
  failed that morning. With space freed, every class that run failed or
  never reached was rerun on a freshly booted `os3d-test`, and 17 of 17
  passed. Together with the 170 that passed before the disk filled,
  every UI test passes on `main`. The 4 `CompactWidthBarUITests` skip on
  the iPad by design. **Gotcha:** a full disk makes UI tests fail
  spuriously, can crash `xcodebuild`, and stops the agent's own tools
  from writing output at all. A long UI run's `.xcresult` is 1 GB or
  more, and repeated diagnostic runs add up. Check
  `df -h /System/Volumes/Data` before a long run and delete old result
  bundles.

## Mission log — 2026-09-15, App Store screenshots reshot for the new framing

- **All twelve App Store shots were reshot** (iPad Pro 13-inch 2064 × 2752,
  iPhone 17 Pro Max 1320 × 2868) because both sets predated #37
  (aspect-aware Zoom to Fit) and #39 (phone palette safe area). A marketing
  image that shows the old framing misrepresents the shipping app, and the
  iPhone set was the point: #39 exists so a fitted model is not left under
  the palette. Pipeline and shot list: `docs/APP_STORE_READINESS.md`.
- **Staging over the bridge, posing by touch.** `marketing_scenes.py
  wheel|plate|bottle` builds, paints and frames each model through
  `/v1/exec`; only the states with no endpoint (dimensioned sketch, armed
  push/pull, History panel, Export menu) are posed by hand. Aim taps with
  `GET /v1/project` and read results from `/v1/state` — a screenshot cannot
  tell you which face got selected. Two traps cost real time: taps on the
  plate's top can land on the filleted band ("Curved face — no push/pull",
  perimeter 0.00) instead of a planar face, so pick the target from
  `/v1/faces` + `/v1/project`; and committed sketch dimensions are invisible
  unless the app is launched with `-os3d.alwaysShowDimensions YES`
  (annotations otherwise follow selection). `/v1/sketches` reports
  `dimensionCount`, which is how you prove one exists.
- **Zoom to Fit now frames marketing shots too small, where it used to frame
  them too large.** On the phone the fit is aspect-aware *and* confined to
  the strip the palette leaves visible, so the bottle fitted at ~25 % of
  screen height against the ~68 % the shot wants. Every shot is still
  hand-framed, now by pinching *out*. A two-finger `touch2_path` whose two
  contacts move symmetrically is a clean zoom: it leaves `mode` at `idle`
  and the selection empty, so it cannot disturb a posed scene.
- **#39 verified on the finished images, not just in tests.** Measured on
  saturated model pixels, the bottle has zero pixels under the palette
  before or after, and its left edge moved outward 129 pt → 173 pt; the two
  shots that changed most went 14.4 % → 3.9 % (sketch) and 13.2 % → 5.6 %
  (extrude) of model pixels inside the palette band. **Gotcha for anyone
  repeating this:** a naive "saturated or dark" pixel mask also catches the
  palette icons' own dark strokes and the coloured ground axes, which run to
  the screen edge — that floors every shot at 1–2 % and reports a spurious
  occlusion. Restrict the mask to the model's own hue.
- **`marketing/` is gitignored, so none of this is committable.** The twelve
  raws and twelve composed images live on disk only and are regenerable from
  the two tracked scripts; a fresh clone has neither. Only this record and
  the readiness doc are in the repo.

## Mission log — 2026-09-13, sketch-parity branch merged; iPad open time

- **`fix/sketch-parity-foundations` (PR #29) is ready to merge** after full
  serial runs at the final state (last, on the final tree: unit 1613/1613
  with 1 skipped; UI 185 executed, 4 skipped, 0 failures). Per-case receipts under `docs/testing/`,
  the register `SKETCH_PARITY_OPEN_STATUS.md`, and published evidence
  (Google Docs linked from the register). Remaining partial-core scope is
  device-only (hover, pan, pinch, Pencil).
- **Opening a drawing no longer replays the feature graph on the main
  thread** (7b80282). Measured on Jason's iPad: 130 ms to load, then 5.7 s in
  `refreshEvalErrors()` replaying every feature for badges on every open;
  the replay runs detached now and only its error map is adopted. DEBUG
  `OpenTiming` marks print with `OS3D_OPEN_TIMING=1`
  (`testing/perf-open-path-2026-09-13.md`).
- **iPad session feedback (2026-09-14):** plane picker tiles sized to the
  screen (3004c48); rotation ring typed entry with the app keypad and lit
  handles (ba42c5b). `testing/ipad-feedback-2026-09-14.md`.
- **Pinch-out on a metre-scale model no longer jumps the camera in
  (2026-09-14).** `TurntableCamera.zoom` capped distance at 2000 mm while
  `fit` sets it directly: a 1 m wheel fits from ~2.6 m, so every zoom-out
  snapped to 2 m (×1.29 closer, whatever the pinch). The cap is now
  `maxZoomDistance` (100 m) and never below the current distance
  (`CameraTests.testPinchOutFromAFarFitNeverMovesCloser`).
- **Zoom to Fit respects the viewport aspect (2026-09-14).** `fit` sized the
  bounding sphere against the vertical FOV only, so a wide model overflowed
  a portrait phone. `fit(boundsMin:boundsMax:aspect:)` now fits inside the
  tighter half-FOV (horizontal = atan(tan(fovY/2)·aspect); orthographic
  needs no branch). Aspect ≥ 1 is unchanged. The viewport passes its aspect
  on every fit, and redoes the attach-time fit once when the view first
  gets a size (it opens at .zero) unless the camera moved meanwhile.
  Measured over the bridge, the plate after isometric + fit: iPhone 17 Pro
  Max x −109…562 → 65…378 on 440 pt (reopening the design lands the same);
  iPad portrait (aspect 0.75, where the horizontal FOV also binds) x 43…1009
  → 157…886 on 1032 pt, ~25 % smaller and clear of the palette. The
  iPhone palette overlap left open here is fixed by the next entry.
- **The phone palette keeps a safe area (2026-09-14).** The aspect-aware
  fit still centred on the full width, so on iPhone the fitted plate's
  near corner sat under the tool palette (AABB x 61 vs its edge at 79).
  `ViewportSafeArea` (Camera.swift) is the strip the palette leaves
  visible, derived from its measured frame (EditorView `onGeometryChange`;
  compact width only, so iPad framing is unchanged; a palette pushed
  inward by an open panel, leaving under half the width, covers nothing).
  Fits use the strip's aspect, and the projection centre moves to the
  strip's middle: a clip-space shift, `centerOffset`, read from
  `Renderer.centerOffset` by the on-screen frame, `ray(at:)` and
  `worldToScreen` (every overlay, `/v1/project`), so drawing, picking and
  labels agree. **Anything new that draws, picks or projects must pass it
  too.** Offscreen captures (thumbnails, `/v1/screenshot`) stay centred.
  It is a lens shift, not an offset fit target, so the model stays clear
  at every orbit angle and standard view. The opening fit is redone when
  the palette is first measured, while the camera is untouched.
  `CameraTests` +3; full suite 1633 (1 skipped), 0 failures. Live on the
  iPhone 17 Pro Max, plate after isometric + fit: AABB x 61…382 → 129…392
  (centre 259.3, mid-strip 259.5); Back view 141…377; a tap on the plate's
  end selects it, and a tap 18 pt past its drawn edge selects nothing.
- **Painted bodies keep their material through previews and face edits
  (2026-09-14).** Every preview that stands in for its source body — face
  push/pull, fillet/chamfer, shell, delete face, replace face — was drawn
  with no material, so a painted part went the default grey for the whole
  drag; the face move/scale/rotate drags did the same by swapping a fresh
  `Body` (no material) into the document in `session.preview`. Worse, those
  three committed through `ReplaceBodyCommand` with freshly built
  before/after snapshots, so the commit, its undo and a cancelled drag
  stripped the paint for good. Now one spec→render mapping,
  `BodyMaterial(spec:meshHasTexcoords:revision:)`, serves bodies and
  replacing previews alike (a rebuilt preview mesh keeps the colour and
  drops an imported texture, as a committed rebuild already did); the face
  drag previews carry the source's material; `ReplaceBodyCommand` apply and
  revert keep the live body's material and visibility
  (`Body.keepingAppearance`). `MaterialTests` +2; full unit suite 1629
  (1 skipped), 0 failures. Live on the iPad: the same 6.5 mm push/pull drag
  is grey on the old build and blue on the new; a bridge `feature.moveFace`
  commit and its undo stay blue. Left alone on purpose: the fresh-extrude
  and pattern ghosts stay translucent accent previews. **Booleans, checked
  the same day:** the live Combine path (`runBoolean`) built its result as
  a fresh `Body` and `BooleanCommand` wrote it verbatim, so Union/Subtract/
  Intersect turned a painted target grey (and redo did again); apply and
  revert now keep the target's appearance the same way — the tool's paint
  goes with the tool. Graph replays were already fine: every boolean route
  (`evalBoolean`, extrude/revolve/sweep/loft join-cut) keeps the target's
  id, so `RebuildPlanner` carries the material. `MaterialTests` +1 (1630,
  1 skipped, 0 failures). Live on the iPhone: blue 20×20×10 ∪ grey
  20×10×16 by touch → one blue body, 6700 mm³; undo → blue + grey; redo →
  blue.
- **Gotchas added:** UI tests share the app's UserDefaults across launches
  (`OS3D_RESET_STORE` now resets them too); grid snapping captures small
  test drags (launch with `-os3d.snapToGrid NO` where the recipe is
  sub-grid); a locked iPad denies every launch and hangs `xctrace`.

## Mission log — 2026-09-09, arc endpoint tangent transition

Paired native/clone construction confirmed that a visually tangent endpoint Arc
was not storing the native Tangent relationship. Arc third-point commit now
performs endpoint-only inference through the saved point, angle, and setting
gates, then commits the Arc and accepted constraint as one Draw history step.
Native and the exact clone build both showed the tangent glyph; one-step Undo
and Redo matched. Focused inference/construction passed 31/31 and the final
combined solver/construction/existing-arc-UI regression passed cleanly 63/63.
Direct gesture major/minor boundaries, hover delivery, physical Pencil/touch,
QA-55/56, final candidate regression, and device-build handoff remain open.
[Detailed receipt](testing/sketch-parity-arc-tangent-transition-2026-09-09.md).

## Mission log — 2026-09-09, direct arc boundaries

Controlled native and clone gestures now cover direct minor, semicircle and
major construction. Native sampled 90/180/220 degrees; the differently scaled
clone sampled 81.91/176.03/214.93 degrees. Clone toolbar Undo removed only the
major arc and Redo restored its profile. QA-13 remains partial for simulator
hover delivery and physical Pencil/touch; no exact macOS-to-iPad coordinate or
device-input equivalence is claimed.
[Detailed receipt](testing/sketch-parity-arc-major-minor-boundaries-2026-09-09.md).

## Mission log — 2026-09-09, downstream smoke

Native and clone each carried an isolated circle through closed-profile
selection, extrusion commit and solid Undo/Redo; the clone also canceled a
preview cleanly. Current-revision Sweep/Loft UI plus kernel/feature-graph
coverage passed 65/65 in one serial run. QA-56 is passed without claiming
advanced downstream parity or physical-device testing.
[Detailed receipt](testing/sketch-parity-downstream-smoke-2026-09-09.md).

## Mission log — 2026-09-09, sustained use

QA-55 passed paired ten-cycle rectangle/circle/line construction, history,
dense-state gallery reopen and clone post-test relaunch. One clean 71/71
focused profile/cache/constraint/construction/selection run supplements the
live evidence. No visible hang occurred. Native needed a settled circle-release
pause; wall-clock automation timings are recorded but are not a performance
comparison. Physical Pencil endurance remains unverified.
[Detailed receipt](testing/sketch-parity-sustained-use-2026-09-09.md).

## Current baseline correction — 2026-09-07

The September 5 sections below are **historical**, not the current implementation contract.
At audited revision `88b0478`, both Always Show Dimensions and Always Show Constraints default **OFF**. Off means selection-based, not hidden and not “all active sketch annotations.” The follow-up implementation filters each annotation and makes normal model-mode outline taps recover its dimensions; see [implementation ledger](SKETCH_PARITY_IMPLEMENTATION.md).

`PSTools.Dimension.*` and the shipped Dimension tutorial include **2D Drawings** features. The “ten sketch dimension tools” / G2 list below is **withdrawn as a sketch requirement**. Label dragging also needs verified sketch-specific evidence. Native Shapr3D was accessible during the September 6 audit; the old accessibility blockage below is historical. Camera behavior requires per-device UI verification, not assumptions from old notes.

## Mission log — 2026-09-07 noon, illustrated evidence and camera entry

Published [illustrated Google Docs addendum](https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit) with 16 embedded screenshots; exported-image count and anonymous reading verified. The desktop locked again, so fresh direct A/B awaits unlock. An hourly continuation reminder is enabled at the user’s request until stopped.

Changed beginSketch to align the camera to the selected plane automatically, removing the unsupported preserve-oblique-view reference claim. Simulator build passed; focused RectangleWorkflowUITests/testCenterRectangleExtendsAcrossItsStartingPoint passed (1/1, 12:10 EDT), asserting no Look at Sketch action is needed and checking the drawn profile. Receipt: `/tmp/os3d-parity-camera-ui.xcresult`. Fresh live reference recheck and other planes remain open. Diagonal-anchor, post-draw line readout and keypad fixes remain open.

## Mission log — 2026-09-07, direct two-app comparison

Operated native Shapr3D and the latest dedicated simulator build through Peekaboo after desktop unlock. Confirmed diagonal rectangle first-corner drift on width edit, oblique sketch entry, missing post-draw line readout, keypad obstruction and incomplete three-point dimension presentation. Center width anchoring and circle-at-corner drawing matched in the exercised cases. [Live receipt](testing/sketch-parity-live-2026-09-07.md) separates direct evidence, matches and unresolved investigations. Prioritize the confirmed diagonal-anchor issue; do not label center anchoring universally broken. No source change or new automated test run in this pass.

## Mission log — 2026-09-07, rectangle construction and constraint discoverability

Added center/diagonal/three-point rectangle selection, staged tap/drag construction, anchor/preview/readouts, cancellation, and one-step rectangle undo. Rotated rectangles reuse four ordinary lines with seven internal constraints. Drawing tools now own strokes beginning on existing geometry; disarm for point/entity/gizmo editing. A visible opposite-side constraint rail exposes common relations, prerequisites and settings, with More/compact fallback. Rectangle terminology is expanded from “Rect.”

A small-profile extrusion regression exposed fixed model-unit acquisition floors: outline targets now use 16 screen points and control points 24. This fixes selection acquisition, not snap/grid resolution. New pure tests exercise geometry, solver/Codable preservation and selection across zoom levels. Verification covers 60 distinct tests across the combined run (58 passed, two line-label failures) and the final 9/9 passing correction rerun; see [the second-batch receipt](testing/sketch-parity-rectangles-2026-09-07.md).

Remaining priorities: typed rectangle anchor preservation/two-axis entry; remaining snapping categories/grid behavior; rectangle and edit intent A/B on physical Pencil and mouse; constraint Disconnect; distance/radius preferences and other confirmed dimension gaps. All 42 audit records remain tracked; this mission is not a full parity sign-off.

## Mission log — 2026-09-07, sketch parity foundations

Implemented normal outline selection in model mode (depth-aware; profile interiors remain extrudable), per-annotation selection filtering, persistent snapping preferences, and pending keypad cleanup on tool/selection/exit transitions. Defaults remain both annotation visibility switches OFF; existing grid/guidepoint snaps default ON. Grid-off also disables face-edge quantization and sketch translation capture. Snap acquisition and auto-constraint recording remain distinct.

Final combined verification: **40 unit + 7 UI tests passed, 0 failures**; [receipt](testing/sketch-parity-foundations-2026-09-07.md). See [the implementation ledger](SKETCH_PARITY_IMPLEMENTATION.md) for exact scope and all remaining audit issues. SK-05 is partial: independently configurable guidelines and off-plane 3D guidepoints are not implemented. DM-12 is only partially verified, not a complete keypad/keyboard matrix sign-off.

Existing `SketchToolsUITests` exposed a missing `RedoButton` accessibility identifier (the button was present under label “Redo”); added it alongside the existing Undo identifier to unblock the end-to-end undo/redo/profile regression.

## Mission log — 2026-09-05, sketch dimensions stop vanishing (Shapr3D-measured)

Complaint: "drawing a sketch and dimensions staying visible for the user to
click and edit are missing." Half wrong, and the accurate half was sharper —
worth recording because the wrong half nearly sent the work in the wrong
direction. openshape3d already HAD tappable, editable, expression-aware
dimension badges with red conflict attribution. What it did not have:

- both annotation overlays were gated on `viewModel.mode.isSketching`, so
  every dimension vanished the instant you tapped Exit Sketching;
- `sketchDimensionLabels` / `sketchConstraintGlyphs` each opened with
  `guard let sketch = activeSketch`, so a second sketch's annotations were
  never visible in any mode.

Fixed by `EditorViewModel.annotatedSketches(alwaysShow:)` (active sketch
always; every non-hidden sketch when the setting is on — the active one
included even when hidden, since `openItemSketch` renders it while editing).
The live *candidate* label stays active-sketch-only: it belongs to the
selection. Tapping a badge or glyph from outside its sketch now calls
`openItemSketch` first, because `commitDimensionEdit` and `deleteConstraint`
both require it to be active. New `AppSettings.alwaysShowDimensions` /
`.alwaysShowConstraints` (default ON, read via `object(forKey:)` so an explicit
`false` survives relaunch), surfaced as a Visibility section in
`ConstraintSettingsView` — Shapr3D's "Constraint & Locked Dimension Visibility".
Label text also moved off a hardcoded `"%.2f" + " mm"` onto the existing
`DisplayUnit.compactLengthString`, which matches Shapr3D's trimmed format;
the field is seeded in display units and converted back on commit, EXCEPT for
a formula, whose identifiers resolve against document variables already in
millimetres.

**The reference evidence is reproducible without owning a Shapr3D licence.**
Shapr3D ships screen recordings of its own UI at
`/Applications/Shapr3D.app/Contents/Resources/Tutorials.bundle/Tool/*/video.mp4`,
and its full vocabulary (3,226 keys) in `en.lproj/Localizable.strings` via
`plutil -convert json`. Frames extracted with a small `AVAssetImageGenerator`
tool — the Homebrew `ffmpeg` here is broken (missing `libx265`). Driving
Shapr3D live is NOT possible: UI scripting needs Accessibility and `osascript`
returns `not allowed assistive access (-1719)`. Write-up + screenshots:
`docs/SHAPR3D_SKETCH_PARITY.md`. Historical list (corrected above): G2 (withdrawn: ten-tool evidence came from 2D Drawings), G3 (badge dragging needs sketch-specific verification), G7 (Disconnect, Anchored Sketch Entity),
G8 (spline / sketch-pattern UI).

**On-canvas number pad for dimensions (`NumericKeypad`).** Tapping a dimension
now opens Shapr3D's compact pad rather than the system keyboard: `( )`, the four
operators and `±` (all already parsed by `ExpressionEvaluator`), `mm cm m deg`,
backspace, a lock, and a double-height commit. Wired into the sketch dimension
field only; the component is a text editor over a `Binding<String>` and knows
nothing about sketches, so the other numeric fields can adopt it one line each.

Two real bugs surfaced while building it:

- **A typed unit was decoration.** The evaluator STRIPS a trailing unit before
  parsing, so `20 cm` meant "20 display units". Worse, the suffix is letters, so
  `ExpressionEvaluator.identifiers(in:)` read `cm` as a VARIABLE — which made
  `20 cm` count as a formula, skip conversion entirely, and store `"20 cm"` in
  the dimension's `formula`. Strip the unit before asking what a string
  references.
- **`text.append(x)` through a `Binding` does nothing.** Assignment
  (`text = text + x`) works. Not the cause of the bug below, but a trap worth
  knowing.

**UI-suite regressions after the pad rollout — 1 of 3 fixed, 1 root-caused.**

1. `CylinderGrowShotUITests` — FIXED. It typed into `RadialDiameterField`, which
   after the `ExpressionValueField` migration opens the number pad rather than
   the keyboard ("Neither element nor any descendant has keyboard focus").
   Routed through `replaceText`, which drives whichever input is in front.
2. `ParityWalkthroughUITests.testWalkthrough01SketchTools` — ROOT-CAUSED, not
   fixed. Reduced to `TwoShapeReproUITests.testDrawSwitchToolDrawAgain`: draw a
   shape, switch tool, draw a SECOND shape, and the app leaves the sketch and
   comes back on the project gallery with the document saved. The walkthrough's
   confusing symptom ("Failed to tap SketchGroup") is just
   `tapPaletteTool` falling back to the body-mode group button once the editor
   is gone — SketchGroup does not exist inside a sketch, so a missing EDITOR
   reports as a missing BUTTON. Look there first next time.
   No `.ips`, no fatal line in `simctl spawn … log stream`, process exits
   SIGTERM at teardown — consistent with a Swift trap (this project writes no
   crash report for those) but not proven.
   **Attribution: the uncommitted work causes it.** Clean `HEAD` PASSES
   (`alive-after-shape-2=true`); the working tree fails. Method, since a partial
   stash does not build — `EditorViewModel` carries both the pad work and the
   shell-crash work: park the untracked files that reference uncommitted APIs
   (`NumericKeypad.swift`, `CylinderShellCrashTests`,
   `UnionThenSubtractBugReportTests`, `NumericKeypadTests`,
   `SketchAnnotationVisibilityTests`, `SketchParityStepsUITests`), keep
   `TwoShapeReproUITests` — it depends on nothing uncommitted — then
   `git stash push -- openshape3d/ openshape3dTests/ openshape3dUITests/`.
   Leave `project.pbxproj` alone; the target uses filesystem-synchronized
   groups, so parked files simply drop out of the build.
   **CULPRIT: the pad work, and specifically `SketchDimensionOverlay.swift`.**
   Bisected by splitting `EditorViewModel`'s 27 hunks — the first four belong to
   OTHER uncommitted workstreams (blend face-edge selection, bug e07493b5; and
   the subtract-feedback work, a1ee4e4a), hunks 4-26 are the pad work — then
   reverse-applying only those four alongside `git checkout HEAD` of
   `KernelOps` / `ShellKit` / `Renderer`. Results:

   | tree | repro |
   |---|---|
   | clean `HEAD` | passes |
   | pad work ONLY (other three workstreams reverted) | FAILS |
   | pad work minus `SketchDimensionOverlay.swift` | passes |

   Narrowed further, by bisecting inside the file: my `body` is fine (it passes
   with HEAD's `DimensionField`), and inside `DimensionField` it is specifically
   the **`NumericKeypad` subtree** — delete just that from the VStack and the
   repro passes. Confirmed NOT the cause, each tried and reverted:
   view identity (the field is now hoisted out of `labelView`'s ForEach — a
   good change, kept), the content-vs-mode existence gate (also kept: existence
   now follows the mode, hit-testing follows the content), the model-backed
   text `Binding` (moved back to `@State` — also kept; the swallowed keypad taps
   that originally motivated it were `contentShape`), and the keypad's
   accessibility container.
   The app is genuinely on the GALLERY afterwards (screenshot + `editorChrome`
   false), not a slow-accessibility query artefact, and it exits SIGTERM at
   teardown with no crash report — so hang→watchdog→relaunch.

   **`sample` on the app pid through the failure window shows a UIKit FOCUS
   spin**: `_UIFocusMapSnapshot addRegionsInContainer:` 555 recursive,
   `_UIFocusRegionContainerProxy _searchForFocusRegionsInContext:` 554,
   `_UIFocusRegionSearchContextSearchForFocusRegionsInEnvironment` 544. Capture
   it with: start the test with `nohup`, poll
   `pgrep -f "CoreSimulator/Devices/<UDID>.*openshape3d.app/openshape3d"` for
   the pid, wait ~14 s, then `sample <pid> 10 1 -mayDie -file …`.
   `sample` cannot resolve simulator processes BY NAME — use the pid.

   **But it is NOT the keypad's controls.** Bisected inside the pad: digits-only
   still fails, and replacing `NumericKeypad` with an inert
   `Text(...).frame(width: 250, height: 190)` ALSO fails. So the trigger is the
   card's size/presence as a second child of `DimensionField`'s VStack, not its
   buttons, focus or accessibility. Also ruled out: the field's own focus
   membership (`.focusable(false)` + `.allowsHitTesting(false)` on it — kept
   anyway, it is correct that a pad-backed field is a readout).

   Next line of attack is LAYOUT, not focus: a large `.position`-ed child inside
   the full-screen `.ignoresSafeArea()` overlay. Suspect the card left over from
   the FIRST shape still covering the point where the second stroke starts.
   `TwoShapeReproUITests` and
   `SketchParityStepsUITests.testAnotherToolIsReachableWhileTheValuePadIsOpen`
   are `XCTExpectFailure` so this stays visible without reddening the suite.
   STILL OPEN.

   ⚠️ **`git checkout HEAD -- <file>` on an uncommitted file is destructive** and
   cost the branch's `KernelShellTests` / `BugReportingTests` edits for a while.
   Recovered from a dropped stash via `git fsck --unreachable` (the stash
   commits survive; `git checkout <sha> -- <paths>` pulls them back). Back up to
   the scratchpad BEFORE reverting anything uncommitted — and prefer
   `git stash push -- <paths>` over `checkout`, because a stash is recoverable
   by design.
3. `SweepLoftUITests.testLoftFlowCollectsSectionsAndRejectsCoplanarCommit` —
   untouched. Its assertion ("Tapping another fill should append a loft
   section") is also a SECOND interaction after a first shape, so it may be the
   same underlying fault as (2); check that before treating it as separate.

**FIXED — the second-shape hang was a leftover value card.** The size field a
freshly drawn shape opens (bug report 5ef841c2) survived arming the NEXT tool,
so the next stroke began ON that card — its digit grid covers the middle of the
canvas (x 394-594, y 527-689 at the default zoom) — instead of on the sketch.
The app then spun in UIKit's focus engine and was watchdog-killed back to the
gallery. `startSketch(tool:)` now clears `editingDimension` when switching
tools: reaching for another tool says you are done with that value. Pinned by
`TwoShapeReproUITests`, which now asserts the card and its pad are gone after
the switch.

That also fixed `ParityWalkthroughUITests.testWalkthrough01SketchTools`, so 2 of
the 3 pad-rollout regressions are closed (with `CylinderGrowShotUITests`).
`SweepLoftUITests` still fails BOTH its tests, and it is NOT the annotation
overlays — restricting them to sketch mode changes nothing. `testSweepCircle…`
was already in the original 16, so suspect the other workstreams there.

The bisect that found it is worth repeating: the trigger was NOT the keypad's
buttons, focus or accessibility. Replacing `NumericKeypad` with an inert
`Text(...).frame(width: 250, height: 190)` reproduced it exactly — it was the
card's FOOTPRINT all along, and the focus-engine spin was a symptom of the
stroke landing on it, not the cause.

**KNOWN GAP (new, not a regression):** with "Always Show Dimensions" off — now
the default, matching Shapr3D — selecting a sketch OUTSIDE sketch mode does not
reveal its dimensions, though Shapr3D does. `annotatedSketches` already handles
a sketch with a selected entity, so the missing piece is that a tap outside
sketch mode never reaches `selectedSketchEntityIDs`. Pinned as an
`XCTExpectFailure` in `DimensionUITests.testDimensionFollowsTheSelectionAfterExitingTheSketch`.

**The grid was manufacturing Horizontal constraints.** A line aimed ~1.6° off
horizontal arrived at the auto-constraint engine as EXACTLY 0°, because both
stroke ends are pulled onto the grid first and, zoomed out, one grid step
swallows several degrees. The engine then dutifully recorded a Horizontal
nobody asked for — the "it constrains my lines the moment I draw them"
complaint. Fixed by judging the H/V decision on the AIMED direction (raw start
to raw end, `EditorViewModel.aimedConstraints`, a pure static so it is testable
without a gesture) while leaving the snap itself alone: the grid may still
flatten the geometry, it may not invent a constraint.

**Three paths set `pendingInferredConstraints`, and the gate must be on all
of them.** Gating only `updateSketchStroke` looked like it had no effect,
because `endSketchStroke` re-runs inference at release and overwrites the
result; `commitChainSegment` is the third. That cost several rounds of "the fix
does nothing" — grep the field, do not assume the drag path is the only writer.

**Tolerance 5° → 1°, measured** by driving the real Shapr3D at known angles:
0.57° snapped flat and carried a constraint badge, 1.15° and 1.6° did not.

**Both "Always Show" settings now default OFF**, matching Shapr3D's shipped
Constraint Settings ("Logical constraints and locked dimensions are shown based
on your current selection"). Off is selection-based here, not hidden.

**⚠️ Two "findings" I reported that were my own harness, not the app** — worth
recording because each looked convincing:
- *"A rectangle only shows one dimension."* It shows both; my UI test tapped the
  rectangle's INTERIOR, and `SketchHitTester.nearestEntity` measures distance to
  the OUTLINE, so nothing was selected. Pinned properly now by
  `testSelectedRectangleOffersWidthAndHeight` as pure values.
- *"1.6°/4°/8° are all clean."* Calling `startSketchTool` when the tool is
  already armed TOGGLES IT OFF, so those drags orbited the camera and drew
  nothing. An oblique camera also makes a screen-space angle meaningless on the
  sketch plane — `SketchParityStepsUITests.freshSketch` now asserts
  "Look at Sketch" is gone before drawing.

Parity evidence and method: `docs/SHAPR3D_SKETCH_PARITY.md`. Shapr3D can be
driven directly now (Accessibility granted) — but `System Events click at`
does NOT move the cursor and clicks wherever the pointer happens to be; use a
CGEvent clicker that refuses unless the target app is frontmost and the point is
inside its window.

**Rollout of the pad to the other numeric fields.** Now on: fillet/chamfer and
shell thickness (through the shared `ExpressionValueField`), the extrude arrow
pill, the move-gizmo distance, the extrude `Distance` bar field, and the History
row fields (distance, scalars, pattern count/angle/spacing). Adoption is one
line — `.numericKeypadField(text:onCommit:)`, a `ViewModifier` so each site owns
its own `padOpen` without the call site declaring state.

**A `.popover` will not present from the canvas overlays.** It is the right
shape for a bar or a panel — self-positioning, anchored, dismisses on an outside
tap — but the extrude arrow pill and the move-distance pill floated silently
with no pad (`Neither element nor any descendant has keyboard focus`, because
the test fell through to the typing path). Those now stack the pad under the
field, the way the sketch dimension card already did. Two presentations, chosen
by context.

**Every `value:`-bound bar field migrated to `ExpressionValueField`** (done, same
day): scale factor, rotate-axis angle, revolve angle, pattern count/spacing/
total angle, polygon sides, image size, offset-plane distance, radial diameter,
primitive dimensions, and the helix sheet. `TextField(value:format:)` cannot
take an expression, apply live, or host the pad, so there is now ONE numeric
field in the bars.

That needed `ExpressionValueField.Kind`, because not everything numeric is a
length. `.length` stores millimetres and displays in the user's unit — call
sites bind RAW mm, since wrapping in `unit.binding` (as the old code did) now
converts twice. `.plain` is for values already in the user's terms: an angle, a
count, a scale factor. Int fields bridge through Double and round; their range
moved from the binding's setter into the field's `clamp`.

Behaviour change worth knowing: the helix sheet's Radius and Pitch were bare
numbers that silently meant millimetres, and are now unit-aware like every other
length. Turns stays `.plain`.

NOTE if you go looking for more of these: grepping `TextField(` for `value:` on
the SAME line misclassifies them — the argument is on a later line. I got that
wrong once and reported the opposite of the truth.

**Test note:** `replaceText` in `PullArrowTestSupport` now drives the pad when it
is present and falls back to typing for genuine text fields, so most numeric
tests needed no change. The pad has no `-` key — sign is the `±` toggle, which
on an empty field yields `-`, so the helper maps it. The pad's commit key is
`KeypadCommit` (it is shared; it was `DimensionCommit`).

**⚠️ Gotcha — a SwiftUI Button's hit area is its GLYPH, not its frame.** Every
keypad digit rendered correctly, reported `isEnabled=true`, `isHittable=true`
and a correct 44×36 frame — and swallowed every tap, including taps at explicit
window coordinates. The delete/lock/unit keys worked, which made it look like a
layout or overlap problem; it was not. A `Button` whose label is
`Text(...).frame(w, h).background(...)` is only tappable where the text's ink
is, because `.frame` and `.background` do not extend the content shape. The cure
is `.contentShape(Rectangle())` on the label. The icon keys "worked" only
because an SF Symbol's ink fills more of its frame. Cost about an hour of
bisecting position, ForEach identity, binding semantics and gesture conflicts —
check `contentShape` FIRST when a SwiftUI control renders but will not activate.

**Follow-up pass, same day — three refinements.**

1. **A circle disagreed with itself.** `LiveDimensionKit` draws **Ø** while you
   drag a circle out, but `dimensionCandidate` returned `.radius`, and the badge
   printed the number with no leader at all: Ø40 during the drag, a bare "20 mm"
   on release. A full circle now dimensions as `.diameter`; arcs and polygons
   keep radius. Badges carry `R` / `Ø` from `LiveDimensionKit.Kind.prefix`, the
   same source the live readout uses. `.diameter` was already wired end to end
   (solver residual at `SketchSolverBridge:595`, `dimensionGeometry`,
   `measuredValue`, glyph `⌀`) — only the candidate never chose it.
   `testCircleRadiusDimensionDrivesGeometry` → `testCircleDiameterDimension…`,
   now typing 10 and asserting radius 5 plus a `Ø10 mm` badge.
2. **The off-state was wrong.** Shapr3D's off is
   `"shown based on your current selection"`, not hidden. `annotatedSketches`
   now includes any visible sketch with a selected entity, so turning the
   toggle off no longer costs you the dimensions of the sketch you are
   pointing at.
3. **Constraints default OFF** (dimensions stay ON), and **both overlays gate on
   having content rather than on the mode**. They are full-screen and
   hit-testing; rendering an empty one laid an invisible layer over the viewport
   for taps to land in — the same failure shape as the branch's edge-picking
   cluster, and worth not adding a second source of.

Historical G2–G8 list in `SHAPR3D_SKETCH_PARITY.md`: the ten-tool G2 list is
withdrawn (2D Drawings evidence); use audit DM-03/DM-04 for sketch dimension
choices. G3 needs sketch-specific evidence; G7 and G8 remain in the audit queue. Also unpinned: no test proves a badge does not swallow a viewport tap —
gating on content narrows the window but does not close it.

**⚠️ 16 UI-suite failures are already on this branch, from the UNCOMMITTED
shell-crash work — not from the dimension change.** Full run: 107 tests, 89
passed, 16 failed, 2 skipped. Two clusters: edge picking ("tapping the body
should select an edge" — BlendUITests ×4, BlendEditUITests, FilletLeakUITests,
BooleanFlowUITests, SweepLoftUITests) and "Multiple matching elements found"
(SketchFlowUITests, PlanesUITests ×2, SketchOffsetUITests ×2, SketchToolsUITests,
ViewsUITests, BugHuntUITests). Attribution, established by experiment:

| Tree | Result |
|---|---|
| Clean `HEAD` (everything stashed) | 3/3 sampled tests **pass** |
| Branch, dimension change disabled, simulator app uninstalled first | 3/3 **fail** |

The first attempt at that second row was WRONG and worth remembering: flipping the
code default to `false` changed nothing, because `AppSettings` reads
`object(forKey:)` and the earlier full run had already persisted
`alwaysShowDimensions = true` into the simulator's UserDefaults. `OS3D_RESET_STORE`
clears the SwiftData store, NOT UserDefaults — **`xcrun simctl uninstall` is the
only reliable way to test a defaults-backed setting's default.**

Prime suspect: the uncommitted `EditorViewModel` face/edge boundary work around
`onBoundary` / `KernelOps.distanceToSegment` (~3541), which the `KernelOps`
diff exists to expose (it drops `private`). That is precisely what the fillet /
chamfer edge-selection tests exercise. Not chased further — it is in-flight work,
not this mission's.

**Gotcha — the keyboard has its own "Undo".** `testCircleRadiusDimensionDrivesGeometry`
started failing with "Multiple matching elements found" for `app.buttons["Undo"]`.
Nothing to do with undo: drawing a circle/rect/polygon auto-opens the radius
field (`EditorViewModel`, bug report 5ef841c2), that raises the on-screen
keyboard, and the keyboard's accessory bar contributes a second button labelled
"Undo". Any single-element query on a common label is a race against the
keyboard animation. `setDimension` now uses an already-open field instead of
tapping a label that isn't there, and the undo assertion runs after the commit.

## Mission log — 2026-09-05, first Firebase bug reports triaged (seven from the iPad)

The first real reports arrived through the in-app reporter (Firestore
`bugReports`, all from an iPad Pro on iPadOS 26.5.2, design "Untitled 5",
with `.os3d` attachments). Read them with the REST API and the project's
web API key (`GET …/documents/bugReports?key=…`, attachments via
`firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media`) — which
still works ANONYMOUSLY, i.e. the create-only rules in `docs/BUG_REPORTS.md`
are **still not published**. Do that before the build reaches anyone else.

- **Shell crash (6cb10527) — fixed.** "Creating a cylinder, Modify → Shell,
  tapping the cylinder crashes the app." The attached body was a
  brep-less 48-slice mesh cylinder (a radial push/pull rebuilds it via
  `cylinderAlongAxis`), so the tap ran the MESH shell with the cap open at
  the default 2 mm wall. The old shell was two CSGs — cavity, then a prism
  over the open face inset by the wall — and the prism's wall lay on the
  cavity wall's plane; the BSP left zero-width slivers that
  `makeWatertight` tried to cap with a degenerate triangle (a Euclid
  `assert` in Debug; NaN/trap on the device). Folding the opening into the
  offset solve did not help either (mitred inner vertices sit exactly on
  the fan cap's triangle edges). `KernelOps.shell` now BUILDS the result —
  outer surface + inverted inner surface + a planar rim band per opening —
  with no CSG at all (`ShellKit.swift`). Volumes match the old results
  where the old code worked; two adjacent openings now drop the bar along
  the shared edge (1000 − 8·9·9 = 352 on the 10-cube), which is what OCCT's
  MakeThickSolid produces — `testTwoOpenFacesCutBothWalls` updated.
  Pinned by `CylinderShellCrashTests` (the archived mesh is a fixture,
  `Fixtures/bugreport-6cb10527-cylinder.d3so`; also runs on a 512 KB
  stack). Note for future crashes: the reporter carries no crash log —
  the sim's Debug assert was the only way in. MetricKit crash diagnostics
  attached to the next report would be the real fix for that.
- **Grid vanishes zoomed out (abb6ea37) — fixed.** `gridParams` was a
  fixed 1 mm pitch with a 120 mm fade radius. The pitch now steps by
  decades from the view height at the target (10–100 minor lines on
  screen) and the fade radius follows the camera distance
  (`Renderer.makeFrameUniforms`).
- **Keyboard hides the transform value field (8c98bd3b) — fixed.** The
  move-gizmo field (`MoveDistanceOverlay`), the extrude/push-pull arrow
  field and the sketch dimension field now clamp into the top 42 % of the
  screen while editing, the rule `RotationOrbitOverlay` already had
  (`MoveDistanceOverlay.clearOfKeyboard`).
- **Subtract "doesn't work" after a Union (a1ee4e4a) — feedback added.**
  The attached design shows the union result is one body; tapping "the
  second one" hit the target itself, which was a silent no-op. The Combine
  pick now says so (and that undoing the union separates them), and a
  tool whose bounds never touch the target gets a notice instead of an
  unchanged commit. `UnionThenSubtractBugReportTests` replays every
  pairing of the four archived bodies through the kernel (all fine).
- **Chamfer/fillet by face (e07493b5) — done.** A tap on a flat face well
  clear of every edge (18 pt on screen) selects all the face's boundary
  edges as one unit (`blendFaceEdges`); near an edge it is still that
  edge. A facet of a curved wall (smooth sides) does not count as a face.
- **Typed sketch sizes on lift-off (5ef841c2) — done.** Drawing a circle,
  rectangle or polygon selects it and opens its dimension field
  (`beginDimensionForSelection`), Shapr3D's manual input; a new stroke
  dismisses the field.
- **Flange on a tube (4a7e66e4) — not a bug.** It's a Revolve of an
  L-shaped profile (tube wall + flange) around the tube axis, or Extrude
  the flange ring with Union onto the tube. Worth a tutorial note.
- **Securing the reporter (same day).** Rules now live in the repo —
  `firebase/firestore.rules` (create-only, every field typed and
  size-capped, `hasOnly` on the key set, `attachment.path` pinned to the
  report's own prefix) and `firebase/storage.rules` (one `.os3d` per
  report prefix, ≤ 40 MB, octet-stream) — with `firebase.json`/`.firebaserc`
  so `firebase deploy --only firestore:rules,storage` publishes them.
  Triage moves off the API key to the owner's Google account:
  `scripts/bug_reports.py list|show|fetch|resolve|probe` mints a token with
  `gcloud auth print-access-token` and talks to the REST APIs through IAM,
  which the rules don't gate. `probe` fails loudly while anonymous
  list/read/update still succeed. **Not yet deployed**: both the Firebase
  CLI and gcloud logins on this Mac had expired (`firebase login --reauth`,
  `gcloud auth login`), and both are interactive.

## Mission log — 2026-09-05, full UI suite: green

- After the reorder fix and the simulator reboot: **109 executed, 107
  passed, 2 skipped, 0 failures** in 60 min on `os3d-test` (portrait,
  freshly booted). No known UI-test failures remain on
  `feat/textured-mesh-import`. Unit suite: 1334 green.

## Mission log — 2026-09-05, history drag-reorder fixed (two bugs behind one failing test)

- **Symptom since 2026-09-03:** `HistoryReorderUITests/testDragReorderTwoExtrudes`
  failed at the press-and-drag with "Not hittable: HistoryRow-Extrude".
- **Bug 1 — the long press opened the context menu.** History rows carry
  both `.contextMenu` and `.draggable`; a 1 s press opens the menu before a
  drag lifts, and the retry then found the rows covered. Fix: a reorder
  grip (`line.3.horizontal`, `HistoryDragHandle-<name>`) on each row that
  sits OUTSIDE the content carrying the context menu, so a press there
  always lifts a drag. The row-level draggable stays for finger drags.
- **Bug 2 — a String drop pasted into the Distance field.** With the grip,
  the drag reached the target row, but XCUITest drops at the row's centre,
  which is the Distance text field — and a text field accepts a String
  drop. The feature's UUID was pasted into the field, the test read the
  changed value as "reordered", and its Undo undid the extrude ("1 row").
  A real bug for fingers too. Fix: `AppDragPayload` (typed Transferable,
  custom UTType `com.laan.labs.openshape3d.drag-payload`) is now the
  payload for history rows and Items rows/folders; text fields refuse it
  and the row's `dropDestination` receives it. (Gallery cards still drag
  Strings — no text fields there.)
- Verified by touch (grip drag reorders, one "Reorder Feature" undo step,
  Undo restores both) and by the suite: HistoryReorder, HistoryPanel and
  ItemsFolder UI tests pass. No known UI-test failures remain on the branch.

## Mission log — 2026-09-05, full UI suite on the branch (and a stuck test simulator)

- **Result:** 109 executed, 100 passed, 2 skipped, 7 failed in 65 min on
  `os3d-test`. Six of the seven were NOT the branch: Dimension line-length,
  ParityWalkthrough 11 (dimension editing), both ReplaceFace tests, Section
  via ZX tile, and Planes sketch-on-face all failed deterministically in
  isolation on `os3d-test`, passed unchanged on `os3d-touch`, and passed on
  `os3d-test` after a `simctl shutdown`/`boot`. Its home screen was
  rendering LANDSCAPE in a portrait framebuffer — every precise viewport
  tap (a 2 mm tile, a face, a dimension label, the 4 mm box) landed off
  target while big-target taps kept passing, which is why the failures
  looked like a regression in "taps". `GalleryFolderUITests` had set
  `.landscapeLeft` in `setUp` earlier that day; it is portrait now.
  (`CompactWidthBarUITests` also rotates to landscape, inside one test —
  the suite has survived that before; the reboot is the fix either way.)
- **Still failing at that point:** `HistoryReorderUITests/testDragReorderTwoExtrudes`
  (pre-existing since 2026-09-03; fails on both simulators) — fixed in the
  entry above.
- **Gotcha 56 added below.**

## Mission log — 2026-09-05, Import Units prompt (Shapr3D parity)

- **What landed.** Picking a mesh file (OBJ, STL, glTF/GLB, USDZ, .blend,
  or a zip of them) no longer builds bodies straight away: `MeshUnitPromptSheet`
  ("Import Units") shows the file, its part/triangle count, and the model's
  size under Millimetres / Centimetres / Metres / Inches / Feet, with the
  detected unit preselected and tagged. Import applies the choice. The
  footer says whether the format records a unit (glTF, USD, Blender) or the
  detection is a size guess (OBJ, STL).
- **How.** `MeshImportKit.probe(data:fileName:siblings:)` parses at scale 1
  and returns a `MeshImportProbe` (parts in file units, `detectedScale`,
  `unitIsDeclared`, `sizeDescription(for:)`); `MeshImportKit.scaled(_:by:)`
  applies a unit; `parts(unitScale:)` is now exactly probe + scale, so the
  bridge and every existing caller behave as before. `MeshImportUnit` holds
  the five units (`nearest(toScale:)`, `parse`). `EditorViewModel.probeMesh`
  + `importParts` split the old `importMesh`; the editor's `.stl` and `.mesh`
  picks both route through the prompt (`pendingMeshImport`). A zip's bodies
  keep the archive's name. `/v1/exec document.import` takes `units`
  ("mm"|"cm"|"m"|"in"|"ft") or a numeric `unitScale`; absent → detected.
- **Testing the prompt without a file picker:** DEBUG env
  `OS3D_DEBUG_IMPORT_MESH=<path>` opens the prompt for that file on launch
  (`MeshUnitPromptUITests` writes a 4.7-unit OBJ to its temp dir, picks
  Centimetres, and reads 47.00 × 47.00 × 47.00 mm off the info bar).
  Verified by touch with the LiDAR scan zip: Metres detected, sizes
  previewed per unit, Import → 4746 × 1960 × 2691 mm.
- **Tests.** `MeshUnitPromptTests` (5), `MeshUnitPromptUITests` (1); the
  import suites (MeshImport, BlendImport, HeavyMeshGuard) still pass.

## Mission log — 2026-09-05, LiDAR room-scan import: scale, plane picker, Extrude stall

- **Report:** `Untitled_Scan_11_02_32.zip` (a scanner-app OBJ + JPG, 102 749
  open triangles, 4.75 × 1.96 × 2.72 **metres**) imported "large and hard
  to work with", the sketch plane picker was unusable, and Extrude crashed.
- **What was actually happening.** (1) The OBJ metres heuristic fired only
  under 2 units, so the room came in as a 4.7 mm object with a 0.5 mm grid
  and a camera fitted to a speck. (2) The origin plane tiles were a fixed
  0.3–2.3 mm square: inside the scan and, once the scale is right, a speck
  beside a 4.7 m room. (3) On Extrude, `commitToolResult` intersected the
  tool with EVERY body to decide Auto's union/subtract, judged the scan
  "touched", then unioned the box into the scan and ran `makeWatertight`
  on 100k+ polygons — over a minute on the main thread (sampled:
  `commitExtrude → commitToolResult → Mesh.makeWatertight`), which a
  device's watchdog reports as a crash.
- **Fixes.** OBJ heuristic threshold 2 → 10 units (`MeshImportKit`);
  `PlanePicking.worldTiles(sceneExtent:)` sized from the largest visible
  body (`EditorViewModel.worldPlaneTiles`, 2.3 mm floor so the empty-scene
  UI tests are unchanged); `BooleanCandidacy` (Kernel): mesh-only bodies
  over 50 000 triangles never enter a CSG — Auto builds a new body beside
  them, an explicit Union/Subtract/Intersect aimed at one is refused with a
  message naming the body and its triangle count — plus an AABB gate in the
  commit loop before any CSG. Verified by touch: scan imports at
  4746 × 1960 × 2691 mm, room-sized picker tiles, a 1600 × 1200 × 300 mm
  extrude commits instantly next to the scan. `HeavyMeshGuardTests` (3).
- **Regression check:** ExtrudeFlow, BooleanFlow, FaceFlow, RevolveFlow,
  Planes, Items and SketchEdit UI tests — all green except
  `PlanesUITests/testSketchOnFaceThenExtrudeNewBody`, which fails the same
  way with these changes stashed (the post-delete tap at (0.30, 0.62) no
  longer selects the surviving box) — pre-existing on this branch, not
  from this fix; listed with `HistoryReorderUITests` as a known break.
- **Still open:** booleans *against* a heavy scan (e.g. cutting it) are
  refused rather than slow; a decimate-on-import or an OCCT mesh boolean
  would be the next step. Unit prompt on mesh import (Shapr3D asks) would
  remove the heuristic entirely.

## Mission log — 2026-09-05, in-app bug reporter

- **What landed.** A ladybug button at the right end of the editor toolbar
  (`BugReportButton`; also "Report a Bug…" in the gallery's ⋯ menu) opens
  `BugReportSheet`: summary, what happened, steps, optional email, and in
  the editor a toggle to attach the open design as an `.os3d`. Send writes
  one Firestore document to `bugReports` and the attachment to Cloud
  Storage under `bugReports/<id>/` — through the REST APIs
  (`BugReporting.swift`), **no Firebase SDK, no analytics, nothing sent
  until Send**. The form's footer lists exactly what goes along (app
  version, OS, device model, design name and counts, last undo title).
- **Config is git-ignored.** `openshape3d/GoogleService-Info.plist`
  (API key, project ID, bucket) is in `.gitignore`; copy
  `docs/GoogleService-Info.example.plist` there. Without it the sheet
  shows "not configured" and Send stays disabled. Rules the project needs
  (create-only, size-capped) and the field table: `docs/BUG_REPORTS.md`.
- **Verified end to end** once the owner provisioned Firestore and Storage:
  a report from the simulator landed as a document with context and a
  27 KB `.os3d` in the bucket. **Rules are still wide open** (anonymous
  list/read worked) — the create-only rules in `docs/BUG_REPORTS.md` need
  publishing before anyone else runs the build.
- **Tests.** `BugReportingTests` (4: config parsing incl. placeholder
  rejection, Firestore field shape, attachment path sanitising, server
  message extraction); `BugReportUITests` (opens, validates, cancels — never
  sends).

## Mission log — 2026-09-05, Items Manager folders (spec §11)

- **What landed.** The Items panel has a folder tree above its type
  sections. `ItemFolder {id, name, parentID, members: [DocumentItemKey]}`
  lives on `DesignDocument.itemFolders`; membership is on the folder, so no
  item type's Codable or persistence changed — the tree is one JSON column
  (`Project.itemFoldersData`), pruned of deleted items on save but NOT in
  memory (undo of a delete puts the item back in its folder). `.os3d`
  archives carry it and the duplicate remap rewrites the IDs inside.
  Panel: "New Folder" button (takes the body selection), row menus "Move to
  Folder ▸" (+ "New Folder with Item"), drag rows onto folder rows or onto a
  section header to file them out, folder eye = hide/show the subtree as one
  `CompositeCommand`, inline rename, "New Subfolder", "Remove Folder"
  (contents move up) vs "Delete Folder and Items" (folders + delete
  commands in one composite). Every tree edit is `SetItemFoldersCommand`
  (whole-array before/after — the tree is tiny, and it keeps undo trivial).
  `/v1/state` gained `itemFolders`.
- **Verified by touch** on the iPad simulator: select the seeded body → New
  Folder → "Folder 1 ▸ Drilled"; folder eye → body hidden, undo title
  "Hide Folder"; row menu → Move to Folder ▸ Top Level ("Move out of
  Folder"); relaunch → the folder and membership load back.
- **Not verified by touch: dragging rows inside the panel.** Five synthetic
  touch paths (holds of 420–1000 ms, then a move) all opened the row's
  context menu instead of lifting a drag, for item rows and folder rows
  alike, even after moving `.draggable` onto the inner content beneath the
  `.contextMenu` wrapper (the layout the gallery cards use, where a
  synthetic drag DID move a card). The rows use the same
  `.draggable`/`.dropDestination` API as the gallery; whether a real finger
  lifts a drag in the panel's ScrollView is untested. "Move to Folder" is
  the covered path (UI test + touch).
- **Tests.** `ItemFolderTreeTests` (9), `ItemsFolderUITests` (create, move
  via menu, folder eye, rename, Remove Folder, undo). Unit suite 1322 green.

## Mission log — 2026-09-05, project folders (spec §13.1; Shapr3D 5.492 "Folders are here")

- **What landed.** The gallery organises designs into nested folders:
  `ProjectFolder` (new `@Model`: `folderID`, `name`, `parentID`) plus a
  defaulted `Project.folderID` scalar. Regular widths get a folder sidebar
  ("Designs" root + disclosure tree, drop targets, context menu); every
  width gets breadcrumbs inside a folder, toolbar Back/Forward with ⌘[ / ⌘]
  (`FolderNavigationHistory`), folder cards with "N folders, M designs",
  drag-and-drop of designs AND folders onto cards / sidebar rows / crumbs /
  the empty grid, "Move to Folder…" from the card context menu and a
  Move (n) button in Select mode (`FolderPickerSheet`, disables a moving
  folder's own subtree), "New Folder Inside", rename, and delete with a
  confirmation naming the counts. New designs, archive imports and
  duplicates land in the folder on screen. Verified by touch on the iPad
  simulator against the existing 50-project store (lightweight migration,
  everything at the root) — a card dragged onto a folder card moved.
- **Why scalar IDs, not a relationship.** `ProjectFolder.swift` explains:
  seventeen unit tests build `Schema([Project.self, …])` by hand and a
  `Project → ProjectFolder` relationship would make every one of them fail
  to open a container; a self-referential SwiftData relationship is a
  second thing to fight; and the defaulted-scalar route is the repo's
  proven migration path (see the construction-axes note). The cost is a
  hand-rolled cascade in `delete(folder:)` — `ProjectFolderTree.descendants`
  is the single source of what a folder contains. Orphans (a parent that
  no longer exists) list at the root rather than vanishing.
- **Tests.** `ProjectFolderTreeTests` (8: sorting, paths, descendants, move
  legality, orphan/cycle safety, flattening, unique names, history incl.
  deleted-folder pruning); `GalleryFolderUITests` (create → open → design
  inside → crumbs → Back/Forward → Move to Folder… → nested folder from
  the sidebar → delete with counts). Unit suite 1313/1313 green.
- **Gotcha reminder that bit again (2):** the sidebar row's identifier had
  to go on its select Button, not the HStack around chevron + button.

## Mission log — 2026-09-04/05, fourth session (practice-problem retry round; four kernel/UI fixes; 1298/1298 unit tests green)

- **Kernel crash guard (`OCCTBridge.mm`, "Crash guard").** Sheet 4.7's clevis
  plate: an R2 fillet on the concave arcs where the lug cylinder meets the
  plate's side faces segfaulted inside `ChFi3d_Builder::PerformOneCorner →
  Extrema_ExtCC::Points` and took the app and its unsaved document down. The
  OCCT archive was built with `OCC_CONVERT_SIGNALS`, so the bridge defines it,
  arms `OSD::SetSignal` for the duration of each fillet/chamfer/draft build
  inside `OCC_CATCH_SIGNALS`, and restores the previous signal actions after.
  The fault becomes a `Standard_Failure` from a normal context; ChFi3d's own
  try block catches it and the op reports `partialResult(failed: 2)`. A
  home-made `sigsetjmp` guard was tried first and is the wrong tool: it
  leaves OCCT's `Standard_ErrorHandler` chain dangling and the NEXT kernel
  call dies in `FindHandler` (gotcha 55). Fixture:
  `openshape3dTests/Fixtures/Captures/clevis-lug-junction-fillet-r2`.
- **Cylindrical face draft reached the kernel only on paper.** The point that
  identified the picked face to OCCT was the centroid of ALL side facets —
  on a full cylinder that is on the axis, its radial push-out undefined —
  so every cylindrical draft fell through to the mesh path's "declined"
  error. One facet's centroid, pushed to the true radius, fixes it (Ø40×30
  boss +10° → 28 607.139 mm³, the frustum to 1e-10, brep kept).
- **Shell through a ring face refused.** The open face was handed over by its
  outline centroid, which for an annulus lies in the hole ("no face within
  tolerance of the pick", every Level 13 hub). `FeatureGraph.pointOnPlanarFace`
  (largest facet's centroid) now serves both shell and planar draft; ring
  Ø100/Ø40×20 shelled 3 mm through its top = 42 223.005 mm³ exactly.
- **Touch-pass findings fixed:** edge snaps step 0.5 mm along the edge from
  the nearer corner (`SnapEngine.gridAlongEdge`; a raw 10.025 slide made a
  wall 0.25 % oversize); Top/Bottom views square the azimuth to the nearest
  quadrant (near-vertical it IS the roll — a stray orbit left a plan view
  36° tilted with no way back); the armed profile and every extra region
  tapped into an extrude draw a stronger fill (a second region used to join
  with no visible sign).
- **UI tests re-laid out for full-length drags** (gotcha 54): Blend arrow
  scrub measured from the handle, sweep path lines a grab tolerance clear of
  the circle rim. Suite: 100 pass, 1 pre-existing fail (History drag-reorder).
- **Practice-problem retry round** (`scripts/swpp`, `docs/SWPP_PRACTICE_PROBLEMS.md`):
  eight bridge workers over the deferred list. Highlights: 4.4/4.5/4.7/4.9/
  4.50/4.58/4.60 (all pass, several beating "structural" deferrals by
  pixel-measuring the drawing), 4.11/4.12/4.33/4.36/4.64/4.67, 1.2/1.7/1.8/
  1.10, 2.x, 3.4, 4.1, 7.33/7.42/7.44, 15.2B exact; 13.9A/B built and scored
  as honest fails (the printed numbers sit between two readings). 111 sheets
  had never been downloaded; fetched this session with the user's go-ahead
  (HTTP/1.1 only — the CDN resets HTTP/2 streams) and dispatched.
- **Open kernel findings from the round (not fixed):** (1) lateral profile-
  wall edges (the prism corners parallel to the extrusion) list without a
  mesh-side signature after `feature.extrude`, so `feature.fillet` answers
  `unaddressable_edge` — every "R n TYP" on such a corner needs a sketch
  fillet instead **[stale for sharp corners, 2026-09-16: on `main` a
  bridge fillet on 4.5's two lateral corner edges matches its sketch-fillet
  volume exactly; see that day's Fillet mission log]**; (2) `feature.shell` on the 13.9 hub (`level13._p139_build(60,
  5, do_shell="app")`) succeeds with brep true and a clean check but removes
  517k mm³ where the offset cavity is 286k — the 25-deep front pockets'
  offsets are not honoured **[stale, 2026-09-16: on `main` and on the
  2026-09-05 build this call is refused ("the shelled solid failed validity
  checking"); see that day's Shell mission log]**; (3) a Level 10-13 worker's earlier note that
  `/v1/faces` reports a meaningless normal for cylindrical faces (select by
  `kind`) and `kind: "other"` for conical walls.

## Mission log — 2026-09-04, third session (textured mesh import; exact face draft; 1291/1291 unit tests green)

- **Import OBJ (+MTL/textures), glTF/GLB and USDZ (2026-09-04).** New
  `Kernel/MeshImportKit.swift`: a self-written glTF 2.0 reader (GLB + JSON,
  data: URIs and sibling buffers, node TRS/matrix baked into world space,
  normals computed when a file ships none, PBR base colour + base colour
  texture, KHR specular-glossiness diffuse as fallback), an OBJ reader that
  keeps `vt`, honours `usemtl`/`mtllib` and pulls `map_Kd` images from the
  files that travelled with it, Model I/O for USD (`metersPerUnit` read
  from text layers, USD's cm default otherwise), and a minimal zip reader
  (stored + deflate via Compression) so a downloaded archive can be dropped
  in whole — the `.obj` or `.glb` inside is found and its siblings resolved
  case-insensitively by path, then by bare name. Units: glTF is metres so
  ×1000; USD per `metersPerUnit`; OBJ 1:1. Every part becomes a mesh body
  (pivot at its AABB centre, placement kept in the transform, like STL) in
  ONE undo step (`EditorViewModel.importMesh`). Import menu: "OBJ / glTF /
  USDZ…" (`ImportMesh`); bridge: `POST /v1/exec {"op":"document.import",
  "args":{"path":…}}` reads the file straight off the host, since the
  simulator shares the Mac's file system.
- **Textures render.** `RenderMesh.texcoords` (MeshBlob v2; v1 blobs still
  decode), `BodyMaterialSpec.baseColorTexture` (raw PNG/JPEG bytes,
  persisted by the synthesized Codable), `BodyMaterial.textureData` on the
  drawable, `BodyTextureCache` (MTKTextureLoader, mipmapped, keyed by body
  + mesh revision), `litTextured`/`litTexturedBlended` pipelines and
  `vertex_/fragment_litTextured` in `Shaders.metal` — the texel multiplies
  the base colour and then takes the exact lighting/selection/section path
  `fragment_lit` does, so a textured body highlights and clips like any
  other. UV origins: glTF's is top-left (Metal's too); OBJ and USD `st` are
  bottom-left, so those importers flip v. Verified live: a 40 mm checker
  cube imported from a GLB and from a zipped OBJ+MTL+PNG both render the
  8×8 checker on every face (64 000 mm³, 12 triangles, `textured: 1`).
- **Exact face draft on the B-rep path.** `evalDraftFace` now tries OCCT
  first (`OCCTKernel.draftResult` → `BRepOffsetAPI_DraftAngle`, planar AND
  cylindrical faces, healed + adopted); the mesh shear stays as the
  fallback for non-analytic bodies, and a curved face without a brep gets a
  clear error instead of a silent no-op. Positive angle narrows the body
  away from the neutral plane — `DraftFaceBRepTests` pins the removed
  wedge to ½h²·tanθ·d within 1e-3 and checks the hinge edge stays put.
  This is what the Level 12/13 casting sheets were deferred on.
- **Tests:** `MeshImportTests` (12: GLB round trip through `GLBExporter`,
  default m→mm, hand-built textured GLB with node transform, .gltf with a
  data: URI, zipped OBJ+MTL+PNG with a deflated entry, OBJ without MTL, zip
  without a model refused, usda + usdz through Model I/O, `metersPerUnit`
  parsing, MeshBlob v2). Full unit suite 1291/1291 on os3d-unit.
- **Blender files import too (2026-09-05, `Kernel/BlendImporter.swift`).**
  A .blend is a memory dump described by its own DNA1 catalogue; the reader
  parses that catalogue and reads every field by name at the offset it
  gives, so one reader spans versions: uncompressed and gzip files, 32/64-
  bit, either endianness; mesh objects via MVert/MPoly/MLoop (2.63–3.4) or
  the "position" / ".corner_vert" / poly_offset_indices layers (3.5+); UVs
  from `mloopuv`, a CD_MLOOPUV or a CD_PROP_FLOAT2 layer; one part per
  material slot with the slot's viewport colour and a base-colour image
  from a 2.7x texture slot or a 2.8+ Image Texture node (packed in the
  file, or beside it). Z-up metres → Y-up mm. zstd-compressed saves
  (Blender 3.0+ "Compress") are refused with a message — no zstd on iOS.
  Checked against Sketchfab's own glTF conversions of two Blender 2.78 CAD
  uploads (day16: 27 450 triangles, 6000 × 6000 × 9381 mm; day50: 1 482
  triangles with its packed base colour): identical to 0.01 mm.
  `BlendImportTests` builds a synthetic .blend (DNA and all) to pin the
  axis swap, UV flip, packed image and gzip path.
- **Loose OBJ/glTF/.blend paths pick up their folder** over the bridge
  (`MeshImportKit.folderSiblings`), so an .obj finds its .mtl; and an OBJ
  whose whole model is under 10 units across is taken as metres (×1000;
  was 2 until a 4.7 m LiDAR room scan came in as 4.7 mm, 2026-09-05) —
  Sketchfab's Case_for_Tools came in at 0.34 mm otherwise; now 337 mm, 27
  material parts, 115 248 triangles. Unnamed OBJ groups take the file's
  name ("Case (App0)").
- **Verified on the real thing (2026-09-05):** the Sketchfab "Mechanical
  CAD Model Showcase" (CC-BY, devkrsm; the user downloaded it, since the
  site needs a login) imports from all three of its downloads — GLB, the
  zipped glTF+BIN+PNG, and USDZ — as the same 7 parts, 11 166 triangles
  (the published face count), 348.66 × 164.16 × 211.04 mm, 266 240 mm³,
  with the SteelCast base-colour texture on the clamp frame ("Heavy Duty /
  Steel Screw Clamp" lettering renders) and `/v1/check` clean on all 7.

## Mission log — 2026-09-04, second session (UI-driven practice-problem pass; 1279/1279 unit tests green)

- **SOLIDWORKS practice problems THROUGH THE UI (2026-09-04).** Goal: complete
  the practice-problem sheets using the app's own interface and fix what
  breaks. Two full sheets were built by touch on the iPad Pro simulator with
  nothing but the palette — **1.1** (72,593.275 vs 72,593: rect + typed
  dimensions, extrude, a face-sketched Ø12 cut, a tap-to-place stepped
  tower unioned) and **4.38** (151,817.766, the same −0.30 % reading as the
  bridge recipe: an L-profile polyline, R23/R9 fillets picked by tapping
  edges, through hole, counterbore, notch and a cross hole on the leg) —
  every stage checked against a closed form over the bridge. In parallel
  three runner workers on their own simulators (ports 8901–8903) read and
  built the untouched sheets through the palette-equivalent bridge ops:
  the ledger went from 68 attempted / 60 pass to **115 attempted / 102
  pass** (Level 4: 10 → 32 attempted, Level 7: 6 → 23, plus 1.13, 1.15,
  10.8A, 14.1/14.3, 15.1's three configurations), with 130 sheets deferred
  for a written reason each. **Seven app errors found by the touch pass,
  all fixed the same day** (gotchas 43–50): (1) every drag stroke anchored
  at the pan recognizer's `.began` location, ~10 pt past the touch-down
  (`ViewportGestureController` now captures the touch in `shouldReceive`);
  (2) Result = Union of a boss flush on a face produced a SECOND body
  (`commitToolResult` accepts contact for an explicit union); (3) Zoom to
  Fit ignored sketches and reset to the default camera
  (`ViewportScene.worldBounds` folds the sketch batches in); (4) a Line
  tap-chain kept its pre-solve anchor, so an inferred constraint left the
  polyline open (`refreshChainAnchors`); (5) equal-length inference at 3 %
  pulled a 96/98 profile off its grid — now capped at the snap tolerance;
  (6) the fillet/chamfer/shell value fields were formatted numeric fields
  that could not take an expression and flushed only on Return, so "type
  23, Apply" blended at 1 mm (`ExpressionValueField`, applied live); (7)
  the runner relaunched every simulator's app onto port 8899. Bridge gains
  for driving: `GET /v1/sketches` (every sketch's plane + entities) and
  `GET /v1/project` (world → viewport points, so taps are aimed from
  geometry instead of screenshots). Also landed: `Profile.interiorPoint`
  (a ref's seed is now a point INSIDE the region, and `resolveProfile`
  lets the seed decide between id matches). Kernel finding from the
  workers: an R6 fillet running out onto a tangent face (4.57) is refused
  with "failed validity checking" — the one sheet that failed for a
  kernel reason. One unexplained one-off: a touch-committed counterbore
  once came back as a mesh-only body of half the volume with the feature
  count unchanged; the identical gesture sequence a few minutes later was
  exact, and the bridge's node is exact — recorded, not reproduced.

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
  two adjacent face normals + convexity, decided from the triangle winding);
  `selectableEdges(from:)` welds positions and merges TOUCHING collinear
  same-face-pair creases into maximal straight edges; `signature(of:)` / `resolve(_:in:sizeScale:)` re-find an edge after a
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
| `OS3D_FRESH_NAME` | With `OS3D_FRESH`: title that document (staged screenshots show "Motorcycle Wheel", not "Untitled 64") |
| `OS3D_AUTO_OPEN` | Open the most recent document straight away |
| `OS3D_DEBUG_SEED` | Seed a 4 mm box, **selected** (`.editingPrimitive`) — the fastest way to a live move gizmo |
| `OS3D_DEBUG_SEED_CYLINDER` | Circle extrude via OCCT (a TRUE smooth cylinder), `brep` and all — it calls `adoptBRep` exactly like `evalExtrude` |
| `OS3D_DEBUG_SEED_BOOLEAN` | Cylinder − cylinder, staying round through the brep path |
| `OS3D_DEBUG_SEED_HOLE` | 10×10×6 box with a Ø4 through-hole (524.60 mm³ B-rep-exact; the mesh read 524.62 before 2026-09-02) — the only seed with a CYLINDRICAL face, so the one Delete Face needs |
| `OS3D_DEBUG_SEED_STEP` | Stepped block, low half to y=6 and high half to y=12 (1800 mm³) — two PARALLEL faces at different heights, which is the pair Replace Face needs and no single-box seed can offer |
| `OS3D_DEBUG_SEED_PRIMBOOL` | Cylinder primitive − box primitive (mixed analytic boolean) |
| `OS3D_DEBUG_SEED_IMAGE` | Reference image on the ground plane, left unselected |
| `OS3D_GIZMO_DEBUG` | Print the gizmo part each drag grabs, its world delta, and the rotation pill's live value |
| `OS3D_DEBUG_IMPORT_MESH=<path>` | Open the Import Units prompt for that mesh file once the editor appears (the UI suite's stand-in for the file picker). |
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

43. **A drag's anchor was the pan recognizer's `.began` location, not the
    touch-down** (fixed 2026-09-04): UIPanGestureRecognizer begins ~10 pt
    into the movement, so a circle's centre or a rectangle's corner landed a
    grid step downstream of the finger. `ViewportGestureController` now
    records the touch in `shouldReceive` and starts the drag there.
44. **Result = Union with a FLUSH boss made a second body** (fixed): the
    "touch" test demanded overlap volume even for an explicit union.
45. **Zoom to Fit framed bodies only** (fixed): with a sketch and no body
    the camera fell back to the default isometric view.
46. **Line tap-chains anchored on the pre-solve point** (fixed): an
    inferred constraint solved right after each segment can move its end;
    `refreshChainAnchors` re-reads the committed geometry.
47. **Equal-length inference at 3 % relative** moved a whole polyline off
    grid (96 vs 98 qualified); now also capped at `SnapEngine.pointTolerance`.
48. **Blend/shell value fields were formatted numerics** (fixed): no
    expressions, flushed on Return only, and a centre tap put the caret
    BEFORE the value. `ExpressionValueField` applies live; still tap the
    field's right edge so typed text appends.
49. **`kit.relaunch_fresh` hard-coded port 8899** (fixed): a second
    simulator's relaunched app failed to bind and came up bridge-less.
50. Origin plane picker tiles scale with the scene — outer edge 60 % of the
    largest visible body extent, 2.3 mm floor (`PlanePicking.worldTiles(sceneExtent:)`,
    fixed 2 × 2 mm before 2026-09-05);
    a face sketch's plane origin is the face centroid; a hidden (consumed)
    sketch cannot be tapped for Extrude until the Items panel shows it. All
    three cost screenshots — `docs/TOUCH_DRIVING_PLAYBOOK.md` has the moves.
51. **`USDZExporter.usdz` returns nil on the simulator** (Model I/O has no
    USD writer there), so a USDZ round-trip test is impossible; test USD
    IMPORT with a hand-written `.usda` layer (it reads `.usda`, `.usdc` and
    `.usdz` fine, and even a stored zip of a usda passes as usdz).
52. **UV origins differ per format**: glTF (0,0) is the image's top-left,
    same as Metal; OBJ `vt` and USD `st` are bottom-left. Forgetting the
    flip renders the texture upside-down with no other symptom.
53. **`/v1/exec` arguments go under `"args"`** — `{"op":…, "path":…}` is
    answered with `missing_path`, which reads like a parser bug.
54. **XCUITest drags used to be short-changed.** A synthetic
    `press(thenDragTo:)` moves fast, so the one-finger pan recognizer's
    `.began` location was well ALONG the stroke, and every UI-test circle,
    rect and pull-arrow scrub was shorter than the coordinates asked for.
    Since the touch-down capture (2026-09-04) strokes run their full
    length: a circle that now reaches the next stroke's start gets RESIZED
    by it (entity grab tolerance ≈0.5 mm ≈ 45 pt zoomed in — that was
    `SweepLoftUITests`), and an arrow scrub that used to move 0.5 mm moves
    the whole 2.3 mm (`BlendUITests`). Measure test drags from the handle
    with `withOffset`, keep them short, and keep strokes a full grab
    tolerance apart.
55. **Never `siglongjmp` out of OCCT.** A fault inside the kernel cannot be
    caught in C++; a sigsetjmp guard that jumps back over OCCT frames leaves
    the `Standard_ErrorHandler` chain (`OCC_CATCH_SIGNALS` objects on the
    unwound stack) dangling, and the next kernel call segfaults in
    `Standard_ErrorHandler::FindHandler`. Use OCCT's own conversion:
    `#define OCC_CONVERT_SIGNALS`, `OSD::SetSignal`, `OCC_CATCH_SIGNALS`
    inside the try — that is what `OS3D_GUARDED` in `OCCTBridge.mm` does,
    and it restores the previous signal actions on the way out so Swift
    traps elsewhere still crash the way they always did.


---
56. **A UI-test simulator can get stuck rotated.** Symptom: a handful of
    precise viewport taps (plane tiles, faces, dimension labels, a 4 mm box)
    fail deterministically while big-target taps pass, and the same tests
    pass on another simulator. `simctl io <udid> screenshot` shows a
    landscape home screen in a portrait image. Fix: `xcrun simctl shutdown`
    + `boot` that simulator. Prevention: keep `XCUIDevice.shared.orientation
    = .portrait` in `setUp`; a test that must rotate should rotate back in
    `tearDown`. Cost 2026-09-05: an hour of bisecting the branch for a
    "tap regression" that was the device.
57. **A switch in a sheet parked at a medium stop it can still resize from
    drops taps** (2026-09-15). With `[.medium, .large]` at medium, `Toggle`
    taps never reached the binding: 17 of 60 on one switch and 3 of 30 on
    another, in streaks, at the top of the sheet as well as at its bottom
    edge. Menus, buttons, list rows, a colour well and a segmented control
    in the same sheets lost none, and so did the switches in one-stop
    `[.medium]` sheets. Put switches in a sheet that opens full height (no
    detents, as #40 did) or has a single stop. Re-measure with
    `SheetDetentTapUITests` (`TEST_RUNNER_OS3D_SHEET_PROBE=1`). When
    probing a medium sheet from a UI test, tap window coordinates: an
    element tap can scroll, a scroll expands the sheet, and an expanded
    sheet hides the bug. **Measured on iPads only:** on the iPhone 17 Pro
    Max simulator the same constraint sheet with `[.medium, .large]` lost
    0 of 75 switch taps at its medium stop (2026-09-16). There the medium
    stop is an edge-attached half sheet (grabber "Half"), not the iPad's
    centred card (grabber "Collapsed").
58. **A toolbar item that folds into the "…" overflow needs a `Text` in
    its label, and a `Label` cannot carry a 44 pt target** (2026-09-16).
    Each overflow row is built from a `Text` in the item's label. An item
    with none (an `Image` with only `.accessibilityLabel`) silently
    disappears from the menu. In the bar, every `Label` variant tried
    renders as a native 41.5 pt item: an outer 44 pt `.frame`, a
    `Color.clear` backing, a custom `LabelStyle`, a 44 pt `ZStack` as the
    icon. A custom view (the `ZStack` itself) keeps its 58 pt. An item that
    needs both is the custom view plus a hidden `Text`, as `SettingsButton`
    is. **Do not branch on `horizontalSizeClass`:** the bar folds whenever
    it runs out of room, and the iPad mini in portrait (744 pt) is regular
    width and folds. In UI tests, find an overflow row by its title: the
    row does not keep the toolbar item's `accessibilityIdentifier`, so
    `app.buttons["SettingsButton"]` finds nothing even with the row on
    screen.

59. **OCCT's offset refuses a fillet's C0 B-spline faces** (2026-09-16).
    A blend over several support faces comes back as a B-spline face with
    C0 knots, and `BRepOffset` fails any shell or offset of that body with
    `C0Geometry` before it tries a join. Both shell branches split at
    those knots and retry (`OS3DSplitAtC0`). Anything new that offsets a
    filleted body (a thicken, an offset face) needs the same split. Do not repair
    the split body's SameRange flags with `ShapeFix`: it rebuilds every
    face and the ancestry goes with them.

60. **`Generated()` is not a per-edge success signal for a fillet**
    (2026-09-16). ChFi3d credits a tangent chain's blend faces to some of
    its edges only; a blended edge can generate nothing. Ask
    `OS3DEdgeBlended` instead (generated faces, or gone from the result with
    no modified image). Anything new that judges a blend per edge (history,
    element naming, a partial-result report) must not count on each edge
    naming its own faces.

61. **`ShapeUpgrade_UnifySameDomain` changes the shape you give it** (2026-09-17).
    Merging same-domain faces rewrites edges of its input in place, even in
    safe-input mode, and it can leave an invalid result without merging
    anything. A boolean result shares its untouched sub-shapes with the
    operands, so merging it in place can corrupt a stored body. Merge a
    copy (`BRepBuilderAPI_Copy`, topology only) and check the merged
    result, as `booleanOfShape:` does. The public `unifiedShape:` still
    merges in place; its only caller is the `OS3D_DEBUG_SEED_STEP` seed, on
    a fresh fuse that nothing else holds. Any new caller on a stored body
    needs a copy first.

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

### 4c. SOLIDWORKS practice-problem campaign — IN PROGRESS (2026-09-05)

The 365-sheet practice database at solidworks.com/solution/education/
practice-problems, every sheet printing the finished part's volume, used as
an outside-in parity harness: read the drawing, build it, score the body's
volume against the printed number to 0.5 %.

**Re-verified 2026-09-16** on `main` (5e0f9c3): all 202 rerun, 170 still pass, the same sheets (mission log, 2026-09-16). **Where it stands (2026-09-05, small hours).** 202 sheets attempted, 170 pass (114 within 0.01 %), 32 fail — every fail a drawing that admits two readings whose printed volume picks the one not drawn (the notes name the reading that WOULD hit the number and the view it contradicts), or a blend the kernel refuses (4.57; 4.7's lug arcs now a typed refusal via the crash guard); none a wrong volume from a correct feature. 155 sheets carry a written reason in `scripts/swpp/deferred.json`: 83 readable-but-not-reached (the best next picks are named), 22 undimensioned to 0.5 %, 31 packages the database no longer serves (404 — assembly / START-part exercises), 11 assemblies or centre-of-mass studies, 6 needing an unsupplied parent part, 2 needing a normal-to-profile loft. Four sheets (1.1, 1.9, 2.13, 4.38) were built entirely BY TOUCH; `docs/TOUCH_DRIVING_PLAYBOOK.md` is how. Resume by dispatching bridge workers over `deferred.json`'s "readable" entries with `scripts/swpp/run.py` (see the worker brief pattern in the 2026-09-04/05 mission log).

| Level | Title | Sheets | Attempted | Pass |
|---|---|---|---|---|
| 1 | Basic Sketch & Extrusion | 20 | 16 | 14 |
| 2 | Sketch Tools & End Conditions | 20 | 9 | 8 |
| 3 | Global Variables & Sketch Patterns | 8 | 6 | 6 |
| 4 | Extrude Cut & Fillet/Chamfer | 70 | 32 | 28 |
| 5 | Reference Geometry | 15 | 6 | 6 |
| 6 | Revolve Boss/Cut | 20 | 7 | 5 |
| 7 | Feature Patterning | 48 | 24 | 21 |
| 8 | Sweep Boss/Cut | 14 | 3 | 3 |
| 10 | CSWA Exam Level | 19 | 1 | 1 |
| 11 | Hole Wizard | 12 | 3 | 3 |
| 14 | Rib | 9 | 3 | 2 |
| 15 | Configurations, Design Tables, Suppress | 16 | 1 | 1 |
| 16 | Global Variables, Equations, Link Values | 7 | 4 | 4 |
