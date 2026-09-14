# Scalar arithmetic retention — September 10, 2026

Baseline58a203a pushed, immutable05be744IPA unchanged. No full acceptance closure.

## Paired live diagnosis

Native1924 reopenedSketch02Top forward20mm line: type10+5,Return→15mm with
on-canvas f(x) marker. Clear/reselect,openlabel→(10 + 5) mm. Native geometry
holdsleft on this reselected edit, outside prior first-size fixscope.
Clone6492 reopenedUntitled2 standalone1mmline: explicitpad1+.5→1.5mm,
no marker, reopenedfield1.5. The source expression is discarded.
All screenshots inspected; /tmp/os3d-formula-native15-commit.png,
native-reselected-editor.png, clone-expression.png, clone15-commit.png,
clone-reopened-value.png (all prefixedos3d-formula-).
Immediate nativeclickaftercommit clearedselection; reselectedbeforeopening.
Immediate cloneselect→badgeclick clearedselection; repeatwithsettledcaptureworked.

## Implementation under regression

SketchDimension optionaldisplayExpression stores constant arithmetic with explicit
inputunits, independent of variable-drivenformula. Legacydecodeoptionalnil.
Firstopen reuses retainedtext; unchangedresubmission preservesformat; plainnumeric
replacement clears it. On-canvas noninteractivef(x) marker leaves measuredlabeltext
and mainhitgeometry unchanged. Arc radius→diameter transforms sourceexpressiontoo.
Existing variableformula behavior unchanged. Constantfunctions withoutvariables
use thissourcepath. Unit conversion still follows explicit/displayunits, anglesdeg.

Initial /tmp/os3d-scalar-expression-20260910.xcresult passed clean 16/16.
After leading-equals normalization/test, final
/tmp/os3d-scalar-expression-final-20260910.xcresult passed clean 15/15.
Live inspection exposed a nearly invisible secondary-color marker in dark app
chrome over the light canvas. Explicit gray corrected it; subsequent build passed.
Updated simulator relaunch/gallery reopen retained `(1+.5) mm` and visible f(x).
Plain 1 clears the marker, Undo restores 1.5 and f(x), Redo restores plain 1.
Native repeated plain 10 clears f(x), Cmd-Z restores 15 and f(x), Redo plain 10.
All states captured and inspected. Different scales remain explicit; exact physical
Pencil equivalence is not inferred. Unit-change roundtrip remains automated-only.
Diagnosis publication verified 310 placements, all four new hashes once, no
predecessor loss in /tmp/os3d-formula-diagnosis-publication.docx.
Post-fix publication and commit pending; no runner active. Local evidence at reports/
openshape3d-core-sketch-milestone-2026-09-08/scalar-expression/SHA256SUMS.

Prior line-anchor58a203a clean33/33 and pairedhorizontalfirstsizes/history/reopen
publishedillustrated306/master38. Verticalnativecreationattempts remaininconclusive;
points/no verifiedline from GUIroute; synthOnly localroute also noresult. No app
failure inferred. Reselection/freeangle/connected sizing remainsopen.

## Final regression checkpoint

Project import now retains displayExpression while remapping dimension refs.
Import-inclusive final run `/tmp/os3d-scalar-expression-complete-20260910.xcresult`
passed clean 31/31 (16 ProjectMerge, 10 keypad, 4 arc-sweep, 1 scalar UI).
No runner remains. Earlier 16/16 and 15/15 runs remain separate, not summed.
The final import-only followup does not alter the live-verified marker or editing
path. Named-variable formulas and broader rotated-marker appearance remain outside
this paired constant-line sample. Physical input and full QA33/40 closure remain open.

Publication verified: illustrated 314 placements; all four post-fix hashes once,
no predecessor loss (`/tmp/os3d-formula-final-publication.docx`). Master retains
38 placements, prior anchor note and one scalar checkpoint, no media loss
(`/tmp/os3d-formula-master.docx`). Original audit and stalled tabs preserved.
