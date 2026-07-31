---
phase: 143
plan: gap-closure-caller-resolution-regression
subsystem: test-harness
tags: [harness-01, d-31, async-guard, caller-resolution, elixir-1.18, ci-regression, version-independence]
status: complete
requires:
  - "Mailglass.TestSupport.SandboxOwnership — checkout!/1, unsandboxed_module/1, mode_manual!/2, scratch_schema!/2, with_search_path!/3 (plans 143-01/04/07/08 + the three prior gap closures)"
provides:
  - "checkout!/1 :context option — the ExUnit context is the async guard's only subject, mandatory when shared: true"
  - "unsandboxed_module/1 unified on the same three-way classification (absent :async now raises rather than defaulting to false)"
  - "Zero process-label reads in test/support — caller resolution is version-independent across Elixir 1.18.4 and 1.19.5"
  - "Two regression tests pinning caller resolution against silent degradation to nil"
affects:
  - "test/support/sandbox_ownership.ex, test/support/data_case.ex, test/support/mailer_case.ex, test/test_helper.exs, test/mailglass/test_support/sandbox_ownership_test.exs, test/mailglass/properties/webhook_idempotency_convergence_test.exs, test/mailglass/outbound/deliver_many_test.exs, test/mailglass/outbound/deliver_later_test.exs"
key-files:
  created: []
  modified:
    - test/support/sandbox_ownership.ex
    - test/support/data_case.ex
    - test/support/mailer_case.ex
    - test/test_helper.exs
    - test/mailglass/test_support/sandbox_ownership_test.exs
    - test/mailglass/properties/webhook_idempotency_convergence_test.exs
    - test/mailglass/outbound/deliver_many_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
metrics:
  process-label-reads-before: 4
  process-label-reads-after: 0
  dialyzer-errors: 0
  dialyzer-ignore-entries-added: 0
  mutation-checks: 3
  new-tests: 3
---

# Phase 143 Gap Closure: caller resolution made version-independent

Commits `8a113924` / `355e7ebb` are green on this machine (Elixir 1.19.5 / OTP 28) and failed
catastrophically on every gating CI lane (Elixir 1.18.4 / OTP 27), runs `30561673591` /
`30561673620`. This closes that regression without reverting any of the legitimate work in
those two commits.

---

## 1. The defect, stated exactly

`guard_shared_checkout_from_async!/1` was hardened to fail closed: it raises when it cannot
establish whether its caller is an `async: true` module. That principle is right. Its
**observation mechanism** was not.

`calling_test_module/0` resolved the caller from `Process.get(:"$process_label")`.
`ExUnit.Runner` sets that label only from **Elixir 1.19.0**:

| Evidence | Result |
|---|---|
| `elixir-lang/elixir` `CHANGELOG.md` @ `v1.19.0`, "#### ExUnit" | `* [ExUnit] Set a process label for each test` |
| `lib/ex_unit/lib/ex_unit/runner.ex` @ `v1.19.0` | `Process.set_label({test.case, test.name})` — line **443** |
| `lib/ex_unit/lib/ex_unit/runner.ex` @ `v1.18.4` (640 lines, fetched whole) | **zero** occurrences of `set_label` or `process_label` |
| Local `ExUnit.Runner` decompiled (1.19.5) | exactly one `Process.set_label` call site |

`mix.exs` declares `elixir: "~> 1.18"`, `.tool-versions` pins `1.18.4`, and every gating job in
`ci.yml` is named "(Elixir 1.18 / OTP 27)". So on **100% of gating runs** the label was never
set, `calling_test_module/0` returned `nil`, `async_classification(nil)` returned `:unknown`,
and the guard raised on **every legitimate shared checkout** — `MailerCase`, `DataCase` and
every module built on them.

The governing rule holds in both directions, and the second half is what was violated:

> A check that cannot observe its subject MUST NOT report success — but equally, it must not
> fire on healthy callers.

A guard whose observation mechanism exists on only one of two supported toolchains does not
fail closed. It fails *everywhere*, for callers that did nothing wrong. The fix is to make the
subject observable, not to make non-observation fatal.

---

## 2. The mechanism chosen: the ExUnit context, and only the ExUnit context

`checkout!/1` now takes `context:` — the map ExUnit hands every `setup`/`setup_all` callback —
and reads `:async` straight out of it. No inference, no process dictionary, no module
interrogation. **When `shared: true`, passing it is mandatory**: the `:unknown` branch is
reachable only by omitting `context:` (a misuse with zero instances in this repo), never by a
runtime declining to volunteer the answer.

```elixir
defp async_classification(context) when is_map(context) do
  case Map.fetch(context, :async) do
    {:ok, true} -> :async
    {:ok, false} -> :sync
    _ -> :unknown
  end
end

defp async_classification(_absent_context), do: :unknown
```

`unsandboxed_module/1` — already context-based, but reading `Map.get(context, :async, false)`,
which silently answered an absent key "not async" — now shares this exact function, so both
guards have one classification with one `:unknown` branch.

**Process-label inference was removed, not demoted to a fallback.** A mechanism that answers on
one supported toolchain and stays silent on the other produces version-dependent behavior
wherever it is consulted; as a fallback it would have made attribution differ by CI lane. There
are now **zero** executable process-label reads under `test/support/` (the two remaining
mentions are prose in the docs explaining why).

### Minimum Elixir version of every API the new mechanism relies on

| API / fact | Introduced | 1.18.4 | 1.19.5 |
|---|---|---|---|
| `Map.fetch/2`, `Map.get/3` | Elixir **1.0** | yes | yes |
| `:async` as a reserved ExUnit context key | long predates 1.18 (`ExUnit.Case` `@reserved`, and *"`:async` - if the test case is in async mode"* in its Context docs) | `case.ex:304` / `:150` | `case.ex:351` / `:155` |
| Runner merges `%{module: module, async: async?}` into the **per-test** context | predates 1.18 | `runner.ex:279` | `runner.ex:292-293` |
| Runner merges `%{module: module, async: async?}` into the **`setup_all`** context | predates 1.18 | `runner.ex:301` | `runner.ex:317` |
| `Process.set_label/1` **in `ExUnit.Runner`** — *no longer used* | **1.19.0** | absent | `runner.ex:443` |

Both `Map.merge` expressions are byte-identical between the two tags (verified by fetching both
files, not inferred). The context is also strictly *wider* coverage than the label ever had: the
label covers only the per-test process, so a `setup_all` block — one of the exact holes the
fail-closed branch was written for — carries no label on **any** version, while it does carry
`:async` and `:module` on **both**.

---

## 3. Call sites changed

| File | Change |
|---|---|
| `test/support/sandbox_ownership.ex` | `:calling_module_fun` → `:context`; `guard_shared_checkout_from_async!/1` and `async_classification/1` read the context; new `context_module/1` for attribution; `calling_test_module/0` **deleted**; `unsandboxed_module/1` unified on the same classification; three `:caller` defaults changed from `Keyword.get(opts, :caller) \|\| calling_test_module() \|\| __MODULE__` to `Keyword.get(opts, :caller, __MODULE__)`; moduledoc "Async guards" rewritten + new "Caller attribution" section |
| `test/support/mailer_case.ex:93` | `checkout!(shared: not async?, context: tags)` |
| `test/support/data_case.ex:35` | `checkout!(shared: not tags[:async], context: tags)` |
| `test/mailglass/properties/webhook_idempotency_convergence_test.exs:50,60` | `setup do` → `setup context do`; `checkout!(..., context: context)` |
| `test/test_helper.exs:168` | `mode_manual!(TestRepo, caller: "test/test_helper.exs (suite boot)")` |
| `test/mailglass/outbound/deliver_many_test.exs:45` | `mode_manual!(TestRepo, caller: __MODULE__)` |
| `test/mailglass/outbound/deliver_later_test.exs:63` | `mode_manual!(TestRepo, caller: __MODULE__)` |
| `test/mailglass/test_support/sandbox_ownership_test.exs` | guard tests rewritten onto synthetic contexts; `FakeAsyncModule`/`FakeSyncModule` deleted (the guard no longer interrogates a module); `setup_all` added to capture the setup_all context; 3 new tests |

Untouched by design: `schema_axis_boot_order_test.exs:30` and the Credo fixture string in
`credo/integration_test.exs:298` both use `shared: false`, where the guard does not run and no
context is needed. `scratch_schema!/2` and `with_search_path!/3` already pass
`caller: __MODULE__` at **every** call site — the process-label default was dead weight there,
and its removal changes no observed attribution.

---

## 4. Audit of `8a113924` / `355e7ebb` for other version-dependent assumptions

As directed — this being the second 1.19-only behaviour to ship as if universal — every runtime
assumption introduced by those two commits was checked against both toolchains:

| Introduced | Version-dependent? |
|---|---|
| `Process.get(:"$process_label")` caller resolution | **YES — the regression.** Fixed here. |
| `Code.ensure_loaded?/1`, `function_exported?/3`, `module.__ex_unit__(:config)` | No. `__ex_unit__(:config)` returns `%{async?: ...}` identically at `case.ex:592-594` (1.18.4) and `case.ex:639-641` (1.19.5). Now unused anyway — deleted with the module-interrogation path. |
| `Process.alive?/1` in `assert_manual!/3`'s exhausted-bound classification | No — Elixir 1.0 / OTP `erlang:is_process_alive/1`. |
| `Ecto.Adapters.SQL.Sandbox.mode/2` return range (`mode_manual!/2` succeed-or-raise) | No — a dependency contract, pinned by `mix.lock`, independent of Elixir. |
| `:sys.get_state/1` + `Ecto.Adapter.lookup_meta/1` in `probe/1` | No — OTP + Ecto, and untouched here per the standing constraint. |
| `LeakError`'s second `message/1` clause, `SuiteFloor`'s `violation_class()` type | No — pure compile-time. |
| The two dropped `@spec`s (`skipped_ceiling/0`, `nudge_margin/0`) | No. Dialyzer's `contract_supertype` verdict is analyzer-version-sensitive in principle, but the `Dialyzer (Elixir 1.18 / OTP 27)` lane was **not** among the failing jobs on runs `30561673591`/`30561673620`, so it is green on both. |

The three substantive changes those commits made — the four Dialyzer contract fixes,
`mode_manual!/2`'s succeed-or-raise contract, and `assert_manual!/3`'s live/dead holder
classification — are all preserved verbatim. `assert_manual!/3`'s caller argument now receives
an exact module (from the context) instead of a value that was `nil`-then-`__MODULE__` on
1.18.4, so its attribution improves as a side effect.

---

## 5. Mutation evidence (non-vacuity)

Each mutation applied alone, everything else in place, then reverted; `sandbox_ownership.ex`
confirmed **byte-identical** to its pre-mutation backup afterwards (`diff` clean).

| # | Defect reintroduced | Result |
|---|---|---|
| **M1** | `data_case.ex` forced to `shared: true` regardless of the module's `async` tag — a genuine, real-path violation from a real `async: true` module | `mix test test/mailglass/events_test.exs` → **14 tests, 14 failures**, every one: `` `checkout!(shared: true)` MUST NOT be called from an async: true module (Mailglass.EventsTest) `` |
| **M2** | The `:async` branch's `raise` neutered (guard classifies but does not fire) | **2 failures** — the direct async-guard test and the no-process-label regression test |
| **M3** | The 1.19-only process-label mechanism reinstated verbatim inside `async_classification/1` | **6 failures**, including the new regression test, failing with the exact CI message: *"could not tell whether its caller is an async: true module"* |

**M1 is the decisive one the directive asked for.** The async-safety guard genuinely fires on a
real violation, through the real `DataCase` path, against a real `async: true` ExUnit module,
naming that module — it is not a synthetic-only check. **M3 is the regression proof**: the new
test fails the instant caller resolution degrades back to reading a process label.

---

## 6. New tests (3)

1. **`the async guard classifies correctly with NO process label present at all`** — deletes
   `:"$process_label"` from the process dictionary (asserting it is then `nil`), so the test runs
   in the *exact* 1.18.4 shape even on 1.19.x, then asserts **both** directions: a real
   `async: true` context still raises, and a healthy `async: false` context still gets through.
   That second assertion is precisely what fails on the pre-fix code, and it is what the
   direction "must NOT raise merely because the runtime declines to volunteer the caller"
   demands. The label is restored in an `after` block.
2. **`ExUnit supplies the guard's subject in every context, on every supported Elixir`** — pins
   the runtime contract the new mechanism depends on: `is_boolean(context.async)` and
   `is_atom(context.module)` in the per-test context, **and** the same pair captured from
   `setup_all` (the context the process label never covered on any version). If a future Elixir
   stops supplying either, this fails loudly instead of the guard silently degrading.
3. **`unsandboxed_module/1 raises when the context carries no boolean :async`** — closes the
   `Map.get(context, :async, false)` hole, with an `async: false` positive control so an
   unconditionally-raising guard cannot pass it.

The four old guard tests were rewritten, not removed: `... when the calling module resolves to
async: true` → `... when the context's :async is true`; `... cannot be resolved` → `... when no
context is supplied at all` (four shapes: absent, `nil`, non-map, `%{}`); a new `... :async is
present but not a boolean`; and the positive control `... when the context's :async is false`.

---

## 7. Acceptance

Every run from a freshly reset DB
(`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`),
`--warnings-as-errors`, read from **raw** `mix test` / `mix dialyzer` / `mix credo` output only —
never the SuiteFloor ledger or the formatter.

| Gate | Command | Result | Exit |
|---|---|---|---|
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace` | 23 properties, **1559 tests, 0 failures**, 7 skipped (14 excluded) | 0 |
| public axis | `mix test --seed 783091 --exclude requires_workspace` | 23 properties, **1560 tests, 0 failures**, 7 skipped (13 excluded) | 0 |
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3903 mods/funs, found no issues.` | 0 |

`signature tally: already_shared=0, formatter_violations=0` on both axes.

**Test-count delta, reconciled exactly:** mailglass 1556 → 1559, public 1557 → 1560. Both **+3**
= 4 old guard tests → 6 (rewritten + 2 net new) plus 1 new `unsandboxed_module/1` test.
No pre-existing test was removed, skipped, excluded, tagged away, serialized around, or
weakened. `.dialyzer_ignore.exs` is **byte-identical** (`git diff` empty) and still at 15
entries. No file's `async:` value changed. `probe/1` and `baseline_tables_present?/1` are
untouched and remain read-only.

---

## 8. Deviations

1. **Process-label inference removed entirely rather than kept as an optional enhancement.** The
   directive permitted keeping it as a non-sole source. Keeping it would have made caller
   *attribution* differ between CI (1.18.4, generic) and local (1.19.5, exact) — the same
   version-dependence class, relocated. `:caller` is passed explicitly at every call site
   instead, including `test_helper.exs` (which, being a script, has no `__MODULE__`).
2. **`unsandboxed_module/1` hardened too, though it was not the reported defect.** Its
   `Map.get(context, :async, false)` was the same "unanswerable question silently answered no"
   shape, two lines from the code being changed, and it now shares one classification function
   with `checkout!/1`.
3. **`FakeAsyncModule` / `FakeSyncModule` deleted.** They existed only to satisfy
   `function_exported?(module, :__ex_unit__, 1)` for the module-interrogation path, which no
   longer exists. Their replacement is two module attributes holding synthetic context maps.

## 9. Not closed

- **Not verified on the real 1.18.4 / OTP 27 leg.** `asdf` is not installed on this machine and
  the process constraints forbid dispatching CI, so the argument is made from the Elixir source
  at both tags (§2) plus a local test that erases the process label to reproduce the 1.18.4
  shape (§6.1) — not from a green 1.18.4 run. The next push to this branch is the confirmation.
- **The prior gap closure's §10 items are unchanged**: the Class C flake's liveness
  classification is still unobserved on the real 1.18/OTP 27 leg; `probe/1` remains mode-keyed
  rather than liveness-keyed; and the formatter's `:module_finished`-only blind spot
  (`143-MECHANISM.md` §7) is untouched. Nothing here narrows any of them.
- **`Mailglass.Credo.NoRawSandboxOwnership` does not (and cannot cheaply) enforce that a
  `checkout!(shared: ...)` call passes `context:`.** The runtime raise is the enforcement; a
  static check would have to reason about whether `shared:` can be truthy. Recorded rather than
  built, since the failure mode is a loud raise at the offending call site on the first run.

## Self-Check: PASSED

- `test/support/sandbox_ownership.ex` — modified, present
- `test/support/data_case.ex` — modified, present
- `test/support/mailer_case.ex` — modified, present
- `test/test_helper.exs` — modified, present
- `test/mailglass/test_support/sandbox_ownership_test.exs` — modified, present
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — modified, present
- `test/mailglass/outbound/deliver_many_test.exs` — modified, present
- `test/mailglass/outbound/deliver_later_test.exs` — modified, present
- `.dialyzer_ignore.exs` — unchanged (`git diff` empty)
- Working tree clean of all three mutations (backup `diff` byte-identical); dialyzer, format,
  credo and both acceptance axes re-verified on the committed state
