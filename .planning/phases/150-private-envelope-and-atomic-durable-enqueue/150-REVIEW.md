---
phase: 150-private-envelope-and-atomic-durable-enqueue
reviewed: 2026-08-03T01:40:37Z
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
status: fixed
fixed_by: 773a0747
---

# Phase 150: Code Review Report

**Reviewed:** 2026-08-03T01:40:37Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** fixed

## Summary

Reviewed the actual gap-closure changes from plans 150-06 through 150-09, including codec fidelity/safety, the prefix-hostile V06 lifecycle test, real queued-worker retry proof, and the isolated no-optional-dependency runtime harness. The migration, queued retry, and runtime probe exercised successfully in this checkout. The finite-float JSONB integrity finding below was fixed in `773a0747` with a storage-stable, reversible representation and a persistence regression.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: JSONB numeric canonicalization makes valid payloads fail integrity verification

**Resolution:** Fixed in `773a0747`. Finite floats in the bounded JSON subtrees now persist as unambiguous, escaped tagged IEEE-754 strings and decode back to their original values after digest verification; integer values remain native JSON integers. The regression inserts and reloads exponent-form and trailing-zero floats through PostgreSQL, verifies reconstruction, and retains the tamper rejection assertion.

**File:** `lib/mailglass/outbound/payload.ex:40-46`, `lib/mailglass/outbound/payload.ex:58-62`

**Issue:** `from_envelope/4` stores a SHA-256 digest of `Jason.encode/1`'s pre-insert representation, but `fetch_for_delivery/2` recomputes that digest from the map decoded from PostgreSQL `jsonb`. PostgreSQL normalizes valid JSON numeric spellings: for example, Jason encodes `%{"value" => 1.0e20}` as `{"value":1.0e20}`, whereas `jsonb` canonically stores it as `{"value": 100000000000000000000}`. On read it no longer has the same Elixir numeric representation/encoding, so the recomputed digest differs and `fetch_for_delivery/2` returns `:integrity_failed`. Finite floats are explicitly accepted by `Envelope.json/1` at `lib/mailglass/outbound/envelope.ex:267-268`, so a supported `metadata` or `provider_options` value can permanently prevent a committed queued job from dispatching.

**Fix:** Hash a canonical, storage-stable representation instead of the transient Elixir map. For example, persist the canonical JSON bytes (or a recursively normalized numeric representation that cannot change under `jsonb`) and digest those exact bytes; alternatively reject floats from V1 if numeric fidelity is intentionally unsupported. Add a persistence-level regression that inserts and fetches envelopes containing exponent-form and trailing-zero floats, then proves `Payload.fetch_for_delivery/2` succeeds.

```elixir
# One viable direction: store canonical JSON text and hash that exact value.
canonical_json = Jason.encode!(envelope)
digest = :crypto.hash(:sha256, canonical_json) |> Base.encode16(case: :lower)

# On fetch, verify the stored canonical_json bytes before decoding/loading.
```

---

_Reviewed: 2026-08-03T01:40:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
