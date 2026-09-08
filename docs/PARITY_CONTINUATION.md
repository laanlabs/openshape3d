# Parity continuation checkpoint

Updated September 7, 2026, following Jason's request for sustained-work rules.

## Verified state

- Branch: `fix/sketch-parity-foundations`; draft PR https://github.com/laanlabs/openshape3d/pull/29.
- Latest implementation commit at this checkpoint: `84aa29e` (rectangle anchors).
- No active desktop-testing worker has been established by this rules update.
- Latest live result: ground-plane entry in the clone settled automatically into
  Top without Look at Sketch. Shapr3D existing-sketch re-entry showed Top too.
  This is not full plane-entry parity. Local paired captures:
  `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/recheck-2030/`.
- Later line-readout and anchor implementations still need fresh paired live
  verification. The last anchor batch passed 19 regression tests; not live sign-off.
- Illustrated Google Doc:
  https://docs.google.com/document/d/1qHopHdl7nDJncL4MR4bEF3JGdbkOIXuXSe3bC3xGNko/edit
  Latest recheck captures have not been uploaded there.

## Exact next action

Check current desktop ownership and state. In the existing test projects, draw a
line in native Shapr3D and in the latest OpenShape3D simulator; compare retained
length readout and keypad behavior after release, then reopen the dimension.
Capture both states and record settings/input differences before diagnosing gaps.

## Next queue

1. Live recheck completed-line dimensions and diagonal/center resize anchors.
2. Fix confirmed keypad obstruction/automatic opening and two-axis rectangle input.
3. Verify three-point height access, selection, constraints, snapping, undo/redo,
   exit/re-entry and persistence against the core acceptance checklist.
4. Publish paired findings and updated statuses in the existing Google Docs.
5. Prepare identified installable iPad candidate and 15–20 minute A/B checklist;
   notify Jason only when the readiness gates in AGENTS.md are met.

## Environment notes

User reports desktop unlocked. Verify again rather than assuming. Peekaboo GUI
bridge has previously worked with an explicit app switch, `--foreground`, and
`--bridge-socket '/Users/thelodgestudio/Library/Application Support/Peekaboo/bridge.sock'`.
Default click routing previously fell back to an inaccessible daemon/local host.
Inspect actual results; this is an observed workaround, not a guaranteed fix.

Existing continuation watchdog: `3eced82f-bc37-4bcf-9f42-518d25e7558c`, every 30
minutes. Check for active work before resuming; never create a duplicate worker.
No Mac restart or lock-setting changes. iPad readiness: **not reached**.
