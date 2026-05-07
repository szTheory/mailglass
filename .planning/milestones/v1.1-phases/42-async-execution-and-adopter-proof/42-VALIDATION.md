---
phase: 42
slug: async-execution-and-adopter-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for durable Oban execution, bounded fallback execution, canonical adopter docs, and sibling-package release/root proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks + workflow/config validation |
| **Config file** | `mailglass_inbound/mix.exs`, `mailglass_inbound/test/test_helper.exs`, `mix.exs`, `.github/workflows/release-please.yml`, `release-please-config.json` |
| **Quick run command** | Task-local: `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors`, `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`, or `actionlint .github/workflows/release-please.yml` |
| **Full suite command** | `cd mailglass_inbound && mix test --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && actionlint .github/workflows/release-please.yml` |
| **Estimated runtime** | ~20-40s task-local / ~120s wave-level / ~240s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest changed-surface command; async dispatch changes must run `async_execution_test.exs` or `worker_test.exs`, docs changes must run `docs_contract_test.exs`, workflow/release proof changes must run `actionlint` plus the root stability check.
- **After every plan wave:** rerun `cd mailglass_inbound && mix test --warnings-as-errors`; for wave 3 also rerun the root proof commands touching release/config files.
- **Before `$gsd-verify-work`:** full phase command must be green and root release-proof wiring must be rechecked.
- **Max feedback latency:** 40 seconds task-local, 120 seconds per wave, 240 seconds for the full phase scope.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 42-01-01 | 01 | 1 | EXEC-01 | T-42-01 | fresh inserted inbound rows enqueue durable work through an internal Oban worker without exposing `%Oban.Job{}` publicly | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` | ⬜ task creates files | ⬜ pending |
| 42-01-02 | 01 | 1 | EXEC-02 | T-42-03 | fallback dispatch runs only after persistence, never inline, and remains explicitly non-durable/non-retrying | unit + plug integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ⬜ / ✅ expand existing | ⬜ pending |
| 42-02-01 | 02 | 2 | ADOPT-01 | T-42-04 | canonical docs cover provider mounts, parser/body-reader wiring, Oban setup, fallback semantics, and verification commands honestly | docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 42-02-02 | 02 | 2 | ADOPT-01 | T-42-05 | replay/operator wording distinguishes replay from fresh provider receive and rejects public replay/UI claims | docs + behavior | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 42-03-01 | 03 | 3 | ADOPT-01 | T-42-07 | root proof wiring fails if `mailglass_inbound` drops out of semantic verification | root contract | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 42-03-02 | 03 | 3 | ADOPT-01 | T-42-08 | release automation and publish proof explicitly register `mailglass_inbound` in release-please and inbound-specific publish expectations | workflow / config / grep | `actionlint .github/workflows/release-please.yml && rg -n "mailglass_inbound|release-please|publish" release-please-config.json .release-please-manifest.json .github/workflows/release-please.yml .planning/publish/mailglass_inbound-files.expected .planning/publish/mailglass_inbound-publish-summary.json` | ⬜ / task creates files | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The phase needs these validation assets or test expansions before execution:

- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs`
- `mailglass_inbound/test/mailglass_inbound/worker_test.exs`
- extended `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
- root proof assertions that cover `mailglass_inbound`
- inbound-specific publish expectation artifacts

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Oban-backed execution is exercised in a host app with real Oban config | EXEC-01 | Durable enqueue semantics depend on adopter runtime configuration outside unit tests | In execution/verify phases, run the documented host-app setup path and record the real enqueue path used. |
| The fallback warning copy is understandable to operators | EXEC-02 | Warning clarity is partly a wording judgment, not only a code-path assertion | During docs/UAT review, confirm the fallback warning and README language make the non-durable semantics obvious. |
| Release-please PR and publish workflow coverage for `mailglass_inbound` behave correctly in GitHub | ADOPT-01 | GitHub release automation state is external and temporal | After implementation, inspect the generated PR/update behavior and record whether `mailglass_inbound` is treated as a real package participant. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual-only rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 gaps are identified explicitly
- [x] No watch-mode flags
- [x] Feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
