# OpenShape3D: sustained parity-work rules

## Goal and authorization

Jason has authorized ongoing OpenShape3D sketch/UI parity work against native
Shapr3D, until he says stop. Work toward a verified candidate for his physical
iPad sketching comparison. This is the native OpenShape3D project, not OpenPlan3D.
New user steering takes precedence over this file.

## Execute continuously within each active work session

1. Read `docs/SKETCH_PARITY_IMPLEMENTATION.md`, the latest receipts under
   `docs/testing/`, and the continuation checkpoint below. Inspect the actual
   branch, working tree, and running work before changing anything.
2. Pick the highest-priority unfinished core-sketch issue. Reproduce the same
   workflow in native Shapr3D and OpenShape3D in the simulator through Peekaboo.
3. Capture reference and clone evidence, implement the confirmed fix, run focused
   regression checks, and repeat the changed workflow in both apps.
4. Update the issue ledger and screenshot-backed Google Docs, retaining a local
   evidence copy. Mark automated-only checks and pending publication explicitly.
5. Continue directly to the next unfinished issue. A passing test, commit, PR
   update, screenshot, status reply, or completed batch is not a stopping point.

Do not end an active work turn merely with a plan, an offer to continue, a promise
that a reminder will do the work, or a summary of one batch while actionable work
remains. Answer status questions briefly and resume the authorized work unless
the user pauses, cancels, or changes the objective.

## Desktop ownership and sustained sessions

- Exactly one workflow may control the desktop at a time. Do not run overlapping
  Peekaboo interactions, simulator UI tests, or competing builds against the same
  simulator/checkouts. Check existing activity before resuming.
- Keep chat responsive with meaningful progress updates during sustained work.
  Do not fabricate desktop activity, background execution, verification, or an ETA.
- Reminders are watchdog wake-ups, not proof that a worker is running. On a
  continuation wake, inspect the checkpoint and resume concrete work if idle.
  If work is already active, do not duplicate it or send reminder-only chatter.
- Rules cannot keep an ended process/session alive. Do not claim continuous
  background execution unless a real running session/process has been verified.
  An interrupted session must resume from its checkpoint at the next opportunity.
- Preserve the existing 30-minute continuation schedule; do not add duplicate jobs.

## Evidence and progress

- For each changed feature, verify native Shapr3D versus simulator OpenShape3D.
  Unit/UI tests supplement, never replace, hands-on reference comparisons.
- Inspect screenshots after interactions; command success alone is not evidence
  that the intended UI action happened. Allow animations to settle.
- Track separately: implemented, regression-tested, live-compared, documented,
  and ready for device testing. Do not combine these into an unsupported “done.”
- Give updates for actual results, failures, or blockers, not repeated reminders.
  State when no progress occurred. Report whether tests were one clean run or a
  failing run followed by targeted successful reruns.
- Keep PR changes reviewable; do not merge or claim a real-device installation
  without the appropriate authorization and verification.

## Legitimate pauses and handoffs

Pause only when the user requests it, the iPad-readiness checkpoint is reached,
all authorized work is exhausted, a real external blocker prevents all useful
work, or the execution environment interrupts the session. A locked desktop
alone does not block independent implementation, tests, or documentation.

Before a controllable interruption, update `docs/PARITY_CONTINUATION.md` with:
current revision and dirty files; actual work running and its owner; last verified
result and evidence; unresolved failure; exact next action; remaining queue;
blocker and what resolves it. Do not leave a stale “running” state after stopping.
On unexpected interruption, reconcile the checkpoint with actual processes and
repository state rather than trusting it blindly.

Never restart the Mac, log out, change lock settings, or restart Screen Sharing
as part of this work. Never request login passwords. Escalate only a real blocker
that requires Jason; continue unrelated authorized work while waiting.

## iPad readiness

Notify Jason when core sketch workflows have paired live evidence, blocking UI
issues are resolved, relevant regressions pass, and an identified installable
build plus a short device A/B checklist are available. Include known differences.
This is readiness for Pencil/touch testing, not a claim of full parity. Physical
Pencil behavior remains unverified until tested on a physical device.
