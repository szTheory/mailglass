---
id: add-clean-baseline-trust-lane-after-republish
created: 2026-05-28
status: completed
priority: high
origin: Phase 59 (ci-trust-lanes-checkpoint-evidence) execution
requirement: EVID-02
resolves_phase: 62
---

# Add the clean-baseline trust lane (EVID-02) after a mailglass release contains the trust runner

## Why this is deferred

Phase 59 Plan 02 originally specified a `trust_lane_clean_baseline` CI job that runs
`mix verify.reference_host.journey` from `working-directory: reference/host_app`, against
the **Hex-published** sibling packages (`{:mailglass, "~> 1.2"}`, etc.). During execution
(2026-05-28) this was found to be impossible against the current published release:

- `verify.reference_host.journey` is an alias defined only in the **root** `mix.exs`
  (it delegates to the `mailglass.trust.run` Mix task). `reference/host_app/mix.exs` does
  not define that alias, and aliases are not inherited from dependencies.
- `mailglass.trust.run` was added in Phase 57 (commit `293cd74`), **after** the
  `mailglass-v1.2.0` tag. The published 1.2.0 package contains no trust/verify Mix task.

So the lane would fail "task could not be found" on every CI run and — being a non-advisory
`ci.yml` job — would block `gate-ci-green` (the Hex publish gate). A clean-baseline trust
proof can only run against a published release that already contains the trust runner.

Maintainer decision (2026-05-28): ship EVID-01 (repo-head lane) now, defer EVID-02.

## What "done" looks like

After a `mailglass` version that includes `mailglass.trust.run` is published to Hex:

1. Bump `reference/host_app/mix.exs` to that published version (e.g. `~> 1.3`) and refresh
   `reference/host_app/mix.lock` (verify with `scripts/check_clean_baseline_hex_only.sh`,
   which is already shipped from Phase 59 Plan 01).
2. Add the `trust_lane_clean_baseline` job to `.github/workflows/ci.yml` (the planned shape
   is in `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-02-PLAN.md` Task 1,
   Edit B; the now-removed job body is recoverable from that plan). Either invoke the runner
   via a `reference/host_app/mix.exs` alias or call the published Mix task directly — confirm
   the task name resolves from `reference/host_app/` before wiring.
3. Validate the checkpoint via `bash scripts/check_trust_runner_checkpoint.sh --checkpoint reference/host_app/tmp/mailglass_trust_runner/checkpoint.json`
   and upload it as `trust-runner-clean-baseline-${{ github.run_id }}` (retention-days: 90,
   if-no-files-found: error, exact file path — Pitfall 6).
4. Decide whether the clean-baseline lane is publish-gate-required only (current A1 lock) or
   should also be added to `REQUIRED_CHECKS`.

## Ready-made building blocks from Phase 59 (already merged)

- `scripts/check_clean_baseline_hex_only.sh` — Hex-source guard, ready to wire.
- `gate-self-test.yml` `check_name` input — can self-test the new lane's enforcement.
- `test/scripts/required_checks_test.exs` — array/heredoc drift contract (name-agnostic).
