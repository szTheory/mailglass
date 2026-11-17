---
phase: 183-docs-packaging-and-launch-prep
verified: 2026-11-17T22:00:19Z
status: gaps_found
score: "19/20 must-haves verified"
covered_files:
  - .github/workflows/advisory-matrix.yml
  - .github/workflows/ci.yml
  - .github/workflows/publish-hex.yml
  - .impeccable/config.json
  - .impeccable/design.json
  - .planning/phases/183-docs-packaging-and-launch-prep/183-01-PLAN.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-01-SUMMARY.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-02-PLAN.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-02-SUMMARY.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-03-PLAN.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-03-SUMMARY.md
  - .planning/publish/mailglass_admin-files.expected
  - .planning/research/brand-v2-adoption/favicon-catalog/favicon-299c1aa-20261116T231912Z/manifest.json
  - CONTRIBUTING.md
  - DESIGN.md
  - MAINTAINING.md
  - README.md
  - brandbook/brand.pin.json
  - brandbook/exdoc/code-colors.css
  - brandbook/exdoc/mailglass-mark-dark.svg
  - brandbook/exdoc/mailglass-mark-light.svg
  - brandbook/exdoc/theme-mark.js
  - brandbook/status-marks.json
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
  - ci/contracts/brand_docs_output_test.exs
  - config/test_exceptions.exs
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
  - mailglass_admin/e2e/favicon-capture-order.test.cjs
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
  - scripts/gsd-regression-gate.sh
  - scripts/verify_brand_docs.sh
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
  - test/scripts/brand_docs_ci_wiring_test.exs
  - test/scripts/brand_docs_contract_test.exs
  - test/scripts/brand_name_lint_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
  - test/scripts/lane_classification_drift_test.exs
  - test/scripts/readme_image_contract_test.exs
  - test/support/ci_lanes.ex
  - test/support/webhook_case.ex
covered_digest: "v4:sha256:fd5041f29bee48bff9814228151144bcaabb5e68b75107713f3f07897fdd1cf9"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 16
  total: 16
  not_honored: []
gaps:
  - truth: "The accepted favicon catalog is bound to the producer source and pin, and passes the independent pixel/manifest validator."
    status: failed
    reason: "The current Admin suite reports a FaviconCatalogTest producer-SHA mismatch: manifest bff05d778648d4d900c9e977e89227ea3290ede9490e1e7fd5de28bdda7f6ee3 differs from current producer 55208b4010bd21fbb03f48754a320b1672e5d2846d919ac915d1fd9a1fc235a9. The recorded digest matches the pre-capture script in git; the current source changed afterward."
    artifacts:
      - path: .planning/research/brand-v2-adoption/favicon-catalog/favicon-299c1aa-20261116T231912Z/manifest.json
        issue: "Catalog records the older capture-producer digest, so current validator rejects its provenance."
      - path: mailglass_admin/e2e/favicon-capture.cjs
        issue: "Current producer bytes no longer match the digest stored in the accepted catalog."
      - path: mailglass_admin/test/support/favicon_catalog.ex
        issue: "The validator intentionally compares the recorded producer digest with the current file and reports the mismatch."
    missing:
      - "A deterministic, reviewable provenance resolution that preserves the consumed capture authorization and does not rewrite historical capture metadata."
---

# Phase 183: Docs, Packaging and Launch Prep Verification Report

**Phase Goal:** Everywhere an adopter meets mailglass outside the dashboard (the hex.pm README, HexDocs, Hex package contents, browser favicon) carries brand v2.0 correctly. Nothing irreversible (an announcement or a trademark claim) goes out before the Phase 179 search result allows it.

**Verified:** 2026-11-17T22:00:19Z
**Status:** gaps_found
**Re-verification:** No — the previous report had no top-level gaps, so this refresh rechecked the phase contract.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | All three candidate README sources select pinned light/dark lockups using renderer-specific references and immutable raw GitHub URLs. | ✓ VERIFIED | `test/scripts/readme_image_contract_test.exs` checks all three source headers, exact theme URLs, immutable pin bytes, fallback alt text, and responsive geometry. Generated ExDoc theme/layout also passes. The candidate is unpublished; live GitHub/Hex.pm pages were not observed and are not an owner UAT gate. |
| 2 | Real core, Admin, and Inbound docs carry the v2 mark/favicon and code-color-only CSS, retain Lato, and use ExDoc’s native theme toggle. | ✓ VERIFIED | Current run `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 bash scripts/verify_brand_docs.sh` built all three packages with warnings as errors; the fresh generated-output contract passed 1 test. Theme/layout browser evidence is historical and is listed separately. |
| 3 | Lowercase adopter prose is enforced while API/module names, wire identifiers, history, and approved exceptions remain valid. | ✓ VERIFIED | The active lowercase lint and mutation tests passed; the complete adopter corpus was checked without weakening structural API and historical exceptions. |
| 4 | Actual Hex package contents match reviewed goldens and pin-bound assets, including Admin fonts/OFL texts/logo/favicon and excluding the full book/evidence tree. | ✓ VERIFIED | The actual-tarball contract builds and unpacks all three packages, compares every path to its golden, and checks Admin brand bytes against the pin. Its focused suite and all three publish checks passed in Plan 01. |
| 5 | Missing or unreadable logo/favicon assets fail validation, and README fallback alt text stays lowercase mailglass. | ✓ VERIFIED | Offline source/output contracts reject missing or corrupt assets and assert alt text on all three README headers. |
| 6 | Favicon capture waits for decoded image bytes before screenshotting and saving. | ✓ VERIFIED | `mailglass_admin/e2e/favicon-capture-order.test.cjs` passed locally against the actual capture helper. It gates decode, confirms no screenshot or file before decode completes, and verifies frame settling precedes screenshot/save. The manifest validator preserves `safariTabChromeObserved: false`; no new capture was run. |
| 7 | Missing, undecodable, or pin-mismatched media bytes fail validation while README keeps lowercase alt text fallback. | ✓ VERIFIED | Readme and generated-doc mutation tests reject missing refs/assets, corrupt bytes, pin drift, and missing fallback text. |
| 8 | Populated surfaces use matching light/dark artwork; ExDoc follows its class toggle; favicon evidence records both themes, sizes, and Chromium/Firefox/WebKit. | ✓ VERIFIED | The 108-cell manifest contains all three engines, both themes, and 16/24/32 px. The generated-doc theme/layout browser pass is historical; current catalog acceptance is separately failed below because its producer binding is stale. |
| 9 | README has one lowercase H1 and a separate tagline; its image is not stretched, cropped, or truncated. | ✓ VERIFIED | All package README source contracts pass. The generated ExDoc browser contract verifies the separate tagline and original image ratio at 375 px. |
| 10 | Candidate README lockup fits narrow content at its original ratio, remains at least 96 px wide, and causes no horizontal scrolling. | ✓ VERIFIED | README source contracts reject distorted or too-small geometry in all three headers; the final generated ExDoc browser check passes 375 px width, original ratio, minimum width, and no horizontal overflow for all packages. Live GitHub/Hex.pm display remains unobserved and informational. |
| 11 | The caution record blocks announcement and trademark claims while code rollout and package readiness remain usable. | ✓ VERIFIED | The production gate reads trademark-search.json by default; the current record is caution with register_checked false and required registers not_checked. The blocked draft is explicit, registered marks are denied, and package checks are decoupled. |
| 12 | Clearance requires the named registers, valid bounded dates, and current production record; registered-mark claims are always denied. | ✓ VERIFIED | Production gate logic and focused tests enforce the register set, dates, production input, and unconditional registered-mark denial. |
| 13 | Admin/root design guidance and the impeccable sidecar match the pinned v2 tokens; owner instruction patches remain pending and unapplied. | ✓ VERIFIED | Design parity checks pass, owner-signoff/STATUS is pending, and the canonical owner files remain unapplied. |
| 14 | The accepted favicon catalog is unique, bound to current producer, pinned and served bytes, and accepted by independent PNG validation; Safari tab chrome is not claimed. | ✗ FAILED | Static inventory shows 108 unique cells and source/served/pin bytes all match SHA `299c1aaa…`; `safariTabChromeObserved` is false. However, the manifest producer SHA is `bff05d…`, while current `favicon-capture.cjs` is `55208b…`. The current Admin result reports this validator failure; the earlier 13-test green run is historical. No capture or retry was performed. |
| 15 | The social-card handoff has full URLs and a read-back step; no upload or personal-avatar change occurs. | ✓ VERIFIED | The repository-only checklist includes settings/repository URLs and GraphQL read-back. It records no upload or personal-avatar change. |
| 16 | The normal root test lane does not require ignored generated docs and retains source/fixture brand checks. | ✓ VERIFIED | Plan 03 moved actual-output checking to ci/contracts; the default source/fixture test passed without generated checkout docs. The current tree has no generated doc/README.html outputs. |
| 17 | The required Docs Warnings as Errors job builds and validates all three package outputs and remains behind CI Green. | ✓ VERIFIED | .github/workflows/ci.yml installs locked dev dependencies for all three packages and runs scripts/verify_brand_docs.sh; the wiring contract confirms the required CI Green edge. |
| 18 | One generated output set feeds both the real-output contract and local theme/layout browser verification. | ✓ VERIFIED | In this re-verification, one temporary output root passed the ExUnit output contract and the Docker Chromium check; all three packages passed both checks. |
| 19 | Browser checks use the existing pinned engine, fail visibly when prerequisites are missing, and neither download browsers nor generate favicon captures. | ✓ VERIFIED | Missing output fails before Chromium launch; the existing Playwright 1.65.1 image ran with networking disabled. The docs browser helper writes no captures, and this verification did not run the favicon producer. |
| 20 | Pending owner/counsel/platform handoffs and the consumed favicon-capture authorization remain unchanged. | ✓ VERIFIED | Owner sign-off is pending, the announcement draft is blocked, the social checklist remains an owner handoff, and CONTEXT.md says no further favicon capture is authorized. |

**Score:** 19/20 truths verified (0 behavior-unverified)

The verification target is the unpublished candidate's source-controlled README, package, and generated ExDoc behavior. Live GitHub/Hex.pm pages were not observed and remain an explicit external limitation, not an owner UAT gate.

### Plan Prohibitions

| Prohibition | Status | Evidence |
|---|---|---|
| Artwork use must not imply adopter endorsement or certification. | Resolved by owner decision | DESIGN.md, .impeccable/design.json, Admin design guide, and owner sign-off text state this explicitly; the prior verification records owner approval of the wording. |
| Browser captures must not be described as real Safari tab-chrome evidence. | VERIFIED | The accepted manifest sets safariTabChromeObserved false, discloses image-only capture, and CONTEXT.md keeps Safari tab chrome unobserved. The owner previously accepted that limitation. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| test/scripts/readme_image_contract_test.exs | Offline README reference, byte, fallback, and geometry contracts | ✓ VERIFIED | Covers all three package READMEs and mutation rejection against the pin. |
| scripts/brand_docs_check.exs | Real generated-output and public-claim validation | ✓ VERIFIED | Fresh outputs for all three packages passed its explicit-root contract. |
| brandbook/exdoc/code-colors.css | Syntax-only class-driven color overrides | ✓ VERIFIED | CSS scope is limited to Makeup code colors; no OS scheme query or broad layout rules. |
| brandbook/exdoc/theme-mark.js | Pinned mark follows ExDoc’s dark class | ✓ VERIFIED | Native body class selects the matching mark; generated browser scenarios passed. |
| scripts/brand_name_lint.exs | Lowercase adopter-prose detector with structural exceptions | ✓ VERIFIED | Active test suite and corpus check preserve public identifiers and historical text. |
| test/mailglass/publish/brand_asset_allowlist_test.exs | Actual Hex payload and pin equality contract | ✓ VERIFIED | Builds/unpacks real package tarballs and checks goldens, digest coverage, and exact Admin assets. |
| scripts/brand_trademark_gate.exs | Fail-closed production decision and public-claim scan | ✓ VERIFIED | Defaults to the current caution record; registered-mark claims are denied. |
| DESIGN.md | Root v2 design authority | ✓ VERIFIED | Token and copy parity check passes. |
| .impeccable/design.json | Schema-2 token sidecar | ✓ VERIFIED | Sidecar parity and schema tests pass. |
| .planning/research/brand-v2-adoption/owner-signoff/STATUS | Pending state for owner patches | ✓ VERIFIED | Current value is pending. |
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | Independent favicon catalog validator | ✓ PRESENT / WIRED | Substantive PNG/pixel/manifest validator runs in the Admin lane. The current lane reports its catalog check failing on the recorded producer digest; the 13-test pass is historical. |
| mailglass_admin/e2e/favicon-capture-order.test.cjs | Actual capture helper decode/frame/screenshot/save ordering contract | ✓ VERIFIED | Passed locally; verifies no screenshot or output file appears before image decode and frame settling. |
| .planning/research/brand-v2-adoption/SOCIAL-UPLOAD-CHECKLIST.md | Repository-only upload/read-back instructions | ✓ VERIFIED | Full repository URLs and GraphQL read-back are present; no upload was made. |
| ci/contracts/brand_docs_output_test.exs | Fail-closed real-output contract outside root test discovery | ✓ VERIFIED | Requires explicit output root and validates core/Admin/Inbound directories. |
| scripts/verify_brand_docs.sh | Serial three-package docs build, output contract, optional browser mode | ✓ VERIFIED | Builds once per package into an owned temp root and cleans that root. |
| test/scripts/brand_docs_ci_wiring_test.exs | Proof of required CI invocation and root-suite separation | ✓ VERIFIED | Checks locked deps, active workflow command, fail-fast behavior, and CI Green edge. |
| mailglass_admin/e2e/docs-theme-contract.cjs | Explicit output-root theme and layout browser assertions | ✓ VERIFIED | Validates all README files before launch, selects native theme, checks decoded lockup and 375 px layout. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| All three README.md files | brandbook/v2/mailglass-lockup-light.svg | Immutable raw GitHub URL and renderer-specific fragment | ✓ WIRED | Source refs, responsive geometry, and offline bytes match the pinned asset commit; live platform display was not observed and is informational. |
| mix.exs, mailglass_admin/mix.exs, mailglass_inbound/mix.exs | brandbook/exdoc/code-colors.css and theme-mark.js | ExDoc assets and before-closing hooks | ✓ WIRED | All three configurations copy the directory and inject the CSS/script; generated output checks found the assets. |
| scripts/brand_docs_check.exs | scripts/brand_trademark_gate.exs | Explicit generated-doc claim scan | ✓ WIRED | Checker loads and calls the claim scanner; it is not a publish prerequisite. |
| test/mailglass/publish/brand_asset_allowlist_test.exs | brandbook/brand.pin.json | Actual archive path and byte comparison | ✓ WIRED | Test compares unpacked archive assets against pin and reviewed goldens. |
| scripts/brand_trademark_gate.exs | .planning/research/brand-v2-adoption/trademark-search.json | Production default record and UTC date | ✓ WIRED | Source uses the fixed default record; current caution denies announcement/mark claims. |
| DESIGN.md | brandbook/tokens.json | Test-checked v2 values | ✓ WIRED | The parity test reads the pinned tokens and fails on drift. |
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | mailglass_admin/priv/static/favicon.svg | Source/served digest and PNG-derived metrics | ⚠️ PARTIAL | Source, served file, and brand pin currently match `299c1aaa…`; the validator also compares the captured producer digest and rejects its stale value. |
| .github/workflows/ci.yml docs_warnings_as_errors | scripts/verify_brand_docs.sh | Required same-job build/check and CI Green edge | ✓ WIRED | Direct workflow and mutation test confirm locked package deps and a fail-fast script invocation. |
| scripts/verify_brand_docs.sh | ci/contracts/brand_docs_output_test.exs | MAILGLASS_DOCS_OUTPUT_ROOT points to fresh package outputs | ✓ WIRED | One root was passed to the output contract and validated all three package directories. |
| scripts/verify_brand_docs.sh --browser | mailglass_admin/e2e/docs-theme-contract.cjs --all --output-root | Same output root; existing Playwright engine | ✓ WIRED | The direct browser contract passed against the same root without re-generating docs. |

### Data-Flow Trace (Level 4)

| Artifact | Data value | Source | Produces real data | Status |
|---|---|---|---|---|
| README artwork | Light/dark SVG bytes | Immutable Git blob, README URL, and brand.pin.json | Yes; exact bytes and digest are checked | ✓ FLOWING |
| Generated ExDoc pages | Mark, favicon, CSS, and script | Three mix.exs configs copy source assets into each build | Yes; fresh output roots passed checker and browser | ✓ FLOWING |
| Hex package payload | File path set and shipped brand bytes | Actual mix hex.build --unpack tarballs | Yes; compared with reviewed goldens and pin | ✓ FLOWING |
| Favicon evidence | 108 PNG raster captures | Stored catalog manifest, PNG digests, pinned/served SVGs, and producer-script digest | Source/served/pin bytes match; producer provenance does not | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Fresh core/Admin/Inbound docs builds and real-output contract | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 bash scripts/verify_brand_docs.sh` | Current run built all three packages with warnings as errors; standalone output contract passed 1 test; owned temporary directory was cleaned; 7 seconds total | ✓ PASS |
| Theme selection and README layout for generated docs | Historical Playwright 1.65.1 Docker run documented in 183-03-SUMMARY.md and 183-VALIDATION.md | All three packages previously passed both native themes, image decode, 375 px width, ratio, and overflow checks. No browser was launched in this refresh. | ✓ HISTORICAL PASS |
| Favicon capture ordering | Owner-provided local result in 183-VALIDATION.md; `mailglass_admin/e2e/favicon-capture-order.test.cjs` exercises the actual helper | Earlier helper test passed decode/frame/screenshot/save ordering. The test is not rerun here; no capture was repeated. | ✓ HISTORICAL PASS |
| Accepted favicon catalog provenance | Current lane result in 183-VALIDATION.md; static SHA comparison during this audit | Latest Admin lane: 1,824 tests, 1 failure in FaviconCatalogTest. Manifest producer `bff05d…` equals the pre-capture git version; current producer is `55208b…`. Source, served, and pin SVG SHA values are all `299c1aaa…`. | ✗ FAIL |
| Current local regression-lane snapshot | Current Validation Refresh in 183-VALIDATION.md (exact command transcript not retained) | Storybook 42 passed; Core 82 passed; Admin 1,824 with the catalog producer-SHA failure; Inbound 481 passed with 3 property exclusions. This is supplied current evidence, not a rerun in this verification. | ✗ FAIL (Admin) |
| Previous full browser/regression gate | Historical hash-verified log `/private/tmp/mailglass-183-regression-gate-verified.log` | The earlier run recorded Storybook 42, Core 81, Admin 1,817 (1 excluded), Inbound 481 (3 excluded), browser 37. It is historical and does not clear the current catalog failure. | ✓ HISTORICAL PASS |
| Full default root suite | Explicitly not rerun | Last recorded result: 2,448 tests, 7 failures, 27 excluded, 7 skipped. Two focused contracts were later fixed; the entire root lane remains unverified and is not claimed green. | ? NOT RUN |

The last recorded default root-suite run remains red and was not repeated in this refresh. Current lane counts are from 183-VALIDATION.md and have no retained command transcript. No curated gate, Mix alias, browser run, capture, or recapture was attempted.

### Probe Execution

No phase-declared or conventional scripts/*/tests/probe-*.sh probes were found. Probe execution is not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| BRDOC-01 | 183-01, 183-03 | Theme-specific immutable README lockups, byte contract, and platform selection | SATISFIED | All three source headers pass URL, pin-byte, fallback, and geometry contracts; generated ExDoc theme/layout passes. Live pages for the unpublished candidate were not observed and are not an owner UAT gate. |
| BRDOC-02 | 183-01, 183-03 | Real branded docs builds for all three packages | SATISFIED | Fresh builds, output contract, CSS/Lato checks, and three-package theme/layout browser check passed. |
| BRDOC-03 | 183-02 | Design guide, .impeccable config, and pending owner guidance drafts | SATISFIED | Token parity passes; paired patches remain pending and unapplied. |
| BRDOC-04 | 183-01 | Lowercase lint, Hex allowlists, and package readiness checks | SATISFIED | Linter, actual archive tests, and all three package publish checks passed in the phase run. |
| BRDOC-05 | 183-02 | Multi-browser favicon evidence and manual social-card checklist | BLOCKED | The 108-cell catalog and checklist exist, but the current Admin validator rejects the catalog's stale producer digest. The 108 captures are historical evidence; no recapture was authorized or performed. |
| BRDOC-06 | 183-02 | Announcement/trademark claims gated on Phase 179 while code rollout stays available | SATISFIED | Production gate denies the current caution record; package readiness has no trademark dependency. |

No Phase 183 requirement IDs are orphaned. All six appear in plan frontmatter.

### Decision Coverage

All 16 trackable CONTEXT.md decisions are represented in shipped artifacts; none were unhonored.

### Test Quality Audit

| Test File | Linked Requirement | Active/Disabled | Circular | Assertion strength | Verdict |
|---|---|---:|---|---|---|
| test/scripts/readme_image_contract_test.exs | BRDOC-01 | Active | No | Exact URL, byte, fallback, and mutation values | PASS |
| mailglass_admin/e2e/favicon-capture-order.test.cjs | BRDOC-05 | Active | No | Actual helper; decode gate, frame settling, screenshot and file ordering | PASS |
| test/scripts/brand_docs_contract_test.exs | BRDOC-02 | Active | No | Fixture/source mutations; no ambient generated docs dependency | PASS |
| ci/contracts/brand_docs_output_test.exs | BRDOC-02 | Active | No | All three fresh outputs are checked | PASS |
| test/scripts/brand_docs_ci_wiring_test.exs | BRDOC-02 | Active | No | Required CI wiring and negative mutation controls | PASS |
| test/scripts/brand_name_lint_test.exs | BRDOC-04 | Active | No | Corpus findings and structural exceptions | PASS |
| test/mailglass/publish/brand_asset_allowlist_test.exs | BRDOC-04 | Active | No | Actual archive paths/bytes and digest coverage | PASS |
| test/scripts/brand_trademark_gate_test.exs | BRDOC-06 | Active | No | Gate/date/claim/release-decoupling behaviors | PASS |
| test/scripts/brand_design_md_test.exs | BRDOC-03 | Active | No | Token parity and pending-state invariants | PASS |
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | BRDOC-05 | Active | No | Independent PNG decoding, metrics, hash and mutation rejection | PASS — current Admin run exposes stale producer provenance |
| test/mailglass/docs_contract_test.exs | BRDOC-03 | Active coverage plus one unrelated legacy skip | No | Active token/guide assertions | PASS WITH WARNING |

**Disabled requirement tests:** 0 direct BRDOC acceptance tests. One pre-existing Phase 38 skipped test remains in the broader docs contract file; it is not the sole proof for BRDOC-03. The current exception registry points at line 826. The prior root-suite report had an outdated line; root was not rerun per owner instruction.
**Circular expected-value patterns:** 0. **Insufficient assertions:** 0.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No current docs warnings emitted by the warnings-as-errors build | Info | Current three-package docs build completed successfully. Historical cross-package link follow-up remains recorded in phase deferred-items.md. |
| test/scripts/brand_docs_contract_test.exs:15 (prior verification) | 15 | Generated-output test depended on ignored checkout docs | Resolved | Plan 03 moved it to the standalone explicit-root output contract and retains source/fixture tests in the default lane. |

No unreferenced TBD/FIXME/XXX debt markers or placeholder implementations were found in the changed implementation code. One 183-02 test contains the string placeholder as an accessibility attribute name; this is data, not a stub marker.

### Human Verification Required

None. The candidate's live GitHub and Hex.pm pages remain unobserved because it is unpublished. That limitation is recorded above and is not an owner UAT gate; source contracts and generated ExDoc checks cover the current acceptance criterion.

### Gaps Summary

Plan 03 closed the clean-checkout docs gap: root source/fixture checks do not depend on ignored generated docs, and the required docs job builds and validates core, Admin, and Inbound outputs behind CI Green. A fresh local output root passed the standalone ExUnit output contract and the current warnings-as-errors three-package docs build. Browser theme/layout evidence is historical; no browser check was repeated in this refresh.

BRDOC-05 remains blocked. The catalog has 108 unique capture cells and its source, served, and pinned SVG bytes agree, but its manifest producer digest matches the pre-capture script rather than the current capture producer. The current Admin lane reports this validator failure. Resolving provenance requires a deterministic reviewable decision that preserves the already-consumed capture authorization; no capture, alias, curated gate, or recapture was retried. Current lane counts are recorded separately from the historical green browser/regression run. The default root suite remains at its last recorded result of 2,448 tests with 7 failures; it was not rerun and is not described as green. Live GitHub/Hex.pm rendering remains unobserved for this unpublished candidate and does not require owner UAT.

---

_Verified: 2026-11-17T22:00:19Z_
_Verifier: the agent (gsd-verifier)_

