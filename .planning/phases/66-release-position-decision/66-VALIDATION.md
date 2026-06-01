---
phase: 66
slug: release-position-decision
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 66 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `mix.exs`, `mailglass_inbound/mix.exs` |
| **Quick run command** | `mix verify.stability_contract` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.stability_contract` when the task touches contract, docs, version, release, or planning-state truth.
- **After every plan wave:** Run `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound`.
- **Before `$gsd-verify-work`:** Both release-blocking lanes must be green and their outputs captured in phase artifacts.
- **Max feedback latency:** 180 seconds for the core stability/publish gate pair.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | REL-01 | T-66-01 | Release decision is based on fresh green stability and publish evidence, not stale assumptions. | integration/process | `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound` | yes | pending |
| 66-01-02 | 01 | 1 | REL-02 | T-66-02 | Release notes summarize compatibility posture without duplicating or contradicting canonical contract docs. | docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | pending |
| 66-01-03 | 01 | 1 | REL-03 | T-66-03 | Planning state continues blocking broad feature-growth until the release-position decision is closed. | governance/manual | `rg -n "release-position decision|feature-growth|broad feature-growth" .planning/STATE.md .planning/ROADMAP.md` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the final binary release posture is explicit and supported by captured evidence. | REL-01 | The decision is a governance artifact derived from command evidence and cannot be fully inferred by tests. | Read the final release-position artifact and verify it states either `1.0.0` promotion or final `0.x` fallback, cites fresh command evidence, and names the blocker if fallback is chosen. |
| Confirm feature-growth work remains blocked until Phase 66 is closed. | REL-03 | Planning-state language is a project governance constraint, not a runtime behavior. | Run the `rg` command above and inspect `.planning/STATE.md` / `.planning/ROADMAP.md` for explicit release-position gating language. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual governance verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 180s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
