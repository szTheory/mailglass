---
phase: 162-protected-release-and-scheduled-control-recovery
verified: 2026-08-22T20:53:16Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Proposal capture now preserves its real outputs through post-worktree cleanup and feeds them to the proposal-control artifact."
    - "Post-publish now writes one resolution artifact before the mandatory upload for its supported pass, blocked, cannot-check, and release-event paths."
  gaps_remaining:
    - "Release-please has no truthful successful pending outcome for an idle scheduled run with no proposal."
    - "Repo-hygiene cannot identify the CI branch from its scheduled detached-HEAD checkout."
  regressions:
    - "The repaired proposal-result workflow still converts the normal empty-proposal schedule case into a failed blocked result."
    - "The scheduled hygiene workflow passes an empty detached-HEAD branch to gh run list."
gaps:
  - truth: "Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority."
    status: failed
    reason: "Every digest-free schedule bypasses preflight discovery and runs capture; when no proposal exists, capture emits blocked/proposal_missing and the final non-pass step fails. The documented pending path only applies when capture is skipped, which this branch never does."
    artifacts:
      - path: ".github/workflows/release-please.yml"
        issue: "Lines 92-95 set should_run=true for an empty candidate digest; lines 474-477 classify the ordinary idle state as proposal_missing; lines 613-618 fail the artifact."
      - path: "test/scripts/release_trigger_recovery_test.exs"
        issue: "run_preflight/3 injects a nonempty candidate digest by default, so no executable test covers empty digest plus no open proposal."
    missing:
      - "Discover whether a schedule has an open proposal before capture; for an idle schedule, emit a successful pending bounded result and add an executable empty-digest/no-proposal fixture."
  - truth: "Repository-hygiene reports an inspectable pass, policy block, or cannot-check outcome with agreeing logs and JSON evidence, including control and applicable scheduled-run proof."
    status: failed
    reason: "The scheduled workflow uses a detached checkout, yet ci_state/1 obtains git branch --show-current and passes that empty value to gh run list --branch. It cannot reliably find the CI run for the checked-out SHA, so normal scheduled hygiene cannot supply the intended truthful CI verdict."
    artifacts:
      - path: "dev/mix/tasks/mailglass.repo.hygiene.ex"
        issue: "Lines 160-180 derive an empty detached-HEAD branch and use it as the gh --branch selector."
      - path: ".github/workflows/repo-hygiene.yml"
        issue: "The schedule checkout is detached and supplies neither the repository default branch nor a commit-based CI query input."
      - path: "test/mix/tasks/mailglass.repo.hygiene_test.exs"
        issue: "The gh fixture returns a matching run independently of arguments; it has no detached-HEAD integration case."
    missing:
      - "Pass the default branch explicitly or query CI by the checked-out SHA and validate headSha; add a detached-HEAD scheduled fixture."
---

# Phase 162: Protected Release and Scheduled-Control Recovery Verification Report

**Phase Goal:** Maintainers can explain and safely disposition the blocked release state while existing release and repository controls report only truthful, bounded outcomes.
**Verified:** 2026-08-22T20:53:16Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A maintainer can reconcile PR #222, its commits/checks, tags, Hex versions, and the target ledger into one evidence-backed narrative. | ✓ VERIFIED | [`162-RELEASE-RECONCILIATION.md`](162-RELEASE-RECONCILIATION.md) retains timestamped source, identity, observation, and disposition rows; its eight parser/coverage tests exercise required sources and stable ordering. |
| 2 | Every scoped PR, stale release branch, and check has a safe disposition; none is auto-merge-armed in unexplained limbo. | ✓ VERIFIED | The ledger gives each scoped item one protected-merge/retire/retain outcome or named recovery condition. `release-please.yml:629-638` explicitly disarms ordinary auto-merge, while protected merge remains guarded by the exact-digest dispatch. |
| 3 | Release-please gives a truthful proposal-only result through its control and scheduled entry points without gaining release authority. | ✗ FAILED | The Plan 06 trap/output defect is repaired and its pass/mismatch fixture is substantive, but an ordinary idle schedule is forced through capture and ends as failed `blocked/proposal_missing`, not its documented pending result. |
| 4 | Repository-hygiene reports pass, blocked, or cannot-check consistently in CLI, summary, JSON, and retained evidence, with control and applicable scheduled provenance kept distinct. | ✗ FAILED | The one-result-map JSON/summary wiring is correct, but scheduled `actions/checkout` is detached while `ci_state/1` queries `gh run list --branch ""`; scheduled CI evidence cannot be reliably determined. |
| 5 | Post-publish uses only the exact immutable target and provides bounded blocked/inapplicable evidence without `main` fallback or forced publication. | ✓ VERIFIED | Plan 07 initializes/finalizes the resolution artifact for schedule, protected dispatch, blocked, cannot-check, and release no-op paths before the mandatory upload. The executable resolver fixtures cover pass, blocked, cannot-check, and pending; no fallback target is selected. |

**Score:** 3/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `162-RELEASE-RECONCILIATION.md` + reconciliation test | Evidence-backed release/disposition ledger | ✓ VERIFIED | Substantive append-only matrices, timestamped capture, exact identities, and deterministic coverage tests. |
| `.github/workflows/release-please.yml` + recovery test | Bounded proposal-only result for control and schedule | ⚠️ PARTIAL | Post-worktree result emission is wired and exercised, but idle schedules remain incorrectly forced to a failing blocked result. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` + workflow/test | Three-state hygiene result, JSON, summary, and scheduled proof | ⚠️ PARTIAL | Aggregate/rendering contract is substantive and artifact-first; detached scheduled CI lookup is not wired to a valid branch or SHA selector. |
| `.github/workflows/post-publish-smoke.yml` + contract test | Exact-target resolution result before upload | ✓ VERIFIED | One serializer/write path exists for every supported resolver outcome; summary/upload consume the saved JSON. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| GitHub/Git/Hex/target inputs | Reconciliation ledger | Timestamped immutable source rows | ✓ WIRED | Captured evidence and parser contract retain distinct candidate, ledger, published, tag, and Hex identities. |
| Capture proposal shell | `steps.capture-proposal.outputs` → proposal result JSON | One guarded `EXIT` handler emits after cleanup | ✓ WIRED | `cleanup_and_emit_capture_outputs` at `release-please.yml:454-463` preserves status and fixture exercises pass/mismatch serialization. |
| Empty-digest schedule | Proposal result JSON | Preflight → capture → writer | ✗ NOT WIRED | Empty digest always sets `should_run=true`; the writer's pending branch only handles a skipped capture. |
| `audit/1` result map | JSON → Actions summary/upload | Same serialized result | ✓ WIRED | `repo-hygiene.yml:46-68` pipes JSON, renders it with `jq`, and uploads it. |
| Scheduled checkout SHA | Hygiene CI query | Branch/commit selector → `gh run list` | ✗ NOT WIRED | Detached HEAD yields an empty branch selector at `mailglass.repo.hygiene.ex:160-180`. |
| Trigger/resolver | `post-publish-resolution.json` → summary/upload | Initial/final resolution serializer | ✓ WIRED | Classification writes pending/cannot-check and resolver finalizes truthfully before the mandatory upload. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Reconciliation ledger | Evidence/disposition rows | GitHub/Git/Hex/ledger capture or explicit cannot-check | Yes | ✓ FLOWING |
| Proposal result | Capture status and identities | Capture shell → GitHub outputs → result writer | Yes for pass/mismatch; no truthful idle-schedule classification | ⚠️ PARTIAL |
| Hygiene result | `%{status, reason, checks}` | `audit/1` → JSON → summary/artifact | Yes for local/control inputs; scheduled CI query lacks a valid selector | ⚠️ PARTIAL |
| Post-publish resolution | Resolution JSON | Classification/resolver → summary/upload | Yes; each supported test fixture materializes the result | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 162 focused contracts | `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors --no-deps-check` | Completed without a reported test failure; emitted only known runtime OTLP-exporter warnings. | ✓ PASS |
| Capture after worktree creation | Executable fixture at `release_trigger_recovery_test.exs:398` | Pass and identity-mismatch paths emit actual outputs, remove worktree, and produce matching JSON. | ✓ PASS |
| Post-publish artifact coverage | Executable fixtures at `post_publish_smoke_contract_test.exs:113,162` | Pending/no-op, pass, blocked, and cannot-check paths write one decodable artifact. | ✓ PASS |
| Idle release schedule | Static control-flow trace of `release-please.yml:92-95,474-477,613-618` | Empty digest enters capture; absent proposal becomes non-pass blocked rather than pending. | ✗ FAIL |
| Scheduled hygiene CI lookup | Static runtime trace of detached checkout plus `mailglass.repo.hygiene.ex:160-180` | Empty `git branch --show-current` reaches `gh run list --branch`. | ✗ FAIL |

No declared `probe-*.sh` files apply to this phase.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AUTO-01 | 162-01, 162-05 | Evidence-backed release-state narrative | ✓ SATISFIED | Reconciliation ledger and focused parser/coverage contract. |
| AUTO-02 | 162-01, 162-05 | Safe explicit PR/branch/check dispositions | ✓ SATISFIED | Singular disposition/empty-category checks and ordinary auto-merge disarm. |
| AUTO-03 | 162-02, 162-05, 162-06 | Truthful proposal-only control/schedule result without authority expansion | ✗ BLOCKED | Capture output repair is real, but normal idle schedules are forced to failing `proposal_missing`; no empty-digest/no-proposal test exists. |
| AUTO-04 | 162-03, 162-05 | Inspectable three-state hygiene result with control/scheduled evidence | ✗ BLOCKED | JSON/summary agreement is proven, but scheduled detached-HEAD CI lookup cannot reliably find the checked-out commit's CI evidence. |
| AUTO-05 | 162-04, 162-05, 162-07 | Exact immutable post-publish proof or bounded blocked/inapplicable outcome | ✓ SATISFIED | Artifact-first resolver behavior is executable across all declared outcomes; no `main` fallback or forced publication. |

No orphaned Phase 162 requirements were found: all AUTO-01 through AUTO-05 occur in plan frontmatter and are assessed above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.github/workflows/release-please.yml` | 92-95, 474-477, 613-618 | Idle schedule has no pending branch and is made a failing block | 🛑 BLOCKER | Expected absence is reported as a failed control rather than a bounded scheduled observation. |
| `test/scripts/release_trigger_recovery_test.exs` | 811-814 | Helper supplies a candidate digest by default | ⚠️ WARNING | Green preflight tests omit the empty-digest/no-proposal scheduled path. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | 160-180 | Empty detached-HEAD branch used for CI lookup | 🛑 BLOCKER | Scheduled hygiene cannot reliably establish its CI state. |
| `test/mix/tasks/mailglass.repo.hygiene_test.exs` | 269-275 | `gh` fake ignores requested branch/commit | ⚠️ WARNING | Green test does not model scheduled detached-HEAD behavior. |
| `.github/workflows/post-publish-smoke.yml` | 327, 350-385 | Eight-minute job contains three serial five-minute waits | ⚠️ WARNING | The immutable pass path may be hard-timed-out before its documented polling allowances complete. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | 321-328 | Stale branches are always informational pass | ⚠️ WARNING | A stale inventory cannot affect readiness; policy intent should be clarified or enforced. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in phase-delivered code. The `not available` messages in post-publish are real Hex availability diagnostics, not placeholders.

### Human Verification Required

After the two blocker repairs are deployed to protected `main`, observe each applicable scheduled run and retain its JSON artifact, summary, event name, run ID, and workflow SHA. This is external GitHub Actions behavior and cannot be proven by local fixtures. The existing ledger correctly keeps the current post-change scheduled observations as `pending`; manual dispatches must not be substituted.

### Gaps Summary

The original two gap-closure plans successfully repaired the proposal-capture output trap and the missing post-publish artifacts. However, the advisory review exposed two independently observable scheduled-control failures that the green focused suite does not cover. Because AUTO-03 and AUTO-04 both require truthful scheduled behavior, these are BLOCKER gaps and the phase goal is not achieved.

The post-publish polling timeout and stale-branch classification are warnings: they require follow-up but are not used to turn the two failed roadmap truths into a pass.

---

_Verified: 2026-08-22T20:53:16Z_
_Verifier: the agent (gsd-verifier)_
