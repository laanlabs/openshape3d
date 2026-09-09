# QA-56 downstream smoke — 2026-09-09

Revision: `1ea2ea5` (`fix/sketch-parity-foundations`, PR #29).

## Paired live result

Native Shapr3D and the exact OpenShape3D simulator build each created an isolated circle, selected its closed profile, entered the extrusion flow, committed a solid, and removed/restored the solid through Undo/Redo. The clone additionally canceled its first extrusion preview and returned to intact profile geometry before committing the second attempt.

Native used a typed 100 mm distance. The clone used a dragged 1.24 mm preview. This is workflow and history evidence, not dimensional or pixel equivalence. The native sample lived beside earlier unrelated arc geometry; the new circle was isolated and selected independently.

Verdict: QA-56 downstream smoke passes for the core closed-profile-to-solid handoff and history. Sweep/Loft remain separately covered by current-revision automation; this receipt does not claim that sketch parity changes fixed advanced downstream behavior or that physical device input was exercised.

## Current-revision regression

One serial run passed cleanly 65/65:

- 2 `SweepLoftUITests` workflows: committed two-segment Sweep with exact four-command Undo, and coplanar Loft rejection/cancellation.
- 63 unit checks across `SweepLoftTests`, `RevolveSweepLoftBrepTests`, `FeatureGraphEvalTests`, `SweepFlowTests`, and `LoftOctagonTests`.

Result bundle: `/tmp/os3d-qa56-downstream-20260909.xcresult`.

## Evidence

Twelve inspected PNGs and `SHA256SUMS` are stored at:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/downstream-smoke/`

Google Docs publication is complete and anonymously export-verified:

- illustrated comparison: 246 media assets, all 12 new SHA-256 hashes present,
  one clean QA-56 status block, and no stray recovery text;
- master roadmap: 38 media assets with one dated QA-56 note.

The verified DOCX exports and `publication-verification.json` are retained
beside the PNGs.
