---
phase: 143-test-harness-truth
plan: gap-closure-app-env-restore
subsystem: test-harness-truth
tags: [d-31-class-d, harness-01, app-env-restore, seam, credo, anti-vacuity]
status: complete
requires:
  - "143-12 — Finding B, the nondeterministic gating-leg failure this closes"
  - "143-07 — SandboxOwnership.with_schema!/2, the restore-first seam precedent this follows"
provides:
  - "Mailglass.TestSupport.SandboxOwnership.with_app_env!/2 + restore_app_env!/3 — the sanctioned Application-env save/restore"
  - "Mailglass.Credo.NoRawAppEnvRestore — build failure on Application.put_all_env/1 under test/"
  - "A 75-site mechanical audit of every env save/restore in both test trees, 11 affected, all fixed"
  - "Five newly-recorded residual findings, chief among them that SuiteTruthFormatter's four module-boundary probes have NEVER executed"
affects:
  - "test/support/sandbox_ownership.ex"
  - "the seven put_all_env modules + compliance_test.exs, outbound_test.exs, deliver_later_test.exs"
  - ".credo.exs, .planning/WINDOWS.md, .planning/phases/143-test-harness-truth/deferred-items.md"
tech-stack:
  added: []
  patterns:
    - "A restore that cannot express removal is not a restore — put_all_env/1 merges"
    - "One file's local hardening can arm another file's leak; only an exact restore composes"
    - "Verify a claimed mechanism before building on it, even when it comes from a prior plan's summary"
key-files:
  created:
    - credo_checks/no_raw_app_env_restore.ex
    - test/mailglass/credo/no_raw_app_env_restore_test.exs
  modified:
    - test/support/sandbox_ownership.ex
    - test/mailglass/test_support/sandbox_ownership_test.exs
    - test/mailglass/compliance/unsubscribe_test.exs
    - test/mailglass/compliance/unsubscribe_controller_test.exs
    - test/mailglass/properties/unsubscribe_property_test.exs
    - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
    - test/mailglass/router/unsubscribe_router_test.exs
    - test/mailglass/schema_prefix_hardening_test.exs
    - test/mix/tasks/mailglass.gen.unsubscribe_test.exs
    - test/mailglass/compliance_test.exs
    - test/mailglass/outbound_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - .credo.exs
decisions:
  - "Built a seam (with_app_env!/2) plus a Credo check rather than N hand-rolled delete_env copies — the sibling's hand-rolled fix is precisely what armed the other file's leak"
  - "Did NOT adopt the seam in the shared case templates: two async: true modules mutate :mailglass env concurrently and the verification raised for two unrelated tests. Recorded, reverted, and the one async site uses per-key fetch_env restores instead"
  - "Did NOT ship the SuiteTruthFormatter async-gate fix, despite writing and proving it, because resurrecting the probes turns ~15 unrelated pre-existing Class A/C defects into gating-lane violations. Recorded in full instead of shipped half-remediated"
  - "Corrected 143-12 Finding B's stated mechanism, which is false: :tenancy IS pinned at boot in config/test.exs:19"
metrics:
  duration: "~4h"
  completed: "2026-07-30"
  sites-audited: 75
  sites-affected: 11
  residual-findings-recorded: 5
---

# Phase 143 gap closure: the Application-env restore defect — Summary

**The nondeterministic gating-leg failure is closed by a seam and a lint check rather than
by the one-line `delete_env` the finding recommended — because that one-line fix, already
present in the sibling file, is what ARMED the leak. 75 save/restore sites audited, 11
affected, all fixed. Both gating legs are green on the real 1.18.4/OTP 27 toolchain,
including the exact seed that failed in CI. Five residual findings are recorded, the
largest being that this phase's own flagship instrument has never observed anything.**

---

## What was wrong with the diagnosis, stated first

143-12's Finding B says: "`:tenancy` is in no `config/*.exs`, so it is never in the saved
env." **That is false**, and it was checked before anything was changed:

```
$ git blame -L 17,20 config/test.exs
b058da75d (szTheory 2026-04-22) config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant

$ MIX_ENV=test mix run -e '…'
boot :tenancy: Mailglass.Tenancy.SingleTenant
present in get_all_env: true
```

Finding B's `elixir -e` demo is a correct proof of `put_all_env/1`'s merge semantics — on a
synthetic `:demoapp` where the key really is absent. It was mis-applied to `:tenancy`,
where the key is present and therefore *is* restored by a merging write.

The **observation** was right — the lane really does fail nondeterministically on unchanged
code, and `as: :scoped` really does come from a leaked resolver. Only the causal account
was wrong. Building the recommended fix on it would have produced a change that could not
have fixed the failure.

## The actual mechanism, proven live

**Two independent leaks share one idiom.**

**1. `:compliance` leaks on every single run.** Genuinely absent from every `config/*.exs`,
and written by all seven modules that used `put_all_env` as their restore. A merging write
cannot remove it. Same for `:feedback_id`, `:unsubscribe_test_pid`, and three `TestEndpoint`
module keys. Finding B missed this entirely, and it is the deterministic half.

**2. `:tenancy` leaks compositionally — and the sibling's "fix" is the trigger.**
`unsubscribe_property_test.exs`'s `on_exit` ran `put_all_env` *and then*
`Application.delete_env(:mailglass, :tenancy)`, local hardening added because the merging
restore could not remove `UnsafeTenancy`. That leaves the key **absent**. Any module whose
snapshot is taken afterwards has no `:tenancy` key to write back — so *its* merging restore
can no longer remove the resolver **it** installs, and `unsubscribe_test.exs`'s resolver is
the one binding `as: :scoped`. Verified by direct observation, not inference:

| run | `:tenancy` present? | value |
|---|---|---|
| boot (probe only) | **true** | `Mailglass.Tenancy.SingleTenant` |
| after `unsubscribe_property_test.exs` | **false** | `nil` |
| after `unsubscribe_test.exs` alone | true | `Mailglass.Tenancy.SingleTenant` |

Which of the two files runs first is not a property either file can see. That is the
nondeterminism, and it is why **one correct `delete_env` copy is not a fix** — it is the
cause. This is the single strongest argument for the seam.

The collision itself: `Mailglass.Tenancy.scope/2` resolves through
`Application.get_env(:mailglass, :tenancy)`, and `Mailglass.Operator.SupportSummary` binds
`as: :orphan` on the query it hands to it. Reproduced verbatim in a test:

```
** (Ecto.Query.CompileError) can't apply alias `:scoped`, binding in `from` is already aliased to `:orphan`
```

(Note the backticks — the CI quote recorded in `143-12-SUMMARY.md` and `deferred-items.md`
drops them, so an assertion written from that quote silently never matches. The test
asserts the real form and says so in a comment.)

## The audit — 75 sites, 11 affected

Mechanical, not eyeballed: a script classified every `prior = Application.get_env/fetch_env/
get_all_env(...)` capture in `test/`, `mailglass_inbound/test/` and `mailglass_admin/test/`
against the live boot key set of each app, run over `git show HEAD:<file>` so the numbers
are "as found".

| classification | count |
|---|---|
| **AFFECTED — `put_all_env/1` restore (merge cannot remove an added key)** | **7** |
| **AFFECTED — presence-blind `put_env(app, key, prior)` on a key ABSENT at boot** | **4** |
| safe — `fetch_env` + `:error -> delete_env` | 6 |
| safe — guarded `is_nil(prior) -> delete_env` | 46 |
| safe — presence-blind, but key present at boot | 12 |
| **total audited** | **75** |

The four presence-blind ones are the second flavour the orchestrator named: `prior` is
`nil` because the key was absent, and `put_env(app, key, nil)` **creates** the key holding
`nil` rather than removing it — so every later `Application.get_env(app, key, default)`
resolves to `nil` instead of its default. Identical in shape to the `:schema` restore bug
that produced a 104-failure cascade in 143-07. They are
`compliance_test.exs` (`:compliance`, `:feedback_id`), `outbound_test.exs` (`:compliance`)
and `deliver_later_test.exs` (`:compliance`).

**`mailglass_inbound/test/` has ZERO affected sites** — every restore there already uses
`Application.fetch_env/2` with an `:error -> delete_env` branch, or a `restore(key, nil) ->
delete_env` helper. The one flag the first-pass heuristic raised
(`mailbox_case_test.exs:60`) is not a restore at all; it is an assertion that the case
template writes no `:async_*` key. `mailglass_admin/test/` has no `:mailglass` env captures.

All 11 affected sites are fixed.

## The seam, and why a seam

`Mailglass.TestSupport.SandboxOwnership.with_app_env!/2` — same door, same ordering
invariant as `checkout!/1` and `with_schema!/2`: the restore is registered on the statement
immediately following the capture, so a raise anywhere below still restores. Its
`restore_app_env!/3`:

1. `put_env/3`s every captured key back, and
2. `delete_env/2`s every key present at exit that was **not** present at capture — the step
   `put_all_env/1` cannot express — and
3. **verifies** the result equals the capture, raising if not, because a restore that
   cannot confirm it landed is a check reporting success without observing its subject.

It also erases `{Mailglass.Config, :schema}` when the restore actually moves `:schema`,
through the same documented cache boundary `with_schema!/2` uses, and only on a real change.

The raise names **keys only**, never values (T-143-01): `:compliance`'s test fixtures are
secret-shaped and this message reaches CI logs. Asserted in both directions.

**One deliberate non-adoption.** `compliance_test.exs` is `async: true` and mutates env, as
is `clock_test.exs` (`:clock`). A whole-env restore fired from one could delete a key the
other had live. Phase 143 changes no file's `async:` value (D-11/D-31), so that module uses
per-key `fetch_env` + `:error -> delete_env` restores — same semantics for the keys it
owns, no claim over any key it does not. Documented in the seam's own `@doc` so the next
reader does not "fix" the inconsistency.

## The static check

`Mailglass.Credo.NoRawAppEnvRestore` fails the build on `Application.put_all_env/1` under
`test/` **and** `mailglass_inbound/test/` (clean today; linting it stops the idiom arriving
by copy-paste). Allowlist is **two** entries, the same structural pair
`NoRawSandboxOwnership` uses: the seam itself (its `@doc` must quote the banned idiom) and
the seam's mechanism test (which must reproduce the leak). No convenience exemptions.

Deliberately narrow: it catches the idiom that is **never** a correct restore. The
presence-blind `get_env`/`put_env` flavour is not statically decidable — whether `prior` can
be `nil` depends on runtime config — so the check does not guess, and says so in its own
explanation rather than pretending to cover it.

## Mutation evidence

**1. The Credo check.** Reinstated the merging idiom verbatim in
`unsubscribe_router_test.exs`:

```
credo exit WITH mutation  = 16     (issue at unsubscribe_router_test.exs:13:31)
credo exit AFTER revert   = 0
```

File restored byte-identical (`git diff` shows only the intended change).

**2. The seam, in one test, so it cannot pass for the wrong reason.**
`"put_all_env/1 CANNOT remove an added key; with_app_env!/2 can"` reinstates the banned
idiom in its first half and asserts the key **survives** — then runs the same sequence
through the seam and asserts it is **gone**. If `with_app_env!/2` ever degrades into a
merge, half two fails while half one keeps passing.

**3. The CI failure itself, both directions.** With a leaked `as: :scoped` resolver
installed, `Tenancy.scope/2` on an `as: :orphan` query raises the exact
`Ecto.Query.CompileError`; after the seam's restore the same call returns an `%Ecto.Query{}`.
A companion test asserts `support_summary.ex` still contains `as: :orphan`, so the fixture
cannot drift away from the code it stands in for.

**4. The verification path.** Driven through an injectable `:read_fun`, added because the
raise is otherwise unreachable: `with_app_env!/2` always passes a live snapshot, and writing
that back always satisfies the comparison. An earlier draft tried to force it with a
one-key "unsatisfiable" capture — that path **succeeds** (correctly deleting every other
key, including `:schema` and `:repo`) and destroyed the app env for the rest of the file.
The seam's `@doc` records this so nobody retries it.

## Deviations from Plan

### 1. [Rule 1 — Bug] The finding's stated mechanism was wrong; verified before building on it

Recorded above. The orchestrator's instruction to "verify it yourself, don't take it on
trust" is the only reason this was caught.

### 2. [Rule 4 — Architectural, recorded not applied] `SuiteTruthFormatter` has never observed anything

While building a runtime Class D `:app_env_drift` probe as the backstop for the
non-statically-detectable flavour, the probe did not fire — on a suite where the leak was
provably present. Cause:

```elixir
defp async_false?(%ExUnit.TestModule{tags: tags}), do: tags[:async] == false
```

`%ExUnit.TestModule{}`'s `:tags` is `%{}` for every module. Dumped live at
`:module_finished` for a `use ExUnit.Case, async: false` module:

```
%{name: Mailglass.Compliance.UnsubscribeTest, file: "...", state: nil,
  parameters: %{}, tags: %{}, setup_all?: false}
```

The module's own `__ex_unit__/0` returns `tags: %{}` too. So the expression is
`nil == false` → `false`, on every boundary, and **all four module-boundary probes — Class A
`baseline_missing`, Class B `config_schema_drift`, Class C `pool_mode_leaked`, and their
`:cannot_verify` paths — have never executed.** The ledger's `0 record(s)` has never meant
anything. `143-MECHANISM.md` §7 attributed the quiet ledger to the boundary-only
observation window; that explanation is incomplete — the probes were not observing a narrow
window, they were not observing at all.

The formatter's own negative-control tests passed throughout, because
`suite_truth_formatter_test.exs` synthesises `%ExUnit.TestModule{tags: %{async: false}}` —
a shape ExUnit never produces.

Async-ness **is** available, from `%ExUnit.Test{}.tags[:async]` at `:test_started` /
`:test_finished` (verified: `%{async: false, module: Mailglass.Compliance.UnsubscribeTest}`).
A fix was written and run: learn it per module from test events, report `:unknown` as
`:cannot_verify`. With the gate alive, the public-axis suite at seed 590679 reported **103**
module-boundary violations — 88 `app_env_drift`, 13 `cannot_verify`, **2 `pool_mode_leaked`**.

**Not shipped, deliberately.** Resurrecting the probes converts ~15 unrelated, pre-existing
Class A/C defects into gating-lane violations under `MAILGLASS_SUITE_FLOOR=1`, and each
deserves the mutation proof every other guard in this phase received. Shipping it
half-remediated at the end of this session would be the fifth premature-completion incident
this phase has had. It is recorded in `.planning/WINDOWS.md` with the reproduction, the
struct dump, and the violation breakdown — **not masked, not tagged away, not weakened**.

### 3. [Rule 2 — recorded not applied] A green report from a crashed instrument

When `probe_baseline_tables/2` raised (a `DBConnection.ConnectionError` propagating out of
the baseline query), the formatter GenServer died mid-suite and never reached
`:suite_finished` — so `SuiteFloor` read the **unit tests'** synthetic `:persistent_term`
snapshot and printed `already_shared=0, formatter_violations=0` and `0 violation(s)`.
`read_formatter_tally/0`'s `:unavailable -> :cannot_verify` path cannot fire, because the
key is always populated by those unit tests. The moduledoc's ordering argument holds only
while the formatter survives the run. Recorded; needs a run-identity marker in the
snapshot, not merely its presence.

### 4. Two real Class C ownership leaks are live and invisible

Surfaced only by the local async-gate fix: `Mailglass.Webhook.Providers.SES.CertCacheTest`
and `Mailglass.UpgradeV2SchemaGenerationTest` both leave the pool `{:shared, pid}` at their
module boundary; `Mailglass.Outbound.DeliverManyTest` leaves it `:auto`. HARNESS-01's
"`:already_shared` count is exactly zero" passes alongside them because that tally counts
raised failures, not leaked pool modes, and the probe that would have named them never ran.
Recorded.

### 5. The seam was NOT adopted in the shared case templates

Tried (`DataCase`, `MailerCase`, `WebhookCase`) and reverted. The verification raised for
`Mailglass.ComplianceTest` and `Mailglass.Operator.TimelineTest` with **no key added or
removed** — a *value* differed, i.e. a concurrent writer moved the env between one module's
restore and its verify. Root cause is the pre-existing policy violation, not the seam:
`compliance_test.exs` and `clock_test.exs` are `async: true` while mutating env the code
under test reads, which this repo's own async policy (D-11 reason 2) forbids, and Phase 143
may not change any file's `async:` value. Recorded.

### 6. `:tenancy` holds `nil` mid-suite

Found because a mechanism-test precondition asserting
`Application.get_env(:mailglass, :tenancy) != nil` — true at boot, per `config/test.exs:19`
— **failed inside the full suite**. Once any module leaves the key absent or `nil`, every
later presence-blind `prior_tenancy` site propagates the `nil` forward. Benign today only
because `Tenancy.resolver/0` maps `nil` back to `SingleTenant`. The test was rewritten to
establish its own precondition (a mechanism test whose result depends on which modules ran
before it is not a mechanism test); the drift is recorded.

## Known Stubs

None. No placeholder, TODO, FIXME, `@tag :skip`, exclusion, or weakened assertion was
introduced. No test was serialized around a defect and no file's `async:` value changed.
`.dialyzer_ignore.exs` is untouched and stays at 15.

## Threat Flags

None. No network surface, auth path, file-access pattern or schema change at a trust
boundary. Nothing under `lib/` was modified — the entire change is test harness, one Credo
check, and `.credo.exs`.

---

## Verification — raw `mix test` / `mix dialyzer` / `mix credo` output only

No SuiteFloor ledger line and no formatter output was used to validate itself. Every suite
run was preceded by
`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`.

### Gating toolchain (`make toolchain`, Elixir 1.18.4 / OTP 27, 2 vCPU / 4 GB)

Banner confirmed: `gating toolchain confirmed: Elixir 1.18.4 / OTP 27.x`.

| Leg | Command | Result | Exit |
|---|---|---|---|
| public | `mix test --seed 783091 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1620 tests, 0 failures**, 13 excluded, 7 skipped; `total: 1643, excluded: 13, skipped: 7, executed: 1623` | 0 |
| mailglass, **the CI failing seed** | `MAILGLASS_SCHEMA=mailglass mix test --seed 590679 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1620 tests, 0 failures**, 14 excluded, 7 skipped; `total: 1643, excluded: 14, skipped: 7, executed: 1622` | 0 |
| new mechanism + Credo tests | `mix test …sandbox_ownership_test.exs …no_raw_app_env_restore_test.exs …checks_have_tests_test.exs …compliance_test.exs --warnings-as-errors` | **79 tests, 0 failures** | 0 |

### Local (Elixir 1.19.5 / OTP 28)

| Gate | Command | Result | Exit |
|---|---|---|---|
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1606 tests, 0 failures**, 7 skipped (14 excluded); `executed: 1622` | 0 |
| public axis | `mix test --seed 783091 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1607 tests, 0 failures**, 7 skipped (13 excluded); `executed: 1623` | 0 |
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` / `done (passed successfully)` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3935 mods/funs, found no issues.` | 0 |

Executed counts rise from `143-12`'s 1606/1605 to **1623/1622** — the 17 new tests
(11 seam mechanism tests, 12 Credo-check regression tests, minus overlap in the counts as
reported per axis). No test was removed.

### The third acceptance command, reported exactly

`MAILGLASS_SCHEMA=mailglass mix test --seed 590679` (no `--exclude requires_workspace`)
reports **9 failures**. All 9 come from the five `@moduletag :requires_workspace` modules
(`ReferenceHost.*` ×3, `DemoDataTest`, `Publish.PostPublishSmokeContractTest`), and the
cause is environmental, not this change:

```
reference demo app ecto.create failed:
Unchecked dependencies for environment test:
  * boundary (Hex package) — the dependency is not available, run "mix deps.get"
```

Those nested apps have no fetched deps in this worktree, which is exactly what the tag
exists for and why both gating lanes pass `--exclude requires_workspace`. The same seed on
the same axis **with** the flag is 0 failures on both the local and gating toolchains, as
tabled above. Reported rather than quietly dropped.

## Still Open

1. **`SuiteTruthFormatter`'s four module-boundary probes have never run.** Fix written and
   proven locally; not shipped. `WINDOWS.md`, kind `unmet-truth`. **This is the largest
   single finding of this pass** — the phase's flagship instrument has been reporting
   `0 record(s)` without looking at anything.
2. **`SuiteFloor` reports green from a crashed formatter**, reading the unit tests'
   `:persistent_term` write. `WINDOWS.md`.
3. **Two live Class C pool-mode leaks** (`SES.CertCacheTest`, `UpgradeV2SchemaGenerationTest`)
   plus `DeliverManyTest` in `:auto`. `WINDOWS.md`.
4. **The case templates carry no env guard**, because two `async: true` modules mutate env
   concurrently in violation of the repo's own async policy. `WINDOWS.md`.
5. **`:tenancy` holds `nil` mid-suite** despite being pinned at boot. `WINDOWS.md`.
6. **`REQUIREMENTS.md` was not touched, in either direction.** 143-14 owns that file.
7. Prior gap closures' open items are unchanged and none is narrowed here.

## Self-Check: PASSED

| Claim | Verification |
|---|---|
| `credo_checks/no_raw_app_env_restore.ex` created | present; `mix credo --strict` loads it (79 checks, up from 78) |
| `test/mailglass/credo/no_raw_app_env_restore_test.exs` created | present; `checks_have_tests_test.exs` passes, which it did not before |
| All 7 `put_all_env` restores removed | `grep -rn "Application.put_all_env" test/` returns only `@doc`/comment text and the allowlisted mechanism test |
| 11 affected sites fixed | re-running the audit script over the working tree reports 0 AFFECTED |
| Credo check is non-vacuous | mutation: exit 16 with, exit 0 after revert; file restored byte-identical |
| Seam is non-vacuous | in-test mutation asserts `put_all_env` still leaks and `with_app_env!` does not |
| CI exception reproduced | `Ecto.Query.CompileError` asserted by struct + both binding names |
| Both axes green, fresh DB, `--warnings-as-errors` | local 1606/0 and 1607/0; toolchain 1620/0 and 1620/0 |
| Gating toolchain used for gating claims | `make toolchain` banner: `Elixir 1.18.4 / OTP 27.x` |
| Dialyzer / format / credo clean | exits 0, 0, 0; `.dialyzer_ignore.exs` untouched at 15 |
| `REQUIREMENTS.md` untouched | not in `git status --short` |
| No `async:` value changed | `git diff` contains no `async:` edit |
| Findings recorded, not masked | `WINDOWS.md` 5 new `unmet-truth` entries; id 10 marked `fixed`; `deferred-items.md` updated with the corrected mechanism |
