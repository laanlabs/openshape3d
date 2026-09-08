# Three-point rectangle leaders — September8,2026

Baseline8bf9568. Nativeangledbaseline920,450→1045,490 plusheight800: solid
leadersoutsidebaseline(above) andheight(right), rotatedplaintext/arrows.
Clone500,470→650,510 height1.244: tinyborderedbadgesalongedges, nogenuine
offsetleaders. PairedPNGsinrectangle-ui/os3d-three-leader-{native,clone}-release.png.

Correction recoversisolatedrectloop, places100logicalpointleadersawayfrom
projectedinteriorcenter. Otherline/axisrectlayoutunchanged. Ordinaryfourlines
andconstraintsretained. Outwardnormalunit testbothdirections/height sides plus
threepointheight/history/profileUI planned. PublicationblockedbothDocs.

Serial76327 completed0 clean6/6:4layout+2UI (height29.565s,profile23.742s). Orientation35055 ownsdesktop; finalpairedlivepending. Localvisual-corrections-2026-09-08.md index supplementsfullaudit.

FinalcloneFront outsidebaseline/heightleaders matchreferencearrangement.
Height1.244→1 retainsbaseline2.565 andfar loweredge; baseline→2 retains
height1, bothlabels/keypadsusable. Nativeheight800→400 holdsfar loweredge,
baseline1520.2328 remains. Nativebaseline→1200 thenholdsRIGHTside instead
ofcloneLEFT. This is a newlyobserved sequentialanchor discrepancy, not a
paritypass. Nativeprebasecorners909,483/1035,523/1024,555/899,516; after
935,491/1035,523/1024,555/925,524. Clonebaseeditfixedleft495,484/480,542.
Investigate edge/reference/sequence dependence separately; do not undo a
verifiedpresentationfix or generalizeonebaselineanchorrule. Nativeclears
labelsaftercommits; doubleclickedge restores relevantreadout.

No tests/Peekaboo workers active. BothDocsSavingblocked; allnewthreepoint
evidence localonly, notpublished.

## Baseline-only diagnosis, approximately 16:40 EDT

After undoing both numeric edits, native original 1520.2328 × 800 rectangle
was selected with the drawing tool off. Editing its top baseline to 1200
held right endpoints (1045,490)/(1024,555); left endpoints moved to
(946,458)/(925,524). Undo, select the opposite bottom edge and enter 1200
produced the same anchored result. Thus neither prior height editing nor
which parallel edge was selected explains this sample. Clone undoing both
edits restored 2.565 × 1.244; baseline-only 2 held left endpoints
(500,470)/(480,542), with right endpoints moving to (617,501)/(597,573).
Screenshots saved under rectangle-ui/os3d-anchor-*.png. No solver changes
yet: an isolated fresh native sample remains necessary to reconcile the
earlier left-held reference. Publication remains pending, not verified.

Fresh disconnected native samples clarify the geometric rule: descending-right
baseline 1686.5472→1200 holds right (690,220)/(676,270). Reversed draw
direction, same slope, holds right (1050,170)/(1036,220) too. Opposite
slope holds left (250,600)/(264,650), moving right to (350,572)/(364,622).
Thus sampled baseline sizing holds the lower adjacent side, not the first or
second drawn endpoint. Clone currently always preserves its first side.
Implemented transient lower-side baseline preference, including opposite
parallel-edge selection, with horizontal left tie-break; explicit constraints
retain solver priority. Regression 72820 running exclusively: construction
geometry plus two three-point UI workflows. Post-fix live repeat pending.
