---
quick_id: 260916-g7k
slug: dispose-the-14-open-dependabot-prs
date: 2026-09-16
description: dispose the 14 open dependabot PRs
---

# Quick Task: dispose the 14 open dependabot PRs

## Finding that shaped the plan

The "14 open PRs" are **13 dependabot PRs + 1 release-please proposal (#222)**, not 14
dependabot PRs.

All 13 dependabot PRs are **single-lockfile** changes. Every `mix.exs` pin involved is
already a `~>` range that admits the proposed version, so nothing but `mix.lock` moves in
any of them. They collide on only three lockfiles:

| Lockfile | PRs |
|---|---|
| `mix.lock` | #246 mox, #244 swoosh, #243 phoenix, #240 oban |
| `mailglass_admin/mix.lock` | #255 ex_doc, #247 phoenix_live_view, #242 phoenix, #236 swoosh |
| `mailglass_inbound/mix.lock` | #256 ex_doc, #254 oban, #241 phoenix_live_view, #237 phoenix, #234 swoosh |

Merging them serially costs 13 dependabot rebases and 13 CI runs, because each merge
staleness-invalidates its siblings on the same lockfile. Two pairs are also mutually
superseding (#243/#242 want phoenix 1.8.13; #237 wants 1.8.14).

## Approach

One consolidated `chore(deps):` lockfile refresh across the three lockfiles, reaching a
version at-or-above every one of the 13 targets, then close the 13 as superseded. This is
the same shape as the phoenix-advisory disposal in #258.

`chore(deps):` does not trigger a release-please version bump, and `reference/host_app` +
`reference/demo_app` lockfiles are frozen deterministic baselines that must stay untouched.

## Tasks

1. Branch `chore/dependabot-lockfile-consolidation` off `origin/main`.
2. `mix deps.update` the targeted deps in each of the three packages.
3. Confirm only the three intended lockfiles moved; `reference/*` untouched.
4. Verify: `deps.get --check-locked`, `compile --warnings-as-errors`, and the full
   suite in all three packages. Any failure must be bisected against `origin/main`'s
   own lockfile before being attributed to the bump.
5. Push, open PR, land on green.
6. Close the 13 superseded dependabot PRs with a pointer to the consolidation PR.

## Out of scope

**#222 `chore: release main`** is the release-please proposal that would cut
`mailglass 2.6.0` / `mailglass_inbound 2.3.0` **to Hex**. It is not a dependabot PR, it is
genuinely red (Core Full Suite + CI Green failing), and merging it is an irreversible
outward-facing publish. Reported to the user for a separate decision, not touched here.

## Note on execution

Executed directly rather than via gsd-planner + gsd-executor: the task is a mechanical
repo-operations task that was already fully investigated before planning, and it requires
`gh` plus network judgement rather than code authoring. All GSD artifacts (PLAN, SUMMARY,
STATE table, atomic commit) are preserved.
