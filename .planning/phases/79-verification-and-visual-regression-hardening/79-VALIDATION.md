---
phase: 79
slug: verification-and-visual-regression-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `79-RESEARCH.md` "Validation Architecture" section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (structural e2e) + ExUnit (unit/integration) + committed shell gates |
| **Config file** | `mailglass_admin/playwright.config.cjs` (e2e); `mailglass_admin/mix.exs` `verify.preview` alias (full) |
| **Quick run command** | `cd mailglass_admin && mix test --seed 0 --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` |
| **e2e command** | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs operator.spec.js` |
| **Estimated runtime** | ~120 seconds full suite; ~30 seconds e2e |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_admin && mix test --seed 0 --warnings-as-errors`
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview` (includes bundle-clean gate)
- **Before `/gsd:verify-work`:** Full suite green + all Playwright tests passing + `bash mailglass_admin/scripts/check-conformance.sh` exits 0
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Plan | Wave | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|-------------|----------|-----------|-------------------|-------------|--------|
| conformance script | 1 | VERIF-03 | 5 conformance greps + bundle-clean gate run as committed script | shell | `bash mailglass_admin/scripts/check-conformance.sh` | ❌ W1 | ⬜ pending |
| e2e extension | 1 | VERIF-02 | Operator Overview + inbound/preview orientation structural coverage | e2e | `npx playwright test --config=playwright.config.cjs operator.spec.js` | ✅ (tests added) | ⬜ pending |
| e2e replay fix | 1 | VERIF-02 | "exact replay flow" test green (timeout + stable anchor) | e2e | `npx playwright test --config=playwright.config.cjs -g "exact replay flow"` | ✅ (fix needed) | ⬜ pending |
| audit matrix | 1 | VERIF-01 | 18-cell before/after matrix re-run vs Phase 74 baseline | manual (agent-browser) | `bash mailglass_admin/scripts/ui-audit.sh` | ✅ | ⬜ pending |
| gap closeout | 1 | VERIF-01, VERIF-04 | zero open sev-4/5 rows; GAP-22 deferral recorded | evidence artifact | review `79-GAP-CLOSEOUT.md` | ❌ W1 | ⬜ pending |
| design-system docs | 1 | VERIF-03 | screenshot→LLM-critique loop documented as repeatable ritual | prose review | review `design-system.md` audit-loop section | ✅ (expansion) | ⬜ pending |
| release prep | 2 | VERIF-04 (SC-5) | inbound exact-pin → 1.5.0; CHANGELOG readiness; matched bump | grep + commit history | `grep '== 1.5.0' mailglass_inbound/mix.exs` | ✅ (update needed) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

This is a verification/closeout phase against an already-built system — existing test infrastructure (Playwright + ExUnit + `verify.preview`) covers all phase requirements. No test-framework install required.

New verification *assets* the phase itself creates (not pre-execution stubs):
- `mailglass_admin/scripts/check-conformance.sh` — committed conformance gate (created in-phase, VERIF-03)
- `79-GAP-CLOSEOUT.md` — closeout evidence artifact (created in-phase, VERIF-01/04)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Before/after audit-matrix visual comparison | VERIF-01 | Pixel/visual judgment vs Phase 74 baseline; non-deterministic PNGs, no CI promotion by locked decision (D-01/D-07) | Run `bash mailglass_admin/scripts/ui-audit.sh` (agent-browser CLI confirmed available), then LLM-critique the 18 cells vs the 6-pillar rubric in `design-system.md`; record the textual finding citing GAP rows in `79-GAP-CLOSEOUT.md` |
| GAP-22 deep-link deferral disposition | VERIF-04 | Decision/documentation deliverable, not code (touches locked asset-serving seam) | Reconfirm Phase 75 D-17 deferral; reference `design-system.md` lines 141–159; hold GAP-22 at severity 3 in `79-GAP-CLOSEOUT.md` |
| Release ceremony acknowledgment | VERIF-04 (SC-5) | The hands-free Release Please pipeline owns the actual cut/publish; Phase 79 only prepares | Verify conventional-commit history + CHANGELOG readiness + inbound exact-pin re-point; do NOT run `mix hex.publish` or hand-merge the Release Please PR |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify command OR a documented manual-only justification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (N/A — existing infra covers all)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter (planner/executor to set once map is complete)

**Approval:** pending
