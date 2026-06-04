---
phase: 75
slug: information-architecture-navigation-and-orientation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `75-RESEARCH.md` § Validation Architecture. This is a frontend (`mailglass_admin`)
> phase plus one additive core `mailglass` read-model function. No DB schema change.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Elixir)** | ExUnit (`mix test`) |
| **Framework (e2e)** | Playwright (`operator.spec.js` + `demo.spec.js`) |
| **Config file** | `mailglass_admin/e2e/playwright.config.js` (e2e); standard `mix test` (ExUnit) |
| **Quick run command** | `mix test test/mailglass_admin/ --seed 0` + `npx playwright test mailglass_admin/e2e/operator.spec.js` |
| **Full suite command** | `mix test --seed 0` (scope per-package to avoid the inbound flake) + both e2e specs |
| **Estimated runtime** | ~30–90 seconds (ExUnit fast; Playwright dominates) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass_admin/ --seed 0` (+ `npx playwright test operator.spec.js` for any LiveView render change)
- **After every plan wave:** Run full `mix test --seed 0` (per-package scope — `project_inbound_suite_flake`) + both e2e specs
- **Before `/gsd:verify-work`:** Full suite green + conformance greps pass + `git diff --exit-code priv/static/` clean
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

> Task IDs are placeholders until the planner finalizes plan/wave assignment; the
> requirement → behavior → test-type mapping is authoritative (from RESEARCH § Validation Architecture).

| Plan (likely) | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| shell/orientation | 1 | IA-01 | aggregate-only, no PII | structural ExUnit + grep | `grep -n "def orientation_strip" mailglass_admin/lib/mailglass_admin/operator/shell.ex` | ❌ W0 (shell_test.exs) | ⬜ pending |
| shell/orientation | 1 | IA-01 | N/A | LiveView ExUnit + Playwright | `mix test test/mailglass_admin/operator_live_test.exs` + `npx playwright test operator.spec.js` | ✅ / ❌ W0 | ⬜ pending |
| inbound orientation | 1 | IA-01 | N/A | LiveView ExUnit | `mix test test/mailglass_admin/inbound_live_test.exs` | ✅ | ⬜ pending |
| preview orientation | 1 | IA-01 | N/A | LiveView ExUnit | `mix test test/mailglass_admin/preview_live_test.exs` | ✅ | ⬜ pending |
| preview orientation | 1 | IA-01 | preserve `preview-empty-mailables` | regression ExUnit | `mix test test/mailglass_admin/preview_live_test.exs` | ✅ | ⬜ pending |
| frozen copy | 1 | IA-01 | verbatim copy | conformance grep | `grep -n "Email never arrived" mailglass_admin/lib/mailglass_admin/operator/shell.ex` | n/a | ⬜ pending |
| token-clean | 1 | IA-01/IA-03 | no faux-bold/raw size | conformance grep | `grep -n "text-sm" mailglass_admin/lib/mailglass_admin/operator/shell.ex` → 0 hits on new component | n/a | ⬜ pending |
| core suppressions | 1 | IA-02 | tenant-scoped, aggregate | ExUnit (core) | `mix test test/mailglass/operator/suppressions_test.exs` | ✅ / ❌ W0 | ⬜ pending |
| overview branch | 2 | IA-02 | `params["view"]` pattern-matched | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t overview` | ❌ W0 | ⬜ pending |
| overview no-tenant | 2 | IA-02 | nudge, no health row | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "overview no tenant"` | ❌ W0 | ⬜ pending |
| overview health | 2 | IA-02 | aggregate counts only | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "overview health"` | ❌ W0 | ⬜ pending |
| suppression degradation | 2 | IA-02 | degrade to `—`, never crash | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs -t "suppression degradation"` | ❌ W0 | ⬜ pending |
| aria-current | 2 | IA-02 (GAP-21) | N/A | LiveView ExUnit (regression) | `mix test test/mailglass_admin/operator/shell_test.exs -t aria-current` | ❌ W0 | ⬜ pending |
| `?view=deliveries` nav | 2 | IA-02 | preserve `tenant_id` | Playwright | `npx playwright test operator.spec.js` | ✅ | ⬜ pending |
| e2e ripple (operator) | 3 | IA-03 | N/A | Playwright (same-commit) | `npx playwright test mailglass_admin/e2e/operator.spec.js` | ✅ | ⬜ pending |
| e2e ripple (demo) | 3 | IA-03 | N/A | Playwright (same-commit) | `npx playwright test reference/demo_app/assets/e2e/demo.spec.js` | ✅ | ⬜ pending |
| 390px structural | 3 | IA-03 (GAP-07/09/11) | N/A | Playwright | `npx playwright test operator.spec.js --grep mobile` | ✅ (extend) | ⬜ pending |
| deep-link disposition | — | IA-04 (GAP-22) | N/A | documentation | manual: deferral note near `docs/design-system.md:141-150` referencing Phase 79 | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass_admin/operator/shell_test.exs` — `Shell.orientation_strip/1` public-component tests (per-surface testids + verbatim copy + token-clean class); `aria-current` regression *(create if absent)*
- [ ] `test/mailglass_admin/operator_live_test.exs` — Overview branch cases: no-tenant nudge, with-tenant health counts, suppression degradation to `—`, `?view=deliveries` navigation *(extend existing)*
- [ ] `test/mailglass/operator/suppressions_test.exs` — `count_active_suppressions/1` cases: count correctness + active-only filter (excludes expired/wrong-tenant) *(create/extend in core)*
- [ ] Extend Playwright test 2 (`operator.spec.js:64-89`) — assert `deliveries-orientation` testid visible at 390px

*Confirm each test file's existence during Wave 0; create stubs where ❌.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 390px readability (orientation strip, health counts, nav cards) | IA-03 (GAP-07/09/11) | Visual legibility judgment; `agent-browser` is local-only, not CI (VR-NEXT-01 out of scope) | Local screenshot→LLM-critique ritual: capture `tmp/ui-audit/{surface}-390-{light,dark}.png`; review before IA merge |
| Deep-link GAP-22 disposition recorded | IA-04 | Decision/documentation artifact, not code | Confirm deferral-to-Phase-79 note + asset-seam rationale recorded near `docs/design-system.md:141-150` and in plan |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 test files + 1 Playwright extension)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
