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
