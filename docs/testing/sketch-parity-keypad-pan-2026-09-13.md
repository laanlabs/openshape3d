# QA-40 — keypad transitions: pan while a dimension keypad is open (2026-09-13)

Open item from the Sept 12 receipt: "Pan is not yet compared" (the rotate
half — an orientation-cube drag — was paired: native blocks it while the
keypad is open; the clone was changed to match at 5f1bf94).

## Native pan: not deliverable through this tooling

Every pan candidate Peekaboo can post was tried in model mode with the
canvas compared pixel-wise before/after (Default View reset between tries):

| input | result |
|---|---|
| plain left-drag on empty canvas | no camera change |
| ⇧ / ⌘ / ⌥ + left-drag | no camera change |
| horizontal wheel scroll (left ×8) | no camera change |
| trackpad-style "smooth" scroll, left and down | no camera change |
| ← and ⇧+← | no camera change |
| ⌘+← | camera **rotated** (the View menu's "Rotate Left by 15°" chord) — not a pan |

Shapr3D on the Mac pans on the middle button or a two-finger trackpad gesture;
Peekaboo has no middle button and posts wheel events (which zoom), and no
Python on this machine has the Quartz binding to post a middle-button drag.
Native pan therefore stays a physical-input observation (QA-52), now with an
explicit inventory of what was tried rather than an open question.

## Clone rule inventory during dimension entry (code, 5f1bf94 line)

- Orientation-cube drag: claimed and ignored while `editingDimension` is set;
  draft and geometry untouched (paired with native; DimensionUITests
  testOpenDimensionBlocksCubeDragUntilDismissed).
- Canvas tap: click-away — a changed draft is committed, an unchanged one is
  cancelled without a history step (`finishDimensionEditOnClickAway`).
- One-finger empty-canvas drag and two-finger pan: not gated — the camera
  moves and the open editor reprojects. Native's response to a pan is
  unobserved; its cube rule suggests it would block, but that is inference,
  not evidence, so the clone is left as is.

## Result

QA-40 stays partial; the pan comparison moves to the physical-device list
with the attempt inventory above. No source change. 32/0/1/23; iPad
unchanged.
