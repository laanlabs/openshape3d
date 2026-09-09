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
