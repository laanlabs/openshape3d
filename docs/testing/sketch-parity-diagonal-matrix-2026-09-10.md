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

### Center padlock appearance and direct action

Native center-selected screenshot shows small black unboxed padlock; clone
emoji/blue box changed to unboxed SFlock.fill12pt with22pt hit area. Focused1/1
passed; live new appearance and old glyph select/Delete/Undo worked in clone.
But native comparison disproved interaction equivalence: clicking its padlock
changed palette Unlock→Lock immediately. Subsequent Delete removed rectangle
because center remained selected; Undo restored geometry with unlocked center.
This is a direct Lock toggle, not generic constraint selection. Native9×12 restored;
no source sketch lost. Captures glyph-native-clicked/deleted/restored preserve this.

Now direct center control is shown for selected center both free/locked, toggles
existing scoped Lock command, uses black icon; generic centerLock badge suppressed
when only edge selected. Other constraint glyphs unchanged. UI test now exercises
Lock→Unlock→Lock using control before refusal/symmetric resize/history. Run
/tmp/os3d-qa08-center-direct-toggle-20260910.xcresult pending. No final claim yet.

### Direct center padlock targeting diagnosis, 12:08 EDT

Second targeted UI attempt (`center-direct-toggle2`) failed after explicit AX-center tap; after-tap capture still showed free center and the subsequent button query disappeared. No passing claim. Live clicked the visible glyph at global434,518 after gallery reopening: palette Lock→Unlock, center and all four corners unchanged (`os3d-qa08-direct-selected.png`, `os3d-qa08-direct-tapped.png`). Automatic Peekaboo host routing briefly fell back to a daemon without permissions; selecting the existing GUI bridge restored input without host/security changes. Frame diagnostic running before any speculative product hit-testing change.

Frame diagnostic failed1/1: button frame(539,662.5,22,22), marker frame(547.5,631,5,5); synthesized tap(550,673.5) is its advertised center. Rendered transparent background attempt also failed1/1 and was removed. Testing explicit full-canvas GeometryReader container next; no unsupported root-cause claim. Receipts `/tmp/os3d-qa08-center-direct-frame-20260910.xcresult`, `/tmp/os3d-qa08-center-direct-surface-20260910.xcresult`.

Full-canvas container and outer button contentShape attempts each failed1/1 and were removed (`center-direct-container`, `center-direct-shape` xcresults). Temporary input logging now distinguishes delivered canvas coordinates from control action; no solver changes.

### Delivered touch path confirmed

`center-direct-trace` failed1/1, but its temporary log is decisive: after selecting center at(550,633.5), the padlock tap arrived at Metal `gestureTapped` at(550,673.5), and the button action did not fire. This is the exact advertised icon position, not an XCTest coordinate miss. Live mouse click used the SwiftUI action successfully. Removed all transient NSLog/print tracing. Added scoped padlock hit dispatch ahead of ordinary canvas picks, sharing the same40pt offset/22pt bounds with the visible button; this follows existing gizmo control routing. Focused `center-direct-dispatch` now verifies Lock→Unlock→Lock plus refusal, sizing and history.

Canvas-dispatch focused run: first Lock succeeded, immediate second label assertion failed before unlock was observed (`center-direct-dispatch`,1/1failed). Touch uses single-tap recognizer delayed by double-tap disambiguation. Test now waits for each exact required label transition (3s bound), rather than assuming immediate state; this is not yet a passing result. Local direct-input captures and trace copied to retained report with refreshed hashes.

`center-direct-settled` passed1/1 (50.501s): each direct Lock/Unlock/Lock transition completed, refused movement did not add a history step, half-width edit preserved center/height, and numeric Undo/Redo restored values. Shared visibility gating now used by both drawn control and canvas dispatch. Final combined33-case run underway before live post-fix repeat; prior failures remain in audit.

Remaining visual observation from retained same-state native `glyph-native-clicked`: selected center has an orange halo around its small orange core; clone currently colors only the5pt dot orange. Not included in padlock action fix or claimed matching. Partial-edge colors remain separate/inconclusive until paired isolation.

### Combined pass and native settled-state correction

Initial combined `center-direct-final` passed clean33/33, zero skipped/failed,166.360s. Exact-build live clone directUnlock, Undo, Redo and relock changed only the lock state; all corners stayed fixed (`toggle-clone-before/unlocked/undo/redo/relocked`). Native repeated free→Lock twice cleared center selection and hid padlock, while locked→Unlock kept it selected (`toggle-native-free/locked/locked-selected/unlocked/relocked`). Prior assumption that both operations retain selection is withdrawn. Native center remains9×12 at same coordinates; originals unaffected. Scoped direct-control lifecycle now mirrors this asymmetry; palette Lock unchanged. New combined regression underway, not counted until result. Native selected-free halo differs from selected-locked center; do not generalize a universal selection halo yet.

### Final direct-padlock verification, September10 12:39 EDT

Final lifecycle-adjusted regression PASSED clean33/33, zero failures/skips,173.583s: `/tmp/os3d-qa08-center-direct-lifecycle-20260910.xcresult`. Includes24 rectangle geometry,6 point states,2 constraint UI and1 extended center UI. This is a clean final run after the retained failures/diagnostics above, not an unbroken first-attempt pass. No test runner remains.

Exact-build live clone: selected locked center→directUnlock retains orange selection/padlock; directLock clears selection/padlock and shows green center. All four corners remain at local(324,394),(401,394),(324,534),(401,534). One toolbarUndo restores blue/free center, Redo green/locked; gallery return/reopen/re-enter/reselect shows Unlock and the same rectangle. Images `lifecycle-clone-before/unlock/lock/undo/redo/final-reopen`. Native same-state repeated toggles show identical Lock-versus-Unlock selection lifecycle; cmd-Z/shift-cmd-Z restores blue/green center without moving middle9×12 rectangle or original shapes. Galleryreopen→Skip→Sketch04→NormaltoSketch→center reselect retains Unlock (`lifecycle-native-undo/redo/final-reopen`). Native initial post-prompt doubleclick was too early; repeated after inspected settled model state, no persistence failure.

All image originals and SHA256SUMS retained in report diagonal-matrix. Google publication remains blocked by signed-out existing tabs; nothing beyond illustrated466/master38 claimed. QA08 remainspartial: partial-edge colors, state-specific center halo/other glyph visibility and publication unresolved. Physical input/device equivalence unverified; immutableIPA untouched.

### Selected free-center halo diagnosis

69d3ad3 pushed successfully. Follow-up native pointer moved away from selectedlocked center: nohalo (`halo-native-locked-away`). DirectUnlock then moveaway: selectedfree center still hasorangehalo (`halo-native-free-away`). Clone samefree-selected state lacks it (`halo-clone-free-before`). Thus not generic hover or everyselectedpoint. Added16pt/25% orangehalo onlyselectedfree rectanglecenter; existing5pt core/hit bounds unchanged. Existing centerUIworkflow under regression; no new paint-mirroring test. Evidence copied/hashed locally; Google signedout.

Halo correction verified: existing center drag/Lock/sizing/history UI passed clean1/1(56.896s) at `/tmp/os3d-qa08-center-halo-20260910.xcresult`. Exact-build live savedlockedcenter selected→nohalo; directUnlock→freecenter retainsorangehalo afterpointermovesaway (`halo-clone-locked-after`, `halo-clone-free-after`), matching native state-specific sample. Hit bounds/core/geometry unchanged. Comparison establishes the visual state cue, not exact physical iPad/macOS pixel equivalence. No runner. Documentation local-only pending sign-in; IPA unchanged.

### Partial-edge-color continuation/input diagnosis

Halo0877725 pushed. More/Rectangle native armed; first drag rejected unsupported `--foreground` option, noaction. Valid900ms drag650,280→800,390 and click650,280 only movedbluecursor/guidepoint; no fresh rectangle exists. Earlier pendingpoint description withdrawn. Escape disarmedtool; blankclicks/secondEscape left centerselection. Explicittargeted foreground/global/synthOnly click now pendingexec40943. Read-only capture attempted whilecallpending returnederrorwithimage, notsuccessfulinputverification. No appfailure or edgecolorrule inferred; originalsintact.

### Partial-edge colors: recovered native input and perpendicular confirmation

The explicit synthOnly input call40943 completed after ~31s with no visible
selection change. No native geometry failure inferred. Exit Sketch/re-enter
Sketch04, clear selection, re-arm Rectangle restored the same draw route; a fresh
14×10 rectangle was created, preserving the prior three rectangles. No restart.
Native left Lock: left/top/bottom green, right blue. Native top Lock: top/left/right
green, bottom blue. Clone isolated left Lock: all four edges blue despite correct
green left corners. This confirms supporting-line rather than whole-entity color
determinacy for axis rectangles. Evidence: edges-native-fresh-recovered,
edges-native-left-settled, edges-native-top-locked, edges-clone-left-locked PNGs
under the retained diagonal-matrix report directory, SHA256SUMS updated.
Native blank deselection added a history step: first Undo restored selected edge,
second removed Lock (left-undo/left-undo2 captures); this does not invalidate the
previous direct-center-toggle one-step history sample.
Correction uses the existing background DefinitionReport nullspace coordinates,
not a new synchronous solve. Focused regression currently running; no post-fix
live claim or publication. Google remains signed out, last verified466/master38.

Initial edge-color regression clean35/35,0failed/skipped (30.531s),
/tmp/os3d-qa08-edge-colors-20260910.xcresult. Exact-build saved left Lock renders
left/top/bottom green, right blue; selecting left keeps orange selected ink and
other green/blue edges. Unlock returns allblue; top Lock yields top/left/right
green, bottomblue. Clone toolbarUndo removesLock/returnsblue, Redo restores
threegreen; galleryreopen via Items sketch icon retains same colors/geometry.
Initial model doubleclicks fit camera, item-name doubleclick selected editable
text; neither entered sketch. Items sketch ICON click is the successful route.
Native topLock Undo afterblankdeselect takes2steps (selection thenLock); Redo
restoresgreen. Galleryreopen retainedfourrectangles andgreen topcorners. After
NormaltoSketch, blankclicks failedtodeselect; those final captures prove retained
Lock/corners, NOT a new unselected-color comparison. Earlier unselected paired
colors remain valid. No native geometryfailure inferred.
Added a scene-cache integration assertion to ensure threegreen/oneblue batches
and preservedfreeoppositeedge during single-edge selection. Finalcombinedrun
41198 nowowns simulator; no product change afterlivecomparison.

Final combined edge-color run clean36/36,0failed/skipped,7.889s: `/tmp/os3d-qa08-edge-colors-final-20260910.xcresult`. No runner remains. Product code unchanged since paired live comparison. Native finalreopen repeated blank/farblank still leaves selected16edges; savedLock/corners verified, unselectedfinalcapture notclaimed.
