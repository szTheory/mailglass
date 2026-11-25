---
phase: 183-docs-packaging-and-launch-prep
reviewed: 2026-11-17T15:15:57Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/ci.yml
  - ci/contracts/brand_docs_output_test.exs
  - scripts/verify_brand_docs.sh
  - mailglass_admin/e2e/docs-theme-contract.cjs
  - mailglass_admin/e2e/docs-theme-contract.test.cjs
  - test/scripts/brand_docs_contract_test.exs
  - test/scripts/brand_docs_ci_wiring_test.exs
  - config/test_exceptions.exs
  - brandbook/status-marks.json
  - scripts/gsd-regression-gate.sh
  - mailglass_admin/test/support/admin_bootstrap.ex
  - mailglass_admin/test/mailglass_admin/test_support/admin_bootstrap_test.exs
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/favicon-capture.cjs
  - mailglass_admin/e2e/favicon-capture-order.test.cjs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
  necessity: 0
status: clean
---

# Phase 183: Code Review Report

**Reviewed:** 2026-11-17T15:15:57Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** clean

## Summary

The prior standard-depth review of the first seven files remains clean. It included the WR-01 fix: workflow assertions require the exact active `run:` value on the named step, dependency checks bind the locked command to the matching named step and working directory, the docs job rejects `continue-on-error`, and CI Green requires the docs job.

The next supplemental review covered `config/test_exceptions.exs` and `brandbook/status-marks.json`. The exception registry's changed source reference points to the live `@tag :skip` at `test/mailglass/docs_contract_test.exs:826`; its fields and expiry date match the validation script's contract. The status-marks JSON uses the pinned zip SHA and member path, and its schema, role mappings, dimensions, labels, shapes, and canonical key order match the generator and its validation fixtures. No discrepancies were found. Focused checks were reported as passed and were not rerun.

The final Docker browser gate review found no endpoint exposure, resource-limit, cache, or Axe-scope issue. It initially identified a gap in the container readiness preflight's deadline; the follow-up below confirms that fix. No active findings remain.

## Follow-up Review (two files added)

- `config/test_exceptions.exs`: the only changed entry updates the skip source from line 807 to line 826, where the tag currently appears. The required metadata is present, and all entries expire on 2026-12-31.
- `brandbook/status-marks.json`: the recorded zip hash matches `brandbook/brand.pin.json`, and the member name matches the pinned root plus `mailglass-brand-book.html`. The committed data follows the generator's document shape and canonical encoding contract.

No tests or online re-extraction were run during that follow-up review.

## Follow-up Review (final Docker browser gate)

- `mailglass_admin/test/support/admin_bootstrap.ex` remains loopback-only, and the focused bootstrap test asserts that address. The gate no longer enables a bind-all override.
- `scripts/gsd-regression-gate.sh` checks readiness on host loopback and then from the matching Playwright container through `host.docker.internal` before launching Playwright. Its failure branch logs server output and stops the server. The browser container has explicit memory, CPU, process, shared-memory, and temporary-filesystem limits; its XDG cache is under writable `/tmp`.
- `mailglass_admin/e2e/structural.spec.js` uses legacy Axe mode only for the preview cell, retaining the existing WCAG 2.2 AA tags and per-theme baseline comparison.

## Follow-up Review (preflight deadline fix)

- The previous WR-01 is resolved. `scripts/gsd-regression-gate.sh` now starts a 3-second wall-clock timer immediately after creating the HTTP request, before asynchronous hostname resolution completes, and clears it on response or request error. The timeout therefore covers the DNS gap identified in the earlier review.
- Static checks (`bash -n`, embedded runner `node --check`, and `git diff --check`) were reported as passed and were not rerun during that review.

## Follow-up Review (favicon capture ordering)

- `mailglass_admin/e2e/favicon-capture-order.test.cjs` calls `captureAndSaveTile`, the same production helper used by `captureEngine`. Its gated `img.decode()` mock demonstrates that capture cannot reach the screenshot/save stage while decoding is pending, then checks the final order and saved bytes.
- `captureEngine` supplies a validation callback to that helper. PNG signature/dimensions and the total-byte cap are checked before the helper's exclusive file write; the PNG count cap is checked before capture. The order test now passes a validator and asserts it runs after screenshot completion while the output file is still absent, then checks the saved bytes.
- Playwright is loaded inside `main()` only after the `--check` early return. Requiring the module for the order test therefore uses only Node built-ins and does not require installed browser dependencies.
- CI runs the cheap Node test after Node setup and before dependency installation, database setup, Playwright browser installation, and the full browser gate. The job-level PostgreSQL service and runtime setup still occur before its steps.

No tests were run during this follow-up review.

## Narrative Findings (AI reviewer)

The original seven-file review and all follow-ups are clean. The preflight deadline warning was resolved before this favicon review; no active findings remain.

---

_Reviewed: 2026-11-17T15:15:57Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
