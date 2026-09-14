# Selected arc radial handle — September 8,2026

Baseline4cfe3f0. Native right semicircle center950,525 R400 driven: white
bidirectional radial handle refused outward30px drag, native constrained-parts
message. Undo restored undrivenR310; reselect, same outward30px drag increased
radius539.1552, center/sweep180/verticalcrossingline retained.

Clone center225,300 R1 driven. First Undo after app-switch showed Home, PID90565
remained alive. simctl reactivation then same Undo coordinate457,118 restored
R0.662 live. This narrows prior history discrepancy toward activation/input,
not proof of cause. Outward drag on blue ring produced no radius change.
Tangential drag first showed Home; reactivation and repeat rotated arc~20°
while R0.662/180 retained; crossing line stayed. Thus generic ring is rotation,
not native radial sizing. All captures under handle-ui; failed/Home attempts
excluded from feature passes.

Single-selected-arc default now white radial arrow at sweep midpoint, no full
blue ring/diamond. Explicit Move/Rotate toggle retains previous manipulation;
Copy enables it. Other selection gizmos unchanged. Toggle location is a
functional entry point, not a claim of matching native More-menu placement.
Radial gesture projects screen translation onto initial radial direction and
uses temporary radius+center intent. Saved constraints/dimensions win; no new
radius/Lock persisted. Commands coalesce and dependent rebuild runs on release.

Implementation not yet live-verified. Serial exec84467 owns simulator:
/tmp/os3d-radial-handle-20260908.xcresult/.log. Two solver tests plus strengthened
arc UI handle/undo/radius/sweep/history/fullturn and existing sketch move UI.
Postfix live native/clone comparison and publication pending.

First run exec84467 exit65: both solver tests passed; arc UI reached radial
resize/Undo/radius2 but sweep-label tap failed. Attachment confirmed new
white handle overlapped angle text. Angle target moved outside curved leader
when radial control is active; handle hidden during numeric editor. Existing
sketch move test failed because Line remained armed; explicit tool-off added
to fixture before selection (current product behavior). No clean-run claim.

Clearance rerun12460 exit65: arc UI now passes53.889s; move test selection
appears but no third undo step. Fixture retained newest line after release,
then toggled it off on second selection tap; midpoint glyphs also confound.
Clear initial selection, pick both line bodies off-midpoint and attach before/
after move. Targeted move rerun follows. Master diagnosis22images verified.

Fixture diagnostic10324 failed at compilation before tests: screenshot helper
was file-private in another suite. Local helper added; no product change.

Move fixture2 exec57290 completed0:1/1 passed, exactly3undo steps after proper
selection. Thus2unit+2distinctUI passing across initial/targeted runs, notone
combined clean run. Orientation/launch24909 ownsdesktop; livepostfix pending.

Intermediate live post-fix: whitehandle/no fullring for selected rightarc.
Outward30px R0.662→1.155,center225,300/180/crossline225,220–380 retained.
LiveUndo0.662/Redo1.155 passed. Explicitradius1 saved, outwarddrag refused
(no movement). Native has a rejection notice; matching nonblocking notice
added once per drag. Copy chip truncated in explicit mode; fixed intrinsic
width. Transform mode restored ring, but angle label returned into its right
handle and blocked sampled rotation; keep angle outside leader in both modes.
Two inactive-window keypad attempts excluded; refocus successful. These
presentation followups trigger targeted arc UI before final live repeat.

Final targetedarc28143 completed0,1/1passed58.517s includingdrivenrefusal
notice, explicitmode toggle, radius/sweep/history/fullturn. Productbuild
updated; final live transform/reopen followup pending.

Final live: fresh Front rightsemicircle R0.662→1.155 bywhitehandle30px,
center225,300/180°/verticalcrossline retained. ExplicitMoveRotate ring rotates
~20° clockwise; Done restores radial handle, Copy textfullyvisible. Gallery
reopen+ItemsSketch1 reselect retainsR1.155/180 androtatedgeometry, default
radial mode. Native galleryreopen retainsR539.1552/180; camera restoredvia
doublecube thenCmd2 Front, doubleclicksketch+singlearcselection. Trialprompt
skipped; first scrollrejected bridgeforegroundrequirement, --foreground
rejectedCLIflag; nozoomclaimfromthoseattempts. Native reopenedRlabel partly
clippedbottom but selectedmeasurementstripreads539.1552.

Intermediatelive drivenR1refusal andUndo/Redo verified; finaltargetedUIchecks
addednotice/modetoggle. Finalnoticeappearance not separatelycapturedlive yet.
BinarySHA256915031d77b9609075c58fef2e1fd6bd25dcfadbb933f940a8319dde7148c728e.
All tests/orientation/Peekaboo processes completed. No fulltransformstyling,
Copy-mode interaction or arbitrarycirclehandle parityclaim.

Publication verified after reconciliation: master-handle-corrected.docx has25 embedded images; exact SHA256 matches final-outward, final-reopen-values-valid and native-reopen-values-valid PNGs. No duplicate reinsertion. Original illustrated Doc remains blocked at76 verified images.
