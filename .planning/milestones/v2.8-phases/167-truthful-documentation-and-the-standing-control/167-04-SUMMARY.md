---
phase: 167-truthful-documentation-and-the-standing-control
plan: 04
subsystem: docs-and-ci
tags: [state-md, gh-audit, dependabot, docs-contract-test, exunit, standing-control]

requires:
  - phase: 166
    provides: false-green fixes (GREEN-01..05, CTRL-01..05) this phase's docs corrections assume are true
provides:
  - "scripts/check_state_md_pr_refs.sh — three-way live audit (pass/blocked/cannot_check) of every #NNN reference in .planning/STATE.md against live gh state, human/workflow_dispatch-invokable only, not a registered scheduled control"
  - ".planning/STATE.md truthed up: PR #222 and #129 stated as closed (permanent fact), the two InboundLiveTest replay-copy reds stated as fixed by f733fc22/d65a1aa8, all open-PR/open-issue counts and identities delegated to gh pr list / gh issue list rather than snapshotted"
  - "test/mailglass/state_md_contract_test.exs — offline pin refusing the *shape* of a hardcoded open-count claim (\\d+ open PR/pull request/issue), wired into the required verify.support_contract.core lane"
  - ".github/dependabot.yml's three mix entries grouped (mix-minor-patch: minor+patch), capped at open-pull-requests-limit: 3, majors and security-updates left individually reviewable (STAND-01)"
affects: [167 phase close, future STATE.md corrections, Dependabot PR volume]

actuals:
  tokens: 5400
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Bash-only three-way live-state audit (pass/blocked/cannot_check, D-34 distinct exit codes 0/1/2), unregistered as a control, reusing dev/mix/tasks/mailglass.repo.hygiene.ex's check shape and aggregation precedence"
    - "Shape-level regex refute (\\b\\d+\\s+open\\s+(PR|pull request|issue)) rather than a literal-string refute, so the pin survives a rewrite of the specific number"
    - "Bounded-window (binary.match + radius) proximity check in ExUnit for self-correcting sentences ('PR #N as open (it is closed)'), avoiding both false negatives on real drift and false positives on a sentence that names both states to resolve them"
    - "Dependabot groups: with update-types restricted to minor+patch (omitting major) as the documented mechanism that leaves majors ungrouped, applied identically to all three mix entries"

key-files:
  created:
    - scripts/check_state_md_pr_refs.sh
    - test/mailglass/state_md_contract_test.exs
  modified:
    - .planning/STATE.md
    - mix.exs
    - .github/dependabot.yml

key-decisions:
  - "Fixed a self-inflicted false positive in check_state_md_pr_refs.sh mid-Task-2: the original open/closed classifier flagged any line containing the word 'open' near a #NNN reference as blocked, even when the same line also named the true state to correct it ('PR #222 as open (it is closed)'). Changed to: blocked only when a line asserts ONE state and gh reports the other; a line naming both is treated as self-correcting, not contradictory. Committed separately as a Rule-1 bug fix rather than folded into the Task 1 commit, since it was discovered while executing Task 2."
  - "STATE.md's pre-existing 'WIP limit 1 open PR' policy phrasing was reworded to 'at most one PR open at a time' — it is a policy constraint, not a stale snapshot, but it structurally matched Task 2's own shape-level regex pin (\\d+ open PR) and would have permanently blocked that test from ever passing."
  - "Did not hardcode PR #280 (the currently-open release-please proposal at execution time) anywhere in STATE.md, per the plan's explicit prohibition — Operator Next Steps now tells the reader to check `gh pr list --state open` for whatever proposal is currently open rather than naming one that will go stale within days."
  - "COVERAGE.md was already created and committed at phase-plan time (978c80e9) with the exact required content; Task 3 verified it rather than recreating it."

requirements-completed: [DOCS-01, STAND-01]

coverage:
  - id: T1
    description: "scripts/check_state_md_pr_refs.sh gives a three-way live verdict on every #NNN reference in STATE.md, all three exit paths observed"
    requirement: DOCS-01
    verification:
      - kind: manual
        ref: "bash scripts/check_state_md_pr_refs.sh (pass, exit 0 against real STATE.md); fixture asserting a closed PR as open (blocked, exit 1); same fixture with gh removed from PATH (cannot_check, exit 2)"
        status: pass
    human_judgment: false
  - id: T2
    description: "STATE.md states only permanent facts and delegates ongoing state; the defect shape is pinned offline in the required core lane"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/mailglass/state_md_contract_test.exs (5 tests) via mix verify.support_contract.core"
        status: pass
    human_judgment: false
  - id: T3
    description: "The three mix Dependabot entries are grouped, capped, and weekly; majors and security advisories stay individually reviewable"
    requirement: STAND-01
    verification:
      - kind: manual
        ref: "python3 yaml structural assertion against .github/dependabot.yml; grep counts for open-pull-requests-limit, mix-minor-patch, major (0), security-updates (0)"
        status: pass
    human_judgment: false
    notes: "Full behavioral acceptance (<=1 grouped PR per lock directory over a real weekly window, CI green with no hand edits) is post-merge evidence, same shape as Phase 166's CTRL-0x items — not observable from inside this repo."

duration: 12min
completed: 2026-09-18
status: complete
---

# Phase 167 Plan 04: Truthful STATE.md and the Dependabot Standing Control Summary

**Truthed up `.planning/STATE.md` (PR #222/#129 permanently closed, InboundLiveTest reds fixed, all open-PR/issue counts delegated to live `gh` state rather than snapshotted), pinned the *shape* of the defect offline in the required test lane, added a three-way live audit script for the ongoing claim class, and grouped/capped the three `mix` Dependabot entries so the 13-PR pileup class of 2026-09-16 can't recur.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-09-18
- **Tasks:** 3
- **Files created:** 2 (`scripts/check_state_md_pr_refs.sh`, `test/mailglass/state_md_contract_test.exs`)
- **Files modified:** 3 (`.planning/STATE.md`, `mix.exs`, `.github/dependabot.yml`)

## Accomplishments

- **Task 1:** Built `scripts/check_state_md_pr_refs.sh` — extracts every `#NNN` reference from a target file (URL-embedded refs excluded, first-appearance order preserved, deduplicated), resolves each against live `gh pr view`/`gh issue view`, and classifies pass/blocked/cannot_check per D-34 (exit 0/1/2). Human/`workflow_dispatch`-invokable only, deliberately not registered as a scheduled control — the phase's one permitted new control is STAND-01's Dependabot grouping, not this. All three exit paths observed directly (real STATE.md, a synthetic blocked fixture, the same fixture with `gh` unreachable), plus the empty-input, ordering, and URL-exclusion contracts.
- **Task 2:** Corrected `.planning/STATE.md`'s three false claims (PR #222 described as open — it's closed; PR #260 described as open — it's merged; two `InboundLiveTest` reds described as undiagnosed — fixed by `f733fc22`/`d65a1aa8`) and delegated all ongoing state (open-PR count, current release-please proposal identity) to `gh pr list --state open` / `gh issue list --state open` rather than re-snapshotting it. Pinned with a new offline `test/mailglass/state_md_contract_test.exs` (5 tests, no network call) wired into the required `verify.support_contract.core` lane, with the load-bearing assertion refusing the *shape* `\d+ open (PR|pull request|issue)` rather than the literal `14 open PR` string. Observed the mutation RED (`There are 9 open PRs.` inserted, test failed, reverted, test passed again) before considering the pin done.
- **Task 3:** Added `open-pull-requests-limit: 3` and a `mix-minor-patch` group (`update-types: minor, patch`) to each of the three `mix` Dependabot entries, leaving majors ungrouped (by omission, the documented mechanism) and `security-updates` out of every group (advisory bumps stay individually visible). The `github-actions` and two `docker` entries are byte-for-byte untouched, and no `mix` entry was added for `reference/host_app`/`reference/demo_app`. `COVERAGE.md` was already present from plan-authoring time and verified rather than recreated.

## Task Commits

1. **Task 1: scripts/check_state_md_pr_refs.sh** — `85c74899` (feat)
2. **Rule-1 deviation: fix self-correcting-line false positive** — `8ebb4200` (fix)
3. **Task 2a: truth up STATE.md's permanent facts** — `bdafaf18` (docs(state))
4. **Task 2b: name PR #129 as closed (test-driven correction)** — `7280b679` (docs(state))
5. **Task 2c: offline contract test + mix.exs alias wiring** — `d2a374a3` (test(167-04))
6. **Task 3: group/cap the three mix Dependabot entries** — `59ac8866` (feat)

## Files Created/Modified

- `scripts/check_state_md_pr_refs.sh` — new executable, `--target PATH` / `--format text|json`, exit codes 0/1/2
- `test/mailglass/state_md_contract_test.exs` — new `Mailglass.StateMdContractTest`, 5 tests
- `.planning/STATE.md` — permanent facts stated, ongoing state delegated, defect shape eliminated (including the pre-existing "WIP limit 1 open PR" phrasing, reworded to avoid the same shape)
- `mix.exs` — `verify.support_contract.core` alias extended with the new test file (no existing entry removed)
- `.github/dependabot.yml` — three `mix` entries gain `open-pull-requests-limit: 3` + `mix-minor-patch` group; `github-actions`/`docker` entries untouched

## Decisions Made

- The audit script's open/closed classifier was corrected mid-execution to treat a line naming both "open" and "closed"/"merged" as self-correcting rather than contradictory — otherwise Task 2's own truthful correction sentences ("PR #222 as open (it is closed)") would permanently trip the script as blocked.
- STATE.md's existing "WIP limit 1 open PR" policy phrase was reworded to "at most one PR open at a time" so it doesn't collide with the new shape-level regex pin, which can't distinguish a policy constraint from a stale count by wording alone.
- No currently-open PR number (e.g. #280, the release-please proposal open at execution time) is named anywhere in STATE.md — Operator Next Steps points at `gh pr list --state open` instead, per the plan's explicit prohibition.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] check_state_md_pr_refs.sh false-positived on its own target self-correcting sentence**
- **Found during:** Task 2, while re-running the script against the corrected STATE.md
- **Issue:** The script's per-reference classifier checked only whether the word "open" appeared anywhere on the line naming a `#NNN` reference; a line like "PR #222 as open (it is closed)" — which truthfully states both the old and new fact to correct itself — tripped it as `blocked`.
- **Fix:** Reworked the classifier so a line naming both "open" and "closed"/"merged" is treated as consistent (self-correcting), not contradictory; only a line asserting exactly one state, when `gh` reports the other, is now flagged.
- **Files modified:** `scripts/check_state_md_pr_refs.sh`
- **Verification:** Re-ran all of Task 1's exit-path proofs (pass/blocked/cannot-check fixtures, empty input, ordering, URL exclusion) after the fix — all still hold.
- **Committed in:** `8ebb4200`

**2. [Rule 1 - Bug] Test 5's `#129` assertion had nothing to match after the Operator Next Steps rewrite**
- **Found during:** Task 2, first test run (2 failures)
- **Issue:** Rewriting the stale `## Operator Next Steps` section removed the only `#129` mention in the file (previously speculative: "Likely coupled to the unmerged PR #129 replay-copy redesign") without replacing it with a positive closed-statement, so the new test's `#129 ... closed` assertion had no match. A second, related issue: the initial `#222`-proximity regexes in the test used a `[^\n]*` line-bound that failed to see "closed" when Markdown line-wrapping split a sentence across two physical lines inside a blockquote.
- **Fix:** Added an explicit "PR #129 ... is also closed" sentence to the maintainer note; reworked the test's proximity checks to operate on a whitespace-flattened copy of the file (`String.replace(state_md, ~r/\s+/, " ")`) with a byte-offset window helper, immune to Markdown line-wrap position.
- **Files modified:** `.planning/STATE.md`, `test/mailglass/state_md_contract_test.exs`
- **Verification:** `mix test test/mailglass/state_md_contract_test.exs --warnings-as-errors` — 5/5 passing.
- **Committed in:** `7280b679`, `d2a374a3`

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs, both self-tripped by the plan's own new artifacts and caught before the final commit)
**Impact on plan:** No scope creep. Both fixes are exactly the pinning/audit mechanism working as designed — the new tooling caught its own edge cases during first real use.

## Verification Performed

- `mix verify.support_contract.core` — 119 tests, 0 failures, 1 skipped (pre-existing, unrelated).
- `bash scripts/check_state_md_pr_refs.sh` — exit 0, 7/7 checks pass against the corrected `.planning/STATE.md`.
- `python3 -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"` — parses; structural assertion (3 mix entries, each with `open-pull-requests-limit: 3` and the exact `mix-minor-patch` group shape; no non-mix entry touched) passes.
- `git status --porcelain .github/workflows/ .github/scheduled-controls.json` — empty; no workflow or control registered.
- `git diff --name-only lib/` — empty; no product code touched.
- CI-lane reachability confirmed by reading `.github/workflows/ci.yml`'s `Detect Non-Doc Changes` job: `mix.exs`, `test/`, and `scripts/` are outside `.planning/` and `prompts/`, so the PR classifies `code=true` and the new test runs in the required matrix.

## Known Stubs

None.

## Next Phase Readiness

- All four of Phase 167's plans (01–04) are now complete and committed.
- No blockers. STAND-01's full behavioral acceptance (a real weekly Dependabot window producing ≤1 grouped PR per lock directory) is filed as post-merge evidence, not claimed as verified here — same treatment as Phase 166's CTRL-0x items.

---
*Phase: 167-truthful-documentation-and-the-standing-control*
*Completed: 2026-09-18*

## Self-Check: PASSED

All modified/created files (`scripts/check_state_md_pr_refs.sh`, `test/mailglass/state_md_contract_test.exs`,
`.planning/STATE.md`, `mix.exs`, `.github/dependabot.yml`) confirmed present on disk. All six task
commit hashes (`85c74899`, `8ebb4200`, `bdafaf18`, `7280b679`, `d2a374a3`, `59ac8866`) confirmed
present in `git log --oneline --all`.
