# QA-04 empty entry/cancel — September 10

Baseline d5cb119. No new product changes or test runner.

Clone saved design contains Sketch 1 (line0.5mm and circle). From model mode,
Sketch→Line→green ground tile creates provisional Sketch 2. Items shows both
while empty; Exit Sketching removes Sketch 2 and preserves Sketch 1 visibility.
Inspected /tmp/os3d-qa04-items-baseline.png, -top-during.png, -top-after.png.

Native Top Sketch command re-enters existing Sketch 02; excluded from empty
entry evidence. View→Default View resets oblique, Sketch enters No active plane.
View→Front then activates empty Sketch 03. Items never adds a new row in the
inspected empty state. Exit returns to model with original Sketch02, Body01,
Sketch01 only. Body01 deliberately hidden via right-click Show/Hide beforehand
to uncover origin; it remains hidden. Existing sketches remain visible.
Inspected /tmp/os3d-qa04-native-front-empty.png and -front-after.png.

Input setup errors retained: initial clone clicks lacked explicit app switch;
View→Views→Isometric is nonexistent; corrected supported View→Default View.
Right-click --button unsupported, corrected --right. No geometry was drawn in
these setup attempts. Native rapid state transitions required settled recapture.

Remaining: matched Front/Right/Top entry Exit/Escape, hidden existing sketch
(not just body) visibility preservation, final gallery reopen and relevant unit
regression. No QA-04 full pass or publication claim yet.

## Front Escape and provisional Items discrepancy

Paired Front firstEscape disarmsLine, secondEscape exits/removesempty context;
existing sketch visibility retained. Native emptySketch03 neverappearsinItems;
clone provisionalSketch2 visible until exit. Captures native-front-esc1/esc2,
clone-front-empty/esc1/esc2. Implemented itemSketches presentation filter only for
untouched provisional entries (same history depth, no redo, no entities/relations/
dimensions). Persistedempty andhistory-owned rows remain. Added identity test
for firstgeometry→Undo→Redo discovery, strengthened hidden-reference assertion.
Serial SketchIdentityTests + ItemsUITests started exec76274,
/tmp/os3d-empty-items-20260910.{log,xcresult}. Live post-fix pending.

## Explicit closure matrix (in progress)

| Entry/state | Native | Clone | Remaining |
|---|---|---|---|
| Front empty / Exit | verified | pending current repeat | post-fix clone |
| Front empty / two Escapes | verified | verified pre-fix | post-fix clone |
| Top empty / Exit | existing coplanar reentry, not valid empty sample | verified pre-fix | isolated native empty Top |
| Top empty / two Escapes | pending | pending | paired |
| Right empty / Exit and two Escapes | pending | pending | paired |
| Hidden existing sketch stays hidden | pending (hidden body only so far) | pending | paired |
| First geometry reveals row / history retains discoverability | pending reference capture | unit under regression | live both |
| Gallery reopen after empty cancellation | pending | pending | paired |

Diagnosis paragraph and native/clone Front empty images inserted once in t18;
export `/tmp/os3d-empty-items-diagnosis.docx` pending verification. All local
screenshots (including excluded setup attempts) retained under workspace
reports/openshape3d-core-sketch-milestone-2026-09-08/empty-entry/SHA256SUMS.

Diagnosis publication export verified at 405 placements: native/clone new hashes
exactly once, heading once, no predecessor loss versus the 403-placement field
report. `/tmp/os3d-empty-items-diagnosis.docx`. This documents the pre-fix gap,
not post-fix verification or full QA-04 acceptance.

## Post-fix live followup and native history refinement

Initial combined run clean6/6 (5identity +1Items UI). New liveclone Front entry
with hidden consumedSketch1 and hiddenMyPart omits provisionalSketch2; first
2mm line revealsSketch2, Undo removesline but initiallyretainedrow, Redorestores.
Native first80.0007mm line revealsSketch03; Undo removes BOTH geometry androw,
Redo restoresboth. Thus initial claim that a history-owned empty row should stay
visible is withdrawn for this active newly-created context. Underlying history
identity must remain, but presentation canhideit. Refinedfilter drops history
depth/redo gate for currentlyprovisionalsketch ONLY. Persistedemptyrows remain
visible. Test nowasserts hiddenrow AND retaineddocumenttarget beforeRedo.
Focused5identity tests running exec20688,
/tmp/os3d-empty-items-history-20260910.{log,xcresult}. Final live repeat pending.
Native remainsFrontSketch03 withnewline; cloneFrontSketch2 with2mmline before
unitrun. Neither new line yet gallery-reopened. No finalpublication claim.

## Final refined result so far

Focused revised5/5 identity passed (separate from initial6/6). Exact-build
Right empty entry/Exit and twoEscapes verified; existing hiddenSketch1/MyPart
and visibleFrontSketch2 retained. A rapid repeat clicked outside the now-smaller
origin tile and merelycanceledchooser; excluded, then repeated with inspected
515,420 tile. Valid images final-empty3, final-esc1-valid, final-esc2-valid.
NativeRight emptySketch04 Exit andtwoEscapes retainitems. HiddenSketch02 plus
hiddenBody01 remainhidden duringnewemptyRight entry andafterExit; priorSketch03
andSketch01 visible. Nativehidden-exit inspected.

Final cloneRight first2mmline revealsSketch3; Undo hidesrow AND line; Redo
restoresboth, matchingnativeFrontfirstlinehistory. history-final-draw/undo/redo.
Clonegalleryreopen retainsSketch1hidden/MyParthidden, Sketch2/3visible andboth
lines. history-final-saved.png. Nativegalleryreopen currentlyatLimitedVersion
skip; finalsettledcapture pending. Topisolatednativeemptycase stillopen.
Twohistorydiagnosis images insertedonce after405; finalexportpending.

Native final gallery reopen settled after LimitedVersion Skip; Sketch03/newline
visible, Sketch02/Body01 hidden, Sketch01 visible. No emptySketch04 row.
`/tmp/os3d-qa04-native-final-saved.png` inspected. Four final images inserted
once after two history diagnosis images; exports now requested, expected411
placements (403prior +2initial +2history +4final), master38/newdatednote.

Publication verified: illustrated411 placements, all eight new hashes exactly
once, no predecessor media loss versus403. Master38media/newheadingonce, prior
fieldnote retained and finalpairedreopen wording verified. Exports
`/tmp/os3d-empty-items-publication.docx` and `/tmp/os3d-empty-items-master.docx`.
No runner. Ready to commit the scoped correction, not full QA-04 closure.
