# QA-36 external arc–circle Tangent — September 12, 2026

Baseline f40804a; source 108eec3. QA36 remains partial; inventory26/0/1/29.
Native free semicircle center550400,R10007.9041mm,180degrees and circle550510,
R5000: Tangent translates arc center to550435, preserves radius/sweep, contacts
circle at550485. LastSelected, Auto Constraints off, all acquisition categories
confirmed off for this controlled sample. Clone corresponding semicircle
center250250/r50 and circle250360/r25 selects both but disables Tangent.

An earlier native arc landed on body references with 3D Guide Points enabled:
Tangent changed radius/sweep while center stayed on reference. This sample is
preserved as a confounder, not evidence of free-arc behavior. A third-point move
initially used window-local rather than global coordinates, yielding an uncommitted
major-arc preview; corrected before the controlled semicircle was committed.
One clone attempt failed focus guards before a global drag reached native blank
area; excluded. Explicit app switch then produced the verified clone fixture.

Before regression0/1, focused3/3, separate boundary/refusal1/1 passed.
Production extends the circle pair route only to separated arc/circle pairs
whose external-contact ray lies inside the arc span. Both radii are transient
solve preferences; arc sweep remains unchanged by the existing solver model.
Saved relation explicitly records externalContact. Arc–arc, overlapping/nested
arc–circle and off-span contact remain unsupported, not parity claims.
Tests cover exact placement/radius/sweep, fixed circle, no persisted dimensions,
selection cleanup, JSON, residual, exact Undo/Redo, scope exclusions, saved-lock
refusal with geometry and selection retained.

Final98/98 passed on108eec3, zero failures/skips:56application+19merge+6polish+10Trim+7railUI.
Changed clone LastSelected moves arc center250250→250285 with circle250360 fixed;
R0.6227mm/180.02degrees retained through Undo/Redo and gallery reopening.
Saved JSON radius0.6226610672331411,sweep180.02350481696166,circle radius0.30801880359658884,
external contact residual0.0, retained explicit externalContact. Drawn clone arc
is not claimed exact180degrees; model test uses exact semicircle. First live
apply used inherited FirstSelected (settings tap missed), moved circle instead,
then undone. LastSelected visibly verified before corrected sequence.
Native Undo center550400,Redo550435; gallery reopening preserves contact and
R10007.9041/180degrees. Publication verified: illustrated1023unique/master38, nine hashes once, headingsonce, no1014/38 predecessor loss. Evidence retained
under constraint-types/qa36-arc-tangent-live-2026-09-12. Immutable05be744/iPad unchanged.
