# Phase 143: Test-Harness Truth — Research

**Researched:** 2026-07-29
**Domain:** Ecto SQL Sandbox ownership semantics · ExUnit suite-result instrumentation · GitHub Actions publish gating
**Confidence:** HIGH for the mechanism and the CI anatomy (both read from source and confirmed against live run logs); MEDIUM for the floor numbers (measured from a currently-red run, must be re-measured post-fix)

> **Read this first.** Section § "The Premise Has Moved" contains a load-bearing finding that changes what
> Wave 1 must investigate. `SEED-007`'s evidence table (194/242, measured **locally** on 2026-07-28) does
> **not** reproduce on `main` in CI today. The current failure distribution is materially different and is
> dominated by a defect class SEED-007 explicitly ruled out. Do not plan Wave 1 against the seed's numbers.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

`143-CONTEXT.md` is **binding in full**. Its decision bodies are not reproduced here — read that file. The
locked decision headlines, verbatim:

### Locked Decisions

**A. Mechanism Confirmation (HARNESS-01)**

- **D-01: The mechanism is confirmed, and it is not what HARNESS-01 and ROADMAP criterion 1 say it is.**
- **D-02: The two confirmed leak sites, both verified by direct read.**
- **D-03: What is confirmed vs. what Wave 1 must still prove.**
- **D-04: The evidence bar is artifact class (b+): a written mechanism account, backed by a committed ledger dump from an instrumented full-suite run, plus a deterministic *mechanism-level* regression test.**
- **D-05: Ordering/seed bisection is REJECTED as the diagnostic.**

**B. Fix Shape & Recurrence Guard**

- **D-06: One sanctioned door — `Mailglass.TestSupport.SandboxOwnership` at `test/support/sandbox_ownership.ex`.**
- **D-07: Second confirmed defect (S2) — four raw `Sandbox.mode(repo, {:shared, self()})` calls are provable no-ops whose discarded return value is telling them so.**
- **D-08: Recurrence guard is TWO layers, because neither substitutes for the other.** (formatter = detection; Credo check = prevention)
- **D-09: ONE formatter, not three.**
- **D-10: The healing call is safe only because sync modules run strictly after, and strictly serially to, async modules.**
- **D-11: Async policy — a test earns `async: false` only by mutating state global to the pool or the VM.** **Phase 143 changes no file's `async:` value.**
- **D-12: `Sandbox.unboxed_run/2` becomes the documented idiom for new tests needing committed writes, but migrating the existing nine `:auto` files to it is DEFERRED.**

**C. Anti-Vacuity Proof (HARNESS-03)**

- **D-13: Counts come from `ExUnit.after_suite/1`, never from parsing the CLI summary line.**
- **D-14: The load-bearing invariant is the PINNED EXCLUSION-TAG ALLOWLIST, not the count floor.**
- **D-15: Policy lives in `Mailglass.TestSupport.SuiteFloor` (`test/support/suite_floor.ex`) — hardcoded constants, deliberately.**
- **D-16: Floors are PER-SCHEMA and comparison is `>=` with manual raises.** `skipped == 0` is REJECTED; pin a measured ceiling.
- **D-17: The `:already_shared` count becomes a first-class named signature, not a grep and not an inference.** Signature-laundering guard is mandatory.
- **D-18: Two probes, different in kind — both required.**
- **D-18a: FINDING — the existing `gate-self-test.yml` is vacuous against `CI Green`, and Phase 143 is the first honest use of it.**
- **D-18b: Explicitly declined as over-engineering** (mutation testing, coverage gates, external count reporting, per-test-name manifest, flaky quarantine).

**D. Publish Gating & Lane Naming (HARNESS-04)**

- **D-19: Core Full Suite BECOMES publish-gating — but only the two Elixir 1.18 / OTP 27 legs**, matched by exact equality on runtime name.
- **D-20: `Inbound Full Suite Advisory` is NOT gated despite being green today.**
- **D-21: Renames — required, but for a sharper mechanical reason than "honesty."**
- **D-22: `gate-ci-green` must SELF-HEAL `advisory-matrix.yml` by dispatch — this is the default path, not an edge case.**
- **D-23: The gate decision table — three rules, stated plainly.** Plus a dispatch-only override, inert on `release`.
- **D-24: Registry shape — a THIRD axis, disjoint by construction.** Do NOT fold into `all_classified_lanes/0`.
- **D-25: `MAINTAINING.md` gets a NEW `## Advisory Matrix Lanes` section under its OWN heading.**
- **D-26: Branch protection is NOT touched.** `ci_parity_drift_test.exs` is NOT touched.

**E. Sequencing & Evidence**

- **D-27: Wave order is fixed by the requirements' own sequencing constraints.** (1 evidence → 2 fix+guard → 3 anti-vacuity+rename → 4 gating)
- **D-28: A D-14-style blocking checkpoint gates Wave 4 — "observed green in the shape the gate will actually read it," not "merged."** Five conditions.
- **D-29: The gate gets exercised despite "no release cut" — a rehearsal PAIR.**
- **D-30: Known risks accepted, recorded rather than discovered later.**
- **D-31: Upstream artifact amendments this phase MUST make.**

### Claude's Discretion

> The user asked for a single coherent recommendation set rather than choosing per-question, so every
> decision above is Claude's call, made under the CLAUDE.md decision policy (research → synthesize →
> decide → escalate rarely). The genuinely strategic fork — **whether to gate a publish at all** (D-19) —
> was researched from both sides and decided on the cost-asymmetry argument rather than escalated, because
> it is reversible config, not a contract break. If the maintainer disagrees with gating, D-19 and Wave 4
> can be dropped wholesale without disturbing Waves 1-3; HARNESS-04 would then be recorded as a
> deliberate "not gating, and here is why" decision, which ROADMAP criterion 4 explicitly permits
> ("**whether** Core Full Suite is now release-gating").
>
> Left to the planner: exact task decomposition, file-by-file `on_exit`-ordering verification order for the
> nine `:auto` files, and the precise wording of the composed failure messages (drafts exist in the
> research; brand voice per `brandbook/brand-book.md`).

### Deferred Ideas (OUT OF SCOPE)

> - **Migrating the three property files from `:auto` to `Sandbox.unboxed_run/2`** — a genuine improvement
>   (process-local instead of pool-global, removing the bug class for those files), but it is a test
>   redesign mid-milestone. Ship `unsandboxed/2` as the documented forward idiom now; migrate later (D-12).
>   The six migration/schema files **cannot** migrate — `Ecto.Migrator.with_repo/2` spawns a process
>   `unboxed_run` cannot cover.
> - **Fixing `gate-self-test.yml`'s vacuity against `CI Green`** (D-18a) — no `ci.yml` lane runs the root
>   `mix test`, so the probe's injection point is unreachable there. Phase 143 records and verifies the
>   finding; fixing `ci.yml` coverage is a topology change this phase is forbidden. → Phase 144 /
>   `.planning/TOOLING-DEFECTS.md`.
> - **Promoting the Credo lane (sandbox-hygiene enforcement) to merge-gating** — would close the
>   publish-only gap in D-30, but lane re-classification beyond Core Full Suite is out of scope here.
> - **Gating `Inbound Full Suite Advisory`** — blocked on removing its `--seed 0` flake pin (D-20).
>   Revisit with SEED-006/LD-8.
> - **The publish fan-out race** (two `publish-hex` runs per release train) — observed live during this
>   research (D-30). Already scoped as TRUTH-08 / Phase 144; this phase only designs around it.
> - **SEED-006 CI/CD efficiency work** — the dispatched matrix run adds ~10:30 to every release, and the
>   per-directory `deps.get` cost from Phase 142 compounds. Deliberately sequenced after v2.2:
>   "optimizing a pipeline whose greens are not trustworthy just makes it lie faster."
> - **Mutation testing / coverage gates / external count reporting** — explicitly declined with reasoning
>   recorded in D-18b so they are not re-litigated.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (verbatim, `.planning/REQUIREMENTS.md:63-81`) | Research Support |
|----|-------------|------------------|
| HARNESS-01 | "The Ecto Sandbox ownership leak is fixed, with the **mechanism empirically confirmed before the fix is written** rather than inferred. 194 of 242 core-suite failures are `{:badmatch, :already_shared}` from `Sandbox.start_owner!/2`. Leading candidates, all to be verified: `Mailglass.DataCase` (the dominant shared-mode acquisition site, 35 files), `mailer_case.ex:158` and `:248` … and `properties/webhook_idempotency_convergence_test.exs`." | §§ "The Premise Has Moved", "Mechanism Account", "The Proven Causal Chain". The mechanism is now confirmed **from live CI logs**, not just synthetically. The 194/242 numbers, the `DataCase` candidacy, and the `:158`/`:248` framing all need the D-31 amendments. |
| HARNESS-02 | "Core Full Suite passes across all four matrix legs (Elixir 1.18/OTP 27 and 1.19/OTP 28, each × `public` and `mailglass` schema)." | § "Current Four-Leg State" gives the exact per-leg failure inventory. **Three distinct leak classes** must be closed, not one. § "The Matrix" documents leg asymmetries. |
| HARNESS-03 | "The recovered tests are proven to genuinely execute and assert … a test-count floor that fails if the executed count drops, plus a deliberate-failure probe following the existing `gate-self-test.yml` pattern pointed at Core Full Suite." | § "Measuring The Suite Honestly" (with a **hard-verified** reason shell parsing is wrong on this matrix), § "The `gate-self-test.yml` Probe" (with the exact `--required` defect that makes it unusable as-is). |
| HARNESS-04 | "`gate-ci-green` inspects `advisory-matrix.yml` in addition to `ci.yml`, so a Core Full Suite regression blocks a Hex publish. *(Sequenced strictly after HARNESS-01..03 …)*" | § "`gate-ci-green` Anatomy", § "Runtime vs Declared Job Names" (verified live against three event types), § "Demonstrating The Block Without Publishing". |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives that bind this phase's implementation:

| Directive | Applies here as |
|---|---|
| Errors are specific and composed — `"[Noun] [past-tense verb]: [specific cause]"`, never "Oops!" | Every guard raise, formatter violation, and gate `core.setFailed` message. Canonical existing shape: `Delivery blocked: …` (used 8× in `publish-hex.yml`; e.g. `:180`, `:295`, `:309`). |
| "Don't pattern-match errors by message string. Match the struct." | The signature classifier (D-17) must match `%MatchError{term: …}` structurally, not `String.contains?(msg, "already_shared")`. See § "The Exact Failure Term". |
| "Custom Credo checks at lint time" is the repo's native enforcement idiom | D-08's `NoRawSandboxOwnership` joins 20 existing checks in `credo_checks/`; `.credo.exs:180` already carries `requires: ["./credo_checks/*.ex"]` and `:177` already lints `test/`. |
| "`lib/` vs `dev/` vs `test/support/` placement is load-bearing" | All three new modules go to `test/support/` (already on `elixirc_paths(:test)`, `mix.exs:115`). Nothing to `lib/` — that would incur `docs/api_stability.md` + `stability_contract_test.exs` obligations in the **required** Support Contract Core lane. |
| "The fake adapter is the merge-blocking release gate" / advisory lanes never block PRs | HARNESS-04 is **publish**-gating only. Branch protection is untouched (D-26); `required_checks_test.exs:45-58` locks `{CI Green, Guard Release Trigger}`. |
| "Don't use `Application.compile_env*` outside `Mailglass.Config`" | `SuiteFloor` reads `System.get_env("MAILGLASS_SUITE_FLOOR")` and `ExUnit.configuration()` at **runtime**, never `compile_env`. |
| Conventional Commits; `docs(state):` for STATE.md | Commit shapes for the four waves. D-31's upstream artifact amendments are `docs(143):`. |
| No new runtime **or** dev/test dependency | Verified: everything this phase needs exists — see § "Standard Stack". |

---

## Summary

The `:already_shared` mechanism is now **confirmed from live CI logs**, not merely hypothesised or
synthetically reproduced. The complete causal chain — upstream trigger, leak window, propagation, and the
bounded self-heal — is reconstructed below with `file:line` citations into `deps/` and a specific job log
URL. CONTEXT.md's D-01 and D-02 are **correct**; ROADMAP criterion 1's stated hypothesis (`:auto`-mode
siblings *colliding*) is **wrong** in the direction D-01 already predicted (they *heal*).

But the phase's premise numbers have moved. `SEED-007`'s evidence table was measured **locally** on
2026-07-28 (`SEED-007…md:42`). Four legs on `main` today (run `30464215272`, SHA `3edc95f0`) show a
different distribution: `:already_shared` is present on **exactly one leg** (1.19/OTP 28 × `public`, 354
log hits / 213 failures) and **absent from both gating legs**, whose 29 and 12 failures are dominated by
`42P01 undefined_table`. The `42P01` wave is not one defect but **two**, distinguishable by whether the
missing relation name is schema-qualified: an unqualified `mailglass_deliveries` means the migration
baseline was torn down and not restored; a qualified `mailglass.mailglass_suppressions` on the *public*
leg means `Mailglass.Config.schema()` leaked to `"mailglass"` from a schema-isolation test. SEED-007's
binding "already ruled out" list says migration teardown is fixed — that claim does not hold in CI.

The three leak classes are the same disease — **process-global or pool-global state escaping the module
that set it** — and they are causally chained: the schema leak makes `CitextProbe.run` raise inside
`webhook_idempotency_convergence_test.exs`'s unguarded acquire/release window, which strands the shared
owner, which produces every `:already_shared`. Fixing only the ownership window will make the
`:already_shared` signature go to zero on the 1.19 leg and leave HARNESS-02 unmet on the other three.

**Primary recommendation:** keep CONTEXT.md's Wave order and its whole fix design intact — nothing in it is
refuted — but re-scope Wave 1 from "instrument to find the leaker" (already found; cite the log) to
"instrument to inventory *all three* global-state leak classes across all four legs," and re-scope Wave 2
to close all three behind the one sanctioned door plus the two `:schema`/baseline restoration defects. The
`SuiteTruthFormatter` (D-09) is the right instrument for this widened job with **no design change** — add
`:config_schema_drift` and `:baseline_missing` to its `:module_finished` probe alongside the pool-mode
probe, and to its signature tally (D-17) alongside `:already_shared`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Sandbox ownership acquire/release | Test harness (`test/support/`) | — | Pool-global state; the one sanctioned door (D-06) owns it. Never `lib/` (Hex-shipped, API-stability-bound). |
| Suite-global mutable state hygiene (pool mode, `:schema` config, DB baseline) | ExUnit formatter (`test/support/`) | Per-file `on_exit` folded into `checkout!/1` | Only a formatter sees **every** module regardless of case template (D-08). Opt-in guards are invisible to a new file that forgets them. |
| Static prevention of raw sandbox calls | Credo check (`credo_checks/`) | — | Repo's native lint-time enforcement idiom; runs on `test/` already (`.credo.exs:177`). |
| Executed-count / exclusion-tag truth | ExUnit `after_suite/1` callback + pure policy module | `$GITHUB_STEP_SUMMARY` warn | Counts are only knowable in-process; the CLI summary line is **not** a stable contract (proven below). |
| Deliberate-failure probe (does the lane catch a regression?) | GitHub Actions (`gate-self-test.yml`) | — | The thing under test is the *wiring*, not a pure function. Cannot be unit-tested. |
| "Does the floor fail when tests are removed?" | ExUnit unit test (`test/scripts/`) | — | Pure arithmetic over `SuiteFloor.violations/1`. Needs no CI (D-18.1). |
| Publish gating verdict | `publish-hex.yml` `gate-ci-green` job | `Mailglass.CILanes` registry + drift meta-test | Gate is CI-side; registry is the Elixir-side source; drift test is the seam (Phase 141 idiom). |
| Merge gating | **Nobody — deliberately** | — | D-26 / REQUIREMENTS.md "Out of Scope". Four matrix legs per PR is the cost SEED-006 exists to address. |

---

## The Premise Has Moved

**[VERIFIED: GitHub Actions REST API, run `30464215272`, workflow `advisory-matrix.yml`, event `push`, head SHA `3edc95f0`, 2026-07-29T15:06:17Z]**

### Current Four-Leg State

| Runtime job name | properties | `N tests` | failures | excluded | skipped | `already_shared` log hits | `42P01` log hits |
|---|---|---|---|---|---|---|---|
| `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema public)` | 23 | **1450** | 29 | 13 | 7 | **0** | 22 |
| `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema mailglass)` | 23 | **1450** | 12 | 14 | 7 | **0** | 8 |
| `Core Full Suite Advisory (Elixir 1.19 / OTP 28 / schema public)` | 23 | 1437 | **213** | 13 | 7 | **354** | 35 |
| `Core Full Suite Advisory (Elixir 1.19 / OTP 28 / schema mailglass)` | 23 | 1436 | 22 | 14 | 7 | **0** | 19 |

Job ids for log retrieval: `90617762097`, `90617762070`, `90617762038`, `90617762037`.
Retrieve with `gh api "repos/szTheory/mailglass/actions/jobs/<id>/logs"`.

### Reading the table

1. **`:already_shared` does not appear on either gating leg today.** ROADMAP criterion 3's "the
   `:already_shared` failure signature is exactly zero" is *already true* on the two legs D-19 proposes to
   gate. That does not make the guard pointless — it makes the guard the only thing that will keep it true
   — but the plan must not budget Wave 1 as "make 194 failures go away on the 1.18 legs."
2. **The gating legs' failures are `42P01`.** 22 of 29 (1.18/public) and 8 of 12 (1.18/mailglass) log hits
   are `Postgrex.Error ERROR 42P01 (undefined_table)`. Error-kind tally on 1.18/public: 22 `Postgrex.Error`,
   1 `DBConnection.ConnectionError`, remainder assertion failures.
3. **`SEED-007`'s "already ruled out" list is stale on one entry.** It states (`:93-94`) *"Not
   `migration_test.exs` teardown. Its conditional-restoration defect was real and is fixed; the file now
   restores the baseline correctly."* On the 1.18/public leg, `Mailglass.MigrationTest` itself has two
   failures (`migration_test.exs:57` → `:71` `assert rows != []` got `[]`; `migration_test.exs:164` → `:186`
   `assert fn_rows == []` got `[["mailglass_raise_immutability"]]`) and 22 downstream tests then fail on
   missing tables. The seed measured **locally** with a restored baseline DB (`SEED-007…md:42`); CI is a
   cold database created by `mix ecto.create` per run. **The seed's ruling-out is not binding for CI
   conditions.** Record this and re-open the entry.

### Three leak classes, distinguished by the missing relation name

**[VERIFIED: grep of all four job logs]**

| Leg | `relation "…" does not exist` shapes observed | Diagnosis |
|---|---|---|
| 1.18 / public | `mailglass_deliveries` ×26, `mailglass_suppressions` ×18, `mailglass_webhook_events` ×12 — all **unqualified** | **Class A — migration-baseline teardown leak.** `Config.schema()` is `"public"`, search_path is public, the tables are genuinely gone. |
| 1.18 / mailglass | unqualified ×13 **plus** `public.mailglass_deliveries` ×2, `public.mailglass_events` ×2, `public.schema_migrations` ×1 | **Class A + Class B (inverted).** A `public.`-qualified miss on the `mailglass` leg means `Config.schema()` leaked *back* to `"public"`. |
| 1.19 / public | **`mailglass.mailglass_suppressions` ×44** plus unqualified ×38 | **Class B — `Mailglass.Config.schema()` leaked to `"mailglass"` on the public leg**, and that schema had been dropped. This is the trigger for Class C. |
| 1.19 / mailglass | unqualified ×34 plus `public.*` ×4 | Class A + Class B (inverted). |

- **Class A — committed DDL not restored.** `migration_test.exs`'s `down/0` describe and the five sibling
  schema/migration files run `Ecto.Migrator` under `Sandbox.mode(:auto)` — outside any sandbox transaction,
  so the DROPs commit. `migration_test.exs:24-43`'s `on_exit` restores conditionally on
  `baseline_tables_present?()`; the CI evidence says restoration does not always complete.
- **Class B — `Application.put_env(:mailglass, :schema, …)` + `persistent_term` erase leaking across
  modules.** `config/test.exs:15` pins `"public"`; its own comment records that schema-isolation tests
  override it in `setup`. This is exactly D-11's sanctioned-`async: false` reason (2), and it is currently
  unguarded.
- **Class C — the sandbox ownership leak.** The subject of HARNESS-01. Triggered here **by Class B**.

**Planning consequence:** HARNESS-02 ("all four legs green") cannot be met by fixing Class C alone. The
planner must budget Class A and Class B explicitly. They are in scope — HARNESS-02 names the outcome, and
CONTEXT.md's D-11 async policy already names both as sanctioned-`async: false` reasons, so the helper's
guard surface is the natural home for both. Neither requires a topology change or a new dependency.

---

## Mechanism Account

### The `:already_shared` source — exactly one place

**[VERIFIED: `deps/db_connection/lib/db_connection/ownership/manager.ex:148-159`]**

```elixir
def handle_call({:mode, {:shared, shared}}, {caller, _}, %{mode: {:shared, current}} = state) do
  cond do
    shared == current      -> {:reply, :ok, state}              # :150-151 idempotent
    Process.alive?(current) -> {:reply, :already_shared, state}  # :153-154 THE ONLY SOURCE
    true                   -> share_and_reply(state, shared, caller)  # :156-157 dead owner replaced
  end
end
```

`:already_shared` is returned **only** when the pool is already `{:shared, pid}`, that `pid` is a different
process, and it is **still alive**. A dead shared owner is transparently replaced (`:156-157`). CONTEXT.md
D-01 is verbatim correct.

### The badmatch site

**[VERIFIED: `deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:448-465`]**

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

`mode/2`'s own `@spec` (`sandbox.ex:509-510`) declares the return as
`:ok | :already_shared | :not_owner | :not_found`, and its `@doc` (`:506-507`) says *"May return
`:already_shared` if another process set the ownership mode to `{:shared, _}` and is still alive."* The bare
`:ok =` at `:458` discards that contract. `:460` is why **`shared: false` (i.e. `async: true`) tests survive
a leaked owner** — D-01's falsifiable prediction #3, confirmed by construction.

### The exact failure term

**[VERIFIED: job `90617762038` log + local reproduction of the `Agent.start` error shape]**

The `Agent.start` init function raising inside an **unlinked** agent does not propagate — `Agent.start`
returns `{:error, reason}`, and the *outer* `{:ok, pid} =` at `:451` is what ExUnit sees:

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

Locally reproduced, no DB required:

```
$ elixir -e 'IO.inspect(Agent.start(fn -> :ok = :already_shared end))'
{:error, {{:badmatch, :already_shared}, [...]}}
```

**This is load-bearing for D-17.** A classifier matching `{:badmatch, :already_shared}` at the top level of
the ExUnit failure term will match **nothing**. The correct structural match is:

```elixir
{:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, _stack}}}, _stack}
```

A separate SASL `crasher:` report (`exception error: no match of right hand side value already_shared`) is
also logged from the dying Agent — that is log noise, **not** the ExUnit failure, and it inflates any
grep-based count. The 354 log hits on the 1.19/public leg correspond to 213 total failures.

### Every way a leaked shared owner heals — and how long it lasts

**[VERIFIED: `deps/db_connection/lib/db_connection/ownership/manager.ex` + `.../ownership/proxy.ex`]**

The manager monitors the **proxy**, not the owner: `ref = Process.monitor(proxy)` (`manager.ex:278`), and
`mode_ref` is that same ref (`share_and_reply/3`, `manager.ex:388-392`). Therefore:

| Healing path | Mechanism | Where |
|---|---|---|
| `Sandbox.stop_owner(agent)` | agent exits → proxy's `Process.monitor(caller)` fires → `shutdown/2` → proxy stops → manager `{:DOWN}` → `unshare/2` sets mode `:manual` | `proxy.ex:28,61-63`; `manager.ex:242`, `:402-404` |
| `Sandbox.mode(repo, :auto)` / `(:manual)` | falls to `manager.ex:169-172` → `proxy_checkin_all_except(state, [], caller)` → `Proxy.stop` + `unshare` for **every** owner → then `%{state \| mode: mode, mode_ref: nil}` | `manager.ex:169-172`, `:285-297`, `:299-307` |
| **`ownership_timeout` expiry** | proxy timer fires → `pool_disconnect(err, keep_alive? = false, …)` → `{:stop, {:shutdown, err}, state}` → proxy dies → manager `{:DOWN}` → `unshare` | `proxy.ex:53`, `:77-86`; `pool_done/6` `:269-293`; `manager.ex:242` |
| Agent crash | same as `stop_owner` | — |

**Two corrections to record:**

1. **CONTEXT.md D-01.1 cites `manager.ex:402 unshare/2` as what `mode(:auto)` does.** `unshare/2` *is*
   reached (via `proxy_checkin/3` at `:289`), but the authoritative mode reset is the explicit
   `%{state | mode: mode, mode_ref: nil}` at **`manager.ex:171`**. Cite both.
2. **CONTEXT.md D-01 says the leak persists "until something calls `Sandbox.mode/2` or the ownership
   timeout expires."** Verified correct — but the *duration* is the whole story. `db_connection`'s default
   is `@ownership_timeout 120_000` (`proxy.ex:9`); `config/test.exs` does not override it. **But
   `webhook_idempotency_convergence_test.exs:53-56` sets `ownership_timeout: 10 * 60_000`.** A leak from
   *that* file poisons the pool for **ten minutes** — long enough to swallow hundreds of sync tests. This
   is the quantitative core of the blast radius, and it is why that one file is the highest-risk site in
   the repo.

Note also: after a timeout-driven heal the **zombie Agent is still alive** (nothing kills it — `Agent.start`
is unlinked and unsupervised). It holds no connection and no mode, so it is harmless, but a ledger keyed on
"is the owner pid alive?" will see it. Key the ledger on the **pool mode**, not on agent liveness.

### The Proven Causal Chain

**[VERIFIED: job `90617762038` log, failure #22 and the first `already_shared` crasher immediately following it]**

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
                (stack: citext_probe.ex:123 → :78 → :61 →
                        webhook_idempotency_convergence_test.exs:58 __ex_unit_setup_0/1)
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
   exactly why no single file reproduces it (SEED-007:100-101).
```

**Every one of D-01's three corrections and both of D-04's falsifiable predictions is satisfied by this
log.** In particular D-04 prediction #2 ("the test immediately preceding the first `:already_shared` shows
a ledger start with no matching stop") is confirmed verbatim: failure #22 *is*
`WebhookIdempotencyConvergenceTest`'s setup raising between the acquisition at `:52` and the `on_exit` at
`:64`, and the very next log entry is the first `already_shared` crasher.

**HARNESS-01's "empirically confirmed before the fix is written" bar is met by this artifact.** Wave 1
should *cite and re-verify* it (and widen it to Classes A and B on all four legs), not re-derive it.

### The two confirmed leak windows

**[VERIFIED: direct read]**

| Site | Acquire | Statements that can raise before cleanup is registered | Cleanup registered | Release |
|---|---|---|---|---|
| `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | `:52-56` `start_owner!(shared: true, ownership_timeout: 600_000)` | `:58` `CitextProbe.run/1`, `:59` `Tenancy.put_current/1`, `:61` `TRUNCATE …webhook_events`, `:62` `TRUNCATE …events` | `:64` | `:68` `stop_owner(owner)` — the **last** statement inside `on_exit`, after two more `TRUNCATE`s (`:65-66`) and `Tenancy.clear()` (`:67`) |
| `test/support/mailer_case.ex` | `:93` `start_owner!(shared: not async?)` | **`:95`–`:184`, 90 lines**: `CitextProbe.run/1` (`:98`), `Fake.checkout()` (`:100`), `Phoenix.PubSub.subscribe` (`:113-116`), `start_supervised!({Oban, …})` (`:160-162`), `Fake.set_shared/1` | `:185` | `:206` `stop_owner(pid)` — the **last** statement inside `on_exit`, after five preceding restores (`:186-205`) |

Both have the same shape: **acquire → work-that-can-raise → register release**, and **release-last inside a
teardown whose earlier statements can raise**. `test/support/data_case.ex:35-36` is the control — the
`on_exit` is registered on the line *immediately following* acquisition, which is the idiom Ecto's own
`start_owner!/2` `@doc` prescribes (`sandbox.ex:421-428`). D-01.2's exoneration of `DataCase` is verified.

### D-07 (S2) — the four raw `{:shared, self()}` no-ops

**[VERIFIED: direct read + `manager.ex:148-159`]**

| Site | Preceding shared acquisition | Verdict |
|---|---|---|
| `test/support/mailer_case.ex:158` | `:93` `start_owner!(shared: not async?)` in the same setup (`@tag oban:` forces `async: false` via the `:80-91` guard, so `shared: true`) | pool is `{:shared, agent_pid}`, agent alive, `self() != agent_pid` → `manager.ex:154` returns `:already_shared`; **return value discarded**; nothing changes |
| `test/support/mailer_case.ex:248` | `set_mailglass_global/0`'s caller already went through `:93` | same |
| `test/mailglass/outbound/deliver_many_test.exs:17` | `use Mailglass.DataCase, async: false` → `data_case.ex:35` runs first (`ExUnit.CaseTemplate` setups precede the module's own) | same |
| `test/mailglass/outbound/deliver_later_test.exs:37` | same | same |

D-07's correction is verified: the *intent* ("Oban internal processes can access the DB") **is already
satisfied** by `start_owner!(shared: true)` — the pool genuinely is in shared mode. Deletion is
behaviour-preserving. The comment at `mailer_case.ex:153-157` asserts a guarantee the code does not provide;
correct it.

**Arithmetic note for the planner.** CONTEXT.md D-07 says this "removes four of the six raw mode call
sites." That count is scoped to *files that are not the nine `:auto` files and not `test_helper.exs`*:
`mailer_case.ex` ×2, `deliver_later_test.exs` ×2 (`:37`, `:54`), `deliver_many_test.exs` ×2 (`:17`, `:35`)
= 6, of which 4 are the `{:shared, self()}` no-ops. The **total** raw-`Sandbox.*` inventory under `test/` is
larger and the Credo check must account for all of it:

| Call | Count | Sites |
|---|---|---|
| `Sandbox.mode(_, :auto)` | 9 | the nine `:auto` files (`migration_test.exs:23`, `upgrade_v2_schema_migration_test.exs:61`, `schema_prefix_hardening_test.exs:88`, `schema_isolation_integration_test.exs:56`, `schema_isolation_immutability_test.exs:49`, `shipped_migration_divergence_test.exs:48`, `properties/idempotency_convergence_test.exs:43`, `properties/unsubscribe_post_idempotency_property_test.exs:69`, `properties/webhook_suppression_convergence_test.exs:16`) |
| `Sandbox.mode(_, :manual)` | 12 | the nine `:auto` files' `on_exit` reverts + `deliver_later_test.exs:54` + `deliver_many_test.exs:35` + `test_helper.exs:129` |
| `Sandbox.mode(_, {:shared, self()})` | 4 | the S2 no-ops |
| `Sandbox.start_owner!/2` | 3 | `data_case.ex:35`, `mailer_case.ex:93`, `webhook_idempotency_convergence_test.exs:53` |
| `Sandbox.stop_owner/1` | 3 | `data_case.ex:36`, `mailer_case.ex:206`, `webhook_idempotency_convergence_test.exs:68` |
| `Sandbox.checkout/1` | 1 | **`test/mailglass/schema_axis_boot_order_test.exs:27`** — `:ok = Sandbox.checkout(TestRepo)`, no `checkin`, no `on_exit`. Safe (Ecto auto-releases on owner death) but architecturally distinct; the Credo check must either allowlist it or migrate it. |
| **Total** | **32** | across 14 files + `test_helper.exs` |

**Note the two `:manual` reverts in `deliver_later_test.exs:54` and `deliver_many_test.exs:35` are
themselves healing calls** — and because `on_exit` runs in reverse registration order, the file's own
`on_exit` (registered later) runs **before** `DataCase`'s `stop_owner`. So `mode(:manual)` checks in all
connections *including the agent's*, then `stop_owner` stops a connection-less agent. Net: healed. This
widens D-01.1's "healing" set beyond the nine `:auto` files and reinforces D-05's rejection of bisection.

---

## Standard Stack

**No new dependency, runtime or dev/test.** Every mechanism this phase needs is already resolved in
`mix.lock`.

### Core

| Library | Version (from `mix.lock`) | Purpose here | Why standard |
|---|---|---|---|
| `ecto_sql` | **3.14.0** | `Ecto.Adapters.SQL.Sandbox` — `mode/2`, `start_owner!/2`, `stop_owner/1`, `checkout/2`, `allow/4`, `unboxed_run/2` | The only sandbox in the Elixir ecosystem; already the harness. |
| `db_connection` | **2.10.2** | `DBConnection.Ownership.Manager` / `.Proxy` — the actual `:already_shared` source and the ownership timer | Transitive under `ecto_sql`; read for mechanism truth, never called directly. |
| `ecto` | 3.14.1 | — | — |
| `postgrex` | 0.22.3 | `Postgrex.Error` struct for the `42P01` signature match | Already the driver. |
| `ex_unit` (stdlib) | Elixir 1.18.4 / 1.19.5 | `ExUnit.after_suite/1`, `ExUnit.configure/1`, the formatter behaviour (`:module_finished`, `:test_finished`) | Stdlib. |
| `credo` | (dev/test, present) | `Credo.Check` behaviour for `NoRawSandboxOwnership` | 20 checks already live in `credo_checks/`. |
| `jason` | (present) | If a ledger artifact is emitted as JSON | Already a dep. |

Toolchain: `.tool-versions` → `erlang 27.3.4.13`, `elixir 1.18.4`.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| ExUnit formatter for the hygiene probe | `ExUnit.Case` `setup_all` postcondition in each case template | Opt-in. A new mode-switching file that uses neither `DataCase` nor `MailerCase` is invisible — the exact failure mode being guarded (D-08). |
| `ExUnit.after_suite/1` counts | parsing `mix test`'s summary line in bash | **Rejected on correctness, now with hard proof** — see below. |
| `--formatter` CLI flag | `ExUnit.configure(formatters: [...])` in `test_helper.exs` | `--formatter` **replaces** the default list; the lane would lose `ExUnit.CLIFormatter` output (D-09). |
| Ownership telemetry handler | — | **Dead end, verified.** Neither `Ecto.Adapters.SQL.Sandbox` nor `DBConnection.Ownership` emits any `:telemetry` event for mode changes or checkouts. Do not plan it (D-05). |

**Installation:** none.

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages. Every module, behaviour, and API it uses is
either Elixir stdlib or already resolved in `mix.lock` (verified above against the committed lockfile).
CONTEXT.md's scope lock is explicit: *"No new runtime dependency, and no new dev/test dependency either."*

**Packages removed due to `[SLOP]` verdict:** none.
**Packages flagged as suspicious `[SUS]`:** none.

---

## Measuring The Suite Honestly (HARNESS-03)

### The summary line is not a contract — proven on this repo's own matrix

**[VERIFIED: run `30464215272`, four job logs]**

```
Elixir 1.18.4:   23 properties, 1450 tests, 29 failures, 13 excluded, 7 skipped
Elixir 1.19.5:   23 properties, 1437 tests, 213 failures, 7 skipped (13 excluded)
```

Two independent breaking differences **between the two legs of the very matrix HARNESS-02 requires green**:

1. **Field order changed.** `excluded` moved after `skipped` and into parentheses.
2. **The meaning of `N tests` changed.** On 1.18 it is `total`; on 1.19 it is `total - excluded`.
   `1450 - 13 = 1437` (public) and `1450 - 14 = 1436` (mailglass) — exact on both schema axes.

A shell parser pinned to 1.18's shape reads `1437` as the total on the 1.19 legs and silently under-reports
by the exclusion count; one pinned to 1.19's shape fails to parse 1.18 at all. **D-13 is not merely
"brittle vs. robust" — it is "wrong vs. right", and this repo's own matrix is the counterexample.** Put
this table in the `SuiteFloor` moduledoc.

### `ExUnit.after_suite/1` is stable across both legs

**[VERIFIED locally on Elixir 1.19.5 via `Code.Typespec.fetch_types(ExUnit)`]**

```elixir
@type suite_result :: %{
        excluded: non_neg_integer(),
        failures: non_neg_integer(),
        skipped: non_neg_integer(),
        total: non_neg_integer()
      }
```

`ExUnit.after_suite/1` @doc: *"Callbacks set with `after_suite/1` must accept a single argument, which is a
map containing the results of the test suite's execution. If `after_suite/1` is called multiple times, the
callbacks will be called in reverse order."* **[VERIFIED: `Code.fetch_docs(ExUnit)` on 1.19.5]**

The 1.18 shape is `[ASSUMED]` identical (the four numbers all appear in its summary line, and this map has
been stable since Elixir 1.8). **Wave 3 must confirm it on the 1.18 leg** — an `after_suite` callback that
crashes on a missing key would be a self-inflicted vacuity. Guard with `Map.fetch!/2` and a composed message
rather than pattern-matching the whole map.

`ExUnit.configuration()` is also available inside the callback and exposes the **effective merged**
`:exclude` list (CLI `--exclude` ∪ `test_helper.exs`'s conditional `ExUnit.configure/1`) — this is what
D-14's both-directions set-equality reads.

### The exclusion-tag allowlist (D-14) — the complete current source list

**[VERIFIED: direct read]**

| Token | Source | Applies on |
|---|---|---|
| `requires_workspace` | `advisory-matrix.yml:114` and `:217` — `mix test --warnings-as-errors --exclude requires_workspace` | all four legs |
| `public_only` | `test/test_helper.exs:54` — `if schema != "public", do: ExUnit.configure(exclude: [:public_only])` | `mailglass` legs only |

That is the whole set. Note the two legs therefore *legitimately* differ by exactly one tag, which is the
entire justification for D-16's per-schema floors — and the measured data confirms it: `excluded` is 13 on
both `public` legs and 14 on both `mailglass` legs.

The inbound lane's `--seed 0` (`advisory-matrix.yml:353`) is a **different job** and is not part of this
allowlist; it is D-20's reason for not gating that lane.

### Measured baselines (pre-fix, from the run above)

| Quantity | `public` legs | `mailglass` legs | Notes |
|---|---|---|---|
| `total` | **1450** | **1450** | identical across both toolchains — the most stable number |
| `excluded` | 13 | 14 | exactly the `:public_only` delta |
| `skipped` | **7** | **7** | identical on all four legs |
| **executed** = `total - excluded - skipped` | **1430** | **1429** | the number D-15/D-16's floor should key on |

**`skipped == 0` is indeed false today** (D-16 is right to reject it), and the ceiling to pin is **7**, not
the 8 that CONTEXT.md's `5 × @tag :skip + 3 × @moduletag :skip` arithmetic implies. Static grep of `test/`
finds **6** `@tag :skip` and **3** `@moduletag :skip` = 9 declarations; only 7 are reached (the others sit
in excluded modules). **Pin the measured 7, not a grep count.** Record the discrepancy so a future reader
does not "fix" the constant to match the grep.

⚠️ **These are pre-fix numbers from a red run.** D-27 correctly requires the floors be pinned from **green**
runs in Wave 3. Use these only as sanity bounds — if the post-fix `total` is not ≥ 1450, tests were lost.

### The signature tally (D-17)

Signatures the classifier must recognise, with their structural match (never a message-string match — CLAUDE.md):

| Signature | Match | Current count (1.19/public) |
|---|---|---|
| `:already_shared` (raw) | `%MatchError{term: {:error, {{:badmatch, :already_shared}, _}}}` | 213 failures / 354 log hits |
| `:already_shared` (post-fix, composed) | the `SandboxOwnership` error struct or `%RuntimeError{}` the new guard raises — **D-17's mandatory laundering guard** | n/a |
| `:undefined_table` | `%Postgrex.Error{postgres: %{code: :undefined_table}}` (SQLSTATE `42P01`) | 35 log hits |
| `:config_schema_drift` | **NEW — recommended.** `:undefined_table` where the relation name is schema-qualified with a prefix ≠ `Mailglass.Config.schema()` | 44 log hits |
| `:sandbox_ownership` | `DBConnection.OwnershipError`, "cannot find ownership process" (`manager.ex:419-427`) | 0 |
| `:citext_probe` | the `CitextProbe` permanent-fault error | 0 (the honest probe re-raises the underlying `Postgrex.Error` instead) |
| `:other` | everything else | — |

The `:config_schema_drift` split is what makes Class B legible instead of hiding inside `:undefined_table`
— the same argument D-17 makes for `:already_shared` vs. "43 failures."

---

## The CI Surfaces

### The Matrix (`advisory-matrix.yml`)

**[VERIFIED: direct read]**

| | `core_full_suite_advisory` | `core_latest_elixir_advisory` |
|---|---|---|
| job key / `name:` line | `:20` / `:21` | `:133` / `:134` |
| declared `name:` | `Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})` | **byte-identical string** |
| legs | 1.18/27 × {public, mailglass} | 1.19/28 × {public, mailglass} |
| job-level `if:` | none | `:139` `github.event_name != 'pull_request'` |
| cache key | `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` — **not toolchain-parameterised** | `mix-${{ runner.os }}-${{ matrix.elixir }}-${{ matrix.otp }}-…` — toolchain-parameterised (Pitfall 4 note at `:189-192`) |
| suite step | `:113-114` `env: MAILGLASS_SCHEMA` + `run: mix test --warnings-as-errors --exclude requires_workspace` | `:216-217` **identical command** |
| extra steps | `:115-125` — `deps.get` + `ecto.create` in `mailglass_inbound`, then `mix verify.schema_prefix` | **none** |
| seed | random (no `--seed`) | random |

Workflow-level: `on:` = `push[main]`, `pull_request[main]`, `schedule "21 4 * * *"`, `workflow_dispatch`
(`:3-10`). `concurrency: group: advisory-matrix-${{ github.ref }}`, `cancel-in-progress: true` (`:15-17`).

**Three planning consequences:**

1. **Gating the 1.18 legs gates three extra steps** the 1.19 legs do not run: the inbound `deps.get`, the
   inbound `ecto.create`, and `mix verify.schema_prefix`. D-19's blast radius is wider than "Core Full
   Suite" reads. Say so in `MAINTAINING.md`'s new section.
2. **The schema switch** is `MAILGLASS_SCHEMA` → `config/runtime.exs` → `config :mailglass, :schema` →
   `Mailglass.Config.schema()`, read at `test_helper.exs:41`. `test_helper.exs:59-67` additionally puts
   `search_path = "<schema>, public"` on the connection parameters. This is the **exact mechanism Class B
   corrupts** — a leaked `Application.put_env(:mailglass, :schema, …)` desynchronises `Config.schema()`
   from the connection's `search_path` mid-run.
3. **The 1.18 cache key is not toolchain-parameterised.** With only one toolchain in that job today it is
   harmless, but it is a real leg-specific difference. It is **not** an ownership-difference candidate.
4. **`--warnings-as-errors` on `mix test`** is D-30's floating-toolchain risk made concrete: a new 1.18.x
   deprecation warning turns the release gate red with no repo change. CONTEXT.md accepts this deliberately.

### `gate-ci-green` Anatomy (`publish-hex.yml`)

**[VERIFIED: direct read, 633 lines total]**

| Anchor | Line |
|---|---|
| `gate-ci-green:` job, `needs: [prepublish-summary]`, `permissions: {contents: read, actions: write}` | `:115-127` |
| Step "Resolve tagged SHA" — `context.payload.release?.tag_name \|\| context.payload.inputs?.tag \|\| context.sha` | `:128-141` |
| Step "Ensure a completed ci.yml run exists on tagged SHA" — the **existing** anti-recursion self-heal | `:142-189` |
| — dispatch when `!run` | `:169-176` |
| — 30-minute deadline, 20 s poll | `:179-188` |
| Step "Verify CI is green on tagged SHA" | `:190-361` |
| `REQUIRED_LANES` (7, **exact equality**) | `:204-212` |
| `ADVISORY_LANES` (3, prefix) | `:230-234` |
| `PUBLISH_GATING_LANES` (12, prefix) | `:239-256` |
| `STRUCTURAL_LANES` (2, prefix) | `:258-261` |
| `startsWithAny` / `classify` | `:263-271` |
| `total_count === 0` → `setFailed` | `:281-284` |
| required-lane presence loop producing the `(missing)` marker | `:295-305` |
| `blockingFailures` (publish-gating + structural) → `setFailed` | `:311-321` |
| `unclassifiedFailures` → `setFailed` | `:323-330` |
| `unclassifiedGreen` → `core.warning` only | `:332-345` |
| `advisoryFailures` → `core.warning` only | `:347-354` |
| `publish-core: needs: [gate-ci-green]` | `:364-365` |
| `publish-core` "Skip if version already on Hex" idempotency guard | `:394-401` |

**What must change for D-19/D-22/D-23 (all additive; the ci.yml verdict logic stays byte-identical):**

1. A **new step** mirroring `:142-189` but for `advisory-matrix.yml` — with `workflow_id:
   'advisory-matrix.yml'`. D-22 requires **one step, two dispatches (ci.yml + advisory-matrix.yml), one
   shared 30-minute deadline, polled concurrently**. Do not serialise; the existing `:179-188` shape is a
   single-workflow loop and must be generalised to poll a list.
2. Two new JS arrays (`ADVISORY_MATRIX_GATING_LANES` = 2, `ADVISORY_MATRIX_ADVISORY_LANES` = 5) in the
   verify step, plus a second `listWorkflowRuns` + `paginate(listJobsForWorkflowRun)` for
   `advisory-matrix.yml`.
3. **Exact equality** for the two gating lanes (safe — proven below), and a `(missing)`-style presence loop
   with the same weight as `failure` (D-23.1).
4. Two `workflow_dispatch` inputs for the override (`skip_core_full_suite_gate` +
   required `core_full_suite_gate_skip_reason`), inert when `github.event_name == 'release'`.

**Fail-closed idioms already present that the new code must copy:** `data.total_count === 0` → `setFailed`
(`:281`); the `(missing)` marker string, which `lane_classification_drift_test.exs:267-281` asserts still
exists precisely so a zero-job API response cannot fall through to success.

### Runtime vs Declared Job Names

**[VERIFIED: live GitHub API, three event types]**

| Event | Run | Reported names for the two Core Full Suite jobs |
|---|---|---|
| `push` | `30464215272` | Four **distinct, fully interpolated, suffix-free** names: `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema public)`, `… 1.18 / OTP 27 / schema mailglass`, `… 1.19 / OTP 28 / schema public`, `… 1.19 / OTP 28 / schema mailglass` |
| `pull_request` | `30464262578` | The two 1.18 legs interpolate normally; the 1.19 job collapses to **one `skipped` entry** carrying the **literal uninterpolated template** `Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})` |
| declared (`CIYaml.job_names/1`) | — | **one** entry after `MapSet.new(Map.values(…))` — the two identical templates collapse |

**Why the suffix behaviour differs from `Dialyzer`:** GitHub appends ` (<matrix values>)` only when the
job's `name:` contains **no** matrix expression. `ci.yml:452-453` declares `dialyzer` with a *static*
`name: Dialyzer (Elixir 1.18 / OTP 27)` over a `strategy.matrix`, so it reports live as
`Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`. `advisory-matrix.yml:21` and `:134` interpolate **every**
axis, so nothing is appended. This is why `MAINTAINING.md:262-265`'s claim — *"All are matrix lanes whose
display names carry runtime matrix suffixes, so the never-promote rule above applies to them too"* — is
**factually wrong** and must be corrected (D-25 already schedules the rewrite; this is the reason).

**Conclusion (matches D-21 exactly):** exact-equality gating is safe on the gate's path, because publish
reads a `release`/tag/push run where names are interpolated and suffix-free. **No rename is needed for gate
matching.** The rename is load-bearing for two *other* reasons: (a) a registry↔YAML set-equality drift test
would claim 4-leg coverage while proving 2, and (b) on PR runs a **skipped** job reports a string identical
to the gating job's *declared* name. `Core Full Suite (` and `Core Full Suite Next Toolchain Advisory (`
diverge at index 16, so neither is a prefix of the other.

**`CIYaml.expanded_matrix_job_names/1` (D-24) must therefore:** parse `strategy.matrix.include:` rows
(8-space `include:`, 10-space `- key: value`, 12-space `key: value` in this file) and substitute
`${{ matrix.<key> }}` into the `name:` template, producing 7 runtime names for `advisory-matrix.yml`
(2 + 2 + 1 + 2). Carry `required_checks_test.exs:30-34`'s anti-vacuity idiom (`assert MapSet.size(...) > 0`)
plus a negative control (D-30).

### The Registry (`test/support/ci_lanes.ex`)

**[VERIFIED: direct read]**

- `@required_lanes` (7) `:83-91`; `@advisory_lanes_ci` (8) `:94-103`; `@advisory_lanes_browser` (1) `:106-108`;
  `@advisory_classified_lanes` (3) `:114-118`; `@publish_gating_lanes` (12) from `:122`; `@structural_lanes` (2).
- `all_classified_lanes/0` at `:207-210` **composes via public accessors**, and
  `lane_classification_drift_test.exs:442-465` asserts `map_size(job_names) == 24` *and*
  `length(classified) == 24` *and* `MapSet.size(MapSet.new(classified)) == 24`. **D-24's "do not fold" is
  mandatory** — folding breaks all three at once plus the two set-equality tests.
- The **exclusions moduledoc at `:54-63`** calls `Core Full Suite Advisory` a *"cron-only / live-provider
  canar[y]"*. That is factually wrong today (it runs on push, PR, cron and dispatch — `advisory-matrix.yml:3-10`)
  and becomes actively misleading once the lane gates a publish. D-31's amendment is required. The
  *parity* exclusion itself stays correct: `mix ci` runs `test --warnings-as-errors --exclude flaky`
  (`mix.exs:389`), the lane runs `--exclude requires_workspace` — different suites, so D-26's refusal to add
  a parity matcher is right (parity ≠ classification).

### `MAINTAINING.md`

**[VERIFIED: direct read + `lane_classification_drift_test.exs:613-626`]**

`parse_disposition_table/1` bounds itself with `find_required_checks_section/1`, which does
`String.split(md, "\n## ") |> Enum.find(&String.starts_with?(&1, "Required Checks"))`, then keeps every line
starting with `|`, rejects `---` rows and any row whose `|`-split length ≠ 7, and drops the `job id` header.
`:455` asserts **exactly 24 rows**.

**Therefore:** the 7-row advisory-matrix table MUST live under its own `## ` heading. Adding rows inside
`## Required Checks` produces a 31-row failure. This is D-25's warning, verified. Also rewrite the
paragraph at `:259-265` (both its "none gates a merge" claim — now half-true — and its factually wrong
matrix-suffix claim), and amend `:212-216`'s never-promote note to carve out interpolated-name matrix jobs.

### The `gate-self-test.yml` Probe

**[VERIFIED: full read, 177 lines]**

| Element | Line | Behaviour |
|---|---|---|
| `workflow_dispatch` only, inputs `cleanup_only` + `check_name` (default `"CI Green"`) | `:12-22` | no schedule — good, keep it that way (D-18.2) |
| stale-branch/PR cleanup | `:45-58` | closes open `gate-self-test/` PRs, deletes orphan branches |
| injection point | `:66-93` | writes `test/gate_self_test/intentional_failure_test.exs` (`use ExUnit.Case, async: true`, `assert false`), commits, pushes branch `gate-self-test/<epoch>-<run_id>` |
| draft PR | `:95-108` | |
| poll loop | `:110-145` | 25-minute deadline, 30 s sleep |
| outcomes | `:126-136`, `:143-145` | `FAILURE\|FAILED\|CANCELLED\|TIMED_OUT` → `blocked`, exit 0 · `SUCCESS` → `leaked`, **exit 1** · deadline → `timeout`, **exit 1** |
| cleanup | `:147-156` | `if: always()` |
| summary | `:158-176` | writes `blocked` vs `Delivery blocked: … the gate has regressed.` |

**The one defect that blocks reuse as-is — verified:**

```bash
STATUS=$(gh pr checks "$PR" --required --json name,state \
  --jq '.[] | select(.name | startswith(env.CHECK_NAME)) | .state' | head -1)     # :122-124
```

`--required` restricts the query to **required** status checks. Branch protection's required set is exactly
`{CI Green, Guard Release Trigger}` (`required_checks_test.exs:45-58`), and D-26 keeps it that way.
`Core Full Suite (…)` will therefore **never appear**, `$STATUS` will be empty, the `*)` arm treats empty as
`pending`, and the run burns 25 minutes and exits 1 with `result=timeout`. D-18's `required_only: false`
input is not a nicety — it is the difference between a working probe and one that always times out.

D-18's second input requirement is equally verified: the `*)` arm at `:137-141` **cannot distinguish
"pending" from "never appeared."** Add a distinct outcome that, on deadline, prints the checks that *were*
seen (`gh pr checks "$PR" --json name,state`) so the failure names itself.

**D-18a is confirmed.** The only two `mix test` invocations in `ci.yml` are `:355`
(`mix test --exclude property`) and `:362` (`mix test --only property`), **both** under
`working-directory: mailglass_inbound` (`:354`, `:361`). Every root-project lane runs an explicit file list
(`verify.support_contract.core`, `mix.exs:299-301`) or a directory glob
(`verify.mix_tasks` → `test test/mix/tasks/`, `mix.exs:287-289`; `verify.ci_lane_contract` →
`test test/scripts/`, `mix.exs:296-298`). **No `ci.yml` lane executes `test/gate_self_test/`.** A
default-input run of `gate-self-test.yml` against `CI Green` should therefore report `leaked` — i.e. the
existing probe has been vacuous. `mix ci` (`mix.exs:389`) *does* run root `mix test`, but `mix ci` is not a
CI lane. Verify live, record, route the fix to Phase 144 / `.planning/TOOLING-DEFECTS.md` — do **not** fix
`ci.yml` here.

Conversely, `advisory-matrix.yml:114`'s `mix test --warnings-as-errors --exclude requires_workspace` **does**
reach `test/gate_self_test/`, and `core_full_suite_advisory` has no job-level `if:`, so it runs on
`pull_request`. `Core Full Suite` is the first lane for which this probe is meaningful — exactly as D-18a says.

### Demonstrating The Block Without Publishing

**[VERIFIED: `publish-hex.yml:394-401`, `:69`, `:364-365`]**

`publish-core`'s idempotency guard reads the version from `mix.exs` and runs
`mix hex.info mailglass "${VERSION}" | grep -q "Released:"` → `skip=true`. With the current versions already
on Hex, a `dry_run: true` dispatch has **no publish side effect**. `publish-core` is `needs: [gate-ci-green]`,
so a red gate means `publish-core` never starts — which is what ROADMAP criterion 4 asks to demonstrate.

**Both `prepublish-summary` (`:69`) and `publish-core` (`:372`) check out
`${{ github.event.inputs.tag || github.event.release.tag_name }}`, and `workflow_dispatch` runs the
workflow file *as it exists at the dispatched ref*.** D-29's ordering constraint follows directly: create
the throwaway tag **after** the gate change is on `main`, or the rehearsal runs the old gate and proves
nothing.

**D-22's self-heal necessity, verified live:**

| SHA | commit | `ci.yml` runs | `advisory-matrix.yml` runs |
|---|---|---|---|
| `25c74ca0` | `chore: release main (#149)` — **bot-merged** | 1 (`workflow_dispatch` — the existing self-heal) | **0** |
| `3edc95f0` | human-merged | 1 (`push`) | 1 (`push`) |

`advisory-matrix.yml` has no `release:` trigger, so without a dispatch **every** release deadlocks on
`(missing)`.

**D-30's fan-out mitigation, verified constraint:** `advisory-matrix.yml:15-17` is
`group: advisory-matrix-${{ github.ref }}`, `cancel-in-progress: true`. Two concurrent `publish-hex` runs
both dispatching on the *same tag ref* would land in the same group and **cancel each other** — and both
gates would then read `cancelled` and block. Query on `head_sha` (both tags resolve to the same SHA), add a
short randomised settle before dispatching, re-check after. **Do not** change the concurrency group to
`github.sha` — same trap. Add a comment pinning the group shape as load-bearing.

---

## Architecture Patterns

### Suite-state instrumentation and enforcement

```
test/test_helper.exs
  ├─ ExUnit.start()                                                       :1
  ├─ ExUnit.configure(exclude: [:public_only])   if schema != "public"    :54
  ├─ … migrations, TestRepo.start_link, CitextProbe.run …                 :30-127
  ├─ Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)                    :129  BASELINE
  ├─ + ExUnit.configure(formatters: [ExUnit.CLIFormatter,
  │                                  Mailglass.TestSupport.SuiteTruthFormatter])   NEW (D-09)
  └─ + Mailglass.TestSupport.SuiteFloor.install()                                  NEW (D-13/D-15)
          └─ ExUnit.after_suite(&SuiteFloor.check/1)

                      ┌──────────────── every module, no opt-in ────────────────┐
   ExUnit.Runner ───► SuiteTruthFormatter
     async modules      │ :module_finished (async: false modules only)
     first, then        │    ├─ SandboxOwnership.probe(TestRepo)   pool mode == :manual?
     sync modules       │    ├─ Config.schema() == the boot value?         [Class B]  NEW
     one at a time      │    ├─ baseline tables present?                   [Class A]  NEW
     (D-10)             │    ├─ record violation, naming the module
     │                  │    └─ HEAL (Sandbox.mode :manual) so the next ~1200 tests still signal
     │                  │ :test_finished
     │                  └─    classify failure by named signature (D-17), tally
     ▼
   after_suite(%{total:, failures:, excluded:, skipped:})
     └─ SuiteFloor.violations/1   (PURE — the negative control drives THIS function)
          ├─ exclusion-tag allowlist set-equality, both directions   (D-14)
          ├─ executed >= per-schema floor                            (D-16)
          ├─ skipped <= measured ceiling (7)
          ├─ already_shared_total == 0  (raw signature + composed guard error)  (D-17)
          └─ formatter violations == 0
     └─ enforced only when MAILGLASS_SUITE_FLOOR=1  (advisory-matrix.yml, 2 env: additions)

   credo_checks/no_raw_sandbox_ownership.ex   ── prevention, lint time (D-08)
   test/scripts/suite_floor_contract_test.exs ── negative control, required lane (D-18.1)
```

### Pattern 1: Register the release before anything that can raise

**What:** the invariant of `SandboxOwnership.checkout!/1` (D-06).
**When:** every sandbox acquisition in `test/`.
**Example (the repo's own control — this is what the helper must generalise):**

```elixir
# Source: test/support/data_case.ex:35-36 — matches ecto_sql's own documented idiom
#         (deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:421-428)
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
```

The helper's shape, with the two extra obligations CONTEXT.md requires (release-first, match every return):

```elixir
def checkout!(opts \\ []) do
  shared? = Keyword.get(opts, :shared, false)
  owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, opts)

  # Registered on the line immediately after acquisition. Everything else this
  # module does happens AFTER this line, so a raise anywhere below still releases.
  ExUnit.Callbacks.on_exit(fn ->
    :ok = Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
    if shared?, do: assert_manual!(Mailglass.TestRepo, __MODULE__)
  end)

  owner
end
```

### Pattern 2: Heal, then still fail — fail loud and early, not 200 failures later

**What:** the formatter names the offending module at `:module_finished` and restores the pool so the
remaining ~1200 tests still produce signal. The run still fails; it fails *readably*.
**Why it is safe:** `ExUnit.Runner`'s `async_loop/4` waits for `map_size(running) == 0` before spawning any
sync module — sync modules run strictly after, and strictly serially to, async modules. `Sandbox.mode(repo,
:manual)` checks in **all** connections (`manager.ex:169-172`; Ecto's own warning at `sandbox.ex:498-501`),
so running it while async modules were live would be catastrophic. **Comment the reliance at the call
site** (D-10). It is exercised on both the 1.18/OTP 27 and 1.19/OTP 28 legs, so a future Elixir change
surfaces as a matrix divergence rather than silent corruption.

### Pattern 3: Hardcoded registry + drift meta-test + negative control

**What:** `SuiteFloor` (D-15) and the advisory-matrix axis (D-24) are deliberate siblings of
`Mailglass.CILanes`. Hardcoded constants; a drift test; a negative control that exercises the **same**
function the real path uses.
**Existing example:** `lane_classification_drift_test.exs:161-229` — asserts the sanity case first, then
`MapSet.delete/2`s one known entry and asserts `drift/2` reports it *and only it*, in the correct direction.
**Where it runs:** `verify.ci_lane_contract`'s `test test/scripts/` glob (`mix.exs:296-298`) auto-collects
`suite_floor_contract_test.exs` into the **required** `mix_task_tests` lane — **no `mix.exs` change**
(verified: the alias is a directory glob, and `ci.yml:285-292` runs it).

### Pattern 4: Custom Credo check

**What:** `Mailglass.Credo.NoRawSandboxOwnership` bans
`Ecto.Adapters.SQL.Sandbox.{mode, start_owner!, stop_owner, checkout, checkin}` under `test/` outside the
helper.
**Skeleton to copy verbatim:** `credo_checks/no_raw_swoosh_send_in_lib.ex` — `param_defaults` with
`allowed_modules` / `included_path_prefixes` / `forbidden_functions` (`:4-9`), the
`included_path?/2` early return (`:26`), `Macro.traverse` with a `module_stack` prewalk (`:33-40`,
`:47-56`), alias collection (`collect_swoosh_mailer_aliases/1`), and `format_issue/2` with `trigger` +
`line_no` + `column`.
**Config:** `.credo.exs:180` already has `requires: ["./credo_checks/*.ex"]`; `:177`'s `included:` already
covers `"test/"`. The check must resolve `alias Ecto.Adapters.SQL.Sandbox` — **six of the nine `:auto`
files use the aliased form** (`properties/*.exs`, and note `webhook_idempotency_convergence_test.exs:43`).
Allowlist `Mailglass.TestSupport.SandboxOwnership` and decide explicitly on
`schema_axis_boot_order_test.exs:27` (raw `checkout/1`).

### Anti-Patterns to Avoid

- **Rescuing the badmatch.** `rescue MatchError -> retry` makes the symptom vanish and the suite prove less.
  Explicitly named in `.planning/research/v2.2/PITFALLS.md:225`.
- **Blanket `async: false`.** SEED-007 `:85-86` and D-11 forbid it. Also destroys HARNESS-02's
  interpretability: the four-leg evidence is only comparable if the async/sync split is byte-identical
  before and after.
- **`@tag :skip` / new `--exclude` tokens.** D-14's both-directions allowlist equality makes this a hard
  failure on the tag *name*, before any arithmetic.
- **`setup_all`-scoped checkouts.** `PITFALLS.md:240`.
- **Grepping the workflow log for `already_shared`.** Log text is not a contract, it false-positives on any
  test *named* after the bug (someone will write one during HARNESS-01), and — verified above — the SASL
  crasher reports inflate the count 354-vs-213.
- **A committed baseline JSON that CI rewrites.** D-15: a threshold a machine rewrites is an artifact, not
  a decision (the SimpleCov `.last_run.json` failure mode — ratchets on flakes).
- **Adding rows to `MAINTAINING.md` § "Required Checks".** Breaks `:455`'s 24-row assertion.
- **Folding the advisory-matrix lanes into `all_classified_lanes/0`.** Breaks four assertions at once.
- **Changing `advisory-matrix.yml`'s concurrency group to `github.sha` to dedupe the fan-out.** With
  `cancel-in-progress: true` both runs cancel each other and both gates read `cancelled` → block.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Suite counts | bash/awk over `mix test`'s summary line | `ExUnit.after_suite/1` | **Verified wrong**: `N tests` means `total` on 1.18 and `total - excluded` on 1.19 — on this repo's own matrix. |
| Effective exclusion tags | re-parsing `--exclude` out of YAML at runtime | `ExUnit.configuration()[:exclude]` inside `after_suite` | Already merged (CLI ∪ `test_helper.exs`). Re-deriving it re-introduces the drift D-14 exists to catch. |
| Cross-process DB access in tests | new `async: false` modules | `Sandbox.allow/4` (`sandbox.ex:604-606`) | D-11: cross-process delivery is **not** a sanctioned `async: false` reason. |
| Committed (non-transactional) writes in a test | `Sandbox.mode(repo, :auto)` | `Sandbox.unboxed_run/2` (`sandbox.ex:624-625`) | Process-local instead of pool-global — removes the bug class. Forward idiom only; the nine existing files stay (D-12), and six of them genuinely cannot migrate because `Ecto.Migrator.with_repo/2` spawns a process `unboxed_run` cannot cover (`migration_test.exs:19-22`). |
| Per-module hygiene assertion | a `on_exit` postcondition each file must remember | an `ExUnit` formatter (`:module_finished`) | Zero opt-in. ExUnit routes **every** module through the formatter regardless of case template. |
| Detecting whether a lane catches regressions | reasoning about it | `gate-self-test.yml` extended with two inputs | The thing under test is the wiring. Do not rebuild — it already handles cleanup, fail-closed-on-SUCCESS, and orphan branches. |
| Ownership observability | a `:telemetry` handler | the pool-mode probe | **Verified: neither `Ecto.Adapters.SQL.Sandbox` nor `DBConnection.Ownership` emits ownership telemetry.** Dead end. |
| Diagnosing which module leaked | seed bisection / delta debugging | the formatter's `:module_finished` probe | `:auto`/`:manual` files *heal*, so leaker and victim are not adjacent and bisection converges on the wrong pair (D-05a). |

**Key insight:** every "just parse the output" or "just add a tag" shortcut in this domain reproduces the
milestone's originating defect in miniature — a check that reports a number it cannot actually justify.

---

## Common Pitfalls

### Pitfall 1: Fixing Class C and declaring HARNESS-02 met

**What goes wrong:** the ownership fix lands, the 1.19/public leg's 213 failures collapse, and the two
gating legs are still red on `42P01`.
**Why:** three distinct global-state leak classes are conflated under one requirement.
**Avoid:** treat Class A (migration baseline) and Class B (`:schema` config) as first-class Wave 1/2 work.
**Warning sign:** a Wave 2 exit criterion phrased as "`:already_shared` is zero" rather than "all four legs
are green."

### Pitfall 2: The signature classifier matches nothing

**What goes wrong:** D-17's tally reports `already_shared == 0` from day one because it matches
`{:badmatch, :already_shared}` at the top level.
**Why:** the unlinked `Agent.start` wraps it — ExUnit sees
`%MatchError{term: {:error, {{:badmatch, :already_shared}, _}}}`.
**Avoid:** write the classifier against the verbatim term captured above; add a unit test in
`suite_floor_contract_test.exs` that feeds it that exact term and asserts a non-zero tally. **This is the
single highest-risk vacuity in the phase** — a signature guard that can never fire.
**Warning sign:** no test in the phase ever exercises the classifier with a real captured failure term.

### Pitfall 3: The deliberate-failure probe passes by timing out

**What goes wrong:** `gate-self-test.yml` polls with `--required`, never sees the lane, sleeps for 25
minutes, and the maintainer reads `result=timeout` as "inconclusive."
**Avoid:** D-18's `required_only: false`, plus a distinct never-appeared outcome that prints the checks it
*did* see. `exit 1` on timeout is already correct (`:145`) — keep it.
**Warning sign:** the probe's evidence in the phase artifact is a run URL with no `result=blocked`.

### Pitfall 4: The gate deadlocks the hands-free release pipeline

**What goes wrong:** release-please bot-merges, `push` is suppressed for **both** workflows, no
`advisory-matrix.yml` run exists, gate reads `(missing)`, publish stalls unattended.
**Avoid:** D-22's dual-workflow self-heal is mandatory, not optional — verified against SHA `25c74ca0`
(0 advisory-matrix runs). Bound the deadline, name the recovery command in every message, keep the
dispatch-only override (D-23) inert on `github.event_name == 'release'`.
**Warning sign:** the new poll step waits 30 minutes for ci.yml *then* 30 for advisory-matrix.

### Pitfall 5: `MAINTAINING.md` edits break the 24-row assertion

**What goes wrong:** the 7 advisory-matrix rows go inside `## Required Checks`; `parse_disposition_table/1`
returns 31; `:455` fails.
**Avoid:** own `## ` heading. Verified against `:613-626`.

### Pitfall 6: A "helpful" merge of the third registry axis

**What goes wrong:** `all_classified_lanes/0` is bound by set-equality to `ci.yml`'s 24 jobs. Folding the
advisory-matrix lanes in breaks `:442-465` (three assertions) plus both set-equality tests plus the
MAINTAINING table comparison.
**Avoid:** state the "do NOT fold; the six hardcoded counts at `ci_lanes.ex:71/88/105/143` and
`lane_classification_drift_test.exs:252/257/455` are UNCHANGED" instruction in the plan text itself.

### Pitfall 7: The healing call runs while async modules are live

**What goes wrong:** `Sandbox.mode(repo, :manual)` checks in **all** connections
(`manager.ex:169-172`); async modules mid-flight lose their connections.
**Avoid:** probe and heal only at `:module_finished` for `async: false` modules, and document the
`ExUnit.Runner` ordering reliance at the call site (D-10).

### Pitfall 8: `mix verify.schema_prefix` is inside the gated legs

**What goes wrong:** the plan reasons about "Core Full Suite" as one `mix test` invocation; the 1.18 job
actually has three more steps after it (`advisory-matrix.yml:115-125`), any of which can red the gate.
**Avoid:** name all four steps in `MAINTAINING.md`'s new section and in the D-28 checkpoint evidence.

### Pitfall 9: New YAML parsing passes vacuously

**What goes wrong:** `expanded_matrix_job_names/1` returns `MapSet.new()` after a whitespace change; every
set-equality passes trivially.
**Avoid:** `required_checks_test.exs:30-34`'s idiom (`assert MapSet.size(...) > 0` with a message naming
the parser) **plus** a negative control that removes one known name and asserts the drift is reported.

---

## Code Examples

### Reading the effective exclusion set (D-14)

```elixir
# Source: verified against ExUnit 1.19.5 (Code.Typespec.fetch_types/1, Code.fetch_docs/1)
defmodule Mailglass.TestSupport.SuiteFloor do
  @exclusion_allowlist MapSet.new([:requires_workspace, :public_only])

  def install do
    ExUnit.after_suite(&__MODULE__.check/1)
  end

  def check(results) do
    effective = ExUnit.configuration() |> Keyword.get(:exclude, []) |> MapSet.new()

    case violations(results, effective, Mailglass.Config.schema()) do
      [] -> :ok
      violations -> report_and_halt(violations)
    end
  end

  # PURE. test/scripts/suite_floor_contract_test.exs drives THIS function with
  # synthetic reports — the negative control exercises the real code path.
  def violations(%{total: t, excluded: e, skipped: s, failures: _f}, effective, schema) do
    []
    |> tag_allowlist_violation(effective)      # BOTH directions (D-14)
    |> floor_violation(t - e - s, schema)      # >= (D-16)
    |> skipped_ceiling_violation(s)
    |> signature_violations()                  # already_shared == 0, raw AND composed (D-17)
  end
end
```

### Classifying the `:already_shared` failure (D-17)

```elixir
# Source: the verbatim ExUnit failure term captured from
# https://github.com/szTheory/mailglass/actions/runs/30464215272 (job 90617762038)
#
# NOT `{:badmatch, :already_shared}` — the unlinked Agent.start/1 in
# ecto_sql/lib/ecto/adapters/sql/sandbox.ex:452 wraps it in {:error, reason},
# and the outer `{:ok, pid} =` at :451 is what raises.
def signature({:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, _}}}, _}),
  do: :already_shared

# Signature-laundering guard (D-17, MANDATORY): once SandboxOwnership composes its
# own error, criterion 3 passes vacuously unless BOTH shapes are counted.
def signature({:error, %Mailglass.TestSupport.SandboxOwnership.LeakError{}, _}),
  do: :already_shared

def signature({:error, %Postgrex.Error{postgres: %{code: :undefined_table}} = e, _}) do
  if schema_qualified_foreign_prefix?(e), do: :config_schema_drift, else: :undefined_table
end

def signature(_), do: :other
```

### Probing the pool without touching it (D-08)

```elixir
# Reads the manager's mode. :already_shared is returned, not raised, so a probe
# that re-asserts the CURRENT mode is a safe no-op:
#   manager.ex:150-151  shared == current -> {:reply, :ok, state}
#   manager.ex:165-167  {:mode, mode} when state.mode == mode -> {:reply, :ok, state}
def probe(repo \\ Mailglass.TestRepo) do
  case Ecto.Adapters.SQL.Sandbox.mode(repo, :manual) do
    :ok -> :ok
    other -> {:leaked, other}
  end
end
```

⚠️ **Design note the planner must resolve:** `mode(repo, :manual)` is not read-only — when the pool *is*
leaked it both detects **and** heals in one call (`manager.ex:169-172`). That is exactly what D-08 wants at
`:module_finished`, but it means the probe cannot distinguish "was already `:manual`" from "was leaked and I
fixed it" from the return value alone. Compare against a *recorded expectation* (the module declared
`async: false` and used `unsandboxed_module/1`?) rather than inferring from the return.

### The negative-control idiom to copy

```elixir
# Source: test/scripts/lane_classification_drift_test.exs:161-229
test "negative control: removing one entry makes the drift comparison report it" do
  assert drift(parsed, @registry) == {MapSet.new(), MapSet.new()},
         "sanity check failed: ... should agree before the injected-breakage assertion runs"

  removed = "Installer Host Smoke"
  assert removed in MapSet.to_list(parsed)

  {only_in_broken, only_in_registry} = drift(MapSet.delete(parsed, removed), @registry)

  assert only_in_registry == MapSet.new([removed]),
         "a vacuous pass is exactly the failure mode this test excludes: ..."
  assert MapSet.size(only_in_broken) == 0
end
```

---

## Empirical Confirmation Technique (HARNESS-01)

### What is already proven — cite, don't re-derive

The full causal chain is in the job log for run `30464215272`, job `90617762038`. **Capture that log into
the phase artifact in Wave 1** (`gh api "repos/szTheory/mailglass/actions/jobs/90617762038/logs"`), excerpt
the failure-#22 → first-crasher sequence, and record both D-04 predictions as **pass** with the excerpt as
evidence. That satisfies HARNESS-01's "empirically confirmed before the fix is written" bar for Class C.

### What Wave 1 must still produce

1. **A four-leg, three-class inventory.** Instrument with `MAILGLASS_SANDBOX_TRACE=1 mix test` (D-05: keep
   the lane command unchanged; no `dev/mix/tasks/` diagnostic — the instrumentation must run *inside*
   `mix test`). Record, per `async: false` module boundary: pool mode, `Mailglass.Config.schema()`,
   baseline-table presence. Commit the ledger.
2. **The Class A culprit** — which module's teardown leaves the baseline missing, and why
   `migration_test.exs:24-43`'s conditional restoration does not complete under CI conditions. Candidate
   evidence already in hand: `MigrationTest` failures at `:57→:71` and `:164→:186` on 1.18/public.
3. **The Class B culprit** — which module leaves `Config.schema()` at a non-boot value. Candidates are the
   six `:schema_isolation`-tagged files; `config/test.exs:12-15`'s own comment names the mechanism
   (`Application.put_env` + `persistent_term` erase).
4. **Seed stabilisation for reproducibility only.** `--seed 0` makes the ledger artifact reproducible.
   Record the `--max-cases 1`-changes-nothing negative control **once**: `ExUnit.Runner.async_loop/4` runs
   sync modules strictly after all async modules, one at a time, so there is no async/sync overlap to
   serialise away. Do not plan around bisection (D-05).
5. **Refutation budget.** D-03 explicitly permits Wave 1 to refute D-01/D-02. The evidence above makes that
   unlikely for Class C, but Classes A and B are genuinely open.

### Techniques that will not help here — record so they are not tried

| Technique | Why not |
|---|---|
| `--max-cases 1` | No-op for this bug: sync modules already run serially, after all async modules. |
| Seed bisection / delta debugging | `:auto`/`:manual` files heal, so leaker and victim are not adjacent (D-05a). Verified: even `deliver_later_test.exs:54` and `deliver_many_test.exs:35` heal. |
| Ownership `:telemetry` handler | No such events exist in either library. Verified against `deps/`. |
| `mix test --slowest` | Reports duration, not ownership. |
| JUnit formatter | Adds a dependency (forbidden) and still would not see pool state. |
| Reproducing in a single file | SEED-007 `:100-101` — none does. `start_owner!(shared: true)` in one file succeeds; the collision needs a *prior* module's leak. |

---

## Runtime State Inventory

This is a test-harness and CI-config phase, but its whole subject matter *is* runtime state. Inventory:

| Category | Items found | Action required |
|---|---|---|
| **Stored data** | The CI Postgres service is created fresh per job (`mix ecto.create`, `advisory-matrix.yml:100-104`). **But within a run** three pieces of DB state escape module boundaries: the migration baseline (Class A), the `mailglass` schema's existence (Class B), and `schema_migrations` rows. No production/local datastore is touched. | Code + test-harness fix; no data migration. |
| **Live service config** | GitHub branch protection required contexts — **explicitly NOT touched** (D-26; asserted by `required_checks_test.exs:45-58` to be exactly `{CI Green, Guard Release Trigger}`). The two job **display names** change (D-21), which is a YAML change, not a live-config change, because neither is a required context. | None. Verify the required-context set is unchanged post-merge. |
| **OS-registered state** | None. No cron on the host, no scheduler entries. `advisory-matrix.yml:8-9`'s `schedule: "21 4 * * *"` is a workflow trigger and is unchanged. **`gate-self-test.yml` must remain `workflow_dispatch`-only** (D-18.2) — adding a schedule would open real PRs against `main` on a cadence. | None. |
| **Secrets / env vars** | Two **new** `env:` keys on the two full-suite steps: `MAILGLASS_SUITE_FLOOR=1` (D-15). No secret changes. `HEX_API_KEY` stays inside the `hex-publish` environment. `BRANCH_PROTECTION_PAT` / `RELEASE_PLEASE_PAT` untouched. `MAILGLASS_SANDBOX_TRACE` is a Wave-1-only opt-in and must not be set in any lane. | Add the two `env:` lines; assert `MAILGLASS_SUITE_FLOOR` presence in the D-15 drift test so the opt-in cannot silently disappear. |
| **Build artifacts** | `_build/test/lib/mailglass/priv/repo/migrations/` — the CI logs show `warning: redefining module Mailglass.TestRepo.Migrations.MailglassInit` during migration re-runs, which is expected. `test/gate_self_test/intentional_failure_test.exs` is injected on a throwaway branch and cleaned up by `gate-self-test.yml:147-156`; the throwaway tags from D-29 must be deleted (D-29 already requires it). No installed-package artifacts. | Delete D-29's two rehearsal tags; record both run URLs. |

**Nothing found in a category:** OS-registered state — none; verified by grepping all four workflow files
for `schedule:` (only `advisory-matrix.yml:8` and unchanged) and by the absence of any host-side scheduler
in this repo.

---

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.18.4 per `.tool-versions`; 1.19.5 on the next-toolchain legs) |
| Config file | `test/test_helper.exs` (`ExUnit.start()` at `:1`; conditional `ExUnit.configure(exclude: [:public_only])` at `:54`) |
| Quick run command | `mix test test/scripts/ --warnings-as-errors` (≈ seconds; the `verify.ci_lane_contract` alias, `mix.exs:296-298`) |
| Full suite command | `mix test --warnings-as-errors --exclude requires_workspace` (≈ 8 min per leg; observed `Finished in 478.3 seconds`) |
| Lint gate | `mix credo --strict` (`.credo.exs`, `requires: ["./credo_checks/*.ex"]` at `:180`) |

### Phase Requirements → Test Map

| Req | Behavior | Test type | Automated command | Exists? |
|---|---|---|---|---|
| HARNESS-01 | The mechanism account is written and cites the confirming run | doc contract | `mix test test/scripts/ --warnings-as-errors` (a docs-contract assertion over the artifact, same idiom as Phase 140 DOC-01) | ❌ Wave 1 |
| HARNESS-01 | A leaked shared owner produces `:already_shared` on the next `start_owner!(shared: true)`; `shared: false` survives; `stop_owner`/`mode(:auto)` heal | unit (mechanism-level regression, D-04) | `mix test test/mailglass/test_support/sandbox_ownership_test.exs -x` | ❌ Wave 2 |
| HARNESS-01 | `checkout!/1` registers release before any statement that can raise | unit | `mix test test/mailglass/test_support/sandbox_ownership_test.exs --only release_first` | ❌ Wave 2 |
| HARNESS-01 | The four S2 no-ops are deleted; `set_mailglass_global/0` semantics unchanged | unit + grep tripwire | `mix test test/mailglass/mailer_case_test.exs` + `mix credo --strict` | ⚠️ `mailer_case_test.exs` exists; add assertions |
| HARNESS-01 | Raw `Sandbox.*` under `test/` outside the helper fails lint | Credo | `mix credo --strict` | ❌ Wave 2 |
| HARNESS-01 | Class A: baseline tables present at every `async: false` module boundary | formatter probe (suite-level) | full suite, `MAILGLASS_SUITE_FLOOR=1` | ❌ Wave 2 |
| HARNESS-01 | Class B: `Config.schema()` equals its boot value at every `async: false` module boundary | formatter probe (suite-level) | full suite, `MAILGLASS_SUITE_FLOOR=1` | ❌ Wave 2 |
| HARNESS-02 | All four legs green | CI (integration) | `advisory-matrix.yml` — three consecutive completed runs across three distinct `main` SHAs, ≥1 `schedule`, ≥1 `workflow_dispatch` on a tag-shaped ref (D-28) | ✅ lane exists, currently red |
| HARNESS-02 | Green is not seed-luck | CI (repeat) | the three runs above use random seeds (no `--seed` in the lane) — that *is* the seed variation | ✅ |
| HARNESS-03 | `violations/1` fires when executed count drops | unit (negative control) | `mix test test/scripts/suite_floor_contract_test.exs` — auto-collected by `verify.ci_lane_contract` | ❌ Wave 3 |
| HARNESS-03 | `violations/1` fires on an unknown `--exclude` tag, in both directions | unit | same file | ❌ Wave 3 |
| HARNESS-03 | The signature classifier returns `:already_shared` for the verbatim captured failure term | unit | same file | ❌ Wave 3 — **highest-value single test in the phase** |
| HARNESS-03 | The classifier also counts the composed guard error (laundering guard) | unit | same file | ❌ Wave 3 |
| HARNESS-03 | The lane catches a deliberately-injected regression | CI probe | `gh workflow run gate-self-test.yml -f check_name='Core Full Suite (' -f required_only=false` → expect `result=blocked` | ⚠️ workflow exists; needs 2 inputs + never-appeared outcome |
| HARNESS-03 | The existing probe is vacuous against `CI Green` (D-18a) | CI probe, one-shot | `gh workflow run gate-self-test.yml` (defaults) → expect `result=leaked` | ✅ runnable today |
| HARNESS-04 | Registry ↔ YAML ↔ `MAINTAINING.md` agree on the 7 advisory-matrix lanes | drift meta-test | `mix test test/scripts/lane_classification_drift_test.exs` | ⚠️ file exists; add assertions |
| HARNESS-04 | `expanded_matrix_job_names/1` is non-vacuous | unit + negative control | same file | ❌ Wave 3 |
| HARNESS-04 | The 24-row `ci.yml` counts are unchanged | drift meta-test | same file (`:442-465`) | ✅ exists — must stay green |
| HARNESS-04 | Branch protection still exactly `{CI Green, Guard Release Trigger}` | unit | `mix test test/scripts/required_checks_test.exs` (`:45-58`) | ✅ exists |
| HARNESS-04 | A red gating leg blocks a Hex publish | CI rehearsal (negative) | tag a branch with one deliberately failing core test; `gh workflow run publish-hex.yml -f tag=<tag> -f dry_run=true` → gate fails, `publish-core` never starts | ❌ Wave 4 (D-29) |
| HARNESS-04 | A green gating leg permits the publish path | CI rehearsal (positive) | throwaway tag on `main` **created after merge**; `-f dry_run=true` → gate passes, `publish-core` skips on the idempotency guard (`publish-hex.yml:394-401`) | ❌ Wave 4 (D-29) |

### Sampling Rate

- **Per task commit:** `mix test test/scripts/ --warnings-as-errors` + `mix credo --strict` (seconds).
- **Per wave merge:** `mix test --warnings-as-errors --exclude requires_workspace` locally on the `public`
  axis, then `MAILGLASS_SCHEMA=mailglass` on the `mailglass` axis.
- **Wave 2 → Wave 3 boundary:** floors may only be pinned from **green CI runs**, never locally (D-27).
- **Wave 3 → Wave 4 boundary:** D-28's five-condition blocking checkpoint, pasted into the phase artifact.
- **Phase gate:** full suite green on all four legs + `mix verify.ci_lane_contract` + `mix credo --strict`
  before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `test/support/sandbox_ownership.ex` — the sanctioned door (D-06)
- [ ] `test/support/suite_truth_formatter.ex` — hygiene probe + signature tally (D-08/D-09)
- [ ] `test/support/suite_floor.ex` — floors, tag allowlist, ceilings (D-13/D-15/D-16)
- [ ] `credo_checks/no_raw_sandbox_ownership.ex` — prevention (D-08)
- [ ] `test/scripts/suite_floor_contract_test.exs` — negative controls; **auto-collected, no `mix.exs`
      change** (`verify.ci_lane_contract` is a directory glob)
- [ ] `test/mailglass/test_support/sandbox_ownership_test.exs` — the mechanism-level regression test (D-04)
- [ ] Two `env: MAILGLASS_SUITE_FLOOR: "1"` additions (`advisory-matrix.yml`, the two full-suite steps at
      `:113` and `:216`)
- [ ] `Mailglass.CIYaml.expanded_matrix_job_names/1` + `Mailglass.CILanes` third axis (D-24)
- [ ] `MAINTAINING.md` new `## Advisory Matrix Lanes` section (D-25)
- Framework install: **none** — ExUnit, Credo, and the drift-test harness all already exist.

---

## Security Domain

`security_enforcement` is not set to `false`, so this section is required. The phase's attack surface is
CI/CD configuration and test tooling, not adopter-facing code.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control here |
|---|---|---|
| V2 Authentication | no | No auth code touched. |
| V3 Session Management | no | — |
| V4 Access Control | **yes** | `gate-ci-green` keeps `permissions: {contents: read, actions: write}` (`publish-hex.yml:125-127`). `actions: write` is required for the dispatch self-heal and is already granted. `gate-self-test.yml:24-27` keeps `contents: write, pull-requests: write, checks: read` — these let it push a branch and open a PR; do **not** widen. Publishing stays behind the `hex-publish` GitHub Environment so `HEX_API_KEY` is never visible to PR jobs (CLAUDE.md). |
| V5 Input Validation | **yes** | Two new `workflow_dispatch` inputs (D-23) are interpolated into shell/JS. Read them via `env:` bindings and `${{ inputs.x }}` in `github-script`, never by string-concatenating user text into a `run:` block — the existing `gate-self-test.yml:113-117` `env:`-binding pattern is the model. The free-text skip reason goes to `$GITHUB_STEP_SUMMARY`; treat it as untrusted markdown. |
| V6 Cryptography | no | Nothing hand-rolled; no signing changes. |
| V14 Configuration | **yes** | All third-party Actions stay SHA-pinned (CLAUDE.md). No new actions are introduced — the new steps reuse `actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3`. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard mitigation |
|---|---|---|
| A publish gate that can be self-skipped on the automated path | Elevation of Privilege | D-23's override is **inert** on `github.event_name == 'release'`; only a human `workflow_dispatch` can set it, and the reason is required and echoed to the summary. |
| Script injection via `workflow_dispatch` free-text input | Tampering | `env:`-bind, never inline-interpolate into `run:`. |
| A guard that "cannot verify" and reports green | Repudiation | The milestone's core theme. `(missing)`/`cancelled`/`skipped` block with the same weight as `failure` (D-23.1); a probe that cannot observe its lane reports failure, not a timeout pass (D-18). |
| Two concurrent gate runs cancelling each other into a false `cancelled` | Denial of Service | Query on `head_sha`, randomised settle, re-check; **do not** change `advisory-matrix.yml`'s concurrency group (D-30). |
| Test-only tooling leaking into the shipped tarball | Information Disclosure | `test/support/` and `credo_checks/` are excluded by `mix.exs`'s `:package :files` allowlist (which lists `lib`, not `test`/`credo_checks`). Phase 142's tarball-allowlist protocol applies if that list is ever touched — it should not be here. |
| PII in the new instrumentation | Information Disclosure | The ledger and formatter must record **module names, pool modes, counts, and signatures only** — never test data, recipient addresses, or query parameter values. The `42P01` messages this phase quotes contain relation names, which are safe; the accompanying `query:` lines contain bound-parameter *placeholders* (`$1`), not values — keep it that way. |

---

## State of the Art

| Old approach | Current approach | When changed | Impact here |
|---|---|---|---|
| `Sandbox.checkout/2` + `checkin/2` in setup | `Sandbox.start_owner!/2` + `stop_owner/1` | ecto_sql 3.4.4 (`@doc since: "3.4.4"`, `sandbox.ex:446`) | The repo already uses the modern form. `start_owner!`'s own doc (`:430-438`) says to prefer it *only* when unlinked processes outlive the test; otherwise `checkout/2` "involves less overhead." |
| `Sandbox.mode(repo, :auto)` for committed writes | `Sandbox.unboxed_run/2` (`sandbox.ex:624-625`) | present in 3.14.0 | Forward idiom (D-12). Cannot replace `:auto` where `Ecto.Migrator.with_repo/2` spawns a process. |
| Parsing `mix test`'s summary line | `ExUnit.after_suite/1` | ExUnit 1.8 | **The summary line changed shape between 1.18 and 1.19** — see § "Measuring The Suite Honestly". |
| `mix test --formatter X` | `ExUnit.configure(formatters: [CLIFormatter, X])` | — | `--formatter` *replaces* the list. |

**Deprecated / outdated in this repo's own artifacts:**
- `SEED-007`'s "already ruled out" entry for `migration_test.exs` teardown — contradicted by CI evidence.
- `ci_lanes.ex:54-63`'s "cron-only canary" description of Core Full Suite.
- `MAINTAINING.md:262-265`'s claim that advisory-matrix lanes carry runtime matrix suffixes.
- `mailer_case.ex:153-157`'s comment asserting a guarantee `Sandbox.mode(repo, {:shared, self()})` does not provide.
- ROADMAP Phase 143 criterion 1's `:auto`-siblings-*collide* hypothesis.

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | `ExUnit.suite_result()`'s four keys are identical on Elixir 1.18.4 (verified only on 1.19.5 locally) | Measuring The Suite Honestly | An `after_suite` callback crashing on the gating legs — a self-inflicted vacuity. **Mitigate: `Map.fetch!/2` with a composed message; verify on the 1.18 leg in Wave 3.** |
| A2 | The Class B leak originates in one of the six `:schema_isolation`-tagged files | The Premise Has Moved | Wave 1 hunts the wrong files. Bounded — the formatter's per-module probe finds it regardless. |
| A3 | The Class A leak is `migration_test.exs`'s incomplete restoration (its own failures at `:57→:71`, `:164→:186` are consistent) | The Premise Has Moved | Same as A2; the probe finds the true module either way. |
| A4 | GitHub appends the matrix-value suffix only when `name:` contains no matrix expression | Runtime vs Declared Job Names | The rule is inferred from two observed cases (`dialyzer` suffixed, advisory-matrix not). **The observed outcomes themselves are `[VERIFIED]`** and are what the gate depends on; only the general rule is assumed. |
| A5 | `Core Full Suite (` and `Core Full Suite Next Toolchain Advisory (` will be the post-rename runtime prefixes | Runtime vs Declared Job Names | A prefix collision would misclassify. Cheap to confirm on the first push run after the rename — make it a D-28 sub-item. |
| A6 | The `--seed`-less lane provides genuine seed variation across the three D-28 runs | Validation Architecture | If GitHub somehow produced identical seeds, "repeated runs and seeds" would be unmet. Record the seed from each run's log as checkpoint evidence. |
| A7 | The ~10:30 cold-cache dispatched-matrix cost quoted in D-30 still holds | Pitfalls | Wall-clock only; SEED-006 input, not a correctness risk. |
| A8 | Deleting the four S2 calls is behaviour-preserving | Mechanism Account (D-07) | Verified by construction against `manager.ex:148-159`, but Oban-tagged tests are the proof. **Mitigate: run `mix test --only oban` before and after and diff.** |

## Open Questions

1. **Is the Class A / Class B work in scope for Phase 143, or does it need a requirement amendment?**
   - What we know: HARNESS-02 demands all four legs green; Classes A and B are currently the *only* thing
     red on both gating legs. CONTEXT.md's D-11 async policy already names both as sanctioned
     `async: false` reasons, and the D-06 helper's `unsandboxed_module/1` is the natural home for the
     guards. So the *design* covers them.
   - What's unclear: no requirement text names them, and HARNESS-01 is scoped to "the Ecto Sandbox
     ownership leak."
   - Recommendation: fold into HARNESS-01/02 and add a **D-31 amendment** recording that the phase closed
     three global-state leak classes, not one. This is the Phase 141 precedent (never silently diverge from
     a requirement) applied in the widening direction.

2. **Does the D-28 checkpoint's "three consecutive green runs" become unreachable if Class A/B prove
   deep?**
   - What we know: 29 and 12 failures on the gating legs, concentrated in a handful of modules.
   - Recommendation: keep D-28 as written. If Wave 3 cannot reach three consecutive greens, D-19's
     escape hatch already exists — Claude's Discretion permits dropping Wave 4 and recording HARNESS-04 as
     a deliberate "not gating, and here is why," which ROADMAP criterion 4 explicitly allows.

3. **Should the `:config_schema_drift` signature and the Class A/B probes ship in Wave 2 (with the fix) or
   Wave 1 (as instrumentation)?**
   - Recommendation: **Wave 1, as instrumentation only** (no enforcement). They are how Wave 1 produces its
     inventory, and shipping them early means Wave 2's fix has its own detector already in place.

4. **`schema_axis_boot_order_test.exs:27`'s raw `Sandbox.checkout/1` — allowlist or migrate?**
   - What we know: safe today (Ecto auto-releases on owner death), architecturally distinct from every
     other call site, `async: false`.
   - Recommendation: **migrate to `checkout!/1`** rather than allowlist. An allowlist entry is a permanent
     exception a future reader will copy; the helper handles the bare-checkout case at no cost. Decide
     before writing the Credo check, since it determines whether `checkout` is in `forbidden_functions`.

5. **Does `mix credo --strict` currently lint `test/support/*.ex` and `test/**/*.exs` both?**
   - What we know: `.credo.exs:177` `included: ["lib/", "test/", …]`; Credo's default file glob covers
     `{ex,exs}`.
   - Recommendation: confirm with a deliberately-violating scratch file before relying on the check; the
     Credo layer is D-08's *prevention* half and a silent no-match would be exactly the vacuity this
     milestone exists to kill.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir | everything | ✓ | **1.19.5** locally; `.tool-versions` pins **1.18.4** | ⚠️ **Local/CI divergence.** The local toolchain is the *next-toolchain* version, not the gated floor. Local full-suite runs will reproduce the 1.19 legs, not the 1.18 gating legs. Use `asdf`/`mise` to install 1.18.4 before pinning any floor locally, or (better, per D-27) pin floors from green CI runs only. |
| Erlang/OTP | everything | ✓ | 28 locally; `.tool-versions` pins 27.3.4.13 | same |
| PostgreSQL | full suite | ✗ **not verified in this session** | — | Required for local full-suite runs. `scripts/preflight_postgres.sh` exists (`mix.exs:385`). CI provides `postgres:16-alpine`. |
| `gh` CLI, authenticated | D-18/D-28/D-29 evidence, log retrieval | ✓ | authenticated against `szTheory/mailglass`; all API calls in this research succeeded | — |
| `deps/` populated | reading ecto_sql / db_connection source | ✓ | `ecto_sql 3.14.0`, `db_connection 2.10.2` present | — |
| Docker | — | not needed | — | Demo/browser lanes are out of scope. |
| Node | — | **must stay unnecessary** | — | Zero-Node is an adopter guarantee (CLAUDE.md). Nothing here needs it. |

**Missing dependencies with no fallback:** none blocking research or planning.
**Missing dependencies with fallback:** local Postgres (CI covers it); local Elixir 1.18.4 (pin floors from
CI per D-27).

---

## Sources

### Primary (HIGH confidence — read in this repo / this session)

**Dependency source (`deps/`):**
- `deps/db_connection/lib/db_connection/ownership/manager.ex` — `:148-159` (`:already_shared`), `:161-172`
  (mode reset + `proxy_checkin_all_except`), `:242` (`{:DOWN}` → `unshare`), `:257-283` (`proxy_checkout`,
  `Process.monitor(proxy)`), `:285-307` (checkin helpers), `:388-408` (`share_and_reply`, `unshare`),
  `:419-427` (`not_found` message)
- `deps/db_connection/lib/db_connection/ownership/proxy.ex` — `:9` (`@ownership_timeout 120_000`), `:23-56`
  (init, monitors, timer), `:61-63` (owner DOWN), `:75-86` (ownership timeout), `:225-247` (`shutdown`),
  `:259-293` (`pool_disconnect` / `pool_done`)
- `deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex` — `:415-465` (`start_owner!/2` doc + impl), `:467-474`
  (`stop_owner/1`), `:476-516` (`mode/2` doc + spec + impl), `:544` (`checkout/2`), `:590` (`checkin/2`),
  `:604-606` (`allow/4`), `:624-625` (`unboxed_run/2`)

**Repo — test harness:**
- `test/test_helper.exs` (`:1`, `:41`, `:54`, `:59-67`, `:129`)
- `test/support/data_case.ex` (`:35-36` — the control)
- `test/support/mailer_case.ex` (`:80-91` I-12 guard, `:93`, `:98`, `:100`, `:113-116`, `:153-162`, `:185`,
  `:206`, `:248`)
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` (`:37`, `:43`, `:51-69`)
- `test/mailglass/migration_test.exs` (`:1-46`, `:57`, `:164`, `:449-455`)
- `test/mailglass/outbound/deliver_many_test.exs` (`:1-35`), `deliver_later_test.exs` (`:33-54`)
- `test/mailglass/upgrade_v2_schema_generation_test.exs` (`:1-5`, `:134-176`)
- `test/mailglass/schema_axis_boot_order_test.exs:27`
- `config/test.exs` (`:12-15` schema pin + its own leak-mechanism comment, `:26-46` pool + `disconnect_on_error_codes`)
- Full `Sandbox.*` call-site grep across `test/` — 32 sites, 14 files (table above)

**Repo — CI registry, gate, workflows:**
- `.github/workflows/advisory-matrix.yml` (`:3-17`, `:20-21`, `:26-40`, `:64-77`, `:100-125`, `:133-139`,
  `:150-156`, `:186-217`, `:219-220`, `:273-274`, `:340-353`)
- `.github/workflows/publish-hex.yml` (`:1-39`, `:63-69`, `:115-361` in full, `:364-365`, `:394-401`)
- `.github/workflows/gate-self-test.yml` (all 177 lines)
- `.github/workflows/ci.yml` (`:24`, `:227-231`, `:280-292`, `:351-362`, `:452-458`, `:1142`, plus the
  full job-name inventory)
- `test/support/ci_lanes.ex` (`:1-80` moduledoc incl. `:54-63` exclusions, `:83-91`, `:94-118`, `:122+`,
  `:190-210`)
- `test/support/ci_yaml.ex` (all 105 lines)
- `test/scripts/lane_classification_drift_test.exs` (`:150-229`, `:245-300`, `:440-470`, `:600-640`)
- `test/scripts/required_checks_test.exs` (`:1-70`)
- `MAINTAINING.md` (`:205-270`)
- `mix.exs` (`:110-116`, `:280-320`, `:385-400`)
- `.credo.exs` (`:150-180`), `credo_checks/no_raw_swoosh_send_in_lib.ex` (`:1-90`)
- `mix.lock` (ecto 3.14.1, ecto_sql 3.14.0, db_connection 2.10.2, postgrex 0.22.3), `.tool-versions`

**Live GitHub API (`gh`, this session):**
- `actions/runs/30464215272` (push, SHA `3edc95f0`) + all four Core Full Suite job logs
  (`90617762097`, `90617762070`, `90617762038`, `90617762037`)
- `actions/runs/30464262578` (pull_request) — the uninterpolated-template collapse
- `gh run list --workflow=advisory-matrix.yml --limit 12` — 12 consecutive non-success runs
- SHA `25c74ca0` vs `3edc95f0` workflow-run comparison (D-22's self-heal necessity)

**Local runtime verification:**
- `elixir -e 'IO.inspect(Agent.start(fn -> :ok = :already_shared end))'` → `{:error, {{:badmatch, :already_shared}, …}}`
- `Code.Typespec.fetch_types(ExUnit)` → `suite_result()` shape on 1.19.5
- `Code.fetch_docs(ExUnit)` → `after_suite/1` doc

**Planning artifacts (binding):**
- `.planning/phases/143-test-harness-truth/143-CONTEXT.md` (all of it)
- `.planning/REQUIREMENTS.md:55-81`, `:168-180`
- `.planning/ROADMAP.md` § Phase 143
- `.planning/STATE.md` §§ v2.2 Milestone Intent, v2.2 Scope Locks
- `.planning/seeds/SEED-007-sandbox-ownership-leak.md` (all 125 lines)
- `.planning/research/v2.2/SUMMARY.md`, `ARCHITECTURE.md` (§§ HARNESS-01/04), `PITFALLS.md` (Pitfalls 2, 4)
- `CLAUDE.md`, `.planning/config.json`

### Secondary (MEDIUM confidence)

- `ecto_sql` HexDocs `Ecto.Adapters.SQL.Sandbox` v3.14.0 — cross-checked against the installed source in
  `deps/`, which is authoritative and was preferred wherever they could differ.

### Tertiary (LOW confidence)

- The general GitHub Actions rule for when matrix values are appended to a job's display name (A4). The
  *observed outcomes* on this repo are `[VERIFIED]` from the live API; only the generalisation is inferred.

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|---|---|---|
| `:already_shared` mechanism | **HIGH** | Read from `deps/` source with line citations **and** confirmed end-to-end in a live CI log, including the exact ExUnit failure term and the immediately-preceding leak. |
| The two leak windows (D-02) | **HIGH** | Direct read; the CI log's stack trace lands on `webhook_idempotency_convergence_test.exs:58`, inside window (a) exactly as predicted. |
| S2 no-ops (D-07) | **HIGH** | Provable from `manager.ex:148-159` plus setup ordering; `[ASSUMED]` only that removal is observably behaviour-preserving under `@tag oban:` (A8). |
| Current four-leg failure inventory | **HIGH** | Measured from run `30464215272`. |
| Class A / Class B diagnoses | **MEDIUM** | The *symptoms* are `[VERIFIED]`; the *culprit modules* are `[ASSUMED]` (A2, A3) and are Wave 1's job. |
| Summary-line instability (D-13) | **HIGH** | Two independent divergences observed between 1.18 and 1.19 on this repo's own matrix. |
| Floor numbers | **MEDIUM** | Measured, but from a **red** run. Must be re-measured from green runs per D-27. |
| `gate-self-test.yml` `--required` defect | **HIGH** | Direct read of `:122-124` against `required_checks_test.exs:45-58`'s locked required set. |
| D-18a (probe vacuity) | **HIGH** | Exhaustive grep of `ci.yml`'s `mix test` invocations + every root-lane alias in `mix.exs`. |
| Runtime vs declared job names (D-21) | **HIGH** | Confirmed live across `push`, `pull_request`, and the declared parser. |
| `gate-ci-green` change surface (D-22/23/24) | **HIGH** | Full read of `:115-361` plus the two-SHA run comparison. |
| `MAINTAINING.md` parse hazard (D-25) | **HIGH** | Read `parse_disposition_table/1` and the 24-row assertion. |

**Research date:** 2026-07-29
**Valid until:** **2026-08-05 (7 days).** Fast-moving: the four-leg failure inventory is a snapshot of a
single `main` SHA, and every subsequent push re-measures it. Re-run the four-leg log extraction at the start
of Wave 1 and again before pinning floors in Wave 3. The mechanism findings (Ecto/db_connection internals,
gate anatomy, name-space behaviour) are stable for ~30 days.
