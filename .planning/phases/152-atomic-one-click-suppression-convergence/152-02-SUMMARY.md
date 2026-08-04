---
phase: 152-atomic-one-click-suppression-convergence
plan: 02
subsystem: compliance
tags: [elixir, ecto, phoenix, unsubscribe, suppression, concurrency]
requires:
  - plan: 152-01
    provides: atomic canonical event-and-suppression convergence
provides:
  - created-only post-commit lifecycle and broadcast effects
  - concurrent one-click convergence and real preflight isolation proof
affects: [152-03 compatibility documentation]
tech-stack:
  added: []
  patterns: [post-commit best-effort Ecto.Multi, unique-identity canonical refetch, barrier-coordinated POST proof]
key-files:
  created: []
  modified:
    - lib/mailglass/compliance/unsubscribe_controller.ex
    - lib/mailglass/compliance/unsubscribe_convergence.ex
    - test/mailglass/compliance/unsubscribe_controller_test.exs
    - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
    - test/mailglass/schema_prefix_hardening_test.exs
    - test/mailglass/outbound/preflight_test.exs
key-decisions:
  - "Lifecycle compatibility receives a fresh Ecto.Multi after the durable convergence transaction commits and its returned Multi is best-effort."
  - "Canonical suppression refetch follows the real uniqueness identity and preserves an existing stronger manual or policy suppression."
metrics:
  duration: 10min
  completed: 2026-08-03
status: complete
requirements-completed: [UNSUB-08, UNSUB-09, UNSUB-10, UNSUB-11]
---

# Phase 152 Plan 02: Post-Commit One-Click Effects Summary

**One-click unsubscribe now emits bounded lifecycle and broadcast effects only after a newly created convergence commits, while real concurrent replays and send preflight stay tenant- and stream-isolated.**

## Accomplishments

- Moved lifecycle compatibility work out of the convergence transaction; the returned `Ecto.Multi` runs separately and callback, Multi, and broadcast failures are logged without changing the empty 200 result.
- Bound effects to tenant, delivery, event type, normalized address, scope, and stream facts; tokens and private payload are excluded.
- Added barrier-coordinated concurrent POST proof with one created-only lifecycle effect and updated hostile-schema coverage to inspect the convergence service.
- Added the public `Outbound.send/1` matrix for matching-stream blocking plus stream, transactional, normalized-address, and other-tenant controls.

## Task Commits

1. **Task 1: Run lifecycle compatibility and broadcast only after created convergence commits** — `d786c273` (RED), `2eaa8d19` (GREEN)
2. **Task 2: Prove serial, true-concurrent, tenant, and hostile-schema convergence** — `6dd3f7b0`
3. **Task 3: Prove immediate enforcement through the real Outbound preflight matrix** — `abb46b6d`

## Verification

- `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` — pass (17 tests)
- `mix test test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/schema_prefix_hardening_test.exs --warnings-as-errors && mix verify.schema_prefix` — pass
- `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` — pass (27 tests)
- Combined Plan 02 gate — pass: 1 property, 49 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Refetch canonical suppression by its real unique identity**
- **Found during:** Task 1
- **Issue:** The conflict refetch additionally required `reason: :unsubscribe`, but the database uniqueness constraint is tenant/address/scope/stream. A pre-existing manual or policy row would therefore make a valid unsubscribe falsely fail after `ON CONFLICT DO NOTHING`.
- **Fix:** Removed the reason predicate, preserving the existing immutable stronger suppression while the canonical unsubscribe event still records the request.
- **Files modified:** `lib/mailglass/compliance/unsubscribe_convergence.ex`, `test/mailglass/compliance/unsubscribe_controller_test.exs`
- **Commit:** `2eaa8d19`

**2. [Rule 1 - Bug] Kept schema-prefix source assertion aligned with extracted convergence service**
- **Found during:** Task 2
- **Issue:** The hostile-schema test still inspected the controller for a refetch that Plan 01 moved into `UnsubscribeConvergence`.
- **Fix:** Pointed the structural assertion at the convergence service.
- **Files modified:** `test/mailglass/schema_prefix_hardening_test.exs`
- **Commit:** `6dd3f7b0`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all six modified implementation and test files exist.
- Confirmed task commits `d786c273`, `2eaa8d19`, `6dd3f7b0`, and `abb46b6d` exist in git history.
