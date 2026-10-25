# CI Efficiency Pass: 2026-10 Recommendations

**Status:** recommended; implement after PR #302 merges.
**Raised by:** the owner on 2026-10-25: "keep pruning or rearranging, not churn, but keep it efficient".
**Inputs:**
- A measured audit of runs 40199863646, 40145365145 and 40205750932, plus 28 runs of history and 14 days of scheduled runs. The raw JSON was in the session scratchpad.
- Primary-source research: GitHub Actions limits, caching, concurrency and required checks; the setup-beam and actions/cache READMEs; Mix.Tasks.Test; Playwright CI and sharding docs; dialyxir CI notes.

Already shipped, so not re-proposed: v1.15's `mix ci` parity, CI Green fan-in, toolchain-hashed keys, PLT self-heal, and PR `cancel-in-progress`.

## Measured baseline

- **PR CI:** about 85–97 runner-min per push, plus 31–33 for the Advisory Matrix. Wall time is about 14 min.
- **Time to mergeable** is set by **Core Deterministic Suite (12.7m)**. The Operator Browser Gate (median 12.5m, range 9.1–19.1m) is not in CI Green's `needs`.
- **Queueing:** the 20-job free-plan cap is briefly exceeded, but the worst job wait is 37s. **Queueing is not the bottleneck.**
- **Biggest consumers over 14 days:**

  | Consumer | Runs | Runner-min | Notes |
  |---|---|---|---|
  | Hourly release-please | 351 × 3.9m | ~1370 | Recompiles from scratch every hour |
  | Scheduled Advisory Matrix | 15 × 50.6m | ~758 | All 15 runs on the same SHA |
  | Dependabot PRs | 6 | ~430 | Each fails deterministically in about 1 min while 22 other jobs run on |

- **~18 Elixir jobs cache `deps` but not `_build`.** Each recompiles deps plus mailglass, at 53–80s per job. Core Deterministic Suite compiles mailglass 4 times.
- **Known flake:** `flows.spec.js:1278`, the operator replay focus trap. It failed both its run and its retry on 7336a269, and has 3 failures in 28 runs.

## Decisions

### Wave 1: low risk and high payoff (one PR, `ci:` and `test:` commits)

1. **Cache `_build` in every Elixir job.** Move the jobs onto the existing `.github/actions/setup-beam-mix` composite, with a per-job `cache-namespace` and the reference apps' `_build` paths. Keys: lock hash, `.tool-versions` and MIX_ENV.
   - Guard: a warm `_build` hides warnings in unchanged modules. "Compile Warnings as Errors" and the docs-warnings lane must compile with `--force`, or skip `_build` restore entirely.
   - Saves about 15–25 runner-min per push and 2–3 min off the merge path.
2. **Restore everywhere, save on main only.** Use `actions/cache/restore` in PR jobs and save from main or schedule runs, so PR-scoped entries stop churning the 10 GB budget.
3. **Inbound Test: stop running the TELE-08 property twice.** The standalone step takes 123s and the coverage run repeats it. Keep it in the coverage run only. Saves about 2 min.
4. **Advisory Matrix schedule: skip the 1.18 legs when a successful run already exists for `github.sha`.** Keep the next-toolchain legs, which carry the forward-compatibility signal. Saves about 350–400 runner-min per 14 days.
5. **Cache deps and `_build` for release-please's trusted control.** Use a key written only on main, which schedule runs can read. Profile the 109s "Detect already-tagged" step and cache whatever compile it does.
   - Leave the cadence alone. It is a dead-man's switch, and the memories record that cadence is not the fix for its red.
   - Saves about 600 runner-min per 14 days.
6. **Group Dependabot's Hex updates into one PR, monthly.** This matches the existing batch-disposal practice (memory: lockfile-only bumps, consolidated). Also make the demo-deps lock-drift failure fail fast, so the whole matrix doesn't run behind it. Saves about 300 runner-min per 14 days.
7. **Fix the focus-trap flake.**
   - Diagnosis: `openOperatorReplayModal` and `openInboundReplayModal` return as soon as the modal is visible, but `phx-mounted={JS.focus(to: "#…-replay-close")}` then moves focus asynchronously. The test also checks `contains(document.activeElement)` once instead of polling.
   - Fix: the helpers wait until the initial focus lands on the close button, and the inside-check polls with `expect.poll`.
   - Report the Playwright **flaky** count in the job summary so retries can't hide rot.

### Wave 2: merge-path cuts (medium risk, separate PR, after Wave 1 is measured)

8. **Partition Core Deterministic Suite** with `--partitions 2` (`config/test.exs` already honours `MIX_TEST_PARTITION`). 114 files are `async: false` and the run takes 455.9s, 411.8s of it sync.
   - The suite-floor and skip-ledger checks move to a fan-in that sums both partitions.
   - Expected: time to mergeable drops from about 12.7m to about 7–8m.
9. **Shard the Operator Browser Gate in two** (`--shard`, keeping `workers: 1` per Playwright guidance; each shard gets its own server and DB). This cuts about 5 min off time to full signal.
   - Don't cache browsers. Playwright advises against it, and restoring takes about as long as downloading. Install Chromium only, and check whether the 65s here vs 21s in Preview Capture comes from `--with-deps` OS packages.
10. **On `pull_request`, run only the `schema: mailglass` leg of Advisory "Core Full Suite".** It duplicates Core Deterministic on 1.18/public. Keep both legs on push, dispatch and schedule.
    - Care: this is the HARNESS-04 publish pair, and `gate-ci-green` reads it. Update the `CILanes` contract tests together with the change.
    - Saves about 12–15 runner-min per push.

### Process

- **Batch `docs(state)` commits, or push them after merge.** Each push to an open PR branch costs a full matrix (about 117 runner-min), because PR CI must produce a fresh CI Green for the new head. This is correct by design, so the fix is the habit, not the gate.

## Leave alone (looks slow, is justified)

- **The no-optional-deps compile lanes:** they keep a compatibility promise.
- **`Detect Non-Doc Changes` diffing `base...HEAD`:** correct, because a per-commit skip would strand the required check.
- **Guard Release Trigger running on every push, and the CI Green aggregate:** together they avoid the pending-check trap.
- **Postgres container init.**
- **Both Dialyzer lanes:** the PLT cache already hits.
- **The Trust Lane baselines and demo Hex-pin proof.**
- **`verify.ci_lane_contract`:** the deliberate TRUTH-07 split.
- **Demo Browser Evidence and Preview Capture:** both are advisory and off the merge path.
- **The hex-publish approvals and every required gate.**

## Expected outcome

| Area | Before | After Wave 1 | After Wave 2 |
|---|---|---|---|
| PR runner-min per push | ~120 | ~100 | ~85 |
| Time to mergeable | ~12.7m | ~10m | ~7–8m |
| Scheduled and bot runner-min per 14 days | — | ~1,250+ less | — |

Measure after each wave, and record the numbers in the PR description.
