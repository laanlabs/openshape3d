# Arc cancellation and sketch-exit parity — September 9

Baseline `772a1e9`; native Shapr3D Sketch04 and OpenShape3D Ground/Top sketch.
This receipt covers cancellation after one or two arc endpoints and the settled
Escape that follows. It does not close QA-13's remaining third-point, chaining,
major/minor or tangent-transition cases.

## Paired diagnosis

Native had an existing committed arc and an unfinished second arc with radius
and `45°` feedback. The first Escape removed only the unfinished arc and
disarmed Arc. The committed arc remained. The next Escape exited sketch mode.

On the `772a1e9` clone, Escape left a pending `225.55° / R1.34 mm` arc unchanged.
`CommandShortcutsView` registered cancel actions for dimension and Line input,
but not Arc input or a settled sketch.

## Correction

Arc now owns Escape while armed. It clears either the first endpoint or pending
arc, clears transient snap/guide state, and disarms without committing geometry
or adding history. A separate settled-sketch Escape is registered only when no
drawing tool, selection, dimension, constraint, symbol, select mode or explicit
sketch transform owns the key; it then exits sketching.

The first focused run failed at compile time because the new test fixture omitted
a required line entity ID; no test executed. The corrected focused run passed
cleanly 6/6 in `ArcTapConstructionTests`, including first-endpoint cancellation,
two-endpoint cancellation, committed-geometry preservation and unchanged undo
depth. Result bundle: `/tmp/os3d-arc-cancel-final-20260909.xcresult` (Xcode may
suffix the on-disk bundle name when an earlier path exists).

The illustrated Google Doc was anonymously export-verified at 207 image
placements with all six newly inserted native/clone sequence hashes present.
The master roadmap stayed at 38 images and its cancellation checkpoint text was
also independently export-verified. The DOCX exports are retained with the PNGs.

## Live verification

The exact updated simulator binary was installed and inspected. With an existing
committed arc, a new two-endpoint pending arc showed its radius and `45°` sweep.
First Escape removed the pending arc and disarmed Arc while preserving the prior
arc; second Escape returned to model mode. This matches the native two-stage
sequence. Screenshots and SHA-256 receipts are retained under
`reports/openshape3d-core-sketch-milestone-2026-09-08/arc-cancellation/`.

QA-13 remains partial. Physical Pencil/touch input remains unverified.
