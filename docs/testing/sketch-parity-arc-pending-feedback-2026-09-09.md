# Pending three-point arc feedback — September 9

Baseline `aa34577`, native Shapr3D Front view and OpenShape3D Ground/Top view.
This receipt covers on-canvas presentation and third-point shaping only; it does
not claim physical iPad input or complete QA-13 acceptance.

## Paired diagnosis

After two endpoint taps, native displays the provisional arc with two radius
rays, a curved angular leader and arrowheads, its sweep, and a radius leader
continued through the second endpoint. OpenShape3D displayed only a radius line
from the circle center to the arc midpoint. Its long line could leave the
viewport without exposing the defining sweep.

Native and clone both change curvature when the provisional arc's third-point
region is dragged. The supported Peekaboo Return route did not produce a
repeatable completion result in either app. A secondary native synthesized-key
diagnostic blocked before delivery and was terminated. Return/chaining therefore
remains explicitly inconclusive; no construction or commit semantics changed.

## Correction

`LiveDimensionKit` now emits both pending-arc radius and angular descriptors.
Radius terminates at the second endpoint. The live overlay draws the two radius
rays and a screen-space curved sweep leader with arrowheads, and extends the
radius leader toward a viewport-aware label position. The overlay remains
informational and does not intercept taps.

Focused regression `/tmp/os3d-arc-pending-feedback-20260909.xcresult` passed
cleanly: 21 `LiveDimensionTests` and the two-click arc UI workflow. The UI test
requires both `R` and degree readouts before the pending arc is committed.

## Live verification

- Native upper sample: `/tmp/os3d-arc-pending-native-upper.png`.
- Clone initial 45-degree sample: `/tmp/os3d-arc-pending-clone-postfix.png`.
- Native third-point adjustment: `/tmp/os3d-arc-thirddrag-native.png`.
- Clone third-point adjustment: `/tmp/os3d-arc-thirddrag-clone.png`.

The clone's 45-degree pending sample keeps both labels visible; after an upward
third-point drag it updates to `R1.5 mm` and `106.49°`. The native sample likewise
updates geometry and its two defining readouts. Different project scale means
the numeric radii are not compared as equal.

Final combined regression `/tmp/os3d-arc-feedback-final-20260909.xcresult`
passed cleanly in one run: 3 arc UI workflows plus 36 construction, analytic
and live-dimension tests (39/39 total). The illustrated report was anonymously
export-verified at 201 image placements with all four new screenshot hashes;
the master remained at 38 images and contains the final acceptance note. Both
DOCX exports and the PNGs are retained in the durable transform-controls report.

QA-13 remains partial because Return/chaining, major/minor and
tangent-transition cases are unfinished.
