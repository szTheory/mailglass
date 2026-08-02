---
artifact: handoff
phase: 143-test-harness-truth
created: 2026-07-31
---

# 143-HANDOFF — state, live evidence, and the traps

Written at a deliberate stopping point. Plans 143-01..143-13 are complete and merged to `main`.
**143-14 is the only plan left**, and only half of it.

---

## 1. What is done and live on `main`

| Landed | PR | `main` SHA |
|---|---|---|
| The harness fixes + recurrence guards | #151 | `d6e50388` |
| `gate-self-test.yml` probe fixes | #157 | `981b9343` |
| Post-merge evidence, three windows closed | #159 | `7649f96f` |
| **The publish gate** (143-13) | #161 | `34008138` |

`main` had a **red Core Full Suite for 28 days** (0 of the last 40 advisory-matrix runs green, last
green 2026-07-02). It is green now, all four legs, floors enforced.

Released and published to Hex during this work: **2.2.2** (ungated) and **2.3.0** (through the new
gate). `mailglass_inbound` remains 2.1.1 and is unaffected — it pins `{:mailglass, "~> 2.0"}`, a
range, **not** the exact `== <core>` pin CLAUDE.md still describes. That note in CLAUDE.md is stale.

---

## 2. The only remaining work — 143-14's negative rehearsal

143-14 wants two rehearsal runs. **The positive half is already evidenced by a real release**, better
than a manufactured one could be:

> Release 2.3.0, tags cut on `d0054bdc`. The release SHA had **no** advisory-matrix run (anti-recursion,
> see §3). `gate-ci-green` **dispatched** run [`30645896855`](https://github.com/szTheory/mailglass/actions/runs/30645896855)
> (`workflow_dispatch`, ref `mailglass_admin-v2.3.0`), waited ~9 minutes, saw green, and released the
> publish. `gate-ci-green` = **success** in both publish runs
> ([core](https://github.com/szTheory/mailglass/actions/runs/30645265238),
> [admin](https://github.com/szTheory/mailglass/actions/runs/30645266725)). Only one advisory dispatch
> appeared across both, so the fan-out settle appears to deduplicate as designed.

**Outstanding: the NEGATIVE rehearsal** — prove a RED gating leg actually blocks a publish. This is
what the phase goal's *"demonstrably blocks a Hex publish (not merely a PR merge)"* asks for, and it
is the reason `HARNESS-04` is still `[ ]`.

It was **not attempted deliberately**, not forgotten: it points a dispatch at `publish-hex.yml`, and
that is the one irreversible surface here. Whoever runs it should confirm intent explicitly first,
use `dry_run`, cut the throwaway tag **after** the gate change is on `main` (a dispatch runs the
workflow file as it exists at the ref, so an older tag would test the old gate and prove nothing),
and delete the tag afterwards.

---

## 3. The trap that bit three times in one day — read this first

**GitHub does not trigger workflows for events raised with `GITHUB_TOKEN`.** Every bot-merged commit
and bot-opened PR is affected. Observed three separate times on 2026-07-31:

| Where | Symptom |
|---|---|
| `gate-self-test.yml` | The PR it opens itself gets **zero checks**. Run 30597469482 polled 35 min and observed an empty check list. This is why condition 4's probe had to be run manually. |
| Release commits | `e88daa15` and `d0054bdc` have **no** advisory-matrix run and no release-please run. |
| `ci.yml` | Already documented in CLAUDE.md: `gate-ci-green` reports "no ci.yml runs found for SHA". |

Consequences already handled:
- **The gate DISPATCHES, it does not look up.** A lookup-only gate would wedge every release.
- **release-please has a sanctioned recovery**: `workflow_dispatch` ("one-click manual recovery,
  anti-recursion exception") plus an hourly `schedule` dead-man's-switch at `17 * * * *`. The
  preflight is idempotent. Used on 2026-07-31 to complete 2.3.0's tags.

**Open decision, now much smaller than it looked.** `gate-self-test.yml` cannot self-serve because of
this rule. Automating it needs a PAT — and **`RELEASE_PLEASE_PAT` already exists in this repo for
exactly this reason**. So the question is not "create and store a PAT?" but "reuse the existing one,
or mint a narrower-scoped sibling?" Unresolved; maintainer's call.

---

## 4. Things that look like failures and are not

- **`Demo Browser Evidence (Docker Compose / Chromium)`** fails on `main` and always has. Pre-existing,
  out of scope for this phase.
- **`Operator Browser Gate`** flakes on heavy Playwright matrix specs (~30s timeouts, a different spec
  each time) and passes on rerun.
- **`publish-core` "failure" on one of two release runs.** Both the core and admin tags fan out to
  `publish-core`, so whichever loses the race reports
  `inserted_at: must include the --replace flag to update an existing release` against an
  already-successful publish. Seen on both 2.2.2 and 2.3.0, winner reversed between them. **Verify
  against the Hex registry, not the run conclusion.** A genuine core-publish failure stays
  distinguishable: `gate-ci-green` emits nothing resembling that text, and every blocking message it
  emits carries a `Delivery blocked: ` prefix and names a lane.
- **The advisory-matrix cron fires ~1h late, daily.** Declared `21 4 * * *`; actual 05:29 / 05:20 /
  05:33 on successive days. A missing 04:30 run is not a skipped schedule.

---

## 5. The biggest unshipped finding — read before trusting the ledger

**`SuiteTruthFormatter`'s four module-boundary probes have never executed, not once.**
`async_false?/1` reads `%ExUnit.TestModule{}.tags[:async]`, which is `%{}` for every module. Their
negative controls passed because they synthesise a struct shape ExUnit never produces.

A fix was written and run: it surfaces **103 violations**, including **2 real `pool_mode_leaked`**.
It is **deliberately not shipped**, because it converts ~15 unrelated pre-existing Class A/C defects
into gating-lane violations — that wants its own phase, not a ride-along.

Until then: **a green/empty ledger is not evidence.** Validate against raw `mix test` output and raw
`already_shared` counts. Recorded in `.planning/WINDOWS.md`.

---

## 6. Working conventions that were load-bearing

- **`make toolchain`** runs the suite on the real gating toolchain (Elixir 1.18.4 / OTP 27, capped
  2 vCPU / 4 GB to match the runner). Local is 1.19.5 / OTP 28, and it produced changes that were
  green locally and broke **every** gating lane twice — once on a 1.19-only `Process.set_label`
  dependency. Use the toolchain for any claim about gating-leg behaviour.
- **ExUnit 1.18 prints its count line inclusive of exclusions** (1573 = 1559 + 14). 1.18 and 1.19
  count lines are not directly comparable; reconcile via the unambiguous `total:/excluded:/executed:`
  line.
- **Reset the DB before every measurement:**
  `MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`.
  The `-r Mailglass.TestRepo` is required or it silently no-ops. Suite runs on the mailglass axis
  corrupt the DB for later runs; a stale DB produces phantom failures.
- **CI runs dialyzer as `MIX_ENV=test mix dialyzer`.** A bare `mix dialyzer` runs in `:dev`, where
  `elixirc_paths` excludes `test/support` entirely and misses these errors.
- **`.dialyzer_ignore.exs` is at its hard cap of 15 entries (D-08-07).** Fix contracts; do not add
  entries.
- **Seeds matter.** Several defects here were ordering- or load-dependent and invisible at a lucky
  seed. Verify at multiple seeds, and prefer the seed from a failing CI run.

---

## 7. Guards now in place (each mutation-proven)

Custom Credo checks fail the build on the re-typed idiom: `NoRawSandboxOwnership`,
`NoRawSearchPathMutation`, `NoRawAppEnvRestore`. Sanctioned seams in
`Mailglass.TestSupport.SandboxOwnership`: `checkout!/1`, `with_schema!/2`, `with_search_path!/3`,
`with_app_env!/2`, plus a scratch-schema guard that raises rather than dropping the live schema.
Anti-vacuity floors pinned **from green CI evidence only** (D-27): `public: 1576`, `mailglass: 1575`,
`skipped_ceiling: 7`.

The governing rule behind all of it, worth keeping: **a check that cannot observe its subject must
not report success — route "could not verify" to a visible failure, never to silence or green.** It
caught defects in the leak probe, the baseline verifier, the self-test probe, and the formatter —
every instrument in this phase had the disease it was built to detect.
