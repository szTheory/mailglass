---
phase: 173-consistency-and-delivery-evidence
reviewed: 2026-10-10T10:48:28Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - .github/workflows/ci.yml
  - compose.demo.yml
  - reference/demo_app/Dockerfile
  - reference/demo_app/mix.exs
  - reference/demo_app/assets/e2e/phase173-evidence.spec.js
  - reference/demo_app/assets/e2e/persona-screenshots.spec.js
  - reference/demo_app/assets/scripts/check-demo-browser-deps.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs
  - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
  - reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs
  - mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex
  - mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs
  - mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex
  - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - reference/demo_app/storybook/primitives/theme_picker.story.exs
  - scripts/run_demo_browser_evidence.sh
  - scripts/test_run_demo_browser_evidence.sh
  - scripts/check_phase173_candidate.sh
  - scripts/test_check_phase173_candidate.sh
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 173: Code Review Report

**Reviewed:** 2026-10-10T10:48:28Z  
**Depth:** standard  
**Files Reviewed:** 24  
**Status:** issues_found

## Summary

Reviewed the listed Phase 173 source and contract-test files. The exact-candidate evidence gate can accept a mixed dirty/clean capture set as clean, and the default Compose E2E service omits the identity required by the reset guard. The Admin capture writer also labels arbitrary file bytes as PNG evidence without validating PNG structure.

## Narrative Findings (AI reviewer)

### CR-01: Mixed capture dirtiness can be recorded as a clean candidate — BLOCKER

**File:** `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:283-284`
**Issue:** `candidate_dirty` is computed with `captures.every((capture) => capture.candidate_dirty)`. If any capture is marked clean, the checkpoint records `false`, even when another capture is marked dirty. The retained-evidence gate in `scripts/check_phase173_candidate.sh:466` accepts only that aggregate field and does not check each capture's dirtiness, so a mixed set can be certified as a clean exact-candidate capture. The values are currently sourced from one environment variable, but the validator accepts inconsistent manifests and is the integrity boundary used by the delivery gate.
**Fix:** Reject capture sets with inconsistent `candidate_dirty` values, and derive the checkpoint value with `captures.some((capture) => capture.candidate_dirty)`. In the retained-evidence validator, also require every capture's `candidate_dirty` to be exactly `false` before passing.

### WR-01: Default Compose E2E run lacks the reset identity required by its specs — WARNING

**File:** `compose.demo.yml:45-46,85-94`
**Issue:** The default `demo_e2e` command runs the full `test:e2e:ci` Playwright suite, but the Compose defaults leave `DEMO_EVIDENCE_RUN_ID` and `DEMO_EVIDENCE_PROJECT_ID` empty. Both the Phase 173 and persona screenshot specs call `resetDisposableEvidence` before each test; that helper rejects an empty run ID at `reference/demo_app/assets/scripts/check-persona-reset-target.cjs:34-37`. Consequently, running the declared default E2E service without wrapper-provided environment values fails its evidence specs before they can run.
**Fix:** Ensure the default E2E service and demo service receive the same valid disposable evidence project ID, or make the default E2E command use a runner that supplies and validates that shared identity.

### WR-02: Actual capture writer accepts non-PNG bytes as screenshot evidence — WARNING

**File:** `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex:189-208`
**Issue:** In `:files` mode, the writer only checks that the screenshot path is a regular file and hashes its bytes. It does not check the PNG signature or image dimensions. The success test at `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs:107-135` confirms this gap by treating a 12-byte truncated PNG prefix as a valid actual capture. A corrupted or misdirected output file can therefore be recorded as actual screenshot proof.
**Fix:** Validate the PNG signature and a complete, sane IHDR before hashing and recording an actual capture; update the success fixture to use a valid PNG and add a rejection case for truncated or non-PNG bytes.

---

_Reviewed: 2026-10-10T10:48:28Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
