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
