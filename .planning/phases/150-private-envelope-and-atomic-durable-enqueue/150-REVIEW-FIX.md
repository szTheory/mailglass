---
phase: 150
fixed_at: 2026-08-03T02:00:00Z
review_path: .planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 150: Code Review Fix Report

**Fixed at:** 2026-08-03T02:00:00Z
**Source review:** `.planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: JSONB numeric canonicalization makes valid payloads fail integrity verification

**Files modified:** `lib/mailglass/outbound/envelope.ex`, `test/mailglass/outbound/worker_test.exs`
**Commit:** `773a0747`
**Applied fix:** Finite floats in `metadata` and `provider_options` are persisted as reversible IEEE-754 tagged strings before JSONB storage. User strings matching either reserved tag prefix are escaped, so no marker collision is ambiguous. On delivery loading restores the original float values; integers remain ordinary JSON integers. The persistence regression covers exponent-form and trailing-zero values, a reserved-prefix string, and a stale-digest tamper rejection.

## Verification

- Tier 1: re-read the codec and persistence regression after formatting; `git diff --check` passed before the atomic source commit.
- Tier 2: `elixir -e 'Code.string_to_quoted!(...)'` parsed both changed Elixir files successfully.
- Focused envelope/payload/worker test command and the Phase 150 sampler were attempted, but Mix stopped before Mailglass compilation because this checkout has `premailex` 0.3.20 while `mix.lock` requires `~> 1.0`; an isolated build also hits pre-existing missing `yamerl` headers. The full core suite was therefore not runnable in this environment.

---

_Fixed: 2026-08-03T02:00:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
