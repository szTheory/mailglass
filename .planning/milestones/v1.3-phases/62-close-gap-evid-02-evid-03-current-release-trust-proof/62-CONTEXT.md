# Phase 62: close-gap-evid-02-evid-03-current-release-trust-proof - Context

**Gathered:** 2026-05-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.3 milestone audit gap for **EVID-02** and **EVID-03** by making the clean-baseline and published-version trust proof validate the current published release line.

This is a narrow gap-closure phase over repo truth. The workflows for `trust_lane_clean_baseline` and `published-trust-journey` already exist; the blocker is that `reference/host_app` still resolves `mailglass` 1.2.0, `mailglass_admin` 1.2.0, and `mailglass_inbound` 0.2.0. Phase 62 should align the host constraints, lockfile, and clean-baseline guard with the intended current release line: `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0.

Out of scope: redesigning the trust runner, changing checkpoint schema semantics, adding provider-matrix breadth, changing clean-baseline branch-protection posture, reworking post-publish smoke topology, or attempting credentialed GitHub branch-protection operations.
</domain>

<decisions>
## Implementation Decisions

### Current-Release Dependency Drift

- **D-01:** Phase 62 implementation scope is the current-release dependency drift identified by the milestone audit. Fix `reference/host_app/mix.exs` from `~> 1.2` / `~> 1.2` / `~> 0.2` to `~> 1.3` / `~> 1.3` / `~> 0.3`, then refresh the reference host lock so the sibling Hex entries resolve to `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0.
- **D-02:** Do not redesign the existing `trust_lane_clean_baseline` job in `.github/workflows/ci.yml` or the `published-trust-journey` job in `.github/workflows/post-publish-smoke.yml`. Those lanes already run the repo-root trust runner with `--host-root reference/host_app`; the missing proof is the reference host's release-line resolution, not lane topology.
- **D-03:** Refresh the lockfile narrowly. Prefer `mix deps.update mailglass mailglass_admin mailglass_inbound` from `reference/host_app`; accept only those sibling updates plus resolver-required patch churn that is explicitly reviewed.

### Folded EVID-02 Todo

- **D-04:** Fold `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` into this phase because Phase 62 is the post-release current-line closure it was waiting for.
- **D-05:** Treat Phase 60 context as superseding the todo's stale "run from `reference/host_app`" wording. The trust runner remains repo-root orchestration via `mix verify.reference_host.journey --host-root reference/host_app`; aliases and dev-only trust tasks are not inherited from Hex dependencies.

### Version-Specific Clean-Baseline Guard

- **D-06:** Extend `scripts/check_clean_baseline_hex_only.sh` so it asserts both source and version:
  - `mailglass` resolves via `:hex` at `1.3.0`
  - `mailglass_admin` resolves via `:hex` at `1.3.0`
  - `mailglass_inbound` resolves via `:hex` at `0.3.0`
- **D-07:** Add or extend a focused contract test so the guard cannot drift back to Hex-source-only validation. The audit found the current guard can pass while proving the old release line.

### Audit Residuals

- **D-08:** Live GitHub branch-protection proof for EVID-01 is a residual/manual audit item, not Phase 62 local implementation scope. Agents can preserve notes that it remains pending, but should not plan credentialed server-side branch-protection operations as this phase's code work.
- **D-09:** Live post-publish green-run evidence remains a runtime residual after the dependency drift fix. Phase 62 should make the local repo capable of proving the current release line; observing a future green `post-publish-smoke` run is milestone-audit evidence, not a local implementation blocker.

### The agent's Discretion

- Exact wording of failure output in `scripts/check_clean_baseline_hex_only.sh`, as long as stale versions fail clearly and include expected vs actual version.
- Whether the version-specific guard contract is added to an existing publish/trust-lane contract test file or a new focused test file, following nearby test organization.

### Folded Todos

- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` — fold into Phase 62 and mark resolved when the reference host resolves the current release line and the version-specific guard is verified.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/v1.3-MILESTONE-AUDIT.md` — audit gap source for EVID-02/EVID-03 current-release drift and residual EVID-01/live-run items.
- `.planning/REQUIREMENTS.md` — EVID-02, EVID-03, OPS-02 requirement text and traceability.
- `.planning/ROADMAP.md` — Phase 62 gap-closure entry and v1.3 milestone context.
- `.planning/phases/60-release-trust-gate-drift-prevention/60-CONTEXT.md` — superseding decisions for clean-baseline/published trust topology, especially repo-root runner orchestration and publish-gate-only clean-baseline posture.
- `.planning/phases/60-release-trust-gate-drift-prevention/60-VERIFICATION.md` — local verification evidence showing current guard passes on stale versions and identifying the blocker.
- `.planning/phases/60-release-trust-gate-drift-prevention/60-05-PLAN.md` — concrete gap-closure shape already drafted for the reference-host version drift.
- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` — folded EVID-02 todo; read for history, but follow Phase 60's corrected runner path.
- `reference/host_app/mix.exs` — dependency constraints to bump to `~> 1.3`, `~> 1.3`, and `~> 0.3`.
- `reference/host_app/mix.lock` — Hex lock entries to refresh to `1.3.0`, `1.3.0`, and `0.3.0`.
- `scripts/check_clean_baseline_hex_only.sh` — Hex-source guard to extend with expected-version checks.
- `.github/workflows/ci.yml` — existing `trust_lane_clean_baseline` job; do not redesign unless verification proves a direct mismatch with Phase 60 decisions.
- `.github/workflows/post-publish-smoke.yml` — existing `published-trust-journey` job; do not redesign unless verification proves a direct mismatch with Phase 60 decisions.
- `test/mailglass/publish/ci_trust_lane_contract_test.exs` — likely home for clean-baseline guard/workflow contract coverage.
- `scripts/check_trust_runner_checkpoint.sh` — checkpoint validator reused by existing lanes.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `trust_lane_clean_baseline` already exists in `.github/workflows/ci.yml` and runs the repo-root journey with `--host-root reference/host_app`, validates `tmp/mailglass_trust_runner/checkpoint.json`, and uploads `trust-runner-clean-baseline-${{ github.run_id }}`.
- `published-trust-journey` already exists in `.github/workflows/post-publish-smoke.yml` and mirrors the same Hex-source guard, repo-root journey, checkpoint validation, and artifact upload for post-publish evidence.
- `scripts/check_clean_baseline_hex_only.sh` already parses `reference/host_app/mix.lock` as an Elixir term and asserts the three sibling packages resolve via `:hex`; it is the right seam to add expected-version enforcement.
- `60-05-PLAN.md` already captures the intended fix shape, including scoped dependency refresh and a version-specific guard contract.

### Established Patterns

- Trust proof lanes use repo-root orchestration because the trust runner is dev/test tooling in the root repo, not a Mix task shipped for dependency callers.
- Clean-baseline trust remains publish-gate-only per Phase 60 D-04; do not add it to `REQUIRED_CHECKS` or branch protection as part of this closure.
- Release evidence artifacts use `trust_runner.v1` checkpoints at the default `tmp/mailglass_trust_runner/checkpoint.json` path with 90-day retention.
- Audit gap closure should be minimal and evidence-led: fix the failing truth, add a guard that would have caught it, then re-run the focused contract suite.

### Integration Points

- `reference/host_app/mix.exs` + `reference/host_app/mix.lock` enable both EVID-02 and EVID-03 current-release proof, because both trust lanes build that host before running the root trust runner.
- `scripts/check_clean_baseline_hex_only.sh` is invoked by both the CI clean-baseline lane and the post-publish published-trust lane, so version-specific validation protects both requirements.
- Phase 62 verification should include the guard script from `reference/host_app`, relevant publish/trust-lane contract tests, workflow YAML parse/actionlint, and a targeted check that lock entries match the intended versions.
</code_context>

<specifics>
## Specific Ideas

- The expected current release line is `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0, matching the root package versions in the current tree and `.release-please-manifest.json`.
- If lock refresh pulls unrelated dependency changes, require the planner/executor to call them out explicitly instead of burying them in the gap closure.
- Use clear guard output such as "expected 1.3.0, got 1.2.0" so future CI failures point directly at release-line drift.
</specifics>

<deferred>
## Deferred Ideas

- Live GitHub branch-protection reassertion for EVID-01 — credentialed maintainer action, not Phase 62 local implementation.
- Observing and recording a future green `post-publish-smoke` run with `published-trust-journey` artifact — milestone audit/runtime evidence after the local drift fix.
- Adding `trust_lane_clean_baseline` to branch protection / `REQUIRED_CHECKS` — explicitly out of scope and contrary to Phase 60's publish-gate-only lock.
- Provider-matrix breadth, transport expansion, `SEED-003` ecosystem work, and new reference-app features — all outside v1.3 gap closure.

### Reviewed Todos (not folded)

None. The single matched todo was folded into scope.
</deferred>
