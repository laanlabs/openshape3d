# Pending report publication — September 10, 2026

Google Docs signed out during the QA-08 post-fix update. Preserve existing tabs.
The illustrated report is read-only; the master says to sign in from another tab.
Restore the authorized Google session through host-owned sign-in. Never request
or put credentials in chat. This blocks publication, not independent parity work.

## Last verified state

- Illustrated: 466 placements / 464 media assets; six QA-08 diagnosis hashes
  present once, no loss from the preceding 460-placement export.
- Master: 38 media assets; last verified note is QA-07 closure.
- Fresh export `/tmp/os3d-qa08-postfix-publication-check.docx` still has 466
  placements and does **not** contain the attempted post-fix heading.
- Leader correction `84ca2aa` is pushed; post-fix publication remains pending.

## Leader correction update to append once

Clean 25/25 regression. Paired down-left top/left and up-right bottom/right
leaders now match. Height-first then width holds bottom/left: native
31 × 19 → 15.5 × 9.5 mm; clone 1.979 × 1.481 → 1 × 0.75 mm. Width Undo/Redo
restores/reapplies in both apps. Gallery reopen preserves final values. Explicit
opposite-edge selection retains priority. QA-08 remains partial; no full parity
or physical-device claim. Immutable 05be744 IPA unchanged.

Images, in order (prefix `/tmp/os3d-qa08-`, suffix `.png`):

1. postfix-downleft
2. postfix-upright
3. native-upright-width155-height95
4. postfix-width1-height075
5. native-reopen-values
6. postfix-reopen-values

Durable copies and full SHA256SUMS are under the workspace report directory
`reports/openshape3d-core-sketch-milestone-2026-09-08/diagonal-matrix/`.
The same six upload files are staged directly in `.openclaw/media/inbound/`.

## Center-control update

Final center run passed clean25/25. Live free/driven translation and history,
locked refusal notice, Unlock and paired saved recovery passed. Final local
center screenshots use os3d-qa08-center-final-* and native-center-* prefixes.
Publish the bounded result, keeping remaining center selection and corner
marker differences explicit.
Keep native center-only Lock distinct from clone whole-rectangle Lock.

## Verification after access returns

Append without replacing prior audit content. Export both reports and verify
heading text, every new image hash, placement count, and no predecessor media
loss before recording publication as complete. Do not duplicate diagnosis images.

### Rectangle corner correction verified (September 10)

Final regression clean **30/30**, zero skipped/failed, at
`/tmp/os3d-qa08-corner-final-20260910.xcresult`: six point-state tests,
23 rectangle geometry tests, one center drag/history UI workflow. Prior31/31
included one additional UI workflow before final styling; do not combine counts.
Only indentation changed after the final build.

Exact-build live clone shows four light hollow corners; left-edge Lock produces
two green left corners and two blue right corners, matching the native sampled
point-state convention. Whole Lock shows all four green hollow. Clone toolbar
Undo returns all corners blue; Redo restores partial green without geometry
movement. Gallery reopen retains partial Lock and marker states. Native latest
hotkey Undo sample reselected the edge but did not visibly clear Lock; therefore
that particular native history repeat is inconclusive, not a paired history pass.
Native partially constrained edge colors still differ from clone and remain open.
Center-point selection/Lock scope remains open; QA08 remains partial.

Final captures: `native-corners-left-locked`, `final-partial`, `final-undo`,
`final-redo`, `final-reopen-state` under the os3d-qa08 prefix in diagonal-matrix.
All copied and hashed locally. Google signed-out blocker persists; no new
publication claim beyond illustrated466/master38. Immutable05be744IPA untouched.

### Center-only rectangle Lock correction — September 10

Native center Lock permits width18→9 about the unchanged midpoint while height12
remains. Clone now selects only the center point (mouse and touch drag-start),
saves a center-scoped Lock, and lowers it to a fixed-midpoint equation without
new rectangle variables. Unsupported derived-center relationships stay disabled.
Center colors show selection/Lock; local glyph is offset below the drag target.
Final clean31/31 at `/tmp/os3d-qa08-center-lock-final2-20260910.xcresult`, after
retained kernel/UI failures and fixture corrections. Exact-build live clone
width0.957→0.5 preserves midpoint/height1.736; Undo/Redo, locked refusal, Unlock
translation40×20, relock and gallery reopen all captured. Native resize is live
compared; latest native reopen remains pending at trial modal7759 because supported
focus/capture routes are inconsistent. No native persistence failure claimed.
Publication remains queued, not verified: Google signed-out, last illustrated466 /
master38. Immutable05be744IPA unchanged. QA08 remains partial; wider selection,
constraint icon styling/visibility and other acceptance cases remain open.

Pending center-fix image set (not inserted; no duplicate retry):
- os3d-qa08-center-native-widthselected.png
- os3d-qa08-center-native-width9.png
- os3d-qa08-center-final-selected.png
- os3d-qa08-center-final-refuse.png
- os3d-qa08-center-final-width05.png
- os3d-qa08-center-final-reopen-state.png
All exact hashes retained in report diagonal-matrix/SHA256SUMS.

Follow-up read-only browser check during the rectangle suite: correct openclaw profile/t18 remains
Request edit access/Sign in; t19 text explicitly says signed out/Trying to connect.
Empty interactive snapshots were not evidence of recovered login. No insertion
or reload attempted; original tabs preserved. Local pending evidence remains
unpublished and no count beyond466/38 is claimed.

### Broader regression and recovered native reopen

35382d4 broader RectangleWorkflowUITests passed clean15/15, zero failures/skips
at `/tmp/os3d-qa08-center-lock-rectangle-suite-20260910.xcresult` (463.879s).
No runner remains. Supported `see --mode screen --no-web-focus` saved an inspected
image despite AX error: an earlier openshape3dUITests-Runner crash dialog covered
the Shapr3D trial prompt. Dismissed Ignore (failed fixture xcresult retained), then
Skip immediately worked. No Shapr3D/Simulator restart or host security change.
Native gallery-opened Sketch04 re-entered/NormaltoSketch: middle9×12 and green
locked center retained (`os3d-qa08-native-center-reopen-values.png`). This closes
the previously pending paired center-Lock persistence sample. Earlier failed
modal deliveries/capture errors are retained, not attributed to native persistence.
Google remains signed-out; this result and new image are queued locally only.

### Direct rectangle center padlock — queued, not inserted

September10 paired native direct action revealed two corrections: plain black padlock directly toggles scoped Lock (not generic glyph-selection/Delete); directLock finishes center selection, while Unlock retains it. Touch bypass to Metal reproduced at exact icon center and corrected through shared-bounds on-screen-control dispatch. Final clean33/33 plus paired live lifecycle, unchanged corners, one-step history and final galleryreopen passed. Retained failed attempts and superseded symmetric-selection interpretation are in diagonal-matrix receipt.

Pending final paired images (all hashes in report SHA256SUMS):
- os3d-qa08-toggle-native-unlocked.png
- os3d-qa08-toggle-native-relocked.png
- os3d-qa08-lifecycle-clone-unlock.png
- os3d-qa08-lifecycle-clone-lock.png
- os3d-qa08-lifecycle-native-final-reopen.png
- os3d-qa08-lifecycle-clone-final-reopen.png

Illustrated466/master38 remain last verified; Google signedout. No duplicate insertion or tab reset. Remaining QA08 partial-edge colors and free-versus-locked center halo require separate comparisons. IPAunchanged, physical inputunverified.

### Selected free-center halo — queued, not inserted

Native halo persists awayfrompointer onlyselectedfree, notselectedlocked; clone nowmatches this cue. CleanexistingUI1/1 and exact-build live verified. No core/hit/geometry change; no physicaldevice pixel-equivalence claim. Pending images: `os3d-qa08-halo-native-locked-away.png`, `os3d-qa08-halo-native-free-away.png`, `os3d-qa08-halo-clone-locked-after.png`, `os3d-qa08-halo-clone-free-after.png`. Exact hashes in retained SHA256SUMS. Google signedout; counts unchanged466/38.
