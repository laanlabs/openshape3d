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
