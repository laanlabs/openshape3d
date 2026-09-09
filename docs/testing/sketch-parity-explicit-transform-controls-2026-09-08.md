# Explicit sketch transform controls — September 8

Baselineb9ad8ea. Native circle801334 Ø1000 (unlocked) explicitMove/Rotate shows
whiteaxisarrows/cornerrotationcontrol, notpersistentlargebluering/diamond.
Native diagonal axisdrag producednone (excluded); clickverticalarrow801284,
type1000,Return commitscenter801292 withx/diameterunchanged. Screenshot
os3d-transform-native-axis-typed.png. Clonecircle450570 explicitmodeonlybluering;
clickcorrespondingarea450520 deselects, noaxisnumericcontrol. Capturesmodebefore
andaxisattempt; thisisabsenceverification, notgeometryequivalentdistance.

## Implementation under verification

Explicitmode whiteX/Y/rotationoverlay plusnearbyNumericKeypad; centerfree-move
continuesexistingcanvaspath. Overlaydragprojectsontoplaneaxis; tapopensnumeric
entry. Typedunits/anglevalidated, zero/cancelno-op; savesexistingcoalescedhistory,
Copyandconstraintsolverpaths. Legacyautomaticmultiselectionringunchanged.
First40386 buildfailedbeforetests:quantizeflagunintentionallyreplacedunrelated
sketchdragconditions. Fixedscope, globallocaldragcoordinatecorrection. Rerun
45777 /tmp/os3d-explicit-sketch-controls2-20260908.log/.xcresultrunningserially.
NewexactaxisunitandtypedaxisUI pluscirclecenter,arcCopy,transformregressions.
Livepostfix/publicationpending. No concurrentdesktopworker.

Rerun45777 newtypedaxisUI failedbeforetap: outline/whiteglyph exportedduplicateYbuttonIDs. AddedaccessibilityElement(children:.ignore) tocreateoneexplicitlabeledcontrol; nofirstMatchworkaround. ArcCopy/circlecenterpassed; remainingrunstillactive, targetedrerunpending.

45777finished65:18unit+5UIpass,1typedaxisUIduplicate-targetfailure. Accessibilitysinglecontrol correction79961targetedrun /tmp/os3d-explicit-sketch-controls-axis3-20260908.log/.xcresult owns simulator. Native/clonepostfixlivepending.

79961targetedaxisUI passed.24distinctchecks across45777+79961,notcleancombined.
Livewhitecontrols replacebluering;Yarrow450600 opensvisiblepad;1mm commitmoves
circle450650→450569,Ø0.992unchanged. Undo650/Redo569 verified. Arcrotationkeypad
45commitsretainedR1.241/106.26,butpairednativefree45 exposedinitialpivotdifference:
nativearcR539.1552 center775446 usesvisibleboundscenter786446, movingcirclecenter
onrotation;cloneusedsupportingcirclecenter280460. Exactbounds(singlearconly)
correctionnowunder97350 /tmp/os3d-explicit-sketch-controls-pivot4-20260908.log/
.xcresult. UI Copyfixtureupdatedfromcirclecenter tovisibleboundscenter.
Nativeoperationvaluepersists andcontrolframerotates withoperation; clonecurrently
clearsinput/recomputesbounds/worldaxes. These remainopenfollowups,notfullparity.

## Verified follow-through, 22:50 EDT

97350 finished successfully: one clean 16/16 run (14 ConstraintApply unit tests
and two UI workflows). This does not erase the earlier compile/accessibility
failures or turn the complete 25 distinct checks into one clean run.
Live corrected arc rotates 45 degrees around initial visible-bounds center
(280,380), not supporting-circle center (280,460). Radius 1.241 mm and sweep
106.26 degrees remain unchanged. Undo/Redo restores/reapplies geometry.
Typed X Copy 1 mm retains the original arc and creates a second translated arc;
gallery reopen visibly retains both. Captures: os3d-transform-pivot-mode.png,
-angle45.png, -undo.png, -redo.png, -copied.png and -reopened.png.
No test runner remains active. New-control publication is pending export
verification; native-axis image was inserted, not yet verified as saved.
Retained operation value, fixed operation pivot and rotated local control frame
remain blocking follow-ups; the current implementation resets those after commit.

Publication verified: illustrated export has 92 images; native axis, corrected
45-degree arc and final two-arc reopen PNG SHA256 hashes match embedded media.
Master final gallery-reopen note verified by DOCX export (38 existing images).
Native follow-up inspected input 90 before commit: angle replaces prior operation
value around original pivot, not an additional rotation. Fast earlier 90 entry
only delivered 9 and is excluded. Valid evidence os3d-transform-native-input90.png
and os3d-transform-native-valid90.png. Re-edit/frame correction remains next.

## Retained-operation follow-up under test

Native inspected 90-degree input replaces the prior value around the original
pivot. Cmd-Z restores the preceding 9-degree geometry (fast-input attempt), not
the original unrotated arc. Therefore each commit remains a separate undo step.
Implementation retains the last exact control value and original solver baseline
for supported line/circle/arc transforms; a repeated value is absolute to that
operation, not additive. New history commands retain the preceding committed
geometry as their undo state. Zero restores the operation baseline. Retention
is invalidated by mode exit, selection/geometry/constraint changes, or Copy.
Rotation pivot remains fixed; world-aligned directional frame is still open and
not advertised as matched. Focused serial run 20790:
/tmp/os3d-transform-retained-20260908.log/.xcresult. No live interactions during it.

20790 completed clean 17/17: 15 unit and two UI workflows. Live retained 45 label
opens seeded 45, replacement 90 keeps initial pivot (280,380), radius 1.241 mm
and sweep 106.26 degrees. Undo restores 45 geometry; Redo restores 90 plus value.
Clone Done/gallery/reopen retains the 90-degree arc. Post-Undo mode remains active
in clone but native exits Move/Rotate; retained local-axis frame remains open.
Captures os3d-retained45.png, os3d-retained45-editor.png, os3d-retained90.png,
os3d-retained-undo45.png, os3d-retained-redo90.png, os3d-retained-reopened.png.
No runner active. New paired publication inserted; export verification pending.

Illustrated94 images and both new90-degree PNG hashes exported successfully.
Native immediate Home/reopen after Redo returned to pre-transform right semicircle
(center775446,R539.1552,sweep180), NOT the rotated top semicircle. Reselection
confirms it; no paired persistence pass claimed. Explicit native transform
acceptance/exit path is next to investigate. Clone reopen remains verified.

## Local-frame follow-through
Native explicit Escape→Exit Sketch→Home/reopen preserves45-degree arc;
os3d-native-accepted-front.png confirms accepted-operation persistence. Earlier
immediate Home after Redo is a distinct unaccepted path, not a persistence pass.
Native new45-degree operation then inspected X1000 moves center781455→811425
(diagonal screen +30,-30), frame retained. Clone same new45 thenX1 moved
supporting center337324→418324 (horizontal). Confirmed local-axis direction gap.
Implementation now carries frame angle to rendering and next exact axis movement;
accepted movement translates the retained pivot without recentering geometry bounds.
Rotation pointer gesture captures its initial axes so the rotating visual frame
does not alter the gesture's reference basis. Serial24151 owns simulator:
/tmp/os3d-transform-frame-20260908.log/.xcresult. Live corrected repeat pending.

Native accepted-operation persistence addendum exported in both existing Docs;
public DOCX text contains the acceptance-path resolution. All earlier contrary
path evidence retained. No new image count claimed beyond verified94/38.

24151 passed clean18/18 (16unit,2UI). Live corrected45-degree frame thenX1mm
moves supporting center337437→394380, originalpivot280380→337323, preserving
R1.241/106.26 and diagonal control orientation. Native sample+30,-30 matches
direction, with different physical scale. Rotation double-arrow still radial
in clone versus native tangent; fixed +90-degree glyph orientation. Also closes
explicit mode/retained value on UI Undo/Redo, matching native observed history.
44749 serial /tmp/os3d-transform-frame-history2-20260908.log/.xcresult owns
simulator for strengthened history unit/UI plus frame/Copy regressions.

44749 passed clean19/19 (17unit,2UI), no failures/skips. Final live repeat
45→X1mm moves337437→394380 with tangent rotation arrow and diagonal axes.
Undo restores prior geometry and closes explicit mode/value; Redo reapplies
geometry without reopening controls, matching observed native mode behavior.
Clone gallery reopen/reselect retains center394380,R1.241,sweep106.26.
Final captures os3d-frame-final45.png, -x1.png, -undo.png, -redo.png, -reopened.png.
Native accepted movement reopen in progress; no runner active.

Native accepted movement reopen/reselection retains center811426,R539.1552mm,
180degrees. Both accepted-operation persistence samples verified, with distinct
angles/scales and native exit path explicitly recorded. Illustrated98images,
all four new local-frame/final PNG hashes matched exported media; master38-image
final local-frame/history/reopen note exported. No runner active.
Remaining: transform annotation visibility/placement, direct rotated handle-drag
matrix, symmetric circle frame behavior, remaining numeric/selection recipes and
final installable candidate gate. No full parity/device readiness claim.

## Symmetric-circle frame correction under verification
Native selectedcircle801292 Ø1000 keeps geometry unchanged after inspected45
rotation but retains45value/rotatedaxes. Undo closesmode without undoing preceding
accepted arcXmove (arc811426 remains). Clonecircle450650 Ø0.992 after45 drops
value/frame because no geometry command pushed. Confirmed screenshots
os3d-circle-frame-native-before/input/45/undo.png and clone-input/45.png.
Correction records circle frame-only accepted rotation in existing command history
with identical before/after geometry; do not perturb center/radius to force change.
This retains frame and ensures Undo consumes operation rather than prior creation.
Scoped to single circle rotation whose target geometry equals original.
97346 serial /tmp/os3d-circle-frame-20260908.log/.xcresult owns simulator;
ConstraintApply unit suite/new frame-history test plus exact-axis UI.

97346 passed clean19/19 (18unit,1UI). Livecircle45 retainsframe/value with
center450650/Ø0.992unchanged. X1 moves507593; Undo move thenframe preserves
circle, Redo restoresmove. Gallery reopen/reselect retains507593/Ø0.992.
Illustrated firstexport99images lackedlastcloneimage; secondexport100images
includes both new paired PNG hashes. Master circle final-reopen note exported.
Remaining confirmed visual gaps: diameter text overlaps rotatedX arrow (Xstill
openscorrecteditor); retainedXvalue hides under right constraint rail. Native
explicitMove/Rotate screenshots have no constraint rail; clonekeepsit.
Next compare free-vs-driven dimension visibility and correct transform rail/layout.

## Correction: settled post-history tool state
The prior interpretation that native Undo closes Move/Rotate was too broad.
Settled screenshot os3d-transform-annotation-native-start.png shows Move/Rotate
armed with 'Select items to move or rotate' and no selected handles. Clicking
circle801271 immediately restores controls (os3d-history-native-reselect-transform.png).
Thus native clears selection/operation value but retains armed tool, not full
mode exit. Earlier geometry/restoration evidence stands; mode sign-off withdrawn.
Correction keeps tool armed, clears selection/retained state for history; keeps
Done available even without selection. Selection changes retain tool; entering
a drawing tool or leaving sketch clears it. Nativeexplicit screenshots also
show no constraint rail; clone rail now hidden in explicit transform (removes
confirmed right-edge value obstruction). Serial56861 owns simulator:
/tmp/os3d-transform-armed-history-20260908.log/.xcresult. Unit+axisreselectionUI,
CopyUI and draw-switch-draw regression. Live correction pending.

56861 completed clean21/21 (18unit+3UI), no failures. Live Undo clears selection
and controls but keeps Move/Rotate armed; reselection restores controls. Redo
restores moved circle507593 without selection; Done restores normal rail and
circle controls. Retained X1mm value visible near right edge while rail hidden.
Screenshots os3d-armed-history-mode/x1/undo/reselect/redo/done.png inspected.
Normal circle diameter still overlaps rail after Done: separate open visual gap.
No test worker active. Earlier mode-exit interpretation explicitly superseded.

Publication: illustrated102 embedded images; both new native/clone armed-state
PNG SHA256 values match anonymous DOCX media. Master38 images/result prose
verified. Exports /tmp/os3d-armed-final-illustrated.docx and -master.docx.
