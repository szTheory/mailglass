---
phase: 138
slug: schema-prefix-no-search-path-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 138 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox |
| **Config file** | `config/test.exs`, `test/test_helper.exs`, `mailglass_inbound/test/test_helper.exs` |
| **Quick run command** | `mix verify.schema_prefix` after Wave 0 adds the alias |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~60-180 seconds for the focused lane after alias creation |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.schema_prefix` once the alias exists.
- **After every plan wave:** Run `mix verify.schema_prefix` plus affected package focused tests.
- **Before `/gsd:verify-work`:** `mix verify.schema_prefix` and `mix ci` must be green.
- **Max feedback latency:** 180 seconds for the focused lane.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 138-01-01 | TBD | 0 | SCHEMA-01 | T-138-01 | `Mailglass.Webhook.Replay` projection update mutates configured-schema delivery under hostile `search_path`. | integration | `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix` | No - Wave 0 | pending |
| 138-01-02 | TBD | 0 | SCHEMA-02 | T-138-02 | Unsubscribe replay/idempotency conflict lookup reads configured-schema event under hostile `search_path`. | integration | `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix` | No - Wave 0 | pending |
| 138-02-01 | TBD | 0 | SCHEMA-03 | T-138-03 | Raw repo calls and `Ecto.Multi` callbacks touching mailglass tables are prefixed, facade-routed, or allowlisted. | static + unit | `mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs` and `mix credo --strict` | No - Wave 0 | pending |
| 138-03-01 | TBD | 0 | SCHEMA-04 | T-138-04 | Inbound repo-option extension points default to facade, or raw-repo paths have explicit prefix contracts. | integration + unit | `cd mailglass_inbound && mix test test/mailglass_inbound/schema_prefix_contract_test.exs` | No - Wave 0 | pending |
| 138-04-01 | TBD | 0 | GATE-01 | T-138-05 | Focused schema-prefix lane runs hostile runtime proofs and static guard. | alias smoke | `mix verify.schema_prefix` | No - Wave 0 | pending |
| 138-04-02 | TBD | closeout | GATE-02 | T-138-06 | Advisory dual-schema matrix remains documented as a broad canary, not the only proof. | source assertion | `rg -n "canary|focused no-search-path|verify.schema_prefix" .github .planning mix.exs` | No - closeout update | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/schema_prefix_hardening_test.exs` - hostile `search_path` runtime proofs for SCHEMA-01 and SCHEMA-02.
- [ ] `credo_checks/raw_repo_prefix_contract.ex` plus `test/mailglass/credo/raw_repo_prefix_contract_test.exs`, or a narrower source-scanner equivalent, for SCHEMA-03.
- [ ] `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` - inbound repo-option contract proof for SCHEMA-04.
- [ ] `mix.exs` alias and `cli.preferred_envs` entry for `verify.schema_prefix`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Advisory matrix stays a canary rather than the sole proof. | GATE-02 | Mostly a documentation/review assertion unless the planner adds a source check. | Confirm the phase plan includes a closeout source assertion or docs/comment update that names `mix verify.schema_prefix` as the focused no-search-path proof. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 180 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
