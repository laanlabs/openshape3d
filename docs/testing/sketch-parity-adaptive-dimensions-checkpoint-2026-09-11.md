# QA-27 — Adaptive linear dimensions checkpoint

Evidence date: September 11, 2026. Baseline `89bb2f0`.

## Confirmed gap and implementation

A selected sloped line previously exposed only its absolute length. The
Dimension action now offers Absolute, Horizontal and Vertical measurements for
a genuinely sloped single-line selection. Axis-aligned lines retain the direct,
unambiguous Absolute action. The chosen kind is used for measurement, stored
dimension lookup, editing and persistence rather than merely changing label
text.

The 3-4-5 model recipe verifies 50 mm absolute, 30 mm horizontal and 40 mm
vertical dimensions independently. Each commit leaves geometry unchanged,
survives JSON round-trip, is removed by Undo and restored by Redo. The UI recipe
verifies all three choices, a fresh first-digit replacement session, a 1 mm
horizontal commit, Undo to an undriven measurement, and Redo restoration.

## Regression history

- Model recipe: clean 1/1 at
  `/tmp/os3d-qa27-dimension-kinds-20260911.xcresult`.
- Initial UI run failed because the test's `Horizontal` title matched both the
  adaptive menu and constraint rail. Unique accessibility identifiers corrected
  the fixture; the corrected menu run passed 1/1 at
  `/tmp/os3d-qa27-dimension-menu-ui-corrected-20260911.xcresult`.
- The first 18-case combined run passed all 17 model cases but expected Undo to
  hide the selected line's candidate. The second expected the horizontal seed,
  while the app correctly returned to the default absolute undriven candidate.
  Both assertion failures are retained.
- Final current-tree serial result is clean 18/18, zero failures/skips, at
  `/tmp/os3d-qa27-dimension-final2-20260911.xcresult`.

## Boundary

Fresh paired live comparison and screenshot publication are still blocked by
the simulator input-delivery failure. Repository reference material establishes
the adaptive-dimension requirement, but no new native sloped-line menu capture
is claimed here. QA-27 remains partial; inventory stays 13 passed / 0 failed /
1 device-blocked / 42 incomplete. The immutable `05be744` IPA is unchanged.


## September 11 18:29 — paired badge diagnosis and WIP correction

Baseline `8748e29`. Native input/capture recovered with the existing GUI bridge.
Select a standalone line, hover its value, then click the small leading Distance
Type badge: Absolute/Horizontal/Vertical appear. The same line showed
35462.0578/21277.236/28369.6453 mm with unchanged endpoints. Undo of Vertical
restored Horizontal after reselection; Redo restored Vertical. Gallery reopen
and Items→Sketch06 retained Vertical. This is a large-scale live sample, not
an exact 30/40/50 mm sample.

Clone pre-fix: separate Untitled2, front sketch, 3.0974 mm sloped line. Its
Constrain→Dimension menu exposes all three choices, but Horizontal immediately
opens a keypad (1.859 seed); Escape returns the readout to Absolute. This is a
confirmed display-switch/access gap, not a missing projection calculation.

WIP correction adds a label-adjacent chooser for an undriven standalone line,
undoable serialized presentation metadata, and projected CAD leaders; it does
not create drivers or open a keypad. Toolbar editing remains available. Scope
does not claim driven-dimension switching or native selection-cleanup parity.
Metadata is remapped on import and handled by contextual trim/delete commands.

Focused three-case model/UI gate is running serially at
`/tmp/os3d-qa27-badge-focused-20260911.xcresult` (matching `.log`). No pass claimed
for this source tree yet. Prior18/18 covers the prior toolbar implementation only.
New tests cover no driver/geometry mutation, history, JSON/legacy decode,
trim/delete restoration, and the actual label menu. New source is not live-verified.

Durable inspected PNG/JSON pairs and hashes:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/adaptive-dimensions/qa27-live-2026-09-11/manifest.json`.
New diagnosis evidence is queued for Google Docs; no insertion claimed. Inventory
remains22/0/1/33; QA27 partial. Immutable05be744 and physical iPad unchanged.

### 18:35 focused correction

WIP `21c27ea` was pushed during the first run. That run ended 2/3: both model
checks passed, UI changed H/V without a keypad but failed after Undo/reselection.
Inspection showed Undo retained selection, unlike native, so reselect toggled
it off. A dedicated SetLineDimensionKindCommand now scopes native-style history
selection cleanup; the UI assertion is unchanged. The geometry-only legacy Trim
initializer no longer mutates presentation metadata it cannot restore. Import
remapping has an explicit independent-identity assertion.

Corrected focused run: clean4/4, zero failed/skipped, at
`/tmp/os3d-qa27-badge-focused2-20260911.xcresult`; summary JSON alongside it.
The complete annotation/layout/Trim/import and old/new dimension UI gate is
running at `/tmp/os3d-qa27-badge-final-20260911.xcresult` (matching `.log`).
No combined pass or changed-build live proof is claimed yet.

## Verified changed-build and publication checkpoint

Revision `bbbfd2b`: final combined gate clean **53/53**, zero failures/skips, at
`/tmp/os3d-qa27-badge-final-20260911.xcresult`; terminal summary retained locally.
Changed-build live label menu switches Absolute3.0974 / Horizontal1.859 /
Vertical2.4771mm without keypad or endpoint movement. Undo/Redo clear selection
and restore expected projection after reselection. Gallery reopen retains
Vertical2.4771mm. Native reference menu, projections, history and saved reopen
are also inspected; different scales are explicit, not exact30/40/50 live proof.

Illustrated export:813 unique media, ten new source hashes exactly once, zero
loss from803 predecessor. Master:38 media, one dated QA27 note, zero media loss.
Before/after exports and publication verification JSON are in the durable
QA27 directory above. No duplicate evidence insertion. QA27 remains partial,
inventory22/0/1/33. Immediate type-choice deselection still differs from native;
driven switching and exact live30/40/50 remain unverified. Device unchanged.

### Immediate-choice cleanup follow-up

After `7f502db`, the scoped helper also clears selection on the display choice
itself, matching native. Focused model/UI2/2 passed at
`/tmp/os3d-qa27-choice-clear-20260911.xcresult` (zero failures/skips); this is
separate from the earlier53/53, not a new combined pass. Changed-build live
Horizontal1.7593→Vertical2.0361mm clears highlight/readout without keypad or
endpoint changes; deliberate reselection restores Vertical. Inspected PNG/JSON
receipts and `choice-cleanup-manifest.json` are in the same durable directory.
Four-image publication verified: illustrated817 unique media, all four new
source hashes once, zero813 predecessor loss; master38 media, one follow-up
note and zero media loss. Exact live30/40/50 and driven
variants still open; QA27 partial and inventory22/0/1/33 unchanged.

## Exact recipe and driven-state WIP

On native, numeric Vertical40 followed by Horizontal30 and Item→Zoom to
produces the exact same line with H30/V40/Absolute50 readouts. Native still
exposes the badge after numeric sizing (lock icon visible). Clone numericV40
commits but removes the badge, confirming the remaining numeric-driven gap.
PNG/JSON/actions are retained in the durable QA27 directory/exact-recipe.

WIP preserves the one numeric driver's ID/references and changes kind/value to
the current measured projection in place, atomically with presentation metadata.
No geometry movement or new driver; variable-linked/multiple-driver references
remain excluded pending evidence. Focused3-case run is active at
`/tmp/os3d-qa27-driven-focused-20260911.xcresult`; no result or changed-build
live proof claimed yet. Publication of this new exact/driven evidence pending.
