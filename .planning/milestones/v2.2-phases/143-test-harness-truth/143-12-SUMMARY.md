---
phase: 143-test-harness-truth
plan: 12
subsystem: ci-lane-truth
tags: [harness-02, harness-03, harness-04, d-18, d-21, d-24, d-28, promotion-checkpoint, anti-vacuity]
status: blocked-at-checkpoint
requires:
  - "143-11 — the D-21 rename and the third registry axis (advisory_matrix_gating_lanes/0)"
  - "143-02 — gate-self-test.yml's required_only / deadline_minutes inputs and the never-appeared outcome"
provides:
  - ".planning/phases/143-test-harness-truth/143-PROMOTION-CHECKPOINT.md — all five D-28 conditions assessed against live evidence, verdict BLOCKED (0/5)"
  - "143-PROBE-EVIDENCE.md's Core Full Suite section — recorded NOT RUN, with the verbatim dispatch command and every input justified"
  - "Research assumption A5 closed for the two gating lanes (exact registry-to-runtime name match, run 30574508370)"
  - "Finding B — a live global-state leak (:tenancy via Application.put_all_env) causing nondeterministic failure in the lane proposed for publish-veto"
affects:
  - ".planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md"
  - ".planning/phases/143-test-harness-truth/143-PROMOTION-CHECKPOINT.md"
  - ".planning/phases/143-test-harness-truth/deferred-items.md, .planning/WINDOWS.md"
tech-stack:
  added: []
  patterns:
    - "A checkpoint that cannot gather its evidence records the absence as the finding, rather than lowering its own bar to clear itself"
    - "An automated verification that passes against the untouched file is vacuous — test the verify before trusting a green verify"
key-files:
  created:
    - .planning/phases/143-test-harness-truth/143-PROMOTION-CHECKPOINT.md
  modified:
    - .planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md
    - .planning/phases/143-test-harness-truth/deferred-items.md
    - .planning/WINDOWS.md
decisions:
  - "Recorded the checkpoint verdict as BLOCKED (0 of 5 conditions) rather than clearing it. Three conditions fail on evidence independently of the process constraints; only two are constraint-blocked. Clearing on partial evidence is the plan's own named prohibition."
  - "Did NOT take the recorded not-gating escape hatch. Three consecutive greens are not unreachable — they are blocked on a merge plus one open defect, both ordinary work with a clear path. Taking the hatch now would record 'not gating' as a decision when it is really a deadline."
  - "Did NOT fix the :tenancy leak found in Finding B. Pre-existing, not caused by this plan's changes, outside its two-file scope, and deserving of the mutation proof every other guard in this phase received. Recorded in three places instead."
  - "Did NOT flip HARNESS-02 or HARNESS-03 in REQUIREMENTS.md. HARNESS-03's probe is this plan's deliverable and it did not run; 143-14 owns that file."
metrics:
  duration: "~1h"
  completed: "2026-07-30"
  conditions-met: 0
  conditions-total: 5
  dispatches-made: 0
  commits: 1
---

# Phase 143 Plan 12: The promotion checkpoint — Summary

**The checkpoint is held, not cleared. 0 of 5 D-28 conditions are met, and only two of the five failures are
attributable to this plan's process constraints — `main`'s Core Full Suite has been red for twenty-eight
days, and the lane proposed for publish-veto power was caught failing nondeterministically on a docs-only
commit, with the mechanism traced to a live global-state leak. Nothing was given veto power over a Hex
publish.**

---

## What this plan could not do, stated first

Plan `143-12` is built entirely on two real GitHub Actions dispatches: Task 1 runs `gate-self-test.yml`
(which pushes a branch and opens a PR), and Task 2's condition 3 pushes a throwaway tag and dispatches
`advisory-matrix.yml`. This plan's process constraints state, verbatim: **"Do NOT push. Do NOT trigger
GitHub Actions runs (real CI minutes on a public repo)."**

**No dispatch was made. No branch, tag or PR was pushed. Zero CI minutes were consumed.** Every fact below
comes from read-only `gh` queries against runs that already existed, or from local runs.

This is the third consecutive plan in this phase to hit the same wall (`143-10` Task 3, `143-11`'s
post-rename push run). It is recorded openly rather than worked around.

---

## Verdict: BLOCKED — 0 of 5 conditions

| # | Condition | Status | Why |
|---|---|---|---|
| 1 | Three consecutive `main` runs, distinct SHAs, both gating legs green | **NOT MET** | **Zero** green Core Full Suite legs on `main`. Not a shortfall of three — of one. |
| 2 | At least one of the three is a `schedule` (cron) run | **NOT MET** | Cron runs exist on the right cadence; none is green. |
| 3 | A `workflow_dispatch` on a tag-shaped ref, both legs green | **NOT MET** | Constraint-blocked. Not attempted; no tag created, so no cleanup outstanding. |
| 4 | The deliberate-failure probe has gone red against the renamed lane | **NOT MET** | Constraint-blocked. Not attempted; no run URL exists. |
| 5 | The executed-count floor is merged and green | **NOT MET** | `grep -c MAILGLASS_SUITE_FLOOR` on `origin/main`'s workflow → **0**. Unmerged. |

Conditions 1, 2 and 5 fail **on the evidence**, independently of the constraints. Only 3 and 4 are purely
constraint-blocked.

---

## The finding that dominates condition 1: `main` has been red for 28 days

Of the **last 40** `advisory-matrix.yml` runs on `main`: **34 `failure`, 6 `cancelled`, 0 `success`.** The
most recent success is run `28568190903` at `c34e54e6`, **2026-07-02** — every run from 2026-07-04 onward is
red or cancelled. Job-level, all four Core Full Suite legs fail in each of the five most recent runs, while
`Provider Compatibility Advisory` and both `Inbound Full Suite Advisory` legs pass. The failure is specific
to Core Full Suite.

The cause is the defect set this branch fixes — `ERROR 42P01 (undefined_table) relation
"mailglass.mailglass_suppressions" does not exist` and `Map.keys(summary)` ordering. So condition 1 is
**unsatisfiable until this branch merges**: it asks for `main` evidence of a lane that only goes green with
code not yet on `main`.

**The operational consequence, and the reason this matters more than a paperwork gap:** under the approved
blocking decision, wiring `gate-ci-green` to this lane today would block every publish from `main`
immediately and unconditionally. Not a risk — the guaranteed outcome.

---

## The exact semantics: what blocks, what passes, what the override path is

The maintainer's approved **blocking** decision is recorded in the checkpoint artifact so plan `143-13` does
not re-ask, together with its rationale (thirty minutes and one dispatch versus an unrecallable sixty
minutes on Hex, and a preference for a documented deliberate override over narrowing the check).

**No gate semantics were implemented by this plan.** `.github/workflows/publish-hex.yml` was not touched —
verified, `git diff --name-only -- .github/workflows/publish-hex.yml` is empty. `gate-ci-green` still does
not read `advisory-matrix.yml`. HARNESS-04 remains open. What this plan produced is the decision record and
the evidence gate that `143-13` must clear first.

What the checkpoint records for `143-13` to implement:

- **Would block:** the two lanes in `advisory_matrix_gating_lanes/0` — `Core Full Suite (Elixir 1.18 / OTP
  27 / schema public)` and `… / schema mailglass)`.
- **Would not block:** the five lanes in `advisory_matrix_advisory_lanes/0`, including both next-toolchain
  1.19/OTP 28 legs (forward-compatibility canary) and both `Inbound Full Suite Advisory` legs (D-20 — pinned
  `--seed 0` to dodge a known flake, so gating it would gate on the absence of an unfixed bug).
- **Override path:** not yet designed. The checkpoint records the requirement that it be usable **without a
  code change**, and the specific reason: two of the four steps these legs gate are network- and
  service-dependent (see blast radius below), so a Hex outage or a Postgres hiccup can block a release with
  no core regression present.

### Blast radius — the four steps gating these two legs actually gates

Named so it is recorded rather than discovered. Steps 2–4 are the ones the 1.19 legs do **not** run:

| # | Step | Command | 1.19 legs? |
|---|---|---|---|
| 1 | `Run advisory full suite` | `mix test --warnings-as-errors --exclude requires_workspace` | yes |
| 2 | `Install inbound deps for focused schema-prefix proof` | `mix deps.get` (`working-directory: mailglass_inbound`) | **no** |
| 3 | (same step) | `mix ecto.create -r MailglassInbound.TestRepo --quiet` | **no** |
| 4 | `Run focused schema-prefix proof` | `mix verify.schema_prefix` | **no** |

---

## Finding B — the lane fails nondeterministically, and the mechanism is a live global-state leak

The most consequential result, and not something the plan asked for.

**The observation.** Run `30571989203`, head SHA `71fcd8f5`, full-suite seed `590679`: the mailglass gating
leg **fails** with two `** (Ecto.Query.CompileError) can't apply alias :scoped, binding in from is already
aliased to :orphan` from `SupportSummary.orphan_backlog_summary/2`. `71fcd8f5` is
`docs(143-10): …` — **one file, `.planning/WINDOWS.md`, 16 insertions, no code**. Two commits later at
`6bacf2ff` the same leg is green, with `lib/mailglass/operator/support_summary.ex` byte-identical
(`git diff --stat` empty), nothing under `lib/` changed at all, and `main` unmoved (tip `25c74ca0`,
2026-07-29). Same code, same merge base, same toolchain — red, then green.

**The mechanism, traced to the line.** `Mailglass.Tenancy.scope/2` resolves via
`Application.get_env(:mailglass, :tenancy)` — global state. Two test modules define a resolver whose
`scope/2` applies `as: :scoped`; `grep -rn "as: :scoped" lib/` returns nothing, so that alias exists only in
test code. `unsubscribe_test.exs`'s `on_exit` restores with `Application.put_all_env/1`, which **merges** and
cannot remove a key absent from the saved env — and `:tenancy` is in no `config/*.exs`, so it is never in the
saved env. Demonstrated directly rather than asserted:

```
$ elixir -e 'Application.put_all_env(demoapp: [a: 1])
             prior = Application.get_all_env(:demoapp)
             Application.put_env(:demoapp, :tenancy, LeakedModule)
             Application.put_all_env(demoapp: prior)
             IO.inspect(Application.get_env(:demoapp, :tenancy), label: "after restore")'
after restore: LeakedModule
```

The module sets `:tenancy` at lines 103/216 and relies on in-test `delete_env` at 109/119/221; any raise
between put and delete leaks it for the rest of the suite. **The sibling
`unsubscribe_property_test.exs` already carries the fix** — explicit
`Application.delete_env(:mailglass, :tenancy)` after `put_all_env` (line 52) plus a defensive delete in
`setup` (line 34) — which is strong corroboration that this leak has been hit before.

**Why it blocks promotion.** It is a residual instance of the exact defect class this phase exists to close,
it is invisible to `SuiteFloor` (counts are unaffected; ExUnit reports a real failure), and it defeats
condition 1's *purpose* even if the count were met — three greens from a lane that flips on a docs-only
commit is luck, not evidence of stability.

**Not fixed here, deliberately.** Pre-existing, outside this plan's two-file scope, and deserving the
mutation proof every other guard in this phase received. **Not masked, skipped, tagged away, serialized
around, or weakened.** Recorded in three places: the checkpoint (Finding B), `deferred-items.md`, and
`.planning/WINDOWS.md` (kind `unmet-truth`). The recommended one-line fix and a suggested suite-wide sweep
for the same `put_all_env`-restore anti-pattern are recorded with it.

---

## Assumption A5 — closed for the gating pair, open for two advisory names

Observed on run `30574508370`, the first post-rename run:

| Observed runtime name | Registry accessor | Match |
|---|---|---|
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` | `advisory_matrix_gating_lanes/0` | **exact** |
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` | `advisory_matrix_gating_lanes/0` | **exact** |
| `Provider Compatibility Advisory (Elixir 1.18 / OTP 27)` | `advisory_matrix_advisory_lanes/0` | **exact** |
| `Inbound Full Suite Advisory (schema public)` / `(schema mailglass)` | `advisory_matrix_advisory_lanes/0` | **exact** |
| `Core Full Suite Next Toolchain Advisory (Elixir ${{ matrix.elixir }} / …)` | — | **unexpanded** |

**A5 is closed for the two lanes the gate will actually match on** — `expanded_matrix_job_names/1` computed
these from the workflow source and GitHub reports them character-for-character, so exact-equality matching is
safe where `143-13` needs it. This is a genuine advance on `143-11`'s open item 1.

**A5 is not closed for the two next-toolchain legs.** On `pull_request` they collapse to a single
placeholder with the matrix expression uninterpolated (the D-21 artifact, now seen a third time), so the two
registry strings have never been reported live. Only `push`/`schedule` expand them, and neither has occurred
since the rename because the rename is unmerged. Recorded as an inference, not a closure.

---

## Verification — raw `mix test` / `mix dialyzer` / `mix credo` output only

No SuiteFloor ledger line and no formatter output was used to validate itself. Both suite runs were preceded
by `MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && mix ecto.create -r Mailglass.TestRepo --quiet`.

### Local (Elixir 1.19.5 / OTP 28)

| Gate | Command | Result | Exit |
|---|---|---|---|
| public axis | `mix test --seed 783091 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1590 tests, 0 failures**, 7 skipped (13 excluded); `total: 1626, excluded: 13, skipped: 7, executed: 1606` | 0 |
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1589 tests, 0 failures**, 7 skipped (14 excluded); `total: 1626, excluded: 14, skipped: 7, executed: 1605` | 0 |
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` / `done (passed successfully)` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3926 mods/funs, found no issues.` | 0 |
| Scripts lane | `mix test test/scripts/ --warnings-as-errors` | 102 tests, 0 failures | 0 |
| Artifact-reading contracts | `mix test test/mailglass/docs_contract_test.exs test/scripts/mechanism_account_contract_test.exs --warnings-as-errors` | 42 tests, 0 failures, 1 skipped | 0 |

### Gating toolchain (`make toolchain`, Elixir 1.18.4 / OTP 27, 2 vCPU / 4 GB)

| Command | Result | Exit |
|---|---|---|
| `make toolchain CMD='mix test test/scripts/ test/mailglass/docs_contract_test.exs --warnings-as-errors'` | **135 tests, 0 failures**, 1 skipped | 0 |

Identical to `143-11`'s toolchain figure, as expected — this plan changed no code.

**Executed counts are unchanged from `143-11` on both axes** (1606 / 1605), which is the correct outcome:
this plan adds no tests and removes none. The local public figure of 1606 matches CI run `30574508370`'s
`executed: 1606` exactly. `.dialyzer_ignore.exs` untouched (`git diff HEAD` empty); it stays at its hard cap
of 15.

### Mutation evidence

**None, and none was required.** This plan added no guard, no assertion and no code — its two deliverables
are planning artifacts. Rather than manufacture a mutation to fill the section, two *mechanism*
demonstrations were run instead, and both are reproduced above: the `put_all_env` non-removal proof
(Finding B) and the vacuity proof of the plan's own Task 1 verification (below).

---

## The plan's own Task 1 verification is vacuous — recorded so it is not trusted

`143-12-PLAN.md` verifies Task 1 with
`grep -q 'result=blocked' .planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md`.

**That command already exited 0 against the untouched file**, because the reserved section legitimately
quotes the expected value at line 150 (`… is expected to report **`result=blocked`** …`). Verified before any
edit:

```
$ grep -q 'result=blocked' …/143-PROBE-EVIDENCE.md && echo PASSES
PASSES
$ grep -n 'result=blocked' …/143-PROBE-EVIDENCE.md
150:required_only=false` against a synthetic-failure PR is expected to report **`result=blocked`** — i.e.
```

The check cannot distinguish "the probe ran and the lane blocked" from "the probe never ran and this file
merely predicts that it would" — this phase's own failure mode, appearing inside this phase's own plan. A
non-vacuous replacement (asserting the recorded outcome line and a run URL together) is recorded in
`143-PROBE-EVIDENCE.md`. **Task 1's automated verify is therefore reported as PASSING-BUT-VACUOUS, not as
passing.**

---

## Deviations from Plan

### 1. Task 1 not executed — process constraints forbid the dispatch

`gate-self-test.yml` cannot run without pushing a branch and opening a PR. Recorded as NOT RUN in
`143-PROBE-EVIDENCE.md` with the verbatim dispatch command, every input justified (including the two easy to
get wrong: `--ref` must be the phase branch, since `main`'s pre-rename lane name would not match the prefix;
and `required_only=false`, since the required set is exactly two entries), the `action_required` approval
blocker from Run 1, and the `timeout-minutes: 30` job cap that constrains `deadline_minutes`.

### 2. Task 2 checkpoint recorded as BLOCKED rather than cleared

The plan's prohibition is explicit: "MUST NOT proceed to the gate wiring on partial evidence." With 0 of 5
conditions met, the honest output is a blocked checkpoint. The artifact was still written in full — every
condition assessed against live evidence with run IDs, SHAs, events, conclusions and seeds — because the
evidence that *does* exist is what makes the blocked verdict actionable rather than a shrug.

### 3. [Rule 2 — Missing critical functionality, recorded not applied] Finding B

A defect materially affecting this plan's central decision, discovered while gathering condition-1 evidence.
Not fixed, for the scope reasons above. Recorded in three places so it cannot be lost.

### 4. The not-gating escape hatch was not taken

The plan permits recording HARNESS-04 as a deliberate "not gating, and here is why" if three consecutive
greens prove unreachable. They are not unreachable — they are blocked on a merge plus one open defect. The
checkpoint records a six-step path (fix the leak, merge, collect three greens including a cron, cut and
dispatch a tag, run the probe, re-open the checkpoint) costing roughly two days of ordinary work.

### 5. Condition 3's cleanup requirement is satisfied vacuously and is labelled as such

No throwaway tag was created, so none is orphaned. Stated explicitly in the artifact so a future reader does
not read "no orphaned tag" as evidence the dispatch happened.

---

## Known Stubs

None. No placeholder, TODO, FIXME or sentinel value was introduced. Every run ID, SHA, seed and count in
both artifacts is a value read from a live GitHub Actions API response or a local command's raw output.

The two artifacts do contain **explicit NOT MET / NOT RUN records**. Those are the deliverable, not stubs.

## Threat Flags

None. No network surface, auth path, file-access pattern or schema change at a trust boundary was
introduced. Publishing safety posture is unchanged: `publish-hex.yml` untouched, no credential scoping
altered, the `hex-publish` GitHub Environment arrangement not modified.

The plan's four registered threats:

| Threat | Disposition |
|---|---|
| T-143-42 (timeout/never-appeared recorded as inconclusive) | Moot — no probe outcome exists. The artifact forbids reading its expected value as an observation, and flags the vacuous grep. |
| T-143-43 (wiring the gate on partial evidence) | **Mitigated** — checkpoint recorded BLOCKED at 0/5; `publish-hex.yml` untouched. |
| T-143-44 (orphaned tag or probe branch) | **Mitigated vacuously** — nothing was created. `gh pr list --search 'head:gate-self-test/'` unchanged from Run 1's confirmed-clean state. |
| T-143-45 (registry names not matching runtime) | **Partially mitigated** — exact match confirmed for the gating pair; the two next-toolchain names recorded as unconfirmed. |

---

## Still Open

1. **Conditions 1, 2, 3 and 5's merge sub-claim** — all require `main` runs after the merge.
2. **Condition 4** — requires the `gate-self-test.yml` dispatch. Command recorded verbatim.
3. **The two next-toolchain runtime names** — require a post-merge `push` or `schedule` run.
4. **The 1.19/OTP 28 legs still have never executed on this branch** and now carry floors measured on the
   1.18 legs. `143-10` left this open; unchanged.
5. **Whether the `:tenancy` leak is the only source of the nondeterminism**, or merely the one traced here.
6. **`REQUIREMENTS.md` was not touched, in either direction.** HARNESS-02 and HARNESS-03 remain `[x]`
   although HARNESS-03's deliberate-failure probe — this plan's deliverable — did not run, and HARNESS-02's
   "all four matrix legs" bar still has evidence for two. Plan `143-14` owns that file. **The evidence for
   reconciling both is recorded here and in the checkpoint rather than acted on**, exactly as instructed, so
   this is not compounded into a fifth premature-completion incident.
7. **`gate-ci-green` still does not read `advisory-matrix.yml`.** HARNESS-04 stays `[ ]`.
8. **Prior gap closures' open items are unchanged and none is narrowed here**: no full-clock reproduction of
   the 120s ownership timeout, `probe/1` remains mode-keyed rather than liveness-keyed, and the formatter's
   `:module_finished`-only blind spot (`143-MECHANISM.md` §7) is untouched.

## Pipeline footgun — not made worse

The bot-merged-release-SHA / no-`ci.yml`-run footgun is unchanged. This plan modified no workflow and wired
no gate, so it introduced no new instance. The checkpoint flags that a gate keyed to `advisory-matrix.yml`
runs on a bot-merged release SHA has the same exposure, and that condition 3's tag-shaped dispatch is the
rehearsal that would surface it.

---

## Self-Check: PASSED

| Claim | Verification |
|---|---|
| `143-PROMOTION-CHECKPOINT.md` created | present; 4+ run URLs matching the `actions/runs/[0-9]+` pattern |
| `143-PROBE-EVIDENCE.md` Core Full Suite section filled | present; records NOT RUN plus the verbatim dispatch command |
| No dispatch, push, tag or branch created | `git status --short` shows only `.planning/` paths; no `gh workflow run` / `git push` was issued |
| `publish-hex.yml` untouched | `git diff --name-only -- .github/workflows/publish-hex.yml` empty |
| No source file modified | `git status --short` → 3 modified + 1 new, all under `.planning/` |
| Both axes green, fresh DB, `--warnings-as-errors` | public 1590/0 exit 0; mailglass 1589/0 exit 0 |
| Dialyzer / format / credo clean | exits 0, 0, 0; `.dialyzer_ignore.exs` untouched |
| Gating toolchain clean | `make toolchain` 135 tests, 0 failures, exit 0 |
| `REQUIREMENTS.md` untouched | not in `git status --short` |
| Finding B recorded in three places | checkpoint § Finding B; `deferred-items.md`; `.planning/WINDOWS.md` (`unmet-truth`) |
