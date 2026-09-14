# Shared-edge profiles / construction dashes — September 9

Baseline603d6b2. Native Sketch03 existing rectangle567500–660593 extended
with three lines660500→720500→720593→660593. Clone Sketch2 rectangle
300650–450750 extended450650→525650→525750→450750. Shared boundary
is one existing edge, not a duplicate. Left and right interiors each select only
their respective profile in both apps. No body created; clone preview cancelled.

Native selected divider660546 → Make Construction1190710. Dashed divider
no longer separates profiles: interior610550 selects the whole outer rectangle.
Clone selected450700 → Construct61696; interior375700 selects whole outer
region. Functional boundary exclusion matches, selected-state color differs.

Confirmed visual gap: native divider has compact dashes; clone has two very
long strokes and a large gap at this zoom. SketchTessellator used fixed0.5/0.3
model-unit dash/gap. Added viewport-scale option (8/4 screen points); selected
and unselected EditorViewModel construction paths now supply worldPerPoint.
Legacy no-camera callers retain original default. New multi-scale test checks
bounded screen dash size, gap and endpoint coverage; existing construction
commands/profile exclusion and15 ProfileTests included in serial1296.

Current run /tmp/os3d-construction-dash-20260909.log/.xcresult in progress;
no desktop interaction during runner ownership. Post-fix live repeat, history,
reopen and publication pending. os3d-touch-* PNGs copied to durable
transform-controls reports. No tiny tolerance/duplicate-edge/point-touch/
self-intersection or device-ready claim.

## Post-fix verification

Serial1296 completed0, clean24/24 (9 ConstructionProjectFlow +15 Profile).
Updated app relaunched after tests. Saved divider reopened with compact dashes;
selected/unselected Front states inspected. Make Regular, Undo construction,
Redo regular inspected; Undo again leaves construction for final gallery reopen.
Native Undo regular / Redo construction inspected. Both final reopens retain
construction divider/merged region and existing bore. No geometry-code change.

Scroll rejected twice by bridge: foreground=true required even with default
focus. One snapshot publication failure during attempted scroll, retry worked.
No live multi-zoom claim: scale invariance is automated-only. Fit after reopen
barely changed framing and is not a distinct zoom sample. Front and oblique
states inspected. Curved construction dash phase/pattern not sampled here.
Publication inserted; export verification pending.

Final publication: illustrated160 media, all5 new PNG hashes and addendum
verified; master38 final reopen/test note verified. Export copies local.
