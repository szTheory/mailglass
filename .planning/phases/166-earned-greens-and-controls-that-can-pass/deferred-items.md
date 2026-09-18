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
