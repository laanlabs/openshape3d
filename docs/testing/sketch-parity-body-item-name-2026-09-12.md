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

Focused2/2 passed, zero failures, terminal0 on8fbcac5 source. Explicit contextmenu
Rename/Delete each encounters60-second missing-animation-notification waits,
but both complete; single-tap selection passes in12.9seconds. Final combined
selection/identity/Items/folder/pattern model+UI gate now running exclusively at
/tmp/os3d-qa24-itemname-final-20260912.{log,xcresult}. No final/live claim yet.

Final broadened gate passed48/48 (41 model/integration and7 UI), zero failures or
skips, terminal0 on8fbcac5. Includes selection/identity, Items commands, folder
structure and real folder/rename/Delete/Undo/marquee/Select Through/pattern/split
workflows. No runner remains; changed live and publication next.

Changed live on8fbcac5: name tap selects whole4mmBox without keyboard, explicit
Rename opens editing, corrected exactpart24 commit and twoUndo/twoRedo restore
Box/part24 (first clear-field input miss created an intermediate name), gallery
reopen preserves onebody namedpart24. Native explicitRename selects wholeoldname;
typingpart24 directly replacesBody05. Native Undo/Redo clearsbodyselection; clone
keepsit. These additional seed-selection/history gaps are now under before tests;
no source correction or new publication yet. Native images retained locally.

Rename-semantics before0/2 reproduces four history selection/mode assertions and
UI exact-name failure. Scoped initial untouched seed selection now uses the
existing deferred UITextField notification pattern; body RenameItemCommand Undo/
Redo clears selected/primitive modes without changing other tool history.
Focused3 tests running at /tmp/os3d-qa24-rename-semantics-focused-20260912;
no post-fix result/live claim yet. Native Redo also remains deselected.
