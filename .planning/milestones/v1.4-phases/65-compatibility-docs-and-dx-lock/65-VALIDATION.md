---
phase: 65
slug: compatibility-docs-and-dx-lock
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
updated: 2026-06-01
---

# Phase 65 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix |
| **Config file** | `mailglass_inbound/test/test_helper.exs` and root Mix aliases |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~60 seconds focused, ~2 seconds aggregate on current workstation |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`.
- **After every plan wave:** Run `mix mailglass.docs.check`.
- **Before `$gsd-verify-work`:** `mix verify.stability_contract` must be green.
- **Max feedback latency:** 60 seconds for focused docs-contract checks, 180 seconds for aggregate stability verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 65-01 | 1 | DX-01 | T-65-01 | README remains the sole canonical inbound adoption lane and install docs stay subordinate. | docs-contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 65-01-02 | 65-01 | 1 | DX-01 | T-65-02, T-65-03 | Compatibility guidance routes stable inbound guarantees through `mailglass_inbound/docs/api_stability.md` without creating a second repo-root authority. | tier1-docs | `mix mailglass.docs.check` | yes | green |
| 65-02-01 | 65-02 | 1 | DX-02 | T-65-04, T-65-05 | Operator docs keep doctor/replay/prune tenant guards, exit semantics, replay-over-stored-truth wording, and destructive confirmations explicit. | docs-contract + tier1-docs | `mix mailglass.docs.check` | yes | green |
| 65-02-02 | 65-02 | 1 | DX-03, DX-04 | T-65-06 | Testing docs preserve process-local capture and one-assertion-per-drive semantics; admin trust docs avoid fresh-receive replay, silent reroute, public replay API, and stable UI/DOM/component guarantees. | docs-contract + tier1-docs | `mix mailglass.docs.check` | yes | green |
| 65-03-01 | 65-03 | 2 | DX-01 | T-65-07 | Package-local docs-contract assertions fail on adoption-path or compatibility-story drift. | docs-contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 65-03-02 | 65-03 | 2 | DX-01 | T-65-08, T-65-09 | Tier 1 docs checker fails closed on adoption-path and compatibility-route drift. | tier1-docs | `mix mailglass.docs.check` | yes | green |
| 65-04-01 | 65-04 | 3 | DX-02, DX-03, DX-04 | T-65-10, T-65-11, T-65-12 | Docs-contract assertions lock operator, testing, and admin trust wording to stable semantics and negative boundary phrasing. | docs-contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 65-04-02 | 65-04 | 3 | DX-02, DX-03, DX-04 | T-65-10, T-65-11, T-65-12 | Tier 1 docs checker reinforces operator/testing/admin trust required tokens without broad forbidden-token false positives. | tier1-docs | `mix mailglass.docs.check` | yes | green |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

- [x] Add or confirm docs-contract assertions for README canonical adoption path tokens and subordinate guide parity.
- [x] Add or confirm docs-contract assertions for stable-vs-internal/deferred compatibility language and deprecation bridge wording.
- [x] Add or confirm docs-contract assertions for doctor/replay/prune command semantics, exit behavior, tenant guards, and destructive confirmation language.
- [x] Add or confirm docs-contract assertions for `MailboxCase`, `Test.Ingress`, process-local assertions, and one-assertion-per-drive examples.
- [x] Add or confirm Tier-1 docs checks for admin/operator trust anti-overclaim wording.

---

## Manual-Only Verifications

All phase behaviors should have automated verification through the docs-contract and stability-contract lanes. Manual review is limited to judging prose clarity after automated required/forbidden phrase checks pass.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** validated 2026-06-01

## Validation Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Phase 65 is Nyquist-compliant as executed. The existing generated tests cover each requirement through `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` and `lib/mix/tasks/mailglass.docs.check.ex`; no additional test files were required during this retroactive audit.

Verification evidence:

- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` — 22 tests, 0 failures.
- `mix verify.stability_contract` — root lane: 1 property, 75 tests, 0 failures, 1 skipped; inbound lane: 35 tests, 0 failures; admin lane: 29 tests, 0 failures; docs check OK.
