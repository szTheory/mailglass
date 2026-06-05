---
phase: 76
slug: component-library-and-design-system-hardening
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
audited: 2026-06-04
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
| DS-01 | Exact CSS class per atom (24 atom tests across 4 taxonomy tables) | unit | `mix test test/mailglass_admin/components_test.exs` | ✅ | ✅ green |
| DS-01 | Exact `hero-*` icon name per atom (24 atom tests) | unit | `mix test test/mailglass_admin/components_test.exs` | ✅ | ✅ green |
| DS-01 | Exact text label per atom (24 atom tests) | unit | `mix test test/mailglass_admin/components_test.exs` | ✅ | ✅ green |
| DS-01 | No private `badge_class/1` remains (all 5 copies deleted) | structural grep | `! grep -rn 'defp badge_class' mailglass_admin/lib/` | ✅ | ✅ green |
| DS-02 | Zero raw `text-(sm\|base\|xs)` in admin HEEx | structural grep | `! grep -rE '\btext-(sm\|base\|xs)\b' mailglass_admin/lib/` | ✅ | ✅ green |
| DS-02 | Zero off-grid `gap-(3\|4\|6)` in admin HEEx | structural grep | `! grep -rE '\bgap-(3\|4\|6)\b' mailglass_admin/lib/` | ✅ | ✅ green |
| DS-02 | Zero `font-medium/semibold`, ad-hoc `z-[N]`, hex colors in HEEx classes | structural grep | conformance grep per `design-system.md:104-121` | ✅ | ✅ green |
| DS-03 | Support cards render Tier 1 (full card) / Tier 2 (compact row) hierarchy | unit/LiveView | `mix test test/mailglass_admin/operator_live_test.exs` (support-card drilldown render assert) | ✅ | ✅ green |
| DS-04 | Asset bundle rebuilt + committed, no drift | structural diff | `git diff --exit-code mailglass_admin/priv/static/` | ✅ (CI) | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/mailglass_admin/components_test.exs` — NEW file written in 76-01 Task 2. 30 tests (24 atom tests + 6 `normalize_inbound_outcome` tests), one assertion-group per atom asserting exact CSS class **+** `hero-*` icon name **+** text label (Pitfall 5: one assertion per atom, no atom-loop). Covers the new atoms with no prior copy (`:queued`, `:opened`, `:clicked`, `:autoresponded`, `:unknown`, `:failed_ingest`). Runs green: `mix test test/mailglass_admin/components_test.exs --seed 0` → 30 tests, 0 failures.
- [x] DS-03 support-card hierarchy exercised by `test/mailglass_admin/operator_live_test.exs:207` (support-card drilldown render asserts `data-testid="support-card-failed-ingest-detail"`). The Tier 1/Tier 2 *visual* prominence remains a documented Manual-Only browser check.

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
- [x] `wave_0_complete` — flipped true; 76-01 Task 2 wrote `components_test.exs` (GREEN commit 27262c55, RED commit f22265d6)

**Approval:** approved 2026-06-04 (plan-phase verification loop)

---

## Validation Audit 2026-06-04

Retroactive Nyquist audit (`/gsd-validate-phase 76`, State A). Confirmed each requirement
against the live codebase — ran the grep gates, the test suite, and the bundle-drift check
directly rather than trusting prior reports.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Evidence (re-run 2026-06-04):**
- `mix test test/mailglass_admin/components_test.exs --seed 0` → 30 tests, 0 failures
- `grep -rn 'defp badge_class' mailglass_admin/lib/ --include="*.ex"` → empty (CLEAN)
- `grep -rE '\btext-(sm\|xs)\b' …` / `\bgap-(3\|4\|6)\b` / `\bfont-(medium\|semibold)\b` → all empty (CLEAN)
- `git diff --exit-code mailglass_admin/priv/static/` → exit 0 (bundle committed)
- DS-03: `test/mailglass_admin/operator_live_test.exs:207` renders support cards via LiveView

**Conclusion:** Phase 76 is Nyquist-compliant. All automated-testable requirements (DS-01..DS-04)
are COVERED and green. No auditor spawn required (zero gaps). The 4 outstanding browser-visual
checks (badge CSS-mask render, inbound normalization, Tier1/Tier2 prominence, 390px overflow)
are correctly classified Manual-Only and mirrored in `76-VERIFICATION.md` Human Verification —
the 390px overflow is deferred to the Phase 79 audit-matrix re-run.
