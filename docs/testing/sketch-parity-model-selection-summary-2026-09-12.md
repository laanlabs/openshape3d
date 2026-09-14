# QA24 model-mode selection summary — September 12, 2026

Native named sketch entry/Exit retains six-edge count, total length and a 3D
Move/Rotate gizmo. Clone0cc5d6c retains both selected lines but no bottom summary
or gizmo. Fresh paired os3d-qa24-gizmo-native/clone-entry/exit PNG/JSON is durable
in workspace reports selection/qa24-through-live-2026-09-12.

This correction addresses only count/length feedback, not 3D transform dispatch.
Before model0/1 reproduces missing model-mode rows. First focused invocation
failed compilation (document needed session.document); corrected focused17/17
passes SketchIdentity7 + SelectionUX10, zero failures/skips. Sources/test dirty.
Real UI workflow now checks preserved measured length, edge-count feedback and
blank deselection. Exclusive runner at /tmp/os3d-qa24-model-summary-ui-20260912
.{log,xcresult}. Broader gate, changed live and publication remain pending.

Inventory32/0/1/23; iPad unchanged. Full model-mode transform, curved overlap
and remaining item types remain open.

Corrected UI1/1 passed after initial query error: SwiftUI identifier is on text
leaves, not a container. Added primitive rectangle+pentagon nine-edge assertion;
UI length query no longer assumes mm preference. Source checkpoint before final
combined gate; live/publication pending.

## Final regression and changed live

Source605511b, test-only fixture correction0e86c6b pushed. Corrected final47/47
(43 model/measurement +4 UI), zero failures/skips, terminal0. Initial final compile
failure used wrong rect argument labels; min/max correction only. All receipts
retained at /tmp/os3d-qa24-model-summary-{before,focused,focused2,ui,ui2,final,final2}
-20260912.{log,xcresult}; final2-summary.json has terminal counts.

Changed live: single-line Exit shows1edge/2.00mm; two disconnected line selection
shows2edges/3.58mm. Blank clears strip and selection, preserves geometry. Undo
removes added sloped line; Items reselection/Exit measures1edge/2.00mm. Redo
restores sloped line but only horizontal remains selected:1edge/2.00mm is correct
for that partial selection. Explicit named whole-sketch reselection then shows
2edges/3.58mm. Gallery reopen retains both lines; reselect/Exit repeats same total.
Native fresh blank/reselect/Exit shows no strip /6edges21,454.0456mm respectively.
Fixture counts/scales differ; no native geometry edit was needed for this read-only
summary comparison. Prior native gallery proof remains retained, not new.

All os3d-qa24-summary-* and earlier gizmo-* live PNG/JSON copied to durable
workspace reports selection/qa24-through-live-2026-09-12. Ten unique before/after
assets inserted, export verification pending. No runner. 3D MoveRotate dispatch
and gizmo remain open; QA24partial32/0/1/23;iPadunchanged.

Publication verified: illustrated1302 unique media/1305 placements, ten hashes
exactly once, no1292unique/1295 predecessor loss. Master38, dated heading once,
no loss. Durable model-summary-verification.json records both exact inventories.
