# Constrained endpoint drag — September8,2026

Based984465; native Front1293×743 and clone Top landscape887×736, mouse via
Peekaboo. Same milestone versions/settings. Evidence root workspace
`reports/openshape3d-core-sketch-milestone-2026-09-08/selection/`.

## Paired live diagnosis

Fresh horizontal line native700mm x401–603,y498, clone3mm x171–352,y515.
Select endpoint then vertical drag: native both endpoints move toy455, clone
toy485; line lengths/direction and unrelated rectangles preserved. Different
snap increments mean semantic integrity, not exact pixel-motion parity.
`native-endpoint-selected.png`, `native-endpoint-drag.png`,
`clone-endpoint-selected.png`, `clone-endpoint-drag.png`.

Lock left endpoint: native point turns green, clone lock glyph appears at left
point. `native-point-locked.png`, `clone-point-locked.png`. Direct clone drag on
locked glyph produced no movement, but glyph can intercept, so not sufficient
proof of geometry-lock behavior alone (`clone-locked-drag.png`).

Drag opposite endpoint diagonally right/up. Native keeps left401,455 and extends
right603→632 at samey455. Clone rejects with Constraints conflict, right stays352,
left171,y485. `native-locked-opposite-end-drag.png`,
`clone-locked-opposite-end-drag.png`. Existing horizontal plus fixed opposite
endpoint leaves one free axis; pointer off-axis should not prevent that motion.

## Correction under test

The transient pointer target previously competed equally with saved constraints;
its compromise residual made the editor reject a valid partially constrained edit.
When a drag's structural residual is nonzero, project its attempted solution back
onto saved constraints without the pointer target. Existing conflict gate remains;
contradictory structural constraints must still report failure. No persistent
constraint removed or weakened. Non-drag dimension solve behavior unchanged.

New geometry tests: horizontal and vertical locked-endpoint free-axis motion,
unrelated circle unchanged, rigid driving length retained, contradictory driving
lengths remain conflicting. Existing drag DOF cache, lifecycle and coalescing UI
regressions included in serial run exec88567:
`/tmp/os3d-milestone-drag-projection-20260908.xcresult`.
No passing or post-fix live claim yet. Candidate/history/input gate still open.

## Initial results / diagnostic

Initial run14geometry/constraint checks passed, one historicalDragSolveUI failed:
seven undo steps vs expected six. No count weakened. Added pending Undo/Redo
action accessibility values and test history-title capture to identify the extra
step. First diagnostic failed compilation before tests (incorrect redo-title
reference); fixed to existing redoCommands.last.title. Second diagnostic running
exec76121, `/tmp/os3d-milestone-drag-history-diagnostic2-20260908.xcresult`.
Post-fix live pending. Diagnosis Doc74images and both PNG hashes verified;
`published-drag-diagnosis.docx`, `drag-diagnosis-publication.json`.

Diagnostic2 completed with seven Draw actions, no Move. Video confirms old fixture
left Line armed and used unsnapped pointer coordinates for supposed corner edits.
Replaced it with one rectangle (built-in H/V relations), disarmed tool, rendered
marker coordinates, actual movement/alignment and undo/redo position assertions.
This changes construction setup, not the one-coalesced-edit requirement. Serial
fixture run `/tmp/os3d-milestone-drag-fixture-20260908.xcresult` pending.

Rectangle-marker fixture failed before editing because native rect storage exposes
two diagonal points, not four corners. Exact UI regression now follows the paired
locked-line case; four-line rectangle geometry coverage remains in unit tests.
First locked-line launch was intentionally interrupted to correct the rail's raw
accessibility identifier (`fixed`, not title `Lock`); no test result claimed.
Corrected run: `/tmp/os3d-milestone-locked-drag-ui2-20260908.xcresult`, exec39958.

Locked-line UI2 verified free-axis movement and fixed endpoint, then failed
only the new toolbar action-title assertion (reported Draw instead of Move).
Thus the earlier repeated Draw titles do NOT independently prove actual history
contents; the earlier armed-Line screenshots still invalidate that old fixture.
Next run checks geometry undo/redo directly without relying on the title.
`/tmp/os3d-milestone-locked-drag-history-20260908.xcresult`, exec7390.

## Verified correction,09:11 EDT

Locked-line history run passed1/1: both endpoint positions restore on Undo and
Redo; exactly Draw+Lock+one coalesced edit exhaust history. Combined with initial
14unit passes, NOT one clean combined run. Diagnostic toolbar titles were stale
and removed; no history implementation changed. Earlier failed fixtures retained.

Live fresh landscape Untitled2: left171,515 locked; far352,515. Diagonal pointer
drag toward382,485 yields far383,515, left unchanged,3→3.5mm, no conflict.
`clone-fixed-lock-before.png`, `clone-fixed-lock-after.png`. Native repeat
right632→661,y455 while left401,455 and unrelated rectangles remain unchanged.
`native-locked-drag-repeat.png`. Corrected free-axis movement paired-pass.
Live toolbar/keyboard history delivery is still unverified; automated history
restoration is not a physical-input sign-off.

Live simulator binary SHA256e0c92bc8929490962e12311111f0a2d222f8a12b114f9e4605cd934076ec08ec;
this includes temporary diagnostic toolbar AX titles, removed before commit.
Solver code unchanged after successful geometry/UI/live tests. Publication pending.

Publication verified: illustrated Doc76inline images, corrected native/clone PNG
hashes and text found in anonymous DOCX; master text update verified. Local
`published-drag-fixed.docx`, `drag-fixed-publication.json`, `master-drag-fixed.txt`.
