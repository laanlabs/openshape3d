# Line cancellation and circle release — September 8, 2026

## Context

Dedicated desktop owner; native macOS Shapr3D vs portrait iPad Simulator
AC2FD923-1661-435F-BF47-3E9DF30D1A16, mouse via Peekaboo. Top/ground sketches.
Base `0e02425`; circle-only source correction under test. Native existing disposable
audit sketch, clone disposable project. Different zoom/units displayed; compare
interaction semantics and saved coordinates rather than screen-scale equality.
Evidence root:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/line-cancel/`.

## Line release/cancellation (QA-05/06; partial/blocked)

- Native horizontal drag leaves 338.4817 mm committed segment. Click endpoint,
  move pointer: temporary vertical next-segment preview. Escape removes that
  preview, leaving horizontal geometry and Line armed. `native-drag-release.png`,
  `native-chain-preview.png`, `native-chain-escape.png`.
- Clone horizontal drag leaves 3 mm committed segment. Endpoint click/move
  leaves 0 mm marker, no displaced hover preview. Escape and double-click show
  no visible change: `clone-drag-release.png`, `clone-chain-preview.png`,
  `clone-chain-escape.png`, `clone-double-finish.png`.
- Simulator Hardware Keyboard is checked. Separate Send Keyboard Input to Device
  capture was enabled, tested, then returned to its original off state. Escape,
  Cmd-Z and C hotkeys still have no observed effect; tool-palette Circle click
  works. No security/permission/service changes. Missing ordinary-sketch Escape
  binding found in source, but input delivery also unresolved: no speculative
  cancellation or Undo patch, no live history/cancel sign-off.
- Manual and OS3D_FRESH project creation both call createProject; the gallery
  route hypothesis does not establish a source defect. Preserve prior clean
  automated history receipts separately from this live blocker.

## Circle initiation and release (QA-12/18)

- Native Circle starts at left endpoint of committed line (relative1100,600),
  preserves the line and center, displays diameter420 mm without keypad on
  release. Explicit diameter click opens keypad. `native-circle-endpoint.png`,
  `native-circle-keypad.png`.
- Clone Circle starts at corresponding line endpoint (relative221,335),
  preserves the 3 mm line and center, but auto-opens diameter2.236 input.
  `clone-circle-endpoint.png`. This is a confirmed release-behavior discrepancy,
  distinct from the unresolved keyboard/history delivery issue.
- Correction: retain circle selection/diameter badge, do not call
  beginDimensionForSelection on release. Rectangles unchanged; polygon automatic
  input intentionally unchanged pending its own reference check.
- Existing diameter-driving test now asserts no automatic keypad, then explicitly
  opens badge and drives diameter10/radius5. Circle-at-rectangle-corner test now
  asserts diameter readout, no auto editor, and explicit usable commit.

## Verification/publication state

Serial dimension and circle-at-corner UI run: clean4/4 passed, no reruns,
`/tmp/os3d-milestone-circle-20260908.xcresult`; archived circle-test-summary.json.
Tested simulator binary SHA256
`9285e5857dbe2b2afbc00a3989bddeac5634e716fa9016357a4372b10e9247b2`.

Post-fix live fresh Untitled2 Top sketch: horizontal3 mm line then circle from
left endpoint. Diameter2.236 badge remains without keypad; explicit badge click
opens it, first digit1 replaces seed, commit drives diameter1/radius0.5. Center
(relative221,335) and line endpoints remain fixed. Native explicit edit420→200 mm
also preserves center(relative1100,600) and line endpoints. This is a paired
semantic check at different scales, not equal-size overlays.
`clone-circle-release-fixed.png`, `clone-circle-keypad-fixed.png`,
`clone-circle-diameter1.png`, `native-circle-diameter200.png`.

Diagnosis text/two images verified via anonymous DOCX export:43 inline images,
exact hashes matched. Corrected-result publication verified:46 inline images, corrected text and all
three new PNG hashes found in anonymous DOCX export (published-circle-fixed.docx,
circle-fixed-publication.json). No candidate gate
claim. Prior active-plane fix/publication remains complete at0e02425.
