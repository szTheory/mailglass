---
artifact: main-green-evidence
phase: 143-test-harness-truth
created: 2026-07-31
---

# 143-MAIN-GREEN-EVIDENCE — post-merge `main` runs of `advisory-matrix.yml`

Ledger of `main` runs after Phase 143's work merged, kept because the promotion checkpoint
(`143-PROMOTION-CHECKPOINT.md`) is gated on `main` evidence that did not exist while the work sat on
a branch. Every row below is read from the GitHub API, not from a local run.

Background: before the merge, `main`'s Core Full Suite had been **red for 28 days** — 0 successes in
the last 40 `advisory-matrix.yml` runs, last green `28568190903` on 2026-07-02.

---

## The runs

| # | Run | Event | Head SHA | Created (UTC) | Conclusion |
|---|---|---|---|---|---|
| 1 | [`30595090072`](https://github.com/szTheory/mailglass/actions/runs/30595090072) | `push` | `d6e50388` | 2026-07-31T00:59:03Z | **success** |
| 2 | [`30607136165`](https://github.com/szTheory/mailglass/actions/runs/30607136165) | `schedule` | `d6e50388` | 2026-07-31T05:33:38Z | **success** |
| 3 | [`30635221221`](https://github.com/szTheory/mailglass/actions/runs/30635221221) | `push` | `981b9343` | 2026-07-31T13:4xZ | **success** |

`d6e50388` = PR #151 (the phase's own work). `981b9343` = PR #157 (probe fixes + evidence).

---

## All four matrix legs are green — HARNESS-02's bar, met on `main`

The Elixir 1.19 / OTP 28 legs carry `if: github.event_name != 'pull_request'`, so they **never ran
once** during this phase's branch life — plan 143-10 recorded that as an open `unrun-verify` in
`.planning/WINDOWS.md`, noting the floors were pinned from the 1.18 legs and enforced on 1.19 legs
nobody had measured.

They have now run, on both `main` SHAs, and passed:

| Leg | Run 2 (`schedule`) | Run 3 (`push`) |
|---|---|---|
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` | success | success |
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` | success | success |
| `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)` | success | success |
| `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema mailglass)` | success | success |
| `Inbound Full Suite Advisory (schema public)` | success | success |
| `Inbound Full Suite Advisory (schema mailglass)` | success | success |

**The floors were genuinely enforced on the previously-unmeasured leg**, not merely present. From run
3's `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)` log:

```
total: 1643, excluded: 13, skipped: 7, executed: 1623, failures: 0
signature tally: already_shared=0, formatter_violations=0
scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1576, skipped ceiling 7 enforced;
a violation halts this run.
```

`executed: 1623 >= floor 1576`, and the run declares that a violation would halt it. This closes the
`unrun-verify` window on schema-keyed floors being applied to unmeasured toolchain legs: they were
applied, and they held.

---

## What this does and does not settle for the promotion checkpoint

**Condition 2 (a green `schedule` run) — substance met.** Run 2 is a cron on a plain `main` SHA, cold
cache, no pull-request context, unattended, both gating legs green. First green cron since 2026-07-02.

**Condition 1 (three consecutive greens on three DISTINCT `main` SHAs) — NOT met: 2 of 3.** Three
green runs exist, but runs 1 and 2 share `d6e50388`. That is one SHA observed twice, not two of the
three. The condition asks for distinct SHAs deliberately — its stated purpose is that repeated greens
on a frozen tree demonstrate nothing about stability. `main` must advance once more.

Do not read "three green runs" in the table above as satisfying condition 1. It is three runs across
**two** SHAs.

---

## Operational note — the cron fires ~1h late, every day

`advisory-matrix.yml` declares `schedule: - cron: "21 4 * * *"`. Observed actual start times:

| Date | Declared | Actual |
|---|---|---|
| 2026-07-29 | 04:21 | 05:29 |
| 2026-07-30 | 04:21 | 05:20 |
| 2026-07-31 | 04:21 | 05:33 |

GitHub delays scheduled workflows under load and gives no guarantee of promptness. Budget for
~05:20–05:35 UTC. **A missing run at 04:30 is not a skipped schedule** — it has simply not fired yet.
