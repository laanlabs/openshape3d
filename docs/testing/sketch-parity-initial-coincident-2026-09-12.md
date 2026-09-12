# QA-36 already-concentric equal circles — September 12, 2026

Baseline293bf9c; sourcec6dee5d. Native fresh R9000 circles560250/650250,
Concentric moves first to650250. Two-edge selection reports center0, unchanged
113097.3355mm total length. Tangent remains enabled and applies successfully,
adds marker without moving geometry, clears selection. Direct center-start
second-circle creation instead moved the selected first circle; undone and
excluded. This is explicitly the existing-Concentric fixture, not proof of
unconstrained duplicate-circle creation.

Before0/1 failed six downstream assertions; corrected focused3/3 passed with
already-concentric, equal-radius deep overlap and unequal overlap matrix.
Eligibility now permits full circles regardless of coincident center/radius;
existing internal residual handles zero geometry change. Test retains both exact
entities and Concentric, adds internalContact, checks selection clear, archive,
residual and exact Undo/Redo. No source changes after c6dee5d.

Final96/96 passed in one serial run, zero failures/skips, on c6dee5d:
54application+19merge+6polish+10Trim+7railUI. No runner.
Changed clone circles exact Ø1 at300730/420730 joined via Concentric→420730,
then Tangent enabled/applied without moving. Items shows Concentric+Tangent and
both Diameter1.00mm records. Undo removes only Tangent; Redo/reopen restores it.
Saved JSON verifies distinct IDs, two diameter1 values, both relations, radii
0.5/0.5000000000031334 and center difference3.999423014988679e-11.

Selection-route boundary: coincident rim taps cannot reliably select both.
The verified clone route is Exit→Select marquee→Done→Items sketch reopening;
this retains both operands (total6.28mm) and enables Tangent. Native uses the
in-sketch marquee. Do not claim equal selection-route parity or treat this as
physical mouse/touch equivalence. No selection source changes were made.

Native Undo preserves coincident geometry while removing transient Tangent marker;
Redo and gallery reopening show retained Tangent marker, two edges, center0 and
113097.3355mm total length. The settled deselected Redo hides markers under its
visibility settings; reopened selected pair is the durable relation proof.

Illustrated1014unique/master38 saved and export-verified: nine source hashes
once, headingsonce, no1005/38 predecessor loss. All captures, final/before/focused logs
and summaries, saved-sketch/identity JSON, publication manifest durable in
constraint-types/qa36-initial-coincident-live-2026-09-12. QA36partial26/0/1/29;
iPad/immutable05be744 unchanged. Next native circle/arc Tangent comparison;
exact halfway and selection-route variants remain open.
