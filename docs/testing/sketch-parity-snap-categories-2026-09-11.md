# Sketch parity — snap categories (September 11, 2026)

## Scope and status

QA-19 asks whether Grid, Sketch Guide Lines, Sketch Guidepoints, Face Guidepoints,
and Snapping Hints can be controlled independently and whether acquisition is
truly free when the acquisition categories are off. This checkpoint remains
**partial** pending one clean native 3D-Guide-Points on/off near-threshold repeat.
It does not close QA-20 zoom or QA-21 hover/feedback.

## Existing paired evidence retained

- `sketch-parity-snap-lock-2026-09-08.md`: paired all-acquisition-off free input,
  Grid-only input, Guide-Lines-only input, and settings persistence.
- `sketch-parity-preplacement-snap-2026-09-08.md`: paired Sketch Guidepoint
  near/far acquisition at two clone scales.
- `sketch-parity-drawing-on-points-2026-09-11.md`: paired exact top-face-corner
  circle placement, Undo/Redo, and clone reopen.

## Confirmed interaction defect and correction

The first expanded settings regression exposed a reproducible defect limited to
Snapping Hints: its row was reported hittable, but tap, label tap, and swipe did
not change the value. The other four settings had already persisted off. The
last row now uses an explicit trailing switch inside the unchanged visual row.
This gives the control its rendered 44-point switch target instead of the full
Form-row accessibility frame. The settings test also includes the previously
omitted Sketch Guide Lines toggle and uses a finite reveal helper.

Exact-build Peekaboo verification toggled Snapping Hints off and Face Guidepoints
off independently. A seeded top-face sketch then showed a raw, visibly displaced
circle centre with Grid and Face Guidepoints both off. Face Guidepoints could be
restored without changing the other stored categories. A controlled repeated
near-threshold on/off gesture was outside the screen-space tolerance after
Simulator coordinate quantization, so it is retained as inconclusive rather
than claimed as a live snap distinction.

## Regression history

- `/tmp/os3d-qa19-category-matrix-20260911.xcresult`: 20/21; initial expanded
  run failed only at the nonresponsive Hints switch.
- `/tmp/os3d-qa19-settings-center-taps-20260911.xcresult`,
  `/tmp/os3d-qa19-settings-frame-diag2-20260911.xcresult`,
  `/tmp/os3d-qa19-settings-trailing-switch-20260911.xcresult`, and
  `/tmp/os3d-qa19-settings-switch-swipes-20260911.xcresult`: retained failed
  interaction diagnostics; no product pass is inferred from them.
- `/tmp/os3d-qa19-settings-h-row3-20260911.xcresult`: corrected targeted 1/1.
- `/tmp/os3d-qa19-category-matrix-final-20260911.xcresult`: final clean **21/21**
  in one serial run: 20 AppSettings/Foundation/LineGuide tests plus the five-row
  settings persistence workflow.

## Evidence

Local evidence and exact hashes:
`~/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/snap-categories/`.
Publication is pending and must be hash/export verified before counting.

## Remaining closure step

Repeat one near-threshold top-face-corner gesture in native Shapr3D with Grid
off and 3D Guide Points off/on, then the same calibrated gesture in the clone.
If both pairs distinguish raw versus acquired placement and the report is
published without duplicate images, QA-19 can close. Physical Pencil input
remains QA-52 and is not inferred from Simulator evidence.

### September 11 input-delivery retry

The native retry correctly restored Circle through Shapr3D's More menu, with
Grid, Auto-constraining, and 3D Guide Points off. The first attempts did not
reach the canvas because a transient macOS Automation-permission dialog from a
diagnostic `System Events` query was frontmost. Its notification process was
dismissed without granting or changing the permission; Shapr3D then became the
reported frontmost application again. Despite that recovery, Peekaboo click,
drag, and swipe routes still produced no canvas mutation at either the intended
near-corner point or an obvious face-interior diagnostic point. Toolbar actions
continued to work through accessibility.

This is retained as a native input-delivery blocker, not an application failure
and not snap-category evidence. No synthetic placement is counted. QA-19 stays
partial while independent finite acceptance work continues.


### September11 evening — recovered input, first threshold pair inconclusive

After QA05 closure3c2538b, native Circle input works using global bridge drags.
Body04 face entry created provisional Sketch10 on a side face, not the intended
top face; no top-face acceptance is claimed. All acquisition categories were
visibly off (Hints on), and a circle aimed6px right/6px above the visible vertex
was raw. Undo removed it; only3D Guide Points was enabled, but the identical
repeat remained raw. This8.5px offset therefore does not establish acquisition.
Next narrower2px/2px aim and pre-placement hint inspection; QA19 remainspartial.
Remote scroll explicitly rejected foreground=false, but CLI lacks --foreground;
synthFirst fallback ran local and did not reach GUI. These are input diagnostics,
not camera or snapping defects. No product change. Durable new PNG/JSON under
snap-categories/native-threshold-2026-09-11; publication remainspending.


The narrower2px/2px repeat produced the same vertex-centered circle with3D
Guide Points bothON andOFF, despite visuallyverified settings andUndo between.
Both screenshots' unobscured blue arc fits yield approximate center404.97,297.80;
the earlier6px/6px ON/OFF pair both yield410.88,291.48. These image-derived fits
supplement inspection, not exact model coordinates. Thus neither pair proves
category-dependent acquisition; narrowdirect point hit may take precedence.
The intermediate apparent ON acquisition is NOT a pass aftertheOFF control.
Next verify official scope and choose a non-hit near-threshold or3Dreference
fixture. No clone behavior changed, no QA19closure. NativeSketch10currently
one nearvertexcircle, all acquisitionOFF, HintsON; no runner.


The face-center control (aim800,400→900,350 window-local) also produced the
same circle with3D Guide PointsOFF/ON. No native category distinction has been
established on this active side-face fixture. The official glossary describes
3D guide-point acquisition, but does not resolve direct-hit/active-face scope:
https://support.shapr3d.com/hc/en-us/articles/7644593398172-Glossary-of-terms
This bounded investigation is checkpointed as inconclusive, not productfailure
or paritypass. No source/tests changed; existing21/21 remains historical, not a
newrun. Evidence locally retained; not published as a closure. Next independent
work QA37 First/Last anchor live comparison; QA19needs a clarified3Dreference
fixture and changed-build clone pair beforeclosure. Inventory26/0/1/29.
