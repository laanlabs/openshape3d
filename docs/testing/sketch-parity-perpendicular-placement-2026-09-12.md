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

## Final changed-build paired verification

Source `c73f126`. Final114/114 passed in one serial run, zero failures/skips
(107 model/integration +7 UI), `/tmp/os3d-qa36-perp-placement-final-20260912.xcresult`.
Changed clone lower275375→295455 keeps1.026mm, upper350250→430230 fixed.
Undo restores350300→430320; Redo restores the pivot rotation; both clear
selection. Gallery reopening retains the relation and1.026mm. Native Undo
restores554553→636573, Redo477630→498711; gallery reopen561569→576629
retains43,805.7842mm and supporting-line guides, fixed upper618475→678459.
The trial overlay was dismissed through its Skip accessibility element; failed
coordinate clicks on the overlapping modal are retained, not counted. Normal
to Sketch animation settled before inspecting the reopened geometry.

Illustrated1129 unique placements/master38 verified: ten new source hashes
once, one heading per report, no predecessor loss from1119/38. Durable
publication-assets.json/publication-verification.json and before/after DOCX
record the gate. clone-reopened-sketch.json preserves serialized state.
This resolves the documented midpoint-pivot mismatch for the scoped Last
Selected free pair. No blanket First/Last/reverse/locked parity claim. QA36
remains partial pending finite matrix reconciliation; inventory26/0/1/29.
