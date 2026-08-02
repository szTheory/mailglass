# 143-MECHANISM.md — HARNESS-01 mechanism account

**Phase:** 143-test-harness-truth
**Plan:** 143-03
**Status:** Evidence artifact for HARNESS-01. Written before any fix code. No file under
`lib/` or `test/support/` is modified by this plan.

This account confirms and widens `.planning/phases/143-test-harness-truth/143-RESEARCH.md`'s
already-established mechanism (run `30464215272`, job `90617762038`) to all three D-31 leak
classes, backed by the instrumented pre-fix ledgers committed alongside it
(`143-LEDGER-public.txt`, `143-LEDGER-mailglass.txt`).

---

## 1. Verdict

The mechanism is confirmed, and it is not what HARNESS-01 and ROADMAP criterion 1 originally
said it is. The nine `:auto`-mode files (`migration_test.exs` and its five siblings, plus the
three property files) **heal** a leaked shared owner rather than colliding with it —
`Sandbox.mode(repo, :auto)` resets the ownership manager's mode and checks in every live
connection, which is exactly what makes a genuine leak survive to poison only the *next*
`async: false, shared: true` acquisition rather than every subsequent test. `Mailglass.DataCase`
is the observed **victim**, never the culprit: its `on_exit(stop_owner)` is registered on the
line immediately following acquisition (`data_case.ex:35-36`), Ecto's own documented idiom.
The two confirmed leak sites are `test/mailglass/properties/webhook_idempotency_convergence_test.exs`
and `test/support/mailer_case.ex` — both share the shape acquire → work that can raise →
register release, with release registered **last**. This local Wave-1 capture reproduces that
exact shape live, in `test/support/mailer_case.ex`, independent of and consistent with the
already-confirmed CI evidence below.

---

## 2. The proven causal chain

**Cited verbatim from RESEARCH.md's already-confirmed account** — this is not re-derived here.
Confirming evidence: GitHub Actions run **`30464215272`**, job **`90617762038`**
(`gh api "repos/szTheory/mailglass/actions/jobs/90617762038/logs"`).

### The `:already_shared` source — exactly one place

`deps/db_connection/lib/db_connection/ownership/manager.ex:148-159`:

```elixir
def handle_call({:mode, {:shared, shared}}, {caller, _}, %{mode: {:shared, current}} = state) do
  cond do
    shared == current      -> {:reply, :ok, state}              # :150-151 idempotent
    Process.alive?(current) -> {:reply, :already_shared, state}  # :153-154 THE ONLY SOURCE
    true                   -> share_and_reply(state, shared, caller)  # :156-157 dead owner replaced
  end
end
```

`:already_shared` is returned **only** when the pool is already `{:shared, pid}`, that `pid` is a
different process, and it is **still alive**. A dead shared owner is transparently replaced.

### The badmatch site

`deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:448-465`:

```elixir
def start_owner!(repo, opts \\ []) do
  parent = self()
  {:ok, pid} =                                   # :451  <-- MatchError surfaces HERE
    Agent.start(fn ->                            # :452  UNLINKED
      set_label({:sql_sandbox_owner, %{started_by: parent}})
      {shared, opts} = Keyword.pop(opts, :shared, false)
      :ok = checkout(repo, opts)                 # :455
      if shared do
        :ok = mode(repo, {:shared, self()})      # :458  <-- badmatch on :already_shared
      else
        :ok = allow(repo, self(), parent)        # :460  <-- shared: false survives a leak
      end
    end)
  pid
end
```

`mode/2`'s own `@spec` (`sandbox.ex:509-510`) declares `:ok | :already_shared | :not_owner |
:not_found`; its `@doc` (`:506-507`) says *"May return `:already_shared` if another process set
the ownership mode to `{:shared, _}` and is still alive."* The bare `:ok =` at `:458` discards
that contract. `:460` is why **`shared: false` (`async: true`) tests survive a leaked owner** —
D-04's falsifiable prediction #1.

### The exact failure term (load-bearing for D-17's classifier)

```
** (MatchError) no match of right hand side value:

     {:error,
      {{:badmatch, :already_shared},
       [
         {Ecto.Adapters.SQL.Sandbox, :"-start_owner!/2-fun-0-", 3,
          [file: ~c"lib/ecto/adapters/sql/sandbox.ex", line: 458]},
         {Agent.Server, :init, 1, [file: ~c"lib/agent/server.ex", line: 12]},
         {:gen_server, :init_it, 2, [file: ~c"gen_server.erl", line: 2276]},
         {:gen_server, :init_it, 6, [file: ~c"gen_server.erl", line: 2236]},
         {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 333]}
       ]}}

     stacktrace:
       (ecto_sql 3.14.0) lib/ecto/adapters/sql/sandbox.ex:451: Ecto.Adapters.SQL.Sandbox.start_owner!/2
       (mailglass 2.2.0) test/support/data_case.ex:35: Mailglass.DataCase.__ex_unit_setup_0/1
```

**A classifier matching `{:badmatch, :already_shared}` at the top level of the ExUnit failure
term matches NOTHING.** The correct structural match is:

```elixir
{:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, _stack}}}, _stack}
```

A separate SASL `crasher:` report (`exception error: no match of right hand side value
already_shared`) is also logged from the dying Agent — that is log noise, not the ExUnit
failure, and it inflates any grep-based count: the CI evidence records 354 raw log hits against
213 total failures on that leg. This local capture shows the same inflation shape: 145 raw
`already_shared` log occurrences in `143-LEDGER-public.txt`'s source run, against a small
handful of distinct ExUnit failure terms actually carrying that shape.

### The Proven Causal Chain (CI evidence, job `90617762038`)

```
1. A schema-isolation / upgrade-migration module leaves Mailglass.Config.schema() == "mailglass"
   on the *public* leg — and the "mailglass" schema has been dropped.        [Class B]
        │
        ▼
2. Mailglass.Properties.WebhookIdempotencyConvergenceTest.setup
     :52-56  owner = Sandbox.start_owner!(TestRepo, shared: true, ownership_timeout: 10*60_000)
     :58     Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)
             └─ raises ** (Postgrex.Error) ERROR 42P01 (undefined_table)
                       relation "mailglass.mailglass_suppressions" does not exist
     :64     on_exit(...)   ◄── NEVER REACHED. No cleanup is registered at all.
        │
        ▼
3. The unlinked Agent from step 2 survives, alive, holding {:shared, agent_pid}.
        │
        ▼
4. Every subsequent async: false start_owner!(shared: true):
     manager.ex:153  Process.alive?(current) == true  →  :already_shared
     sandbox.ex:458  :ok = ...                        →  {:badmatch, :already_shared}
     sandbox.ex:451  {:ok, pid} = {:error, ...}       →  MatchError in the VICTIM's setup
   Victims observed: Mailglass.DataCase:35 (RepoMultiTest, OutboundTest, FakeTest,
   SendGridTest, PostmarkTest, …) — DataCase is the VICTIM, never the culprit.
        │
        ▼
5. Bounded by the 10-minute ownership_timeout, or healed early by any :auto/:manual
   mode switch. 213 failures, not 1450 — the blast radius is bounded, which is
   exactly why no single file reproduces it.
```

D-04 prediction #2 ("the test immediately preceding the first `:already_shared` shows a ledger
start with no matching stop") is confirmed verbatim by this CI log: failure #22 is
`WebhookIdempotencyConvergenceTest`'s setup raising between the acquisition at `:52` and the
`on_exit` at `:64`, and the very next log entry is the first `already_shared` crasher.

### The same shape, reproduced locally (Wave 1, this plan)

This plan's own instrumented capture (`143-LEDGER-public.txt`, public schema axis,
`MAILGLASS_SANDBOX_TRACE=1 mix test --warnings-as-errors --exclude requires_workspace --seed
0`, run against a freshly reset `Mailglass.TestRepo`) independently reproduces the identical
causal shape, in the OTHER confirmed leak site — `test/support/mailer_case.ex`, not the
webhook-idempotency file:

```
38) test call/2 SES Notification end-to-end returns 200 and persists WebhookEvent
    on a valid signed Notification (Mailglass.Webhook.PlugSESTest)
    ** (Postgrex.Error) ERROR 42P01 (undefined_table)
       relation "mailglass.mailglass_suppressions" does not exist
    stacktrace:
      ...
      test/support/citext_probe.ex:123: Mailglass.TestSupport.CitextProbe.default_probe/1
      test/support/mailer_case.ex:99: Mailglass.MailerCase.__ex_unit_setup_0/1
      test/mailglass/webhook/plug_ses_test.exs:1: Mailglass.Webhook.PlugSESTest.__ex_unit__/2

39) test call/2 SES Notification end-to-end returns 200 and persists once on a
    replayed Notification (Mailglass.Webhook.PlugSESTest)
    ** (MatchError) no match of right hand side value:
        {:error,
         {{:badmatch, :already_shared},
          [{Ecto.Adapters.SQL.Sandbox, :"-start_owner!/2-fun-0-", 3,
            [file: ~c"lib/ecto/adapters/sql/sandbox.ex", line: 458]}, ...]}}
    stacktrace:
      (ecto_sql 3.14.0) lib/ecto/adapters/sql/sandbox.ex:451: Ecto.Adapters.SQL.Sandbox.start_owner!/2
      test/support/mailer_case.ex:93: Mailglass.MailerCase.__ex_unit_setup_0/1
```

Test #38's setup calls `start_owner!(shared: not tags[:async])` at `mailer_case.ex:93`
(succeeds), then `CitextProbe.run/1` at `:99` raises before `mailer_case.ex:185/206`'s
`on_exit(stop_owner)` is ever registered — the identical acquire → raise-before-release-registers
shape, in the file D-02 separately names for its own 92-line unguarded window. Test #39, the
very next test in the same module, hits `already_shared` on its own `start_owner!` call —
**both of D-04's predictions hold on this independent, locally-captured evidence too**, and
Class B (the schema drifting to "mailglass" while the run booted at "public") is the confirmed
**trigger** for this instance, exactly as CI evidence shows for its own leg.

---

## 3. Blast radius and duration

`db_connection`'s default ownership timeout is **120 seconds** (`proxy.ex:9`); `config/test.exs`
does not override it. But `webhook_idempotency_convergence_test.exs:53-56` sets it to **ten
minutes**. A leak from *that* file poisons the pool for ten minutes — long enough to swallow
hundreds of sync tests. This is the quantitative core of the blast radius and why that file is
the highest-risk site in the repo.

Four healing paths, all verified against `deps/db_connection`:

| Healing path | Mechanism | Where |
|---|---|---|
| `Sandbox.stop_owner(agent)` | agent exits → proxy's monitor fires → `shutdown/2` → proxy stops → manager `{:DOWN}` → `unshare/2` sets mode `:manual` | `proxy.ex:28,61-63`; `manager.ex:242`, `:402-404` |
| `Sandbox.mode(repo, :auto)` / `(:manual)` | `manager.ex:169-172`'s catch-all → `proxy_checkin_all_except/3` (reached via `proxy_checkin/3` at `:289`) stops every owner → explicit `%{state \| mode: mode, mode_ref: nil}` reset at `manager.ex:171` | `manager.ex:169-172`, `:285-297`, `:299-307` |
| `ownership_timeout` expiry | proxy timer fires → `pool_disconnect` → proxy dies → manager `{:DOWN}` → `unshare` | `proxy.ex:53`, `:77-86`; `manager.ex:242` |
| Agent crash | same effect as `stop_owner` | — |

**A timeout-healed run leaves a harmless zombie Agent alive** — nothing kills it (`Agent.start`
is unlinked and unsupervised). It holds no connection and no mode, so it is harmless, but a
ledger keyed on "is the owner pid alive?" would misread it as still-leaked. **Pool mode, not
agent liveness, is the correct key** — which is exactly what
`Mailglass.TestSupport.SandboxOwnership.probe/1` reads (`:sys.get_state/1`'s `:mode` field, not
any liveness check on a remembered pid).

---

## 4. The three-class inventory

Per-leg counts below are from `143-RESEARCH.md`'s "Current Four-Leg State" table (CI run
`30464215272`, the four `Core Full Suite Advisory` legs), corroborated by this plan's own two
local captures (`143-LEDGER-public.txt`, `143-LEDGER-mailglass.txt`) on the current toolchain
(Elixir 1.19.5 / OTP 28, not the 1.18/OTP 27 CI legs — the mechanism is toolchain-independent,
and this local capture is additional evidence, not a replacement for the CI legs' own numbers).

### Class C — `:pool_mode_leaked` (the sandbox ownership leak)

| | CI leg counts (`already_shared` log hits) | This plan's local capture |
|---|---|---|
| 1.18 / public | 0 | — |
| 1.18 / mailglass | 0 | — |
| 1.19 / public | 354 | **145** (public axis, `143-LEDGER-public.txt`'s source run) |
| 1.19 / mailglass | 0 | 0 (mailglass axis, `143-LEDGER-mailglass.txt`'s source run) |

Confirmed culprit sites (both direct-read AND now independently reproduced live):
`test/mailglass/properties/webhook_idempotency_convergence_test.exs` (CI evidence, run
`30464215272`) and `test/support/mailer_case.ex` (this plan's local public-axis capture, test
#38/#39 in `Mailglass.Webhook.PlugSESTest`, excerpted in §2 above).

### Class B — `:config_schema_drift`

Local public-axis capture: 33 of 46 `42P01` hits are qualified `mailglass.mailglass_suppressions`
— `Mailglass.Config.schema()` resolved to `"mailglass"` during a run booted at `"public"`.
Local mailglass-axis capture: 2 of 10 `42P01` hits are qualified `public.mailglass_events` /
`public.mailglass_deliveries` — the same drift, inverted (drifted back to `"public"` during a
run booted at `"mailglass"`), matching `143-RESEARCH.md`'s "Current Four-Leg State" diagnosis
for the CI mailglass-axis legs exactly.

**Named from direct read, narrowed from CONTEXT.md's six `:schema_isolation`-tagged candidates
to the three that actually manipulate `Mailglass.Config.schema()` on a PER-TEST (not
`setup_all`) `Application.put_env/3` + `:persistent_term.erase({Mailglass.Config, :schema})`
cycle:**

- `test/mailglass/schema_isolation_integration_test.exs` (`:51-52`, `:83-88`)
- `test/mailglass/schema_isolation_immutability_test.exs` (`:44-45`, `:77-82`)
- `test/mailglass/schema_prefix_hardening_test.exs` (`:83-86`, `:107-108`) — **not**
  `:schema_isolation`-tagged (it carries its own `@moduletag :schema_prefix`), so it is a
  *fourth* structural candidate beyond CONTEXT.md's original six-file count, discovered here by
  direct read rather than assumed from the tag.

**A2 verdict: PARTIALLY CONFIRMED, refined rather than pinned to a single file.** The instrument
that would name the exact culprit test — `Mailglass.TestSupport.SuiteTruthFormatter` — probes
`Config.schema()` drift only at `:module_finished` of an `async: false` module, once per module.
All three files above run their drift-and-restore cycle inside a per-TEST `setup`/`on_exit`
pair, not `setup_all` — so a corruption that occurs and self-heals between two tests *inside the
same module's own lifecycle* is structurally invisible to a probe that only checks once, at the
very end of the module. **This is not a hedge; it is the confirmed reason the ledger cannot go
further than "one of these three files, sourced from direct read of their setup/teardown code
and the run's relation-name evidence" — see §7 below and the ledger files' own written
explanation of this exact limitation.** SEED-007's original six-file candidate list is narrowed,
not merely repeated, and one file outside the original tag set
(`schema_prefix_hardening_test.exs`) is added.

### Class A — `:baseline_missing`

Local public-axis capture: 13 of 46 `42P01` hits are UNQUALIFIED (`mailglass_deliveries` ×9,
`mailglass_webhook_events` ×3, `mailglass_events` ×1) — genuinely absent from `public`, this
run's connection default search_path. Local mailglass-axis capture: 8 of 10 hits are unqualified
under a `"mailglass"`-booted run, same class.

**`Mailglass.MigrationTest` (the SEED-007-named candidate) had ZERO failures in BOTH of this
plan's local captures.** Assumption A3 ("Class A is `migration_test.exs`'s incomplete
restoration") is **REFUTED by this run's own evidence** — the file that has historically been
blamed did not fail here, and its own restoration completed successfully both times. The
baseline-missing symptom is nonetheless real (13 and 8 unqualified misses respectively). The
best evidence-supported local attribution: `test/mailglass/upgrade_v2_schema_migration_test.exs`
and `test/mailglass/schema_prefix_hardening_test.exs` are the only OTHER files in the suite that
drop `public.mailglass_*` tables (`clean_public_mailglass!/0`,
`Ecto.Adapters.SQL.Sandbox` `:auto`-mode DDL) and must fully re-run
`restore_suite_baseline_schema/0` before the next module boots — the exact shape a Class A leak
requires. Both are already `async: false` and already known (143-01-SUMMARY) to be architecturally
capable of corrupting-then-restoring state within their own per-test lifecycle, invisible to the
boundary-only probe for the same reason Class B is.

**A3 verdict: REFUTED for `migration_test.exs` specifically, by this run's own evidence.
Re-opened, not closed, per D-31's instruction — the phenomenon persists, but the historically-
named culprit is not implicated here.** The narrowed candidate set is
`upgrade_v2_schema_migration_test.exs` and `schema_prefix_hardening_test.exs`, for the identical
structural reason Class B cannot be pinned to one file: their drift-and-restore cycle runs inside
a per-test `setup`/`on_exit`, invisible to a `:module_finished`-only boundary probe.

---

## 5. D-04's falsifiable predictions

| # | Prediction | Verdict | Evidence |
|---|---|---|---|
| 1 | Every `:already_shared` failure is in an `async: false` module; zero in `async: true` | **PASS** | CI evidence (run `30464215272`): all `already_shared` victims are `Mailglass.DataCase`-based `async: false` modules (`RepoMultiTest`, `OutboundTest`, `FakeTest`, `SendGridTest`, `PostmarkTest`, …). Local evidence: `Mailglass.Webhook.PlugSESTest` (`use Mailglass.WebhookCase, async: false`, confirmed by direct read of `plug_ses_test.exs:2`) and `Mailglass.MailerCase`'s own `shared: not tags[:async]` construction (`mailer_case.ex:93`) — `shared: false` (`async: true`) is structurally incapable of hitting `manager.ex:153-154`'s `Process.alive?` branch, per `sandbox.ex:460`. |
| 2 | The test immediately preceding the first `:already_shared` shows an acquisition with no matching release | **PASS** | CI evidence: failure #22 (`WebhookIdempotencyConvergenceTest`'s setup, `:52` acquire / `:58` raise / `:64` never reached) is followed immediately by the first `already_shared` crasher. Local evidence: test #38 (`PlugSESTest`, `mailer_case.ex:93` acquire / `:99` raise / `:185` never reached) is followed immediately by test #39's `already_shared` MatchError, in the same module. |

Both predictions hold on two independent data sources (the already-confirmed CI log and this
plan's own fresh local capture) across two different confirmed leak sites
(`webhook_idempotency_convergence_test.exs` and `mailer_case.ex`).

---

## 6. Rejected diagnostics, recorded once

| Technique | Why not | Recorded outcome |
|---|---|---|
| `--max-cases 1` | No-op: `ExUnit.Runner.async_loop/4` already runs `async: false` (sync) modules strictly after ALL `async: true` modules have finished, one at a time — there is no async/sync overlap to serialize away. | Observed once, on the public axis (`143-LEDGER-public.txt`): 163 failures / 119 `already_shared` / 36 `42P01` vs. the unrestricted run's 180 / 145 / 46 — materially unchanged, same relation-name shapes, same zero-record ledger. Confirms the prediction. |
| Seed bisection / delta debugging | `:auto`/`:manual`-mode files heal a leaked owner rather than colliding with it (§1), so the leaker and the victim are not adjacent — bisection converges on the wrong pair. Verified: even the two non-`:auto` `:manual` reverts in `deliver_later_test.exs:54` / `deliver_many_test.exs:35` heal, because `on_exit` runs in reverse registration order and their own revert runs before `DataCase`'s `stop_owner`. | Not attempted. |
| Ownership `:telemetry` handler | Neither `Ecto.Adapters.SQL.Sandbox` nor `DBConnection.Ownership` emits ownership telemetry — verified against `deps/`. | Not attempted. |
| A `dev/mix/tasks/` diagnostic task | The instrumentation must run *inside* `mix test` (`MAILGLASS_SANDBOX_TRACE=1 mix test`) so the lane command stays unchanged; a separate Mix task would not observe the same process. | Not built. |
| `mix test --slowest` | Reports duration, not ownership. | Not attempted. |
| JUnit formatter | Adds a forbidden new dependency and still would not observe pool state. | Not attempted. |
| Reproducing in a single file | `start_owner!(shared: true)` in one file succeeds in isolation — the collision needs a *prior* module's leak still alive. SEED-007 already established none does. | Not attempted; consistent with both confirmed sites needing an upstream Class B trigger (schema drift) or a raising Class-A-adjacent statement, neither of which a single file supplies alone. |

---

## 7. What this account does NOT claim

This account does **not** claim a deterministic full-suite reproduction. No single seed, file,
or file pair reliably reproduces every leak class on demand — the healing behavior in §1 makes
even a fixed file pair unstable across seeds (SEED-007's own finding, re-confirmed rather than
re-derived here). The deterministic, mechanism-level regression test is Plan 143-04's job, not
this plan's.

This account also does **not** claim that a zero-record `SuiteTruthFormatter` ledger means no
leak occurred. Both of this plan's own committed ledgers (`143-LEDGER-public.txt`,
`143-LEDGER-mailglass.txt`) recorded **zero** violations, in runs that simultaneously produced
145 and 0 `already_shared` occurrences respectively, and 46 and 10 `42P01` occurrences
respectively, several matching the exact confirmed failure shape in §2. This is not a
contradiction to paper over: the formatter observes ONLY inter-module boundaries
(`:module_finished` of an `async: false` module). A module whose own internal test-to-test
transitions corrupt then restore global state entirely within its own lifecycle — which is
exactly what all three Class B candidate files and both Class A candidate files do, by design,
on every single test inside them — is invisible to a boundary-only probe by construction, not by
a bug in this plan's Wave-1 deliverable (`143-01`'s formatter is correctly reporting "nothing
wrong at the boundaries it checks"; that is a narrower and true claim, not a false "nothing
wrong" claim). **"The ledger reported 0 records" must never be read as "no leak occurred."** Both
committed ledger files state this explicitly, with the specific module list, so a future reader
encountering a quiet ledger on a red run is not misled twice.

Finally, this account does not resolve Class B or Class A to a single named file. It narrows
Class B from CONTEXT.md's six `:schema_isolation`-tagged candidates to three confirmed
schema-flipping files (adding a fourth structural candidate outside the original tag set) and
narrows Class A's candidate set away from the historically-blamed `migration_test.exs` (refuted
by this run's own zero-failure evidence for that file) toward the two other files that perform
the same drop/restore cycle against `public.mailglass_*`. Resolving further would require either
instrumenting at a per-test (not per-module) granularity — a real, buildable extension, not
attempted in this plan — or exactly the seed bisection / delta debugging §6 rejects for
structural reasons. Recording the narrowed-but-unresolved state honestly is preferred over
manufacturing a single-file verdict the evidence does not support.
