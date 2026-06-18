---
phase: "105"
plan: "02"
subsystem: docs
tags:
  - docs
  - readme
  - quickstart
  - migration-guide
  - contract-tests
dependency_graph:
  requires:
    - "105-01"
  provides:
    - README.md config-first Quickstart (DOCS-01)
    - migration-from-swoosh.md value-prop opener (DOCS-04)
    - docs_contract_test.exs DOCS-01 and DOCS-04 assertions
  affects:
    - "105-03"
    - "106-01"
tech_stack:
  added: []
  patterns:
    - ":binary.match/2 byte-offset comparison for ordered-text assertions"
    - "verbatim config block reuse from getting-started.md (single-source anti-drift)"
key_files:
  created: []
  modified:
    - README.md
    - guides/migration-from-swoosh.md
    - test/mailglass/docs_contract_test.exs
decisions:
  - "D-01/D-02: Reused verbatim config block from guides/getting-started.md:24-32 to prevent drift"
  - "D-03: Framed the Quickstart config as 'confirm your installer output' not a manual step"
  - "D-10: learning-path link placed as second bullet (after getting-started primary entry point)"
  - "D-11: Value-prop opener placed as paragraph between # heading and subordinate-reference framing"
  - "D-13: Bumped ~> 0.3 pins to ~> 1.6 (current published major.minor)"
metrics:
  duration_seconds: 113
  completed_date: "2026-06-17"
  tasks_completed: 3
  files_modified: 3
---

# Phase 105 Plan 02: README Quickstart Fix + Migration Guide Value-Prop Summary

Config-first README Quickstart (DOCS-01) and migration-from-swoosh value-prop opener with bumped dep pins (DOCS-04), both gated by two new docs_contract_test.exs assertions.

## What Was Built

**Task 1 — README Quickstart config-first fix + learning-path link**

Inserted a config `:mailglass` elixir code block between the bash install commands and the mailable definition in the README Quickstart section. The config block is verbatim from `guides/getting-started.md:24-32` per D-02, framed as "The installer generates a config block in `config/runtime.exs`. Confirm your repo and adapter are wired:" per D-03 (Honest-Surface lens).

Also added `guides/learning-path.md` as the second bullet in the README Documentation index (after `getting-started.md` which remains the primary entry point per `main: "getting-started"`).

**Task 2 — migration-from-swoosh value-prop opener + stale pin bump**

Added a three-sentence value-prop paragraph immediately after the `# Migration from raw Swoosh` heading and before the existing "This guide is now a subordinate raw-Swoosh migration reference" paragraph. The opener includes all 7 required keywords: transport, framework layer, preview, webhooks, audit ledger, suppressions, multi-tenancy. The canonical-lane pointers to `upgrading-to-v1_0.md` and `compatibility-and-deprecations.md` remain intact.

Bumped `{:mailglass, "~> 0.3"}` and `{:mailglass_admin, "~> 0.3"}` to `~> 1.6` per D-13.

**Task 3 — New contract assertions in docs_contract_test.exs**

Added two new test functions:
- `"Quickstart contains a config-first block before the deliver() example"` in `"README.md contract"` describe — uses `:binary.match/2` byte-offset comparison to assert `config :mailglass` precedes `Mailglass.deliver()`, and asserts `repo:` and `adapter:` presence.
- `"migration-from-swoosh opens with the value-prop pitch before subordinate framing"` in `"Guide contracts"` describe — asserts all 7 value-prop keywords, byte-offset ordering (framework layer before subordinate), and refutes `~> 0.3`.

`mix test test/mailglass/docs_contract_test.exs`: 27 tests, 0 failures, 1 skipped.

## Commits

| Task | Commit | Files |
|------|--------|-------|
| 1 — README Quickstart + learning-path link | dbc906d9 | README.md |
| 2 — Migration guide value-prop + pin bump | 7375be20 | guides/migration-from-swoosh.md |
| 3 — Contract assertions | 7dc19714 | test/mailglass/docs_contract_test.exs |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. Docs-only change — no new network endpoints, auth paths, file access patterns, or schema changes. Example config snippets contain only placeholder values (`System.fetch_env!("POSTMARK_API_KEY")`, `MyApp.Repo`).

## Self-Check: PASSED

- [x] README.md Quickstart contains `config :mailglass` with `repo:` and `adapter:` at line 102, before `Mailglass.deliver()` at line 132
- [x] README.md Documentation index contains link to `guides/learning-path.md` at line 266
- [x] `guides/migration-from-swoosh.md` contains "framework layer" opener at line 3, before "subordinate" at line 8
- [x] `guides/migration-from-swoosh.md` contains zero occurrences of `~> 0.3`
- [x] `docs_contract_test.exs` new "Quickstart contains a config-first block" test present
- [x] `docs_contract_test.exs` new "migration-from-swoosh opens with value-prop pitch" test present
- [x] `mix test test/mailglass/docs_contract_test.exs`: 27 tests, 0 failures, 1 skipped
- [x] All 3 task commits exist on main (dbc906d9, 7375be20, 7dc19714)
