---
phase: 118
slug: method-audit-storybook-stand-up
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-26
---

# Phase 118 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Filled from 118-RESEARCH.md "## Validation Architecture". This is a pure tooling/method
> phase — the planner refines the per-task map against the final PLAN.md task IDs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`@playwright/test`, JS) — both pre-existing |
| **Config file** | `mailglass_admin/e2e/playwright.config.*` / `reference/demo_app/assets/playwright.config.cjs`; ExUnit needs no config |
| **Quick run command** | `bash mailglass_admin/scripts/check-conformance.sh` (~26 gates, fast grep floor) |
| **Full suite command** | conformance + `mix test` (ratchet/axe/bucket-A/persona-drift ExUnit) + `make demo-e2e` (Playwright) |
| **Estimated runtime** | conformance ~seconds; ExUnit baselines ~1–2 min; Playwright e2e ~several min (Docker boot) |

---

## Sampling Rate

- **After every task commit:** Run the task-local command (conformance script for gate edits; the single new spec for the storybook/nav-gate tasks).
- **After every plan wave:** Run the full inherited-floor verify-green set (D-14 inventory).
- **Before `/gsd-verify-work`:** Full floor green; new judgment gates present as `test.fixme` (skipped, neither red nor green); DEFECT-REGISTER.md exists and is non-empty.
- **Max feedback latency:** < 120 seconds for the gate/ExUnit lanes (Playwright e2e is the slow outer loop).

---

## Per-Task Verification Map

> Refined by the planner against final PLAN.md task IDs. Skeleton mapped to the five deliverables (A–E from research).

| Deliverable | Requirement | Test Type | Automated Command | Status |
|-------------|-------------|-----------|-------------------|--------|
| A. `.gitignore` for screenshot cache (Wave-0 prereq) | METHOD-01 | infra | `git check-ignore .planning/research/v1.14/.cache/screenshots/x.png` exits 0 | ⬜ pending |
| B. phoenix_storybook `only: :dev` wiring + sandbox `css_path` | STORY-01 | behavior | `/dev/storybook` renders; `mix verify.preview` git-diff on `priv/static/` exits 0 (bundle unchanged) | ⬜ pending |
| C. Persona-critic screenshot seam → DEFECT-REGISTER.md | METHOD-01 | artifact | `DEFECT-REGISTER.md` exists, severity-ranked, each finding cites surface/persona/viewport/theme/state + screenshot path | ⬜ pending |
| D. Two drafted judgment gates (nav-active-correctness, no-nav-duplication) | METHOD-02 | structural (Playwright) | new spec sibling of `mailglass_admin/e2e/structural.spec.js`; both as `test.fixme` (skipped) asserting correct end-state | ⬜ pending |
| E. Verify-green inherited floor (no re-score) | METHOD-02 | regression | conformance + ratchet_baseline_test + axe_baseline_test + bucket_a_coverage_test + persona_drift_guard_test all green | ⬜ pending |
| F. `/dev/mail/gallery` retained unchanged | STORY-02 | regression | gallery structural/drift-guard tests still green (no testid churn) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.gitignore` entry covering `.planning/research/v1.14/.cache/screenshots/` — RESEARCH flagged the cache dir is NOT actually gitignored today (`git check-ignore` returns not-ignored); without this the gsd commit seam would sweep ~100 PNGs. **Hard Wave-0 prereq before the screenshot harness runs.**

*Existing test infrastructure (ExUnit + Playwright + conformance script) otherwise covers all phase requirements — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Persona-critic *judgment* findings (redundancy / IA clarity / least-surprise / info-dump per STRESS-TEST-PROMPT) | METHOD-01 | Taste/judgment-level assessment — no automated gate can score "is this page redundant/coherent." This is the deliberate method inversion. | Critic agents walk the matrix, screenshot, and author DEFECT-REGISTER.md against the binding STRESS-TEST-PROMPT.md rubric; maintainer reviews at the phase-boundary checkpoint. |
| Storybook stories render on-brand across states/themes/viewports | STORY-01 | Visual on-brand judgment (not pixel-diff — pixel-diff is out of scope) | Load `/dev/storybook`, toggle theme/viewport, confirm components inherit the committed `app.css` sandbox bundle. |

---

## Validation Sign-Off

- [ ] All deliverables have an automated verify command or a documented manual-judgment rationale (A–F above)
- [ ] Sampling continuity: gate/ExUnit lanes run after each task; floor verify-green after the wave
- [ ] Wave 0 covers the `.gitignore` MISSING reference
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for gate/ExUnit lanes
- [ ] `nyquist_compliant: true` set in frontmatter (after planner refines the per-task map)

**Approval:** pending
