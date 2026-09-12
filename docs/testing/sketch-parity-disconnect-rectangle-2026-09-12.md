# QA38 primitive rectangle Disconnect and finite closure — September 12, 2026

Source03b9e1c, prior paired checkpointc91f8f9. No source change in this variant;
reuse the clean corrected120/120 on that exact source, not another test run.

## Paired workflow

Native diagonal rectangle500230→623316,100000×70000mm. Line500370→580410.
Narrow box selects lower-left corner and line endpoint; Coincident moves only
line endpoint to500316. Corner Disconnect preserves shape/geometry. Center
drag561273→591273 translates rectangle30px, external line unchanged. Two Undo
restore movement then connected joint (Disconnect enabled); two Redo restore
detach/move. Gallery reopen retains rectangle100000×70000 and separate line.

Clone fresh diagonal rectangle250650→400750 is verified one stored rect.
Line250800→330840. Corner+endpoint Coincident initially averages points to
250775 and changes rectangle height; despite First Selected this differs from
native. This initial-application anchor/selection bug is explicitly separate.
Disconnect from connected baseline preserves geometry. Immediate center drag
did not move; settled repeat326712→356712 translates only rectangle30px,
line250775→330840 fixed. Two Undo restore movement then explicit Coincident;
saved JSON after save settles confirms connection and removes exclusion marker.
Immediate pre-save JSON was stale and is retained separately. Two Redo restore
detach/move. Gallery reopen retains one primitive, identical line/dimensions,
width1.852200627326965 and height1.5377821922302246 (computed width roundoff
2e-16 only). No decomposition. Native/clone geometry sizing scales differ.

## Publication

Illustrated1154 unique images, eight exact source hashes once, heading once,
zero loss from1146. Master38 media unchanged, closure heading once, no loss.
Durable reports/openshape3d-core-sketch-milestone-2026-09-08/disconnect/
qa38-rectangle-live-2026-09-12 contains PNG/actions, detached/restored/reopened
JSON, before/after DOCX and publication-assets/verification.json.

## Finite acceptance

QA38 PASS: retained four-line endpoint evidence plus September12 midpoint,
circle-center and stored-corner paired Disconnect/independent movement/history/
reopen. Current120 verifies unaffected dimensions/relations, exact history,
archive/import/Trim/Delete integrity. Earlier failures remain in prior receipts.
Initial Coincident anchoring/selection, general overlap picking and physical
Pencil/touch remain separate; no universal constraint or device claim.
Inventory28passed/0failed/1device-blocked/27incomplete. Immutable05be744 and
iPad unchanged. No runner. Next confirmed point-pair Coincident anchor fix.
