---
phase: 143-test-harness-truth
plan: 04
subsystem: testing
tags: [ecto, sandbox, dbconnection, exunit, harness-01, d-06, d-11, d-17]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 01)
    provides: "SandboxOwnership.probe/1 and baseline_tables_present?/1 — the read-only boundary-probe instrument this plan's checkout!/1 and assert_manual!/2 build on top of, unchanged"
  - phase: 143-test-harness-truth (plan 03)
    provides: "143-MECHANISM.md — the confirmed acquire/raise/lost-release causal chain (mailer_case.ex:93->99, webhook_idempotency_convergence_test.exs:52->58) this plan's checkout!/1 makes structurally impossible to re-type, and the two D-04 falsifiable predictions this plan's regression test pins"
provides:
  - "Mailglass.TestSupport.SandboxOwnership.checkout!/1 — the one sanctioned acquire/release door. Registers ExUnit.Callbacks.on_exit on the statement immediately following start_owner!/2, so a raise anywhere below still releases the owner; matches stop_owner/1's return; verifies the release (not merely assumes it) via assert_manual!/2 when the checkout was shared."
  - "Mailglass.TestSupport.SandboxOwnership.unsandboxed_module/1 — a setup callback switching the pool to pool-wide :auto with the revert registered first (reverse on_exit order preserves the nine :auto files' baseline-restore semantics, load-bearing for plan 143-06)."
  - "Mailglass.TestSupport.SandboxOwnership.unsandboxed/2 — wraps Sandbox.unboxed_run/2 as the preferred forward idiom for a single committed, non-transactional write."
  - "Mailglass.TestSupport.SandboxOwnership.assert_manual!/2,3 — raises LeakError (naming the caller) when the pool is not :manual; bounded (~150ms) settle-window retry absorbs stop_owner/1's benign manager-propagation delay without masking a genuine leak; injectable :probe_fun seam."
  - "Mailglass.TestSupport.SandboxOwnership.live_holder/0,1 — the current shared-owner pid keyed on pool mode, not agent liveness."
  - "Mailglass.TestSupport.SandboxOwnership.LeakError — the composed error plan 143-08's Wave-3 signature classifier must count alongside the raw {:badmatch, :already_shared} term, or ROADMAP criterion 3 passes vacuously."
  - "Both async: false sanctioned reasons (pool-mode mutation, committed non-transactional DB state) are now mechanical: checkout!(shared: true) and unsandboxed_module/1 each raise from a module whose async tag is true, in the I-12 guard's microcopy shape."
  - "test/mailglass/test_support/sandbox_ownership_test.exs — a deterministic, mechanism-level regression test pinning all four D-04 causal-chain branches (leak reproduces / shared: false survives / stop_owner heals / mode(:auto) heals) plus four helper-contract behaviors (release-first, async guards, assert_manual!, live_holder), against the real Mailglass.TestRepo pool."
affects: [143-05, 143-06, 143-07, 143-08, 143-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Register the release callback on the statement immediately following acquisition, before any other setup work — the acquire/release ordering bug's structural fix, generalized from data_case.ex's own control idiom."
    - "A bounded settle-window retry (fixed attempt count x fixed interval, defaulting to a ceiling comfortably above the empirically observed real-world propagation delay) absorbs a benign async-consistency gap between a resource's own confirmed termination and a downstream supervisor's derived state change, without masking a genuine, persistent fault — the fault still raises once the bound is exhausted."
    - "ExUnit.OnExitHandler.run(pid, timeout) + ExUnit.OnExitHandler.register(pid) forces a test's on_exit chain to execute synchronously mid-test (instead of waiting for the test to end), enabling a single, self-contained regression test to prove an on_exit-ordering invariant that would otherwise only be observable across two separate tests."
    - "A plain module exposing __ex_unit__(:config) (not `use ExUnit.Case`) is a synthetic double for 'a module ExUnit considers async: true/false' — drives a real detection function's logic through an injectable seam without registering a real (empty) test module with the live ExUnit.Server."

key-files:
  created: []
  modified:
    - test/support/sandbox_ownership.ex
    - test/mailglass/test_support/sandbox_ownership_test.exs

key-decisions:
  - "checkout!/1 detects the calling test module's async status via Process.get(:\"$process_label\") (the {module, test_name} pair ExUnit's own Runner sets before setup runs) plus that module's compiler-generated __ex_unit__(:config).async? — a deliberate, version-pinned coupling to ExUnit internals, confirmed empirically against this repo's Elixir 1.19.5, in the same spirit as probe/1's :sys.get_state/1 coupling. Documented as an accepted limitation: if the calling process cannot be resolved, the guard fails open (not closed) — it is a convenience check, not the enforcement backbone (the Credo check in plan 143-08 is)."
  - "assert_manual!/3 retries up to 30 times at 5ms intervals (~150ms bound) before raising LeakError. Found while writing the mechanism regression test: calling assert_manual! in the same breath as stop_owner/1 returning (exactly what checkout!/1's on_exit does) intermittently observes a transient {:shared, pid} that clears within single-digit milliseconds — GenServer.stop/1 confirms the owner Agent terminated, but the ownership manager's unshare/2 only runs one message-passing hop later. Reproduced deterministically (5/5 failing runs before the fix, 5/5 passing after) against the real Mailglass.TestRepo pool. The bound is a ceiling, not a retry-until-green loop: a mode that has not healed within it still raises exactly as before."
  - "test/mailglass/test_support/sandbox_ownership_test.exs keeps async: false, unchanged from the file plan 143-01 created — the plan's own action text said 'async: true' in one sentence and 'tag the module so it cannot run concurrently with anything that shares the pool' in the next, which are in direct tension for a file that deliberately corrupts pool-global state. D-11/D-31 (this phase changes no file's async value) settle it decisively in favor of the already-committed async: false."
  - "The plan's acceptance criterion 'grep -Ec rescue test/support/sandbox_ownership.ex is 0' is not literally satisfiable without violating the same task's explicit instruction 'do not change probe/1's or baseline_tables_present?/1's existing behavior' — both of those pre-existing functions rescue for legitimate, unrelated fail-loud (:cannot_verify) reasons, not to mask the {:badmatch, :already_shared} leak. Read the acceptance criterion as 'no new `rescue MatchError`' (which the file satisfies, per the plan's own hard prohibition) rather than literally zero rescue clauses in the whole file; the actual count is 2, both pre-existing and untouched."

patterns-established:
  - "A check that cannot observe its subject reports failure, never silence or green (carried forward from Phase 143-01) — extended here: a check that observes its subject through a genuinely transient, benign propagation delay retries within a hard bound rather than either (a) reporting a false leak on the first read, or (b) retrying forever and thereby being unable to ever report a real leak."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "SandboxOwnership.checkout!/1 registers the release callback on the statement immediately following acquisition (structurally verified by reading the function body); every Ecto return value it touches is matched; a raise anywhere after the registration still releases the owner, proven live by forcing checkout!/1's on_exit chain to run mid-test via ExUnit.OnExitHandler.run/2 while a later-registered on_exit deliberately raises first"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/sandbox_ownership_test.exs#checkout!/1's release still runs even when a later-registered on_exit raises first (@tag :release_first)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A leaked live shared owner makes the next start_owner!(shared: true) fail with the verbatim nested {:error, {{:badmatch, :already_shared}, stacktrace}} term (not a message string); shared: false survives it; stop_owner/1 and mode(repo, :auto) each heal it — all four branches asserted against the real Mailglass.TestRepo in one deterministic mechanism-level regression test"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/sandbox_ownership_test.exs (4 mechanism-branch tests: leak reproduces / shared: false survives / stop_owner heals / mode(:auto) heals)"
        status: pass
    human_judgment: false
  - id: D3
    description: "checkout!(shared: true) and unsandboxed_module/1 each raise (in the I-12 guard's microcopy shape) when called from a module whose async tag is true; SandboxOwnership.LeakError exists and is the composed error the Wave-3 classifier must count alongside the raw badmatch term; the async policy (three sanctioned reasons, cross-process delivery explicitly excluded) and unsandboxed_module/1's reverse-on_exit-order guarantee are documented in the moduledoc"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/mailglass/test_support/sandbox_ownership_test.exs (async guard tests, assert_manual!/LeakError tests, live_holder test) — 13 tests total, 0 failures across 5 consecutive runs and via --only release_first (exactly 1 test)"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-07-29
status: complete
---

# Phase 143 Plan 04: The Sanctioned Sandbox Ownership Door Summary

**`Mailglass.TestSupport.SandboxOwnership.checkout!/1` makes the confirmed acquire/raise/lost-release ordering bug structurally impossible to re-type, backed by a deterministic mechanism-level regression test that pins all four causal-chain branches and four helper-contract behaviors against the real `Mailglass.TestRepo` pool — plus a genuine, empirically-reproduced Rule 1 fix to a benign async settle-delay in the new `assert_manual!/3` discovered while writing that test.**

## Performance

- **Duration:** ~40 min (includes empirical debugging of a real timing race with a standalone `mix run` script and a throwaway ExUnit test file)
- **Started:** 2026-07-29T22:50:00Z (approx.)
- **Completed:** 2026-07-29T23:31:00Z
- **Tasks:** 2 (`type="auto"`)
- **Files modified:** 2, plus this SUMMARY

## Accomplishments

- `Mailglass.TestSupport.SandboxOwnership` now exposes the full sanctioned door: `checkout!/1`, `unsandboxed_module/1`, `unsandboxed/2`, `probe/1` (unchanged), `assert_manual!/2,3`, `live_holder/0,1`, and `LeakError`, each with `@spec` and `@doc`.
- `checkout!/1`'s non-negotiable invariant — release registered on the statement immediately following acquisition — is structurally verified by reading the function body and behaviorally proven by a real regression test that forces the on_exit chain to run mid-test (`ExUnit.OnExitHandler.run/2`) while a later-registered callback deliberately raises first.
- Both mechanical async: false guards (`checkout!(shared: true)`, `unsandboxed_module/1`) raise in the I-12 guard's exact microcopy shape when called from an `async: true` module, detected via a documented, deliberate coupling to ExUnit internals (`Process.get(:"$process_label")` + `__ex_unit__(:config).async?`), with an injectable `:calling_module_fun` seam so the raise path is testable via a synthetic fixture double rather than a real async module.
- `LeakError` is defined and its moduledoc states, explicitly, why plan 143-08's Wave-3 classifier must count it alongside the raw `{:badmatch, :already_shared}` term.
- All four D-04 mechanism branches (leak reproduces / `shared: false` survives / `stop_owner/1` heals / `mode(:auto)` heals) are pinned against the real pool in `test/mailglass/test_support/sandbox_ownership_test.exs`, with the leak-reproduction assertion matching the verbatim nested failure term structurally, never by message string.
- **Rule 1 bug found and fixed while writing the test:** `assert_manual!/2` (as first implemented in Task 1) intermittently and reproducibly reported a leak immediately after a genuinely successful `stop_owner/1` — a real, empirically-confirmed async propagation gap between the owner Agent's confirmed termination and the ownership manager's own derived `unshare/2`. Fixed with a bounded (~150ms) settle-window retry in `assert_manual!/3` that absorbs the benign delay without masking a real, persistent leak.
- Verified the full regression file green across 5 consecutive runs and via `--only release_first` (exactly 1 test), plus `mix test test/mailglass/test_support/` (32 tests) and `mix test test/scripts/` (49 tests) both stay green.

## Task Commits

Each task was committed atomically, plus one Rule-1 fix commit discovered mid-Task-2:

1. **Task 1: Complete the `SandboxOwnership` public surface and its async-policy guards** - `da100ba6` (feat)
2. **Rule 1 fix: absorb `stop_owner/1`'s benign manager-settle delay in `assert_manual!`** - `d5f84874` (fix — see Deviations)
3. **Task 2: Deterministic mechanism-level regression test against the real repo** - `44f127c8` (test)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/support/sandbox_ownership.ex` - grew from 158 to ~380 lines: `checkout!/1`, `unsandboxed_module/1`, `unsandboxed/2`, `assert_manual!/2,3` (with the settle-window retry), `live_holder/0,1`, `LeakError`, both async guards, and the expanded moduledoc. `probe/1` and `baseline_tables_present?/1` are byte-for-byte unchanged from plan 143-01.
- `test/mailglass/test_support/sandbox_ownership_test.exs` - grew from 6 tests (143-01) to 13: the 4 D-04 mechanism branches, the release-first invariant, both async guards, `assert_manual!`'s two raise paths (real leak + injectable synthetic), and `live_holder/0`, plus the 3 pre-existing `probe/1`/`baseline_tables_present?/1` tests carried forward unchanged.

## Decisions Made

See `key-decisions` in frontmatter. The four load-bearing ones: (1) `checkout!/1`'s async-module detection couples deliberately to `Process.get(:"$process_label")` + `__ex_unit__(:config)`, documented as an accepted-limitation, fail-open convenience check (the Credo check in plan 143-08 is the fail-closed layer); (2) `assert_manual!/3`'s bounded settle-window retry, added after empirically reproducing a real timing race 5/5 times; (3) the regression test file keeps `async: false` (unchanged from 143-01), resolving a tension in the plan's own action text via D-11/D-31's explicit "changes no file's async value"; (4) the plan's literal "grep rescue is 0" acceptance criterion is read as "no new `rescue MatchError`," since literal zero would require altering `probe/1`'s pre-existing, unrelated fail-loud rescues that the same task explicitly forbids touching.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `assert_manual!/2` intermittently reported a leak immediately after a genuine, successful `stop_owner/1`**

- **Found during:** Task 2, while writing the "stop_owner/1 heals a leaked shared owner" regression test
- **Issue:** The test failed consistently (5/5 runs, same PID, same seed) with `SandboxOwnership.probe(Mailglass.TestRepo)` still reporting `{:leaked, {:shared, pid}}` immediately after `Sandbox.stop_owner(owner)` returned `:ok` and `Process.alive?(owner) == false`. A standalone throwaway ExUnit test isolated the cause: `GenServer.stop/1` (which `stop_owner/1` calls) confirms only that the owner Agent itself has terminated; `db_connection`'s ownership manager unshares the pool one message-passing hop later, after its own monitor on the checkout proxy delivers the `:DOWN`. A 50ms `Process.sleep` before the next probe reliably converged to `:ok`. Left unfixed, this meant `checkout!/1`'s own on_exit (which calls `assert_manual!` immediately after `stop_owner`) could intermittently raise a false-positive `LeakError` for an entirely healthy release — exactly the kind of "check that cannot observe its subject reliably" defect this milestone exists to eliminate, just in the opposite direction (false alarm instead of false green).
- **Fix:** `assert_manual!/3` now retries its probe up to 30 times at 5ms intervals (~150ms bound, ~3x the ~50ms observed live) before raising `LeakError`. Documented in the moduledoc as a bounded settle window, not a retry-until-green loop: a genuine, persistent leak still raises exactly as before once the bound is exhausted.
- **Files modified:** `test/support/sandbox_ownership.ex`
- **Verification:** Re-ran the full regression file 5 consecutive times post-fix — 13/13 tests pass every time (previously 12/13, same failure every time). `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted` all re-verified green.
- **Committed in:** `d5f84874`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug, discovered empirically via a reproducible 5/5 failure before the fix and a reproducible 5/5 pass after)
**Impact on plan:** Necessary for `checkout!/1`'s own on_exit-time verification to be trustworthy rather than flaky. No scope creep — no new public function was added beyond what Task 1 already specified; the fix only bounds an existing function's probe loop.

## Issues Encountered

- The plan's Task 2 action text says "Use `use ExUnit.Case, async: true`" in one sentence and "tag the module so it cannot run concurrently with anything that shares the pool" in the very next — a direct tension for a file that deliberately corrupts pool-global state. Resolved in favor of the already-committed `async: false` (from plan 143-01), which D-11/D-31 require unchanged, and which is the only safe choice given the file's own pool-mode mutation (see `key-decisions`).
- The plan's acceptance criterion "`grep -Ec 'rescue' test/support/sandbox_ownership.ex` is 0" conflicts with the same task's explicit "do not change `probe/1`'s or `baseline_tables_present?/1`'s existing behavior" — both pre-existing functions legitimately `rescue` for unrelated fail-loud reasons. Resolved by leaving those two rescues untouched (actual count: 2) and adding zero new `rescue` clauses, consistent with the phase's hard prohibition on rescuing the badmatch specifically.

## User Setup Required

None - no external service configuration required. This plan does require a reachable PostgreSQL instance for `Mailglass.TestRepo` (verified via `scripts/preflight_postgres.sh` before Task 2's real-repo regression test) — the precondition held throughout.

## Next Phase Readiness

- The one sanctioned door (`checkout!/1`, `unsandboxed_module/1`, `unsandboxed/2`, `assert_manual!/2,3`, `live_holder/0,1`, `LeakError`) is built, real-repo-verified, and committed. Plan 143-05/06 (the 13-file call-site migration) can proceed against this exact public surface.
- `LeakError` exists and is documented as load-bearing for plan 143-08's Wave-3 signature classifier — that plan must count both the raw `{:badmatch, :already_shared}` term and this composed error, or ROADMAP criterion 3 passes vacuously.
- The Credo check in plan 143-08 must allowlist exactly two files: `test/support/sandbox_ownership.ex` and `test/mailglass/test_support/sandbox_ownership_test.exs` (the latter is the one file besides the helper itself that legitimately drives `Ecto.Adapters.SQL.Sandbox` directly).
- No blockers. The database was left in a clean, migrated state; the Sandbox pool is `:manual` at the end of this plan's execution (verified: `mix test test/mailglass/test_support/` and `mix test test/scripts/` both green, 5 consecutive runs of the new regression file all pass).

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-29*

## Self-Check: PASSED

Both modified files confirmed present on disk with the expected new public functions
(`grep -Ec 'def (checkout!|unsandboxed_module|unsandboxed|probe|assert_manual!|live_holder)' test/support/sandbox_ownership.ex` = 6).
All 3 commit hashes (`da100ba6`, `d5f84874`, `44f127c8`) confirmed present in `git log --oneline --all`.
