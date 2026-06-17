---
phase: "105"
plan: "01"
subsystem: docs
tags: [docs, onboarding, learning-arc, hex-docs]
dependency_graph:
  requires: []
  provides: [guides/learning-path.md, mix.exs-learning-path-registration, docs-contract-learning-path]
  affects: [mix.exs, test/mailglass/docs_contract_test.exs]
tech_stack:
  added: []
  patterns: [docs-contract-test, regex-scan-count-assertion]
key_files:
  created:
    - guides/learning-path.md
  modified:
    - mix.exs
    - test/mailglass/docs_contract_test.exs
decisions:
  - "learning-path.md is prose+links only (no fenced code blocks) to avoid extract_block_after_heading coupling"
  - "Contract assertion uses Regex.scan count >= 2 to prove both extras: and groups_for_extras: entries exist"
  - "learning-path.md placed immediately after getting-started.md in both mix.exs lists per D-09"
metrics:
  duration: "55 seconds"
  completed: "2026-06-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 105 Plan 01: Learning Path Index Summary

**One-liner:** Created canonical `guides/learning-path.md` (ordered 7-step week-1 arc + going-deeper section), registered in both `mix.exs` docs lists, gated by new `docs_contract_test.exs` count-based dual-registration assertion.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create guides/learning-path.md | 1830b79a | guides/learning-path.md |
| 2 | Register in mix.exs + add contract assertion | 309d0584 | mix.exs, test/mailglass/docs_contract_test.exs |

## What Was Built

**`guides/learning-path.md`** — The single source of truth for the first-week learning sequence. Structured as:

- `# Learning Path` heading + brief purpose statement
- `## Week 1 arc` — 7 bullets linking getting-started, jobs, authoring-mailables, preview, webhooks, testing, telemetry; each with a one-sentence description
- `## Going deeper` — links to multi-tenancy, DKIM setup, unsubscribe, migration-from-swoosh

No fenced code blocks (prose + links only), so the guide never needs `extract_block_after_heading` coupling. Brand voice follows brandbook/brand-book.md (clear, exact, confident).

**`mix.exs` — dual registration (D-09):**
- `extras:` list: `"guides/learning-path.md"` inserted immediately after `"guides/getting-started.md"` (line 389)
- `groups_for_extras: [Guides: ...]`: same placement (line 417)
- `main: "getting-started"` unchanged per D-09

**`test/mailglass/docs_contract_test.exs` — new test in "Guide contracts" describe:**
- `"learning-path is registered in both mix.exs docs lists"` inserted before the multi-tenancy test
- Asserts `Regex.scan(~r/"guides\/learning-path\.md"/, mix_exs)` length >= 2 (proves both list entries)
- Asserts `File.exists?("guides/learning-path.md")` is truthy

## Verification

```
mix test test/mailglass/docs_contract_test.exs
25 tests, 0 failures, 1 skipped (pre-existing Phase 38 skip)
```

`grep -n "learning-path" mix.exs` returns two lines: 389 (extras:) and 417 (Guides group).

## Deviations from Plan

None — plan executed exactly as written.

## Threat Flags

None — docs-only change, no new attack surface.

## Known Stubs

None.

## Self-Check: PASSED

- guides/learning-path.md: FOUND
- mix.exs entries at lines 389 and 417: FOUND
- Docs contract test new assertion: FOUND
- Commits 1830b79a and 309d0584: verified via git log
