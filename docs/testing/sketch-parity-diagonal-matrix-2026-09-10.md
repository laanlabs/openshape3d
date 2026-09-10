# Diagonal rectangle remaining live matrix — September 10

Baseline b59abcf (product eb9b4ab). No source edits or tests running.
QA07 closed/published460; this begins QA08 remaining mixed-quadrant checks.
Earlier up-left/down-right and normalized lower-left rules retained, not repeated.

Native existing Sketch03 line fixture hidden via Items eye after model-mode
exit/clear/hover; all22lines preserved. Empty Front Sketch04 created. Diagonal
1000,350→800,500 global down-left produces30x22mm (screen bounds local
x710–901,y271–411). Width30→15 holdsleft710,movesright901→806. After Escape
and left-edge reselection, height22→11 holdsbottom411,movestop271→341;
width stays15. Both edits keypad1/5 or1/1 thencommit, inspected screenshots.
Files /tmp/os3d-qa08-native-downleft-release.png, -width15.png, -height11.png
(with full prefix os3d-qa08-native-downleft-). No publication claim yet.

Clone prior eight-line Untitled preserved; fresh Untitled2 created via gallery.
Currently modelmode empty, no rectangle yet. Exactnext draw down-left and edit
both sizes, comparelowerleft; thenup-right/height-first counterpart, history,
reopen and relevant regression if changes or current-revision gap justify.
No physicaldevice/IPAchangerequest. QA08 remains partial.

## Paired diagnosis and correction under test

Clone down-left release1.989x1.494 became1x0.75; left268 andbottom440
remainedfixed. Native15x11 likewise holdsleft/bottom. Sample geometrypasses.
Visiblegap: native down-left widthleaderabove, clonebelow. Freshup-right
native31x19 heightleaderright; clone1.979x1.481 heightleaderleft. Captures
/tmp/os3d-qa08-{native,clone}-downleft-* and native-upright-release-valid.png,
clone-upright-release.png. Native r shortcut attempt didnotarmtool and earlier
upright-release.png is excluded; More/Rectangle validrepeat producedsecondrect.
Historical Sept8 up-left capture confirms top/right; down-right bottom/left.

Correction uses persisted firstcorner metadata for default leader sides only,
without changing lower-left sizing geometry. Explicit selectedside wins; center
and legacy rectangles retain defaults. Reload/allfourdirections/selectededges
unit coverage added. Serial focused regression starts; livepostfix and publication
pending. No IPA modifications. QA08 remains partial.

## Clean regression and live post-fix

/tmp/os3d-qa08-leader-sides-20260910.xcresult passed25/25,0failed/0skipped
in onecleanrun:22RectangleConstruction,1new persistedleader/selectededge test,
2RectangleWorkflowUI. Unit tests reset clone gallery; freshUntitled2 created.
Postfixdown-left widthabove/heightleft andup-right widthbelow/heightright match
native references. Cloneup-right1.979x1.481→1.979x0.75→1x0.75 holdsbottom720
andleft229(local). Native31x19→31x9.5→15.5x9.5 holdsbottom621,left551.
NativewidthUndo via hotkey cmd,z restores31,redo cmd,shift,z restores15.5.
ClonetoolbarUndo restores1.979,Redo1;editedheightretained.

Excludedattempts: firstcloneheightclick at508705 missedlabel(center508690),
startedpendingrectangle; Escape via press didnotcancel it, nextclick committed
extra rectangle. ToolbarUndo removed onlyextra,Rectbuttonexplicitlydisarmed.
Two intendedrectangles preserved; successfulnumericchecks use inspectedcenter.
Native press cmd+z didnotundo geometry; supported hotkey did. Notappfailures.

Illustrateddiagnosis verified466placements/464media,allsixnewhashesonce,
no predecessorloss vs460; /tmp/os3d-qa08-diagnosis.docx. Postfixpublication
andgalleryreopenpending. Evidencecopiedto reports/.../diagonal-matrix with
SHA256SUMS. No runner; uncommittedproductcorrection remains underliveverification.

## Saved recovery and publication blocker

Paired gallery reopen passed: clone1x0.75 with right-side size restored; native
15.5x9.5 andprior15x11 retained. Explicitcloneleft-edgeselection movesheightleft,
provingoverridepriority. Native trialprompt dismissed withSkip, noaccountchange.

Postfixpublication attempted once but Google session signedout. Illustratedt18
nowread-only/requesteditaccess; mastert19 explicitly says signedout/signinfrom
anothertab. Fresh /tmp/os3d-qa08-postfix-publication-check.docx stays466 and
postfixheadingabsent. No newimagesinserted; allpostfixevidence local. Restoring
authorized Googlelogin viahost-owned signin resolves; never requestsecrets.
Parentnotified. Sourcefix cancommit; publicationpendingnotclaimedcomplete.
