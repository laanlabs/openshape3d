# Arc third-point and chained continuation — September 9

Baseline `00537b4`; native Shapr3D Sketch04 and OpenShape3D Ground/Top sketch.
This receipt corrects the earlier ambiguous midpoint-drag interpretation and
covers the direct Arc third-point stage plus chained continuation. It does not
close QA-13 major/minor or tangent-transition acceptance, and it does not claim
physical Pencil behavior.

## Paired diagnosis

After two endpoint clicks, moving the macOS pointer in native Shapr3D reshaped
the pending arc through the hovered third point. Clicking that point committed
the arc. Arc remained armed and the prior endpoint immediately became the start
of the next arc: moving the pointer showed the next provisional chord, arc,
radius and sweep. Thus the earlier screenshot described as a midpoint drag was
actually third-point construction followed by chained continuation.

The clone accepted a third click, but before this correction did not preserve a
shared endpoint for the next arc. Supported Peekaboo pointer movement did not
deliver a simulator hover callback, so clone hover remains automated-only rather
than a live failure. Direct simulator clicks remained a valid touch-equivalent
route.

## Correction

Pending Arc now reads pointer/Pencil hover as its third point and continuously
updates sagitta. A touch-only third click also applies its own location before
commit. After that commit, Arc stays armed and the prior second endpoint anchors
the next arc. Hover previews the next default arc without advancing the tap
state; the next click establishes only endpoint two. Escape drops that transient
chained preview without changing committed geometry or undo depth. Tool switch,
finish and non-chained commit paths still clear the anchor.

The three affected UI fixtures now commit through an explicit third point and
reselect that known point. Their prior fixed-45-degree reselection assumption was
invalid once the third point became authoritative.

## Regression history

- A clean focused construction run passed 9/9 after chained preview was added.
- The final focused run passed cleanly 10/10 after the Escape/history guard.
- The first broader run passed all 31 unit/live-dimension checks but failed all
  three arc UI fixtures because they still targeted the old default-45-degree
  midpoint.
- After correcting those recipes, two UI tests passed and the sweep test failed
  only at its one-direction radial-handle assertion. The new above-chord fixture
  correctly places that handle on the opposite side, so the assertion now checks
  visible separation rather than a hard-coded downward direction.
- A targeted sweep rerun passed 1/1.
- Final current-revision combined run passed cleanly 34/34: 10
  `ArcTapConstructionTests`, 21 `LiveDimensionTests`, and three arc
  `DimensionUITests`. Result bundle:
  `/tmp/os3d-arc-thirdpoint-chain-combined-final-20260909.xcresult`.

Earlier malformed/typo command attempts either selected no valid destination or
scheme and ran no tests; they made no simulator-app assertion and are not counted
as product failures.

## Live verification and evidence

Native captures show the hovered third-point shape, committed arc and automatic
post-commit chained preview. On the exact tested clone binary, two endpoint
clicks showed `R3.21 mm` and `45°`; the third click reshaped and committed a
major arc. The following click produced a new `R1.46 mm` / `45°` pending arc
from the prior endpoint while the first arc remained committed. This proves the
shared endpoint through the available simulator click route. Clone hover is
still automated-only because supported host pointer movement did not trigger the
simulator hover path.

Screenshots and SHA-256 receipts are retained under
`reports/openshape3d-core-sketch-milestone-2026-09-08/arc-third-point/`.
The existing illustrated Google Doc was anonymously export-verified at 213
image placements (six new placements): all three native PNG hashes match
exactly, while Google normalized the three large simulator PNG assets and their
32x32 RGB signatures match within 0.046 mean absolute channel value. The section
text is present. The master remains at 38 images and its corrected checkpoint
text was independently export-verified. Both DOCX exports and a machine-readable
`publication-verification.json` are retained beside the screenshots.

QA-13 remains partial: clean native major/minor boundary recipes, tangent
transition, and physical Pencil hover/touch remain open.
