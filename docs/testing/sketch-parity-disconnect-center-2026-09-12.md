# QA38 circle-center Disconnect — September 12, 2026

Partial, baseline db56d29/source96b1368. Native R18000 circle500550 and line
500650→600650; narrow left-to-right box485535→515665 selects center+endpoint.
Coincident joins endpoint at500550 without moving circle (FirstSelected).
Disconnect leaves geometry unchanged. Next center click exposes Circle Center/
Endpoint chooser; explicit Circle Center then drag→470550 moves only circle.
Original line500550→600650 unchanged, radius visually unchanged. History/reopen
still pending. Failed initial drag only dismissed the overlapping-point chooser;
it is not a geometry failure. Invalid --keys CLI attempt executed no key input.

Clone Ø0.6168 circle250280, line250350→350350. Explicit center+endpoint
Coincident moves both to250315 and retains selection/zero readout; initial
application anchor/selection differs and is separately unresolved, not part of
this Disconnect correction. After deselect/reselect center, Disconnect removes
connection without movement. Center drag→220315 moves only circle, diameter
0.6168 unchanged, line250315→350350 fixed, but promotes whole-circle selection,
dimension and transform controls. Native stays point-only.

Before regression0/1 fails only whole-circle selection assertion; independent
geometry, radius dimension, exact two-step history and JSON pass. Scoped source
correction retains point-only for an already-selected circle center during
beginSketchEntityDrag; unselected/body drag, solver and storage unchanged.
Focused3/3 passed, zero failures/skips: center, prior endpoint and connection breadth.
/tmp/os3d-qa38-center-{before,focused}-20260912.{log,xcresult}. Changed-build
live/history/reopen and publication pending. No acceptance promotion.
Durable disconnect/qa38-center-live-2026-09-12 holds current PNG/actions.
Reports1138/master38; QA38partial27/0/1/28; immutable05be744/iPad unchanged.
