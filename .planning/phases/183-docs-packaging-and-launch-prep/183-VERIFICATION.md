---
phase: 183-docs-packaging-and-launch-prep
verified: 2026-11-18T00:38:05Z
status: passed
score: "25/25 must-haves verified"
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
  - .planning/phases/183-docs-packaging-and-launch-prep/183-04-PLAN.md
  - .planning/phases/183-docs-packaging-and-launch-prep/183-04-SUMMARY.md
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
  - mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.cjs
  - mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.json
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
covered_digest: "v4:sha256:acd849a27ec199b2aa52b4130c6f7b8b3590809edca3090e8777415059137127"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: "19/20"
  gaps_closed:
    - "The accepted favicon catalog is bound to authenticated historical producer bytes and passes independent manifest and PNG validation."
  gaps_remaining: []
  regressions: []
decision_coverage:
  honored: 16
  total: 16
  not_honored: []
---

# Phase 183: Docs, Packaging and Launch Prep Verification Report

**Phase Goal:** Everywhere an adopter meets mailglass outside the dashboard (the hex.pm README, HexDocs, Hex package contents, browser favicon) carries brand v2.0 correctly. Nothing irreversible (an announcement or a trademark claim) goes out before the Phase 179 search result allows it.

**Verified:** 2026-11-18T00:38:05Z
**Status:** passed
**Re-verification:** Yes — after Phase 183 plan 04 closed the producer-provenance gap.

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
| 8 | Populated surfaces use matching light/dark artwork; ExDoc follows its class toggle; favicon evidence records both themes, sizes, and Chromium/Firefox/WebKit. | ✓ VERIFIED | The 108-cell manifest contains all three engines, both themes, and 16/24/32 px. The generated-doc theme/layout browser pass is historical. The accepted catalog now passes the complete validator using its exact authenticated historical producer snapshot; no new capture or browser run was made. |
| 9 | README has one lowercase H1 and a separate tagline; its image is not stretched, cropped, or truncated. | ✓ VERIFIED | All package README source contracts pass. The generated ExDoc browser contract verifies the separate tagline and original image ratio at 375 px. |
| 10 | Candidate README lockup fits narrow content at its original ratio, remains at least 96 px wide, and causes no horizontal scrolling. | ✓ VERIFIED | README source contracts reject distorted or too-small geometry in all three headers; the final generated ExDoc browser check passes 375 px width, original ratio, minimum width, and no horizontal overflow for all packages. Live GitHub/Hex.pm display remains unobserved and informational. |
| 11 | The caution record blocks announcement and trademark claims while code rollout and package readiness remain usable. | ✓ VERIFIED | The production gate reads trademark-search.json by default; the current record is caution with register_checked false and required registers not_checked. The blocked draft is explicit, registered marks are denied, and package checks are decoupled. |
| 12 | Clearance requires the named registers, valid bounded dates, and current production record; registered-mark claims are always denied. | ✓ VERIFIED | Production gate logic and focused tests enforce the register set, dates, production input, and unconditional registered-mark denial. |
| 13 | Admin/root design guidance and the impeccable sidecar match the pinned v2 tokens; owner instruction patches remain pending and unapplied. | ✓ VERIFIED | Design parity checks pass, owner-signoff/STATUS is pending, and the canonical owner files remain unapplied. |
| 14 | The accepted favicon catalog is uniquely bound to authenticated historical producer bytes, pinned and served bytes, and independent PNG validation; other catalogs remain current-producer-bound and Safari tab chrome is not claimed. | ✓ VERIFIED | The accepted manifest's raw-byte SHA and catalog ID select one historical branch, which checks producer path/digest, an exact provenance record against compiled constants, and the snapshot's SHA-256/Git-blob IDs. The full validator passes the Git-free accepted-catalog test; every other identity uses current-file comparison. Source, served and pin SHA is `299c1aaa…`; Safari tab chrome remains false. |
| 15 | The social-card handoff has full URLs and a read-back step; no upload or personal-avatar change occurs. | ✓ VERIFIED | The repository-only checklist includes settings/repository URLs and GraphQL read-back. It records no upload or personal-avatar change. |
| 16 | The normal root test lane does not require ignored generated docs and retains source/fixture brand checks. | ✓ VERIFIED | Plan 03 moved actual-output checking to ci/contracts; the default source/fixture test passed without generated checkout docs. The current tree has no generated doc/README.html outputs. |
| 17 | The required Docs Warnings as Errors job builds and validates all three package outputs and remains behind CI Green. | ✓ VERIFIED | .github/workflows/ci.yml installs locked dev dependencies for all three packages and runs scripts/verify_brand_docs.sh; the wiring contract confirms the required CI Green edge. |
| 18 | One generated output set feeds both the real-output contract and local theme/layout browser verification. | ✓ VERIFIED | In this re-verification, one temporary output root passed the ExUnit output contract and the Docker Chromium check; all three packages passed both checks. |
| 19 | Browser checks use the existing pinned engine, fail visibly when prerequisites are missing, and neither download browsers nor generate favicon captures. | ✓ VERIFIED | Missing output fails before Chromium launch; the existing Playwright 1.65.1 image ran with networking disabled. The docs browser helper writes no captures, and this verification did not run the favicon producer. |
| 20 | Pending owner/counsel/platform handoffs and the consumed favicon-capture authorization remain unchanged. | ✓ VERIFIED | Owner sign-off is pending, the announcement draft is blocked, the social checklist remains an owner handoff, and CONTEXT.md says no further favicon capture is authorized. |

**Score:** 20/20 roadmap truths verified (0 behavior-unverified)

### Phase 183-04 Must-Haves

| # | Truth | Status | Evidence |
|---|---|---|---|
| 21 | The accepted 108-cell favicon catalog passes independent manifest and PNG validation using authenticated historical producer bytes without changing its manifest or PNGs. | ✓ VERIFIED | The focused ExUnit run passed the Git-free accepted-catalog test through `validate_catalog/2`. The post-hardening log records 18 tests, 0 failures; the protected inventory before and after is byte-identical across 113 files. |
| 22 | Historical producer acceptance applies only to the exact reviewed manifest byte digest, catalog identity and recorded producer digest; all other catalogs still require the current producer file digest. | ✓ VERIFIED | `producer_failures/4` selects the exception only for the compiled accepted catalog ID plus raw manifest SHA. The expected producer path/digest and full record map are checked against independent module constants. Tests reject a whitespace-only raw-manifest change and show a synthetic future catalog passes with the current producer but fails after mutation or historical-digest substitution. |
| 23 | The provenance decision works from a source archive without Git history, network access, browser installation or a capture invocation. | ✓ VERIFIED | The passing test explicitly asserts the copied root has no `.git`; runtime code reads only fixed local files and OTP crypto. The snapshot is treated as data, never executed. |
| 24 | Missing, malformed, substituted or symlinked historical evidence fails closed; current source, served favicon, pin, raster thresholds and Safari limitations remain enforced. | ✓ VERIFIED | Focused tests cover missing/corrupt/oversized/symlinked files, a symlinked parent and every provenance-record field. Existing source/served/pin, matrix, pixel and diagnostic checks still execute; metric thresholds are unchanged and Safari tab chrome must remain false. |
| 25 | The consumed capture authorization and blocked alias remain stopped; inability to authenticate historical source leaves the verification gap open rather than authorizing another capture. | ✓ VERIFIED | No capture alias, producer, browser, or recapture was run. The implementation changes only validator/test fixtures; the 113-file protected inventory (including accepted manifest, PNGs, pin and SVGs) is identical before and after. The plan retains the stop if evidence cannot be authenticated. |

All 25 roadmap and plan truths are verified. Source-byte provenance does not independently attest to the historical browser process and creates no new browser or Safari observation, as the evidence record and plan explicitly state.

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
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | Independent favicon catalog validator and Git-free provenance contract | ✓ VERIFIED | The validator runs across the accepted catalog and synthetic producer cases; final focused run passes 18 tests with 0 failures. |
| mailglass_admin/test/support/favicon_catalog.ex | Exact-manifest historical source authentication; current producer checks for other catalogs | ✓ VERIFIED | Historical selectors and evidence hashes are constants; all non-matching catalogs flow through current-file SHA comparison. |
| mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.json | Offline record binding the accepted catalog to immutable source provenance | ✓ VERIFIED | The full decoded record equals independent module constants; every field substitution is rejected. |
| mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.cjs | Exact historical source snapshot, retained as inert bounded data | ✓ VERIFIED | 16,209 bytes; SHA-256 and Git-blob IDs match code constants. Read-only `git show` of the referenced commit matches byte-for-byte. |
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
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | mailglass_admin/priv/static/favicon.svg | Source/served digest and PNG-derived metrics | ✓ WIRED | The accepted catalog passes the full validator; pinned source and served SVG bytes both match `299c1aaa…`, and all PNG digests and independent raster metrics remain checked. |
| .github/workflows/ci.yml docs_warnings_as_errors | scripts/verify_brand_docs.sh | Required same-job build/check and CI Green edge | ✓ WIRED | Direct workflow and mutation test confirm locked package deps and a fail-fast script invocation. |
| scripts/verify_brand_docs.sh | ci/contracts/brand_docs_output_test.exs | MAILGLASS_DOCS_OUTPUT_ROOT points to fresh package outputs | ✓ WIRED | One root was passed to the output contract and validated all three package directories. |
| scripts/verify_brand_docs.sh --browser | mailglass_admin/e2e/docs-theme-contract.cjs --all --output-root | Same output root; existing Playwright engine | ✓ WIRED | The direct browser contract passed against the same root without re-generating docs. |
| `mailglass_admin/test/support/favicon_catalog.ex validate_catalog/2` | `accepted-producer.json` | Raw manifest SHA selects the only historical record | ✓ WIRED | Manual source trace: `validate_catalog/2` hashes raw bytes before decode, `source_bindings/4` passes that hash to `producer_failures/4`, then the exact accepted ID/hash branch validates the fixed-path record against compiled constants. The automated link checker rejected the plan's function-name label as a file path. |
| Historical producer snapshot | Accepted catalog `producer.sha256` | Recomputed SHA-256 and Git-blob ID compared to independent constants | ✓ WIRED | `historical_producer_failures/3` checks manifest producer path/digest; snapshot bytes must match exact length, SHA-256 and Git-blob SHA-1. The snapshot is not executed. |
| `source_bindings/4` current producer branch | `mailglass_admin/e2e/favicon-capture.cjs` | `producer_failures/4` falls through to `compare_file/3` | ✓ WIRED | Manually traced the `else` path: every non-accepted catalog identity or changed raw manifest is compared against current producer bytes. The automated link checker rejected the function-name source label and conceptual digest target, so its 0/3 result does not show a broken link. |

### Data-Flow Trace (Level 4)

| Artifact | Data value | Source | Produces real data | Status |
|---|---|---|---|---|
| README artwork | Light/dark SVG bytes | Immutable Git blob, README URL, and brand.pin.json | Yes; exact bytes and digest are checked | ✓ FLOWING |
| Generated ExDoc pages | Mark, favicon, CSS, and script | Three mix.exs configs copy source assets into each build | Yes; fresh output roots passed checker and browser | ✓ FLOWING |
| Hex package payload | File path set and shipped brand bytes | Actual mix hex.build --unpack tarballs | Yes; compared with reviewed goldens and pin | ✓ FLOWING |
| Favicon evidence | 108 PNG raster captures and historical producer bytes | Stored manifest/PNG bytes, pinned/served SVGs, independent provenance constants and frozen source snapshot | Yes; accepted manifest, capture PNGs, source, served, pin and producer snapshot are hash-checked; other catalogs remain bound to current producer | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Fresh core/Admin/Inbound docs builds and real-output contract | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 bash scripts/verify_brand_docs.sh` | Current run built all three packages with warnings as errors; standalone output contract passed 1 test; owned temporary directory was cleaned; 7 seconds total | ✓ PASS |
| Theme selection and README layout for generated docs | Historical Playwright 1.65.1 Docker run documented in 183-03-SUMMARY.md and 183-VALIDATION.md | All three packages previously passed both native themes, image decode, 375 px width, ratio, and overflow checks. No browser was launched in this refresh. | ✓ HISTORICAL PASS |
| Favicon capture ordering | Owner-provided local result in 183-VALIDATION.md; `mailglass_admin/e2e/favicon-capture-order.test.cjs` exercises the actual helper | Earlier helper test passed decode/frame/screenshot/save ordering. The test is not rerun here; no capture was repeated. | ✓ HISTORICAL PASS |
| Phase 183 plan 04 summary metadata | `gsd-tools verify-summary .planning/phases/183-docs-packaging-and-launch-prep/183-04-SUMMARY.md` | Latest summary commit `826962d6` passes: both created artifacts found, commit references exist, self-check passes. Frontmatter and prose both report 38 minutes. | ✓ PASS |
| Accepted favicon catalog provenance | Hash-verified focused ExUnit log `/private/tmp/phase183-04-temp-ownership-test.log` | 18 tests, 0 failures, 10.9 seconds; log SHA-256 `f85cf2bc797a241d9bd44069bf1c35940fce18a83fbc83656b7f649f0c6872d1`. The Git-free test exercises complete manifest/PNG validation; code and immutable Git object were independently inspected. | ✓ PASS |
| Favicon capture helper ordering | Hash-verified browser-free Node log `/private/tmp/phase183-04-node-test.log` | 1 test passed in 38.6 ms; log SHA-256 `8dd35fa0ec60f4ac0f2d325db911c74b1e9bcf936fcaba1b16cd0f48f3f51d4e`. No capture was invoked. | ✓ PASS |
| Current local regression-lane snapshot | Current Validation Refresh in 183-VALIDATION.md (exact command transcript not retained) | Before this focused gap closure, Admin reported 1,824 tests with the producer-provenance failure. That failure is now resolved by the 18-test focused contract; the broad Admin lane was not rerun. | ℹ️ PRIOR FAILURE RESOLVED; BROAD LANE NOT RERUN |
| Previous full browser/regression gate | Historical hash-verified log `/private/tmp/mailglass-183-regression-gate-verified.log` | The earlier run recorded Storybook 42, Core 81, Admin 1,817 (1 excluded), Inbound 481 (3 excluded), browser 37. It remains historical; this re-verification relies on the focused post-closure catalog check, not a rerun of the broad gate. | ✓ HISTORICAL PASS |
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
| BRDOC-05 | 183-02, 183-04 | Multi-browser favicon evidence, authenticated accepted-catalog provenance, and manual social-card checklist | SATISFIED | The existing 108-cell catalog passes the full validator using byte-authenticated historical producer provenance; every other catalog still uses current producer bytes. The social checklist remains intact. No new browser, Safari or capture observation is claimed. |
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
| mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs | BRDOC-05 | Active | No | Full accepted catalog validation, independent PNG decoding/metrics and positive/negative provenance mutations | PASS — 18 tests, 0 failures in focused post-hardening log |
| test/mailglass/docs_contract_test.exs | BRDOC-03 | Active coverage plus one unrelated legacy skip | No | Active token/guide assertions | PASS WITH WARNING |

**Disabled requirement tests:** 0 direct BRDOC acceptance tests. One pre-existing Phase 38 skipped test remains in the broader docs contract file; it is not the sole proof for BRDOC-03. The current exception registry points at line 826. The prior root-suite report had an outdated line; root was not rerun per owner instruction.
**Circular expected-value patterns:** 0. **Insufficient assertions:** 0.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No current docs warnings emitted by the warnings-as-errors build | Info | Current three-package docs build completed successfully. Historical cross-package link follow-up remains recorded in phase deferred-items.md. |
| test/scripts/brand_docs_contract_test.exs:15 (prior verification) | 15 | Generated-output test depended on ignored checkout docs | Resolved | Plan 03 moved it to the standalone explicit-root output contract and retains source/fixture tests in the default lane. |

No unreferenced TBD/FIXME/XXX debt markers or placeholder implementations were found in the changed implementation code. One 183-02 test contains the string placeholder as an accessibility attribute name; this is data, not a stub marker.

The test temp-directory follow-up is resolved: `temporary_directory!/1` creates an exclusive root with `File.mkdir/1`, retries `:eexist`, and registers recursive cleanup only after successful creation. This prevents a cross-VM candidate collision from deleting another run's files.

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---|---|---|
| — | None. | — | No new-scope concern was found without deterministic evidence. |

### Human Verification Required

None. The candidate's live GitHub and Hex.pm pages remain unobserved because it is unpublished. The historical producer snapshot authenticates source-byte provenance only; it does not establish that historical browser process or add a Safari tab-chrome observation. Those limits are explicit in the record and phase contract. The focused source/archive contracts cover the current acceptance criterion, and no owner UAT is needed.

### Gaps Summary

Plan 03's clean-checkout docs boundary remains intact: root source/fixture checks do not depend on ignored generated docs, and the required docs job builds and validates core, Admin, and Inbound outputs behind CI Green. The previous fresh local output root and generated-doc browser evidence remain as recorded; no browser check was repeated in this verification.

The carried-forward BRDOC-05 gap is closed. The accepted 108-cell catalog validates against the exact historical producer snapshot, whose SHA-256 and Git-blob IDs match compiled constants and the immutable local Git object. The checked producer commit exists, its blob and tree resolve, it is an ancestor of the recorded execution revision, and the fixture matches its bytes exactly. The full catalog still checks source/served/pin data, PNG metrics, limits, and the Safari disclosure. Future catalogs use the current producer digest. No accepted manifest, PNG, pin or favicon source changed, and the 113-file protected inventory is byte-identical before and after.

The post-hardening focused ExUnit log is hash-verified at 18 tests with 0 failures; the browser-free ordering test log is hash-verified at 1 pass. The temp-root fix uses exclusive `mkdir` and only cleans directories it successfully created. No capture alias, browser, broad suite, package build, hosted CI or release action ran. The broad Admin lane and default root suite were not rerun; the last recorded root result remains 2,448 tests with 7 failures, and is not claimed green. Live GitHub/Hex.pm rendering and historical browser-process identity remain unobserved; neither is an owner UAT requirement for this source-level closure.

---

_Verified: 2026-11-18T00:38:05Z_
_Verifier: the agent (gsd-verifier)_

