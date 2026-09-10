# Phase 164 Finalization Boundary

Phase 164 closes across two deliberately separate proof boundaries. Ordinary
GSD execution owns tracked implementation, summaries, verification, roadmap,
requirements, and phase-completion metadata. The project-local
`/finalize-phase 164` command runs only after those tracked outputs have reached
protected `main`, and writes no tracked result that would invalidate the SHA it
just proved.

The project-local dispatcher is deliberately Phase-164-only. It rejects every
other positive phase before repository discovery because no other phase has an
authenticated downstream mapping. For Phase 164, it preserves the canonical
lexical `164-FINALIZE.sh` path, requires that checkout entry to be a non-symlink
regular file, and authenticates its exact HEAD/index/worktree identity before
using `realpath` only as an additional containment check.

Before the first Bash process starts, the dispatcher enumerates a closed Phase
164 dependency manifest from HEAD, authenticates every exact executable and
data blob, and materializes the complete set beneath one mode-0700 private
authority root. Executables are mode 0500 and data is read-only. Both shell
layers use that authority root for helper execution and immutable ledger,
registry, plan, summary, verification, and preservation inputs. The canonical
checkout remains a separate observation target only for live Git and GitHub
identity, protected-main, stable-porcelain, and ignored-output checks; mutable
checkout helper or policy bytes never become execution authority.

The handler reports errors by setting a nonzero exit code and throwing through
its cleanup-protected scope. Its `finally` removes the complete private
authority root before success, ordinary failure, or `--print` failure returns
to the caller.

## Pre-verification checkpoint

After Plans 01–13 and their summaries have reached protected `main`, run:

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

Plans 164-18 and 164-19 repaired the stage-aware ledger and authenticated
finalization chain after the earlier pre-verification capture. Neither those
plans nor Plan 164-20 ran pre-verification or terminal finalization; their
ordinary test results are implementation evidence, not a replacement terminal
report.

## Terminal operational proof

After the normal verifier has passed and the phase-completion commit has reached
protected `main`, run:

```text
/finalize-phase 164
```

Terminal mode additionally requires a summary for every numbered Phase 164
plan, a completed Phase 164 ROADMAP entry, completed TRTH-01 through TRTH-03,
and both `status: passed` and a required `verified_implementation_sha` in
`164-VERIFICATION.md`. The SHA is exactly 40 lowercase hexadecimal characters,
names the implementation commit evaluated by the ordinary verifier, and must be
an ancestor of terminal `HEAD`. Every later commit on that first-parent chain is
inspected relative to its first parent; each may change only
`.planning/phases/164-repository-truth-reconciliation-and-closeout/164-VERIFICATION.md`,
`.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, or `.planning/STATE.md`.
This per-commit check retains forbidden change-then-revert history and judges a
merge by its result relative to its first parent without traversing unrelated
second-parent history. It writes only ignored
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
