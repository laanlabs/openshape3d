# Fresh line sizing anchor — September 10, 2026

Baseline `02e0cd2`; exclusive desktop/build owner is this dedicated session.
Preserved `05be744` IPA unchanged. This is a narrow correction, not QA closure.

## Paired diagnosis

Native Shapr3D1924, Top,5mmgrid: fresh forward stroke global(980,680)→(1130,680),
39.5456mm, edited20mm. Window-relative left endpoint(881,601) staysfixed;
right(1031,601)→(957,601). Reverse stroke(1130,750)→(980,750),39.5456→20:
right/start(1031,671) staysfixed, left(881,671)→(955,671).
After Escape and reselecting that reverse line,20→10 instead holds LEFT(955,671),
right moves1031→993. Therefore creation and reselection must NOT be generalized.

Clone6492 latest02e0cd2: fresh forward and reverse lines2→1mm both center-shrink:
x220/382→261/342, y577 and739. Screenshots inspected after each commit.
Native and clone zoom differ; endpoint positions within each unchanged view establish anchoring.

## Excluded attempts

Initial native gestures on left canvas created no geometry; later right-canvas
stroke succeeded. No anchor inference from these attempts. `peekaboo press l`
is invalid (letter shortcuts require another supported route); explicit palette works.
First forward text input ran12seconds; Return was issued before it completed,
so initial field/result excluded. Retried with inspected20 field and settled Return.
An extra9 caused by stale coordinate click was replaced before valid commit.

## Implementation under test

Fresh standalone first dimension only: transient drawing entity ID, cleared with
line chain cancellation/tool change; prefer endpointA in solve. Saved constraints
win if preference fails. Excludes cross-entity relationships, preexisting dimensions,
reselection without creation intent, and rectangle handling. Refresh chain endpoint
after successful numeric size so continuation uses the new end. No persisted Lock.
Reselected-line anchor rules, connected-line sizing, broader orientation and device
input remain open pending controlled comparisons.

## Regression/execution

Serial /tmp/os3d-fresh-line-anchor-20260910.xcresult running; exec55882 owns simulator.
RectangleConstructionTests,DimensionKeypadCommitTests,new forward/reverse anchor UI,
and keyboard focus recovery UI. No result yet. Live post-fix/publication pending.

Evidence local reports/.../line-sizing-anchor/ with SHA256SUMS; all original attempts retained.
Key valid screenshots: native-right-draw, native-forward20-valid, native-reverse-release,
native-reverse20, native-reselected10; clone-forward-release/forward1/reverse-release/reverse1,
all prefixed os3d-anchor-. No new Google Doc insertion yet; verified baseline298/master38.

Initial run:33 tests,31 passed/2 failed cases (3 assertions total) (UI missing Keypad-/;
actual buttonKeypad-÷, plus two sloped-direction assertions in one geometry test).
KeyboardUI and9keypad cases passed. Free sloped solve rotated despite startanchor;
product scope now requires existing H/V relation. Unit coverage now checks both
horizontal/vertical directions and savedendLockfallback; freeangle sizing remains open.
Corrected combined rerun /tmp/os3d-fresh-line-anchor-final-20260910.xcresult pending.

## Corrected final result and live recheck

Corrected combined run clean33/33:22construction+9keypad+2UI; exec75430exit0.
Updated installed clone freshly launched, no test runner. Freshforward2→1 holds
x221 at y295, end382→302. Reverse2→1 holdsx382 at y577, other220→302.
ToolbarUndo2/Redo1 inspected. Newvertical joins resizedend(302,577)→(302,739).
Aftergalleryreopen bothhorizontal lengths1mm and verticalcontinuation persist.
NativeUndo20/Redo10 after prior reselection inspected; galleryreopen forward20,
reverse10 retained. Native continuation attempt only leaves a point/unconfirmed
segment, NOT persistent joined-segment evidence; comparison remains open.

Initial illustrative diagnosis302 placements/all4hashes/no predecessorloss verified
at /tmp/os3d-anchor-diagnosis-publication.docx. Final4images prepared, not yet published.
H/V savedconstraint presence now required for product preference; vertical is
unit-covered only, horizontal forward/reverse is paired live. First-size only;
reselected second sizing, freeangles and cross-entity constraints remain outside scope.

Final illustrated publication306 placements/all4final hashes exactlyonce/no
predecessor loss verified at /tmp/os3d-anchor-final-publication.docx. Master
Fresh-line anchor checkpoint appended; export verification pending.

Master38 placements/newdatedheading once/prior keyboard note and media retained;
export verified /tmp/os3d-anchor-master.docx.
