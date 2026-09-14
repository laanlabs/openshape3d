# Arc direct major/minor boundary receipt — 2026-09-09

Revision: `44d72bb` (`fix/sketch-parity-foundations`, PR #29).

## Scope and result

This receipt closes QA-13's previously open direct-gesture minor/major boundary sample. It does not claim identical pixel coordinates across the native macOS viewport and iPad simulator, live clone hover delivery, or physical Pencil/touch validation.

- Native Shapr3D: with Arc armed, a two-endpoint chord drag followed by a third-point click produced selected `90°`, `180°`, and `220°` arcs.
- Exact OpenShape3D build: the same construction regions at a different scale produced selected `81.91°`, `176.03°`, and `214.93°` arcs.
- Clone toolbar Undo removed only the sampled `214.93°` major arc, leaving the earlier profile; Redo restored the profile geometry. The corrected global toolbar coordinates were used after one harmless click into the window's title area caused no mutation.

Verdict: direct minor, near-semicircle, and major construction categories are paired live. QA-13 remains partial because clone pointer hover is automated-only and physical device input is untested.

## Regression context

No source code changed for this boundary check, so no new automated run was started. The last relevant current-revision combined arc run remains the clean 63/63 result at `/tmp/os3d-arc-tangent-final-combined2-20260909.xcresult`.

## Evidence

Local evidence and `SHA256SUMS`:

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/arc-major-minor-boundaries/`

Files cover native 90/180/220 states, clone 81.91/176.03/214.93 states, and clone major Undo/Redo. Anonymous DOCX exports verify the illustrated report at 234 media assets with all eight new hashes and every predecessor unique hash retained. The net increase is seven because one repeated predecessor asset was de-duplicated by the DOCX package. The master remains at 38 media assets and its dated boundary note is present. Export copies and `publication-verification.json` are stored beside the PNGs.
