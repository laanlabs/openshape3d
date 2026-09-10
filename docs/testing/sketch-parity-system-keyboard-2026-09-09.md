# System-keyboard dimension continuation — September 9, 2026

Baseline bda21f7 pushed. Immutable05be744 IPA unchanged. No physical keyboard/
Pencil testing; macOS hardware-key delivery into native and iPad simulator.

Native selected line29.0517mm: field keyboard icon hides numeric pad, keeps
variables affordance and offers123 toggle back. First typing20 replaces seed;
Return commits20mm. Screenshots os3d-keyboard-native-pad/field/first-entry/commit.
Clone fresh line2mm: switching hides numeric pad, removes variables affordance,
offers only commit (no123). Explicit foreground typing1 appends21. Prior
auto-routed background typing produced an ambiguous character and is excluded
from first-digit diagnosis; foreground route is inspected and authoritative.
Cancelled clone21 without committing; original2mm remains.

Confirmed gaps: system-keyboard seed replacement and missing return-to-pad route.
Variables visibility also differs. Preserve already-entered drafts when switching.
Focused red UI test at /tmp/os3d-system-keyboard-red-20260909.xcresult exec33057
now owns simulator. No product correction yet.
Evidence reports/.../system-keyboard/. Publication pending. QA33/40 partial.

Red regression reproduced the product failure: seed1.5 plus typed1 became1.51,
not1. First assertion failed; no later assertions ran. Untouched-seed selection
on field-focus now implemented, with123 return-to-keypad and variables retained
in either route. Real typed drafts clear the replacement flag. Focused corrected
run exec1867 /tmp/os3d-system-keyboard-fix-20260909.xcresult active.

First corrected test passes seed replacement and keyboard-toggle draft retention,
then fails because invalid Return leaves12+ editor without keyboard focus.
Native initial repeat accidentally operated outside the field; that attempt
changed view/selection and is excluded. Recovered with menu-verified Cmd4 Top,
reentered line, inspected field first, then actual2+ Return retained focus;
following1 typed without refocus yields2+1 and clears warning.

September10 focus correction restores only the same rejected edit session after
Return. Serial9keypad+system-keyboard+click-away UI run exec52810 at
/tmp/os3d-system-keyboard-focus-20260910.xcresult. No concurrent desktop.
Four initial diagnosis images inserted once; export verification pending.

Focus correction final run clean11/11 (9keypad unit+system-keyboard and click-away
UI). Native2+1 draft survives123 return-to-keypad toggle. Exact-build clone live
repeat underway; tests reset disposable gallery. Diagnosis publication verified
292placements/all4hashes/no predecessor loss at
/tmp/os3d-keyboard-diagnosis-publication.docx. No runner.

Final live clone seed2 replaced by1,123 toggle preserves1, plus added on keypad
then systemReturn retains1+ with yellow warning. Typing0.5 without refocus
produces1+0.5 and clears warning;Return commits1.5, toolbarUndo restores2mm.
Native2+ Return retains focus; immediate1 gives2+1,123 toggle preserves draft,
keypadcommit3 thenCmdZ restores20mm. Native shows f(x) marker for arithmetic
formula; clone simple arithmetic has no marker. Input-route changes are verified,
not full formula/annotation parity. Native session also remembers system keyboard
on reopening an editor; clone preference resets, pending controlled comparison.
Observed line anchors differ (nativeleft vs clonecenter); compare matched fresh/
reselected construction direction before changing solver. Final6images prepared
for publication; prior292 diagnosis verified.

Final illustrated publication export verifies298placements/all6newhashes once
and zero predecessorloss (/tmp/os3d-keyboard-final-publication.docx). Master
new dated note inserted; export verification pending. No runner.

Master export verifies38images, Keyboard-route recovery checkpoint once and
prior polygon note retained (/tmp/os3d-keyboard-master.docx). Ready for source
checkpoint; continuing controlled line-anchor comparison, not stopping here.
