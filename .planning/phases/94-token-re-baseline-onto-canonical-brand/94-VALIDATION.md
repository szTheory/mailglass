---
phase: 94
slug: token-re-baseline-onto-canonical-brand
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-13
---

# Phase 94 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `94-RESEARCH.md` "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir/OTP — no external dep) + bash/grep shell gates |
| **Config file** | `mailglass_admin/test/test_helper.exs` (existing) |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/accessibility_test.exs test/mailglass_admin/brand_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` |
| **Estimated runtime** | ~30 seconds (tests) + bundle rebuild |

Gate scripts (run from repo root): `bash mailglass_admin/scripts/check-conformance.sh` (hard), `bash mailglass_admin/scripts/check-conformance-advisory.sh` (advisory, new), `bash scripts/check_motion_conformance.sh`.

---

## Sampling Rate

- **After every task commit (gate tasks):** `bash mailglass_admin/scripts/check-conformance.sh && bash scripts/check_motion_conformance.sh`
- **After every task commit (test/CSS tasks):** `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/brand_test.exs test/mailglass_admin/accessibility_test.exs`
- **After every plan wave:** `cd mailglass_admin && mix verify.preview` (includes bundle rebuild + `git diff --exit-code priv/static/`)
- **Before `/gsd:verify-work`:** `cd mailglass_admin && mix verify.support_contract.admin` must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Requirement | Wave | Proof mechanism | Automated Command | File Exists | Status |
|-------------|------|-----------------|-------------------|-------------|--------|
| RATCHET-03 (wire dead gate + hard arms) | 0 | `check-conformance.sh` runs in CI + 5 hard gates exit 0 | `bash mailglass_admin/scripts/check-conformance.sh` | ✅ (script); ❌ CI step | ⬜ pending |
| RATCHET-03 (advisory typography/tracking arms) | 0 | `check-conformance-advisory.sh` (`continue-on-error: true`) | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | ❌ W0 | ⬜ pending |
| RATCHET-03 (THRASH layout-transition arms) | 0 | `check_motion_conformance.sh` Pass A extended | `bash scripts/check_motion_conformance.sh` | ✅ (needs extension) | ⬜ pending |
| TOKEN-04 (parity oracle) | 0 | `token_parity_test.exs` value-equality + `File.exists!/1` startup assert | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs` | ❌ W0 | ⬜ pending |
| TOKEN-01 (no raw hex / `--mg-*` inlined) | 1 | `token_parity_test.exs` no-raw-hex scan + `--mg-*` presence assert | same | ❌ W0 | ⬜ pending |
| TOKEN-02 (light/dark slot remap) | 1 | `token_parity_test.exs` `@mapping` per-slot asserts; `brand_test.exs` var-wiring asserts | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/brand_test.exs` | ❌ W0 / ✅ (update) | ⬜ pending |
| TOKEN-03 (dark AA + border sub-3:1 pin) | 1 | `accessibility_test.exs` 5 new contrast tests (muted/error/primary-content ≥4.5:1; borders `< 3.0`) | `cd mailglass_admin && mix test test/mailglass_admin/accessibility_test.exs` | ✅ (extend) | ⬜ pending |
| TOKEN-05 (bundle rebuilt + committed) | 1 | `mix verify.preview` `git diff --exit-code priv/static/`; `bundle_test.exs` size < 150KB | `cd mailglass_admin && mix verify.preview` | ✅ (wired) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — new; covers TOKEN-01, TOKEN-02, TOKEN-04
- [ ] `mailglass_admin/scripts/check-conformance-advisory.sh` — new; covers RATCHET-03 advisory arms
- [ ] `mailglass_admin/test/mailglass_admin/accessibility_test.exs` — extend with 5 new contrast tests; covers TOKEN-03
- [ ] `mailglass_admin/test/mailglass_admin/brand_test.exs` — update 3 assertions (lines 44-52) hex → var+hex; covers TOKEN-01/02
- [ ] `mailglass_admin/scripts/check-conformance.sh` — extend TYPE-GATE regex; covers RATCHET-03
- [ ] `scripts/check_motion_conformance.sh` — extend THRASH_PATTERN; covers RATCHET-03
- [ ] `.github/workflows/ci.yml` — add 2 steps in `credo_strict` job (hard + advisory gates); covers RATCHET-03 CI wiring
- [ ] `mailglass_admin/mix.exs` — add `token_parity_test.exs` to `verify.support_contract.admin`; covers TOKEN-04 CI gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All Phase 94 behaviors (token parity, contrast math, gate exit codes, bundle drift) have automated proof | — |

*All phase behaviors have automated verification. No browser/visual UAT this phase — markup is unchanged (SC-4); visible refresh lands in Phases 97–103.*

---

## Validation Sign-Off

- [ ] All requirements have an `<automated>` verify or a Wave 0 dependency
- [ ] Sampling continuity: every task commits behind a gate or test command
- [ ] Wave 0 covers all MISSING references (8 files above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter (after plan-checker pass)

**Approval:** approved 2026-06-13 (plan-checker PASS after revision)
