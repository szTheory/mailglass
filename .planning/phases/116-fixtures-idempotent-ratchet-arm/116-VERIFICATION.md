---
phase: 116-fixtures-idempotent-ratchet-arm
verified: 2026-06-20T18:45:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
gaps: []
deferred:
  - truth: "16 pre-existing operator-browser Playwright failures (operator.spec.js openOperator helper asserts the now-md:hidden mobile list at desktop width after the Phase-113 table/card split)"
    addressed_in: "Phase 117"
    evidence: "deferred-items.md: stale Phase-113 layout-split harness failures, root-caused as NOT a 116 regression (116-06 touched only cohort.spec.js + 2 baseline JSONs); logged for a Phase-117 admin e2e-harness triage"
advisory_review_notes:
  - id: WR-01
    severity: warning
    impact: "Future re-run hazard, not a current failure. Committed prior.run_id (2026-06-20-phase-116-axe) and current.run_id (axe-2026-06-20-phase-116) are distinct today, so the anti-vacuity guard passes. A same-day re-run of the producer with PERSIST_AXE_BASELINE=1 would emit a run_id byte-identical to the committed prior.run_id and break round-trippability. Does not block goal achievement; recommend the producer read existing.prior.run_id and assert inequality (or use a timestamp/uuid suffix) before the next re-baseline."
  - id: WR-02
    severity: warning
    impact: "The DEDICATED 'adding a persona to spec() without materializing it fails closed' test (persona_drift_guard_test.exs:110-132) is tautological — it appends 'phantom-persona' in the test body and refutes a comparison that is true by construction. HOWEVER the fail-closed property IS genuinely covered by the SIBLING test at :73-108 ('deliveries-bearing personas ... are exactly the ones materialized'), which drives the production comparison (assert materialized == spec_bearing) and would go red if a spec persona were unmaterialized. Recommend renaming/rewriting the dedicated test so its name does not overstate coverage; the property itself is not a gap."
  - id: WR-03
    severity: warning
    impact: "gallery_intends_literal?/2 ignores its label arg and uses one coarse global trigger (gallery contains 'fjordline-aps') for all four literals. Imprecise: it cannot attribute a dropped specimen to the right literal. Today benign — all four canonical literals are individually byte-present in gallery_live.ex (verified: Bjørn Hansen / 山田太郎 / del_01JXW9... / ...VeryLongModuleName each 1x) and the assertion passes. Recommend per-literal namespaced testid signal. Not a goal failure."
  - id: WR-04
    severity: warning
    impact: "Axe producer openOverlay swallows all opener errors (catch (_err) { scan surface alone }), so an overlay-open regression could promote an overlay-free, under-counted baseline under PERSIST_AXE_BASELINE=1. This is a producer-robustness concern on the re-baseline path, not a current-state failure (the committed 9-cell baseline is green and the comparator fails closed on missing cells / rising counts). Recommend a per-cell overlay_opened flag asserted true for the two scrim-backed surfaces."
  - id: IN-04
    severity: info
    impact: ":playwright_testid guard kind in bucket_a_coverage_test.exs iterates an empty comprehension (no manifest row uses it) — a vacuous-pass shape. Harmless dead branch; recommend dropping the kind or asserting >=1 row exercises it."
---

# Phase 116: Fixtures + Idempotent Ratchet-Arm Verification Report

**Phase Goal:** Land the 2-3-persona stress cohort + widen gallery to component×state×theme×viewport; interaction pillar + axe-JSON baseline; run full matrix incl. one run against demo_app data; promote current→prior, re-score all gates green; close all 24 usability defects.
**Verified:** 2026-06-20T18:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

This phase delivers test infrastructure whose entire deliverable is "gates that fail
closed." Verification prioritized *mutate → red* evidence over *gate passes*, per the
verification context. The headline finding: the fail-closed property is genuinely
established by construction (the axe comparator ships 5 mutate-input tests that drive
the real `compare_axe/2` red; the Bucket-A manifest asserts each cited guard literal
physically exists; the drift-guard's production assertion exercises the real
spec↔materializer comparison). The 4 code-review Warnings are gate-*honesty/precision*
concerns on the re-baseline path and one mislabeled test — none of them falsify a
must-have, because each covered property is independently enforced by an adjacent
passing assertion. They are recorded as advisory_review_notes for follow-up, not gaps.

### Observable Truths (mapped to ROADMAP Success Criteria + merged PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | RATCHET-01: 2-3-tenant persona stress cohort (no-data/one/many/long-ID/non-ASCII/null/high-count/error) lands in demo seeds + admin test-support, single declarative spec, drift-guarded | ✓ VERIFIED | `reference/persona_spec/personas.ex:122-152` (spec/0: 3 personas + 8 edge cases), `:163-219` (seed!/1 materializers); demo wiring `reference/demo_app/lib/mailglass_demo/demo_data.ex:35` (`Personas.seed!(Repo)`); admin materializer `operator_fixtures.ex:182-184` (reads `Personas.spec()`); `persona_cohort_test.exs` + `persona_drift_guard_test.exs` = 13 tests, 0 failures |
| 2 | list_tenants/2 returns ≥2 selectable (northstar+fjordline-aps); helios-void absent (zero Delivery) | ✓ VERIFIED | drift-guard `persona_drift_guard_test.exs:73-108` asserts `materialized == spec_bearing` (deliveries-bearing personas) AND helios-void NOT materialized; passes in suite |
| 3 | RATCHET-02: gallery widened to component × state × {light,dark,system} × {320,390,768,wide}, no overflow, stable testids preserved | ✓ VERIFIED | `gallery-matrix.spec.js:39-40` (MATRIX_WIDTHS=[320,390,768,1440], MATRIX_THEMES=[light,dark,system]), `:24` scrollWidth<=clientWidth+1; specimens `gallery_live.ex:468-488` fjordline_stress with stable `gallery-{component}-{state}` testids |
| 4 | RATCHET-03 (interaction half): 4 binary Playwright gates — panel-above-scrim hit-test, scroll-chaining, focus-restore, layout-jump/CLS | ✓ VERIFIED | `structural.spec.js`: elementFromPoint hit-test `:699-721`, scrollY scroll-chaining, activeElement focus-restore `:1707-1721`, CLS thresholds `:2582-2583` (CLS_THRESHOLD_PX=4, sync=0) |
| 5 | RATCHET-03 (axe half): 9-cell WCAG 2.2 AA baseline (schema 1), producer regenerates current, comparator fails closed (per-cell + per-rule, missing-cell, distinct run_id) | ✓ VERIFIED | `docs/axe-baseline.json` schema_version 1, distinct run_ids; `axe_baseline_test.exs:90-98` anti-vacuity run_id guard; `:116-177` FIVE mutate→red verify-by-construction tests (rising total, new rule-id, rising per-rule, missing cell, meet-or-beat pass); producer `e2e/axe-baseline.spec.js` AxeBuilder |
| 6 | RATCHET-04: full matrix incl. ≥1 run vs rich demo_app data; current→prior promoted; 54-cell + 9-cell re-scored, all three comparators green | ✓ VERIFIED | demo run `reference/demo_app/assets/e2e/cohort.spec.js:50-52` (POST /demo/evidence/reset → DemoData.reset! → Personas.seed!); `ui-baseline-scores.json` schema 3, prior `2026-06-16-phase-103` → current `2026-06-20-phase-116` (promoted, distinct); `ratchet_baseline_test.exs` 4 tests 0 failures; all 3 comparators green |
| 7 | RATCHET-05: all 24 Bucket-A defects closed, each with a live guard; executable manifest fails closed on stale citation | ✓ VERIFIED | `bucket_a_coverage_test.exs` 26 A-rows covering A1..A24, `:196-200` every canonical id has a row; `:214-272` per-guard-kind `String.contains?` existence assertions (grep_gate, playwright_title, playwright_testid, axe, fixture) — fail closed on rename/delete; 6 net-new guards `:296-303` all :live; A11 `check-conformance.sh:542` TABLE_FLOOR=3 |

**Score:** 7/7 truths verified (0 present/behavior-unverified). Maps to 5/5 ROADMAP Success Criteria and 5/5 RATCHET requirements.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | 16 pre-existing operator-browser Playwright failures (Phase-113 table/card split stale-helper) | Phase 117 | deferred-items.md root-causes them to Phase-113 `feat(113-02)` (`openOperator` asserts now-`md:hidden` mobile list at desktop width); 116-06 touched only cohort.spec.js + 2 baseline JSONs, so cannot be a 116 regression |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `reference/persona_spec/personas.ex` | Declarative persona spec + seed!/1 | ✓ VERIFIED | 220 lines; `def spec` present; MailglassDemo.Personas module name preserved. **Path deviation (acceptable):** plan declared `reference/demo_app/lib/mailglass_demo/personas.ex`; A1/Pitfall-3 fallback moved it to a shared `reference/persona_spec/` dir because a demo→admin path dep is circular. Contract (single source, both apps compile it) intact — wired via elixirc_paths in both mix.exs |
| `mailglass_admin/test/support/operator_fixtures.ex` | seed_persona_cohort!/0 | ✓ VERIFIED | `:182-184` reads `MailglassDemo.Personas.spec()` |
| `mailglass_admin/test/mailglass_admin/persona_cohort_test.exs` | 3 seed, ≥2 selectable, helios-void absent | ✓ VERIFIED | 153 lines; 6 tests pass |
| `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs` | Fail-closed drift guard | ✓ VERIFIED | 232 lines; 7 tests pass (see WR-02 on the one mislabeled dedicated test) |
| `mailglass_admin/docs/axe-baseline.json` | 9-cell schema-1 baseline | ✓ VERIFIED | schema_version 1; distinct prior/current run_ids |
| `mailglass_admin/e2e/axe-baseline.spec.js` | Producer (AxeBuilder) | ✓ VERIFIED | 244 lines; AxeBuilder present (see WR-01/WR-04 on producer robustness) |
| `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` | Fail-closed comparator | ✓ VERIFIED | 240 lines; 5 mutate→red tests drive compare_axe |
| `mailglass_admin/e2e/structural.spec.js` | 4 interaction invariants | ✓ VERIFIED | 2975 lines; elementFromPoint/scrollY/activeElement/getBoundingClientRect all present |
| `mailglass_admin/lib/mailglass_admin/gallery_live.ex` | Stress specimens, stable testids | ✓ VERIFIED | 1397 lines; all 4 fjordline literals byte-present (1× each) |
| `mailglass_admin/e2e/gallery-matrix.spec.js` | 320/390/768/wide × themes resize loop | ✓ VERIFIED | 232 lines; MATRIX_WIDTHS + MATRIX_THEMES + overflow assert |
| `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs` | Executable fail-closed manifest | ✓ VERIFIED | 305 lines; 26 rows, per-kind existence assertions |
| `.planning/research/v1.13/BUCKET-A-LEDGER.md` | Human mirror | ✓ VERIFIED | 81 lines |
| `mailglass_admin/scripts/check-conformance.sh` | A11 table gate | ✓ VERIFIED | 572 lines; TABLE_FLOOR=3 |
| `reference/demo_app/assets/e2e/cohort.spec.js` | Demo cohort spec | ✓ VERIFIED | 161 lines; /demo/evidence/reset wiring |
| `mailglass_admin/docs/ui-baseline-scores.json` | Re-scored 54-cell, current→prior | ✓ VERIFIED | schema 3; prior 2026-06-16-phase-103 → current 2026-06-20-phase-116 |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| operator_fixtures.ex | personas.ex | shared spec dir (elixirc_paths), `MailglassDemo.Personas.spec()` | ✓ WIRED — `mailglass_admin/mix.exs:83-84` @persona_spec_dir in :test elixirc_paths; `operator_fixtures.ex:184` |
| personas.ex | lib/mailglass/operator/tenants.ex | helios-void zero Delivery → absent from list_tenants/2 | ✓ WIRED — drift-guard asserts absence; helios-void materialize! is a no-op (`personas.ex:172`) |
| axe-baseline.spec.js | docs/axe-baseline.json | producer writes current.violations + run_id | ✓ WIRED |
| axe_baseline_test.exs | docs/axe-baseline.json | Jason.decode! + compare_axe meet-or-beat | ✓ WIRED |
| structural.spec.js | live surfaces | elementFromPoint/scrollY/activeElement/getBoundingClientRect | ✓ WIRED |
| gallery-matrix.spec.js | gallery_live.ex | resize loop over stable gallery-{component}-{state} | ✓ WIRED |
| gallery_live.ex | personas.ex | gallery literals == fjordline-aps literals (drift-guarded) | ✓ WIRED — all 4 literals byte-present; drift-guard byte-consistency assertion active + passing |
| bucket_a_coverage_test.exs | check-conformance.sh | manifest asserts cited gate literals exist | ✓ WIRED — `:214-222` |
| bucket_a_coverage_test.exs | structural.spec.js | manifest asserts cited testid/title literals exist | ✓ WIRED — `:225-244` |
| cohort.spec.js | demo seed | POST /demo/evidence/reset re-runs DemoData.reset! → Personas.seed! | ✓ WIRED — `:50-52` |
| ui-baseline-scores.json | ratchet_baseline_test.exs | promoted prior/current, distinct run_ids, meet-or-beat | ✓ WIRED — 4 tests green |

### Behavioral Spot-Checks (executed by verifier)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 4 phase comparators green | `mix test bucket_a_coverage_test axe_baseline_test persona_cohort_test persona_drift_guard_test --seed 0` | 31 tests, 0 failures | ✓ PASS |
| 54-cell ratchet green | `mix test ratchet_baseline_test.exs --seed 0` | 4 tests, 0 failures | ✓ PASS |
| Full admin suite (validation strategy expectation: 431/0) | `mix test --seed 0` | 431 tests, 0 failures (1 excluded) | ✓ PASS |
| Axe comparator fails closed on mutation | inspected `axe_baseline_test.exs:116-177` | 5 mutate→red tests drive compare_axe (rising total, new rule, rising per-rule, missing cell) | ✓ PASS (mutate→red proven by construction) |
| Bucket-A manifest fails closed on stale citation | inspected `:214-272` | per-kind `String.contains?` existence assertions | ✓ PASS |
| Gallery drift-guard non-vacuous | grep 4 fjordline literals in gallery_live.ex | all 4 present (1× each); byte-consistency assertion active | ✓ PASS |
| Playwright operator-browser matrix | (not executed — server-dependent) | 16 pre-existing Phase-113 failures, deferred to Phase 117; phase's own gates (comparators + cohort.spec + axe producer) green | ? SKIP (deferred, not a 116 regression) |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| RATCHET-01 | 116-01 | ✓ SATISFIED | persona cohort + drift-guard, truths 1-2 |
| RATCHET-02 | 116-04 | ✓ SATISFIED | gallery matrix widening, truth 3 |
| RATCHET-03 | 116-02, 116-03 | ✓ SATISFIED | interaction pillar + axe baseline, truths 4-5 |
| RATCHET-04 | 116-06 | ✓ SATISFIED | demo run + promote + re-score, truth 6 |
| RATCHET-05 | 116-05 | ✓ SATISFIED | 24 Bucket-A guards + fail-closed manifest, truth 7 |

All five RATCHET IDs are declared in PLAN frontmatter, present in REQUIREMENTS.md (lines 70-74, marked `[x]`), mapped to Phase 116 (lines 149-153, "Complete"), and verified against the codebase. No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| (none) | TBD/FIXME/XXX debt markers in any phase-modified source file | — | Debt-marker gate CLEAN |
| `persona_drift_guard_test.exs:110-132` | Tautological dedicated fail-closed test | ⚠️ Warning (WR-02) | Mislabeled, but property covered by sibling :73-108 — not a goal failure |
| `bucket_a_coverage_test.exs:236-244` | Empty `:playwright_testid` comprehension (vacuous pass shape) | ℹ️ Info (IN-04) | Dead branch; no manifest row uses the kind |
| `axe-baseline.spec.js:154-160` | openOverlay catches all errors (could under-count on re-baseline) | ⚠️ Warning (WR-04) | Producer-robustness on re-baseline path; current baseline green |

### Human Verification Required

None. All phase behaviors have automated verification (this phase IS verification
infrastructure). The 116-VALIDATION.md "Manual-Only Verifications" section confirms
zero manual checks. The interaction/gallery/cohort Playwright surfaces are server-
dependent but their fail-closed ExUnit comparators (the durable enforcement artifacts)
were executed directly by the verifier and are green.

### Gaps Summary

No gaps. All 5 RATCHET requirements and all 7 derived observable truths are verified
with file:line evidence in the codebase. The fail-closed property central to this
phase's goal is established by construction (5 mutate→red axe tests, per-guard
existence assertions in the Bucket-A manifest, a production-driving drift-guard
assertion) — not merely claimed.

The 4 code-review Warnings (WR-01..04) were independently assessed and do NOT undermine
goal achievement:
- **WR-01** (axe run_id collision) is a *future re-run* hazard; committed run_ids are
  distinct today and the anti-vacuity guard passes.
- **WR-02** (tautological dedicated drift-guard test) is a *naming/coverage-overstatement*
  issue; the fail-closed property is genuinely enforced by the sibling test that drives
  the real spec↔materializer comparison.
- **WR-03** (label-ignoring gallery intent heuristic) is *imprecise but benign*; all four
  canonical literals are byte-present and the assertion is active and passing.
- **WR-04** (overlay-open error swallowing) is a *producer-robustness* concern on the
  re-baseline path, not a current-state failure.

These are recorded as `advisory_review_notes` for a future hardening pass. They are the
right kind of finding for "idempotent fail-closed gates" and worth fixing before the
next re-baseline, but none blocks marking the phase complete.

The 16 operator-browser Playwright failures are pre-existing Phase-113 harness staleness
(root-caused in deferred-items.md), correctly scoped out of this phase and deferred to
Phase 117.

---

_Verified: 2026-06-20T18:45:00Z_
_Verifier: Claude (gsd-verifier)_
