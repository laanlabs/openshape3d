# QA12 circular annotation preference — September 11

Baseline78c7c7c pushed, QA11closed8/0/1/47. Native PreferencesGeneralCircular
Annotations defaultsRadiusandDiameter; AlwaysRadius switches savedinnerØ9.3357
toR4.6679 withgeometryunchanged andradiusleader. R5typedcommit clearsselection;
switchbackRadiusandDiameter +rimselectreadsØ10, centerunchanged. Native now
innerØ10driven,outer16.0041, sharedcenter726422. Preference restoreddefault.
Clone Settings has no circularannotationpreference, candidatehardcodeddiameter.
ConfirmedDM04 gap. DirtyAppSettings enum/persistence, Settingspicker, circlelive
Kitmodeparameter, Editorlabelconversion/prefcandidate/dedupRadiusDiameterfamily,
existingdimensioneditadoptsdisplaykindwithsameID; untouchedconvertedseedreturns
withoutchangingoriginalsource/history. Arc/polygonexistingradiusunchanged.
CircleCenterInputTests addsfactor-of-two/display/noopsource/stableID/history;
AppSettingsTestspersistence/default. InitialscriptassertionstoppedbeforeKernel
write becausepolygonsharesdiameterstring; correctedcircle-onlyreplacement, no
compile/testfailurefromthat. Serialexec14333 owns simulator:
/tmp/os3d-qa12-circular-preference-20260911.xcresult. Exactnext collectresult,
addSettingsUIflow, pairedliveAlwaysRadiuscreate/edit/switch/Undo/reopen; verify
existingexpressionsandradiusleaderlayout. No liveclonepostfixclaim. No merge/
deviceinstallation/IPAchanges; unrelatedidentityfilespreserved. Native/source
reporttabsuntouched. LastpublicationQA11illustrated724/master38verified.

Initial14333 passedclean18/18. AddedrealSettings->AlwaysRadius->R1edit->RadiusandDiameter->Ø2editorUI workflow, stablecenter/onebadge assertions. ExistingcircleDiameterUIincluded; same18units+2UI now serialexec24346 /tmp/os3d-qa12-preference-ui-20260911.xcresult. Nativecurrentlydefaultpreference/innerØ10selected; no newdesktopworker.

## September 11 01:03 — QA12 live radius clipping follow-up

Combined preference run completed clean 20/20 at
`/tmp/os3d-qa12-preference-ui-20260911.xcresult`; no preceding failures.
Live saved fixture reopened; Always Radius shows R1 with radius leader and
editor seed1. Immediate rim click after Settings dismissal did not select;
settled repeat did. Physical keyboard typing in keypad mode did not change
value; Return retained R1, excluded as a resize attempt. Visible keypad entry
1.5 inspected before commit and enlarged radius1→1.5 with center unchanged.
Readout then ran behind right constraint rail (screenshot
`/tmp/os3d-qa12-clone-radius-valid.png`, lower info shows Radius1.50).
Radius leader now reserves rail/palette space and rotated text half-width;
strengthened Settings UI test uses R1.5→Ø3 and asserts value clear of rail.
Serial exec25255 owns simulator: `/tmp/os3d-qa12-radius-rail-20260911.xcresult`
(two UI workflows). No desktop until complete. HEAD78c7c7c, QA12 dirty plus
SketchDimensionOverlay.swift. Next collect result, repeat live enlarged
radius/readout, switch/history/native history and paired gallery reopen;
publish postfix evidence and commit/push. Native unchanged innerØ10, center
726422, preference Radius and Diameter. Illustrated727 native diagnosis
verified; new clone evidence local only. Inventory8/0/1/47, IPA unchanged.

Follow-up diameter case failed its Ø-prefix assertion because live Always Radius
preference persisted into the older default-assuming fixture. Initial spoken
setup-failure interpretation was wrong and immediately corrected; no sketch-entry
failure. Test now explicitly chooses Radius and Diameter through Settings, with
assertions retained. New radius-clearance case still running in25255.

25255 completed1pass/1fail: enlarged radius-clearance workflow passed; older
diameter fixture expectedØ despite persistedAlwaysRadius. Explicit UI preference
setup added, no assertions weakened. Consolidated unit+circle+arc editor run
exec30191 `/tmp/os3d-qa12-radius-final-20260911.xcresult` now owns simulator.
Shared radius leader arc editor included; live postfix pending.

Radius diagnosis publication export verified729 placements; both new hashes+1, no727loss, headingonce and prior ordered text preserved. Arc and explicit-mode diameter UI passed in30191; final preference/units still running.

## Final relevant regression and live preference check

30191 completed clean21/21 (18units+3UI), after retained1pass/1fixturefail.
No runner. Live updated R1.5 value now fully clear of rail, keypad seed1.5
reachable; keypad editR1 holdscenter414444global. Preference switchØ2 does
not resize, oneUndo→Ø3,Redo→Ø2. Native priorR5edit Undo→Ø9.3357 andRedo
restoresgeometry, followed by galleryreopenØ10 and preference/reselectR5.
Native label refresh needed reselection after preference switch; first screenshot
retained oldØ10 label while info already showedR5. Settled reselect correct.
Clone galleryreopenØ2, switchR1, anothergalleryreopen retainsAlwaysRadius/R1.
Paired numeric geometry/history and saved values pass for these samples.
Separate confirmed lifecycle gap: native commit/Undo/Redo clears selected rim
and readout; clone retains them during numeric-circle edit/history. Keep QA12
partial, address next, no broad radial/explicit-transform cleanup. Current
cloneR1selectedcenter414444, nativeR5selectedcenter706420; bothtooloff.
Postfix screenshots local circle-annotation-modes directory, publication next.
HEAD78c7c7c/dirtyQA12, immutableIPAunchanged, inventory8/0/1/47.

Postfix illustrated export verified735 placements, all6newhashes+1/no729loss, priororderedtextpreserved andheadingonce. Master38 firstexport retains priorcontent butnewheadingnotyetpresent; insertedonce, retryexportwithoutduplicate.

## September11 01:17 — circle numeric lifecycle correction under test

Preference/clearance944ae3e committed and pushconfirmed. Final21/21 and paired
saved values publishedillustrated735/all6hashes verified; master38 newnote
firstexportmissing, retrywithoutduplicate. New dirtyEditorViewModel,
CircleCenterInputTests, DimensionUITests implement narrowly disarmed-circle
successfulnumericcommit cleanup and preUndo/Redo cleanup only when stack
command adds/updates selectedcircle drivingdimension (recursescomposites).
Free radialdrag/history andexplicittransform excluded. Unitchecks exact
original/edited sketches andonehistoryentry; UI preservesnumericvalueassertions
and explicitlyreselects after expectedselectionclear. Serialexec13296 owns
simulator `/tmp/os3d-qa12-circle-numeric-lifecycle-20260911.xcresult`
(CircleCenterInputTests+3circleUI includingexplicitMove). No livepostfixclaim.
NativeR5selectedcenter706420, clonewillUIreset/relaunch. Exactnextcollect
result, diagnose failureswithoutbroadcleanup, pairednumericcommit/history
postfix+reopen; masterexportretry, publish/commit thenremainingQA12creation.
Inventory8/0/1/47, IPAunchanged.

Master retry export now verified38/headingonce/no prior media or ordered text loss; no duplicate insertion. Preference publication complete735/master38. Lifecycle13296 still running.

13296 numeric-circleUI deselection assertion passed, then radius-info assertion
failed after center (not rim) reselection; no geometryfailureclaim. Needfailure
screenshotinspection and validrimfixture. ExplicitMove/history exclusion passed.
PreferenceUI/units stillrunning; no repeateddesktopwork.

13296 complete10pass/1fail. New exact geometry/history unit and explicitMove
exclusion passed; numericUI info assertion aftercenterreselectionfailed.
No automaticfailureattachments were saved (exportmanifestempty). Addedexplicit
after-reselectiondiagnosticattachment, singlecaseexec15233 nowowns simulator
`/tmp/os3d-qa12-circle-selection-diagnostic-20260911.xcresult`. No assertion
weakened orgeometryclaim. Nextinspectcapture, correctactualfixture/product as
evidencewarrants, finalrelevant/liverecheck. Master38 andillustrated735verified.

15233 reproducedinfofailure; explicitcapture shows largeØ10circle with only
centerselected, noriminfo. Geometryvisiblyenlarged; no productsizefailure.
Fixture now computes lowerdiagonal rim from originalmeasuredØ andpixelradius,
retainsØ10/Ø8 andR5/R4assertions andnewselectioncleanupassertions. Same11
cases rerun serialexec28441 `/tmp/os3d-qa12-circle-numeric-final-20260911.xcresult`.
No new productchange since13296. Diagnosticcapture copiedlocally; publication
notyetupdatedforthisfixture. Next collect/run livecommit/history/reopen.

28441 diameterUI nowpassed with originalØ10/Ø8/R5/R4assertions and rimreselection; unitsalso passed. Other2UI stillactive; nofinalcombinedclaimyet.

## Numeric-circle lifecycle verified live — September11 01:34

28441 finalclean11/11 (8circleunits+3UI), after retained10pass/1fail and
single1faildiagnostic. SameØ10/Ø8/R5/R4assertions preserved; lower-rim
reselection fixes fixture, no geometry/testthreshold weakening.
Paired freshdisarmednumeric: nativeR5→R4 andcloneØ3→Ø2 both clearselected
rim/readout/handle oncommit; reselect/Undo restoresprevioussize andclears;
reselect/Redo reapplies andclears. Finalgalleryreopen retainsnativeR4 with
AlwaysRadius andcloneØ2 withRadiusandDiameter. Centers unchanged within each
viewport; differentnative/clone scales explicitlyretained. No runner.
Productcleanup excludesarmedCirclecreation, freeradiusdrag andexplicitMove;
history onlyreacts to selectedcircle Add/Update drivingdimension commands,
recursingcomposites. Rawgeometry/Undo stack logic unchanged.
Nextpublishpaired8images/masterverify, commit/pushlifecycle then remaining
QA12freshAlwaysRadiuscreation/armednumeric/cancellation matrix. QA12partial,
inventory8/0/1/47. NativeR4selectedcenter706420; cloneØ2selected414444.

Lifecycleillustratedexport verified743/all8newhashes+1/no735loss, headingonce andpriororderedtextpreserved. Masterfollowupinsertedonce; exportverificationcurrenttool. No runner; commit/pushnext.

Masterfollowupverified38/headingonce/no predecessor media ororderedtextloss. Lifecyclepublicationcomplete743/master38.

## September11 01:43 — fresh radius construction leader under test

Lifecycle5436e46 pushed; final11/11 andpairednumericcommit/history/reopen
verified, illustrated743/master38/all8hashes verified. No IPAchange.
ContinuingQA12AlwaysRadiuscreation: native20pxradiusfreshcircle center630720
releasedR2.7185 withcompactcenter-to-rimleader/valueovermidpoint, centerhalo/
Lock andCirclearmed. Clone20pxradiuscenter420700 releasesR.2475 withlong
extension. NativearmededitR3 retainsCircle/valuewhitebluebadge anddimension
lock butdropscenterhalo/centerLock. ClonevalidkeypadR.3commit dropscenter
halo too, butlongplainradiuslabel persists. No newgeometryfailure.
DirtyisCircleRadiuslabelmetadata andcompactCircle-armedradiuslayout keep
center-to-rimtail/insidearrow/valueabove midpoint; disarmedcircle/arc keep
rail-awareextension. NewfreshAlwaysRadiusUI assertsactualmidpointplacement
andexpliciteditor, existingpreferenceUI+arcEditor+circleunitsincluded.
Serialexec48328 nowowns simulator:
`/tmp/os3d-qa12-compact-radius-20260911.xcresult`. Exactnext collectresult,
livefreshreadout/editor/armedcommit, then selectedbadge+dimensionLock
discrepancy/cancellation/reversecreation. NativefreshR3center630720Circle
armed; priorpaircenter706420 innerR4. ClonefreshR.3center420700Circlearmed,
priorcirclecenter414444Ø2. Reportnewdiagnosislocalonly. Inventory8/0/1/47.

## September11 01:53 — armed radius badge and direct unlock under test

Compact48328 passedclean11/11. Diagnosis747/all4hashes/no743loss verified.
LiveupdatedfreshcircleR.2475 compactleader andexplicitkeypadwork; armedR.3
commitretainscompactreadout. NativeR3selectedbadgeLock clicked directly
(global664704): removesradiusconstraintwithoutresizing, restoresplainR3
outwardleaderwhileCirclearmed. This narrowscompactrule to freshselected
center ordrivingradius, notallarmedcirclelabels.
Dirtycirclelabelmetadata/UIcompactrule refined; successfularmedradiuscommit
setsselectedDimensionID. SelectedradiusHStack showswhite/bluebadge+separate
44ptUnlockbutton callingexistingdeleteDimension; sourcef(x)markerretained.
UnlockclearsselectedID andcandidate resumesoutwardleader. Unitasserts
geometryandUndoRedo; freshUIassertsreadoutposition, editor, postcommitcenter
clear, directUnlock/valuepreservation/outwardlabel. Serialexec18215 owns
simulator `/tmp/os3d-qa12-armed-radius-controls-20260911.xcresult` (9units+3UI).
Exactnextcollect, livepostfixarmedcommit/Unlock/history/cancel/reopen,
publish/commitcompact+controls, thenremainingreverse/freecreationQA12.
HEAD5436e46pushed; dirtyEditorViewModel,SketchDimensionOverlay,
CircleCenterInputTests,DimensionUITests,receipt/checkpoint. NoIPAchange.
NativeR3nowunlockedcenter630720,Circlearmed; cloneUIwillresetfixture.
PriorNativeR4center706420 preserved. Inventory8/0/1/47.

18215 completed11pass/1fail: test incorrectlyexpected CircleCenterControl
(informational5ptmarker) absent. Nativebluecenterpointremains; liveclonealso
retainsit, selectedcenterunitNilpassed. CorrectedUI requiresmarkerexists
andCircleCenterLockToggleabsent; geometryassertions unchanged. Selectedbadge
also nowpreservesexistingconflict-red styling/accessibilityidentifier. Same12
cases serialexec27851 `/tmp/os3d-qa12-armed-radius-final-20260911.xcresult`
nowowns simulator. No livefinalcontrolsclaimyet; first11/12retained.

## September 11 02:06 — armed radius live control and history follow-up

27851 completed clean12/12, no failures/skips. Exact-build live fresh R0.2475
compact leader opens editor; R0.3 commit shows selected white/blue badge and
dimension Unlock, without selected-center Lock. Direct Unlock retains geometry
and R0.3, restoring the plain outward leader, matching native R3 sample.
Native direct-Unlock Undo and Redo clear selection and disarm Circle. Clone
Undo restored compact radius but retained Circle/selection: confirmed separate
lifecycle gap. Narrow RemoveSketchDimensionCommand radius/selected-circle
Undo cleanup implemented; geometry and cleared/disarmed unit assertions added.
Serial exec94018 owns simulator, result
`/tmp/os3d-qa12-radius-unlock-history-20260911.xcresult`. No live postfix claim.
Latest7 screenshots copied to circle-annotation-modes local report. Publication
remains747/master38; new final controls/history evidence not inserted yet.
HEAD5436e46; current compact/badge/Unlock/history work uncommitted. Inventory
8passed/0failed/1deviceblocked/47incomplete. IPA unchanged. Exact next collect
94018, live corrected Unlock Undo/Redo and saved reopen, publish verified images,
commit/push then remaining QA12 cancellation/reverse creation.

## September 11 02:10 — armed radius controls verified

94018 completed clean10/10. Final live R0.3 Unlock Undo/Redo both clear readout
and disarm Circle while preserving geometry, matching native R3 reference.
Gallery reopen retains nativeR3/cloneR0.3. Illustrated export
`/tmp/os3d-qa12-armed-controls-final.docx` verified756 placements, allnine
newhashes+1, no747predecessorimage loss, allorderedprior text preserved. Master
`/tmp/os3d-qa12-armed-controls-master.docx`38media/headingonce verified.
No runner active. NativeFrontfreshR3selectedafterreopen; cloneTopR.3selected
afterreopen. Exactnext commit/push compact radius/badge/Unlock/history correction,
then paired reverse creation and armed cancellation; QA12 remains partial.
