# QA29 — label overlaps (2026-09-13)

The last simulator-feasible QA-29 item: what happens when two dimensioned
entities are close enough for their labels to crowd.

## Native observation (sketch24, two parallel lines 22,558 mm apart)

- One line selected: its label reads in full above it (136,373.8556 mm).
- Both selected (marquee): **no on-canvas dimension labels at all**; the
  info bar reads "2 edges  279,925.293 mm  22,558.0444 mm" — total length
  and the distance between the parallel lines.
- Native therefore never lays out two per-entity labels together; crowding
  cannot arise in this recipe. Probe lines undone/deleted, Default View.

## Clone

- One line selected: its 6 mm label sits below the pair, readable. Both
  selected by successive taps: no per-entity labels either (the pair keeps
  only its own parallel-distance dimensioning candidate; with the sketch
  Move/Rotate control up no label is drawn) — parity with native's rule.
- **Info bar gap closed (93df1d3):** the sketching info bar now adds a
  "Distance" row for exactly two parallel lines (perpendicular distance),
  next to Total Length. Unit test
  SelectionUXTests.testTwoParallelLinesReadTheirDistance (16/16,
  /tmp/os3d-qa29-overlap2-20260913.xcresult).

Four captures with SHA-256s in workspace reports
layout/qa29-label-overlap-live-2026-09-13/evidence-index.json (local).

## Result

QA-29 "overlaps" observed on both sides with no crowding case; the only
difference (native's parallel-distance readout) is matched. QA-29 stays
partial only on a clone zoom check on a physical device.
