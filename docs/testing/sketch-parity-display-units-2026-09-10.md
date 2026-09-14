# Display-unit switching and imperial annotations — September 10, 2026

Baseline eaf6847 pushed. Native1924 selected circle20.32mm and clone6492 landscape
selected circle1.016mm. Native View > Units > Centimeter changes readout2.032cm
without moving circle; original0.025ft+0.5in source retained. Clone Settings cm
changes readout0.102cm (rounded), geometry fixed, source0.00125ft+0.025in retained.
Recommitting unchanged source leaves geometry fixed. Native Inch0.8quote and
Foot0.0667apostrophe retain geometry. Clone inch0.04in and foot0.003ft retain
geometry but show different compact notation/precision. Screens:
/tmp/os3d-display-units-{native,clone}-{cm,source,inch,foot}.png, with native cm
settled frame at /tmp/os3d-display-units-native-cm-settled.png.

Invalid/limited routes retained: native View > Units only opens submenu, not a
setting; coordinate click did not change units. Full menu path succeeded.
Standalone menu-window capture failed; full-screen inspection identified submenu,
but full-screen capture includes unrelated desktop and is NOT publication evidence.
Clone Settings icon-center905,148 was ignored twice; offset914,148 opened the sheet.
That hit-target discrepancy remains separate and unresolved.

Confirmed correction: compact imperial annotation now uses quote/apostrophe suffix
and four decimal rounding (native feet sample). Input tokens in/ft, unit picker,
ordinary measurement rows, source evaluation and stored geometry unchanged.
Metric compact formatting unchanged. Existing AppSettings format test expanded
with native/sample values and input-token separation. Serial30209 runs settings,
parser and keypad tests at /tmp/os3d-imperial-annotation-20260910.xcresult and.log.
No live post-fix evidence yet. No physical installation; immutable IPA unchanged.

Clean45/45 settings/parser/keypad tests, zero failed/skipped, exec30209exit0.
Updated clone8787 live Foot0.0033apostrophe and Inch0.04quote readouts inspected;
source unchanged through recommit. Final clone gallery reopen retains Inch units,
0.04quote and full source. Native gallery reopen retains Foot0.0667apostrophe and
source0.025ft+0.5in. Re-entry reframes camera; no assertion of identical viewport.
Native initial --click-count2 was rejected before execution; corrected --double
opened project. Trial prompt skipped via explicit Limited Version, no purchase.
Native saved keypad now offersft/in, whereas clone retainsmm/cm/m; next confirmed
unit-row gap. No runner. Seven publication images prepared, verification pending.

Publication verified: illustrated380 placements/all7 new hashes exactlyonce/no
predecessor loss in /tmp/os3d-imperial-annotation-publication-final.docx. First
export373 was stale; no duplicate inserts. Master38 media/new+prior notes and
final paired reopen statement verified in /tmp/os3d-imperial-annotation-master.docx.
No runner remains. Next imperial keypad unit-row correction; Settings target gap
remains separate.
