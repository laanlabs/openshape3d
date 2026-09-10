# Center rectangle remaining matrix — September10,2026

Baseline3eb9c9b pushed; no newcode/test run for firstsample. NativeFront mouse,
cloneTop portraitsimulator, differingzoom; no exactdeviceequivalence claim.
RetainedSep8 up-leftwidthfirst andearlierheightfirst not repeated asnewcoverage.

Mixedright-up centercreation, widththenheight:
- Native centerlocal600,420; corners535,377–665,463,12×8. Width6→corners
  567,377–632,463; height4→567,398–632,442. Centerunchanged, prior4rectanglesintact.
  Nativewidthclick699,598 openedseed12; key6/commit; disarmEscape/rightedge731,499
  thenheightreadout817,499 openedseed8; key4/commit. No inputfailure.
- Clone centerlocal251,620; corners201,580–301,660,1.234×0.989. Widthseed/2
  yields0.617/corners225,580–276,660; heightseed/2 yieldsdisplay0.495/corners
  225,600–276,640. Centerunchanged; prior2rectanglesintact. Bothbadgeeditorsusable.
  Explicitexpressionsretained/f(x), notsame sourcemethod asnative literalhalf.
- Geometrysamplepasses. History/reopen for thissamplepending. No globalQA09pass.
- ReleaseUI followup: native newlycreatedcenterselectedorangehalo/padlock, clone
  plainbluedot/no padlock. This is observed in mixed-beforepair, needs isolated
  confirmation beforeproductchange. Nativeinitialheightleader right, cloneleft;
  retainvisibilitydifference, notexactUIclaim.

Evidence `reports/.../center-matrix/os3d-qa09-*.png`, SHA256SUMS. PublicationGoogle
signedout; localonly. Lastverifiedillustrated466/master38. ImmutableIPAunchanged.

Bothapps twoUndo/twoRedo restoreheight/width in sequence, centerunchanged, exact
priorbounds. Clone retainsselection; nativeclear. Newoppositemixeddown-leftnative
center creation initiallyfailedinput (cursoronly, no newgeometry), includinginset
retry. Exit/re-enter+edgepick recoveredselection. Rapidmenuattempt accidentally
armedLine, no newgeometry; excluded. Explicitsettledmenu/CenterRectanglethen
samedrag1149,599→1099,639 created10×8 centeredlocal1050,520, corners996,477–1104,563.
Againnative orangehalo+directpadlock onrelease. Directpadlock1149,640 lockedcenter
green, clearedreadouts/selection, leftCenterRectanglearmed. Prior5rectanglesintact.
Clone down-leftcenter460,720→410,760 created1.241×0.985, corners410,680–511,760;
plainbluecenter/no padlock. Bothcreation pairs confirmreleasegap. Leadersalso
differ: native up-rightwidthbelow/heightright, down-leftwidthabove/heightleft;
clonebothsampleswidthbelow/heightleft. Leadercorrection separatepending.

Releasefix implemented (drag andtap centercreation selectedpoint; padlockavailable
whileCenterRectanglearmedandnoplacementpending; directLockclearsbothselectionsets).
Firstselectorwrong RectangleToolUITests: buildsuccessbutZEROtests, xcresultunknown
/tmp/os3d-qa09-center-release-20260910.xcresult. CorrectclassRectangleWorkflowUITests
focusedrun88858 nowowns simulator, resultcorrectedxcresult. No post-fixliveclaim.

Correctedselector run failed1/1 at initialDimensionLabelassertion: selectedcenter made dimensionCandidate requirepts.empty fail. Productregression, notfixture. Narrowcandidateallowance for matchingreleasedcenter/tool/entityselection added; rerunning.

Corrected candidate run passed 1/1, 46.481 seconds, zero failures/skips:
`/tmp/os3d-qa09-center-release-labels-20260910.xcresult`. This is a targeted
pass following the retained product regression, not an initially clean batch.
Combined RectangleConstructionTests plus release and center movement/history UI
checks now run serially (exec 9834):
`/tmp/os3d-qa09-center-release-combined-20260910.xcresult`. Live repeat pending.

## Release correction verified — September 10, 13:53 EDT

Final combined run passed clean **26/26** (24 RectangleConstruction tests and
2 center UI workflows), 87.869 seconds, zero failures/skips:
`/tmp/os3d-qa09-center-release-combined-20260910.xcresult`. No runner remains.
The earlier zero-test selector and failed focused run remain above.

Exact-build live clone right-up release at center local251,620 shows orange
center halo, direct padlock and both1.234×0.989mm readouts without a keypad.
Direct padlock click locks only the center (green), clears labels/selection,
and leaves Center Rectangle armed. Toolbar Undo makes the center blue; Redo
restores green, with corners unchanged. Native down-left sample similarly
undoes/redoes the direct center Lock in one step, without changing geometry.

Both projects exited to gallery and reopened. Native trial prompt was skipped
(no trial/purchase); Sketch04 re-entry/Normal to Sketch retains all six rectangles,
newest green center and prior6×4 dimensions. Clone saved Sketch1 retains both
rectangles and both center Locks in Items, unchanged bounds. The original
pre-test clone half-sizing sample was replaced by the UI test fixture; do not
claim a final reopen of that specific sample. Its paired history is verified.
Native final clear attempt left the old top edge selected; not a deletion or
geometry change.

Evidence: `os3d-qa09-release-fixed*.png`, native retained/undo/redo/reopen/normal
and clone saved-lock PNGs, plus diagnosis predecessors; copied and hashed in
`reports/.../center-matrix/SHA256SUMS`. Google remains signed out; all new
images are local-only and queued. Release-control fix verified; leader-direction
gap and broader QA09 matrix remain open. Immutable05be744 IPA untouched.

## Direction-dependent leaders — in progress

Release correction7fb14cf pushed. Inspected retained September8 native up-left
`quadrants/os3d-center-native-before.png`: width above / height right. Together
with today's up-right below/right and down-left above/left confirms three
center directions. Down-right below/left still needs direct native confirmation.

Implemented persisted center-direction variants of RectangleSizingAnchor;
`cornerUsesMax` stays nil for every center variant so solver behavior is unchanged.
Only annotation-side lookup uses creation direction. Tap and drag pass the final
corner explicitly. Legacy `.center` keeps prior default sides. Selected-edge
override remains higher priority. Tests extend serialization, center sizing and
selected-edge checks and cover real drag/Undo/Redo in all four directions.
Serialexec15631 owns simulator:
`/tmp/os3d-qa09-center-leaders-20260910.xcresult` + `.log`. Live post-fix pending.

Initial leader run15631 failed compilation before tests: fixture assigned the
private rectangleType setter. Corrected to public setRectangleType(.center);
no product change for this compilation failure. Initial result/log retained.

Corrected compilation run passed27/27,49.102s. Live fourth-direction check
then contradicted the inferred diagonal-equivalent mapping: native down-right
989,719→1029,754 produced8×6 with width ABOVE/height RIGHT. Inset repeat
799,449→824,469 produced4×4 with the same sides, so not just bottom clipping.
Fresh up-left799,549→774,529 produced4×4 with width BELOW/height LEFT.
Thus the old September8 receipt's described up-left direction cannot support
the current mapping (capture shows above/right, but the exact input route was
not recovered); retain it as historical evidence, withdraw it as controlled
direction proof. No geometry was removed; native now9rectangles.

Confirmed center rule: width opposite vertical drag, height toward horizontal
drag. Today up-right below/right and down-left above/left remain consistent.
Corrected center-only label mapping; diagonal policy untouched. Initial27/27
was automated correctness against an incorrect expectation, NOT live parity.
Rerun with corrected expected sides follows; no final live claim yet.

## Corrected leader mapping live verified — September10 14:13 EDT

Final corrected run clean27/27,41.579s, zero failures/skips:
`/tmp/os3d-qa09-center-leaders-final-20260910.xcresult`. Earlier compilation
failure and the passing-but-wrong-expectation run remain above. No runner active.

Exact-build clone four release samples (local centers; global drag endpoints):
- Up-right center200,660,272,690→307,665: below/right,0.863×0.619.
- Down-left center450,660,522,690→487,715: above/left,0.865×0.619.
- Down-right center200,290,272,320→307,345: above/right,0.870×0.626.
- Up-left center450,290,522,320→487,295: below/left,0.869×0.626.
All preserve halo/padlock and no-auto-keypad release. Matches today's controlled
native samples. Native original nine rectangles and clone original test rectangle
remain intact. Default leader-side correction is live-compared, not full UI parity.

Clone up-left width0.869/2 then height0.626/2 keeps center450,290: bounds
415,265–485,315 →432,265–467,315 →432,278–467,303. Both explicit editors usable.
Two Undo restore height then width; two Redo restore both bounds and leader sides.
Native fresh up-left4×4 →2×4 →2×2 keeps center700,470, height Undo/Redo restores
prior/new bounds. Native input literal2; clone arithmetic, not identical source
entry method. Native clears selection/readouts between edits; retained difference.

Separate observed rounding issue: clone width displays0.435 after width half,
then0.434 after height half; height0.313. Width geometry has no visible pixel
change. Do not infer solver drift vs rounding without exact-value diagnosis;
this remains next numeric follow-up, not silently closed.

Paired gallery reopen retains native2×2 and allnine rectangles, clone five
rectangles/half-size result and leader sides. Clone first bottom-edge click
selected center (short geometry); subsequent left-side click exposed retained
0.434/0.313 labels. Native first re-entry click during trial dismissal did not
enter; settled retry worked, no purchase. Native ends all36edges selected after
Items re-entry; clone has short-rectangle selection.

Evidence all `os3d-qa09-leaders-*.png` copied/hashed with predecessors under
center-matrix. Google still signed out; no new publication count. Final leader
fix ready to commit; next rounding diagnosis and remaining finite QA09 constraints.

## Numeric readout follow-up — in progress

Leader fix27e6a4e pushed. Read-only simulator SwiftData inspection (inline blob
prefix removed, store not modified) saved exact fixture to
`center-matrix/os3d-qa09-rounding-saved-sketch.json`. Driving width0.4345,
minX1.1313221349728357/maxX1.5658221349728356 => measured0.4344999999999999.
Driving height0.313, solved residual ~1e-12. Confirms floating-point rounding
noise, not visible geometry drift. Native same source0.869/2 displays0.4345mm;
clone prior readouts0.435 then0.434 confirm metric precision gap as well.
Native same-input edit occurred from all36edge re-entry selection and moved
its small rectangle's horizontal position; do not use it as center-anchor proof.

Implemented four-decimal compact MILLIMETRE labels (other metric units unchanged;
imperial alreadyfour) and stored-value readout only when measured difference
is <=1e-10 relative/absolute scale. Real unsatisfied dimensions remain measured.
Tests cover exact saved coordinates, residuals on both sides of a rounding tie,
genuine0.01mm difference and unchanged geometry. Serialexec53679 owns simulator:
`/tmp/os3d-qa09-readout-rounding-20260910.xcresult` + `.log`. Live repeat pending.

Precision/residual unit run passed clean36/36,20.072s. Updated clone reopened
the saved five-rectangle fixture and shows0.4345mm/0.313mm. Height source
`(0.626/2) mm` retained. Changing height to0.626, Undo0.313 and Redo0.626
keeps width0.4345 throughout; center/bounds restored as expected. Native same
source0.869/2 remains0.4345 after height2→0.626 and Items re-selection.
Native selection-dependent anchor motion is explicitly excluded from sizing
parity for this numeric sample.

Clone final gallery reopen verified0.4345/0.626 and allfive rectangles;
`os3d-qa09-rounding-final-labels.png`. Original diagnostic JSON is preserved.
Attempted second JSON snapshot used stale app-container path after reinstall
and failed; by the corrected read-only lookup, UI tests had reset the store.
No final JSON snapshot is claimed. All final PNGs copied/hashed successfully.

Serial numeric UI follow-up10489 now owns simulator (expression/source/history
and circle diameter workflows), result/log:
`/tmp/os3d-qa09-readout-rounding-ui-20260910.xcresult`. No further desktop work
until collected. Google still signed out; local queue only.

### Unchanged-accept follow-up (September10)

Precision numeric UI follow-up finished 1pass/1failure, not a clean pass: circle
diameter passed53.274s; scalar retained-expression workflow failed33.658s because
Undo after unchanged accept retained1.5 instead of original1.5314. Native unchanged
0.626 accept followed by Cmd-Z restored prior2mm visibly; screenshots
`os3d-qa09-noop-native-editor.png` and `os3d-qa09-noop-native-undo.png`.
Clone existing-dimension path always emitted an update and re-solved identical
values. Guard now skips identical driving dimension updates before solving;
source/lock changes remain edits. Exact geometry/history unit plus two numeric
UI workflows running in `/tmp/os3d-qa09-unchanged-accept-20260910.xcresult`.

Corrected run completed clean3/3 (93.940s): exact geometry/history unit, circle
diameter UI, and previously failing scalar UI. Live saved line1mm was changed
to1.5 through `1+.5`, reopened as `(1+.5) mm`, accepted unchanged; one toolbar
Undo restored1mm and Redo1.5. Native Redo restored0.626 after prior2mm Undo.
All no-op screenshots copied/hashed in center-matrix. This confirms history
semantics for these samples, not all selection/constraint contexts. Prior36unit
passes remain a separate run; initial1pass/1failure retained. Docs signedout.

### Center-only Lock sizing follow-up (14:46 EDT)

Native small rectangle center(703,351) locked via direct center control, then
reselected top edge4→2, right edge4→2; center stayedfixed, corners684331–723370
to694341–713360. Clonefresh center(320,630),1.9822×1.4842, direct Lock then
reselected top1mm and right0.75mm; centerfixed, bounds240570–400690 to280600–361660.
Clone height Undo restores1.4842 and Redo0.75 with width1 and centerretained.
Escape via Peekaboo didnotdisarm; subsequent edgeclick startedpendingplacement.
Visible CancelRectangle then Recttool toggledoff, no extraentitycommitted.
Keyboarddelivery discrepancy retained separately. Native remained blue-cornered
afterbothsizes whereas clonegreen; investigate degrees-of-freedom/rotation before
colorchange. Clonefieldseed1.982/1.484 versusbadge1.9822/1.4842; precisionfollowup.
AlllockedPNGs copied/hashed. No newtests/productchanges for this livecase yet.

Fieldprecision correction: mm/in/ft now fourdecimals on both badge/palette edit
entry; angles/otherunits unchanged. First runfield-precision passed1/1 scalarUI
only because NumericKeypadTests is filename, nottestclass. Corrected actual
DimensionKeypadCommitTests/NumericKeypadTextTests running in field-precision-units.
No unitcoverage claimed from firstselector.

Corrected class run clean23/23 (`field-precision-units`,2.914s), separatefrom
scalarUI1/1. New test checks both entrypaths in mm/in/ft and exactunchanged
geometry. Native prior feeteditor0.0656 reference in rounded-seed receipt retained;
no newimperiallive claim. Live newclone1.9822×1.4842 center320630 now opens
1.9822 (previous1.982); untouchedaccept retains samebounds240570–400690 and
readouts. Currentfixture line+freshrectangle replaces earlierlockedrectangle via
UIreset; that earlierfixture has screenshots, not a newreopenclaim. Allseed-fix
PNGs copied/hashed. Remainingcenterconstraints/colorfreedom investigation pending.

### Locked-center rotational freedom diagnosis (14:55 EDT)

Native heightUndo restored2×4, Redo2×2; cornerdragglobal812420→822429 rotated
2×2 aroundfixedcenter703351, retainedboth2mm sizes. Undo restoredaxisalignment.
Native settings Auto-constraining ON, anchoredentity FirstSelected. Thusnative
bluecorners are meaningfulremainingrotation, not a standalonecolorbug. Clone
axisrectangle has no rotationparameter (SketchTransform rotatesnonrightangles
bydecomposition into4lines); its fullysizedcenterlocked corners aregreen.
Need preserve center/dimensions/refs if adapting representation; no speculative
color or destructiveconstraintmigration applied. Native screenshots locked-undo,
redo,cornerdrag,settings copied/hashed. Currentclonefreshfreecenterfixture not
used as correspondinglockedrotationcomparison yet.

Corresponding freshclone confirmation: stored both exact1.9822/1.4842 readout
values through untouchedaccept, directcenterLock then disarmedcornerdrag
global472600→492660 leavesbounds240570–400690 unchanged. Bothsizebadges/green
cornersretained. Confirms rotationrefusal, not just hypothesized model limitation.
Currentclonefixture retainsline+centerlocked/two-sizedrectangle; no pendingtool.
RotationPNGs copied/hashed. A safe correction needs rotational geometry plus
center/dimension/external-reference preservation; naive4lineconversion is unsafe.

### Explicit rotation loses saved intent — integrity correction

Clone explicitrotation dragglobal440612→457682 rotatesrectangleaboutcenter,
but Items now onlyshowsunrelatedlineDistance1.00mm. ReadonlySwiftDataconfirms
constraints[] and onlythelinedimension remain; savedJSONrotation-loss.json.
Thevisible1.9822/1.4842 aretemporarymeasurements, notretaineddrivingdimensions.
TwoUndo restoreaxisrectangle, centerLock and Width/Height Items. Screens
rotation-clone-explicit/after/items-after/restored copied/hashed.
Guard prevents rotation of selectedprimitive rectangles referencedbyconstraints
or dimensions beforedecomposition; plainunreferencedrectangles unchanged.
Typed/continuouscontrol and canvasgizmoroutes covered. This is interimdata-loss
protection, notrotationparity. Safe migratedcenter/dimensions/history stillrequired.
Regressionexec10008 running, no passclaimyet.

Integrity run clean12/12,35.083s; typed+continuous exactintent/history guard,
arcrotation and puretransforms. Live updatedsavedrectangle reopensintact; same
explicitrotationdrag nowrefuseswithnotice, no geometrychange. Itemsstillshows
Lock, Width1.98, Height1.48 plusunrelatedlineDistance1.00. Screenshotguard-retained
verifiesstoredentries, nottemporarylabels. No freshpostrefusalreopen yet; no
rotationparityclaim. Guardimagescopied/hashed.

Postguardpairedgalleryreopen nowverified: cloneItemsLock/Width/Height intact;
nativeFront2×2centerlocked preserved. Trialskip dismissed; firsttoo-fastItems
doubleclickdidnotenter, settledrepeat+NormalToSketch succeeded. FinalPNGs copied.

Migrationred1test/2assertions: prepared4linesretainedsymboliccenterLockbutsolver
ignoredlinecenter. ValidatedcenterDiagonalReferences now resolvesonlypersisted
centerintent+isolatedrectangle; fixedmidpointlowering retainscenter. Corrected
geometry27/27. AtomicReplaceSketchGeometryCommand integration then29/29: identity/
source/center/dimensions preserved, oneUndo restoresprimitive, Redo/restoredJSON.
Directcornerroute forcenterLock+bothsizesadded; regression23646 running.
No postmigrationliveclaimyet. Unsupportedrefscontinueguard. Groupcenterhandle
interaction and postrotationresize/history/reopen stillneedverification.

Directrun29/29; livefirstattemptstayedaxisaligned. Savedfixtureanchors[] revealed
olddecompositionUndo restoredrectangle but AddlineUndo removedsizinganchor, not
restoredbyRemoveSketchEntitiesCommand. ExactJSONmigration-live-before retained.
Delete/decompositionUndo nowpreservesremovedanchors; explicitcenterLockallows
legacyintent recovery, notarbitraryunannotatedrectangles. Legacyrun29/29.
Migratedcenterhit/Unlock/translation nowunder95062 regression; no livepostlegacy
claimyet. No geometry/UIpass substitutedforliveevidence.

Center-controls run completed clean29/29. Live legacy fixture now rotates around
center320630; readouts1.9822/1.4842 and Items Lock + both distances remain.
One Undo restores primitive/Width/Height, one Redo restores rotated geometry.
PNG migration-legacy-{start,rotated,items,undo,redo} retained in /tmp; copy pending.
Found review risk: isolated-loop inference would drop virtual center after adding
an attached branch. Added persisted ordered edge group (legacy decode empty),
merge remapping and deletion/Undo metadata cleanup. Group-identity unit regression
exec59861 running; no live or passing claim for this latest follow-up yet.

Group identity run clean30/30. New live top rectangle center320300 rotated with
1.9898/1.2511 dimensions. Numeric width1 then changed height to1.3327: FAILED.
Saved group-resized.json proves migration used single whole-edge distance refs,
which are not canonical driving line-length refs; reopening created another
endpoint-pair dimension rather than editing the saved ID. New pure resize test
reproduced failure (expected1, actual4) in rotation-resize-red, one failed test.
Migration now maps to endpointA/endpointB pairs. Corrected size-references run
clean30/30 includes real resize, preserved other size, VM dimension-ID/count and
exact Undo. New focused UI workflow running exec4905, rotation-size-ui result.
No corrected live resize claim yet. Screens and JSON copied/hashed locally.

Initial size UI failed at line76 before rotation (0labels): immediate disarm→edge
selection. Event tap495.5,550.5 lies on painted top edge in extracted recording;
1s settling interval added. Settled UI passed1/1, including actualrotationlevels.
FFmpeg extraction unavailable due missing x265 dylib; AVFoundation extracted
recording frame without altering host installation. Failure retained.
Live corrected saved fixture opens Lock+two dimensions; width1→2 retains other
1.6288 and center329480. Angle changed about43→40degrees. Native isolated tiny
centerlocked rectangle rotated then size2→4 retains prior angle and center703351.
Thus temporary direction preference added for migrated centerlocked numericedit,
not a persistent constraint. Combined direction regression exec67522 running.
New merge identity remap and center-dimension deletion cleanup included.

Direction combined passed48/48. Exact-build clone width1→2 retains orientation
(~39.5degrees), center329480 and other size1.6288. Direct center Unlock then drag
moves center to379520; Undo restores329480, secondUndo restoresLock. Gallery
reopen retains2/1.628840059041977, Lock and group metadata; finalJSON retained.
Native gallery reopen retains4×2 rotated rectangle around703351. Initial immediate
post-trial Items doubleclick did not enter; settled repeat + Normal worked.
Final related run `rotation-final` clean74/74:71 units +3UI, including retained
angle re-edit exactUndo, center controls, Copy and project remapping. No runner.
Fresh authorized browser tab recovered editing/SavedtoDrive. New six-image
addendum export verified472placements/470media, all6hashes exactlyonce, no
predecessor image loss and original full text retained. Addendum was prepended,
not appended; audit retained. Existing stalled tab preserved. Earlier backlog
still queued; master update verification pending. New evidence paths directed-*
and native-directed-* copied/hashed. Ring/glyph-density mismatch remains visible.

Migration committed/pushed03338a4. Master dated note export verified once;
38 image placements and all original media hashes retained (export file names
changed, so name equality was not used as loss evidence). Original full text
retained. Fresh report tabs t20/t21; old stalled t11 preserved. Remaining default
ring/glyph density next; earlier backlog still queued. No runner at checkpoint.

Default-ring follow-up: clean3/3 in rotation-explicit-controls result. Live fresh
centerlocked rectangle1.9795×1.4814 rotates about320630, retains bothleaders
and no automatic blue ring. Explicit Move/Rotate shows whitecontrols; Done
hides them. Undo restoresaxisrectangle; Redo restoresrotation withsingleedge
selected (notfullgroup). Galleryreopen/Items retainLock andbothdimensions.
New ring-* screenshots retained/hashed. Native ring-reference andsingleedge
glyph comparison show no default ring. AlwaysShowConstraints toggledON and
verified: native still doesnotshow rectangle internalparallel/perpendicular/
coincidentbadges; setting restoredOFF. Clone generatedrelations createclutter.
This is a separate confirmed presentation gap; no constraintdeletion authorized
or intended. Ringpublication3images insertedonce, exportverificationpending.
RecoveredQA08leaderbatch verified478placements/all6newhashes/noimageloss;
textdiff reports only755insertedcharacters, no deleted/replacedpriorcontent.

Ring publication final export481placements: all3newimages, prior478image
placements and full prior text retained. Initialexport480missedlastimage while
saving; no reinsert. Master38note verifiedonce, no image/text loss.

Structural badge correction: first build failed on ConstraintRef Set/Hashable,
no tests ran. Replaced with unordered pair equality. Corrected run clean12/12
(`/tmp/os3d-qa09-structural-glyphs-corrected-20260910.xcresult`), includes11
annotation tests and1migration/history. Internal7rules retained in model/Items;
only ordinary badges hidden for saved migrated group. Explicit selection and
conflicts remain visible; external relation visibility unchanged. Migrated
centerLock now uses existing directcentercontrol, not duplicategenericbadge.
Live edge selection clear; directcenterUnlock/move320630→350600, Undo restores
position thenLock. ItemsParallelclick exposes onebluebadge. Finalgalleryreopen
Items retainsLock/two distances; no geometryloss. NativeAlwaysON comparison
showsno internalbadges, restoredOFF. Full QA09 notclosed; nativeoneedge shows
bothsavedsizeleaders whilecloneoneedge showsonlyone, nextconfirmedgap.
Illustrated490placements/all4hashes/no predecessor loss and master38note verified;
prior text retained. Fiveoldercornerimages verified486beforethisbatch. Evidence
glyph-* and native-settings-verify retained/hashed. No runner; IPAunchanged.

Single-edge dualreadout initialrun12passed/1failed: all4side edit/Undo checks
passed; unrelated/centerselectionassertions failed becausefixture retained
explicitselecteddimension. Clearedexplicitselection/cancellededitor before
unrelatedfixturechecks; corrected13/13clean. Livewidth/heightedge nowshowsboth
1.9795/1.4814 withno thirdcandidate. Opposite selectedside retainedlabelon
originalside, unlike native reference; narrowlabelgeometry correctionnowunder
32682regression selected-side-leaders. Drivingrefs/valuesunchanged. No runner
claimforprior30721(done); current32682exclusive. Prior13passnotfinalpass.
RetainedcenterLockpublication497/all7hashes/no predecessor loss verified.

Selected-side finalrun clean13/13 aftercompile-onlyimmutablelabel failure;
geometry tupleadjusted beforeconstructingimmutablelabel. Live selectedwidth
andperpendicularside showbothsizes, selectedsideleadercorrect. Firstheighttap
addedsecondedge/ring, excluded; deselectedthenheightonlyverified. Heightedit
1.4814→1 retainswidth1.9795/center320630; UndoRedoexactstatescaptured. Native
2→1 andhistory preservecenter; attemptedtinyreselectionhitcenter, excluded.
Pairedfinalgalleryreopen: native4×1, cloneLock/1.9795×1. TrialSkip/Normalworked.
Editoropening shifts selectedoppositeside todrivingedge; retainedasnextnative
comparison, no parityclaim. Side-* PNGs copied/hashed. Sixreportimages inserted
once and exportverificationpending; no runner.

Publication503/all6hashes/master38note verified, no predecessor loss. Review
found broadreplacement alsoadjusted measuredValue, removed beforecommit; new
unsolvedoppositeside fixture asserts drivingmeasurement4notselectedside6. First
newguardbuild failed on incorrectReplaceSketchGeometryCommand initializer,
no tests ran. Correctedtitle/before/after run2037 active, side-measurement-corrected.
Final exact-build live recheck required; prior live pictures retainedasinterim.

Final correctedmeasurementguardrun clean13/13; no runner. Updatedclone
relaunch/gallery/selected-side values1.9795×1 verified. No change to measurement
path remains in diff. Final-build screenshot publishedonce, illustrated504
placements/all7batchhashes across503+1, prior text/imagesretained; master38
finalbuildnoteonce. Exactnext nativeopposite-edge editorselectioncomparison;
no full QA09closure or IPAchange.

## Selected-side editor preservation — September 10

Confirmed native opposite-height editor retains the selected side on open and
Escape; clone previously switched to original driving edge. Narrow correction
keeps selected parallel side while preserving dimension refs and values. Clean
first run13/13: `/tmp/os3d-qa09-editor-side-preservation-20260910.xcresult`.
All four side fixtures cover open/cancel selection and leader geometry, unchanged
sketch and original edit/history checks. No test runner remains.

Live clone left-side open/Escape and 1→0.5 mm commit retain width1.9795 and
center320630. Undo1/Redo0.5 verified. Native6→3 history retains center703351.
Paired gallery reopen native8×3 and clone1.9795×0.5 plus centerLock verified.
Native shows additional opposite-side3mm annotation after commit/reopen; this
separate lifecycle/constraint distinction remains open, no full QA09 closure.
Native trial dismissed using Skip; initial rapid entry clicks did not enter,
settled single Items selection plus Normal to Sketch succeeded. No purchase.
Evidence editor-* in center-matrix with SHA256SUMS. Diagnosis publication509
placements/all5 hashes/no predecessor text/image loss verified; four post-fix
images inserted once and await export verification. Master note pending.

Selected-side editor correction: clean13/13, paired open/Escape and sizing
history, final gallery reopen verified. Illustrated513 placements/all4postfix
hashes plus5diagnosis hashes/no predecessor loss; master38 dated note and full
prior text/images verified. Exports `/tmp/os3d-qa09-editor-fixed-published.docx`
and `editor-fixed-master.docx`. Native opposite-side annotation distinction
remains open; QA09/inventory unchanged. See center-matrix September10 receipt.

## Post-edit migrated corner reselection — September 10

Native directcorner after numeric edits rotates about703351, retaining8×4mm.
Clone initial directdrag unchanged; explicit endpointtap then repeat rotates
about320630 but leaves defaultblue ring and zero point-to-edge candidate.
Pointer-away settled screenshot confirms persistent symptom. New focused
regression reproduces both failures (1test/2assertions):
`/tmp/os3d-qa09-reselected-corner-red-20260910.xcresult`. Geometry/history
assertions passed; not a solver failure. Narrow correction clears stale point
selection when grabbing a saved migrated rectangle endpoint; other entity/point
selection paths unchanged. Corrected annotation/migration regression pending.
Native plain clicks replace selection; stationary shift-drag didnot acquire
two edges. Box selection accidentally grabbed nearby14mmrectangleedge; immediate
Undo restored originalgeometry, screenshots retained and excluded. No parity
claim for multi-edge default controls. Opposite-side native labels disappear
on blanktap; ordinary single-side reselection returns width/height. Editing
right3→4 updatesbothside labels, without conflict. Lock toggle and Undo captured;
no internal storage inference. These separate display states remain open.

Corrected run `/tmp/os3d-qa09-reselected-corner-fixed-20260910.xcresult` passed
clean14/14 (2migration/center +12annotation). Exact-build live endpoint tap then
drag retains1.9795×0.5 and center320630, no defaultblue ring/zero candidate.
Native8×4 cornerrotation remainscenter703351. PairedUndo/Redo andgalleryreopen
verified; cloneItemscenterLock/twodistances retained. Native point-highlight
versus clone selected-edge handle remains open, not exactvisualparity. Five
diagnosis/postfix/reopen images insertedonce; export verification pending.
Recovered earlierdirectpadlockbatch verified519/all6hashes/text+imagesretained.

Migrated endpoint-drag selection cleanup: red1test/2assertions followed by
clean14/14; paired live cornerrotation/history/finalreopen. No default ring or
zero candidate; endpoint-vs-edge selection appearance remains open. Illustrated
524/all5newhashes/no predecessor loss and master38 dated note/text/images
verified in `/tmp/os3d-qa09-cornerfix-{published,master}.docx`. Receipt/evidence
center-matrix September10. Inventory unchanged4passed/1blocked/51incomplete.

## Selected migrated endpoint appearance — September 10

Native pointer-away confirms persistent orangecornerhalo and bothadjacent sizes;
prior allItems selection dragrefused, not valid evidence. Selectedoneedge then
blank cleared it; validpointdrag captured. ExplicitEscape delayed11s and capture
snapshotpublicationfailed; nextcapture recovered without hostchanges.
VM now retains grabbedendpoint alone (notwholeedge), suppressesgenericgizmo and
showsorangehollowmarker/halo. Cleaninitial14/14 in corner-selection-20260910;
liveorangeendpointaway/noedgehandle/ring passed. UndoRedo geometryretained.
Live leaders stillon original sides, unlike nativeadjacentgrabbedcorner; narrow
geometrypresentation adjustment follows incident sides, refs/valuesunchanged.
Eight endpoint-reference combinations added; corner-leaders-20260910 running.
No finalpostleaderpass/publicationclaimyet; earlierimagesretaininterimstate.

Selected migrated endpoint and adjoining leaders: final clean14/14 in
`/tmp/os3d-qa09-corner-leaders-20260910.xcresult` after initialmarker14/14.
All8endpointreferences retain savedrefs/values and attachbothleaders tocorner.
Paired oppositecorner pointer-away samples verifyorangehalo/noedgehandle/ring
andadjoiningsides. Nativeadditional4mmannotation remains. Exact-buildclone
relaunch/galleryItems retains1.9795×0.5/centerLock; finalnativegallery8×4.
Illustrated530/all6hashes/no predecessor text/image loss; master38datednote
verified: `/tmp/os3d-qa09-pointleaders-{published,master}.docx`. Remaining
historyselection-clearing, extraannotation and broaderQA09 stillopen.


## Migrated corner history selection cleanup — September 10

On `724758e`, a fresh paired corner rotation confirmed native Undo/Redo clears
the selected endpoint and dimensions; clone Undo restored geometry but retained
the endpoint/labels. Evidence: `pointhistory-native-before/undo/redo` and
`pointhistory-clone-before/undo` (PNG files in center-matrix evidence directory).
The correction clears only migrated-corner transient selection in history
preparation; no geometry command or dimension references changed.

First focused run passed **14/14**, zero failed/skipped:
`/tmp/os3d-qa09-corner-history-20260910.xcresult` and `.log`.
The strengthened test asserts exact geometry restoration and absent point/labels
through ViewModel Undo and Redo, plus the existing constraint/annotation checks.
Live updated clone rotation, Undo, Redo, reselect and gallery reopen were inspected:
Undo restores the prior orientation, Redo restores the new orientation, both
clear the point and labels, and reselect restores adjoining 1.9795 × 0.5 mm.
Final gallery reopen retains the rotated profile, both dimensions and center Lock.
Native reference is 8 × 4 mm at its different viewport scale. Evidence prefix
`os3d-qa09-historyfix-` includes before, undo, redo, reselected and reopen.

Six paired/reference/post-fix images and master note inserted once; export
verification follows. QA-09 remains partial; broader visual/constraint criteria
and historical publication backlog are not closed by this narrow correction.

Publication verified: `/tmp/os3d-qa09-historyfix-published.docx` contains 536
placements, all six new hashes exactly once, no predecessor image/text loss.
`/tmp/os3d-qa09-historyfix-master.docx` retains 38 placements and the dated note
exactly once, no predecessor image/text loss.


## Center + corner Lock conflict feedback — September 10

Native rotated rectangle, already dimensioned8×4 and center-locked: selecting
lower-left point then Lock turns all edges green. Width8→9 is rejected with
“This constraint would conflict with existing ones.” notice; editor dismisses
and8×4 survives. Clone corresponding1.9795×0.5 also goes green and refuses
width2, but previously displayed blocking Something Went Wrong alert. Both
preserved geometry. Captures `os3d-qa09-cornerlock-*` retained locally/hashed.

Dimension conflict now uses the existing nonblocking notice surface with native
wording; solver guard and history commands unchanged. First clean **7/7**:
`/tmp/os3d-qa09-corner-conflict-20260910.xcresult` and `.log`, one new migrated
rectangle conflict/rollback/history test plus six constraint-polish checks.
Exact unchanged sketch, dismissed editor, absent modal, notice and no extra Undo
step are asserted. Live updated clone confirms notice instead of alert.

Paired corner Unlock allows the same previously refused values. Native9×4 and
clone2×0.5 survive Undo/Redo and gallery reopen, with center Lock retained and
corner Lock removed. Native all-Items selection at final reopen shows both
saved sizes; its extra opposite-side annotation remains open. Clone point-to-edge
selection change on editor opening and corner Lock icon/filled point appearance
are separately recorded visual gaps, not part of this notice fix.
Evidence `os3d-qa09-conflictfix-*` retained/hashed. Five images inserted once;
export verification pending. No QA-09 closure or immutable IPA change.

Conflict publication verified: illustrated541, all five new hashes once, no
predecessor image/text loss; master38 and dated note once, no predecessor loss.
Exports `/tmp/os3d-qa09-conflictfix-{published,master}.docx`.


## Corner editor selection lifecycle — September 10

Opening a selected migrated corner's distance label previously selected the
whole driving edge and exposed an edge handle. Native retains the point on
open/Escape/refusal. Narrow selection preservation passed initial clean14/14
`/tmp/os3d-qa09-corner-editor-20260910.xcresult`, and paired open/Escape passed.
Fresh native successful9→8 instead cleared the corner. First attempted native
re-edit did not open the editor, excluded; inspected double-click and typed8
was valid. Final implementation additionally clears point only after successful
size command, not cancellation or refusal. Native outlined badge after Escape
and additional opposite-side saved annotation remain separate visual differences.

Final clean14/14 `/tmp/os3d-qa09-corner-editor-lifecycle-20260910.xcresult`:
all8 endpointrefs/bothsize editors retain leader endpoints/references through
cancel, unchangedsketch; successfulsizechange ends pointselection and exactUndo
restores geometry; refusal retains point with no modal/history pollution.
Live finalclone2→3 clearscorner/noedgehandle; Undo/Redo2↔3 and finalgalleryreopen
retain3×0.5/centerLock. Native valid8×4 retainscenter; earlierpairedgallery9×4
belongs to preceding conflict batch, not a new native8×4reopen claim.
Evidence `os3d-qa09-cornereditor-*` retained/hashed. Fiveimages +master note
inserted once; export verification pending. QA09 remainspartial.

Editor lifecycle publication verified: illustrated546/all5hashesonce andmaster38
notewithno predecessorimage/textloss. Exports
`/tmp/os3d-qa09-cornereditor-{published,master}.docx`.


## Migrated corner Lock presentation — September 10

Freshnative center+cornerLock8×4 showsgreenhollowcorners, selectedorangeendpoint,
contextualUnlock, nooverlaidendpointLockbadge. Currentclone3×0.5 showedfilled
genericmarkers andbadge. Savedvalidfourline groups nowmarkendpoints asrectangle
corners; defaultendpointLockbadgehidden, explicitItems/conflictinspectionkept.
Ordinarylinemarkerstyle unchanged. Firstclean14/14:
`/tmp/os3d-qa09-corner-markers-20260910.xcresult` and.log. Testsincludeall8endpoint
refs/nonfree/hollow, contextualUnlock, explicitglyphinspection andunrelatedline
markers; annotation/conflict/historycoverage retained.
Liveupdatedclone hollowgreencorners/nooverlaidbadgepassed. PairedUnlock returns
bluehollow; Undo restoresgreen, Redo blue, withoutgeometrychanges andclearing
selectiononhistory asnative. Evidence `os3d-qa09-cornerglyph-*` retained. Final
reopen andpublicationverification pending; noQA09closure.

Finalpairedgalleryreopen retainednative8×4/clone3×0.5, centerLock/unlockedcorner.
Publication export-verified551/all5newhashesonce, master38datednote, no prior
image/textloss: `/tmp/os3d-qa09-cornerglyph-{published,master}.docx`.


## Selected corner-size outline — September 10

Native editor Escape leaves the selected size white/blue outlined, while the
clone's earlier inspected `cornereditor-dismiss` remained plain. Styling now
applies only to an explicitly selected saved size while its migrated corner is
selected; plain and successful-commit states remain unchanged. First clean14/14
`/tmp/os3d-qa09-selected-badge-20260910.xcresult` and `.log` compiles the view and
runs existing annotation/history/conflict tests. No mirrored style-only test.

Paired editor/Escape shows the selected outline; blank then corner reselection
returns both to plain text. First clone launch sequence arrived before gallery
settled and was not evidence. An old label coordinate missed; exact center at
330,598 opened successfully. Immediate corner reselection did not select; a
settled second tap did. These attempts are retained, not an input parity claim.
No geometry edits: native8×4/clone3×0.5 unchanged from prior paired final gallery.
Evidence `os3d-qa09-badge-*` retained/hashed, four selected/reselected screenshots
inserted once. Export verification pending. Extra native opposite-side annotation
and historical publication backlog remain; QA-09 partial.

Publication verified: illustrated555/all4hashesonce andmaster38datednote, no
predecessor image/text loss. Exports `/tmp/os3d-qa09-badge-{published,master}.docx`.


## Single-edge adjacent size presentations — September 10

Native four-side sampling shows selected side plus both perpendicular sides
(three readouts); selected corner remains two. Native top4→5 updates both
visible perpendicular values, then Undo restores4. This does not prove two
independently stored dimensions. Clean clone side shows two. Initial point→edge
retained generic ring/zero readout; blank and settled edge isolated the size
case. Screenshots `os3d-qa09-oppositereadout-*` retained/hashed, not published.
Presentation-only third label shares dimensionID, refs and measured value;
unique UI ID and opposite-side world geometry. Adjacent editor retains selected
edge. Serial14-case regression started; live result remains pending.

First clean14/14 `/tmp/os3d-qa09-adjacent-readouts-20260910.xcresult`.
No runner remains. Live left and top single-side selections show3; new height
and width aliases open usable editors while retaining selected side. Widthalias
3→2 updates both displayed widths; toolbarUndo3/Redo2 restores geometry.
Direct edge-to-edge tap added to selection (two orange edges/ring), so blank
then settled single edge was used; not evidence of a new single-edge failure.
Current clone2×0.5, native8×4. Selectededge remains aftercommit/history, a
separate lifecycle comparison still open. Fresh paired reopen/publication pending.

All four clean clone single-side selections now show3readouts. Paired final
reopen retains native8×4/clone2×0.5 and native/clone triple presentations.
Publication verified561/all6hashesonce andmaster38 note, no predecessorimage
or textloss: `/tmp/os3d-qa09-adjacent-{published,master}.docx`.
