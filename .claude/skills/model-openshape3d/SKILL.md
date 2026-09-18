---
name: model-openshape3d
description: Model 3D shapes in the openshape3d CAD app from a description — sketch, extrude, revolve, shell, fillet, boolean, pattern, set materials, check the solid and export STL / 3MF / STEP for 3D printing. Use whenever asked to make, build, design, change, fix or export a part, shape or object in openshape3d, or whenever the `os3d` tool (or `os3d_*` tools) is available and the person wants something modelled ("make a flowerpot", "add a 5 mm hole", "make the walls thicker", "export it for printing"), even if they never name the app.
---

# Modelling in openshape3d

You drive the live app. Every operation you send is recorded as an undoable,
parametric feature — the person watching sees the part appear in their
viewport and can carry on editing it by hand. Work in their terms: when you
report back, give sizes, wall thickness and file names, not ids.

Two equivalent clients; use whichever you have:

| You have | Change the design | Read it |
|---|---|---|
| the `os3d` MCP tool | `os3d {op, args}` — every feature below, plus `command.run` (`args: {"id":"view.fit"}`) and `document.export` | the same tool: `op` `health`, `state`, `faces` / `edges` (`args: {"body": id}`), `sketches`, `check`, `screenshot`, `commands` |
| a shell | `curl -s -X POST $B/v1/exec -d '{"op":…,"args":{…}}'`; commands `POST $B/v1/command -d '{"id":"view.fit"}'`; files `GET "$B/v1/export?format=stl&up=z&body=<id>" -o part.stl` | `GET $B/v1/state`, `/v1/faces?body=`, `/v1/edges?body=`, `/v1/sketches`, `/v1/check`, `/v1/screenshot` |

`B=http://127.0.0.1:8787` unless the app was launched on another port.
Everything goes through the one `os3d` tool on purpose: the person approves
it once and is never asked again. The commands you need are
`view.isometric`, `view.front`, `view.top`, `view.right`, `view.fit`,
`edit.undo`, `edit.redo` (op `commands` / `GET /v1/commands` for all).

Start with health (op `health` / `GET /v1/health`): `hasDocument:false`
means the project gallery is showing — ask the person to open or create a
design. Launching the app is `docs/AI_MODELING_SETUP.md`.

## Conventions that decide whether the part comes out right

- **Millimetres and degrees** in every feature. Only sketch-entity angles
  (arc `startAngle`/`endAngle`, polygon/ellipse `rotation`) are radians.
- **Y is up.** The ground is the XZ plane. A default sketch (`sketch.create`
  with no args) lies on the ground: sketch `(u, v)` is world `(u, 0, −v)`,
  and a positive extrude grows **up** (+Y). A sketch on top of a body sits at
  `origin: [0, h, 0]` with the same axes.
- A **vertical** sketch for side profiles and revolves:
  `{"origin":[0,0,0],"xAxis":[1,0,0],"yAxis":[0,1,0]}` — then `u` is world X
  (the radius) and `v` is world Y (the height).
- **Profiles are found by a seed point**: `seedPoint` is any point strictly
  inside the closed region, in sketch `(u, v)`. **One seed = one region**: a
  sketch with three circles cuts only the seeded one. Several holes are one
  seeded cut each, or one cutter body and `feature.pattern`.
- A revolve's `axisPoint` / `axisDirection` are in the sketch's own `(u, v)`.
  The vertical axis through the origin is `[0,0]`, `[0,1]`. Keep the whole
  profile on one side of the axis (`u ≥ 0`).
- Face and edge **indices are per-shape**: list them again after every
  feature, never reuse an index from before an edit.
- Ids are UUID strings copied from replies (`sketchID`, `producedBodyIDs`,
  `bodies[].id`). Never invent one.
- Booleans want overlap: a tool that stops exactly on a face, or a cut whose
  wall coincides with the target's, is the classic kernel failure. Run cuts
  through and past the target; overlap unions by a millimetre.

## The loop

1. `state` — what is already there (bodies with `volumeMM3` and `bounds`).
2. Build with `exec`, one op per call, and read each reply: `bodies[]` is
   the new state, `producedBodyIDs` / `changedBodyIDs` / `removedBodyIDs`
   say what happened. **`"failed": true`** means the feature was recorded
   but did not build — read `message`, undo once (`command.run`
   `edit.undo`), fix the arguments. Never retry a call unchanged.
3. **Verify with numbers, not pictures**: compare `volumeMM3` and `bounds`
   with what you expect (work the volume out by hand — a wrong boolean or a
   zero-thickness wall is invisible in a screenshot).
4. Look once at the end: `view.isometric`, `view.fit`, wait a second,
   screenshot. Hide the construction sketches first (`item.setHidden` with
   `"allSketches": true`) so the person sees the solids.
5. Before anything is manufactured: `check` (`valid: true`, no findings),
   then export.

## Operations (`op` → `args`)

| op | args |
|---|---|
| `sketch.create` | none = ground plane; or `origin`, `xAxis`, `yAxis` (world vectors), `name`. Reply: `sketchID` |
| `sketch.addEntities` | `sketchID`, `entities[]` (below); optional `construction` (indices) |
| `feature.extrude` | `sketchID`, `seedPoint` `[u,v]`, `distance`; optional `symmetric` (±distance, so 2× tall), `taperDegrees` (positive narrows), `boolean`, `booleanTargets` |
| `feature.revolve` | `sketchID`, `seedPoint`, `axisPoint` `[u,v]`, `axisDirection` `[u,v]`; optional `angleDegrees` (360), `boolean`, `booleanTargets` |
| `feature.loft` | `sections[]` of `{sketchID, seedPoint}` (≥2, each profile on its own plane, in order); optional `boolean`, `booleanTargets` |
| `feature.sweep` | `sketchID`, `seedPoint`, `spine` `[[x,y,z],…]` (world) or `helix` `{axisPoint, axisDirection, radius, pitch, turns}`; the profile sketch sits at the spine's start, normal to it |
| `feature.shell` | `bodyID`, `thickness` (positive hollows inward), `openFaces` `[faceIndex,…]` (omit for a sealed hollow) |
| `feature.fillet` | `bodyID`, `radius`, `edges` `[edgeIndex,…]` |
| `feature.chamfer` | `bodyID`, `setback`, `edges` `[edgeIndex,…]` |
| `feature.boolean` | `kind` (`union` / `subtract` / `intersect`), `targetBodyID`, `toolBodyIDs[]` |
| `feature.pattern` | `bodyID`, `count` (total, including the original); `kind` `circular` (default: about `axis`, default +Y, through `center`, over `totalAngleDegrees` 360) or `linear` (`axis` = direction, `spacing` mm) |
| `feature.mirror` | `bodyID`, `planeOrigin`, `planeNormal`; `keepOriginal` true (default) leaves a mirrored copy, false moves the body |
| `feature.transform` | `bodyID`; `translation` `[x,y,z]` and/or `rotationDegrees` with `rotationAxis` (default +Z — pass `[0,1,0]` to turn about the vertical) and `rotationCenter`, and/or `scale`. Moves in place, same id |
| `feature.pushPull` | `bodyID`, `face`, `distance` (negative pushes in) |
| `feature.moveFace` / `scaleFace` / `rotateFace` | `bodyID`, `face`; `delta` `[du,dv,dn]` in the face's basis / `factor` / `angleDegrees` (+ `axis`) |
| `feature.draftFace` | `bodyID`, `face`, `angleDegrees` (±89); the neutral plane defaults to the ground |
| `feature.deleteFace` | `bodyID`, `faces[]` — the kernel heals over them (removes a fillet or a boss) |
| `feature.replaceFace` | `bodyID`, `face`, `targetOrigin`, `targetNormal` (world plane) |
| `body.setMaterial` | `bodyIDs[]`, `preset` (Steel, Aluminum, Brass, Plastic Matte, Plastic Gloss, Rubber, Wood) or `color` `[r,g,b]` 0…1; optional `metallic`, `roughness` |
| `item.setHidden` | `ids[]` and/or `allSketches: true`; optional `hidden` (true) |
| `command.run` | `id` — a view, `edit.undo`, `edit.redo` (MCP; over curl it is `POST /v1/command`) |
| `document.export` | `format` (`stl` / `3mf` / `obj` / `step`), `up` (`"z"` for slicers), `body` `[ids]`, `name` (MCP; over curl it is `GET /v1/export`) |
| `health`, `guide`, `state`, `sketches`, `commands` | no args — reads (MCP; over curl `GET /v1/…`) |
| `faces`, `edges` | `body` — the index lists below |
| `check` | optional `body`, `bop: true` (the slow self-intersection pass) |
| `screenshot` | optional `width`, `height` (default 1024; a JPEG sized for a chat) |

**Inline booleans**: `"boolean"` is a STRING — `"newBody"` (default),
`"union"`, `"subtract"`, `"intersect"` — and the bodies it acts on go in
`"booleanTargets": ["<bodyID>"]`. A cut is an extrude with
`"boolean":"subtract"` that passes through its target.

**Sketch entities**

```json
{"kind":"line","a":[0,0],"b":[40,0]}
{"kind":"rect","min":[-20,-10],"max":[20,10]}
{"kind":"circle","center":[0,0],"radius":12}
{"kind":"polygon","center":[0,0],"radius":10,"sides":6}
{"kind":"ellipse","center":[0,0],"radiusX":20,"radiusY":12}
{"kind":"arc","center":[0,0],"radius":10,"startAngle":0,"endAngle":1.5708}
{"kind":"spline","points":[[0,0],[10,8],[20,0]],"closed":false}
```

A profile made of lines must close exactly: the last `b` equals the first
`a`. Polygon `radius` is the circumscribed circle (across-flats is
`2·r·cos(π/n)`).

## Reading faces and edges

`faces[]` rows: `index`, `kind` (`planar`, `cylindrical` with `radius`, or
`other` with `referenceable: false` — a torus-class blend you cannot pick),
`areaMM2`, `centroid`, `normal`, all in world mm. The top of a body is the
planar face with normal `[0,1,0]` and the highest centroid `y`; the floor of
a pot is the planar face with normal `[0,1,0]` *inside* the walls.

`edges[]` rows: `index`, `faces` `[a, b]` (the two face indices it joins),
`midpoint`, `lengthMM`, `convex` (true on an outside corner, false in a
groove). The rim of a cup is every edge whose midpoint `y` is the top
height; a circular edge's length is its circumference. Edges missing from
the list are seams, which never blend. Fillet an edge loop together in one
call, not one edge per call.

## Recipes

**Plate with a hole** — ground sketch → `rect` + `circle` in ONE sketch →
extrude with the seed inside the rectangle but outside the circle: the hole
comes for free. Several holes: one sketch, one seeded `subtract` extrude per
hole through the plate.

**Turned part (pot, vase, knob, wheel)** — vertical sketch, draw HALF the
cross-section of the wall as a closed loop of lines at `u ≥ 0`, revolve about
`[0,0]`,`[0,1]`. Starting the loop at `u = r` instead of `u = 0` leaves a
hole of radius `r` along the axis (a drainage hole). The exact volume is
Pappus: `2π · centroid_u · area` — compare it to `volumeMM3`.

**Hollow box / enclosure** — extrude the outside, `faces` to find the top
(planar, normal `[0,1,0]`, highest centroid), `feature.shell` with that index
in `openFaces`. A lid is a second plate whose lip is `0.3 mm` smaller than
the opening.

**Rounded edges** — `edges`, pick by `midpoint` / `lengthMM` / the adjacent
faces, `feature.fillet` with all of them at once. A radius larger than the
wall or the neighbouring face fails with "too large for the local geometry":
keep it under half the thinnest dimension, and fillet before shelling only
if the wall is thicker than the radius.

**Boss, peg, stand-off** — a circle on a sketch at the face's height
(`origin: [0, h, 0]`), extrude with `"boolean":"union"` and the body as the
target; start the sketch `0.5 mm` inside the body so the union overlaps.

**Several parts** — every new-body feature returns its id. Move one beside
another with `feature.transform`; export them one file each with `body`.

## Exporting for 3D printing

MCP: `document.export` with `format: "stl"` (or `"3mf"`), **`up: "z"`**,
`body: ["<id>"]` when only one part should be in the file, and a `name`;
the file lands in the person's Downloads folder and the reply gives
`fileName`, `path`, `sizeMM` (width × depth × height as written — check it
against what was asked) and `triangles`. Over curl:
`GET "/v1/export?format=stl&up=z&body=<id>" -o part.stl`. Slicers are Z-up,
the app is Y-up, and `up:"z"` stands the part on the bed exactly as it
stands on the ground plane here. Units are millimetres. `format: "step"`
hands the exact B-rep to another CAD tool; STL carries no colour.

Design for the printer while modelling, not after: walls ≥ 1.2 mm (three
0.4 mm perimeters; 2–3 mm for anything that holds soil or water), overhangs
≤ 45° from vertical print without supports, a flat face on the ground plane
is the bed face, and clearances between mating parts ≥ 0.3 mm.

## When something goes wrong

Errors are named, and the name is the fix: `unknown_op`,
`unknown_entity_kind`, `bad_boolean_type` (you sent an object, send a
string), `missing_boolean_targets`, `unknown_sketch` / `unknown_body` (stale
or invented id — re-read state), `unknown_edge` / `unknown_face` (re-list),
`one_face_only`, `no_document` (ask the person to open a design). A kernel
message ("fillet: this size is too large…", a boolean that returns the
target unchanged) means the geometry, not the syntax: smaller radius, more
overlap, or a different order of operations. Each exec is one undo step;
undo a failed feature before trying again so History stays clean.
Full protocol: `docs/AGENT_CONTROL.md`.
