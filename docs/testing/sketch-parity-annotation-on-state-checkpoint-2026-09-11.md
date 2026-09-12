# QA-26 — Annotation on-state checkpoint

Evidence date: September 11, 2026. Baseline `89bb2f0`.

## Automated result

`SketchAnnotationVisibilityTests.testAlwaysShowToggleCoversActiveOtherHiddenAndReentry`
passes inside the current-tree annotation suite. It verifies that Always Show
Dimensions includes the active and every other visible sketch, excludes a
hidden inactive sketch, persists through sketch exit, returns to selection-only
visibility when disabled, and includes a hidden sketch when that sketch is
explicitly re-entered.

The focused QA-26 run passed clean 16/16 at
`/tmp/os3d-qa26-annotation-on-20260911.xcresult`. The same test is also included
in QA-27's final clean combined run at
`/tmp/os3d-qa27-dimension-final2-20260911.xcresult`.

## Boundary

This is automated evidence only. Fresh paired toggle, exit and re-entry capture
is blocked by the current simulator input-delivery failure: supported Peekaboo
events resolve to the foreground Simulator window without mutating the app.
QA-26 remains partial and has not been added to the passed inventory. Google
Docs publication is also pending; the illustrated baseline remains 786 media.


## September 11 paired scope correction WIP

Paired live unselected50mm, Exit retention, Hide removal and explicit hidden
re-entry restoration pass. Clone switch coordinate taps did not toggle; direct
switch drag did, so initial missing labels were not a product failure.

Confirmed gap: native Always Show Dimensions remains ON while Sketch05 is
active and visible Sketch06's50mm dimension is suppressed. Matched clone
Front-plane editing viewed fromTop still displays its ground-plane50mm driver.
The correction limits always-show dimensions to the active geometric plane
while editing; outside editing all visible sketches remain included. Hidden
active sketch and saved flags are preserved. Constraint glyphs unchanged.
Native separate coplanar-sketch scope is still unverified; no broader rule is
claimed. Focused2-case gate running at
`/tmp/os3d-qa26-plane-focused-20260911.xcresult`; changed live and publication
pending. Durable PNG/JSON/manifest under workspace reports/core milestone/
annotation-on-state/qa26-live-2026-09-11. Inventory23/0/1/32 unchanged.
