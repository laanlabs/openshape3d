# Crossing straight profiles — September 9

Baseline6c8dd06. Native source03 bow-tie (900,650)→(980,710)→(900,710)→
(980,650)→start exposes independently selected upper/lower triangular faces.
Clone source2 (150,500)→(230,570)→(150,570)→(230,500)→start exposes neither
triangle after Exit/interior taps. All four strokes visible; no intended
intersection endpoint. Existing bodies retained. Profile graph only nodes
chain endpoints; confirmed crossing gap. Initial regression added, no fix yet.
Point-touch first-loop fill also appears absent in this final clone frame;
recheck separately after crossing correction, do not erase earlier passing
partial-overlap/reopen evidence. No new publication yet.

## Red and implementation

Red43043 completed65: new crossing test failed (missing two regions, total area,
and both interior hits). Temporary graph now splits nonparallel straight
intersections, including endpoint-to-interior junctions, preserving source IDs
and original editable entities. Curved chains and collinear overlap remain
unchanged. Added unsplit-divider coverage; green66431 running profile/history/
seed/analytic-arc/spline suites. /tmp/os3d-crossing-green-20260909.log/.xcresult.
No live post-fix or publication verification yet.

Green66431 completed0 clean42/42 (21Profile,2History,3Seed,11AnalyticArc,5SplineProfileEval). No test runner remains; live post-fix recheck underway.

## Live post-fix

Saved bow-tie now exposes independently selectable top/bottom triangles.
Lower triangle extrudes1mm in clone (volume0.26mm³,bounds1.09×0.48×1.00),
native500mm createsBody04. Both Undo remove new solid, Redo restores; both
finalgallery reopens retain prism and prior bore/block. Different scales, no
equal-size claim. Native source remains visible; clone hidden after extrusion
as previously recorded. Earlier partial-overlap first loop still has no fill
before extrusion, so that regression remains open. Publication in progress.

Publication verified: illustrated179 placements/all6 new PNG hashes; master38 final42/42, pairedhistory/reopen and remainingpartial-overlap note. Exports and allcrossing PNGs copied to durable transform-controls reports.
