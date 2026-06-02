---
phase: 72-contract-docs-and-stale
plan: 01
subsystem: docs
tags: [docs, stale-claims, inbound, compatibility, guards]
dependency_graph:
  requires: []
  provides: [DOC-01, DOC-02, PROOF-02]
  affects: [guides/jobs.md, guides/compatibility-and-deprecations.md, MAINTAINING.md, lib/mix/tasks/mailglass.docs.check.ex, test/mailglass/docs_contract_test.exs]
tech_stack:
  added: []
  patterns: [exact-token stale-claim guards, ExUnit assert/refute string assertions, Mix task forbidden/required token rules]
key_files:
  created: []
  modified:
    - guides/jobs.md
    - guides/compatibility-and-deprecations.md
    - MAINTAINING.md
    - lib/mix/tasks/mailglass.docs.check.ex
    - test/mailglass/docs_contract_test.exs
decisions:
  - Used "1.0" not "1.x" for inbound's own contract to avoid triggering refute_over_claims! regex guard
  - Fixed MAINTAINING.md line wrap so "independent 1.0 contract" appears contiguous for ExUnit substring match
  - Moved stale required token to forbidden list in docs.check.ex rather than deleting it
metrics:
  duration: "2 min 28 sec"
  completed: "2026-06-02"
  tasks_completed: 2
  files_modified: 5
---

# Phase 72 Plan 01: Contract Docs and Stale-Claim Guards Summary

Corrected five stale public-doc claim sites describing `mailglass_inbound` as "outside the `v1.x` stability promise" or "excluded from the `1.x` compatibility promise", replacing them with "independent stable `1.0` contract" language routed to `mailglass_inbound/docs/api_stability.md`. Simultaneously flipped the corresponding executable guards in `mailglass.docs.check.ex` and `docs_contract_test.exs` to enforce the corrected posture.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Correct stale prose in jobs.md, compat guide, and MAINTAINING.md | cf54a847 | guides/jobs.md, guides/compatibility-and-deprecations.md, MAINTAINING.md |
| 2 | Flip executable guards in docs.check.ex and docs_contract_test.exs | 8b96ceef | lib/mix/tasks/mailglass.docs.check.ex, test/mailglass/docs_contract_test.exs, MAINTAINING.md |

## Verification Results

1. `mix mailglass.docs.check` exits 0 — PASSED
2. `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` exits 0 (24 tests, 0 failures, 1 skipped) — PASSED
3. No occurrences of "outside the `v1.x` stability promise" in jobs.md, compat guide, or MAINTAINING.md — PASSED
4. No occurrences of "excluded from the `1.x` compatibility promise" in compat guide — PASSED
5. No occurrences of "Through `mailglass_inbound` `0.x`" in compat guide — PASSED
6. "independent `1.0` contract" present in compat guide — PASSED
7. "independent stable `1.0` contract" present in jobs.md — PASSED
8. "independent `1.0` contract" present in MAINTAINING.md — PASSED

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MAINTAINING.md line wrap caused test substring match failure**
- **Found during:** Task 2 verification
- **Issue:** The replacement text split "independent `1.0`" and "contract" across two lines, so the ExUnit assertion `assert maintaining =~ "independent \`1.0\` contract"` failed because `String.contains?/2` does not match across newlines.
- **Fix:** Moved the line break to after "contract" so the complete token "independent `1.0` contract" appears on a single line.
- **Files modified:** MAINTAINING.md (line 117)
- **Commit:** 8b96ceef

## Decisions Made

- **Use "1.0" not "1.x" for inbound's own contract.** The `refute_over_claims!` guard in `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` rejects `~r/mailglass_inbound.*1\.x.*(stability|stable|compatibility)/i`. All replacement wording uses "1.0" to avoid this guard while correctly describing inbound's own contract.
- **Move stale token from required to forbidden.** In `@tier1_surface_rules` for README.md, the phrase "mailglass_inbound is outside the v1.x stability promise" was moved from `required:` to `forbidden:` rather than deleted, so any future regression re-introducing the phrase fails the check.
- **Preserve all inbound docs_contract_test.exs tokens.** The compatibility guide edits preserved: "mailglass_inbound/docs/api_stability.md", "stable/internal/deferred source", "Reachability is not a compatibility promise.", "## mailglass_inbound compatibility", "## Inbound deprecation-DX inventory", and the full DX inventory header row.

## Known Stubs

None. All five stale claim sites are fully corrected with verifiable content. No placeholder or deferred prose remains.

## Threat Flags

No new security-relevant surfaces introduced. All changes are Markdown documentation edits and ExUnit/Mix task token-rule changes. No authentication, cryptography, input validation, or access-control surfaces were modified.

## Self-Check: PASSED

- guides/jobs.md: present and contains "independent stable `1.0` contract"
- guides/compatibility-and-deprecations.md: present and contains "independent `1.0` contract"
- MAINTAINING.md: present and contains "independent `1.0` contract"
- lib/mix/tasks/mailglass.docs.check.ex: present with corrected @tier1_surface_rules
- test/mailglass/docs_contract_test.exs: present with corrected freshness and MAINTAINING tests
- Commits cf54a847 and 8b96ceef: verified in git log
