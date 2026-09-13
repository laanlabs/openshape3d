# QA24 Select Through targets — September 12, 2026

Baseline89dbafc. Native right-click→Select Through This Point→foreground Return
at sketch/body overlap exposes two faces, Body05 and Sketch05 Profile. Clone
long-press with visible source sketch exposes only Extrude. Earlier native
long-press probes produced hover feedback, not chooser evidence. Clicking the
native Profile row subsequently showed profile/extrusion controls, but the
apparent selected region differed from the menu label; exact identity remains
unverified and must not be counted yet.

Before0/1: zero face candidates versus two expected. Face-only correction8/8;
typed face/profile suite9/9. Final broadened run **26/26**, zero failures/skips: SelectionTests, SelectionUXTests, SketchIdentityTests and two Selection UI workflows.

Implementation adds all ray surface hits, deduplicates planar topology faces,
retains body candidates and their additive API, and adds visible occluded sketch
fills. Face choice selects existing face context; profile choice arms existing
zero-distance extrusion. No geometry commit follows selection. Curved smooth
walls are excluded from planar face choices, retaining whole-body selection;
full curved-face/edge candidate parity is not claimed. Tests verify front/back
planes, source identities, no geometry mutation, Cancel and hidden/stale profile
suppression; legacy body order remains separately asserted.

Evidence: durable selection/qa24-through-live-2026-09-12 under core-sketch reports.
/tmp/os3d-qa24-through-{before,faces,typed,final}-20260912 logs/xcresults.
Changed-build live on ab6fb2d verified first/top and second/occluded planar face
selection at 0 mm. A fresh 2 mm circle on the middle box appears as Profile—Sketch1;
choosing it arms zero-distance extrusion on that exact circle. Cancel and gallery
reopen preserve all three boxes and the circle, with no extra extrusion. An initial
back-face retry hit a readout rather than opening the chooser and is excluded.

Publication verified: illustrated 1258 unique images, eleven new hashes each once,
no loss from the 1247 predecessor; master 38 media, one checkpoint heading and no
loss. Durable publication-verification.json records exact inventories and export
hashes. Exact native Profile identity and curved-face/edge breadth remain open.
QA24 partial; inventory 32/0/1/23; iPad unchanged.

Reference routes: https://support.shapr3d.com/hc/en-us/articles/7770768736924-Selecting-geometry
and https://support.shapr3d.com/hc/en-us/articles/12469688911516-Create-sketches .

## Native identity follow-up

Fresh chooser again names Sketch05 Profile. Selecting its current accessibility
node elem_24 highlights the pentagon at the original probe, with Sketch05 selected
in Items and Sketch05/Extrusion05 in filtered History. Exact native identity is
now verified. Earlier coordinate-only click selected unrelated Sketch12 geometry;
retain that failed input receipt, not a product discrepancy. Publication follow-up verified: 1259 unique media and 1262 placements, versus
1258 unique/1261 placements before; master38. Fresh chooser was byte-identical
to retained evidence, so the initial two-image upload was undone and only the
new correct pentagon selection inserted. Both hashes exist once as media; one
net placement added, no predecessor loss, each follow-up heading once. No extrusion
was committed. Curved-face/edge and remaining selection breadth still open.
