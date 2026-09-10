# Dimension keyboard-mode persistence — September 10, 2026

Baseline7a5c618 pushed; existing05be744IPA unchanged. QA33/40 partial.
Native1924 Sketch02Top10mm: open keypad, keyboard icon switches to compact
keyboard-only editor; Escape dismisses. Reopen same label retains keyboard-only
mode with 123 toggle. Clone6492 saved1.5mm expression: same route switches to
keyboard, Escape dismisses, reopening resets to numeric keypad. Screenshots
inspected in both apps, prefixed /tmp/os3d-kmode-. Different desktop/iPad input
surfaces remain explicit; physical keyboard/Pencil not tested on device.

Correction under regression: move mode preference from DimensionField-local State
to EditorViewModel session state. Reopened keyboard editor acquires focus. No
cross-app-launch persistence assumption or saved geometry/schema change. Existing
keyboard invalid-Return/draft test extended with reopen, seed replacement, Escape,
and return-to-keypad preference. Serial exec82065 owns simulator:
/tmp/os3d-keyboard-preference-20260910.xcresult and .log. No result yet.
Post-fix paired verification and publication pending. Native currently keyboard-only
editor10 open; clone reserved by regression. Initial clone gallery click immediately
after launch did not open; settled repeat did. No app failure inferred.

Initial run failed at reopened first-digit replacement: expected2, observed1.52.
Mode itself persisted, but initial onAppear seeding while keyboard mode was already
active marked the seed as modified. Corrected onChange to distinguish model-seed
assignment from a real draft change. Final rerun exec89300 now owns simulator:
/tmp/os3d-keyboard-preference-final-20260910.xcresult and .log.
Diagnosis text inserted once in illustrated report; two images uploading.

Second run:10 passed/1 UI failure at XCTest synthetic Escape, after reopened seed
replacement passed. Live exact-build Peekaboo Escape after typing2 dismisses the
editor and preserves1.5; reopen retains keyboard mode and selected seed. Returning
to123, Escape/reopen retains keypad mode in clone. Native123 returned to keypad,
but immediate Escape/reopen click left a selected label; settled reopen still needs
capture. Do not claim that last native frame was an open keypad.
Final fixture uses explicit commit for automated editor-lifetime coverage; synthetic
Escape discrepancy remains recorded, no speculative history/cancel logic change.
Serial exec70772, /tmp/os3d-keyboard-preference-commit-route-20260910.xcresult/.log.
Diagnosis publication verified316placements/bothhashesonce/no predecessor loss
at /tmp/os3d-kmode-diagnosis-publication.docx. Post-fix images not yet inserted.

Final commit-route regression passed clean11/11 (10 keypad +1 expanded keyboard
UI), /tmp/os3d-keyboard-preference-commit-route-20260910.xcresult, exec70772exit0.
Earlier runs each10pass/1failure: firstseedappend corrected; secondsyntheticEscape
discrepancy retained. Live native settled keypad reopen now captured and inspected:
/tmp/os3d-kmode-native-pad-reopen-settled.png. Both modes survive dismissal in
both apps for the sampled same-dimension session; app-launch lifetime not claimed.
Four post-fix images inserted once in illustrated Doc; export verification pending.
No runner remains.

Final publication verified: illustrated320 placements, allfourcorrectedhashesonce,
no predecessor loss (/tmp/os3d-kmode-final-publication.docx). Master38placements,
prior scalar note and newkeyboard note once, no media loss
(/tmp/os3d-kmode-master.docx). Local evidence refreshed and hashed.
