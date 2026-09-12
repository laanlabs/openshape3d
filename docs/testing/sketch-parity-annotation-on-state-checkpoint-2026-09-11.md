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

## Verified cross-plane correction checkpoint

Implementation `6b89d01` pushed. Focused2/2 followed by one clean **29/29**
combined result (26 annotation/identity tests and three UI workflows), zero
failures/skips, at `/tmp/os3d-qa26-plane-final-20260911.xcresult`.
Summary/log copied to durable QA26 live directory. No runner remains.

Changed-build live uses the UI suite's saved two-sketch fixture and a2mm driver:
AlwaysShow remainsON, Front-plane editing viewedTop hides the inactive ground
label, and Exit immediately restores2mm without geometry change. Native50mm
reference and pre-fix clone50mm leak are retained; size difference is explicit.
The first changed-run plane tile tap missed at the new zoom and was not counted;
confirmed tile entry/status preceded the verified suppression capture.

Publication verified: illustrated835 unique media, eight new source hashes once,
zero827 predecessor loss, heading once. Master38, zero media loss, one note.
`publication-manifest.json`, `illustrated-verification.json`,
`master-verification.json` and exports live in the durable directory.

QA26 remains PARTIAL: independent coplanar native annotation scope remains
unverified. Native Sketch entry resumedSketch06 instead of creating a separate
item. Official plane documentation explains immediate same-plane continuation:
https://support.shapr3d.com/hc/en-us/articles/7874240047388-Using-sketch-planes
Next establish a separate same-plane item after an intervening creation, then
compare its annotation scope. Inventory23/0/1/32; iPad/immutable05be744 unchanged.

## Independent coplanar correction

Native Sketch08 independently created on Front after committing Top Sketch07.
With Always Show Dimensions ON, visible Front Sketch06's50mm dimension is
suppressed during Sketch08 editing and restored on Exit. This disproves the
intermediate plane-only scope; the dimension filter now uses active sketch ID.
Constraint glyph behavior remains unchanged. Focused annotation21/21 clean.
Changed clone gallery reopened saved2mm Sketch1 driver; editing independent
coplanar Sketch2 hides2mm, Exit restores it without changing any of three lines.
Native/clone sizes differ explicitly (50mm/2mm); comparison is annotation scope.
PNG/JSON and focused log/summary copied to durable QA26 directory. Combined gate
and publication pending; QA26 remains partial until final verification.

## Final finite QA26 closure

Source `2fdecd6` pushed. Final combined **29/29**, zero fail/skip, one serial run
at `/tmp/os3d-qa26-coplanar-final-20260911.xcresult` (26 annotation/identity tests
and three UI workflows), after separate focused21/21. No runner remains.
Changed live coplanar suppression/Exit and gallery persistence inspected; prior
paired active/hidden/re-entry/toggle and other-plane checks remain valid.
Illustrated export841 unique media, all six new source hashes once, zero835
predecessor loss, one coplanar heading and final verdict. Master38, one closure
note, zero loss. Durable `coplanar-publication-manifest.json`, both
`coplanar-*-verification.json` and `coplanar-*-after.docx` record verification.
QA26 finite recipe PASS. Inventory24/0/1/31. QA25off-state selection next.
No iPad installation, Pencil or full-parity claim; immutable05be744 untouched.
