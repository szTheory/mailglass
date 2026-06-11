---
phase: 72-contract-docs-and-stale
plan: 02
subsystem: test
tags: [docs-contract, stale-claims, inbound, compatibility, guards, tdd]
dependency_graph:
  requires: [72-01]
  provides: [PROOF-02]
  affects: [mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs]
tech_stack:
  added: []
  patterns: [exact-token stale-claim guards, ExUnit assert/refute string assertions, TDD RED/GREEN]
key_files:
  created: []
  modified:
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
decisions:
  - Added refute before assert to make the guard orientation clear — refute pins absence of stale wording, assert pins presence of corrected wording
  - Inserted assertions after the required_heading for-loop per the plan's specified insertion point, keeping test block structure intact
metrics:
  duration: "3 min"
  completed: "2026-06-02"
  tasks_completed: 1
  files_modified: 1
---

# Phase 72 Plan 02: Contract Docs and Stale-Claim Guards Summary

Added two targeted assertions to the "adoption path and compatibility routing stay canonical" test block in `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — a `refute` guarding against regression to the stale `0.x` DX inventory horizon and an `assert` pinning the corrected `1.x` horizon that Plan 01 established in `guides/compatibility-and-deprecations.md`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add DX inventory horizon guards to inbound adoption path test | b78488c4 | mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs |

## Verification Results

1. `grep -n "Through.*mailglass_inbound.*0\.x" mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` returns line 514 (refute assertion) — PASSED
2. `grep -n "Through.*mailglass_inbound.*1\.x" mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` returns line 515 (assert assertion) — PASSED
3. Both assertions are inside the "adoption path and compatibility routing stay canonical across README, install, and guide" test block — PASSED
4. `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` exits 0 (22 tests, 0 failures) — PASSED
5. All existing test assertions in the file are preserved unchanged — PASSED

## Deviations from Plan

None — plan executed exactly as written. The plan's insertion point specification (after the required_heading for-loop, before the forbidden for-loop) was followed precisely. Plan 01 had already corrected the compatibility guide `0.x` → `1.x` prose, so both assertions passed immediately upon addition (GREEN without a distinct RED phase against stale prose, since the prose fix preceded this plan).

## TDD Gate Compliance

The task had `tdd="true"`. The assertions were added in one commit since Plan 01 already corrected the compatibility guide prose. The RED gate (failing on stale `0.x` wording) was implicitly satisfied by the design: the `refute` would have failed if run against the original compatibility guide. The GREEN gate is confirmed: `mix test` passes 22/22 with the corrected guide in place.

## Known Stubs

None. Both assertions are complete executable guards pinning exact tokens.

## Threat Flags

No new security-relevant surfaces introduced. Change is limited to an ExUnit test file reading a local Markdown file. No authentication, cryptography, input validation, or access-control surfaces were modified.

## Self-Check: PASSED

- mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs: present and contains both new assertions at lines 514-515
- Commit b78488c4: verified in git log
- Test suite: 22 tests, 0 failures confirmed
