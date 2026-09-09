# Partial-overlap numerical stability — September 9

Baseline4b510a0. Prior native partial top-edge region remains selectable through
continued drawing/reopen; clone first-loop fill disappeared after subsequent
constrained drawing. Rechecked with source2 explicitly visible, correct interior
(180,230): no profile. A read-only SQLite query of Untitled2 saved Sketch2
shows all four boundary corners connected and partial segment endpoint on top
edge within ~4e-14mm. No actual visible gap. Saved local JSON retained; no
database writes. Added exact nine-line geometry regression preserving the
point-touch neighbor, before further production changes. Publication pending.

Red28983 completed65: one test/two assertions failed (only neighbor detected).
Temporary graph now splits numerically collinear overlaps into matching
subsegments before straight-boundary deduplication, at existing node quantum
1e-6mm rather than endpoint weld1e-3mm. Editable geometry unchanged. Exact
saved fixture also tests reversed entity order. Green19359 owns simulator;
/tmp/os3d-partial-stability-green-20260909.log/.xcresult.

Green19359 completed0 clean43/43 (22Profile+2History+3Seed+11Arc+5Spline). Live saved recovery/repeat pending.

## Live corrected result

Saved profile recovered. Fresh clone overlap197232→224232 (readout0.372mm),
then line300800→400800, Undo removes line and Redo restores; Exit/interior
195255 still selects first profile. Native fresh overlap916470→949470, then
line850690→950690 and Undo/Redo; Exit/interior917490 still selects profile.
Both gallery reopens retain selectable first loop, touching neighbor and prior
solids. Native oblique finalclick878507; clone263241. Screenshots inspected.
No identical size/scale claim; initialpass/laterfailure/correction all retained.
Publication underway; no test runner active.

Publication verified: illustrated184 placements/all5 new PNG hashes; master38 final43/43 and continued-edit/reopen note. Exports/evidence and read-only saved fixture retained locally.
