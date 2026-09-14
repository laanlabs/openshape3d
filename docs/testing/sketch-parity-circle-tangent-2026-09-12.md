# QA36 two-circle Tangent diagnosis — September 12, 2026

Base f7f8b16. Native independent circles900430 R40 and1000450 R30:
Tangent enabled, applies external contact, preserves second center and R40.
Apply clears selection. Undo restores separation. Redo restores tangency and
an orange first-circle selection in this probe; history-selection semantics
remain under investigation, not assumed equal to line-circle behavior.
Clone independent circles200320 diameter0.7501 and400340 diameter0.4974:
both selected, Tangent disabled. No source correction yet.

Before focused test0/1 with six assertion failures: capability, missing relation,
separation, selection and consequent Undo/Redo of sketch creation rather than
missing application. Receipt /tmp/os3d-qa36-circle-tangent-before-20260912.xcresult.
No runner. New test remains failing intentionally until the confirmed gap is fixed.

Next native nested-circle branch check. Outer circle1000600 R70 created;
inner probes1010600 and1010620 did not create a second circle. Circle remains
armed; no branch result claimed. Settle via Exit/reenter before retrying.
Do not force all pairs external without checking internal contact behavior.
Native existing external Tangent and Concentric fixtures preserved.
Durable evidence: constraint-types/qa36-circle-tangent-live-2026-09-12 under
workspace reports/openshape3d-core-sketch-milestone-2026-09-08.
Publication pending. Reports965/master38; QA36partial26/0/1/29;iPad unchanged.

## Bounded external implementation under test

Nested-circle creation remains input-inconclusive after reentry and settled
menu/blank checks. Only separated full-circle pairs are newly enabled; nested,
overlapping and arc pairs remain unsupported explicitly, not forced external.
External circle-circle residual equates center distance to sum of radius variables.
Transient application radius preferences preserve both radii and yield to saved
relationships; existing First/Last whole-anchor logic remains in force.
No new stored dimension/Lock or schema property. Line-circle lowering unchanged.
Focused /tmp/os3d-qa36-circle-tangent-focused-20260912.xcresult passed1/1.
Expanded First/Last/reversed-order and whole-Lock refusal two-case run active
at /tmp/os3d-qa36-circle-tangent-focused2-20260912.xcresult.
Changed live validation and combined regression pending.

Expanded focused2: 1/2 passed; four First/Last/order variants refused by initial
conflict check despite free geometry. Diagnostic run confirms errorMessage.
Locked refusal remained valid. Dirty correction tests radius-preserving
satisfiability as an alternative while retaining all saved constraints.
Focused3 active; no success or broader regression claimed yet.

The radius-only and radius+anchor validation alternatives still failed the same
free-layout check (focused3/4). Diagnostic direct numeric solve confirmed
residual0.1306119286621084 after200iterations. Those editor validation changes
were removed. Current correction seeds external contact along the initial
center ray in solver construction, moving only a center whose coordinates are
not fixed; all saved residuals remain validated. Focused5 two-case run active.

Focused5 passed2/2: exact radii/preferred center, all four anchor/order variants,
locked refusal, application deselection, exact Undo/Redo and JSON. No runner.
Combined90-case application/merge/polish/Trim/rail gate next. Changed live and
publication remain pending; nested/overlapping circle scope still unsupported.

## Final gate, changed live and publication verified

Source `becd8ed`: final90/90, zero failures/skips, one serial run at
/tmp/os3d-qa36-circle-tangent-final-20260912.xcresult (49 application, 18 merge,
6 polish, 10 Trim, 7 rail UI). No runner. Earlier failures above are retained.
Changed clone external pair preserves diameters0.7501/0.4974 and second center;
apply deselects, geometry Undo/Redo and gallery reopen with Tangent in Items pass.
Native external R40/R30 pair likewise preserves second center/radii and reopens
at exactR30. Native Redo orange highlight remains unresolved (hover/selection),
so no history-selection parity claim. Nested/overlap/arc pairs stay disabled.
Illustrated975 unique: all ten source hashes once, one heading, no965 predecessor
loss. Master38: one heading/no loss. publication-verification.json and both after
DOCX exports retained beside the evidence manifest. QA36partial26/0/1/29;
physical iPad and immutable05be744 unchanged.
