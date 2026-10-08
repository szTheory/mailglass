---
phase: 169-outbound-investigation-and-recovery
plan: "02"
subsystem: outbound-operator
tags: [elixir, ecto, phoenix-liveview, operator-health, webhook-support, playwright]

requires:
  - phase: 169-01
    provides: Account-scoped Delivery context, URL-backed filters, and the rendered browser baseline.
provides:
  - Independent Account Health observations with explicit current, stale, and unavailable states.
  - Exact Account-scoped webhook and Event support evidence, separated from population examples.
  - Same-kind Health destinations and Delivery handoffs only when persisted linkage proves the relationship.
affects: [169-03, 169-05, outbound-operator, support-investigation]

actuals:
  tokens: 20028
  tasks: 2
  commits: 2
commits: 2
plan_head_before: fec3a2a4265fa5941afa9dd08316b7fd44061649
plan_head_after: 77452a76a192ee250d04ae910bd2a79eb0d38bb8

tech-stack:
  added: []
  patterns:
    - Independent scoped evidence reads retain the last known value and label stale or unavailable results.
    - Exact Account support reads expose narrow projections and use the same non-disclosing state for missing and foreign IDs.
    - Synthetic browser faults use a locked, one-shot registry that survives short-lived request processes.

key-files:
  created: []
  modified:
    - lib/mailglass.ex
    - lib/mailglass/operator/support_summary.ex
    - test/mailglass/operator/support_summary_test.exs
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/support/operator_fixtures.ex

key-decisions:
  - "Keep the five Health populations independently readable and bind windowed reads to one as-of instant; active suppressions remain current-at-read."
  - "Resolve exact Account webhook and Event IDs independently from Delivery list membership, and name a Delivery only when a unique persisted linkage exists."
  - "Keep exact support read functions documentation-hidden while exporting their module through the core boundary for Admin use."
requirements-completed: [OUTUX-01, OUTUX-04]
coverage:
  - id: D1
    description: "Health shows independent Account populations with accurate time basis and explicit stale/unavailable state while retaining other available facts."
    requirement: OUTUX-01
    verification:
      - kind: unit
        ref: "test/mailglass/operator/support_summary_test.exs; test/mailglass/operator/suppressions_test.exs"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs — isolated transient and unexpected read failures"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase169-journey.spec.js — Health partial observation refresh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact webhook/Event support IDs remain stable, scoped, non-disclosing for foreign records, and separate from population exemplars."
    requirement: OUTUX-04
    verification:
      - kind: unit
        ref: "test/mailglass/operator/support_summary_test.exs — exact Account support reads"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs — older exact, missing/foreign, linkage, and independent failure cases"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase169-journey.spec.js — Account support exact ID and proven Delivery handoff"
        status: pass
    human_judgment: false
  - id: D3
    description: "Health actions open same-kind support evidence; exact linked Events hand off only to their recorded Delivery while retaining the Event ID."
    requirement: OUTUX-01
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs — Health destinations and exact support routes"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase169-journey.spec.js — empty filtered Deliveries and linked Event navigation"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-10-08
status: complete
---

# Phase 169 Plan 02: Scoped Health and Exact Account Support Summary

**Health now keeps independent Account evidence truthful through partial reads, and exact webhook/Event investigations no longer depend on Delivery list membership.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-10-08T00:34:00Z
- **Completed:** 2026-10-08T00:58:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Split failed webhook, unmatched Event, replay audit, reconciliation audit, and current suppression observations so an unavailable read cannot turn other evidence into a false empty state.
- Bound windowed Health reads and their displayed interval to a shared observation instant; stale cards retain prior values and say “Last retrieved.”
- Added narrow Account-scoped exact webhook/Event projections with safe identifiers, provider references, timestamps, status, and proven linkage only.
- Added a separate exact support record view that preserves the requested ID alongside changing examples, shows a shared non-disclosing missing/foreign state, and hands off only to a uniquely linked Delivery.
- Added synthetic one-shot transient and unexpected fault coverage plus browser scenarios for partial Health and exact support navigation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Read each Health population independently and label its actual basis** — `63f532d3` (feat)
2. **Task 2: Resolve exact Account support evidence and prove its Delivery relationship** — `77452a76` (feat)

## Verification

- Core: `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/operator/suppressions_test.exs --seed 1` — 19 passed.
- Admin: `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 1` — 92 passed.
- Browser: Phase 169 Health partial-refresh and exact Account support journeys on port 4102 — 2 passed. Screenshots were written under `mailglass_admin/test-results/`.
- The installed Elixir 1.20 / Erlang 29 toolchain was used with an isolated `HEX_HOME` because the repository-pinned Erlang 27.3.4.13 version is unavailable on this host. No toolchain or dependency files were changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Keep one-shot browser reader faults alive across request completion**
- **Found during:** Task 1 browser verification
- **Issue:** An ETS table first created by the short-lived mutation request disappeared before the LiveView consumed its fault.
- **Fix:** Replaced request-owned ETS storage with a locked, VM-wide test-only registry that atomically consumes each session/operation fault once and clears on fixture reset.
- **Files modified:** `mailglass_admin/test/support/operator_fixtures.ex`
- **Commit:** `63f532d3`

**2. [Rule 2 - Missing boundary access] Expose the planned internal SupportSummary reads to Admin**
- **Found during:** Task 2
- **Issue:** The Admin app could call the planned sibling-only projection functions only through a core module that was not exported by the Mailglass Boundary.
- **Fix:** Exported `Operator.SupportSummary` at the core boundary; the added exact-read functions remain marked `@doc false`.
- **Files modified:** `lib/mailglass.ex`
- **Commit:** `77452a76`

**3. [Rule 1 - Bug] Avoid false empty evidence and label stale metric cards**
- **Found during:** Task 2
- **Issue:** Stale reads did not trigger the partial-evidence notice, and support cards could describe an unavailable count as “No failures.”
- **Fix:** Include stale observations in the partial notice, label stale counts “Last retrieved,” and show “Unavailable” instead of empty-state copy for missing counts.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`
- **Commit:** `77452a76`

## Decisions Made

- Keep Health evidence tied to persisted populations and show active suppression records on their current-at-read basis.
- Keep Account support Event selection independent of the selected Delivery; open a named Delivery only from a recorded unique linkage.
- Keep synthetic fault injection limited to the test router and exact enumerated reader operations.

## Known Stubs

None found in the files changed by this plan.

## Threat Surface Scan

The implementation adds read-only scoped query projections. The mutation route and fault registry exist only in the synthetic test endpoint. No new production route, authentication path, schema, or raw-payload exposure was added.

## Self-Check: PASSED

- Summary file exists at the planned phase path.
- Task commits `63f532d3` and `77452a76` are ancestors of HEAD.
- Persisted plan ledger measured 2 commits from `fec3a2a4265fa5941afa9dd08316b7fd44061649` through `77452a76a192ee250d04ae910bd2a79eb0d38bb8`.
