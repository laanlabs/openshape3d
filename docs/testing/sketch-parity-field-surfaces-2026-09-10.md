# Matched-Light dimension editor — September 10

Baseline6c8ffaf. CloneTheme changed System(darkhost)→Light throughSettings;
native alreadyLight. This is a deliberate comparison preference, no default
change. Native20mm line editor `/tmp/os3d-light-field-native-editor.png`:
field spans near keypadwidth, text comparable to digit keys; opaque panel hides
geometry. Clone1.5mm line editor `/tmp/os3d-light-field-editor.png`: shortfield
only~92screenpx over156px keypad; 12ptcaptiontext smaller relative to20ptdigits;
blue sketchendpoint circles show through keypad between keys. Different native
macOS/simulator scales recorded; proportions/occlusion compared, not raw pixel
size equivalence.

Implemented 208ptminimum textslot/16ptsemibold, bounded320pt longexpressions,
2ptoutline and opaque theme-aware field/keypad surfaces. Position uses actual
measured editor bounds as before. Four relevant keyboard/rail/imperial UI tests
running, `/tmp/os3d-field-surfaces-20260910.xcresult`, exec52338. Corrected live
comparison/publication pending. No readiness claim; immutableIPA unchanged.

Regression finished clean4/4, nofailed/skipped, one combinedrun. Diagnosisexport
398 placements/all2hashes/no predecessorloss verified:
`/tmp/os3d-field-surfaces-diagnosis.docx`. Live recheck pending; simulator shell
landscape/deviceportrait after UIrun requires supportedorientation resync.

## Live followup exposed layering, not only translucency

First updated portraitLight field readable; live2→1mm typedentry, Undo2/Redo1
passed. Short1mm line reopened and its two blueendpointmarkers still painted
on top of keypad. Earlier transparency-only causal explanation is withdrawn:
SketchPointStateOverlay was later in EditorView's overlay chain than dimensions.
Image `/tmp/os3d-field-fixed-short.png` proves the interim gap; not final parity.
Moved pointmarker layer below dimension editor; retained opaque surfaces for
underlying Metal geometry. Refined minimumslot208→192 after actualrow was wider
than pad. Followup3 UI workflows running (imperial, lowerkeyboard, nearrail),
`/tmp/os3d-field-layer-followup-20260910.xcresult`, exec49407. No live final yet.

## Final layer/field result

Followup clean3/3, nofailure/skip. Exact-build native20→10mm typedReturn,
Undo20/Redo10; clone1→0.5mm keyboardReturn, Undo1/Redo0.5. Native and clone
final gallery reopen retain10mm and0.5mm respectively. Native skipped trial via
existingLimitedVersion button; no purchase. Clone savedDark editor retains
opaque coverage. Light shortline endpoints/Hglyph now fullyhiddenbykeypad;
keyboardfield/commit visible. Prior4/4 plus revised3/3, not a single final4run.
192ptminimum now aligns fullrow tokeypad; 16pttype andopaque themeawaresurfaces.
Pointmarkersmovedbeloweditor is essential; firsttransparency-only explanation
corrected above. Theme default remainsSystem; Light/Dark were UItestpreferences.
Native/iPadscale and residualplatformstyling notclaimedexactphysicalparity.
Final4imagesinsertedonce afterinterim1; exportverificationpending. No runner.

## Publication verified

Final illustrated export `/tmp/os3d-field-surfaces-publication.docx` contains
403 placements, all seven new screenshot hashes exactly once, and no predecessor
media loss against the prior 396-placement export. Includes the interim failure,
not just successful final images. Master `/tmp/os3d-field-surfaces-master.docx`
retains 38 media, the prior Settings note, and exactly one new field/occlusion
heading with final paired gallery-reopen status. Local evidence and SHA256SUMS:
`reports/openshape3d-core-sketch-milestone-2026-09-08/field-surfaces/` in the
agent workspace. No test runner remains.
