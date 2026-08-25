---
phase: 162-protected-release-and-scheduled-control-recovery
verified: 2026-08-24T20:51:36Z
status: human_needed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Protected exact-digest dispatch now requires a fresh repository-admin check for github.actor before any PAT-backed protected step."
    - "Malformed or non-list successful GitHub PR-list output now becomes serialized cannot-check evidence instead of aborting repository-hygiene."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "After these changes are on protected remote main, inspect the next applicable release-please, repo-hygiene, and post-publish-smoke schedule runs and download their retained JSON artifacts."
    expected: "Each run has event=schedule, the expected workflow SHA, and a bounded pass/blocked/cannot-check/pending result that agrees with its log, summary, and artifact; no manual dispatch is used as schedule proof."
    why_human: "The checked-in ledger records the required post-change schedule rows as pending because the workflows were not yet reachable on protected remote main when captured; local fixtures cannot create or observe GitHub's scheduled runs."
  - test: "Review the phase's judgment-tier MUST NOT constraints against the protected remote workflow and release evidence."
    expected: "No retained evidence was rewritten, no stale/manual observation was presented as fresh proof, and no release or publication authority was broadened or forced."
    why_human: "These are intentional judgment-tier prohibitions with no test-tier enforcement or accepted override."
---

# Phase 162: Protected Release and Scheduled-Control Recovery Verification Report

**Phase Goal:** Maintainers can explain and safely disposition the blocked release state while existing release and repository controls report only truthful, bounded outcomes.
**Verified:** 2026-08-24T20:51:36Z
**Status:** human_needed
**Re-verification:** Yes — after Wave 7 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can reconcile PR #222, its commits/checks, tags, Hex versions, and the target ledger into one evidence-backed narrative. | ✓ VERIFIED | `162-RELEASE-RECONCILIATION.md` retains timestamped PR/check/tag/Hex/target/WT-03/recovery rows and exact identities; all 8 reconciliation-contract tests passed. |
| 2 | PR #222 and every stale release branch or check have a protected merge, recorded retirement reason, or named recovery condition; none remain unexplained or auto-merge-armed in limbo. | ✓ VERIFIED | The final disposition matrix gives every scoped identity one outcome; PR #222 records `auto-merge: null` and an exact-digest protected recovery condition. |
| 3 | Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority. | ✓ VERIFIED | The dispatcher gate requires the exact GitHub admin permission shape before all protected/PAT-bearing steps; the unauthorized-dispatch regression passed. The idle-schedule regression produced pending `no_open_proposal` JSON and no protected command. |
| 4 | Repository-hygiene reports an inspectable pass, policy block, or cannot-check outcome with agreeing logs and JSON evidence, including control and applicable scheduled-run proof. | ✓ VERIFIED | `pull_requests/1` and `ci_state/1` use non-raising JSON/list-shape guards; the malformed PR test passed with decodable nonzero `cannot-check` JSON. The workflow writes its summary and upload from the same artifact. Live post-change schedule observation remains a human gate below. |
| 5 | Post-publish validation checks the exact immutable published target through its recovery path, or records an evidence-backed inapplicable or blocked result without substituting `main` or forcing publication. | ✓ VERIFIED | The resolver fixture passed for pass, blocked, and cannot-check paths, verifies the exact immutable ref, and serializes one resolution before summary/upload. |

**Score:** 5/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `162-RELEASE-RECONCILIATION.md` and reconciliation test | Append-only release narrative and disposition ledger | ✓ VERIFIED | Exists, substantive, and its eight deterministic schema/identity tests pass. |
| `.github/workflows/release-please.yml` and trigger-recovery test | Bounded proposal/control results and protected authority boundary | ✓ VERIFIED | Repository-admin dispatcher authorization precedes validation, merge, release, and PAT checkout; executable denial fixture passes. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex`, workflow, and test | Three-state CLI/JSON/summary/artifact agreement | ✓ VERIFIED | Both external JSON boundaries classify malformed/non-list bytes as `cannot-check`; workflow reads the emitted file for summary/upload. |
| `.github/workflows/post-publish-smoke.yml` and contract test | Exact-target recovery result and mandatory evidence | ✓ VERIFIED | Resolution writer, `always()` summary/upload, and exact target guard are wired and exercised. |

`verify.artifacts` reported only two literal-pattern misses: Plan 09 expects the shell spelling `checkout --detach`, while the executable test uses `git!(repo, ["checkout", "--detach", sha])`; Plan 10 expects `post-merge`, while the test names and exercises the same lifecycle in prose. These are verifier-pattern false negatives, not stubs.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `github.actor` permission query | Protected validation, merge, release, and PAT checkout | `protected-dispatcher.outputs.authorized == 'true'` | ✓ WIRED | Workflow lines 171-301 establish the fresh admin query and gate every protected/PAT-bearing step; named regression passes. |
| Proposal/schedule discovery | Proposal-control JSON, summary, upload, final gate | Empty-digest predicate and result writer | ✓ WIRED | Named idle-schedule fixture proves pending output is persisted and does not invoke protected commands. |
| `gh` CI/PR list bytes | `audit/1` map → JSON → Actions summary/upload | `Jason.decode/1` + `is_list` guards | ✓ WIRED | Both malformed-response contracts pass; `repo-hygiene.yml` reads the same JSON written by the command. |
| Exact policy target | `check_post_publish_target.sh` → resolution JSON → summary/upload | Immutable target ref and exact package versions | ✓ WIRED | Resolver fixture runs pass/blocked/cannot-check cases and the workflow has no `main` fallback in the resolver job. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Reconciliation ledger | source/disposition rows | GitHub/Git/Hex/target evidence | Captured immutable values and explicit unavailable states | ✓ FLOWING |
| Proposal-control result | status/reason/event/run/identities | scheduled discovery or capture output | Fixture writes and decodes actual JSON | ✓ FLOWING |
| Hygiene result | `%{status, reason, checks}` | `audit/1` external observations | Decodable output flows unchanged to summary/artifact | ✓ FLOWING |
| Post-publish resolution | status/reason/target/version fields | immutable-target resolver | Fixture produces each bounded outcome before upload | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Unapproved dispatcher cannot reach protected PAT boundary | `mix test test/scripts/release_trigger_recovery_test.exs:251 --warnings-as-errors --no-deps-check --seed 0` | 1 test, 0 failures | ✓ PASS |
| Malformed/non-list PR-list bytes become bounded JSON evidence | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs:312 --warnings-as-errors --no-deps-check --seed 0` | 1 test, 0 failures | ✓ PASS |
| Idle scheduled release creates pending control result without authority | `mix test test/scripts/release_trigger_recovery_test.exs:504 --warnings-as-errors --no-deps-check --seed 0` | 1 test, 0 failures | ✓ PASS |
| Exact post-publish resolver preserves pass/blocked/cannot-check | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs:162 --warnings-as-errors --no-deps-check --seed 0` | 1 test, 0 failures | ✓ PASS |
| Reconciliation schema, ordering, and evidence rows | `mix test test/scripts/phase_162_release_reconciliation_test.exs --warnings-as-errors --no-deps-check --seed 0` | 8 tests, 0 failures | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `scripts/**/tests/probe-*.sh` probe exists.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AUTO-01 | 01, 05 | Evidence-backed release-state narrative | ✓ SATISFIED | Reconciliation ledger plus passing schema contract. |
| AUTO-02 | 01, 05 | Explicit safe PR/branch/check dispositions | ✓ SATISFIED | Stable one-outcome matrices, explicit empty rows, and `auto-merge: null`. |
| AUTO-03 | 02, 05, 06, 08, 10, 12 | Truthful proposal-only controls without authority expansion | ✓ SATISFIED | Admin dispatcher enforcement and ordinary schedule/control regressions pass; live scheduled UAT remains required. |
| AUTO-04 | 03, 05, 09, 11, 13 | Inspectable three-state hygiene evidence | ✓ SATISFIED | Exact-SHA and malformed CI/PR evidence boundaries are serialized; live scheduled UAT remains required. |
| AUTO-05 | 04, 05, 07 | Exact immutable post-publish proof or bounded outcome | ✓ SATISFIED | Resolver fixtures prove immutable pass, blocked-unpublished, and cannot-check outcomes; live scheduled UAT remains required. |

All requirement IDs declared in the 13 plan frontmatters are AUTO-01 through AUTO-05. `REQUIREMENTS.md` assigns exactly those five IDs to Phase 162, so no orphaned requirement exists.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `.github/workflows/post-publish-smoke.yml` | 489, 495 | “not available on Hex.pm” diagnostic | ℹ️ Info | Genuine bounded package-availability failure message, not placeholder text. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in phase-delivered implementation files. No missing, stubbed, or orphaned phase artifact was found.

### Human Verification Required

### 1. Observe post-change scheduled controls

**Test:** After deployment to protected `main`, download the next `event=schedule` run and JSON artifact for `release-please.yml`, `repo-hygiene.yml`, and `post-publish-smoke.yml`.

**Expected:** Event/run ID/workflow SHA, logs, job summary, and JSON artifact agree on a bounded outcome. A manual dispatch is never used as schedule evidence.

**Why human:** The final ledger records the post-change schedule rows as pending; GitHub's scheduler and retained artifacts are external state that local tests cannot observe.

### 2. Resolve judgment-tier safety prohibitions

**Test:** Review preserved release evidence and protected remote workflow settings.

**Expected:** No uncertain evidence was rewritten; no stale/manual observation was claimed fresh; no publication was forced; and protected release authority remains limited to an approved admin dispatcher.

**Why human:** These phase-plan MUST NOT constraints are judgment-tier and have neither automated enforcement evidence nor an accepted override.

### Gaps Summary

The two prior blocking implementation gaps are closed. No subsequent milestone phase specifically covers any unresolved Phase 162 implementation concern. This report is an escalation gate, not a pass: it awaits external scheduled-run evidence and developer resolution of the judgment-tier prohibitions. The repository must not advance on a claim that these operational observations have already occurred.

---

_Verified: 2026-08-24T20:51:36Z_
_Verifier: the agent (gsd-verifier)_
