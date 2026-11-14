---
phase: 178-preview-authoring-and-milestone-review
reviewed: 2026-11-02T22:59:57Z
depth: standard
files_reviewed: 47
files_reviewed_list:
  - .github/workflows/ci.yml
  - mailglass_admin/docs/phase174-review.md
  - mailglass_admin/e2e/axe-baseline.spec.js
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase176-filters.spec.js
  - mailglass_admin/e2e/phase178-real-zoom.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/support/real-zoom.cjs
  - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
  - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/test/mailglass_admin/discovery_test.exs
  - mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
  - mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
  - mailglass_admin/test/support/feedback_ledger.ex
  - mailglass_admin/test/support/fixtures/mailables.ex
  - reference/demo_app/assets/e2e/phase178-stories.spec.js
  - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
  - reference/demo_app/storybook/preview_authoring.story.exs
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
  - scripts/check_phase178_candidate.sh
  - scripts/check_preview_capture_advisory_setup.test.cjs
  - scripts/test_check_phase178_candidate.sh
  - test/mailglass/state_md_contract_test.exs
  - compose.demo.yml
  - scripts/run_demo_browser_evidence.sh
  - scripts/test_run_demo_browser_evidence.sh
  - scripts/phase178_cost_disposition.cjs
  - scripts/phase178_cost_disposition.test.cjs
  - test/scripts/ci_node_test_requires_contract_test.exs
  - test_js/support/ci-require-guard.cjs
  - mailglass_admin/e2e/support/storybook-axe-supplement.cjs
  - test/scripts/phase_164_closeout_test.exs
  - mailglass_admin/test/mailglass_admin/browser_server_readiness_test.exs
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_browser_server.ex
  - reference/demo_app/assets/e2e/quick-views.spec.js
  - test/scripts/workspace_evidence_contract_test.exs
  - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
  - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
  - mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs
  - mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
recheck:
  reviewed: 2026-11-02T23:25:29Z
  depth: standard
  files_reviewed: 4
  files_reviewed_list:
    - scripts/check_phase178_candidate.sh
    - scripts/test_check_phase178_candidate.sh
    - scripts/phase178_cost_disposition.cjs
    - scripts/phase178_cost_disposition.test.cjs
  findings:
    critical: 0
    warning: 0
    info: 0
    total: 0
  status: clean
---

# Phase 178: Code Review Report

**Reviewed:** 2026-11-02T22:59:57Z  
**Depth:** standard  
**Files Reviewed:** 47  
**Status:** issues_found

## Summary

The top-level review metadata preserves the original 47-file review snapshot. The latest scoped recheck covers the four Phase 178 candidate-preview and cost-disposition files at `recheck.files_reviewed_list`; it found no remaining issues. Earlier findings and their original evidence remain below for disposition traceability.

## Scoped Recheck Outcomes

| Prior finding | Recheck result | Current evidence |
|--------------|----------------|------------------|
| CR-01: redirects can leave candidate origin | Fixed for initial routes and route, HTML, and CSS redirects. Custom routes must be root-relative paths and are origin-checked before the first request (`scripts/check_phase178_candidate.sh:122-160`); curl redirect following is disabled and each redirect is checked and bounded (`:92-119,163-200`). Both `/dev/mail` and the versioned CSS probe use this helper (`:807-812`). |
| CR-02: missing expected counts can pass | Fixed. Expected operator/demo objects must contain every required count, and the demo receipt must contain exactly one complete cold and warm condition (`scripts/phase178_cost_disposition.cjs:345-389`). |
| CR-03: teardown trusts editable record fields | Fixed. Teardown verifies the record against a private marker before reading cleanup fields or performing Git/Docker operations (`scripts/check_phase178_candidate.sh:349-413,486-500`). |
| CR-04: failed cleanup can report success and discard recovery files | Fixed. Every project-labeled container, volume, and network list/removal is checked and followed by an absence query; any command or verification failure retains the worktree and run directory (`scripts/check_phase178_candidate.sh:515-590`). |
| WR-01: teardown globally prunes worktrees | Fixed. The launcher contains no `git worktree prune`; it removes only the named candidate worktree (`scripts/check_phase178_candidate.sh:583-594`). The offline contract checks the absence of global prune (`scripts/test_check_phase178_candidate.sh:427-428`). |
| CR-05: self-consistent fabricated counts pass disposition | Fixed. The disposition API recomputes counts from the operator log, demo receipt, and complete expected-count input; the CLI hashes all three (`scripts/phase178_cost_disposition.cjs:421-449,557-584,684-731`). Regression cases reject precomputed counts and prove a forged report cannot override counts derived from the raw inputs (`scripts/phase178_cost_disposition.test.cjs:459-520`). |
| CR-06: custom route can target a different origin on first request | Fixed. Only single-slash root-relative routes are accepted and the resolved URL is checked against the candidate origin before curl runs (`scripts/check_phase178_candidate.sh:122-160`). Offline regression cases verify `@host`, absolute, network-path, backslash, and control-character inputs cause zero requests (`scripts/test_check_phase178_candidate.sh:229-250`). |
| Test fixture cleanup scope | Safe. Cleanup only considers paths tracked from three `mktemp -d /tmp/mailglass-phase178.XXXXXXXX` calls; it accepts the `/tmp` and macOS `/private/tmp` forms, validates the exact generated basename, and refuses symlinks before `rm -rf` (`scripts/test_check_phase178_candidate.sh:17-29,354-396`). |

The current scoped recheck has **0 BLOCKER findings and 0 WARNING findings**. The orchestrator reports that the offline launcher test passed all 19 checks and left no `mailglass-phase178.*` fixture directories; this final recheck reviewed the cleanup-helper change by inspection and did not rerun tests, Docker, network requests, or hosted CI.

## Narrative Findings (AI reviewer)

The two findings below are retained from the 23:16 scoped review for traceability. The latest scoped review verified both fixes; neither remains open.

### CR-05: Self-consistent fabricated counts pass the disposition gate

**Severity:** BLOCKER  
**File:** `scripts/phase178_cost_disposition.cjs:575-610,617-650,755-757`  
**Issue:** `requirePrecomputedCounts` verifies that the supplied `mismatch` flag and `mismatches` array agree with the supplied `expected` and `executed` values, but it does not bind those values to the operator log, demo cost receipt, or expected-count source from which `deriveCounts` is supposed to calculate them. The disposition CLI accepts an arbitrary `--counts` JSON file and only hashes that file. Changing both sides of a comparison to matching values (and setting an empty mismatch list) therefore passes validation even when the actual source evidence differs. The new test only changes `expected.passed` without changing `executed.passed` (`scripts/phase178_cost_disposition.test.cjs:464-467`), so it does not exercise a self-consistent forgery.
**Fix:** Have disposition consume the operator log, demo cost receipt, and expected-count file and recompute counts with `deriveCounts`; alternatively, bind the precomputed counts to hashes of those exact source inputs and verify the binding before accepting them.

### CR-06: A custom route can bypass the loopback origin check on its first request

**Severity:** BLOCKER  
**File:** `scripts/check_phase178_candidate.sh:126-139,639-644`  
**Issue:** `probe_route` forms the first request URL by concatenating `base_url` and the unvalidated route, then sends it directly to curl. For example, `--route @127.0.0.1:5001/collect` forms `http://127.0.0.1:5000@127.0.0.1:5001/collect`; URL parsing treats the candidate address as user-info and targets port 5001. The probe cookie jar is shared across ports, so the request can send the synthetic session cookie to another local service. Redirect validation only runs after a response and does not protect this initial request.
**Fix:** Accept only path-only route values and validate the fully assembled URL's scheme, host, and port against `base_url` before every curl invocation. Add an offline case proving an `@host` route is rejected without issuing a request.

## Historical Findings (initial 47-file review; retained for disposition traceability)

The five findings below preserve their original text, IDs, and evidence. The scoped outcomes above are the current status: CR-01 through CR-06 and WR-01 are fixed.

## Initial Narrative Findings (historical; 47-file review)

### CR-01: Candidate route probes follow redirects outside the loopback origin

**Severity:** BLOCKER  
**File:** `scripts/check_phase178_candidate.sh:99-107`
**Issue:** `probe_route` enables automatic redirect following with `curl --location` and returns only the final status and URL. Its caller at line 523 accepts any final HTTP 200 without comparing the effective URL to `BASE_URL`. A candidate response can therefore send the probe to an external host or another loopback port and still satisfy the route check. This also lets the locally run preview probe reach unrelated local services; cookies are scoped by host/path, not port, so another service on `127.0.0.1` may receive the synthetic session cookie.
**Fix:** Disable automatic redirects (`--max-redirs 0`), parse each `Location`, and follow only a bounded chain whose scheme, hostname, and port exactly match the candidate `BASE_URL`. Reject cross-origin redirects before making the next request.

### CR-02: Missing expected counts produce a passing count gate

**Severity:** BLOCKER  
**File:** `scripts/phase178_cost_disposition.cjs:361-399`
**Issue:** `compareCounts` returns no mismatches when `expected` is absent, and `deriveCounts` defaults missing expected input to `{}`. An empty `demoCost.conditions` array also passes the current `Array.isArray` check and produces `demo.mismatch: false`. The Phase 178 preview eligibility check accepts `counts.operator.mismatch === false` and `counts.demo.mismatch === false`, so incomplete count evidence can be treated as a match even though no expected values or demo conditions were compared.
**Fix:** Validate that expected operator/demo count objects contain the required keys and that the cost receipt contains every required condition before deriving a disposition. Make missing comparisons fail closed (for example, return a mismatch/error unless at least one required count was compared for each category).

### CR-03: Teardown trusts editable record fields as ownership proof

**Severity:** BLOCKER  
**File:** `scripts/check_phase178_candidate.sh:289-302`
**Issue:** Teardown accepts any JSON record whose `compose_project` matches the broad Phase 178 prefix and whose `run_parent`/`worktree` match the expected path shape. It does not prove that those fields were generated together by this run or match an ownership marker in that run directory. Editing a valid record's project to another active `mailglass-phase178-review-*` project makes teardown stop that other candidate while removing the first record's worktree and run directory. This breaks the candidate-only cleanup boundary.
**Fix:** Write a run-ownership marker when creating the candidate, binding the project, source SHA, run identifier, and canonical run/worktree paths. Before any Docker or Git mutation, validate every record field against that marker and reject records with mismatched or missing bindings.

### CR-04: Label-sweep cleanup can report success after Docker operations fail

**Severity:** BLOCKER  
**File:** `scripts/check_phase178_candidate.sh:325-340`
**Issue:** When the candidate worktree is already absent, `docker ps`, `docker rm`, volume listing/removal, and network removal errors are suppressed with `|| true`. The code then records `compose_down` as `label-sweep` unconditionally. Since the final check at lines 373-375 fails only when a disposition is explicitly `failed`, teardown can print “complete” and return success while candidate containers, volumes, or network remain. It also removes the run parent at lines 354-355, discarding the compose file needed for normal recovery.
**Fix:** Treat every failed Docker query/removal as a failed disposition, verify that no containers, project volumes, or project network remain before reporting success, and retain the run directory/configuration whenever cleanup has not been verified.

### WR-01: `git worktree prune` mutates registrations beyond this candidate

**Severity:** WARNING  
**File:** `scripts/check_phase178_candidate.sh:352,440-441`
**Issue:** Both teardown and failed pre-Compose cleanup invoke repository-wide `git worktree prune`. That can remove stale metadata registrations belonging to unrelated worktrees, despite the phase's candidate-only cleanup boundary; neither call is needed to remove the explicitly named candidate worktree.
**Fix:** Remove the global prune calls. If cleanup needs to repair metadata, operate only on the task's exact worktree and report any unresolved Git metadata instead of pruning every registration.

---

_Initial review: 2026-11-02T22:59:57Z_  
_Latest scoped recheck: 2026-11-02T23:25:29Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
