---
phase: "178"
slug: "preview-authoring-and-milestone-review"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-29"
validated: "2026-11-02"
---

# Phase 178 — Validation Strategy

> Audit of the eight phase requirements against their behavioral tests and retained exact-candidate receipts. The initial map was stale: Wave 0 tests had since been added, and later recovery plans closed additional UIQ-08 evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | ExUnit, Playwright 1.59.x, Node `node --test`, and offline shell contract tests |
| **Config files** | `mailglass_admin/mix.exs`, `mailglass_admin/playwright.config.cjs`, `reference/demo_app/assets/playwright.config.cjs` |
| **Toolchain** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` for local Mix commands |
| **Focused local command** | `cd mailglass_admin && mix test <phase-178-files> --seed 0` |
| **Full admin command** | `cd mailglass_admin && mix verify.support_contract.admin --seed 0` |

Browser runs use `npx playwright test` directly. The browser suite was not launched during this audit because it requires an app service; its latest exact-candidate results are cited below. No hosted workflow, container, or preview service was started.

## Per-Requirement Verification Map

| Requirement | Observable behavior and verification | Type | Status |
|-------------|--------------------------------------|------|--------|
| PRVUX-05 | Restore-defaults action has its expected name/classes, restores defaults and clears drafts/errors; browser checks cover responsive geometry, border, focus, and reduced motion. Local: `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0`. Browser: `e2e/structural.spec.js` Phase 178 cases. | LiveView + browser | **green** — local behavior tests passed; exact-candidate browser receipt passed. |
| PRVUX-06 | Read-only guidance appears once in the mixed form, specific validation errors remain, and all ARIA references resolve; the Preview axe cell matches the baseline. Local: same Preview test command above. Browser: `e2e/structural.spec.js` axe and assigns cases. | LiveView + browser | **green** — local behavior tests passed; exact-candidate browser receipt passed. |
| PRVUX-07 | Humanized and collision-safe labels, visible technical identity, unchanged scenario URLs/return context, and keyboard access for long Unicode choices. Local: `mix test test/mailglass_admin/preview/scenario_label_test.exs test/mailglass_admin/preview_live_test.exs test/mailglass_admin/phase177_return_navigation_test.exs --seed 0`. Browser cases are listed in `e2e/structural.spec.js` and `e2e/flows.spec.js`. | Unit + LiveView + browser | **green** — local behavior tests passed; browser suite passed on the exact candidate. |
| STORY-07 | Authoring stories render production components and their facts agree with the live Preview field set; story accounting requires each feedback row to have a story or a counted connected-only boundary. Local: `mix test test/mailglass_admin/quick_view_projection_test.exs test/mailglass_admin/feedback_ledger_test.exs --seed 0`. Demo browser: `e2e/phase178-stories.spec.js`. | Unit + browser | **green** — local behavior tests passed; exact-candidate Demo receipts passed cold and warm. |
| UIQ-04 | Ledger pointers and two-way scenario links resolve; no row is pending/partial; the replaced Phase 174 assertion and deterministic inbound projection cutoff are covered. Local: admin feedback-ledger/projection tests above, plus `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/records_test.exs --seed 0`. The Phase 174 demo assertion ran in the retained Demo suite. | Integration + browser | **green** — local admin and inbound tests passed; Demo receipt passed. |
| UIQ-06 | Real browser zoom at 320 CSS px, Preview reduced motion/focus, and StatCard production font roles are covered; the prohibition contract rejects calling CSS `zoom` real zoom. Local prohibition test: `mix test test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0`. Browser specs: `phase178-real-zoom.spec.js`, `structural.spec.js`, and `phase178-stories.spec.js`. | Browser + unit | **green** — prohibition test passed; hosted Operator and Demo receipts passed on the exact candidate. |
| UIQ-07 | Expected/executed browser counts and hosted identity/cost disposition match the retained exact-candidate evidence. Local: `node --test scripts/phase178_cost_disposition.test.cjs scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs`. | CLI + evidence | **green** — checker tests passed; exact-candidate receipts show 310 operator passes, one expected skip, no failures/flakes, and 169 Demo checks in both cold and warm runs. The recorded cost disposition is reproducible and its overage is explicitly scoped to this review cycle. |
| UIQ-08 | CI Node package resolution is guarded; permanent state facts are pinned; candidate launcher refusals are tested offline; the accepted exact-SHA preview record shows six default routes at HTTP 200, matching built/served CSS hashes, successful required CI contexts, and later 17 URL/marker checks. Local: `mix test test/scripts/ci_node_test_requires_contract_test.exs test/mailglass/state_md_contract_test.exs --seed 0 --warnings-as-errors`; no-match require-guard smoke below; `bash scripts/test_check_phase178_candidate.sh`. | Contract + smoke + retained preview receipt | **green** — all local checks passed; Plan 24 records owner acceptance and candidate-scoped cleanup. |

### Current Audit Results (2026-11-02)

| Check | Result |
|-------|--------|
| Focused Admin behavior set (Preview, label builder, navigation, discovery, story projection, ledger, capture task, prohibition contract) | 233 tests, 0 failures, 1 excluded |
| Inbound records projection | 41 tests, 0 failures |
| Root state and CI require-guard contracts | 16 tests, 0 failures |
| Node evidence and cost checker tests | 59 tests, 0 failures |
| Offline candidate-launcher self-test | 13 checks passed; Docker/GitHub operations stubbed |
| CI require-guard load-only smoke | All 5 test files loaded with no allowed package roots |
| Playwright inventory | 12 matching Operator cases and 2 Phase 178 Demo cases listed; browser execution used the retained exact-candidate receipts |

The browser receipts are recorded in `178-AUTOMATION.md`, `178-CYCLE-09-COST-DISPOSITION.json`, `178-38-SUMMARY.md`, and `178-24-SUMMARY.md`. The attempt-3 launcher record is `reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/preview-attempt-3.json`; the runbook URLs are historical and the preview was removed after owner acceptance.

## Wave 0 Requirements

- [x] Scenario label behavior test.
- [x] Feedback ledger behavior and mutation tests.
- [x] Phase 178 prohibition contract tests.
- [x] Preview authoring story projection tests and Demo browser specs.
- [x] Offline candidate launcher contract test.

## Manual-Only Verifications

| Behavior | Requirement | Outcome |
|----------|-------------|---------|
| Approval of the exact candidate's hosted sequence and conditional preview | UIQ-08 | Completed; cycle 9 approval, CI/cost receipts, and exact-SHA preview are recorded. |
| Owner ship/no-ship decision for the working preview | UIQ-08 | Completed; owner accepted candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023` in Plan 24, then candidate-only cleanup completed. |

## Validation Sign-Off

- [x] All eight requirements have automated behavior coverage; manual owner decisions are recorded as complete.
- [x] Wave 0 dependencies exist and their focused tests pass.
- [x] No watch-mode flags are used.
- [x] Focused local test feedback stayed under 300 seconds per command.
- [x] `nyquist_compliant: true`.

**Approval:** validated by the focused local tests and retained exact-candidate browser/evidence receipts.

## Evidence Limit

At the time this audit was first written, `178-VERIFICATION.md` still marked UIQ-08 open based on the earlier Cycle 06 stop. Plans 38 and 24 subsequently record a passing attempt-3 preview, owner acceptance, and cleanup; final phase verification reconciles that history against the later evidence.

## Validation Audit 2026-11-02

| Metric | Count |
|---|---|
| Gaps found | 8 |
| Resolved | 8 |
| Escalated | 0 |

## Final closeout gate (2026-11-02)

The candidate launcher and cost-disposition follow-up tests passed: 19 offline launcher checks and 20 Node tests. The phase regression gate then passed with the repository's pinned OTP/Elixir versions: 42 Storybook/evidence tests, 81 core tests, 1,205 Admin tests (one excluded), 481 inbound tests plus 3 properties (three excluded), and 37 connected Operator/Preview browser checks. The first browser launch was blocked by the sandbox's macOS Mach-port restriction; rerunning the same local gate with host process permission completed the browser suite successfully. No Docker preview or hosted workflow was launched.

The offline launcher test now removes its own synthetic teardown directories through either macOS temp path spelling (`/tmp` or `/private/tmp`). After the final run, no `mailglass-phase178.*` test directories remained. Historical Phase 168/169 screenshot changes were present before the gate and remain preserved by its snapshot/restore trap.
