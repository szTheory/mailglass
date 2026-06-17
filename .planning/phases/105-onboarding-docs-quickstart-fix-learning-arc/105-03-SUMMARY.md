---
phase: "105"
plan: "03"
subsystem: docs
tags: [docs, onboarding, getting-started, contract-test]
dependency_graph:
  requires:
    - "105-01"
    - "105-02"
  provides:
    - "guides/getting-started.md ends on ## Next steps"
    - "DOCS-02 contract assertion in docs_contract_test.exs"
  affects:
    - "test/mailglass/docs_contract_test.exs"
tech_stack:
  added: []
  patterns:
    - "Regex.scan with ~r/^## (.+)$/m for last-heading detection"
    - "List.last/1 as proof of file-ending heading"
key_files:
  created: []
  modified:
    - guides/getting-started.md
    - test/mailglass/docs_contract_test.exs
decisions:
  - "Troubleshooting section updated in-place (no heading rename) to preserve extract_block_after_heading lookups"
  - "## Next steps uses no sub-headings — single section with ordered list per plan constraint"
  - "Regex.scan multiline pattern for heading detection (not greedy dotall) to avoid matching ### or deeper"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-17"
  tasks_completed: 2
  files_modified: 2
---

# Phase 105 Plan 03: Getting Started Reorder + DOCS-02 Contract Summary

**One-liner:** Reordered `guides/getting-started.md` to end on `## Next steps` with a 6-step week-one arc, updated 401 troubleshooting to reflect Phase 104 fail-closed behavior, and added a contract assertion proving Next steps is the final `##` heading.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Reorder getting-started.md — Troubleshooting before Next steps | d5658a27 | guides/getting-started.md |
| 2 | Add DOCS-02 contract assertion | 7591cfbd | test/mailglass/docs_contract_test.exs |

## What Was Built

### Task 1: guides/getting-started.md

- Updated `### Webhooks return 401 after installation` to reflect Phase 104 behavior:
  - `mix mailglass.install` now fails closed (exits non-zero via `Mix.raise`) on unmanaged `Plug.Parsers` conflict
  - Documents `--force` escape hatch and installer ordering guarantee
  - Instructs users to run `mix mailglass.doctor` post-install to verify `Mailglass.Webhook.CachingBodyReader` wiring
  - Covers the "installed before v1.7" retroactive check path
- Added `## Next steps` as the final `##` heading with a 6-step ordered arc:
  1. [What you can do with mailglass](jobs.md)
  2. [Authoring mailables](authoring-mailables.md)
  3. [Preview](preview.md)
  4. [Webhooks](webhooks.md)
  5. [Testing](testing.md)
  6. [Telemetry and operating](telemetry.md)
- Closing line links to `learning-path.md` for the fuller ordered index
- Removed stale `*Last updated: ...*` footer (was inside the replaced block; not load-bearing)
- All existing `##` heading names unchanged (Prerequisites, 1) Install and verify, 2) Configure mailglass, 3) Mount preview and webhook routes, 4) Send your first message, End-to-End Example, Troubleshooting the Installer)

### Task 2: test/mailglass/docs_contract_test.exs

Added `"Getting Started ends on a Next steps section"` test in the `"Guide contracts"` describe block, after `"Config examples are valid"` and before `"learning-path is registered in both mix.exs docs lists"`:
- `Regex.scan(~r/^## (.+)$/m, ...)` collects all `##` headings in document order
- `List.last/1` proves the final heading is `"Next steps"` (exact string match)
- Asserts `learning-path.md` link is present in the file
- Asserts `mix mailglass.doctor` appears in the file (troubleshooting section coverage)

**Test run result:** 28 tests, 0 failures, 1 skipped (pre-existing Phase 38 skip)

## Verification

```
$ grep -n "^## " guides/getting-started.md | tail -1
120:## Next steps

$ mix test test/mailglass/docs_contract_test.exs
28 tests, 0 failures, 1 skipped
```

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — docs-only change, no new attack surface.

## Self-Check: PASSED

- [x] `guides/getting-started.md` exists and ends on `## Next steps`
- [x] `test/mailglass/docs_contract_test.exs` contains "Getting Started ends on a Next steps section"
- [x] Commits d5658a27 and 7591cfbd exist on main
- [x] `mix test test/mailglass/docs_contract_test.exs` exits 0 (28 tests, 0 failures)
