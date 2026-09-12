# QA-36 Horizontal alignment — September 12, 2026

Status: source f5d82e5 pushed; focused1/1 and locked-driver1/1 passed separately. Final108/108 passed; changed-build live/history/both reopenings verified. Publication verified1099/master38. QA36 partial, inventory26/0/1/29. iPad/immutable05be744 unchanged.

## Paired diagnosis

Native fresh free line500300→600330, Last Selected and Auto-Constrain off (settings matched in preceding Midpoint comparison), exact48028.3119mm. More→Horizontal/Vertical aligns500300→604300, retaining first endpoint and length, clearing selection. Reselection confirms48028.3119mm. Undo restores slope and deselects; reselect then Redo restores Horizontal and deselects. Initial Undo menu attempt while app was inactive was disabled; foreground activation resolved delivery, not a product issue.

Clone fresh350700→450730,1.2897mm. Horizontal moves both endpoints to350715→450715, shortens to1.2361mm and retains selection. Captures distinguish first deselected ready frame from corrected selected ready2 frame.

## Scoped correction

Ordinary single-line Horizontal supplies first-endpoint-preserving, original-length placement to solvePointTransform against the original saved system. Saved Locks/drivers override placement preferences; no extra persistent dimension/constraint is added. Successful application and its Undo/Redo clear selection for this observed line form. Refusal retains existing handling. Vertical and point-pair/rectangle alignment are not changed or claimed by this comparison.

## Regression receipts

- Before source:0/1, six geometry/selection assertions failed.
- Corrected focused1/1: length, endpoint, selection, exact Undo/Redo and JSON.
- Saved endpointB Lock plus driving-length guard1/1: existing endpoint and length survive; exact history restored.
- Combined gate:108/108 clean (101 model/integration +7 UI), zero failures/skips, /tmp/os3d-qa36-horizontal-final-20260912.log and .xcresult.

Durable evidence: /Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-axis-alignment-live-2026-09-12. Publication1099unique/master38; ten source hashes once, headings once, no1089/38 predecessor loss. Manifests and DOCX exports preserved in the durable directory.

## Changed-build live and reopening

Final UI left First Selected; changed live explicitly restores Last Selected,
with acquisition/Auto-Constrain off visibly verified. Fresh350700→450730
releases1.2897mm. Horizontal now350700→454700, clears selection; reselect
shows1.2897mm and H glyph. Undo restores original slope and deselects;
reselect/Redo restores alignment and deselects. Gallery reopen retains value,
first endpoint and H glyph. Saved JSON has Horizontal plus unrelated Parallel,
zero dimensions. Native gallery reopen retains48028.3119mm at fitted
535304→635304. Initial post-trial reentry was delivered during animation;
settled row selection resolved it. No source change after final gate.
