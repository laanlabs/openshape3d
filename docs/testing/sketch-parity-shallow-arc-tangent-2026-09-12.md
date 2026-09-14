# QA-36 shallow arc/circle overlap — September 12, 2026

Source77365e3, baseline2e451a5. Native fresh lower arc center550550,
R10425.5562mm/180degrees; circle550605,R5000. Reverse box605645→500530
selects exactly two edges. Tangent separates the shallow overlap externally,
arc center~550546, circle fixed; selected arc retains radius/sweep. Earlier
unarmed chord attempt and shifted-toolbar Trim activation changed no geometry
and are excluded. Native history/reopen still pending for this new pair.

Clone corresponding lower arc250700,r40; circle250755,r20. Both orange but
Tangent disabled. New regression before0/1 (six assertions); focused3/3 passes
with distance>max(radii) eligibility. Full-circle branches unchanged; arc/circle
continues externalContact only. Deep/nested and exact max-radius boundary remain
unverified, not promoted. Solver unchanged. Test preserves source geometry,
LastSelected circle, no new dimensions, exact archive and Undo/Redo.

Combined application/merge/polish/Trim/seven rail UI gate passed100/100, zero failures/skips, on77365e3 at
/tmp/os3d-qa36-shallow-arc-final-20260912.xcresult. Changed-build paired
history/reopen and publication pending. Evidence durable under constraint-types/
qa36-shallow-arc-tangent-live-2026-09-12. Reports1033/master38 unchanged;
QA36partial26/0/1/29, iPad/immutable05be744 unchanged.


Changed-build live on77365e3: LastSelected confirmed, arc250700→~250695,
circle250755 fixed. R0.4947/179.59degrees unchanged through apply/Undo/reopen;
circle diameter0.4943. SavedJSON radius0.4946802078065139, sweep179.58778684509392,
circle radius0.24712985754013062, external residual0.0, no dimensions. Native
Undo/Redo and gallery reopen retain R10425.5562/180degrees and contact.
Nine comparison images and dated notes saved in both reports; export verification
pending. Initial clone settings animation miss rotated camera only, restored via
Exit/Items reentry before controlled draw. No source changes after final100.


Final publication verified1042unique/master38, nine hashesonce, headingsonce,
zero1033/38 predecessor loss. Manifests, DOCX exports and verification JSON
are durable alongside all captures/test logs/summaries/saved geometry. No runner.
QA36 remains partial; next native deeper arc/circle boundary.
