# QA24 Items sketch selection — September 12, 2026

Native named sketch entry selects all six owned edges and enters sketch mode;
Exit retains the six selected edges in model mode. Native Rename Undo/Redo
clears selection. Retained paired name-route publication contains exact native
entry, Exit (local), and history screenshots. Clone05bed51 enters with no selected
IDs and clears on Exit. No geometry change is intended.

Before model0/1 reproduced empty entry/Exit selection. New Items-only
selectItemSketch wrapper selects named entities; untouched all-entity selection
survives Exit. Selection changes invalidate the scope; unrelated openItemSketch
callers remain passive. Focused8/8 (identity6 +coplanar/name UI2) passed.

Extended Rename history assertions then failed0/1 on both Undo and Redo. Scoped
model-mode sketch Rename history now clears retained IDs, leaving active sketch/
tool history unchanged. Focused identity6+bodyRename1 running at
/tmp/os3d-qa24-sketch-item-history-focused-20260912.{log,xcresult}, exec7188.
Before receipts use sketch-item-selection-before and sketch-item-history-before,
all same date. No broad final, changed live or new publication claimed yet.
HEAD27cc8db; source uncommitted; inventory32/0/1/23;iPad unchanged.

Corrected history focused7/7 passed, terminal0. No runner. Source checkpoint
being committed before broad final gate; changed live/publication pending.
