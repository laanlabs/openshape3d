# QA-36 Tangent with a fixed circle — September 12, 2026

## Status

Source `2b89368` pushed. Final **87/87** passed in one serial run, zero failures
or skips (46 application, 18 merge, 6 polish, 10 Trim, 7 rail UI). No runner.
Changed-build paired history/reopen passed. Inventory26/0/1/29; QA36 remains partial.

## Native reference and confirmed clone defect

Native isolated circle center(850,660), R30mm, line(830,710) to(870,710),
length63.9544mm. Box selection did not establish reliable First/Last operand
order; those attempts are inconclusive, not anchor parity evidence. After Undo,
center Lock plus radius30 commit makes the circle fully defined. Tangent holds
the circle and rotates line endpointA to approximately(843,680), keeping
endpointB(870,710) and exact63.9544mm length. Apply clears selection. Native
locked-case Undo/Redo and gallery reopening preserve the fixed circle and
63.9544mm line. The reopened line value was inspected after Normal/Zoom settled.

Clone center(-0.5131351352,-2.514377594), center Lock + driving diameter
0.4946773052, line(-0.7598895431,-3.1285703182) to
(-0.2655923963,-3.1285700798), length0.4942971468. Application holds the circle
but moves the line to endpoints(-46.8478384556,-2.7621161379) and
(-42.5471617850,-2.7620790209), length4.3007. Read-only persisted JSON confirms
geometry; Undo restores the original line. An immediate post-Undo DB read was
stale while save completed; the later snapshot matches restored live geometry.

## Correction and regression

Application-only line-length and endpointB preferences stabilize the solve;
endpoint preference is released before length if saved relationships conflict.
The preference also runs when an incompatible preferred whole-line anchor must
be removed. No additional Lock/dimension is saved.

- Before0/1: seven assertions failed, reproducing movement/length loss.
- Initial focused2/3: one computed radius differed by4e-13; exact identity,
  locked center and history assertions retained, radius tolerance1e-9.
- Corrected focused3/3: free-circle matrix, fixed-circle line and lock/refusal.
- Expanded1/1: saved endpointA Lock overrides endpointB preference without
  losing line length, both operand orderings and exact history/JSON.
- Final combined87/87, zero fail/skip, source2b89368:
  `/tmp/os3d-qa36-tangent-reverse-final-20260912.xcresult`.
  This is one clean serial run, not an aggregate of targeted results.

## Evidence

Durable `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-tangent-reverse-live-2026-09-12/`
contains native/clone captures, original/applied JSON, focused/final summaries/logs.

Changed clone preserves circle center(300,700) and driving diameter0.4946773052;
lineA moves from(280,750) to approximately(293,721), endpointB(320,750) stays put,
and selected line length remains0.4943mm. Deliberately selected Undo/Redo clears
selection and restores each geometry state. Gallery reopen retains exact line
length plus Lock, Tangent and diameter in Items. Native and clone are separately
scaled fixtures, not equal absolute-size claims.

Publication verified: illustrated955 unique images, ten new hashes exactly once,
heading once, no loss from945; master38, heading once/no predecessor loss.
Export verification recorded in
`publication-verification.json` alongside both DOCX exports. No physical iPad update; immutable05be744
IPA untouched. Neither unconstrained selection order nor all tangent geometries
are claimed matched by this fixed-circle case.
