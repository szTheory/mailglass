---
phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering
reviewed: 2026-09-13T21:25:11Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - mix.exs
  - scripts/finalize_milestone_v2_7.sh
  - scripts/mailglass_finalize_milestone_loader.mjs
  - test/scripts/ci_parity_drift_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_165_milestone_finalizer_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test/scripts/suite_floor_contract_test.exs
  - test/support/suite_floor.ex
  - test/test_helper.exs
  - test/support/mailglass_milestone_finalizer_fixture.mjs
findings:
  critical: 5
  warning: 1
  info: 0
  total: 6
status: issues_found
disposition: accepted_risk
disposition_date: 2026-09-15
disposition_authority: maintainer
disposition_scope: CR-01, CR-02, CR-03, CR-04, CR-05, WR-01
---

# Phase 165: Code Review Report

**Reviewed:** 2026-09-13T21:25:11Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The iteration-2 changes do close the five findings they targeted at a surface level: the finalizer now accepts the canonical audit field layout, authenticates live ROADMAP/RETROSPECTIVE and absent REQUIREMENTS state, checks all three validation booleans, separates fixture reports from production reports, validates installed bytes and pinned runtime tools, restores config bytes after false-success hooks, and releases unpublished receipt reservations. The terminal lifecycle is nevertheless still not shippable. Its supposedly exact document parser accepts contradictory authenticated content, approval/install can trust a stale remote-tracking ref, a late loader-side authority failure leaves a published pass receipt, one-shot state is scoped to an OID instead of the milestone, and rollback does not preserve or durably receipt the predecessor transition it claims to authenticate.

Executable evidence confirmed that a duplicate contradictory `scores` parent is accepted as `16/16`, and that an authoritative-looking heading inside a fenced Markdown example is accepted. The deterministic receipt helper also produces distinct receipt locations for two OIDs of the same v2.7 milestone. Bash and Node syntax checks passed, as did `git diff --check`; the Elixir lane could not be rerun in this checkout because the available 1.19/OTP-27 runtime encountered dependency BEAMs compiled under an incompatible runtime (`corrupt atom table`). The prior fix report records a green 436-test CI-lane run. `.planning/config.json` remained byte-identical at SHA-256 `1bd93e09ff13a2f3536d7b5308f9fb19dcedc378424a7fa00c163a2868bf05fc`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 — BLOCKER: Contradictory YAML and fenced examples can still impersonate terminal archive semantics

**File:** `/Users/jon/projects/mailglass/scripts/finalize_milestone_v2_7.sh:29-61,70-72,103-115`

**Issue:** `frontmatter_value` counts a nested parent only when it has the exact empty form `scores:` or `nyquist:`. It therefore accepts a document containing both `scores: {requirements: 0/16}` and a later block-form `scores:` with `requirements: 16/16`; the review probe returned `16/16` instead of rejecting the duplicate parent. The lifecycle checks are looser still: `require_heading` is a raw `grep`, so an exact PROJECT, ROADMAP, MILESTONES, or RETROSPECTIVE heading inside a fenced code example passes. The two accepted-debt checks are unanchored prose searches and can occur in a sentence that repudiates the policy. The audit's `gaps` collections and exact Nyquist phase sets are not checked at all. Thus an authenticated final commit can contain contradictory canonical state while the finalizer emits a production `pass` report.

**Fix:** Parse the complete frontmatter as one strict document with duplicate-key rejection, require empty critical-gap collections and exact Nyquist phase sets, and reject unsupported YAML shapes rather than selecting one occurrence. Parse Markdown headings outside fenced/code regions and require exactly one canonical lifecycle record. Move the accepted-debt disposition to an exact structured owner field, or at minimum require one exact non-negated line outside fences. Add hostile cases for duplicate inline/block parents, non-empty audit gaps under `status: passed`, fenced canonical headings, duplicate ledger records, and negated debt prose.

### CR-02 — BLOCKER: Approval and installation authenticate a stale cached `origin/main`

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:432-445,1017-1061`

**Issue:** Proposal creation refreshes `origin/main` once, but `--approve-installation` and `--install-approved` do not fetch. Their call chain reaches `assertProposalAuthority`, which compares HEAD only with the local `refs/remotes/origin/main`. If protected main advances after proposal creation without another local fetch, that cached ref still equals the old HEAD, so both fresh approval and the host installation proceed for authority that is no longer current. Terminal execution will eventually discover the advance, but only after the external executable has already been replaced, contradicting the runbook rule that authority drift invalidates the proposal and approval.

**Fix:** Before recording approval and again immediately before mutating the destination, fetch `origin main` with the pinned Git binary, then require clean physical canonical `main == origin/main == proposal.source_oid`. Reauthenticate the proposal, source bytes, runtime closure, and predecessor after that refresh. Add a disposable remote fixture where main advances between proposal/approval and between approval/install; neither transition may write a receipt or destination byte.

### CR-03 — BLOCKER: A loader-side late authority failure leaves a valid-looking pass receipt published

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:992-1009`

**Issue:** The staged Bash finalizer marks the report blocked when its own post-write checks detect movement, but after it returns the loader performs another HEAD and cleanliness check. If HEAD or the worktree changes in the interval between Bash's last check and lines 1007-1008, those loader checks throw without changing the already-published report. The invocation exits non-zero while `report.json` remains `schema: mailglass-finalize-milestone-report-v1, status: pass`; the occupied receipt directory then prevents a corrective retry. This is exactly the late-race case the terminal receipt is supposed to fail closed on.

**Fix:** Wrap every post-publication loader check in a common finalization path that atomically rewrites the owned report to `blocked` before propagating the error, and reauthenticate that blocked write. Prefer returning the final observation to the report-owning process so there is one post-publication authority boundary. Add a mutation hook after staged Bash returns but before the loader's final checks and assert that the durable receipt is blocked, never pass.

### CR-04 — BLOCKER: “Exactly once” is enforced per commit, not per v2.7 milestone

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:737-739,742-777,993-1005`

**Also affected:** `/Users/jon/projects/mailglass/.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md:354-367`

**Issue:** The exclusive receipt directory includes `authorityOid`. Two different commits therefore map to two different receipt directories (`tmp/mailglass-finalize-v2.7-<oid>/report.json`) and can each execute the v2.7 terminal workflow once. The runbook requires one terminal invocation followed by a hard stop against later v2.7 lifecycle/report writes; the implementation only rejects a repeat at the same commit and has no milestone-global consumed marker. A later tracked commit—whether accidental or hostile—reopens the supposedly terminal command.

**Fix:** Add a milestone-global exclusive one-shot record whose identity is independent of OID and whose payload binds the single authorized OID/report. Acquire it only after read-only evidence and semantic preflight so unpublished failures remain retryable; remove only an owned unpublished reservation, and retain every published pass/blocked consumption permanently. Keep the OID-specific report as evidence, but gate it on the global record. Add a test that publishes at OID A, advances the fixture repository to OID B, supplies otherwise valid evidence, and proves the second v2.7 invocation is rejected before queries or report creation.

### CR-05 — BLOCKER: Rollback neither preserves the authenticated predecessor nor guarantees a consumable receipt

**File:** `/Users/jon/projects/mailglass/scripts/mailglass_finalize_milestone_loader.mjs:401-422,631-644,646-720,1063-1076`

**Issue:** The proposal records predecessor uid/gid/mode, but installation backs it up with `copyFileSync` and restores it with `renameSync`; only the mode is reapplied. A root-owned or differently grouped allowed predecessor can therefore be restored with the installer's uid/gid, despite the receipt claiming the original authenticated predecessor. The explicit rollback mutates the destination before creating `rollback.json`; if that exclusive receipt write fails, rollback has already happened, the command returns failure without a durable receipt, and a retry cannot pass the installed-byte precondition. Moreover the CLI derives the rollback control directory from current HEAD rather than the supplied proposal digest/source OID, so an authority advance makes the approved prior installation receipt undiscoverable precisely when rollback may be needed.

**Fix:** Preserve the predecessor inode/metadata with an authenticated rename-to-backup design (or explicitly restore and verify uid, gid, mode, and digest), and verify all restored fields. Reserve a rollback journal/receipt path before mutation and make failure recovery deterministic so the operation ends in either authenticated installed state or authenticated rolled-back state with a consumable record. Resolve the approved installation by proposal digest and authenticated receipt source OID rather than current HEAD, without weakening destination or receipt authentication. Add root/different-group metadata coverage where supported, a pre-existing/unwritable rollback-receipt failure case, and rollback after repository HEAD advances.

## Warnings

### WR-01 — WARNING: The “actual canonical audit” and one-shot tests do not exercise the remaining trust boundaries

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_165_milestone_finalizer_test.exs:111-171,407-434,517-553,706-817`

**Issue:** The test named “actual canonical audit schema” uses a hand-authored fixture rather than output from the canonical producer, and its duplicate test duplicates only a nested child under one block parent. The one-shot test repeats the same OID only, the installation lifecycle asserts restored bytes but not uid/gid/mode, and no test covers remote advancement between installation stages or mutation after Bash returns. These omissions let all five blocker paths above remain green while the suite claims the relevant controls.

**Fix:** Check in or generate a producer-authentic canonical audit sample and exercise it unchanged. Add the hostile cases described in CR-01 through CR-05, including a different-OID second invocation and metadata/receipt-order assertions. Keep fixture-only schema assertions, but do not label a manually reconstructed document as actual producer output.

---

_Reviewed: 2026-09-13T21:25:11Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

---

## Disposition — Accepted Risk (2026-09-15)

All six findings above (CR-01..CR-05, WR-01) are **accepted as known risk**. They are not
fixed and are not scheduled. Phase 165 closes with them open.

### Rationale

The asset under review is `scripts/finalize_milestone_v2_7.sh` and its loader: repository-local
tooling that archives Markdown under `.planning/` and writes a receipt. It is not adopter-facing,
not published to Hex, and not reachable by any third party. No file in `lib/` was touched by any
Phase 165 commit.

Every open finding models an adversary who already holds commit rights to protected `main` and is
attempting to smuggle contradictory YAML, race a HEAD advance, or subvert a local file install.
Such an actor can edit the archive directly and does not need this script. The realistic
worst case for each finding is a milestone-archive commit recorded against a stale SHA, in a
single-maintainer repository, by the maintainer — recoverable by `git revert`.

The review loop was also not converging: three passes produced 9 → 5 → 6 findings, each pass
introducing a new adversary class rather than exhausting the prior one. The hardening already
committed (3,750 lines of script, loader, fixture and test) is disproportionate to the asset and
was itself becoming the larger risk surface.

### Verification status at disposition

`mix verify.phase_165.repository` — 22 executed, 1 expected exclusion, 0 failures. Confirmed by
direct execution on 2026-09-15, not inherited from a prior report.

### Correction to the iteration-2 verification claim

`165-REVIEW-FIX.md` records `verify.ci_lane_contract` as "436 executed, 12 expected exclusions,
0 failures". That result was **not reproducible as stated**. Re-running the lane produced 5, 0, 0
and 1 failures across four runs.

The cause is a test-isolation defect, since fixed: `release_policy_test.exs` `run_cli/1` invoked
`mix run --no-compile --no-deps-check` in a subprocess without pinning `MIX_ENV`. Mix applies an
alias's `preferred_envs` internally rather than exporting `MIX_ENV`, so the child resolved to
`:dev` and depended on `_build/dev` being populated by some unrelated earlier command. With
`_build/dev` present the test passed; with it absent it failed deterministically. The subprocess
now inherits `to_string(Mix.env())`.

Two process lessons are recorded because they are the reason this survived three review passes:

1. The iteration-3 reviewer could not execute the Elixir lane at all — it reported a `corrupt atom
   table`, which was an uninstalled local toolchain (`.tool-versions` pins `elixir 1.18.4` /
   `erlang 27.3.4.13`; neither was present). It then carried the iteration-2 green claim forward
   rather than marking the lane unverified.
2. A green result asserted in a fix report is not evidence. It must be re-executed by whoever
   relies on it.

### Not accepted / still open elsewhere

- `architecture_boundary_test.exs:131` invokes `mix xref graph` with the same missing `MIX_ENV`
  pin. It omits `--no-compile`, so it self-heals by compiling and is not a correctness risk. Left
  unchanged deliberately; pinning it would force dev compilation on cold runs.

### Revisit condition

Reopen these findings if `scripts/finalize_milestone_v2_7.sh` is ever generalized beyond v2.7,
packaged for distribution, or executed by anyone other than the maintainer on a trusted checkout.
