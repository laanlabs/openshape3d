# QA24 body item-name interaction — September 12, 2026

Baseline f1e6ebb. Native Items Body05 single name click selects the whole body;
right-click exposes explicit Rename. Clone Box2 single name tap instead focuses
inline rename and opens the keyboard, without selecting the body. Paired images
are retained in selection/qa24-through-live-2026-09-12 under durable reports.

Before regression 0/1, failing the no-keyboard assertion:
/tmp/os3d-qa24-itemname-before-20260912.{log,xcresult}.
Scoped correction changes body names only to tap-to-select labels and adds an
explicit context-menu Rename action opening the existing inline editor. Other
item types retain their existing behavior, not presumed parity. Body existence
assertions use stable ItemName identifiers independently of accessibility type;
rename workflow explicitly invokes Rename. No geometry/model command changes.

Focused selection and Items visibility/rename/Delete/Undo UI workflows running:
/tmp/os3d-qa24-itemname-focused-20260912.{log,xcresult}, owner exec48324.
No final result, changed-build live or new publication claimed. Current inventory
32/0/1/23; QA24 partial. iPad and immutable05be744 unchanged.
