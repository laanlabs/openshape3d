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

## Initial combined failure and scope correction

Sourceee329b1 first combined gate118/120: all109model and9UI pass, fresh and
connected armed-circle UI fail only post-drag readout access. This was an
over-broad source correction, not stale assertions: it altered armed Circle's
previously verified creation readout. Restricted point-only branch to disarmed
mode, matching the observed native Disconnect workflow. UI assertions unchanged.
Scoped center model +both failed UI rerun active at
/tmp/os3d-qa38-center-scoped-20260912.{log,xcresult}. Final corrected combined
and changed live still pending. First combined receipt retained.

Scoped correction passes3/3, zero failures/skips, including both unchanged armed-circle UI assertions. Corrected combined120 next.

Final corrected120/120 passed in one serial run on03b9e1c, zero failures/skips (109model+11UI). No runner. Changed live next.

## Changed-build paired verification

On03b9e1c, disarmed selected-center drag220315 moves only the circle, keeps
point-only selection without dimension/gizmo, and preserves line250315→350350.
Two Undo restore movement then explicit center/endpointA Coincident (saved JSON
confirmed); two Redo restore detach then movement. Gallery reopen retains
Ø0.6168mm and detached center220315. Native two Undo restore center500550 then
connection with Disconnect enabled; two Redo restore detach then center470550.
Native gallery reopen retains detached circle and fixed line; selected rim
confirms R18000mm. Reopened screen coordinates recentered to563523/589523.
The initial Coincident placement/selection discrepancy remains separate: clone
averages both points despite First Selected; native holds circle and moves line.
No claim of initial application-anchor or annotation-layout parity.
Publication pending; reports remain1138/master38. No runner.

## Publication verified

Illustrated1146 unique placements, all eight new source hashes exactly once,
heading once and zero loss from1138 predecessor. Master38 unchanged media,
checkpoint heading once and zero loss. Durable directory contains before/after
DOCX, publication-assets.json and publication-verification.json, paired PNG/actions
and clone restored-sketch JSON. QA38 remains partial27/0/1/28.
