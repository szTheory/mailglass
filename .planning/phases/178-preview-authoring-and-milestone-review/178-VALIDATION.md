---
phase: "178"
slug: "preview-authoring-and-milestone-review"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-29"
---

# Phase 178 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `178-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (admin, `--warnings-as-errors`), Playwright 1.59.x (operator + demo), Node `node --test` (checkers) |
| **Config file** | `mailglass_admin/mix.exs` (`verify.support_contract.admin` = whole admin suite), `mailglass_admin/playwright.config.cjs`, `reference/demo_app/assets/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test <files> --seed 0` |
| **Full suite command** | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin --seed 0` |
| **Estimated runtime** | ~240 seconds (admin suite); browser greps ~60–300 s each |

Browser runs use `npx playwright test` directly, never `npm run test:operator-browser` (it rebuilds and dirties `priv/static/app.css`).

---

## Sampling Rate

- **After every task commit:** the touched ExUnit files with `--seed 0` plus `bash mailglass_admin/scripts/check-conformance.sh`
- **After every plan wave:** `mix verify.support_contract.admin --seed 0`, the scoped Playwright greps, and `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs`
- **Before `/gsd-verify-work`:** admin suite green; demo `MIX_ENV=test mix test --seed 0` (restore `mix.lock` swoosh drift); the operator browser spec set; hosted runs on the candidate
- **Max feedback latency:** 300 seconds

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PRVUX-05 | "Restore defaults" bordered secondary, `reset_assigns` handler unchanged | LiveView | `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` | ✅ edit | ⬜ pending |
| PRVUX-05 | Geometry: full width <640, end-aligned ≥640, 44px, focus ring | browser | `npx playwright test --config=playwright.config.cjs e2e/structural.spec.js --grep "Phase 178" --workers=1` | ❌ W0 | ⬜ pending |
| PRVUX-06 | No generic helpers; single read-only note; describedby closure; specific errors kept | LiveView | same ExUnit command | ✅ edit | ⬜ pending |
| PRVUX-07 | Pure label builder: humanize, `__` collapse, collisions | unit | `mix test test/mailglass_admin/preview/scenario_label_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| PRVUX-07 | Trigger/options markup, raw-atom hrefs, Phase 177 return query | LiveView | `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/phase177_return_navigation_test.exs --seed 0` | ✅ edit | ⬜ pending |
| PRVUX-07 | Narrow/Unicode/duplicate/keyboard/real 200% zoom | browser | `npx playwright test … e2e/structural.spec.js --grep "Phase 171\|Phase 178"` | ✅ extend | ⬜ pending |
| STORY-07 | Authoring story set from production components; pure facts agree with live Preview | unit | `mix test test/mailglass_admin/quick_view_projection_test.exs --seed 0` | ✅ add | ⬜ pending |
| STORY-07 / UIQ-04 | Ledger rule + teeth; no pending/partial at close; zero-story count visible | unit | `mix test test/mailglass_admin/feedback_ledger_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| UIQ-04 | Stale phase-bound demo assertion replaced | browser (advisory) | `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js -g "Phase174 delivery scenario manifest"` | ✅ edit | ⬜ pending |
| UIQ-06 | Real zoom on Preview, Health, Account, quick view, filters; CSS zoom never labelled real | browser | `npx playwright test … --grep "real zoom\|200%"` | ✅ extend | ⬜ pending |
| UIQ-06 | Reduced motion + keyboard/focus for new controls | browser | `npx playwright test … --grep "Phase 178"` | ❌ W0 | ⬜ pending |
| UIQ-07 | Expected/executed counts; hosted identity and cost | CLI | `npx playwright test --list`; `node scripts/check_phase174_evidence.cjs … --pilot --require-ci` on the dispatch run | needs hosted run | ⬜ pending |
| UIQ-08 | Candidate: exact SHA, routes 200, built == served CSS digest, required contexts green | shell | `bash scripts/check_phase178_candidate.sh`; `gh pr checks <n>` | ❌ W0 | ⬜ pending |
| UIQ-08 / D-15 | Prohibition contract (teeth + clean) | unit | `mix test test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` + `test/mailglass_admin/preview/scenario_label_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs`
- [ ] `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs`
- [ ] `reference/demo_app/storybook/preview_authoring.story.exs`, `preview_authoring/1` builder, `reference/demo_app/assets/e2e/phase178-stories.spec.js`
- [ ] `scripts/check_phase178_candidate.sh`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Approval of push / draft PR / workflow dispatch | UIQ-08 (D-13) | Outward-facing remote action; owner authority | Single `checkpoint:decision` naming exact SHA, branch, PR, dispatch |
| Ship/no-ship review of the working preview | UIQ-08 | Owner ship decision (D-52 allowed hand-off) | Full-URL runbook in 178-DELIVERY.md, every URL verified first |

All other phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

## Gap closure verification (plans 178-13 to 178-19)

| Requirement | Verification item | Automated command or evidence | Status |
|-------------|-------------------|-------------------------------|--------|
| UIQ-08 | Required CI lanes catch a missing package in any `ci.yml` `node --test` step | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/ci_node_test_requires_contract_test.exs --seed 0` | ⬜ pending |
| UIQ-08 | The Demo `node --test` inputs load under the CI require guard with no allowed package roots | `NODE_OPTIONS="--require $PWD/test_js/support/ci-require-guard.cjs" MAILGLASS_REQUIRE_GUARD_ALLOWED='' MAILGLASS_REQUIRE_GUARD_RECORD=<record> node --test --test-name-pattern='^__mailglass_ci_require_guard_no_match__$' test_js/phase173-baselines.test.cjs scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` | ⬜ pending |
| UIQ-08 | The recorded Operator scroll-access advisory is repeatable and self-diagnosing | `cd mailglass_admin && CI=1 npx playwright test --config=playwright.config.cjs e2e/flows.spec.js --grep "Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled" --repeat-each=50 --workers=1`; see 178-14 repeated run and full-file rerun records | ⬜ pending |
| UIQ-06 | Re-gate Demo pilot receipts bind the candidate and pass in cold and warm | `node scripts/check_phase174_evidence.cjs --evidence-dir <rerun_local_pilot_evidence_dir> --pilot`; `node scripts/check_phase175_evidence.cjs --evidence-dir <rerun_local_pilot_evidence_dir> --pilot`; verify both Phase 178 story specs are `ok: true` in each report at `rerun_gate_head_sha` | ⬜ pending |
| UIQ-06, UIQ-07 | Hosted receipt identity, counts and cost disposition reproduce from the approved run inputs | 178-17 tasks 1-2: hosted pilot checkers with `--require-ci`, expected/executed count comparison, and byte-identical `scripts/phase178_cost_disposition.cjs disposition` reproduction | ⬜ pending |
| UIQ-08 | Re-frozen candidate preview and runbook URLs resolve to the claimed pages | 178-18 tasks 1-2: `bash scripts/check_phase178_candidate.sh --sha <rerun_candidate_sha> --require-ci --record <record>`; fetch each runbook URL and verify HTTP 200 plus its page marker, or resolve GitHub URLs with `gh` | ⬜ pending |
