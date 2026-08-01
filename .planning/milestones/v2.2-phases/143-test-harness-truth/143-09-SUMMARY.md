---
phase: 143-test-harness-truth
plan: 09
subsystem: testing
tags: [exunit, after_suite, anti-vacuity, harness-03, d-13, d-14, d-17, persistent_term]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 01)
    provides: "SuiteTruthFormatter's :module_finished hygiene probe skeleton (Class A/B/C), the :test_finished handler stub this plan fills in, and the formatter registration in test_helper.exs alongside which SuiteFloor.install() is added"
  - phase: 143-test-harness-truth (plan 03)
    provides: "143-MECHANISM.md's verbatim captured :already_shared failure term (CI run 30464215272, job 90617762038) — the exact fixture the classifier's highest-value test is built against"
  - phase: 143-test-harness-truth (plan 04)
    provides: "Mailglass.TestSupport.SandboxOwnership.LeakError — the composed error checkout!/1 substitutes for the raw badmatch at the confirmed leak sites, and the second half of the D-17 already_shared laundering-guard pair"
provides:
  - "Mailglass.TestSupport.SuiteFloor — a pure, CILanes-shaped policy module answering how many tests executed, which exclusion tags were legitimate, and whether the :already_shared regression signature reappeared, reading counts exclusively from ExUnit.after_suite/1 (never the CLI summary line, D-13)"
  - "The D-14 exclusion-tag allowlist checked by set equality in both directions, with the 'missing' direction deliberately narrowed to only :public_only (the tag test_helper.exs applies deterministically) rather than the full known-tag union — :requires_workspace is asserted only via the 'unknown' direction, since it is applied by an external CLI flag legitimately absent on every narrower lane"
  - "SuiteTruthFormatter.signature/1 — a closed-atom-set (:already_shared, :undefined_table, :config_schema_drift, :sandbox_ownership, :citext_probe, :other) structural classifier for ExUnit failure entries, with the :already_shared pair (raw badmatch term + composed LeakError) as the load-bearing laundering guard"
  - "A working cross-process read path from SuiteFloor.check/1 (the mix test runner process, via after_suite) to the formatter's final tally — via a :persistent_term snapshot written at :suite_finished, after discovering live that a name-registered :sys.get_state/1 read cannot work (ExUnit.EventManager.stop/1 terminates every formatter before after_suite callbacks run)"
  - "test/scripts/suite_floor_contract_test.exs — 23 negative-control tests in the required mix_task_tests lane (auto-collected, no mix.exs change), covering all six boundary points, both allowlist directions, the verbatim-term classifier, and the signature-assertion negative controls"
affects: [143-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A GenServer formatter that needs to expose data to an ExUnit.after_suite/1 callback CANNOT do so via a live-process read (:sys.get_state/1, name registration): ExUnit.Runner calls ExUnit.EventManager.stop/1 — which DynamicSupervisor.stop/1s every formatter's supervisor — BEFORE invoking configured :after_suite callbacks. Confirmed by decompiling ExUnit.Runner's abstract code, not merely reasoned about. The formatter must instead persist a final snapshot (:persistent_term.put/2) at :suite_finished, its last guaranteed-alive event, and the after_suite callback reads that snapshot rather than the live process."
    - "A both-directions exclusion-tag allowlist check must be schema/invocation-aware, not flat: a tag applied only by an external CLI flag (present on the two full-suite lanes, absent from every narrower mix test invocation in the repo) cannot be asserted 'missing' without false-positiving on nearly every other lane. Only a tag the harness applies deterministically from state it controls itself (schema-conditional, no CLI flag required) is safe to assert in the 'missing' direction."
    - "Postgres exposes a missing relation's schema-qualified name only in %Postgrex.Error{}'s raw postgres.message field for the undefined_table SQLSTATE — no structured table/schema key exists for that error class. A classifier needing that name reads the raw driver field directly via regex, never Exception.message/1 (a longer, differently-composed string) and never treats this as the message-string matching CLAUDE.md forbids for exception-type identification (the identity match is still fully structural, on the struct and its :code field)."
    - "An exception with no dedicated struct (a plain `raise \"string\"`, i.e. %RuntimeError{}) can still be classified structurally, without a message-string match, by checking stacktrace-frame module identity (Enum.any?(stacktrace, fn {SomeModule, _, _, _} -> true; _ -> false end)) instead of the exception's own text."

key-files:
  created:
    - test/support/suite_floor.ex
    - test/scripts/suite_floor_contract_test.exs
  modified:
    - test/support/suite_truth_formatter.ex
    - test/test_helper.exs

key-decisions:
  - "The already_shared/formatter_violations pipeline steps and the SuiteTruthFormatter cross-process wiring were deliberately deferred from Task 1 to Task 2, splitting suite_floor.ex's build across both tasks — Task 1's SuiteFloor would otherwise forward-reference SuiteTruthFormatter.current_state/0 before it exists, which mix compile --warnings-as-errors treats as an undefined-function warning (a compile failure under --warnings-as-errors). This matches the plan's own file-list overlap (suite_floor.ex appears in both Task 1's and Task 2's <files>)."
  - "[Rule 1 - Bug, found via live verification] The D-14 both-directions allowlist check's 'missing' direction was narrowed from the full known-tag union to only :public_only. An early draft asserting both :requires_workspace and :public_only as 'expected' on every schema false-positived immediately on `mix test test/mailglass/test_support/` (a real, narrow lane) — :requires_workspace is applied only by advisory-matrix.yml's external --exclude flag, absent from nearly every other invocation of mix test in the repo by design, not by regression. Fixed by asserting only the tag test_helper.exs itself applies deterministically (:public_only, schema-conditional, no CLI flag needed); the 'unknown' direction still protects :requires_workspace fully on any run that DOES pass an unpinned tag."
  - "[Rule 1 - Bug, found via live verification] The formatter's cross-process read path was redesigned mid-Task-2. The first implementation (Process.register/2 in init/1 + :sys.get_state/1 from SuiteFloor.check/1, mirroring SandboxOwnership.probe/1) compiled and passed unit tests but returned :unavailable against every real mix test run. Decompiling ExUnit.Runner's abstract code confirmed ExUnit.EventManager.stop/1 (which DynamicSupervisor.stop/1s every formatter) runs BEFORE the runner invokes :after_suite callbacks — the formatter is provably dead by the time SuiteFloor.check/1 executes, every time. Fixed by having the formatter persist a %{signature_tally:, violations:} snapshot to :persistent_term at :suite_finished (its last guaranteed-alive event) instead of exposing a live-process read; SuiteFloor.check/1 reads that snapshot. Both moduledocs record the failed approach and the empirical proof, so a future reader does not reintroduce it."
  - "The floor and ceiling constants (executed_floors, skipped_ceiling) are explicit placeholder sentinels (0 and 1_000_000_000 respectively), never measured from this plan's own local Elixir 1.19.5/OTP 28 runs, per the coordinator's brief and D-27 — the required/gating lanes run 1.18.4/OTP 27, a different leg of the matrix. Plan 143-10 pins the real values from green CI runs."

patterns-established:
  - "The :already_shared signature classifier's two-clause laundering-guard pair (raw MatchError term + composed LeakError, commented as a pair referencing each other) is the concrete implementation of D-17's mandatory anti-vacuity requirement — any future composed-error substitution for a tallied failure signature must extend this pair, not silently replace the first clause."

requirements-completed: [HARNESS-03]

coverage:
  - id: D1
    description: "Mailglass.TestSupport.SuiteFloor reads all four suite counts from ExUnit.after_suite/1 via Map.fetch!/2 (never the CLI summary line), with a moduledoc documenting the proven 1.18-vs-1.19 summary-line divergence and an explicitly-labelled accepted-gap paragraph"
    requirement: "HARNESS-03"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/test_support/ --warnings-as-errors (35 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors && mix credo --strict (0 issues); mix format --check-formatted (clean)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The D-14 exclusion-tag allowlist is checked by set equality in both directions against the effective merged ExUnit.configuration()[:exclude] set, schema-aware to avoid false-positiving on narrower lanes"
    requirement: "HARNESS-03"
    verification:
      - kind: unit
        ref: "test/scripts/suite_floor_contract_test.exs 'exclusion-tag allowlist, both directions' describe block (4 tests: sanity, unknown-tag, dead-entry, both real schema axes)"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix test --warnings-as-errors --exclude requires_workspace --seed 0 (public axis, real run): 0 allowlist violations reported"
        status: pass
    human_judgment: false
  - id: D3
    description: "SuiteTruthFormatter.signature/1 classifies the verbatim captured :already_shared failure term and the composed LeakError, both structurally, plus undefined_table/config_schema_drift/sandbox_ownership/citext_probe/other, with zero message-string matching"
    requirement: "HARNESS-03"
    verification:
      - kind: unit
        ref: "test/scripts/suite_floor_contract_test.exs verbatim-term + classifier-coverage describe blocks (7 tests)"
        status: pass
      - kind: other
        ref: "grep -Eic 'Exception.message|String.contains\\?|=~' test/support/suite_truth_formatter.ex == 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "16+ negative controls run in the required mix_task_tests lane with no mix.exs change, and the full public-axis suite runs clean end to end with SuiteFloor printing correct counts and a zero already_shared/formatter_violations tally"
    requirement: "HARNESS-03"
    verification:
      - kind: unit
        ref: "mix test test/scripts/suite_floor_contract_test.exs --warnings-as-errors (23 tests, 0 failures); mix test test/scripts/ --warnings-as-errors (72 tests, 0 failures, sibling meta-tests unaffected)"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test --warnings-as-errors --exclude requires_workspace --seed 0 (public axis, full suite): exit 0, 0 failures, already_shared=0, formatter_violations=0"
        status: pass
      - kind: other
        ref: "git diff --name-only mix.exs (empty)"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-07-30
status: complete
---

# Phase 143 Plan 09: The Anti-Vacuity Layer — SuiteFloor Policy and the D-17 Signature Classifier Summary

**Built `Mailglass.TestSupport.SuiteFloor` (counts + exclusion-allowlist + signature-tally policy, read exclusively from `ExUnit.after_suite/1`) and `SuiteTruthFormatter.signature/1` (the closed-atom-set, structural-only failure classifier with its mandatory `:already_shared` laundering-guard pair), then caught and fixed two real bugs live — a false-positive allowlist direction and an architecturally-dead cross-process read — before either shipped, backed by 23 negative controls that drive the same pure functions the real path calls.**

## Performance

- **Duration:** ~35 min (includes two full end-to-end suite runs, ~87s and ~86s, to verify the fix against real data rather than only synthetic fixtures)
- **Tasks:** 3 planned (`type="auto"`), all committed atomically as specified
- **Files modified:** 2 created, 2 modified

## Accomplishments

- **`Mailglass.TestSupport.SuiteFloor`** (`test/support/suite_floor.ex`): a pure policy module, deliberately structured as a `CILanes` sibling — hardcoded constants each with a rationale comment, one-line `@doc`/`@spec` accessors, and a 23-test negative-control meta-test. Its moduledoc carries the required 1.18-vs-1.19 summary-line divergence table verbatim, the rejection of a machine-rewritten baseline (D-15), and an explicitly-labelled "accepted gap" paragraph (D-18b: the floor proves nothing about whether assertions are meaningful).
- **Counts come exclusively from `ExUnit.after_suite/1`**, read with `Map.fetch!/2` per key (10 occurrences across `check/1` and the pure `violations/3`) — never the CLI summary line, which this repo's own matrix proves is outright wrong (not merely brittle) across Elixir 1.18/1.19.
- **The floor and ceiling are explicit, non-representative placeholder sentinels** (`0` and `1_000_000_000`), never measured locally — this repo's dev toolchain (1.19.5/OTP 28) is the wrong leg of the matrix the floor guards; plan `143-10` pins the real numbers from a green 1.18/OTP 27 CI run, per the coordinator's brief and D-27.
- **Found and fixed a real false-positive in the D-14 both-directions allowlist check**, live, before committing: asserting `:requires_workspace` as "expected" in the "missing" direction on every schema tripped a violation on `mix test test/mailglass/test_support/` — a real, narrow, everyday lane — because that tag is applied only by an external CLI flag (`advisory-matrix.yml`'s two full-suite steps), not by anything `test_helper.exs` itself controls. Narrowed the "missing" direction to only `:public_only` (the tag the harness applies deterministically from the schema alone); the "unknown" direction still fully protects `:requires_workspace` on any run that actually adds an unpinned tag.
- **`SuiteTruthFormatter.signature/1`**: 6 clauses classifying ExUnit failure entries into a closed atom set, every clause structural (struct type or stacktrace-frame identity — zero `Exception.message/1`, `String.contains?/2`, or `=~` anywhere in the file). The `:already_shared` pair is the load-bearing one: the verbatim nested `MatchError` term captured from CI run `30464215272` (job `90617762038`), and the composed `SandboxOwnership.LeakError` `checkout!/1` substitutes at the confirmed leak sites — commented as a pair so neither can be deleted without the reader seeing the other. `:config_schema_drift` splits out of `:undefined_table` by reading the missing relation's schema prefix from `Postgrex.Error`'s raw `postgres.message` field (Postgres exposes no structured field for it). `:citext_probe` (no dedicated exception struct exists) is distinguished from an arbitrary `RuntimeError` by a stacktrace-frame identity check, proven by a dedicated coverage test that also proves the match is not overbroad.
- **Found and fixed a genuine architectural dead end in the cross-process read path, live, via a real suite run** — not merely reasoned about: the first implementation (name-registered process + `:sys.get_state/1`, mirroring `SandboxOwnership.probe/1`'s established idiom) compiled clean, passed every unit test, and then returned `:unavailable` on every actual `mix test` run. Decompiling `ExUnit.Runner`'s abstract code confirmed `ExUnit.EventManager.stop/1` terminates every formatter's supervisor BEFORE the runner invokes `:after_suite` callbacks — the formatter is provably dead, always, by the time `SuiteFloor.check/1` runs. Fixed by having the formatter persist a `%{signature_tally:, violations:}` snapshot to `:persistent_term` at `:suite_finished` (its last guaranteed-alive event), an idiom already established in this codebase via `SandboxOwnership.with_schema!/2`. Both moduledocs record the failed approach and the empirical proof so it is not quietly retried.
- **`test/scripts/suite_floor_contract_test.exs`** (23 tests, auto-collected into the required `mix_task_tests` lane via `verify.ci_lane_contract`'s directory glob — confirmed `git diff --name-only mix.exs` is empty): all six boundary points as individual tests (floor exact/minus-one, ceiling exact/plus-one, nudge exact/plus-one, with the nudge explicitly asserted `kind: :warning` and never accompanied by a `kind: :violation`), both allowlist directions, the verbatim-term classifier test with its own explanation of what a naive top-level match would return instead, full classifier coverage including the `:cannot_verify` (formatter unreachable) path reporting a violation rather than silently defaulting to zero, and an anti-vacuity guard on the violation-class vocabulary's non-emptiness.
- **Verified end to end against a real, full public-axis suite run** (not only synthetic fixtures): `MIX_ENV=test mix test --warnings-as-errors --exclude requires_workspace --seed 0` — 0 failures, `SuiteFloor` printed `total: 1550, excluded: 13, skipped: 7, executed: 1530, failures: 0`, `already_shared=0, formatter_violations=0`, exit 0. Also ran the mailglass axis to confirm no new regression: exactly the coordinator's documented 5 pre-existing failures, `already_shared=0` there too — the `:already_shared` signature genuinely has not reappeared on either axis.

## Task Commits

1. **Task 1: The pure `SuiteFloor` policy module and its `after_suite` install** - `02c0264b` (feat)
2. **Task 2: The failure-signature classifier and its laundering guard** - `d3dc1a72` (feat)
3. **Task 3: Negative controls in the required lane, including the verbatim-term test** - `9f1d9fdf` (test)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/support/suite_floor.ex` - `Mailglass.TestSupport.SuiteFloor`: pure policy module, `install/0`, `check/1`, `violations/3`, per-constant accessors.
- `test/support/suite_truth_formatter.ex` - added `signature/1` and its two `:already_shared` clauses plus `:undefined_table`/`:config_schema_drift`/`:sandbox_ownership`/`:citext_probe`/`:other`; the `:test_finished` signature tally; the `:persistent_term`-based cross-process snapshot at `:suite_finished`; `current_state/0`.
- `test/test_helper.exs` - added `Mailglass.TestSupport.SuiteFloor.install()` alongside the existing formatter registration.
- `test/scripts/suite_floor_contract_test.exs` - 23-test negative-control contract suite.

## Decisions Made

See `key-decisions` in frontmatter. The two load-bearing ones, both found via live verification rather than static reasoning: (1) the D-14 "missing" allowlist direction was narrowed to only `:public_only` after a real false positive on a narrow lane; (2) the formatter's cross-process read path was redesigned from a live `:sys.get_state/1` (which cannot work, confirmed by decompiling `ExUnit.Runner`) to a `:persistent_term` snapshot written at the formatter's last guaranteed-alive event.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] D-14 allowlist's "missing" direction false-positived on real, narrow lanes**

- **Found during:** Task 1, running the plan's own required verification command (`mix test test/mailglass/test_support/ --warnings-as-errors`) immediately after building the module.
- **Issue:** The first draft's `expected_exclusion_tags/1` asserted both `:requires_workspace` and (on non-public schemas) `:public_only` as "expected, must be present" in the both-directions check. `:requires_workspace` is applied only by `advisory-matrix.yml`'s external `--exclude requires_workspace` flag on the two full-suite steps — absent by design from every other `mix test` invocation in the repo (a developer's focused run, `verify.ci_lane_contract`, `verify.support_contract.core`, …). The real run immediately reported a `[VIOLATION] exclusion_allowlist_dead_entry` for a completely healthy, narrow test run.
- **Fix:** Narrowed `expected_exclusion_tags/1` to assert only `:public_only` (the tag `test_helper.exs` itself applies deterministically, from the schema alone, with no CLI flag required) — `"public"` expects `MapSet.new([])`, every other schema expects `MapSet.new([:public_only])`. The "unknown" direction (checked against the full known-tag union, `known_exclusion_tags/0`) still fully protects `:requires_workspace`: any run that DOES pass an unpinned tag is caught regardless of lane. Documented the reasoning, including the live false-positive, directly in `SuiteFloor`'s moduledoc and the accessor's `@doc`.
- **Files modified:** `test/support/suite_floor.ex`
- **Verification:** `mix test test/mailglass/test_support/ --warnings-as-errors` re-run clean (`0 violation(s).`); `test/scripts/suite_floor_contract_test.exs`'s "sanity: today's real exclusion sets agree with SuiteFloor on both schema axes" test locks this in for both `public` and `mailglass`.
- **Committed in:** `02c0264b`

**2. [Rule 1 - Bug] The cross-process read path from `SuiteFloor.check/1` to the formatter's state does not work as first designed**

- **Found during:** Task 2, running the plan's own required verification command (`mix test test/mailglass/test_support/ --warnings-as-errors`) after wiring the tally in.
- **Issue:** The first implementation registered the formatter under a well-known name in `init/1` and had `SuiteFloor.check/1` read its state via `Process.whereis/1` + `:sys.get_state/1` — mirroring `SandboxOwnership.probe/1`'s established, working idiom for the Sandbox ownership manager. It compiled clean and passed every unit test (which drive `handle_cast/2` directly, never through a real GenServer), but a real `mix test` run printed `already_shared=:cannot_verify, formatter_violations=:cannot_verify` and a `[VIOLATION]` for each, every time. Decompiling `ExUnit.Runner`'s abstract code (`:beam_lib.chunks/2` on the compiled `.beam`) confirmed the mechanism: `ExUnit.Runner.run/2` calls `ExUnit.EventManager.stop/1` — which `DynamicSupervisor.stop/1`s the supervisor every ExUnit formatter (including custom GenServer-based ones) is started under — strictly BEFORE it invokes the configured `:after_suite` callbacks. The formatter is provably terminated, always, by the time `SuiteFloor.check/1` runs; a name-based lookup can never find a live process there.
- **Fix:** Replaced the live-process read with a `:persistent_term` snapshot: `handle_cast({:suite_finished, ...})` — the LAST event this formatter receives while still alive — writes `%{signature_tally:, violations:}` to a `:persistent_term` key; `current_state/0` reads that snapshot. This is the same idiom already established in this codebase (`SandboxOwnership.with_schema!/2`'s cache-write boundary), and remains a single source of truth (the formatter is still the only place classification/tallying happens; only the read mechanism changed). Confirmed the ordering is safe: `:suite_finished` is ExUnit's last event, firing only after every test module — including this formatter's own unit tests, which call `handle_cast/2` directly with synthetic state — has completed, so the real formatter's write is always the final write before `check/1` reads it. Both moduledocs record the rejected approach and the empirical proof so a future reader does not reintroduce it.
- **Files modified:** `test/support/suite_truth_formatter.ex`, `test/support/suite_floor.ex` (moduledoc only)
- **Verification:** `mix test test/mailglass/test_support/ --warnings-as-errors` re-run clean (`already_shared=0, formatter_violations=0`, `0 violation(s).`); confirmed against two full, real, end-to-end suite runs (public and mailglass axes) with correct non-`:cannot_verify` tallies both times.
- **Committed in:** `d3dc1a72`

Both deviations were found by actually running the plan's own prescribed verification commands rather than trusting the code by inspection — exactly the discipline this phase's coordinator note demanded ("Demonstrate them, do not reason about them").

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs, both caught via live verification before commit, neither shipped in a broken state).
**Impact on plan:** No scope creep. Both fixes stayed inside the plan's own declared `files_modified` list (`suite_floor.ex`, `suite_truth_formatter.ex`); no new files, no new dependencies, no `mix.exs` change.

## Issues Encountered

None beyond the two deviations above, both resolved within the same task before committing.

## User Setup Required

None — no external service configuration required. PostgreSQL reachability was already established by prior plans in this phase; this plan's two full-suite verification runs (public and mailglass axes) both completed against the existing `Mailglass.TestRepo`.

## Known Stubs

None. The floor/ceiling PLACEHOLDER constants are not stubs in the sense this section tracks — they are explicit, documented, intentionally-inert values (see `key-decisions` and the coordinator's brief) that plan `143-10` is specifically scoped to replace; `SuiteFloor`'s moduledoc, the constant comments, and this SUMMARY all name that follow-up explicitly, so no reader could mistake them for a finished measurement.

## Threat Flags

None. This plan adds no new network endpoint, auth path, or schema change. It adds a test-harness policy module and extends an existing test-harness formatter, both entirely inside `test/support/` (excluded from the Hex tarball per D-06's `files:` allowlist) and both mitigating exactly the threats named in the plan's own `<threat_model>` (T-143-28 through T-143-32): the verbatim-term test closes T-143-28, the laundering-guard pair closes T-143-29, `Map.fetch!/2` on all four ExUnit-native keys closes T-143-30, the hardcoded-constants-with-drift-test shape closes T-143-31, and the printed report carries only counts/schema names/signature atoms (no test data or query values) per T-143-32's accepted-risk disposition.

## Next Phase Readiness

- HARNESS-03's anti-vacuity layer is structurally complete: `SuiteFloor` answers "how many tests ran" and "which categories were allowed not to run" (both proven against real CI-shaped runs on both schema axes), and the `:already_shared` signature — the regression identity SEED-007 lost for months — is now a first-class, laundering-guard-protected tally, confirmed genuinely zero on a real full-suite run on both axes today.
- Plan `143-10` can proceed directly: it needs a green 1.18/OTP 27 CI run on each schema axis to pin `SuiteFloor`'s `executed_floors` and `skipped_ceiling` PLACEHOLDER constants to real numbers, and to set `MAILGLASS_SUITE_FLOOR=1` on the two `advisory-matrix.yml` full-suite steps to turn enforcement on. No further code changes in `suite_floor.ex` or `suite_truth_formatter.ex` are anticipated for that plan beyond the constant values themselves.
- No blockers. All three task commits are green under `mix compile --warnings-as-errors`, `mix credo --strict`, and `mix format --check-formatted`; the full public-axis suite is green; the mailglass-axis run shows exactly the 5 pre-existing, out-of-scope failures the coordinator documented, unchanged by this plan's work.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-30*

## Self-Check: PASSED

All 4 files (2 created, 2 modified) confirmed present on disk. All 3 task
commit hashes (`02c0264b`, `d3dc1a72`, `9f1d9fdf`) confirmed present in
`git log --oneline --all`.
