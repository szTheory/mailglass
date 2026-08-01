---
phase: 143-test-harness-truth
plan: 08
subsystem: testing
tags: [credo, ecto, sandbox, harness-01, static-analysis, lint]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 04)
    provides: "Mailglass.TestSupport.SandboxOwnership — checkout!/1, unsandboxed_module/1, probe/1, assert_manual!/3, the sanctioned acquire/release door this plan's Credo check exempts by name"
  - phase: 143-test-harness-truth (plan 05)
    provides: "The decision to migrate schema_axis_boot_order_test.exs's bare checkout rather than allowlist it — the reason :checkout is in this check's forbidden_functions list — plus the two deliver_many_test.exs/deliver_later_test.exs raw calls left, by name, for this plan to migrate"
  - phase: 143-test-harness-truth (plan 07)
    provides: "A fully closed Class A/B/C mechanism (checkout!/1, unsandboxed_module/1, with_schema!/2) for this check's allowlist to protect going forward"
provides:
  - "Mailglass.Credo.NoRawSandboxOwnership — a custom Credo check forbidding raw Ecto.Adapters.SQL.Sandbox ownership calls (:mode, :start_owner!, :stop_owner, :checkout, :checkin) anywhere under test/, outside exactly two allowlisted modules (Mailglass.TestSupport.SandboxOwnership and its own mechanism test). Resolves fully-qualified, aliased bare-tail, and `as:`-renamed call forms; deliberately does NOT copy the Swoosh analog's bare-tail-only fallback"
  - "Mailglass.TestSupport.SandboxOwnership.mode_manual!/1 — the one raw Sandbox.mode(repo, :manual) write the door itself performs, for the two caller shapes (suite boot; pre-release healing) that need direct mode mutation without an acquire/release pairing"
  - "A demonstrated (not assumed) proof that mix credo --strict reaches test/**/*.exs and test/support/*.ex, recorded via a real scratch-file experiment against Mailglass.Credo.NoPiiInTelemetryMeta"
  - "All three remaining raw Ecto.Adapters.SQL.Sandbox.mode call sites under test/ (test_helper.exs, deliver_many_test.exs, deliver_later_test.exs) migrated to the sanctioned door — the allowlist stays at exactly two modules"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Credo custom-check alias resolution for a 4-segment target module (Ecto.Adapters.SQL.Sandbox), built as a structural twin of the 2-segment Swoosh.Mailer analog (credo_checks/no_raw_swoosh_send_in_lib.ex) — same param_defaults/run/prewalk/postwalk/path-filter shape, with the alias-collection function generalized to Enum.map(parts, &Atom.to_string/1) equality against a 4-element list instead of a hardcoded 2-element match."
    - "A forbidden-call Credo check MUST demonstrate its own file-path reach with a real scratch-file experiment before any of its fixtures are trusted — inspecting `.credo.exs`'s `included:` list is not sufficient (RESEARCH.md Open Question 5)."
    - "Do not copy a sibling check's bare-tail-only fallback (matching a module tail with no resolving alias) without re-deriving whether it is safe for the new target — it is a permanent, silent over-match risk that erodes trust in a lint gate the moment an unrelated same-named module appears."
    - "`Keyword.get(opts, :as)` returning `nil` will satisfy a bare `name when is_atom(name)` guard clause, since `nil` is itself an atom — any alias-resolution helper following the Swoosh analog's exact pattern must exclude `nil` explicitly (`not is_nil(name)`) or a bare (non-`as:`) alias silently resolves to the literal string `\"nil\"` instead of falling through to its real default."
    - "When a Credo check forbids raw calls to a low-level dependency function with no allowlist widening permitted, and a legitimate non-acquire/release caller still needs the raw primitive (e.g. a suite-wide boot-time mode set), route it through a narrowly-scoped, explicitly-documented wrapper function on the sanctioned door itself rather than allowlisting the caller — the door's allowlist entry then protects the wrapper's implementation, not an ever-growing set of exempted call sites."

key-files:
  created:
    - credo_checks/no_raw_sandbox_ownership.ex
    - test/mailglass/credo/no_raw_sandbox_ownership_test.exs
  modified:
    - .credo.exs
    - test/mailglass/credo/integration_test.exs
    - test/support/sandbox_ownership.ex
    - test/test_helper.exs
    - test/mailglass/outbound/deliver_many_test.exs
    - test/mailglass/outbound/deliver_later_test.exs

key-decisions:
  - "The check does NOT copy Mailglass.Credo.NoRawSwooshSendInLib's bare-tail-only fallback (matching any module whose tail is the target name even with no resolving alias). A bare `Sandbox` tail is only flagged when an explicit `alias Ecto.Adapters.SQL.Sandbox` (bare or `as:`-renamed) actually resolves it to the Ecto module — pinned by a dedicated negative fixture aliasing an unrelated module `as: Sandbox`."
  - "test_helper.exs's suite-wide boot-time `Sandbox.mode(repo, :manual)` call and the two deliver_many_test.exs/deliver_later_test.exs pre-release healing calls were MIGRATED to a new `SandboxOwnership.mode_manual!/1`, not allowlisted by module or exempted by path — the plan's own prohibition against growing the allowlist to make a call site pass applies to path-based exemptions too, not just module-name exemptions. mode_manual!/1 performs no acquire/release pairing of its own, so it does not reintroduce the ordering bug the check exists to prevent, and the allowlist itself stays pinned at exactly two modules."
  - "The plan's literal acceptance-criterion grep (`grep -Erlc 'Ecto\\.Adapters\\.SQL\\.Sandbox' test/` expected to list only the two allowlisted files) over-matches on this plan's own new check-test fixture heredocs (no_raw_sandbox_ownership_test.exs, integration_test.exs) and a prose comment in test_helper.exs referencing config/test.exs's pool setting. Neither is a real ownership call. `mix credo --strict` finding zero issues over the whole tree is the authoritative confirmation the acceptance criterion was gesturing at; the literal grep is documented here as an imprecise proxy rather than silently reinterpreted."
  - "Task 2's own acceptance criterion (`mix test test/mailglass/credo/checks_have_tests_test.exs --warnings-as-errors exits 0`) cannot pass until Task 3 registers the check in .credo.exs — checks_have_tests_test.exs asserts BOTH 'has a test file' and 'is registered', and the plan's own task split puts the .credo.exs edit in Task 3. Task 2 was committed with that second assertion in a known, temporary failing state; Task 3's commit closes it. Documented here rather than silently reordering the plan's task boundaries."

patterns-established:
  - "SandboxOwnership.mode_manual!/1 is now the sanctioned door for a bare pool-mode write that is neither an acquire nor a release — documented for exactly its two current callers (suite boot; pre-release healing revert) so a future reader does not mistake it for a general-purpose Sandbox.mode wrapper."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "mix credo --strict's reach over test/**/*.exs and test/support/*.ex demonstrated with a real scratch-file experiment (two deliberately-violating files, one under each path shape, both flagged by Mailglass.Credo.NoPiiInTelemetryMeta naming the exact file path, both removed, credo green again afterward) before any check was built on top of that assumption"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "manual scratch-file experiment, recorded below in 'Task 1: Scratch-File Proof'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mailglass.Credo.NoRawSandboxOwnership forbids :mode/:start_owner!/:stop_owner/:checkout/:checkin under test/ outside exactly two allowlisted modules, resolving fully-qualified, aliased bare-tail, and as:-renamed forms, without copying the Swoosh analog's bare-tail-only over-match"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/credo/no_raw_sandbox_ownership_test.exs --warnings-as-errors (13 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The check is registered in .credo.exs, asserted (not assumed) via a new HARNESS-01 fixture pair in integration_test.exs, and the whole tree is green"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix credo --strict over the whole tree (491 files, 0 issues)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass/credo/ --warnings-as-errors (185 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "All raw Ecto.Adapters.SQL.Sandbox call sites the check found outside the two allowlisted modules (test_helper.exs, deliver_many_test.exs, deliver_later_test.exs) were migrated to the sanctioned door via a new mode_manual!/1, not allowlisted or path-exempted; full suite still green on the public axis"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors (21 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test --warnings-as-errors --exclude requires_workspace --seed 0 (public axis): 1491 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test MAILGLASS_SCHEMA=mailglass mix test --warnings-as-errors --exclude requires_workspace --seed 0: 1490 tests, 5 failures — all 5 confirmed pre-existing (schema_isolation_immutability_test.exs's down-test, shipped_migration_divergence_test.exs's 4-failure cascade), explicitly out of this plan's scope per the coordinator's brief"
        status: pass
    human_judgment: false

duration: ~1h10min
completed: 2026-07-30
status: complete
---

# Phase 143 Plan 08: Credo Check — No Raw Sandbox Ownership Summary

**`Mailglass.Credo.NoRawSandboxOwnership` forbids raw `Ecto.Adapters.SQL.Sandbox` ownership calls under `test/` outside the sanctioned door, proven reachable before it was trusted, proven to actually fire against a real positive/negative fixture corpus, and proven against the whole tree — closing the prevention half of HARNESS-01's two-layer recurrence guard by migrating the three remaining raw call sites rather than allowlisting them.**

## Performance

- **Duration:** ~1h10min
- **Tasks:** 3 planned (`type="auto"`), 0 deviation-only commits (the call-site migrations were performed inside Task 3's own commit, per that task's explicit instruction to migrate anything the check finds)
- **Files modified:** 2 created, 6 modified

## Accomplishments

- **Proved `mix credo --strict` actually reaches `test/**/*.exs` and `test/support/*.ex`** before relying on it — RESEARCH.md Open Question 5 answered with a real experiment, not an inspection. Two scratch files (one per path shape), each calling `:telemetry.execute(..., %{to: "..."})`, were both flagged by name and line by `Mailglass.Credo.NoPiiInTelemetryMeta` (the one existing check with no `included_path_prefixes` filter), then removed, with `mix credo --strict` green again immediately after.
- **Built `Mailglass.Credo.NoRawSandboxOwnership`** as a structural twin of `Mailglass.Credo.NoRawSwooshSendInLib`, with the one genuine adaptation — four-segment alias resolution for `Ecto.Adapters.SQL.Sandbox` (fully-qualified, aliased bare-tail, and `as:`-renamed forms) instead of the analog's two-segment `Swoosh.Mailer`. Forbids `:mode`, `:start_owner!`, `:stop_owner`, `:checkout`, and `:checkin`; allowlists exactly `Mailglass.TestSupport.SandboxOwnership` and `Mailglass.TestSupport.SandboxOwnershipTest`.
- **Deliberately did not copy the analog's bare-tail-only over-match fallback** (which flags any module whose tail is `"Mailer"` even with no resolving alias) — pinned by a dedicated negative fixture that aliases an unrelated module `as: Sandbox` and asserts zero issues.
- **Found and fixed a latent bug in the copied `alias_name_from_opts/1` pattern** while writing the bare-tail fixture: `Keyword.get(opts, :as)` returns `nil` when `:as` is absent, and `nil` itself satisfies `is_atom(name)`, so a bare (non-`as:`) alias returned the literal string `"nil"` instead of falling through to the real `"Sandbox"` default — silently defeating bare-tail resolution entirely. The Swoosh analog never surfaces this because its separate bare-tail-only fallback masks it; this check has no such fallback, so the bug was load-bearing. Fixed by excluding `nil` explicitly (`is_atom(name) and not is_nil(name)`), with the reasoning recorded inline so it is not "corrected" back to the analog's form.
- **13 tests** cover all five forbidden functions individually (fully-qualified form), an anti-vacuity total-issue-count guard across them, the aliased bare-tail form, the `as:`-renamed form, both allowlist exemptions, the path filter (a `lib/` file is ignored), the deliberate unrelated-`Sandbox`-tail non-match, and `Sandbox.allow/3`'s non-forbidden pass-through.
- **Registered the check in `.credo.exs`** (only the check entry added — `requires:`, `files:`, and `excluded:` untouched) and added a `HARNESS-01` fixture pair to `integration_test.exs` so the registration is asserted, not assumed.
- **Ran `mix credo --strict` over the whole tree and it surfaced exactly the three raw call sites the coordinator's inventory named** (`test_helper.exs:135`, `deliver_many_test.exs:45`, `deliver_later_test.exs:63`) — nothing else, and nothing missed. All three were **migrated**, not allowlisted, per the plan's own prohibition.
- **Added `Mailglass.TestSupport.SandboxOwnership.mode_manual!/1`** to the sanctioned door — the one raw `Sandbox.mode(repo, :manual)` write it performs, for the two caller shapes that need direct pool-mode mutation with no acquire/release pairing of their own (suite-wide boot; a pre-release healing revert whose `on_exit` runs before `checkout!/1`'s own release, per ExUnit's LIFO `on_exit` ordering). This keeps the allowlist pinned at exactly two modules — no third exemption, by module or by path.
- **Full tree green:** `mix credo --strict` (491 files, 0 issues), `mix test test/mailglass/credo/ --warnings-as-errors` (185 tests, 0 failures), `mix test test/scripts/ test/mailglass/test_support/ --warnings-as-errors` (84 tests, 0 failures), `mix format --check-formatted` (clean), public-axis full suite (1491 tests, 0 failures). Mailglass-axis full suite ran the coordinator's documented 5 pre-existing failures, confirmed unrelated to this plan's scope.

## Task 1: Scratch-File Proof

**Scratch file A** (`test/mailglass/credo/_scratch_proof_exs_test.exs`):
```elixir
defmodule Mailglass.Credo.ScratchProofExsTest do
  @moduledoc false

  def emit do
    :telemetry.execute([:mailglass, :scratch, :proof, :stop], %{}, %{to: "scratch@example.com"})
  end
end
```

**Scratch file B** (`test/support/_scratch_proof_ex.ex`):
```elixir
defmodule Mailglass.TestSupport.ScratchProofEx do
  @moduledoc false

  def emit do
    :telemetry.execute([:mailglass, :scratch, :proof, :stop], %{}, %{to: "scratch@example.com"})
  end
end
```

**Reported output** (`mix credo --strict`):
```
[W] ↗ Telemetry metadata must not include blocked key `:to`.
      test/support/_scratch_proof_ex.ex:5:16 #(Mailglass.TestSupport.ScratchProofEx.emit)
[W] ↗ Telemetry metadata must not include blocked key `:to`.
      test/mailglass/credo/_scratch_proof_exs_test.exs:5:16 #(Mailglass.Credo.ScratchProofExsTest.emit)
```

Both flagged by `Mailglass.Credo.NoPiiInTelemetryMeta` (the one existing custom check with no `included_path_prefixes` filter, so it naturally lints anything the top-level `.credo.exs` `included:` list covers). Both scratch files were then deleted; `mix credo --strict` reported `3846 mods/funs, found no issues` immediately after (unchanged from the pre-scratch baseline), and `git status --porcelain` confirmed no scratch remained.

## Task Commits

1. **Task 1: Prove `mix credo --strict` reaches `test/**/*.exs` and `test/support/*.ex`** - `98162333` (test)
2. **Task 2: Build `Mailglass.Credo.NoRawSandboxOwnership` with four-segment alias resolution** - `1da4f6a8` (feat)
3. **Task 3: Wire the check into `.credo.exs` and prove the whole tree is clean (including migrating the 3 found call sites)** - `0063f8e0` (fix)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `credo_checks/no_raw_sandbox_ownership.ex` - `Mailglass.Credo.NoRawSandboxOwnership`: forbidden-function AST check with 4-segment alias resolution, no bare-tail fallback.
- `test/mailglass/credo/no_raw_sandbox_ownership_test.exs` - 13-test fixture corpus (Task 1 scaffold, filled in Task 2).
- `.credo.exs` - one added `checks:` entry; `requires:`/`files:`/`excluded:` unchanged.
- `test/mailglass/credo/integration_test.exs` - one added `HARNESS-01` fixture pair (`@check_cases`).
- `test/support/sandbox_ownership.ex` - added `mode_manual!/1` and its moduledoc "Public surface" bullet.
- `test/test_helper.exs` - migrated the suite-wide boot-time `Sandbox.mode(repo, :manual)` call to `SandboxOwnership.mode_manual!/1`.
- `test/mailglass/outbound/deliver_many_test.exs` / `deliver_later_test.exs` - migrated the pre-release healing `Sandbox.mode(repo, :manual)` call to `SandboxOwnership.mode_manual!/1`, updated the inline comment accordingly.

## Decisions Made

See `key-decisions` in frontmatter. The load-bearing one: the three raw call sites `mix credo --strict` found in Task 3 were migrated via a new, narrowly-scoped `mode_manual!/1` on the sanctioned door, not allowlisted by module or exempted by path — keeping the check's allowlist at exactly two modules, matching the plan's must-have.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Latent `nil`-vs-`is_atom` bug in the copied `alias_name_from_opts/1` pattern**

- **Found during:** Task 2, while writing the aliased bare-tail fixture.
- **Issue:** `Keyword.get(opts, :as)` returns `nil` when `:as` is absent; `nil` satisfies `is_atom(name)`, so `Mailglass.Credo.NoRawSwooshSendInLib`'s exact `alias_name_from_opts/1` shape, copied verbatim, returned the string `"nil"` instead of `nil` for a bare `alias Ecto.Adapters.SQL.Sandbox` (no `as:`) — defeating the `|| "Sandbox"` bare-tail default entirely.
- **Fix:** excluded `nil` explicitly (`name when is_atom(name) and not is_nil(name)`), with the reasoning recorded in a comment so a future reader does not "restore parity" with the analog and reintroduce the bug.
- **Files modified:** `credo_checks/no_raw_sandbox_ownership.ex`
- **Verification:** `mix test test/mailglass/credo/no_raw_sandbox_ownership_test.exs --warnings-as-errors` — the aliased bare-tail test now passes (previously failed with 0 issues instead of 1).
- **Committed in:** `1da4f6a8`

**2. [Rule 3 - Blocking, plan-anticipated] Migrated 3 raw call sites the check found outside its own declared `files_modified`**

- **Found during:** Task 3's required whole-tree `mix credo --strict` run.
- **Issue:** `test/test_helper.exs`, `test/mailglass/outbound/deliver_many_test.exs`, and `test/mailglass/outbound/deliver_later_test.exs` each carried a raw `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)` call — exactly the three sites named in the coordinator's inventory, none of which were in this plan's frontmatter `files_modified` list.
- **Fix:** added `SandboxOwnership.mode_manual!/1`, a narrowly-documented wrapper for exactly these non-acquire/release caller shapes, and migrated all three call sites to it.
- **Files modified:** `test/support/sandbox_ownership.ex`, `test/test_helper.exs`, `test/mailglass/outbound/deliver_many_test.exs`, `test/mailglass/outbound/deliver_later_test.exs`
- **Verification:** `mix credo --strict` over the whole tree — 0 issues. `mix test test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` — 21 tests, 0 failures. Public-axis full suite — 1491 tests, 0 failures.
- **Committed in:** `0063f8e0`

Both deviations were explicitly anticipated by the plan itself (Task 2's own action text calls out the `alias_name_from_opts` risk area implicitly via the "explicit decision on the analog's bare-tail over-match" instruction; Task 3's action text explicitly says "if the check reports a call site, that site was missed by the migration and must be migrated" and the coordinator's note names all three sites by file and line in advance).

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking issue explicitly anticipated by the plan/coordinator). No scope creep beyond what the plan's own Task 3 verification step required.

## Issues Encountered

- **Local test DB was found in a corrupted state at session start** (schema_migrations recorded 10 applied versions but the underlying `mailglass_*` tables did not exist — a known local-only artifact from prior sessions' repeated `mix ecto.drop`/`mix ecto.create` cycles per 143-07's own "Issues Encountered"). Reset via `mix ecto.drop -r Mailglass.TestRepo` / `mix ecto.create -r Mailglass.TestRepo` before Task 1's verification could run; left in a clean, fully-migrated state afterward. Not a code regression — CI creates a fresh database per matrix-axis job and never accumulates this state.

## User Setup Required

None — no external service configuration required. PostgreSQL reachability was verified (`scripts/preflight_postgres.sh`, then a drop/create cycle after finding the local DB in the corrupted state above); the DB is left in a clean, fully-migrated state on the public axis.

## Known Stubs

None.

## Threat Flags

None — this plan introduces no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. It adds a lint-time guard (`Mailglass.Credo.NoRawSandboxOwnership`) and a narrowly-scoped test-infrastructure wrapper (`SandboxOwnership.mode_manual!/1`), matching the threat model's own T-143-24 through T-143-27 mitigations: reachability was demonstrated before reliance, an anti-vacuity guard pins the positive fixtures, the allowlist is pinned at exactly two modules by both the check's own design and by migrating (not exempting) every call site found, and the `.credo.exs` diff was inspected to confirm only the check entry was added.

## Next Phase Readiness

- HARNESS-01's two-layer recurrence guard is now complete: `Mailglass.TestSupport.SuiteTruthFormatter` (detection, prior plans) plus `Mailglass.Credo.NoRawSandboxOwnership` (prevention, this plan). A raw acquire/release call re-typed anywhere under `test/` outside the sanctioned door now fails `mix credo --strict` by name; a leak that slips past that check anyway (e.g. via `:sys.get_state/1`-level state corruption the check cannot see) is still named at the instant it happens by the formatter.
- No blockers. All three task commits are green under `mix compile --warnings-as-errors`, `mix credo --strict`, and `mix format --check-formatted`.
- The mailglass-axis 5 pre-existing failures documented in `.planning/WINDOWS.md`/`deferred-items.md` remain open and out of this plan's scope, unchanged by this plan's work (confirmed: this plan touches no migration/schema code, only Credo tooling and test-infrastructure pool-mode calls).

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-30*

## Self-Check: PASSED

All 9 files (2 created, 7 modified/read) confirmed present on disk. All 3
commit hashes (`98162333`, `1da4f6a8`, `0063f8e0`) confirmed present in
`git log --oneline --all`.
