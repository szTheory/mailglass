---
phase: 183-docs-packaging-and-launch-prep
plan: "01"
subsystem: docs-packaging
tags: [readme, exdoc, hex, brand-v2, lowercase-lint]
requires:
  - phase: 183-02
    provides: Accepted pinned launch artwork, favicon evidence, design guidance, and announcement gate
provides:
  - Immutable, theme-aware README artwork and offline image-byte verification across all packages
  - Real generated docs contracts for the three Hex packages with native ExDoc theme behavior
  - Structural lowercase prose lint and actual Hex payload verification with package release gates
affects: [hex-packaging, adopter-docs, exdoc, brand-name-lint, release-checks]
actuals:
  tokens: 40659
  tasks: 3
  commits: 5
  plan_head_before: 94e42eb4978e0df930355c36a62302443cb44ab2
  plan_head_after: a1d342e4a85d4983b2745c0fd8c57f3c815158d1
tech-stack:
  added: []
  patterns:
    - Offline verification of immutable image refs against repository blobs
    - Generated-output inspection and native ExDoc theme verification per package
    - Structural prose scanning with explicit, scoped compatibility exceptions
    - Actual unpacked Hex payload comparison against reviewed goldens and brand pins
key-files:
  created:
    - scripts/brand_docs_check.exs
    - scripts/brand_name_lint.exs
    - test/scripts/readme_image_contract_test.exs
    - test/scripts/brand_docs_contract_test.exs
    - test/scripts/brand_name_lint_test.exs
    - test/mailglass/publish/brand_asset_allowlist_test.exs
    - brandbook/exdoc/code-colors.css
    - brandbook/exdoc/theme-mark.js
    - mailglass_admin/e2e/docs-theme-contract.cjs
  modified:
    - README.md
    - mailglass_admin/README.md
    - mailglass_inbound/README.md
    - mix.exs
    - mailglass_admin/mix.exs
    - mailglass_inbound/mix.exs
    - lib/mix/tasks/mailglass.publish.check.ex
    - scripts/brand_trademark_gate.exs
    - .planning/publish/mailglass_admin-files.expected
    - .planning/phases/183-docs-packaging-and-launch-prep/deferred-items.md
key-decisions:
  - "Keep ExDoc 0.40.4, Lato, and its native class-driven theme; add only syntax color CSS and a small class-driven logo selector."
  - "Keep the trademark announcement gate independent from package publication readiness; the caution record remains denied for announcement."
  - "Preserve canonical CLAUDE.md and PRODUCT.md for owner review and do not introduce dependencies."
patterns-established:
  - "README media is selected by standard renderer fragments and validated offline against exact pinned bytes."
  - "Package brand claims are proven against actual unpacked contents, not only a file-list golden."
requirements-completed: [BRDOC-01, BRDOC-02, BRDOC-04]
coverage:
  - id: D1
    description: "Three package READMEs use immutable, theme-aware lockup URLs whose paths and bytes are checked against pinned assets."
    requirement: BRDOC-01
    verification:
      - kind: unit
        ref: "test/scripts/readme_image_contract_test.exs#offline immutable ref, byte, fallback, and geometry contracts"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/docs-theme-contract.cjs --all"
        status: pass
    human_judgment: false
  - id: D2
    description: "Core, Admin, and Inbound generated docs retain native ExDoc theme and Lato behavior while carrying the pinned mark, favicon, and code-only colors."
    requirement: BRDOC-02
    verification:
      - kind: integration
        ref: "mix docs in core, mailglass_admin, and mailglass_inbound; scripts/brand_docs_check.exs --package core|admin|inbound"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/docs-theme-contract.cjs --all"
        status: pass
    human_judgment: false
  - id: D3
    description: "Lowercase adopter prose and actual Hex payloads are checked, with all three package readiness checks passing independently of the announcement gate."
    requirement: BRDOC-04
    verification:
      - kind: unit
        ref: "test/scripts/brand_name_lint_test.exs; test/mailglass/publish/brand_asset_allowlist_test.exs"
        status: pass
      - kind: integration
        ref: "mix mailglass.publish.check --package mailglass|mailglass_admin|mailglass_inbound"
        status: pass
    human_judgment: false
duration: 83min
completed: 2026-11-17
status: complete
---

# Phase 183 Plan 01: Docs, Packaging and Launch Prep Summary

**Three adopter packages now ship pinned theme-aware README and ExDoc identity, enforce lowercase prose, and verify real package payloads without changing public APIs or email defaults.**

## Performance

- **Duration:** 1h 23m
- **Started:** 2026-11-16T23:38:09Z
- **Completed:** 2026-11-17T01:01:02Z
- **Tasks:** 3/3
- **Files modified:** 98

## Accomplishments

- Added light/dark README lockups using immutable source URLs, lowercase alt text, and offline blob checks across core, Admin, and Inbound.
- Built and checked real ExDoc output for all packages. The custom CSS changes syntax colors only; Lato and the native class-driven toggle remain in place. Browser evidence covers both themes, opposite OS preference, image decoding, and narrow layouts.
- Added structural lowercase-name lint and actual unpacked-package checks. All three package publish checks pass; the Admin payload golden now includes its two real operator modules and the required pinned fonts, licenses, logo, and favicon.
- Kept public module names, wire headers, host email defaults, and canonical owner-controlled `CLAUDE.md` / `PRODUCT.md` unchanged. No dependency was added.

## Task Commits

1. **Task 1: Render the core README through a real v2 ExDoc build and native theme switch** — `8b4d055b` (contract tests), `7815e1b3` (implementation).
2. **Task 2: Expand the proven README and docs contract to Admin and Inbound** — `46abc48b` (implementation).
3. **Task 3: Enforce lowercase prose and prove the actual Hex payload contracts** — `c945a203` (contract tests), `a1d342e4` (implementation).

## Files Created/Modified

- `scripts/brand_docs_check.exs`, `scripts/brand_name_lint.exs` — generated docs and adopter prose checks.
- `test/scripts/readme_image_contract_test.exs`, `test/scripts/brand_docs_contract_test.exs`, `test/scripts/brand_name_lint_test.exs`, `test/mailglass/publish/brand_asset_allowlist_test.exs` — source, generated-output, casing, digest, and actual archive contracts.
- `brandbook/exdoc/code-colors.css`, `brandbook/exdoc/theme-mark.js`, `mailglass_admin/e2e/docs-theme-contract.cjs` — scoped ExDoc assets and local browser contract.
- Three package READMEs and all three `mix.exs` files — consistent README artwork and generated docs configuration.
- `lib/mix/tasks/mailglass.publish.check.ex`, `.planning/publish/mailglass_admin-files.expected`, `scripts/brand_trademark_gate.exs` — actual package gates, reviewed payload golden, and corrected pin binding.
- Adopter docs, guides, rendered Admin copy/tests, and installer README golden — lowercase product prose with public APIs and behavior retained.

## Decisions Made

- Kept ExDoc's native typography and theme mechanism. A small class observer switches the single emitted sidebar mark; no matchMedia preference or broad layout styling was introduced.
- Kept the announcement/counsel gate separate from package readiness. Code and package checks can pass while the current caution record continues to deny an announcement.
- Used task-local Hex/Mix resolution state for package verification after sandbox-protected global caches and an asdf shim prevented reads. The user's global tool state was not changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the pinned trademark-input digest**
- **Found during:** Task 3 package/trademark validation.
- **Issue:** The gate's stored digest did not match the current pinned `brandbook/v2/brand.json`, causing its tests to fail.
- **Fix:** Rebound the check to the approved source pin and verified the focused gate suite.
- **Files modified:** `scripts/brand_trademark_gate.exs`.
- **Verification:** `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` passed 45 tests.
- **Committed in:** `a1d342e4`.

**2. [Rule 1 - Bug] Made the favicon mutation test mutate an existing path**
- **Found during:** Task 3 support-contract regression lane.
- **Issue:** The accepted favicon changed the SVG path token, so the old test mutation no longer changed any bytes and could pass vacuously.
- **Fix:** Mutated the present `M9.98 12.2` path and asserted that the bytes changed.
- **Files modified:** `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs`.
- **Verification:** The focused logo asset suite passed 29 tests; Admin support lane passed on rerun.
- **Committed in:** `a1d342e4`.

**3. [Rule 3 - Blocking] Isolated package check cache state**
- **Found during:** Task 3 full package readiness checks.
- **Issue:** Global Hex cache access was denied by the sandbox; an asdf shim also ignored the task-local Mix home for its archive lookup.
- **Fix:** Used a task-local `HEX_HOME` and direct installed Mix executable with task-local copied archive/cache. Global Hex and asdf state was left untouched; report files were restored byte-for-byte after the checks.
- **Verification:** All three full package checks passed independently.
- **Files modified:** No committed project source beyond the planned package checks.

**4. [Rule 1 - Bug] Recorded existing docs link and ExDoc warnings**
- **Found during:** Final docs builds.
- **Issue:** Inbound package-relative compatibility guide links point outside the package, and Admin/Inbound docs contain existing links to hidden internal modules/functions.
- **Fix:** Recorded the exact follow-up in `deferred-items.md`; builds and generated-output checks remain green.
- **Verification:** All three `mix docs` builds and all three docs checks passed.
- **Committed in:** `a1d342e4`.

**5. [Rule 3 - Blocking] Preserved the existing Windows ledger mismatch**
- **Found during:** Best-effort skipped-test ledger append.
- **Issue:** `.planning/WINDOWS.md` has a pre-existing disagreement between rendered table and fenced JSON at row 48.
- **Fix:** Left the ledger untouched and documented the failed append in `deferred-items.md`; no manual repair was in scope.
- **Verification:** The existing skipped Phase 38 contract remains identified in the plan notes; no new skip was added.
- **Committed in:** `a1d342e4`.

**Total deviations:** 5 auto-fixed or documented (2 bug fixes, 3 validation/tooling issues).
**Impact on plan:** Scope remained within the approved docs, casing, and package contracts. No dependencies, external writes, or owner-controlled canonical document edits were made.

## Validation

- Lowercase lint, mutation tests, docs source/output tests, Admin rendered-copy and navigation tests, installer smoke, favicon assets, and trademark gate all passed.
- The core support lane passed 140 tests with one pre-existing skipped contract. Inbound passed 34/34. Admin passed 1,816 with one excluded case.
- All three docs builds, per-package docs output checks, and local three-engine browser docs checks passed. ExDoc emitted existing hidden-internal-link warnings; Inbound also retains the external-to-package compatibility-guide links described above.
- `mix mailglass.publish.check --allowlist-only` passed for all packages. Full package checks passed: core (19 steps), Admin (18), and Inbound (18). The expected Admin golden includes six WOFF2 files, three OFL texts, logo, favicon, and the two missing operator modules; core and Inbound contain no brand fonts/source payload.
- Favicon evidence source pin matched `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5`. Shared ExDoc asset hashes: light mark `d62b4f66ae060d3d379e6f9072c740440aa9c21c2550163e184698264d896f92`, dark mark `97810e12cb76f8ebecb5efdd594613e334a872397e56bf9b77625d5cd3ed041b`, favicon same as pin above, CSS `13d429050607a69251253a66e4261ce18755f3798301a24629ef7c98c3fbeecd`, theme script `afa5e4ea33b868ecf6a7e7fc49a3ad9a9f3dcfdd529ac3c3d1289ec87960b551`.
- Generated docs were hash-checked and removed after validation; no generated docs output was left untracked. `doc/.DS_Store` was preserved.
- `git diff --check` passed. No threat flags: changes add static documentation validation and package-content checks, not runtime network endpoints, auth paths, or new trust-boundary access.

## Announcement Gate

The plan's announcement check returned `deny (not_clear)`: the current record is cautionary and its register check is not complete. This is an expected safety result, not a package blocker. No trademark search/claim, public announcement, social upload, publication, remote tag, release, deployment, or external write was performed.

## Unrelated CI Run Observed (Read Only)

At inspection, this run was still in progress; it was not changed or rerun:

- [GitHub Actions run 43990268130](https://github.com/szTheory/mailglass/actions/runs/43990268130), SHA `fce1b2ed3f12d2ac1044201d8ffec1331c20a78e`, branch `release-please--branches--main`.
- `Support Contract Core` failed at **Install demo deps** in 40s, and `Core Deterministic Suite` failed at the same step in 41s. Downstream steps were skipped. `Demo Browser Evidence` failed at **Run demo browser evidence** in 126s. Detailed logs were unavailable while the run remained in progress; no cause is inferred here.
- Other observed job durations: Detect Non-Doc Changes 8s (success); Branch Protection Advisory 18s (success); Inbound Test 253s (success); Compile Warnings as Errors 101s (success); Installer Host Smoke 356s (success); Compile No Optional Deps 120s (success); Docs Warnings as Errors 91s (success); CI Green 16s (failure); Format Check 27s (success); Mix Task Tests 331s (success); Operator Browser Gate at least 528s and still running at last sample; Dialyzer 144s (success); Deps Audit 125s (success); Trust Lane Clean Baseline 167s (success); Trust Lane Repo Head 272s (success); Support Contract Admin 192s (success); Design System Conformance 7s (success); Credo Strict 119s (success); Hex Audit 139s (success); Inbound Dialyzer 261s (success); Inbound Compile No Optional Deps 89s (success); Installer Golden Gate 108s (success); Preview Capture Advisory 270s (success).
- The longest completed job was Installer Host Smoke at 5m56s. At the last observation, Operator Browser Gate was the unresolved critical path at 8m48s or longer. CI Green reported failure after about 6m47s of wall time while that browser gate remained pending.
- The run repeats dependency setup across isolated lanes. The isolation is intentional, and this single unrelated run does not establish a safe way to share it; no CI optimization or workflow edit was made.

## Deferred Issues

- Existing Phase 38 prepublish-proof skip and `.planning/WINDOWS.md` row 48 inconsistency remain; the attempted best-effort append failed without changing the ledger.
- Existing Inbound cross-package compatibility-guide links and Admin/Inbound links to hidden internal modules remain for a docs-specific follow-up.
- Canonical `CLAUDE.md` and `PRODUCT.md` draft patches remain pending owner review and were not applied.

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- All five task commits are ancestors of the current HEAD.
- `git diff --check` passed.
