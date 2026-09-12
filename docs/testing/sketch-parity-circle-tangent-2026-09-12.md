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
