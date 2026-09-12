# QA-36 free-target Midpoint anchoring — September 12, 2026

Status: source e177ce1 implemented, final106/106 clean, changed-build paired mode/history and Last-mode reopening verified. QA36 remains partial; inventory26/0/1/29. iPad/immutable05be744 unchanged.

## Paired diagnosis

Native Auto-Constrain off, source endpoint selected first, target line second via Shift box. Last Selected changes target500600→600600 (38419.426mm) to400600→600600 (76838.8519mm), and source500500→500570 to500500→500600. Undo restores the original. First Selected visibly confirmed on the same restored fixture instead preserves target and translates source to550530→550600, preserving its original26893.5852mm length. Both mixed operands and enabled Midpoint were captured before applying. Earlier one-operand attempts are not behavior evidence.

Clone matched acquisition/Auto-Constrain off, Last Selected verified. Source350200→350270 (0.8737mm), target350300→450300 (1.2444mm). Last Selected stretches source diagonally to400300, keeping target; First Selected instead translates target to300270→400270 while retaining source. Both differ from native.

## Scoped correction

Point-first/line-second endpoint Midpoint now supplies native-observed placement preferences to the existing solvePointTransform projection, built from original saved constraints. First mode translates source to target midpoint. Last mode intersects source/target directions and reshapes target about its far endpoint. No stored constraints/dimensions/schema are added beyond Midpoint. Reverse order, parallel/degenerate directions, non-line points and other relations retain existing behavior. Saved Locks/drivers remain authoritative, not rewritten to match preferred geometry.

## Verification

- Initial new test invocation: compilation failed on inferred SIMD2<Int>; corrected explicit Double before any assertion ran.
- Corrected before-source:0/1, six endpoint assertions fail, history/archive assertions pass.
- Changed focused:2/2 clean, zero failures/skips (native two-mode endpoint matrix and existing cleanup/history/refusal).
- Locked-target/driving-source-length1/1 passed.
- Final combined106/106 on e177ce1, zero failures/skips (99model/integration+7UI), no runner. Changed live/publication verified below.

Logs/xcresults under /tmp/os3d-qa36-mid-anchor-{before,before2,focused,locked}-20260912. Durable captures: /Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-midpoint-anchor-live-2026-09-12. Reports remain1078/master38; no new publication claimed.

## Changed-build paired verification and publication

Both anchor modes now match the observed native geometry. Clone First mode
translates source350200→350270 to400230→400300, retaining target350300→450300;
Undo/Redo restore both states. Last mode extends target250300→450300 and source
350200→350300. Its readout2.4887mm survives Undo/Redo and gallery reopening.
Native First history is verified; Last reapplication/history and gallery reopen
retain target76838.8519mm at the new fitted view545567→712567 with midpoint628567.
Clone saved JSON retains the Midpoint record and unrelated Parallel, dimensions0.
An initial changed-build selection attempt selected two whole edges; disabled
Midpoint prevented application. Settled blank then endpoint-only selection
resolved the fixture. No source change after final106.

Illustrated export1089 unique media: all11 new source hashes exactly once,
heading once, no1078 predecessor loss. Master38 unique, heading once/no loss.
publication-assets.json, publication-verification.json and before/after DOCX
exports are preserved beside screenshots and clone-reopened-sketch.json.
First-mode gallery reopen is not separately claimed; both modes have paired
live history, and Last-mode reopening is verified in both apps.
