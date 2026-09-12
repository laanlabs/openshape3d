# QA-24 — Multi-selection checkpoint

Evidence date: September 11, 2026. Baseline `f70d15d`.

One clean serial run passed 19/19, zero failures/skips:

- 10 `SelectionTests`
- 7 `SelectionUXTests`
- 2 `SelectionUITests`

Result: `/tmp/os3d-qa24-multiselect-baseline-20260911.xcresult`.
The UI workflows select three patterned bodies with a crossing marquee, delete
them atomically, restore them with one Undo, and select an overlapped body via
the long-press Select Through list. Unit coverage verifies additive tap toggling,
empty-space retention in additive mode, filters, window/crossing semantics, and
front-to-back candidate order.

This is automated evidence only. The UI harness's seeded state did not persist
into a subsequent ordinary launch, so it was not relabeled as an independent
live check. Retained connected-rectangle double-click evidence is not a substitute
for native Shift/additive input. QA-24 therefore stays partial; inventory remains
13 passed / 0 failed / 1 device-blocked / 42 incomplete. Physical Pencil/touch
remains QA-52, and the immutable `05be744` IPA is unchanged.
