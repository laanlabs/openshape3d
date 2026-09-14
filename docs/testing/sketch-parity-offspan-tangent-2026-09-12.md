# QA-36 off-span arc–circle Tangent — September 12, 2026

Baselinefb8684f; source49ac92e. Native lower semicircle center540280,
R9568.4738mm/180degrees, circle540200/R5000. Tangent accepts separated
supporting-circle contact outside the visible arc, moves arc center to540261,
preserves radius/sweep and circle, and displays complementary upper arc dashed
violet. Selected arc readout confirms unchanged R9568.4738/180degrees.
All acquisition/AutoOFF,LastSelected. Original forward selection started in
Drawings UI; reversebox590330→490170 selected exactly two edges. Failed
forward/chord attempts are preserved, not product failures.

Clone corresponding lowerarc450700/r40 and circle450620/r20 selected both but
Tangent disabled. Before0/1 reproduced; focused3/3 passed after removing the
visible-span exclusion for separated arc/circle pairs. Existing solver preserves
radius/sweep and preferred circle via prior transient preferences. Dashed guide
uses complementary arc in active sketch only, deduplicated per arc; no entities,
profiles or selectable edges are added. Overlapping/nested arc/circle and arc–arc
remain unsupported/unverified. Tests cover geometry/selection/history/archive,
guide after apply/Redo and absence after Undo; final also checks Exit suppression.

First combined99/99 clean on49ac92e. Native Undo/Redo and gallery reopen
preserve contact and R9568.4738/180degrees. Settled unselected Redo/reopen hides
the dashed guide; selecting either arc or circle reveals it. This exposed an
over-broad clone guide policy. Visibility before0/1, focused1/1 passed after
reusing annotationIsVisible in source007181c (pushed). Corrected combined gate passed99/99, zero failures/skips; no runner. Native immediate post-apply transient timing remains outside the
settled-state claim. Changed clone live/history/reopen and publication pending. Reports1023/master38. QA36partial26/0/1/29;
iPad/immutable05be744 unchanged. Durable qa36-offspan-tangent-live-2026-09-12.


Changed-build live verified on007181c: LastSelected explicitly confirmed. Arc
center450700→450680; circle450620 fixed. Selected arc reads R0.4947mm/179.59°
in applied, Undo and reopened states; circle diameter0.4953mm. This proves sweep
preservation, not exact180° creation. Settled none/arc/circle selection states
match native guide visibility. Geometry Undo/Redo and gallery reopen pass;
reopened arc selection restores dashed complementary guide. Saved archive has
externalContact, two radius entities, no dimensions, and preserved source lines.
Publication pending; baseline1023/master38 unchanged.


Publication verified: illustrated1033 unique media, all ten source hashes exactly
once, one heading and zero loss from1023. Master38, one heading, no predecessor
loss. Manifests, before/after DOCX, saved-contact-verification.json and final
99/99 receipts retained in the durable off-span directory. No runner. Next
native overlapping arc/circle comparison; no acceptance promotion.
