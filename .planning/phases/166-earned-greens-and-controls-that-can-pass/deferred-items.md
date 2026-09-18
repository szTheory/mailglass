# Deferred Items — Phase 166

Out-of-scope discoveries logged per the executor's scope-boundary rule (do not fix, do not
re-run builds hoping they resolve themselves).

## 166-04

- **`test/scripts/phase_164_closeout_test.exs` is slow/flaky on this machine.** During Task 2's
  full `test/scripts/ test/mix/tasks/` verification run, the test
  `"phase 164 immutable loader loader and shell authenticate exact terminal pairs 01 through 44"`
  hit ExUnit's 60s per-test timeout (and did not complete even under a 200s isolated `timeout`
  wrapper). This file shells out via `System.cmd` across 44 terminal-pair sub-cases and is
  unrelated to `.github/workflows/release-please.yml` (its two `"release-please"` mentions are
  just control-ID strings passed to `scripts/closeout_repository_truth.sh`, not anything this
  plan's diff touches). Not fixed here — pre-existing, unrelated file, out of scope for CTRL-02/
  CTRL-03. Confirmed 166-04's full test suite is green when this one file is excluded (492 tests,
  0 failures, 20 excluded).

- **Task 3 (checkpoint:human-verify, `gate="blocking-human"`) -- post-merge evidence for
  CTRL-02/CTRL-03 acceptance criteria is explicitly PENDING, not observed.** Cannot be satisfied
  pre-merge and must never be manufactured by dispatch or re-run (plan prohibition, confirmed by
  maintainer). Checklist for whoever picks this up next (166-05/166-06 or Phase 167 merges are
  expected to supply the observations naturally per D-37):
  1. Open the `release-please` workflow runs for the three most recent merges to `main`; confirm
     each concluded `success`.
  2. For each of those SHAs, open both the `push` run and the `schedule` run and confirm they
     agree.
  3. When the next `chore: release main` PR merges, open its `release-please` push run and confirm
     the tagged-SHA skip fired (CTRL-02's own acceptance) rather than the action re-running.
  4. Confirm no run reported a `cannot-check` outcome as `pass`.

  Until all four are observed, `.planning/REQUIREMENTS.md`'s CTRL-02/CTRL-03 rows stay
  `Implemented, evidence pending` -- not `Complete`. See `166-04-SUMMARY.md` for full detail.
