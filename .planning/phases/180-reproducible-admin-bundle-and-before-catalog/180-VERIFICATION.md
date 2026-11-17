---
phase: 180-reproducible-admin-bundle-and-before-catalog
verified: 2026-11-17T20:55:50Z
status: passed
score: 23/23 must-haves verified
covered_files:
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-01-PLAN.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-01-SUMMARY.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-02-PLAN.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-02-SUMMARY.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-03-PLAN.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-03-SUMMARY.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-04-PLAN.md"
  - ".planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-04-SUMMARY.md"
  - ".planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/cases.json"
  - ".planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/manifest.json"
  - ".planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json"
  - "mailglass_admin/.gitattributes"
  - "mailglass_admin/.gitignore"
  - "mailglass_admin/assets/css/app.css"
  - "mailglass_admin/dev/mailglass_admin/assets_check.ex"
  - "mailglass_admin/docs/design-system.md"
  - "mailglass_admin/e2e/flows.spec.js"
  - "mailglass_admin/e2e/gallery-matrix.spec.js"
  - "mailglass_admin/e2e/phase168-plan03-acceptance.spec.js"
  - "mailglass_admin/e2e/structural.spec.js"
  - "mailglass_admin/e2e/support/theme.cjs"
  - "mailglass_admin/e2e/theme-ownership.spec.js"
  - "mailglass_admin/lib/mailglass_admin/admin_shell.ex"
  - "mailglass_admin/lib/mailglass_admin/gallery_live.ex"
  - "mailglass_admin/lib/mailglass_admin/operator/shell.ex"
  - "mailglass_admin/lib/mailglass_admin/preview/tabs.ex"
  - "mailglass_admin/lib/mailglass_admin/preview_live.ex"
  - "mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex"
  - "mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex"
  - "mailglass_admin/mix.exs"
  - "mailglass_admin/test/mailglass_admin/admin_shell_test.exs"
  - "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs"
  - "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs"
  - "mailglass_admin/test/mailglass_admin/preview_live_test.exs"
  - "mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs"
  - "reference/demo_app/assets/catalog/before-catalog.spec.js"
  - "reference/demo_app/assets/catalog/capture-before-catalog.cjs"
  - "reference/demo_app/assets/e2e/persona-screenshots.spec.js"
  - "reference/demo_app/assets/e2e/phase178-stories.spec.js"
  - "reference/demo_app/assets/playwright.catalog.config.cjs"
  - "reference/demo_app/lib/mailglass_demo/catalog_seed.ex"
covered_digest: "v4:sha256:8023ee1d3dd25cb8b49c02ed4832d08508656ee3837d21be7c400aa99e751424"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 25
  total: 25
  not_honored: []
deferred:
  - truth: "CLAUDE.md item 6 still says CI runs git diff --exit-code on mailglass_admin/priv/static"
    addressed_in: "Phase 183"
    evidence: "Phase 183 success criterion 3 leaves the CLAUDE.md/PRODUCT.md edits drafted pending owner sign-off; the current CLAUDE.md line 140 remains unchanged."
---

# Phase 180: Reproducible Admin Bundle and Before-Catalog Verification

**Phase Goal:** The committed admin bundle can be regenerated and diffed by a CI lane that actually runs, the html element alone controls the theme, and current screens are captured on realistic fixtures so the token swap can be judged against a known before.

**Verified:** 2026-11-17T20:55:50Z  
**Status:** passed  
**Re-verification:** No. The prior report had no gaps frontmatter, so this refresh used initial-mode must-haves and rechecked the current source.

## Goal Achievement

The four roadmap criteria are verified. Current source and gate results were checked separately from the historical before-catalog. No test, browser, capture, or alias action was run during this refresh because the active hash stop remains in force.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The committed generator reproduces the committed bundle byte for byte, and check mode rejects drift. | ✓ VERIFIED | Current AssetsCheck builds to a temporary file and compares bytes; the current bundle contract includes a positive compare plus flipped, truncated, missing-file, and source-input drift controls. The current Admin suite reports 1,824 tests with one separately identified FaviconCatalogTest producer-SHA mismatch; the bundle contract is in the unrestricted test task. Prior direct generator runs are retained as historical evidence, not presented as a new run. |
| 2 | A required CI lane runs the check; deliberate bundle drift fails that lane. | ✓ VERIFIED | ci.yml defines support_contract_admin, invokes mix verify.support_contract.admin, and ci_green.needs includes the job. mix.exs places the --check task before the full test task. The contract test asserts the compare's drift behavior and the lane wiring. |
| 3 | Only html owns data-theme; light, dark, and system re-theme the admin surfaces and browser coverage checks the result. | ✓ VERIFIED | Current lib search finds the assignment only on layouts/root.html.heex:2. The current root-theme contract asserts document ownership, and the theme-ownership browser test covers cookie × OS × surface behavior. Existing recorded browser evidence includes the Phase 183 Docker suite (37 passed) after the token changes; no browser was launched in this refresh. |
| 4 | Before-captures cover the named fixtures and delivery cases, use unique paths, and record a pre-token source SHA. | ✓ VERIFIED | The catalog manifest records source 9eb9deedfcdc435f2ac01bfd9dc2a441e8042662, before the token changes. Read-only inspection confirmed 80 unique PNG paths, matching file sizes and SHA-256 values, 80 aria sidecars, and 8,876,502 PNG bytes. The current superseded marker matches the current bundle and root-layout hashes; the catalog remains explicitly historical evidence. |
| 5 | app.css is the sole generated artifact; source assets remain outside the check. | ✓ VERIFIED | AssetsCheck uses the pinned Tailwind profile and compares only priv/static/app.css; its output path is under the system temp directory. The input CSS retains the prose scan exclusion. |
| 6 | The check fails closed, reports actionable drift, and writes nothing under priv/static. | ✓ VERIFIED | Current source propagates installer failures, uses a temporary output, removes it in an after block, and formats drift with the repair command. Contract tests cover missing, truncated, and changed bytes. |
| 7 | Stale bundle-diff claims in the scoped admin files are corrected and verify.preview ends with the check. | ✓ VERIFIED | Current scoped files and aliases reflect the check. CLAUDE.md item 6 remains a separately deferred owner-sign-off edit, not part of this plan's scoped truth. |
| 8 | Tailwind 4.1.12 linux-x64 under linux/amd64 emits identical bytes. | ✓ VERIFIED | Prior verification recorded a direct emulated-linux comparison against the phase bundle. This is phase-time evidence; it was not repeated. |
| 9 | A cold build path resolves the task and performs the check before tests. | ✓ VERIFIED | The prior verification records the empty MIX_BUILD_PATH run, Tailwind download, check output, and ordering before ExUnit. It is historical execution evidence; the alias was not rerun here. |
| 10 | Preview, operator, inbound, and gallery documents have the intended root-only theme attribute counts. | ✓ VERIFIED | Current root-theme contract covers explicit light/dark and system mode across the named surfaces; the current suite aggregate has only the separately identified favicon failure. |
| 11 | The static theme scan rejects nested owners and token redeclarations. | ✓ VERIFIED | Current root_theme_ownership_contract_test.exs scans lib sources and contains planted invalid-owner and token-declaration cases. |
| 12 | Preview backdrop, tabs, and iframe retain their separated theme/sandbox behavior. | ✓ VERIFIED | Current preview/tabs.ex receives the backdrop state and keeps the iframe isolated with allow-same-origin; existing browser evidence exercised the frame control. |
| 13 | Gallery shows one specimen per state, mounts, and has no duplicate IDs. | ✓ VERIFIED | The current gallery passes per-specimen id_prefix values into composed components, and the current contract now asserts duplicates == []. The old 39-ID floor described in the Nov 15 report is no longer the current implementation. |
| 14 | The Admin coverage floor remains above its baseline. | ✓ VERIFIED | The phase-time coverage run recorded 86.86% against an 83.52% baseline without changing the baseline. No coverage command was rerun in this refresh. |
| 15 | Browser tests cover theme ownership, computed styles, picker transitions, iframe isolation, and forced colors. | ✓ VERIFIED | The browser spec contains these assertions. Existing records show the 37-case connected browser suite passing in the matching Playwright image after the token change. No browser action was taken now. |
| 16 | Existing e2e assertions were reworked rather than deleted. | ✓ VERIFIED | The named operator and demo specs remain present and use the root-owner contract or per-theme page loads. Existing recorded suites passed; no suite was run in this refresh. |
| 17 | The Phase 180 change did not regenerate the axe baseline. | ✓ VERIFIED | The baseline is outside the Phase 180 implementation diff; Phase 181 owns its planned regeneration. |
| 18 | The connected operator browser suite passes and leaves the committed bundle clean. | ✓ VERIFIED | Existing Phase 183 regression evidence records 37 browser cases passing. The current browser suite was not rerun due the active hash stop. |
| 19 | The catalog includes manifest, case map, 80 PNGs, and matching aria sidecars under a unique source-prefixed path. | ✓ VERIFIED | The catalog path is before-9eb9dee-20261115T022124Z; the manifest source SHA shares that prefix. Read-only hash checks found 80/80 PNG matches and all sidecars present. |
| 20 | The four missing UX cases are catalog-seeded and the before source is not rewritten by later fixture work. | ✓ VERIFIED | The historical cases.json contains the four catalog_seed delivery cases. Later DemoData edits do not alter the immutable manifest or captured bytes. |
| 21 | The required-lane manifest validator binds and mutation-checks the catalog. | ✓ VERIFIED | The current manifest test validates catalog contents and current superseded-marker values. The current marker's bundle and root-layout hashes match independently computed working-tree values. Existing phase-time evidence records mutation controls. |
| 22 | Capture guards refuse unsafe, nondeterministic, stale, or over-budget catalog promotion. | ✓ VERIFIED | The current driver contains dirty-tree, server-identity, overwrite, budget, double-capture, relative-time, and pre-promote identity guards. Prior phase-time evidence records exercised refusal paths; no capture was run now. |
| 23 | The original catalog source commit was the final render-input tree at capture time. | ✓ VERIFIED | The manifest ties the catalog to source SHA 9eb9deed and records clean/rechecked state; the prior phase report records the one-time ancestry and render-input diff checks at phase completion. Current repository changes and superseding markers are kept separate from that historical assertion. |

**Score:** 23/23 must-haves verified (0 present-but-behavior-unverified).

### Current Gate Status

The shared current gate reports Storybook/evidence/review 42 passing, Core contracts 82 passing, Admin 1,824 tests with one known FaviconCatalogTest producer-SHA mismatch against the current favicon, and Inbound 481 passing with 3 property exclusions. The Admin aggregate is therefore not fully green today. The known failure is in the later favicon producer/catalog path, not in the Phase 180 bundle, theme-ownership, or before-catalog contracts. It is recorded as a current limitation and is not counted as a Phase 180 gap.

### Required Artifacts

| Artifact | Status | Evidence |
|---|---|---|
| mailglass_admin/dev/mailglass_admin/assets_check.ex | ✓ VERIFIED | Substantive temp-output compare; fail-closed installer behavior. |
| mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex | ✓ VERIFIED | --check parses and delegates to AssetsCheck. |
| mailglass_admin/mix.exs and .github/workflows/ci.yml | ✓ VERIFIED | Alias-first check, required job, and CI Green dependency. |
| bundle_reproducibility_contract_test.exs | ✓ VERIFIED | Positive comparison, failure modes, source-side mutation controls, and wiring checks. |
| root_theme_ownership_contract_test.exs | ✓ VERIFIED | Current root-only scan, document counts, gallery specimen and unique-ID assertions. |
| mailglass_admin/e2e/theme-ownership.spec.js and support/theme.cjs | ✓ VERIFIED | Browser matrix and theme helpers are present and wired. |
| reference/demo_app/assets/catalog and capture driver | ✓ VERIFIED | Capture producer, config, seed, and manifest validator are present and wired. |
| before-9eb9dee-20261115T022124Z | ✓ VERIFIED | 80 PNGs, cases, manifest, aria sidecars, and current superseded marker. The directory is a historical before baseline, not current after-token UI. |

### Key Link Verification

| From | To | Status | Evidence |
|---|---|---|---|
| mix.exs alias | assets build task | ✓ WIRED | First step is mailglass_admin.assets.build --check. |
| assets build task | AssetsCheck | ✓ WIRED | Code.ensure_loaded? and run_check! delegation. |
| ci.yml support_contract_admin | alias | ✓ WIRED | Job runs the alias and is a ci_green dependency. |
| bundle contract test | AssetsCheck.check/1 | ✓ WIRED | Test calls the same compare function. |
| root layout | theme resolver | ✓ WIRED | html root_theme(assigns) resolves cookie/system mode through Theme.data_theme/1. |
| preview_live | preview tabs | ✓ WIRED | Backdrop state is passed into tab content. |
| root-theme contract | root layout | ✓ WIRED | Static allow-list and document-level assertions target the root layout. |
| theme browser spec | theme helper and operator browser server | ✓ WIRED | Cookie/media setup and browser reset/login routes are present. |
| gallery matrix | GalleryLive | ✓ WIRED | Per-state system specimen IDs are consumed by the matrix. |
| catalog driver | reset helper, CatalogSeed, source-identity helper | ✓ WIRED | The driver calls each dependency and writes the resulting identity to manifest data. |
| manifest test | catalog, app.css, root layout | ✓ WIRED | Current file hashes are recomputed and compared with the manifest or exact superseded marker. |

### Data-Flow Trace

| Artifact | Source | Produces real data | Status |
|---|---|---|---|
| Catalog PNGs | Rendered demo app at the manifest source revision with realistic fixtures | Yes, for the recorded pre-token source | ✓ FLOWING (historical) |
| Theme attribute | Theme cookie/system choice → root layout resolver → html | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

No command was run during this refresh. Existing phase records contain the direct byte-check, drift controls, theme browser matrix, and catalog validator results. The current connected browser evidence is the Phase 183 recorded 37-case pass; it is not represented as a new run.

| Behavior | Existing evidence | Status |
|---|---|---|
| Bundle byte equality and drift rejection | Current contract source and phase-time direct checks; current Admin aggregate has the unrelated favicon mismatch | ✓ VERIFIED |
| Root-only theme and computed surface values | Current source contract plus existing connected browser evidence | ✓ VERIFIED |
| Catalog integrity and historical source identity | Read-only PNG SHA/size check and manifest/source/marker inspection | ✓ VERIFIED |

### Probe Execution

Skipped. No plan or summary declares a probe script, and there are no phase-specific probe paths.

### Requirements Coverage

| Requirement | Source | Status | Evidence |
|---|---|---|---|
| BRPIPE-01 | Plans 180-01 | ✓ SATISFIED | Current generator, --check task, negative controls, and required CI wiring. |
| BRPIPE-02 | Plans 180-02 and 180-03 | ✓ SATISFIED | Current html-only owner, server contract, and existing browser matrix evidence. |
| BRPIPE-03 | Plan 180-04 | ✓ SATISFIED | Unique, hash-verified before catalog bound to source 9eb9deed and exact current superseded values. |

No Phase 180 requirements are orphaned.

### Test Quality Audit

| Test File | Requirement | Quality finding |
|---|---|---|
| bundle_reproducibility_contract_test.exs | BRPIPE-01 | Value-level byte comparison and mutation cases; part of the unrestricted Admin test task. |
| root_theme_ownership_contract_test.exs | BRPIPE-02 | Structural/document assertions plus negative controls; current test asserts no duplicate gallery IDs. |
| theme-ownership.spec.js | BRPIPE-02 | Behavioral assertions across theme, OS, surface, picker, iframe, and forced-colors cases. |
| before_catalog_manifest_test.exs | BRPIPE-03 | Recomputes hashes and checks closed manifest, identity, budget, privacy, and marker binding. |

No disabled requirement-linked tests were found. The capture producer writes the screenshots under verification, but the manifest validator independently checks their hashes and metadata; this is not a circular expected-value test.

### Anti-Patterns Found

No unresolved TBD, FIXME, or XXX debt markers were found in Phase 180 implementation files. The existing placeholder text and placeholder UI states are intentional product content.

### Decision Coverage

All 25 trackable CONTEXT decisions are honored by shipped artifacts; none were unhonored.

### Human Verification Required

None for the Phase 180 acceptance criteria. Visual/browser and capture checks were not repeated in this refresh; existing phase and later regression records are cited with their dates and source context.

### Deferred Items

| Item | Addressed in | Evidence |
|---|---|---|
| CLAUDE.md item 6 still says CI runs git diff --exit-code for priv/static | Phase 183 | Phase 183 criterion 3 leaves the paired CLAUDE.md/PRODUCT.md edits awaiting owner sign-off; CLAUDE.md line 140 remains unchanged. |

---

_Verified: 2026-11-17T20:55:50Z_  
_Verifier: gsd-verifier_
