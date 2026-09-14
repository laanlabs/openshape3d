# QA-36 smaller arc / larger circle deep Tangent

Source checkpoint: `5076e32`. QA-36 remains partial; inventory 26/0/1/29.

## Paired diagnosis

Native Shapr3D: lower semicircle centered at window (1000,600),
R6708.725 mm / 180 degrees, and larger circle centered at (1000,625),
R13000 mm. Reverse-box selection selected two edges and enabled Tangent.
Apply moved the arc center downward to approximately (1000,606), preserving
radius/sweep and the circle. The supporting-circle contact is above the arc,
with a complementary dashed guide. Selected arc readout confirms unchanged values.

Unchanged clone: lower arc at (450,700), approximately 20-point radius, and
circle at (450,725), approximately 40-point radius. Both edges selected;
Tangent disabled. Pixel dimensions are fixture proportions, not matched units.

## Implementation and regression

Enable only the newly observed smaller-arc deep-overlap interval:
`circleRadius - arcRadius < centerDistance < circleRadius`.
The existing internal-contact solver preserves radius/sweep and fixed target.
For a smaller internally tangent arc, the guide ray points away from the
larger circle center, rather than toward it. No geometry is added by the guide.

Before regression: 0/1. Corrected focused regression: 5/5, zero failures/skips.
The new test checks internal contact, fixed circle, unchanged radius/sweep,
selection-scoped guide visibility for either operand, JSON and exact Undo/Redo.
The focused set also retains nested/deep larger-arc, external off-span and
boundary/locked-refusal coverage. Combined final gate: **103/103**, zero failures/skips, on5076e32
(96 model/integration plus seven rail UI workflows). No runner remains.

## Evidence and remaining gate

Durable evidence root:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-small-arc-tangent-live-2026-09-12/`.
Native preview/pair/applied/value and clone before screenshots retained locally.
Before/focused logs and summaries copied there. Final result path:
`/tmp/os3d-qa36-small-arc-final-20260912.xcresult`.

Changed-build live apply and selected-arc opposite guide passed. Undo restores
arc450700; Redo restores center~450705 with fixed circle450725. Gallery reopen
retains R0.2473mm/179.62degrees and the guide/Tangent glyph. Saved archive:
arcRadius0.24733978408446772, circleRadius0.49448525905632124,
sweep179.61861462041549degrees, internalContact residual1.4e-16, dimensions0.
Native Undo/Redo and reopening retain R6708.725mm/180degrees; reopened arc
center~981572, fixed circle~981589. Native Top transition required a settled
second click; the intermediate perspective capture is not a Top-view claim.
Publication verified: illustrated1069unique/master38, nine source hashes
exactlyonce, headingsonce, zero1060/38 predecessor loss. Smaller-arc fully nested,
coincident-center and exact branch boundaries remain unverified. iPad and
immutable 05be744 IPA unchanged.
