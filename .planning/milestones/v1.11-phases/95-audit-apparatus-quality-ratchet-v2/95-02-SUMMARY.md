---
phase: 95-audit-apparatus-quality-ratchet-v2
plan: 02
subsystem: mailglass_admin/test + mailglass_admin/docs + mailglass_admin/mix.exs
tags: [ratchet, baseline, exunit, ci-lane, quality-gate]
dependency_graph:
  requires:
    - 95-01 (RATCHET-GAP-REGISTER.md scaffolded — D-08 commit 1)
  provides:
    - ratchet_baseline_test.exs (D-04/D-05 fail-closed ExUnit baseline assertion)
    - ui-baseline-scores.json (D-03 score baseline — placeholder with all 36 cells)
    - verify.support_contract.admin lane updated (D-08 commit 2)
  affects:
    - 95-03 (Playwright structural.spec.js — D-08 commit 3)
    - 95-04 (LLM seed run — D-08 commit 4, replaces placeholder scores with real scores)
    - 103 (Phase 103 adds compare_baselines/2 call site to activate regression teeth)
tech_stack:
  added: []
  patterns:
    - ExUnit fail-closed required-lane test (mirrors token_parity_test.exs pattern)
    - Path.join(__DIR__, "..", "..", "docs", ...) for files outside priv/
    - if false guard to reference Phase 103 hook point without calling it
key_files:
  created:
    - mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
    - mailglass_admin/docs/ui-baseline-scores.json
  modified:
    - mailglass_admin/mix.exs (verify.support_contract.admin alias updated)
decisions:
  - Use Path.join([__DIR__, "..", "..", "docs", "..."]) for docs/ path (not Application.app_dir — docs/ is outside priv/)
  - Use `if false, do: compare_baselines(%{}, %{})` in setup_all to silence unused-function warning while keeping defp private and never actually calling it
  - All 36 placeholder scores set to 1 (minimum valid score) so range assertion passes on placeholder
metrics:
  duration: ~10 minutes
  completed: 2026-06-14
  tasks: 2
  files_created: 2
  files_modified: 1
---

# Phase 95 Plan 02: Fail-Closed ExUnit Baseline Assertion + Lane Wiring Summary

**One-liner:** Fail-closed ExUnit shape/range gate wired into verify.support_contract.admin; placeholder JSON with all 36 surface×pillar×theme cells at score 1; compare_baselines/2 defined as Phase 103 hook point (defp, never called).

## What Was Built

### Task 1: ratchet_baseline_test.exs + ui-baseline-scores.json

Created `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` (D-04/D-05) with 3 real, non-vacuous tests:

1. **schema_version is present and supported** — asserts `b["schema_version"] == 1`
2. **all 36 graded cells are present** — nested for comprehension across 3 surfaces × 6 pillars × 2 themes; collects and reports all missing paths before asserting
3. **all 36 scores are in the valid range 1–4** — same pattern; collects and reports all out-of-range values before asserting

`compare_baselines/2` is defined as `defp` and acts as the Phase 103 hook point. It collects cells where `current_score < prior_score` and asserts the regression list is empty. In Phase 95 it's never called at runtime; an `if false` guard in `setup_all` makes the Elixir compiler treat it as "referenced" so `--warnings-as-errors` does not abort.

Created `mailglass_admin/docs/ui-baseline-scores.json` — placeholder with all 36 cells, every score set to integer 1 (minimum valid, keeps range assertion green before the real LLM scores land in Plan 95-04).

### Task 2: mix.exs alias wiring

Appended `test/mailglass_admin/ratchet_baseline_test.exs` to the `verify.support_contract.admin` explicit file list (before `--warnings-as-errors`). The alias remains a single "test ..." command. All existing 7 test files are preserved; `mix verify.support_contract.admin` exits 0 with 46 tests (43 existing + 3 new).

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` | 3 tests, 0 failures |
| `mix verify.support_contract.admin` | 46 tests, 0 failures |
| JSON has all 36 cells | 0 missing |
| JSON scores all in 1..4 | PASS |
| `compare_baselines` grep count | 5 (>= 1) |
| `compare_baselines` is `defp` | PASS |
| `compare_baselines` has no real call site | PASS (if-false guard is unreachable at runtime) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Compiler unused-function warning blocked --warnings-as-errors**

- **Found during:** Task 1 verification
- **Issue:** `defp compare_baselines/2` is explicitly required to be private and uncalled (Phase 103 hook). Elixir's compiler emits an "unused function" warning for any `defp` not referenced in the module's call graph, causing `--warnings-as-errors` to abort.
- **Fix:** Added `if false, do: compare_baselines(%{}, %{})` inside `setup_all`. The Elixir compiler's static analysis sees the call in the AST (suppressing the warning); the runtime optimizer eliminates the dead branch so `compare_baselines/2` is never actually invoked. This preserves both the `defp` privacy constraint and the `--warnings-as-errors` gate.
- **Alternatives considered:** Module attribute capture (`@attr &compare_baselines/2`) fails — can't capture private functions at module scope; `_compare_baselines` prefix doesn't suppress Elixir unused-function warnings (only variable underscore is special-cased); making it `def` would suppress the warning but violates the "private function" constraint.
- **Files modified:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs`
- **Commit:** dd9b07a1

## Known Stubs

`mailglass_admin/docs/ui-baseline-scores.json` — all 36 scores are intentionally set to 1 (placeholder). This is the designed state for D-08 commit 2: the placeholder keeps the range assertion green before Plan 95-04 seeds real LLM scores. It is NOT a bug; it is the explicit "establish-and-freeze" design (D-05).

Plan 95-04 (LLM seed run) replaces all 36 scores with real scored values from the ui-audit.sh + LLM scoring step.

## Threat Flags

None. This plan creates test infrastructure and a committed JSON score file. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Self-Check

- [x] `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` exists
- [x] `mailglass_admin/docs/ui-baseline-scores.json` exists and is valid JSON
- [x] 3 tests pass with `--warnings-as-errors`
- [x] `mix verify.support_contract.admin` exits 0
- [x] 36 cells present, all scores in 1..4
- [x] `compare_baselines/2` defined as `defp`, unreachable at runtime
- [x] Commits: dd9b07a1 (Task 1), 6f013fe9 (Task 2)

## Self-Check: PASSED
