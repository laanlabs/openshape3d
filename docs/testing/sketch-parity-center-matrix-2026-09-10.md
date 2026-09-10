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
