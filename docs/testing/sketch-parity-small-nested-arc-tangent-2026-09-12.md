# QA-36 fully nested smaller arc / larger circle Tangent

Source7349e99 pushed. QA36 partial, inventory26/0/1/29, iPad unchanged.

Native fresh lower semicircle centered800650, R7140.419mm/180degrees;
circle centered800660, R14000mm. Reverse-box selects two edges and enables
Tangent. Apply moves the smaller arc upward to~800641 while circle stays
fixed, with opposite-side supporting-arc guide. Selected readout preserves
R7140.419/180degrees. This fully nested interval differs from the prior
smaller-arc deep intersection fixture.

Unchanged clone arc250700 (20-point radius), circle250710 (40-point radius):
both selected, Tangent disabled. Different units are intentional; pixel
proportions define the same contact class, not exact matched dimensions.

The bounded change enables noncoincident nested smaller-arc pairs with
`0 < distance < circleRadius - arcRadius` (1e-9 center tolerance).
Existing internal-contact solver and opposite-side guide are reused.
Before0/1; focused6/6, zero failures/skips. New test checks fixed larger circle,
unchanged arc radius/sweep, internal branch, selection-scoped guide, exact
JSON/Undo/Redo. Final combined104/104 passed on7349e99, zero failures/skips
(97 model/integration plus7 rail UI). No runner.

Changed-build live apply/history/reopen and native history/reopen verified.
Clone arc250700→~250690, fixed circle250710, R0.2473/179.62degrees and
opposite guide persist. Saved arcRadius0.2473399343894175,
circleRadius0.49460166692733765, sweep179.61843474254567degrees,
internalContact residual2.8e-17, dimensions0. Native reopenedarc800589 and
circle800607 preserve R7140.419/180degrees. Intermediate perspective capture
is excluded from the settled Top-view claim.
Publication verified1078unique/master38, nine hashesonce, headingsonce and
zero1069/38 predecessor loss. Exact branch boundaries/coincident centers and arc-arc are not
claimed. 

Durable local evidence:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-small-nested-arc-tangent-live-2026-09-12/`.
Before/focused logs and summaries, native preview/pair/applied/value and clone
before PNGs retained there. Final path:
`/tmp/os3d-qa36-small-nested-final-20260912.xcresult`.
