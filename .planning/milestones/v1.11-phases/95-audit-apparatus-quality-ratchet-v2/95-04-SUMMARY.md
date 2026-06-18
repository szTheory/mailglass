---
phase: 95
plan: "04"
subsystem: audit-apparatus
tags: [ratchet, scoring, gap-register, baseline, playwright, exunit]
dependency_graph:
  requires: [95-01, 95-02, 95-03]
  provides: [real-scored-baseline, gap-register-seeded, phase-95-apparatus-green]
  affects: [phases-98-103]
tech_stack:
  added: []
  patterns:
    - LLM multimodal scoring of PNG matrix against D-01 6-pillar rubric
    - GAP register stable-ID pattern with anti-churn citation gate
key_files:
  created: []
  modified:
    - mailglass_admin/docs/ui-baseline-scores.json
    - .planning/RATCHET-GAP-REGISTER.md
    - .planning/phases/95-audit-apparatus-quality-ratchet-v2/95-VALIDATION.md
decisions:
  - Radius/Color/Elevation all score 4 across all surfaces — token discipline from Phase 94 is holding
  - Spacing/Type score 3 across all surfaces — btn-sm and label token gaps exist but are measured, not blocking
  - Preview Motion+A11y scored 2 — dark-mode absence (theme param ignored) is the most significant gap in this baseline
  - workers=1 required for operator-browser to avoid pre-existing DB-constraint race (documented, not a test defect)
metrics:
  duration: ~10 minutes
  completed: "2026-06-14T04:55:00Z"
  tasks_completed: 3
  tasks_total: 4
  files_changed: 3
---

# Phase 95 Plan 04: Seed Run — Summary

LLM-scored 36-cell baseline committed to ui-baseline-scores.json (run_id 2026-06-13-phase-95-baseline), 5 initial GAP rows seeded in RATCHET-GAP-REGISTER.md, and both required CI lanes verified green (mix verify.support_contract.admin: 46/46 + npm run test:operator-browser --workers=1: 28/28).

---

## Task Execution

### Task 1 (completed by orchestrator, pre-existing commit ff2080f5)

Task 1 was completed before this executor was spawned. The orchestrator:
- Confirmed the reference demo Docker container (mailglass-demo-demo-1) was running on port 4015
- Fixed a bug in mailglass_admin/scripts/ui-audit.sh (agent-browser CLI syntax change for >= 0.27) committed as ff2080f5
- Ran ui-audit.sh successfully — all 18 PNGs captured at tmp/ui-audit/ (gitignored)
- Verified authenticated surfaces (Deliveries + Inbound) rendered real seed-tenant content with masked recipients

### Task 2: LLM-score 18 cells → write ui-baseline-scores.json (commit 55a831fa)

Scored all 6 surface×theme pairs (deliveries-light, deliveries-dark, inbound-light, inbound-dark, preview-light, preview-dark) against the D-01 6 pillars by reading all 18 PNGs via multimodal inspection.

**Score results (36 cells):**

| Surface | Spacing | Radius | Color | Type | Elevation | Motion+A11y |
|---------|---------|--------|-------|------|-----------|-------------|
| deliveries (light) | 3 | 4 | 4 | 3 | 4 | 3 |
| deliveries (dark) | 3 | 4 | 4 | 3 | 4 | 3 |
| inbound (light) | 3 | 4 | 4 | 3 | 4 | 3 |
| inbound (dark) | 3 | 4 | 4 | 3 | 4 | 3 |
| preview (light) | 3 | 4 | 4 | 3 | 4 | 2 |
| preview (dark) | 3 | 4 | 4 | 3 | 4 | 2 |

**Score rationale for < 4 cells:**
- **Spacing=3 (all)**: Consistent 4px grid with one gap — support_cards.ex CTA buttons use `btn-sm` without `min-h-11` guard, falling below 44px touch target threshold
- **Type=3 (all)**: Field labels in inbound filter form use uppercase raw CSS rather than the `text-label` token; deliveries health counts use raw numeric display size rather than type-scale token
- **Motion+A11y=3 (deliveries/inbound)**: btn-sm touch target issue tracked in GAP-01; structural spec's gap-posture recording of keyboard focusability edge cases
- **Motion+A11y=2 (preview)**: Two compounding gaps — (a) preview surface ignores the dark theme param entirely (preview-*-dark PNGs are visually identical to light; the "Light & dark" feature card in the preview orientation itself advertises this capability but it does not work in the operator chrome), and (b) preview-orientation empty-state keyboard focusability is borderline (GAP-02)

ExUnit: `mix test test/mailglass_admin/ratchet_baseline_test.exs` → 3 tests, 0 failures. All 36 scores valid integer in 1..4.

### Task 3: Populate initial GAP rows in RATCHET-GAP-REGISTER.md (commit 8c7d45b2)

Seeded 5 GAP rows from the Phase 95 seed run findings plus the mandated gallery-absence row:

| GAP | Surface | Pillar | Sev | Issue |
|-----|---------|--------|-----|-------|
| GAP-01 | deliveries | Spacing | 3 | support_cards.ex CTA buttons: btn-sm without min-h-11 (~21px, below 44px threshold) |
| GAP-02 | preview | Motion+A11y | 3 | Preview orientation empty-state keyboard focusability — structural spec confirmed border case |
| GAP-03 | preview | Motion+A11y | 3 | Preview dark mode absent — theme param ignored; preview chrome does not respond to dark toggle |
| GAP-04 | inbound | Type | 2 | Filter section labels (TENANT, PROVIDER, etc.) rendered as uppercase raw CSS vs text-label token |
| GAP-05 | all | Motion+A11y | 2 | Gallery surface /dev/mail/gallery does not exist (Phase 97 deliverable) |

Anti-churn gate satisfied: 3 rows with sev=3 (GAP-01, GAP-02, GAP-03). Gallery row present.

### Task 4: Verify both CI lanes green + update VALIDATION.md (commit 7fa96d38)

**mix verify.support_contract.admin**: 46 tests, 0 failures (includes ratchet_baseline_test.exs on real scores).

**npm run test:operator-browser**: Default 2-worker run flaked on the pre-existing DB-constraint race (Ecto.ConstraintError on `mailglass_deliveries_provider_msg_id_idx` in browser-reset). Re-ran with `--workers=1` → 28 passed, 1 skipped (gallery deferred), 0 failures. Documented in VALIDATION.md per plan instructions.

**git status tmp/ui-audit/**: empty — no PNGs committed.

Updated 95-VALIDATION.md:
- `wave_0_complete: true` (frontmatter)
- All 8 per-task status rows updated from pending to green

---

## Deviations from Plan

None — plan executed as written.

**Task 1 was pre-completed by the orchestrator.** This executor handled Tasks 2, 3, and 4 as specified. The orchestrator's ui-audit.sh bug fix (ff2080f5) is documented here for completeness:
- [Rule 3 - Blocking] Fixed agent-browser CLI syntax change in ui-audit.sh (orchestrator action, pre-existing commit ff2080f5)

**Default-worker Playwright flake is documented (not a deviation):** The plan explicitly notes the 2-worker DB-race pre-existing issue and permits `--workers=1` with documentation. The 28-passed green result was observed and reported honestly.

---

## Known Stubs

None. All 36 scores are real LLM-assessed integers. The GAP register rows reflect actual findings from visual inspection and structural spec evidence.

---

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced by this plan. The only committed artifact is a 36-integer JSON file (ui-baseline-scores.json). PNGs are gitignored.

---

## Self-Check: PASSED

- mailglass_admin/docs/ui-baseline-scores.json — FOUND
- .planning/RATCHET-GAP-REGISTER.md — FOUND, contains GAP-01..GAP-05
- .planning/phases/95-audit-apparatus-quality-ratchet-v2/95-VALIDATION.md — FOUND, wave_0_complete: true
- Commits: 55a831fa, 8c7d45b2, 7fa96d38 — all present in git log
- tmp/ui-audit/ — gitignored, no PNG committed
- ratchet_baseline_test.exs — 3 tests, 0 failures on real scores
- structural.spec.js — 28 passed, 0 failures (--workers=1)
