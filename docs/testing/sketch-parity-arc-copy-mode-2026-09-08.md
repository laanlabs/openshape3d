# Arc Copy transform-mode continuation — September8,2026

Baseline66cb99b. Paired live native and clone Copy translated a single arc,
retaining original and copied radius/sweep. Native stays Move/Rotate with
controls; clone returned to radial mode because copied IDs reset selection
state. Evidence handle-ui/os3d-copy-{armed,result,native-transform,native-result}.png.

Correction preserves explicitly chosen transform mode across duplicate IDs;
ordinary canvas selection still resets it. Targeted UI checks mode retention,
radius and actual copied position Undo/Redo. Regression/livepostfix pending.
Native Copy remains armed whereas clone resets Copy afterdrag: separate open
interaction difference, not silently claimed identical.

TargetedUI72373 completed0: clean1/1 passed35.365s, /tmp/os3d-arc-copy-mode-20260908.xcresult. Explicitmode retained, radius unchanged, copiedposition Undo/Redo verified. Posttestorientation5704 ownsdesktop; no active tests.

Live postfix: freshFront R0.662/180 arc copiedcenter225,300→405,300. Original/crosslineunchanged; explicitMoveRotate retained. Second move→445,340 works; toolbarUndo returns405,300, sameR/sweep. Smallarc anglelabelnearrotationring remains an annotation gap. No tests/Peekaboo workers remain.

Master export verified28images, all3Copy diagnosis/correction PNGs exacthash; firstexportlaggedcorrectedimage, repeatreadconfirmed. SavedtoDrive status confirmed.
