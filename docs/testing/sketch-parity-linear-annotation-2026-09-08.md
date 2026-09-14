# Standalone line annotation — September8,2026

Baselinea974343. Native horizontal900 line425–543y563 shows below-line black
leader/arrows, plain horizontaltext. Fresh native downwardvertical950450→950600
shows1145.7745mm, leaderleftx880, textfurtherleftx865 rotatedupright. Line remains
blue while Line tool armed. Clonevertical350249→350450 shows3.315mm horizontal
badge and dashedgeometryoverlay, orange after priorcolorchange.

Confirmed corrections: standalone line offsetleader/arrows/plainrotatedtext,
and restore blue whiledrawingtoolarmed (orange forselectedgeometrytooloff).
Rectangle loops and point-to-point dimensions deliberately retain existing
layout pending respective comparisons. Arc curvedleader untouched.

Serial DimensionUITests running exec42207,
/tmp/os3d-linear-annotation-20260908.xcresult/.log. No post-fix live pass yet.
Vertical text side requires specific inspection: reference text is farther left
than leader, unlike horizontal text above its leader. Fullmanipulationring and
endpoint halos remainopen. Evidence linear-ui/ screenshots retained.

Initial standaloneleader DimensionUI suite clean5/5 passed, exec42207exit0.
After run, vertical text anchor corrected to sit farther left of leader as native
reference shows; horizontal anchor unchanged. This small display-position follow-up
gets build+livevertical validation; not claiming the prior UI run covered final
vertical placement. No new solver/geometry logic. Master11images includes native
vertical reference with exact PNG hash verified in exportedDOCX.

First final livevertical FAIL: leader right of line, notnativeleft. Nearzero
projected dx exceeded absolute0.001threshold and reversed canonical direction.
Relative1% slope classification now handles nearvertical before ordering bydx.
Failed screenshot os3d-linear-final-vertical.png retained; build/live repeat next.
UI5/5 did not detect this visual projection error; no unsupported passingclaim.

Direction tolerance build passed but was not installed/live-claimed. Extracted
screen layout into SketchLinearDimensionLayout and normalized nearvertical text
rotation too (otherwise opposite tiny dx signs reverse reading direction). Added
regression for observed +/-0.01projectiondrift, endpointreversal, horizontal
placement and degenerateprojection. Serial3unit+1lineUI runexec22863
/tmp/os3d-linear-direction-regression-20260908.xcresult before live repeat.

Targeted regression clean4/4 (3layoutunit+1lineUI), exec22863exit0.
Prior5/5UI passed before live visualfailure; failure and intermediatebuilds retained.
Orientation/launch92419 nowownsdesktop; livecorrectionnotyetverified.

Final live repeat passed sampled orthogonal directions: vertical350249→350450
3.315mm leaderleftx315, textfurtherleftx303 upright; armedLineblue. Freshhorizontal
500–650y4992.473mm leaderbelowy535, plaintextabovey523. Explicittexttap opens
keypad,3mmcommit resizes to484–665y499 andleadertracksendpoints; verticalunchanged.
Disarm+selectverticalorange, textopenseditor,Escapecloses withoutvaluechange.
Initial selection attempt added bothlines (90° candidate); cleared/reselected
verticalalone forvalidsample. Nativehorizontal900/vertical1145.7745 screenshots
providepairedplacementreference; scalesdiffer. Finaltext/keypadpassed; broad
sloped/edge/rectangle/persistentlabelmatrix remainsopen. Fullblue ring remains.

Master13images verified by anonymousDOCX and both correctedPNG hashes; historical
heading inspected intact. master-linear-corrected-publication.json/.docx local.
Finalsimulatorbinary8a684796d7fc7169aefce0fc8ce8c4e4d72d553b9d58855c7bd75ec3685db5a8.
