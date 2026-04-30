---
phase: 20
slug: config-schema-installer-surface-for-ses-resend
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-30
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for config-schema, installer-snapshot, and release-gate execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs test/mailglass/publish/installer_golden_check_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~15s quick / ~45s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the plan-scoped ExUnit command for the files just changed
- **After every plan wave:** rerun the full Phase 20 command
- **Before `$gsd-verify-work`:** run `MIX_PUBLISH=true mix mailglass.publish.check --package mailglass`
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-01 | boot rejects unknown `:ses` / `:resend` keys and accepts only the locked runtime surface | unit | `mix test test/mailglass/config_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 20-01-02 | 01 | 1 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-02 | installer snippet keeps the default route surface narrow while opt-in guidance mentions `:mailgun`, `:ses`, and `:resend` | snapshot | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 20-01-03 | 01 | 1 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-03 | committed README snapshots match the generated installer output | snapshot | `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors && mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 20-02-01 | 02 | 2 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-03 | publish drift is represented by a typed Mailglass sibling error with a closed `:type` set | unit | `mix test test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs --warnings-as-errors` | ❌ Wave 0 | ⬜ pending |
| 20-02-02 | 02 | 2 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-03 | deterministic helper coverage proves golden drift returns `%Mailglass.PublishError{type: :publish_blocked_golden_drift}` with the exact refresh command | unit | `mix test test/mailglass/publish/installer_golden_check_test.exs --warnings-as-errors` | ❌ Wave 0 | ⬜ pending |
| 20-02-03 | 02 | 2 | SES-01, SES-03, SES-04, SES-05, RESEND-01, RESEND-02 | T-20-03 | `mix mailglass.publish.check` still exits 0 on the green path after the helper extraction | integration-lite | `MIX_PUBLISH=true mix mailglass.publish.check --package mailglass` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/errors/publish_error_test.exs` — focused tests for the new sibling error module
- [ ] `test/mailglass/publish/installer_golden_check_test.exs` — deterministic drift-path tests for the extracted helper seam

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-20-01 | Mistyped SES/Resend config silently survives boot | Tampering | closed NimbleOptions subtrees in `Mailglass.Config` | V5 |
| T-20-02 | Installer copy-paste broadens public webhook endpoints beyond default posture | Elevation of Privilege | default route snippet stays zero-arg; optional providers move to adjacent guidance | V4 |
| T-20-03 | Maintainer ships stale installer output | Repudiation | installer golden test remains a pre-publish gate and gains typed internal failure semantics | V1 |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers the only missing test file
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
