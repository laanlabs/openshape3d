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
Changed-build live, exact native candidate identity, publication and closure
remain pending. QA24partial32/0/1/23; reports1247/master38; iPad unchanged.

Reference routes: https://support.shapr3d.com/hc/en-us/articles/7770768736924-Selecting-geometry
and https://support.shapr3d.com/hc/en-us/articles/12469688911516-Create-sketches .
