# Point-touch profiles — September 9

Baseline 682e1bf. No competing test/build worker. Native Sketch03 first loop
approximately (900,580)-(976,580)-(980,630)-(900,630); second loop shares only
(980,630), extending to (1037,690). First loop slightly trapezoidal after native
snapping: topology comparison, not identical rectangular dimensions.
Native Exit and separate interior taps (940,605), (1010,660) each select one
face, leaving the other unselected. Captures native-first/second-profile.

Clone explicitly made Sketch2 visible, entered via icon at (487,275), drew
(150,200)-(210,200)-(210,260)-(150,260) and second loop sharing (210,260),
extending to (250,300). Exit and separate interiors (180,230)/(230,280)
each open Extrude for only the selected loop. Captures clone-first/second-profile.
Existing bore/block retained. No implementation change or new test run.
Paired persistence and publication pending; next partial straight overlap.
All os3d-point-touch-* PNGs retained in durable transform-controls reports.

## Partial overlap

Native added top-edge interior segment (920,580)→(950,580); profile remains
selectable. Clone attempted (170,200)→(190,200), but snapped second endpoint
to existing (210,200); shorter coincident segment still preserves profile.
No identical endpoint/scale claim. Two precise geometry tests added for point
touch, interior/corner-ending partial overlap and both directions. Serial42414
owns simulator; /tmp/os3d-point-partial-20260909.log/.xcresult. Publication
prose inserted; images/export and final reopen pending.

## Final verification

Serial42414 completed0: clean2/2 targeted geometry checks. No production code
change. Clone relaunch/gallery reopen and native gallery reopen both retain
touching loops and earlier bore/block. The partially overlapped first loop
remains independently selectable in each. Reopen snapshots inspected after
settling; native trial prompt dismissed via inspected Skip action, no purchase.

Illustrated173 placements/172 unique assets; six comparison plus two final
reopen PNG hashes verified in DOCX exports. Master38 retains final2/2 and
reopen note; referenced images are in illustrated Doc. All evidence/exports
retained in durable transform-controls reports. Remaining tiny thresholds,
duplicate curves, crossing variants and downstream/device acceptance open.
