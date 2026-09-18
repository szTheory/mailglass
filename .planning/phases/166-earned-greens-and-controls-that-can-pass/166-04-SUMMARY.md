---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 04
subsystem: infra
tags: [github-actions, release-please, rate-limiting, ci]

# Dependency graph
requires:
  - phase: 166-03
    provides: "CTRL-04 permanent-refusal advisory framing (no code coupling, sequencing only)"
provides:
  - "release-please.yml with the already-tagged-SHA push skip reachable again (CTRL-02 code change)"
  - "Bounded classify-and-retry (403/429 + secondary-rate body match, 60/120/240s, 3 attempts) around both proposal-path gh api calls and one guarded re-run of the release-please action step (CTRL-03 code change)"
  - "An explicit, checklist-shaped pending-evidence record for the post-merge observations CTRL-02/CTRL-03 acceptance requires"
affects: [166-05, 166-06, phase-167-merges, release-please-workflow]

actuals:
  tokens: 14000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Classify-then-gate extended: retry loop reuses the existing cannot-check/github_evidence_unavailable classification on terminal failure rather than inventing a new status"
    - "continue-on-error used only to route a step's failure into classification, paired with exactly one guarded backoff re-run — never a blind retry"

key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - test/scripts/release_policy_contract_test.exs
    - test/scripts/release_trigger_recovery_test.exs
    - .planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md

key-decisions:
  - "D-20's line citations (:119/:179) are stale against the current file; the semantic clause — 'the gh api calls that already classify to cannot-check' — was treated as authoritative. Verified independently: the only calls classifying to cannot-check/github_evidence_unavailable are the gh pr list calls at lines 572 and 684, both wrapped. The gh api call at line 113 is a preflight tag lookup (Task 1's territory) and the one at line 173 is a workflow_dispatch-gated permission check — neither classifies to cannot-check. The gh pr list at line 220 sits inside a different step ('Validate protected exact candidate dispatch'), hard-exits instead of classifying, and is a different security surface — correctly left unwrapped. This is a durable finding: the plan's line numbers should not be trusted for this file without re-grepping."
  - "Task 3 (post-merge evidence) is carried as explicitly pending, not asserted passing. Maintainer directive: do not dispatch, re-run, or otherwise manufacture the three-push observation; per D-37, plans 166-05/166-06 and the Phase 167 merges are expected to supply them naturally as the milestone continues."
  - "Self-caught bug during Task 2 (Rule 1): `if CMD; then ...; fi` reports exit 0 regardless of CMD's own exit status, so reading $? after the fi block does not capture CMD's failure. Fixed with `CMD || call_status=$?` at both retry call sites (lines 550, 659) before the fix was committed — caught by release_trigger_recovery_test.exs flipping pass to fail on the naive version."

patterns-established:
  - "Bash retry-with-classification: HTTP status in {403,429} AND case-insensitive secondary-rate-phrase body match is the retry trigger; status-only or header-only conditions do not qualify. Sleep precedence: retry-after header, else x-ratelimit-reset - now + 1 only when x-ratelimit-remaining is 0, else 60s; every wait floored at 60s and doubled per consecutive secondary failure; hard bound of 3 attempts."

requirements-completed: []  # CTRL-02/CTRL-03 code changes are implemented but NOT marked complete — their acceptance criteria are post-merge observations not yet available. See "Requirement Status" below.

coverage:
  - id: D1
    description: "CTRL-02: the early-return block that makes the tagged-SHA push skip unreachable is deleted; the downstream autorelease:-tagged label check and expected_tags_text branch are reachable again on an ordinary push, with should_run set correctly and no new hard-fail exit reachable."
    requirement: "CTRL-02"
    verification:
      - kind: unit
        ref: "test/scripts/release_policy_contract_test.exs, test/scripts/release_trigger_recovery_test.exs, test/scripts/guard_release_trigger_test.exs, test/scripts/linked_release_concurrency_test.exs"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release-please.yml; python3 yaml.safe_load parse check"
        status: pass
    human_judgment: true
    rationale: "The code-level change is proven by the contract tests and by the Task 1 ordinary-push path trace (below), but CTRL-02's own acceptance criterion — 'the merge of a chore: release main PR produces a green release-please push run' — is a real post-merge observation that cannot be produced inside this execution. Task 3 (checkpoint) explicitly defers this to the maintainer/future merges."
  - id: D2
    description: "CTRL-03: both proposal-path gh api calls are wrapped in a bounded (3-attempt, 60/120/240s) classify-and-retry loop keyed on {403,429} plus a secondary-rate body match; the release-please action step gains continue-on-error plus exactly one guarded backoff re-run; the final gate expression and github_evidence_unavailable classification are unchanged."
    requirement: "CTRL-03"
    verification:
      - kind: unit
        ref: "mix test test/scripts/ test/mix/tasks/ (492 tests, 0 failures, 20 excluded — see Deferred Items note on the excluded flaky file)"
        status: pass
      - kind: other
        ref: "actionlint clean; RELEASE_STEP_GUARDED python3 check; grep -c 'secondary rate' > 0; grep -c 'github_evidence_unavailable' >= pre-change count; final gate expression diff-clean; no permissions: entry added; grep -c 'rate_limit' unchanged"
        status: pass
    human_judgment: true
    rationale: "The retry/classify code is proven correct by the acceptance-criteria checks above, but CTRL-03's own acceptance criterion — 'three consecutive pushes to main produce success, with push and schedule at the same SHA agreeing' — is an inherently post-merge, naturally-triggered observation. It cannot be manufactured by dispatch or rerun (explicitly prohibited), so it is recorded as pending evidence, not a pass."
  - id: D3
    description: "Post-merge evidence checklist for CTRL-02/CTRL-03 recorded as pending, with the exact verification steps needed to close it, so a later pass (166-05/166-06 or Phase 167 merges, per D-37) can complete it without re-deriving what to look for."
    verification: []
    human_judgment: true
    rationale: "By definition this deliverable is 'not yet observable' — there is no automated check that can assert future push evidence exists. Recorded in deferred-items.md and this SUMMARY for pickup at phase close-out."

duration: 6min
completed: 2026-09-18
status: complete
---

# Phase 166 Plan 04: CTRL-02/CTRL-03 (release-please rate limit) Summary

**Deleted the release-please early return so the already-tagged-SHA push skip is reachable again, and wrapped both proposal-path `gh api` calls plus the action step in a bounded 60/120/240s classify-and-retry loop — but the acceptance criteria for both requirements are inherently post-merge and remain explicitly pending, not verified, at the close of this plan.**

## Performance

- **Duration:** ~6 min across two prior-session tasks (this continuation session: SUMMARY/state-update only)
- **Tasks:** 2 of 3 completed (Task 3 is a `checkpoint:human-verify gate="blocking-human"` that cannot be satisfied pre-merge)
- **Files modified:** 4 (2 code/workflow, 2 test files touched in Task 1's read-first scope; see Task Commits)

## Accomplishments

- CTRL-02: deleted the early-return block guarded by the empty candidate-digest condition in the release-preflight step, making the already-written `expected_tags_text` proposal-mode branch and the downstream `autorelease: tagged` label check (the actual tagged-SHA skip) reachable on an ordinary push. Traced every path an ordinary push can now take: no candidate digest still reaches the merge-PR-number parse and label check, sets `should_run=false` correctly, and no new hard-fail exit became reachable.
- CTRL-03: wrapped both proposal-path `gh api` calls (the two that already classify to `cannot-check`) in a bounded retry loop — retry only on HTTP 403/429 AND a case-insensitive secondary-rate-phrase body match, sleep per the `retry-after` → `x-ratelimit-reset` → 60s-floor precedence, doubling per consecutive failure, capped at 3 attempts (60/120/240s). Added `continue-on-error: true` plus exactly one guarded backoff re-run to the `googleapis/release-please-action` step (the only unprotected API step in the path). Final gate expression left byte-for-byte unchanged; no `permissions:` entry touched.
- Self-caught and fixed a bash exit-status bug in the first draft of the retry wrapper (see Deviations).
- Confirmed via independent re-verification that D-20's stale line citations do not change which calls needed wrapping — the two `gh pr list` calls that actually classify to `cannot-check` (lines 572, 684) were the correct and only targets.

## Task Commits

1. **Task 1: CTRL-02 — delete the early return so the already-tagged-SHA skip becomes reachable** - `45391306` (feat)
2. **Task 2: CTRL-03 — bounded classify-and-retry for release-please GitHub API calls** - `a6e58817` (feat)
3. **Task 3: Post-merge evidence checkpoint** - NOT completed; see "Requirement Status" and "Task 3 — Pending Post-Merge Evidence" below.

**Plan metadata:** (this commit) `docs(166-04): complete CTRL-02/CTRL-03 plan with pending post-merge evidence`

## Files Created/Modified

- `.github/workflows/release-please.yml` — early-return deletion (CTRL-02); bounded classify-and-retry loop around both `gh api` calls plus `continue-on-error` + one guarded re-run on the release-please action step (CTRL-03)
- `test/scripts/release_policy_contract_test.exs` — exercised by Task 1's verification; no assertions needed to change
- `test/scripts/release_trigger_recovery_test.exs` — caught the Rule-1 exit-status bug in Task 2's first draft (pass → fail → pass)
- `.planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md` — Task 2's out-of-scope flaky-test note; this session adds the Task 3 pending-evidence checklist

## Decisions Made

- **D-20 line citations are stale; the semantic clause governs.** The plan cites `:119`/`:179` for the two `gh api` calls needing wrapping. Independently re-verified against the current file: the only calls that classify to `cannot-check`/`github_evidence_unavailable` are the `gh pr list` calls at lines 572 and 684 — exactly the two that were wrapped. The literal `gh api` sites are a preflight tag lookup (line 113, Task 1's territory, not a classify-to-cannot-check site) and a `workflow_dispatch`-gated permission check (line 173, same). A third `gh pr list` at line 220 lives inside "Validate protected exact candidate dispatch," hard-exits instead of classifying, and is a different security surface — correctly left unwrapped. **Maintainer confirmed this reading is correct; no rework performed.** Recorded here as a durable finding: line-number citations in this plan should not be trusted verbatim for this file without a fresh grep.
- **Task 3 carried as explicitly pending, not a pass.** Per maintainer directive: this SUMMARY records Tasks 1-2 as complete (code implemented, verified by the automated `<verify>` steps) and Task 3 as unfinished post-merge evidence. The plan and its requirements (CTRL-02, CTRL-03) are NOT marked verified/complete on the strength of Tasks 1-2 alone — their acceptance criteria are real post-merge observations (a green push run against an already-tagged SHA; three consecutive agreeing push/schedule runs) that cannot be produced or manufactured now. Per D-37, plan 166-05/166-06 and the Phase 167 merges are expected to supply the three push observations naturally as the milestone continues — each subsequent merge is itself one of the three.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bash exit-status swallowing in the retry wrapper's first draft**
- **Found during:** Task 2 (CTRL-03 retry loop implementation)
- **Issue:** `if CMD; then ...; fi` reports the `if`'s own exit status (0, since the `if` block itself succeeds), not `CMD`'s — so `$?` read after the `fi` does not capture `CMD`'s failure. The first draft treated every `gh` failure as a success, silently defeating the classify-on-failure path.
- **Fix:** Changed to `CMD || call_status=$?` at both retry call sites (lines 550 and 659 in the final file) to capture the real exit status.
- **Files modified:** `.github/workflows/release-please.yml`
- **Verification:** `test/scripts/release_trigger_recovery_test.exs` went pass → fail on the naive version, confirming the bug was real and test-detectable; fix restored green.
- **Committed in:** `a6e58817` (part of Task 2's single commit — fixed before commit, not a separate commit)

---

**Total deviations:** 1 auto-fixed (1 bug, self-caught during implementation before commit)
**Impact on plan:** Necessary correctness fix for the retry loop's core contract (classify on failure, never silently swallow it). No scope creep.

## Issues Encountered

- **Task 3 (checkpoint:human-verify, gate="blocking-human") cannot be satisfied inside this execution.** Its acceptance criteria — a green `release-please` push run at an already-tagged SHA, and three consecutive naturally-triggered pushes to `main` with `push`/`schedule` agreement — require a real `chore: release main` merge and real subsequent pushes. The plan itself forbids manufacturing these observations (no dispatch, no re-run), and the maintainer confirmed this should be carried as pending evidence rather than assumed or forced. See "Task 3 — Pending Post-Merge Evidence" below for the exact steps needed to close it.

## Requirement Status

**CTRL-02 and CTRL-03 are IMPLEMENTED but NOT verified-complete.** Their code changes pass every pre-merge automated check in the plan's `<verify>` blocks (actionlint, YAML parse, the four targeted `mix test` files, the full `test/scripts/ test/mix/tasks/` suite, and every `<acceptance_criteria>` grep/python check). Their formal acceptance criteria, however, are defined as post-merge observations (see plan lines 73-83 of `.planning/REQUIREMENTS.md`) that have not yet occurred:

- CTRL-02 accept: "the merge of a `chore: release main` PR produces a green `release-please` push run" — **not yet observed.**
- CTRL-03 accept: "three consecutive pushes to `main` produce `success`, and `push` and `schedule` at the same SHA agree" — **not yet observed.**

`.planning/REQUIREMENTS.md`'s traceability table for CTRL-02/CTRL-03 is updated in this commit to `Implemented, evidence pending` (not `Complete`) to reflect this honestly. The checkboxes at REQUIREMENTS.md lines 73/77 remain unchecked.

## Task 3 — Pending Post-Merge Evidence

Carried forward (per maintainer directive) as an explicit checklist for whichever future plan or close-out pass observes it. **Do not dispatch, re-run, or manufacture these — they must be naturally triggered.**

| # | Verification step | Status |
|---|---|---|
| 1 | Open the `release-please` workflow runs for the three most recent merges to `main`; confirm each concluded `success`. | Pending — 0 of 3 observed |
| 2 | For each of those SHAs, open both the `push` run and the `schedule` run and confirm they agree. | Pending |
| 3 | When the next `chore: release main` PR merges, open its `release-please` push run and confirm the tagged-SHA skip fired (CTRL-02's own acceptance) rather than the action re-running. | Pending — no such merge has occurred since this plan landed |
| 4 | Confirm no run reported a `cannot-check` outcome as `pass`. | Pending (structurally guaranteed by the unchanged final gate expression, but not yet observed in a real run) |

**Expected natural close-out path (D-37):** PR-5 (plans 166-05/166-06) and the Phase 167 merges are each themselves one of the required push observations — no dedicated action is expected to be needed to gather this evidence; it should accumulate as the milestone continues. This checklist is recorded in `deferred-items.md` for the same reason, so it is visible at phase close-out even if this SUMMARY scrolls out of context.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The CTRL-02/CTRL-03 code changes are merged to `main` and ready to start accumulating their own post-merge evidence via ordinary subsequent development (166-05, 166-06, Phase 167).
- **Blocker for phase close-out (not for continuing to 166-05):** CTRL-02 and CTRL-03 cannot be marked `Complete` in REQUIREMENTS.md until the Task 3 checklist above is satisfied. Whoever runs Phase 166's close-out audit must re-check this table before treating the phase as done.

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-18*

## Self-Check: PASSED
- FOUND: .github/workflows/release-please.yml (modified, tracked)
- FOUND: commit 45391306 (Task 1)
- FOUND: commit a6e58817 (Task 2)
- FOUND: .planning/phases/166-earned-greens-and-controls-that-can-pass/166-04-SUMMARY.md
