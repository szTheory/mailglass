---
phase: 177-readable-health-and-coherent-account-navigation
plan: "02"
subsystem: testing
tags: [golden, health, regression-guard, liveview, floki]
status: complete

requires:
  - phase: 169
    provides: seed_phase169_scenario!/0, seed_phase169_health_partial!/0 and arm_reader_fault!/3 fixtures
provides:
  - "health_population_test.exs: five pre-refactor Health population goldens (default, all-eight, reversed, stale, quiet)"
  - "OperatorFixtures.seed_phase177_health_all!/1 (counts: :ascending | :reversed)"
  - "OperatorFixtures.seed_phase177_health_quiet!/0"
affects: [177-04, 177-05]

plan_head_before: 78fbad0ff162a725ffcc981a6d948bbdb9e3e377
plan_head_after: 1676b15a54625f25222c414918b04008e979f2ab

actuals:
  tokens: 4400
  tasks: 2
  commits: 2

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/health_population_test.exs
  modified:
    - mailglass_admin/test/support/operator_fixtures.ex

key-decisions:
  - "Goldens are one multi-line block per state, shaped [issues: [...], activity: [...]], so the plan's awk extraction (@<name>_golden [ ... closing line `  ]`) selects exactly five blocks"
  - "Seeded record ids are random UUIDs; each id the seed returns is replaced in the href by {<seed key>} and any other UUID in an href fails the extraction"

requirements-completed: []

coverage:
  - id: D1
    description: "Health population fingerprint (testid, count, href, stale tag) frozen from the pre-refactor markup for default, all-eight, reversed, stale and quiet states"
    requirement: OUTUX-06
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/health_population_test.exs (7 tests, tag :phase177)"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 02: Health Population Golden Summary

**Five literal Health population fingerprints, captured from the pre-refactor HealthOverview markup, so plan 177-04 can prove the recomposition changes presentation only.**

golden_commit: 1676b15a54625f25222c414918b04008e979f2ab

Tenant used by every seed: `browser-tenant` (`OperatorFixtures.tenant_id/0`). Window: the default 168 hours.

## What was built

- `seed_phase177_health_all!/1` seeds, for one tenant, deliveries failed/bounced/rejected/deferred, inbound failed/no_match, failed webhooks and unmatched events with counts 1..8 (`:ascending`) or 8..1 (`:reversed`). It returns `%{tenant_id, counts, newest_webhook_event_id, oldest_unmatched_event_id}`; the two ids are the records the Health deep links open.
- `seed_phase177_health_quiet!/0`: one delivered message, no recorded problem.
- `health_population_test.exs` (`@moduletag :phase177`, 7 tests): the five goldens plus two literal-only checks (row order equals the taxonomy order for both count sets; every issue row has a non-empty href, count above zero, and activity links have hrefs).
- No `lib/` file changed in either commit (`git diff --stat $plan_head_before..HEAD -- mailglass_admin/lib` is empty).

## Golden contents

| Golden | Issue rows (testid: count) |
|---|---|
| `@default_golden` (`seed_phase169_scenario!/0`) | failures: 1 (21 outbound, 0 inbound activity) |
| `@all_golden` | deliveries failed 1, bounced 2, rejected 3, deferred 4; inbound failed 5, no_match 6; failures 7; orphans 8 |
| `@reversed_golden` | same eight testids in the same order, counts 8 down to 1 |
| `@stale_golden` (`seed_phase169_health_partial!/0` plus a `failed_ingest` reader fault and a same-window patch) | failures: 1 with stale true; orphans: 1 with stale false |
| `@empty_golden` (`seed_phase177_health_quiet!/0`) | none; both activity links present |

## For plans 177-04 and 177-05

- Only the extractor helpers are markup dependent. Retarget `row_count/1` (today the trimmed text of the row's `p.mono`) in 177-04 and `stale_tag?/1` (today the row text containing "Last retrieved") in 177-05. Leave every `@..._golden` block byte-identical.
- Compare blocks with `awk '/^  @[a-z_]+_golden \[/,/^  \]$/'` between `golden_commit` and HEAD. It selects five blocks.
- `mask_ids/2` replaces seeded ids in hrefs by `{key}` and fails on any other UUID, so a fixture or href change cannot slip through as noise.

## Verification

- `mix test health_population_test.exs persona_cohort_test.exs --seed 0 --warnings-as-errors`: 13 tests, 0 failures (seed 12345 for the new file alone: 7 tests, 0 failures).
- Wave gate with `operator_live_test.exs`: 187 tests, 0 failures in 5.7s.
- `mix format --check-formatted` on both touched files: clean. `mix credo --strict` on both: no issues. No `IO.inspect` remains.

## Deviations from Plan

**1. [Rule 1 - Bug in plan assumption] The support-empty seed does not render zero issue rows**
- **Found during:** Task 2 capture.
- **Issue:** `seed_phase169_support_empty!/1` seeds two failed webhooks and two unmatched events inside the window, so Health renders failures 2 and orphans 2, contradicting the plan's "renders zero issue rows".
- **Fix:** added `seed_phase177_health_quiet!/0` (one delivered message) for the empty golden. The support-empty seed is not fingerprinted.
- **Commit:** 1676b15a

**2. [Rule 3 - Blocking] Hrefs embed random UUIDs**
- **Found during:** Task 1 capture. The failed-webhook and unmatched-event deep links carry `support_webhook_event_id` / `support_event_id`, which the seeds generate randomly, so a byte-literal golden could never pass twice.
- **Fix:** the extractor substitutes each id the seed returned with `{<seed key>}` and rejects any remaining UUID. Nothing else in an href is normalised (the plan's "do not normalise" intent holds for every deterministic part).
- **Commit:** 251839a6, 1676b15a

**3. [Process] Golden shape**
- The plan sketched flat tuple lists. To keep the plan's awk extraction valid for the empty state (`@x_golden []` on one line would make the range swallow later text) each golden is a single multi-line `[issues: ..., activity: ...]` block. Extractor output and literals are otherwise as specified.

**Total deviations:** 2 auto-fixed, 1 process note. **Impact:** none on scope; no `lib/` change.

## Requirement status

OUTUX-06 is guarded by this plan but not delivered by it (the Health recomposition is plan 177-04), so it is not marked complete here.

## Known Stubs

None.

## Threat Flags

None. Test-only files; no package or lockfile changes.

## Self-Check: PASSED

- `health_population_test.exs` and `operator_fixtures.ex` exist; commits 251839a6 and 1676b15a are reachable from HEAD.
- `git show --stat 1676b15a` lists `mailglass_admin/test/mailglass_admin/health_population_test.exs`; `golden_commit:` appears exactly once in this file.
