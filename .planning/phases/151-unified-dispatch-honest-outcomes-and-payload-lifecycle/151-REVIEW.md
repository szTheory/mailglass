---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
reviewed: 2026-08-03T03:28:38Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - docs/api_stability.md
  - guides/compatibility-and-deprecations.md
  - guides/jobs.md
  - guides/production-go-live-checklist.md
  - lib/mailglass/adapters/swoosh.ex
  - lib/mailglass/config.ex
  - lib/mailglass/migrations/postgres.ex
  - lib/mailglass/migrations/postgres/v07.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/dispatch_outcome.ex
  - lib/mailglass/outbound/payload.ex
  - lib/mailglass/outbound/payload_lifecycle.ex
  - lib/mailglass/outbound/payload_pruner.ex
  - lib/mailglass/outbound/payload_pruner_worker.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mix/tasks/mailglass.outbound.payloads.prune.ex
  - test/mailglass/adapters/swoosh_test.exs
  - test/mailglass/config_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/migration_test.exs
  - test/mailglass/outbound/dispatch_outcome_test.exs
  - test/mailglass/outbound/payload_lifecycle_test.exs
  - test/mailglass/outbound/payload_pruner_test.exs
  - test/mailglass/outbound/wire_equivalence_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/outbound_test.exs
  - test/mailglass/v07_migration_test.exs
  - test/runtime/no_optional_deps_public_send.exs
  - test/runtime/no_optional_deps_public_send_test.exs
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 151: Code Review Report

**Reviewed:** 2026-08-03T03:28:38Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The Phase 151 source, tests, migrations, operations path, and public guidance
were reviewed at standard depth. The explicit CAS claim, atomic accepted-path
scrub, tenant-bounded pruner, V07 prefix validation, and no-Oban compile guard
are present, but three correctness/privacy regressions block shipment. In
particular, the new outcome object escapes a stable public error API, invalid
payloads are claimed without being settled, and the non-durable path logs
unbounded adapter exception text.

## Critical Issues

### CR-01: Sync delivery now returns a non-error outcome struct, breaking the stable API

**File:** `lib/mailglass/outbound.ex:671-674` (contracted by `docs/api_stability.md:1310-1316`)

**Issue:** `dispatch_prepared/4` returns `{:error, %DispatchOutcome{}}` for
every provider failure. `DispatchOutcome` is not an exception and does not
implement `Mailglass.Error`, yet `send/2`, `deliver/2`, and `dispatch_by_id/1`
are documented and specified to return `{:error, %Mailglass.Error{}}`. This is
a public compatibility break for callers that match `%Mailglass.SendError{}`;
it also changes the persisted `last_error` shape from the documented
`type/message/module` projection to an outcome map.

**Fix:** Keep `DispatchOutcome` internal to dispatch/worker classification.
Return a typed `Mailglass.SendError` (with only its safe class/reason projection
in context) on the public sync boundary, or make the outcome a documented,
stable `Mailglass.Error` implementation and update every locked contract and
consumer deliberately. The worker can receive the classification through an
internal helper/tuple rather than exposing it from `deliver/2`.

### CR-02: Invalid modern payloads are claimed but never terminally settled

**File:** `lib/mailglass/outbound.ex:260-280, 915-940, 793-823`; `lib/mailglass/outbound/payload.ex:149-175`

**Issue:** The CAS claim changes a modern payload to `:dispatching` before
envelope loading. A corrupt/unsupported envelope is converted at lines 936-940
to a `SendError` with `reason_class: :payload_unavailable`; the outer error path
only updates Delivery/Event in `persist_failed_by_id/2` and never settles that
claimed Payload. The first Oban attempt is retried because `worker_error_result/1`
does not recognize `:payload_unavailable`; later attempts see
`:already_dispatching` and cancel. The private envelope is then retained
indefinitely in `:dispatching`, cannot be pruned, and contradicts the documented
fail-closed terminal handling for corrupt and unsupported modern payloads.

**Fix:** After a successful claim, route every hydration/route-resolution error
through one settlement Multi that updates Delivery, appends the event, and
transitions the Payload atomically. Map integrity/decode/version failures to
the explicit terminal reason classes (`:payload_corrupt` or
`:payload_unsupported_version`), set their expiry, and return a cancelled
worker result. Add an integration test asserting both the first attempt and a
second attempted job leave a corrupt payload terminal (not `:dispatching`) and
that it is subsequently pruneable.

### CR-03: TaskSupervisor dispatch logs provider/private exception text

**File:** `lib/mailglass/outbound.ex:475-485`

**Issue:** Both the ordinary failure branch and rescue interpolate
`Exception.message(err)` into Logger output. A custom adapter or underlying
provider can raise with response/request text containing recipient addresses,
subject/body fragments, headers, tokens, or provider payloads. This bypasses
the new safe outcome projection and conflicts with Phase 151's promise that raw
exception content is excluded from public/operational surfaces.

**Fix:** Log only a fixed event name plus a bounded, allowlisted error module
and reason class; never interpolate exception messages or inspect the error.
For example, convert known errors with `DispatchOutcome.classify/1` and log
`outcome.class`/`outcome.reason_class`; use `:unknown` for unrecognized raised
exceptions. Add a test adapter that raises a sentinel containing an email/token
and assert the captured log omits it.

---

_Reviewed: 2026-08-03T03:28:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
