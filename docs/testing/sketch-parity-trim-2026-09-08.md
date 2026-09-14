# Basic trim acceptance — September8,2026

Revisione82b9e4; native Front and clone Top landscape; mouse Peekaboo.
Evidence workspace core-sketch-milestone-2026-09-08/trim. Original snap settings
restored (both Auto-Constrain on, native guide categories off, clone all on).

Crossing lines: native near-horizontal350,190→603,196 with vertical473,167–225;
trim righttail550,195 leaves left350→473 and vertical unchanged. Clone horizontal
168–389,y256 with vertical278,201–284; trim330,256 leaves168→278 and vertical
unchanged. Other geometry stable through trim. `native-cross-before/after.png`,
`clone-cross-before/after.png`. Sampled paired pass, not full reference-integrity
or history matrix. Native horizontal fixture was slightly angled after creation;
trim correctness is intersection span removal, not initial H relation parity.

Circle crossing: native400mm circle centered848,182, horizontal line761–934 at182;
trim upper arc leaves lower semicircle and entire crossing line. Clone circle
center581,256,radius55px; line498–664,y256; trim top581,202 leaves lower arc and
crossing line. `native-circle-before/after.png`, `clone-circle-before/after.png`.
Sampled paired pass for circular span trimming. No product change/tests this batch.

During clone circle-line creation, automatic Equal relation linked a previously
created near-equal-length line and slightly shifted that existing line. This is a
candidate separate auto-inference discrepancy, not attributed to trimming. Exact
paired near-equal-line reproduction next. Native shortcutL did not arm Line;
explicit More→Line did. Do not treat attempted shortcut as successful input.

Publication pending existing Google Doc save blockage (six prior snap/lock images
still unsynced); no new trim inserts until editing resumes. Local evidence kept.
