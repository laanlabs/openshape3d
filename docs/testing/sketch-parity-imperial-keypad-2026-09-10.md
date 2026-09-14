# Imperial keypad unit row — September 10, 2026

Baseline647fd42 pushed. Native saved Foot editor exposes parentheses, ft, in,
deg; clone saved Inch editor still exposes parentheses,mm,cm,m,deg. Paired
screens /tmp/os3d-imperial-annotation-native-saved-source.png and
/tmp/os3d-imperial-annotation-saved-source.png are published in illustrated380.
Native/clone source values differ by scale; row tokens are the confirmed gap.

NumericKeypad now selects ft/in/deg for inch or foot display settings and keeps
metric units otherwise. Token recognition includes both families regardless of
visible keys; no evaluator or model geometry change. New real UI test selects
Inches in Settings, enters0.05in through keypad, expects quote readout and exact
Undo; restoresmm. Existing lower keyboard/source workflow plus keypad unit tests
run serially as65463 at /tmp/os3d-imperial-keypad-20260910.xcresult and.log.
Live post-fix comparison/publication pending. No physical install/IPA changes.

Clean22/22 combined (2UI+20keypad), no failures/skips, exec65463exit0. Updated
clone9987 relaunched. Simulator frame remained landscape while test device was
portrait, producing sideways gallery; supported Rotate Right resynchronized it.
First gallery click in sideways frame did not open design; no app defect claimed.
Fresh clone circle1mm inFoot mode exposesft/in/deg. Native keypad0.05ft and clone
keypad0.0025ft commit withcentersfixed. NativeCmdZ/ShiftCmdZ and clone toolbar
UndoRedo restore original/edited geometry. Clone finalgalleryreopen retains
0.0025ft/source andimperial keys. Nativegallerynotrepeated inthisbatch (prior
notation batchpairedreopenstands). Unit-key text spacing differs (native0.05ft,
clone0.0025 ft); no fullstylingclaim. Untouchedfree seedstillroundsthree decimals,
next measurement-no-op diagnosis. Four publicationimagesprepared; verificationpending.

Publication verified: illustrated384/all4 hashes exactlyonce/no predecessor loss
in /tmp/os3d-imperial-keypad-publication-final.docx. Initial380stale, no duplicate
insertion. Master38/new+prior+finalreopen note in /tmp/os3d-imperial-keypad-master.docx.
No runner. Next untouched rounded-seed commit diagnosis, not yet a proven failure.
