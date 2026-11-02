# Phase 178 deferred items

Out-of-scope discoveries logged by plan executors. Not fixed by the plan that found them.

## From 178-03 (2026-10-29)

### D-178-03-A: `reference/demo_app/mix.lock` at `main` no longer passes `mix deps.get --check-locked` (BLOCKS fresh isolated demo launches)

- **Symptom:** a fresh Compose project built from any current `main` SHA exits 1 at start: `** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag`. The container `CMD` is `mix deps.get --check-locked && mix ecto.setup && mix phx.server` (`reference/demo_app/Dockerfile`).
- **Cause:** upstream Hex releases after the 2026-10-26 lock: `bandit 1.14.0 => 1.14.1`, `swoosh 1.29.0 => 1.29.3` (the "reference baselines drift on upstream releases" class). The already-running owner review demo is unaffected only because its volumes were seeded earlier.
- **Proof the launcher is fine:** the same launcher, on a throwaway unreferenced commit equal to `main` plus exactly that two-line lock refresh, passes the whole gate (see 178-03-SUMMARY). On `main` HEAD itself the gate fails in 11-13 s with the cause above, the demo log saved next to the record, and teardown clean.
- **Impact:** plans 178-05 and 178-07 run the isolated demo from the committed HEAD in their named gates, and 178-09/10 run the hosted proof; all of them fail until the demo lock is refreshed. Any hosted job that runs the same `--check-locked` step against these locks is exposed to the same drift (not measured here).
- **Established remedy (project memory, not applied here):** a one-line-class `chore(deps):` commit that bumps `reference/demo_app/mix.lock` for the `Upgraded:` block (bandit 1.14.1, swoosh 1.29.3 as of 2026-10-29) and nothing else. It is outside 178-03's `files_modified`, and the dispatch forbids committing demo `mix.lock` drift, so it needs the orchestrator's go-ahead before 178-05.

### D-178-03-B: `scripts/check_phase174_evidence.cjs --pilot --require-ci` cannot pass on current `main` for ANY Phase 174 evidence directory

- **Symptom:** run against the untouched retained directory `reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1` it fails with `Axe comparison rejected: missing expected case delivery-investigation-...` (8 cases).
- **Cause:** the checker reads the CURRENT `reference/persona_spec/quick_view_scenarios.json`, which Phases 175-177 extended with delivery-investigation scenarios the 174 receipts predate. Not related to the cost derivation.
- **How 178-03 still proved the contract:** the full checker was run from a detached worktree at the Phase 174 candidate `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5`, where it returns `valid:true` for the regenerated `ci-job.json` and `phase174/cost.json`; and `validateCiJob` / `validateHostedCost` (the exports that cover the regenerated files) run in `scripts/phase178_cost_disposition.test.cjs` on current `main`.
- **Left for:** whichever plan needs a green full Phase 174 checker run on current `main` (none in 178 as written).
