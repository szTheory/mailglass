---
phase: 162-protected-release-and-scheduled-control-recovery
verified: 2026-08-22T19:35:16Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining release authority."
    status: failed
    reason: "The proposal-capture step replaces its EXIT output trap after creating the worktree, so successful and identity-mismatch capture paths do not publish their result fields. The result writer consequently defaults to cannot-check."
    artifacts:
      - path: ".github/workflows/release-please.yml"
        issue: "Line 487 replaces the line-453 emit_capture_outputs EXIT trap."
    missing:
      - "Use one guarded cleanup-and-output trap (or explicitly chain both) and add an executable capture-path test that asserts GitHub outputs and the resulting pass artifact."
  - truth: "Post-publish validation checks the exact immutable published target through its recovery path, or records an evidence-backed inapplicable or blocked result without substituting main or forcing publication."
    status: failed
    reason: "post-publish-resolution.json is only written for the scheduled authorized/not_started branch, while its upload is mandatory for every trigger. Normal completed schedule/dispatch and deliberate release-event no-op paths therefore fail artifact upload and skip dependent proof jobs."
    artifacts:
      - path: ".github/workflows/post-publish-smoke.yml"
        issue: "Lines 117-120 write only the blocked artifact; lines 217-224 require that artifact unconditionally."
    missing:
      - "Serialize one resolution artifact before exit for pass, blocked, cannot-check, and release-event pending/no-op paths, then test each resolver outcome before upload."
---

# Phase 162: Protected Release and Scheduled-Control Recovery Verification Report

**Phase Goal:** Maintainers can explain and safely disposition the blocked release state while existing release and repository controls report only truthful, bounded outcomes.
**Verified:** 2026-08-22T19:35:16Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Reconcile PR #222, commits/checks, tags, Hex versions, and the target ledger into one evidence-backed narrative. | ✓ VERIFIED | `162-RELEASE-RECONCILIATION.md` is append-only, has timestamped source/evidence/disposition matrices, and the parser-backed reconciliation contract passed. It keeps candidate, published, WT-03, tag, Hex, and recovery identities distinct. |
| 2 | Every scoped PR, stale release branch, and check has a safe disposition; none is auto-merge-armed in unexplained limbo. | ✓ VERIFIED | The final disposition table gives each scoped identity one retain/retire/protected-path outcome; `release-please.yml:623-629` keeps ordinary auto-merge disarmed. The reconciliation contract's singular-disposition and sentinel tests passed. |
| 3 | Release-please emits a truthful bounded proposal-only result for control and schedule paths, without expanded release authority. | ✗ FAILED | The authority boundary remains narrow, but capture's line-487 EXIT trap replaces the line-453 output trap. On every path reaching worktree creation, `result_status`, identity fields, and `captured` are never emitted; the following writer defaults to `cannot-check`, including for actual success or known mismatch. |
| 4 | Repository hygiene reports pass, blocked, or cannot-check consistently in CLI, summary, JSON, and retained evidence, with control and observed schedule provenance kept distinct. | ✓ VERIFIED | `audit/1` produces one three-state result map; the workflow pipes its JSON to `repo-hygiene.json` and renders summary fields with `jq` from that same file. The reconciliation documents distinct historical `workflow_dispatch` and `schedule` rows and correctly leaves post-change protected-remote observations `pending`, not substituted with manual proof. |
| 5 | Post-publish uses only the exact immutable target and provides bounded blocked/inapplicable evidence without `main` fallback or forced publication. | ✗ FAILED | The target checks remain exact and the scheduled unpublished branch writes a correct blocked record, but all other resolver outcomes create no `post-publish-resolution.json`. The unconditional `if-no-files-found: error` upload then fails successful dispatch/completed schedule and release-event no-op paths before downstream proof can run. |

**Score:** 3/5 truths verified.

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `162-RELEASE-RECONCILIATION.md` | Append-only release-state evidence and dispositions | ✓ VERIFIED | Substantive timestamped capture and final provenance records; data is evidence-backed rather than a placeholder. |
| `test/scripts/phase_162_release_reconciliation_test.exs` | Deterministic ledger contract | ✓ VERIFIED | Eight substantive parser/coverage tests exercise required rows, ordering, outcomes, provenance, and pending states. |
| `.github/workflows/release-please.yml` | Proposal-only result artifact | ✗ STUBBED EXECUTION PATH | File and result writer exist, but the normal capture path is unwired to its output emitter because the later EXIT trap replaces it. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` + workflow/test | Three-state hygiene result and artifact-first rendering | ✓ VERIFIED | The task owns aggregate status/reason; workflow only consumes the emitted JSON. Focused tests exercise pass, blocked, cannot-check, rendering, and exits. |
| `.github/workflows/post-publish-smoke.yml` + contract test | Exact-target recovery result artifact | ✗ STUBBED EXECUTION PATH | The artifact exists only for one blocked branch while upload requires it for every result. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| GitHub/Git/Hex/Phase 161 inputs | Reconciliation ledger | Timestamped immutable source rows and dispositions | ✓ WIRED | Ledger has source rows and distinct immutable identities; test verifies coverage/order. |
| `.planning/release-target.json` | Reconciliation ledger | Lifecycle/proposal/digest/publication comparison | ✓ WIRED | Ledger explicitly records `authorized` + `publication: not_started` as blocked non-authority. |
| Proposal capture | `release-proposal-control-result.json` | Capture outputs feed result writer | ✗ NOT WIRED | Trap replacement prevents the capture outputs from reaching the writer. |
| Hygiene `audit/1` | JSON, summary, upload | One result map → JSON → `jq` summary/artifact | ✓ WIRED | CLI emits before non-pass exit; workflow reads the saved JSON, not step outcome. |
| Exact resolved post-publish target | `post-publish-resolution.json` → upload | Resolver serializes each outcome before upload | ✗ NOT WIRED | Only the scheduled unpublished branch serializes the file; pass/no-op paths fail required upload. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Reconciliation ledger | Source/evidence/disposition rows | Captured GitHub, Git, Hex, target-ledger, and Phase 161 facts | Yes; time-sensitive unavailable data is explicitly `cannot-check`. | ✓ FLOWING |
| Release proposal result | Capture outputs | `capture-proposal` step → result writer | No; the effective EXIT handler only removes the worktree. | ✗ DISCONNECTED |
| Hygiene result | `%{status, reason, checks}` | `audit/1` → JSON file → summary/upload | Yes; result map is rendered directly. | ✓ FLOWING |
| Post-publish resolution | Resolution JSON | Exact target resolver → required upload | No for pass, completed schedule/dispatch, and no-op paths. | ✗ DISCONNECTED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 162 focused contracts | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors --no-deps-check` | 45 tests, 0 failures (non-failing pre-existing OTLP warnings) | ✓ PASS, but insufficient for the two workflow paths below |
| Proposal capture output publication | Static shell-control-flow trace of `release-please.yml:453,487` | Bash permits one EXIT trap; line 487 replaces `emit_capture_outputs`. | ✗ FAIL |
| Post-publish resolver artifact publication | Trace `post-publish-smoke.yml:117-120,134-154,217-224` | Only one blocked branch writes the required file; other exits reach required upload without it. | ✗ FAIL |

No declared `probe-*.sh` files apply to this phase.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AUTO-01 | 162-01, 162-05 | One evidence-backed release-state narrative | ✓ SATISFIED | Append-only ledger, source coverage, and passing reconciliation contract. |
| AUTO-02 | 162-01, 162-05 | Safe explicit PR/branch/check dispositions | ✓ SATISFIED | Singular disposition/sentinel tests and ordinary auto-merge disarm. |
| AUTO-03 | 162-02, 162-05 | Truthful proposal-only control/schedule result | ✗ BLOCKED | Output-trap replacement makes true capture outcomes report as `cannot-check`; static fixture test never executes capture. |
| AUTO-04 | 162-03, 162-05 | Three-state hygiene JSON/log/summary evidence | ✓ SATISFIED | One result map, artifact-first rendering, focused behavioral tests, and separately recorded historical control/schedule evidence. Post-change schedule remains explicitly pending. |
| AUTO-05 | 162-04, 162-05 | Exact immutable post-publish recovery or bounded blocked/inapplicable result | ✗ BLOCKED | Mandatory upload is incompatible with all resolver outcomes except the scheduled unpublished branch. |

No orphaned Phase 162 requirements were found: every AUTO-01 through AUTO-05 appears in plan frontmatter and was assessed above.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `.github/workflows/release-please.yml` | 487 | Replaces an existing `EXIT` trap | 🛑 BLOCKER | Success/mismatch capture evidence is dropped and misclassified. |
| `.github/workflows/post-publish-smoke.yml` | 217 | Required artifact is not produced on all result paths | 🛑 BLOCKER | Normal/no-op runs fail before downstream immutable-target proof. |
| `test/scripts/release_trigger_recovery_test.exs` | 347 | Isolated result-writer fixture | ⚠️ WARNING | Green test cannot exercise capture's trap replacement. |
| `test/mailglass/publish/post_publish_smoke_contract_test.exs` | 82 | Text-presence contract only | ⚠️ WARNING | Green test does not prove artifact creation on success/no-op paths. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in the phase deliverables. The only `not available` strings are runtime Hex availability messages, not placeholders.

## Human Verification Required

None before code repair. The reconciliation correctly treats protected-remote post-change scheduled observations as `pending`; manual dispatches are not presented as schedule proof. After the two blocker fixes are deployed to protected `main`, the named scheduled observations still need to be collected as follow-up evidence, not retroactively treated as Phase 162 proof.

## Gaps Summary

The evidence ledger and repository-hygiene control are substantive and wired, and they preserve the intended blocked/pending distinction. The two workflows that must carry that truthful bounded behavior through actual Actions execution are not. The passing focused suite is misleading because it tests result fragments and text presence rather than the capture and resolver execution paths. These are two independent BLOCKER gaps, so the phase goal is not achieved.

---

_Verified: 2026-08-22T19:35:16Z_
_Verifier: the agent (gsd-verifier)_
