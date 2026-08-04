---
phase: 152-atomic-one-click-suppression-convergence
plan: 03
subsystem: compliance-documentation
tags: [elixir, ecto, rfc-8058, unsubscribe, suppression, stability-contract]
requires:
  - plan: 152-02
    provides: post-commit created-only lifecycle and broadcast effects with tenant-safe convergence
provides:
  - executable one-click response, scope, lifecycle, and operator contract
  - stable configuration and callback compatibility evidence
affects: [phase-152-verification, phase-153-adoption-proof]
tech-stack:
  added: []
  patterns: [executable documentation contracts, post-commit lifecycle compatibility]
key-files:
  created: []
  modified:
    - lib/mailglass/lifecycle.ex
    - lib/mailglass/config.ex
    - guides/unsubscribe.md
    - guides/production-go-live-checklist.md
    - docs/api_stability.md
    - test/mailglass/docs/unsubscribe_guide_test.exs
    - test/mailglass/docs_contract_test.exs
    - test/mailglass/stability_contract_test.exs
    - test/mailglass/compliance/unsubscribe_test.exs
key-decisions:
  - "One-click lifecycle compatibility retains its callback and config shape but its returned Multi runs separately and best-effort only after convergence commits."
  - "Empty 200 is Mailglass privacy compatibility, while RFC 8058 is cited only for HTTPS POST/no-redirect interoperability."
requirements-completed: [UNSUB-07, UNSUB-08, UNSUB-09, UNSUB-10, UNSUB-11]
metrics:
  duration: 12min
  completed: 2026-08-03
status: complete
---

# Phase 152 Plan 03: One-Click Contract Evidence Summary

**Executable public guidance now locks atomic canonical event plus stream suppression convergence, byte-empty outcomes, and compatible best-effort lifecycle effects.**

## Accomplishments

- Replaced every one-click transaction-local/co-commit promise with the actual post-commit `handle_event(Ecto.Multi.new(), attrs)` compatibility sequence.
- Documented and tested canonical event plus immutable `:address_stream` suppression, Delivery-derived scope, replays/concurrency, tenant/prefix isolation, byte-empty 200 privacy outcomes, and byte-empty 500 convergence failures.
- Added a bounded production verification procedure proving real same-stream preflight blocking with transactional, unrelated-stream, and tenant isolation controls.
- Kept RFC 8058 attribution accurate and explicitly excluded arbitrary-host exactly-once and Phase 153 generated-host/release claims.

## Task Commits

1. **Task 1: Lock the lifecycle config and public one-click contract in executable docs** — `9a1c7f24`
2. **Task 2: Add production, stability, and cross-contract evidence** — `08f928ab`

## Verification

- `mix test test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` — pass (21 tests).
- `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` — pass (44 tests, 1 existing skip).
- `mix verify.docs.contract` — pass.
- Phase 152 combined focused test gate — pass (115 tests, 1 existing skip).
- `mix docs --warnings-as-errors` — pass.
- `mix verify.stability_contract` — blocked by two unrelated `mailglass_admin` OperatorLive baseline failures; recorded in `deferred-items.md`.
- `mix format --check-formatted` — blocked by unrelated existing formatting drift in `lib/mailglass/optional_deps/oban.ex`; that file was untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used the available `Code.fetch_docs/1` API in the contract test**
- **Found during:** Task 1
- **Issue:** The initial test used non-existent `Code.fetch_docs!/1`.
- **Fix:** Switched the assertion to inspect the lifecycle source, which also avoids compiled-doc line wrapping as a false contract failure.
- **Files modified:** `test/mailglass/compliance/unsubscribe_test.exs`
- **Commit:** `9a1c7f24`

## Known Stubs

None.

## Deferred Issues

- Full stability and format gates have unrelated baseline failures documented in `deferred-items.md`; no Phase 152-owned source or test was changed to mask them.

## Self-Check: PASSED

- Confirmed all key files exist and task commits `9a1c7f24` and `08f928ab` are present in git history.
