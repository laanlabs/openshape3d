# QA-36 Vertical alignment — September 12, 2026

Status: source9466502, final110/110 passed; changed live/history/both reopenings verified. Publication1109/master38 verified. QA36 partial26/0/1/29. iPad/immutable05be744 unchanged.

Native fresh500350→530450, Last Selected and Auto-Constrain off. Horizontal/Vertical on the steep line aligns500350→500454, preserves50272.4354mm and first endpoint, clears selection. Reselect confirms exact length. Undo restores slope/deselects; reselect then Redo restores Vertical/deselects.

Clone450300→480400 releases1.3009mm, Vertical moves both endpoints to465300→465400, shortens1.2464mm and retains selection. Same Last Selected/acquisition/Auto off state as preceding Horizontal fixture.

Before-source regression0/1, six geometry/selection assertions fail. Correction extends the already verified ordinary-line axis placement to Vertical, preserving signed axis direction and original length about endpointA; existing saved system remains authoritative. No persistent additional driver. Cleanup extends only single whole ordinary-line Vertical. Two-point and rectangle variants are unchanged.

Logs/xcresults: /tmp/os3d-qa36-vertical-{before,focused}-20260912. Durable screenshots: /Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-vertical-alignment-live-2026-09-12. Final110/110 clean (103model/integration+7UI), zero failures/skips. Publication1109 unique/master38; ten hashes once, headings once, no1099/38 predecessor loss. DOCX exports/manifests/verification retained beside screenshots.

## Changed-build verification

Explicit Last Selected/acquisition/AutoOFF after final UI fixture. Fresh
450300→480400 releases1.3009mm; Vertical now450300→450405, deselects.
Reselect shows1.3009mm and V glyph; Undo restores slope/deselects; reselect
then Redo restores Vertical/deselects. Gallery reopen retains glyph/value.
Saved JSON Vertical/unrelated Parallel, dimensions0. Native gallery reopen
retains50272.4354mm at fitted527352→527453. Reentry Top required a second
settled click; both screenshots retained, no false first-click claim.
