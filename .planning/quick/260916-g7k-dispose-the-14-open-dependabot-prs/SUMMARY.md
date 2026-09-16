---
quick_id: 260916-g7k
slug: dispose-the-14-open-dependabot-prs
status: complete
date: 2026-09-16
commits:
  - 753a840c
prs:
  merged: [260]
  closed_superseded: [234, 236, 237, 240, 241, 242, 243, 244, 246, 247, 254, 255, 256]
  left_open: [222]
---

# Summary: dispose the 14 open dependabot PRs

**Outcome: open PRs 15 → 1.** All 13 dependabot PRs disposed. The one remaining PR is
#222, deliberately untouched (see Deliberately out of scope).

## What the task turned out to be

"The 14 open dependabot PRs" was **13 dependabot PRs + the release-please proposal #222**.
The 13 were all single-lockfile changes: every `mix.exs` pin involved was already a `~>`
range admitting the proposed version, so nothing but `mix.lock` moved in any of them. They
collided on only three lockfiles (root ×4, admin ×4, inbound ×5), and two pairs were
mutually superseding — #243/#242 wanted phoenix 1.8.13 while #237 wanted 1.8.14.

Merging serially would have meant 13 dependabot rebases and 13 full CI runs, each merge
staleness-invalidating its siblings on the same lockfile.

## What was done

One consolidated `chore(deps):` refresh of the three lockfiles to a version at or above
every one of the 13 targets — the same disposal shape as #258.

| Lockfile | Bumps | Supersedes |
|---|---|---|
| `mix.lock` | mox 1.3.2, swoosh 1.28.0, phoenix 1.8.14, oban 2.24.1 | #246 #244 #243 #240 |
| `mailglass_admin/mix.lock` | ex_doc 0.40.4, phoenix_live_view 1.2.12, phoenix 1.8.14, swoosh 1.28.0 | #255 #247 #242 #236 |
| `mailglass_inbound/mix.lock` | ex_doc 0.40.4, oban 2.24.1, phoenix_live_view 1.2.12, phoenix 1.8.14, swoosh 1.28.0 | #256 #254 #241 #237 #234 |

Landed as PR #260 → `753a840c` on protected `main`, auto-merge on green (32 checks, 0
failures). The 13 were then closed with a pointer to #260 and their branches deleted.

`reference/host_app` and `reference/demo_app` lockfiles are frozen deterministic baselines
and were deliberately left untouched.

## Findings worth keeping

**The cowlib transitive bump is advisory-neutral, not a regression.** Transitive drift
pulled cowboy 2.19.0 → 2.20.0 and cowlib 2.19.0 → 2.20.0, and `mix` loudly flags 2.20.0
as VULNERABLE with `EEF-CVE-2026-43966` / `-43969` / `-43971`. Those are exactly the three
entries already registered in `Mailglass.SupplyChain.AcceptedAdvisories`, and 2.19.0
carries them too — there is no upstream fix. The loud warning is not evidence of a new
problem; it must be checked against the allowlist rather than reacted to.

**Two pre-existing reds on `main` in `MailglassAdmin.InboundLiveTest`.** Both assert the
flash copy `"Replay recorded. A new replay run was appended to this InboundMessage's
timeline."` — at `inbound_live_test.exs:913` and `:1411`. They were bisected by checking
out `origin/main`'s own `mailglass_admin/mix.lock`, refetching, and re-running: identical
two failures. So they are **not** caused by the LiveView 1.2.9 → 1.2.12 bump. Not
diagnosed further. PR #129 (open, unmerged) is the replay-copy redesign, which makes a
test-written-against-#129-copy-vs-main-renders-old-string mismatch the likely story.

**A local-only stale-deps failure masqueraded as a regression.** `Mailglass.DemoDataTest`
failed with `phoenix ... lock mismatch` because #258 had bumped `reference/demo_app`'s lock
without the local `deps/` ever being refetched. Fixed with `mix deps.get` in that directory
— and per the known drift gotcha, `reference/demo_app/mix.lock` was `git checkout`'d
immediately afterwards, since any mix run there re-bumps swoosh away from the pinned
baseline.

## Verification

| Package | Result |
|---|---|
| Core | 23 properties, 2120 tests, 0 failures |
| `mailglass_inbound` (`--seed 0`) | 3 properties, 460 tests, 0 failures |
| `mailglass_admin` | 509 tests, 2 failures — both pre-existing on `main` |
| All three | compile `--warnings-as-errors` clean; `deps.get --check-locked` resolves |
| CI on #260 | 32 checks, 0 failures |

## Deliberately out of scope

**#222 `chore: release main`** — the release-please proposal that would cut
`mailglass 2.6.0` / `mailglass_inbound 2.3.0` **to Hex**. Not a dependabot PR; genuinely
red (Core Full Suite + CI Green failing) and `BEHIND`. Merging it is an irreversible
outward-facing publish, so it was left for a maintainer decision rather than disposed here.

**This does not fully clear the scheduled controls.** `repo-hygiene` blocks on any open PR,
and both `post-publish-smoke` and `release-please` block specifically on #222. A green
scheduled signal requires resolving #222 — either rebase-and-release, or close it and let
release-please regenerate the proposal.

## Note on execution

Executed directly rather than via gsd-planner + gsd-executor. The task was mechanical
repo operations, fully investigated before planning, and needed `gh` plus network judgement
rather than code authoring. All GSD artifacts are preserved: PLAN.md, this SUMMARY.md, the
STATE.md quick-task table, and an atomic commit.
