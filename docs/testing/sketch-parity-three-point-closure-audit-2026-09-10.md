# QA-10 finite closure audit — September 10, 2026

Product revision: `5014cef`, pushed to PR #29. Final relevant serial regression:
`/tmp/os3d-qa10-direction-final-20260910.xcresult` — **36 passed, 0 failed,
0 skipped** (29 RectangleConstruction, 3 RectangleInputCancellation, 4
three-point RectangleWorkflow UI checks). This is not a new whole-project gate.

## Original criterion

“Rotated baseline, perpendicular height, cancel at each stage.” The finite
recipe is distinct from every possible desktop/iPad input, arbitrary constraint
network, import route, and pixel/layout permutation. Detailed prior attempts,
withdrawn interpretations and fixes remain in the [matrix receipt](sketch-parity-three-point-matrix-2026-09-10.md).

| Criterion | Paired evidence | Qualification |
|---|---|---|
| Rotated baseline | Earlier September 10 reverse slope 780,230→620,190; final forward 900,740→1050,710 and reverse 1050,710→900,740; matching clone slopes/directions | Different native/clone units per screen distance and snap acquisition; not identical physical-input scales |
| Perpendicular height, either side | Native forward/reverse 20.4084×9; clone 1.8895×0.7957 / 1.8895×0.797. Completed dual leaders and center control visible, no auto-keypad | Wrong initial clone Diagonal subtype was undone and excluded |
| First-point cancellation | Native first click then supported pointer move exposes uncommitted 8.3239 mm baseline preview; Escape removes it, preserves geometry and leaves Rectangle armed. Clone first-point/Escape same state transition | Native click-only screenshot was inconclusive until settled hover; premature capture excluded |
| Released-baseline cancellation | Earlier native reversed-baseline first Escape removes draft, second disarms; corrected clone matches. Later forward draft Escape preserves completed reverse rectangle | Concrete missing Escape registration fixed; historical delivery-only suspicion corrected, not erased |
| Idle second Escape | Native final first-point sequence second Escape disarms; clone earlier verified second Escape disarms without exiting sketch | Physical keyboard/Pencil not inferred |
| Pending numeric value | Paired keyboard entry, Return preserving first endpoint, completion; direct pending-label click is a third-point placement, not a keypad action | Prior direct-interactivity assumption withdrawn. Clone simulator cmd-Z delivery did not act in the final horizontal attempt; toolbar worked |
| Pending visual state | Orange baseline, outlined value, four-decimal precision, fixed screen-space leader distance, readable-side value for forward/reverse horizontal and sloped baselines | Earlier universal “outside geometry” rule withdrawn; only forward evidence supported it |
| Completed controls, sizes and history | Fresh center release/Lock/Unlock/move, numeric height/baseline/reselection, isolated legacy identity recovery, and exact geometry history retained in detailed receipts | Legacy fixture used production archive APIs, not a passing system-picker test |
| Persistence | Fresh center/control and legacy saved recovery; final horizontal reverse native23.4062×6 and clone2.4891 baseline reopen | Not a claim about arbitrary downstream graphs or external imports |

## Regression history

The final36/36 is one clean combined run at5014cef. Earlier precision4/4,
readable-side5/5, legacy54/54 and other documented runs remain separate results.
Compile-only fixture failure and earlier over-lock/presentation failures are
retained in their original receipts; no failed run is relabeled clean.

## Publication and closure gate

Illustrated687/master38 plus final gallery-reopen note already export-verified.
Angled supplement695 verified all8 new hashes exactly once, no predecessor
placement loss and preserved prior text order. Last five first-point screenshots
inserted once; **final700 verification pending at audit creation**. Do not
promote the matrix row until that export and dated master closure note verify.

## Explicitly outside this finite closure

- Physical touch/Pencil, actual-device layout and input remain QA-52 blocked.
- General keyboard focus/delivery remains QA-54 partial.
- General layout/handedness/zoom/manual-placement permutations remain QA-53.
- System file-picker import was not validated by the controlled legacy fixture;
  preserve that follow-up with broader persistence/import work.
- Higher-degree center constraints, branched legacy-group recovery, and arbitrary
  constraint networks are not generalized from the isolated-rectangle result.
- The immutable05be744 IPA is unchanged and does not contain later corrections.

Next finite acceptance case: QA-11 concentric-circle initiation, reconciling its
already-sampled live result with the original recipe and current presentation.

## Final closure verification

Illustrated700 verified all5 final hashes once, no695placement loss, preserved text order. Dated closure note appears once in final illustrated700/master38 exports. QA10 original finite recipe PASSED at5014cef. Inventory7passed/0failed/1deviceblocked/48incomplete (37partial11deferred), total56. Earlier pending-publication statement above is superseded by this verification only.
