---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-01T14:15:47Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .gitignore
  - .gsd/extensions/finalize-phase/extension-manifest.json
  - .gsd/extensions/finalize-phase/index.ts
  - MAINTAINING.md
  - README.md
  - config/test_exceptions.exs
  - mailglass_admin/README.md
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_inbound/README.md
  - scripts/ci_monitor.cjs
  - scripts/closeout_repository_truth.sh
  - scripts/finalize_phase_164.sh
  - scripts/scheduled_control_evidence.sh
  - scripts/validate_repository_truth.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test_js/ci-monitor.test.cjs
findings:
  critical: 6
  warning: 1
  info: 0
  total: 7
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-01T14:15:47Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The phase adds useful exact-SHA and provenance checks, but the terminal closeout boundary is not yet safe to ship. Predictable ignored paths can redirect writes through symlinks, repository identity is not pinned to the authoritative GitHub repository, protected `main` is not revalidated at the final decision point, and two claimed authority validators accept incomplete or fabricated evidence. Public admin installation guidance also makes the documented production surface unavailable, while version-contract prose remains stale.

Focused shell syntax and Node tests passed. Adversarial probes additionally proved that the scheduled predicate accepts a one-control sweep and that the ledger validator returns `:ok` after tracked-state and evidence fields are replaced with fabricated values.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Predictable ignored component paths allow arbitrary writes through symlinks

**Classification:** BLOCKER
**File:** `scripts/closeout_repository_truth.sh:73-106`
**Issue:** The script reuses a predictable ignored `components` directory, accepts an existing `components` symlink via `mkdir -p`, and redirects command output to predictable leaf names. A stale or malicious ignored path such as `tmp/phase-164-closeout/components -> /some/writable/directory`, or a symlinked `git.source`, causes the supposedly read-only closeout to overwrite files outside the repository evidence area. The stable-porcelain check does not detect writes outside the worktree. `scripts/finalize_phase_164.sh:172-191` also reuses predictable paths and redirects to `ci-runs.json` and `*.tmp`, so terminal finalization exposes the same class of overwrite.
**Fix:** Allocate a new private capture directory for every run and require its physical path to remain under canonical `tmp` before writing:

```bash
capture_dir=$(mktemp -d "$repo/tmp/phase-164-closeout.XXXXXX")
capture_dir=$(cd "$capture_dir" && pwd -P)
case "$capture_dir" in "$repo/tmp/"*) ;; *) fail "capture directory escaped tmp" ;; esac
components_dir="$capture_dir/components"
mkdir -m 700 "$components_dir"
```

Create every output with `mktemp` inside that fresh directory and rename it atomically. Never follow a pre-existing component directory or leaf.

### CR-02: Closeout accepts an incomplete scheduled-control sweep as complete evidence

**Classification:** BLOCKER
**File:** `scripts/closeout_repository_truth.sh:9-28`
**Issue:** `scheduled_report_is_acceptable/2` requires only a non-empty controls array. It does not require the exact registry control set, unique control IDs, workflow names, run IDs, result reasons, or archive digests. It also accepts a top-level `blocked` sweep and later converts any accepted sweep into a `pass` component. An adversarial one-control sweep passed this production predicate (`partial-sweep-status=0`). Because `SCHEDULED_CONTROL_CONFIG` is inherited, direct closeout can be made green while omitting two of the three required controls. The terminal finalizer performs a stronger later check, but the closeout command and its report independently claim a truthful quiet verdict and are documented for direct use.
**Fix:** Pass the canonical registry into the predicate and use the same exact-set and provenance validation as `raw_sources_are_acceptable/5`: require `kind == "sweep"`, top-level `status == "pass"`, `reason == "all_controls_current"`, set-equality with registered IDs, matching workflow names, positive run IDs, non-empty reasons, and strict 64-hex payload/archive digests. Remove the weaker duplicate predicate or share one validator between closeout and finalization.

### CR-03: Finalization can certify a fork because GitHub repository identity is only shape-checked

**Classification:** BLOCKER
**File:** `scripts/finalize_phase_164.sh:176-188`
**Issue:** The physical checkout path is hardcoded, but neither the `origin` remote nor `gh repo view` is required to resolve to the authoritative `szTheory/mailglass` repository. `.git/config` is outside stable porcelain. Repointing `origin`, or setting GitHub CLI repository context, allows the script to fetch a fork, select that fork's CI, query that fork's scheduled controls, and produce a passing finalization. The regex on line 187 proves only `owner/name` syntax, not authority.
**Fix:** Pin and verify repository identity before any remote evidence query:

```bash
expected_repository=szTheory/mailglass
[ "$github_repository" = "$expected_repository" ] ||
  fail "GitHub repository identity is not $expected_repository"
```

Also normalize `git remote get-url origin` and require it to identify the same repository, rejecting alternate remotes and `GH_REPO` overrides.

### CR-04: Protected main is checked only before a multi-step evidence collection

**Classification:** BLOCKER
**File:** `scripts/finalize_phase_164.sh:155-160,207-212`
**Issue:** The script fetches `origin/main` once at the beginning. At the final decision it checks only that local `HEAD` and porcelain are unchanged; it never fetches or resolves protected `main` again. If another protected commit lands after the scheduled sweep reads main but before line 212, terminal finalization succeeds for a SHA that is no longer current. This violates the exact-current-main terminal claim and creates a real race during the network-bound evidence collection.
**Fix:** Immediately before success, fetch `origin main` again, require `HEAD == refs/remotes/origin/main == main_sha`, and ensure the report's scheduled `expected_main_sha` still matches that freshly fetched value. If protected main advanced, preserve the non-pass report and require a new run.

### CR-05: The authoritative ledger validator accepts fabricated authority and evidence fields

**Classification:** BLOCKER
**File:** `scripts/validate_repository_truth.exs:74-115`
**Issue:** Validation checks required subject presence plus only `currentness`, `disposition`, non-blank fields, and duplicate subjects. It does not validate `stable_id`, `kind`, `producer`, `state`, `authority`, `reproducibility`, `durable_consumer`, `evidence`, or the relationship between those fields and disposition. Replacing every `tracked` value with `forged-state` and SHA evidence with `fabricated-evidence` still returned `:ok` in an in-memory probe. Closeout then labels this `complete_authoritative_disposition_ledger`, so malformed authority rows can satisfy a terminal gate.
**Fix:** Define closed enums and per-kind invariants for every semantic field, require unique stable IDs where IDs are identities, validate evidence formats and required digests/paths, and enforce relationships such as tracked/current/retain for durable artifacts and locked digest equality for removal rows. Add negative tests that mutate each column independently and require validation failure.

### CR-06: Current installation guidance excludes the documented production operator from production

**Classification:** BLOCKER
**File:** `mailglass_admin/README.md:42-54`
**Issue:** The new current compatibility section tells every adopter to declare `mailglass_admin` with `only: :dev`, but the same README documents mounting the production operator at line 105. A copy-pasted dependency is not compiled or available in `:prod`, so the documented production router import/macro cannot work. Root `README.md:63-69` repeats the same dev-only constraint while presenting the package family generally.
**Fix:** Separate the two supported dependency shapes explicitly: use `only: :dev` for preview-only installations, and omit `only:` for adopters mounting the production operator. The root current-package example should either use the production-capable declaration or state the tradeoff and show both variants. Add a docs contract that fails when production-operator guidance is paired only with a dev-scoped dependency.

## Warnings

### WR-01: Current docs still describe the released v2 packages as v1/1.0 contracts

**Classification:** WARNING
**File:** `README.md:166-186`
**Issue:** The README's new current `2.5 / 2.5 / 2.2` dependency guidance conflicts with nearby claims that core/admin belong to a `v1.x` contract group; the package table repeats those claims at lines 245-246. `MAINTAINING.md:169-173` instructs future JTBD refreshes to describe inbound as an independent `1.0` contract even though the same phase declares inbound stable `2.0` and installs `~> 2.2`. The docs contract at `test/mailglass/docs_contract_test.exs:403-404` actively requires that stale `1.0` wording, making future reconciliation fail tests.
**Fix:** Update current contract labels to the actual v2 lines (distinguishing historical compatibility promises where needed), change the JTBD refresh rule to the current inbound major contract, and replace assertions that require `1.0`/`v1.x` prose with manifest- or stability-inventory-derived major versions.

---

_Reviewed: 2026-09-01T14:15:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
