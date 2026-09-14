# QA-36 intersecting-circle Tangent — September 12, 2026

Baseline c007c0a. Native Sketch12Top shallow R8000/R5000 pair at
950620/1010620 (distance9453.7983mm) resolves to external contact,
first center927620, second unchanged. Deep overlap at950450/980450
(distance4726.8982mm) resolves internally, first961450, second unchanged.
Both preserve visible radii and clear selection. Existing nested pair untouched.
Clone shallow pair400730/460730 radius50/30px has disabled Tangent.
Evidence under durable constraint-types/qa36-overlap-tangent-live-2026-09-12.

Before regression0/1 confirms missing capability/application. Product now
admits intersecting circles and selects nearest radius-difference/sum contact;
the exact halfway tie defaults external (not yet native-observed). Equal-radius
contact remains external; coincident equal circles and arc pairs unsupported.
Source76dd2b0 pushed. Focused three-case gate passed3/3, zero failures/skips
at /tmp/os3d-qa36-overlap-focused-20260912.xcresult. Combined94-case
gate running exclusively exec82688; all87 model checks passed, seven UI
workflows pending. Changed-build paired history/reopen/publication next.
No closure claim yet.
Reports985/master38; inventory26/0/1/29; physical iPad unchanged.

## Changed-build live and final gate

Source76dd2b0 final94/94 passed, zero failures/skips, one serial run:
52application+19merge+6polish+10Trim+7rail UI. No runner.
Matched LastSelected after tests left FirstSelected. Initial immediate post-sheet
Circle attempt instead orbited; discarded and repeated from settled Top view.
Shallow clone diameters1.2324/0.7358 centers400730/460730 apply external,
first381730/secondunchanged. Deep diameters1.2398/0.7358 centers200730/230730
apply internal, first210730/secondunchanged. Deep creation initially dragged
outer annotation; retry from clear start created inner. Captures distinguish
attempts. Both branch Undo/Redo preserve geometry/radii; gallery reopen retains
both Tangent records and inner0.7358. Native deep Undo restores overlap,
Redo contact, no orange highlight in this run; both branches survive gallery
reopen, deep innerR5000 exact. Earlier native Redo-highlight ambiguity is not
retrospectively resolved. Eleven images and notes inserted into both reports;
anonymous export verified996 unique illustrated images, all11 hashes once,
headingonce/no985loss; master38 headingonce/no loss. No runner. Nextequal-radius
overlap and exact halfway boundary comparison; QA36partial26/0/1/29.
