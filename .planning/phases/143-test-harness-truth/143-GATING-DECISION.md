---
artifact: gating-decision
phase: 143-test-harness-truth
plan: 13
task: 1
created: 2026-07-31
verdict: gate-floor-legs
---

# 143-GATING-DECISION — the one-way door, decided

## Verdict: **`gate-floor-legs`**

The two Elixir 1.18 / OTP 27 `Core Full Suite` legs are given veto power over a Hex publish, as D-19
designs it. `no-gate-record-why` is **not** taken.

The two legs, by their exact runtime names:

```
Core Full Suite (Elixir 1.18 / OTP 27 / schema public)
Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)
```

Nothing else on `advisory-matrix.yml` gates. The 1.19 / OTP 28 next-toolchain legs, `Provider
Compatibility Advisory`, and both `Inbound Full Suite Advisory` legs stay advisory — classified,
enumerated, warned on, never blocking.

---

## The decision was already made; this record executes it, it does not re-open it

`143-PROMOTION-CHECKPOINT.md` § "Decision of record" states it plainly: *"The maintainer has approved
the **blocking** option for the fork about whether the Core Full Suite legs should be able to block a
release. Plan `143-13` should execute on that basis and **must not re-ask**."* The maintainer
re-confirmed it at the start of this plan's execution, with the promotion checkpoint closed.

What was genuinely open was not *whether* but *when* — the checkpoint was `BLOCKED, 0 of 5` when
`143-12` wrote it, because the lane had never been observed green on `main`. That is now closed.

---

## The evidence this verdict rests on

### C1 — three consecutive green `advisory-matrix.yml` runs, three DISTINCT `main` SHAs

| # | Run | Event | Head SHA | Both gating legs |
|---|---|---|---|---|
| 1 | [`30595090072`](https://github.com/szTheory/mailglass/actions/runs/30595090072) | `push` | `d6e50388` | success / success |
| 2 | [`30635221221`](https://github.com/szTheory/mailglass/actions/runs/30635221221) | `push` | `981b9343` | success / success |
| 3 | [`30638980059`](https://github.com/szTheory/mailglass/actions/runs/30638980059) | `push` | `7649f96f` | success / success |

Three distinct `main` SHAs, which is what the condition asks for and what
`143-MAIN-GREEN-EVIDENCE.md` correctly refused to claim when the count stood at two. All four Core
Full Suite legs are green in each — including the 1.19 / OTP 28 pair, which had never executed at all
during the phase's branch life.

Before the merge, `main`'s Core Full Suite had been **red for 28 days**: 0 successes in the last 40
runs, last green `28568190903` on 2026-07-02.

### C2 — one of them a `schedule` (cron) run

[`30607136165`](https://github.com/szTheory/mailglass/actions/runs/30607136165), `schedule`, head SHA
`d6e50388`, green on both gating legs. First green cron on `main` since 2026-07-02. This is the
condition's substantive point: a plain `main` SHA, cold cache, no pull-request context, fully
unattended.

### C3 — a `workflow_dispatch` on a tag-shaped ref

[`30595564984`](https://github.com/szTheory/mailglass/actions/runs/30595564984), dispatched on a
throwaway tag cut from green `main`; both gating legs green; tag deleted afterwards, none orphaned.

This is the condition `143-PROMOTION-CHECKPOINT.md` calls *"the only proof of the exact code path the
gate will use, and the one nobody would think to run."* It is not redundant, and it is now the
load-bearing rehearsal for this plan's self-heal: the gate dispatches `advisory-matrix.yml` on the
**release tag**, and this run is the evidence that a tag-shaped ref dispatch resolves, expands both
matrix legs with fully-interpolated suffix-free names, and goes green.

### C4 — the deliberate-failure probe went red against the renamed lane

[`30599206217`](https://github.com/szTheory/mailglass/actions/runs/30599206217): both gating legs
returned **FAILURE** on a commit carrying `test/gate_self_test/intentional_failure_test.exs`
verbatim, on a branch cut from the green `main` SHA. Probe PR
[#156](https://github.com/szTheory/mailglass/pull/156), closed, branch deleted.

- `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` → **FAILURE** ([job 91058066866](https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066866))
- `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` → **FAILURE** ([job 91058066875](https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066875))

Recorded in `143-PROBE-EVIDENCE.md`. Condition 4's bar — *a lane never observed catching an injected
regression must not be given veto power over a publish* — is met: the lane was observed catching one.

**The residual gap is recorded honestly rather than elided.** The observation is not reproducible
without a human (or an agent with a user token) in the loop, because `gate-self-test.yml`
structurally cannot produce it: GitHub does not trigger workflows for events raised with
`GITHUB_TOKEN`, so the PR the workflow opens receives zero checks. That is the same anti-recursion
rule this plan's self-heal is built around. It does not weaken what was observed; it means the
observation is a manual procedure today.

### C5 — the executed-test-count floor is merged and enforcing

`public: 1576`, `mailglass: 1575`, `skipped_ceiling: 7`, enforced on every leg — including the
previously-unmeasured 1.19 / OTP 28 pair, whose log declares *"executed floor 1576, skipped ceiling 7
enforced; a violation halts this run"* at `executed: 1623`.

---

## The trade, restated so the verdict is made against it rather than around it

**Against gating.** The ecosystem norm is dramatically weaker: comparable Elixir libraries — Bandit,
Phoenix, Ecto, Oban, Req, Broadway — publish on tag push with no test gating at all. And on a
hands-free auto-merging pipeline a wedged gate is a silent unattended stall, discovered when a
release does not happen rather than when something breaks.

**For gating.** The seven required lanes are narrow contract and file lists. Today a total core
regression can reach Hex without a single red light — and that is not hypothetical any more. On
2026-07-31, mid-phase, the pipeline cut and published `mailglass` 2.2.2 / `mailglass_admin` 2.2.2
with **no human approval and no test gate**, while the `CI` workflow run on the released SHA was
itself **red** (`Demo Browser Evidence`, a job absent from `CI Green`'s `needs` list). `main` happened
to be green, so the published artefact is the tested tree. The point is that nothing in the pipeline
would have stopped a bad one. Recorded in `143-MAIN-GREEN-EVIDENCE.md`.

**The asymmetry decides it.** A blocked release costs the maintainer thirty minutes and one dispatch.
A published broken core costs every adopter and cannot be unpublished after sixty minutes on Hex.
Gate — and pay for it with a documented override rather than by narrowing the gate until it stops
being able to observe a regression.

**Why the floor pair only.** This repo's own prior research settles the scope:
`prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:167` ("keep branch protection tied to a
smaller required matrix") and `:329`, which lists *"use one gigantic matrix as required status"* under
anti-patterns. Ecto and Oban both confine `--warnings-as-errors` to a single matrix row for the same
reason. The gated legs are exactly the declared `~> 1.18` floor `mix.exs` states, so LD-13's
floor-coincidence invariant is preserved.

---

## The accepted costs, stated verbatim rather than discovered later

1. **Added release wall-clock.** Every release now waits on a dispatched `advisory-matrix.yml` run on
   the release tag, cold cache — roughly ten and a half minutes, and it is a *dispatched* run rather
   than one that already exists, because a release-please bot-merged SHA structurally has none.

2. **Floating-toolchain exposure.** A floating 1.18.x toolchain can red the gate with no repo change,
   because the lane runs with `--warnings-as-errors`. A new warning introduced by a patch release of
   Elixir 1.18 blocks a publish that has no regression in it.

3. **Three extra steps inside the gated legs.** Gating `core_full_suite` gates more than a test
   command. The job's steps 2 through 4 — the inbound `mix deps.get`, the inbound
   `mix ecto.create -r MailglassInbound.TestRepo`, and `mix verify.schema_prefix` — are gated too, and
   the next-toolchain legs run none of them. Two of those three are **network- and
   service-dependent**: a Hex outage or a Postgres service hiccup in `mailglass_inbound` can block a
   release with no core regression present.

Cost 3 is precisely why the override is not optional garnish. `143-PROMOTION-CHECKPOINT.md` § sub-item
C states the requirement it creates: *"the override path must be usable **without** a code change, or
the maintainer's thirty minutes becomes a day."* Tasks 2 through 4 of this plan implement it as
`skip_core_full_suite_gate` + a required `core_full_suite_gate_skip_reason`, dispatch-only and inert
on the release event.

---

## Two things this verdict does NOT license

**It does not license widening.** Two legs gate. Adding a third is a deliberate act with its own
evidence bar, and `lane_classification_drift_test.exs` pins the count at 2 so widening cannot happen
by accident.

**It does not license the override becoming the habit.** D-30 records that risk explicitly. The
override is dispatch-only, inert on the automated release path, requires a written reason, echoes that
reason to the run summary, and logs a warning naming itself as an exception. A gate whose override is
reached for reflexively is a gate that has been removed without anyone recording that it was.
