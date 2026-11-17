---
phase: "181"
slug: "brand-v2-tokens-fonts-and-logo"
status: partial
nyquist_compliant: false
wave_0_complete: true
created: "2026-11-15"
audited_at: "2026-11-17T19:31:23Z"
---

# Phase 181 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `181-RESEARCH.md` § Validation Architecture. Zero human UAT (D-52): every row is machine-observed.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27); `node --test` for evidence scripts; Playwright (advisory only, never cited as required proof) |
| **Config file** | `mailglass_admin/test/test_helper.exs`; `mailglass_admin/mix.exs` aliases (`verify.support_contract.admin`) |
| **Toolchain env** | `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/{token_parity,brand,accessibility,contrast_contract,bundle,assets,font_assets_contract,glyph_contract,logo_assets_contract,before_catalog_manifest}_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin` (runs `mailglass_admin.assets.build --check` first) |
| **Estimated runtime** | quick ~5 s; admin lane ~22 s; root `mix test --warnings-as-errors` several minutes |

---

## Sampling Rate

- **After every task commit:** quick run command (plus `mix test test/scripts/brand_pin_test.exs` when the pin or scripts moved)
- **After every plan:** `mix verify.support_contract.admin`, the conformance trio (`check-conformance.sh`, `check_motion_conformance.sh`, `check-conformance-advisory.sh`), `mix format --check-formatted` in root and `mailglass_admin`, allowlist task and node evidence tests after the font plan
- **Phase gate:** root `mix test --warnings-as-errors` (`core_deterministic_suite`) + admin lane; axe producer once, last; then `/gsd-verify-work`
- **Max feedback latency:** 30 seconds for the quick run

---

## Per-Task Verification Map

Per-task rows (task IDs from the four PLAN files). Admin commands run from `mailglass_admin/` with the toolchain env; root commands from the repo root. Exact command text and `<fails_when>` live in each task's `<verify>`; this table names them.

| Task ID | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|---------|-------------|----------|-----------|-------------------|-------------|--------|
| 181-01-T1 | BRTOK-01, BRTOK-05 | tokens.json == tokens.css == bundle for 41 roles x 3 blocks; palette == brand.json by name; designed values recompute under `round/1`; v2 anchors present, v1 hexes absent; marker current | gate + unit | `MIX_ENV=test mix mailglass_admin.assets.build --check && mix test test/mailglass_admin/{token_parity,brand,before_catalog_manifest,bundle_reproducibility_contract}_test.exs --warnings-as-errors --seed 0`; `grep -oE -- '--mg-[a-z-]+:#[0-9a-fA-F]{3,6}\b' priv/static/app.css \| wc -l` == 123 | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-01-T2 | BRTOK-02, BRTOK-05 | book pairs, admin pairs (incl. designed/unconsumed roles), slot and designed-value coverage guards, `never` rules; accessibility_test on the 0.04045 helper | unit | `mix test test/mailglass_admin/{contrast_contract,accessibility}_test.exs --warnings-as-errors --seed 0` | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-01-T3 | BRTOK-01, BRTOK-03 (wording), BRTOK-02 (no dep) | slot/woff2 counts and criterion 3 static-proof wording amended; no lockfile or core change | shell | wording `grep -c` == 0; `git diff --exit-code 9bd70fa5 -- <lockfiles> lib test/mailglass test/fixtures test/support` | ✅ | 🟢 phase-time green; scope guard is historical |
| 181-01 plan-end | BRTOK-01/02/05 | whole admin lane cold, conformance, format, docs_contract | lane | `MIX_BUILD_PATH=<cold> mix verify.support_contract.admin`; conformance trio; root `mix test test/mailglass/docs_contract_test.exs test/scripts/icon_exists_gate_test.exs test/scripts/brand_pin_test.exs` | ✅ | 🟡 phase-time green; current Admin lane has the favicon source-hash blocker below |
| 181-02-T1 | BRTOK-03 | pin `extend` + verify; 16 shipped assets; compile-time font map; 404 outside allow-list; bundle/marker/allowlist current | unit + task | `mix run --no-start scripts/brand_pin.exs verify && mix test test/scripts/brand_pin_test.exs` (root); `mix test test/mailglass_admin/{bundle,assets,before_catalog_manifest,token_parity}_test.exs`; `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` | ✅ exists | 🟢 phase-time green (181-02-SUMMARY) |
| 181-02-T2 | BRTOK-03 | woff2 magic, set equality, face table, no remote URL, OFL texts, tabular numerals on list rows; 400/600 docs | unit | `mix test test/mailglass_admin/{font_assets_contract,token_parity}_test.exs --warnings-as-errors --seed 0 && bash scripts/check-conformance.sh` | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-02-T3 | BRTOK-03 | evidence scripts name v2 fonts; no retired font in owned files | node + shell | `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs`; retired-font `git grep` gate == 0 | ✅ exists | 🟢 Node contracts current green (42); font grep historical green |
| 181-02 plan-end | BRTOK-03 | admin lane cold, root targeted files, pin verify, allowlist, conformance, lockfiles | lane | see 181-02 `<verification>` Plan-end gate | ✅ | 🟡 phase-time green; current Admin lane has the favicon source-hash blocker below |
| 181-03-T1 | BRTOK-04 | no U+2190-2193 in rendered lib text; every `hero-*` has a bundle rule | unit + gate | `MIX_ENV=test mix mailglass_admin.assets.build --check && mix test test/mailglass_admin/{glyph_contract,before_catalog_manifest,bundle}_test.exs && bash scripts/check-conformance.sh` | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-03-T2 | BRTOK-03 | no glyph outside the 170-codepoint subset; subset bound to pinned woff2 hashes; lib-derived pins follow | unit | `mix test test/mailglass_admin/{glyph_contract,before_catalog_manifest,operator_live,components,preview_live}_test.exs test/mailglass_admin/operator/repair_state_test.exs` | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-03-T3 | BRTOK-03, BRTOK-04 | e2e and demo replay pins follow lib text; fixtures and core untouched | shell | replay-audit middot `grep` == 0; `git diff --exit-code 9bd70fa5 -- <lockfiles> lib test/mailglass test/fixtures test/support mailglass_admin/test/support/operator_fixtures.ex` | ✅ | 🟢 phase-time green; scope guard is historical |
| 181-03 plan-end | BRTOK-03/04 | admin lane cold, conformance (ICON-EXISTS-GATE), icon_exists_gate_test, format | lane | see 181-03 `<verification>` Plan-end gate | ✅ | 🟡 phase-time green; current Admin lane has the favicon source-hash blocker below |
| 181-04-T1 | BRTOK-04 | logo byte/path/token identity; inline logo follows `<html data-theme>` | unit | `MIX_ENV=test mix mailglass_admin.assets.build --check && mix test test/mailglass_admin/{logo_assets_contract,bundle,before_catalog_manifest,root_theme_ownership_contract,glyph_contract}_test.exs && bash scripts/check-conformance.sh`; `cmp` logo == 0 | ✅ exists | 🟢 current Admin suite passed these contracts |
| 181-04-T2 | BRTOK-04 (+BRTOK-03 advisory half) | favicon byte identity; no v1 colour or retired font tree-wide; advisory specs expect v2 faces at 600 | unit + shell | `mix test test/mailglass_admin/{assets,logo_assets_contract}_test.exs`; `cmp` favicon == 0; v1-colour grep == 0; retired-font gate (no deferrals) == 0; `"700"` grep == 0 | ✅ exists | 🔴 blocker: current FaviconCatalogTest producer SHA differs from the current favicon source; preserve stop |
| 181-04 plan-end | BRTOK-06, all | root full suite (`core_deterministic_suite` mirror), admin lane cold, pin, allowlist, conformance, node, format; run BEFORE the axe producer | lane | see 181-04 `<verification>` Plan-end gate | ✅ | 🟡 partial current regression evidence; Admin source-hash blocker remains |
| 181-04-T3 | BRTOK-05, BRTOK-06 | core defaults untouched; axe ratchet; baseline regenerated once, last, no new `color-contrast` | phase-scope diff + unit + producer | `git diff --exit-code 9bd70fa5 -- lib test/mailglass test/fixtures test/support <lockfiles> && mix test test/mailglass/components/vml_preservation_test.exs`; `mix test test/mailglass_admin/axe_baseline_test.exs` + commit count == 1; `PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js` (producer, once) | ✅ | 🟢 phase-time green; producer/browser evidence is historical |

*Status: 🟢 green · 🟡 partial/historical · 🔴 blocker*. Current aggregate runs are distinguished from phase-time evidence in the audit record below. `<PHASE_BASE>` = `9bd70fa5`. `<lockfiles>` = `mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json`.

---

## Wave 0 Requirements

- [x] `mailglass_admin/test/support/contrast.ex` — BRTOK-02
- [x] `mailglass_admin/test/support/glyph_scan.ex` — BRTOK-03/04
- [x] `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` — BRTOK-02
- [x] `mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs` — BRTOK-03
- [x] `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs` — BRTOK-03/04
- [x] `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` — BRTOK-04
- [x] `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json` updated in every bundle-moving plan

No new framework or dependency.

---

## Manual-Only Verifications

All phase behaviors have automated verification. The browser network check (no font request leaves the host) is an advisory Playwright run recorded as evidence, never as the required proof (Phase 180 D-04/D-13).

---

## Validation Audit — 2026-11-17

**Verdict: PARTIAL.** The phase plans and summaries show the planned behavioral tests and mutation checks were completed. The current-tree refresh has a single observed blocker in the favicon catalog provenance check; it is preserved as a stop. No additional deterministic test is missing, so this refresh adds no test files.

### Current-tree evidence

| Lane | Observed result | Scope |
|------|----------------|-------|
| Storybook/evidence contracts | 42 passed | Current deterministic Node evidence suite; the command is listed in 181-02-T3. |
| Core deterministic contracts | 82 passed | Current scoped core contract run. |
| Admin alias / ExUnit | 1,824 tests; 1 failure | The only failure is `FaviconCatalogTest`: the existing `favicon-299c1aa-20261116T231912Z` producer SHA differs from the current favicon source. This leaves 181-04-T2 blocked. |
| Inbound deterministic suite | 481 passed; 3 properties excluded | Current regression evidence; exclusions remain exclusions, not passes. |
| Browser and hosted checks | Not run in this refresh | Any browser results in 181-04-SUMMARY are historical evidence only. No current browser or hosted behavior is claimed. |

The current Admin failure is classified **BLOCKER** for the favicon source-identity requirement: an existing behavioral check fails against the current source bytes. Preserve the source-hash stop. Do not recapture or rewrite favicon evidence, and do not rerun the full Admin alias under this refresh. The supplied run is the observed failure; no retry was performed. This audit did not modify implementation files or other working-tree changes.

Historical phase execution remains documented in `181-01-SUMMARY.md` through `181-04-SUMMARY.md`: each plan's admin lane and mutation checks were green at plan completion, with the recorded root-suite environment failure and advisory browser caveats in `181-04-SUMMARY.md`. Those historical results are not represented as current browser/hosted verification.

### Coverage disposition

| Requirement area | Classification | Evidence / limitation |
|------------------|----------------|-----------------------|
| BRTOK-01/02 tokens and contrast | FILLED | Current Admin ExUnit batch exercised the existing token parity, contrast and accessibility contracts; their mutation teeth are recorded in 181-01-SUMMARY. |
| BRTOK-03 fonts and glyph coverage | FILLED | Current Admin ExUnit batch and 42 Node evidence contracts passed; font tree grep evidence is historical. |
| BRTOK-04 logo, favicon and icon coverage | BLOCKER | Logo and glyph contracts pass in the current Admin batch, but the favicon catalog producer-SHA assertion fails as described above. No evidence refresh is authorized by this stop. |
| BRTOK-05 contrast ratchet | FILLED at phase completion | Axe baseline provenance and mutation evidence passed in 181-04-SUMMARY; browser/producer behavior was not rerun in this refresh. |
| BRTOK-06 host email defaults | FILLED at phase completion | Phase-scope diff and VML test were green at plan completion; current core/inbound scoped suites passed, but the phase-start diff was not rerun against later working-tree edits. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 artifacts exist in the current tree
- [x] No watch-mode flags
- [x] Phase-time quick checks were within the planned feedback window
- [ ] `nyquist_compliant: true` set in frontmatter; the current favicon source-hash blocker keeps this false

**Approval:** Partial. Tests cover the phase requirements and passed at phase completion. The current favicon catalog source-hash failure is unresolved by design under the preserved stop; browser and hosted checks were not run during this refresh.
