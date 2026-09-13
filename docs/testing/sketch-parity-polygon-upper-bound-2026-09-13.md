# QA-33 — native polygon side-count upper bound (2026-09-13)

Open item from the Sept 11 probe: submitting 10,001 sides left Shapr3D in a
busy overlay at ~100% CPU that was not waited out, so the clone's 10,000
ceiling was "defensive, not parity". This probe bounds it with completed runs.

## Native (Shapr3D macOS, fresh ground Sketch 14, undone afterwards)

Route: Polygon (More → Polygon), drag centre → vertex, Return; disarm; click an
edge; click the rotated "N sides" label → keypad editor with the value
selected; type the count; Return. Shapr3D's CPU sampled every 3 s.

| count | CPU at ~100% | outcome |
|---|---|---|
| 1,000 | ~10 s | completed, "1,000 sides" rendered (native-03) |
| 2,000 | ~47 s | completed, "2,000 sides" (native-04) |
| 3,000 | ~119 s | completed, "3,000 sides" (native-05) |

No refusal, no overlay that outlives the computation. Cost grows with the
square of the count (≈1.3e-5 s·n² on this Mac): 10,001 extrapolates to ~22
minutes, which is the Sept 11 "hang". Undo of each count was instant. The
sketch was undone and the project parked (native-06).

## Clone

Bridge `sketch.addEntities` polygon: 1,000 / 3,000 / 10,000 sides each return
in ~0.04 s. The exec path also accepted 10,001, 100,000 and 1,000,000 (the
keypad path refuses > 10,000); after the million-sided polygon and its undo the
app sat at 100% CPU for over six minutes with `/v1/state` unresponsive and was
terminated. So a ceiling is a genuine guard here, and the exec parser now
shares the keypad's 3…10,000 bound (`bad_sides`), with a unit case for 10,001.
**Fixed at d2ff046** — AgentExecTests + DimensionKeypadCommitTests +
AgentRouterTests 84/84, one clean run; live on the rebuilt clone, exec 10,000 is
accepted and 10,001 refused with "must be a whole number from 3 to 10000".

## Result

The native "upper bound" is resolved: there is none — Shapr3D accepts any
count and degrades quadratically. The clone's 10,000 ceiling is a deliberate
divergence (native would take ~22 min at 10,001; the clone would render
instantly up to its bound and wedge far beyond it). Recorded as a
**scope exception, accepted by Jason 2026-09-13 (keep the 10,000 ceiling)**;
QA-33 stays partial on its remaining scope only.
Evidence: …/numeric-recovery/qa33-upper-bound-2026-09-13/ — 6 assets,
evidence-index.json. **Published 2026-09-13 18:24 UTC:** https://docs.google.com/document/d/1oplNFZXivCEu3pKEFR3VTM8vEvGUsDHTZjeVmMUYhzI/edit.
32/0/1/23; iPad unchanged.
