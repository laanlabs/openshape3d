# QA-36 Parallel alignment — September 12, 2026

Partial. Base27a86a2/source9466502. Native Last Selected free pair:
lower600650→700670 becomes600650→700630, upper600600→700580 fixed.
Lower length50871.8061mm and first endpoint preserved; apply deselects.
Clone lower350700→450720 releases1.2606mm, upper350650→4506301.2625mm.
Ordered lower/upper Parallel shrinks lower, moves both endpoints, retains
selection; total2.52→1.66mm. Screenshots inspected, exact before regression
fails0/1 with six geometry/selection assertions.

Correction targets Last Selected two ordinary lines with preferred anchor
transiently fixed, original moving length/direction and first endpoint.
Saved constraints take precedence; no extra persisted dimension. Pair apply/
history selection cleanup. First Selected/multi-line placement unchanged.
First focused1/2: only exact anchor assertion failed at ~5e-15 numerical noise.
Corrected focused2/2 passes after transient anchor fixation. Separate Lock/driver1/1 passed. Final combined, changed live, native history/reopen and publication
pending. No acceptance promotion. Reports1109/master38; inventory26/0/1/29.

Durable evidence: /Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-parallel-live-2026-09-12.
Logs/xcresults: /tmp/os3d-qa36-parallel-{before,focused,focused2,locked}-20260912.
Immutable05be744/iPad unchanged.

## Combined gate and UI fixture correction

Source33f7358 pushed. First combined105/105 model/integration and5/7UI;
two failures at ConstraintRailUITests.swift:199 expected visible glyphs
immediately after successful apply. Corrected fixture explicitly selects
Last Selected, verifies apply deselection, reselects stationary upper line,
then verifies glyph and Undo/Redo selection cleanup. Focused UI rerun pending.
No changed-build paired or publication claim yet.

## Final paired checkpoint

Final corrected112/112 on e834525 (source33f7358):105model/integration+7UI,
zero failures/skips. No runner. Changed clone fresh lower350700→450720
releases1.2606mm, upper350650→4506301.2625mm; Parallel rotates lower to
350700→450680, preserves first endpoint/length and upper, deselects.
Undo restores slope/deselects, reselect then Redo restores Parallel/deselects.
Gallery reopen retains1.2606mm and glyph. Saved JSON retained locally.
Native same history/deselection verified, gallery reopen retains50871.8061mm
at fitted612605→705586. First native Undo screenshot premature while menu
command was still pending; settled undo2.png is valid evidence. First native
Home click inactive, switch then repeat succeeded. Changed clone initial
sheet-transition click did not arm Line, so drag orbited camera without creating
geometry; Exit/reentry restored sketch view before valid fresh creation.

Illustrated1119unique/master38 verified: ten new source hashes exactly once,
headings once, no1109/38 predecessor loss. DOCX exports, manifest, verification,
PNG/actions/test receipts and saved JSON in durable evidence directory.
QA36 remains partial pending finite relation-matrix reconciliation.
