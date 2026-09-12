# Visible gap closure and hidden-source control — September 9

Baseline `30625e0`; no code change or new test run in this lane. Existing
ProfileTests clean 15/15 and history/profile-seed clean 5/5 remain supporting
checks, not replacements for this live comparison.

## Paired visible gap

Native Sketch03: outline 550,550 → 650,550 → 650,650 → 550,650,
with final side drawn 550,570 → 550,650. Clone Sketch2: 300,650 →
450,650 → 450,750 → 300,750, with final side 300,670 → 300,750.
Both leave a visible 20-screen-pixel gap. Different zoom/model sizes and aspect
ratios: this is not a tiny-gap tolerance boundary or identical geometry claim.
With source outlines explicitly visible, interior taps do not select a profile.

Connecting the two gap endpoints produces a selectable closed region in both.
Native offers Extrude; clone opens the extrusion preview, cancelled without
creating a body. Undo removes closing segment and fill; Redo restores both.
Gallery reopen retains closed region and original bore solid in both apps.
Native reopen defaults oblique; clone does likewise. No physical device claim.

Evidence: os3d-gap-native-no-profile.png and
os3d-gap-clone-visible-no-profile.png; paired closed-profile, undo (clone
undo-settled), redo and final-reopen PNGs in durable transform-controls reports.

## Corrected visibility diagnosis and excluded attempts

Initial clone no-profile screenshot had a hidden consumed source and is NOT
valid gap evidence. Unhiding Sketch2 yielded the valid visible-outline check.
Native initially left its source visible, which suggested a visibility mismatch.
Controlled check: explicitly hide native Sketch03; named entry renders it while
editing but retains the hidden eye; Exit hides it again. This matches clone.
Earlier observation was a state mismatch, not a confirmed code defect. No
visibility code change. Evidence consumed-native-explicit-hidden, hidden-opened,
hidden-exit. Rapid unhide/row click entered rename, no text changed.

Native initial fourth-side attempts from selected endpoint did not persist;
reversed free-start drawing after reset succeeded. These attempts are excluded
from geometric acceptance, not evidence of a native defect. Closing segment
succeeded after Escape, blank deselection and rearming Line.
Clone first rapid cancel/Undo/interior tap still showed closed profile. A second
cancel, inspected settled screenshot, then Undo visibly removed closure; Redo
restored it. Preserve this input timing observation, no speculative history fix.

## Scope and publication

Sample passes visible-gap rejection, explicit closure, history and reopen.
Tiny tolerance boundary, touching loops, duplicate edge, construction crossing
and self-intersection remain open. No new implementation needed here.
Google Doc addendum/images pending export verification; prior illustrated151
and master38 remain last verified publication counts.

Final publication: illustrated155 embedded images, all4 new closure/reopen
PNG hashes and corrected prose verified by DOCX export. Master38 retains final
reopen/visibility correction note. Export copies retained locally.
