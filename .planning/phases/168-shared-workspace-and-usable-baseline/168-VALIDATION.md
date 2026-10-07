---
phase: "168"
slug: "shared-workspace-and-usable-baseline"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 168 — Validation Strategy

Planning contract only. No product checks or rendered verification have run in this planning session. Final task IDs and command allocation are completed with the plans.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit/LiveView tests and opt-in Playwright suite |
| Config | `mailglass_admin/mix.exs`, `mailglass_admin/playwright.config.cjs` |
| Quick command (repository root) | `cd mailglass_admin && mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1` |
| Phase integration command (repository root) | `cd mailglass_admin && mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` |
| Asset build (repository root) | `cd mailglass_admin && mix mailglass_admin.assets.build` |
| Existing browser command (repository root) | `cd mailglass_admin && npm run test:operator-browser` |
| Runtime | Research estimates 30–120 seconds for focused LiveView checks; unmeasured. Browser runtime unmeasured. |

Commands require the package's documented toolchain/database setup. Resolve host Elixir/OTP mismatch through the existing gating-toolchain container when necessary; do not change CI or dependency policy. Browser fixture host and AtlasDesk demo are distinct; label evidence accordingly. The existing opt-in browser harness is not a new product Node toolchain.

## Sampling Rate

- After an implementation task: run the smallest existing checks covering that task, with an observable nonzero/missing-assertion failure condition in its plan.
- After a plan wave: run affected integration and asset checks. Rebuild source CSS before bundle checks and before rendered review.
- Before Phase 168 verification: affected checks and the specified direct-browser matrix must pass; source assertions alone cannot establish visual quality or focus behavior.
- Keep review bounded to one inspection, one corrective batch, and one confirmation per coherent slice; extend only for a concrete unresolved blocker.
- Feedback target: under 120 seconds for focused checks; measure actual timing in execution and report slower prerequisites honestly.

## Per-Task Verification Map

The planner will replace this seed with concrete task IDs, waves, commands, existing-file status, and applicable threat references before final plan verification. All results remain pending until execution.

## Wave 0 Requirements

- Existing test infrastructure is available. No framework installation is planned.
- Reconcile preserved source with merged cleanup while retaining unrelated work; identify the served checkout/revision and assets before baseline capture or UI edits.
- Record toolchain, database, browser and fixture prerequisites. Treat unavailable prerequisites as unverified, never as passing.
- Add focused regressions only for demonstrated gaps in the approved behaviors; retain substantive authorization/scope/action checks when presentation assertions change.

## Manual-Only Verifications

“Manual” means direct browser/visual inspection, which the executing agent may perform with browser tools.

| Behavior | Requirement | Why direct inspection | Instructions |
| --- | --- | --- | --- |
| Identified before/after specimens | UXF-01 | Historical artifacts and source checks do not prove current output | Record source/asset identity, route, fixture/persona, theme/OS scheme, viewport, zoom, state, issue and capture. |
| Reflow, readable exact values and targets | UXF-02, UXF-03, UXF-04, UXF-06, UXF-07 | Markup does not prove clipping/readability | Inspect representative 320/390/768/1440 CSS px and 200% zoom, long/non-ASCII names/IDs, touch and keyboard. |
| Theme preference versus effective scheme | UXF-05 | Cookie/radio assertions do not prove OS response | Choose System; change OS scheme; navigate and reload; verify System remains selected and email appearance remains independent. |
| Overlay focus and motion | UXF-07, UXF-08 | Structural focus hooks do not prove actual focus/animation | Open/close Quick view and confirmation; cycle focus, Escape/dismiss, return focus; inspect reduced motion and repeated LiveView patches. |
| Applicable adverse states | UXF-01..08 | Fixtures need truthful, visible state | Cover UI-SPEC's 52 criteria through a representative matrix; distinguish unavailable/denied/empty/partial/stale, never fabricate a success. |

## Validation Sign-Off

- [ ] Every task has an automated verification or explicit prerequisite and direct-browser evidence where applicable.
- [ ] No three consecutive implementation tasks lack automated feedback.
- [ ] No missing test targets or watch-mode commands.
- [ ] Measured execution timing and actual outcomes recorded.
- [ ] `nyquist_compliant: true` set only when established by the appropriate validation workflow.

**Approval:** Planning draft; execution evidence pending.
