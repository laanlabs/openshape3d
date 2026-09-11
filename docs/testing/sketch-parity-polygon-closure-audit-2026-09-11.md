# QA-15 polygon closure audit — September 11, 2026

## Scope

This receipt closes the finite QA-15 recipe: side-count boundaries, radius
semantics, orientation, exact input, history, profile availability, and saved
recovery. It does not claim general constraint parity, hover parity, or physical
Pencil/touch behavior.

## Paired live comparison

- Native Shapr3D and OpenShape3D both released a five-sided polygon with the
  side-count and radius readouts visible and no automatically opened keypad.
- Editing the count from 5 to 65 retained the same center, radius, and first
  vertex direction in both apps. OpenShape3D used its visible keypad after a
  synthesized keyboard attempt failed to reach the field; that failed delivery
  is not classified as a product failure.
- Exact radius edits retained the center, side count, and orientation: native
  `R 3,471.1876 mm -> R 300 mm`; clone `R0.6184 mm -> R0.5 mm`.
- In both apps, the first Undo restored the old radius and the second Undo
  restored the pentagon. Two Redos restored the 65-gon and exact edited radius.
- The clone gallery reopen retained the 65-gon and `R0.5 mm`. Native reopened
  the saved 65-edge geometry and `R 300 mm`. Shapr3D documents and exhibits its
  polygon side badge as an immediately-after-creation control, so reopened
  count editing is not imposed as a reference requirement.
- The previously verified closed-profile extrusion behavior remains covered by
  the current UI workflow.

## Boundary and invariant coverage

The model test checks that 2 is refused, divide-by-zero remains recoverable,
3.5 truncates to 3, Undo/Redo is atomic, 65 is accepted, 10001 is refused
without adding history, and the polygon ID, center, radius, and rotation remain
unchanged. Geometry tests cover regular-polygon profile area, snap vertices,
tessellation, and encode/decode round trips.

## Regression history

- `/tmp/os3d-qa15-closure-20260911-0804.xcresult`: clean 12/12, but the intended
  count-boundary class was omitted because the selector used the file name
  instead of the declared XCTest class name. This run is retained and is not
  represented as boundary coverage.
- `/tmp/os3d-qa15-closure-final-20260911.xcresult`: clean 12/12 with the same
  selector mistake repeated at method level. Retained, not represented as the
  final closure run.
- `/tmp/os3d-qa15-closure-corrected-20260911.xcresult`: clean 12/12, but its
  selector named the file's first XCTest class rather than the class that owns
  the boundary method. Retained and excluded from the boundary claim.
- `/tmp/os3d-qa15-closure-final13-20260911.xcresult`: final corrected combined
  run, clean 13/13 with 0 failures and 0 skips. It includes the exact polygon
  boundary/history method, 11 geometry/profile/entity checks, and the complete
  polygon/ellipse profile UI workflow.

## Evidence

Local paired PNGs and exact hashes:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/polygon-closure/`

The illustrated Google Doc export contains 772 image placements, all eight new
closure hashes exactly once, and no media loss from the 764-image QA-12 export.
The master export retains 38 media and contains one dated QA-15 closure note.
Verified exports and SHA256 lists are stored beside the PNGs. The immutable
`05be744` IPA was not modified or installed.
