---
phase: 106-day-2-guides-go-live-checklist-error-troubleshooting-map
plan: "02"
subsystem: docs
tags: [docs, mix.exs, contract-tests, api_stability, hexdocs]
dependency_graph:
  requires: [106-01]
  provides: [OPS-01, OPS-02, docs-contract-gating]
  affects: [mix.exs, test/mailglass/docs_contract_test.exs, docs/api_stability.md]
tech_stack:
  added: []
  patterns: [ExUnit docs-contract assertions, Regex.scan registration test pattern]
key_files:
  created: []
  modified:
    - mix.exs
    - test/mailglass/docs_contract_test.exs
    - docs/api_stability.md
decisions:
  - Both new day-2 guides appended after migration-from-swoosh.md in both extras: and Guides: lists
  - Four new test names follow verbatim-from-plan spec for stable CI output identifiers
  - api_stability.md edits are exactly two surgical prose changes; no atom sets touched
metrics:
  duration: "8 minutes"
  completed_date: "2026-06-17"
  tasks: 3
  files: 3
---

# Phase 106 Plan 02: mix.exs Registration + Docs-Contract Assertions + api_stability.md Correction Summary

Both day-2 guides registered in HexDocs, four OPS-01/OPS-02 contract assertions added to CI gate, and two stale api_stability.md prose lines corrected (six→ten structs, StreamPolicyError added to stable list).

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Register both guides in mix.exs | 90c7f562 | mix.exs |
| 2 | Add docs-contract assertions for OPS-01 and OPS-02 | ec6a834b | test/mailglass/docs_contract_test.exs |
| 3 | Correct stale error-count and missing StreamPolicyError in docs/api_stability.md | 6c7c51f3 | docs/api_stability.md |

## What Was Built

**Task 1 — mix.exs registration:** Appended `"guides/production-go-live-checklist.md"` and `"guides/errors-and-troubleshooting.md"` to both the `extras:` list and the `Guides:` group in `groups_for_extras:`, inserted after `"guides/migration-from-swoosh.md"` in both locations. Each guide now appears exactly 2 times in mix.exs. The `main: "getting-started"` line is unchanged.

**Task 2 — docs-contract assertions:** Added four new tests inside the existing `"Guide contracts"` describe block in `docs_contract_test.exs`:
1. `"production-go-live-checklist is registered in both mix.exs docs lists"` — Regex.scan count >= 2 + File.exists?
2. `"errors-and-troubleshooting is registered in both mix.exs docs lists"` — Regex.scan count >= 2 + File.exists?
3. `"production-go-live-checklist covers required go-live topics"` — asserts: mix mail.doctor, mix mailglass.doctor, Oban, suppression, telemetry, rotation
4. `"errors-and-troubleshooting covers all ten error structs and routes to api_stability.md"` — asserts all 10 short names (SendError, TemplateError, SignatureError, SuppressedError, RateLimitError, ConfigError, EventLedgerImmutableError, TenancyError, StreamPolicyError, PublishError) + api_stability.md cross-link

Test run: **32 tests, 0 failures, 1 skipped** (pre-existing Phase 38 skip).

**Task 3 — api_stability.md corrections:** Two surgical prose edits only:
- Line 59: Added `Mailglass.StreamPolicyError,` before `Mailglass.PublishError` in the stable errors list
- Line 214: Changed `"union of the six error structs"` to `"union of ten error structs"`

## Verification

```
grep -c '"guides/production-go-live-checklist.md"' mix.exs   → 2
grep -c '"guides/errors-and-troubleshooting.md"' mix.exs     → 2
grep "ten error structs" docs/api_stability.md               → 1 match
grep -c "six error structs" docs/api_stability.md            → 0
grep "StreamPolicyError" docs/api_stability.md               → 1 match
mix test test/mailglass/docs_contract_test.exs               → 32 tests, 0 failures, 1 skipped
```

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are documentation, test, and docs config — consistent with T-106-03/04/05 accept dispositions in the plan's threat register.

## Self-Check: PASSED

- mix.exs: modified, 4 lines inserted (2 in extras:, 2 in Guides:) ✓
- test/mailglass/docs_contract_test.exs: modified, 58 lines inserted ✓
- docs/api_stability.md: modified, 3 insertions / 3 deletions (net 0, two line rewrites) ✓
- Commits 90c7f562, ec6a834b, 6c7c51f3 all present in git log ✓
- `mix test test/mailglass/docs_contract_test.exs` exits 0, 32 tests, 0 failures, 1 skipped ✓
