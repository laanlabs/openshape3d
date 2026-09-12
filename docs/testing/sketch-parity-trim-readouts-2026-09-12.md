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
