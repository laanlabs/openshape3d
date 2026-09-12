# Duplicate straight boundary — September 9

Baselineb2de2ac. Native Sketch03 allselection11edges before repeat. Draw
existing top567500→660500 again, Escape, namedrowselection now12edges.
Modelinterior610550 stillselects mergedouterregion with constructiondivider.
Clone existingtop300650→450650 repeated, readout1.859mm; Exitmodelinterior
375700 no longerselects and fillabsent. Beforeduplicate fillwaspresent. Existing
bore retained. Pairednativeprofile and cloneprofile PNGs copied to durable
transform-controls reports, plus allintermediateos3d-duplicate-* images.

Clone live Undo/Redo/settledUndo did not visiblyrestorefill; inconclusivehistory
input/state observation, no history-code change. Profilehalfedgegraph currently
includes duplicatecoincidentstraightedges. Added two tests for forward/reversed
boundaryduplicates (originaledgeidentity, editableentitypreservation) and a
reversedduplicate shareddivider. Redrun83500 owns simulator, result/log
/tmp/os3d-duplicate-red-20260909.xcresult/.log. No geometryfix yet.
Exact/endpointwelded straightduplicate scope; partialoverlap, duplicateconics,
pointtouch andtinygaptolerance notcovered. Publicationpending.

## Reproduction and graph correction

Red83500 completed65: both new tests failed, 0profiles instead of1/2, four
assertion failures. Straight boundary chains now deduplicated after existing
endpoint weld in temporary detector graph. First entity remains boundaryowner;
editable sketch untouched. Arc/spline chains excluded from deduplication.
Green40413 profile/history/seed run owns simulator. Requested ArcProfileTests/
SplineProfileTests selectors were not actual suites; do not claim those ran.
Inspect actual curve suites and run correct relevant followups.

Green40413 completed0 clean22/22 (17Profile+2History+3Seed). Correct
AnalyticArcTests/SplineProfileEvalTests/SketchEntityTests followup42416 running.

## Final live correction

Correctcurves42416 completed0 clean27/27 (11AnalyticArc+11SketchEntity+
5SplineProfileEval). Initial2testfailure, then22+27clean followup runs; not one
combined49test run. Relaunch savedUntitled2 restores previouslymissingfill.
Fresh reverseoverlap450650→300650 on correctedbuild retainsprofile; interior
opensExtrude. Onscreen1 input appends01 toseed0; keypadcommit creates1mm
solid, displayedvolume3.45mm³/bounds2.79×1.24×1.00. Native sameprofile
extrudes500mm via keypad intoBody03. Different scales, no identicalsizeclaim.

NewbodyUndo removes solid, Redo restores it inboth; this verifiedbodyhistory
is separate from earlier inconclusiveduplicateUndo attempts. Pairedfinalgallery
reopens retain blockandpriorbore. Clone sourceSketch2hiddenbyextrusion as
before; native source03visible. No change tothatknownstatepolicy.
Publicationaddendum/5images prepared; exportverificationpending.

Publication verified: illustrated165 imageplacements vs prior160;164unique
mediaassets due identicalimage reuse. All5 suppliedPNG hashes match export.
Master38 finalreopen/testhistory note verified. Exportcopies retainedlocally.
