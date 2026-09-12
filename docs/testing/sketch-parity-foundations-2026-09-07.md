# Sketch parity foundations — verification receipt

## Baseline and environment

- Original source: `88b0478d873ffc5efe71f086f84f529b6ca032a4`.
- Branch: `fix/sketch-parity-foundations` (separate worktree; original checkout unchanged).
- Xcode developer directory: `/Applications/Xcode.app/Contents/Developer`.
- iOS 26.5 simulator, iPad Pro 13-inch (M5), portrait; new isolated device `os3d-parity-sept7`.
- Test execution is serial (`-parallel-testing-enabled NO`). Tests do not reset existing user simulator documents.

## Final result

**PASS — 40 unit tests + 7 UI tests, 0 failures, 0 expected failures.**

Final combined `xcodebuild test` exited 0 on 2026-09-07 at 06:21 EDT, reporting `TEST SUCCEEDED`. Test-operation elapsed time: 230.105 seconds. Local detailed result bundle: `/tmp/os3d-parity-final.xcresult`; log: `/tmp/os3d-parity-final.log`. No runtime source changes followed this run; only the receipt/status text was finalized.

## Covered behavior

- Model-mode sketch-outline selection recovers a dimension, whose badge re-enters its owning sketch and opens the editor.
- Line length / circle diameter edits drive geometry; undo remains available.
- Drawing a polygon and ellipse, undoing/redoing, then selecting a profile interior still opens extrusion.
- Changing drawing tools dismisses the old keypad and permits a second shape.
- Toggling the active tool off dismisses its keypad; reopening a rectangle's dimension and exiting sketch mode also dismisses it.
- Four snapping switches can be disabled, survive app relaunch, and be restored through the UI.
- Pure selection policy filters unrelated annotations and point roles, retains explicitly selected glyphs, and honors Always Show.
- Pure ray picking selects nearer outlines, skips hidden sketches and honors occluders; a profile interior is not an outline hit.
- Pure snapping tests preserve default endpoint/midpoint/face priorities, honor category switches, preserve the raw point when all snapping is off, and avoid along-edge quantization when grid snapping is off.
- AppSettings persists explicit off values.

## Failures found and resolved during verification

- Existing profile test expected `RedoButton`; the app exposed only label “Redo.” Added the identifier alongside `UndoButton`.
- XCTest's automatic hittable-point fallback for a compact rectangle badge chose a padded corner that deselected geometry. Added 44-point badge hit regions; the regression explicitly taps the visible badge center and verifies editor entry.
- SwiftUI Form switch accessibility includes the entire row; tests tap the switch track, scroll it into view, allow scroll settling, and await the changed value rather than assuming a synchronous accessibility update.
- Opening a dimension from model mode enters sketch mode **without** arming a drawing tool. Its status reads “Drag to orbit — pick a tool to draw,” not “Sketching on ground plane.” The test now checks `Exit Sketching` and the open dimension field instead of an incorrect tool-specific status string.

## Reproduction

Choose an isolated iPad simulator destination and run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project openshape3d.xcodeproj -scheme openshape3d \
  -destination 'platform=iOS Simulator,name=os3d-parity-sept7' \
  -derivedDataPath /tmp/os3d-parity-derived \
  -parallel-testing-enabled NO \
  -only-testing:openshape3dTests/SketchParityFoundationTests \
  -only-testing:openshape3dTests/SnapKindTests \
  -only-testing:openshape3dTests/FaceSnapTests \
  -only-testing:openshape3dTests/AppSettingsTests \
  -only-testing:openshape3dUITests/DimensionUITests \
  -only-testing:openshape3dUITests/TwoShapeReproUITests \
  -only-testing:openshape3dUITests/SketchToolsUITests \
  -only-testing:openshape3dUITests/SettingsUITests/testSnappingControlsPersistAcrossLaunch
```

## Not covered / not claimed

This is not a full UI-suite run, a real-device or Apple Pencil sign-off, the complete portrait/landscape matrix, or execution of all 56 audit acceptance scenarios. The legacy persistence-backed `SketchAnnotationVisibilityTests` expectation was corrected but that suite was not included; new policy tests use pure values, not `ModelContainer` or `DocumentSession`.

SK-05 remains partial (no independently configurable sketch guidelines or off-plane 3D guidepoints); DM-12 remains a partial transition-matrix verification. The complete remaining queue is in [the implementation ledger](../SKETCH_PARITY_IMPLEMENTATION.md).
