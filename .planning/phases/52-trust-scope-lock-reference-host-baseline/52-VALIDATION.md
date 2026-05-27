---
phase: 52
slug: trust-scope-lock-reference-host-baseline
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 52 is a trust-baseline governance phase: establish one maintained reference host app, enforce public seam boundaries, and lock scope/non-goals with deterministic checks.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit contract tests + deterministic command checks |
| **Config file** | `reference/host_app/mix.exs` (new), root `mix.exs`, `.planning/REQUIREMENTS.md` |
| **Quick run command** | `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test test/reference_host/boot_contract_test.exs test/reference_host/public_seams_contract_test.exs test/reference_host/scope_lock_contract_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test test/reference_host/boot_contract_test.exs test/reference_host/public_seams_contract_test.exs test/reference_host/scope_lock_contract_test.exs --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green and host bootstrap command must pass
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | HOST-01 | T-52-01 | Maintained host app boots from clean checkout with documented setup | integration + contract | `cd reference/host_app && mix deps.get && mix ecto.create && mix ecto.migrate && mix compile --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 52-01-02 | 01 | 1 | HOST-01 | T-52-01 | Boot contract test asserts canonical setup path and expected files | unit/contract | `mix test test/reference_host/boot_contract_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 52-02-01 | 02 | 1 | HOST-02 | T-52-02 | Reference host wiring only uses documented stable seams | contract | `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 52-02-02 | 02 | 1 | HOST-02 | T-52-02 | Forbidden internal module/provider-internal patterns are absent | grep | `! rg -n "Mailglass\\.(Repo|Outbound\\.Projector|OptionalDeps)|MailglassInbound\\.Ingress\\.Providers|MailglassAdmin\\.Operator\\.Mount" reference/host_app` | ❌ W0 | ⬜ pending |
| 52-03-01 | 03 | 2 | HOST-03 | T-52-03 | Scope allowlist + non-goals are explicit and complete | contract | `mix test test/reference_host/scope_lock_contract_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 52-03-02 | 03 | 2 | HOST-03 | T-52-03 | SCOPE document contains milestone-locked non-goals verbatim | grep | `rg -n "Provider-matrix broadening|SEED-003|gen_smtp|second product" reference/host_app/SCOPE.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `reference/host_app/` — maintained host artifact scaffolded and committed
- [ ] `reference/host_app/mix.exs` and host app bootstrap docs
- [ ] `test/reference_host/boot_contract_test.exs`
- [ ] `test/reference_host/public_seams_contract_test.exs`
- [ ] `test/reference_host/scope_lock_contract_test.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host README setup instructions are adopter-readable and not fixture-oriented | HOST-01 | readability and intent are editorial judgments | Read `reference/host_app/README.md`; confirm it is written for adopters and links to trust journey expectations. |
| Boundary language does not imply expanded API guarantees | HOST-02 | wording can over-promise even when tests pass | Compare host docs against `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, and `mailglass_inbound/docs/api_stability.md`; reject language promoting internal modules. |
| Scope allowlist and non-goals remain crisp, not vague | HOST-03 | quality of scope framing is qualitative | Review `reference/host_app/SCOPE.md` and ensure it clearly distinguishes in-scope proof tasks from deferred/out-of-scope items. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
