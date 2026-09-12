# Edge keypad layout samples — September8,2026

Revisione004769, latest tested executable7a49dcfed7caa38bc954dc021b9bce065ea2b13c71468299cb4206bc048132e6.
Mouse-operated landscape iPad simulator887×736, native resized1293×743. Same
settings as milestone. Evidence root `reports/openshape3d-core-sketch-milestone-2026-09-08/layout/`
under OpenClaw workspace. Actual iPadOS compact window and Pencil not tested.

Clone bottom-right rectangle3×1mm,boundsx504–686,y545–606. Height badge opens full
keypadx586–744,y492–636,clear of constraint railx752+,commit reachable. Typed0.5
commits3×0.5,bottomy606 held,topy575. `clone-landscape-edge-pad.png`,
`clone-landscape-edge-halfheight.png`. First attempted edge drag produced no
geometry; subsequent inspected drag produced the stated case, not two rectangles.

Native More→Rectangle (keyboardR had not armed it) creates700×250mm near bottom
rightx747–949,y556–628. Height keypad fitsx557–797,y487–698,commit visible.
Typed125 halves height,topy592,bottom628; width visually unchanged. Captures:
`native-edge-height-pad.png`, `native-edge-halfheight.png`. Native text/Return
used; clone keypad digit/decimal/commit clicks used. Semantic fit/resize comparison,
not identical app dimensions, scale, input or full layout coverage.

Clone Settings toolbar click did not open sheet; right-palette check blocked by
live input-delivery issue, not marked passed and no speculative settings fix.
Compact-window/system-keyboard and remaining quadrant/sequence matrix stay open.
Continue independent selection/editing acceptance while retaining those gaps.

No source change or extra test run for these samples. Relevant latest suite is
clean15/15 Camera/Dimension on e004769 source. Illustrated Doc72inline images,
text and all4new PNG hashes verified by anonymous DOCX export:
`published-edge-layout.docx`, `edge-layout-publication.json`. Full audit preserved.
