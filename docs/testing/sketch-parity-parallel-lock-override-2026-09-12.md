# QA37 Parallel whole-Lock override — September 12, 2026

Baseline sourcefb5d9a5/checkpoint4312d4d. Native First Selected, free lower first,
whole-Locked upper second: preserves upper, lower first endpoint and100743.02mm
length. Upper943580→1039560; lower943627→1039650 rotates end to~1040608.
Setup reused prior pair after Delete Constraints and lower-endpoint drag;
fresh Line attempts were inconclusive, excluded. Whole Lock verified by green
endpoints and Unlock rail; clean two-edge pair verified before apply. An initial
one-edge selection miss was corrected, not counted.

Clone fresh lower200280→300300 / upper200230→300210, upperwholeLock. First
free lower then locked upper: upper remains exact, lower length1.26971836→
0.40161145mm, first endpoint displacement0.45624786mm. PNG/JSON durable under
constraint-types/qa37-anchor-live-2026-09-12 in the September8 milestone reports.

Strengthened existing selection-order/Lock test fails0/1 with2geometryassertions
(start moves1.248603; length10→10.2956475). Lock and history still pass. The
fixture's length increases instead of shortening; both violate native length
and first-endpoint preservation. No assertion relaxed.

Scoped source correction makes an explicit whole-Locked operand the actual
Parallel placement anchor before projecting. Existing point-lock/driving-length
projection/fallback unchanged. Focused7/7 clean; expanded First/Last x both orders Lock matrix1/1 clean
(four Lock cells plus four free-anchor/repeated-stability cells). Final148/148 clean on1cb2c54, zero failures/skips. Changed live passed; publication pending. No acceptance promotion, inventory30/0/1/25. Reports1194/
master38. iPad/immutable05be744 unchanged.

## Changed live on1cb2c54

Fresh clone upperwholeLock, freelower first/lockedupper second: free length
1.269718362753064→1.269718362753045, firstendpointdelta3.78e-14mm; locked
upper exact. Apply deselects. Saved Undo, Redo and gallery reopen exactly match
respective snapshots; Lock retained after Undo. Native Undo/Redo and gallery reopen also passed; reopened free length100743.02mm and locked upper retained. Reopen initially displayed a trial modal; dismissed through Skip, no purchase. Final geometry/value screenshots inspected.

## Last Selected reverse-order completion

Native Last Selected confirmed in UI; upper first (99911.5848mm), lower second
(100743.02mm): Parallel preserves lower and upper first endpoint, rotates upper
to its direction and deselects. Changed clone fresh upper200650→300670 first,
lower200700→300680 second: lower exact, upper length1.2621869301751034→
1.2621869301750852, first endpoint delta3.67e-14. Apply/Undo/Redo visually
verified and gallery reopen JSON exactly equals applied snapshot. Immediate
autosave reads during Undo/Redo lagged one step (retained); they are not counted
as terminal history states. Existing whole-Lock pair, polygon and ellipse retained
with only ~1e-13 solver roundoff on the previously free line. A first second-tap
opened the overlapping dimension keypad; corrected lower-left edge tap obtained
the intended two-line selection. No product change for this input setup.

## Publication and finite closure

Illustrated1208 unique, fourteen listed hashes once, heading once and no1194
predecessor loss; master38, one note, no loss. Verification and XML extracts
retained in qa37-anchor-live-2026-09-12/lock-closure. Disk filled while making a
redundant baseline copy; only that incomplete new copy removed. Intact original
baseline reused, new export verified in memory, hashes/XML retained instead of
a second full DOCX. All source screenshots remain local. QA37 finite pass;
inventory31/0/1/24. No runner or source change after final148/148.
