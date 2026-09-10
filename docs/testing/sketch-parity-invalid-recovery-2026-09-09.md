# QA-33 / QA-40 closure batch — September 9, 2026

Baseline a40c22c; product runtime 05be744. The exported 05be744 IPA is immutable
and is not overwritten by acceptance work. Handoff is not milestone completion.

## Finite closure criteria

- QA-33: in each app, zero and negative linear sizes, malformed expression and
  division by zero must not silently commit geometry or a driving value. Record
  exact warning, editor dismissal/retention and recovery with a valid value.
  One Undo must restore the pre-valid-edit shape, with no invalid history step.
- QA-40: explicitly compare Escape, blank click, tool switch and system-keyboard
  commit/cancel; verify no orphan editor or hidden canvas interception. Repeat
  edge-adjacent editor in portrait/landscape. Unsupported desktop/Pencil routes
  remain separately blocked, not inferred from unit results.
- Known mismatch carried forward: native inline warning versus clone modal error.
  No product correction claimed before a current paired recheck.

## Recovery and execution

No prior runner active. Peekaboo image window/screen/background routes report
`Web-focus detection returned without its required mutation outcome`. Existing
Peekaboo GUI bridge is healthy with accessibility, posting and screen grants;
`see` works for native1924 and clone6492. Explicit app switch preceded successful
native Sketch02 entry. Error is capture/input routing, not a product failure.
Snapshots /tmp/os3d-resume-native.png, /tmp/os3d-resume-clone.png and
/tmp/os3d-numeric-native-entry.png inspected. Native remains dense Sketch02;
new invalid numeric interaction not yet performed.

Added a bounded regression to DimensionKeypadCommitTests: six invalid strings,
unchanged geometry/dimensions, valid25 recovery, then exactly two Undo actions
restore the original and remove its construction. Product source unchanged.
Serial run completed clean1/1 (six inputs in one test): /tmp/os3d-invalid-recovery-20260909.xcresult,
log /tmp/os3d-invalid-recovery-20260909.log. Live UI work paused during run; no runner remains.
No new case pass, no publication claim yet.

## Read-only device eligibility

Paired iPad Pro11-inch (3rd generation), iPadOS26.6.1, Developer Mode enabled.
Its UDID matches a device entry in the preserved development profile. Eligibility
only: no installation, no physical touch/Pencil validation, no profile mutation.

## Current paired zero refusal

Native fresh line29.0517mm: zero commit closes keypad, restores original readout
and presents nonmodal “Distance between points must be a non zero value.”
Screenshot /tmp/os3d-numeric-native-zero.png. Clone fresh line2mm: zero commit
closes keypad, preserves2mm and presents blocking Something Went Wrong alert
with “Dimension must be greater than zero.” /tmp/os3d-numeric-clone-zero.png.
Different viewport/zoom and displayed lengths; this is warning behavior evidence,
not equal-scale typography acceptance.

Input recovery: foreground click of exposed simulator title at190,55 selects
correct6492; previous380,65 was covered by old simulator5147. New sketch entry
was repeated after an animation-time click exited the first empty sketch. Only
settled second construction is used as evidence.

Implemented dimension parse/range refusals via existing transient notice; solver
conflicts remain unchanged. Expanded test asserts notice, no modal, closed editor,
unchanged geometry/history and valid recovery. Serial DimensionKeypadCommitTests
run /tmp/os3d-numeric-notice-20260909.xcresult owns simulator (exec62721).
Live post-fix and publication pending.

## Post-fix result

Clean8/8 DimensionKeypadCommitTests; no failures/skips. No runner remains.
Live fresh Front-plane clone line2mm rejects0 via nonmodal notice, closes keypad
and preserves2mm. Reopening and committing1mm works; one toolbar Undo restores2mm.
Native zero→valid20mm recovery also succeeds; Cmd+Z restores original150px line
length (from103px at20mm). An initial presumed Undo coordinate hit camera-quarter-
turn instead; that screenshot is excluded as history proof. Actual Cmd+Z screenshot
shows Undo notice and restored geometry. Native clears readout after Undo whereas
clone retains it; no blanket lifecycle parity claim. Native Top vs clone Front are
recorded; numeric behavior compared, not equal-viewport style.

Seven screenshots retained under reports/openshape3d-core-sketch-milestone-2026-09-08/
numeric-recovery with SHA256SUMS.txt. Publication pending. Warning icon/style still
differs. Negative/malformed native comparisons and QA40 matrix remain open.

## Expression lifecycle distinction — next correction

Native -1 rejects with “Negative values aren't accepted”, closes keypad, restores
29.0517mm. Native1/0 and2+ instead keep the keypad/text open with yellow inline
warning and specific divide-by-zero/syntax messages. Draft screenshots inspected.
Clone2+ current transient-notice implementation still dismissed keypad; confirmed
/tmp/os3d-numeric-clone-mal-result.png. Moved editing-state dismissal after parse
validation so malformed expressions remain editable. Range rejections still close.
Test recovery now uses the retained editor, reopening only for0/-1. Inline-warning
style and specific parser messages remain unmatched. Serial8unit+click-away/tool-
switch UI run active: /tmp/os3d-numeric-retention-20260909.xcresult (exec70335).
Native negative/division/syntax evidence at /tmp/os3d-numeric-native-negative.png,
/tmp/os3d-numeric-native-div-result.png, /tmp/os3d-numeric-native-mal-result.png.

Retention run completed clean9/9 (8unit+1UI). Live corrected clone retains2+
and allows adding1 in the same editor to commit3mm. Screenshots os3d-retain-result
and os3d-retain-recovery retained. Top-canvas notice vs native field-anchored
yellow warning remains a visible gap. Initial zero publication export verified
270placements, all5 added hashes once, dated heading once; export
/tmp/os3d-numeric-publication.docx. Expression screenshots/addendum and master
note pending. No full acceptance row closed.
