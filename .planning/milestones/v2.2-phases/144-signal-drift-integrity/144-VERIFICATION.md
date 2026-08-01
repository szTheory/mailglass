---
phase: 144-signal-drift-integrity
verified: 2026-07-31T21:54:42Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 144: Signal & Drift Integrity Verification Report

**Phase Goal:** Every remaining automated check in this pipeline reports a status a maintainer can trust without reading its logs — a check that cannot do its job never reports success, the icon-existence gate covers the class of bug it claims to prevent (not just the two historical instances), and the publish/release machinery cannot report a false failure on a release that actually shipped.

**Verified:** 2026-07-31T21:54:42Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Branch-protection advisory, scheduled reassertion, and repo hygiene distinguish clean, observed drift, and unavailable verification; only clean succeeds. | ✓ VERIFIED | `branch-protection-outcome.sh` has a closed `clean`/`drift`/`cannot_check` classifier and a reporter whose only zero exit is `clean`; both workflows invoke it through `if: always()` reporters. `Repo.Hygiene.branch_protection/1` emits `:pass`, `:blocked`, or `:unknown`, and `status/1` permits aggregate pass only when every check is `:pass`. Hermetic fake-`gh` tests cover missing token, `gh`, `jq`, API failure, drift, and clean paths. |
| 2 | A daily scheduled job compares live protection against canonical desired state before owner-only reassertion, and required context identity is the display name. | ✓ VERIFIED | `branch-protection-drift.yml` retains `37 6 * * *` and invokes `probe --reassert main`; the real outcome seam calls `verify-branch-protection.sh` before `setup_branch_protection.sh` only after observed drift. The focused test verifies GET-before-PUT with fake `gh`; `required_checks_test.exs` parses and compares `Guard Release Trigger`, rejecting the YAML id. |
| 3 | Branch Protection Advisory remains publish-gating, not a CI Green or advisory-bucket input. | ✓ VERIFIED | `Mailglass.CILanes.publish_gating_lanes/0` contains the display name while the parsed `ci_green` job excludes `branch_protection_advisory`; both are asserted in `branch_protection_truth_test.exs`. |
| 4 | A genuinely computed missing icon fails the real icon gate, bounded finite constructions compare against the vendored inventory, unresolved dynamic expressions fail closed, and fixtures are removed. | ✓ VERIFIED | The real `check-conformance.sh` unions literal scans with `extract_dynamic_icon_references`, normalizes names, and diffs them against `heroicons-inline.js` via `comm -23`. The isolated real-gate harness proves a non-contiguous `"hero-" <> "missing-computed"` value reports `hero-missing-computed`, finite concatenation/interpolation of vendored names pass, and assign/map/helper/unbounded expressions are explicitly non-green. Every fixture registers cleanup before writes and asserts removal. |
| 5 | The normal admin source tree passes the same icon-conformance command after negative controls. | ✓ VERIFIED | `bash mailglass_admin/scripts/check-conformance.sh` exited 0 in this verification: `OK: design-system conformance clean.` |
| 6 | Publish and post-publish smoke share one static, non-cancelling concurrency group. | ✓ VERIFIED | Both workflow top-level blocks specify `group: mailglass-linked-release-fanout` and `cancel-in-progress: false`; the source contract rejects the prior ref/tag-scoped forms and requires exactly one block in each file. |
| 7 | All three package publish paths treat an already-published release as successful, explicit no-op work. | ✓ VERIFIED | `publish-core`, `publish-admin`, and `publish-inbound` each use `mix hex.info ... | grep Released:`, output `skip=true`, guard publishing on that output, and log “Nothing to do”. The contract parser requires every one of these pieces. |
| 8 | Release-please recovery stays hourly, manual, and push-triggered; it runs only when every expected release is absent and fails closed on incomplete or inaccessible state. | ✓ VERIFIED | `release-please.yml` retains push, `workflow_dispatch`, and `17 * * * *`; checkout precedes a manifest-derived preflight. Only explicit HTTP 404 is absent, partial tags and 403/API/label errors exit nonzero, while all-present or `autorelease: tagged` writes `should_run=false`. Fake-`gh` execution tests all cases. |
| 9 | Maintainers can discover the bounded recovery delay, symptoms, automatic recovery, and manual fallback. | ✓ VERIFIED | `CONTRIBUTING.md`’s “If a release publishes but the tags/publish never fire” documents minute 17, up-to-one-hour delay, the pending/tag symptoms, idempotent all-present behavior, deliberate partial-state failure, `workflow_dispatch`, and final manual release fallback; the recovery contract parses this section. |
| 10 | No unavailable branch-protection prerequisite is mislabeled as verified drift or allowed to aggregate to hygiene pass. | ✓ VERIFIED | Focused hygiene tests exercise missing verifier, no `gh`, no `GH_TOKEN`, 403/non-`DRIFT:` output, drift, clean text, and clean JSON. The implementation classifies only output beginning `DRIFT:` as `:blocked`; all other failures are `:unknown`, and either status yields aggregate `:blocked`. |
| 11 | Workflow/source contract parsers fail loudly rather than passing on an empty or missing block. | ✓ VERIFIED | Branch, context, concurrency, and release-recovery tests use bounded extractors with nonempty/exact-count assertions plus in-memory negative controls. `mix verify.ci_lane_contract` passed 141 tests. |
| 12 | Phase 144 introduces no new workflow, registry, package identity, public API, or external integration. | ✓ VERIFIED | Direct source and workflow review shows one internal shell seam, existing workflow edits, existing CLI semantics, and test harnesses only. No new workflow or desired-state registry exists; release, branch-protection, icon inventory, and package identities remain the existing ones. |

**Score:** 12/12 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/branch-protection-outcome.sh` | Shared closed outcome classifier/reporter | ✓ VERIFIED | 104 substantive lines; both workflows call it; hermetic probe/reassert tests execute it with real verifier/setup scripts and fake `gh`. |
| `.github/workflows/ci.yml` | Honest Branch Protection Advisory result | ✓ VERIFIED | PAT absence supplies `cannot_check`; verifier output is captured; the always-run reporter determines the visible conclusion. |
| `.github/workflows/branch-protection-drift.yml` | Scheduled read-only check then owner reassertion | ✓ VERIFIED | Daily cron and `probe --reassert` path are present; read-only verifier precedes possible mutation. |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | Honest three-state branch-protection subcheck | ✓ VERIFIED | Uses canonical verifier, specific prerequisite remediation, and all-pass aggregate rule. |
| `mailglass_admin/scripts/check-conformance.sh` | Dynamic icon inventory enforcement | ✓ VERIFIED | Substantive extractor, zero-scan guard, unresolved-expression failure, vendored-key extraction, and `comm -23` comparison. |
| `.github/workflows/publish-hex.yml` / `post-publish-smoke.yml` | Shared release serialization | ✓ VERIFIED | Equal static groups, cancellation disabled, and source contract tested. |
| `.github/workflows/release-please.yml` / `CONTRIBUTING.md` | Fail-closed recovery plus durable operational runbook | ✓ VERIFIED | Manifest/HTTP/partial-state checks are executable under fake `gh`; documentation contract parses the runbook. |
| Phase regression tests | Hermetic evidence for every seam | ✓ VERIFIED | 43 focused tests passed: branch/context/icon/concurrency/recovery/hygiene. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `ci.yml` / `branch-protection-drift.yml` | `scripts/branch-protection-outcome.sh` → canonical verify/setup scripts | workflow probe and always-run report | ✓ WIRED | The indirect shared seam supersedes the plan’s direct grep pattern; direct source and E2E tests prove the chain. |
| Repo hygiene | `scripts/verify-branch-protection.sh` | `branch_protection/1` command result | ✓ WIRED | Path is joined from the repository root and invoked through `cmd/3`; outcome tests execute substitute scripts. |
| Icon gate | vendored Heroicons | normalized set difference | ✓ WIRED | Real script writes normalized used and available sets then executes `comm -23`; fixture invokes a copied real script. |
| Publish workflow | smoke workflow | equal static concurrency group | ✓ WIRED | Both exact blocks are parsed and equality-tested. |
| Release recovery test and runbook | `release-please.yml` | extracted preflight/triggers/docs contracts | ✓ WIRED | Tests execute extracted preflight shell under fake `gh` and parse the runbook section. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Branch outcome seam | classification | canonical live verifier stdout/status and environment prerequisites | `clean`, `drift`, or `cannot_check`; fake-`gh` integration proves each producer path | ✓ FLOWING |
| Repo hygiene | `branch_protection` result | canonical verifier process result | Actual output is the sole distinction between drift and unknown | ✓ FLOWING |
| Icon gate | used/available icon sets | admin source and vendored `heroicons-inline.js` | Real fixture inventory/source flow reaches `comm -23` | ✓ FLOWING |
| Release preflight | expected/present/missing tags | checked-out manifest and repository-qualified GitHub API responses | Fake HTTP 200/404/403/API results prove divergent paths | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| All Phase 144 regression contracts | `mix test test/scripts/branch_protection_truth_test.exs test/scripts/required_checks_test.exs test/scripts/icon_exists_gate_test.exs test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs --warnings-as-errors` | 43 tests, 0 failures | ✓ PASS |
| CI lane source contracts | `mix verify.ci_lane_contract` | 141 tests, 0 failures | ✓ PASS |
| Mix task contracts | `mix verify.mix_tasks` | 56 tests, 0 failures | ✓ PASS |
| Real admin conformance gate | `bash mailglass_admin/scripts/check-conformance.sh` | Exit 0; clean | ✓ PASS |
| Shell/workflow syntax and formatting | `bash -n …`, `mix format --check-formatted`, `actionlint …`, `shellcheck …` | All exit 0 | ✓ PASS |

### Probe Execution

No `scripts/**/tests/probe-*.sh` probe was declared or exists for this phase. The required negative controls are hermetic ExUnit subprocesses and were executed in the focused Phase 144 regression command above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| CONFORM-02 | 144-03 | ICON-EXISTS-GATE covers computed/dynamic icon bug class | ✓ SATISFIED | Real-gate fixtures prove computed-missing rejection, clean finite computation, unresolved fail-closed behavior, and cleanup. |
| TRUTH-02 | 144-01 | Cannot-check branch-protection workflows never report success | ✓ SATISFIED | Closed outcome seam, always-run reporters, and fake-CLI path coverage. |
| TRUTH-03 | 144-01 | Scheduled canonical protection check and display-name identity guard | ✓ SATISFIED | Verify-before-reassert E2E and parsed `Guard Release Trigger` negative control. |
| TRUTH-04 | 144-05 | Release anti-recursion recovery fixed/documented | ✓ SATISFIED | Hourly/manual preflight contract, fail-closed fake-API cases, and runbook. |
| TRUTH-06 | 144-02 | Repo hygiene separates drift from cannot-check | ✓ SATISFIED | Exact `DRIFT:` classifier and exhaustive prerequisite/API outcome tests. |
| TRUTH-08 | 144-04 | Linked publish fan-out cannot self-race into false failure | ✓ SATISFIED | Static shared concurrency and three package idempotency contracts. |

All six requirement IDs are declared across Phase 144 plans and map to this phase in `REQUIREMENTS.md`; no orphaned Phase 144 requirement was found.

### Anti-Patterns Found

None. No `TBD`, `FIXME`, or `XXX` debt marker appears in the Phase 144 implementation artifacts. No empty implementation, hardcoded historical icon allowlist, orphaned workflow, false-green unavailable path, or unchecked dynamic data source was found.

### Gaps Summary

No gaps found. The passing tests are not accepted as summary claims: the verifier independently executed the complete hermetic regression set and traced all runtime-relevant workflow/data paths. The intentionally strict icon behavior is fail-closed for non-finite assign/map/helper expressions and accepts only finite resolved constructions, so those forms cannot silently evade the icon inventory gate.

---

_Verified: 2026-07-31T21:54:42Z_  
_Verifier: the agent (gsd-verifier)_
