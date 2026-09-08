# Near-equal line inference — September 8, 2026

Baseline e82b9e4, native Front and clone fresh Untitled3 Top landscape. Paired
mouse strokes through Peekaboo; Grid and guidepoint acquisition off, Auto-Constrain
on. Evidence root: workspace reports/openshape3d-core-sketch-milestone-2026-09-08/selection.

Native first line window-relative720,450→920,450 reads694.4694mm. Second720,530→925,530
reads711.8311mm (2.5% longer). Reselecting first retains694.4694mm and endpoints;
no Equal relationship observed. native-nearequal-first/second/first-after.png.
Different zoom scales mean this does not establish native absolute inference tolerances.

Clone first181,350→381,350 reads3.306mm. Second181,430→386,430 adds visible Equal,
reads3.346mm, and shifts first endpoints to approximately180/382 from181/381.
clone-nearequal-first/second.png. The first-after capture selects both lines and
shows total6.69mm; it is not an individual first-line readout. Settings capture
initially showed guidepoints still on; /tmp/nearequal-settings.png confirms both
were turned off before valid strokes. Earlier attempts are not silently promoted.

Correction: automatic Equal inference defaults off for new settings, while manual
Equal and saved Codable preferences remain unchanged. Users with stored Equal=true
retain it; this is explicitly not a migration that silently overwrites preferences.
Relative/absolute tolerances for explicit opt-in remain intact. Regression covers
near-equal default independence, retained Horizontal inference, saved opt-in, and
existing tolerance behavior. Serial inference/lifecycle run passed33/33 in one clean run:
/tmp/os3d-milestone-equal-optin-20260908.xcresult. Post-fix live check passed for explicit Equal-off settings: first3.306mm,
second3.385mm; first reselected remains3.306mm with endpoints181/381 unchanged.
clone-equal-off-settings/first/second/first-after.png. Saved Equal=true was visibly
retained after launch; toggled off deliberately for the live test. Default-fresh
behavior is unit-tested, not claimed as an untouched-preferences live launch.
Native reselected second remains711.8311mm, native-nearequal-selection-second.png.
Initial launch attempt used wrong bundle ID and failed; corrected actual
com.laan.labs.openshape3d launched successfully. No simulator service changes.

Publication pending Google Doc Saving/editing-disabled blocker. Last verified export
76 images; six previous snap/lock inserts visible locally but unverified remotely.
No trim/equality images inserted while blocked. Preserve tab and local evidence.
