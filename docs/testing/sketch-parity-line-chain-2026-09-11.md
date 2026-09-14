# QA-05 line-chain checkpoint — September 11, 2026

## Scope and reference state

Finite recipe: tap A→B→C, finish the open chain, resume from B, and close a
second loop intentionally. Native Shapr3D and the portrait iPad simulator were
kept at separate zoom/unit scales; topology, tool state, history, and saved
recovery are compared rather than pixel coordinates. Exact implementation base
was pushed `89ffd35`; this checkpoint is intentionally partial because fresh
native canvas clicks remain blocked by desktop input delivery.

Native reference evidence retained from September 8 shows a committed line,
endpoint continuation preview, and first Escape removing only the preview while
Line remains armed. A fresh September 11 native entry shows Line armed and the
explicit prompt: “Press Return to finish, or Escape or Delete to finish without
placing temporary segments.” Supported Peekaboo clicks reported delivery but
made no native canvas change; `synthOnly` cannot see the remote GUI session.
This is an input-delivery blocker, not a Shapr3D failure and not fresh paired
proof of the complete QA-05 recipe.

## Confirmed implementation

- Return now calls `finishLineInput`: it clears only transient line-chain state,
  leaves Line armed, and does not alter committed geometry or history.
- With Line armed and no active chain, an endpoint tap seeds a fresh chain at the
  exact saved endpoint. An entity-body tap still follows selection behavior and
  an empty tap starts a free chain.
- The new UI workflow constructs A→B→C, finishes with Return, resumes from the
  rendered B endpoint, draws D→E→B, and requires exactly five history entries.
- The pre-existing closed-loop workflow now requires all four Undo steps. Its
  prior `for` loop could tap a disabled button and still pass, so earlier 2/2
  baseline results did not prove four segments.
- Line tests pin their snap launch defaults because the guide-only workflow
  intentionally persists different settings; this removes suite-order coupling.
  Vertex taps use human-scale spacing so the transient anchor has settled.

## Regression history

- Existing baseline: 2/2 passed at
  `/tmp/os3d-qa05-line-chain-baseline-20260911.xcresult`, but the old history
  assertion was later shown incomplete.
- Red/diagnostic iterations are retained under `/tmp/os3d-qa05-return-*.xcresult`.
  They exposed, in order: wrong four-marker assumption, dynamic AX coordinate
  rebinding, left-tool-rail intrusion, insufficient initial anchor settling, one
  compile-only missing local binding, and persisted guide-setting order coupling.
  These are not promoted as product failures.
- Corrected focused workflow: 1/1 passed at
  `/tmp/os3d-qa05-final-focused-v2-20260911.xcresult`.
- Final current-tree serial LineChain run: clean 3/3 at
  `/tmp/os3d-qa05-linechain-clean-combined-v2-20260911.xcresult`.

## Exact-build live OpenShape3D result

The DerivedData app from the 3/3 run was installed on simulator
`AC2FD923-1661-435F-BF47-3E9DF30D1A16`. After restarting only the Simulator UI
process to recover its input bridge, live clicks produced:

1. two connected A→B→C segments;
2. Return with geometry retained and Line still armed;
3. a separate B→D→E→B triangle sharing the saved B endpoint;
4. toolbar Undo removing only the triangle closing edge and Redo restoring it;
5. gallery thumbnail save and reopen retaining the original open chain plus the
   closed profile.

Evidence and SHA-256 inventory:
`/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-core-sketch-milestone-2026-09-08/line-chain-qa05/`.

## Acceptance state

QA-05 remains **PARTIAL**, so the 56-case inventory stays
**12 passed / 0 failed / 1 device-blocked / 43 incomplete**. Product behavior,
focused regression, exact-build clone history, and clone persistence are
verified. Closure still needs the full native A→B→C → Return → B resume → close
workflow after native desktop canvas input delivery recovers. Pointer hover and
physical Pencil/touch remain separate QA-21/QA-52 lanes. The immutable `05be744`
IPA is unchanged and does not contain this work.


## September 11 evening — fresh native completion and current gate

Fresh native Sketch09 on Top now verifies the whole finite recipe: A→B→C,
Return leaving Line armed, resume at B, B→D→E→B closure, Undo removing only
E→B, Redo restoring it, Exit showing a filled triangle and original open chain,
and gallery reopen / named Sketch09 selection recovering exactly five edges.
Instantaneous bridge clicks failed to seed anchors; bounded 200 ms / 1 px presses
successfully delivered the mouse endpoint sequence. This is a recorded delivery
qualification, not a native product defect or physical touch/Pencil claim.
Native and retained clone fixtures use different planes/zoom/lengths; topology,
state and history match. No product source change was needed for this comparison.

Current HEAD `1fdb6a3` serial LineChainUITests gate passes clean **3/3**, zero
failures or skips, at `/tmp/os3d-qa05-native-paired-final-20260911.xcresult`.
Retained clone live screenshots were reinspected: Return, resumed triangle,
closing-edge Undo/Redo and gallery reopen all agree. New native PNG/JSON and
current summary/log are durable in `line-chain-qa05/native-live-2026-09-11/`
under the milestone reports root. Eleven hash-distinct evidence images are now
inserted into the illustrated report; export verification and final verdict
remain pending. QA05 is not yet promoted; inventory25/0/1/30.


## Final publication and bounded closure

Illustrated export `native-live-2026-09-11/illustrated-after.docx` contains
**863 unique media** with no loss from the852-image predecessor, one dated
QA05 heading and one final verdict. Ten new images match source SHA-256 exactly;
Google downsampled the remaining clone reopen image from2064×2752 to1536×2048.
The single unmatched new asset was extracted and visually verified against its
source (same time/toolbar/open chain/shared junction/filled triangle), not called
a byte or pixel match. Its exported hash and mapping are recorded in
`reencoded-verification.json`; all eleven sources/uploads remain in
`publication-manifest.json`. The master export retains38 media, no predecessor
loss, and one dated QA05 closure note. The failed initial upload targeted a menu
ref as a file input and inserted nothing; the corrected chooser upload saved.

QA05 is **PASSED** for the original finite desktop recipe. Inventory advances
to **26 passed /0 failed /1 device-blocked /29 incomplete**, total56. Current
serial3/3 supplements the retained exact-build clone live sequence and fresh
native complete sequence; it does not imply every modality or hover is verified.
No product code changed for this closure. Physical build/install remains pending.
