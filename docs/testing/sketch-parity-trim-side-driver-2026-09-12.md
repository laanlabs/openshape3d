# Rectangle side-driver Trim — September 12, 2026

Native rectangle100000×70000: top width and right height Lock, top Trim.
Height editor exposes expressionNumpad.unlock; bottom width exposes
expressionNumpad.lock after Redo, proving removed top driver did not migrate.
Undo restores top width driver (unlock accessibility). Geometry unchanged elsewhere.
Clone fresh primitive200250→320320, width1.4946754276752472 and
height0.8723702430725098 locked. Top Trim retained both dimensions on surviving
diagonal endpoints, confirmed through saved JSON and live labels.
An Escape delivery attempt left Trim armed and removed the right edge on the
following tap; this extra action was undone, then explicit Trim toggle used.
That input route is excluded, not claimed as successful Escape parity.

Before source0c1f170/2016713: targeted0/1, exact extra-horizontal-driver failure;
reference validity, profile opening, JSON and exact Undo/Redo otherwise passed.
New optional rectangleDrivingEdge records owning side at Lock/numeric creation;
Trim drops a driver if its owning edge does not fully survive, otherwise remaps
to that edge endpoints. Presentation aliases stay separate. Legacy nil keeps
existing behavior. Import preserves provenance. No changed-build live claim yet.
Focused lifecycle/Trim gate running. No publication yet; illustrated1174/master38.
Durable evidence workspace reports/openshape3d-core-sketch-milestone-2026-09-08/trim/qa43-live-2026-09-12.
QA43partial; inventory29/0/1/26; iPad/immutable05be744 unchanged.

Focused21/21 clean; expanded same-method matrix1/1 clean (all four sides × Lock/typed creation), with pre-Trim JSON/import ownership, surviving driver identity/value, post-Trim JSON and exact history. No runner. Combined annotation/application/lifecycle/Trim/merge/polish and two UI gate next. Changed-build live and publication pending.
