---
phase: 149-first-send-contract-foundation
plan: "04"
subsystem: public documentation
tags: [elixir, exdoc, swoosh, tenancy, preflight, renderer]
requires:
  - phase: 149-01
    provides: "Resolver-aware default tenancy and strict custom-tenancy preflight"
  - phase: 149-02
    provides: "Exact one-recipient and bounded body preflight contract"
  - phase: 149-03
    provides: "Renderer-owned plaintext and CSS-inliner behavior"
provides:
  - "Stable public documentation for the Phase 149 first-send contract"
  - "A default-tenant one-recipient walkthrough with exact renderer switches"
  - "Explicit Phase 150/151 durability and dispatch scope fences"
affects: [150-private-envelope-and-atomic-durable-enqueue, 151-unified-dispatch, 153-generated-host-proof, outbound, docs]
tech-stack:
  added: []
  patterns:
    - "Public error docs describe only bounded non-PII context keys."
    - "Preview promises renderer parity, never future provider-wire behavior."
key-files:
  created: []
  modified:
    - docs/api_stability.md
    - guides/authoring-mailables.md
    - guides/getting-started.md
    - guides/jobs.md
    - guides/preview.md
    - guides/multi-tenancy.md
    - test/mailglass/docs_migration_smoke_test.exs
key-decisions:
  - "SingleTenant's implicit tenant is documented consistently as string \"default\"; custom tenancy never inherits that fallback."
  - "Documentation limits parity claims to shared renderer output and reserves envelope, enqueue, wire, outcome, and lifecycle guarantees for Phases 150 and 151."
patterns-established:
  - "Copy-paste first-send examples must include exactly one native recipient and a nonblank supported body."
requirements-completed: [FIRST-01, FIRST-02, FIRST-03, FIRST-04, FIRST-05, FIRST-06, FIRST-07]
coverage:
  - id: D1
    description: "Stable docs state resolver-aware tenancy, bounded preflight errors, and renderer ownership without PII context."
    requirement: FIRST-01
    verification:
      - kind: integration
        ref: "mix docs && mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "First-send, jobs, and preview guides show renderer configuration and only the Phase 149 shared-renderer parity guarantee."
    requirement: FIRST-06
    verification:
      - kind: automated_ui
        ref: "mix docs && mix test test/mailglass/renderer_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "Documentation contract and raw Swoosh migration smoke use a supported first-send body shape."
    requirement: FIRST-07
    verification:
      - kind: integration
        ref: "mix mailglass.docs.check && mix test test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
metrics:
  duration: 8m
  completed: 2026-08-02
status: complete
---

# Phase 149 Plan 04: First-Send Contract Foundation Summary

**Public adopter documentation now describes the tested default-tenant, one-recipient first-send and shared-renderer contract while fencing durable-envelope and dispatch behavior to later phases.**

## Performance

- **Duration:** 8m
- **Started:** 2026-08-02T18:00:00Z
- **Completed:** 2026-08-02T18:08:00Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Documented existing `%Mailglass.SendError{type: :preflight_rejected}` bounded context and the strict `TenancyError :unstamped` distinction without adding error types or exposing PII.
- Published native Swoosh authoring, default `"default"` tenancy, exact recipient/body, explicit plaintext, and CSS-inliner semantics across stability and adopter guides.
- Limited preview, sync, and async claims to the shared `Mailglass.Renderer`; explicitly reserved private-envelope/atomic-enqueue work for Phase 150 and wire outcomes/payload lifecycle for Phase 151.
- Repaired the raw-Swoosh migration smoke fixture so it remains a valid first-send regression under the new nonblank-body preflight.

## Task Commits

1. **Task 1: Lock the stable preflight and renderer contract** - `9d178c4c` (docs)
2. **Task 2: Publish one accurate first-send and preview path** - `305dc1ab` (docs)
3. **Rule 1 regression fix: align migration smoke with preflight** - `8fdb0fa2` (test)

## Files Created/Modified

- `docs/api_stability.md` - Stable preflight, tenancy, error-context, renderer-order, and configuration contract.
- `guides/authoring-mailables.md` - Native one-recipient and valid-body authoring rules.
- `guides/multi-tenancy.md` - `SingleTenant` `"default"` normalization and custom-resolver fail-closed boundary.
- `guides/getting-started.md` - Supported default-tenant sync/async walkthrough and renderer settings.
- `guides/jobs.md` - Accurate async-selection and preview parity boundary.
- `guides/preview.md` - Shared renderer behavior and future-phase fence.
- `test/mailglass/docs_migration_smoke_test.exs` - Raw Swoosh smoke email now includes a valid nonblank plaintext body.

## Decisions Made

- Kept the public error family closed: recipient/body violations are documented as the existing `:preflight_rejected` type with only `reason_class`, `recipient_count`, and `body_state` context.
- Used `"default"` consistently for unstamped `SingleTenant` sends and named custom tenancy as strict and restorable for every execution context.
- Treated renderer parity as HTML/text preparation parity only; no Phase 149 documentation claims private envelope fidelity, atomic enqueue, wire equality, dispatch outcomes, or payload lifecycle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated the stale raw-Swoosh migration smoke fixture**
- **Found during:** Overall phase verification
- **Issue:** The fixture had no body, so the Phase 149 shared preflight correctly returned `:preflight_rejected` instead of the test's expected success.
- **Fix:** Added nonblank plaintext through `Swoosh.Email.text_body/2`.
- **Files modified:** `test/mailglass/docs_migration_smoke_test.exs`
- **Verification:** `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` passed (5 tests).
- **Committed in:** `8fdb0fa2`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The regression now proves a valid raw-Swoosh first send; no public surface or scope changed.

## Issues Encountered

- `mix docs`, the preflight/renderer/preview focused suites, `mix mailglass.docs.check`, and the docs contract suite passed. The full `mix test --warnings-as-errors` gate then failed in the unrelated `Mailglass.Properties.IdempotencyConvergenceTest` property because its snapshot contained keys from concurrent work. The failure and generated case are recorded in `deferred-items.md`; it is outside the documentation and first-send contract changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 150 can rely on a public boundary that does not pre-claim private-envelope persistence or atomic enqueue. Phase 151 can add wire/outcome/payload guarantees without contradicting the published renderer-parity guidance.

## Self-Check: PASSED

- Confirmed task commits `9d178c4c`, `305dc1ab`, and `8fdb0fa2` exist.
- Confirmed all six planned documentation files and the migration smoke test exist.
