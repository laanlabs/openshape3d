# QA-36 Perpendicular supporting-line pivot — September 12, 2026

Partial. Base63bcf12/source33f7358. Native ordered Last Selected lower
500650→580670 and upper500600→580580 each43805.7842mm. Perpendicular
keeps upper and rotates lower around infinite-support intersection400625;
expected425725→445805. Settled Zoom to exposes477630→498711 with upper
554502→636481, confirming same camera transform and43805.7842mm value.
Purple extension guides expose the pivot. Initial narrow box selected only
upper; wider second box verified both. Failed scroll foreground commands
not counted. Zoom to required settling; no geometry mutation from camera.

Clone same shape lower350300→4303201.026mm, upper350250→4302301.0275mm.
Ordered Last Selected Perpendicular instead rotates lower about its midpoint
390310 to380270→400350. Length/selection already match, placement does not.
Before regression0/1 fails only two endpoint assertions. Scoped correction
rotates nonparallel ordinary two-line Last Selected pair about supporting
intersection, chooses nearest perpendicular orientation, projects against saved
constraints with preferred anchor transiently fixed. Parallel/degenerate and
First Selected placement unchanged. No persisted extra dimensions.

Focused4/4 passed: exact pivot/length/anchor/history/JSON; existing both-anchor/
order length matrix; saved-point override in First and Last modes. Final
combined and changed-build live/history/reopen/publication pending. No new
acceptance promotion. Inventory26/0/1/29; reports1119/master38; iPad unchanged.
Durable evidence: workspace reports/openshape3d-core-sketch-milestone-2026-09-08/
constraint-types/qa36-perpendicular-placement-live-2026-09-12.
Logs/xcresults /tmp/os3d-qa36-perp-placement-{before,focused}-20260912.
