# Single-line selection controls — September 8, 2026

Baseline541ea8e pushed. Native disconnected line and separate standalone
horizontal1621.6547mm line show dimension/endpoint selection without generic
transform controls. Native More→Move/Rotate exposes white axes and Copy.
Pressing M alone did not enter the action, so no shortcut behavior inferred.
Clone fresh horizontal2.477mm line250620→450620 immediately shows blue
selection ring/diamond. Three diagnosis screenshots locally indexed.

Correction: single-line render AND hit-test gizmo require explicit Move/Rotate
or Copy, using the existing explicit mode. Direct body/endpoint input unchanged;
rectangle/radial controls remain contextual and multi-selection unchanged.
Native explicit white axes versus clone blue ring is a remaining visual gap.
Serial exec37196 /tmp/os3d-line-selection-transform-20260908.xcresult/.log
runs single-line body/explicit/Copy, two-line selection movement/history, and
Disconnect handle/history workflows. Live post-fix pending. Both Docs blocked.

Initial37196 finished65:2UI passes/1single-line failure. Default state and
body drag/Undo passed; explicit center drag resulted in gallery navigation
(test recording21/22s), not merely missing annotation. Live freshFront clone
2.477mm250350→450350: default no ring; Move/Rotate reveals ring with H glyph
covering center350350. Center40px drag does nothing; start365350→405350
moves line to290350→490350. This confirms the overlap independently of the
XCTest navigation symptom. Shift colliding constraint badges beside transform
center, keeping them tappable. New serial81880 same3UI workflows plus explicit
center/glyph nonintersection assertion. Post-fix center behavior pending.
Native explicit center and arrow attempts remained0mm; no movement claim.

Publication recovery20:18: separate master tabt14 Saved, status addendum and
paired Disconnect reopen images exported/hash-matched,38images. Original
stalledtabs retained. This line-control diagnosis is still local-only.


20:33 follow-through: glyph-clearance rerun clean 3/3; live center350350→390350
moves endpoints250350→450350 to290350→490350, 2.477 mm unchanged.
Painted Undo/Redo restored positions; Done removes ring. Screenshots final-mode,
center, undo, redo, done. Copy did NOT preserve original in place: two live
armed copies moved overlapping original/copies together. Solver proximity weld
confirmed in code. Initial successful UI only tracked copied label, insufficient.
Duplication now excludes copied line endpoints from source proximity, while
adding explicit coincident joins inside copied groups. New test also reselects
original at old Y. Serial72947 isolation suite pending; no live activity alongside.
Master38 and illustrated78 new Disconnect images export-hash verified via new
tabs; old unsynced tabs preserved. This change remains local-only.


Source-isolation72947:9unit pass/1UI original-reselection failure. Expanded
65041:11unit pass/1sameUI failure. New geometry tests verify source stays fixed,
copied group joins, Undo/Redo/reload, and previously disconnected joins stay
separate. Failure screenshots show original and copy separately; reselection
now has settling waits and before/after attachments, serial70218 pending.
Live reopened design shows both 2.298mm lines. Original at y431 selects normally;
Copy y431→331 leaves original431 and earliercopy562 fixed. PaintedUndo returns
new copy431, Redo331. Corrected source isolation live verified; test-selection
failure separate. Line-specific native Copy and finalgallery repeat stillpending.


Final70218 targeted1/1 passed after allowing selection changes to settle;
original remains at original Y. Eleven geometry/history passes from65041 plus
this targetedUI are not one clean combined run. Native line-specific reference:
explicit app switch, More→Move/Rotate, Copy belowcenter, upwardaxis click opens
keypad. Typed1000 moves copy y409→359, original409 unchanged. Copied length
1621.6547 mm verified after Escape/reselection. Drag probes stayed0mm, excluded.
Clone final test design gallery reopened original y431/copy562, each2.298mm
selectable separately with default no ring. Live pre-rerun extra Copy431→331
preserved original431/priorcopy562; UndoRedo restored431/331. Native Copy stays
armed; clone resets. Explicit white axes vs blue ring and copied constraint
inheritance beyond internal joins remain outside this correction.
Illustrated addendum + paired native typed Copy/clone live result inserted;
export verification pending. Local evidence root line-controls current.

Publication final: illustrated Saved80 embedded images, native typed Copy and
clone result exact SHA256 matches in exported DOCX. Master38 final follow-through
and gallery-reopen note exportverified. Initial79 export lagged clone image;
repeat verified80. Original stalled tabs remain untouched. Both finalexports
retained in evidence root. No tests active; ready to commit this bounded change.
