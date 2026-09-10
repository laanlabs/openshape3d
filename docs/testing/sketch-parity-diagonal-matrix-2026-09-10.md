# Diagonal rectangle remaining live matrix — September 10

Baseline b59abcf (product eb9b4ab). No source edits or tests running.
QA07 closed/published460; this begins QA08 remaining mixed-quadrant checks.
Earlier up-left/down-right and normalized lower-left rules retained, not repeated.

Native existing Sketch03 line fixture hidden via Items eye after model-mode
exit/clear/hover; all22lines preserved. Empty Front Sketch04 created. Diagonal
1000,350→800,500 global down-left produces30x22mm (screen bounds local
x710–901,y271–411). Width30→15 holdsleft710,movesright901→806. After Escape
and left-edge reselection, height22→11 holdsbottom411,movestop271→341;
width stays15. Both edits keypad1/5 or1/1 thencommit, inspected screenshots.
Files /tmp/os3d-qa08-native-downleft-release.png, -width15.png, -height11.png
(with full prefix os3d-qa08-native-downleft-). No publication claim yet.

Clone prior eight-line Untitled preserved; fresh Untitled2 created via gallery.
Currently modelmode empty, no rectangle yet. Exactnext draw down-left and edit
both sizes, comparelowerleft; thenup-right/height-first counterpart, history,
reopen and relevant regression if changes or current-revision gap justify.
No physicaldevice/IPAchangerequest. QA08 remains partial.

## Paired diagnosis and correction under test

Clone down-left release1.989x1.494 became1x0.75; left268 andbottom440
remainedfixed. Native15x11 likewise holdsleft/bottom. Sample geometrypasses.
Visiblegap: native down-left widthleaderabove, clonebelow. Freshup-right
native31x19 heightleaderright; clone1.979x1.481 heightleaderleft. Captures
/tmp/os3d-qa08-{native,clone}-downleft-* and native-upright-release-valid.png,
clone-upright-release.png. Native r shortcut attempt didnotarmtool and earlier
upright-release.png is excluded; More/Rectangle validrepeat producedsecondrect.
Historical Sept8 up-left capture confirms top/right; down-right bottom/left.

Correction uses persisted firstcorner metadata for default leader sides only,
without changing lower-left sizing geometry. Explicit selectedside wins; center
and legacy rectangles retain defaults. Reload/allfourdirections/selectededges
unit coverage added. Serial focused regression starts; livepostfix and publication
pending. No IPA modifications. QA08 remains partial.

## Clean regression and live post-fix

/tmp/os3d-qa08-leader-sides-20260910.xcresult passed25/25,0failed/0skipped
in onecleanrun:22RectangleConstruction,1new persistedleader/selectededge test,
2RectangleWorkflowUI. Unit tests reset clone gallery; freshUntitled2 created.
Postfixdown-left widthabove/heightleft andup-right widthbelow/heightright match
native references. Cloneup-right1.979x1.481→1.979x0.75→1x0.75 holdsbottom720
andleft229(local). Native31x19→31x9.5→15.5x9.5 holdsbottom621,left551.
NativewidthUndo via hotkey cmd,z restores31,redo cmd,shift,z restores15.5.
ClonetoolbarUndo restores1.979,Redo1;editedheightretained.

Excludedattempts: firstcloneheightclick at508705 missedlabel(center508690),
startedpendingrectangle; Escape via press didnotcancel it, nextclick committed
extra rectangle. ToolbarUndo removed onlyextra,Rectbuttonexplicitlydisarmed.
Two intendedrectangles preserved; successfulnumericchecks use inspectedcenter.
Native press cmd+z didnotundo geometry; supported hotkey did. Notappfailures.

Illustrateddiagnosis verified466placements/464media,allsixnewhashesonce,
no predecessorloss vs460; /tmp/os3d-qa08-diagnosis.docx. Postfixpublication
andgalleryreopenpending. Evidencecopiedto reports/.../diagonal-matrix with
SHA256SUMS. No runner; uncommittedproductcorrection remains underliveverification.

## Saved recovery and publication blocker

Paired gallery reopen passed: clone1x0.75 with right-side size restored; native
15.5x9.5 andprior15x11 retained. Explicitcloneleft-edgeselection movesheightleft,
provingoverridepriority. Native trialprompt dismissed withSkip, noaccountchange.

Postfixpublication attempted once but Google session signedout. Illustratedt18
nowread-only/requesteditaccess; mastert19 explicitly says signedout/signinfrom
anothertab. Fresh /tmp/os3d-qa08-postfix-publication-check.docx stays466 and
postfixheadingabsent. No newimagesinserted; allpostfixevidence local. Restoring
authorized Googlelogin viahost-owned signin resolves; never requestsecrets.
Parentnotified. Sourcefix cancommit; publicationpendingnotclaimedcomplete.

## Next confirmed control gap

84ca2aa leaderfix pushed. Native clearedselection andclicked lowerrectangle
center global758670: centerselects, drag40right20down translatesentirerect
withoutsizechange (localbounds572746538644→612786558664). Undoissued;
restorationnotyetrecaptured. Clonecenter341719 clickselectsnothing,drag40/20
orbitscamera instead. Centercontrolmissing; alsoonlytwooppositecornermarkers
vsnativefourhollowcornersandcenterdot. Native/clone centerselected/centerdrag
captures retained locally. No productcenterfix yet. Trace: SketchHitTester
rectcontrolPoints has4corners/no center; modelPoints has2solvercorners;
pointmarkers onlymodelPoints. Existingdirectapplying center excludesrect.
Centertranslationmustpreservesizeandrespectsavedlocks/relations, not bypasssolver.
Currentclonecameraorbited; restoreTop beforefurtherpairedchecks. Googleblocked.

Centerkernel initial23/23 passed. Visiblecenterdot/controlPoints center, rigid
translationroute andwholeentitytap selectionimplemented; isolatedrectusesexplicit
Move/Rotate ratherthandefaultring. NewUIcenterdrag/historytest underway with
23geometryandselectededgeUI. NonexistentSketchHitTesterTestsfilterrequested
accidentally; nocoverageclaimed. Extra2cornermarkers andnativecenter-specific
selection/Locksemantics remainopen; nolivepostfixclaimyet.

CenterUI run25/25 clean. Live freecenter249403373513bounds→289443393533
local (40right20down), noorbit. Thenwidth1/height0.75saved; centerdrag40/20
keeps1x0.75,toolbarUndo/Redorestorepositions. ClonewholeLockrefusescenterdrag.
NativecenterLock on15.5x9.5 similarlyrefuses with 'Locked point can’t be moved.'
TheseLockscopesdiffer, so no generalizedcenterLockparityclaim. Clonewas silent;
existingconstraintnotice added, numeric-noop normalized intranslationkernel,
UIassertion added thatUndoafterrefusal removesLock ratherthanphantommovement.
Finalserialexec34992 owns simulator:/tmp/os3d-qa08-center-final-20260910.xcresult.
Latestnativecenterlocked; clonewholelocked beforetestreset. Livefinalnotice,
reopen,currentfinalpublicationattemptpending. Googleloginstillblocked.

## Center-drag correction: final verified checkpoint

Final `/tmp/os3d-qa08-center-final-20260910.xcresult` passed 25/25 in one clean
run (23 geometry + two UI workflows), including refused-drag notice and Undo
removing Lock rather than a no-op movement. No failed center runs; the earlier
23/23 kernel and 25/25 UI runs are separate preliminary checks.

Final live clone: locked center drag shows the existing constrained-movement
notice and leaves geometry unchanged. Unlock then center drag moves the entire
rectangle 40 screen pixels right and 20 down, retaining 1.913 × 1.736 mm. Gallery
reopen retains that position, unlocked state, center dot and dimensions. The
preceding driven 1 × 0.75 mm sample also passed movement and Undo/Redo live.
Native center-only Unlock likewise restores translation; gallery reopen retains
15.5 × 9.5 mm and the other 15 × 11 mm rectangle. Native view fits on reentry,
so saved-position assessment uses the relative geometry, not identical pixels.

The UI-test fixture reopened locked after the test ended with Undo. Immediate
termination/autosave timing is not a new proven persistence failure; the live
Unlock → move → gallery path saved correctly. Retain this observation for the
history/persistence matrix rather than claiming universal coverage.

Remaining differences: clone center tap selects the whole rectangle and shows
both dimensions, whereas native selects a center point with its local Lock
control. Native center-only Lock scope is not implemented by this change.
Clone still lacks two corner markers. No full QA-08 closure claim.

Google publication remains blocked by sign-out; final evidence is local with
SHA256SUMS and the pending-publication receipt. No IPA modification or install.

## Four-corner marker correction under test

Centerdragfix3c6a8b6 pushed. Confirmed nativefourhollowcorners+center vsclone
twocorners+newcenter. Addedmissingoff-diagonalcornermarkers. Sharedsolver
analysisclassifieseachcornerusingitsownX/Yvariables; partialsideLockpins
correcttwo corners, pinnedmin+width determineslower-rightbutnotuppercorners.
No solvervariables added, nohit-targetchanges; existingfourcornerdragtargets
retained. CenterUItestnowassertsall4markersandbounds/history. Serialexec1285
/tmp/os3d-qa08-corner-markers-20260910.xcresult/log running. Livepostfixpending.

Cornerregressionclean31/31 (6pointstate+23rectangle+2UI). Liveall4corners
pluscenter appear; leftsideLock correctlychangesonlyleft2cornerstosquares.
InitialLockclickimmediatelyafterselectiondidnotapply; settledrepeatdid, captured
in corners-left-lock-valid. Existinghollowpointfill inheritsdarkchrome and
appearsblackagainstlightcanvas, unlike nativewhiteinterior. Fillnowfixedwhite
(90%opacity), no size/stroke/hit change; buildexec1649 at
/tmp/os3d-qa08-point-fill-build-20260910.log. Needinstall/relaunchonlyclone
simulatorapp, inspectfreecorners andpartiallock; retain31/31 aspre-fillregression
pluspostfillbuild/live (do notclaimsame-final-tree31run). Googleblocked.

### Final corner-style comparison (September 10)

Post-fill build succeeded; live `fill-free` and `fill-reopen` confirm light
interiors and preserved saved partial Lock. Fresh native 18×12 rectangle after
settled tool arming shows four hollow corners. Locking its left edge makes left
corners green hollow while right corners remain blue hollow (`native-corners-left-locked`).
Clone square locked corners therefore remain a confirmed visual gap; corrected
rectangle-only hollow state styling is under final regression. Existing line/arc
point glyphs are not generalized from this sample. Initial immediate arm/draw
produced a pending point, was discarded and excluded; settled repeat succeeded.
Publication remains blocked; screenshots and hashes retained locally.

### Rectangle corner correction verified (September 10)

Final regression clean **30/30**, zero skipped/failed, at
`/tmp/os3d-qa08-corner-final-20260910.xcresult`: six point-state tests,
23 rectangle geometry tests, one center drag/history UI workflow. Prior31/31
included one additional UI workflow before final styling; do not combine counts.
Only indentation changed after the final build.

Exact-build live clone shows four light hollow corners; left-edge Lock produces
two green left corners and two blue right corners, matching the native sampled
point-state convention. Whole Lock shows all four green hollow. Clone toolbar
Undo returns all corners blue; Redo restores partial green without geometry
movement. Gallery reopen retains partial Lock and marker states. Native latest
hotkey Undo sample reselected the edge but did not visibly clear Lock; therefore
that particular native history repeat is inconclusive, not a paired history pass.
Native partially constrained edge colors still differ from clone and remain open.
Center-point selection/Lock scope remains open; QA08 remains partial.

Final captures: `native-corners-left-locked`, `final-partial`, `final-undo`,
`final-redo`, `final-reopen-state` under the os3d-qa08 prefix in diagonal-matrix.
All copied and hashed locally. Google signed-out blocker persists; no new
publication claim beyond illustrated466/master38. Immutable05be744IPA untouched.

### Center-only Lock resize diagnosis

Corner correction c634c30 pushed. Native fresh18×12 center-only Lock then
width9 preserves midpoint and height12, unlike clone's whole-entity selection
from center dot. New focused regression is running against unchanged solver;
no center implementation claim yet. Evidence center-native-widthselected and
center-native-width9 copied/hashed; publication still blocked.

Center Lock regression reproduced two assertions on old solver (4.5 midpoint
drift, translation allowed). Corrected fixed-midpoint residual passed clean30/30
kernel+pointstate suite at center-lock-kernel xcresult. UI routing is now under
combined regression; no post-fix live claim yet. Derived rectangle centers expose
only supported local Lock, not unsupported point relationships.

Initial center UI run failed no-label assertion (2 labels). Live mouse point
selection succeeded; center Lock width1.913→1 preserved center and height1.736.
The touch beginSketchEntityDrag path still selected whole entity; corrected to
point scope. New local Lock glyph covered center; now offset40 below center.
Followup combined running; retain failed run and do not claim final UI pass.

Touch follow-up ui2:30 kernel passed, UI refusal failed because fixture toggled
already-selected center off. Explicit clear/select and Unlock assertion yielded
ui3 focused1/1 pass. Extended numeric final run found no width labels and crashed
unchecked optional; guard/capture added and touch center→edge transition now
clears center point/set edge. Final2 pending. Preserve every intermediate run.

### Center-only Lock final regression and live result

Final2 clean31/31:24 rectangle geometry,6 point-state,1 strengthened UI. Result
`/tmp/os3d-qa08-center-lock-final2-20260910.xcresult`. Prior red kernel2assertions,
UI1/no-label failure, UI2/selection setup failure, UI3focusedpass, and extended
final fixture crash retained. Final2 explicitly checks selection, refusal,
center-locked halfwidth midpoint/height preservation and numeric Undo/Redo.

Exact-build live: center point orange only, Lock glyph below rather than covering
it; center-locked drag refused. Width0.957→0.5 preserved local midpoint362,464
and height1.736; Undo0.957/Redo0.5. Unlock permitted40right20down translation;
relock and gallery reopen retained movedcenter402,484, savedwidth0.5 and Lock.
Native width18→9 centered at849,417, height12 preserved before reopen. Native
reopen trial modal7759 then blocked supported focus/capture: project1924 click
rejected because modal focused; modal/screen capture reports indeterminate
web-focus error. No native persistence failure or new paired reopen pass claimed.
All screenshots locally copied/hashed. Google still signed-out; publication pending.

### Broader regression and recovered native reopen

35382d4 broader RectangleWorkflowUITests passed clean15/15, zero failures/skips
at `/tmp/os3d-qa08-center-lock-rectangle-suite-20260910.xcresult` (463.879s).
No runner remains. Supported `see --mode screen --no-web-focus` saved an inspected
image despite AX error: an earlier openshape3dUITests-Runner crash dialog covered
the Shapr3D trial prompt. Dismissed Ignore (failed fixture xcresult retained), then
Skip immediately worked. No Shapr3D/Simulator restart or host security change.
Native gallery-opened Sketch04 re-entered/NormaltoSketch: middle9×12 and green
locked center retained (`os3d-qa08-native-center-reopen-values.png`). This closes
the previously pending paired center-Lock persistence sample. Earlier failed
modal deliveries/capture errors are retained, not attributed to native persistence.
Google remains signed-out; this result and new image are queued locally only.
