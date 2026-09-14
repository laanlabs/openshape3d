# Opening a drawing on the iPad: where the seconds went (2026-09-13)

Jason's report, on the paired iPad (Laan iPad Pro 11-inch 3rd gen,
iPadOS 26.6.2, Debug build): "clicking any drawing takes a second or two
to open". The build on the iPad at the time had been made from the main
checkout at 20:59 that evening (main = 88b0478, unchanged since Sept 6),
so the cost was already in main.

## Measurement

Instruments could not attach (`xctrace` timed out waiting for the device;
the iPad was locked). The open path was instrumented instead with
wall-clock marks (`OpenTiming`, DEBUG-only, printed only when
`OS3D_OPEN_TIMING` is set) and read over
`devicectl device process launch --console` with `OS3D_AUTO_OPEN=1`, which
opens the first drawing in the gallery — a 1-body, 1-sketch, 13-feature
document of Jason's.

Before (branch at 3af1dd2 plus the marks; two consecutive opens):

| mark | open 1 | open 2 |
|---|---|---|
| destination requested | 0 ms | 0 ms |
| editor task start | 33 | 24 |
| load start | 37 | 24 |
| 1 body decoded (mesh, brep) | 115 | 106 |
| 1 sketch decoded | 118 | 107 |
| planes/axes/images/symbols | 118 | 107 |
| 13 features decoded, load done | 129 | 116 |
| **view model built** | **5863** | **5796** |
| render context ready | 6077 | |
| renderer + scene built | 6078 | |
| viewport attached | 6078 | |
| first draw | 6192 | |

Loading the document is 130 ms. The 5.7 s between "load done" and "view
model built" is `DocumentSession.load()`'s last step,
`refreshEvalErrors()`: it replays the WHOLE feature graph through the
kernel against an EMPTY memo, purely to compute the error badges for a
reopened document (review R4-N6, on main since 069be64 / 6ba87d2,
2026-08-31), and then throws the replay away. On the iPad in Debug that
is 13 features through OCCT, every open.

## Fix

`scheduleLoadEvalRefresh()` (DocumentSession): the load-time replay runs
detached on value copies of the graph, sketches, planes and naming
strategy — the pattern the boolean CSG already uses — and only its error
map is adopted, on the main actor, and only if the document has not
changed meanwhile (an edit's own rebuild has fresher errors). The scratch
memo is not adopted: its revision stamps come from a scratch counter, not
the document's, so the first live rebuild still warms the memo itself
(that first edit keeps today's cost; a follow-up could warm the memo with
the live counter). Undo/redo keep the synchronous refresh: against the
live memo it is a memo hit for unchanged nodes.

After (same device, same document):

Not yet captured: the iPad auto-locked before the fixed build (7b80282,
installed) could be launched, and a locked iPad denies every launch. To
capture, unlock it and run

```
xcrun devicectl device process launch --console --terminate-existing \
  --environment-variables '{"OS3D_AUTO_OPEN":"1","OS3D_OPEN_TIMING":"1"}' \
  --device 085ACF4B-5DED-50D5-9C77-0FC425B50F2B com.laan.labs.openshape3d
```

Expected: "view model built" within ~30 ms of "load done" (the replay no
longer sits between them) and the first draw near 0.5 s instead of 6.2 s;
the badge refresh lands a few seconds later without blocking anything.

## Also fixed while measuring

The final-state full-suite re-run (/tmp/os3d-full-suite2-20260913.xcresult,
185 executed, 4 skipped, 3 failures, 113 min) surfaced:

- PlanesUITests.testSketchOnFaceThenExtrudeNewBody: my screen-space edge
  target (b4a1bb0) has no depth — perspective draws a box's hidden bottom
  edge inward under its top face, and a tap on the face 0.47 mm inside its
  edge lay 3.8 pt from that hidden edge's projection, so it armed Fillet.
  The edge target is world-unit again (5 pt at the camera scale, sharp
  dihedrals, flat faces only); unit test
  SelectionTests.testTapOnATopFaceAboveAHiddenBottomEdgeIsTheFace.
- RectangleWorkflowUITests.testRectangleCenterDragTranslatesWithoutOrbitAndRestoresHistory:
  a 60 pt centre drag captured to the 0.5 mm grid (67.5 pt) once the
  defaults reset stopped a leaked "grid off" from masking it; the test
  launches without grid snapping (it is about translate-not-orbit).
- BugReportUITests.testBugReportSheetOpensValidatesAndCancels: the title
  field left the realised rows after the test's swipe; the summary is now
  typed before scrolling.

Gate: /tmp/os3d-gate3-20260913.xcresult — SelectionTests 14/14; PlanesUITests 6/6, CylinderGrowShotUITests 1/1, BlendUITests 4/4, BugReportUITests 1/1, RectangleWorkflow centre drag 1/1 (7b80282, 3985340, 2dc2dfc).
