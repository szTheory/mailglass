---
artifact: promotion-checkpoint
phase: 143-test-harness-truth
plan: 12
created: 2026-07-30
decision: BLOCKED — do not proceed to 143-13 gate wiring
conditions_met: 0
conditions_total: 5
---

# 143-PROMOTION-CHECKPOINT — the five D-28 conditions before any lane gains publish-veto power

This is the blocking checkpoint plan `143-12` Task 2 exists to hold. Its bar is deliberately **not**
"merged" — it is **observed green in the shape the gate will actually read it**.

## Verdict: **BLOCKED. 0 of 5 conditions met. Plan `143-13` must not wire `gate-ci-green`.**

Two conditions could not be attempted at all under this plan's process constraints. **Three are not met on
the evidence, independently of those constraints** — and one of those three, condition 1, is not a
paperwork gap but a live statement about the repository: `main`'s Core Full Suite has been red for
twenty-eight days.

A fourth finding, recorded below as **Finding B**, is the most consequential thing this checkpoint turned
up: the lane proposed for publish-veto power has an **observed nondeterministic failure**, and its
mechanism is a live global-state leak of exactly the class this phase exists to close.

---

## Decision of record: the fork is already settled — blocking, not advisory

The maintainer has approved the **blocking** option for the fork about whether the Core Full Suite legs
should be able to block a release. Plan `143-13` should execute on that basis and **must not re-ask**.

**Rationale of record:** a blocked release costs the maintainer thirty minutes and one dispatch; a broken
core reaching adopters cannot be undone after sixty minutes on Hex. The preferred shape is a **documented,
deliberate override path** rather than narrowing the check until it stops being able to observe a
regression.

This decision makes the conditions below *more* load-bearing, not less. A gate that can veto every future
release must not be built on a lane that has never been observed green on `main`, and must not be built on
a lane that fails nondeterministically — a flaky blocking gate spends the maintainer's thirty minutes
repeatedly, on nothing, and trains them to reach for the override reflexively. That is how an override path
decays into a rubber stamp.

---

## Condition 1 — three consecutive completed runs, three distinct `main` SHAs, both gating legs green in each

### **NOT MET. Qualifying runs found: 0 of 3.**

There is no green Core Full Suite leg on `main` at all. Not a shortfall of three — a shortfall of one.

```
gh run list --workflow=advisory-matrix.yml --branch main --limit 100 \
  --json databaseId,headSha,event,conclusion,createdAt
```

Of the **last 40** `advisory-matrix.yml` runs on `main`: **34 `failure`, 6 `cancelled`, 0 `success`.** The
most recent `success` on `main` is run
[`28568190903`](https://github.com/szTheory/mailglass/actions/runs/28568190903), a `schedule` run at
`c34e54e6` on **2026-07-02T05:41:40Z** — twenty-eight days before this checkpoint. Every run from
`28696437680` (2026-07-04T05:35:15Z) through `30516349919` (2026-07-30T05:20:40Z) is red or cancelled.

Job-level conclusions for the five most recent `main` runs, which is the level condition 1 actually asks
about:

| Run | Event | Head SHA | `Core Full Suite Advisory (1.18/27/public)` | `… (1.18/27/mailglass)` | 1.19/28 legs |
|---|---|---|---|---|---|
| [`30516349919`](https://github.com/szTheory/mailglass/actions/runs/30516349919) | `schedule` | `25c74ca0` | **failure** | **failure** | both failure |
| [`30464215272`](https://github.com/szTheory/mailglass/actions/runs/30464215272) | `push` | `3edc95f0` | **failure** | **failure** | both failure |
| [`30463106566`](https://github.com/szTheory/mailglass/actions/runs/30463106566) | `push` | `dede6eec` | **failure** | **failure** | both failure |
| [`30461400734`](https://github.com/szTheory/mailglass/actions/runs/30461400734) | `push` | `014b21d8` | **failure** | **failure** | both failure |
| [`30452712750`](https://github.com/szTheory/mailglass/actions/runs/30452712750) | `push` | `46598461` | **failure** | **failure** | both failure |

`Provider Compatibility Advisory` and both `Inbound Full Suite Advisory` legs are green in every one of
these runs. The failure is specific to Core Full Suite.

### Why `main` is red — it is the defect set this phase's branch fixes

From run `30516349919`'s failed-job log:

```
** (Postgrex.Error) ERROR 42P01 (undefined_table)
   relation "mailglass.mailglass_suppressions" does not exist
     test/mailglass/outbound/projector_broadcast_test.exs:20, :32, :52, :64, :80, :98
     test/mailglass/suppression_test.exs:288
```

```
test/mailglass/operator/support_summary_test.exs:11
  Assertion with == failed
  code:  assert Map.keys(summary) == [:failed_ingest, :orphan_backlog, :replay_outcomes, :reconcile_facts]
  left:  [:orphan_backlog, :failed_ingest, :replay_outcomes, …]
```

These are the schema-collision and global-state-ordering classes plans `143-01`..`143-09` and the five
gap-closure plans closed. **The fixes live on the unmerged branch `gsd/phase-143-test-harness-truth`.**

### The structural consequence, stated plainly

Condition 1 as written is **unsatisfiable until this branch merges**. It asks for `main` evidence of a lane
that only goes green with code that is not yet on `main`. This is not a reason to weaken the condition — it
is a reason to sequence correctly:

> **Merge first, then collect the three `main` runs, then wire the gate.** Wiring `gate-ci-green` to a lane
> that is red on `main` would block every publish from `main` immediately and unconditionally.

Under the approved *blocking* decision this is not a theoretical risk. It is the guaranteed outcome.

### What does exist: three green runs, on the branch, in the wrong shape

Recorded because it is the strongest available evidence and because a future reader will otherwise
rediscover it and mistake it for condition 1. **It does not satisfy condition 1** — wrong ref, wrong event,
and not consecutive.

| Run | Event | Head SHA | Both gating legs | Public seed | mailglass seed |
|---|---|---|---|---|---|
| [`30574508370`](https://github.com/szTheory/mailglass/actions/runs/30574508370) | `pull_request` | `6bacf2ff` | **success / success** | `147642` | `985824` |
| [`30568802513`](https://github.com/szTheory/mailglass/actions/runs/30568802513) | `pull_request` | `369577b0` | **success / success** | `478127` | `43820` |
| [`30557831075`](https://github.com/szTheory/mailglass/actions/runs/30557831075) | `pull_request` | `60349d87` | **success / success** | `40210` | `548165` |

Three distinct SHAs; **six distinct seeds**, no repeats. But: all three are `pull_request` events on the
phase branch, none is a `main` SHA, and they are **not consecutive** — runs `30571989203` (`71fcd8f5`) and
`30564591156` (`7e149ad5`) sit between them and are red. See **Finding B** for why `30571989203` matters far
more than a routine mid-development red.

---

## Condition 2 — at least one of those three is a `schedule` (cron) run

### **NOT MET.**

Cron runs on `main` exist and are on the right cadence, but none is green:

| Run | Event | Head SHA | Created | Conclusion | Gating legs |
|---|---|---|---|---|---|
| [`30516349919`](https://github.com/szTheory/mailglass/actions/runs/30516349919) | `schedule` | `25c74ca0` | 2026-07-30T05:20:40Z | failure | both **failure** |
| [`30425226323`](https://github.com/szTheory/mailglass/actions/runs/30425226323) | `schedule` | `e8315fec` | 2026-07-29T05:29:38Z | failure | (run red) |

The phase branch has produced **no** cron run and structurally cannot: the schedule trigger fires on `main`
only. So this condition, like condition 1, is gated on the merge.

### UPDATE 2026-07-31 — the substantive point is now evidenced; the literal count is not

PR #151 merged as `d6e50388`, and the next scheduled run went green:

| Run | Event | Head SHA | Created | Conclusion | Gating legs |
|---|---|---|---|---|---|
| [`30607136165`](https://github.com/szTheory/mailglass/actions/runs/30607136165) | `schedule` | `d6e50388` | 2026-07-31T05:33:38Z | **success** | both **success** |

This is the first green cron on `main` since 2026-07-02. **The condition's substantive point is met:**
a plain `main` SHA, cold cache, no pull-request context, fully unattended — green on both gating legs.

**It does NOT complete condition 1**, and that distinction must not be blurred. Condition 1 asks for
three *distinct* `main` SHAs. `d6e50388` has now produced two green runs (`push` 30595090072 and this
`schedule` run), but that is one SHA observed twice, not two of the three. `main` must advance twice
more before condition 1 can close.

**Operational note for whoever waits on this next:** the cron is declared `21 4 * * *` but GitHub
consistently delays it by roughly an hour — 05:33 today, 05:20 on 2026-07-30, 05:29 on 2026-07-29.
Budget for ~05:20–05:35 UTC, not 04:21, and do not read a missing 04:30 run as a skipped schedule.

---

The condition's substantive point — a plain `main` SHA, cold cache, no pull-request context — remains
entirely unevidenced for a *green* lane.

---

## Condition 3 — one `workflow_dispatch` run on a tag-shaped ref, both gating legs green

### **NOT MET — NOT ATTEMPTED.**

This requires `git push origin <throwaway-tag>` followed by `gh workflow run advisory-matrix.yml --ref <tag>`.
Plan `143-12`'s process constraints forbid both: **"Do NOT push. Do NOT trigger GitHub Actions runs (real CI
minutes on a public repo)."**

No tag was created, no tag was pushed, and no dispatch was made. **No cleanup is outstanding** — there is no
orphaned throwaway tag, because none was ever created. `git ls-remote --tags origin` was not modified by
this plan.

This is the condition the plan itself calls "the only proof of the exact code path the gate will use, and
the one nobody would think to run." It remains unproven, and it is the condition most likely to be quietly
skipped later precisely because it feels redundant. It is not redundant: `github.ref` on a tag dispatch is
a different shape from a branch push, and `gate-ci-green`'s run-lookup is keyed on it.

**Sequencing note:** running this before the merge would test the wrong tree. The tag should be cut from a
post-merge `main` whose lane is green, otherwise the dispatch measures the same red lane condition 1
already documents.

---

## Condition 4 — the deliberate-failure probe has already gone red against the renamed lane

### **NOT MET — NOT ATTEMPTED.**

`143-PROBE-EVIDENCE.md`'s Core Full Suite section records **no `result` value and no run URL**. The probe
requires `gate-self-test.yml`, which pushes a synthetic-failure branch and opens a real PR — forbidden by
the same process constraints.

Two things are recorded in `143-PROBE-EVIDENCE.md` rather than here:

1. **The verbatim dispatch command**, with every input justified, including the two that are easy to get
   wrong: `--ref` must be the phase branch (not `main`, whose pre-rename lane name would not match the
   prefix), and `required_only=false` (branch protection's required set is exactly two entries, so an
   advisory-matrix lane never appears in a `--required` query).
2. **That the plan's own automated verification for this task is vacuous.** `grep -q 'result=blocked'`
   already exited 0 against the untouched file, because the reserved section legitimately quotes the
   expected value at line 150. The check cannot tell "the probe ran and blocked" from "the probe never ran."
   That is this phase's own failure mode appearing inside this phase's own plan, and it is recorded so no
   one reads a green Task 1 verification as evidence.

**A lane never observed catching an injected regression must not be given veto power over a publish.** That
is the whole content of this condition, and it holds.

---

## Condition 5 — the executed-test-count floor is merged and green

### **NOT MET.** Two of the three sub-claims hold; the load-bearing one does not.

| Sub-claim | Status | Evidence |
|---|---|---|
| `MAILGLASS_SUITE_FLOOR` set on both full-suite steps **on `main`** | **NOT MET** | `git show origin/main:.github/workflows/advisory-matrix.yml \| grep -c MAILGLASS_SUITE_FLOOR` → **0**. It is on the branch (count 2), unmerged. |
| `SuiteFloor`'s constants are measured values with recorded source run IDs | **MET** | `public: 1576`, `mailglass: 1575`, `skipped_ceiling: 7`, each carrying run `30568802513`, its job ID (`90959947929` / `90959948064`), its arithmetic and its date. |
| The three runs from condition 1 passed with enforcement active | **NOT MET** | Condition 1 has no qualifying runs. Enforcement has been observed live on exactly **one** run. |

The single run with enforcement genuinely active is
[`30574508370`](https://github.com/szTheory/mailglass/actions/runs/30574508370):

```
job 90979266906 (public)     total: 1626, excluded: 13, skipped: 7, executed: 1606, failures: 0
  scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1576, skipped ceiling 7 enforced
  0 violation(s).

job 90979266969 (mailglass)  total: 1626, excluded: 14, skipped: 7, executed: 1605, failures: 0
  scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1575, skipped ceiling 7 enforced
  0 violation(s).
```

This confirms `143-10`'s and `143-11`'s prediction exactly: `1606 − 1576 = 30` and `1605 − 1575 = 30`, both
inside the 40-test nudge margin, so the first enforced CI run showed neither a violation nor a nudge. That
is a real and satisfying result — it is simply **one** run, not three, and not on `main`.

The other two green branch runs (`30568802513`, `30557831075`) predate `143-10` Task 3 and print no
`scope: FULL SUITE` line. They cannot be counted as "passed with enforcement active"; run `30568802513` is
the run the floors were *measured from*, which is a different claim.

Without the merge, the gate would enforce a vacuum: `gate-ci-green` would read a lane whose floor opt-in is
absent from `main`'s workflow.

---

## Sub-item A — the ExUnit seed printed by each run

The lane pins no seed, so the seed each run happens to print **is** the seed-variation evidence.

| Run | Head SHA | Public leg seed | mailglass leg seed |
|---|---|---|---|
| `30574508370` | `6bacf2ff` | `147642` | `985824` |
| `30568802513` | `369577b0` | `478127` | `43820` |
| `30557831075` | `60349d87` | `40210` | `548165` |

**Six distinct seeds; no two runs share one.** Extracted as the first `Running ExUnit with seed: N` line
after the `##[group]Run mix test --warnings-as-errors --exclude requires_workspace` marker in each job log —
each job runs several `mix test` invocations (the full suite, then `verify.schema_prefix`'s focused lanes),
so a naive grep returns four seeds per job and the wrong one three times out of four. The method is
self-validating: it reproduces `478127` / `43820` for run `30568802513`, the pair `143-10` recorded
independently.

The seed condition would be satisfiable **if** the runs it applies to qualified. They do not (condition 1).

---

## Sub-item B — observed runtime job names vs. the registry (research assumption A5)

### Partially closed: **the gating pair is exactly confirmed; two of the five advisory names are not.**

Observed on run [`30574508370`](https://github.com/szTheory/mailglass/actions/runs/30574508370), the first
post-rename run:

| Observed runtime name | Conclusion | Registry accessor | Match |
|---|---|---|---|
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` | success | `advisory_matrix_gating_lanes/0` | **exact** |
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` | success | `advisory_matrix_gating_lanes/0` | **exact** |
| `Provider Compatibility Advisory (Elixir 1.18 / OTP 27)` | success | `advisory_matrix_advisory_lanes/0` | **exact** |
| `Inbound Full Suite Advisory (schema public)` | success | `advisory_matrix_advisory_lanes/0` | **exact** |
| `Inbound Full Suite Advisory (schema mailglass)` | success | `advisory_matrix_advisory_lanes/0` | **exact** |
| `Core Full Suite Next Toolchain Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})` | **skipped** | — | **unexpanded** |

**A5 is closed for the two lanes the gate will actually match on.** `Mailglass.CIYaml.expanded_matrix_job_names/1`
computed these strings from the workflow source and GitHub reports them character-for-character. Exact-equality
matching is therefore safe for the gating pair — which is the only place `143-13` needs it.

**A5 is NOT closed for the two next-toolchain legs.** On a `pull_request` event those legs carry
`if: github.event_name != 'pull_request'`, and GitHub reports a **single collapsed placeholder job with the
matrix expression left uninterpolated** rather than two expanded names. This is the D-21 job-name-collapse
artifact, now observed a third time. The registry holds:

```
"Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)"
"Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema mailglass)"
```

Those exact strings have **never been reported by a live run**, because the only events that expand them
(`push`, `schedule`) have not occurred since the rename — the rename is unmerged. The pre-rename evidence is
one template-shape removed: `main`'s push and cron runs do report fully-expanded
`Core Full Suite Advisory (Elixir 1.19 / OTP 28 / schema public)`, confirming that this template shape
interpolates every axis and gets no appended suffix. The inference is strong and the parser is bound to the
registry by drift assertions — but it is an inference, and it should be confirmed on the first post-merge
push run.

**This is not a blocker for `143-13`** (which gates only the 1.18 pair), but it must not be recorded as A5
fully closed.

---

## Sub-item C — blast radius: the four steps gating these two legs actually gates

Naming all four so the blast radius is recorded rather than discovered. From
`.github/workflows/advisory-matrix.yml`, the `core_full_suite` job:

| # | Step name | Command | Also run by the 1.19 legs? |
|---|---|---|---|
| 1 | `Run advisory full suite` | `mix test --warnings-as-errors --exclude requires_workspace` (env `MAILGLASS_SCHEMA`, `MAILGLASS_SUITE_FLOOR: "1"`) | yes |
| 2 | `Install inbound deps for focused schema-prefix proof` | `mix deps.get` (`working-directory: mailglass_inbound`) | **no** |
| 3 | (same step) | `mix ecto.create -r MailglassInbound.TestRepo --quiet` | **no** |
| 4 | `Run focused schema-prefix proof` | `mix verify.schema_prefix` (env `MAILGLASS_SCHEMA`) | **no** |

Steps 2–4 are the ones easy to miss. `mix verify.schema_prefix` is described in the workflow's own comments
as "the focused no-search-path proof … hostile runtime tests plus the raw-repo prefix guard and strict
Credo" — the fail-closed proof for schema-prefix correctness, as distinct from the full suite's broad
canary. Gating the two 1.18 legs therefore gives publish-veto power to a sibling-package dependency fetch
and a sibling-package database creation as well as to two test commands.

That matters under the approved blocking decision in a specific, foreseeable way: **steps 2 and 3 are
network- and service-dependent**. A Hex outage, a transient `deps.get` failure, or a Postgres service
hiccup in `mailglass_inbound` would block a release without any core regression existing. This is an
argument for the documented override path, not against gating — but the override path must be usable
*without* a code change, or the maintainer's thirty minutes becomes a day.

---

## Finding A — the required context still cannot observe a test regression

Unchanged and re-confirmed. `CI Green` is the registered branch-protection context; branch protection's
required set is **exactly** `{CI Green, Guard Release Trigger}`, asserted by
`test/scripts/required_checks_test.exs` ("REQUIRED_CHECKS contains exactly {CI Green, Guard Release
Trigger} (GATE-01)"). `CI Green` aggregates seven `needs`, none of which runs the root test suite. This is
the gap the phase exists to close and it is still open — HARNESS-04 remains `[ ]`.

---

## Finding B — **the lane proposed for publish-veto power fails nondeterministically, and the mechanism is a live global-state leak**

This is the most consequential result of this checkpoint and it was not something the plan asked for. It
bears directly on whether the *blocking* decision is safe to implement now.

### The observation

Run [`30571989203`](https://github.com/szTheory/mailglass/actions/runs/30571989203), head SHA `71fcd8f5`,
`pull_request`, full-suite seed **`590679`**:

- `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema public)` → **success**
- `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema mailglass)` → **failure**, 2 failures

```
1) test FACADE-04: orphan-count read via SupportSummary resolves under mailglass prefix …
   test/mailglass/schema_isolation_integration_test.exs:290
   ** (Ecto.Query.CompileError) can't apply alias `:scoped`, binding in `from` is already aliased to `:orphan`
     (mailglass 2.2.1) lib/mailglass/operator/support_summary.ex:79
     Mailglass.Operator.SupportSummary.orphan_backlog_summary/2

2) test FACADE-04 schema isolation: rows land under mailglass.* while public stays clean …
   test/mailglass/schema_isolation_integration_test.exs:180
   ** (Ecto.Query.CompileError) can't apply alias `:scoped`, binding in `from` is already aliased to `:orphan`
```

### Why this is nondeterminism and not a fixed regression

`71fcd8f5` is **`docs(143-10): record the unrun advisory-matrix dispatch in the broken-windows ledger`** — a
one-file commit touching `.planning/WINDOWS.md`, 16 insertions. It changes no code whatsoever.

Two commits later, run `30574508370` at `6bacf2ff` is **green on both legs**. Between the two:

```
$ git diff --stat 71fcd8f5 6bacf2ff -- lib/mailglass/operator/support_summary.ex
(empty — byte-identical)

$ git diff --name-only 71fcd8f5 6bacf2ff
.github/workflows/advisory-matrix.yml   .planning/STATE.md   .planning/WINDOWS.md
.planning/phases/…/143-11-SUMMARY.md    MAINTAINING.md
test/mailglass/demo_data_test.exs       test/mailglass/docs_contract_test.exs
test/reference_host/…                   test/scripts/lane_classification_drift_test.exs
test/scripts/suite_floor_contract_test.exs
test/support/ci_lanes.ex  test/support/ci_yaml.ex  test/support/suite_floor.ex
```

**Nothing under `lib/` changed.** And `main` did not move: its tip is `25c74ca0` from 2026-07-29T11:12, so
both `pull_request` runs merged against an identical base. Same production code, same merge base, same
toolchain — red, then green. The variable is test ordering, which is seed-dependent.

### The mechanism, traced to the line

1. `Mailglass.Tenancy.scope/2` resolves its implementation from **global application environment**:

   ```elixir
   defp resolver do
     case Application.get_env(:mailglass, :tenancy) do
       nil -> Mailglass.Tenancy.SingleTenant
       mod when is_atom(mod) -> mod
     end
   end
   ```

2. `SupportSummary.unresolved_orphans_query/2` builds `from(event in Event, as: :orphan, …)`, and
   `orphan_backlog_summary/2` pipes that query through `Tenancy.scope(tenant_id)`.

3. Two test modules define a tenancy resolver whose `scope/2` applies a **second** alias:

   ```
   test/mailglass/compliance/unsubscribe_test.exs:22
   test/mailglass/properties/unsubscribe_property_test.exs:25
       def scope(queryable, _context), do: from(row in queryable, as: :scoped)
   ```

   `grep -rn "as: :scoped" lib/` returns nothing — the `:scoped` alias exists **only** in test code.

4. If either module's resolver is still installed in the application environment when a later test calls
   `SupportSummary.summarize_tenant/1`, the `as: :orphan` query gets `as: :scoped` applied on top and Ecto
   raises exactly the observed `CompileError`.

5. **The leak window is a restore that cannot restore.** `unsubscribe_test.exs`'s `setup` is:

   ```elixir
   prior_mailglass = Application.get_all_env(:mailglass)
   on_exit(fn ->
     Application.put_all_env(mailglass: prior_mailglass)
     Mailglass.Tenancy.clear()
   end)
   ```

   `Application.put_all_env/1` **merges**; it cannot remove a key that was added during the test and was
   absent from `prior_mailglass`. `:tenancy` is set in no `config/*.exs` (`grep -rn ":tenancy" config/*.exs`
   → nothing), so it is never in `prior_mailglass`. Demonstrated directly:

   ```
   $ elixir -e 'Application.put_all_env(demoapp: [a: 1])
                prior = Application.get_all_env(:demoapp)
                Application.put_env(:demoapp, :tenancy, LeakedModule)
                Application.put_all_env(demoapp: prior)
                IO.inspect(Application.get_env(:demoapp, :tenancy), label: "after restore")'
   after restore: LeakedModule
   ```

   The module sets `:tenancy` at lines 103 and 216 and relies on in-test `Application.delete_env/2` at
   lines 109, 119 and 221. **Any failure, raise, or early exit between the put and the delete leaks the
   resolver globally for the remainder of the suite.**

6. **The sibling file already carries the fix**, which is the strongest corroboration that this leak has
   been hit before. `unsubscribe_property_test.exs`'s `on_exit` is `put_all_env` **followed by an explicit
   `Application.delete_env(:mailglass, :tenancy)`** (line 52), and its `setup` defensively deletes the key
   on the way *in* (line 34). `unsubscribe_test.exs` has neither.

### Why this blocks promotion rather than merely annoying

- It is a **residual instance of the exact defect class this phase was created to eliminate** — global
  state surviving a test boundary. Phase 143 closed three leak classes; this is a fourth, still open, and it
  is not covered by `SuiteFloor`'s instruments (the counts are unaffected; ExUnit reports a genuine failure,
  so no floor or ceiling fires).
- It defeats condition 1's *purpose* even if the count were satisfied. Three consecutive greens are meant
  to demonstrate stability. A lane that flips red on a docs-only commit and green two commits later is not
  stable, and three greens in a row would be luck rather than evidence.
- Under the approved **blocking** decision it converts directly into spurious release blocks, on a schedule
  nobody can predict, with a confusing symptom (`Ecto.Query.CompileError` in a schema-isolation test) that
  looks nothing like its cause (an unsubscribe compliance test leaking an app-env key).

### Not fixed here, deliberately

Plan `143-12`'s `files_modified` is exactly two planning artifacts, and this defect was not introduced by
this plan's changes — the executor scope boundary says log it, do not fix it. It also deserves what every
other guard in this phase received: a fix **plus a mutation proof** that the fix is non-vacuous, which is a
plan of its own, not a drive-by edit. **It was not masked, skipped, tagged away, serialized around, or
weakened in any form.**

**Recommended fix**, for whoever plans it — the one-line shape the sibling file already proves out:

```elixir
on_exit(fn ->
  Application.put_all_env(mailglass: prior_mailglass)
  Application.delete_env(:mailglass, :tenancy)   # put_all_env cannot remove an added key
  Mailglass.Tenancy.clear()
end)
```

The mutation proof is available and cheap: install the leaking resolver, run
`SupportSummary.summarize_tenant/1`, observe the `CompileError`, apply the `delete_env`, observe it clear.
A broader sweep for the same `put_all_env`-restore anti-pattern across the suite is warranted — the pattern
is silent by construction, and this is the second file known to need the explicit delete.

---

## The recorded escape hatch, and why it is not being taken

The plan names an escape hatch: if three consecutive greens prove unreachable, drop the gating work and
record HARNESS-04 as a deliberate "not gating, and here is why" — which the goal criterion permits, since it
asks **whether** Core Full Suite is now release-gating.

**Not recommended, and not taken.** Three consecutive greens are not unreachable; they are *blocked on a
merge and one open defect*, both of which are ordinary work with a clear path:

1. Fix the `:tenancy` leak (Finding B) with a mutation proof.
2. Merge `gsd/phase-143-test-harness-truth` to `main`. This alone should turn the lane green — `main`'s
   failures are the schema-collision and ordering classes this branch closed.
3. Collect three consecutive green `main` runs, at least one from the cron. The cron runs daily, so this
   costs about two days of ordinary pushes plus one overnight.
4. Cut a throwaway tag from green `main`, dispatch on it, record both conclusions, delete the tag.
5. Dispatch the probe from a green ref with the command recorded in `143-PROBE-EVIDENCE.md`.
6. Re-open this checkpoint. Then, and only then, `143-13`.

Taking the escape hatch now would record "not gating" as a *decision* when it is really a *deadline*, and
would leave the maintainer's approved blocking decision unimplemented for reasons that expire in a week.

---

## What is confirmable only by a real CI run

Recorded so no one mistakes any of it for settled:

1. Conditions 1, 2, 3 and 5's merge sub-claim — all require runs on `main` after the merge.
2. Condition 4 — requires the `gate-self-test.yml` dispatch.
3. The two `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema …)` runtime names
   (sub-item B) — require a post-merge `push` or `schedule` run.
4. Whether the 1.19/OTP 28 legs pass the floors pinned from 1.18 measurements. They have still never
   executed on this branch, and `main`'s have been red throughout. `143-10` left this open; it stays open.
5. Whether the `:tenancy` leak is the *only* source of the nondeterminism, or merely the one traced here.

## Pipeline footgun — unchanged, and not made worse

A release-please **bot-merged** release SHA gets no `ci.yml` run (GitHub anti-recursion), so a check keyed
to that workflow reports "no ci.yml runs found for SHA"; recovery is to dispatch `ci.yml` on the release tag,
or land the release commit under a human identity. **This plan introduced no new instance of that failure
mode** — it modified no workflow and wired no gate. Plan `143-13` must take care here: a gate keyed to
`advisory-matrix.yml` runs on a bot-merged release SHA has the same exposure, and condition 3's tag-shaped
dispatch is exactly the rehearsal that would surface it.

## Publishing safety posture — unchanged

`.github/workflows/publish-hex.yml` was **not** touched by this plan, under any circumstance, as Task 2's
action directs. No credential scoping was changed; the `hex-publish` GitHub Environment arrangement is
untouched. Verified: `git diff --name-only origin/main -- .github/workflows/publish-hex.yml` is empty for
this plan's commits.
