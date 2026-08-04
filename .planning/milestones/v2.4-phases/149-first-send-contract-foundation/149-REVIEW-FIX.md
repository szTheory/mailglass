---
phase: 149
fixed_at: 2026-08-02T18:44:18Z
review_path: /Users/jon/projects/mailglass/.planning/phases/149-first-send-contract-foundation/149-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 149: Code Review Fix Report

**Fixed at:** 2026-08-02T18:44:18Z
**Source review:** `/Users/jon/projects/mailglass/.planning/phases/149-first-send-contract-foundation/149-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Supported HTML masks and silently drops an unsupported explicit plaintext body

**Files modified:** `lib/mailglass/outbound/preflight.ex`, `test/mailglass/outbound/preflight_test.exs`, `test/mailglass/outbound/deliver_later_test.exs`
**Commit:** ed5781ef
**Applied fix:** Validation now rejects any explicitly supplied unsupported HTML or plaintext component before accepting another present body. Sync and async regression tests cover atom and invalid-UTF-8 plaintext alongside valid HTML, asserting bounded typed errors and no rendering, persistence, job, task, or adapter effect.

### CR-02: Idempotency erases the native recipient field and suppresses a distinct valid envelope

**Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound_test.exs`, `test/mailglass/outbound/deliver_many_test.exs`
**Commit:** c3cecc2c
**Applied fix:** The key now hashes the validated native recipient field as well as its unchanged address. Sync coverage proves distinct `to`/`cc`/`bcc` envelopes dispatch intact with distinct keys; batch coverage proves distinct keys and exact same-field replay convergence.

---

_Fixed: 2026-08-02T18:44:18Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
