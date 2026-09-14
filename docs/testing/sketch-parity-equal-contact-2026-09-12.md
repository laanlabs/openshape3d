# QA-36 equal-radius internal Tangent — September 12, 2026

Source `5ddba88`, baseline `098557f`. Native Sketch12Top two R9000 circles
at550630/590630 (distance7059.6428mm) resolve to coincident centers590630.
Box selection verifies two edges, center distance0 and unchanged total length
113097.3355mm. Apply clears selection. Geometry Undo/Redo and gallery reopen
retain both edges; reopened selection again reports center0 and the same length.

Changed clone exact Ø1 circles at300730/325750 resolve to center325750 with
LastSelected matched. Apply, geometry Undo/Redo and gallery reopen pass; Items
retains Tangent and both Diameter1.00mm records. Read-only saved-sketch JSON
confirms distinct circle IDs, radii0.5/0.5000000000031284, center distance
3.128335168788072e-12, two diameter1 dimensions and internalContact. This is
solver roundoff, not identity loss. Existing unrelated Parallel/lines survive.

Before0/1 failed three assertions; focused3/3 then final95/95 passed in one
serial run with zero failures/skips:53application+19merge+6polish+10Trim+7railUI.
Final xcresult `/tmp/os3d-qa36-equal-contact-final-20260912.xcresult`.
No source edits after final gate. No runner.

Durable evidence: `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-equal-contact-live-2026-09-12/`.
Contains captures, test logs/summaries, saved-sketch JSON and identity validation,
publication manifest/verification and after DOCX exports. Illustrated1005 unique:
nine new hashes exactly once, heading once, no loss from996. Master38, heading
once/no predecessor loss. Both saved to Drive and anonymous exports verified.

QA36 remains partial. Exact halfway contact, initially coincident equal circles,
and arc variants remain unverified. Inventory26/0/1/29; iPad/immutable05be744
unchanged. Next fresh native contact-boundary comparison, not acceptance promotion.
