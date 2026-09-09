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
