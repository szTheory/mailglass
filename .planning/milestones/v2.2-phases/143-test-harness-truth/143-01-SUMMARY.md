---
phase: 143-test-harness-truth
plan: 01
subsystem: testing
tags: [ecto, sandbox, dbconnection, exunit-formatter, credo, harness-01, d-06, d-08, d-09, d-10, d-31]

# Dependency graph
requires: []
provides:
  - "Mailglass.TestSupport.SandboxOwnership.probe/1 — a genuinely read-only observation of the Ecto Sandbox pool's ownership mode via `:sys.get_state/1` on the DBConnection.Ownership.Manager process (looked up via the public `Ecto.Adapter.lookup_meta/1`), returning `:ok` on `:manual` or `{:leaked, mode}` otherwise. Never mutates the pool."
  - "Mailglass.TestSupport.SandboxOwnership.baseline_tables_present?/1 — a read-only `information_schema.tables` check for the three CI-log-named baseline relations, run through `Sandbox.unboxed_run/2` so a caller with no Sandbox checkout of its own can run it. Returns `true | {false, missing} | {:cannot_verify, sqlstate_or_term}`."
  - "Mailglass.TestSupport.SuiteTruthFormatter — a GenServer ExUnit formatter registered alongside `ExUnit.CLIFormatter` in test_helper.exs. At every `async: false` module's `:module_finished` boundary it inventories all three D-31 leak classes (pool-mode / config-schema-drift / baseline-teardown) in a fixed, commented order (C, then B, then A — B before A because a drifted schema would misattribute a Class A finding), records a violation record per class, and prints the accumulated ledger only under `MAILGLASS_SANDBOX_TRACE=1`."
  - "Three injectable seams (probe_fun, schema_fun, baseline_fun) on the formatter's state, mirroring `Mailglass.TestSupport.CitextProbe`'s `probe_fun:` idiom, so downstream plans (143-02..143-14) and this plan's own tests can drive every check synthetically with zero real DB/schema manipulation."
affects: [143-02, 143-03, 143-05, 143-06, 143-07, 143-08, 143-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read a GenServer's internal state via `:sys.get_state/1` when the only public API for the thing you need to observe is a write (`Sandbox.mode/2`) — confirmed empirically (leaked pool observed and left untouched; repeated reads idempotent) before relying on it, and documented as a version-pinned coupling to a `@moduledoc false` internal shape."
    - "`Sandbox.unboxed_run/2` as the sanctioned mechanism for a process with no Sandbox checkout of its own (a formatter's GenServer, not any single test) to run a genuinely read-only catalog query without an ownership error and without touching pool mode."
    - "Injectable-function seams (`probe_fun`/`schema_fun`/`baseline_fun`) on formatter state, built from a single `quiet_state/1` test helper so every unit test defaults to 'nothing wrong' and must deliberately override the one seam it exercises — makes it structurally hard for a future test to accidentally perform real DB/schema manipulation."

key-files:
  created:
    - test/support/sandbox_ownership.ex
    - test/support/suite_truth_formatter.ex
    - test/mailglass/test_support/suite_truth_formatter_test.exs
    - test/mailglass/test_support/sandbox_ownership_test.exs
  modified:
    - test/test_helper.exs

key-decisions:
  - "Rejected the plan's originally-specified probe implementation (`Sandbox.mode(repo, :manual)` matched by return value) after a coordinator checkpoint review proved it was vacuous: that call's catch-all clause (`manager.ex:161-172`) always replies `:ok` regardless of the pool's prior state, so `{:leaked, term}` was unreachable for the `{:shared, pid}` leak class this phase exists to observe, and the call itself unconditionally healed (masked) any real leak on every boundary. Replaced with a genuinely read-only `:sys.get_state/1` read on the ownership manager process."
  - "Detection and healing are fully separated for this plan: `probe/1` never mutates the pool, and no heal mechanism (opt-in or otherwise) was added in this plan at all — an explicit, separately-named, off-by-default heal step is deferred to Wave 2's `SandboxOwnership.checkout!/1`."
  - "`baseline_tables_present?/1` runs its query through `Sandbox.unboxed_run/2` rather than a bare `Ecto.Adapters.SQL.query/4` call, because the formatter's own GenServer process holds no Sandbox checkout — confirmed via a real experiment that the bare call raises `DBConnection.OwnershipError` from a foreign process while `unboxed_run/2` succeeds and leaves pool mode unchanged."
  - "Class B (`config_schema_drift`) is probed before Class A (`baseline_missing`) in the formatter's `:module_finished` handler, per the plan's explicit ordering requirement — a drifted `Config.schema()` would make the Class A query look at the wrong schema and misattribute the failure. Commented at the call site."
  - "All pre-existing (Task 1) formatter tests were rebuilt on a shared `quiet_state/1` helper when Task 2 added two more real-DB/real-config-reading default seams, so no existing test silently began performing real Postgres queries or `persistent_term` reads just because it predated those seams."

patterns-established:
  - "A probe that later turns out to be a write in disguise is a Rule 1 bug, not a design nuance — verify empirically against the real leaked state (not just plausible reasoning about return values) before trusting a 'detect' claim."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "SandboxOwnership.probe/1 observes a genuine, artificially-created {:shared, pid} Sandbox leak (reports {:leaked, {:shared, pid}}) without curing it — proven against the real Mailglass.TestRepo pool, not a synthetic stand-in"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/sandbox_ownership_test.exs#observes a genuine {:shared, pid} leak — reports it, does not cure it"
        status: pass
    human_judgment: false
  - id: D2
    description: "SuiteTruthFormatter inventories all three D-31 leak classes (pool_mode_leaked, config_schema_drift, baseline_missing) plus a per-class cannot_verify outcome at every async: false module's :module_finished boundary, in the required B-before-A order, via injectable seams"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/suite_truth_formatter_test.exs (13 tests: Class C/B/A + combined-boundary + suite-lifecycle describes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The formatter is registered alongside ExUnit.CLIFormatter in test_helper.exs (never via the --formatter flag), is silent by default, and a MAILGLASS_SANDBOX_TRACE=1 run prints the ledger with the same pass/fail exit status as the same run without the env var"
    requirement: "HARNESS-01"
    verification:
      - kind: other
        ref: "MAILGLASS_SANDBOX_TRACE=1 mix test test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors (prints ledger, exit 0) vs. the same command without the env var (no ledger output, exit 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "baseline_tables_present?/1's query executes correctly against the real, migrated schema and is safely callable from a process with no prior Sandbox checkout (the shape the formatter's own GenServer process is in), leaving pool mode unchanged"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/sandbox_ownership_test.exs#reports true for the real, migrated Mailglass.TestRepo schema; #baseline_tables_present?/1 is callable from a process with no prior checkout, and leaves pool mode unchanged"
        status: pass
    human_judgment: false
  - id: D5
    description: "No file's async attribute value changed (D-11); nothing was added to lib/; mix credo --strict and mix format --check-formatted stay green"
    requirement: "HARNESS-01"
    verification:
      - kind: other
        ref: "git diff --unified=0 -- test/ | grep -Ec '^[+-][^+-].*\\basync: (true|false)' — all matches are test names/comments, no case-template attribute changed; mix credo --strict (3825 mods/funs, 0 issues); mix format --check-formatted (exit 0)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-07-29
status: complete
---

# Phase 143 Plan 01: Test-Harness Truth — Observation Layer Summary

**A GenServer ExUnit formatter that inventories all three Ecto Sandbox leak classes (pool-mode, schema-config drift, baseline-table teardown) at every `async: false` module boundary via genuinely read-only probes — built as a tracer slice, then corrected mid-review when a coordinator checkpoint proved the first probe implementation was itself a silent auto-heal.**

## Performance

- **Duration:** ~55 min (includes one coordinator-directed correction cycle after the Task 1 checkpoint)
- **Started:** 2026-07-29T18:20:00Z (approx.)
- **Completed:** 2026-07-29T18:52:00Z
- **Tasks:** 2 (`type="tracer"`, `type="auto"`)
- **Files modified:** 5 (4 created, 1 modified), plus this SUMMARY

## Accomplishments

- `Mailglass.TestSupport.SandboxOwnership.probe/1` reads the Sandbox pool's ownership mode without mutating it, via `:sys.get_state/1` on the `DBConnection.Ownership.Manager` process — confirmed against a real, artificially-created `{:shared, pid}` leak that it reports `{:leaked, {:shared, pid}}` and leaves the leak in place.
- `Mailglass.TestSupport.SandboxOwnership.baseline_tables_present?/1` checks the three CI-log-named baseline relations via a read-only `information_schema.tables` query, run through `Sandbox.unboxed_run/2` so a process with no Sandbox checkout of its own (the formatter's own GenServer) can run it.
- `Mailglass.TestSupport.SuiteTruthFormatter` inventories Class C (pool-mode), Class B (config-schema drift), and Class A (baseline teardown) at every `async: false` module's `:module_finished` boundary, in the required B-before-A order, registered alongside `ExUnit.CLIFormatter` and silent unless `MAILGLASS_SANDBOX_TRACE=1`.
- Every check has an injectable seam (`probe_fun`, `schema_fun`, `baseline_fun`) so downstream plans and this plan's own 19 tests can drive every path — including the `:cannot_verify` outcome for each class — without real DB/schema manipulation.

## Task Commits

Each task was committed atomically, plus one coordinator-directed fix commit inserted between Task 1 and Task 2:

1. **Task 1: End-to-end "the suite observes its own pool hygiene" — one probe dimension only** - `65b8e0db` (feat)
2. **Coordinator fix: make the pool-mode probe genuinely read-only** - `c3548427` (fix — see Deviations)
3. **Task 2: Widen the boundary probe to all three leak classes** - `724235e3` (feat)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/support/sandbox_ownership.ex` - `probe/1` (read-only pool-mode observation via `:sys.get_state/1`) and `baseline_tables_present?/1` (read-only baseline-relation check via `Sandbox.unboxed_run/2`)
- `test/support/suite_truth_formatter.ex` - GenServer ExUnit formatter; three ordered checks (C, B, A) at `:module_finished`, injectable seams, silent-unless-traced ledger
- `test/test_helper.exs` - registers the formatter alongside `ExUnit.CLIFormatter`
- `test/mailglass/test_support/suite_truth_formatter_test.exs` - 13 synthetic-payload tests across all three classes plus suite lifecycle
- `test/mailglass/test_support/sandbox_ownership_test.exs` - 6 real-`Mailglass.TestRepo` regression tests (the genuine leak/heal cycle and the real baseline query)

## Decisions Made

See `key-decisions` in frontmatter. The load-bearing one: the plan's own Task 1 action text specified implementing `probe/1` via `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)` — a coordinator checkpoint review proved this call's catch-all clause always replies `:ok`, making the probe structurally incapable of ever reporting a leak while also silently healing every real one. Replaced with a `:sys.get_state/1` read, verified against a real leak before and after the fix (see Deviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, coordinator-reported] `probe/1` was a silent auto-heal, not an observation**

- **Found during:** Task 1 checkpoint review (before Task 2 began)
- **Issue:** The plan specified implementing `probe/1` via `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)`, matching its return value. `manager.ex:161-172`'s catch-all clause matches ANY current pool mode and always replies `:ok` — there is no input for which that call returns anything else. The coordinator reproduced this live: putting the pool in `{:shared, pid}` and calling the original `probe/1` returned `:ok`, and the leak was gone afterward (the call had healed it). Two fatal consequences: (a) `{:leaked, term}` was unreachable for the exact leak class HARNESS-01 exists to observe — the ledger would read `0 record(s)` forever; (b) the call ran at every `async: false` module boundary, healing (masking) any real leak — the phase goal explicitly forbids masking the mechanism it's building an instrument to expose.
- **Fix:** Rewrote `probe/1` to read the ownership manager's `:mode` field directly via `:sys.get_state/1` (no `GenServer.call`, no `handle_call` clause triggered, confirmed to mutate nothing). The manager pid is obtained via the public `Ecto.Adapter.lookup_meta/1`, the same lookup `Sandbox` uses internally. Verified live: a leaked `{:shared, pid}` pool now reports `{:leaked, {:shared, pid}}`, a second shared-mode acquisition attempt still raises the real `{:badmatch, :already_shared}` (proving the read did not heal it), and repeated reads are idempotent.
- **Files modified:** `test/support/sandbox_ownership.ex`, `test/support/suite_truth_formatter.ex` (updated the D-10 comment to reflect that no heal call exists in this task), `test/mailglass/test_support/sandbox_ownership_test.exs` (new file — the real leak/heal regression test)
- **Verification:** New regression test drives the real `Mailglass.TestRepo` pool into `{:shared, pid}` and asserts the probe reports it and does not cure it; `mix credo --strict`, `mix format --check-formatted`, and the silent-by-default/`MAILGLASS_SANDBOX_TRACE=1` pair all re-verified green afterward.
- **Committed in:** `c3548427`

**2. [Rule 2 - Missing critical functionality] Added `sandbox_ownership_test.exs` (not in the plan's `files_modified` list)**

- **Found during:** Task 1 checkpoint fix, extended in Task 2
- **Issue:** `SandboxOwnership.probe/1`'s core correctness claim ("observes a real leak without curing it") had no test against the real Sandbox/Postgres — only synthetic-payload coverage of the formatter that assumes the probe's contract is correct. The plan's own `143-PATTERNS.md` names this exact gap ("The mechanism-level regression test... needs a real `Mailglass.TestRepo` leak/heal cycle — that part has no analog").
- **Fix:** Created `test/mailglass/test_support/sandbox_ownership_test.exs`, a dedicated `async: false` unit-test file (sanctioned D-11 reason 1: pool-mode mutation) that drives the real pool into a leaked state and back, plus (Task 2) proves `baseline_tables_present?/1` executes correctly against the real migrated schema and is safely callable from a foreign process.
- **Files modified:** `test/mailglass/test_support/sandbox_ownership_test.exs` (new)
- **Verification:** All 6 tests pass; `mix credo --strict` and `mix format --check-formatted` unaffected.
- **Committed in:** `c3548427` (initial 2 tests), `724235e3` (2 more real-DB tests for Class A)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug found via coordinator checkpoint review, 1 Rule 2 missing-test-coverage gap named by the plan's own pattern map)
**Impact on plan:** Both were necessary for HARNESS-01's "empirically confirmed" bar to mean anything — an instrument that cannot observe its subject would have made the rest of Phase 143 (the mechanism account, the fix waves, the anti-vacuity floor) rest on a vacuous foundation. No scope creep: no new public functions beyond what the plan specified, no heal mechanism added.

## Issues Encountered

- An exploratory full-suite run (`mix test --exclude requires_workspace`, not part of the plan's required verification) surfaced 111-256 real, pre-existing failures in `Mailglass.SchemaPrefixHardeningTest` and left the shared `Mailglass.TestRepo` database in a state missing `public.mailglass_suppressions` — a real, pre-existing defect in that test module's own schema drop/recreate logic (unrelated to this plan's changes), consistent with the exact bug class Phase 143 exists to fix. Restored via `mix ecto.drop -r Mailglass.TestRepo --quiet && mix ecto.create -r Mailglass.TestRepo --quiet` before continuing. **Noted for the mechanism account (143-03):** the current formatter observes only inter-module boundaries (`:module_finished`); a module whose own internal test-to-test transitions corrupt-then-restore state within its own lifecycle (as `SchemaPrefixHardeningTest` appears to, given it self-manages schema drop/recreate) is invisible to this instrument by design — the ledger correctly reported `0 record(s)` for that run because nothing was wrong *at the boundaries it checks*, even though 111+ failures occurred *within* module bodies. This is not a defect in this plan's deliverable; it is the documented scope of a boundary-only probe, and downstream plans (143-03 mechanism account, 143-05/06/07 fixes) should account for it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The observation layer plans 143-02 through 143-14 depend on (`SuiteTruthFormatter`, `SandboxOwnership.probe/1`, `SandboxOwnership.baseline_tables_present?/1`, and the `probe_fun`/`schema_fun`/`baseline_fun` injectable seams) is built, real-leak-verified, and committed.
- **Flag for 143-03 (mechanism account):** the boundary-only observation scope (see Issues Encountered) should be stated explicitly in the written mechanism account so a reader doesn't mistake "ledger reported 0 records" for "no leak occurred" — the two are not equivalent for a module whose corruption is fully internal to its own test-to-test lifecycle.
- **Residual risk carried forward (already documented in `sandbox_ownership.ex`'s moduledoc, flagged again here per coordinator note):** `probe/1`'s `:sys.get_state/1` read couples to `db_connection`'s private `Manager` state shape (`%{mode: ...}`, `@moduledoc false`). It fails loud via a `rescue` → `:cannot_verify` rather than silently reporting green, which is the correct failure direction, but a future `db_connection` version bump could still change that internal shape. Worth one line in 143-03's mechanism account.
- No blockers for Wave 2 (fix + guard) or Wave 3 (anti-vacuity + rename) plans.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 6 created/modified files confirmed present on disk; all 3 task/fix commit hashes (`65b8e0db`, `c3548427`, `724235e3`) confirmed present in `git log --oneline --all`.
