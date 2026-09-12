# Explicit inches — September 10, 2026

Baseline ef27d62 pushed. Native circle30mm accepts1in→25.4mm, with f(x).
Clone circle1mm accepts0.05in but silently shrinks to0.05mm instead of1.27mm.
Draft and result inspected in both apps: /tmp/os3d-imperial-native-draft.png,
native-result.png, clone-draft.png and clone-result.png (same prefix).
Parser tolerates suffix, but keypad unit recognition omitted in, so conversion
was skipped and token was wrongly classified as a variable formula.
Correction recognizes keyboard-only `in` without adding a compact keypad button;
length conversion maps to DisplayUnit.inches. Identifier boundary prevents `pin`
from being misread as inches. Focused conversion/source/reopen/UndoRedo regression
added for mm and cm display settings. Serial parser/keypad test is running:
/tmp/os3d-imperial-unit-20260910.xcresult and matching log.
Live corrected result, publication and commit pending. No feet/quote/mixed-imperial
or physical input claims. Existing IPA unchanged.

## Verified correction

Clean33/33 parser/keypad tests, no failures/skips, exec74077 exit0. Updated app
relaunch and saved tinycircle recovery:0.05in→1.27mm, centerunchanged, source/f(x)
retained. Clone toolbarUndo restores0.05mm,Redo1.27mm. Nativefirst arrow clicks
rotatedview, nothistory; excluded, opposingrotation restoresview. CmdZ correctly
restores original30mm geometry, CmdShiftZ25.4mm, source reopens1in. Clonegallery
reopen retains1.27mm and0.05in. Nativegallery not repeated inthisbatch. Screens
/tmp/os3d-imperial-fixed-result.png, fixed-undo.png,fixed-redo.png,saved-source.png,
native-source.png,native-undo-key.png,native-redo-verified.png (sameprefix).
Local evidence reports/.../imperial-unit/SHA256SUMS. Publicationpending.

Publication verified: /tmp/os3d-imperial-publication.docx has357 placements, all4
new hashes once/no predecessor loss. /tmp/os3d-imperial-master.docx has38 media,
new/prior headings once and no media loss. Inserted finalsource image inspected.
