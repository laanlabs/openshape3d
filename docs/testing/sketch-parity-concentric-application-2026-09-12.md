# QA-36 manual Concentric — September 12, 2026

## Paired partial checkpoint

Native separate circles center650640 R40 and740660 R30 merge at740660,
preserve both radii, and clear successful application selection. Exact outer/inner
radii inspected. Clone circles200700 diameter0.7457 and400730 diameter0.4944
merge at400730 but retain operands/gizmo. Native and changed clone apply, selected Undo/Redo and gallery reopen now pass.
Native inner R30 selected at740642; clone inner diameter0.4944 selected at400710
with Concentric visible in Items. LastSelected matched; the initial changed run
inherited FirstSelected from rail tests and correctly held the first center.
Undo restored the fixture before the matched repeat.

Before focused0/1 failed only four selection assertions. Application geometry,
radii, JSON and saved-lock refusal passed. Add Concentric to existing successful
application/history selection cleanup. Corrected focused1/1 passed. Final **88/88** passed in one serial run, zero
failures/skips (47application+18merge+6polish+10Trim+7rail UI), source2e84f84.
`/tmp/os3d-qa36-concentric-final-20260912.xcresult`. No runner.
Changed live verification and publication passed. Illustrated965 unique images,
ten new hashes exactly once, heading once and no955 predecessor loss. Master38,
heading once and no predecessor loss. Verification JSON and both DOCX exports
are retained in the evidence directory. No broader QA36 closure or iPad claim;
inventory26/0/1/29.

Evidence directory:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-concentric-live-2026-09-12/`.
Contains captures and before/focused test receipts. Native background Escape
was ineffective; foreground/no-auto-focus disarmed. Earlier placement attempts
were inconclusive; Exit/reenter plus settled blank state produced real circles.
No product conclusion drawn from input misses. Source geometry unchanged.


## Follow-up discovered, not yet applied

Native two-circle selection also exposes enabled Tangent in
`os3d-concentric-native-pair.png` (two edges, circumference sum439.823mm).
Clone `canApplyConstraint(.tangent)` currently requires one line and one radius
entity. This is a capability discrepancy to reproduce after Concentric is
checkpointed; no circle-circle Tangent application or solver result is claimed.
