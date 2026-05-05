---
phase: 23
slug: production-admin-mount-and-step-up-auth
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for production operator mount, auth seam, and preview/operator regression coverage.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests |
| **Config file** | `mailglass_admin/test/test_helper.exs` plus support harnesses under `mailglass_admin/test/support/` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/preview_live_test.exs test/mailglass_admin/auth_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~20s quick / ~35s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-scoped command for the files just changed
- **After every plan wave:** rerun the quick phase command
- **Before `$gsd-verify-work`:** rerun the full phase command including `auth_test.exs`
- **Max feedback latency:** 35 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | ADMIN-01, ADMIN-05 | T-23-01, T-23-02, T-23-03 | preview and operator routes no longer share one `live_session`; session whitelists stay explicit | compile + route integration | `cd mailglass_admin && mix compile --warnings-as-errors && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 23-01-02 | 01 | 1 | ADMIN-01 | T-23-01, T-23-04 | route/session tests pin preview non-regression and operator session isolation | integration | `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 23-02-01 | 02 | 2 | ADMIN-05 | T-23-05, T-23-06, T-23-07 | auth seam exposes explicit `:unauthorized` / `:stale_auth` outcomes and normalized actor metadata | unit | `cd mailglass_admin && mix test test/mailglass_admin/auth_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 23-02-02 | 02 | 2 | ADMIN-01, ADMIN-05 | T-23-05, T-23-08 | operator mount/live tests prove authorized and unauthorized behavior with the new harness while the Phase 22 UI remains read-only | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 23-03-01 | 03 | 3 | ADMIN-01 | T-23-09 | README accurately documents preview vs production operator mount and adopter-owned auth | doc + regression | `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 23-03-02 | 03 | 3 | ADMIN-01, ADMIN-05 | T-23-10, T-23-11 | final regression lane proves preview survives, operator auth works, and auth seam stays callable | integration | `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/preview_live_test.exs test/mailglass_admin/auth_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mailglass_admin/test/mailglass_admin/auth_test.exs` — focused auth-seam contract tests for `:unauthorized`, `:stale_auth`, and normalized actor metadata

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification.

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-23-01 | Adopter session data leaks into library LiveViews | Information Disclosure | separate preview/operator whitelist callbacks | V3 |
| T-23-02 | Production operator route inherits preview-only auth/session behavior | Elevation of Privilege | split `live_session` boundaries and operator-only mount hook | V2 / V4 |
| T-23-03 | Router opts admit opaque auth/session passthrough | Tampering | narrow `NimbleOptions` validation | V5 |
| T-23-04 | Preview route breaks while operator auth is added | Regression | keep `preview_live_test.exs` in the regression lane | V1 |
| T-23-05 | Unauthorized actor reaches operator LiveView | Spoofing / Elevation of Privilege | operator mount auth seam with explicit deny path | V2 / V4 |
| T-23-06 | Future replay/remove actions skip recent-auth enforcement | Tampering | dedicated auth seam + `auth_test.exs` before mutations ship | V4 |
| T-23-07 | Library couples to one adopter auth stack | Availability / Maintainability | stack-agnostic auth contract; no hard Sigra/phx.gen.auth dependency | V1 |
| T-23-08 | Phase 22 read-only behavior regresses under auth changes | Regression | operator LiveView regression tests remain in lane | V1 |
| T-23-09 | README misleads adopters about production mount/auth ownership | Repudiation | precise preview vs operator docs | V1 |
| T-23-10 | Test harness bypasses the real route/auth boundary | False Confidence | shared endpoint/liveview harness proves real mount path | V1 |
| T-23-11 | Phase passes compile but not behavioral regression | False Confidence | final regression lane includes router/operator/preview/auth tests | V1 |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers the only missing test file
- [x] No watch-mode flags
- [x] Feedback latency < 35s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified
