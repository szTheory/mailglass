## Phase 163

Automates deterministic timeout evidence and removes human UAT from the release-path decision:

- records sanitized SQLSTATE 57014 operation evidence on deterministic-core failures;
- reproduces protected matrix expiries and repairs only three exact test titles plus browser sandbox ownership with finite bounds;
- retains the 30-second global test default, one worker, retry policy, 30-minute job, 1,000-run properties, and complete matrix coverage;
- uploads failure-only database and browser evidence for recurrent diagnosis;
- adds an observable repository-local protected-run monitor.

## Machine verification

- `mix test --warnings-as-errors`: 23 properties, 1,964 tests, 0 failures, 7 skipped;
- `CI=true npm run test:operator-browser`: 176 passed, 1 skipped in 3.8m, no retry;
- three first-attempt focused gallery runs passed with all 117 cells;
- protected run `32998989827` passed both Core Deterministic and Operator Browser jobs;
- workflow/action lint, evidence contracts, recorders, reporter, and monitor tests pass.

No manual dispatch, merge, release, or UAT is requested by this PR.
