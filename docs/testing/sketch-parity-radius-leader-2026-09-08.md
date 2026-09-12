# Arc radius leader — September 8, 2026

Baseline a2251b5. Native old R100/270° arc leader extends left from start
endpoint, solid with arrow and plain text above. Fresh native circle Ø620
center950,525 on vertical line, left-half Trim, Escape and right-edge selection:
right semicircle180°, R310 leader extends downward through lower endpoint,
text rotated upright along extension. Native radius was not edited this cycle.

Clone Front Untitled3 right semicircle center190,455 R2.809, vertical crossing
line retained, selected orange. Existing dashed center-to-right radius line
and rounded badge differ from native. Blue full manipulation ring also differs
and remains open. Evidence radius-ui/os3d-radius-native-half-selected.png and
os3d-radius-clone-selected.png. Different scales, same orientation.

Fixture attempts excluded: first right-canvas circle drags made no geometry;
left-canvas coordinate probe worked. A rapid Line-switch/drag instead drew a
large circle, so tool transition timing is a confound, not an established
location-specific product defect. Added settle/capture before later drag;
vertical crossing line and left-half Trim verified. Native first More tap
activated Arc due changed palette; corrected after inspection. One autofocus
drag showed Home; app PID86772 remained alive, relaunch restored project.
Do not infer a crash or resolved delivery bug.

Arc-only radius geometry now uses actual start endpoint. Overlay solid radial
line continues outward, external arrow and plain upright text. Extension
shortens near viewport edges. Polygon/circle radius behavior unchanged.
No geometry solver/storage changes. Existing arc UI test strengthened to edit
radius2, preserve sweep, then sweep90/history/fullturn checks.
Serial run /tmp/os3d-radius-leader-20260908.xcresult/.log, exec19526 owns
simulator. Post-fix live comparison and publication pending.

Regression clean1/1 passed,49.866s, exec19526 completed0. Radius2 editor,
sweep retention, sweep90/history/fullturn passed. Master diagnosis export18
images, both native/clone PNG hashes matched; master-radius-diagnosis files.
Orientation/launch54121 ownsdesktop until collected. Live postfix pending.

## Post-fix live

Fresh Front clone left-canvas circle center225,300 Ø1.323, vertical line
225,220–380, left-half Trim. Selected right semicircle has R0.662 leader through
lower endpoint, outward arrow, vertical plain text; extension~132 screenpx
matches native sampled~135px. Explicit text tap opened reachable keypad;
1 committed R1,180° retained, center and crossing line unchanged.
Native R310→400 explicit entry, reselect confirms400/180°, center950,525 and
vertical line retained. Native commit clears selection and changes palette;
clone retains selection. Blue full gizmo ring remains open.

Extra failed attempts preserved: corrected-build center/right drag showed Home
with PID90565 still alive; relaunch restored project. Left drag succeeded.
Circle click-click did not create geometry. Initial Trim tap hit overlapping
line dimension editor; Escape and upper-left circumference click trimmed
correctly. No passing claim for these failed attempts or input-delivery cause.

No tests/builds running; orientation54121 collected0. Post-fix images:
os3d-radius-fixed-selected/editor/one.png; native400-selected.png.

Publication verified: master-radius-corrected.docx contains20 images; exact
SHA256 matches for both corrected clone/native edit captures. Browser Saved
to Drive. Original illustrated tab remains76, unsynced inserts preserved.
