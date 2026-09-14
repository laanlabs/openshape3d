# QA24 sketch-name interaction — September 12, 2026

Baseline 5c0c142 / body source b5bff74. Native Sketch05 name single click enters
sketching with six edges selected, not Rename. Clone fresh Sketch1 circle name
click opens keyboard and caret, stays out of sketching. Exact images retained
under durable selection/qa24-through-live-2026-09-12:
os3d-qa24-native-sketch-name.png and os3d-qa24-clone-sketch-name-before.png.

Before UI test 0/1, terminal65, unwanted-keyboard assertion:
/tmp/os3d-qa24-sketch-name-before-20260912.{log,xcresult}.
Scoped change sets sketch ItemRowView nameTapSelects true, reusing existing
explicit Rename and initial seed selection. Existing openItemSketch handler is
unchanged; native all-edge selection remains a separate observed gap. PlanesUI
existence assertions use stable identifiers independent of accessibility type.

Focused three UI workflows running exclusively:
/tmp/os3d-qa24-sketch-name-focused-20260912.{log,xcresult}, exec30688.
Coplanar identity workflow has passed; collect terminal and remaining two before
claiming focused completion. No changed live/publication claimed. Inventory
32/0/1/23; QA24 partial; iPad unchanged; immutable05be744 retained.

Corrected focused3/3 passed, terminal0. Source05bed51 pushed. Final combined
selection/identity/Items/folder model and Selection4+coplanar1 UI run active at
/tmp/os3d-qa24-sketch-name-final-20260912.{log,xcresult}, exec60233. No new live
or publication claim yet.

Final47/47 passed on05bed51 (42model+5UI), zero failures/skips, terminal0.
Changed live name entry/no keyboard, explicit whole-seed Rename, direct sketch24
replacement, UndoSketch1/Redo sketch24 and galleryreopen preserve singleline.
Native explicit sketch Rename/history/reopen and publication next. No runner.

## Paired publication verified

Native explicit Rename selects whole Sketch05 seed; direct sketch24 replacement,
UndoSketch05, Redo sketch24 and clean gallery reopen verified. Native selection
clears on Rename Undo/Redo. Entry selects sixedges and Exit retains them; this
separate difference remains open. Clone line geometry/name persists as above.

Illustrated1284unique/1287placements: thirteen new hashes each exactly once,
heading once, no predecessor1271/1274 loss. Master38, heading once/no loss.
Durable sketch-name-assets.json and sketch-name-verification.json under
selection/qa24-through-live-2026-09-12 retain exact inventory/export receipts.
QA24partial32/0/1/23; no runner; iPad unchanged.
