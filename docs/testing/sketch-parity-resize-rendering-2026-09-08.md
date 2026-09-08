# Resize rendering and landscape keypad — September 8, 2026

Base4c1120e. Peekaboo live mouse; clone iPad13 M5 simulator, native macOS Shapr3D.
Same version/settings as prior milestone receipts. Evidence in workspace
`reports/openshape3d-core-sketch-milestone-2026-09-08/layout/`.

## Paired diagnosis

Clone Untitled2 Top4×1.5 mm rectangle, Circle armed. Rotate via Simulator Device >
Orientation > Landscape Right. Window2386 becomes887×737 (was683×940).
Settled capture (two additional seconds after initial2sec rotation wait) shows
Metal rectanglex174–605,y364–454, while projected corner markers arex292 and534.
`clone-landscape-settled.png`. Opening height badge shows reachable keypad but
same mismatch: `clone-landscape-height-pad.png`. Blank click closes unmodified
editor; Circle tool off triggers a scene redraw. Rectangle nowx292–534,y364–454,
proper4:1.5 aspect and marker alignment. `clone-landscape-after-redraw.png`.
Thus this is a cached frame after resize, not a geometry dimension change.

Native resize command failed with process-generation mutation-receipt error,
no size change; before/after-command images are NOT resize evidence. Physical
window corner drag succeeded:1515×848→1293×743 at99,79. Native Front600×150 mm
rectangle changed projected boundsx243–442,y300–350→x200–373,y268–311, retaining
4:1 aspect and aligned readouts/markers. `native-before-resize.png`,
`native-after-resize-drag.png`. Desktop window resize is the available reference,
not a claim of physical iPad rotation/Pencil testing.

## Correction and checks

Renderer already updates viewportSize and overlay camera epoch in
`drawableSizeWillChange`, but paused/on-demand MTKView needs a redraw request.
Added `setNeedsDisplay()` after size update; no camera/geometry changes.
Serial CameraTests + DimensionUITests passed15/15 clean (11camera,4dimension),
exec38658 exited0, finished08:34:50 EDT:
`/tmp/os3d-milestone-resize-20260908.xcresult`.
Post-fix rotation verified below; publication verified68images, corrected image hash and text.
Landscape keypad fit observed but final layout acceptance pending corrected render.

## Live corrected repeat

Fresh Untitled2 Top4×1.5 rectangle. Portrait boundsx140–463,y456–577;
landscape x292–534,y364–454, with all markers on corners. No canvas interaction
between rotation and capture. Return portrait restores aligned original bounds.
`clone-portrait-fixed-before.png`, `clone-landscape-fixed-no-interaction.png`,
`clone-portrait-return-fixed.png`. Correct proportions remain in both directions.
The capture shell initially yielded while last image was still being written;
inspected it after shell completed, not an application failure.

Tested binarySHA256:
`7a49dcfed7caa38bc954dc021b9bce065ea2b13c71468299cb4206bc048132e6`.
`resize-test-summary.json` retains clean15/15 result. This is a simulator artifact.
Diagnosis67images retained. Corrected export68images, matching PNG hash and
text, plus master roadmap update verified. Initial export preceded image sync
and showed67; subsequent export verified68. Artifacts: published-resize-fixed.docx,
resize-fixed-publication.json, master-numeric-resize.txt.
