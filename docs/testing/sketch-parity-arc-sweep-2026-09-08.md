# Arc radius and sweep — September8,2026

Baseline966b0c0. Native Front trimmed circle: center848,182, radius200mm (~58px),
180° lower semicircle. Radius200→100 keeps center and crossing line761–934,y182.
Clone reopened Untitled2 Top: center543,294, radius1mm (~40px), lower semicircle.
Radius1/2→0.5 keeps center and crossing line483–603,y294; arc length3.14→1.57mm.
Paired radius sample passes, no factor-of-two error. numeric/native-trimmed-arc-
radius200/radius100/radius100-selected.png; clone-trimmed-arc-selected/radius05.png.

Confirmed gap: native exposes both radius and editable180° sweep; clone onlyR.
Native sweep180→90 keeps starting endpoint819,182, center848,182 and radius100;
new end848,210. Crossing line and other sketches unchanged. Angle editor opened
and90 entered/committed; native-trimmed-arc-angle-editor/angle90.png. This is one
orientation/trimmed-arc reference sample; major-angle native check still pending.

Implementation in progress: arc sweep scalar in solver, starting direction held,
whole-arc Lock also fixes sweep; existing angle dimension kind uses one arc ref
(two-line angle unchanged). Selected arc shows radius plus sweep candidate.
Arc validation allows0<angle<360 while two-line retains0<angle<180. Untouched
wrapped angles retain original representation to avoid spurious history updates.
Arc endpoint welding remains an existing limitation; not expanded or claimed fixed.

Serial build/test active exec93683, /tmp/os3d-milestone-arc-sweep-20260908.log and
.xcresult. Arc sweep solver/persistence/lock tests plus existing solver/analyticArc/
DOF and dimension UI run. No post-fix live or passing regression claim yet.
Google Doc remains save-blocked; evidence retained locally, not published.

## Regression and post-fix live result

Initial run:28unit passes (11AnalyticArc,3ArcSweepDimension,1DragTickDOF,13SketchSolverBridge)
plus4existing DimensionUI passes; new UI failed before finding badge because newly
committed arc was not selected. Fixture now explicitly selects default sagitta
midpoint after disarming Arc. Targeted /tmp/os3d-milestone-arc-sweep-ui2-20260908.xcresult
passed1/1, actual90°/radius readouts and Undo/Redo verified.33distinct passing checks
across runs, NOT one clean combined run. Both logs/failure retained.

Native90→270 accepted: center848182,R100,starting819182 unchanged, end848153.
Clone fresh Untitled2 (UI reset store removed prior disposable fixtures): circle
center549349,r~60px,diameter1.987; crossingline469–630,y349; trimupper then select
arc only. Both R0.993 and180° visible. First dual-readout attempt selected bothline
andarc; cleared selection and repeated (valid filename).180→90 keeps start489349,
center549349, radius; endpoint549409.90→270 keeps same anchors, end549289. Crossing
line unchanged. numeric/clone-arc-fixed-dual-readouts-valid/angle90/angle270.png;
native-trimmed-arc-angle270.png. Keypads fully visible and usable.

Gallery reopen: cloneR0.993/270° retained; nativeR100/270° retained after returning
from gallery and restoring Front view. Native trial prompt dismissed through its
Skip accessibility button; earlier coordinate attempt was blocked by modal focus
and did not dismiss it. No trial/purchase/service/security changes. Evidence
clone-arc-fixed-reopen270.png and native-arc-reopen270.png.

Tested/live executable SHA256:
2b6c275b391ae54db9d0ca45223df38d08bc5d4cf5f562b61df1737c9e24a736.
No physical artifact/install claim. Clone angle leader is dashed chord, not native
curved annotation; known visual difference. Full arc construction, boundary inputs,
tangent/endpoint-reference matrix remains open. Native major-angle reference now
verified;0/360 boundary reference not yet checked.

Publication still blocked. Fresh anonymous export via redirects verifies76inline
images and none of six pending snap-image hashes (recovery-check.json). Exact six
image paths/captions backed up in pending-doc-inserts-recovery.json. New arc/trim
images not inserted. Keep existing unsynced tab; no publication claim.
