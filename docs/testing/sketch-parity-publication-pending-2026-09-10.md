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
