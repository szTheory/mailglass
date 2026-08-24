---
phase: 162-protected-release-and-scheduled-control-recovery
verified: 2026-08-24T19:59:42Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "A protected exact-digest release now skips the proposal-only tail after its merge, so zero open proposals cannot retroactively fail the release."
    - "Malformed or non-list zero-exit ci.yml run-list output now becomes serialized cannot-check evidence."
  gaps_remaining: []
  regressions: []
gaps:
  - truth: "Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority."
    status: failed
    reason: "Any collaborator allowed to dispatch workflows can supply the non-secret candidate digest and activate RELEASE_PLEASE_PAT-backed admin merge and release creation; exact candidate integrity is not authorization of the dispatcher."
    artifacts:
      - path: ".github/workflows/release-please.yml"
        issue: "The only protected-dispatch condition is workflow_dispatch plus nonempty candidate_digest; the PAT-backed merge/release steps have neither protected environment approval nor actor/team authorization."
      - path: "test/scripts/release_trigger_recovery_test.exs"
        issue: "The green protected-lifecycle test verifies exact identity and proposal-tail exclusion, but never verifies dispatcher authorization or an environment gate."
    missing:
      - "Put PAT-backed merge and release creation in a GitHub Environment requiring release-maintainer approval, or enforce an equivalent durable GitHub/team authorization check before the secret is exposed."
      - "Add a contract test proving unapproved dispatchers cannot reach PAT-backed merge/release steps."
  - truth: "Repository-hygiene reports an inspectable pass, policy block, or cannot-check outcome with agreeing logs and JSON evidence, including control and applicable scheduled-run proof."
    status: failed
    reason: "A successful malformed gh pr list response calls Jason.decode! and raises before aggregate rendering, JSON output, workflow summary, or artifact upload."
    artifacts:
      - path: "dev/mix/tasks/mailglass.repo.hygiene.ex"
        issue: "pull_requests/1 decodes zero-exit output with Jason.decode! at line 292 without list-shape validation or a cannot-check branch."
      - path: "test/mix/tasks/mailglass.repo.hygiene_test.exs"
        issue: "Malformed successful CI run-list responses are covered, but no malformed/non-list gh pr list fixture exists."
    missing:
      - "Use Jason.decode/1, require a list, and convert malformed zero-exit PR-list output into cannot-check with recovery detail."
      - "Add malformed and non-list PR-list fixtures that prove decodable JSON and the documented nonzero cannot-check exit."
---

# Phase 162: Protected Release and Scheduled-Control Recovery Verification Report

**Phase Goal:** Maintainers can explain and safely disposition the blocked release state while existing release and repository controls report only truthful, bounded outcomes.
**Verified:** 2026-08-24T19:59:42Z
**Status:** gaps_found
**Re-verification:** Yes — after Wave 6 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can reconcile PR #222, its commits/checks, tags, Hex versions, and the target ledger into one evidence-backed narrative. | ✓ VERIFIED | `162-RELEASE-RECONCILIATION.md` has timestamped PR, tag, Hex, ledger, identity, observation, and recovery rows; the reconciliation contract remains substantive. |
| 2 | PR #222 and every stale release branch or check have a protected merge, recorded retirement reason, or named recovery condition; none remain unexplained or auto-merge-armed in limbo. | ✓ VERIFIED | The ledger gives each scoped identity one disposition; PR #222 records `auto-merge: null` and a named exact-digest recovery condition. |
| 3 | Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority. | ✗ FAILED — BLOCKER | The workflow correctly excludes protected dispatch from the proposal-only tail, but its sole activation condition is a nonempty digest. It then exposes `RELEASE_PLEASE_PAT` for `gh pr merge --admin` and release creation without an Environment or actor authorization gate. |
| 4 | Repository-hygiene reports an inspectable pass, policy block, or cannot-check outcome with agreeing logs and JSON evidence, including control and applicable scheduled-run proof. | ✗ FAILED — BLOCKER | `ci_state/1` now bounds malformed CI data, but `pull_requests/1` still uses `Jason.decode!` for a zero-exit PR list and can prevent the required result/artifact. |
| 5 | Post-publish validation checks the exact immutable published target through its recovery path, or records an evidence-backed inapplicable or blocked result without substituting `main` or forcing publication. | ✓ VERIFIED | The resolver writes one resolution before summary/upload; exact 40-character target validation and `check_post_publish_target.sh` occur before pass-only outputs, with no `main` fallback. |

**Score:** 3/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `162-RELEASE-RECONCILIATION.md` and reconciliation test | Evidence and disposition ledger | ✓ VERIFIED | Exists, substantive, and the test covers its schema/identity rows. |
| `.github/workflows/release-please.yml` and trigger-recovery test | Bounded proposal/control result without authority expansion | ⚠️ PARTIAL | Capture/result tail wiring is now safely exclusive; privileged dispatch authorization remains absent. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex`, workflow, and test | Three-state CLI/JSON/artifact agreement | ⚠️ PARTIAL | CI malformed-response handling and exact-SHA flow are wired; malformed PR-list data crashes. |
| `.github/workflows/post-publish-smoke.yml` and contract test | Exact-target recovery resolution | ✓ VERIFIED | Resolution JSON flows to summary/upload and target guard consumes the resolved immutable target. |

`verify.artifacts` reported literal-pattern misses for Plan 09 (`checkout --detach`) and Plan 10 (`post-merge`). These are false negatives, not stubs: the tests execute `git!(repo, ["checkout", "--detach", sha])` and define the protected “after its merge” lifecycle at line 398. All remaining declared artifacts exist and are substantive.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Protected digest classification | proposal capture/result/summary/upload/final gate | `candidate_digest == ''` predicate | ✓ WIRED | Each proposal-only tail step carries the empty-digest predicate; the focused protected lifecycle test passes. |
| Protected dispatch | PAT-backed merge and release | `protected-dispatch` outputs | ✗ NOT SAFELY WIRED | Candidate identity gates the action, but no authorization gate protects the dispatcher or secret. |
| `git rev-parse HEAD` | `gh run list --commit` → CI state | exact SHA and returned `headSha` | ✓ WIRED | `ci_state/1` validates exact SHA/completed/success; malformed CI test passes. |
| `audit/1` result map | JSON → Actions summary/upload | `$RUNNER_TEMP/repo-hygiene.json` | ⚠️ PARTIAL | Valid and CI-malformed paths serialize one map; malformed PR-list decoding aborts first. |
| Exact target resolver | post-publish JSON → summary/upload/guard | serialized resolution | ✓ WIRED | Resolution is finalized before `always()` consumers and pass-only guard. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Reconciliation ledger | source/disposition rows | GitHub/Git/Hex/ledger evidence | Yes | ✓ FLOWING |
| Release proposal control result | capture/discovery output | exact proposal query → JSON writer | Yes for ordinary paths; protected tail excluded | ✓ FLOWING |
| Hygiene result | `%{status, reason, checks}` | `audit/1` → JSON → workflow consumers | Not for malformed successful PR-list data | ⚠️ HOLLOW ERROR PATH |
| Post-publish resolution | resolution JSON | target resolver → summary/upload | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Protected merge then zero open proposal | `mix test test/scripts/release_trigger_recovery_test.exs:398 --warnings-as-errors --no-deps-check` | 1 test, 0 failures; verifies no proposal-tail invocation after merge. | ✓ PASS |
| Malformed/non-list successful CI response | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs:276 --warnings-as-errors --no-deps-check` | 1 test, 0 failures; verifies cannot-check JSON/nonzero exit. | ✓ PASS |
| Dispatcher authorization boundary | workflow control-flow trace | No `environment`, actor, or team check before PAT-backed merge/release; tests do not exercise this boundary. | ✗ FAIL |
| Malformed successful PR-list response | source/error-path trace | `Jason.decode!` necessarily raises before `audit/1` can render the result map. | ✗ FAIL |

No declared or conventional `probe-*.sh` file applies to this phase.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AUTO-01 | 01, 05 | Evidence-backed release-state narrative | ✓ SATISFIED | Reconciliation ledger and contract. |
| AUTO-02 | 01, 05 | Explicit safe PR/branch/check dispositions | ✓ SATISFIED | One-outcome matrix, recovery conditions, auto-merge null. |
| AUTO-03 | 02, 05, 06, 08, 10 | Truthful proposal-only controls without authority expansion | ✗ BLOCKED | A workflow dispatcher can activate PAT-backed protected release using the exposed/non-secret digest. |
| AUTO-04 | 03, 05, 09, 11 | Inspectable three-state hygiene evidence | ✗ BLOCKED | Successful malformed PR-list data has no bounded result. |
| AUTO-05 | 04, 05, 07 | Exact immutable post-publish proof or bounded outcome | ✓ SATISFIED | Resolver serialization and exact target guard. |

Every ID declared across all 11 plan frontmatters is one of AUTO-01 through AUTO-05 and is accounted for above. REQUIREMENTS.md assigns exactly those five IDs to Phase 162; no orphaned Phase 162 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.github/workflows/release-please.yml` | 171-289 | Non-secret dispatch digest is the only gate before PAT-backed `gh pr merge --admin` and release action | 🛑 BLOCKER | Broad workflow-dispatch permission becomes protected-release authority. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | 290-304 | Bang JSON decoder at external PR-list boundary | 🛑 BLOCKER | A truthful bounded cannot-check result, summary, and artifact are skipped. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in phase-delivered implementation files. The two `not available` messages in post-publish are real Hex diagnostics, not placeholders.

### Human Verification Required

After both blockers are repaired on protected `main`, inspect an applicable scheduled release-please and repository-hygiene run plus their JSON artifacts. Confirm that event name, run ID, workflow SHA, summary, and retained artifact agree, and do not treat a manual dispatch as scheduled proof.

The plans also declare judgment-tier MUST NOT prohibitions (evidence preservation, stale/manual-proof handling, trigger authority, forced publication, and CI identity substitution). They have no test-tier enforcement or accepted override, so a maintainer must explicitly review them; this report does not silently pass those judgments.

### Gaps Summary

Wave 6 genuinely closed the previous functional gaps: protected releases now bypass the proposal-only post-merge tail, and malformed CI-run output becomes `cannot-check`. The phase still fails its safety/observability goal for two independent, observable error/authority paths. These gaps are not deferred: Phase 163 addresses timeout repairs, not release authorization or repository-hygiene PR-list decoding. This is an escalation gate; do not advance Phase 162 until both structured gaps are repaired and re-verified.

---

_Verified: 2026-08-24T19:59:42Z_
_Verifier: the agent (gsd-verifier)_
