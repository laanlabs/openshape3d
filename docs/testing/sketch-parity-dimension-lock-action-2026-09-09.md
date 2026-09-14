# Dimension keypad lock action — September 9, 2026

Baseline480bbeb pushed. Native freeØ1000 at964529 keypad lock1054460 immediately
adds driving size and dismisses/clears selection. Reselect/open shows closed
lock. Draft2000 makes lockgray/disabled; clicking leaves draft/geometry unchanged.
Escape discards draft, restored1000. Openunchanged/lock removes stored dimension
and dismisses/clears selection; CmdZ/reselect/open restores closed lock and1000.
Nativetip dismissed, no purchase. Paired cloneØ1 draft2 lock toggles pendingmode
while editor stays; unchangedlock also requiresCommit (previousreceipt).

Implemented actual lock-state display, disabled changed-draft key, immediate
add/remove measured driving dimension without solve/geometry mutations, selection
clear and undoable document commands. Ordinary typed Commit retains driving
semantics. Unit covers unchanged geometry/add/remove/UndoRedo/dirtyguard; UI
checks draftdisabled, immediate dismissal, freed radial resize. Regression and
live postfix/publication pending. Native current original1000padopen; clone reset
when tests launch. No overlapping desktopworker.

Serial56523 completed clean12/12:9unit+3UI. Native line1750.6361 endpoints
312267/348310 also locks immediately/dismisses, endpoints unchanged. Fresh clone
Front circle430450 Ø0.992: open pad shows unlocked; lock510455 closes editor/
clears selection immediately. Reselect/open shows closedlock0.992. Draft2 grays
key; actual click does nothing, geometry unchanged. Escape cancellation under
inspection. Illustrated127 diagnosis pair hashes verified. Postfix/history/reopen
publication not yet signed off.

Live clone continued: Escape cancels draft2 back to0.992. Unchanged-key unlock
dismisses immediately; reselect radial drag firstattempt no effect, settledrepeat
onepixel higher changesØ0.992→1.985. Undo restores0.992; secondUndo restores
closedlock in pad. Keep rapidinput caveat; no false firstattempt pass. Freshline
300600→350640 length0.793, openpad/lock385625 closes withoutmovingendpoints.
Galleryreopen/Sketch1: linepad0.793 closedlock; circlepad0.992 closedlock. First
switchfromlinepad dismissedonly, secondseparatecircle selection works. Native
finalreopen stillbeingcaptured.

Final native gallery reopen inspected: circle Ø1000 and line1750.6361 both
show closed locks. First click away from an open keypad only dismisses it in
BOTH apps; the next click selects the other entity. This corrects any implication
of a clone-only selection gap. Native final circle screenshot:
/tmp/os3d-dimension-lock-native-final-circle-pad.png.

Final visual-only adjustment uses primary neutral tint for both lock states,
matching native instead of blue. Build53633 passed, installed/relaunched without
resetting the saved design; live reopened circle Ø0.992/closed neutral icon
verified in /tmp/os3d-dimension-lock-tint-final-pad.png. Clean12/12 regression
precedes this tint-only adjustment; no claim of another combined test run.
Evidence copied to workspace report transform-controls directory.

Publication verified: illustrated130 images, all3 final PNG hashes matched;
master38 images with final gallery-reopen and tint notes exported.
