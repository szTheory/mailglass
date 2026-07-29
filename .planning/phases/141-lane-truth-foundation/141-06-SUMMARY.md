---
phase: 141-lane-truth-foundation
plan: 06
subsystem: infra
tags: [ci, github-actions, ex-unit, hex-publish, meta-test, docs]

# Dependency graph
requires:
  - phase: 141-04
    provides: "the four-bucket classification axis on Mailglass.CILanes (required/advisory-classified/publish-gating/structural, all_classified_lanes/0) and gate-ci-green's classify/1 rewrite"
  - phase: 141-05
    provides: "the hardened lane_classification_drift_test.exs (16 tests: set-equality, exact-count anti-vacuity, adjacency, matrix-safety, charset, order-independence) this plan extends to a third registry"
provides:
  - "MAINTAINING.md § \"Required Checks\" rewritten as one 24-row `job id | display name | classification | disposition | reason` disposition table — the durable, findable record TRUTH-05 requires, resolving D-15's three-list self-contradiction (a merge-gating bullet list, an exact-required-contexts list, and an advisory-signal list that all disagreed)"
  - "A rewritten branch-protection truth statement naming the exact two required contexts (CI Green, Guard Release Trigger) and the five ci_green.needs merge-gating leaves distinctly — closing the job-id-vs-display-name gap that opened this milestone"
  - "A prose note above the table carrying the two warnings a cell can't hold: the classification/parity axis split, and the never-promote-a-matrix-lane warning naming all three matrix lanes"
  - "parse_disposition_table/1 + trim_bt/1 in lane_classification_drift_test.exs binding the table to Mailglass.CILanes with 7 new tests: pair-set-equality, exact-count anti-vacuity, adjacency, closed-vocabulary disposition membership, no-pipe-in-cells, order-independence, negative control"
  - "Live-verified: 24 runtime ci.yml job names, matrix suffixes included, each prefix-match exactly one classification array; branch protection is exactly [\"CI Green\",\"Guard Release Trigger\"]; the v2.0/v2.1 phase archives are 48/39 files"
affects: [142-supply-chain-remediation, 143-test-harness-truth, 144-signal-drift-integrity]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Markdown-table parsing via section-bound-then-regex, mirroring the heredoc-bullet parser precedent in required_checks_test.exs: split on \"\\n## \", find the chunk, filter to `|`-prefixed lines, reject the separator/header rows, reject any row whose cell count isn't 7 so a stray `|` in free text drops that row loudly (via the paired exact-count assert) rather than silently"
    - "Three-way registry agreement: Mailglass.CILanes <-> publish-hex.yml's four JS arrays <-> MAINTAINING.md's disposition table, all bound by the same drift/2 two-direction set-difference helper"

key-files:
  created: []
  modified:
    - MAINTAINING.md
    - test/scripts/lane_classification_drift_test.exs

key-decisions:
  - "[141-06] The branch-protection truth statement was rewritten in place (not left as a separate bullet list) to name ci_green.needs' five members and the two real required contexts side-by-side — the exact confusion (a merge-gating leaf mistaken for a required context) that produced the milestone's originating incident."
  - "[141-06] `hex_audit` and `deps_audit_advisory` carry disposition `promote` with the qualifier moved into their `reason` cell (\"Phase 142/VULN-03 executes the promotion... not this phase\") rather than left bolded/parenthetical in the disposition cell itself — keeps the disposition column a closed three-word vocabulary the meta-test can assert against exactly, per D-07."
  - "[141-06] Task 1 (docs) and Task 2 (tests) were committed as two separate atomic commits on the same file pair, matching the 141-05 precedent, so each commit's diff maps 1:1 to its task."
  - "[141-06 / Rule 1 fix, applied by coordinator while this plan was paused at the Task 3 checkpoint, commit b787d9a0] Task 2's `length(rows) > 0` anti-vacuity assert is a Credo-flagged expensive-length-comparison pattern. Changed to `rows != []` with identical assertion semantics and message; the adjacent `length(rows) == 24` exact-count guard was left untouched (Credo only flags the zero-comparison form, not the exact-count form). This had redded `mix ci.fast`'s `credo_strict` lane — a phase whose entire point is that green must mean green, so a phase-141 commit cannot itself ship a red lint lane."
  - "[141-06 / Rule 1+2 fix, applied by coordinator while this plan was paused at the Task 3 checkpoint, commit 7a603e34] Task 1's rewrite dropped the only in-repo mentions of `Core Full Suite Advisory` and `Provider Compatibility Advisory`, which `test/mailglass/docs_contract_test.exs:304` pins as part of the required-vs-advisory contract (redding `Support Contract Core`). Restored as prose immediately above the pre-existing `Provider Live Advisory` sentence — deliberately NOT as table rows, since those lanes live in the separate `advisory-matrix.yml` workflow, not `ci.yml`, and adding them as rows would have broken the 24-row / 24-job / 24-classified triple-equality this plan's own anti-vacuity guards depend on. This was also a genuine TRUTH-05 completeness gap on its own terms (those lanes' disposition belongs recorded, not just ci.yml's), not merely a test-fix."
  - "[141-06] Task 3's checkpoint precondition (a CI run where code lanes execute, not a docs-only skip) could not be satisfied by this executor directly — pushing/merging was out of session scope. The coordinator pushed the branch (already merged as PR #143) and used `workflow_dispatch` (which hardcodes `changes.outputs.code=true`) to force a genuine code-lane run, since a plain push/merge to `main` had already happened without a matching non-doc-touching trigger."
  - "[141-06] Verification Group 5 (`mix ci` green locally) was NOT achieved in this sandbox: `mix ci` fails at an `Unchecked dependencies for environment dev` step even after `MIX_ENV=dev mix deps.get` succeeded, and separately requires network access (`preflight_network.sh`, `consumer_install_smoke.sh`) that this sandbox may not provide. Format, compile, and Credo (482 files, no issues) all clear before that failure — it is a local workspace/environment gap, not an assertion failure. The full remote CI run (30408642505, 24/24 jobs, only the pre-existing unrelated `Demo Browser Evidence` red) is recorded as the stronger substitute evidence per the coordinator's explicit instruction, and the working tree is confirmed clean (`git status --porcelain` empty)."

requirements-completed: [TRUTH-05]

coverage:
  - id: D1
    description: "MAINTAINING.md § \"Required Checks\" rewritten as one 24-row disposition table (job id | display name | classification | disposition | reason); the contradicting merge-gating bullet list and the unparenthesized advisory bullet list are both gone; branch-protection truth restated as exactly two contexts with the five ci_green.needs leaves named distinctly; a prose warning above the table covers the classification/parity axis split and the never-promote-a-matrix-lane rule"
    requirement: "TRUTH-05"
    verification:
      - kind: unit
        ref: "awk-based section-scoped acceptance checks (24 data rows, 1 separator, 0 `NF!=7` cell leaks, 0 'advisory signal' phrase, 0 'mix dialyzer' text, 22 keep-with-reason + 2 promote = 24, >=1 'Guard Release Trigger'/'ci_green.needs'/'matrix', 0 `### ` subsections, 0 non-ASCII in cols 2-5, 0 malformed id/name cells, >=1 'verify.stability_contract') — all run and recorded green in this session"
        status: pass
    human_judgment: false
  - id: D2
    description: "parse_disposition_table/1 + trim_bt/1 bind MAINTAINING.md's table to Mailglass.CILanes with 7 new tests (pair-set-equality, exact-count anti-vacuity, adjacency, closed-vocabulary disposition, no-pipe-in-cells, order-independence, negative control); three deliberate-drift probes run against the real file (classification-cell change, empty-disposition cell, row swap) and reverted"
    requirement: "TRUTH-05"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs — mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors (23 tests, 0 failures); MIX_ENV=test mix verify.ci_lane_contract (40 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "Probe A (classification cell publish-gating->advisory on format_check): pair-set test failed both directions naming the lane; reverted. Probe B (empty disposition cell on format_check): vocabulary test failed naming the row; reverted. Probe C (swapped format_check/compile_warnings row order): suite still passed 23/23; reverted."
        status: pass
    human_judgment: false
  - id: D3
    description: "Live GitHub verification — runtime ci.yml job names (with matrix suffixes) each prefix-match exactly one classification array; Credo Strict and Design System Conformance (shell gates) both green in the same run; branch protection returns exactly [\"CI Green\",\"Guard Release Trigger\"]; v2.0/v2.1 phase archives are exactly 48/39 files"
    requirement: "TRUTH-05"
    verification:
      - kind: other
        ref: "CI run 30408642505 (head SHA 7a603e34, event workflow_dispatch, forced code=true): gh api repos/szTheory/mailglass/actions/runs/30408642505/jobs --jq '.jobs[].name' returned 24 names, all matched by exact-equality-or-prefix rule against Mailglass.CILanes' four buckets; gh api repos/szTheory/mailglass/branches/main/protection/required_status_checks --jq '.contexts' returned exactly [\"CI Green\",\"Guard Release Trigger\"]; find .planning/milestones/v2.0-phases -type f | wc -l = 48, find .planning/milestones/v2.1-phases -type f | wc -l = 39"
        status: pass
    human_judgment: true
    rationale: "Task 3 is a checkpoint:human-verify with gate=\"blocking\" — the plan requires a human eye on 'assert by eye: every returned name prefix-matches exactly ONE entry... anything unmatched or double-matched is a defect.' The coordinator ran the live gh/api verification in this session and reported the pass results transcribed above; recording human_judgment: true preserves the audit trail that a human, not an automated script alone, confirmed the match rather than silently downgrading a live-API-dependent check to a self-certified pass."
  - id: D4
    description: "mix ci green locally (Verification Group 5, part of the plan's whole-phase gate)"
    requirement: "TRUTH-05"
    verification:
      - kind: other
        ref: "mix ci — fails at 'Unchecked dependencies for environment dev' after format/compile/credo (482 files, no issues) clear; likely also blocked on preflight_network.sh/consumer_install_smoke.sh needing network the sandbox may not provide"
        status: fail
    human_judgment: true
    rationale: "This is a documented local-sandbox environment gap, not an assertion or code failure — format, compile, and Credo all clear before the dependency-environment step fails. The working tree is confirmed clean (git status --porcelain empty), and the full remote CI run (D3, 24/24 jobs, only the pre-existing unrelated Demo Browser Evidence red) is the stronger substitute evidence per the coordinator's explicit instruction. Flagged for human awareness rather than silently marked pass."

# Metrics
duration: 55min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 06: MAINTAINING.md Disposition Table + Live Lane-Truth Verification Summary

**Rewrote `MAINTAINING.md` § "Required Checks" into one 24-row job-classification/disposition table bound to `Mailglass.CILanes` by a markdown-table parser, then closed Phase 141 with a live GitHub verification run (24/24 jobs, correct classification, correct branch protection, correct archive counts).**

## Performance

- **Duration:** ~55 min across two sessions (paused at the Task 3 checkpoint pending a live CI run; resumed once the coordinator pushed and forced a `workflow_dispatch` run)
- **Completed:** 2026-07-28
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify)
- **Files modified:** 2 (`MAINTAINING.md`, `test/scripts/lane_classification_drift_test.exs`) across 4 commits (2 from this plan's initial execution, 2 coordinator-applied fixes)

## Accomplishments

- `MAINTAINING.md` § "Required Checks" is now a single classification statement: the contradicting "before merging" merge-gating bullet list and the unparenthesized advisory bullet list are both gone, replaced by one 24-row `job id | display name | classification | disposition | reason` table transcribed from `141-RESEARCH.md`'s Lane Classification Ledger per its five normalization rules.
- The branch-protection truth statement now names the exact two required contexts (`CI Green`, `Guard Release Trigger`) and the five `ci_green.needs` merge-gating leaves distinctly — resolving the job-`id`-vs-display-`name` ambiguity that produced this milestone's originating incident.
- `test/scripts/lane_classification_drift_test.exs` gained `parse_disposition_table/1` + `trim_bt/1` and 7 new tests proving three-way agreement between `Mailglass.CILanes`, `publish-hex.yml`'s four classification arrays, and `MAINTAINING.md`'s table — 40 tests, 0 failures under `mix verify.ci_lane_contract`.
- Two coordinator-applied fixes closed real gaps this plan introduced (see Deviations): a Credo-flagged assertion style and two dropped advisory-matrix lane mentions that a pre-existing docs contract test pins.
- Live GitHub verification (CI run `30408642505`, forced via `workflow_dispatch` to guarantee code lanes executed) confirmed all 24 runtime job names classify correctly (matrix suffixes included), `Credo Strict` and `Design System Conformance (shell gates)` both green, branch protection is exactly the two expected contexts, and the v2.0/v2.1 phase archives are exactly 48/39 files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite `MAINTAINING.md` § "Required Checks" as one 24-row disposition table** - `920f853c` (docs)
2. **Task 2: Bind the disposition table to the registry with a markdown-table parser and drift assertions** - `e560431d` (test)
3. **Task 3: Live verification — checkpoint** - no code commit (verification-only); two coordinator fix commits landed during the pause: `b787d9a0` (fix), `7a603e34` (fix)

**Plan metadata:** this commit (docs: complete 141-06 plan)

## Files Created/Modified

- `MAINTAINING.md` — § "Required Checks" rewritten as one 24-row disposition table + rewritten branch-protection truth statement + prose note (two axes, matrix-promotion warning) + advisory-matrix prose (restored by `7a603e34`)
- `test/scripts/lane_classification_drift_test.exs` — `parse_disposition_table/1`, `trim_bt/1`, `find_required_checks_section/1`, `disposition_table_pairs/1`, `cilanes_classification_pairs/0`, and 7 new tests; `@moduledoc` updated to record three-way agreement; anti-vacuity assert style fixed by `b787d9a0`

## Decisions Made

See `key-decisions` in frontmatter — six decisions recorded, including the two coordinator-applied fixes and the Verification Group 5 local-sandbox gap.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `length(rows) > 0` is a Credo-flagged expensive-comparison pattern**
- **Found during:** Task 3 checkpoint pause, after this plan's Task 2 commit landed
- **Issue:** Credo flags `length(list) > 0` in favor of `list != []` (constant-time vs. linear). This redded `mix ci.fast`'s `credo_strict` lane.
- **Fix:** Changed `assert length(rows) > 0, ...` to `assert rows != [], ...` with identical message; the adjacent `length(rows) == 24` exact-count guard is untouched (Credo only flags the zero-comparison form).
- **Files modified:** `test/scripts/lane_classification_drift_test.exs`
- **Verification:** `mix ci.fast` exit 0 (Credo: 482 files, no issues) after the fix.
- **Committed in:** `b787d9a0` (applied by the coordinator while this plan was paused at the Task 3 checkpoint, not by this executor)

**2. [Rule 1/2 - Bug + Missing Critical] Table rewrite dropped two advisory-matrix lane mentions a docs contract test pins**
- **Found during:** Task 3 checkpoint pause, after this plan's Task 1 commit landed
- **Issue:** The Task 1 rewrite deleted the eleven-item unparenthesized advisory bullet list, which was the only place `Core Full Suite Advisory` and `Provider Compatibility Advisory` were mentioned. `test/mailglass/docs_contract_test.exs:304` pins those names as part of the required-vs-advisory contract, redding `Support Contract Core`. This was also a genuine TRUTH-05 completeness gap: those lanes exist in the separate `advisory-matrix.yml` workflow and their disposition belongs recorded.
- **Fix:** Restored both names (plus `Inbound Full Suite Advisory`) as prose immediately above the pre-existing `Provider Live Advisory` sentence — deliberately as prose, not table rows, since `advisory-matrix.yml` is a separate workflow from `ci.yml` and adding rows would have broken the 24-row/24-job/24-classified triple-equality this plan's own anti-vacuity guards enforce.
- **Files modified:** `MAINTAINING.md`
- **Verification:** `mix test test/mailglass/docs_contract_test.exs` (33 tests, 0 failures, 1 skipped); `mix verify.support_contract.core` (88 tests, 0 failures, 1 skipped); `mix verify.ci_lane_contract` (40 tests, 0 failures); `mix ci.fast` exit 0.
- **Committed in:** `7a603e34` (applied by the coordinator while this plan was paused at the Task 3 checkpoint, not by this executor)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 bug+missing-critical), both applied by the coordinator during the Task 3 checkpoint pause rather than by this executor directly.
**Impact on plan:** Both fixes were necessary corrections to this plan's own Task 1/Task 2 work, discovered by running the full test suite the fixes' own commit messages cite. No scope creep — the 24-row table, its five normalization rules, and the drift meta-test's assertion set are all unchanged; only a lint-safe assertion form and two restored prose sentences were added.

## Issues Encountered

- **Task 3 checkpoint precondition could not be self-satisfied.** The plan's `<precondition>` required a CI run where code lanes actually executed (not a docs-only skip). This executor's session explicitly prohibited pushing or switching branches, so the precondition was genuinely unmet at the time Task 3 was reached — correctly surfaced as a blocked checkpoint rather than guessed past. The coordinator resolved it externally: pushed the branch (already merged as PR #143, which alone triggers nothing further since `ci.yml` only fires on push-to-main/PR-to-main/`workflow_dispatch`) and used `workflow_dispatch` to force `changes.outputs.code=true`, guaranteeing a genuine code-lane run (`30408642505`) rather than relying on the already-passed docs-only run `30384054278`.
- **Verification Group 5 (`mix ci` local green) not achieved in this sandbox.** `mix ci` fails at an `Unchecked dependencies for environment dev` step even after a successful `MIX_ENV=dev mix deps.get`, and separately depends on `preflight_network.sh`/`consumer_install_smoke.sh`, which require network access this sandbox may not have. Format, compile, and Credo all clear (482 files, no issues) before that failure. Recorded honestly as a local-environment gap rather than papered over; the full remote CI run (`30408642505`, 24/24 jobs, only the pre-existing unrelated `Demo Browser Evidence` red) is the stronger substitute evidence, and the working tree is confirmed clean.
- **`Demo Browser Evidence` is red in the live verification run, pre-existing and out of scope.** It was already failing on `main` before Phase 141 (runs `30378514471` and `30375325963`); the three more recent `main` runs before this phase's work show it `skipped` only because those runs were docs-only. It is not a member of `ci_green.needs` (exactly `compile_no_optional_deps`, `installer_host_smoke`, `support_contract_core`, `support_contract_admin`, `trust_lane_repo_head`), so it gates no merge. Not fixed in this phase, per the coordinator's explicit instruction.

## Live Verification Evidence (Task 3)

**CI run:** `30408642505`, head SHA `7a603e34ae80d037d282a983fe7a974ee5c99a39`, event `workflow_dispatch`. Job count: 24. Run conclusion: `failure` (solely `Demo Browser Evidence`, pre-existing/out-of-scope — see above). `CI Green`: `success`.

| Job (runtime name, matrix suffix if any) | Conclusion |
|---|---|
| Detect Non-Doc Changes | success |
| Branch Protection Advisory | success |
| Mix Task Tests (Elixir 1.18 / OTP 27) | success |
| Compile Warnings as Errors (Elixir 1.18 / OTP 27) | success |
| Support Contract Core (Elixir 1.18 / OTP 27) | success |
| Format Check (Elixir 1.18 / OTP 27) | success |
| Compile No Optional Deps (Elixir 1.18 / OTP 27) | success |
| Installer Host Smoke | success |
| Hex Audit (Elixir 1.18 / OTP 27) | success |
| Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22) (22) | success |
| Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27) | success |
| Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22) | success |
| Inbound Test (Elixir 1.18 / OTP 27) | success |
| Design System Conformance (shell gates) | success |
| Demo Browser Evidence (Docker Compose / Chromium) | failure |
| Support Contract Admin (Elixir 1.18 / OTP 27) | success |
| Credo Strict (Elixir 1.18 / OTP 27) | success |
| Trust Lane Repo Head (Elixir 1.18 / OTP 27) | success |
| Trust Lane Clean Baseline (Elixir 1.18 / OTP 27) | success |
| Docs Warnings as Errors (Elixir 1.18 / OTP 27) | success |
| Deps Audit Advisory (Elixir 1.18 / OTP 27) | success |
| Installer Golden Gate (Elixir 1.18 / OTP 27) | success |
| Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27) | success |
| CI Green | success |

**Group 1 (runtime names vs. classification arrays) — PASS.** 24 runtime job names; `Mailglass.CILanes.all_classified_lanes/0` has 24 entries; every runtime name (matrix suffixes included) prefix-matches EXACTLY ONE of `required_lanes` / `advisory_classified_lanes` / `publish_gating_lanes` / `structural_lanes` under the exact-equality-or-prefix rule.

**Group 2 (the CONFORM-04 split) — PASS.** `Credo Strict (Elixir 1.18 / OTP 27)` :: success AND `Design System Conformance (shell gates)` :: success, both green in the same run.

**Group 3 (branch protection) — PASS.** `gh api repos/szTheory/mailglass/branches/main/protection/required_status_checks` returned contexts exactly `["CI Green","Guard Release Trigger"]`, `strict: true`, both `app_id 15368`. No third context.

**Group 4 (archive counts) — PASS.** `find .planning/milestones/v2.0-phases -type f | wc -l` = `48`; `find .planning/milestones/v2.1-phases -type f | wc -l` = `39`. Exact match to expected 48/39 (HIST-01).

**Group 5 (`mix ci` green + clean tree) — NOT ACHIEVED LOCALLY, recorded honestly.** `mix ci` fails at `Unchecked dependencies for environment dev` after clearing format/compile/Credo (482 files, no issues); local sandbox/network gap, not an assertion failure. `git status --porcelain` empty (working tree clean). The full remote CI run above is the stronger substitute evidence.

**Local gates confirmed at HEAD `7a603e34` (this session):**
- `mix verify.ci_lane_contract` — 40 tests, 0 failures
- `mix test test/mailglass/docs_contract_test.exs` — 33 tests, 0 failures, 1 skipped
- `git status --short` — clean

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 141 (Lane Truth Foundation) is complete: TRUTH-07, TRUTH-09, TRUTH-05, and CONFORM-04 are all closed, `MAINTAINING.md`/`ci_lanes.ex`/`publish-hex.yml`'s `gate-ci-green` are proven to agree by a build-breaking meta-test, and live GitHub state confirms the classification holds at runtime. Phase 142 (Supply-Chain Remediation & Gating) can proceed against the reconciled classification — `hex_audit` and `deps_audit_advisory`'s `promote` dispositions are recorded recommendations only, ready for VULN-03/VULN-05 to execute. No blockers. `Demo Browser Evidence`'s pre-existing red status and the local-sandbox `mix ci` gap are both out of this phase's scope and documented for awareness, not carried forward as open Phase 141 work.

---
*Phase: 141-lane-truth-foundation*
*Completed: 2026-07-28*

## Self-Check: PASSED

All referenced files (`MAINTAINING.md`, `test/scripts/lane_classification_drift_test.exs`, this SUMMARY) confirmed present on disk. All referenced commit hashes (`920f853c`, `e560431d`, `b787d9a0`, `7a603e34`, `4f84208c`) confirmed present in `git log --oneline --all`.
