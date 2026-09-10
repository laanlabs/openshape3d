# Center rectangle remaining matrix — September10,2026

Baseline3eb9c9b pushed; no newcode/test run for firstsample. NativeFront mouse,
cloneTop portraitsimulator, differingzoom; no exactdeviceequivalence claim.
RetainedSep8 up-leftwidthfirst andearlierheightfirst not repeated asnewcoverage.

Mixedright-up centercreation, widththenheight:
- Native centerlocal600,420; corners535,377–665,463,12×8. Width6→corners
  567,377–632,463; height4→567,398–632,442. Centerunchanged, prior4rectanglesintact.
  Nativewidthclick699,598 openedseed12; key6/commit; disarmEscape/rightedge731,499
  thenheightreadout817,499 openedseed8; key4/commit. No inputfailure.
- Clone centerlocal251,620; corners201,580–301,660,1.234×0.989. Widthseed/2
  yields0.617/corners225,580–276,660; heightseed/2 yieldsdisplay0.495/corners
  225,600–276,640. Centerunchanged; prior2rectanglesintact. Bothbadgeeditorsusable.
  Explicitexpressionsretained/f(x), notsame sourcemethod asnative literalhalf.
- Geometrysamplepasses. History/reopen for thissamplepending. No globalQA09pass.
- ReleaseUI followup: native newlycreatedcenterselectedorangehalo/padlock, clone
  plainbluedot/no padlock. This is observed in mixed-beforepair, needs isolated
  confirmation beforeproductchange. Nativeinitialheightleader right, cloneleft;
  retainvisibilitydifference, notexactUIclaim.

Evidence `reports/.../center-matrix/os3d-qa09-*.png`, SHA256SUMS. PublicationGoogle
signedout; localonly. Lastverifiedillustrated466/master38. ImmutableIPAunchanged.

Bothapps twoUndo/twoRedo restoreheight/width in sequence, centerunchanged, exact
priorbounds. Clone retainsselection; nativeclear. Newoppositemixeddown-leftnative
center creation initiallyfailedinput (cursoronly, no newgeometry), includinginset
retry. Exit/re-enter+edgepick recoveredselection. Rapidmenuattempt accidentally
armedLine, no newgeometry; excluded. Explicitsettledmenu/CenterRectanglethen
samedrag1149,599→1099,639 created10×8 centeredlocal1050,520, corners996,477–1104,563.
Againnative orangehalo+directpadlock onrelease. Directpadlock1149,640 lockedcenter
green, clearedreadouts/selection, leftCenterRectanglearmed. Prior5rectanglesintact.
Clone down-leftcenter460,720→410,760 created1.241×0.985, corners410,680–511,760;
plainbluecenter/no padlock. Bothcreation pairs confirmreleasegap. Leadersalso
differ: native up-rightwidthbelow/heightright, down-leftwidthabove/heightleft;
clonebothsampleswidthbelow/heightleft. Leadercorrection separatepending.

Releasefix implemented (drag andtap centercreation selectedpoint; padlockavailable
whileCenterRectanglearmedandnoplacementpending; directLockclearsbothselectionsets).
Firstselectorwrong RectangleToolUITests: buildsuccessbutZEROtests, xcresultunknown
/tmp/os3d-qa09-center-release-20260910.xcresult. CorrectclassRectangleWorkflowUITests
focusedrun88858 nowowns simulator, resultcorrectedxcresult. No post-fixliveclaim.

Correctedselector run failed1/1 at initialDimensionLabelassertion: selectedcenter made dimensionCandidate requirepts.empty fail. Productregression, notfixture. Narrowcandidateallowance for matchingreleasedcenter/tool/entityselection added; rerunning.

Corrected candidate run passed 1/1, 46.481 seconds, zero failures/skips:
`/tmp/os3d-qa09-center-release-labels-20260910.xcresult`. This is a targeted
pass following the retained product regression, not an initially clean batch.
Combined RectangleConstructionTests plus release and center movement/history UI
checks now run serially (exec 9834):
`/tmp/os3d-qa09-center-release-combined-20260910.xcresult`. Live repeat pending.

## Release correction verified — September 10, 13:53 EDT

Final combined run passed clean **26/26** (24 RectangleConstruction tests and
2 center UI workflows), 87.869 seconds, zero failures/skips:
`/tmp/os3d-qa09-center-release-combined-20260910.xcresult`. No runner remains.
The earlier zero-test selector and failed focused run remain above.

Exact-build live clone right-up release at center local251,620 shows orange
center halo, direct padlock and both1.234×0.989mm readouts without a keypad.
Direct padlock click locks only the center (green), clears labels/selection,
and leaves Center Rectangle armed. Toolbar Undo makes the center blue; Redo
restores green, with corners unchanged. Native down-left sample similarly
undoes/redoes the direct center Lock in one step, without changing geometry.

Both projects exited to gallery and reopened. Native trial prompt was skipped
(no trial/purchase); Sketch04 re-entry/Normal to Sketch retains all six rectangles,
newest green center and prior6×4 dimensions. Clone saved Sketch1 retains both
rectangles and both center Locks in Items, unchanged bounds. The original
pre-test clone half-sizing sample was replaced by the UI test fixture; do not
claim a final reopen of that specific sample. Its paired history is verified.
Native final clear attempt left the old top edge selected; not a deletion or
geometry change.

Evidence: `os3d-qa09-release-fixed*.png`, native retained/undo/redo/reopen/normal
and clone saved-lock PNGs, plus diagnosis predecessors; copied and hashed in
`reports/.../center-matrix/SHA256SUMS`. Google remains signed out; all new
images are local-only and queued. Release-control fix verified; leader-direction
gap and broader QA09 matrix remain open. Immutable05be744 IPA untouched.
