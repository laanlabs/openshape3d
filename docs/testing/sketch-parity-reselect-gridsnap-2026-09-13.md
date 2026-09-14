# Sketch parity — the three "tap-to-reselect" failures were grid snapping (2026-09-13)

Scope: the three DimensionUITests logged on 2026-09-13 as pre-existing
failures (testing/sketch-parity-badge-layout-2026-09-13.md), reported as
"tapping the line/rim does not reselect it" and "the centre drag moves less
than expected".

## What the recordings show

The result bundle of the attribution run (/tmp/os3d-qa29-attrib-20260913.xcresult)
carries a screen recording and the synthesized touch events per test. Frames
were pulled at the failure times and measured in window points (1032×1376
iPad window; the sketch was framed by Look at Sketch, where 0.5 mm ≈ 69 pt).

| Test | Intended geometry | Drawn geometry (measured) | Re-tap / drag | Outcome |
|---|---|---|---|---|
| LineDistanceTypeBadge… | line (361, 578) → (599, 853) | (376, 551) → (588, 825) | tap at the intended midpoint (480, 716) | 18.7 pt off the drawn line; pick tolerance is 16 pt → no selection |
| NearRailCircleDiameter… | centre (805, 894), r 69 | centre ≈ (786, 891), r 68 (Ø1 mm) | rim tap at (736, 894) computed from the intended centre | 17.7 pt from the drawn rim → no selection |
| ConnectedCircleGlyph… | centre drag +60, +30 pt | centre jumps +68, +0 at release | asserts Y moved > 20 pt | Y snapped back to the original row (0.22 mm rounds to 0) |

Grid snapping is on by default (AppSettings.snapToGrid) and the simulator's
persisted preferences match the defaults, so nothing about the device is
special: any touch-drawn point is quantised to the 0.5 mm grid, up to ~35 pt
at this zoom. The tests hard-code their re-tap and drag coordinates from the
pre-snap drag inputs. Live on the clone, a paced real tap on a bridge-seeded
sloped line reselects it after a Horizontal type switch, and a second tap
deselects — the reselect path itself is fine.

So these are test-geometry failures, not an app defect. Two earlier receipts
had met the same thing (sketch-parity-rectangles-2026-09-07: "temporarily
disables grid snapping for deterministic input coordinates";
sketch-parity-keypad-transitions-checkpoint-2026-09-11: "persisted Grid
snapping quantized the oblique circle-direction fixture").

## Change (9e4b2cc)

- The three tests launch with `-os3d.snapToGrid NO`, with the measurement in
  a comment. Guidepoint snapping, which the connected-circle test is about,
  is untouched (it switches those toggles on itself).
- AppSettings reads the snap/hint booleans through `storedBool`, which
  accepts launch-argument strings ("NO"/"YES"/"0"/"1") as well as stored
  Bools. Before this, `object(forKey:) as? Bool` dropped a string back to the
  default, so `-os3d.snapToGrid NO` would have done nothing (LineChainUITests
  passes YES, which coincides with the default). Unit test
  AppSettingsTests.testLaunchArgumentStringsOverrideSnapDefaults.

## Result

The three tests pass, one clean serial run on sim AC2FD923 (iPad Pro 13"):
/tmp/os3d-qa23-gridsnap-20260913.xcresult, 3/3, 166 s. AppSettingsTests
(new launch-argument case included) — see the register ledger for the gate
result bundle. No app behaviour changed: the app still snaps to the grid by
default; only launch-argument strings are now honoured for the snap and
hint booleans. The three cases are no longer open items under QA-29; the
"tap-to-reselect" investigation is closed with no defect found.
