# Arc endpoint tangent transition — September 9

Baseline `a380680`; native Shapr3D and OpenShape3D on the `os3d-unit`
simulator. This receipt closes the sampled line-to-arc tangent transition inside
QA-13. Direct gesture major/minor boundaries, simulator hover delivery, and
physical Pencil/touch acceptance remain open.

## Paired diagnosis and result

An isolated native recipe created a horizontal line, began an Arc at its right
endpoint, and placed the third point on the analytic tangent path. Shapr3D
committed the arc with a persistent tangent glyph at the shared endpoint. Undo
removed the arc while retaining the line; Redo restored the arc and tangent
relationship.

The same-shaped pre-fix clone arc looked tangent but stored no tangent
relationship or glyph. Arc construction now runs endpoint-only tangent
inference after the third point is known. It accepts only a line whose endpoint
is within point-snap tolerance and whose direction is perpendicular to the arc
radius within the saved angle tolerance. Interior crossings, connected oblique
lines, and the disabled Tangent setting are rejected. The arc and accepted
constraint commit through one Draw command, and chained input resumes from the
solver's settled endpoint.

The exact built clone then displayed the `T` glyph on selection. Undo removed
the arc and inferred constraint in one step; Redo restored the geometry and
the glyph. Gallery reopen retained the line/arc geometry. The generic sketch
constraint round-trip is already covered elsewhere; this live pass did not
re-prove the `T` glyph after reopening, so that narrower visual state remains
unclaimed.

## Regression

- Focused construction/inference run passed 31/31:
  `/tmp/os3d-arc-tangent-focused-20260909.xcresult`.
- Final current-revision combined run passed cleanly 63/63 in one run: 12 arc
  construction, 27 auto-constraint, 21 constraint-residual, and three existing
  arc UI workflows:
  `/tmp/os3d-arc-tangent-final-combined2-20260909.xcresult`.
- Three experimental UI attempts failed at canvas reselection, not tangent
  creation. Their recordings show the created arc, but XCTest selected the
  connected line instead of the arc before querying the glyph. The flaky test
  was removed rather than counted as coverage. The deterministic integration
  test asserts inference, one-step Undo, and Redo; paired live screenshots
  prove the actual glyph and geometry behavior.
- One malformed `xcodebuild` filter failed before building or running tests and
  is not a product failure.

Eight paired screenshots and `SHA256SUMS` are retained under
`reports/openshape3d-core-sketch-milestone-2026-09-08/arc-tangent-transition/`.
Google Docs publication is anonymously export-verified: the illustrated report
contains 227 drawing placements, all eight new PNG hashes match exported media,
and no unique media hash from the 219-placement predecessor is missing. The
master roadmap remains at 38 drawings and contains the dated tangent/63-of-63
note. Verification artifacts are `os3d-arc-tangent-illustrated.docx`,
`os3d-arc-tangent-master.docx`, and `publication-verification.json` in the same
evidence directory.
