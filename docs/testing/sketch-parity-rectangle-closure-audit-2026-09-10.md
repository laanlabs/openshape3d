# QA-08 / QA-09 finite closure audit — September 10

Baseline `ffe2e59` (product `a24ef1b`); current publication 598 illustrated
placements / master 38, verified anonymously with predecessor retention.
This audit does not promote either case or erase broader visual/input gates.
Current inventory: 4 passed, 0 failed, 1 device-blocked, 51 incomplete.

## Evidence reconciliation

| Criterion | Paired evidence | Remaining qualification |
|---|---|---|
| Diagonal four quadrants / default leaders | Sept8 diagonal-anchor receipt plus Sept10 diagonal-matrix: mixed down-left and up-right; corrected leader mapping | No exact device-scale equivalence claimed |
| Diagonal both size orders / anchor | Down-left width then height preserves normalized lower-left; up-right height then width preserves lower-left | Initial first-corner interpretation withdrawn |
| Diagonal history / persistence | Width Undo/Redo and final native15.5×9.5 / clone1×0.75 reopen | Excluded misdirected clicks retained |
| Rectangle center controls / Lock / markers | Center translation, scoped direct Lock, four hollow corners, halo and supporting-line colors in diagonal-matrix | Unsupported derived-center relations are outside the Lock result |
| Center both sizing orders | Prior height-first; Sept8 reverse width-first; Sept10 right-up and up-left sequential sizing | Literal versus arithmetic input methods distinguished |
| Center four release directions | Sept10 corrected center leaders: below/right, above/left, above/right, below/left | Initial wrong-expectation run explicitly superseded |
| Center precision / no-op accept | Saved0.4345 residual diagnosis, four-decimal readouts, unchanged accept skips Undo pollution | Native all-items numeric motion excluded from anchor evidence |
| Center Lock with free rotation / corner constraints | Migration, retained sizes/refs, corner rotation, explicit conflict refusal, history and reopen | Refused values retain selection and do not create phantom history |
| Migrated selected-side/corner annotations | Adjacent corner leaders, selected outline, hollow markers, three single-side readouts, preserved editor side | Distinct from unmigrated axis rectangle's sampled two-readout state |
| Migrated successful side edit / history | Fresh native8↔9 and clone2↔3 clear selected edge/handle, retain parallel readouts; final reopen9×4/3×0.5 | Does not establish the analogous axis-primitive lifecycle |
| Publication | Historical sign-out queue now represented through598; failed runs, interim UI, replaced fixtures and capture qualifications retained | Full attempts remain local, representative screenshot sets published |

## Concrete next visual check before closure

The Sept8 axis center-width-first receipt explicitly records native clearing
selection/readouts after commit while clone kept both badges. The latest
successful-commit correction is scoped to **migrated four-line rectangles**,
not axis primitives. Do not silently transfer that fix or close QA08/09 from
geometry alone. After the consolidated runner completes, compare a fresh axis
rectangle selected side → numeric commit → Undo/Redo → blank/reselect in both
apps, including which values/handles remain visible. Fix a current confirmed
difference and repeat; preserve cancellation/refusal semantics.

## Consolidated regression in progress

`/tmp/os3d-qa0809-consolidated-20260910.xcresult` and `.log`, serial exec64632.
RectangleConstructionTests, SketchAnnotationVisibilityTests,
DimensionKeypadCommitTests, NumericKeypadTextTests, RectangleWorkflowUITests.
No simultaneous desktop interactions. Actual result/counts pending; no test
pass inferred from process presence. UI tests replace the clone's live fixture.

Immutable signed05be744 IPA remains unchanged; no physical installation/input
claim. Current regression is not a replacement whole-project final gate.


### Additional coverage qualification found during review

`testRightSideHeightKeypadIsReachableAndReplacesSeed` chooses the minimum-X
badge for a down-right center rectangle. The corrected default layout puts its
height on the right, so that old targeting heuristic may exercise width instead.
Do not call its passing count proof of right-side height. After the active run,
correct this fixture to target the known rightmost height and assert the other
size stays unchanged. Preserve the original run and rerun relevant changed
checks; no concurrent file/test mutation while the suite is using it.


Consolidated run finished clean78/78, zero failures/skips (516.732s wall span),
including16 UI workflows. Preserve the right-height targeting qualification:
its old pass was not height-specific evidence. Corrected fixture now selects
rightmost badge for the known down-right release and checks actual height
change, unchanged width and fixed center. Targetedexec81256 active:
`/tmp/os3d-qa0809-height-target-20260910.xcresult` and.log. No productchange.


Corrected right-height target passed1/1 (31.538s); no runner left. Live native
axis diagonal right side9.5→8 clearsedge/handle andkeepsoneheightreadout;
Undo9.5/Redo8 sameunselectedstate. InitialallItems clickopenedoverlapping
0.4345dimension, Escape dismissed withnoedit; firstimmediateedgeclickdidnot
clearallItems, settledsecondclick isolatedrightedge. Theseattempts retained.
Clone reopenedheightUIcenterrectangle1.5175×1.5, selectedright→height1 retained
orangeedge/handle andwidthbadge. Confirmedgap, independentofprior migratedfix.

Correction nowclearsentityselection onlyafter successful explicitlyselected
axis-side h/v commit; retains selectedDimensionID andsidepresentation (no
newdimension). Cancel/refusal unchanged. New allfour-side unitchecks readout
count/refs/leader endpoints/exactgeometryUndoRedo/blankclear. Serialexec8390:
`/tmp/os3d-qa0809-axis-lifecycle-20260910.xcresult`, annotation+construction+
correctedheight and reversediagonalUI. Livepostfix pending. Screenshots
`os3d-qa0809-axis-*` retained/hashed, notyetpublished.

Initialaxis run41passed/1failed (six assertions in newfour-side test), notclean.
Entityselectionobserver clearedselectedAxisRectangleEdge, so aftercommit the
remaining readoutjumped todefaultside. Restoringonlypresentationpick after
clearingentityselection fixes that rootcause; nohandle/entityrestoration.
Same42casesrerunexec8160 at `/tmp/os3d-qa0809-axis-lifecycle-final-20260910.xcresult`.
Two diagnosisimages insertedonce; exportaxis-diagnosis.docx awaitinghashcheck.

### Axis lifecycle final rerun and opposite-side qualification

The identical corrected set passed clean 42/42 in
`/tmp/os3d-qa0809-axis-lifecycle-final-20260910.xcresult`; initial 41/1 remains
recorded above. No runner remains. Live clone right-side commit 1.5→1, Undo→1.5
and Redo→1 clear the selected edge/handle and retain the right edited readout.
Left-side open/Escape preserves selection; committing 1→2 clears selection and
retains the left readout, with the center unchanged. Screenshots `axis-fixed-*`.

A subsequent native opposite-side sample QUALIFIES the earlier single-readout
generalization: selecting the left side of the same lower axis-shaped rectangle
shows top and bottom width readouts; committing left height 8→7 then leaves BOTH
left and right 7 mm readouts. Clone exposes only upper width while selected and
one edited height after commit. Captures `axis-native-left*` and
`axis-fixed-left*` are copied and hashed in center-matrix. Native geometry may
carry separate opposite-edge dimension state from successive edits; do not
blindly extend migrated aliases or declare blanket axis parity. Next isolate
fresh native/clone opposite-side edits and determine dimension-history dependence.
Current native lower shape is 15.5×7; clone center shape 1.5175×2. Paired final
reopen/publication and product commit remain pending. Illustrated diagnosis
600 placements verified; these new post-fix captures are LOCAL ONLY.

### Fresh-native qualification, reopen and publication

Fresh native Center rectangle (10×6) selected left shows two readouts; first
height 6→4 commit clears edge and leaves only left height. Opposite right
selection shows two readouts (its height text overlaps native constraint rail).
This differs from the previously dimensioned 15.5×7 shape and confirms the
extra-readout rule must be investigated with saved dimension state, not applied
to every axis-shaped rectangle. Native `press r` was an unsupported Peekaboo
key; `hotkey --keys r` correctly armed Rectangle after reentering the sketch.
No erroneous key attempt is counted as app failure.

Paired gallery reopen inspected: native lower 15.5×7 and fresh height4 retained;
clone 1.5175×2 retained with selected-left readouts. Native all-Items selection
is persistence evidence only. Native trial prompt was skipped without purchase;
one immediate post-modal selection did not act and was repeated after settling.
All axis screenshots copied and hashed in center-matrix.

Publication export `/tmp/os3d-qa0809-axis-fixed-published.docx`: 608 placements,
all eight new correction/caveat/reopen hashes exactly once, zero predecessor
image loss and all prior text retained in order. Master export
`/tmp/os3d-qa0809-axis-fixed-master.docx`: 38 placements, dated note once, no
predecessor image/text loss. Prior diagnosis 600 remains included.
QA08/09 remain partial for the dimension-history-dependent opposite-side
readout case; no change to inventory or immutable IPA.

### Selection-relative adjacent side diagnosis

On the fresh native Center10×4 fixture, selected right exposes bottom width;
width10→9 committed there. Subsequent left selection exposes top and saved
bottom9; selected top exposes saved left4 and adjacent right4. This reproduces
the extra-label pattern without the older dense shape's edit history. Clone
selected right instead exposes upper width, inherited from creation direction.
`axis-history-native-right`, `native-width-editor/commit`, `native-left-after-width`,
`native-top` and `clone-right` are local hashed diagnosis evidence.

First correction is narrowly selection-relative adjacent placement: selected
axis side uses its preceding counter-clockwise edge for the other size. Four-side
world endpoint assertions added to the existing history test. Serial exec29238
`/tmp/os3d-qa0809-axis-adjacent-20260910.log`/.xcresult owns simulator, running
AnnotationVisibility + RectangleConstruction + right-height UI. Saved dimension
presentation-side persistence/duplicate alias behavior remains a distinct next
fix, not implemented by this placement change. Baseline0067ea4 pushed.

Adjacent placement run29238 passed clean41/41. Live clone selected-right width
now below, typed1 commits below, selected-left adjacent width moves above.
Native corresponding bottom9 persists alongside top9; clone lost bottom1.
New optional `SketchDimension.rectangleLabelEdges` records committed axis
annotation sides; aliases share same saved dimension/refs and never add solver
equations. Nil legacy dimensions retain defaults. Project merge preserves the
metadata. New regression checks alias IDs/refs, one equation, cancel, commit,
exact Undo/Redo and Codable roundtrip. Serial53489 saved-side run active; no
postfix claim for this metadata change. New adjacent-fixed evidence copied/hashed.

Saved-side initial run passed59/59; strengthened absent-key legacy decoding and
project insertion passed1/1 separately. Live clone bottom1 plus adjacenttop1
now matches native bottom9/top9. Top edit clone1→2 and native9→8 both leave
two widths with no selection. HOWEVER native Undo returns to one bottom9
readout; clone Undo showed top1 and bottom1. Exact metadata undo already passed,
but stale selected-side presentation overrode restored saved side. Final fix
uses stored-side placement whenever no entity side is selected; new explicit
Undo label-count/edge assertion added. Final combined run exec2900
`/tmp/os3d-qa0809-axis-saved-sides-final-20260910.log`/.xcresult now active.
Native remains at Undo9×4 (Redo not yet performed); no desktop while UI tests
run. `saved-side-*` screenshots copied/hashed, interim not final evidence.

### Final saved-side result and publication

Final combined59/59 passed in `/tmp/os3d-qa0809-axis-saved-sides-final-20260910.xcresult`
including the strengthened legacy/insertion and Undo-side checks (no failures
or skips). Live corrected clone Undo2→1 leaves only bottom1; Redo1→2 restores
both. Native Undo8→9 leaves bottom9 and Redo9→8 restores both. Final gallery
reopen retains clone2×1.5 with top/bottom width plus selected-left height and
native8×4 with both widths. Native all-Items image is persistence-only.
Latest `sides-final-*` PNGs copied/hashed. Initial live stale-alias failure is
retained above, not hidden by earlier automated passes.

Illustrated `/tmp/os3d-qa0809-saved-sides-published.docx` verified616 placements,
all8 new hashes exactly once, no predecessor image or ordered-text loss,
heading once. Master `/tmp/os3d-qa0809-saved-sides-master.docx`38 placements,
new dated note once, no predecessor loss. Legacy dimensions cannot recover
unknown historical annotation sides; nil preserves defaults until subsequent
edits record a side. No extra equations or reference changes.

Next confirmed visible issue: Move/Rotate chip overlays lower-right keypad
area in `sides-final-first-editor`; native editor has no such chip. Upper
commit was reachable but overlap is not a parity pass. Hide unrelated sketch
transform chips while a dimension editor is active; test restoration on cancel.
QA08/09 remain partial; inventory unchanged.
