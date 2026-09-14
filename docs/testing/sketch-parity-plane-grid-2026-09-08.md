# Non-ground sketch grid — September 8, 2026

## Paired reproduction

From native Top view, Sketch reopened the existing audit sketch. Exit and
orientation-cube double-click returned to oblique modeling. Sketch then displayed
No active plane; choosing the upright right-hand origin tile entered Front,
normal view, visible grid and axes, new empty Sketch 02. Exit without geometry:
Items retained only Sketch 01. No trial/purchase started; existing disposable
audit project reused because new-project command showed a trial offer.

Clone: new disposable Untitled 2, Sketch → Line, blue upright origin tile.
Camera settled to Front, but grid and axes were completely absent. Repeated
settled capture confirmed blank canvas. Both camera labels read Front; coordinate
axis conventions differ (native Z-up; clone Y-up), so named-view behavior is
compared, not equal plane-enum names. Ground grid was visible earlier in this
same clone configuration, ruling out a globally hidden-grid preference.

Evidence: milestone workspace reports `planes/native-oblique-picker.png`,
`native-picked-right.png`, `native-empty-exit-items.png`, `clone-picker.png`,
`clone-front-entry.png`, `clone-front-settled.png`. Native entry screenshot has a
nonblocking tutorial tip; grid/axes are visible around it. All inspected.

## Confirmed cause and correction

Renderer/shader built the grid only on world Y=0 and used viewDir.y for fade.
After normal alignment to an upright plane, the ground grid is edge-on. New
ViewportScene.gridPlane follows activeSketch.plane; nil uses existing ground.
Uniforms carry sketch origin/basis; quad center projects camera target onto the
plane. Grid lines use local coordinates, axes use world-direction colors, and
grazing fade uses plane normal. Modeling and screenshot grid-disable semantics
remain unchanged. No document geometry, units, snapping or stored schema changed.

## Verification result

Serial PlaneTests + CameraTests + PlanesUITests at
`/tmp/os3d-milestone-grid-20260908.xcresult`, log same prefix. Completed 07:13 EDT: 21/21 passed, zero failures/skips, one clean run. No Peekaboo simulator interactions during tests. Paired
post-fix Front/Right/Top checks completed; publication export verification pending.
Do not infer all-plane coverage, offset-plane parity or physical Pencil readiness.

## Live post-fix result (07:14–07:18 EDT)

Clone Front grid/axes restored (`clone-fixed-front.png`), Right grid/axes visible
(`clone-fixed-side.png`), ground Top retained (`clone-fixed-ground.png`). Native
Right origin entry shows grid (`native-side-entry.png`), Top re-entry retains grid
(`native-top-reentry.png`). Native/clone Front empty exit both leave no empty item;
clone Items reads No sketches yet (`clone-fixed-empty-exit.png`). No geometry was
needed to reproduce the rendering defect. Model view returns to ground-grid
behavior; edge-on modeling views may have no ground grid, outside this sketch fix.

Built executable SHA256 `c0ea005f51a9295670ccd089fc93001511caac1c02371358e139a861b45528be`.
No tests running. Local image pairs retained; no iPad installation.

Publication verified: `published-grid.docx` anonymous export contains41inline
images and corrected-outcome text. Exact bytes of all5new grid screenshots
(native Front, clone Front before/after, native/clone Right) appear in export.
Ground and empty-exit screenshots retained locally. Metadata `grid-publication.json`.
