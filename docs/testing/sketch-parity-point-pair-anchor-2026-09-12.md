# Point-pair Coincident anchor correction — September12,2026

Native paired circle/line and rectangle/line FirstSelected fixtures preserve
shape and move only external endpoint, then deselect. Evidence in current
QA38 center/rectangle receipts (illustrated1154/master38). Clone before moves
both halfway and retains zero-readout/selection, despite confirmedFirstSelected.

Before0/1 reproduces both geometry and selection failures; incremental selection
order assertion passed. Solver weld averages slots before temporary whole Lock,
so it freezes the already-moved shape. Scoped correction seeds the free line
endpoint at the preferred shape point before solving. Saved line relationships
and dimensions excluded; general welding/solver storage unchanged. Selection
clearing restricted to observed circle/rectangle point plus line point.
Focused3/3 passed before final predicate narrowing: new paired geometry/history/
JSON test plus prior center drag/Disconnect breadth. Final combined and changed
live repeat pending. /tmp/os3d-point-pair-{before,focused}-20260912.{log,xcresult}.
No new acceptance promotion. Inventory28/0/1/27; iPad unchanged.

## Changed-build gate and live repeat

Final121/121 passed on9e99752, zero failures/skips in one serial run.
Changed circle point-only apply preserves center/radius and far line endpoint;
Undo restores separate endpoint, Redo restores contact. Rectangle clean point-only
selection likewise preserves bounds and moves only external endpoint; Undo/Redo
and gallery reopen of both shapes pass. Durable evidence:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/disconnect/point-pair-live-2026-09-12`.

First rectangle attempt retained the newly drawn whole line before corner
selection (visible manipulation ring/Length readout); it changed rectangle
height and is retained, not counted as a clean point-only comparison. Undo,
blank deselection, corner-first then endpoint selection removes that extra
operand and passes without further source changes. Publication pending.

Publication verified: illustrated1162 unique media, eight new hashes exactly
once, heading once, no loss from1154. Master38 retained, heading once.
Before/after exports and publication-verification.json in durable directory.
No additional source changes after9e99752/final121.
