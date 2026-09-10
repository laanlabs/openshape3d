# Final same-revision regression and gate triage — 2026-09-09

Tested working tree over runtime baseline `8479219` on
`fix/sketch-parity-foundations` (PR #29). Final correction revision and artifact
are pending. Physical iPad/Pencil testing
has not been performed.

## Initial full run

The first complete serial run produced 1,598 results: 1,586 passed, nine failed,
and three skipped. Result bundle:
`/tmp/os3d-final-gate-rerun-20260909.xcresult`.

All nine failures reproduced when rerun together, so they were not dismissed as
long-run contamination:

- five Chamfer/Fillet workflows;
- the Bug Report sheet workflow;
- two Sketch Offset workflows;
- the fillet-to-next-box isolation workflow.

The earlier 15-case failure set, which also included six already-corrected sketch
fixtures and the stale `FrameUniforms` ABI assertion, subsequently passed together
15/15 at `/tmp/os3d-final-triage-consolidated-2-20260909.xcresult`.

## Diagnosis and corrections

### Blend viewport ownership

Arming Chamfer/Fillet retained the normally selected body and its transform gizmo,
even though edge picking now owned the viewport. The gizmo received first refusal
on taps and visibly obscured the intended tool state. `beginBlend` now retains the
source body identifier in `blendBodyID` but clears the ordinary selection.

The test taps were also semantically stale. Their face-interior coordinates
correctly selected every edge of a planar face; the default 1 mm blend cannot be
applied to all four edges of these small fixtures, so Apply remained disabled.
The corrected fixtures tap inspected rendered edges, verify one/two-edge state,
and retain the invalid whole-face behavior rather than weakening it.

### Offset rendered targeting

Fixed viewport fractions no longer reached the diagonal rectangle after camera and
chrome corrections. A newly released rectangle advertises two opposite placement
markers, not four redundant connected-corner markers. The fixtures now derive the
painted top-edge midpoint from that visible bounding pair. Both Offset tests pass
cleanly 2/2 at `/tmp/os3d-final-offset-fix2-20260909.xcresult`.

### Bug Report reachability

The portrait Form keeps the attachment switch below the initial viewport. The
fixture now scrolls before querying the stable `BugAttachToggle`, then continues
through validation and Cancel.

## Consolidated deterministic rerun

All nine originally deterministic failures pass together in one serial run:
9/9 in 541.443 seconds at
`/tmp/os3d-final-nine-clean-20260909.xcresult`.

The Blend edit case incurred a 120-second XCTest animation-idle wait before
continuing successfully. This is retained as test-environment timing evidence;
it is not reported as a product performance comparison.

## Final full run

The same-working-tree full serial run passed. The authoritative xcresult summary
reports **1,598 total: 1,595 passed, zero failed and three skipped**. The device
configuration counter includes skipped tests in its passed count; the top-level
summary above is used to avoid reporting 1,598 passes.

- result: `/tmp/os3d-final-full-clean-20260909.xcresult`;
- log: `/tmp/os3d-final-full-clean-20260909.log`;
- elapsed: 5,116.835 seconds (about 85 minutes), serial, with no simultaneous
  Peekaboo or competing build.

## Live correction smoke

On the exact tested simulator build, an extruded rectangle initially showed the
normal blue whole-body selection and transform gizmo. Arming Chamfer changed it
to a neutral body with no transform gizmo. Tapping the painted top edge selected
one 3.50 mm edge immediately. Because the test body was only 0.79 mm thick, the
1 mm default was correctly rejected with an explicit local-geometry message and
disabled Apply rather than a false success.

Native Shapr3D was also inspected with its existing cylinder. Selecting the whole
body showed the native cyan body plus Move/Rotate controls. Invoking
Tools > Chamfer/Fillet with the whole body selected left that state unchanged;
native's normal edge-first workflow is therefore not claimed equivalent to the
clone's body-then-tool workflow. This is retained as a known downstream workflow
difference, not a core-sketch parity pass. The production correction is supported
by exact-build live clone evidence and the clean full regression.

Five inspected screenshots and hashes are retained under
`reports/openshape3d-core-sketch-milestone-2026-09-08/final-gate/`. Google Docs
publication, commit/push and signed device-artifact inspection remain required.
