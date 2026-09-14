# Angle unit in length field — September 10, 2026

Baseline0b33fdb pushed. Native selected12mm length rejects10deg with warning
"Cannot use angle in a length type parameter." after Return, retaining draft and
geometry. Clone selected1.2mm length accepts1deg and silently shrinks to1mm.
Inspected /tmp/os3d-unit-type-native-draft.png/native-result.png and clone-draft.png/
clone-result.png (same prefix). Different zoomscales explicit. This is a geometry
acceptance gap, not just warning styling.

Fix checks evaluated input's degree suffix before editor dismissal/geometry/history
mutation for length dimensions. Existing scalar evaluator remains unit-agnostic.
Test covers three degree expressions, unchanged entities/dimensions, immediate valid
recovery and exact Undo/Redo. Serial /tmp/os3d-unit-type-20260910.xcresult pending.
No post-fix live or reciprocal angle-field claim yet. Publication pending.

## Verification

Clean28/28 exec86205exit0. Exact-build live clone rejects2deg, retains yellow
message/draft and1mm geometry. First CmdA attempt inserted literal a rather than
selecting draft, so its malformed recovery is excluded. Explicitdelete then2mm
commits2mm. Native20mm valid correction commits after10deg refusal. No fresh live
history claim for this batch (exact history unit checks pass). Four images inserted
once; first illustrated export still332, zero newhashes, so publicationpending.
Master note inserted once, export pending. Local reports/.../unit-type images hashed.

Publication recovered on retry: illustrated336placements/all4hashesonce/no predecessor loss
(/tmp/os3d-unit-type-publication-final.docx); master38/newnoteonce/priornote/allmedia
retained (/tmp/os3d-unit-type-master.docx). No duplicate insertion. No runner.
