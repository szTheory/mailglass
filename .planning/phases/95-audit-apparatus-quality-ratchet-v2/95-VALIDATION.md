---
phase: 95
slug: audit-apparatus-quality-ratchet-v2
status: draft
nyquist_compliant: false
wave_0_complete: false
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

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| GAP register schema | 01 | 1 | RATCHET-02 | — / — | N/A (planning artifact) | doc-review | reviewer confirms PR cites a GAP row at sev≥3 | ❌ W0 | ⬜ pending |
| Baseline ExUnit assertion (shape/range/36-cell coverage) | 02 | 2 | RATCHET-01 | T-95 / V5 | JSON parsed + schema-asserted before use | unit | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs` | ❌ W0 | ⬜ pending |
| `compare_baselines/2` defined-but-unused (Phase 103 hook) | 02 | 2 | RATCHET-01 | — / — | N/A | unit | same (function compiles; no call site) | ❌ W0 | ⬜ pending |
| Playwright `structural.spec.js` — 6 pillar facts × 3 surfaces | 03 | 2 | RATCHET-04 | — / — | N/A | structural (browser) | `cd mailglass_admin && npm run test:operator-browser` | ❌ W0 | ⬜ pending |
| Seed run: LLM scores → `ui-baseline-scores.json` committed; PNGs gitignored | 04 | 3 | RATCHET-05 | T-95 / V5 | only JSON committed; PNGs under `/tmp` | unit + manual | `mix test ...ratchet_baseline_test.exs` (shape) + `git status tmp/ui-audit/` (gitignore) | ❌ W0 | ⬜ pending |
| Seed run: populate initial `GAP-NN` rows in register | 04 | 3 | RATCHET-02 | — / — | N/A | doc-review | reviewer confirms rows have status/run_id/first_seen_run | ❌ W0 | ⬜ pending |

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

- [ ] `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — stubs for RATCHET-01/05 (shape/range/36-cell coverage + `compare_baselines/2` hook)
- [ ] `mailglass_admin/e2e/structural.spec.js` — stubs for RATCHET-04 (6 facts × 3 live surfaces), auto-picked-up by `testDir: "./e2e"`
- [ ] `mailglass_admin/docs/ui-baseline-scores.json` — initial valid-JSON placeholder (all 36 cells present) so the ExUnit test compiles; real scores land in commit 4 (D-08)
- [ ] `.planning/RATCHET-GAP-REGISTER.md` — header + schema (v1.7 columns + `status`/`run_id`/`first_seen_run`); rows populated in commit 4

*Framework install: none — Playwright and ExUnit already configured in the admin dev harness.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM scores reflect the D-01 6-pillar rubric (subjective grading) | RATCHET-05 | Visual/judgment grading of PNGs against the rubric is inherently human/subagent | Run `scripts/ui-audit.sh`, score each cell 1–4 per pillar against `design-system.md:104-121`, write to JSON |
| GAP register rows are correctly classified (surface/component:line/pillar/sev) | RATCHET-02 | Markdown planning artifact; correctness is a review judgment | Reviewer cross-checks each GAP row against the cited evidence cell |
| Anti-churn sev≥3 citation gate honored by downstream phases | RATCHET-02 | Process/review rule, not machine-checkable in this phase | PR reviewers reject build tasks (Phases 98–103) that don't cite a sev≥3 register row |

*The structural pillar-fact contract (RATCHET-04) and the JSON shape/range (RATCHET-01) ARE automated; only the subjective grading and register-classification are manual.*

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify (ExUnit/Playwright) or a documented manual-review rule + Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (manual doc-review tasks are bracketed by automated ones)
- [ ] Wave 0 covers all MISSING references (4 new files)
- [ ] No watch-mode flags (ExUnit + Playwright run once, CI-mode)
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner once the per-task map is wired into PLAN.md `<automated>` blocks)

**Approval:** pending
