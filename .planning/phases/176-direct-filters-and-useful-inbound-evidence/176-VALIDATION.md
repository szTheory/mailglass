---
phase: "176"
slug: "direct-filters-and-useful-inbound-evidence"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
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

Requirement → test map lives in `176-RESEARCH.md` § Phase Requirements → Test Map. Every row closes as `source: automated` (D-52).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 176-01-01 | 176-01 | 1 | FILTER-01, FILTER-02 | T-176-01 | Account forced server-side; select commits with no Apply | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/bucket_a_coverage_test.exs --seed 0` | ✅ | ✅ green |
| 176-01-02 | 176-01 | 1 | FILTER-03 | T-176-02 | One history entry per intent; page and selection keys dropped | ExUnit unit + LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator/filter_commit_test.exs test/mailglass_admin/operator_live_test.exs --seed 0` | ✅ | ✅ green |
| 176-01-03 | 176-01 | 1 | FILTER-01 | T-176-03 | Mobile Filters toggle reports committed filters only | LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-02-01 | 176-02 | 1 | INUX-05 | T-176-05 | Unmasked From/To plus separate Delivered to; escaped markup | ExUnit + LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --seed 0` | ✅ | ✅ green |
| 176-02-02 | 176-02 | 1 | INUX-05 | T-176-06, T-176-07 | Address matrix: overflow, duplicates, spoof, Unicode | ExUnit unit + component | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound/address_list_test.exs test/mailglass_admin/inbound/components_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-02-03 | 176-02 | 1 | INUX-05 | T-176-05 | Inbound Quick view labels the envelope recipient Delivered to | ExUnit + bundle | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/components_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/token_parity_test.exs --seed 0` | ✅ | ✅ green |
| 176-03-01 | 176-03 | 2 | INUX-06 | T-176-08, T-176-10 | One persistent Reveal/Hide disclosure; exact reveal telemetry keys | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/evidence_card_test.exs --seed 0` | ✅ | ✅ green |
| 176-03-02 | 176-03 | 2 | INUX-06 | T-176-09 | Coupled evidence-card specs and rebuilt bundle agree | browser + parity | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- operator.spec.js phase170-journey.spec.js structural.spec.js` (advisory) | ✅ | ✅ green |
| 176-04-01 | 176-04 | 2 | FILTER-04 | T-176-11, T-176-12 | Failed new-query read: error, Retry, no count or empty copy | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --seed 0` | ✅ | ✅ green |
| 176-04-02 | 176-04 | 2 | FILTER-04 | T-176-12 | Same-query failure keeps rows under a stale panel; status region | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator/results_status_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` | ✅ | ✅ green |
| 176-04-03 | 176-04 | 2 | FILTER-04 | T-176-13 | Invalid draft and URL values are labelled, never unlabelled fallback | LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-05-01 | 176-05 | 3 | INUX-06 | T-176-23, T-176-24 | Five truthful facts; unknown reads Unavailable, never 0 | ExUnit component | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound/evidence_card_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-05-02 | 176-05 | 3 | INUX-06 | T-176-23 | Number formatting, empty/missing evidence copy, rebuilt bundle | ExUnit + bundle | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound/evidence_card_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/token_parity_test.exs --seed 0` | ✅ | ✅ green |
| 176-06-01 | 176-06 | 3 | FILTER-02, FILTER-03 | T-176-04 | Deliveries Search: one history entry per edit; Enter commits at once | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs --seed 0` | ✅ | ✅ green |
| 176-06-02 | 176-06 | 3 | FILTER-02, FILTER-03 | T-176-04, T-176-25 | FilterSearchSync restores focused Search on Back/Forward (LV 1.2.13 and 1.1.33) | ExUnit + browser x2 | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/assets_test.exs --seed 0` | ✅ | ✅ green |
| 176-07-01 | 176-07 | 4 | FILTER-01, FILTER-03 | T-176-14, T-176-15 | Inbound select commits through FilterCommit, Account forced | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --seed 0` | ✅ | ✅ green |
| 176-07-02 | 176-07 | 4 | FILTER-02, FILTER-03 | T-176-15 | Inbound debounced Search, Enter, focus hook, mobile toggle | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-07-03 | 176-07 | 4 | FILTER-04 | T-176-16 | Raw draft retained so the select never contradicts its error | LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/components_test.exs --seed 0` | ✅ | ✅ green |
| 176-08-01 | 176-08 | 4 | INUX-05, INUX-06 | T-176-17, T-176-18 | Retained Inbound evidence scenario via production components | ExUnit + story evidence | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/quick_view_projection_test.exs --seed 0` | ✅ | ✅ green |
| 176-08-02 | 176-08 | 4 | INUX-05, INUX-06 | T-176-17 | Worst-case contact and evidence scenarios | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/quick_view_projection_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-08-03 | 176-08 | 4 | INUX-05 | T-176-18 | Gallery shows synthetic worst-case data, no masked-looking addresses | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/persona_drift_guard_test.exs test/mailglass_admin/group_nesting_test.exs test/mailglass_admin/bucket_a_coverage_test.exs --seed 0` | ✅ | ✅ green |
| 176-09-01 | 176-09 | 5 | FILTER-04 | T-176-19 | Failed new-query Inbound read: error, Retry, no count or empty copy | ExUnit + browser | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --seed 0` | ✅ | ✅ green |
| 176-09-02 | 176-09 | 5 | FILTER-04 | T-176-20 | Same-query stale retention above rows; status region | ExUnit | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs --only phase176 --trace` | ✅ | ✅ green |
| 176-09-03 | 176-09 | 5 | FILTER-04 | T-176-20 | Inbound invalid draft and URL notes | LiveView | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` | ✅ | ✅ green |
| 176-10-01 | 176-10 | 6 | FILTER-01 | T-176-21, T-176-22 | P1 no Apply/submit control, mutation-proven | ExUnit contract | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/phase176_prohibition_contract_test.exs --trace` | ✅ | ✅ green |
| 176-10-02 | 176-10 | 6 | FILTER-01..04, INUX-05, INUX-06 | T-176-21, T-176-22, T-176-26 | P2-P8 prohibitions mutation-proven; telemetry keys exact | ExUnit contract | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/phase176_prohibition_contract_test.exs --trace` | ✅ | ✅ green |
| 176-10-03 | 176-10 | 6 | FILTER-01..04, INUX-05, INUX-06 | T-176-21 | Connected history, focus, reconnect, page reset and axe proof on both clients | browser (advisory) | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js` (advisory) | ✅ | ✅ green |
| 176-10-04 | 176-10 | 6 | FILTER-01..04, INUX-05, INUX-06 | T-176-22 | Every coupled spec, full admin suite, format, credo, conformance, fresh bundle | gates | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs` — pure history-kind / canonical-path tests (FILTER-03)
- [x] `mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs` — mutation-proven prohibitions (D-30, phase175 template)
- [x] `"deliveries"` added to `arm_reader_fault!/3` whitelist in `mailglass_admin/test/support/operator_fixtures.ex`
- [x] Inbound stale/error fault helper (swap `:mailglass_inbound, :repo` with `on_exit` restore)
- [x] Shared patch-kind test helper (`view.proxy` + `assert_receive {:patch, topic, %{kind: kind}}`)
- [x] `mailglass_admin/e2e/phase176-filters.spec.js` (advisory) + demo `Phase 176` e2e group (LV 1.1.33)
- [x] Browser spike: hook `updated()` fires for focused search input on both pinned clients (A3)
- [x] Scenario manifest entries + `inbound_evidence.story.exs` (D-32); re-run `check_phase174/175_evidence.test.cjs`

---

## Manual-Only Verifications

None remain. All phase behaviors have automated verification (D-52: zero owner UAT; judgment-tier prohibitions are the mutation-proven `phase176_prohibition_contract_test.exs`). Residual, recorded not hidden: IME composition (assumption A6) is not automatable and stays unverified at low risk, since a focused value is never patched by LiveView.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-28 (validate-phase audit: 16 mapped ExUnit files re-run, 580 tests, 0 failures, `--seed 0`)

## Validation Audit 2026-10-28

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
