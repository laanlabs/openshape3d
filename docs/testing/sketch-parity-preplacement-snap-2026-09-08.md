# Pre-placement line snap feedback — September 8, 2026

Baseline daa8478 pushed. No competing desktop worker. Native MAIN Front sketch
standalone copied horizontal line342359→424359; clone saved Top sketch has
horizontal lines298431→484431 and298562→484562. Native snapping popover showed
all categories off, Hints on from earlier category tests. Enabled only Sketch
Guide Points. Hover left endpoint then shows purple marker + Endpoint tooltip.
Native midpoint hover shows purple marker, no captured text yet; not a label pass.
Clone settings also had Grid/Sketch/Face off and Hints on. Enabled only Sketch
Guidepoints, selected Line, hover original endpoint: no marker/hint.
Code confirms idle hover ignored until tap-chain active. Implemented line-only
preplacement named snap feedback; creates no anchor/entity/undo operation. Nil
hover clears. Added model regression endpoint/midpoint/leave/category-off/no-edit;
serial12051 ConstraintApply+SnapKind owns simulator, postfix live pending.
Mouse versus Pencil hover remains a device-A/B distinction. QA20 zoom notrun.
Local snap-feedback images retained; no new Doc publication yet.

12051 clean25/25 (12ConstraintApply+13SnapKind), no failures. Postfix reopened
clone sameendpoint idlehover still blank. Inspecting Simulator pointer delivery;
no liveparity claim and no further speculative app change. No geometry created.


21:16 correction to acquisition setup: guidepoint clicks had NOT enabled the
clone switch. Post-test plist and screenshots confirmedfalse. Direct slider drag
742566→764566 made it green; only then is the clone snap-on comparison valid.
Earlier clone snap-on/hover statements excluded. Verified enabled hover still
blank (input delivery unresolved). Model idlefeedback remains automated-only.
Native guidepoints on: 20px-above endpoint start342339 remains20px from342359;
new segment ends280320. Near3px hover latchespurpleendpoint359; near drag did
not produce accepted segment. Clone verifiedguidepoints on: start298411 (20px
above298431) snapsdown to431, segment to230360. Thus fixed0.35model radius
captures an unexpectedly remote target at this zoom. Simulator imagepx differ
from UIKitpoints; no exact native threshold claimed. Adopt12UIpoint radius via
camera world-per-point for all VM SnapEngine calls; chain start acquisition uses
same enabled radius, epsilon whenoff. Gridspacing/otherchainclosure remainseparate.
Serial78332 /tmp/os3d-screen-snap-radius-20260908.log/.xcresult covers SnapKind,
FaceSnap,ConstraintApply andLineChainUI. Live near/far/zoom repeat pending.

Simulator-only app restart cleared pointercapture; temporarilyopeneddefault
sim53EC... then shut that newlyopeneddefault down and restored dedicatedAC2...
Normal simulator nowwindow5147 at27544. No Mac/ScreenSharing/securitychanges.
CLI fellbackondemandpermissionerror; healthyexistingGUIbridge selected explicitly
with --bridge-socket '/Users/thelodgestudio/Library/Application Support/Peekaboo/bridge.sock'.
All future Peekaboo calls use that existinghost. No tests/GUI overlap.


78332 clean37/37:36unit (12ConstraintApply,10FaceSnap,14SnapKind)+1LineChainUI.
Postfix freshFront line250350→450350 length2.477; settings screenshot confirms
Guidepoints/Hints on,Grid/Face off. Far20px-above250330 start remainsseparate;
near3px-above250347 start snaps250350. AfterUndo andOptionpinch, line spans
164212→553212 (~1.94x); nearleftcontrols164232 drawingattempt producednone,
excluded. Adjustpinch to~1.48x:207280→502280. Far20px-below207300 startsseparate;
Undo, near3px-below207283 snaps207280. Bothvalidzoom samples keepbaselinefixed.
This is two sampled scales, not full0.1x/1x/10x QA20 acceptance. Native original
far20pxfree +near3pxpurpleacquisition supportbounded comparison; near native
segmentdelivery remainedunverified. Idlehover implementation remainsautomatedonly.
Postfix imagescopiedroot; publication inprogress. No testrunneractive.

Publication/reopen checkpoint21:33: illustrated Saved83 embeddedimages, all3
native/far/near PNG hashes match exportedDOCX; initial82exportlaggedlastimage,
repeat83verified. Master38 snapfollowthrough/finalreopen noteexportverified.
Finalclone galleryreopen preserves2.477mm baseline and joinedbranch. Fullmatrix,
idlehoverdelivery and leftedgeinput remainopen; no candidate claim.
