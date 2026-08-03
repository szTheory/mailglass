---
phase: 150
fixed_at: 2026-08-03T02:20:00Z
review_path: .planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md
iteration: 3
findings_in_scope: 3
fixed: 3
skipped: 0
status: partial
---

# Phase 150: Code Review Fix Report

**Fixed at:** 2026-08-03T02:20:00Z
**Source review:** `.planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 3
- Fixed in source: 3
- Skipped: 0
- Re-review status: pending — runtime tests could not start in this checkout.

## Fixed Issues

### CR-02: Old V1 marker-shaped strings are silently decoded as new markers

**Files modified:** `lib/mailglass/outbound/envelope.ex`, `test/mailglass/outbound/worker_test.exs`
**Commit:** `a1646a5d`
**Applied fix:** The envelope codec is V2. Only V2 decodes the `~mailglass:json-v2:*` storage representation; V1 loads its JSON strings literally. A persistence test inserts historical V1 marker-shaped metadata/provider-option strings and proves they return byte-for-byte unchanged.

### CR-03: Pre-fix finite-float V1 payloads are permanently unverifiable

**Files modified:** `lib/mailglass/outbound/payload.ex`, `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/worker.ex`, `test/mailglass/outbound/worker_test.exs`
**Commit:** `a1646a5d`
**Applied fix:** A digest-mismatched V1 row now yields the explicit `:legacy_integrity_unverifiable` outcome. Dispatch persists the Delivery failure with a bounded reason class and the Oban worker returns `{:cancel, error}`, giving the operator a terminal job rather than a retry loop. The regression seeds a V1 JSONB-style exponent float with its historical digest and asserts the terminal outcome.

### WR-01: Signed-zero regression does not observe the sign bit

**Files modified:** `test/mailglass/outbound/worker_test.exs`
**Commit:** `a1646a5d`
**Applied fix:** The float persistence regression now compares the exact IEEE-754 `float-64` bit patterns of both `0.0` and `-0.0` after the database round trip.

## Verification

- Tier 1: re-read all changed source/test sections; `git diff --check` passed before commit.
- Tier 2: `Code.string_to_quoted!/2` parsed all five changed Elixir files successfully.
- Focused envelope/payload/worker command was attempted: `mix test test/mailglass/outbound/envelope_test.exs test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_10_01 --warnings-as-errors`.
- Mix stopped before compiling Mailglass because installed `premailex` is 0.3.20 while `mix.lock` requires `~> 1.0`. Therefore the Phase 150 sampler and full core suite remain unverified; REVIEW.md intentionally remains `issues_found` pending independent re-review.

---

_Fixed: 2026-08-03T02:20:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
