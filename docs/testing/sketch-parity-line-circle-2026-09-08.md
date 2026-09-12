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


## Follow-on acceptance at7400e01 (07:48 EDT)

QA-11 concentric initiation: both apps created a larger circle from the existing
center without moving inner circle or source line. Native inner200/outer420 mm;
clone inner1/outer2.236 mm. Circle tool armed, mouse drag, Top plane. This recipe
passes in the sampled input/layout; physical Pencil remains unverified.
`native-concentric.png`, `clone-concentric.png`.

QA-10 partial construction cancellation: native three-point first-point/baseline
preview and subsequent perpendicular-height preview cancelled with Escape;
clone explicit Cancel Rectangle works after first point and after baseline while
height is pending. No new rectangle remains, old line/circles stay unchanged.
Native hover previews are available on macOS; clone simulated mouse did not
produce equivalent displaced hover. This is state/geometry cancellation evidence,
not identical hover or keyboard-input parity.
`native-rectangle-first-preview.png`, `native-rectangle-after-deselect.png`,
`native-rectangle-height-hover.png`, `native-rectangle-height-cancel.png`,
`clone-rectangle-first-point.png`, `clone-rectangle-first-cancel.png`,
`clone-rectangle-baseline-preview.png`, `clone-rectangle-baseline-cancel-settled.png`.

Evidence caution: immediate captures sometimes show the previous Metal frame
while the status controls already update. Settled app capture and full-desktop
capture confirmed the clone baseline disappeared without another viewport input.
Use an explicit1–2second settle interval, recapture before assigning failure.
Full-screen capture still returns failure while saving inspectable artifact.
No source renderer/cancellation patch inferred from the intermediate frame.

History remained unchanged after held-touch input and a separate toolbar click
with2second settle (`clone-undo-settled.png`). An additional viewport blank tap
also retained geometry. Keep live history blocked; do not promote XCTest results.
No new regression run for these unchanged acceptance cases; previous4/4 circle
run remains the latest focused run, not a full core suite.
Concentric/cancellation publication verified:52 inline images, follow-on text and
all six new image hashes matched in published-cancellation.docx; receipt
cancellation-publication.json.
