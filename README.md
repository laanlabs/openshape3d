# openshape3d

> Sketch usability work (September 2026): [current implementation status and 42-issue queue](docs/SKETCH_PARITY_IMPLEMENTATION.md). Earlier parity notes contain historical defaults; both annotation visibility switches currently default off (selection-based).


An open-source direct-modeling CAD app for iPad and iPhone,
built with SwiftUI, a **custom Metal renderer**, and a dual geometry kernel:
[OpenCASCADE](https://github.com/Open-Cascade-SAS/OCCT) (OCCT) for exact B-rep
solids, with the MIT-licensed
[Euclid](https://github.com/nicklockwood/Euclid) mesh-CSG library alongside it.
See [Geometry kernels](#geometry-kernels-occt--euclid).

![Platform](https://img.shields.io/badge/platform-iPadOS%20%7C%20iOS-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)

## Screenshots

Sketch on a plane or a body face, pull the profile into a solid, then blend the
edges — every operation undoable.

| Pick a sketch plane | Push/pull to a solid | Fillet the edges |
| :---: | :---: | :---: |
| <img src="docs/screenshots/ipad-sketch-plane.jpg" width="270" alt="Sketch plane tiles at the origin"> | <img src="docs/screenshots/ipad-push-pull.jpg" width="270" alt="Extrude bar armed on a face"> | <img src="docs/screenshots/ipad-fillet.jpg" width="270" alt="Fillet edge picking"> |

The same tools on iPhone — the contextual bars adapt to compact width.

| | | |
| :---: | :---: | :---: |
| <img src="docs/screenshots/iphone-hero.jpg" width="200" alt="Solid in the viewport on iPhone"> | <img src="docs/screenshots/iphone-push-pull.jpg" width="200" alt="Extrude bar on iPhone"> | <img src="docs/screenshots/iphone-gallery.jpg" width="200" alt="Project gallery on iPhone"> |

## Getting started

**Install [Git LFS](https://git-lfs.com) before cloning.** The prebuilt
`ThirdParty/OCCT.xcframework` (the OCCT static libs, ~280 MB) is stored via Git
LFS, so the app builds straight after a clone — no local OCCT build needed.

```sh
brew install git-lfs      # once per machine
git lfs install
git clone git@github.com:laanlabs/openshape3d.git
```

If you cloned *without* LFS and the build fails with *"There is no XCFramework
found at …/ThirdParty/OCCT.xcframework"* (or the `.a` files are tiny pointer
text), run `git lfs install && git lfs pull` to fetch the real libraries. To
rebuild the framework from OCCT source instead, see `scripts/build_occt_ios.sh`.

## Features (v0.5)

- **Sketch planes** — pick a world plane (XY/YZ/ZX tiles at the origin), tap
  any planar body face to sketch on it, or pull an **offset construction
  plane** off a face (drag the arrow or type the distance; persisted).
  Re-entering the same plane continues the same sketch item, and the camera
  animates head-on.
- **Sketch tools** — Line (with chain continuation and close-the-loop),
  Rectangle, Circle, **Arc** (drag the chord, then drag the arc to adjust the
  bulge), **Ellipse**, and **Polygon** (side count in the numeric bar), with
  endpoint/midpoint/center/vertex + grid snapping. The Apple Pencil draws.
- **Sketch editing** — tap entities to select, drag endpoints/handles or the
  entity body to edit (one coalesced undo step per drag), Delete, and
  **Trim**: tap a segment to remove the span between its nearest
  intersections (circles trim to arcs, rectangles explode into lines).
  A **move/rotate gizmo** appears on sketch selections (double-tap selects
  the whole connected chain, Copy chip drags duplicates), and **Make
  Construction / Make Regular** toggles dashed reference geometry that is
  excluded from profile fills and preferred as a revolve axis.
- **Constraints & dimensions (2D solver)** — a **pure-Swift** variational
  solver (Levenberg–Marquardt with a numeric Jacobian, SVD/eigen null-space
  DOF analysis) behind a `ConstraintSolver` facade — no C++ dependency.
  An adaptive **Constrain** menu applies geometric relations (coincident,
  horizontal/vertical, parallel, perpendicular, equal length/radius,
  concentric, midpoint, symmetric, tangent, colinear, and Lock); **driving
  dimensions** (length, radius, diameter, angle — with inline arithmetic like
  `25.4/2`) pull the geometry to value. Constraints show as tap-selectable
  **glyphs** on the canvas and, with dimensions, list under **Constraints**
  in the Items panel — Delete removes either (undoable, re-solves). A
  conflicting constraint/dimension is **refused** with a non-blocking message
  rather than corrupting the sketch. The sketch pill reports its state —
  **green** fully defined (0 DOF) or **blue** under-defined (N DOF) — and
  dragging an under-defined point **solves live** as the rest follows.
  Constraints/dimensions persist with the sketch and survive extrude.
- **Text & Project** — the Text tool places typed strings as glyph-outline
  sketch profiles (content/height/font dialog) that fill and extrude like
  any sketch; the Project tool flattens a tapped body's feature edges onto
  the active sketch plane as editable, unlinked line entities (the CNC
  flat-layout workflow).
- **Sketch → Extrude** — tap a fill for numeric extrude or
  pull it directly with a live preview; nested profiles become holes;
  additional fills join a multi-profile extrude. **Boolean badge**
  (Auto | New Body | Union | Subtract | Intersect), **Symmetric** sides
  (per-side distance, 2× total), and validity feedback — the pull arrow
  turns red when the pending result would fail. Tapping empty space commits.
- **Revolve** — select a profile fill, tap "Revolve", pick a sketch line or
  world axis, drag or type the angle (default 360°, partial wedges
  supported); commits through the same automatic-boolean pipeline.
- **Sweep, Loft & Helix** — from an armed profile: **Sweep** chains tapped
  sketch lines/arcs (across planes) into a spine with a live preview and
  segment count; **Loft** collects profile fills as ordered sections
  (coplanar-only section sets are rejected with guidance); **Helix** sweeps
  the profile along a generated helical spine (radius/pitch/turns). All
  three commit through the automatic-boolean pipeline.
- **Split Body** — select a body, tap Split, then tap a world/construction
  plane tile or a sketch profile fill; the body divides into two solids
  named "<name> A" / "<name> B" in one undo step.
- **Pattern** — linear (X/Y/Z axis + spacing) and circular (axis + total
  angle, rotated instances) patterns of a selected body, or in-plane
  patterns of an armed sketch profile, with translucent ghost previews;
  count−1 copies commit as one undo step with suffixed names (Box 2,
  Box 3, …).
- **Face push/pull with automatic booleans** — tap a body to select the
  planar face under your finger (double-tap selects the whole body). Drag
  the face to extrude it: pulling away adds material (union), pushing into
  the body cuts (subtract) — the automatic boolean rule.
- **Booleans** — explicit union, subtract, and intersect between bodies
  (computed off the main thread, cancellable).
- **Transform** — move gizmo with XYZ arrows, plane tiles, and **rotation
  rings**; tap an arrow to type an exact distance; **Copy badge** duplicates
  the selection on the next drag; uniform **Scale** by factor (Copy badge,
  empty-grid commit); **Mirror** a body across a world or construction
  plane; **Translate** moves point-to-point over vertex/sketch/grid snaps;
  **Rotate Around Axis** picks a sketch line or world axis, then drags in
  5° steps or takes typed fine angles; **Align** mates a snap point on one
  body onto a point on another. Every transform lands in undo under its
  own title (Move/Scale/Rotate/Translate/Align).
- **Views** — orientation cube in the corner (tap a face or corner to snap
  the view), Views menu with the six standard views + isometric, and an
  **orthographic** projection toggle. Direct-touch navigation (one finger
  orbits, two fingers pan, pinch zooms — camera never locks up, even
  mid-tool).
- **Section View** — pick a world or construction plane; the model clips
  live against it with a drag arrow to move the cut and Flip / Section Off
  badges. **Isolate** hides everything but the selection.
- **Display modes** — Shaded, Shaded (No Edges), Wireframe (hidden lines
  stay hidden via a depth prepass), and X-Ray, plus a Show Hidden Edges
  pass; bodies stay selectable in every mode.
- **Select mode** — marquee selection with the standard window/crossing
  semantics (left→right solid = fully inside, right→left dashed = touched),
  Bodies/Sketches filter chips, a multi-selection info bar, and one-command
  Delete. **Select Through**: long-press lists every body under the point
  by depth.
- **Materials (visualization-lite)** — a Material sheet on the selection
  with presets (Steel, Aluminum, Brass, plastics, Rubber, Wood), custom
  color + metallic/roughness sliders, persisted per body and undoable;
  optional ground blob shadows.
- **Insert Image** — place PNG/JPEG reference pictures from Photos or Files
  on any plane (auto-sized, aspect preserved); move with the gizmo, tune
  opacity/size in the image bar, manage in Items.
- **Symbols** — capture selected sketch entities as a named symbol and
  stamp instances anywhere with tap-to-place; symbols list/rename in Items.
- **Items panel** — bodies, sketches, construction planes, images, and
  symbols with type icons, visibility eye, inline rename, delete,
  tap-to-select, and Zoom To; extruding auto-hides the consumed sketch.
- **Measure** — a selection info bar (face area, body volume, bounding box,
  sketch-entity length/radius) plus a two-point distance mode with X/Y/Z
  deltas over sketch and body snap points.
- **Import/Export** — import STL (binary + ASCII, welded into a solid mesh
  body that booleans like any other), DXF (entities land in a ground-plane
  sketch), and images; export STL, OBJ, 3MF, **GLB**, **USDZ** (where the
  platform supports it, with an **AR Preview** via Quick Look), and sketch
  **DXF** — OBJ/GLB offer a separate-file-per-body option; **PNG
  screenshot** with resolution, transparent-background, and grid options.
- **Undo/redo** — command-based history for every operation.
- **Projects** — a gallery of designs persisted with SwiftData, including
  rendered thumbnails.

## Architecture

```
Kernel/       Geometry: profiles, extrude, booleans, STL, feature-edge
              extraction, behind the `KernelOps` facade. Double precision,
              nonisolated (runs off the main actor), fully unit-tested.
Kernel/OCCT/  The B-rep kernel seam: `OCCTBridge` (Obj-C++, the ONLY place
              OCCT's C++ headers are included) and `OCCTKernel` (the Swift
              API the rest of the app calls). See Geometry kernels below.
Model/        DesignDocument (value type), undoable commands, SwiftData
              persistence with a compact binary mesh format ("OS3D").
Rendering/    Custom Metal renderer: MTKView (on-demand drawing), Blinn-Phong
              "CAD look" shading with per-body material factors, procedural
              anti-aliased grid, feature edges with vertex-shader depth bias,
              MSAA 4x, display-mode pipelines (wireframe/x-ray/hidden edges),
              section clip plane, textured image quads, ground blob shadows,
              gizmo overlay pass, turntable camera + animator, offscreen
              thumbnail capture.
Interaction/  Gesture arbitration, CPU ray-cast picking (AABB + Möller–
              Trumbore), gizmo drag math.
Editor/       EditorViewModel — the mode state machine tying UI, kernel, and
              viewport together. The viewport never mutates the model.
UI/           SwiftUI chrome: gallery, tool palette, numeric input, overlays.
Shaders/      Single Shaders.metal + ShaderTypes.h shared with Swift via
              bridging header (one source of truth for uniform layouts).
```

Rendering conventions: kernel/model math is `Double`, GPU buffers are
`Float32`. Meshes are welded by (position, normal) so hard edges survive;
feature edges come from a 20° dihedral-angle threshold.

## Why these choices?

Commercial direct-modeling CAD apps generally pair a licensed proprietary
kernel — Siemens Parasolid, say — with a renderer written in-house. A licensed
kernel isn't an option for an open-source app, so openshape3d started on an open
mesh library (Euclid) behind a kernel facade (`KernelOps`) that a stronger
kernel could replace later. That replacement is now underway: **OCCT**, the
same open-source B-rep kernel several commercial CAD products shipped their
early versions on.

## Geometry kernels: OCCT + Euclid

### Why two kernels

Euclid is a **polygon-mesh** CSG library: it has no analytic surfaces. A sketched
circle is tessellated to a fixed segment count (`ProfileDetector.circleSegments
= 48`) *before* any solid exists, so "extrude a circle" produced a 48-sided
prism, not a cylinder — visibly faceted, and impossible to fillet properly.
There is no mesh-side fix; the representation itself has to become exact. That
means a B-rep kernel, and the open option is **OpenCASCADE (LGPL 2.1 + OCC
exception)**.

Euclid is *not* being deleted. It stays as the mesh path for ops not yet ported
and as the fallback when OCCT can't build or boolean a shape.

### How they divide today

`Body.brep` holds an optional OCCT solid (`TopoDS_Shape`). When present it is the
**source of truth**: `Body.adoptBRep(_:)` derives *both* the render mesh and the
CSG (`euclid`) mesh from the same OCCT tessellation, so what you see and what
booleans actually cut can never disagree.

| Op | Kernel |
|---|---|
| Extrude (all profiles; circle → analytic cylinder) | **OCCT** |
| Primitives (box / cylinder / sphere) | **OCCT** |
| Boolean between two B-rep bodies | **OCCT** |
| Revolve, sweep, loft, shell, chamfer/fillet, push-pull, pattern, mirror, split | Euclid |
| Extrude-into-target boolean; multi-profile extrudes | Euclid |
| STL import; live drag previews | Euclid |

Smooth shading comes from normals evaluated on the **analytic surface**
(`BRepAdaptor_Surface` D1 → dU×dV), not per-facet — that, plus a size-independent
angular deflection, is what makes a cylinder read as round.

### Known limitations (honest list)

- **Un-ported ops drop the brep.** Fillet or shell a cylinder and the result
  reverts to Euclid-only, so it goes faceted again. Porting fillet
  (`BRepFilletAPI`) is the next milestone.
- **Circular holes are polygonal** — only the outer profile of a circle is
  analytic.
- **The `.os3d` archive doesn't carry the brep**, so export/import degrades to
  Euclid-only. In-app SwiftData persistence *does* round-trip it.
- **iOS slices only** — the xcframework has `ios-arm64` + `ios-arm64-simulator`;
  macOS/visionOS builds would need slices added.
- **STEP/IGES are off.** `DataExchange` + XDE roughly double the static library
  (18 → 47 toolkits, ~74 → ~140 MB/arch), so they're disabled until a feature
  needs them — a one-line flip in `scripts/build_occt_ios.sh`.

Everything B-rep sits behind `OCCTKernel.useOCCTAsSourceOfTruth`; set it to
`false` to fall back to the pure-Euclid kernel everywhere.

### Licensing

OCCT is LGPL 2.1 with the Open CASCADE exception. The app's own code is MIT;
OCCT keeps its own license. Shipping requires the usual LGPL obligations —
prominent notice, license text, and a route for users to relink the library
(the checked-in `scripts/build_occt_ios.sh` reproduces the exact binary).

## Building

**First build only — OCCT must be built once.** The app links
`ThirdParty/OCCT.xcframework`, which is *not* checked in (~190 MB build
artifact). Build it with the checked-in recipe:

```sh
brew install cmake                       # if you don't have it
# OCCT source + an iOS CMake toolchain file, then:
OCCT_SRC=/path/to/OCCT-7_8_1 \
IOS_TOOLCHAIN=/path/to/ios.toolchain.cmake \
scripts/build_occt_ios.sh
```

It cross-compiles a minimal headless OCCT (modeling only — no visualization,
no third-party deps) for device + simulator and assembles the xcframework.
Takes a few minutes; you only do it once.

Then open `openshape3d.xcodeproj` in Xcode 26+ and run the `openshape3d` scheme
on an iPad (or iPhone) simulator or device. The Euclid package resolves
automatically.

Sanity-check the kernel on a booted simulator any time with
`scripts/run_occt_spike.sh` (builds a box and an extruded circle, and asserts
the circle yields exactly one analytic cylindrical face).

Tests: `⌘U`, or

```sh
xcodebuild test -project openshape3d.xcodeproj -scheme openshape3d \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

Unit tests cover the geometry kernel (bridge/weld, blob serialization,
profiles, extrusion conventions, booleans, STL layout) and the OCCT seam
(analytic face types, smooth-normal tessellation, B-rep serialization
round-trip, transform baking); XCUITests drive the real flows
(place → edit → move → sketch → extrude → subtract).

## Roadmap

- Offset edge UI (kernel done), section caps + interference highlighting
- Auto-constraining guides, pattern constraint, spline tangency (Phase C
  tranche 2+); the 2D constraint solver, constraints, dimensions, and sketch
  states already ship (Phase C tranche 1)
- Parametric history sidebar with editable steps (Phase D)
- **B-rep kernel (Phase E) — in progress.** OCCT is live for extrude,
  primitives and booleans (see [Geometry kernels](#geometry-kernels-occt--euclid));
  next up are fillet/chamfer on `BRepFilletAPI`, then shell, revolve/sweep/loft,
  and STEP/IGES
- Keyboard shortcuts + Command Search, face/edge selection filters
- PBR visualization space (environments, per-face materials, capture)
- Fat-line edge rendering, dark mode viewport theme
- Assembly-style grouping (Items folders), SVG/DXF drawing export

See `docs/MODELING_PARITY_GOALS.md` for the ordered sketch + solid modeling
roadmap (fillet, shell, splines, STEP — with acceptance criteria),
`docs/PARITY_SPEC.md` for the feature-by-feature status audit, and
`docs/IMPLEMENTATION_PLAN.md` for phase sequencing.

## License

MIT. openshape3d is an independent project: it is not affiliated with,
endorsed by, or derived from any other CAD application. Product names mentioned
anywhere in this repository are trademarks of their respective owners and are
used only for factual comparison.
