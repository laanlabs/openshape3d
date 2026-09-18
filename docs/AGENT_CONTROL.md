# Driving openshape3d from Claude

A loopback HTTP channel that lets an AI assistant on the same computer inspect
and build in the running app. Until 2026-09-17 it was DEBUG-only; it now ships,
**off by default**, so that someone who installed the app from the store can
ask Claude or ChatGPT for a part (`docs/AI_MODELING_SETUP.md`).

| Client | Integration | Why |
|---|---|---|
| **Claude Desktop** (store users) | `integrations/claude-desktop/` → `OpenShape3D.mcpb`, handed out by Settings ▸ AI Assistant | One click to install; a stdio↔HTTP relay to the app's own `/mcp`, no dependencies |
| **ChatGPT/Codex, any HTTP MCP client** | the app's `POST /mcp` (`AgentMCP.swift`) | An address and a bearer token; nothing to install |
| **Claude Code** | `.claude/skills/drive-openshape3d/` (run it) + `.claude/skills/model-openshape3d/` (model with it) | It has a shell, so `curl` is a complete client |
| **Developers without a store build** | `scripts/mcp_openshape3d.py` | stdlib Python MCP server over the REST endpoints |

Every dialect ends in the same place — `AgentRouter.route` — so they cannot
drift apart. The tool list (`Agent/MCPTools.json`) and the modelling guide
(`.claude/skills/model-openshape3d/SKILL.md`) have one source each;
`scripts/sync_ai_resources.py --check` fails when a copy is stale.

## Safety posture

- **Off until a person turns it on**: Settings ▸ AI Assistant
  (`AIControl`). That switch is the only way a Release build ever listens.
  DEBUG builds also honour a developer's `OS3D_AGENT=1`.
- **Loopback only**, enforced twice: `requiredInterfaceType = .loopback` on
  the listener, plus a peer check in `accept(_:)` that drops any non-loopback
  address.
- **Paired**: a channel a person opened answers only callers presenting that
  installation's pairing code (`Authorization: Bearer …`; 100 random bits,
  Keychain). `/v1/health` alone answers without it, and then says only
  `{"app":"openshape3d","pairing":"required"}` so a client can find the port.
  A developer's `OS3D_AGENT=1` launch has no code — it is their own flag, on a
  build that never ships.
- **No browsers**: any request with an `Origin` header is refused (every
  cross-site request that can change something carries one), and a `Host`
  that is not a loopback name is refused (DNS rebinding).
- **Small surface in Release**: `/v1/capture` and the `document.import` exec
  op — the two that touch the file system on the caller's say-so — are
  `developer_only` outside DEBUG. MCP exports are written by the app into
  Downloads under a sanitized name and never overwrite.
- Sandbox: `ENABLE_INCOMING_NETWORK_CONNECTIONS` and
  `ENABLE_FILE_ACCESS_DOWNLOADS_FOLDER` on both configurations. The app has no
  network-client entitlement and makes no outbound connection for any of this.

## Files

| File | Role |
|---|---|
| `openshape3d/Agent/AIControl.swift` | The person's switch, the pairing code (Keychain), the Downloads writer |
| `openshape3d/Agent/AgentMCP.swift` | MCP at `POST /mcp`: handshake, tool list, tool → REST request → tool result |
| `openshape3d/Agent/AgentServer.swift` | The socket. `NWListener`, port fallback, loopback enforcement, response writing |
| `openshape3d/Agent/AgentHTTP.swift` | Framing: incremental request parser, `Content-Length` bodies |
| `openshape3d/Agent/AgentRouter.swift` | Routing and every reply that needs no editor |
| `openshape3d/Agent/AgentBridge.swift` | The `@MainActor` hop; holds the live `EditorViewModel` weakly |

The split exists so the parts worth testing are testable. `AgentHTTPTests` and
`AgentRouterTests` cover framing and routing as pure values, with no sockets and
no `EditorViewModel` — which the unit suite cannot instantiate anyway, since an
in-process `ModelContainer` crashes XCTest (STATUS gotcha 1). What is left
untested is the socket and the hop, both of which are thin.

## Launching

### iOS Simulator

The simulator shares the Mac's network stack, so the app's loopback is yours —
nothing to forward.

```bash
SIMCTL_CHILD_OS3D_AGENT=1 SIMCTL_CHILD_OS3D_FRESH=1 \
  xcrun simctl launch 69DB84F4-607C-46F2-9089-3E8C0770B4A9 com.laan.labs.openshape3d
```

Do not use `--console-pty &` from an agent tool call: when the call ends its
process group dies, the pty closes, and the app goes with it. A plain
`simctl launch` survives. `/v1/state` is a better diagnostic than the console.

### Mac Catalyst

```bash
launchctl setenv OS3D_AGENT 1 && open /path/to/openshape3d.app && launchctl unsetenv OS3D_AGENT
```

Must go through LaunchServices. Exec'ing the binary directly gives no
entitlement context, `listen()` silently no-ops, and the listener still reports
`.ready`. Diagnostic: `lsof -nP -iTCP -a -p <pid>` shows `(CLOSED)`.

### Physical iPad

The device's loopback is not the Mac's. Forward over USB:

```bash
brew install libimobiledevice
iproxy 8787 8787 &
```

`usbmuxd` connects to `127.0.0.1` **on the device**, so the app's loopback-only
posture is preserved end to end. `xcrun devicectl` has no port-forward verb. Set
`OS3D_AGENT` in the scheme environment — there is no `SIMCTL_CHILD_` equivalent
for a device launch.

### Where this does not reach

The Claude iOS app cannot drive the app on the same iPad. It has no shell and no
arbitrary-HTTP tool, and its connectors are remote MCP over HTTPS, which cannot
address the device's own loopback. The only architecture that would work is an
outbound relay — the app dials a hosted server and a remote connector talks to
that — which means public hosting, OAuth, and model data leaving the device.
Deliberately not built. Drive a USB-connected iPad from the Mac instead.

## Protocol

`http://127.0.0.1:8787`, JSON unless stated. `OS3D_AGENT_PORT` overrides.
`protocol` in `/v1/health` is bumped on any incompatible response change.

### `GET /v1/health`

Answered on the listener queue without touching the main actor — a liveness
probe that blocks behind a wedged UI reports the one condition it exists to
detect as a timeout.

```json
{"ok":true,"protocol":1,"app":"openshape3d","port":8787,"pid":36567,
 "platform":"simulator","hasDocument":true}
```

### `GET /v1/commands`

Exactly what Command Search offers — the 38 commands that reach the editor, not
the wider ~60-entry catalog. An agent handed the full catalog wastes turns on
ids that cannot run.

```json
{"ok":true,"count":37,"commands":[{"id":"sketch.arc","title":"Arc","category":"sketch","chord":"A"}]}
```

### `GET /v1/state`

```json
{"ok":true,"document":"Untitled 2","mode":"editingPrimitive","platform":"simulator",
 "selection":["BB96E231-…"],"selectedSketchEntities":0,
 "bodies":[{"id":"BB96E231-…","name":"Box","hidden":false,"volumeMM3":64,"brep":false,
            "bounds":[[0,0,0],[4,4,4]]}],
 "sketchCount":0,"featureCount":0,"canUndo":true,"canRedo":false,"undoTitle":"Add Box",
 "measurements":[{"label":"Volume","value":"64.00 mm³"},{"label":"Bounds","value":"4.00 × 4.00 × 4.00 mm"}],
 "commandSearchActive":false}
```

`measurements` is the same array `SelectionInfoBar` renders, so an agent and a
person reading over its shoulder never disagree about what the model measures.
`volumeMM3` is the B-rep's exact `BRepGProp` volume whenever `brep` is true —
a cylinder reads π·r²·h to the mm³, so compare it against analytic values
tightly. Since 2026-09-02 it is Gauss–Kronrod integrated per knot span, so
B-spline walls (splines, lofts, sweeps, drafted rectangles) are exact too,
not only analytic surfaces (a spline extrude matches its closed-form volume
to twelve figures). When `brep` is false it is integrated over the render mesh, which
reads ~0.3% LOW on curved surfaces (an inscribed tessellation), so allow
that much there. (Before 2026-09-02 every body used the mesh figure.)
`brep` says whether a body is still analytic or has been flattened to its
tessellation — the distinction the OCCT port exists for.

When any feature failed to replay, the state also carries `evalErrors` — one
`{featureID, feature, error}` row per failing node, in graph order: the same
signal the History badges render, so a session that drove the UI (not
`/v1/exec`) can still see WHICH feature failed and why. Absent when everything
built.

Verify geometry here, not in a screenshot: an image cannot show that a boolean
produced a 0 mm³ body.

### `GET /v1/check?body=<uuid>&bop=1`

Deep geometry-health report (docs/FREECAD_PLAYBOOK.md D1) — the first thing to
run when a rebuilt model "looks wrong". Without `body`, every body is checked;
`bop=1` adds the slow `BOPAlgo_ArgumentAnalyzer` pass (self-intersections,
too-small edges — advisory, runs only on shapes `BRepCheck` already passed,
under the kernel deadline).

```json
{"ok":true,"checked":1,"invalid":0,"bopCheckRequested":true,
 "bodies":[{"id":"34CF5D5F-…","name":"Drilled","health":{
   "valid":true,"findings":[],"bopCheckRan":true,"bopFindings":[],
   "counts":{"solids":1,"shells":1,"faces":7,"wires":9,"edges":15,"vertices":10},
   "tolerance":{"min":1e-07,"avg":1.0e-07,"max":1.0e-07},
   "volumeMM3":524.60,"openFreeWires":0,"closedFreeWires":0}}]}
```

A finding names its sub-shape (`"Face3"`, `"Edge17"` — 1-based indices into
the body's own indexed shape maps) and its OCCT status (`"notClosed"`,
`"selfIntersectingWire"`, …), with `context` when the fault is registered
against a parent (a wire can be fine alone and self-intersecting in its face).
A mesh-only body comes back as `{"meshOnly": true}` — losing the brep
somewhere in a chain is itself a finding. `invalid` counts sick breps only.

### `GET /v1/edges?body=<uuid>` and `GET /v1/faces?body=<uuid>`

Kernel sub-shape discovery — the vocabulary for identity-addressed exec ops.
Edges: 1-based kernel index, adjacent-face pair, midpoint/length/convexity,
and the durable `EdgeName` when the identity layer has one. Midpoint, length
and convexity appear only for an edge the render mesh shows as a crease (a
tangent join between two faces has none). The midpoint is the kernel's:
the point halfway along the edge's curve by arc length, in world space, the
same on every launch (for a full circle it is measured from the curve's own
start, so it is some fixed point on the circle). `lengthMM` is the sum of
the mesh segments along the edge, so a curved edge reads its chord length,
a hair short of the true arc. Before 2026-09-16 a curved edge's midpoint was
whichever tessellation segment came first, and moved between launches. Faces come KERNEL-SIDE (`faceInfo`, straight from the brep — never
stale, and correct for revolve/sweep/loft bodies whose render is not the
kernel tessellation): index, kind (planar / cylindrical + radius / "other"
with `referenceable: false` for torus-class surfaces), area, centroid,
normal, `ElementName` when the retained name maps are fresh. 409
`mesh_only_body` for bodies without a brep. Sub-shape GEOMETRY can never be
stale; only NAMES go missing after an undo (refs then mint name-less), so
there is no `stale_identity` refusal on these endpoints. Edges missing from
the list are seams/borders, which never blend anyway.

### `GET /v1/section?body=<uuid>&normal=x,y,z[&origin=x,y,z][&xAxis=x,y,z][&deflection=0.05]`

A plane cut through one body — the drawing view. The solid is cut where it
SITS (its placement applied, so a pattern instance or a moved body cuts in
place), and the kernel's section edges are chained into loops in the plane's
own frame: `xAxis` is your `xAxis` projected into the plane (or the world
axis least aligned with the normal), `yAxis = normal × xAxis`. Curves are
sampled at `deflection` mm chord error (default 0.05), collinear runs are
merged, and loops come largest area first:

```json
{"body":"…","plane":{"origin":[0,0,15],"normal":[0,0,1],"xAxis":[1,0,0],"yAxis":[0,1,0]},
 "count":2,"loops":[{"closed":true,"area":6000,"points":[[-50,-30],[50,-30],[50,30],[-50,30]]},
                    {"closed":true,"area":-804.2,"points":[…]}]}
```

`area` is the shoelace area with sign (a hole traverses the other way);
an open chain (the plane grazing a face) has `closed:false` and `area:0`.
This is the tool for checking a rebuild section-for-section against a
reference cut (the BEG 55 report did that by hand on the reference side
only): `bad_plane` when `normal` is missing or zero; a mesh-only body is
refused like `/v1/edges`.

### `POST /v1/exec` — `feature.fillet` / `feature.chamfer` / `feature.shell`

The ops that used to be inexpressible over the wire (they take topological
refs, not numbers) — the `EdgeName`/`ElementName` vocabulary closed that:

```json
{"op":"feature.fillet","args":{"bodyID":"…","radius":1,"edges":[1,3]}}
{"op":"feature.chamfer","args":{"bodyID":"…","setback":0.5,"edges":[7]}}
{"op":"feature.shell","args":{"bodyID":"…","thickness":0.5,"openFaces":[6]}}
```

`edges`/`openFaces` are the 1-based kernel indices `/v1/edges`//v1/faces`
report; omitted/empty `openFaces` hollows fully enclosed. The recorded
feature carries REAL refs — mesh-side signature plus the durable name — so
it replays by identity exactly like a hand-picked blend. Verified live:
extrude → fillet → fillet chained by re-discovery, and an open-face shell
landing the exact analytic volume. Failures are typed: 404
`unknown_edge`/`unknown_face` (with a pointer to the discovery endpoint),
409 `mesh_only_body`/`stale_identity`/`unaddressable_edge`, and a blend the
kernel refuses (radius too big, degenerate offset) comes back as the
feature's `evalErrors` entry with `failed: true` — undo once to remove the
recorded node, exactly like any other exec feature.

### `POST /v1/capture`

Body optional: `{"note":"wheel hub looks wrong"}`. Snapshots every analytic
body into a replayable capture bundle (docs/FREECAD_PLAYBOOK.md D2) — the
manual counterpart of the automatic failed-op capture. Returns the bundle
path; pull it with `scripts/fetch_captures.sh`, replay it with
`KernelCaptureReplay`, or promote it into
`openshape3dTests/Fixtures/Captures/` as a regression fixture. 409
`nothing_to_capture` when no body carries a brep.

### `GET /v1/archive`

The open design as `.os3d` archive bytes (`application/octet-stream`) — the
same `ProjectArchive` Export Project writes, after a save and a fresh
viewport thumbnail, so live edits are in it. This is how the bundled sample
designs are baked: `scripts/demo_models.py` builds each scene in a fresh
design and writes the reply to `openshape3d/Demos/<id>.os3d` (plus a
512 px `/v1/screenshot` for the welcome screen). 409 `no_document` when the
gallery is on screen.

### `GET /v1/export?format=stl|obj|3mf|step[&body=<uuid>,…][&up=y|z]`

The Export menu's bytes (`model/stl`, …) — how an agent finishes "make me a
printable X". No `body` = every body, hidden ones included, as in the menu;
with `body`, one file per part. `up=z` turns the app's Y-up world a quarter
turn about X, (x, y, z) → (x, −z, y), so a part standing on the ground plane
stands on a slicer's bed. Millimetres. Typed refusals: 400 `unknown_format` /
`bad_up_axis` / `bad_uuid`, 404 `unknown_body`, 409 `nothing_to_export`, and
409 `mesh_only_body` when STEP is asked of bodies with no B-rep.

### `POST /v1/command`

Body `{"id":"view.isometric"}`. Returns the full state plus `ran`.

The one thing this endpoint exists to get right: `EditorViewModel.runCommand`
returns a single `Bool` for three different situations. A human pressing a dead
key presses another one; an agent told only "false" retries forever. So:

| Status | `error` / field | Meaning |
|---|---|---|
| 200 | `"ran": true` | Ran |
| 200 | `"ran": false`, `"reason":"not_applicable"` | Real id, wrong editor state. `message` names the mode and selection count |
| 400 | `unknown_command` | No such id |
| 400 | `unrouted_command` | In the catalog, no editor entry point in this build |
| 400 | `missing_id` | Body was absent or carried no `id` |
| 405 | `method_not_allowed` | Wrong verb |
| 409 | `no_document` | Gallery on screen; open a project |

The first two 400s are decided without ever reaching the main actor, because
`CommandRegistry.all` and `routableIDs` are pure statics.

### `POST /v1/exec`

Body `{"op":"feature.extrude","args":{…}}`. The parameterized half: one request
carries the operation AND its numbers, so a model can be built without a
gesture. Returns the full state plus what the op produced.

This does NOT puppet the interactive tools (`beginCreate` → drag →
`commitTool`). It goes to the seams the architecture already mandates —
`DocumentCommand` for mutations, `FeatureKind` for parametric intent — so an
exec'd model is byte-identical to a hand-built one, replays through the same
graph, and shows up in History like any other feature.

| op | required args |
|---|---|
| `sketch.create` | none (defaults to the ground plane); `origin`, `xAxis`, `yAxis`, `name` |
| `sketch.addEntities` | `sketchID`, `entities[]`; optional `construction` (indices) |
| `feature.extrude` | `sketchID`, `seedPoint`, `distance`; optional `symmetric`, `taperDegrees` (±89; non-zero = a DRAFT extrude, walls sloped, positive contracts; holes draft the opposite way and are subtracted), `boolean`, `booleanTargets` |
| `feature.revolve` | `sketchID`, `seedPoint`, `axisPoint`, `axisDirection`; optional `angleDegrees` (360), `boolean`, `booleanTargets` |
| `feature.pattern` | `bodyID`, `count`; optional `kind` (circular), `axis`, `center`, `spacing`, `totalAngleDegrees`, `rotateInstances` |
| `feature.loft` | `sections[]` (≥2 `{sketchID, seedPoint}`, each a profile on its OWN sketch plane, lofted in order); optional `boolean`, `booleanTargets` |
| `feature.pushPull` | `bodyID`, `face` (one 1-based index from `/v1/faces`), `distance` (mm, negative pushes in); optional `mode` (`planarAxial` default / `cylinderRadial`) |
| `feature.moveFace` | `bodyID`, `face`, `delta` `[du, dv, dn]` in the face's own basis (mm — du/dv shear, dn along the normal) |
| `feature.scaleFace` | `bodyID`, `face`, `factor` (>0; scales the face about its centre, tapering the solid) |
| `feature.rotateFace` | `bodyID`, `face`, `angleDegrees` (±360); optional `axis` `[u, v, n]` in the face's basis (default the normal, which twists in place) |
| `feature.mirror` | `bodyID`, `planeOrigin`, `planeNormal`; optional `keepOriginal` (default true — a mirrored COPY beside the source; `false` moves it: the source body is consumed, one body remains) |
| `feature.transform` | `bodyID`; `translation` `[x,y,z]`, `rotationDegrees` (optional `rotationAxis`, default +Z) and/or `scale` (a positive uniform factor), the rotation and scale about `rotationCenter` (default origin). Moves the body IN PLACE — same id, analytic solid and element names kept; a parametric node like any other, the same node the Move/Rotate/Scale tools record. Identity is refused (`identity_transform`), `scale ≤ 0` is `bad_scale`. |
| `feature.boolean` | `kind` (union/subtract/intersect), `targetBodyID`, `toolBodyIDs[]` |
| `body.setMaterial` | `bodyIDs[]`, and `preset` (a Material sheet name, case-insensitive: Steel, Aluminum, Brass, Plastic Matte, Plastic Gloss, Rubber, Wood) or `color` `[r,g,b(,a)]` in 0…1; optional `metallic`, `roughness` (0…1, override the preset's). The sheet's Apply — one `SetMaterialCommand`, one undo step, not a feature |
| `item.setHidden` | `ids[]` (any mix of body, sketch and plane ids) and/or `allSketches: true`; optional `hidden` (default true; false shows). The Items panel's eye — one `SetItemVisibilityCommand` per item, reported as `undoSteps` |

Entity kinds: `line` (`a`,`b`), `circle` (`center`,`radius`), `arc`
(`center`,`radius`,`startAngle`,`endAngle`), `spline` (`points[]`,`closed`),
`rect` (`min`,`max` — two opposite corners, normalized), `polygon`
(`center`,`radius`,`sides`; optional `rotation`) and `ellipse`
(`center`,`radiusX`,`radiusY`; optional `rotation`). The closed primitives
(rect/polygon/ellipse) save spelling a box or hex out as a line loop — a
regular hex is `{"kind":"polygon","center":[0,0],"radius":13.856,"sides":6}`
(radius is the circumscribed circle, so across-flats = 2·radius·cos(π/n)).
Arc/polygon/ellipse angles are RADIANS (unlike the degrees a feature takes);
`unknown_entity_kind` names the full set.

**Profiles are found by seed point.** `seedPoint` is a point INSIDE the closed
region you want, in sketch-local mm; `ProfileDetector` resolves the innermost
enclosing loop. There is no need to enumerate the loop's entity ids.
**One seed = ONE region.** A sketch holding two separate circles under a
single seed extrudes (or cuts) only the seeded one — the other is silently
left alone. To cut several holes, issue one seeded extrude per region or use
`feature.pattern` on one cutter (the door-lock rebuild lost exactly one
hole's volume this way before it seeded each).

**`boolean` is a STRING; targets go in `booleanTargets`.** The inline boolean
on `feature.extrude`/`revolve`/`sweep`/`loft` is `"boolean":"subtract"` (one of
`newBody`/`union`/`subtract`/`intersect`) plus `"booleanTargets":["<bodyID>",…]`
— NOT a nested object. Writing `"boolean":{"kind":"subtract"}` is refused with
`bad_boolean_type` (it used to fall silently to `newBody`, producing a stray
solid where a cut was meant). The standalone `feature.boolean` op is different:
it takes `targetBodyID` + `toolBodyIDs[]`.

**`symmetric` extrudes ±distance** — a symmetric extrude of `distance: d` is
`2d` tall (d each way from the sketch plane). For a part that must be `L` long
symmetric, pass `distance: L/2` (or an asymmetric `distance: L`).

**UNITS: millimetres and degrees.** Note that `FeatureKind.revolve` stores
DEGREES and `FeatureGraph` converts to radians once at the OCCT boundary
(`angle.value * .pi / 180`). Converting on the way in as well yields a
6.28-degree revolve that renders as an entirely plausible solid rather than
failing — the worst way for a unit bug to behave, and the reason the wire
format is degrees end to end.

Failures are named rather than lumped into one code, because an agent cannot
see a disabled button and will otherwise retry the wrong thing forever:
`unknown_op`, `missing_op`, `unknown_entity_kind` (named by index),
`degenerate_line` / `bad_radius` / `bad_spline`, `zero_distance`,
`missing_boolean_targets`, `bad_boolean_type`, `unknown_boolean_op`,
`degenerate_axis`, `degenerate_plane`,
`angle_out_of_range`, `bad_count`, `self_boolean`, `bad_uuid`,
`unknown_sketch` / `unknown_body` (404).

Two behaviours worth knowing:

- A feature exec is **one undo step**, whether it built or failed, reported as
  `undoSteps: 1`: the node is appended and the graph rebuilt in one composite,
  the way the interactive tools commit (`DocumentSession.recordAndRebuild`),
  and `undoTitle` in `/v1/state` is the feature's name. **Undo `undoSteps`
  times.** Until 2026-09-16 the append and the rebuild were separate steps and
  every reply said `undoSteps: 2`, but a feature that FAILED recorded only one
  (its rebuild changed no body, so it committed nothing), and undoing twice
  also reverted the feature before it (union, failed R15 fillet, undo, undo:
  the union was gone). One undo of a feature that built reverted only its
  rebuild, leaving the node in History over the old bodies.
- Every reply carries `producedBodyIDs`, `changedBodyIDs` and `removedBodyIDs`.
  All three are needed, because a BOOLEAN adds no body — it replaces its target
  in place, so judging success by "did a new body appear" reports a subtract
  that just removed 4.5 million mm3 as having done nothing.
- If THIS node failed to build, the reply carries `"failed": true` and a
  `message` naming the reason, alongside `evalErrors` keyed by feature id.
  That flag is the reliable signal: `rebuildFrom` re-emits bodies and bumps
  `meshRevision` on nodes it did not semantically touch, so a failed feature
  can still appear to have changed something. The silent no-op is exactly what
  this endpoint exists to make visible.

### `GET /v1/screenshot?w=&h=[&format=png|jpeg][&maxBytes=]`

PNG bytes by default, rendered by the app itself — so it works identically on
Catalyst and on a device, where `simctl io screenshot` does not exist. Sizes
clamp to 64–4096, default 1024. `format=jpeg` re-encodes (quality 0.85), and
`maxBytes=` then shrinks quality and finally the image until it fits: that is
what the MCP tool asks for (700 kB), because a chat client caps a tool result
(Claude Desktop: 1 MB, and a 1024² PNG of a model is 1.4 MB as base64). It is an offscreen render, centred on the camera
target. On a phone the on-screen view is shifted right of the tool palette
(`ViewportSafeArea`), so for tap coordinates use `/v1/project`, which
follows the screen, not positions read off this image.

Sleep ~1s after any `view.*` command before capturing: standard views animate,
and an immediate capture catches the camera mid-flight, which looks exactly like
the command having failed.

## Registering the MCP server

Claude Desktop — `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{"mcpServers": {"openshape3d": {
  "command": "python3",
  "args": ["/Users/jclaan/projects/ios/openshape3d/scripts/mcp_openshape3d.py"]}}}
```

Claude Code picks the same server up from the project's `.mcp.json`, though the
skill and plain `curl` are the lighter path there.

Stdlib-only and Python 3.9-compatible on purpose: it runs inside Claude
Desktop's launch environment, not yours, where a missing dependency surfaces as
an unexplained failure.

**Tool surface (both MCP dialects, since 2026-09-17).** Claude Desktop asks the
person to approve each tool BY NAME the first time it is used. It reads
`annotations.readOnlyHint` — but only to group those tools under "Read-only
tools" in the extension's Settings page, where they can be pre-approved; the
first-use prompt still appears (checked on 2.110: an annotated `os3d_edges`
prompted after three annotated reads had run). So the catalog lists ONE tool,
`os3d`, whose `op` covers everything: the reads (`health`, `guide`, `state`,
`faces`, `edges`, `sketches`, `check`, `screenshot`, `commands`, with their
arguments in `args`), the features, `command.run` (`{"id":"view.fit"}` →
`POST /v1/command`) and `document.export` (`{"format","up","body","name"}` →
`GET /v1/export`, saved to Downloads). The old per-endpoint tools
(`os3d_state`, `os3d_exec`, `os3d_export`, …) still route — recorded sessions
replay — but are no longer listed. Desktop lists an extension's tools ONCE,
when it starts the relay, and keeps that list until Desktop restarts or the
extension is toggled in Settings ▸ Extensions. A Desktop still holding an older
list keeps working, because the old tool names still route; it just asks once
per old name.
Screenshots over MCP are JPEG under a byte budget (`format=jpeg&maxBytes=`
on `/v1/screenshot`): a 1024² PNG of a model is ~1.4 MB base64, over Claude
Desktop's 1 MB tool-result cap.

## What this cannot do yet

`/v1/exec` covers sketching plus extrude, revolve, pattern, mirror, boolean,
**helix sweep** — threads, springs, wire inserts: give `feature.sweep` a
`"helix": {"axisPoint":[x,y,z], "axisDirection":[x,y,z], "radius":r,
"pitch":p, "turns":n, "referenceDirection":[x,y,z]?, "startAngle":θ?}`
instead of (or as well as) `spine`. The B-rep is swept along the EXACT
helix (right-handed about the axis for positive pitch; `referenceDirection`
is where angle 0 points, any perpendicular when omitted) and the render
polyline is sampled from the same spec, so they agree. Place the profile
sketch at the helix start, normal to its start tangent
(`HelixSpec.point(at:)` / `tangent(at:)`); by Pappus the volume is exactly
section area × turns·√((2πr)² + p²). Bad values return `bad_helix`.
`scripts/rebuild_helicoil.py` is the worked example (a HELICOIL insert:
diamond wire on a helix plus its tang, matched to 1e-4).

**sweep** (`{"op":"feature.sweep","args":{"sketchID":…,"seedPoint":…,
"spine":[[x,y,z],…]}}` — world-space spine, ≥2 points, same boolean/targets
as extrude) — and, since the topological-naming mission landed its edge/face
identity vocabulary, **fillet, chamfer and shell** (see their section above),
plus **deleteFace** (`{"bodyID":…,"faces":[i,…]}` — OCCT heals over the
removed faces, spec §4.16) and **replaceFace** (`{"bodyID":…,"face":[i],
"targetOrigin":[x,y,z],"targetNormal":[x,y,z],"flip":false}` — extend/trim
onto a world plane, spec §4.12, same plane-not-ref v1 limitation as the
interactive tool). What is still missing:

- **`offsetFace`** over exec — no tutorial recipe needs it yet. (Loft
  landed: `feature.loft`, in the table above.)
- **Align**, which has no `FeatureKind` at all.
- **Importing a body.** Several of the reference tutorial models lean on
  `MaterializeImportedBodies`, and those bodies are Parasolid, which OCCT cannot
  read at any price.

`runCommand` still only ARMS the interactive tools; `/v1/exec` is the way to
perform a parameterized operation, not a replacement for driving the UI when you
specifically want to test the UI.
