# QA40 — numeric editor versus camera input

Date September12, baselineed46642 (product43bbf06). QA54 alreadyclosed,
inventory32/0/1/23. No physical input claim.

## Paired cube boundary

Native: existing70912.4119mm line in Sketch12, keypad opened without changing
the value. Orientation cube drag leaves camera and editor unchanged. First
quarter-turn arrow click dismisses editor without moving camera; second rotates
with unchanged selected length. Repeating the same cube drag after dismissal
rotates the camera, proving the original blocked gesture was delivered.
Clone: existing13mm expression line reopened, editor opened. The same cube-drag
class rotates camera and reprojects the still-open editor. This is a confirmed
input-priority discrepancy. Pan is not yet compared.

Navigation control reference (not behavioral proof):
https://support.shapr3d.com/hc/en-us/articles/7873906073884-Keyboard-shortcuts-gestures-and-hotkeys

## Before regression and correction

`DimensionUITests/testOpenDimensionBlocksCubeDragUntilDismissed` before0/1:
field midpoint moves449.5→524.5 while draft12+ remains. Receipt
`/tmp/os3d-qa40-cube-before-20260912.xcresult`, log sibling.
Scoped ViewportView fix claims cube drags while editingDimension exists and
consumes changed/end, leaving draft and geometry untouched. Normal cube drag
returns after dismissal. No camera-tap or two-finger behavior changed.
Focused corrected run `/tmp/os3d-qa40-cube-fixed-20260912.xcresult` active;
final result, broader gate, changed live/history/reopen/publication pending.
Screens retained under workspace report `keyboard/qa40-camera-live-2026-09-12`.

Focused corrected UI1/1 passed, 32.162seconds, terminalexit0. It preserves
invalid12+ draft/field position while blocked, then accepts12 and verifies
LookAtSketch appears after a normal cube orbit. Broader gate/live stillpending.

## Final current-source and live verification

Final57/57 on5f1bf94, zero failures/skips, one serial gate:
`/tmp/os3d-qa40-camera-final-20260912.xcresult`, summary/log retained.
Changed live editor1.4932mm and camera stay fixed during cube drag. After
blank dismissal and settling, the same drag rotates. Immediate post-dismiss
attempt before settling did not rotate, excluded; settled repeat suppliesproof.
Undo removes only newly created line; Redo restores. Reopened line/rectangle
visible, saved line length1.493231177330036mm. There is no visible dimension
badge on the uncommitted reopened line, so value is a saved JSON readback.

Ten illustrated images inserted and one master note; export verification pending
against1227/master38. QA40 partial, inventory32/0/1/23. Pan stilluntested.

Publication verified: illustrated1237 unique, ten hashes each once, no1227
predecessor loss; master38, one heading each. Verification JSON/XML retained
under the durable QA40 folder. No acceptance promotion; pan next.
