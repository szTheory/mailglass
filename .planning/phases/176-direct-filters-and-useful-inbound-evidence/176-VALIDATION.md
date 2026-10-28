---
phase: "176"
slug: "direct-filters-and-useful-inbound-evidence"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-28"
---

# Phase 176 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `176-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest 1.2.13 (merge-blocking); Playwright 1.59.1 (advisory) |
| **Config file** | `mailglass_admin/test/test_helper.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --seed 0` |
| **Full suite command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin` |
| **Estimated runtime** | ~4 seconds (quick); full admin suite a few minutes |

---

## Sampling Rate

- **After every task commit:** quick run command plus the touched test file with `--only phase176 --trace`
- **After every plan wave:** full suite, `bash scripts/check-conformance.sh`, `mix credo --strict`, `mix format --check-formatted`, and the wave's Playwright spec
- **Before `/gsd-verify-work`:** full suite green; `git diff --exit-code mailglass_admin/priv/static/` clean after rebuild; `TokenParityTest` green; prohibition contract mutation-proven
- **Max feedback latency:** 10 seconds (quick lane)

---

## Per-Task Verification Map

Filled by the planner per task; requirement → test map lives in `176-RESEARCH.md` § Phase Requirements → Test Map.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (planner) | | | FILTER-01..04, INUX-05, INUX-06 | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs` — pure history-kind / canonical-path tests (FILTER-03)
- [ ] `mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs` — mutation-proven prohibitions (D-30, phase175 template)
- [ ] `"deliveries"` added to `arm_reader_fault!/3` whitelist in `mailglass_admin/test/support/operator_fixtures.ex`
- [ ] Inbound stale/error fault helper (swap `:mailglass_inbound, :repo` with `on_exit` restore)
- [ ] Shared patch-kind test helper (`view.proxy` + `assert_receive {:patch, topic, %{kind: kind}}`)
- [ ] `mailglass_admin/e2e/phase176-filters.spec.js` (advisory) + demo `Phase 176` e2e group (LV 1.1.33)
- [ ] Browser spike: hook `updated()` fires for focused search input on both pinned clients (A3)
- [ ] Scenario manifest entries + `inbound_evidence.story.exs` (D-32); re-run `check_phase174/175_evidence.test.cjs`

---

## Manual-Only Verifications

All phase behaviors have automated verification (D-52: zero owner UAT; judgment-tier prohibitions become mutation-proven contract tests).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
