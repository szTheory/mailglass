---
phase: 142-supply-chain-remediation-gating
plan: 02
subsystem: infra
tags: [dependabot, github-actions, gh-cli, branch-protection, hex, supply-chain]

# Dependency graph
requires:
  - phase: 142-01
    provides: accepted-advisories allowlist + mailglass.audit CI-side wiring (VULN-05), landed before this plan's gate promotion so the dependency backlog dispositioned here doesn't red-block on already-accepted cowlib advisories
provides:
  - "All 13 named dependabot PRs individually dispositioned (12 merged, 1 closed with a recorded conflict reason) via one-at-a-time `gh pr update-branch` + poll-to-green, never a blanket loop"
  - "Live re-query proof: zero `app/dependabot`-authored open PRs carry a non-null `autoMergeRequest`"
  - "Maintainer PR #132 confirmed out-of-scope and left untouched"
affects: [143-test-harness-truth, 144-signal-drift-integrity]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Serial per-PR gh pr update-branch -> poll required checks (CI Green, Guard Release Trigger) -> confirm merge, repeated one PR at a time because branch protection strict:true re-stales every remaining PR after each merge"]

key-files:
  created:
    - .planning/phases/142-supply-chain-remediation-gating/142-02-SUMMARY.md
  modified: []

key-decisions:
  - "Maintainer overrode the planning-time 'close as superseded' lean on #114 (mailglass_admin credo bump): merge it, because #78 (already-merged root credo bump) touched only the root mix.lock — mailglass_admin's own mix.lock was still pinned at credo 1.7.18, making #114 a genuine outstanding bump on an independent lockfile, not a duplicate."
  - "#96 (igniter 0.8.1 -> 0.8.2) dispositioned as close-with-reason rather than rebase: mergeable: CONFLICTING / mergeStateStatus: DIRTY is a real 3-way lockfile conflict (transitive lines for ex_ast, hpax, finch, mint, plug, req moved independently on main since the branch was cut 2026-06-28), not a stale-base case — hand-resolving a lockfile conflict was explicitly declined in favor of letting Dependabot re-file cleanly."
  - "#115 and #125 (both phoenix_live_view -> 1.2.8) dispositioned independently, each on its own sibling-directory lockfile (mailglass_inbound vs mailglass_admin) — not collapsed into one action, matching the plan's must_haves 'adjacency' edge case."
  - "#132 (maintainer PR, docs guides) confirmed adjacent-but-out-of-scope: flagged, not dispositioned as a dependency PR."

requirements-completed: [VULN-02]

coverage:
  - id: D1
    description: "12 dependabot PRs (#131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #95) merged individually, each via update-branch + poll-to-green on the 2 required status checks (CI Green, Guard Release Trigger)"
    requirement: VULN-02
    verification:
      - kind: manual_procedural
        ref: "gh pr view <N> --repo szTheory/mailglass --json state,mergedAt for each of the 12 PR numbers — all confirmed state: MERGED with a non-null mergedAt"
        status: pass
    human_judgment: false
  - id: D2
    description: "PR #96 (igniter bump) closed with a specific, recorded reason naming the genuine lockfile merge conflict (not rebased, not force-pushed)"
    requirement: VULN-02
    verification:
      - kind: manual_procedural
        ref: "gh pr view 96 --json state,comments — state: CLOSED, mergedAt: null, comment body names the exact transitive deps and CONFLICTING/DIRTY status"
        status: pass
    human_judgment: false
  - id: D3
    description: "Live re-query confirms zero indeterminate auto-merge-armed dependabot PRs remain"
    requirement: VULN-02
    verification:
      - kind: manual_procedural
        ref: "gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest --jq '[.[] | select(.author.login == \"dependabot[bot]\" or .author.login == \"app/dependabot\") | select(.autoMergeRequest != null)] | length' -> 0"
        status: pass
    human_judgment: false

# Metrics
duration: ~40min (this continuation; excludes prior-session maintainer review time before the checkpoint was resolved)
completed: 2026-07-29
status: complete
---

# Phase 142 Plan 02: Dependabot Backlog Disposition Summary

**All 13 named dependabot PRs individually dispositioned via serial `gh pr update-branch` + poll-to-green (12 merged, 1 closed with a recorded lockfile-conflict reason), live-verified zero indeterminate auto-merge-armed dependabot PRs remain, and maintainer PR #132 confirmed out of VULN-02 scope.**

## Performance

- **Duration:** ~40 min (this continuation, after the Task 1 checkpoint was resolved by the maintainer)
- **Completed:** 2026-07-29T03:53:04Z
- **Tasks:** 2 (Task 1 checkpoint resolution consumed; Task 2 executed fully)
- **Files modified:** 0 repository files (this plan's artifact is GitHub PR state + this SUMMARY, per D-12/142-02-PLAN.md's "no new `.planning/` register" choice)

## Accomplishments

- Merged 12 dependabot PRs one at a time, each requiring its own `gh pr update-branch` because branch protection is `strict: true` — every merge re-stales all remaining PRs, so this was inherently serial. 8 of the 12 (`#131, #130, #125, #124, #116, #115, #114, #112`) had already been merged by the maintainer's own review pass before this continuation started; this continuation updated branches, polled required checks, and confirmed the merges of the remaining 4 (`#111, #108, #106, #95`) — `#106` in fact self-merged mid-poll (its auto-merge fired once its already-queued checks finished, right after `#111`'s branch update advanced `main` past it).
- Verified `#96` was already closed (by the maintainer, before this continuation) with a comment naming the exact genuine merge-conflict cause — no rebase or force-push was attempted, matching the maintainer's explicit instruction.
- Re-ran the Task 2 live re-query (`gh pr list ... | jq 'select(autoMergeRequest != null) | length'`) and confirmed it returns `0`.
- Confirmed `#132` (maintainer PR, docs guides) remains open, auto-merge-armed, `mergeStateStatus: UNKNOWN` at time of writing, and was not touched by this plan.

## Task Commits

This plan makes zero repository source-file commits — its entire deliverable is GitHub PR state (merges/closes) plus this SUMMARY.md. No `Task N:` code commits exist for this plan; only the final metadata commit (below) touches the repository.

## Files Created/Modified

- `.planning/phases/142-supply-chain-remediation-gating/142-02-SUMMARY.md` — this file (disposition table + coverage record)

## Disposition Table

All actions verified via `gh pr view <N> --repo szTheory/mailglass --json state,mergedAt,closedAt` after execution.

| PR | Title | Action | Reason |
|----|-------|--------|--------|
| #131 | `actions/checkout` 7.0.0 -> 7.0.1 | **MERGED** | Stale-base-only (`mergeable: MERGEABLE`, `mergeStateStatus: BEHIND`); SHA-pinned action bump, no conflict signal — updated branch, required checks (CI Green, Guard Release Trigger) passed, merged clean. |
| #130 | `actions/setup-node` 6.4.0 -> 7.0.0 | **MERGED** | Same stale-base-only pattern as #131; SHA-pinned action bump, clean merge after branch update. |
| #125 | `phoenix_live_view` 1.1.28 -> 1.2.8 (`mailglass_admin`) | **MERGED** | Stale-base-only. Dispositioned independently of #115 (same target version, different sibling directory/lockfile) per the plan's must_haves adjacency edge — each merges on its own merits, not collapsed as a duplicate pair. |
| #124 | `ecto` 3.14.0 -> 3.14.1 (root) | **MERGED** | Stale-base-only, patch-level root dependency bump, clean merge. |
| #116 | `ex_doc` 0.40.1 -> 0.40.3 (`mailglass_admin`) | **MERGED** | Stale-base-only, dev-dependency doc-tooling bump, clean merge. |
| #115 | `phoenix_live_view` 1.1.30 -> 1.2.8 (`mailglass_inbound`) | **MERGED** | Stale-base-only. Dispositioned independently of #125 — different sibling directory (`mailglass_inbound`) and independent lockfile, not a duplicate. |
| #114 | `credo` 1.7.18 -> 1.7.19 (`mailglass_admin`) | **MERGED** (maintainer override) | Planning-time lean was "close as superseded by already-merged #78." Maintainer overrode: verified #78 (merged 2026-06-18) bumped only the **root** `mix.lock`'s credo pin — `mailglass_admin`'s own `mix.lock` was still pinned at credo 1.7.18 (independent lockfile per Elixir umbrella-style sibling packages), so #114 is a genuine outstanding bump, not a duplicate. Merged clean. |
| #112 | `ex_doc` 0.40.1 -> 0.40.3 (`mailglass_inbound`) | **MERGED** | Stale-base-only, dev-dependency doc-tooling bump in the sibling package, clean merge. |
| #111 | `tailwind` 0.4.1 -> 0.5.1 (`mailglass_admin`) | **MERGED** | Stale-base-only at plan start (`BEHIND`). Updated branch twice (main advanced mid-poll when #106 self-merged); required checks (CI Green, Guard Release Trigger) passed on the second update; merged 2026-07-29T03:39:48Z. |
| #108 | `erlef/setup-beam` 1.24.0 -> 1.24.1 | **MERGED** | Confirmed the "genuinely wanted" case flagged in RESEARCH.md — the action is SHA-pinned in every workflow per CLAUDE.md's "all third-party GitHub Actions pinned to commit SHA" convention, and Dependabot version bumps on SHA-pinned actions are exactly the intended flow, not noise. Updated branch, required checks passed, merged 2026-07-29T03:46:04Z. |
| #106 | `oban` 2.22.1 -> 2.23.0 (`mailglass_inbound`) | **MERGED** | Stale-base-only (`mergeStateStatus: BLOCKED` while checks were mid-run at plan start). Self-merged via its own already-armed auto-merge once its queued checks completed and `main` reached the required commit — observed mid-poll at 2026-07-29T03:21:49Z while updating #111's branch. |
| #96 | `igniter` 0.8.1 -> 0.8.2 | **CLOSED** (not merged, not rebased) | The one PR with a **genuine merge conflict** (`mergeable: CONFLICTING`, `mergeStateStatus: DIRTY`), not merely a stale base — confirmed via `gh pr view`. Closed by the maintainer (before this continuation) with a comment naming the specific driving fact: the PR's 2026-06-28 `mix.lock` snapshot carries transitive dependency lines (`ex_ast`, `hpax`, `finch`, `mint`, `plug`, `req`) that have independently moved on `main` since the branch was cut, producing a real 3-way lockfile conflict. Auto-rebase is disabled (PR open >30 days). No rebase or force-push was attempted — per instruction, the maintainer explicitly chose close-with-reason over hand-resolving the lockfile. Dependabot will re-file cleanly against current `main` if the bump is still wanted. |
| #95 | `actions/cache` 5.0.5 -> 6.1.0 | **MERGED** | Stale-base-only at plan start; its `gh pr checks` history showed several old failing runs (Credo Strict, Hex Audit, Core Full Suite Advisory, Operator Browser Gate, Demo Browser Evidence) but those were runs against a commit from ~5 weeks prior main history (job-run numbers ~29063748xxx vs. current ~304192xxxxx) — a fresh `update-branch` produced a current run against today's `main`, which passed both required checks. Merged 2026-07-29T03:52:10Z. |

**#132 note (out of scope):** `docs: add architecture and code walkthrough guides` — author `szTheory` (maintainer, not `app/dependabot`), auto-merge armed, `mergeStateStatus` currently `UNKNOWN`/`BEHIND` (flapping between polls). This is **not a dependency PR** and was explicitly left untouched per the plan's must_haves ("Maintainer PR #132 ... is flagged as adjacent-but-out-of-scope ... and is NOT dispositioned as part of this plan"). State recorded here only, no action taken.

## Task 2 Live Re-Query Result

```
gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest \
  --jq '[.[] | select(.author.login == "dependabot[bot]" or .author.login == "app/dependabot") | select(.autoMergeRequest != null)] | length'
```

**Result: `0`** — zero open `app/dependabot`-authored PRs carry a non-null `autoMergeRequest`. The only remaining open PRs after this plan are `#132` (maintainer, flagged above), `#129` (maintainer feature PR, `autoMergeRequest: null`), and `#104` (maintainer PR, `autoMergeRequest: null`) — none authored by dependabot.

## Decisions Made

- **#114 merge override:** see `key-decisions` in frontmatter — independent-lockfile fact, not a generic "cleanup" call.
- **#96 close-not-rebase:** see `key-decisions` in frontmatter — genuine 3-way lockfile conflict on transitive deps, auto-rebase disabled by GitHub after 30 days open.
- **#115/#125 independence:** dispositioned as two separate merges on two separate sibling lockfiles, per the plan's explicit "adjacency" must-have.
- **#132 non-disposition:** confirmed out of VULN-02 scope (not a dependency PR) and left alone.

## Deviations from Plan

None — plan executed exactly as the maintainer's checkpoint resolution specified. One operational note (not a deviation from the *decision*, but from the *expected sequencing*): `#106` merged itself mid-poll via its own already-armed auto-merge, ahead of the planned strict one-at-a-time cadence, because its required checks had already queued and completed by the time `main` advanced past it during `#111`'s branch update. This did not violate the "individually decided, individually recorded" prohibition (VULN-02) — `#106`'s merge disposition had already been individually authorized by the maintainer in the checkpoint resolution; only the exact merge timing was auto-merge's own doing, not a blanket agent action.

## Issues Encountered

- `mergeStateStatus` for a PR whose branch was just updated took multiple polling cycles (BLOCKED -> UNKNOWN -> BEHIND -> BLOCKED -> MERGED) to settle, and in one case (`#111`) required a second `gh pr update-branch` call because `main` advanced (via `#106`'s self-merge) between the first update and the poll completing. Resolved by re-checking `gh api .../compare/main...<head-branch>` for `ahead_by`/`behind_by` before each subsequent action, and re-running `update-branch` until the branch was current.
- `#95`'s `gh pr checks` output initially showed several `fail` entries from a stale historical run (~5 weeks old, before several intervening `main` changes). This was not treated as a real blocker — a fresh `update-branch` triggered a current CI run against today's `main`, which passed cleanly. Confirmed via job-run-ID recency rather than assuming the stale failures were current.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- VULN-02 is fully satisfied: zero indeterminate dependabot PRs remain, each of the 13 named PRs has an individually recorded disposition and reason.
- `142-VALIDATION.md`'s "All 13 dependabot PRs dispositioned individually with a recorded reason" manual-only verification row is satisfied by this SUMMARY's disposition table.
- Phase 142's remaining plans (03/04/05, per the phase's 5-plan structure) are unaffected by this plan's scope — this plan touched zero repository source files and ran in parallel (Wave 1) with 142-01.

---
*Phase: 142-supply-chain-remediation-gating*
*Completed: 2026-07-29*
