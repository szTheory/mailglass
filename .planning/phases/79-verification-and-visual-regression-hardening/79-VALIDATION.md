---
phase: 79
slug: verification-and-visual-regression-hardening
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
validated: 2026-06-04
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
| conformance script | 1 | VERIF-03 | 5 conformance greps + bundle-clean gate run as committed script | shell | `bash mailglass_admin/scripts/check-conformance.sh` | ✅ | ✅ green |
| e2e extension | 1 | VERIF-02 | Operator Overview + inbound/preview orientation structural coverage | e2e | `npx playwright test --config=playwright.config.cjs operator.spec.js` | ✅ | ✅ green |
| e2e replay fix | 1 | VERIF-02 | "exact replay flow" test green (timeout + stable anchor) | e2e | `npx playwright test --config=playwright.config.cjs -g "exact replay flow"` | ✅ | ✅ green |
| audit matrix | 1 | VERIF-01 | 18-cell before/after matrix re-run vs Phase 74 baseline | manual (agent-browser) | `bash mailglass_admin/scripts/ui-audit.sh` | ✅ | 🖐 manual-only |
| gap closeout | 1 | VERIF-01, VERIF-04 | zero open sev-4/5 rows; GAP-22 deferral recorded | evidence artifact | review `79-GAP-CLOSEOUT.md` | ✅ | ✅ green |
| design-system docs | 1 | VERIF-03 | screenshot→LLM-critique loop documented as repeatable ritual | prose review | review `design-system.md` audit-loop section | ✅ | ✅ green |
| release prep | 2 | VERIF-04 (SC-5) | inbound exact-pin → 1.5.0; CHANGELOG readiness; matched bump | grep + commit history | `grep '== 1.5.0' mailglass_inbound/mix.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · 🖐 manual-only*

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

- [x] All tasks have an automated verify command OR a documented manual-only justification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (N/A — existing infra covers all)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-04 — all automated gates re-run green during retroactive Nyquist audit.

---

## Validation Audit 2026-06-04

Retroactive Nyquist audit (`/gsd-validate-phase 79`). State A — audited existing VALIDATION.md against live artifacts; re-ran every automated gate.

| Metric | Count |
|--------|-------|
| Requirements (VERIF-01..04) | 4 |
| Tasks classified | 7 |
| COVERED (automated, green) | 6 |
| Manual-only (justified) | 1 (audit-matrix visual, VERIF-01) |
| Gaps found | 0 |
| Resolved | 0 (none needed) |
| Escalated | 0 |

**Re-run evidence (all live, this audit):**

| Gate | Command | Result |
|------|---------|--------|
| VERIF-03 conformance | `bash mailglass_admin/scripts/check-conformance.sh` | exit 0 — "OK: design-system conformance clean." |
| VERIF-03 bundle-clean | `git diff --exit-code mailglass_admin/priv/static/` | exit 0 |
| VERIF-03 docs | `grep -c "Phase 74 baseline" mailglass_admin/docs/design-system.md` | 2 |
| VERIF-02 e2e | `npx playwright test --config=playwright.config.cjs operator.spec.js` | 10 passed (incl. exact replay flow + 2 new structural tests) |
| VERIF-02 testids | `grep -cE "operator-overview-health|operator-overview-nav|inbound-orientation|preview-orientation"` | 5 references / 4 testids present |
| VERIF-01 closeout | `grep -c "CLOSED" 79-GAP-CLOSEOUT.md` | 9 (≥5; zero open sev-4/5) |
| VERIF-04 inbound pin | `grep '== 1.5.0' mailglass_inbound/mix.exs` | `{:mailglass, "== 1.5.0"}` |
| Unit/integration | `cd mailglass_admin && mix test --seed 0 --warnings-as-errors` | 189 tests, 0 failures (2 excluded) |

No new test files generated — phase is fully covered by existing committed infrastructure. The single manual-only item (before/after visual audit-matrix) carries a documented justification (non-deterministic PNGs, no CI promotion per D-01/D-07) and is not a coverage gap.
