# QA-36 — Constraint types checkpoint

Evidence date: September 11, 2026. Baseline `5d31097`.

## Added finite application matrix

A new model recipe directly applies Horizontal, Vertical, Parallel,
Perpendicular, Coincident, Midpoint, Tangent, Concentric, Equal Length,
Equal Radius and Symmetric constraints to valid selections. Every relation must
enable, be stored, solve within the structural residual tolerance, survive JSON
round-trip, disappear through Undo and return through Redo.

The first attempt was compile-only because the test referenced the view model's
nested point-selection type without qualification. No test ran. The corrected
target passed 1/1 at
`/tmp/os3d-qa36-constraint-types-compiled-20260911.xcresult`.

## Final regression

The final one-owner gate passed clean 64/64, zero failures/skips, at
`/tmp/os3d-qa36-constraint-types-final-20260911.xcresult`:

- 28 `ConstraintApplyTests`, including the 11-relation matrix;
- 28 `AutoConstraintEngineTests`;
- 6 `ConstraintPolishTests`;
- 2 portrait/landscape `ConstraintRailUITests`.

This covers explicit application, adaptive availability, inference gates,
over-constraint refusal, deletion/history, serialization and visible rail entry.

## Boundary

Retained paired evidence covers H/V, point Lock, Parallel, tangent and concentric
workflows, but current paired live evidence is incomplete for Equal Length,
Equal Radius, Symmetric and a fresh exact-build sweep of every relation. The
simulator input-delivery blocker prevents that repeat. QA-36 remains partial;
inventory stays 15 passed / 0 failed / 1 device-blocked / 40 incomplete.
Immutable `05be744` IPA unchanged.


## Equal Length direction correction in progress — September 11 evening

Fresh native Sketch11 Front: unequal nonparallel lines759.3439/657.4091mm,
Auto-constrainingOFF and Last Selected inspected. Box selection and Equal
shortened the upper to657.4091mm, left the lower unchanged, preserved directions,
and showed Equal badges. Undo restored the upper and Redo restored Equal.

Clone fresh Untitled2 Front: raw separate lines3.0996/2.6502mm, acquisitionOFF,
HintsON, Auto-ConstrainOFF, Last Selected inspected. Equal made lengths equal
but rotated the free lower line from10.79° to28.90°. The explicit selection order
differs from native's box route; this is not anchor-order evidence. The confirmed
issue under investigation is unnecessary direction drift during free-line sizing.
`testEqualLengthPreservesFreeLineDirectionsAndHistory` reproduced that drift on
unchanged source: 0/1 passed (two direction assertions), zero skipped, receipt
`/tmp/os3d-qa36-equal-direction-before-20260911.xcresult`.

A narrow explicit-Equal correction reuses transient line-direction preservation
from numeric sizing for the non-anchored ordinary line. If saved relationships
conflict, retry without direction preference, then use the existing anchor
fallback. No angle or Lock is added to the saved sketch. Focused three-case gate
is running; no success is claimed yet. Added saved-point-constraint override
coverage, both anchor preferences, exact history and JSON persistence.

PNG/JSON/logs/summary and hashes are durable under workspace
`reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-equal-live-2026-09-11`.
Changed-build live verification, broader regression, gallery reopen and report
publication remain pending. QA36partial; inventory26/0/1/29, reports863/38.
No current device install or immutableIPA change.

Focused corrected gate completed clean **3/3**, zero failures/skips, at
`/tmp/os3d-qa36-equal-direction-fixed-20260911.xcresult`. The prior failed0/1
receipt remains retained. No runner. This is a WIP source checkpoint: broader
constraint/sizing regression and changed-build paired live remain pending.

Final combined gate on `696e8cd` passed **90/90**, zero failures/skips, at
`/tmp/os3d-qa36-equal-final-20260911.xcresult`: 88 model/integration checks
(ConstraintApply, AutoConstraintEngine, ConstraintPolish, LiveDimension) and
both portrait/landscape ConstraintRail UI workflows. No runner remains.
Changed-build live recreation started afterward; no live-fix claim yet.

### Changed-build live follow-through on 696e8cd

The clone retained the 10.79-degree angle after Equal, with lower length
3.0996 mm. Undo restored 2.6502 mm and removed Equal; Redo restored
3.0996 mm and Equal. Gallery reopening followed by the Sketch 1 Items icon
re-entered the saved sketch and displayed exact 3.0996 mm with Equal intact.
The name field briefly opened its rename keyboard; no name or geometry was
changed. Return dismissed it. General Line had opened a new-plane picker; that
was cancelled, not counted as reopening.

Native Recents reopened the same project. Sketch 11 selection showed two edges
and total length 1314.8183 mm. Normal to Sketch and Items > Zoom to exposed
both Equal glyphs; selecting the lower line displayed 657.4091 mm. Native and
clone scales/order differ; no First/Last ordering claim is made.

Ten distinct evidence images submitted to illustrated report under
`QA-36 Equal direction correction — September 11, 2026`; exported publication
verification pending. QA36 remains partial; inventory26/0/1/29 unchanged.

### Equal publication verified

Illustrated export873 unique media: ten source hashes each exactly once, one
heading/verdict, and zero predecessor loss from863. Master export38 media, one
dated note, zero predecessor loss. Durable `illustrated-verification.json` and
`master-verification.json` accompany the source images and exported DOCX files
in `constraint-types/qa36-equal-live-2026-09-11`. Equal fix is implemented,
regression-tested, paired-live verified and documented; not device-tested.
QA36 remains partial for the remaining relation matrix. Inventory26/0/1/29.

## Equal Radius paired checkpoint — September 11 late evening

Source696e8cd/documentation2940020 unchanged. Native Sketch11 circles R43/R65mm:
More > Equal reduces larger toR43 with both centers fixed. Equal badges, Undo
restoration, Redo and exact gallery reopening atR43 verified. Clone Sketch1
circles diameter0.9925/1.4887mm: smaller selected first under First Selected;
More > Equal Radius reduces larger to0.9925 with centers fixed. Undo1.4887,
Redo0.9925 and exact saved-sketch reopening with relation verified.

No new product change or test run: reuse the clean90/90 current-source gate,
including the 11-relation application/JSON/history matrix. Different scales,
radius/diameter preferences and selection conventions are explicit; no pixel
layout or First/Last order parity claim. This closes only the bounded two-circle
Equal Radius workflow, not the complete QA36 relation matrix.

Durable evidence: workspace reports milestone/constraint-types/
qa36-radius-live-2026-09-11. Illustrated881 unique images: all8 new sourcehashes
once, heading/verdict once, no predecessor loss from873. Master38 media, one
new note and no predecessor loss. Export/hash receipts retained beside PNG/JSON.
QA36 remains partial; inventory26/0/1/29; iPadunchanged. Next Symmetric native
two-elements then axis-pick versus current clone point-pair-plus-line workflow.


## September 12 — two-circle Symmetry WIP

Native fresh Sketch11: select two circles, invoke Symmetry, then choose a line
in a dedicated axis-pick state. The right center moves from local(850,330) to
(850,300), reflecting left(600,300) across x725; radii R43 and the axis remain
unchanged. Undo restores the prior center and retains/selects the axis. The
pair already had Equal Radius, so this is not an unequal-radius comparison.
Evidence retained in `constraint-types/qa36-symmetry-live-2026-09-11/` under the
durable workspace report. No new publication yet; illustrated881/master38.

Clone previously disabled Symmetric for two circles and accepted only explicit
point+point+line preselection. Added a transient two-circle axis-pick flow,
Cancel/Escape/tool/Exit/history cleanup, no geometry dragging while picking,
atomic commit and whole-circle Symmetric solver lowering. Existing point-form
Symmetric remains supported. Circle whole-form lowering couples reflected
centers and equal radii; fresh native unequal-radius behavior remains pending.

Focused geometry/cancellation/archive run: **2/2**, zero failures/skips.
Broader application/merge/polish run: **61/61**, zero failures/skips, including
conflicting Locks refusing without a history step and pending-drag suppression.
Receipts `/tmp/os3d-qa36-symmetry-{focused,model}-20260912.xcresult`; model summary
and logs copied durable. New delivered axis-pick/cancel UI test is currently
running at `/tmp/os3d-qa36-symmetry-ui-20260912.xcresult` (not yet counted).
Changed-build live/history/reopen and final combined regression still pending.
This is WIP, not QA36 closure; inventory26/0/1/29, iPad/immutableIPA unchanged.


### Symmetry UI diagnosis and focused recovery

Five UI failures retained (initial, top-arc, additive, settled, overlay receipts).
The first four never selected the first circle: new outer hit-testing modifiers
interfered with existing overlay behavior. Conditional view omission only during
axis picking restored ordinary taps. The fifth reached both circles but the
retained center of the last-created circle incorrectly excluded the selection.
Accepting only own-center markers fixes that without accepting unrelated points.
The pending state now also suppresses the rendered sketch ring and routes axis
taps before other gizmo controls. Corrected focused run **4/4**, zero failures/
skips, includes three model checks and menu→Cancel→menu→axis→saved glyph UI.
Full combined rerun pending at os3d-qa36-symmetry-final-20260912.xcresult.
These are fixes to the WIP implementation; no changed-build live parity claim yet.


Final corrected combined Symmetry gate: **64/64**, zero failures/skips,
61 model/integration plus3 real rail UI workflows, one serial run. Summary/log
copied durable; xcresult `/tmp/os3d-qa36-symmetry-final-20260912.xcresult`.
This supersedes only automated status; native/changed-clone live and publication
remain pending. Earlier failures are retained, not counted as clean passes.


## September 12 — changed-build paired Symmetry checkpoint

Source `5a3687e`, final **64/64** one serial run (zero fail/skip). Both apps
complete two-circle selection→Symmetry→axis, preserve first center/axis, reflect
second center, Undo/Redo and gallery reopen. Native R43 pair already had Equal
Radius; clone Ø0.8638/0.8634 becomes Ø0.8638. Native history highlighted the axis
where clone history deselects; settled application/history selection remains an
explicit follow-up, not a claimed match. Independent unequal native radii and
other similar-element types remain unverified. QA36 stays partial.

Illustrated export891 unique media, all ten new source hashes exactly once,
heading/verdict once, no loss from881. Master38 unique media, checkpoint heading
and final verification paragraph once, no predecessor loss. DOCX exports and
verification JSON are retained in the durable Symmetry directory above.
No runner. Inventory26 passed/0 failed/1 device-blocked/29 incomplete. Physical
iPad build/install and immutable05be744 unchanged.


### Native unequal-radius and hover follow-up

Fresh post-reopen Undo/Redo leaves axis/circles deselected. Merely moving the
pointer to the axis reproduces orange highlighting: prior selection concern
was hover, not a confirmed product defect. No source change warranted.
After undoing Symmetry, axis creation and Equal Radius, native R43/R65 circles
were independently constrained by Symmetry alone across a recreated axis.
Right R65 becomes R43 at reflected center, first center/axis remain fixed;
Undo restores R65 and offset center, Redo R43. Only Symmetry badges remain.
This supports whole-circle radius equality independently of Equal Radius.
Source5a3687e and final64/64 reused; no new run. Four native images appended to
illustrated report; export verified895 unique, four hashes once/no891 loss;
master38, one follow-up heading/no loss. Files os3d-sym-follow-* and
os3d-sym-unequal-* preserved in durable Symmetry directory. Remaining other
element/relation sweep keeps QA36 partial. Inventory26/0/1/29, iPad unchanged.


## Two-line Symmetry WIP — September 12

Native two separate sloped lines57.9747/81.9876mm→Symmetry→axis reflects
left endpoints to the right line while preserving right and axis. First broad
box also selected axis endpoint (disabled action); two separate additive boxes
correctly isolate two edges and enable the workflow. Clone two selected lines
kept Symmetric disabled. Evidence os3d-sym-lines-* retained durable.

WIP source `bcc70c1` extends circle axis-picking to two nondegenerate lines.
One saved Symmetric relationship encodes two explicit endpoint pairs sharing
the axis as five references. Closest initial correspondence is persisted, not
rechosen at each solve. Reject an operand as axis; retain cancellation, atomic
history, First/Last anchoring and refusal behavior. Legacy three-ref point and
circle forms remain supported.

Focused model4/4 and separate delivered UI1/1 passed, zero failures/skips.
Added archive/import remapping assertion before final combined gate (application,
merge, polish, Trim, four rail UI workflows), currently running at
/tmp/os3d-qa36-line-sym-final-20260912.xcresult. No final result claimed.
Changed-build line live/history/reopen/publication pending. Reports895/master38
unchanged; QA36partial; inventory26/0/1/29; physical iPad unchanged.


Final two-line combined gate **76/76**, zero fail/skip in one serial run:
38application +18merge +6polish +10Trim +4rail UI. Sourcebcc70c1 plus
line UI/import tests; receipt /tmp/os3d-qa36-line-sym-final-20260912.xcresult,
log/summary copied durable. No runner. Changed-build live remains next.
