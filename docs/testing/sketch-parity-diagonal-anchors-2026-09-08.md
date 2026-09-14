# Diagonal sizing anchor correction — September 8, 2026

## Scope and correction to earlier conclusions

Base02a50fa (circle release7400e01). Paired live native Shapr3D vs portrait
simulator via Peekaboo mouse. This revisits SK-03/QA-08, not center rectangles or
three-point rectangles. Earlier September7 down/right **width-only** comparison
supported left-side preservation, but was incorrectly generalized to first-corner
preservation for both axes/all drag directions. Preserve the historical receipts;
this reference check supersedes that broader conclusion.

## Reference and clone diagnosis

Evidence directory:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/quadrants/`.

1. Native Top, up-left drag from450,230 toward300,150: released bounds approx
   x300–443,y150–230, width320,height180 mm. Width320→160 keeps LEFTx300, moves
   right443→372. Starting bottom-right corner does not stay fixed.
   `native-up-left-release.png`, `native-up-left-width160.png`.
2. Repeat on otherwise empty native Front Sketch02, away from Top sketch's
   edge-on geometry: up-left drag550,350→350,250. Released boundsx342–550,
   y251–350,width624.6921,height298.5689 mm. Width→300 holds LEFTx342 and moves
   right550→442. Reselect right edge after exiting/re-entering: height→150 holds
   BOTTOMy350, moves top251→300; width retained. `native-front-up-left-release.png`,
   `native-front-up-left-width300.png`, `native-front-up-left-height150.png`.
3. Native Front reverse-direction check: down/right drag800,250→1000,360,
   releasedx807–1000,y251–360,width580,height330. Height330→165 keeps BOTTOMy360,
   moves top251→306, despite original first corner being at top-left.
   `native-front-down-right-release.png`, `native-front-down-right-height165.png`.
4. Clone Top up-left drag420,760→220,600: releasedx221–423,y617–780,2.5×2 mm.
   Width2.5/2→1.25 holds RIGHTx423 and moves left221→321. Confirmed mismatch.
   `clone-up-left-release.png`, `clone-up-left-width125-beforefix.png`.
5. Clone Top down/right drag140,470→290,580: releasedx140–302,y456–577,2×1.5 mm.
   Height→1 holds TOPy456, moves bottom577→537. Confirmed mismatch.
   `clone-down-right-release.png`, `clone-down-right-height1-beforefix.png`.

All coordinates above are screenshot/window-relative pixels, rounded; scale and
planes differ, comparing anchor semantics. Inspect settled captures after1–2s.
This does not establish all constrained/rotated/mirrored rectangle policies.

## Implementation

Direct diagonal width/height sizing now prefers normalized lower-left (min/min),
not whichever corner began the drag. Existing persisted creation-corner values
still identify diagonal vs center; no migration or destructive rewrite. The
preference is transient and falls back to ordinary solving if explicit relations
make it incompatible. Center and legacy/no-metadata behavior unchanged. Three-point
side-preservation unchanged. Ordinary dragging remains unchanged.

Regression updated from the incorrect first-corner assumption: all four drag
quadrants, both axes and expansion after reload now check stable lower-left.
Translated rectangles check their current lower-left. Explicit-lock fallback and
center tests retained. UI width test now draws up-left and verifies an extrudable
profile near the left side, distinguishing the failed previous behavior.

## Verification and publication

One clean 22/22 run passed (14 RectangleConstructionTests, 8 RectangleWorkflowUITests),
no failures, skips or targeted reruns; finished08:06:30 EDT:
`/tmp/os3d-milestone-diagonal-anchor-20260908.xcresult`.
Summary retained as `diagonal-test-summary.json` in the evidence root.

Post-fix live reverse drag width2.5→1.25 mm holds leftx221 and moves right423→321;
height stays2 mm. `clone-up-left-release-fixedbuild.png`,
`clone-up-left-width125-fixed.png`. Down/right height1.5→1 mm holds bottomy577,
moves top456→496; width stays2 mm. `clone-down-right-release-fixedbuild.png`,
`clone-down-right-height1-fixed.png`. Both match native anchor samples above.

Tested simulator executable SHA256:
`baa7963a0f87d8242aa1e009124258500bb66490fbfa3786fd92b589b17972f2`.
Not a physical-device artifact. Full mixed-quadrant live, layout, constraint and
history acceptance remain open; not candidate-ready.

Illustrated Google Doc anonymous DOCX export verified58 inline images, corrected
text, and both corrected PNG hashes. Initial export caught57 images before final
upload synchronized; subsequent export verified58 and both images. Master roadmap
correction also verified by anonymous text export. Local artifacts:
`published-anchor-fixed.docx`, `anchor-fixed-publication.json`,
`master-roadmap-anchor-fixed.txt`. Historical diagnosis and audit preserved.
