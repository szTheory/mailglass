---
phase: 123-cross-surface-coherence-ratchet-re-arm
plan: 03
subsystem: coherence-proof
tags: [coherence, persona-critic, defect-register, COH-01, single-ledger, apple-deliberate-ia]

# Dependency graph
requires:
  - phase: 123-01
    provides: green automated floor — 54-cell ratchet re-scored only-forward (run_id 2026-06-28-phase-123) + the two armed judgment gates (nav-active-correctness, no-nav-duplication)
  - phase: 123-02
    provides: finalized storybook + gallery review surfaces (inventory complete, indigo accepted, stale-boot documented)
provides:
  - "DEFECT-REGISTER.md closed: all 10 findings flipped CATALOGUED -> RESOLVED/HELD with per-finding maintainer sign-off"
  - "Phase 123 cross-surface coherence sign-off section: per-surface verdict + five hats + three personas verbatim + green-floor citation + no-new-gate statement"
  - "COH-01 coherence-proof deliverable satisfied — the auditable evidence trail Phase 124's milestone audit cites"
affects: [124-release-cut, milestone-audit, COH-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Coherence proven as adversarial persona-critic verdict + maintainer sign-off + green floor, recorded in the single DEFECT-REGISTER ledger (D-06) — NOT a new automated coherence-score gate"
    - "Persona re-shoot is evidence only (D-07): screenshots gitignored, no new ratchet cell, Personas.spec/0 byte-unchanged"
    - "Re-shoot authorized to fall back to existing .cache evidence + green floor when the demo can't run in-environment"

key-files:
  created:
    - .planning/phases/123-cross-surface-coherence-ratchet-re-arm/123-03-SUMMARY.md
  modified:
    - .planning/research/v1.14/DEFECT-REGISTER.md

key-decisions:
  - "Re-shoot NOT run: the only demo container up was a different project's (cairnloop_demo, :4100, not mailglass-seeded), DEMO_EVIDENCE_RESET_TOKEN was unset (producer beforeEach throws), and booting this repo's demo risks the documented swoosh mix.lock drift. Per the plan's explicit authorization, the verdict is grounded in existing .cache evidence + the shipped post-119-122 code + the green automated floor — re-shoot was NOT blocked on."
  - "Headline end-states re-confirmed directly against shipped source: active={@view} + :overview nav identity (D-NAV-ACTIVE), operator-overview-nav deleted grep-count 0 (D-NAV-DUP), both asserted green by the armed judgment gates."
  - "Single-ledger closure (D-06): no sibling COHERENCE-AUDIT.md; sign-off appended inline at the end of DEFECT-REGISTER.md."
  - "No new automated coherence-score gate added (D-06); Personas.spec/0 byte-unchanged (D-07)."

requirements-completed: [COH-01]

# Metrics
duration: 8min
completed: 2026-06-28
status: complete
---

# Phase 123 Plan 03: Cross-surface Coherence Proof Summary

**Closed the single DEFECT-REGISTER ledger — flipped all 10 catalogued findings to RESOLVED/HELD with per-finding maintainer sign-off and appended a Phase 123 cross-surface coherence sign-off (per-surface verdict + five hats + three personas verbatim + green-floor citation + explicit no-new-coherence-gate statement) — satisfying the COH-01 coherence-proof deliverable, with the persona re-shoot grounded in existing .cache evidence + the green floor, Personas.spec/0 byte-unchanged, and no sibling audit doc.**

## Performance

- **Duration:** ~8 min
- **Tasks:** 2 (Task 1 = evidence/verdict, no commit; Task 2 = DEFECT-REGISTER closeout, 1 commit)
- **Files modified:** 1 (+ this SUMMARY)

## Accomplishments

### Task 1 — Persona-critic harness as coherence evidence (no commit)

- **Re-shoot feasibility assessed and recorded.** The producer
  (`reference/demo_app/assets/e2e/persona-screenshots.spec.js`) requires a booted, persona-seeded
  `make demo` on its expected port plus `DEMO_EVIDENCE_RESET_TOKEN` (its `beforeEach` reset throws
  without the token). In this environment the only container up was a **different project's** demo
  (`cairnloop_demo_*` mapped to :4100, not mailglass-seeded), the token was unset, and standing up this
  repo's own demo risks the documented swoosh `mix.lock` drift. **Per Plan 123-03's explicit
  authorization, the verdict was grounded in the existing 66-cell `.cache` evidence + the shipped
  post-119-122 code + the green automated floor — the re-shoot was NOT blocked on.**
- **Headline end-states re-confirmed against shipped source:** `active={@view}`
  (`operator_live.ex:350`) + the `:overview` nav identity (`operator/shell.ex:202-265`) for D-NAV-ACTIVE;
  `operator-overview-nav` deleted (grep count 0) for D-NAV-DUP — both asserted green on every CI run by
  the armed `nav-active-correctness` / `no-nav-duplication` judgment gates.
- **Adversarial per-surface walk** against `STRESS-TEST-PROMPT.md` (Apple-deliberate-IA bar) using the
  five hats verbatim (dev-evaluator, library-integrator, maintainer-debugging,
  operator/on-call-SRE-under-stress, security-reviewer) and the three personas verbatim (northstar,
  fjordline-aps, helios-void) — verdict: all four surfaces COHERENT (captured for Task 2).
- **Guards held:** `MailglassDemo.Personas.spec/0` (`reference/persona_spec/personas.ex`) byte-unchanged;
  no screenshots staged; no new persona cell; no new gate/test file.

### Task 2 — DEFECT-REGISTER closeout (commit `e5316b57`)

- **All 10 findings flipped CATALOGUED -> RESOLVED/HELD** with per-finding maintainer sign-off notes:
  - **RESOLVED (7 IA defects, verified Phase 123 re-run, backed by green floor):** D-NAV-ACTIVE,
    D-NAV-DUP, D-ORIENT-REDUNDANT, D-OVERVIEW-SIGNPOST, D-FILTERS-ON-EMPTY, D-LABEL-TRIPLING,
    D-MOBILE-INFODUMP.
  - **HELD (guardrail):** D-THEME-PARITY — light/dark/system parity confirmed across all four surfaces;
    54-cell + 9-cell axe floor green.
  - **RESOLVED (accepted dev-only cosmetic, D-09):** D-STORYBOOK-BRAND — indigo explorer chrome accepted;
    no dep CSS / Node build.
  - **RESOLVED (docs, D-10):** D-STORYBOOK-STALE-BOOT — caveat added to `guides/run-the-demo.md`.
- **Appended `## Phase 123 — Cross-surface coherence sign-off`** recording: the per-surface verdict
  across all four surfaces (Overview/Deliveries/Inbound/Preview, all COHERENT); the five hats + three
  personas verbatim; the green-floor citation (54-cell ratchet under run_id `2026-06-28-phase-123` +
  9-cell axe at `2026-06-21` + 24-item Bucket-A + persona-drift + the two armed judgment gates); the
  explicit statement that **no new automated coherence-score gate was added** (D-06); and a maintainer
  sign-off line.

## Task Commits

| Task | Type | Commit | Files |
|------|------|--------|-------|
| 1 | (no committable artifact — evidence + verdict captured for Task 2) | — | none |
| 2 | docs | `e5316b57` | .planning/research/v1.14/DEFECT-REGISTER.md |

**Plan metadata** (this SUMMARY + STATE/ROADMAP/REQUIREMENTS) committed separately.

## Deviations from Plan

None — plan executed exactly as written. The re-shoot was not run, but that is the plan's explicitly
authorized fallback path ("If the demo or producer cannot run in this environment, record that fact and
base the verdict on the existing .cache screenshots plus the green automated floor — do NOT block on a
re-shoot"), not a deviation.

## Verification Results

- `! grep -q "CATALOGUED" DEFECT-REGISTER.md && grep -q "Cross-surface coherence sign-off" …` → **CLOSED**
  (0 CATALOGUED; 10 RESOLVED/HELD; sign-off section present).
- Five hats verbatim present: dev-evaluator, library-integrator, maintainer-debugging,
  operator/on-call-SRE-under-stress, security-reviewer → **all OK**.
- Three personas verbatim present: northstar, fjordline-aps, helios-void → **all OK**.
- No-new-gate statement + green-floor citation present → **OK**.
- No sibling `COHERENCE-AUDIT.md` created → **OK** (single-ledger, D-06).
- `git status --porcelain reference/persona_spec/personas.ex` → **empty** (byte-unchanged, D-07).
- Only `DEFECT-REGISTER.md` changed by this plan → **OK**.
- D-14 paired-test discipline: `git grep DEFECT-REGISTER` over `*.exs`/`*.spec.js`/`*.js` → **NONE**
  (research doc, no tested string; zero paired-test risk).
- No screenshots staged; `.cache/screenshots/` confirmed gitignored.

## Next Phase Readiness

- **COH-01 satisfied:** the adversarial persona-critic re-run verdict + per-defect Status closures +
  maintainer sign-off are recorded in the single DEFECT-REGISTER ledger, backed by the green automated
  floor, using the fixed five-hats/three-personas vocabulary against the Apple-deliberate-IA bar — no new
  automated coherence gate, no new persona cells, Personas.spec/0 untouched.
- Wave 2 / Phase 123 complete (Plans 01 + 02 + 03 all committed on main). Ready for the Phase 124 release
  cut, which consumes this green floor + closed DEFECT-REGISTER as the COH-01/COH-02-satisfied evidence.

## Self-Check: PASSED

- FOUND: .planning/research/v1.14/DEFECT-REGISTER.md
- FOUND: .planning/phases/123-cross-surface-coherence-ratchet-re-arm/123-03-SUMMARY.md
- FOUND commit: e5316b57 (Task 2)

---
*Phase: 123-cross-surface-coherence-ratchet-re-arm*
*Completed: 2026-06-28*
