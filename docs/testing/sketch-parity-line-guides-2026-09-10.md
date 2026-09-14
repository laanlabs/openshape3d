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

## Follow-up angle matrix (after983e3f7)

Native explicit target/synthOnly scroll returned success via local runtime, and
--no-remote scroll also returned success, but inspected geometry did not zoom.
Do not attribute a zoom to those commands. After View>Front/re-entry, however,
200px now spans26.6825mm versus earlier20.8168mm, establishing a changed scale.
Guide-on/Auto-off200×10 (2.86degrees) remained sloped26.7158mm;200×-2
(0.57degrees) snapped horizontal26.6825mm withoutglyph. Local follow-up images
os3d-qa07-native-above.png and-native-below-second.png. Clone secondscale pending.

Clone Option-drag reported success but showed no pinch; subsequent canvas drags
(upper/lower, local/bridge, fresh Line selection) produced no geometry while
toolbar clicks worked. Gallery reopen fit the saved line much larger, but plane
canvas clicks remained ignored. Standalone press option was rejected as unknown
key. No app failure/root cause asserted. Saved line retained; app-only relaunch
used for recovery, not Mac/simulator restart. No pending geometry discarded.

Settings-dismissal UI diagnostic passed1/1 at
/tmp/os3d-line-guide-settings-ui-20260910.xcresult: guide-only drag createsone
history entry, noH, Undo removes andRedo restores. Subsequent fresh Untitled2
live canvas still showed no response to taps/drags, though plane selection and
toolbar work. Explicit Simulator I/O>Input>Send Pointer to Device didnot visibly
restore drawing. Rootcause unproven; no host permission change requested.
Independent drag-path integration matrix now running withthe UI diagnostic,
exec37600 /tmp/os3d-line-guide-drag-followup-20260910.xcresult. Geometry scales
0.01/1.0 are automated model scales, not live zoom evidence.

Drag integration + Settings UI follow-up completed clean3/3 at
/tmp/os3d-line-guide-drag-followup-20260910.xcresult (no skipped/failures).
No runner remains. Parent subsequently authorized restarting only affected
Simulator/app/input bridge. Scoped shutdown/boot of os3d-unit UUID6490492B
started; Shapr3D/report tabs/other simulators and immutableIPA untouched.

## Recovery and changed-scale verification

Scoped os3d-unit shutdown/boot finished successfully; new Simulator window7715
at72,30,683x940, app33148. Fresh live170x9 drag now visibly creates sloped
2.112mm. Guide-on/Auto-on170x-2 snaps2.103mm/H; inspected AutoOFF then settled
170x-2 repeats snaps2.1mm/noH (first immediate-dismissal drag excluded). Gallery
reopen retains3lines; Items icon re-enters original plane at saved scale. Fit
control(global381148) changes scale;170x9 staysraw1.164mm and170x-2 snaps
1.161mm/noH. Native changed scale26.6825mm/200px both above/below already captured.
Illustrated440placements/438media/all6newhashesonce/no loss vs434 andmaster38
recovery note verified via /tmp/os3d-line-guides-recovery.docx and-recovery-master.docx.
No new product code; initial35 plus focused1 plus expanded3 are separate cleanruns.

## Tighter boundary diagnosis — not closed

Native GuideLinesON/AutoOFF:200x4 snaps26.6825,200x6 staysraw26.6945.
100x4 also snaps13.3412 (2.29degrees), but100x5 staysraw13.3579. Vertical4x100
snapsvertical. Longer300x6 staysraw, but endpoint also acquired another guide
(~15pxshorter), so do not use its length as clean inference evidence.
Clone200x4 staysraw1.364mm, and short60x2 staysraw0.411mm. At~0.596imagepx per
iPadpoint this is~100x3.35logicalpoints, whereas native100x4pointssnaps. Native
AutoON100x4 snaps and addsaxisglyph13.3412. This supports screen-space acquisition
near4points, independent of existing angular saved-inference setting; requires
focused implementation/verification. Do not merely increase1degree default.
Boundary images currently local-only, not included in440publication.

## Screen-distance correction under regression

Line-specific guide acquisition uses four logical screen points via camera scale;
other inference retains existing tolerances. Saved H/V raw-aim gate uses the same
band when Guide Lines is on. Initial combined35 finished33passed/2failed: Float
ray roundoff at the exact4point boundary, and a Settings fixture targeting a
clipped switch. Tiny relative numerical slack and sheet-scoped scrolling now
rerunning the same35 in distance-corrected result. No post-fix live claim yet.
Failure video25s shows Auto row below medium sheet;29s shows sheet dismissed.
Exact mistaken target cause remains inferred, not a product Settings defect.
Illustrated diagnosis export445placements/443media/all5hashesonce/no predecessor
loss vs440; /tmp/os3d-line-guides-distance-diagnosis.docx. Master38 remains prior.

Second combined distance-corrected run34/35: all33unit and normalchainUI pass;
SettingsUI failed because its window-bottom swipe was below the floating sheet.
Inspected38s recording confirms sheet bottom above window bottom. Fixture now
uses Done-relative content swipes and bidirectional visibility checks; same35
rerunning at /tmp/os3d-line-guide-distance-sheet-20260910.xcresult. No product
Settings change or post-fix live claim.

Third distance-sheet run34/35, same unit/normalchain passes; strict sheet-relative
visibility helper failed before Grid. Both ineffective scrolling helpers removed.
Focused direct switch.tap diagnostic now checks actual Settings workflow without
extrapolating offscreen AX coordinates. All failed runs retained.

Direct switch.tap diagnostic failed before Guidepoints: offscreen Form rows are
virtualized, requiring container scroll before query. Next focused run uses
Form UICollectionView swipeUp plus switch.tap; no product changes added.

Form scrolling diagnostic reached Auto but its tap left value1: inspected38s
video shows Auto clipped at bottom while reporting hittable. Fixture now requires
whole switch frame inside visible Form bounds before tapping. Focused visible
run follows. Master38 boundary note and prior recovery reopen clarification
export-verified at /tmp/os3d-line-guides-distance-master.docx; media preserved.

Visible-row diagnostic still left AutoON after direct tap. Reinstated thumb
coordinate after Form-bounds check, retaining container-based scroll. Focused
settings-thumb run pending. No passing Settings result claimed from these runs.

## Corrected live repeat and persistence

Final Settings thumb-target diagnostic passed1/1 at
/tmp/os3d-line-guide-settings-thumb-20260910.xcresult. Thus35distinct relevant
checks pass across runs:33unit plus normalchain1 in34/35, finalSettings1. This
is not one clean combined run. Failed fixtures retained, not product regressions.

Exact installed build, GuideON/AutoOFF:60x2desktoppx horizontal snaps0.745mm,
60x3 remains sloped0.744mm;2x60 snapsvertical0.742mm/noV. Live Undo removes
only vertical and Redo restores it. At Fit-changed scale60x2 snaps0.364mm,
60x3 staysraw0.363mm. Screenshot scale~0.596px/UIKitpoint; these are inside/
outside samples, not exact physical-device boundary measurements. AutoON via
inspected thumb drag:60x2 snaps0.364mm/H. Click alone didnot toggle; excluded.
Native repeat100x4 snaps13.3412mm/axisglyph. Native gallery reopen retained20
edges and reselected13.3412mm glyph; clone retainedall6lines acrossbothscales,
reselected0.364mm/H. Clone returns stored sketch view scale rather than temporary
Fit scale; geometry persists. Native trial prompt skipped without purchase.
Screenshots /tmp/os3d-qa07-distance-*.png copied to local line-guides evidence/hash
manifest. Nine final images inserted once in illustrated; exportverification
pending (expected454placements). QA07 not fully closed: finish signed/reverse
boundary variants before finite recipe signoff. Immutable05be744IPA unchanged.

Final publication verified: illustrated454placements/452media, all9newhashesonce,
no predecessor loss vs445. /tmp/os3d-line-guides-distance-final.docx. Master38
final live/reopen note verified, no predecessor media loss:
/tmp/os3d-line-guides-distance-final-master.docx. No further product edits after
passing unit33 and finalSettings1. Next signed/reverse samples; QA07partial.

## QA-07 finite closure

At pushed eb9b4ab, native reverse(-100,-4) snaps/glyph,(-100,-6)raw15.05mm;
clone(-60,-2)snaps0.742/H,(-60,-3)raw0.742. Cloneoutside also shows a different
inferredrelation; raw slope remains, not claiming generalnon-axisparity.
Both finalgalleryreopens retainnewpair: clone8lines/native22edges. Six closure
screenshots local/hashmanifest and insertedonce in illustrated; exportpending.
QA07 originalrecipe near-horizontalabove/below atseveralzoomlevels nowpassed;
H/V/signedreverse/historysupplementit. GeneralQA19snapcategories/hover/device
remainopen. Inventory4passed/0failed/1deviceblocked/51incomplete (40partial11deferred).
No furtherproductchanges/tests since35distinctpasses; nextQA08remainingquadrants.

Closure publication verified: illustrated460placements/458media, all6closurehashes
once/no loss vs454; master38closure/finalreopen note present/no media loss.
/tmp/os3d-line-guides-closure.docx and-closure-master.docx. QA07passed scopeabove.
