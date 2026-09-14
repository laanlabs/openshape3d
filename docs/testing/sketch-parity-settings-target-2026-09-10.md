# Settings icon-center input — September 10

Baseline7532ae9. Repeated live portrait clone Settings gear center701148 did
nothing; offset710148 opened sheet. Same discrepancy previously observed in
landscape at905148 versus914148. Latest screenshots:
`/tmp/os3d-settings-center-miss.png`, `/tmp/os3d-settings-offset-open.png`.
Native constraint-settings gear center1362439 opens its panel:
`/tmp/os3d-settings-native-center.png`. This is a control-center interaction
comparison, not a claim the different settings panels are equivalent.

Implemented explicit44pt clear hit surface/rectangular content shape, following
existing Undo/Redo buttons. New center-target portrait/landscape UI test plus
imperial keypad settings/commit/Undo workflow running. Live corrected comparison
and publication pending; no product verification claimed yet.

First run: imperial workflow passed; center-target test stopped before tapping
on a fixture assertion assuming44pt external height. UIKit reports36pt toolbar
height despite44pt content. Removed that unsupported assertion; horizontal44pt
and actual center opening checks retained. Targeted rerun owns simulator:
`/tmp/os3d-settings-target-followup-20260910.xcresult`, exec6678. No second
product change. Diagnosis3images inserted once, export pending.

## Live and publication verification

Targeted center test passed both orientations1/1. Initial imperial workflow1pass
plus targeted1pass, not one combined clean run. Exact-build live visible gear
center now opens in portrait model/sketch and landscape sketch states. New
portrait center697148 and landscape901148 account for the resized button;
no offset workaround used. One capture during rotation rejected changed window
bounds; window list confirmed887x736 at72,30, then capture recovered. This is
capture routing/animation, not an app failure.

Illustrated396 placements, all5new hashes exactly once/no predecessor loss;
`/tmp/os3d-settings-target-publication.docx`. Master38/newprior/reopen note
verified, `/tmp/os3d-settings-target-master.docx`. Local images/SHA256SUMS in
reports/.../settings-target. No runner. Subsequent same-theme audit changed
clone Settings Theme fromSystem(darkhost) toLight throughUI; intentional test
preference, not productdefaultchange. ImmutableIPA unchanged.
