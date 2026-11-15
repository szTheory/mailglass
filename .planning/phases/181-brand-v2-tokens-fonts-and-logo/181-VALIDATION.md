---
phase: "181"
slug: "brand-v2-tokens-fonts-and-logo"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-15"
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

Task IDs are filled by the planner; requirement-level map from research:

| Requirement | Plan | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|------|----------|-----------|-------------------|-------------|--------|
| BRTOK-01 | 01 | tokens.json == tokens.css == bundle for all roles x 3 blocks; palette hex == brand.json by name | unit | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs` | ✅ rewrite | ⬜ pending |
| BRTOK-01 | 01 | v2 anchors present, v1 hexes absent | unit | `mix test test/mailglass_admin/brand_test.exs` | ✅ rewrite | ⬜ pending |
| BRTOK-01 | 01 | bundle reproducible, catalog marker current | gate + unit | `mix mailglass_admin.assets.build --check`; `mix test test/mailglass_admin/{bundle_reproducibility_contract,before_catalog_manifest}_test.exs` | ✅ | ⬜ pending |
| BRTOK-02 | 01 | book pairs + admin pairs + coverage guard + `never` rules | unit | `mix test test/mailglass_admin/contrast_contract_test.exs` | ❌ W0 | ⬜ pending |
| BRTOK-02 | 01 | no dependency added | shell | `git diff --exit-code -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json` | ✅ | ⬜ pending |
| BRTOK-03 | 02 | woff2 magic, set equality, no remote URL, OFL texts, 404 outside allow-list | unit + endpoint | `mix test test/mailglass_admin/{font_assets_contract,assets,bundle}_test.exs` | ❌ W0 | ⬜ pending |
| BRTOK-03 | 02 | pin ships exactly expected assets; owned-dir set equality | unit | `mix test test/scripts/brand_pin_test.exs` (root) | ✅ edit | ⬜ pending |
| BRTOK-03 | 02 | Hex tarball file list | task | `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` | ✅ | ⬜ pending |
| BRTOK-03 | 02 | no glyph outside the 170-codepoint subset in rendered text | unit | `mix test test/mailglass_admin/glyph_contract_test.exs` | ❌ W0 | ⬜ pending |
| BRTOK-04 | 03 | favicon and logo byte/path identical to pin; no U+2190-2193; every `hero-*` has a bundle rule | unit | `mix test test/mailglass_admin/{logo_assets_contract,glyph_contract,assets,bundle}_test.exs` | ❌ W0 | ⬜ pending |
| BRTOK-05 | 04 | axe ratchet; baseline regenerated once, last | unit + producer | `mix test test/mailglass_admin/axe_baseline_test.exs`; `PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js` | ✅ | ⬜ pending |
| BRTOK-06 | 04 | core defaults untouched | phase-scope diff + tests | `git diff --exit-code <PHASE_BASE>..HEAD -- lib test/mailglass test/fixtures test/support`; `mix test test/mailglass/components/vml_preservation_test.exs`; root `mix test --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*. `<PHASE_BASE>` = `9bd70fa5`.

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/support/contrast.ex` — BRTOK-02
- [ ] `mailglass_admin/test/support/glyph_scan.ex` — BRTOK-03/04
- [ ] `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` — BRTOK-02
- [ ] `mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs` — BRTOK-03
- [ ] `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs` — BRTOK-03/04
- [ ] `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` — BRTOK-04
- [ ] `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json` updated in every bundle-moving plan

No new framework or dependency.

---

## Manual-Only Verifications

All phase behaviors have automated verification. The browser network check (no font request leaves the host) is an advisory Playwright run recorded as evidence, never as the required proof (Phase 180 D-04/D-13).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (quick run)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
