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
