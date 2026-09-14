# Near-rail circle diameter annotation — September 9, 2026

Baseline ebffe23. Native Front existing circle Ø2000 moved +4000 mm using
inspected exact X entry: center919534→1063534. Escape accepts; blank/reselect
restores vertical outside diameter leader, text1078 clear of rail1096. Left-rim
reselection retains layout. Native new-circle and radial drag attempts did not
mutate geometry; excluded. M keyboard did not arm transform; menu worked.

Clone portrait Front driven circle Ø1 moved +0.8 mm using inspected exact X entry:
center450650→515650. Done restores constraint rail. Horizontal diameter text at
535638 reaches rail548; its 44pt target partly lies behind the rail. Native and
clone dimensions/scales differ; placement semantics compared, not equal units.
Native original release horizontal vs later vertical reselection is retained in
prior diameter receipt; this correction only addresses edge obstruction, not
full automatic/manual annotation-orientation parity.

Implemented screen-space edge fallback: preserve existing horizontal layout
when full target fits; otherwise outside vertical diameter leader, text inward,
roomier vertical extension, target contained inside palette/rail/header margins.
Rotated label receives a matching 44pt-wide vertical target, rather than leaving
an unrotated wide hit region under chrome. No document/solver change.

Serial99295 /tmp/os3d-diameter-edge-20260909.log and .xcresult owns simulator.
Two layout tests cover ordinary/transform clearance and side/top/bottom edge
containment; circle/arc edit/history UI regressions supplement live comparison.
No test pass or post-fix live claim yet. Publication pending; original screenshots
retained locally under transform-controls. Full visual/device gate remains open.

Initial regression clean4/4 (two layout + circle/arc UI) completed successfully.
Serial13192 now owns simulator for the added near-rail painted-target edit/history
check: /tmp/os3d-diameter-edge-target-20260909.log/.xcresult. No live post-fix claim.

Focused13192 passed clean1/1. Live fresh Front circle515650/Ø0.992 now has
vertical outside label501518 clear of rail548 and radial515592. Painted label
opens full keypad; typed1 commits Ø1. Undo0.992/Redo1; gallery reopen and sketch
reselection retains Ø1/edge layout. Initial drag used element flags with numeric
coordinates and failed before mutation; corrected --from-coords/--to-coords valid.
Native near-rail label1078389 also opens keypad. Close comparison shows native
outside arrows beyond rims vs clone inward arrows; final outside arrow/text
reading-direction correction added, requiring final targeted regression/live.
Initial4/4+target1/1 remain earlier revision passes, not final correction signoff.
Illustrated114 images/two diagnosis hashes verified. Post-fix images pending.

Native accepted Escape/Exit Sketch/Home/reopen retains Ø2000, refittedcenter947517.
First Cmd2 after trial dismissal ignored; repeated Cmd2 aligned Front. Final
outside leader includes outward arrow bodies and native top-to-bottom text.
Code review additionally guards fallback to head-on (<0.5degree) projection:
oblique circles must retain their real projected rim points, not inferred
screen-vertical radius. Oblique edge layout remains outside this scoped signoff.
Serial80274 tests pre-guard refinement; latest guard needs following regression.

80274 clean4/4. Latest guard now in serial93433 layout3 + near-railUI1 run.

93433 failed at compilation (SketchID passed to UUID helper parameter), no tests
ran. Corrected helper parameter to SketchID; next run is guard2, not a clean
first-attempt claim.

Guard2: three layout tests passed; near-rail UI failed because Top camera is
intentionally clamped at89degrees, one degree off normal. The0.5degree guard
incorrectly disabled fallback in standard Top. Adjusted to1.1degrees matching
existing camera elevation limit (source Camera.swift27); not arbitrary oblique
coverage. Guard3 rerun follows, preserving guard2 failure in history.

Guard3 final run clean4/4 (three layout + near-rail editor/history UI). Live
post-final-build gallery open/Top sketch/reselect retains Ø1; outside arrows
now lie beyond rims and text reads top-to-bottom as native. Painted relocated
label500487 opens full keypad. This final Top sample is the test-created saved
circle, explicitly reopened/operated via Peekaboo; earlier Front sample was
fresh manual creation. No final manual-creation claim for Top. Front native
reference and earlier fresh Front live edit/history/reopen remain above.

Final publication verified: illustrated116 embedded images, all four new PNG
SHA256 hashes match export; master38 and final gallery-reopen note verified.
Exports retained under transform-controls. Final Escape closes keypad/keepsØ1.
Simulator debug dylib SHA256:
00855795064de92f0c72066d929ddb57a71a296e25b5eddd3f84dbfbe2764a7a.
No runner remains; native1924 Frontcircle947517Ø2000 selected, clone5147 Top
circle514620Ø1 selected. Continue normal reselection/manual label placement.
