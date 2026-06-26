---
phase: 118-method-audit-storybook-stand-up
plan: 02
subsystem: testing
tags: [playwright, judgment-gates, ratchet-floor, ia, aria-current, conformance, axe]

# Dependency graph
requires:
  - phase: 116-bucket-a-ratchet-arm
    provides: v1.13 ratchet floor (54-cell aesthetic + 9-cell axe + 24-item Bucket-A + persona drift-guard)
  - phase: 118-01
    provides: persona-critic harness + storybook stand-up (sibling plan in this phase)
provides:
  - "mailglass_admin/e2e/judgment.spec.js — two drafted (test.fixme) rendered-DOM judgment gates: nav-active-correctness + no-nav-duplication, asserting the correct IA end-state"
  - "Verify-green evidence that the five inherited v1.13 floor artifacts are green on clean main (no re-score, no arming)"
  - "Confirmation that /dev/mail/gallery (gallery_live.ex) is retained byte-unchanged this phase"
affects: [119-shell-nav-overview-redesign, 123-cross-surface-coherence-ratchet-rearm]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Drafted judgment gate: a rendered-DOM Playwright assertion expressed as test.fixme that asserts the CORRECT end-state, flips green when the bug is fixed downstream, and is armed into the ratchet floor only at re-arm time"
    - "Verify-only floor inheritance: run each inherited ratchet artifact for green evidence without re-scoring or promoting current->prior"

key-files:
  created:
    - mailglass_admin/e2e/judgment.spec.js
  modified: []

key-decisions:
  - "Both judgment gates are test.fixme asserting the correct end-state (D-12) — never armed against the live bug; not referenced by any required CI lane (D-13)."
  - "nav-active-correctness asserts Deliveries is NOT aria-current=page on the Overview route AND an Overview nav item IS — encoding the Phase 119 fix for the hardcoded active={:deliveries} literal and the missing :overview nav identity."
  - "no-nav-duplication asserts operator-overview-nav count 0 on populated Overview — the flagged Pitfall-2 contradiction with operator.spec.js VERIF-02 (which asserts it IS visible); operator.spec.js is FLAGGED here, updated in Phase 119, never modified in this plan."
  - "Floor inheritance is verify-only: five artifacts run green, no aesthetic re-score, no current->prior promotion, no new gate arming."

patterns-established:
  - "Drafted-then-armed judgment gate lifecycle: DRAFT (118, test.fixme) -> GREEN (119, bug fixed) -> ARMED into floor (123)."

requirements-completed: [METHOD-02, STORY-02]

coverage:
  - id: D1
    description: "Two drafted judgment gates (nav-active-correctness, no-nav-duplication) exist as test.fixme rendered-DOM assertions asserting the correct IA end-state in a sibling of structural.spec.js"
    requirement: METHOD-02
    verification:
      - kind: e2e
        ref: "playwright: cd mailglass_admin && npx playwright test e2e/judgment.spec.js --list (enumerates exactly 2 fixme/skipped gates)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The inherited v1.13 ratchet floor is verified green on clean main (verify-only, no re-score, no arming): ~26 conformance gates + 54-cell aesthetic + 9-cell axe + 24-item Bucket-A + persona drift-guard"
    requirement: STORY-02
    verification:
      - kind: integration
        ref: "bash mailglass_admin/scripts/check-conformance.sh (exit 0)"
        status: pass
      - kind: unit
        ref: "cd mailglass_admin && mix test ratchet_baseline_test.exs axe_baseline_test.exs bucket_a_coverage_test.exs persona_drift_guard_test.exs persona_cohort_test.exs (39 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "/dev/mail/gallery (gallery_live.ex) is retained byte-unchanged this phase — no testid churn, no drift-guard regression"
    requirement: STORY-02
    verification:
      - kind: other
        ref: "git diff --stat mailglass_admin/lib/mailglass_admin/gallery_live.ex (empty); drift-guard green within the baseline test batch"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-06-26
status: complete
---

# Phase 118 Plan 02: Judgment Gates Draft + Floor Verify-Green Summary

**Two drafted (test.fixme) rendered-DOM judgment gates (nav-active-correctness, no-nav-duplication) asserting the correct IA end-state, plus verify-green proof that the inherited v1.13 ratchet floor is green on clean main and the gallery is unchanged.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-26T16:28:00Z
- **Completed:** 2026-06-26T16:31:58Z
- **Tasks:** 2
- **Files modified:** 1 (new)

## Accomplishments

- Created `mailglass_admin/e2e/judgment.spec.js` as a sibling of `structural.spec.js`, reusing the same login/navigation dance via an `openOverview(page)` helper that lands on the Overview route (`/ops/mail?tenant_id=...`, no `&view=deliveries`).
- Drafted **nav-active-correctness** (`test.fixme`): on the Overview route the Deliveries sidebar link does NOT carry `aria-current="page"` AND an Overview nav item exists that IS. This encodes the Phase 119 fix for `operator_live.ex:349`'s hardcoded `active={:deliveries}` and the currently-absent `:overview` nav identity.
- Drafted **no-nav-duplication** (`test.fixme`): the populated Overview renders zero `data-testid="operator-overview-nav"` elements (`toHaveCount(0)`). This is the flagged Pitfall-2 contradiction with `operator.spec.js:352-368` (VERIF-02), which asserts the same testid IS visible — flagged here, updated in Phase 119.
- Verified all five inherited v1.13 floor artifacts green on clean main (verify-only — no re-score, no current->prior promotion, no gate arming).
- Confirmed `gallery_live.ex` is byte-unchanged this phase (STORY-02); the gallery's drift/structural tests are green within the baseline batch.

## Verify-Green Floor Evidence (Task 2 — D-13/D-14)

| # | Floor artifact | Command | Result |
|---|---|---|---|
| 1 | ~26 conformance gates | `bash mailglass_admin/scripts/check-conformance.sh` | `OK: design-system conformance clean.` — **exit 0** |
| 2 | 54-cell aesthetic ratchet (schema_version 3) | `mix test test/mailglass_admin/ratchet_baseline_test.exs` | green (in 39-test batch, 0 failures) |
| 3 | 9-cell axe baseline | `mix test test/mailglass_admin/axe_baseline_test.exs` | green (comparator reads committed baseline JSON; no live browser server needed for the ExUnit comparator) |
| 4 | 24-item Bucket-A manifest (TABLE_FLOOR=3) | `mix test test/mailglass_admin/bucket_a_coverage_test.exs` | green |
| 5 | persona drift-guard + cohort | `mix test test/mailglass_admin/persona_drift_guard_test.exs test/mailglass_admin/persona_cohort_test.exs` | green |

Combined ExUnit run (artifacts 2-5): **39 tests, 0 failures** (seed 161564). No `prior`/`current` block in the aesthetic baseline was promoted — this was a verification pass only.

**Known caveat (recorded per acceptance criteria):** the axe *producer* `e2e/axe-baseline.spec.js` is a Playwright test that needs a running operator browser server to regenerate `axe-baseline.json`; the floor's *comparator* (`axe_baseline_test.exs`, run above) reads the committed baseline and does not require the live server. Persona tests are deterministic. Per project memory, this run scoped to the named baseline test files and did NOT run a bare full `mix test` (which has ~57 unrelated Oban failures + a `voice_test.exs` dep-JS substring false-positive in worktrees).

## Task Commits

1. **Task 1: Draft judgment.spec.js — two pending rendered-DOM gates** — `1529086d` (test)
2. **Task 2: Verify-green the five inherited floor artifacts + confirm gallery unchanged** — no production code (evidence-only; output is this SUMMARY)

**Plan metadata:** (docs commit — this SUMMARY + STATE/ROADMAP)

## Files Created/Modified

- `mailglass_admin/e2e/judgment.spec.js` (NEW) — two `test.fixme` judgment gates asserting the correct IA end-state; reuses the structural.spec.js accent-allowlist seam keyed off `[aria-current='page']`; not referenced by any required CI lane.

## Decisions Made

None beyond the locked plan decisions (D-11/D-12/D-13/D-14). The gates were drafted exactly as specified: `test.fixme`, correct end-state, never armed; floor inherited verify-only.

A minor authoring note on the acceptance criterion `grep -n "test.fixme" ... returns two lines`: the file contains exactly **two `test.fixme(...)` test entries** (the load-bearing gates), but `grep -n "test.fixme"` returns four lines because two header comments reference the mechanism by name (`test.fixme(...)`). The two actual gate entries enumerate cleanly under `--list` as the two skipped tests, satisfying the intent (two drafted gates). Comment text was kept conceptual per the plan's comment-discipline guidance.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The two drafted judgment gates are ready to flip green in **Phase 119** once the shell stops hardcoding `active={:deliveries}` on the Overview route, gives Overview its own nav identity, and removes the redundant in-page `operator-overview-nav` card block.
- **Phase 119 must also update** `operator.spec.js:352-368` (VERIF-02), the opposing test that currently asserts `operator-overview-nav` IS visible — flagged here, NOT modified.
- The gates are armed into the ratchet floor in **Phase 123** (D-13), not before.
- The inherited v1.13 floor is proven green on clean main, so any Phase 119 regression will be caught by the existing artifacts.

## Self-Check: PASSED

- FOUND: `mailglass_admin/e2e/judgment.spec.js`
- FOUND commit: `1529086d` (test: draft two pending judgment gates)
- `--list` enumerates exactly 2 fixme/skipped gates
- Five floor artifacts green; `gallery_live.ex` diff empty

---
*Phase: 118-method-audit-storybook-stand-up*
*Completed: 2026-06-26*
