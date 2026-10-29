---
phase: 177-readable-health-and-coherent-account-navigation
plan: "05"
subsystem: ui
tags: [phoenix-liveview, health, copy, design-system, floki, playwright]
status: complete

requires:
  - phase: 177-02
    provides: health_population_test.exs literal goldens (golden_commit 1676b15a)
  - phase: 177-04
    provides: Health column structure (verdict/1, issue_list/1, notices/1, activity/1, observation/1)
provides:
  - "Health speaks the UI-SPEC copy: Not refreshed, No mail activity in this period, per-panel stale and unavailable notices, Outbound/Inbound activity unavailable, partial-refresh toast"
  - "Private closed HealthOverview.notice_copy/2 clause set (status x panel)"
  - "docs/design-system.md amended (observation basis group, empty verdict) with a docs-contract test"
affects: [177-08, 177-11]

plan_head_before: 2c4759c8c10cf0f50950f2e9a21e25062e4c5aa4
plan_head_after: 897cd4fb64af091c19ba0708399369797d189caf

actuals:
  tokens: 9000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Notice sentences come from a closed notice_copy(status, panel) clause set; a stale clause returns the lead-in only and the template appends the timestamp and the closing period"
    - "Copy-state tests assert on Floki text with the aria-hidden timestamp tooltip filtered out, never on raw html with an apostrophe"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
    - mailglass_admin/test/mailglass_admin/health_population_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/persona_cohort_test.exs
    - mailglass_admin/docs/design-system.md
    - mailglass_admin/e2e/phase169-journey.spec.js

key-decisions:
  - "Stale notice clauses return the lead-in (\"... weren't refreshed. Showing results from\") so the shared Components.timestamp keeps rendering the time; components.ex is untouched"
  - "Replaced the 177-04 'keeps every pre-refactor visible string' test with the copy-state tests; it existed only to hold strings constant until this plan"

patterns-established:
  - "Branch: main (unpushed), same PR as 177-04 (D-17 same-change rule: the docs amendment ships with the Health restructure)"

requirements-completed: ["OUTUX-06"]

coverage:
  - id: D1
    description: "Verdict, stale tag, notices, activity fallbacks and toast match the UI-SPEC copy table; stale or unavailable never renders No issues found"
    requirement: OUTUX-06
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs (10 'Phase 177 Health copy' tests, incl. all 4 stale and 4 unavailable sentences)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs --only phase177 (real route: stale seed, arm_reader_fault!, toast)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Design system documents the observation basis group and the empty verdict, pinned by a docs-contract test"
    requirement: OUTUX-06
    verification:
      - kind: unit
        ref: "health_overview_test.exs#Phase 177 Health design-system guide documents the observation group and the empty verdict"
        status: pass
    human_judgment: false
  - id: D3
    description: "Golden population literals byte-identical; Refresh role selectors and the CSS bundle untouched"
    requirement: OUTUX-06
    verification:
      - kind: command
        ref: "golden awk extraction diff at 1676b15a vs working tree: empty; git diff on priv/static and assets: empty; 'Refresh health' lines in e2e diff: 0"
        status: pass
      - kind: e2e
        ref: "playwright phase169-journey + health-tooltips + operator (grepped): 11 passed"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-29
---

# Phase 177 Plan 05: Health Copy and Design-System Amendment Summary

**Health now speaks the UI-SPEC copy in every state (stale tag "Not refreshed", empty verdict "No mail activity in this period", eight per-panel notice sentences from a closed `notice_copy/2` clause set, honest partial-refresh toast), and the design system documents the observation-basis group and the empty verdict, pinned by a docs-contract test.**

## What was built

- Task 1 (tracer, `5555cc52`): `health_overview.ex` verdict details, stale tag, empty verdict (no detail line), activity fallbacks, and `notice_copy/2` (eight clauses). The verdict `cond` order is unchanged, so stale or unavailable can never reach "No issues found". `operator_live.ex` changed only the failure toast. `stale_tag?/1` in `health_population_test.exs` retargeted to "Not refreshed"; no literal list touched.
- Task 2 (`897cd4fb`): `docs/design-system.md` paragraphs rewritten (period and last-checked timestamp are both observation basis, one left-aligned group, Refresh adjacent to the timestamp; empty verdict copy), docs-contract test (reads the guide via `Path.expand` from `__DIR__`, asserts both statements and the absence of "stays separate" and "No recent mail activity"), `phase169-journey.spec.js:52` expects "Not refreshed".

## Copy-coupled assertions changed

- `operator_live_test.exs`: quiet Health empty state (`@tag :phase177` added), "a stale zero result cannot produce an all-clear" refute (`@tag :phase177` added), same-window stale card "Not refreshed", changed-window unavailable via `Floki.text` "couldn't be loaded", partial-refresh toast message.
- `persona_cohort_test.exs` helios-void "No mail activity in this period" (`@tag :phase177` added).
- `health_population_test.exs` `stale_tag?/1`.
- `e2e/phase169-journey.spec.js:52`.
- `health_overview_test.exs`: replaced the 177-04 string-hold test with 10 "Phase 177 Health copy" tests plus the docs-contract test.

## Verification evidence

- Task 1 verify: `health_overview + health_population + persona_cohort` 35 tests, 0 failures (`--seed 0`); `operator_live_test --only phase177` 174 tests ran... 0 failures (169 excluded); `--only phase177 --trace` on health_overview shows 12 "Phase 177 Health copy" lines (10 copy tests, counted with their describe/tag echo).
- Golden comparison: extraction (`awk '/^  @[a-z_]+_golden \[/,/^  \]$/'`) at `golden_commit` 1676b15a54625f25222c414918b04008e979f2ab vs working tree: empty diff (GOLDEN-IDENTICAL). `git diff 1676b15a..HEAD -- health_population_test.exs` touches only `row_count/1` (plan 177-04) and `stale_tag?/1` (this plan).
- Acceptance greps: `Last retrieved` 0, `No recent mail activity` 0, `Activity unavailable` 0 in `health_overview.ex`; `defp notice_copy` 8; old toast string 0 in `operator_live.ex`; `stays separate` 0, `No recent mail activity` 0 in the guide; `Last retrieved` 0 in `phase169-journey.spec.js`; `Refresh health` lines in the e2e diff 0.
- Browser (grepped `phase169-journey`, `health-tooltips`, `operator`): 11 passed, 0 skipped, 0 flaky. `priv/static/app.css` and `assets/` byte-identical before and after (`git diff --quiet`); no archived screenshot was rewritten by this narrower run.
- Plan verification: `health_population + health_overview + operator_live + persona_cohort + voice` = 228 tests, 0 failures, 1 excluded (`--seed 0`); `token_parity_test` passes; `mix format --check-formatted` clean on touched files; `check-conformance.sh` clean; `mix credo --strict` unchanged (1 pre-existing warning at `operator_live_test.exs:1945`, 3 refactors, 2 readability, none in lines this plan touched); `git status --short mailglass_admin/priv/static` empty.

## Deviations from Plan

None - plan executed as written. Notes:
- Stale notice clauses return only the lead-in ("... Showing results from") and the template appends the shared timestamp and the closing period. The test normalizes the `<time>` element's trailing source whitespace and filters the aria-hidden tooltip, which is the same markup the previous notice used.
- `mix docs` warnings were not run; the plan's verification does not call for it and no `@doc`/ExDoc source changed.

## Known Stubs

None.

## Threat Flags

None. Copy-only; T-177-26 mitigated (verdict order preserved, eight notice sentences each asserted, "No issues found" refuted for every stale or unavailable panel).

## Branch

`main` (unpushed), same PR as plan 177-04 (D-17 same-change rule).

## Self-Check: PASSED

- FOUND commits: 5555cc52 (Task 1), 897cd4fb (Task 2)
- FOUND: mailglass_admin/docs/design-system.md, mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
