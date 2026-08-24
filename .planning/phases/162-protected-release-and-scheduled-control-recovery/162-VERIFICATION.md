---
phase: 162-protected-release-and-scheduled-control-recovery
verified: 2026-08-24T18:52:47Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "An idle scheduled release run with no open proposal now emits a successful pending/no_open_proposal result without entering capture."
    - "Scheduled repository hygiene now queries ci.yml by the detached checkout SHA and verifies the returned headSha."
  gaps_remaining:
    - "Protected exact-digest dispatch runs proposal capture after merging its release PR, so a successful protected release is turned into proposal_missing failure."
    - "A zero-exit malformed gh CI response raises through Jason.decode! instead of becoming a bounded cannot-check hygiene result."
  regressions:
    - "The protected-dispatch lifecycle is not exercised by the green release-trigger tests."
gaps:
  - truth: "Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority."
    status: failed
    reason: "The protected exact-digest dispatch merges/releases before the unconditional non-scheduled proposal capture. That capture requires an open release PR, so the normal post-merge zero-row result is classified blocked/proposal_missing and the final gate fails the completed protected release."
    artifacts:
      - path: ".github/workflows/release-please.yml"
        issue: "Protected merge/release occurs at lines 250-311, while capture at lines 471-522 still runs for workflow_dispatch and final gate at lines 660-666 rejects proposal_missing."
      - path: "test/scripts/release_trigger_recovery_test.exs"
        issue: "Tests exercise pre-merge capture and idle schedule behavior but no protected merge followed by zero open release proposals."
    missing:
      - "Restrict discovery/capture/result gating to proposal-only runs, or serialize an explicit successful protected-dispatch outcome after merge/release."
      - "Add an executable protected-dispatch lifecycle fixture proving a post-merge zero-proposal query cannot fail the completed protected release."
  - truth: "Repository-hygiene reports an inspectable pass, policy block, or cannot-check outcome with agreeing logs and JSON evidence, including control and applicable scheduled-run proof."
    status: failed
    reason: "A successful but malformed gh run-list response raises at Jason.decode! and terminates the Mix task before it can render the documented cannot-check JSON/summary/artifact."
    artifacts:
      - path: "dev/mix/tasks/mailglass.repo.hygiene.ex"
        issue: "ci_state/1 calls Jason.decode! at lines 182-185 with no decode/list validation or cannot-check branch."
      - path: "test/mix/tasks/mailglass.repo.hygiene_test.exs"
        issue: "Detached SHA, absent, failed, mismatch, and nonzero-gh cases are covered, but zero-exit malformed JSON is not."
    missing:
      - "Use Jason.decode/1, validate a list result, and map malformed successful output to cannot-check with recovery detail."
      - "Add a malformed zero-exit gh fixture that proves JSON output and the nonzero cannot-check policy remain intact."
human_verification:
  - test: "After the two blockers are repaired and deployed to protected main, inspect the next applicable release-please and repo-hygiene scheduled runs and download their JSON artifacts."
    expected: "Each artifact, summary, event name, run ID, and workflow SHA agrees; a control dispatch is not substituted for scheduled evidence."
    why_human: "GitHub Actions scheduling, protected-main reachability, and uploaded remote artifacts cannot be established by local fixtures."
  - test: "Review the unique judgment-tier MUST NOT assertions declared across Plans 01-09 (retained evidence preservation, stale/manual-proof handling, ordinary-trigger authority, forced publication, and CI identity substitution)."
    expected: "The developer explicitly accepts or rejects each prohibition; no non-authoritative LLM judgment is treated as a silent pass."
    why_human: "These plans provide judgment-tier prohibitions with no wired negative-test enforcement or accepted override."
---

# Phase 162: Protected Release and Scheduled-Control Recovery Verification Report

**Phase Goal:** Maintainers can explain and safely disposition the blocked release state while existing release and repository controls report only truthful, bounded outcomes.
**Verified:** 2026-08-24T18:52:47Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can reconcile PR #222, its commits/checks, tags, Hex versions, and the target ledger into one evidence-backed narrative. | ✓ VERIFIED | `162-RELEASE-RECONCILIATION.md` contains timestamped source, identity, observation, and disposition rows; its eight parser/coverage tests passed in the focused run. |
| 2 | PR #222 and every stale release branch or check have a protected merge, recorded retirement reason, or named recovery condition; none remain unexplained or auto-merge-armed in limbo. | ✓ VERIFIED | The final disposition matrix gives every scoped identity one outcome and `release-please.yml:677-` retains the ordinary auto-merge disarm. |
| 3 | Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining release authority. | ✗ FAILED — BLOCKER | The idle-schedule repair is real, but protected dispatch merges/releases before the non-scheduled capture that then requires an open PR. A normal zero-row post-merge lookup becomes `blocked/proposal_missing`, and the final gate fails. |
| 4 | Repository-hygiene reports pass, blocked, or cannot-check consistently in CLI, summary, JSON, and retained evidence, with control and applicable scheduled provenance kept distinct. | ✗ FAILED — BLOCKER | Exact-SHA detached-head selection is wired and tested, but `Jason.decode!` on a zero-exit malformed `gh` response crashes instead of producing the required bounded `cannot-check` result/artifact. |
| 5 | Post-publish uses only the exact immutable target and provides bounded blocked/inapplicable evidence without `main` fallback or forced publication. | ✓ VERIFIED | Resolver tests passed for pass, blocked, cannot-check, and pending/no-op paths; `.github/workflows/post-publish-smoke.yml:138-257` serializes one resolution before summary/upload and invokes the exact-target guard. |

**Score:** 3/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `162-RELEASE-RECONCILIATION.md` + reconciliation test | Evidence-backed release/disposition ledger | ✓ VERIFIED | Substantive append-only matrices and runnable parser contract. |
| `.github/workflows/release-please.yml` + recovery test | Truthful bounded proposal/control result | ⚠️ PARTIAL | Scheduled idle discovery is correct, but protected dispatch is wired into an invalid post-merge capture/fail path. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` + workflow/test | Three-state hygiene result and artifact-first reporting | ⚠️ PARTIAL | Detached SHA flow and JSON/summary wiring are substantive; malformed successful remote output is unbounded. |
| `.github/workflows/post-publish-smoke.yml` + contract test | Exact target resolution before mandatory upload | ✓ VERIFIED | Writer, summary, upload, and target guard consume the same resolution. |

`verify.artifacts` marked the Plan 09 test's literal `checkout --detach` pattern missing, but this is a false negative: the substantive executable test calls `git!(repo, ["checkout", "--detach", sha])` at `mailglass.repo.hygiene_test.exs:221` and asserts detached HEAD. It is not a stub.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Scheduled proposal discovery | Capture/result/final gate | `should_capture`, discovery outputs, JSON status | ✓ WIRED | `no_open_proposal` skips capture; writer preserves discovery status; final gate permits only bounded pending. |
| Protected dispatch | Capture/result/final gate | Non-schedule condition | ✗ NOT WIRED SAFELY | The same condition includes protected workflow dispatch after protected merge/release, causing the failed lifecycle above. |
| Detached checkout SHA | `gh run list --commit` | exact SHA and returned `headSha` validation | ✓ WIRED | `repo.hygiene.ex:160-190`; detached fixture asserts exact argv and success/mismatch/unavailable outcomes. |
| `audit/1` result map | JSON → Actions summary/upload | One JSON file consumed by `jq` | ✓ WIRED | `repo-hygiene.yml:40-69` consumes `$RUNNER_TEMP/repo-hygiene.json`; malformed-decode path prevents producing it. |
| Exact protected target | post-publish resolution → summary/upload | resolver serializer and target guard | ✓ WIRED | Resolution is finalized before the `always()` consumers. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Reconciliation ledger | Source/disposition rows | Read-only GitHub, Git, Hex, ledger, and retained evidence | Yes | ✓ FLOWING |
| Release proposal result | Capture/discovery status and identities | GitHub proposal query → output → JSON writer | Yes for idle schedule and proposal capture; invalid for protected post-merge lifecycle | ⚠️ PARTIAL |
| Hygiene result | `%{status, reason, checks}` | `audit/1` → JSON → summary/artifact | Yes for valid and nonzero-`gh` inputs; malformed zero-exit data crashes | ⚠️ PARTIAL |
| Post-publish resolution | Resolution JSON | Resolver → summary/upload | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Phase 162 contracts | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors --no-deps-check` | Passed; only known OTLP exporter warnings were emitted. | ✓ PASS |
| Idle scheduled proposal discovery | Executable fixture `release_trigger_recovery_test.exs:398` | Empty digest plus argument-sensitive zero-proposal query emits `pending/no_open_proposal`, uploads evidence, and does not invoke protected operations. | ✓ PASS |
| Detached scheduled CI evidence | Executable fixture `mailglass.repo.hygiene_test.exs:214` | Detached HEAD passes its SHA through `--commit`; matching completed success passes and other tested outcomes do not. | ✓ PASS |
| Protected merge then proposal capture | Workflow control-flow trace | `protected-merge`/release precede capture; capture queries only open PRs and final gate rejects its `proposal_missing` result. No test exercises this path. | ✗ FAIL |
| Malformed successful CI response | Source/error-path trace | `Jason.decode!` at `repo.hygiene.ex:184` necessarily raises before the result map can serialize; no test covers it. | ✗ FAIL |

No declared or conventional `probe-*.sh` files apply to this phase.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AUTO-01 | 162-01, 162-05 | Evidence-backed release-state narrative | ✓ SATISFIED | Append-only reconciliation ledger and focused schema/coverage tests. |
| AUTO-02 | 162-01, 162-05 | Safe explicit PR/branch/check dispositions | ✓ SATISFIED | Singular disposition and explicit-empty-category contracts; ordinary auto-merge disarmed. |
| AUTO-03 | 162-02, 162-05, 162-06, 162-08 | Truthful proposal-only control/schedule result without authority expansion | ✗ BLOCKED | Scheduled idle repair passes, but a protected successful dispatch is subsequently converted to a false proposal-missing failure. |
| AUTO-04 | 162-03, 162-05, 162-09 | Inspectable three-state hygiene result with control/scheduled evidence | ✗ BLOCKED | Detached exact-SHA query is correct, but malformed successful remote output has no bounded cannot-check result. |
| AUTO-05 | 162-04, 162-05, 162-07 | Exact immutable post-publish proof or bounded blocked/inapplicable outcome | ✓ SATISFIED | Behavioral resolver fixtures and exact-target/no-fallback workflow wiring. |

All five Phase 162 requirement IDs declared by plan frontmatter are accounted for. No orphaned Phase 162 requirements were found. Phase 163 concerns timeout repairs, not either failed control path, so neither gap is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.github/workflows/release-please.yml` | 250-311, 471-522, 660-666 | Protected merge/release followed by proposal-only open-PR capture and non-pass gate | 🛑 BLOCKER | A valid protected release reports failure after succeeding. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | 182-185 | Bang JSON decoder at an external command boundary | 🛑 BLOCKER | Required cannot-check evidence/artifact is skipped on malformed zero-exit output. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | 95-98 | `--apply` branch does not preserve uncommitted/untracked work | ⚠️ WARNING | The advertised preservation action does not protect dirty work; outside the scheduled CI truth but needs correction or narrowed documentation. |
| `.github/workflows/post-publish-smoke.yml` | 327, 350-385 | Eight-minute job contains three serial five-minute index waits | ⚠️ WARNING | The job can time out before its stated per-package polling windows complete. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in phase-delivered code. The two `not available` strings are genuine Hex diagnostics, not placeholders.

### Human Verification Required

The two items in the frontmatter must be performed after blocker repair. In addition, the plans contain judgment-tier MUST NOT prohibitions without test-tier enforcement or accepted overrides. Those prohibitions are non-authoritative LLM-judge observations and require maintainer review; they are not silently passed.

### Gaps Summary

The Wave 5 fixes close both prior verification gaps: idle schedules now produce a truthful successful pending result, and detached scheduled hygiene uses exact SHA selection. However, independent code tracing confirms the review's blocker: protected dispatch invokes an open-proposal capture after it has merged the only proposal. A second independently validated blocker exists in hygiene's unhandled malformed-successful-`gh` path. Both violate the phase goal's requirement that controls report only truthful, bounded outcomes. This is an escalation gate: do not advance Phase 162 until the two structured gaps are repaired and re-verified.

---

_Verified: 2026-08-24T18:52:47Z_
_Verifier: the agent (gsd-verifier)_
