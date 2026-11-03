---
phase: 177-readable-health-and-coherent-account-navigation
fixed_at: 2026-10-28T22:40:00Z
review_path: /Users/jon/projects/mailglass/.planning/phases/177-readable-health-and-coherent-account-navigation/177-REVIEW.md
iteration: 2
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 177: Code Review Fix Report

**Fixed at:** 2026-10-28
**Source review:** /Users/jon/projects/mailglass/.planning/phases/177-readable-health-and-coherent-account-navigation/177-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 5 (fix_scope `all`: WR-01 from iteration 1, IN-01..IN-04 from iteration 2)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### WR-01: Single-option Account control renders a fake "selected" identity and removes the only way to switch

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
**Commit:** 3dfadea8
**Iteration:** 1
**Status:** fixed: requires human verification (logic change; tests cover both review shapes)
**Applied fix:** `account_variant/3` became `account_variant/4`, taking the selected tenant id as well as the resolved label. The review's guard compared an id to `only.id`, but the old call site passed the label, so the id is now threaded through from `account_context/1`. A single option collapses to static named text only when the state is not `:select_required` and the selected id is nil or equals the sole option's id. Any other single-option case returns `:picker`. This covers `:select_required` with one option and a selected Account that is not the sole listed one.

Deviation from the review's suggestion: for `:select_required` with one option it renders the picker, not a static `:prompt` text. The picker's summary already reads "Choose an Account" (no Account selected, so no bold name and no sr-only id), and it keeps the sole Account reachable. A static prompt would have no way to choose. No new copy or tone was introduced.

Tests added in `phase177_account_scope_test.exs` (run for both sidebar and mobile layouts):
- one option + `:select_required`: switcher label is "Choose an Account", label text is not bold, the sole Account is only a menu option, and no `operator-account-id` is rendered.
- selected `quiet-account` with sole option `busy-account`: picker kept, labelled "Change Account: quiet-account", `busy-account` offered and not `aria-current`.
- one option that is the selected Account: still static, no picker (regression guard for D-10).

### IN-01: Invalid HTML content model in the observation group

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/health_overview.ex`, `mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs`
**Commit:** 33ab7c82
**Iteration:** 2
**Applied fix:** The wrapper `<span class="inline-flex ...">` around the `<p data-testid="operator-health-last-checked">` and the Refresh button is now a `<div>` with the same classes. `data-testid` is unchanged. The existing selectors in `health_overview_test.exs`, `e2e/phase177-health.spec.js` and `e2e/health-tooltips.spec.js` key on `data-testid` / ids, not on the wrapper tag, so they still match. One test added: the freshness `p` sits under a `div` and is never a child of a `span`.

### IN-02: Scope group accessible name absorbs the sr-only Account id

**Files modified:** `mailglass_admin/lib/mailglass_admin/surface_nav.ex`, `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
**Commit:** 056334f2
**Iteration:** 2
**Applied fix:** `SurfaceNav.nav/1` computes `surface-nav-scope-label-<layout>` and passes it to the `scope_header` slot (`render_slot(@scope_header, @label_id)`). The group's `aria-labelledby` points at that id when `scope == :account`. `Shell.account_context/1` takes a new `label_id` attr and puts it on the visible "Account" label span, in both the picker and static variants. The group name is now "Account" and no longer includes the sr-only `tenant_id`. The Preview scope group still uses the header id, because its header holds only the static "Scoped to an Account" paragraph. The header element and its id stay as they were, so the prohibition contract tests that look it up still pass.

The existing test that resolved `aria-labelledby` to the header was updated. It now asserts the labelledby target's text is exactly "Account" and does not contain `operator-account-id`. It also asserts the header still holds the switcher and the sr-only id.

### IN-03: Header `aria-describedby` can reference an empty description

**Files modified:** `mailglass_admin/lib/mailglass_admin/surface_nav.ex`, `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
**Commit:** 442d11dd
**Iteration:** 2
**Applied fix:** `aria-describedby` and the sr-only description span are rendered only when `@scope == :account` and `@description != ""`. Test added: with all scoped paths blank, the group has no `aria-describedby`, no description span, and no scoped links.

### IN-04: Operator Account control does not trim whitespace-only Account ids

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs`
**Commit:** cc1fcfbc
**Iteration:** 2
**Status:** fixed: requires human verification (logic change; mutation-checked test)
**Applied fix:** I first traced reachability. `OperatorLive` and `InboundLive` each have their own `blank_to_nil/1` that guards only `nil` and `""`, so `?tenant_id=%20` does reach the shell as `selected_tenant_id`. The shell's `blank_to_nil/1` now treats whitespace-only binaries as blank and passes non-blank values through unchanged (not trimmed, matching the review's snippet). Its other uses (`build_query/2` tenant id, `item_path/2` nav paths, `preserved_switch_query/1` values) all want a blank value dropped, so nothing relies on whitespace values. `account_context/1` also normalizes `selected_tenant_id` first. Without that, a blank id would still render the sr-only `operator-account-id` span and the single-option variant check would compare a blank id against the sole option.

Test added: whitespace-only selected ids (`"   "`, `"\t"`, `" \n "`) render the "Choose an Account" prompt (not bold) with no `operator-account-id`, and a single option with a blank selection renders the auto-select static label. Without the fix this test fails; I confirmed by reverting `shell.ex` and re-running.

Not changed: the LiveViews' own `blank_to_nil/1` still treats `" "` as a selected Account for the body scope, so the page body would be scoped to a blank Account while the header shows none. That is outside this finding (the review scoped it to the shell control) and is a candidate for a follow-up.

## Verification

Run in the main checkout, because `workflow.use_worktrees` is `false`. No worktree was created. All commands ran from `mailglass_admin/` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

- `mix compile --warnings-as-errors`: clean.
- `mix format --check-formatted`: clean for the whole admin package.
- `mix test --seed 0`: 1088 tests, 0 failures, 1 excluded (baseline 1085; +3 new tests for IN-01, IN-03 and IN-04; the IN-02 change updated an existing test's assertions).
- No `priv/static` assets were touched and no new Tailwind utility classes were introduced.

---

_Fixed: 2026-10-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
