---
phase: 177-readable-health-and-coherent-account-navigation
fixed_at: 2026-10-28T22:15:00Z
review_path: /Users/jon/projects/mailglass/.planning/phases/177-readable-health-and-coherent-account-navigation/177-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 177: Code Review Fix Report

**Fixed at:** 2026-10-28
**Source review:** /Users/jon/projects/mailglass/.planning/phases/177-readable-health-and-coherent-account-navigation/177-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 1 (critical_warning; IN-01..IN-04 out of scope)
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-01: Single-option Account control renders a fake "selected" identity and removes the only way to switch

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
**Commit:** 3dfadea8
**Status:** fixed: requires human verification (logic change; tests cover both review shapes)
**Applied fix:** `account_variant/3` became `account_variant/4`, taking the selected tenant id as well as the resolved label. The review's guard compared an id to `only.id`, but the old call site passed the label, so the id is now threaded through from `account_context/1`. A single option collapses to static named text only when the state is not `:select_required` and the selected id is nil or equals the sole option's id. Any other single-option case returns `:picker`. This covers `:select_required` with one option and a selected Account that is not the sole listed one.

Deviation from the review's suggestion: for `:select_required` with one option it renders the picker, not a static `:prompt` text. The picker's summary already reads "Choose an Account" (no Account selected, so no bold name and no sr-only id), and it keeps the sole Account reachable. A static prompt would have no way to choose. No new copy or tone was introduced.

Tests added in `phase177_account_scope_test.exs` (run for both sidebar and mobile layouts):
- one option + `:select_required`: switcher label is "Choose an Account", label text is not bold, the sole Account is only a menu option, and no `operator-account-id` is rendered.
- selected `quiet-account` with sole option `busy-account`: picker kept, labelled "Change Account: quiet-account", `busy-account` offered and not `aria-current`.
- one option that is the selected Account: still static, no picker (regression guard for D-10).

## Verification

Run in the main checkout, because `workflow.use_worktrees` is `false`. No worktree was created.

- `mix test test/mailglass_admin/phase177_account_scope_test.exs`: 22 tests, 0 failures.
- `mix test --seed 0` in `mailglass_admin/`: 1085 tests, 0 failures, 1 excluded.
- `mix compile --warnings-as-errors`: clean.
- `mix format --check-formatted` on the two changed files: clean. A project-wide `mix format` in `mailglass_admin/` also reformats ten unrelated files that are already unformatted on `main` (for example `auth.ex` and `bucket_a_coverage_test.exs`). I reverted those and committed only the two files for this fix. A project-wide `--check-formatted` therefore fails before and after this fix.
- No `priv/static` assets were touched.

---

_Fixed: 2026-10-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
