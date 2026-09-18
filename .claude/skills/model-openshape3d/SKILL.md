---
name: model-openshape3d
description: Model 3D shapes in the openshape3d CAD app from a description — sketch, extrude, revolve, shell, fillet, boolean, pattern, set materials, check the solid and export STL / 3MF / STEP for 3D printing. Use when asked to make, build, design, change or export a part or shape in openshape3d ("make a flowerpot", "add a 5 mm hole", "export it for printing").
---

# Modelling in openshape3d

You drive the live app over its DEBUG bridge. Every operation you send is
recorded as an undoable, parametric feature — the person watching sees the
part appear in their viewport and can carry on editing it by hand.

Two equivalent clients; use whichever you have:

| You have | Call | Reads |
|---|---|---|
| `os3d_*` MCP tools | `os3d_exec {op, args}` | `os3d_state`, `os3d_faces`, `os3d_edges`, `os3d_check`, `os3d_screenshot`, `os3d_export` |
| a shell | `curl -s -X POST $B/v1/exec -d '{"op":…,"args":{…}}'` | `GET $B/v1/state`, `/v1/faces?body=`, `/v1/edges?body=`, `/v1/check`, `/v1/screenshot`, `/v1/export` |

**Commands** (views, undo) are a separate call from `exec`:
`os3d_run_command {"id":"view.fit"}` or
`curl -s -X POST $B/v1/command -d '{"id":"view.fit"}'`. The ones you need:
`view.isometric`, `view.front`, `view.top`, `view.right`, `view.fit`,
`edit.undo`, `edit.redo` (`os3d_list_commands` / `GET /v1/commands` for all).

`B=http://127.0.0.1:8787` unless the app was launched on another port. Start
with health (`os3d_health` / `GET /v1/health`): `hasDocument:false` means the
project gallery is showing — ask the person to open or create a design.
Launching the app is `docs/AI_MODELING_SETUP.md` (or the `drive-openshape3d`
skill inside this repo).

## Conventions that decide whether the part comes out right

- **Millimetres and degrees** in every feature. Only sketch-entity angles
  (arc `startAngle`/`endAngle`, polygon/ellipse `rotation`) are radians.
- **Y is up.** The ground is the XZ plane. A default sketch (`sketch.create`
  with no args) lies on the ground: sketch `(u, v)` is world `(u, 0, −v)`,
  and a positive extrude grows **up** (+Y).
- A **vertical** sketch for side profiles and revolves:
  `{"origin":[0,0,0],"xAxis":[1,0,0],"yAxis":[0,1,0]}` — then `u` is world X
  (the radius) and `v` is world Y (the height).
- **Profiles are found by a seed point**: `seedPoint` is any point strictly
  inside the closed region, in sketch `(u, v)`. One seed = one region.
- A revolve's `axisPoint` / `axisDirection` are in the sketch's own `(u, v)`.
  The vertical axis through the origin is `[0,0]`, `[0,1]`. Keep the whole
  profile on one side of the axis (`u ≥ 0`).
- Face and edge **indices are per-shape**: list them again after every
  feature, never reuse an index from before an edit.
- Ids are UUID strings copied from replies (`sketchID`, `producedBodyIDs`,
  `bodies[].id`). Never invent one.

## The loop

1. `state` — what is already there.
2. Build with `exec`, one op per call. Read each reply:
   `producedBodyIDs` / `changedBodyIDs` / `removedBodyIDs` say what happened;
   **`"failed": true`** means the feature was recorded but did not build —
   read `message`, run the command `edit.undo` once, fix the arguments.
3. **Verify with numbers, not pictures**: compare `bodies[].volumeMM3` and
   `bounds` against what you expect (work the volume out by hand — a wrong
   boolean or a zero-thickness wall is invisible in a screenshot).
4. Look: command `view.isometric`, then `view.fit`, wait a second, screenshot.
   Tidy up for the person watching: hide the construction sketches
   (`item.setHidden` with `"allSketches": true`) once the solids are built.
5. Before anything is manufactured: `check` (`valid: true`, no findings),
   then `export`.

## Operations (`op` → `args`)

| op | args |
|---|---|
| `sketch.create` | none = ground plane; or `origin`, `xAxis`, `yAxis` (world vectors), `name`. Reply: `sketchID` |
| `sketch.addEntities` | `sketchID`, `entities[]` (below); optional `construction` (indices) |
| `feature.extrude` | `sketchID`, `seedPoint` `[u,v]`, `distance`; optional `symmetric` (±distance, so 2× tall), `taperDegrees` (positive narrows), `boolean`, `booleanTargets` |
| `feature.revolve` | `sketchID`, `seedPoint`, `axisPoint` `[u,v]`, `axisDirection` `[u,v]`; optional `angleDegrees` (360), `boolean`, `booleanTargets` |
| `feature.loft` | `sections[]` of `{sketchID, seedPoint}` (each profile on its own plane, in order) |
| `feature.sweep` | `sketchID`, `seedPoint`, `spine` `[[x,y,z],…]` (world) or `helix` `{axisPoint, axisDirection, radius, pitch, turns}` |
| `feature.shell` | `bodyID`, `thickness` (positive hollows inward), `openFaces` `[faceIndex,…]` (omit for a sealed hollow) |
| `feature.fillet` | `bodyID`, `radius`, `edges` `[edgeIndex,…]` |
| `feature.chamfer` | `bodyID`, `setback`, `edges` `[edgeIndex,…]` |
| `feature.boolean` | `kind` (`union` / `subtract` / `intersect`), `targetBodyID`, `toolBodyIDs[]` |
| `feature.pattern` | `bodyID`, `count` (total, including the original); `kind` (`circular` default / `linear`), `axis`, `center`, `spacing`, `totalAngleDegrees` |
| `feature.mirror` | `bodyID`, `planeOrigin`, `planeNormal`; optional `keepOriginal` (true) |
| `feature.transform` | `bodyID`; `translation` `[x,y,z]` and/or `rotationDegrees` (+`rotationAxis`, `rotationCenter`) and/or `scale` |
| `feature.pushPull` | `bodyID`, `face`, `distance` (negative pushes in) |
| `body.setMaterial` | `bodyIDs[]`, `preset` (Steel, Aluminum, Brass, Plastic Matte, Plastic Gloss, Rubber, Wood) or `color` `[r,g,b]` 0…1 |
| `item.setHidden` | `ids[]`, optional `hidden` (true) |

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

A profile made of lines must close exactly: the last `b` equals the first `a`.

## Recipes

**Plate with a hole** — ground sketch → `rect` + `circle` in ONE sketch →
extrude with the seed inside the rectangle but outside the circle: the hole
comes for free.

**Turned part (pot, vase, knob, wheel)** — vertical sketch, draw HALF the
cross-section of the wall as a closed loop of lines at `u ≥ 0`, revolve about
`[0,0]`,`[0,1]`. Starting the loop at `u = r` instead of `u = 0` leaves a
hole of radius `r` along the axis (a drainage hole). The exact volume is
Pappus: `2π · centroid_u · area` — compare it to `volumeMM3`.

**Hollow box / enclosure** — extrude the outside, `faces` to find the top
(planar, normal `[0,1,0]`, highest centroid), `feature.shell` with that index
in `openFaces`.

**Rounded edges** — `edges`, pick by `midpoint` / `length` / the adjacent
faces, `feature.fillet`. A radius larger than the wall or the neighbouring
face fails: keep it under half the thinnest dimension.

**Several parts** — every new-body feature returns its id. Move one beside
another with `feature.transform`; export them separately with `body`.

## Exporting for 3D printing

`export` with `format: "stl"` (or `"3mf"`), **`up: "z"`** — slicers are Z-up,
the app is Y-up, and `up:"z"` stands the part on the bed exactly as it stands
on the ground plane here — and `body` when only one part should be in the
file. Over curl: `GET /v1/export?format=stl&up=z&body=<id> -o part.stl`.
Units are millimetres. `format: "step"` hands the exact B-rep to another CAD
tool.

Design for the printer while modelling, not after: walls ≥ 1.2 mm (three
0.4 mm perimeters; 2–3 mm for anything that holds soil or water), overhangs
≤ 45° from vertical print without supports, a flat face on the ground plane
is the bed face, and clearances between mating parts ≥ 0.3 mm.

## When something goes wrong

Errors are named, and the name is the fix: `unknown_op`,
`unknown_entity_kind`, `bad_boolean_type` (you sent an object, send a
string), `missing_boolean_targets`, `unknown_sketch` / `unknown_body` (stale
or invented id — re-read state), `unknown_edge` / `unknown_face` (re-list),
`no_document` (ask the person to open a design). Do not retry the same call
unchanged. Undo is the command `edit.undo`; each exec is one undo step.
Full protocol: `docs/AGENT_CONTROL.md`.
