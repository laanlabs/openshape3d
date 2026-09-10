# Untouched rounded dimension seed — September 10, 2026

Baseline `da96a6d`; native macOS Shapr3D and portrait iPad simulator, mouse input.
Native 20 mm horizontal line shows 0.0656 ft in its editor. Accepting without
editing creates the lock; switching back to mm still shows 20 mm and identical
endpoints. Clone fresh ~2 mm line shows 0.0066 ft annotation but 0.007 seed;
untouched commit lengthens its right endpoint from relative423456 to433456,
with left endpoint261456 unchanged. This confirms geometry drift, not just
formatting. An older expression-driven clone line was excluded from this free
fixture comparison.

Evidence: `/tmp/os3d-seed-native-original-mm.png`,
`/tmp/os3d-seed-native-editor.png`, `/tmp/os3d-seed-native-after-mm.png`,
`/tmp/os3d-seed-clone-fresh.png`, `/tmp/os3d-seed-clone-editor.png`,
`/tmp/os3d-seed-clone-after.png`. Prior publication384/master38 verified;
new diagnosis images local only. Red exact measurement/history regression is
running; no corrected live result yet. Immutable IPA unchanged.

## Regression / correction

Red `/tmp/os3d-rounded-seed-red-20260910.xcresult`: one test failed three
assertions, showing 40→39.9288 mm. Correction separates exact measured mm/degrees
from the rounded seed, while changed drafts and retained expressions continue
normal evaluation/conversion. First corrected keypad run clean21/21:
`/tmp/os3d-rounded-seed-20260910.xcresult`. Expanded combined keypad/UI and tiny
length/angle boundary checks running; live corrected result pending.

## Final verification and limits

Expanded combined run clean23/23, zero failed/skipped:
`/tmp/os3d-rounded-seed-combined-20260910.xcresult` (22unit +1UI).
Includes exact original geometry/lock history, stored-dimension reopening,
changed-draft returning to seed text, tiny positive length displaying zero,
rounded arc sweep and real imperial keypad commit/conversion/Undo.

Live corrected fresh clone2mm opens0.007ft and commits to unchanged0.0066ft;
metric return shows2mm with endpoints relative261577/423577 unchanged.
Toolbar Undo shows open lock; Redo shows closed lock, same2mm geometry. Final
clone gallery reopen retains2mm. First immediate Settings unit tap did not apply;
settled sheet recheck/retry succeeded and the unsuccessful image is not counted.

Native history qualifier: Undo after untouched commit affected the prior circle
operation, not the line; Redo restored that circle. Subsequent line endpoint drag
translated the20mm line without changing length, then Undo restored its location.
Therefore the initial lock-creation interpretation is limited to visible icon/
held-length evidence; native untouched-commit history is NOT declared equivalent
to clone lock history. Native gallery reopen was not repeated in this batch.
No speculative native-history change is included in this geometry correction.

Evidence directory:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/rounded-seed/`.
SHA256SUMS retains diagnosis and corrected seed/mm/history/reopen images.
Publication export verified391 placements, all7 new image hashes exactly once,
no predecessor loss versus384; `/tmp/os3d-rounded-seed-publication.docx`.
Master38 media/new+prior+final-reopen note verified:
`/tmp/os3d-rounded-seed-master.docx`. No runner; immutableIPA unchanged.
