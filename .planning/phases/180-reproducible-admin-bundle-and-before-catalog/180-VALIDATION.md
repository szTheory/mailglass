---
phase: "180"
slug: reproducible-admin-bundle-and-before-catalog
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-14"
---

# Phase 180 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `180-RESEARCH.md` § Validation Architecture (lane facts verified against `ci.yml` and `config/quality/ci_policy.exs`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27) in `mailglass_admin`; Playwright 1.59.1 for browser (advisory) |
| **Config file** | `mailglass_admin/mix.exs` aliases; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && mix mailglass_admin.assets.build --check && mix test test/mailglass_admin/<new_file>_test.exs --seed 0` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin` |
| **Browser (advisory)** | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 e2e/theme-ownership.spec.js` |
| **Estimated runtime** | quick ~10 s; full admin lane several minutes |

Toolchain: export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` before any `mix` command.

---

## Sampling Rate

- **After every task commit:** `mix mailglass_admin.assets.build --check` (about 1 s) plus the touched contract file
- **After every plan wave:** `cd mailglass_admin && mix verify.support_contract.admin`, then `mix format --check-formatted` inside `mailglass_admin`
- **Before `/gsd-verify-work`:** full suite green, advisory browser spec and reworked e2e files run locally, `bash scripts/gsd-regression-gate.sh`
- **Max feedback latency:** 60 seconds for per-task checks

Lane rule: only `support_contract_admin` (required, in `ci_green.needs`) counts as proof. `operator_browser_gate` and `demo_browser_evidence` are advisory and are never cited as the proof of a requirement.

---

## Per-Task Verification Map

Task IDs are finalized by the planner; rows below are the requirement-level contract each plan must cover.

| Requirement | Behavior | Test Type | Automated Command | Lane | File Exists |
|-------------|----------|-----------|-------------------|------|-------------|
| BRPIPE-01 | Fresh build equals committed bundle | integration | `mix mailglass_admin.assets.build --check` (exit 0) + positive case in `bundle_reproducibility_contract_test.exs` | REQUIRED | ❌ W0 |
| BRPIPE-01 | Flipped byte, truncation, missing file each fail and name `mix mailglass_admin.assets.build` | unit (hermetic tmp) | `mix test test/mailglass_admin/bundle_reproducibility_contract_test.exs --seed 0` | REQUIRED | ❌ W0 |
| BRPIPE-01 | Source-side drift (appended rule, planted utility token in tmp `lib/`, removed `prose` directive) | unit (tmp tree) | same file | REQUIRED | ❌ W0 |
| BRPIPE-01 | Wiring: `ci.yml` runs `verify.support_contract.admin`, alias has no file list and contains `--check`, `ci_green.needs` has the job | static | same file | REQUIRED | ❌ W0 |
| BRPIPE-01 | Fails closed when the Tailwind binary cannot be installed | unit (injected installer raises) | same file | REQUIRED | ❌ W0 |
| BRPIPE-01 | Real `ubuntu-latest` byte equality | CI | first PR run of `support_contract_admin` | REQUIRED | n/a |
| BRPIPE-02 | No `data-theme=` literal under `lib/**/*.{ex,heex}` except `layouts/root.html.heex`; no `--mg-`/`--color-` redeclaration | static grep | `mix test test/mailglass_admin/root_theme_ownership_contract_test.exs` | REQUIRED | ❌ W0 |
| BRPIPE-02 | Document-level `data-theme` count: explicit = 1, system = 0 (preview show, operator, inbound, gallery), red on current code first | integration | same file | REQUIRED | ❌ W0 |
| BRPIPE-02 | `AdminShell.shell/1` renders no `data-theme` | unit | `mix test test/mailglass_admin/admin_shell_test.exs` | REQUIRED | ✅ rework |
| BRPIPE-02 | Preview frame toggle keeps state marker, no `data-theme` on panes | integration | `mix test test/mailglass_admin/preview_live_test.exs` | REQUIRED | ✅ rework |
| BRPIPE-02 | Computed `--color-base-100` and `color-scheme` equal `<html>`'s across the cookie × OS matrix | browser | `npx playwright test ... e2e/theme-ownership.spec.js` | ADVISORY | ❌ W0 |
| BRPIPE-03 | Manifest shape, per-file sha256, no unlisted file, 40-hex `git_sha`, `dirty == false`, ≤ 80 images / 15 MB, `nested_theme_attr_count == 0` | unit | `mix test test/mailglass_admin/before_catalog_manifest_test.exs` | REQUIRED (catalog and test land in the same PR) | ❌ W0 |
| BRPIPE-03 | Capture determinism self-test, clean-tree refusal, served-bytes equality | script self-checks | the committed capture script | run is not CI; manifest test is the required proof | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Mutation Checks (each shown red, then restored)

- Delete `@source not inline("prose");` → `--check` red (`{:drift, 139137, 136877, 74051}`)
- Flip one byte / truncate / delete the committed bundle copy (hermetic) → red naming the fix command
- Plant `tracking-widest` in a tmp `lib/` copy → red
- Remove the `--check` step from the alias, or the job from `ci_green.needs` (tmp text copy) → wiring assertion red
- Plant `data-theme="mailglass-light"` in a tmp template, and `style="--color-base-100: #fff"` / `[--mg-color-background:#fff]` → ownership grep red
- Re-introduce `theme_attr` into `AdminShell` (scratch) → document-count test red
- Manifest: flip a PNG byte, add an unlisted PNG, set `dirty: true`, exceed byte cap → red

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs` — BRPIPE-01
- [ ] `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` — BRPIPE-02 (red first)
- [ ] `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs` — BRPIPE-03
- [ ] `mailglass_admin/e2e/theme-ownership.spec.js` — BRPIPE-02 browser (advisory)
- [ ] `mailglass_admin/dev/mailglass_admin/assets_check.ex` (or inline in the task) — BRPIPE-01
- [ ] `reference/demo_app/lib/mailglass_demo/catalog_seed.ex` and the capture spec/config outside the demo `./e2e` dir — BRPIPE-03

No framework install needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification (zero-UAT policy, D-52). Evidence that only a real CI run can supply (ubuntu-latest byte equality, optional drifted-bundle draft PR) is collected from the lane itself, not by owner review.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
