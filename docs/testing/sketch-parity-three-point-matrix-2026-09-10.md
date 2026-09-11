# QA10 remaining three-point matrix — September10

Baseline593f25c; QA08/09 closure published624/master38 and pushed. Inventory
6passed/0failed/1deviceblocked/49incomplete. No IPA modification.
Native reversed baseline780,230→620,190 produces17.2047mm. Escape removespending
baseline and leaves Rectanglearmed, prior10rectangles intact. First attempt
780,200→650,170 crossedheader and creatednothing; excluded. Clone580,340→420,300
produces2.05mm pendingbaseline. Both pressescape and hotkeyescape leave it intact;
inputdelivery unresolved, no blanket cancellation verdict. Existing automated
cancelworkflow runs independently.
Paired readout: native outlinedwhite/bluevalue offsettowardgeometry fromleader;
cloneplain text lies ONleader and is struckthrough. Narrow correction flags only
releasedpendingthreepointbaseline, offsetslabel18screenpoints towardsgeometry,
addsoutlinedwhitebackground. No geometry/hitbounds/numericinteraction changes.
Native value remainsinteractive; clonepending liveoverlay is informational,
so full pendingnumeric interaction parity remains open. Baseline color/leader
spacing also differ and are not silently markedmatched.
Evidence `/tmp/os3d-qa10-*` copied/hashed toreports/.../three-point-matrix.
Serial /tmp/os3d-qa10-baseline-readout-20260910.log/.xcresult runs threeexisting
construction,height/history and tapcancelUI workflows. Postfixlivepending;
no simultaneous desktopinteraction.

Readout regression finished clean3/3 (82.898s); no livepostfixclaim yet.
Illustrated diagnosis626/all2hashes/no624predecessorloss/orderedtext verified at
/tmp/os3d-qa10-baseline-diagnosis.docx. Master38 unchanged.
Code inspection found a concrete Escape registration omission: CancelRectangle
button has no keyboardShortcut; CommandShortcuts registers Line/Arc but notRect.
Native secondEscape disarms Rectangle after pendingbaselinecancel (capture
native-second-escape). Added guarded cancelRectangleInput: pending→clear, idle→
deselecttool; numeric editor retains priority. New test checks allplacementstages,
committedsketch equality and unchangedUndo depth. Serialexec63056
/tmp/os3d-qa10-rectangle-escape-20260910.log/.xcresult nowowns simulator;
RectangleInputCancellation+Construction+existingtapcancelUI. Livepostfixpending.
Earlier delivery-only suspicion is corrected by code evidence, not erased.

Final Escape run clean29/29 (28unit+1UI), zero failures/skips. Live newbuild
reversebaseline2.05 readout now outlined and clearofleader. Same pressescape
nowremovespendingbaseline/Cancelbutton and keepsRectanglearmed; nextEscape
disarms. Savedrotatedrectangle unchangedinbothcaptures. Nativefirst/second
Escape referencealreadycaptured. Concreteomissionverified; nohostinputreset.
Fivepostfiximagesinsertedonce; exportverificationpending. Stillopen numeric
pendingbaselineinteraction, leaderdistance/color andremainingcompletioncases.

Publicationverified631placements/all5newhashes/no626predecessorloss/orderedtext; /tmp/os3d-qa10-cancel-published.docx. Master38media/noimageororderedtextloss andone datednote /tmp/os3d-qa10-cancel-master.docx. Commit/push thencontinuependingnumeric/completion; no runner.

Pending numeric follow-up after64992d1: click atprior native readout location
completedrectangle instead of openingeditor; cmdZ removedit. R repeat changed
subtype toCenter, accidentalcentercreation undone; invalid numeric evidence.
Explicit3Points reselected, followingdrag showedonlyfirstpoint. Bare1 thenreset
view/exitedsketch anddisplayednativeviewtip, notnumericentry. Thus earlier phrase
"Native value remainsinteractive" was an unverified assumption and is withdrawn.
No pendingnumeric productgap is established. Keep investigation separate from
verifiedreadout/Escape fixes; continuecontrolledtapconstruction/oppositeheight.

Controlledtwo-tap baseline800,240→650,200 recoverednative19.2508mm selectedreadout.
Bare1 nowopensnumericfield (valid-key1);5→Returnupdatespendingbaseline15mm,
firstendpoint800,240 held. Thirdclick680,270 completes15×7mm rectangle. Earlier
onlyfirstpoint/resetviewattempt excluded. Clonevalidtwo-tap580,340→420,300 produces
2.05readout; bare1noeffect. Pendinghardware-entry gap nowconfirmed fromvalidstates.
Implementationdraft: number/dot shortcuts openexistingDimensionField forpending
baseline, keepkeypad+hardwarefocus; commit updatesonlypendinggeometry, retains
optionaldrivingdimension foratomicrectanglecompletion. Cancelclearsit; nohistory
untilcompletion. Tests coverinvalid1/0 recovery,2cm conversion/source,firstendpoint,
noearlydocument/history,onecompletionUndo/Redo/reload,cancelleddimensionno-leak.
Serialexec68901 /tmp/os3d-qa10-pending-baseline-input-20260910.log/.xcresult owns
simulator; pendinginput+keypadunit+tapcancelUI. No livepostfixclaim.

Pendingentryrun clean23/23 (22unit+1UI). Live firstimmediatekeywas tooearly;
settledbare1 openspad, .5append→1.5, Returnshortenspendingbaseline preserving
firstendpoint580340. Thirdpoint460390 completes1.5×0.9664; priorrotatedrectintact.
Overlaybugconfirmed: livependingreadout paintedabovekeypadkeys. Movedliveoverlay
belowordinarydimensioneditor (nohit/geometrychange). Focusedexec33921
/tmp/os3d-qa10-pending-input-overlay-20260910.log/.xcresult owns simulator;
pendingunit2 +height/historyUI. Initial23passretained; finalvisualpending.
Completedclone selectsallfourlines/showsconstraintbadges; native selectscenter.
This remainsa distinctQA10presentationgap, not erased by successful numericentry.

### Final pending-input live repeat — September10 21:22 EDT

Overlay followup passed clean3/3 after initial23/23; no product test failures.
Final keypad screenshot shows pending label/leader underneath opaque keys.
Return1.5 preserves first endpoint; third point creates1.5×0.9664. One toolbar
Undo removes new rectangle; Redo restores. Saved gallery reopen labels verify
both values. Native oneUndo removes15×7 rectangle and Redo restores; gallery
reopen baseline15 and selected height edge7 retained (height leader partly
behind native palette, bottom measurement readable). Native Undo disarms the
Rectangle tool while clone retains it: separate lifecycle difference, not closed.
Evidence final-keypad/return/complete/undo/redo/reopen-width/reopen-height-settled
and native-typed-undo/redo/reopen-normal/reopen-height-final PNGs. Publication
postfix pending; diagnosis634/master38 already verified.

Publication verified: illustrated640 placements against634 diagnosis, all five
final hashes present (completion twice; others once). First export638 caught
missing keypad/height and duplicate completion due delayed upload routing;
trigger-ref uploads restored missing images. No predecessor image loss and all
prior text characters remain ordered. Master38/no image loss/old text ordered,
new note once. Exports /tmp/os3d-qa10-pending-final-settled.docx and
/tmp/os3d-qa10-pending-master.docx. Duplicate completion retained as redundant
evidence, not an extra distinct check.
