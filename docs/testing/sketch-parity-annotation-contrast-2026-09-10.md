# Canvas annotation contrast — September 10, 2026

Baseline1d28849. Selected90deg arcs paired: native black text/leaders onlightcanvas,
clone white/faint text/leaders onlightcanvas withdarkchrome. Screens inspected:
/tmp/os3d-annotation-contrast-native.png andclone-before.png. Differentarc sizes/
scales, notpixelidentity claim. Renderer lightgradientconstant independentAppTheme;
Color.primary resolveswhiteindarkUI. This regressed readability withtheme, notgeometry.
Correction separateslightcanvas annotationink fromUItheme: blackleaders/text in
SketchDimensionOverlay andSketchLiveDimensionOverlay. Conflictred, bluepending
geometry, keypadcontrols andwhiteoutlinedmanipulationhandles untouched.
Build /tmp/os3d-annotation-contrast-20260910.log exec62859 pending. No newautomatedtest
claim forpurecolorchange; livepostfix andpublication pending. ImmutableIPA unchanged.

## Reconciled live result

Initial build succeeded; updated simulator selected arc and isolated line use black
ink without geometry changes. Fresh circle and rectangle release also show black
leaders/text, as do paired native samples (different scales/placement retained).
Pending arc comparison exposed a separate dark material badge in clone versus
native plain black text. Removed that material and made live text explicitly black;
second build and repeat pending. Screens: /tmp/os3d-contrast-native-circle.png,
native-rect.png, clone-rect.png, native-pending.png, clone-pending.png (all prefixed
os3d-contrast-). No test runner active before this follow-up build.

Follow-up build passed and live plain pending text was inspected. It remained
smaller than the completed dimension font (caption2 versus 16pt). Aligned pending
text to the existing 16pt dimension font; final build/live repeat pending.

Final build /tmp/os3d-annotation-contrast-final-20260910.log passed (exec31523).
Same app installed/relaunched; settled gallery entry restores completed rectangle,
circle, line and arc. Initial too-early gallery clicks were ignored; retained
screenshot shows gallery, then settled retry succeeds. Fresh pending45degree arc
now has plain black 16pt text and black leaders; geometry matches prior pending
sample. /tmp/os3d-contrast-clone-pending-final.png inspected. No automated tests
were run for these presentation-only changes. Six evidence images inserted once
in illustrated Doc; export verification pending. Local original evidence and
SHA256SUMS: reports/openshape3d-core-sketch-milestone-2026-09-08/annotation-contrast.

## Publication verified

First export remained347 with no new images; retried without duplicate insertion.
Final /tmp/os3d-contrast-publication-final.docx has353 placements, all six new
hashes exactly once and no predecessor media loss. New heading exactly once.
/tmp/os3d-contrast-master.docx retains38 media, predecessor heading and one new
annotation/final-saved-geometry note. Illustrated inserted result inspected too.
No runner remains. Remaining numeric/selection acceptance continues.
