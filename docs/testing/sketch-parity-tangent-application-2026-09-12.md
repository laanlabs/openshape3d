# QA-36 Tangent application — September 12, 2026

## Status

Source `b8cf6b7` pushed. Final combined **86/86** passed with zero failures/skips:
45 application +18 merge +6 polish +10 Trim +7 rail UI. Changed-build paired
application, deliberately selected history, reopening and publication verified. QA-36 remains partial;
inventory 26 passed / 0 failed / 1 device-blocked / 29 incomplete.

## Confirmed paired defect

Native fresh isolated circle R50 mm and line95.9311 mm: applying Tangent moves
the circle from local center(530,630) to(530,669), preserves radius and target,
and clears operands. Deliberately selected Undo/Redo restores geometry and clears
selection. Native gallery reopening retains the tangent circle at exact R50 mm.

Clone before fix: circle center(1.3392324448,-3.0072782040), radius0.37262403965;
target endpoints(0.9691042900,-3.9912598133),(1.7097507715,-3.9912595749).
Application moves center to(99.8993011787,-3.3129410658) and changes radius to
0.67828690128, confirmed by read-only persisted sketch JSON, not inferred from
label position. Undo restores original geometry; selection was retained.

The nearly horizontal target leaves along-line circle movement unconstrained;
the solve takes a large tangential displacement while also resizing the circle.
The correction supplies a transient radius and center-projection preference when
the line is the anchored operand. Existing saved relationships override that
preference via fallback. No additional Lock or dimension is persisted. Successful
Tangent apply/history clears selection; refusal retains it.

## Regression evidence

- Before: 0/1, thirty assertions across six slope/side cases.
- Focused correction: 1/1, same geometry/history/archive matrix.
- Expanded: 2/2; First/Last orderings, horizontal/near-horizontal/sloped targets,
  both sides, exact target/radius and Undo restoration, JSON round trip;
  saved center Lock overrides preference and allows radius change, whole-geometry
  Locks refuse without losing operands.
- Final combined: **86/86**, zero failures/skips, one serial run on b8cf6b7.

## Durable evidence

`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-tangent-live-2026-09-12/`
contains native pair/application/radius/Undo/Redo and clone pair/application/Undo
captures, before/applied persisted JSON, focused logs and summaries.
Original xcresults remain under `/tmp/os3d-qa36-tangent-*-20260912.xcresult`.

The earlier attempt to add an existing line using a Shift box lost circle
selection and is excluded. The isolated two-entity containing box gave the actual
native comparison. No native radius ceiling, general arc tangent, circle-anchored
line relocation, or physical-device behavior is claimed verified here.

Changed live circle preserves diameter0.7452 mm, moves from local(450,740) to
(450,790) against fixed line(420,820) to(480,820). Apply clears operands;
deliberately reselected Undo/Redo restore and clear; gallery reopening retains
exact diameter and saved Tangent in Items. Native R50 persists on reopening.

Publication verified illustrated945 unique images: all ten new source hashes
exactly once, one heading and no935 predecessor loss. Master38, one note and no
predecessor loss. See publication-assets.json, publication-verification.json and
both after DOCX exports in the durable evidence directory.
Immutable05be744 IPA and physical iPad installation are unchanged.
