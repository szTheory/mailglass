---
phase: 183-docs-packaging-and-launch-prep
plan: "02"
subsystem: docs
tags: [brandbook, playwright, favicon, hexdocs, trademark, design-system]

# Dependency graph
requires:
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: "Fail-closed trademark policy and immutable brand pin workflow"
  - phase: 181-brand-v2-tokens-fonts-and-logo
    provides: "Pinned v2 brand authority and assets"
provides:
  - "Hardened announcement and public-claim gate with the current caution record still blocking public claims"
  - "Root, Admin and tooling design guidance with pending paired owner patches"
  - "Pinned launch assets and an independently validated 108-cell favicon catalog"
affects: [183-01, readme, hexdocs, package-checks]

# Actuals (#2632)
actuals:
  tokens: 108242
  tasks: 3
  commits: 8

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Refresh declared pinned assets through the manifest-driven update command"
    - "Bind unique Playwright raster catalogs to exact source and served SVG bytes, then recompute their metrics from PNG pixels"

key-files:
  created:
    - DESIGN.md
    - .impeccable/design.json
    - .planning/research/brand-v2-adoption/ANNOUNCEMENT-DRAFT.md
    - .planning/research/brand-v2-adoption/SOCIAL-UPLOAD-CHECKLIST.md
    - mailglass_admin/e2e/favicon-capture.cjs
    - mailglass_admin/test/support/favicon_catalog.ex
    - mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs
    - .planning/research/brand-v2-adoption/favicon-catalog/favicon-299c1aa-20261116T231912Z/manifest.json
  modified:
    - mailglass_admin/docs/design-system.md
    - scripts/brand_trademark_gate.exs
    - scripts/brand_pin.exs
    - brandbook/brand.pin.json
    - mailglass_admin/priv/static/favicon.svg

key-decisions:
  - "The current caution record remains blocked; no register or counsel search, public trademark claim, or announcement was performed."
  - "Keep the paired CLAUDE.md and PRODUCT.md patches pending owner review; canonical files remain unchanged."
  - "Use the owner-approved small-size favicon correction from the pinned brand source."
  - "Keep the ink cutoff at 1.15 and cross-engine IoU minimum at 0.90; real Safari tab chrome remains unobserved."

patterns-established:
  - "Update brand assets through declared source manifests and hash-checked atomic pin updates."
  - "Store one uniquely named catalog per capture and require an independent pixel decoder to validate producer output."

requirements-completed: [BRDOC-03, BRDOC-05, BRDOC-06]
coverage:
  - id: D1
    description: "The current caution record blocks announcements and trademark claims while code rollout and package checks remain separate."
    requirement: BRDOC-06
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Design guidance and sidecar agree with v2 authorities; pending paired owner drafts remain unapplied."
    requirement: BRDOC-03
    verification:
      - kind: unit
        ref: "test/scripts/brand_design_md_test.exs + test/mailglass/docs_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs + mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The approved favicon is pinned and captured across three browsers, both schemes, three sizes and two DPRs; the independent validator accepts the catalog."
    requirement: BRDOC-05
    verification:
      - kind: other
        ref: "PLAYWRIGHT_BROWSERS_PATH=/private/tmp/mailglass-183-02-playwright node mailglass_admin/e2e/favicon-capture.cjs --capture"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs (13 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A repository-only social-preview checklist is prepared; upload and identity changes remain owner actions."
    requirement: BRDOC-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 404min
completed: 2026-11-16
status: complete
---

# Phase 183 Plan 02 Summary

**The caution gate remains fail-closed, the v2 design handoff is ready for owner review, and the corrected favicon passes independent three-engine raster validation.**

## Task Commits

1. **Task 1: Harden the production trademark gate** — `055ca132`, `4767f96e`.
2. **Task 2: Publish v2 design guidance and pending owner patches** — `99db0371`, `8b5e4568`.
3. **Task 3: Pin launch artwork and prove favicon legibility** — `60585b79`, `869397a1`, `ea76cb3e`, `2415f499`.
4. **Plan metadata:** this summary is committed separately after final verification.

## Pinned Source and Capture

The owner-approved small-size correction is from `szTheory/mailglass-brand` commit `677b9d300e0da01abb199076b301bae36447d2da`. Its archive SHA-256 is `3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56`; the favicon SHA-256 is `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5`.

## Performance

- **Elapsed time:** About 6 hours 44 minutes from the first plan-scoped commit through the resumed validation; this spans the prior session and pauses, so it is not active execution time.
- **Started:** 2026-11-16T16:42:04Z (first plan-scoped commit; exact start is unavailable).
- **Completed:** 2026-11-16T23:25:40Z.
- **Tasks:** 3.
- **Files changed in the final source/evidence commit:** 124, including 108 PNG captures.

## Accomplishments

- Hardened the trademark gate and public-text scan. The current caution record still blocks the announcement and unsupported trademark claims, while package checks and code rollout remain independent.
- Published local v2 design guidance and parity checks. The paired `CLAUDE.md` and `PRODUCT.md` patches remain pending, and the canonical files were not changed.
- Updated the source pin through the declared manifest and synchronized the Admin-served favicon. The corrected source is bound to archive SHA-256 `3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56` and favicon SHA-256 `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5`.
- Captured 108 unique PNG cells with Chromium 159.0.8154.6, Firefox 159.0 and WebKit 27.2. Each engine passed its light/dark theme probe. The independent validator passed 13 tests with no failures at ink cutoff 1.15 and minimum cross-engine IoU 0.90.
- Wrote the repository-only social-preview upload checklist. No upload, personal-avatar change, public announcement, trademark search, package publish, release, deployment or remote tag action occurred.

## Validation Results

- `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` — 45 focused tests passed in the prior plan execution.
- `mix test test/scripts/brand_design_md_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 0` — passed in the prior plan execution.
- `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/operator/health_overview_test.exs --warnings-as-errors --seed 0` — passed in the prior plan execution.
- `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0` — 77 tests, 0 failures.
- `node mailglass_admin/e2e/favicon-capture.cjs --check` — source and served favicon hashes match the pin.
- `PLAYWRIGHT_BROWSERS_PATH=/private/tmp/mailglass-183-02-playwright node mailglass_admin/e2e/favicon-capture.cjs --capture` — 108 cells, 81,102 PNG bytes, all engines and themes represented.
- `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/favicon_catalog_test.exs --warnings-as-errors --seed 0` — 13 tests, 0 failures.
- `git diff --check` — passed.

The passing catalog is preserved at `.planning/research/brand-v2-adoption/favicon-catalog/favicon-299c1aa-20261116T231912Z/`. The earlier failed default-cache launch is separately preserved under `failed-favicon-catalog-evidence/`; it produced no cells and does not affect the accepted catalog. No thresholds were changed. Actual Safari tab chrome was not observed.

## Files Created/Modified

- `scripts/brand_trademark_gate.exs` and its tests — production caution gate and public-text claim scan.
- `DESIGN.md`, `.impeccable/design.json`, and `mailglass_admin/docs/design-system.md` — v2 design authority and parity contract.
- `.planning/research/brand-v2-adoption/owner-signoff/` — paired pending owner patches and sign-off instructions.
- `brandbook/brand.pin.json`, `brandbook/v2/`, and `mailglass_admin/priv/static/favicon.svg` — pinned artwork and synchronized served favicon.
- `mailglass_admin/e2e/favicon-capture.cjs`, `mailglass_admin/test/support/favicon_catalog.ex`, and `mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs` — bounded producer and independent PNG validator.
- `.planning/research/brand-v2-adoption/favicon-catalog/favicon-299c1aa-20261116T231912Z/` — passing immutable browser catalog.

## Deviations and Issues

The first fresh invocation used the default Playwright cache and stopped before Chromium launch because revision 1255 was absent there. The owner authorized one new attempt. Inspection found the pinned 1.65.1 browser binaries in the task cache, so the approved capture used that cache and passed; no browser download or dependency install was needed. No further capture is authorized.

A full core/Admin/inbound regression run and the real docs/package checks remain at the phase wave-end gate after plan 183-01. Earlier broad-suite runs included known Phase 164/environmental failures and a catalog failure that this focused validator now clears; those failures must be reported accurately when the phase-wide suites run. No CI run was observed for this plan, so there are no CI timing observations or optimization findings to record.

## User Setup Required

None for the completed plan. The owner may review the paired instruction patches, perform trademark/counsel review before any public trademark claim, and optionally upload/read back the repository social card using the checklist. Those actions were not performed here.

## Next Phase Readiness

Plan 183-02 is complete. Plan 183-01 is now unblocked and can consume the pinned v2 assets and design guidance. Continue the already approved Phase 183 workflow; the full regression suites and generated-doc/package checks remain required before phase verification.

---
*Phase: 183-docs-packaging-and-launch-prep*
*Plan: 02*
*Completed: 2026-11-16*
