# QA-07 — Directional acquisition versus saved constraints

September10, baseline e832350 (product68e97b3). Work in progress.
Native Front/macOS versus clone Top/iPad simulator; different scales, not device equivalence.

## Paired observations

Native acquisition categories all off (Grid, Sketch Guide Lines/Points, 3D points,
distant edges), hints on. Clone initially Grid/Sketch/Face points all on and Auto
on. Matched clone acquisition off and Auto off; first Face toggle did not change,
repeated and inspected. Initial drag during sheet dismissal did not create a
segment, excluded. Valid clone170px×6px drag retained slope, 2.107mm, noH. Native
200px×7px retained slope20.8295mm; 200px×-20px retained20.9206mm. Native scroll5
attempt did not visibly change zoom; no second-scale claim.

Auto on with all native acquisition off: 200px×7px and200px×2px remain sloped,
no axis glyph. Clone Auto on/point acquisition off at170px×2px flattened and
added H. Native separate Sketch Guide Lines toggle ON then200px×2px flattened
and added axis glyph. Native Auto OFF, Guide Lines ON: valid200px×2px repeat
flattened without glyph. First guide-only drag produced no visible segment and
is excluded. Native exact horizontal Auto-on lines previously received glyphs
with Guide Lines off; near-axis acquisition is the distinct behavior.

## Scoped correction under regression

Added persisted Sketch Guide Lines toggle, default on. Line H/V acquisition is
independent of saved Auto-constrain relations. With Guide Lines off, near-axis
raw aim is preserved; exact-axis auto relations may still be inferred. With
Guide Lines on/Auto off, geometry snaps but no persistent constraint is emitted.
Existing H/V inference opt-out still prevents saved relation. Drag preview,
release, tap-chain and hover use the same rule. Other guide relations not claimed.

Runner exec35134 owns simulator: /tmp/os3d-line-guides-20260910.xcresult and.log.
Selected LineGuideAcquisition, AutoConstraintEngine, LineDeleteInput and LineChainUI.
Results, live post-fix and publication pending. No candidate refresh/device claim.
Local screenshots: reports/.../line-guides/SHA256SUMS. Last published425/master38.

## Initial verified results and cleanup follow-up

Initial33/33 clean (/tmp/os3d-line-guides-20260910.xcresult), then editor-path and
persistence2/2 clean (/tmp/os3d-line-guide-workflow-20260910.xcresult). Live clone
GuideLinesoff/Autoon preserves170px×2px slope withoutH; GuideLineson/Autooff
flattens170px×2px withoutH. Raw earlier line unchanged. Undo removes only new
line; Redo restores it; gallery reopen retains both. Native matching guide-only
Undo/Redo passed; final reopen is currently behind recurring trial prompt, not
yet inspected. Last build review found hover guide cleanup needed; added clear
and assertion, final combined35 checks running exec9656 at
/tmp/os3d-line-guides-final-20260910.xcresult and.log.

Live switches: several pointer clicks (including synthOnly) did not change
standard Guide Lines/Grid toggles. Slight offset toggled Guide Lines; direct
thumb drag reliably set Guide Lines/Grid/Auto states, inspected before drawing.
No speculative switch implementation change. Scroll command actually returned
INVALID_INPUT requiring foreground=true despite no CLI flag; no zoom occurred.
Sheet content direct drag reached Auto section. This is a tool-route limitation.

Diagnosis publication429/all4 new hashes once/no predecessor loss versus425
verified via /tmp/os3d-line-guides-diagnosis.docx. Post-fix publication pending.

## Final combined result and publication

Final combined35/35 passed with zero failures/skips at
/tmp/os3d-line-guides-final-20260910.xcresult. No runner remains. Native recurring
trial prompt dismissed using inspected Skip action; saved lines visibly retained
in final model-mode reopen capture. Illustrated434 placements/432 media, allfive
post-fix hashes once, no predecessor loss versus429; master38 media and dated
QA07 note verified by anonymous exports /tmp/os3d-line-guides-final.docx and
/tmp/os3d-line-guides-master.docx. Earlier running statements above are historical.
Finalbinary launched25964. First gallery coordinate click rejected because
Shapr3D remained frontmost; explicit app switch resolved it, no app bug inferred.
Current exact-build on/on follow-up underway; secondscale remains open.

Final exact-build GuideLinesON/AutoON inspected settings then170px×2px drag
snapped horizontal2.103mm withH, matching native prior on/on. Screenshot
os3d-qa07-final-on-on.png is local-only follow-up. No further product changes.
