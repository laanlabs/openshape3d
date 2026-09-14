# QA-23 — Selection-state finite closure

Evidence date: September 11, 2026. Exact-tree baseline `24bf598`.

## Reconciled paired evidence

- Exact endpoints select the endpoint rather than the adjoining edge in both
  apps; a short edge's central midpoint selects the edge. The paired native and
  clone samples, including the 26-pixel native edge and 30-pixel clone edge, are
  retained in `sketch-parity-short-edge-selection-2026-09-08.md`.
- Ordinary line/arc/rectangle outline selection uses the selected highlight and
  returns to the unselected sketch color after blank deselection. Paired color
  and blank-deselect evidence is retained in the September 8 selection receipts
  and the rectangle lifecycle receipts.
- Closed-profile interior selection in each app enters the downstream extrusion
  flow without selecting unrelated geometry. The paired native/clone circle
  profile proof is retained in `sketch-parity-downstream-smoke-2026-09-09.md`.
- On the exact current build, a fresh rectangle was blank-deselected, selected
  by its profile interior, canceled back to the unchanged sketch, selected by
  its outline midpoint, deleted, restored by exactly one Undo, and retained by
  gallery reopen. The saved profile remained available after reopen.

## Regression and evidence

One clean serial current-tree run passed 19/19, zero failures/skips:

- `SelectionTests` (10)
- `SelectionUXTests` (7)
- two short-line endpoint/edge-priority tests

Result: `/tmp/os3d-qa23-selection-baseline-20260911.xcresult`.

Current clone captures and SHA-256 inventory are under
`reports/openshape3d-core-sketch-milestone-2026-09-08/selection-qa23/`.
The first live capture route fell back to an unpermitted local daemon; only the
Peekaboo UI app was restarted. Simulator/app data, Shapr3D, report tabs, and the
Mac security configuration were unchanged. Subsequent interactions used the
authorized GUI bridge and were inspected after settling.

## Verdict and boundaries

QA-23 behavior passes for the finite endpoint/midpoint/outline/profile/blank-selection
recipe. Delete affected exactly the visibly selected outline, and one Undo
restored it. Additive/multi-selection remains QA-24, hover QA-21, comprehensive
dimension selection QA-28, and physical Pencil/touch QA-52. Fresh native canvas
input is still blocked for QA-05 and QA-19; this closure relies on retained
native evidence and does not relabel that delivery blocker.

Publication is verified. A fresh authenticated tab avoided the older tab's
temporary saving lock. Anonymous DOCX/TXT exports contain one QA-23 closure
heading and one verdict, 796 unique image placements, all ten new SHA-256 hashes
exactly once, and all 786 predecessor assets. The new images comprise retained
native short-edge midpoint, endpoint and profile-selection evidence plus the
current-build clone blank/profile/outline/Delete/Undo/gallery/reopen sequence.
The master roadmap retains 38 media and contains one dated closure note.

QA-23 is promoted to passed. Inventory is **21 passed / 0 failed /
1 device-blocked / 34 incomplete**. Additive selection, hover,
dimension-selection breadth and physical Pencil/touch remain separate cases.
The immutable `05be744` IPA is unchanged.
