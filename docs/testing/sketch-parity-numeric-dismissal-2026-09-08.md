# Numeric dismissal / invalid input — September 8, 2026

Base b18e4a8; native Front Sketch02 and portrait clone Top Untitled2, Peekaboo
mouse/keypad (native text injection), same app versions as milestone receipts.
Evidence root `reports/openshape3d-core-sketch-milestone-2026-09-08/numeric/`
under the OpenClaw workspace. Scale differs; compare commit/cancel semantics.

## Paired diagnosis

- Native width300→0: rejects with nonzero-distance message and restores300;
  geometry remains unchanged. `native-zero-width.png`.
- Clone width2→0: rejects with modal greater-than-zero alert, keeps2×1 mm.
  `clone-zero-width.png`. Alert vs inline warning remains a known UI difference.
- Clone seeded2, typed3, switched to Circle: editor closes, width still2.
  `clone-uncommitted-three.png`, `clone-tool-switch-discards.png`.
- Native seeded300, typed450, clicked Line palette: click-away commits450;
  reselect confirms450. `native-uncommitted-450.png`, `native-tool-switch.png`,
  `native-click-away-committed450.png`. The click dismissed editor; do not infer
  it also armed Line from command success.
- Native typed600 then Escape: old450 restored. `native-escape-retains450.png`.
- Native typed600 again and clicked blank canvas: commits600, reselect confirms.
  `native-blank-committed600.png`.
- Clone typed3 again and clicked blank canvas: editor closes, unchanged geometry.
  `clone-click-away.png`. Confirmed click-away commit gap, separate from explicit
  cancellation. No claim of clone live Escape delivery (still unresolved).

## Narrow correction

Blank sketch tap finishes pending dimension and consumes that tap; it must not
also draw or trim underneath. Tool activation accepts pending draft before arming.
The field keeps local SwiftUI text; an observation-ignored, session-keyed mirror
supplies the draft at click-away without reintroducing earlier observable binding
render loop. Unmodified inspection adds no history step. Explicit cancel discards.
Invalid input still rejects via existing validation. No general blur/drag/exit
semantics claimed; these are separate future checks.

Initial serial DimensionUITests finished3passed/1failed:
`/tmp/os3d-milestone-numeric-away-20260908.xcresult`, exec37708 exited65. New test checked dismissal immediately after a canvas tap;
the recognizer waits for double-tap failure. Bounded-wait diagnostic and
before/after captures added, targeted rerun exec47171:
`/tmp/os3d-milestone-numeric-away-diagnostic-20260908.xcresult`. New regression
requires measured values3/4, Undo/Redo restoration, and exactly draw+two edits,
so a click-away cannot silently create a stray point. Not candidate-ready.

Diagnosis publication verified62inline images and all four new PNG hashes in
`published-numeric-diagnosis.docx`; `numeric-diagnosis-publication.json`.

## Verified correction

Targeted diagnostic passed1/1 with bounded wait for single-tap recognition;
initial run3passed/1failed, not a clean combined run. Measurements3/4, undo/redo
and exact draw+two-edit history passed. No source change was needed after initial
failure; diagnostic test now waits for the asynchronous gesture outcome.

Live fresh clone Untitled2 Top: blank click commits2→3, then Circle palette
commits3→4; height remains1.5 and lower-left fixed. No phantom placement.
`clone-click-away-fixed3.png`, `clone-tool-switch-fixed4.png`. Invalid0 via blank
click still rejects and retains4×1.5: `clone-zero-click-away-fixed.png`.
Native comparison above establishes commit semantics; no claim of identical
warning presentation, anchor behavior under explicit relations or Escape delivery.

Latest tested executable SHA256:
`e053cec9fcc4e8ab271eed13c1c448f6c5dd6b191ac86a06c0fd8128e625dee7`.
Illustrated Doc64images, correction text and both corrected PNG hashes verified
by anonymous export: `published-numeric-fixed.docx`, `numeric-fixed-publication.json`.
Next: landscape/compact keypad reachability, remaining rectangle matrix.
