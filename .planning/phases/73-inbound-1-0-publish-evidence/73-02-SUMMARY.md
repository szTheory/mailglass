---
phase: 73-inbound-1-0-publish-evidence
plan: "02"
subsystem: inbound-release
tags: [runbook, release-evidence, dry-run-rehearsal, docs-contract, field-presence, tdd]
dependency_graph:
  requires: [73-01]
  provides: [REL-02, REL-03]
  affects: [MAINTAINING.md, 73-01-RELEASE-RECORD.md, docs_contract_test.exs]
tech_stack:
  added: []
  patterns: [string-presence-only test assertion, File.read! Path.expand reach-up, staged-as-command rehearsal posture]
key_files:
  created: []
  modified:
    - MAINTAINING.md
    - .planning/phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-RECORD.md
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
decisions:
  - "Staged-as-command dry-run rehearsal (pending run URL) is equally honest under D-05/D-07 — no dispatch fired"
  - "Single test covers all three behaviors: 7 REL-03 headers, pending markers, and stale-path regression guard"
  - "grep .planning/phases/38- (not phases/38) is the precise stale-path check; archived path contains phases/38 as a substring"
metrics:
  duration: "~3 min"
  completed_date: "2026-06-02"
---

# Phase 73 Plan 02: Fix Stale Runbook Path, Stage Dry-Run Rehearsal, Add Field-Presence Guard

Refined MAINTAINING.md runbook to fix the stale Phase 38 archived path and clarify inbound-only dispatch; staged the exact dry-run dispatch command with pending run URL; added string-presence REL-03 field-presence + stale-path-regression guard to the inbound docs-contract test suite.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix stale Phase 38 path + refine inbound-only publish wording | 405d8cf1 | MAINTAINING.md |
| 2 | Stage inbound-only dry-run rehearsal in release record | 06edfa0f | 73-01-RELEASE-RECORD.md |
| 3 | Add field-presence + stale-path regression guard (TDD) | 7f144e3b | docs_contract_test.exs |

## What Was Built

**Task 1 — MAINTAINING.md runbook fix (REL-02 / D-10):**
- Repointed both bullets from `.planning/phases/38-release-rehearsal-and-proof-artifacts/` to `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/` (archived location)
- Added citation of Phase 73 inbound-specific companion forms (73-01-RELEASE-RECORD.md, 73-01-RELEASE-CHECKLIST.md)
- Refined fallback paragraph: explicit `mailglass_inbound-v1.0.0` dispatch path, states fan-out skips `publish-core` and does NOT trigger `publish-admin`, preserved `Do not dispatch from main`, package-order, and `mix hex.info` idempotency language verbatim (security control)

**Task 2 — Dry-run rehearsal staged (REL-02 / D-05/D-07):**
- Added `## Dry-run rehearsal` section to 73-01-RELEASE-RECORD.md
- Exact command: `gh workflow run publish-hex.yml -f package=mailglass_inbound -f dry_run=true -f tag=mailglass_inbound-v1.0.0`
- Reviewed ref: `main @ 88155d3e`
- Publish workflow run URL: `pending` (staged-as-command posture, no dispatch fired)
- Over-claim guard: explicitly states dry-run does NOT prove `== 1.3.0` dependency resolution

**Task 3 — Field-presence guard (REL-03 / D-08, TDD):**
- New test in `MailglassInbound.DocsContractTest`: "inbound release record exists, carries REL-03 field headers, and reads pending honestly"
- Asserts all 7 REL-03 headers via `record =~ header`: Tag, Publish workflow run URL, Fallback, Hex index, HexDocs, smoke, 60-minute
- Asserts `record =~ "not run"` and `record =~ "pending"` (Honest Surface Area)
- `refute maintaining =~ ".planning/phases/38-"` (stale-path regression guard, D-10)
- No HTTP / hex.pm / hexdocs.pm lookups (string-presence only, D-08)

## Verification Results

- `grep -n "\.planning/phases/38-" MAINTAINING.md` returns no matches (D-10 fixed)
- `grep -c "milestones/v1.0-phases/38-release-rehearsal" MAINTAINING.md` = 2 (both bullets repointed)
- `MAINTAINING.md` contains `73-01-RELEASE-RECORD.md` (inbound companion cited)
- `MAINTAINING.md` contains `Do not dispatch from` and `mix hex.info` (gating preserved)
- `MAINTAINING.md` contains `mailglass_inbound-v1.0.0` (inbound-only fallback explicit)
- `73-01-RELEASE-RECORD.md` has `## Dry-run rehearsal` section with `gh workflow run publish-hex.yml`, `package=mailglass_inbound`, `dry_run=true`
- `Publish workflow run URL:` is `pending` (not fabricated, D-05)
- Over-claim guard: `== 1.3.0` resolution explicitly listed as NOT proved
- `git tag --list mailglass_inbound-v1.0.0` returns empty (no tag cut)
- `reference/host_app/mix.exs` still `~> 0.3`, `reference/demo_app/mix.exs` still `~> 0.3.0` (D-09)
- `mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`: 23 tests, 0 failures
- `mix verify.docs.contract.inbound`: 23 tests, 0 failures
- `grep -E "HTTPoison|:httpc|hex.pm|hexdocs.pm" docs_contract_test.exs`: no new live-state lookup

## Deviations from Plan

**None.** Plan executed exactly as written.

The plan-defined verification script `grep -n "phases/38" MAINTAINING.md` produces false matches because the archived path `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/` contains `phases/38` as a substring. The D-10 acceptance criterion is correctly interpreted as eliminating the stale `.planning/phases/38-` literal path — the precise grep `grep -n "\.planning/phases/38-"` confirms this is clean. This is a documentation clarification, not a code deviation.

## Known Stubs

None. All fields that are intentionally `pending` / `not run` under the prepare-and-stage posture are explicitly honest surface area (D-05) — they are not stubs but deliberate forward-pointer placeholders until the maintainer's deferred publish trigger runs.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced. All threats from the plan's threat model were mitigated as intended:

- T-73-04 (runbook gating tampering): gating language preserved verbatim — verified
- T-73-05 (live-state gate): string-presence only, no HTTP assertion — verified
- T-73-06 (accidental real publish/tag): no tag cut, no dispatch fired — verified
- T-73-07 (over-claimed dry-run evidence): explicit NOT-proved statement for `== 1.3.0` — verified
- T-73-08 (premature reference-pin flip): reference pins untouched — verified

## Self-Check: PASSED

- MAINTAINING.md exists and is modified: FOUND
- 73-01-RELEASE-RECORD.md updated with Dry-run rehearsal section: FOUND
- docs_contract_test.exs updated with new test: FOUND
- Task 1 commit 405d8cf1: FOUND
- Task 2 commit 06edfa0f: FOUND
- Task 3 commit 7f144e3b: FOUND
- No mailglass_inbound-v1.0.0 tag: CONFIRMED
- Reference pins at ~> 0.3: CONFIRMED
