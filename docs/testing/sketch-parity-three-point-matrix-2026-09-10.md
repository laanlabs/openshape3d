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

### Committed history tool-state correction

Native typed15×7 rectangle Undo removes geometry and disarms Rectangle; Redo
restores geometry without rearming. Clone previously remained armed. Scoped
three-point committed Undo now deselects the drawing tool; pending rectangle
cancellation still returns before touching document history. Clean4/4 in
/tmp/os3d-qa10-history-disarm-20260910.xcresult (2pendingunits, height/historyUI,
tap/cancelUI). Final live fresh2.0523×0.9664 rectangle Undo removes only that
rectangle and clears the palette highlight/header; Redo restores shape without
rearming. Prior fixture unchanged. history-complete/history-undo-fixed/
history-redo-fixed PNGs captured; native-typed-undo/redo is paired reference.
Publication verified642/new2hashes once/master38, no predecessor image or
ordered text loss (/tmp/os3d-qa10-history-published.docx and history-master.docx). Release center remains
open. No other drawing tools or whole-app history semantics generalized.

### Three-point center-control gap

Native saved15×7 center direct Lock clears selection/turns center green; reselect
and direct Unlock restores selected free halo. Clone center click no target.
Paired center PNGs retained. Fresh construction now stores ordered group identity
without center sizing intent, selects center on release, hides implicit glyphs.
Current exec36940 tests group Lock/Unlock/history plus construction and3UI.
No post-fix live claim. Legacy loops without group metadata still need recovery.

Initial center-control36940 result32/33: center Lock included3wholeedges
from release selection; unit assertion correctly failed. Direct padlock now
clears entity selection before deriving Lock refs. Same33 rerunning90180.

Center diagnosis export646/all4newhashes exactlyonce, no642predecessorimage
loss and all prior text characters ordered. Master remains38 at history note.
All current publication exports also copied into local evidence directory.

Corrected90180 clean33/33 (27construction,3pending/centerunits,3UI). Shared
center padlock path followup85567 runs2existing center/migration unit tests and
centerrelease UI. Final live controls pending; initial failure retained.

Existing85567 clean3/3. Live fresh release/directLock/reselect/Unlock pass;
clone center moves(-40,-20) rigidly and UndoRedo restoresgeometry. Native
center move(+60,0) and UndoRedo pass; native clearsselectedhalo afterhistory
while clone retained it. Scoped no-sizing-anchor groupcenter history cleanup
added; exact center-drag/history unit assertions included. Run24376 active.
All current center PNGs copied/hashed; final publication pending.

24376 clean5/5. Final live movement(+40,-40), UndoRedo nowclearselection and
restoregeometry. Galleryreopen centercontrol retained; width2.3659,height1.
Savedwidthselection revealedheight alias on bothparallel sides, inheritedfrom
migratedcenter presentation. Scopedextraaliases to sizing-metadata groups;
newunit assertsonealias onadjacent/retaineddimension. Sixcasesrun71931 active.

Final71931 clean6/6, includingexistingcenterrotationUI. Live reopened3pt
width2.3659/height1 nowshowsoneheightlabel; heighteditoropensvalue1 withfully
visiblekeypad. Native movedcentercontrol also survivesgalleryreopen.
Publication653/all7newhashes once, no646predecessorimageloss andorderedprior
text preserved. Master38/newnoteonce/noloss. Exports center-final-published
andcenter-final-master copiedlocal. Freshgroupcontrol verified; legacyloops
withoutgroupidentity remainunsupported, QA10partial. No wholeapp/deviceclaim.

### Legacy group recovery continuation

Fresh controls pushed377bf34. Confirmed legacy loops still lack center targets.
Conservative decode recovery implemented for an isolated four-line loop with all
seven original directed construction constraints, declining disconnected, branched
or externally related groups; no geometry/dimension/sizing-intent changes.
Initial41618 failed compilation because two new fixtures omitted edge IDs; zero
tests ran. Corrected57656 runs rectangle construction plus existing sketch decode
coverage. Live recovery and publication pending.

Corrected57656 clean41/41. Final28378 clean51/51 after absent-key/driving-
dimension retention coverage and excluding pattern-linked groups. No runner.
Controlled QA10-Legacy.os3d (SHA256 f1fda73fdf673c1ea2d4c8a08f50ef3fa5f94e9848ada924d5843f393fe1fbb1)
retains original four lines/seven constraints/dimension and omits group metadata;
original JSON retained. First archive-copy attempt failed because app container
changed after tests; resolved new path read-only and copied separate archive.
Live Import > Recents: Content Unavailable; On My iPad: Empty. No legacy file
loaded, no live migration claim. Picker dismissed; existing design reopened.

### Forward baseline/opposite-side completion

Native3Points baseline600,740→750,710 reads17.9023mm; third730,780 commits
17.9023×8 with two readouts/selectedcenter/no keypad. Clone380,380→540,350
then520,420 completes2.0254×0.8126 with matching completion controls; different
zoom/model scales. Pending native baseline orange vscloneblue confirmed; native
leader farther from edge, scale comparison retained. Narrow orange released-
baseline correction now under serial57843 (3pendingunits + tap/cancelUI), no
post-fix live claim. Both forward PNG pairs copied/hashed local. Native now12
rectangles/48edges; clone pre-test2rectangles (tests may reset controlled fixture).

Pending-color57843 clean4/4. Exact-build live baseline380,380→540,350 is
orange; Escape removes draft/readout without changing prior rectangle, tool
remains armed. Native same baseline repeated on existing last rectangle then
Escape removes pending preview/readout and preserves all48edges, toolarmed.
Use isolated native-forward-baseline image for color comparison, not later
overlapping draft. Illustrated660/all7newhashesonce/no653predecessor loss and
ordered text retained; master38/noteonce/noloss. Exports forward-published and
forward-master copiedlocal. Leader spacing and legacy live recovery remainopen.
