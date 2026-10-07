---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 169 — Validation Strategy

Planning contract only. No Phase 169 product checks have run. The planner will bind the requirement coverage below to concrete task IDs and threat references before plan checking.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit (core and Admin); existing Playwright operator harness |
| Config | Root/Admin Mix projects; `mailglass_admin/playwright.config.cjs` |
| Core quick command | `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs test/mailglass/operator/replay_targets_test.exs --seed 1` |
| Admin quick command | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` |
| Full phase command set | Core operator + replay tests; Admin complete ExUnit suite; `npm --prefix mailglass_admin run test:operator-browser` |
| Asset checks | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` |
| Runtime | Not measured for Phase 169; do not reuse historical timing as current evidence |

## Sampling Rate

- After each implementation task: run the narrow affected core or Admin tests; each task states the command and observable failure signal.
- After each connected slice: run targeted browser cases once the existing isolated harness is ready.
- After each wave: run the relevant cumulative semantic checks; run asset parity after CSS/HEEx changes.
- Before phase verification: run the full phase command set and review the connected rendered evidence.
- Feedback target: narrow checks under 60 seconds where practical; measure during execution and split long selections without weakening coverage.

## Per-Task Verification Map

Planner must replace this requirement seed with concrete task rows, exact existing/planned test paths, wave and unique threat references.

| Requirement | Required proof | Existing test location | Status |
|---|---|---|---|
| OUTUX-01 | Actual observation window/populations; same-kind destination; independent unavailable/stale/zero | core support_summary tests; Admin operator_live tests | pending execution |
| OUTUX-02 | Exact Account+Delivery independent of page/filter/window; clear return; Account reset; URL/draft/history | core deliveries tests; Admin operator_live and shell tests; browser flows | pending execution |
| OUTUX-03 | Recorded/source semantics; 100/101 overflow; exact selected event; copy and UTC | core timeline; Admin timeline/component tests; browser flows | pending execution |
| OUTUX-04 | Current suppression versus history, policy/expiry, exact Account evidence association | core suppressions/support_summary; Admin operator_live tests | pending execution |
| OUTUX-05 | Frozen exact target/facts, revalidation, host auth, one consumed review; truthful recorded outcomes | core replay_targets/replay tests; Admin replay_modal/operator_live tests; browser flows | pending execution |

## Wave 0 Requirements

- [ ] Use existing ExUnit/Playwright infrastructure; resolve the actual BEAM runtime and browser/test DB prerequisites before execution without changing project pins.
- [ ] Create deterministic exact selection/foreign ID, 101+ event, independent panel failure, current suppression and zero/one/many replay fixtures before dependent assertions.
- [ ] Include changed/removed sole replay target, duplicate queued confirmation, requested-only audit and terminal evidence failure cases.
- [ ] Capture pre-edit source revision, served CSS hash, fixture, route, theme, OS theme, viewport and zoom before the first product edit.

## Manual-Only Verifications

Agent-operated rendered inspection is required for typography, composition, clipped/wrapped content, focus visibility, overlay containment, and coherent copy in connected Health → Delivery → evidence → replay → return flows. Capture representative 320/390/768/1440 widths, 200% zoom, Light/Dark/System and reduced motion, long/non-ASCII values, keyboard and touch. DOM assertions supplement this judgment. Apply one bounded correction batch and confirm affected views. User feedback is optional after the automated baseline; do not substitute a source-only review for rendered evidence.

## Validation Sign-Off

- [ ] Concrete task map and threat references complete
- [ ] Every task has automated verification and an observable failure signal
- [ ] No three consecutive tasks without automated verification
- [ ] Missing fixtures/tests are created before dependent verification
- [ ] No watch flags or historical proof substituted for current execution
- [ ] Feedback timing measured during execution
- [ ] Execution validation complete before setting nyquist_compliant true

**Approval:** Planning seed; execution evidence pending.
