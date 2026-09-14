# Full-turn arc conversion — September8,2026

Baselinee63823e. Native Front savedR100/270° arc: setting360 creates a full circle;
reselection offersØ200, notR/angle. Center/crossing line unchanged. numeric/native-
arc-boundary360.png and native-arc-boundary360-selected.png. Clone270° rejected360
and keptgeometry, modalrangeerror; clone-arc-boundary360-beforefix.png. Confirmed
boundary discrepancy, not an invalid-input parity pass.

Correction: accept exactly360 for a single-arc sweep, validate against structural
constraints first, then convert solved arc to circle with same entityID/center/radius.
Remove obsolete single-arc angular dimensions, migrate any persisted radiusdimension
(same dimensionID, refs) todiameter with doubledvalue/formula. Existing references
and unrelated dimensions untouched. One composite history step includes geometry,
reference changes and downstream sketch rebuild. Ordinarytwo-line180bound unchanged.
A fullturn is never left as zero-sweep wrapped arc.0/out-of-range still rejected.

Clean25/25 regression passed:11AnalyticArc,4ArcSweepDimension,9ConstraintLifecycle,
1extendedDimensionUI (90/sweepUndoRedo plus360circleconversionUndoRedo).
/tmp/os3d-milestone-arc-full-circle-20260908.xcresult and.log; exec67571completed0.
Pure test confirms a closed profile and radius/formula migration. Post-fix live repeat passed: persisted R0.5/180° became a full circle with
Ø1 and no obsolete radius/angle badge. Center549,349 and crossing line469–630,y349
unchanged. Clone gallery reopen retained Ø1; this new full-circle reopen is
clone-only, not a paired persistence claim. Native conversion already captured.
Evidence: numeric/clone-fullturn-radius05-before.png,
clone-fullturn-circle-diameter1.png, clone-fullturn-circle-reopen.png.
Tested/live executable SHA256:
b9c9d789cb8d3107caa8c7bbd75d0fce8a299dd65342ba028ff15c25e2d4d192.
Arc endpoint-reference/welding matrix remains outside this sampled correction.

Master roadmap e63823e/known-differences/publication-blocker update verified via
anonymous master-arc-status.txt export. IllustratedDoc still76verifiedimages,
sixpendinginserts notpresent; recovery-check.json/pending-doc-inserts-recovery.json.
No new illustrated-image inserts or publication claim while blocked.
