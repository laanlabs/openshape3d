# Kernel debug tooling — how to chase a complex-geometry bug

Written 2026-08-31, out of the FreeCAD-mining pass that produced playbook rows
D1–D3. The trigger was a pattern: every attempt to rebuild a non-trivial model
(the reference tutorial models, NEXT §4b) surfaces a kernel bug, and each bug
then cost a hand-built reproduction. This doc is (1) the debugging loop the
new tooling enables, (2) what each piece is, (3) the FreeCAD findings worth
keeping that did NOT become code.

## 1. The loop

**An op fails while modeling** (live tool or feature replay):

1. It already left a bundle behind — `KernelCapture` hooks every
   `OCCTKernel.*Result` failure path and writes
   `Documents/KernelCaptures/<stamp>-<op>-<id>/` (input `.brep`s +
   `manifest.json` with op, params, typed error, per-input health).
   DEBUG-only, on by default in the app, `OS3D_KERNEL_CAPTURE=0` to disable.
2. Pull it: `scripts/fetch_captures.sh` (booted simulator → `./captures`).
3. Reproduce offline: `KernelCaptureReplay.replay(bundleAt:)` runs the bundle
   through the same kernel entry points. Same typed failure, no app, no UI.
4. Fix the kernel.
5. Keep it fixed: copy the bundle into `openshape3dTests/Fixtures/Captures/`,
   add `"expect": {"outcome": "success", "volumeMM3": …}` (or whatever the fix
   promises) to its manifest — `KernelCaptureReplayTests` now pins it forever.

**The op succeeded but the geometry looks wrong**:

1. `GET /v1/check?bop=1` — the deep health report, per body: named
   per-subshape faults ("Face3: notClosed"), tolerance min/avg/max, free
   boundary loops, sub-shape counts, volume, and (with `bop=1`) OCCT's
   self-intersection/small-edge analyzer. `invalid` in the summary is the
   fast read. A mesh-only body reports `meshOnly` — the analytic path was
   lost somewhere upstream, which is its own finding.
2. `GET /v1/state` now carries `evalErrors` (feature name + error per failing
   node), so a driving session sees WHICH feature broke without exec replies.
3. `POST /v1/capture` snapshots every analytic body into a bundle (same
   format) for offline inspection — replaying a snapshot health-checks each
   captured body.

In tests, assert health directly: `OCCTKernel.healthReport(for:)` returns a
typed `ShapeHealth` (`ShapeHealthTests` shows the idiom). For "is the result
sick", prefer it over eyeballing — `findingsSummary` is the message.

## 2. What each piece is

| Piece | Where | Notes |
|---|---|---|
| Health report | `OCCTBridge.healthReportForShape:runBOPCheck:` → `ShapeHealth` | FreeCAD's Check Geometry re-derived over public OCCT APIs (playbook D1). BOP check only runs on a BRepCheck-clean shape (advisory + slow), on a copy, under the 5 s kernel deadline. Findings capped at 200. Judges the geometry, not the render mesh `adoptBRep` stores in the shape: it checks a mesh-free copy, the same as every validity gate in the bridge (`OS3DIsValid`, 2026-09-16), because BRepMesh can store a triangulation BRepCheck rejects (`invalidPolygonOnTriangulation`) on a sound solid. |
| Invalid-shape factory | `OCCTBridge.debugInvalidOpenBox(withSize:)` | DEBUG-only; a box missing one face wrapped as a solid — the only way tests can exercise the findings path, since every public op validates. |
| Failure capture | `KernelCapture` (`Kernel/OCCT/KernelCapture.swift`) | Hooked in `OCCTKernel.booleanResult/filletResult/chamferResult/shellResult/removingFacesResult`. Off under XCTest by default (the suite exercises failures on purpose); `forceEnabledForTesting` for capture tests. Keeps newest 20. |
| Replay | `KernelCaptureReplay` | Loads inputs via `rawShapeFromSerialized:` — deadline + NaN gates but NO heal, so the op sees exactly the failing bytes (`shapeFromSerialized:` would repair or refuse them). |
| Fixtures | `openshape3dTests/Fixtures/Captures/` | Read via `#filePath` off the host FS (simulator tests share it). EXCLUDED from the test target in the pbxproj: synchronized groups flat-copy resources, and two `manifest.json`s break the build with "Multiple commands produce…" — measured. |
| Agent endpoints | `GET /v1/check`, `POST /v1/capture`, `evalErrors` in `/v1/state` | `docs/AGENT_CONTROL.md`. |
| Fetch | `scripts/fetch_captures.sh` | `simctl get_app_container booted … data` + copy. |

Seed fixture: `overradius-fillet-d10-rim` — a 6 mm fillet on a Ø10 rim must
fail typed (never crash, never return a partial build). It doubles as the
worked example of the bundle format.

## 3. FreeCAD findings kept for later (patterns, not code — LGPL rules in the playbook)

- **Signal→exception bridging** (`Part::SignalException`, main branch,
  `src/Mod/Part/App/SignalException.cpp`): converts SIGSEGV inside an OCCT op
  into a catchable exception plus a stacktrace, so a kernel crash becomes a
  per-feature error and the app survives. Linux/GCC-specific as written;
  worth a design pass of its own if simulator crashes inside OCCT start
  costing sessions. Not ported.
- **OCCT message routing** (`OCCTMessagePrinter`, main branch): a
  `Message_Printer` subclass registered on `Message::DefaultMessenger()`
  forwarding kernel warnings into the app log. Our bridge currently discards
  OCCT chatter; if a bug ever hinges on a kernel warning, this is the ~40-line
  pattern to add and the capture manifest is where its tail belongs.
- **DRAW round-tripping**: every capture `.brep` is standard OCCT text — it
  loads in an OCCT DRAW harness (`readbrep f shape` / `checkshape` /
  `tolerance`) for kernel-level triage outside the app entirely. FreeCAD's
  `data/tests/ModelRefineTests/log.txt` is the worked example of that loop.
- **Post-op auto-check policy** (`CheckModel` pref): FreeCAD re-runs
  `BRepCheck_Analyzer` on every boolean result and ABORTS the feature on
  failure. We already do stronger (heal-and-validate inside the bridge, I2),
  so this landed as "nothing to do" — recorded so nobody re-mines it.
- **Recompute-log persistence**: FreeCAD saves per-object error strings INTO
  the document and restores them on load. Our `refreshEvalErrors()` replays
  errors-only on load instead (S3) — equivalent outcome, different mechanism.

## 3b. When the app wedges at 99% CPU: SAMPLE it, don't theorize

`/v1/health` still answering while everything else hangs means the MainActor
is spinning (health serves off the listener queue by design). The Motorcycle-
cover rebuild produced exactly that, and two rounds of plausible kernel-side
fixes (op deadlines — kept, they close a real gap) did not move it, because
the spin was never in the kernel:

```bash
sample $(pgrep -f "openshape3d.app/openshape3d" | head -1) 2 | sed -n '/Call graph/,/^$/p' | head -50
```

named the exact frame in one step: `SignatureNaming.propagate`, quadratic
over a tangent-fuse's sliver tessellation. One `sample` beats an afternoon of
theory — same lesson as the gizmo-debug print, one level lower. Also learned:
a HANG evades failure capture entirely (nothing returns), which is why
constructive builders now run under `kOS3DOpDeadlineSeconds` and quadratic
naming passes under `SignatureNaming.propagateBudget`.

## 4. Machine notes that bit during this pass

- Port 8787 can be occupied by an unrelated local service (on this machine: a
  photogrammetry processor). The app then binds IPv6 only and `curl
  127.0.0.1:8787` answers from the WRONG server — the tell was
  `Server: BaseHTTP/Python` in `curl -v`. Launch with
  `SIMCTL_CHILD_OS3D_AGENT_PORT=8899` and probe `lsof -nP -iTCP:8787` before
  blaming the bridge.
- `xcode-select` pointing at CommandLineTools makes every `xcrun simctl` fail;
  scripts now fall back to `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
