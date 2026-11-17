---
phase: 183-docs-packaging-and-launch-prep
reviewed: 2026-11-17T01:24:35Z
depth: standard
files_reviewed: 126
files_reviewed_list:
  - .github/workflows/advisory-matrix.yml
  - .github/workflows/publish-hex.yml
  - .impeccable/config.json
  - .impeccable/design.json
  - CONTRIBUTING.md
  - DESIGN.md
  - MAINTAINING.md
  - README.md
  - brandbook/brand.pin.json
  - brandbook/exdoc/code-colors.css
  - brandbook/exdoc/mailglass-mark-dark.svg
  - brandbook/exdoc/mailglass-mark-light.svg
  - brandbook/exdoc/theme-mark.js
  - brandbook/v2/avatar-512-dark.png
  - brandbook/v2/avatar-512-light.png
  - brandbook/v2/brand.json
  - brandbook/v2/favicon-16-dark.png
  - brandbook/v2/favicon-16-light.png
  - brandbook/v2/favicon-32-dark.png
  - brandbook/v2/favicon-32-light.png
  - brandbook/v2/favicon.ico
  - brandbook/v2/favicon.svg
  - brandbook/v2/mailglass-mark-dark.svg
  - brandbook/v2/mailglass-mark-light.svg
  - brandbook/v2/social-card-1280x640.png
  - docs/api_stability.md
  - docs/brand-v2-compatibility.md
  - docs/migration-policy.md
  - docs/upgrade-from-0.x.md
  - guides/b2c-first-adopter.md
  - guides/compatibility-and-deprecations.md
  - guides/dkim-setup.md
  - guides/migration-from-swoosh.md
  - guides/multi-tenancy.md
  - guides/operator-incident-support.md
  - guides/rate-limiting.md
  - guides/run-the-demo.md
  - guides/telemetry.md
  - guides/unsubscribe.md
  - guides/upgrading-from-v0_1.md
  - guides/upgrading-to-v1_0.md
  - guides/upgrading-to-v2_0.md
  - guides/webhooks.md
  - lib/mailglass/application.ex
  - lib/mailglass/compliance/unsubscribe_html/state.html.heex
  - lib/mailglass/deliverability/dkim.ex
  - lib/mailglass/deliverability/resolver.ex
  - lib/mailglass/deliverability/spf.ex
  - lib/mailglass/error.ex
  - lib/mailglass/errors/config_error.ex
  - lib/mailglass/events.ex
  - lib/mailglass/installer/doctor.ex
  - lib/mailglass/installer/templates.ex
  - lib/mailglass/message.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/optional_deps/opentelemetry.ex
  - lib/mailglass/repo.ex
  - lib/mailglass/router.ex
  - lib/mailglass/telemetry.ex
  - lib/mailglass/webhook/caching_body_reader.ex
  - lib/mailglass/webhook/router.ex
  - lib/mix/tasks/mailglass.docs.check.ex
  - lib/mix/tasks/mailglass.doctor.ex
  - lib/mix/tasks/mailglass.gen.migration.ex
  - lib/mix/tasks/mailglass.gen.unsubscribe.ex
  - lib/mix/tasks/mailglass.install.ex
  - lib/mix/tasks/mailglass.publish.check.ex
  - mailglass_admin/README.md
  - mailglass_admin/docs/compatibility-and-deprecations.md
  - mailglass_admin/docs/design-system.md
  - mailglass_admin/e2e/brand-name-lint-red.test.cjs
  - mailglass_admin/e2e/docs-theme-contract.cjs
  - mailglass_admin/e2e/docs-theme-contract.test.cjs
  - mailglass_admin/e2e/favicon-capture.cjs
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/discovery.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/package.json
  - mailglass_admin/priv/static/favicon.svg
  - mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs
  - mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs
  - mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs
  - mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs
  - mailglass_admin/test/mailglass_admin/phase182_journey_test.exs
  - mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/support/favicon_catalog.ex
  - mailglass_inbound/README.md
  - mailglass_inbound/lib/mailglass_inbound/inbound_message.ex
  - mailglass_inbound/mix.exs
  - mix.exs
  - scripts/brand_docs_check.exs
  - scripts/brand_name_lint.exs
  - scripts/brand_pin.exs
  - scripts/brand_trademark_gate.exs
  - test/example/README.md
  - test/mailglass/docs/operator_incident_support_guide_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/docs_migration_smoke_test.exs
  - test/mailglass/operator/suppressions_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/publish/brand_asset_allowlist_test.exs
  - test/mailglass/stability_contract_test.exs
  - test/reference_host/public_seams_contract_test.exs
  - test/scripts/brand_design_md_test.exs
  - test/scripts/brand_docs_contract_test.exs
  - test/scripts/brand_name_lint_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
  - test/scripts/lane_classification_drift_test.exs
  - test/scripts/readme_image_contract_test.exs
  - test/support/ci_lanes.ex
  - test/support/webhook_case.ex
findings:
  critical: 0
  warning: 5
  info: 0
  total: 5
  necessity: 0
status: issues_found
---

# Phase 183: Code Review Report

**Reviewed:** 2026-11-17T01:24:35Z  
**Depth:** standard  
**Files Reviewed:** 126  
**Status:** issues_found

## Summary

Reviewed the Phase 183 task-commit source scope at standard depth. Five warnings remain: the favicon advisory job does not rasterize, the casing linter misses valid violation forms and corrupts a multiline code example, and the published Admin guide points to a checklist excluded from its package. The evaluation-scope resolver command was unavailable in the installed GSD runtime, so scope was reconstructed from the completed plan summaries and task commits. The Admin Hex package tarball could not be built locally because the pinned Elixir 1.18.4 runtime is not installed; the package allowlist confirms the guide is included while `.planning` is excluded. No tests were run and no source files were edited.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Advisory favicon job never rasterizes

**Severity:** WARNING  
**File:** `.github/workflows/advisory-matrix.yml:478`  
**Issue:** The job named “Favicon Raster Re-render Advisory” invokes `node e2e/favicon-capture.cjs --check`. In that mode, the script verifies only source/pin/served-file hashes and returns at `mailglass_admin/e2e/favicon-capture.cjs:333-335`, before launching any browser. The path-filtered advisory therefore cannot detect changed raster output or rendering regressions, despite installing Chromium, Firefox, and WebKit.
**Fix:** Run the browser capture mode and validate its generated catalog with the independent catalog validator, using an isolated output location and cleanup for the ephemeral CI artifact.

### WR-02: Case linter accepts unlisted capitalization variants

**Severity:** WARNING  
**File:** `scripts/brand_name_lint.exs:4`  
**Issue:** `@proper_name` recognizes only the exact spellings `Mailglass`, `MailGlass`, and `MAILGLASS`. A prohibited prose spelling such as `mAiLgLaSs` does not match, so `scan_repo` accepts it and the lowercasing rewrite leaves it unchanged. This violates the documented requirement that the product name be lowercase in prose (`DESIGN.md:88`).
**Fix:** Match the product token case-insensitively, then report/rewrite every matched token whose original text is not `mailglass`, while continuing to mask structural API and wire identifiers.

### WR-03: Multiline Gettext values bypass brand scanning

**Severity:** WARNING  
**File:** `scripts/brand_name_lint.exs:267-276`  
**Issue:** `gettext_fragments/1` only collects lines that independently match a complete `msgid` or `msgstr` expression. Standard PO continuation lines are ignored; for example, `msgid ""` followed by `"Mailglass text"` yields no lint fragment for the prohibited spelling. The scanner inventories `.po`/`.pot` files, so multiline translations silently escape the new gate.
**Fix:** Parse PO entries including quoted continuation lines with a PO parser (or a complete stateful parser) and lint the concatenated `msgid`/`msgstr` values.

### WR-04: Multiline inline code sample is rewritten as prose

**Severity:** WARNING  
**File:** `mailglass_admin/lib/mailglass_admin/preview/discovery.ex:38`  
**Issue:** The multiline inline code span contains `deps: [Mailglass]`, the actual root boundary module. The linter's `@inline_code` regex at `scripts/brand_name_lint.exs:11` excludes newlines, so the span is not protected and the phase lowercasing rewrite changed the sample to `deps: [mailglass]`. That is not a valid Elixir module reference and misleads adopters copying the documented configuration.
**Fix:** Restore `Mailglass` in the example and make code-span masking/rewrite preserve inline spans that cross line breaks.

### WR-05: Published Admin guide references an excluded checklist

**Severity:** WARNING  
**File:** `mailglass_admin/docs/design-system.md:260-262`  
**Issue:** The shipped design guide names `.planning/research/brand-v2-adoption/SOCIAL-UPLOAD-CHECKLIST.md` in plain inline code, not as a link. The Admin package includes `docs/` but not `.planning` in its strict file allowlist (`mailglass_admin/mix.exs:238`), so readers of the packaged guide cannot find that file in the package/HexDocs context. A direct local package build was unavailable because Elixir 1.18.4 is not installed; the package file list establishes the exclusion.
**Fix:** Move the adopter-facing checklist under published docs and include it in the package, or link to a stable public repository URL instead of a package-relative `.planning` path.

---

_Reviewed: 2026-11-17T01:24:35Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
