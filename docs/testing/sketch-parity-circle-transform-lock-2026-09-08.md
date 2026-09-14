# Explicit circle transform: saved Lock

## Paired diagnosis, September 8 (~21:45 EDT)

Baseline bb2dd70, dedicated simulator window5147, no concurrent worker.
Native Front circle center744309, driven Ø1000mm: applied Lock, entered
More > Move/Rotate, clicked vertical axis and typed1000. Native refused with
“Sketches with locked points can't be moved.” Geometry stayed at744309.
Clone fresh Front circle450550, free Ø0.992mm: applied Lock (glyph and Unlock
verified), entered explicit Move/Rotate. Center drag was intercepted/no change;
excluded. Offset center-handle drag450570→450490 moved circle center450550
→450470 while its Lock remained. Screenshot confirms concrete enforcement gap.
Reference and clone units/zoom differ; compare locked translation refusal only.

Evidence root: workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/circle-transform/.
- os3d-circlelock-native-refusal.png
- os3d-circlelock-clone-locked.png
- os3d-circlelock-clone-offset-result.png

## Implementation and checks

Line/circle explicit transforms now solve point intent against the original
sketch constraints instead of raw non-line entity replacement. Other primitives
retain their existing paths pending paired comparisons; no broad parity claim.
Regression checks free/driven circle translation, whole/center Lock and unrelated
geometry preservation plus existing rectangle/transform workflows.
Serial76569 running /tmp/os3d-circle-transform-lock-20260908.log/.xcresult.
Post-fix live, persistence and screenshot-backed publication pending.

## Prior snap-input followup

Normal-zoom left-canvas164232→220300 draws successfully in both apps; captures
os3d-left-native-result.png and os3d-left-clone-result.png. No general left-area
block reproduced, so no speculative layout change. Earlier1.94x post-pinch
unaccepted placement remains a narrow input sample, not geometry evidence.

## Verified correction (~21:58 EDT)

Serial76569 finished0, clean28/28:21RectangleConstruction+4SketchRadialDrag
unit and3SketchTransformUI. No tests active. Live fresh circle450550 Ø0.992:
Lock+explicit mode, same offset450570→450490 refuses with notice and no movement.
Unlock then same drag moves center to450470; Øunchanged. Undo center550,
Redo470. Relock, gallery reopen retainscenter470/Ø0.992/Unlock; same upward
attempt refused again. Native gallery reopen (Skip limited-version prompt,
foregroundCmd2 and double-click circle) retainsØ1000/Unlock, center801334 at
new fit scale. BackgroundCmd2 didnot changeview; excluded. Native and clone
refusal screenshots published to illustrated newtab; export verification pending.
Other primitive transforms and central diameter-label interference remain open.

Publication verified: illustrated85 images (native/refusal2 new PNG SHA256 matches); first export84 lagged last image, repeat85 verified. Master38 images and circle/final-reopen note exported. Original stalled tabs preserved.

## Diameter hit-target followup (~22:16 EDT, baseline36127b6)

Freshfreeclonecircle450650 Ø0.992, explicitmode paintedcenterdrag450650→450570
ignored; offset450670→450590 movescenterto450570. Native current drivenØ1000
circle (Unlock applied) retainsdiameterleader inMove/Rotate, contrary to earlier
assumption that mode universallyhideslabels. Keepreadoutvisible; extenddiameter
textclearance20→60UIKitpt onlyinexplicitmode so44ptbuttonclearsthemovehandle.
No nativecenter-handlemovement parityclaim (nativeusesaxiscontrols). Screenshot
os3d-circle-center-native-mode.png plusclonecenter/offsetresultslocal.
Serial37465 /tmp/os3d-circle-center-clearance-20260908.log/.xcresult running2UI
checks:actualcenterdrag/history/editorreachability andexistingdrivendiameter.
Postfixlive/publicationpending. No otherworkers.

Clearancefollowup37465 clean2/2. Postfixlivecenter450650→450570 moves,
UndoRedo restores650/570. Labelat470535 opensusablekeypad; unchangedcommit,
Done/galleryreopen retainsØ0.992/center570 withordinarycloseleader. Native
explicitdrivenØleader retained referencepublished, clonepostfiximagependingexport.
Blue ring/diamond vsnativewhitedirectionalcontrols remainsblockingvisualgap.

Clearance publication: illustrated89images/twonewPNGhashes verified (first88laggedlast); master38paintedcenter/finalreopen noteexportverified.
