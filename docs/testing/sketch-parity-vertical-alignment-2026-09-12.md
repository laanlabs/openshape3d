# QA-36 Vertical alignment — September 12, 2026

Status: confirmed paired gap, correction implemented; focused four-case gate4/4 passed. QA36 partial26/0/1/29. iPad/immutable05be744 unchanged.

Native fresh500350→530450, Last Selected and Auto-Constrain off. Horizontal/Vertical on the steep line aligns500350→500454, preserves50272.4354mm and first endpoint, clears selection. Reselect confirms exact length. Undo restores slope/deselects; reselect then Redo restores Vertical/deselects.

Clone450300→480400 releases1.3009mm, Vertical moves both endpoints to465300→465400, shortens1.2464mm and retains selection. Same Last Selected/acquisition/Auto off state as preceding Horizontal fixture.

Before-source regression0/1, six geometry/selection assertions fail. Correction extends the already verified ordinary-line axis placement to Vertical, preserving signed axis direction and original length about endpointA; existing saved system remains authoritative. No persistent additional driver. Cleanup extends only single whole ordinary-line Vertical. Two-point and rectangle variants are unchanged.

Logs/xcresults: /tmp/os3d-qa36-vertical-{before,focused}-20260912. Durable screenshots: /Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/constraint-types/qa36-vertical-alignment-live-2026-09-12. Changed-build live/final regression/publication pending. Existing illustrated1099/master38 unchanged.
