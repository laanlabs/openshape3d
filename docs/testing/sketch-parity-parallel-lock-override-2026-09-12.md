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
(four Lock cells plus four free-anchor/repeated-stability cells). Changed live/final/
publication pending. No acceptance promotion, inventory30/0/1/25. Reports1194/
master38. iPad/immutable05be744 unchanged.
