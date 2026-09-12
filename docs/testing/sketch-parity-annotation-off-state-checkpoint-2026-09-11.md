# QA-25 — Annotation off-state checkpoint

Evidence date: September 11, 2026. Baseline `f70d15d`.

## Regression

The final current-tree run passed clean 23/23, zero failures/skips:

- 15 `SketchAnnotationVisibilityTests`
- 7 `SketchParityFoundationTests`
- `DimensionUITests.testDimensionFollowsTheSelectionAfterExitingTheSketch`

Result: `/tmp/os3d-qa25-annotation-final-20260911.xcresult`.

The first 22-case run had one fixture-state failure: the radius/diameter test
inherited the saved circular-annotation preference. The fixture now saves,
controls and restores that preference; the corrected 22/22 run is
`/tmp/os3d-qa25-annotation-corrected-20260911.xcresult`. A new several/disjoint
selection check initially observed the expected two saved lengths plus a
synthetic 0-degree selection candidate. That candidate belongs to QA-28, not a
hidden saved annotation. The assertion was narrowed to persisted dimensions,
passed 1/1, and is included in the final clean 23-case run.

The matrix now proves that with Always Show Dimensions off: nothing selected
shows no saved dimensions; selecting one entity shows its own dimension;
selecting several entities shows only their dimensions; and a disjoint
same-sketch selection does not expose the intervening entity's dimension.

## Live status and boundary

Retained paired evidence proves the completed-line and rectangle selection
states, and current automation proves the full ownership matrix. A new exact-build
live pass could not be completed: after the tests, the simulator rendered and
relaunched normally, but foreground Peekaboo clicks resolved to the Simulator
window without reaching its Sketch control or canvas. Restarting only the
Peekaboo app and then only the affected simulator did not restore input delivery.
Shapr3D, Chrome/report tabs, simulator data, and Mac security settings were not
changed.

QA-25 therefore remains partial. It must not be promoted until the fresh paired
none/one/several/disjoint screenshots are captured and the illustrated report is
saved and export-verified. QA-28 owns synthetic dimension candidates. Physical
Pencil/touch remains QA-52. Inventory stays 13 passed / 0 failed /
1 device-blocked / 42 incomplete, and the immutable `05be744` IPA is unchanged.

## Fresh paired matrix and viewport fixture diagnosis

On2fdecd6/d62c25d, nativeSketch08 saved10/12/8mm and cloneSketch1 saved1/2/3mm
show correct none/one/two disconnected/all-three ownership withAlwaysShowOFF.
Clonefirst+third excludesintervening2. Native narrowfirst/third window includes
middleendpoint, so12legitimatelyshows; notcountedasexclusion. Modifier-onlyShift
wasrejectedbybridge. Syntheticangle/transformcandidates are separateQA28.
Differentfixtureangles/scales areexplicit; no numeric-resize-direction claim.
ElevenPNG staged/inserted; illustratedexport verification stillpending841baseline.

Currentgate:28modelpasses/1UI failure. The20mmline extended outsideinitialviewport;
XCTest couldnotreachlabelx1675 on1032ptwindow. Savedownershipassertions passed.
Screenshotandfailurebundle retained. UIfixture now invokesFitView after exact20
edit and launchesAlwaysShowOFF explicitly; visibility/editorassertions unchanged.
Focused rerun active /tmp/os3d-qa25-fitted-ui-20260911.xcresult. Productsource
unchanged. QA25partial pending focused/combined gate and publication verification.

Focused fitted UI rerun passed1/1 at
`/tmp/os3d-qa25-fitted-ui-20260911.xcresult`; unchanged Exit/reselection/editor
assertions passed. Corrected combined29 gate running separately, not yet counted.

## Verified finite QA25 closure

`db230f8` pushed. Corrected combined29/29 clean, zero fail/skip, at
`/tmp/os3d-qa25-live-corrected-final-20260911.xcresult`:21annotation tests,
7foundation tests,1real selection-afterExit/editor workflow. Separate focused1/1
and original28/29 retained. Only viewport/preference fixture changed, no product
source change. No runner. Freshpairednone/one/several/disconnected savedowners
verified. Native/clone scale, angle and input-method differences explicit above.

Illustrated852 unique images, all11newsourcehashesonce, zero841predecessorloss,
oneheading/onefinalverdict. Master38, onenewnote, zeroloss. Exports, manifests,
verificationJSON and testsummary/logs retained under durableQA25live directory.
FiniteQA25 PASS; inventory25/0/1/30. QA05freshnativechainnext. iPadunchanged.
