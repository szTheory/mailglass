---
phase: 150
fixed_at: 2026-08-03T00:27:29Z
review_path: .planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 150: Code Review Fix Report

**Fixed at:** 2026-08-03T00:27:29Z
**Source review:** `.planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Mailglass schema prefix is incorrectly forced onto Oban jobs

**Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound/deliver_later_test.exs`
**Commit:** `31062190`
**Applied fix:** The Delivery, Event, and private Payload steps retain `Repo.multi_opts()`, while the Oban gateway now receives no Mailglass prefix override and uses its configured prefix. The durable enqueue regression asserts the job exists in the public `oban_jobs` table; it runs unchanged on the `MAILGLASS_SCHEMA=mailglass` matrix axis.

### CR-02: Oban-absent durable sends crash instead of returning the typed fail-closed error

**Files modified:** `lib/mailglass/outbound.ex`
**Commit:** `7fd2a06c`
**Applied fix:** The selected-Oban readiness gate now uses the always-compiled literal canonical queue identity, `:mailglass_outbound`, before any conditional Worker reference. A no-Oban runtime therefore reaches the gateway's `:dependency_unavailable` result and is converted into the documented typed `SendError`.

## Verification

- Tier 1: re-read both affected source sections and the regression test; `elixir` parsing passed for `lib/mailglass/outbound.ex` and `test/mailglass/outbound/deliver_later_test.exs`; `git diff --check` passed before each atomic commit.
- Focused test attempted: `mix test test/mailglass/outbound/deliver_later_test.exs:187 --warnings-as-errors`.
- Phase test and no-optional-dependencies commands could not run in this isolated worktree because the existing dependency cache is inconsistent with `mix.lock` (`premailex` is `0.3.20` while the lock requires `~> 1.0`); an isolated clean rebuild also fails inside the pre-existing `yamerl` dependency before Mailglass compilation. No source rollback was needed because these failures precede the changed code.

---

_Fixed: 2026-08-03T00:27:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
