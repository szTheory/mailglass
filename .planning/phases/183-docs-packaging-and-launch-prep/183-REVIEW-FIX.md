---
phase: 183-docs-packaging-and-launch-prep
fixed_at: 2026-11-17T03:50:22Z
review_path: .planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 183: Code Review Fix Report

## Iteration 3

**Fixed at:** 2026-11-17T03:50:22Z
**Source review:** `.planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md`
**Iteration:** 3

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-01: Required workflow commands can be matched inside comments

**Files modified:** `test/scripts/brand_docs_ci_wiring_test.exs`
**Commit:** `9697bb59`
**Applied fix:** Assert exact `run:` values on the expected named workflow steps, with the workflow field indentation anchored so comments and unrelated step text cannot satisfy command checks. Added mutation coverage for commented-out docs/dependency commands and retained the locked dependency, CI Green edge, and failure-propagation checks.

## Verification

Verification ran in the main checkout because `workflow.use_worktrees` is `false`. Formatted the changed Elixir file and ran `mix test test/scripts/brand_docs_ci_wiring_test.exs` with the repository's Elixir 1.18.4 / OTP 27 toolchain; 2 tests passed with 0 failures.

## Iteration 2 (previous fixes)

**Fixed at:** 2026-11-17T01:56:35Z
**Source review:** `.planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

### WR-03: Plural PO message fields bypass brand scanning

**Files modified:** `scripts/brand_name_lint.exs`, `test/scripts/brand_name_lint_test.exs`
**Commit:** `84cfc573`
**Applied fix:** The Gettext scanner now recognizes `msgid_plural` and appends its quoted continuation lines. A plural-entry fixture confirms that a prohibited spelling on a continuation line is detected.
**Status:** fixed: requires human verification

**Verification:** Ran in the main checkout with the repository's Elixir 1.18.4 / OTP 27 toolchain. The focused linter test (12 tests) and adopter-corpus lint check passed. The test emitted the existing optional `opentelemetry_exporter` warning.

## Iteration 1 (previous fixes)

**Fixed at:** 2026-11-17T01:44:22Z
**Source review:** `.planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

### WR-01: Advisory favicon job never rasterizes

**Files modified:** `.github/workflows/advisory-matrix.yml`, `mailglass_admin/e2e/favicon-capture.cjs`
**Commits:** `5a7af911`, `e78b1289` (follow-up)
**Applied fix:** The advisory archives the candidate commit into an isolated temporary checkout, runs browser capture there, and validates the generated catalog with `FaviconCatalog.validate_catalog/2`. It removes the temporary checkout after success or failure. The capture script is unchanged in the final tree, preserving the producer hash recorded by the existing immutable catalog.

### WR-02: Case linter accepts unlisted capitalization variants

**Files modified:** `scripts/brand_name_lint.exs`, `test/scripts/brand_name_lint_test.exs`
**Commit:** `c76a5788`
**Applied fix:** Product-name matching now handles any capitalization and reports or rewrites every spelling except lowercase `mailglass`. API module names and wire identifiers remain masked case-insensitively.

### WR-03: Multiline Gettext values bypass brand scanning

**Files modified:** `scripts/brand_name_lint.exs`, `test/scripts/brand_name_lint_test.exs`
**Commit:** `eeac6fce`
**Applied fix:** The Gettext scanner now tracks `msgid` and `msgstr` fields and appends their quoted continuation lines before scanning, while ending values at other PO lines.

### WR-04: Multiline inline code sample is rewritten as prose

**Files modified:** `scripts/brand_name_lint.exs`, `test/scripts/brand_name_lint_test.exs`, `mailglass_admin/lib/mailglass_admin/preview/discovery.ex`
**Commit:** `c8166c4c`
**Applied fix:** Markdown code-span detection now spans line breaks, and the lowercase rewrite temporarily protects those spans while processing selected lines. The Boundary example again uses the `Mailglass` module name.

### WR-05: Published Admin guide references an excluded checklist

**Files modified:** `mailglass_admin/docs/design-system.md`, `test/mailglass/docs_contract_test.exs`
**Commit:** `4db125d2`
**Applied fix:** The packaged guide links directly to the public repository checklist instead of presenting its `.planning` path as package-relative.

**Verification:** Ran in the main checkout because `workflow.use_worktrees` was `false`. `actionlint`, the read-only favicon pin check, catalog validation, focused favicon and brand linter tests, the adopter-corpus lint check, the Admin Discovery test, and the packaged-doc contract test passed. Browser capture was not repeated, preserving the phase's single-capture evidence constraint.

---

_Fixed: 2026-11-17T03:50:22Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
