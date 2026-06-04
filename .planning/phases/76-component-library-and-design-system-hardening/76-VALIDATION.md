---
phase: 76
slug: component-library-and-design-system-hardening
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `76-RESEARCH.md` § Validation Architecture (Gap 4). Admin-only refactor —
> validation is structural (CSS-class/icon/label per atom + token-conformance grep + bundle diff).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest (`render_component/2`) |
| **Config file** | `mailglass_admin/test/test_helper.exs` (existing) |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix test --seed 0` |
| **Estimated runtime** | ~quick: <5s · full: ~30–60s |

---

## Sampling Rate

- **After every task commit:** `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs`
- **After every plan wave:** `cd mailglass_admin && mix test --seed 0`
- **Before `/gsd:verify-work`:** Full suite green **AND** token-conformance grep gates return zero **AND** `git diff --exit-code priv/static/` clean
- **Max feedback latency:** ~5 seconds (quick) / ~60 seconds (full)

---

## Per-Task Verification Map

> Plan/task IDs are placeholders until the planner finalizes plan splits; the requirement→test mapping below is the contract. Bind each task to one row.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| DS-01 | Exact CSS class per atom (24 atoms across 4 taxonomy tables) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ W0 | ⬜ pending |
| DS-01 | Exact `hero-*` icon name per atom (24 atoms) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ W0 | ⬜ pending |
| DS-01 | Exact text label per atom (24 atoms) | unit | `mix test test/mailglass_admin/components_test.exs` | ❌ W0 | ⬜ pending |
| DS-01 | No private `badge_class/1` remains (all 5 copies deleted) | structural grep | `! grep -rn 'defp badge_class' mailglass_admin/lib/` | ✅ | ⬜ pending |
| DS-02 | Zero raw `text-(sm\|base\|xs)` in admin HEEx | structural grep | `! grep -rE '\btext-(sm\|base\|xs)\b' mailglass_admin/lib/` | ✅ | ⬜ pending |
| DS-02 | Zero off-grid `gap-(3\|4\|6)` in admin HEEx | structural grep | `! grep -rE '\bgap-(3\|4\|6)\b' mailglass_admin/lib/` | ✅ | ⬜ pending |
| DS-02 | Zero `font-medium/semibold`, ad-hoc `z-[N]`, hex colors in HEEx classes | structural grep | conformance grep per `design-system.md:104-121` | ✅ | ⬜ pending |
| DS-03 | Support cards render Tier 1 (full card) / Tier 2 (compact row) hierarchy | unit/LiveView | `mix test test/mailglass_admin/` (support-card render assert) | ⚠️ W0-extend | ⬜ pending |
| DS-04 | Asset bundle rebuilt + committed, no drift | structural diff | `git diff --exit-code mailglass_admin/priv/static/` | ✅ (CI) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass_admin/components_test.exs` — NEW file. 24-atom `status_badge/1` coverage: one assertion-group per atom asserting exact CSS class **+** `hero-*` icon name **+** text label (Pitfall 5: one assertion per atom, never a loop that hides a divergent atom). Must cover the new atoms with no prior copy: `:queued`, `:opened`, `:clicked`, `:autoresponded`, `:unknown`, `:failed_ingest`. House pattern: `test/mailglass_admin/inbound/components_test.exs:26`, `test/mailglass_admin/operator/shell_test.exs:12`.
- [ ] (optional) extend an existing LiveView/component test to assert the support-card Tier 1/Tier 2 structure (DS-03).

*All other test infrastructure already exists — ExUnit, Phoenix.LiveViewTest, LiveViewCase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 390px compressed-row overflow re-check (icon widens every badge) | DS-01 / GAP-10 | Visual clipping not assertable via `render_component` substring match | Local screenshot review at 390px width (deferred final pass is Phase 79); during Phase 76, planner notes it as a `autonomous: false` visual checkpoint or rolls into the Phase 79 audit-matrix re-run. Not a hard Phase 76 gate. |

*All structural Phase 76 behaviors (class/icon/label/grep/bundle) have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have an automated verify command or a Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the MISSING `components_test.exs` reference (planned in 76-01 Task 2)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] `wave_0_complete` — flips true during /gsd:execute-phase once 76-01 Task 2 writes the test file

**Approval:** approved 2026-06-04 (plan-phase verification loop)
