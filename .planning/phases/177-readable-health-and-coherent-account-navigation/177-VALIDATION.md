---
phase: "177"
slug: "readable-health-and-coherent-account-navigation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-28"
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Zero owner UAT (D-52): every row closes `source: automated`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest (LV 1.2.13) + Floki (merge-blocking); Playwright 1.59.1 operator browser gate (advisory) |
| **Config file** | `mailglass_admin/test/test_helper.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/preview/return_context_test.exs test/mailglass_admin/phase177_*_test.exs --seed 0` |
| **Full suite command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin` (entire admin suite, `--warnings-as-errors`) |
| **Estimated runtime** | quick ~30s; full ~180s; Playwright per-task ~180s cold (advisory; includes Tailwind build + webServer boot); Playwright full-spec phase gate ~5 min |

---

## Sampling Rate

- **After every task commit:** the touched file's ExUnit command plus `--only phase177 --trace` (all new tests carry `@moduletag :phase177`)
- **After every plan wave:** quick-run set + `mix format --check-formatted` + `mix credo --strict` + `bash scripts/check-conformance.sh` + `mix compile --no-optional-deps --warnings-as-errors` (CI lane only; never on the shared local `_build`); after any class/CSS change: the one bundle procedure below
- **Wave-level sampling (revision W-5):** each plan's `<verification>` block runs the full coupled files it touches (for example the whole `operator_live_test.exs` / `inbound_live_test.exs` and the full coupled Playwright specs) once per plan. Per-task verifies run only the edited files plus `--only phase177` / `--grep` subsets. The full admin suite (`mix verify.support_contract.admin`) and the full-spec Playwright run happen only in plan 177-11. This once-per-plan full run of coupled files is the intended reading of "after every plan wave".
- **Bundle procedure (revision W-8, plans 177-04, 177-06, 177-07, 177-08, 177-11):** `mix mailglass_admin.assets.build` → `token_parity_test.exs assets_test.exs` → commit the rebuilt `priv/static/app.css` as emitted. No manual restoring of daisyUI theme blocks. Plan 177-04 Task 1 first proves, on a clean tree before any CSS edit, that `mix mailglass_admin.assets.build && git diff --exit-code -- mailglass_admin/priv/static/` passes (research: the fresh build reproduces the committed bundle, so the token-parity landmine is not firing). If that proof fails, execution stops and reports the landmine as live.
- **Shared browser server:** all operator-browser specs share one Playwright webServer on port 4101 and reset state through `/ops/browser-reset?scenario=...`, so browser verifies never run concurrently across plans; kill a stale port-4101 server before final runs.
- **Before `/gsd-verify-work`:** full `mix verify.support_contract.admin` green (baseline zero failures); Playwright specs; `git status --short mailglass_admin/priv/static reference/demo_app/mix.lock reference/demo_app/mix.exs` clean
- **Max feedback latency (revision W-4):** ExUnit per-task verifies ≤ 60 seconds. Playwright per-task verifies are advisory-lane and pay a Tailwind build plus webServer boot, so their budget is about 180 seconds cold (build + boot + the grepped tests). The executor of plan 177-01 records the measured cold time of the phase's first browser verify (177-01 Task 1) in `177-01-SUMMARY.md`.

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| UXF-10 | ReturnContext validator table (closed surface set, id bounds/UTF-8/control chars, non-local path, injection values, 10k surface, replace-in-place `tenant_id`) | unit | `mix test test/mailglass_admin/preview/return_context_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| UXF-10 | Session maps unchanged; no `return_*` key; no Account assigns on Preview | unit | `mix test test/mailglass_admin/router_test.exs test/mailglass_admin/phase177_prohibition_contract_test.exs --seed 0` | ✅ / ❌ W0 | ⬜ pending |
| UXF-10 | Minting per surface, custom mounts, persistence (index redirect, scenario patch, width patch, theme round-trip), direct/tampered fallback, unauthorized arrival denied, independent Preview rendering | connected | `mix test test/mailglass_admin/phase177_return_navigation_test.exs --only phase177 --seed 0` | ❌ W0 | ⬜ pending |
| UXF-10 | ThemeController segment-boundary sanitizer | controller | `mix test test/mailglass_admin/router_test.exs --seed 0` | ✅ (add cases) | ⬜ pending |
| UXF-10 | Browser Back returns to Preview; demo Fjordline round trip | e2e (advisory) | `npm --prefix mailglass_admin run test:operator-browser -- phase177-return-navigation.spec.js`; demo blocking `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo_web/phase177_navigation_test.exs` (includes the D-07 logged-out Fjordline return); demo advisory `cd reference/demo_app/assets && npm run test:e2e -- phase177-return.spec.js` | ❌ W0 | ⬜ pending |
| UXF-09 | Header variants (0/1/many/selected/unavailable/long label), group semantics, unique ids per layout | component | `mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/phase177_account_scope_test.exs --seed 0` | ✅ / ❌ W0 | ⬜ pending |
| UXF-09 | Preview prohibitions (no picker/name/id text, no sample-data claim, Preview outside group) — mutation-proven | contract | `mix test test/mailglass_admin/phase177_prohibition_contract_test.exs --trace --seed 0` | ❌ W0 | ⬜ pending |
| UXF-09 | Account control visible at 320/375/768/1280/1440; topbar not wrapped; keyboard order; reduced motion | e2e (advisory) | `npm --prefix mailglass_admin run test:operator-browser -- phase177-account.spec.js` | ❌ W0 | ⬜ pending |
| OUTUX-06 | Population fingerprint `{testid,count,href}` byte-identical pre/post; order independent of count; deep links kept | LiveView golden | `mix test test/mailglass_admin/health_population_test.exs --seed 0` | ❌ W0 (commit BEFORE Health edits) | ⬜ pending |
| OUTUX-06 | Structure: observation group, activity subordinate, no `order-`, no `role=status` on notices, `min-h-11`, copy states | component | `mix test test/mailglass_admin/operator/health_overview_test.exs test/mailglass_admin/operator_live_test.exs --seed 0` | ❌ W0 / ✅ | ⬜ pending |
| OUTUX-06 | 42rem column rule in bundle; docs amended | unit | `mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/assets_test.exs --seed 0` | ✅ | ⬜ pending |
| OUTUX-06 | Geometry gates; `metricColumns` replaced; issue deep-link landing | e2e (advisory) | `npm --prefix mailglass_admin run test:operator-browser -- phase169-journey.spec.js health-tooltips.spec.js phase177-health.spec.js` | ✅ edit / ❌ W0 | ⬜ pending |
| OUTUX-06 | A vs B comparison recorded with numbers + winner | artifact | `177-HEALTH-COMPARISON.md` exists with gate table | ❌ W0 | ⬜ pending |
| D-21 | Retained stories via production components; manifest `fb-health-crowding`/`fb-account-context` scenario_ids + dispositions | ExUnit table | `mix test test/mailglass_admin/quick_view_projection_test.exs --only phase177 --seed 0` | ✅ (extend) | ⬜ pending |

All ExUnit commands run as `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 <command>`.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/health_population_test.exs` — fingerprint golden captured on pre-refactor commit
- [ ] `mailglass_admin/test/mailglass_admin/preview/return_context_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs` (detector self-tests + recorded mutations)
- [ ] `mailglass_admin/test/support/endpoint_case.ex` — denying `TestOperatorAuth` clause; `navigation:` on `/alt/dev/console` and `/secure/console`
- [ ] `mailglass_admin/e2e/phase177-return-navigation.spec.js`, `mailglass_admin/e2e/phase177-account.spec.js`, `mailglass_admin/e2e/phase177-health.spec.js` + shared visible-account locator helper `mailglass_admin/e2e/support/account.cjs`
- [ ] `reference/demo_app/assets/e2e/phase177-return.spec.js` + demo `AdminAuth` deny test `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs`

---

## Manual-Only Verifications

All phase behaviors have automated verification (D-52).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency: ExUnit per-task < 60s; Playwright per-task ~180s cold (advisory, measured in 177-01-SUMMARY.md)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
