---
phase: 183-docs-packaging-and-launch-prep
fixed_at: 2026-11-17T01:44:22Z
review_path: .planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 183: Code Review Fix Report

**Fixed at:** 2026-11-17T01:44:22Z  
**Source review:** `.planning/phases/183-docs-packaging-and-launch-prep/183-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

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

## Verification

All verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- `actionlint .github/workflows/advisory-matrix.yml` passed.
- `node -c mailglass_admin/e2e/favicon-capture.cjs` and the read-only `--check` pin validation passed.
- The independent catalog validator and focused favicon catalog test passed against the existing immutable catalog (13 tests).
- `test/scripts/brand_name_lint_test.exs` passed (11 tests); the full adopter-corpus lint check passed.
- The focused Admin Discovery test passed (6 tests), and the packaged-doc contract test passed (1 selected test).
- `git diff --check` passed. No remote CI action was run. Browser capture was not repeated, preserving the phase's single-capture evidence constraint.

---

_Fixed: 2026-11-17T01:44:22Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
