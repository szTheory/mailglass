---
phase: 75
slug: information-architecture-navigation-and-orientation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
validated: 2026-06-04
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

> Statuses below reflect the EXECUTED phase (Plans 75-01/02/03). Test files are
> confirmed present and green; the requirement → behavior → test-type mapping is
> authoritative (from RESEARCH § Validation Architecture).

| Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 75-02 | 2 | IA-01 | aggregate-only, no PII | structural ExUnit + grep | `grep -n "def orientation_strip" mailglass_admin/lib/mailglass_admin/operator/shell.ex` (→ L314) | ✅ | ✅ green |
| 75-02 | 2 | IA-01 | N/A | component ExUnit + Playwright | `mix test test/mailglass_admin/operator/shell_test.exs` (orientation_strip/1, 4 tests) + `npx playwright test operator.spec.js` | ✅ | ✅ green |
| 75-02 | 2 | IA-01 | N/A | LiveView ExUnit | `mix test test/mailglass_admin/inbound_live_test.exs` (inbound-orientation testid) | ✅ | ✅ green |
| 75-02 | 2 | IA-01 | N/A | LiveView ExUnit | `mix test test/mailglass_admin/preview_live_test.exs` (preview-orientation testid) | ✅ | ✅ green |
| 75-02 | 2 | IA-01 | preserve `preview-empty-mailables` | regression ExUnit | `mix test test/mailglass_admin/preview_live_test.exs` (coexist test) | ✅ | ✅ green |
| 75-02 | 2 | IA-01 | verbatim copy | conformance grep | `grep -n "Email never arrived" mailglass_admin/lib/mailglass_admin/operator/shell.ex` | n/a | ✅ green |
| 75-02 | 2 | IA-01/IA-03 | no faux-bold/raw size | conformance grep | `grep -n "text-sm" .../shell.ex` → 0 hits on new component | n/a | ✅ green |
| 75-01 | 1 | IA-02 | tenant-scoped, aggregate | ExUnit (core) | `mix test test/mailglass/operator/suppressions_test.exs` (9 tests) | ✅ | ✅ green |
| 75-03 | 3 | IA-02 | `params["view"]` pattern-matched | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs` ("Operator Overview branch") | ✅ | ✅ green |
| 75-03 | 3 | IA-02 | nudge, no health row | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs` (no-tenant nudge) | ✅ | ✅ green |
| 75-03 | 3 | IA-02 | aggregate counts only | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs` (health counts) | ✅ | ✅ green |
| 75-03 | 3 | IA-02 | degrade to `—`, never crash | LiveView ExUnit | `mix test test/mailglass_admin/operator_live_test.exs` (suppression degradation) | ✅ | ✅ green |
| 75-03 (audit) | 3 | IA-02 (GAP-21) | active resolves to `:deliveries`, never `:overview` | component ExUnit (regression) | `mix test test/mailglass_admin/operator/shell_test.exs` (aria-current nav resolution, 2 tests) | ✅ | ✅ green |
| 75-03 | 3 | IA-02 | preserve `tenant_id` | Playwright | `npx playwright test operator.spec.js` | ✅ | ✅ green |
| 75-03 | 3 | IA-03 | N/A | Playwright (same-commit) | `npx playwright test mailglass_admin/e2e/operator.spec.js` | ✅ | ✅ green |
| 75-03 | 3 | IA-03 | N/A | Playwright (same-commit) | `npx playwright test reference/demo_app/assets/e2e/demo.spec.js` | ✅ | ✅ green |
| 75-03 | 3 | IA-03 (GAP-07/09/11) | N/A | Playwright | `npx playwright test operator.spec.js` (390px deliveries-orientation) | ✅ | ✅ green |
| 75-03 | 3 | IA-04 (GAP-22) | N/A | documentation | deferral note in `docs/design-system.md` (GAP-22 ×3) referencing Phase 79 | n/a | 📋 manual-only |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · 📋 manual-only*

---

## Wave 0 Requirements

- [x] `test/mailglass_admin/operator/shell_test.exs` — `Shell.orientation_strip/1` public-component tests (per-surface testids + verbatim copy + token-clean class) *(75-02)*; `aria-current` nav-resolution regression *(filled by 2026-06-04 validation audit)*
- [x] `test/mailglass_admin/operator_live_test.exs` — Overview branch cases: no-tenant nudge, with-tenant health counts, suppression degradation to `—`, `?view=deliveries` navigation *(75-03)*
- [x] `test/mailglass/operator/suppressions_test.exs` — `count_active_suppressions/1` cases: count correctness + active-only filter (excludes expired/wrong-tenant) *(75-01, 9 tests)*
- [x] Extend Playwright test (`operator.spec.js`) — assert `deliveries-orientation` testid visible at 390px *(75-03)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 390px readability (orientation strip, health counts, nav cards) | IA-03 (GAP-07/09/11) | Visual legibility judgment; `agent-browser` is local-only, not CI (VR-NEXT-01 out of scope) | Local screenshot→LLM-critique ritual: capture `tmp/ui-audit/{surface}-390-{light,dark}.png`; review before IA merge |
| Deep-link GAP-22 disposition recorded | IA-04 | Decision/documentation artifact, not code | Confirm deferral-to-Phase-79 note + asset-seam rationale recorded near `docs/design-system.md:141-150` and in plan |

---

## Validation Audit 2026-06-04

State A retroactive audit of the executed phase (Plans 75-01/02/03). Cross-referenced
each requirement against the real test files. One gap found: the `aria-current nav
resolution` test in `shell_test.exs` was left as an empty `@tag :skip` stub (never
implemented by 75-02 or 75-03) — it compiled and was excluded, so it verified nothing.

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Resolved:** `aria-current nav resolution` (IA-02 / GAP-21). Un-skipped and implemented
as two behavioral tests rendering `Shell.shell/1` and asserting via Floki that
`active={:deliveries}` resolves `aria-current="page"` onto the Deliveries nav items (sidebar
`nav_link` + mobile `nav_pill`) and never Inbound, with a contrast render proving the marker
flips on `active={:inbound}`. Guards the PATTERNS.md anti-pattern (no nonexistent `:overview`
active state). `mix test test/mailglass_admin/operator/shell_test.exs --seed 0` → 6 tests, 0 failures.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (3 test files + 1 Playwright extension) — all confirmed present + green
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

> **Manual-only (by design, not gaps):** (1) 390px visual readability of the orientation
> strip / health counts / nav cards — visual-legibility judgment, intrinsically non-CI
> (VR-NEXT-01 out of scope); (2) GAP-22 deep-link disposition — a documentation/decision
> artifact recorded in `docs/design-system.md`, deferred to Phase 79. Every *code-level*
> requirement has automated green verification.

**Approval:** Nyquist-compliant (2026-06-04)
