# QA-49 profile topology closure — September 11, 2026

## Verdict

QA-49 passes its finite desktop recipe on `c039366`: nested hole, touching
loops, tiny versus weldable gap, duplicate straight boundary, and construction
crossing/exclusion. This is not a claim of exhaustive ellipse/spline/curved-
intersection topology.

Retained paired receipts already verify visible gap closure and hidden-source
control, nested-hole selection/extrusion/history/reopen, shared boundaries and
construction rendering, point-touch loops, duplicate and partial-overlap
boundaries, and crossed straight outlines. Those images and notes were already
export-verified; this closure adds no duplicate screenshot publication.

## Current-tree regression

One clean serial run passed **46/46** with zero failures/skips:

- 22 `ProfileTests`: rectangles, shared/divided/touching/crossed cells,
  duplicate and partial-overlap normalization, nested holes, and extrusion.
- 2 `ProfileEndpointWeldTests`: a micron-scale line/arc closure is accepted,
  while a real 50 µm opening remains open.
- 9 `ConstructionProjectFlowTests`: construction state/history/serialization
  and exclusion from profile boundaries.
- 11 `SketchEntityTests`: arc/ellipse/polygon/open-arc profile behavior and
  persistence.
- 2 UI workflows: rectangle-with-hole extrusion and polygon/ellipse profile
  creation/history/extrudability.

Artifacts:

- `/tmp/os3d-qa49-topology-final-20260911.xcresult`
- `/tmp/os3d-qa49-topology-final-20260911.log`

## Boundaries

Curved-curve intersection splitting beyond the finite recipe, comprehensive
tiny-tolerance fuzzing, overlapping coplanar fill hit precedence, and physical
Pencil/touch remain open in their broader acceptance lanes. The immutable
`05be744` IPA remains unchanged.

Acceptance inventory advances to **18 passed / 0 failed / 1 device-blocked /
37 incomplete** (26 partial, 11 explicitly deferred), total 56.
