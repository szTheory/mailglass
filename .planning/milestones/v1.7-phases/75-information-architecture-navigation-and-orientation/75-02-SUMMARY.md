---
phase: 75-information-architecture-navigation-and-orientation
plan: "02"
subsystem: mailglass_admin/operator
tags:
  - orientation-strip
  - shell-component
  - token-clean
  - tdd
  - wave-2
dependency_graph:
  requires:
    - 75-01 (Wave 0 stubs — shell_test.exs orientation_strip describe stubs)
  provides:
    - Shell.orientation_strip/1 public function component in shell.ex
    - Orientation strip wired to all three operator surfaces (deliveries/inbound/preview)
  affects:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix.Component attr :surface discriminator with values: list (compile-time validation)
    - Frozen per-surface copy via private copy_for/1 helper
    - TDD RED/GREEN cycle — shell_test.exs stubs un-skipped, RED confirmed, GREEN implemented
    - MIX_DEPS_PATH/MIX_BUILD_PATH worktree pattern for admin test execution
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
decisions:
  - "copy_for/1 private helper (not inline case in HEEx) — keeps the function body readable and
    the frozen copy table easily auditable; follows the prefer-function-over-macro convention"
  - "Full module reference MailglassAdmin.Operator.Shell.orientation_strip rather than
    Shell.orientation_strip — matches existing call-site style in operator_live.ex and
    inbound_live.ex (both use full-module for shell functions, no alias)"
  - "Bundle rebuild produced no diff — all classes (text-label, p-md, gap-sm, etc.) were already
    in the JIT-scanned bundle from other components; gate passes with exit 0 per plan spec"
  - "voice_test 'Oops' failure excluded from pass/fail — pre-existing phoenix.mjs dep-JS
    noise documented in project memory; unrelated to this plan's changes"
metrics:
  duration_minutes: 10
  completed_date: "2026-06-04"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 8
  files_created: 0
---

# Phase 75 Plan 02: Extract Shell.orientation_strip/1 and Wire All Surfaces Summary

**One-liner:** Public `Shell.orientation_strip/1` component extracted from `operator_live.ex` private defp, wired to all three surfaces (Deliveries/Inbound/Preview) with frozen symptom-first copy and token-clean markup (`text-label`, not `text-sm`).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 (RED) | Add failing tests for Shell.orientation_strip/1 | 50176c6b | shell_test.exs |
| 1 (GREEN) | Extract Shell.orientation_strip/1, wire all three surfaces | 151a63e8 | shell.ex, operator_live.ex, inbound_live.ex, preview_live.ex, shell_test.exs, operator_live_test.exs, inbound_live_test.exs, preview_live_test.exs |
| 2 | Rebuild admin bundle (no-op: all classes already in JIT scan) | — | priv/static/app.css (no change) |

## What Was Built

**Task 1 — `Shell.orientation_strip/1` (TDD RED/GREEN):**

RED phase:
- Un-skipped 4 `@tag :skip` stubs in `shell_test.exs` and implemented assertions
- Confirmed UndefinedFunctionError (function did not exist) — 4 tests, 4 failures

GREEN phase:
- Added `def orientation_strip/1` to `shell.ex` after `defp flash_region/1`
- `attr :surface, :atom, values: [:deliveries, :inbound, :preview], required: true`
- Dynamic `data-testid={"#{@surface}-orientation"}` from surface atom
- `text-label` on ul (not `text-sm`) — born token-clean; no motion-reveal/phx-mounted
- Frozen copy via `copy_for/1` private helper: 3 symptom-first bullets per surface
- Deliveries: "Email never arrived? Start here." / "Replay changed nothing? View the event timeline." / "Address keeps getting blocked? Check suppressions."
- Inbound: "Message didn't route as expected? Inspect the routing trace." / "No mailbox matched? Check the no-match record." / "Failed ingest? Review the provider signature log."
- Preview: "No mailables found? Define a mailable module in your app." / "Mailable not showing? Ensure it's compiled." / "Preview not rendering? Check your template syntax."

Call-site updates:
- `operator_live.ex`: replaced `<.orientation_strip />` with `<MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />`, removed private `defp orientation_strip/1` (31-line extraction complete)
- `inbound_live.ex`: added `Shell.orientation_strip surface={:inbound}` before `inbound-empty-detail` div in the `is_nil(@detail)` branch
- `preview_live.ex`: added `Shell.orientation_strip surface={:preview}` before `preview-empty-mailables` div in the `@mailables == []` branch; preserved `"No mailables discovered"` heading (D-06/Pitfall 5)

Test assertions added:
- `shell_test.exs`: 4 un-skipped tests (testids, frozen copy, text-label class)
- `operator_live_test.exs`: `deliveries-orientation` testid assertion in no-selection test
- `inbound_live_test.exs`: `inbound-orientation` testid assertion in no-selection test
- `preview_live_test.exs`: new test verifying `preview-orientation` AND `preview-empty-mailables` coexist in the same render (both testids present simultaneously)

**Task 2 — Bundle rebuild:**
- `mix mailglass_admin.assets.build` ran successfully (115ms)
- `git diff --exit-code mailglass_admin/priv/static/` exits 0 — all new component classes (`text-label`, `p-md`, `gap-sm`, `rounded-box`, `border-base-300`, `bg-base-200`) were already emitted by other components in the JIT scan
- No bundle change committed — gate passes per plan spec (exit 0 is acceptable)

## Deviations from Plan

### Auto-fixed Issues

None.

### Worktree Test Execution Pattern

The worktree's `mailglass_admin/` directory has no `deps/` or `_build/` (these are not tracked in git). Admin tests require:
```bash
cd /path/to/worktree/mailglass_admin && \
  MIX_DEPS_PATH=/path/to/main/mailglass_admin/deps \
  MIX_BUILD_PATH=/path/to/main/mailglass_admin/_build \
  mix test ...
```
This is not a deviation — it's the correct worktree test execution pattern for this project.

## Verification Results

All plan verification checks pass:

- `grep -c "def orientation_strip" shell.ex` → 1 (public def)
- `grep -c "defp orientation_strip" operator_live.ex` → 0 (private removed)
- `grep -c "Shell.orientation_strip surface={:deliveries}" operator_live.ex` → 1
- `grep -c "Shell.orientation_strip surface={:inbound}" inbound_live.ex` → 1
- `grep -c "Shell.orientation_strip surface={:preview}" preview_live.ex` → 1
- `grep -c "preview-empty-mailables" preview_live.ex` → 1 (preserved)
- `grep "Email never arrived" shell.ex` → frozen copy verbatim present
- `grep -c "text-sm"` on non-comment lines of shell.ex → 0 (token-clean)
- `git diff --exit-code mailglass_admin/priv/static/` → exit 0
- Target tests: 61 tests, 0 failures (6 excluded via @tag :skip)
- Full admin suite: 146 tests, 0 failures (7 excluded) — voice_test "oops" pre-existing dep-JS noise excluded per project memory

## Gap Register Coverage

| Gap | Description | Status |
|-----|-------------|--------|
| GAP-07 | Deliveries 390px orientation readability | CLOSED — deliveries-orientation strip present when no delivery selected |
| GAP-09 | Inbound 390px orientation readability | CLOSED — inbound-orientation strip present when no detail selected |
| GAP-11 | Preview 390px orientation readability | CLOSED — preview-orientation strip present when mailables is empty |

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `orientation_strip/1` renders static frozen strings with no dynamic data or user input. T-75-02-02 mitigation applied: `attr :surface, :atom, values: [...]` provides compile-time validation for the surface atom.

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| `shell_test.exs` | 1 @tag :skip in "aria-current nav resolution" | Plan 75-03 implements the Overview branch |
| `operator_live_test.exs` | 5 @tag :skip in "Operator Overview branch" | Plan 75-03 implements the Overview branch |

## Self-Check: PASSED

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — contains `def orientation_strip` (verified)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — `defp orientation_strip` removed, `Shell.orientation_strip surface={:deliveries}` present (verified)
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — `Shell.orientation_strip surface={:inbound}` present (verified)
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — `Shell.orientation_strip surface={:preview}` present, `preview-empty-mailables` preserved (verified)
- Commits `50176c6b` (RED) and `151a63e8` (GREEN) exist in git log (verified)
- `priv/static/app.css` contains `text-label` utility class (verified)
