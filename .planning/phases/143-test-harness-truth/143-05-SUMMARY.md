---
phase: 143-test-harness-truth
plan: 05
subsystem: testing
tags: [ecto, sandbox, dbconnection, exunit, harness-01, d-06, d-07]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 04)
    provides: "Mailglass.TestSupport.SandboxOwnership.checkout!/1, unsandboxed_module/1, unsandboxed/2, assert_manual!/2,3, live_holder/0,1, LeakError — the sanctioned acquire/release door this plan routes seven call sites through, and probe/1 (read-only, unchanged)"
provides:
  - "Both confirmed leak windows closed by construction: data_case.ex (control, unchanged behaviour) and mailer_case.ex's ninety-line acquire-to-registration window now route through checkout!/1, whose release is registered on the statement immediately after acquisition."
  - "webhook_idempotency_convergence_test.exs — the site the CI log caught in the act — migrated to checkout!/1; both its acquire-to-probe window and its TRUNCATE/clear window now sit below a registered release."
  - "schema_axis_boot_order_test.exs's bare Sandbox.checkout/1 migrated to checkout!/1 (RESEARCH.md Open Question 4 resolved: migrate, not allowlist) — the connection is now released deterministically via a registered on_exit, not by Ecto auto-releasing on owner-process death."
  - "Four raw Sandbox.mode(repo, {:shared, self()}) no-op calls deleted (mailer_case.ex x2, deliver_many_test.exs, deliver_later_test.exs) with corrected comments; deletion proven behaviour-preserving via an Oban-tagged before/after comparison (identical 18 test names, 0 failures) plus new mailer_case_test.exs assertions checking the *effect* the deleted calls were supposed to provide."
  - "Mailglass.TestSupport.SandboxOwnership.checkout!/1 gained optional :settle_attempts / :settle_interval_ms (default 30 / 5ms, unchanged) — a Rule 1 fix discovered while verifying the webhook_idempotency_convergence_test.exs migration: assert_manual!/3's default ~150ms bound is too tight for a caller whose own workload does heavy pool churn before releasing."
affects: [143-06, 143-08, 143-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A caller whose workload does heavy pool churn before releasing (many transactions through a shared connection) can widen SandboxOwnership.checkout!/1's release-verification settle window via :settle_attempts/:settle_interval_ms — the same bounded-retry pattern from 143-04, made configurable per-caller instead of hardcoded, so heavy callers get a wider ceiling without loosening the default for everyone else."

key-files:
  created: []
  modified:
    - test/support/data_case.ex
    - test/support/mailer_case.ex
    - test/support/sandbox_ownership.ex
    - test/mailglass/properties/webhook_idempotency_convergence_test.exs
    - test/mailglass/schema_axis_boot_order_test.exs
    - test/mailglass/outbound/deliver_many_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - test/mailglass/mailer_case_test.exs

key-decisions:
  - "schema_axis_boot_order_test.exs's bare Sandbox.checkout/1 is migrated to checkout!/1, not allowlisted — resolving RESEARCH.md Open Question 4 as the plan's action text required. An allowlist entry is a permanent exception a future reader copies; migrating costs nothing and is what lets :checkout join plan 143-08's Credo forbidden-function list."
  - "deliver_many_test.exs and deliver_later_test.exs keep their Sandbox.mode(repo, :manual) reverts in place (healing calls, not leak sites — reverse on_exit order means they run before DataCase's own release). A comment on each records the hand-off: if plan 143-08's Credo check flags them, migrate there alongside the rest of the :auto-mode inventory."
  - "checkout!/1's :settle_attempts/:settle_interval_ms default to the existing 30/5ms (~150ms) bound — unchanged for every caller except webhook_idempotency_convergence_test.exs, which explicitly opts into a wider 600/10ms (~6s) bound. This keeps the fix scoped to the one caller that needs it rather than loosening verification globally."
  - "The settle-window Rule 1 fix and its one caller (webhook_idempotency_convergence_test.exs) are committed together, separate from Task 2's main migration commit — the option is meaningless (and the code would not run correctly) without the mechanism it depends on existing first."

patterns-established:
  - "assert_manual!/3's bounded settle-window pattern (143-04) is now per-caller configurable, not a single global constant — a caller doing unusually heavy pool churn before releasing widens its own ceiling via checkout!/1's pass-through options rather than the fix requiring every caller's tolerance to change."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "data_case.ex and mailer_case.ex route Sandbox acquisition through SandboxOwnership.checkout!/1; mailer_case.ex's ninety-line acquire-to-registration window is closed by construction (release registered immediately after acquisition, before CitextProbe.run/1, Fake.checkout(), PubSub.subscribe, or start_supervised!({Oban, ...}))"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/mailer_case_test.exs test/support/webhook_case_test.exs --warnings-as-errors (13 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix test --only oban --warnings-as-errors, run on the parent commit and after the four deletions: identical 18 test names, 0 failures both times"
        status: pass
    human_judgment: false
  - id: D2
    description: "webhook_idempotency_convergence_test.exs (the CI-log-confirmed leak site) migrated to checkout!/1 with the same shared: true and 10-minute ownership_timeout preserved; both its acquire-to-probe and TRUNCATE/clear windows close. schema_axis_boot_order_test.exs's bare checkout migrated (not allowlisted). deliver_many_test.exs / deliver_later_test.exs's raw shared-mode no-ops deleted with comments corrected and the :manual healing revert left in place."
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors (1 property, 0 failures, run twice consecutively)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass/schema_axis_boot_order_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors (22 tests, 0 failures, combined and individually)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The four deletions are proven behaviour-preserving: an Oban-tagged before/after comparison shows identical test names and 0 failures, and new mailer_case_test.exs assertions (Tests 11-13) check the pool is genuinely shared (via SandboxOwnership.live_holder/1, not Sandbox.mode/2) and reachable from another process, both on the Oban setup path and after set_mailglass_global/0, plus a text tripwire against the deleted pattern reappearing under test/support/"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/mailer_case_test.exs Tests 11-13 (11 -> 14 tests, +3); mix test --only oban --warnings-as-errors after all 143-05 changes: 19 tests (18 original names unchanged + 1 new intentional Oban test), 0 failures"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-07-29
status: complete
---

# Phase 143 Plan 05: Route the Harness Through the Door Summary

**The two confirmed Class C leak windows (mailer_case.ex, webhook_idempotency_convergence_test.exs) are closed by construction via `SandboxOwnership.checkout!/1`, the bare `schema_axis_boot_order_test.exs` checkout is migrated rather than allowlisted, and all four discarded `:already_shared` no-op mode calls are deleted with their comments corrected — plus a genuine Rule 1 fix widening the release-verification settle window for a heavy-churn caller the migration itself surfaced.**

## Performance

- **Duration:** ~55 min (includes empirical root-cause investigation of a reproducible LeakError under the property test's real workload)
- **Tasks:** 3 (`type="auto"`)
- **Files modified:** 8 (7 planned + `test/support/sandbox_ownership.ex`, a Rule 1 deviation)

## Accomplishments

- `test/support/data_case.ex` and `test/support/mailer_case.ex` both acquire their Sandbox owner via `SandboxOwnership.checkout!/1`. `mailer_case.ex`'s ninety-line window (acquire at the old `:93` → `CitextProbe.run/1` → `Fake.checkout()` → PubSub subscribe → `start_supervised!({Oban, ...})`) is closed by construction: the release is registered immediately after acquisition, so every one of those statements now sits below a registered release.
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — the site the CI log caught in the act — is migrated the same way, preserving the 10-minute `ownership_timeout` exactly. Both its acquire-to-probe window and its TRUNCATE/clear window close.
- `test/mailglass/schema_axis_boot_order_test.exs`'s bare `Sandbox.checkout/1` is migrated to `checkout!/1` (not allowlisted), resolving RESEARCH.md Open Question 4 as the plan required.
- Four raw `Sandbox.mode(repo, {:shared, self()})` no-op calls are deleted (`mailer_case.ex` x2 — the Oban setup path and `set_mailglass_global/0` — plus `deliver_many_test.exs` and `deliver_later_test.exs`), each with a corrected comment stating the truth: the pool was already shared with a live owner, so `db_connection`'s ownership manager (`manager.ex:148-159`) replied `:already_shared` and the call changed nothing.
- The two `:manual` reverts in `deliver_many_test.exs`/`deliver_later_test.exs` are left in place (they heal, they don't leak — reverse `on_exit` order runs them before `DataCase`'s own release) with a comment recording the hand-off to plan 143-08's Credo check.
- The four deletions are proven behaviour-preserving two ways: (1) an Oban-tagged subset comparison (`--only oban`) on the parent commit and after the deletions shows identical test names and 0 failures; (2) three new `mailer_case_test.exs` tests assert the *effect* the deleted calls were supposed to provide (pool genuinely shared via `SandboxOwnership.live_holder/1`, reachable from another process) from a real `@tag oban: :inline` module, both before and after calling `set_mailglass_global/0` directly — plus a text tripwire against the pattern reappearing under `test/support/`.
- **Rule 1 fix found while verifying Task 2:** `assert_manual!/3`'s default ~150ms settle bound (tuned in 143-04 against a lightweight scenario) was empirically too tight for `webhook_idempotency_convergence_test.exs`'s real 1000-iteration workload — `checkout!/1` gained optional `:settle_attempts`/`:settle_interval_ms` (default unchanged) so this one heavy caller can widen its own ceiling. See Deviations.

## Task Commits

Each task was committed atomically, plus one Rule-1 fix commit discovered mid-Task-2:

1. **Task 1: Route both case templates through `checkout!/1`** - `0c1c1cfd` (feat)
2. **Task 2: Close the confirmed leak site and the remaining raw call sites** - `daa2a09b` (feat)
3. **Rule 1 fix: widen `SandboxOwnership`'s release-verification settle window for heavy-churn callers** - `b1a17ec6` (fix — see Deviations)
4. **Task 3: Prove the four deletions were behaviour-preserving** - `ff363c79` (test)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/support/data_case.ex` - acquisition swapped from a direct `start_owner!`/`on_exit(stop_owner)` pair to `SandboxOwnership.checkout!/1`. Only the call path changed.
- `test/support/mailer_case.ex` - acquisition routed through `checkout!/1`; the now-redundant `Sandbox.stop_owner/1` removed from `on_exit`; two raw `{:shared, self()}` mode calls deleted with corrected comments.
- `test/support/sandbox_ownership.ex` - `checkout!/1` gained optional `:settle_attempts`/`:settle_interval_ms` (default 30/5ms, unchanged), forwarded to `assert_manual!/3`. Rule 1 fix, not in the plan's original `files_modified` list — see Deviations.
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` - acquisition routed through `checkout!/1` (with a widened settle window); the file's own `on_exit` no longer calls `stop_owner`.
- `test/mailglass/schema_axis_boot_order_test.exs` - bare `Sandbox.checkout/1` migrated to `checkout!/1`.
- `test/mailglass/outbound/deliver_many_test.exs` / `deliver_later_test.exs` - raw shared-mode no-op deleted, comment corrected, `:manual` revert left in place with a hand-off comment.
- `test/mailglass/mailer_case_test.exs` - grew from 11 to 14 tests: Tests 11-12 (Oban-path and `set_mailglass_global/0` no-op proofs via `live_holder/1`) and Test 13 (text tripwire against the deleted pattern reappearing under `test/support/`).

## Decisions Made

See `key-decisions` in frontmatter. The four load-bearing ones: (1) `schema_axis_boot_order_test.exs`'s bare checkout is migrated, not allowlisted; (2) the two `:manual` reverts in `deliver_many_test.exs`/`deliver_later_test.exs` stay as-is, with the migration decision explicitly deferred to plan 143-08's Credo check; (3) `checkout!/1`'s new settle-window options default to the unchanged 150ms bound and are opted into by exactly one caller; (4) the settle-window fix and its one caller are committed together, separate from Task 2's main migration commit, since the option is inert without the underlying mechanism.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `assert_manual!/3`'s default settle bound was too tight for `webhook_idempotency_convergence_test.exs`'s real workload**

- **Found during:** Task 2, running the required `mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` verification.
- **Issue:** The migrated property test failed reproducibly with `SandboxOwnership.LeakError`: after `checkout!/1`'s `on_exit` called `stop_owner/1` (which returned `:ok`, and `Process.alive?(owner)` was confirmed `false`), `assert_manual!/3`'s probe still observed `{:shared, same_pid}` past its ~150ms bound (30 attempts x 5ms). First suspected as external contention from another agent's concurrent test run sharing the same local Postgres instance (confirmed as a real, separate factor — `too_many_connections` errors observed from a different worktree's idle pool) — but the failure reproduced identically even after that contention cleared. Direct instrumentation confirmed the owner had genuinely terminated but `db_connection`'s ownership manager (`manager.ex`) took 564ms-1131ms across repeated clean runs to process the `:DOWN` message and reset the mode to `:manual` — the same benign, bounded propagation delay `assert_manual!/3`'s moduledoc already documents (143-04), just under a heavier workload (up to 1000 property iterations, each doing real DB work through the shared pool) than the lightweight scenario the original 150ms bound was tuned against.
- **Fix:** `checkout!/1` gained optional `:settle_attempts`/`:settle_interval_ms` (default 30/5ms, unchanged for every other caller — none of the other six migrated call sites use non-default values). `webhook_idempotency_convergence_test.exs` passes `settle_attempts: 600, settle_interval_ms: 10` (a 6s bound, ~5x the worst observed convergence time). A release that genuinely never converges within its caller's bound still raises `LeakError` exactly as before — this widens the ceiling for one heavy caller, it does not weaken the check.
- **Files modified:** `test/support/sandbox_ownership.ex`, `test/mailglass/properties/webhook_idempotency_convergence_test.exs`
- **Verification:** The property test passed consistently across repeated clean runs (0 failures each time) after the fix; `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted` all re-verified green.
- **Committed in:** `b1a17ec6`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug, discovered empirically via a reproducible failure and root-caused via direct instrumentation before fixing)
**Impact on plan:** Necessary for the migrated `webhook_idempotency_convergence_test.exs` (Task 2's own required file) to pass its own verification. No scope creep — the new options default to the exact prior 150ms behavior for every other caller; only the one file whose real workload needed a wider bound opts into one.

## Issues Encountered

- **Two literal acceptance-criteria greps produced false-positive matches from required comment rewrites, not from any actual `async:` value change or reintroduction of the deleted call pattern.** The plan's action text requires rewriting the pre-existing comments above the four deleted raw mode calls (they "asserted a guarantee the code did not provide"); the *removed* lines of those old comments contained the literal substrings `async: false` and `Sandbox.mode(... {:shared, self()} ...)` as English prose describing the (unchanged) behavior, which a blunt textual grep over the diff cannot distinguish from an actual tag/call change. Verified explicitly, not merely asserted: (1) `git diff -- <each of the six migrated files>` shows zero changes to any `use ..., async:` or `@moduletag async:` line — confirmed file-by-file; the only new `async:` declaration in the whole plan diff is on `mailer_case_test.exs`'s brand-new `Mailglass.MailerCaseObanGlobalTest` module, which Task 3 explicitly requires ("from a module that goes through the Oban path") and which necessarily declares `async: false` for Oban's global-state requirement — not a change to an existing module. (2) The two `Sandbox\.mode\(.*\{:shared, self\(\)\}` diff matches are both `-` (deletion) lines from the removed original comments in `mailer_case.ex`, not reintroductions — the acceptance criterion's own grep against the *files themselves* (not the diff) confirms 0 occurrences in both `mailer_case.ex` and the two `deliver_*_test.exs` files, and Test 13's tripwire makes this permanently checked going forward.
- **`mix test --only oban --warnings-as-errors` cannot literally exit 0**, for a reason unrelated to this plan: `test/mailglass/upgrade_v2_schema_migration_test.exs:24` has a pre-existing unused-module-attribute warning (`@emitted_body` — dead because the code actually uses the nested submodule's own `@emitted` copy). Confirmed identical on the parent commit before making any 143-05 changes, and that file is not in this plan's scope. Logged to `.planning/phases/143-test-harness-truth/deferred-items.md` per the executor's SCOPE BOUNDARY rule rather than fixed. The substantive claim the criterion protects — test count, names, and failure count match before/after — was verified explicitly (see coverage D1/D3 above), independent of the exit code.

## User Setup Required

None - no external service configuration required. Postgres reachability (`scripts/preflight_postgres.sh`) was verified before each Task 1/2/3 DB-touching verification step, and re-checked after the two connection-contention incidents encountered while debugging the Rule 1 fix (both resolved by waiting for concurrent unrelated processes to release connections — no destructive action taken).

## Next Phase Readiness

- Seven files now route Sandbox acquisition through `SandboxOwnership`; both confirmed leak windows are closed by construction, not by statement reordering. `checkout!/1`'s public surface is unchanged for every caller except the one that explicitly opts into a wider settle window.
- `schema_axis_boot_order_test.exs`'s migration decision (migrate, not allowlist) and `deliver_many_test.exs`/`deliver_later_test.exs`'s explicit `:manual`-revert hand-off comments are both load-bearing for plan 143-08's Credo forbidden-function-list scoping.
- `deferred-items.md` now exists for phase 143, carrying one out-of-scope pre-existing warning (`upgrade_v2_schema_migration_test.exs:24`) for a future cleanup pass.
- No blockers. All four task/fix commits are green under `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`, and the full set of touched test files.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 8 modified files confirmed present on disk with the expected changes. All 4 commit hashes
(`0c1c1cfd`, `daa2a09b`, `b1a17ec6`, `ff363c79`) confirmed present in `git log --oneline`.
