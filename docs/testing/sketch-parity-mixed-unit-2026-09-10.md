# Mixed-unit additive lengths — September 10, 2026

Baseline aa8d7d9. Native Shapr3D window1924 accepts `1 cm + 2 mm` as12mm with f(x).
Clone simulator6492 rejects equivalent `0.1 cm + 0.2 mm` with syntax warning,
retaining draft and unchanged1mm geometry. Screenshots inspected at /tmp/os3d-mixed-
(native-validdraft, native12, clone-draft, clone-result).png. Different zoom scales.
Initial native typing without field focus triggered selection shortcuts; excluded.
Settled field-open capture preceded the valid repeat. No app failure inferred.

Correction: separate fully-qualified additive length evaluator returns millimetres
for mm/cm/m terms. Legacy variable/scalar evaluator unchanged. Commit bypasses
additional display-unit conversion, stores original source, does not create a
variable formula. Unit tests cover exponent/subtraction, malformed/angle/product
rejection, display-unit independence, recovery, Undo and retained reopening.
This is not general dimensional algebra parity; products and mixed unqualified
operands remain unverified. Serial /tmp/os3d-mixed-unit-20260910.xcresult running;
no result or post-fix live claim yet. Publication pending. Immutable IPA unchanged.

## Verified result

Serial run completed clean27/27, exec43798exit0. Exact-build clone keyboard entry
commits1.2mm/f(x); toolbar Undo1mm and Redo1.2mm inspected. Gallery reopen retains
`0.1 cm + 0.2 mm`. Native CmdZ restores20mm; CmdShiftZ reapplies12mm, reopening
retains `1 cm + 2 mm`. Native gallery persistence not repeated for this batch.
Illustrated332placements/all4newhashesonce/no predecessor loss verified in
/tmp/os3d-mixed-publication.docx. Local evidence copied/hashed under reports/.../mixed-unit.
Master addendum inserted once, export pending. No runner.

Master38/newnoteonce/priorunitnote and allmedia retained, verified /tmp/os3d-mixed-master.docx.
