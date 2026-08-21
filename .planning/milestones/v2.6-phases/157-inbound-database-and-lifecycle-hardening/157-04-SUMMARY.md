---
phase: 157-inbound-database-and-lifecycle-hardening
plan: "04"
subsystem: inbound-router-security
tags: [macros, literal-ast, ets, rate-limiting]
dependency_graph:
  requires: []
  provides: [literal-only-route-declarations, bounded-inbound-key-regression]
  affects: [inbound-router, inbound-rate-limiter]
tech_stack:
  added: []
  patterns: [recursive-literal-decoder, fail-closed-compile-time-validation]
key_files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/router.ex
    - mailglass_inbound/test/mailglass_inbound/router_test.exs
    - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
decisions:
  - "Expand only syntactic module aliases; never expand or evaluate arbitrary mailbox/option AST."
  - "Decode strings, atoms, numbers, lists, tuples, and non-interpolated regex sigils before existing value validation."
metrics:
  completed: "2026-08-17"
  tasks_completed: 2
status: complete
---

# Phase 157 Plan 04: Literal router and bounded inbound state Summary

Inbound route declarations are now compile-time data rather than executable expressions, while the
Phase 156 finite ETS admission, idle reclamation, and owner restart contract remains pinned by tests.

## Completed Tasks

1. **Literal-only route declarations** — Replaced unrestricted `Code.eval_quoted/3` with a recursive
   literal decoder, restricted mailbox inputs to module aliases, preserved regex/route/source behavior,
   and proved variables, calls, interpolation, captures, and mailbox macros are rejected without side
   effects.
2. **Bounded rate-limit regression** — Added a deterministic small-cap test proving active overflow
   fails closed and expired keys are reclaimed without exceeding the configured cardinality.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/router_test.exs test/mailglass_inbound/router/matcher_test.exs test/mailglass_inbound/rate_limiter_test.exs --warnings-as-errors` — passed (2 properties, 27 tests).
- Changed-file formatter and `git diff --check` — passed.
- Repository search confirms no `Code.eval_quoted` remains in the inbound router.

## Deviations from Plan

None. No production rate-limiter change was necessary because the established owner already implements
the required cap, expiry, fail-closed overflow, and restart behavior.

## Self-Check: PASSED

- All plan-owned source and test files plus this summary are present.
- No public route syntax, package boundary, or admin/operator UI file changed.
