# QA53 open-panel palette reachability — September 12, 2026

Baseline5676bd0; acceptance remains partial, inventory32/0/1/23.

## Confirmed comparison

Fresh native Shapr3D modeling state opens History beside Items and retains its
modeling toolbar. History is disabled while sketch editing and becomes available
after Exit. Clone portrait opens both panels but History covers Sketch, Modify,
and Transform. No geometry was edited by these observations.

Native Mac Preferences has no visible interface-side/large-text setting; these
are not freshly paired iPad variants. Failed coordinate click below the parent
window and the first mistaken clone Views-menu click are excluded.

## Correction and regression status

EditorView reserves same-side panel width for the palette. Flyouts render above
panels; Right toolbar opens flyouts inward instead of into Items.

- Original focused before:0/1. XCTest called Sketch hittable, but tapping did not
  open Line. Thus hittability alone was insufficient.
- First corrected left-portrait focused:1/1.
- Expanded four-state matrix:0/1; both Left orientations passed before Right
  portrait failed to dispatch Line. The always-right flyout code was identified.
- Corrected four-state matrix:1/1, all Left/Right portrait/landscape cases dispatch Line into plane selection; zero failures.

Logs/xcresults: /tmp/os3d-qa53-panels-{before,fixed,matrix,matrix2}-20260912.*.
Durable screenshot/command evidence:
/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/keyboard/qa53-panels-live-2026-09-12.
Final combined **50/50** on4b6a78f, zero failures/skips, one serial run: four
settings/layout model classes plus seven Settings UI workflows. Exact receipt:
/tmp/os3d-qa53-panels-final-20260912-summary.json.

Changed live Left and Right both-panel Sketch→Line dispatch enters plane
selection; closing History restores Left palette edge placement. Right flyout
opens inward over History and remains usable. The live project contains an
extruded body from the preceding test, unlike the earlier sketch-only fixture;
no geometry edit or geometry-history comparison is claimed. Right preference
is currently retained; native modeling still has both panels open.

Illustrated **1247** unique assets: all ten hashes once, no loss from1237.
Master38, one dated note, no predecessor loss. Exact export inventories and XML
are in the durable evidence directory. QA53 remains partial; physical/native
handedness and large-text comparisons remain open. Immutable05be744IPA unchanged.

## Separate QA40 pan delivery boundary

Horizontal scroll probes never reached native: default focus and no-auto-focus
both require foreground=true at bridge, while CLI rejects --foreground for
scroll. No pan behavior claim or source change follows from those attempts.
Cube checkpoint5676bd0 remains verified57/57 and publication1237/master38.
