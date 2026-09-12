# QA-55 sustained use — 2026-09-09

Revision: `7863cfd` documentation tip over runtime revision `1ea2ea5`
(`fix/sketch-parity-foundations`, PR #29).

## Paired live result

Both apps completed ten rectangle/circle/diagonal-line construction cycles in
one sketch, exercised Undo/Redo, reached a dense end state, and retained the
geometry through gallery reopen. OpenShape3D retained the dense project after
the focused unit-test host app closed and the exact build was relaunched.

OpenShape3D's ten valid cycles took 6.13–6.23 seconds each under Peekaboo.
Native Shapr3D's accessibility-snapshot orchestration took 19.33–20.58
seconds per rectangle/line cycle, plus 1.68–1.75 seconds for the corrected
settled-circle passes. These are automation wall times, not a product
performance comparison. Neither app visibly hung or stopped accepting input.

Native needed a 0.7-second settle after circle release before the next tool
switch. The initial immediate-switch circle drafts were absent on inspection,
so the nine missing circles were repeated with the settle and verified beside
the first isolated settled circle. Undo removed the final circle and Redo
restored it. This timing correction is recorded rather than counted as an app
failure.

An initial clone stress script orbited the view and did not construct the
intended rectangles. Its screenshots are retained under `excluded/` and are
not acceptance evidence. The corrected clone run used central targets; its
cycle 1, 5 and 10 screenshots show the intended cluster growth.

Verdict: QA-55 passes for sustained desktop/simulator use. Physical
Pencil/touch endurance remains part of QA-52 and is not claimed here.

## Focused regression

One current-revision serial run passed cleanly 71/71 across
`ProfileTests`, `SketchDefinitionCacheTests`,
`ConstraintIntegrationTests`, `RectangleConstructionTests`,
`ArcTapConstructionTests`, and `SelectionTests`.

Result bundle:
`/tmp/os3d-qa55-sustained-20260909.xcresult`.

## Evidence

Thirteen inspected acceptance PNGs, three timing logs, hashes, and the excluded
attempt are retained at:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/sustained-use/`

Google Docs publication is complete and anonymously export-verified:

- illustrated comparison: 260 image placements / 258 unique media assets,
  all 13 new placements and all 12 unique new hashes present, with one QA-55
  status block;
- master roadmap: 38 media assets with one dated QA-55 note.

The verified DOCX exports and `publication-verification.json` are retained
beside the PNGs.
