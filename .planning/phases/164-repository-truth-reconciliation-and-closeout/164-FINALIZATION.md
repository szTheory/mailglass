# Phase 164 Finalization Boundary

Phase 164 closes across two deliberately separate proof boundaries. Ordinary
GSD execution owns tracked implementation, summaries, verification, roadmap,
requirements, and phase-completion metadata. The project-local
`/finalize-phase 164` command runs only after those tracked outputs have reached
protected `main`, and writes no tracked result that would invalidate the SHA it
just proved.

## Pre-verification checkpoint

After Plans 01–11 and their summaries have reached protected `main`, run:

```text
/finalize-phase 164 --pre-verification
```

The command requires a clean canonical checkout whose `HEAD` equals
`origin/main`. It automatically selects the newest successful attempt-1 `CI`
run produced by a normal `push` for that exact SHA. It accepts no run ID and
does not dispatch or rerun a workflow. It writes only ignored
`tmp/phase-164-closeout/pre-verification-inputs.json`,
`pre-verification-report.json`, and raw component sources. Plan 164-12 and the
ordinary phase verifier use that evidence to prove the implementation SHA and
the finalization capability before `phase.complete` writes tracked completion
metadata.

## Terminal operational proof

After the normal verifier has passed and the phase-completion commit has reached
protected `main`, run:

```text
/finalize-phase 164
```

Terminal mode additionally requires a summary for every numbered Phase 164
plan, a completed Phase 164 ROADMAP entry, completed TRTH-01 through TRTH-03,
and `status: passed` in `164-VERIFICATION.md`. It writes only ignored
`tmp/phase-164-closeout/finalization-inputs.json`, `report.json`, and component
sources. No summary, planning update, commit, push, merge, release, publication,
dispatch, or rerun follows the capture.

## Evidence rules

Both modes independently validate the raw source files referenced by the
normalized report. CI must be attempt 1, workflow `CI`, event `push`, branch
`main`, exact SHA, completed, and successful. Every registered scheduled
control must be attempt 1, event `schedule`, branch `main`, completed, exact
head/workflow SHA, evidence-valid, and backed by matching payload and retained
artifact digests. Registry-specific maximum ages remain solely authoritative in
`.github/scheduled-controls.json` through the successful scheduled sweep.

Any missing, malformed, stale, pending, cannot-check, identity-mismatched, or
non-attempt-1 evidence fails closed while preserving the ignored report for
inspection. A HEAD change or any stable-porcelain entry before, during, or after
capture also fails finalization.
