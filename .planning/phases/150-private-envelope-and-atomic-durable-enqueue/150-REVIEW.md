---
phase: 150-private-envelope-and-atomic-durable-enqueue
reviewed: 2026-08-03T01:55:30Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .github/workflows/ci.yml
  - lib/mailglass/migrations/postgres/v06.ex
  - lib/mailglass/outbound/envelope.ex
  - lib/mailglass/outbound/payload.ex
  - lib/mailglass/outbound.ex
  - mix.exs
  - scripts/no_optional_deps_runtime_smoke.sh
  - test/mailglass/outbound/envelope_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/v06_migration_test.exs
  - test/runtime/no_optional_deps_public_send.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 150: Code Review Report

**Reviewed:** 2026-08-03T01:55:30Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Final re-review of `a1646a5d` and `5a39ee89`: the V2 tagged IEEE-754 representation is collision-safe for new envelopes, V1 marker-shaped strings remain literal, V1 numeric digest mismatches now become a terminal persisted failure, V2 tampering remains `:integrity_failed`, and signed zero is bit-tested. The focused codec, worker, and durable-send tests pass. One compatibility blocker remains for payloads produced by the intervening `773a0747` implementation.

## Narrative Findings (AI reviewer)

## Resolved Prior Findings

- **CR-01:** New V2 envelopes encode finite floats as tagged IEEE-754 values, avoiding `jsonb` numeric canonicalization. The persistence regression covers exponent/trailing-zero forms, escaped V2-prefix strings, `+0.0`, `-0.0`, and tamper rejection.
- **CR-02:** `Envelope.load/1` selects decoding by envelope version, so historical V1 marker-shaped strings remain literal.
- **CR-03:** A V1 digest mismatch has an explicit safe outcome: `Payload` returns `:legacy_integrity_unverifiable`, `Outbound` persists failure, and the Oban worker cancels rather than retrying indefinitely.
- **WR-01:** The regression now compares the IEEE-754 bit patterns of both zero signs.

## Critical Issues

### CR-04: Payloads written by the interim V1-marker commit decode floats as strings

**File:** `lib/mailglass/outbound/envelope.ex:68-70`, `lib/mailglass/outbound/envelope.ex:366-379`

**Issue:** `773a0747` wrote float values as `~mailglass:json-v1:float:<IEEE-754 hex>` while continuing to emit envelope version 1. `a1646a5d` correctly makes V1 strings literal to protect pre-existing V1 user data, but consequently treats every float marker written by that interim version as a string on retry. For example, a queued `1.0e20` becomes `"~mailglass:json-v1:float:4415af1d78b58c40"` at adapter dispatch. Its digest still matches, so this is silent type/value corruption rather than the bounded legacy-integrity failure. The current historical-string test demonstrates the decoder behavior, but no test covers data created by `773a0747`.

**Fix:** Do not ship an upgrade path that may contain interim-marker payloads without an explicit data disposition. If `773a0747` was ever deployed, identify its affected payload window and either migrate it using release-scoped evidence or fail those payloads terminally/operator-visibly; the bytes alone are ambiguous with legitimate old V1 strings. Add a regression seeded with an authentic interim V1 marker envelope and assert the documented safe outcome.

---

_Reviewed: 2026-08-03T01:55:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
