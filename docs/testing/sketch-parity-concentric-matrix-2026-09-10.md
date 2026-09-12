# QA11 concentric initiation / selected-center distinction — September10

Baseline c66039f (product5014cef), QA10 closed and published700/master38.
Native FrontSketch04 existing14rectangles: newcircle620340→655340 readsØ9.3357;
release selects center orange/halo and offers padlock. Repeating drag620340→
680340 moves that circle60pixels, retainingØ9.3357; it does NOT createouter.
Filename native-concentric is a MISNAMED attempt, not a concentric pass. Undo
restorescirclecenter620340 and clearsselection. ArmCircle withC and repeat
same620340→680340 nowcreatesouterØ16.0041, inner unchanged, sharedcenter.
Escape disarmsCircle but retainscenter/readout. This distinguishes selected
center control from unselected-center drawing; originalQA11 sampledpass did
not capture freshlyreleasedselectedcenter semantics.
Clone freshcircle430320→465320 readsØ0.8693; centerhollow/notselected/noLock.
Samecenter430320→490320 drag leavescirclecenter/radius unchanged but moves
diameterannotation. Confirmedrelease-selection/annotationhitgap, not a
concentric creation pass. Existing rectangle unchanged.

Correction draft: circle release selects its center, keeps diameter; selected
center can begin existing point-drag whileCirclearmed, unselectedcenter remains
drawing. Circlecenter marker/directlocalLock reuse existing scoped controls.
Diameter paddedhitshape excludes20pointcenter square, preserving texttarget
elsewhere. Selectedcenter diameter also remains visible aftertoolEscape, as
observednative. No rawgeometry construction changes.
Serial42305 now owns simulator: /tmp/os3d-qa11-center-input-20260910.xcresult.
Two new CircleCenterInput tests + existing diameterlayoutunit suite.
Livepostfix and focused UI drag/hit verification pending. No deviceclaim;
immutableIPA unchanged. Evidence localreports/.../concentric-matrix; publication
diagnosis next, lastverified700/master38.

Initial center-input run42305 passed clean7/7 (2newbehavior +5diameterlayoutunits). Added UI workflow targets renderedCircleCenterControl and requiresactualcenter displacement, unchangeddiameter, singlecircle andUndoRedo. Serial17232 nowruns same7units+3UI (newcenterdrag, existingexplicitMove, diametercommit) at /tmp/os3d-qa11-center-ui-20260910.xcresult. No desktopoverlap; no livepostfixclaim. NativeEscape additionallyretainsselectedcenter/diameter afterdisarming; candidate labelcondition keeps thatstate.

## Initial live correction and lifecycle follow-up

Center UI17232 passed clean10/10 (7units+3UI). Exact-build live freshcircle
430650→465650 noworange selectedcenter/Lock/Ø0.8649. Drag430650→490650
movesactualcircle60px, diameterunchanged; sourcecircleaboveunchanged. Toolbar
UndoRedo restoresgeometry but retainedselectedcenter/Circlearmed, unlike
nativepriorcenterMoveUndo thatclearspoint/readout/disarmsCircle. No blanket
historyparityclaim. Native directcenterLock (outerconcentric circle) clears
control, centerturnsgreen andØ16.0041 remains; circlegeometryunchanged.
Added scoped circlecenter historypreparation and ephemeral free-diameter
readout afterlocalLock (not a drivingdimension). Selectionchanges/history clear
that ephemeralreadout. Unit+UI assertions strengthened. Serial88531 owns
simulator: /tmp/os3d-qa11-center-lifecycle-20260910.xcresult, same10checks.
Exactnext collectresult, livehistory/Lock/unselectedconcentric/reopen; then
publish/commit. Current source dirty5productfiles,2testfiles,docs.

QA11 diagnosis publication verified705placements/all5newhashesonce/no700loss/orderedprior text. Masterlastverified38 QA10closure; QA11masterupdate followsfinal live. Serial88531 stillactive; no desktopinteraction.

Lifecycle88531 finished8passed/2failed: diameter-radial Undo and explicitMove
Undo lost theirDimensionLabel because genericselectedcirclecleanup was too
broad. Newfresh-centerUIpassed. Narrowed cleanup to armedCircle+selectedcenter
inUndo only; ordinary radial/transform histories retainpreviousbehavior.
No assertion weakened. Same10checks now serial21417,
/tmp/os3d-qa11-center-lifecycle-final-20260910.xcresult.
Currentlastverifiedpublication705/master38; no postfixlifecycleliveclaim.

## September 11 00:08 — current execution checkpoint

HEAD c66039f; five product files, two test files and QA11 docs dirty; unrelated
identity/memory untouched. Lifecycle21417 completed clean10/10. Live release
and move retain diameter0.8649; first resumed Undo/Redo attempts mistakenly
used app-targeted window-relative coordinates with global values, missed toolbar,
and are excluded. Correct global Undo restored center. Unselected center then
created outer1.4859 at430650. Selected outer-center drag incorrectly moved older
inner circle, while selected control remained atoutercenter; exact screenshots
final-concentric/final-concentric-move retained. Correct toolbar Undo restored
both and cleared selection/disarmed Circle. Native LockUndo/recreateouter then
selectedcenter drag moves BOTH connected circles. Clone Settings visibly has
SketchGuidepoints OFF, so independent motion is not missing-constraint evidence.
Hit target must still retain selected outer identity: scoped selected-circle
center priority added plus exact two-circle target/UndoRedo regression.
Serial /tmp/os3d-qa11-center-target-20260911.xcresult now owns simulator; collect
actual result before desktop. Exact next final selectedtarget live, Lock/readout,
matched guidepoint settings/concentric relation, galleryreopen/publication then
commit/push. Native center now650380 withconnected9.3357/16.0041circles; clone
settings sheet open before test reset. Last illustrated705/master38 verified;
QA11master diagnosis paragraph insertedonce, exportpending. No IPA changes.

Master QA11 diagnosis export verified September11: heading once,38 images, no predecessor media loss and all prior text ordered. Export retained concentric-matrix/os3d-qa11-master-diagnosis.docx. Postfix image publication remains pending.

### Remaining finite QA11 closure checks

- Fresh selected-center drag targets that circle, including equal-position centers.
- Unselected-center drawing creates a second circle, not an annotation edit.
- Match Sketch Guidepoints and Auto-Constrain settings before comparing saved center relationships; current native pair is connected, clone sample intentionally was not.
- Center Lock retains diameter readout without creating a dimensional constraint; verify direct action and history live.
- Verify outer and inner sizes and centers after gallery reopen; preserve native source geometry.
- Publish final paired evidence and exact regression result, with failed attempts retained; only then consider finite QA11 closure. Physical input remains separate.

September11 resumed screenshots use global clicks WITHOUT app argument. App-targeted coordinate clicks instead resolve window-relative; initial resumed Undo/Redo filenames are invalid toolbar attempts and not evidence of an app bug. Corrected delivery JSON is retained in /tmp/os3d-qa11-undo-delivery.json.

## September11 00:16 verified correction checkpoint

Center-target final clean11/11 at /tmp/os3d-qa11-center-target-20260911.xcresult;
no runner. Exact build live freshcenter move/Undo clearscontrols/disarms; unselected
center createsouter. Selectedouter nowmoves30,40 whileinnerstays (guidepointsoff),
retainsØ1.4859. DirectLock clearscentercontrol, greencenter/freeØretained. Gallery
reopen retains3circles includingolderUIfixture, inner0.8649, movedouter1.4859 and
centerLock; rimreselectionreads1.4859. Native connectedpair movesboth; retained
separatecomparison becausecloneGuidepointsoff. NativeLock referencepaired.
Illustrated711/all6newhashesonce/no705imageororderedtextloss verified; master38
QA11diagnosis verified and finalcheckpoint paragraphinsertedonce/exportpending.
No runtimeworkers; clonecurrentouterrimselected/tooloff; nativeconnectedcircles
center650380,Circlearmed. Exactnext commit/push verifiedcenterinputfix, then
matchedGuidepoints/Auto-Constrain QA11 relationship and finalpairedreopen.
Acceptanceunchanged7/0/1/48; no IPA/devicechanges.

Final master export verified38, checkpointheadingonce, no priorimages/text loss.

## September11 00:21 — concentric relationship correction running

HEADca4663e pushed; priorcenterfixpublished711/master38verified. CloneGuidepoints
toggleclicks failed; supported shortswitchdrag visiblyenabled it. AutoConstrainON
and persisted pointSnaptrue verified. NewouterØ1.2419 fromoldinnercenter430650
then drag400610 movedonlynewcircle, innerstayed. NativeAutoConstrainON captured;
connectedpair movesboth (priorreference). Confirmed missingcreationrelationship:
nonlineinference deliberatelypositionalonly; circleANCHOR iswell-definedcenter.
DirtyEditorViewModel addscoincidentcenteronlyforexactacquiredexistingcirclecenter
(distance<=1e-6), gatedAutoConstrain+pointSnap+Guidepoints, acceptedbyexisting
conflictguard andsameDrawcommand. AddedatomiccreationUndoRedo, both-circlemove,
offGuidepoints regressions; selectedtargettest nowrestoresits settings. Serial
exec67561 /tmp/os3d-qa11-center-connection-20260911.xcresult owns simulator; no
desktopinteractionsuntilcomplete. Exactnext collectresult, relevantUI/live
connectedcenter/history/reopen, publish/committhenQA11closure. Nativeconstraint
popupopen,Circlearmed,connectedpaircenter650380; cloneUItestreset/relaunchafter.
No IPA/devicechanges; inventory7/0/1/48.

67561 completedclean32/32. Same32+3circleUI now serial /tmp/os3d-qa11-connection-final-20260911.xcresult; no livepostfix yet.

Connection diagnosis publication714 verified: all3newhashesonce, no711placementloss andpriororderedtextpreserved. Final35test run still active exec84740; no livepostfix claim.

## September11 00:28 — center connection glyph blocker under regression

Connection final84740 completedclean35/35. Liveupdatedclone createsrealcenter
connection, but glyphpaintedoncenter interceptsdrag; no livemovementpass. Native
connectionglyph sitsbelowcenterbesideLock. AddedisCircleCenterConnectionmetadata,
plainblacklink glyph below-left32pt/down40pt (slotfanned), center/Lock unchanged.
NewUI explicitlyenablesGuidepoints/AutoConstrain/pointSnap, createspair, asserts
glyphnotintersectingcenter, bothcentersmove+UndoRedo. Focusedexec15825 at
/tmp/os3d-qa11-connection-glyph-20260911.xcresult nowowns simulator (5units+newUI).
No runner overlap. Exactnext collectresult, liveboth-centerMove/history/reopen,
finalpublish/commit. HEADca4663e; connection+glyph+testsdirty. Prior714diagnosis
verified; newestglyphobstructionPNGlocalonly. Nativepopupopen,pairedcircles
center650380; cloneUIresetfixture/relaunchafter. Acceptanceunchanged,IPAunchanged.

## September11 QA11 finite closure

Selected/unselectedcenterinitiation, savedconnection/clearlinkcontrol, paired
movement/history/reopen nowverified. Clean35/35 plusseparatefinal6/6; illustrated
724/all9hashes/no715loss. Finalclone1.4852/.8645; native16.0041/9.3357. Draft
.8708 unverifiedvaluewithdrawn/corrected. Nativepopoverblockedhistory excluded;
cleanrepeatpassed. Inventory8/0/1/47 (36partial11deferred). Audit
testing/sketch-parity-concentric-closure-audit-2026-09-11.md. No runner.
Exactnext commit/pushconnection+glyphclosure, thenQA12radius/diameter modes.
Cloneinnerselectedat460720; nativeinnerselectedat726422, bothtooloff.
Masterclosureinsertedonce/exportverificationpending; IPAunchanged.

QA11 masterclosureexportverified38, headingonce,no priorimage/textloss.
