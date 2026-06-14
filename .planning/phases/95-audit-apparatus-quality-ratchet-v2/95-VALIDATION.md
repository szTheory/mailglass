---
phase: 95
slug: audit-apparatus-quality-ratchet-v2
status: planning-complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `95-RESEARCH.md` "Validation Architecture". First-run = establish-and-freeze;
> the meet-or-beat regression teeth turn on at Phase 103 (`compare_baselines/2` defined here, unused).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) + Playwright 1.x (existing dev harness) |
| **Config file** | `mailglass_admin/test/test_helper.exs` · `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin && npm run test:operator-browser` |
| **Estimated runtime** | ~5s (ExUnit shape test) · ~60–120s (Playwright browser lane) |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs`
- **After every plan wave:** Run `cd mailglass_admin && mix verify.support_contract.admin && npm run test:operator-browser`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~120 seconds (Playwright lane is the long pole)

---

## Per-Task Verification Map (wired to PLAN.md `<automated>` blocks)

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| GAP register schema (Task 1) | 95-01 | 1 | RATCHET-02 | — / — | N/A (planning artifact) | doc-review | `grep -c "stable_ids: true" .planning/RATCHET-GAP-REGISTER.md && grep -c "first_seen_run" .planning/RATCHET-GAP-REGISTER.md` | ✅ | ✅ green |
| Baseline ExUnit assertion + placeholder JSON (Task 1) | 95-02 | 2 | RATCHET-01 | T-95-V5 / V5 | JSON parsed + schema-asserted before use | unit | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` | ✅ | ✅ green |
| `compare_baselines/2` defined-but-unused Phase 103 hook (Task 1) | 95-02 | 2 | RATCHET-01 | — / — | N/A | unit | same (function compiles; no call site) | ✅ | ✅ green |
| Wire verify.support_contract.admin alias (Task 2) | 95-02 | 2 | RATCHET-01 | — / — | N/A | unit | `cd mailglass_admin && mix verify.support_contract.admin` | ✅ | ✅ green |
| Playwright `structural.spec.js` — 6 pillar facts × 3 surfaces (Task 1) | 95-03 | 3 | RATCHET-04 | T-95-PW1 / — | test fixture non-PII browser-tenant@example.com | structural (browser) | `cd mailglass_admin && npm run test:operator-browser -- --grep "structural assertions"` | ✅ | ✅ green |
| Seed run: LLM scores → `ui-baseline-scores.json` committed; PNGs gitignored (Task 2) | 95-04 | 4 | RATCHET-05 | T-95-V5 / V5 | only JSON committed; PNGs under `/tmp` gitignored | unit + manual | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` + `git status tmp/ui-audit/` (empty = gitignored) | ✅ | ✅ green |
| Seed run: populate initial `GAP-NN` rows in register (Task 3) | 95-04 | 4 | RATCHET-02 | — / — | N/A | doc-review | `grep -c "GAP-0" .planning/RATCHET-GAP-REGISTER.md && grep -c "2026-06-13-phase-95-baseline" .planning/RATCHET-GAP-REGISTER.md` | ✅ | ✅ green |
| Phase gate — both required CI lanes green (Task 4) | 95-04 | 4 | RATCHET-01, RATCHET-04, RATCHET-05 | T-95-V5 / V5 | both lanes green confirms all apparatus layers | full suite | `cd mailglass_admin && mix verify.support_contract.admin && npm run test:operator-browser && git status tmp/ui-audit/ && echo "PHASE_95_APPARATUS_GREEN"` | ✅ | ✅ green (--workers=1) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**First-run vs. regression distinction (carried from RESEARCH):**

| Validation Layer | Phase 95 (establish) | Phase 103 (regression) |
|-----------------|----------------------|------------------------|
| ExUnit shape assertion | ACTIVE — all 36 `surface×pillar×theme` cells present, scores in 1–4 | ACTIVE — unchanged |
| ExUnit meet-or-beat | INACTIVE — `compare_baselines/2` defined, not called | ACTIVE — Phase 103 adds the call site only |
| Playwright structural spec | ACTIVE — pillar-fact contract pass/fail on current surfaces | ACTIVE — regression on any fact fails CI |
| GAP register citation | ACTIVE — documented review rule for downstream phases | ACTIVE — same rule |

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — created by 95-02 (RATCHET-01/05: shape/range/36-cell coverage + `compare_baselines/2` hook)
- [ ] `mailglass_admin/docs/ui-baseline-scores.json` — placeholder created by 95-02 (all 36 cells, scores=1); real scores land in 95-04
- [ ] `mailglass_admin/e2e/structural.spec.js` — created by 95-03 (RATCHET-04: 6 facts × 3 live surfaces), auto-picked-up by `testDir: "./e2e"`
- [ ] `.planning/RATCHET-GAP-REGISTER.md` — header + schema created by 95-01; rows populated by 95-04

*Framework install: none — Playwright and ExUnit already configured in the admin dev harness.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PNG capture via ui-audit.sh (Task 1, Plan 95-04) | RATCHET-05 | Requires human to boot demo server and run agent-browser CLI locally | Boot reference/demo_app, run `bash mailglass_admin/scripts/ui-audit.sh`, confirm 18 PNGs in tmp/ui-audit/ |
| LLM scores reflect the D-01 6-pillar rubric (Task 2, Plan 95-04) | RATCHET-05 | Visual/judgment grading of PNGs against the rubric is inherently human/subagent | Score each surface×theme pair 1–4 per pillar against `design-system.md:104-121`; write to JSON |
| GAP register rows correctly classified (Task 3, Plan 95-04) | RATCHET-02 | Markdown planning artifact; correctness is a review judgment | Reviewer cross-checks each GAP row against the cited evidence cell |
| Anti-churn sev≥3 citation gate honored by downstream phases | RATCHET-02 | Process/review rule, not machine-checkable in this phase | PR reviewers reject build tasks (Phases 98–103) that don't cite a sev≥3 register row |

*The structural pillar-fact contract (RATCHET-04) and the JSON shape/range (RATCHET-01) ARE automated; only the PNG capture, subjective grading, and register-classification are manual.*

---

## Validation Sign-Off

- [x] All tasks have an `<automated>` verify (ExUnit/Playwright) or a documented manual-review rule + Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (manual tasks in 95-01 and 95-04 Task 3 are bracketed by automated ones)
- [x] Wave 0 covers all MISSING references (4 new files across plans 95-01, 95-02, 95-03)
- [x] No watch-mode flags (ExUnit + Playwright run once, CI-mode)
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter (per-task map wired into PLAN.md `<automated>` blocks)

**Approval:** planning-complete (set by planner 2026-06-13)
