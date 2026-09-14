# Explicit arc transform: saved Lock

September8 ~22:04, baseline4a09b06. Paired native R539.1552mm/180° arc center775446,
Lock shows green endpoints/center; More>Move/Rotate vertical axis1000mm refused.
Rotation handle clicked,45° typed: native reports locked points cannot be moved,
arc remains unchanged (ring indicates attempted45°, not accepted geometry).
Clone direct chord200400→360400, default committedarc R1.241/106.26°,
center280460. Lock+explicitmode; offsethandle280480→280400 moveslockedarc
center to280380. Ringdrag168380→200300 rotateslockedarc by45° withglyph retained.
All pre-fix images local root/arc-transform; native vs clone geometry differs,
comparison is whole-Lock refusal semantics, not construction-angle parity.

## Correction

Point solver supports arc center motion; target starting angle carried separately
only for arcs without whole Lock. Whole Lock retains original center/radius/sweep/
orientation. Endpoint welding remains unsupported; other primitives remainopen.
Serial37654 /tmp/os3d-arc-transform-lock-20260908.log/.xcresult. Initialnewtest
fixture accidentally used180 instead of radians.pi for saved angle; corrected
source while initial binary continued. Preserve initial result; targetedrerun
required. Post-fix live and publication pending; no concurrent desktopinput.

## Verified follow-through, ~22:11 EDT

Initial37654 exit65:8unit+2UI passes, one new unit case failed two assertions
because stored180radians fixture was invalid. Correctedonlyfixture to.pi;
39680 targeted1/1 passed.11 distinct passes across runs, notcleancombined.
Live samearc R1.241/106.26 center280460 refuseslockedmove and45°rotation
withnotice. Unlock rotates45°, UndoRedo restores/reapplies, then40pxrightmove
center320460 retainsR/sweep. Relock+galleryreopen retainsall; freshrotationrefused.
Nativegalleryreopen retainsR539.1552/180° andUnlock atoriginalorientation/center.
No testsactive. Publicationpostfiximage/export verificationpending.

Publication verified: illustrated87 images, native+postfix2PNG hashes match; first86 exportlaggedlastimage, repeat87passed. Master38/finalarc-reopen noteverified. Oldstalledtabs preserved.
