# Expression field width — September 10, 2026

Baseline 0e2f312 pushed. Native mixed imperial source fits the visible editor;
clone saved source scrolls/clips inside a hard-coded 96-point field in both
keyboard and keypad mode. Inspected evidence:
/tmp/os3d-mixed-imperial-native-source.png,
/tmp/os3d-mixed-imperial-saved-source.png,
/tmp/os3d-mixed-imperial-saved-keyboard.png.
Native macOS and portrait iPad simulator scale/font differences remain; this
change addresses source visibility, not a claim of identical field styling.

Field width now follows measured caption/semibold source text with caret margin,
bounded 96–320 points. Existing measured editor positioning clears the rails.
No geometry, source evaluation or focus changes. Strengthened the existing lower
editor UI workflow with mixed source, expanded field, on-screen/above-keyboard
commit and keypad switching assertions. The existing focus/recovery test also runs.

Serial exec68473 owns simulator; /tmp/os3d-expression-width-20260910.xcresult
and .log. Live post-fix portrait/landscape and publication pending. Immutable
05be744 IPA unchanged.

Final focused run clean2/2, zero failures/skips; exec68473exit0. No runner.
Live fresh circle source0.00125ft+0.025in fits portrait keyboard/keypad and
landscape keyboard/keypad, with commit clear of software keyboard. Landscape
commit1.016mm inspected. Native source0.025ft+0.5in remains fully visible when
switching to keypad. Native light chrome versus clone dark chrome is retained
as a theme/platform comparison limitation, not claimed identical styling.
The UI tests reset the disposable clone gallery; prior circle evidence remains
in the earlier receipt, fresh clone sample used here. Publication pending.

Final clone gallery reopen retains1.016mm and complete expanded source, screenshots
/tmp/os3d-expression-width-saved-{value,source}.png. Native gallery not repeated.
Illustrated373/all5 new hashes exactlyonce/no predecessor loss verified in
/tmp/os3d-expression-width-publication.docx. Master38 media/new+prior notes and
final gallery note verified in /tmp/os3d-expression-width-master.docx; illustrated
final note text verified in /tmp/os3d-expression-width-final.txt. Local originals
and SHA256SUMS in reports/.../expression-width/. No runner remains.
