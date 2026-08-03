---
phase: 150-private-envelope-and-atomic-durable-enqueue
reviewed: 2026-08-03T01:48:30Z
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
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 150: Code Review Report

**Reviewed:** 2026-08-03T01:48:30Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Re-reviewed the CR-01 fix commits `773a0747` and `31f0e51a` against the actual persistence path. The tagged IEEE-754 representation correctly fixes new envelope float fidelity and survives PostgreSQL `jsonb`; the focused tests pass. However, the implementation changes the interpretation of existing V1 data without a version discriminator or migration: pre-fix float payloads remain undeliverable, while pre-fix strings sharing the new reserved prefixes are silently corrupted on dispatch.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: JSONB numeric canonicalization makes valid payloads fail integrity verification

**Resolution:** Fixed for newly created envelopes in `773a0747`; the two compatibility blockers below still prevent the overall finding from being closed.

**File:** `lib/mailglass/outbound/payload.ex:40-46`, `lib/mailglass/outbound/payload.ex:58-62`

**Issue:** `from_envelope/4` stores a SHA-256 digest of `Jason.encode/1`'s pre-insert representation, but `fetch_for_delivery/2` recomputes that digest from the map decoded from PostgreSQL `jsonb`. PostgreSQL normalizes valid JSON numeric spellings: for example, Jason encodes `%{"value" => 1.0e20}` as `{"value":1.0e20}`, whereas `jsonb` canonically stores it as `{"value": 100000000000000000000}`. On read it no longer has the same Elixir numeric representation/encoding, so the recomputed digest differs and `fetch_for_delivery/2` returns `:integrity_failed`. Finite floats are explicitly accepted by `Envelope.json/1` at `lib/mailglass/outbound/envelope.ex:267-268`, so a supported `metadata` or `provider_options` value can permanently prevent a committed queued job from dispatching.

**Fix:** Hash a canonical, storage-stable representation instead of the transient Elixir map. For example, persist the canonical JSON bytes (or a recursively normalized numeric representation that cannot change under `jsonb`) and digest those exact bytes; alternatively reject floats from V1 if numeric fidelity is intentionally unsupported. Add a persistence-level regression that inserts and fetches envelopes containing exponent-form and trailing-zero floats, then proves `Payload.fetch_for_delivery/2` succeeds.

```elixir
# One viable direction: store canonical JSON text and hash that exact value.
canonical_json = Jason.encode!(envelope)
digest = :crypto.hash(:sha256, canonical_json) |> Base.encode16(case: :lower)

# On fetch, verify the stored canonical_json bytes before decoding/loading.
```

### CR-02: Old V1 marker-shaped strings are silently decoded as new float/string markers

**File:** `lib/mailglass/outbound/envelope.ex:366-379`

**Issue:** V1 already allowed arbitrary JSON strings. Before `773a0747`, a payload could legitimately contain, for example, `"~mailglass:json-v1:float:3ff0000000000000"` or `"~mailglass:json-v1:string:customer-value"`. The new loader has no format/version discriminator for the marker encoding: it converts the former to `1.0` and strips the latter's prefix. Escaping only occurs when new values are dumped (`320-326`), so it cannot protect already persisted V1 rows. A retry of one of those rows sends a different provider option or metadata value than the one that was queued.

**Fix:** Introduce a new envelope version (or an explicit persisted encoding revision) and decode marker strings only for that revision. Retain the legacy V1 decoder unchanged for existing payloads, then add a migration/compatibility test that inserts historical marker-shaped strings and proves they load byte-for-byte unchanged.

### CR-03: Pre-fix finite-float V1 payloads are still permanently unverifiable

**File:** `lib/mailglass/outbound/envelope.ex:115-119`, `lib/mailglass/outbound/payload.ex:58-64`

**Issue:** Existing payloads created before `773a0747` stored finite floats as JSON numbers and recorded a digest of Jason's pre-`jsonb` spelling. PostgreSQL has already discarded that spelling, so `Payload.fetch_for_delivery/2` fails its digest comparison before `Envelope.load/1` can apply the new decoder. No migration, versioned digest verifier, or explicit terminal recovery exists for those queued records. Thus every already-queued exponent/trailing-zero float payload remains stranded even though new payloads work.

**Fix:** Provide an explicit compatible recovery path. Prefer a version bump plus a migration that safely rewrites known affected payloads only when their integrity can be established from a stored canonical representation; if that cannot be proven, mark them terminal with a clear operator-visible recovery action rather than leaving infinite retries. Add a regression seeded with a historical pre-fix `jsonb` envelope/digest and assert the chosen safe outcome.

## Warnings

### WR-01: The signed-zero regression cannot observe a lost sign bit

**File:** `test/mailglass/outbound/worker_test.exs:108-112`, `test/mailglass/outbound/worker_test.exs:137-138`

**Issue:** The test includes `[0.0, -0.0]`, but compares the restored structure with `==`. In Elixir, `0.0 == -0.0` is true, so this test remains green if the codec collapses negative zero to positive zero—the exact IEEE-754 fidelity property the tagged representation is meant to preserve.

**Fix:** Assert the float bit patterns explicitly, e.g. `assert <<-0.0::float-64>> == <<Enum.at(restored.swoosh_email.provider_options["nested"], 1)::float-64>>`, and add marker-shaped historical-string cases separately from the new escaped-string round trip.

---

_Reviewed: 2026-08-03T01:48:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
