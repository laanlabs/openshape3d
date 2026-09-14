# Trim readout interception — September12,2026

Native Trim hides readouts. Fresh polygon left-edge midpoint deletes only that
edge. Clone retains selected polygon count badge; same midpoint opens keypad.
Off-badge point on same edge trims correctly. Line readout also stays visible.
Before regression0/1 fails polygon and line suppression assertions; restoration
and geometry checks pass. Scoped sketchDimensionLabels guard returns empty only
for Trim, preserving selection/document and other tools. Focused11/11 clean,
zero failures/skips: new suppression/Exit restoration +10 Trim tests.
Receipts /tmp/os3d-qa41-readouts-{before,focused}-20260912.{log,xcresult}.

Fresh paired rectangle boundary/Undo, whole arc/Undo, bounded arc and polygon
geometry checks precede fix; changed-build exact badge-position tap pending.
Evidence workspace reports/openshape3d-core-sketch-milestone-2026-09-08/trim/qa41-live-2026-09-12.
Combined gate and publication pending. QA41partial; inventory28/0/1/27;
iPad/immutable05be744 unchanged.

Audit clarification: the September11 polygon test constructs five ordinary
lines, not the native `.polygon` entity. Current live polygon trimming does
exercise primitive explosion; do not describe that older model test as a
primitive-polygon regression. Existing source explicitly explodes rect/polygon
loops into surviving lines. A production-representation guard is still useful
for the final finite QA41 receipt.

Final123/123 clean on2016713, zero failures/skips. Changed clone fresh pentagon
R0.4979 count5: Trim hides labels; former count-overlap midpoint removes only
left edge, no keypad. Undo/Redo/gallery reopening pass. Native polygon Undo/Redo
visually passes, but first immediate gallery reopening restored the left edge.
Not counted as native persistence pass. Repeated trim then explicit Escape and
Exit Sketching leaves open polygon in model mode; currently waiting for gallery
upload before another reopen. No cause claimed for first native discrepancy.

Native repeat now verified in normal sketch view: four pentagon edges remain after explicit Escape, Exit Sketching, completed gallery upload, reopen and Normal to Sketch. Evidence os3d-qa41-native-final-reopened.png. Earlier immediate-reopen restoration remains unresolved, excluded from pass; no cause inferred. Changed clone and native preserved unrelated geometry. Publication inserted twelve assets plus master checkpoint; export verification pending. No runner.

## Final publication and finite acceptance

Illustrated1174 unique assets, twelve new hashes exactly once, one heading, no1162 predecessor loss. Master38, one heading, no predecessor loss. Before/after DOCX, publication-assets.json and publication-verification.json retained beside screenshots. QA41 finite primitive recipe passed; inventory29/0/1/26. QA43 driven-reference/history live comparison remains separate. Final123/123 clean source2016713; no runner. No new native immediate-reopen claim.
