---
phase: 139
slug: admin-asset-first-load-deep-link-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-07
---

# Phase 139 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix; Playwright Test 1.59.1 for browser proof |
| **Config file** | `mailglass_admin/mix.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs --warnings-as-errors` |
| **Browser focused command** | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` |
| **Estimated runtime** | ~30-90 seconds for focused commands; full browser gate depends on local browser startup |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit asset URL test once it exists.
- **After browser-proof task commits:** Run the focused Playwright `admin asset` grep.
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview` plus the focused Playwright proof.
- **Before `/gsd:verify-work`:** Run `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`.
- **Max feedback latency:** 120 seconds for focused gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 139-W0-01 | TBD | 0 | AAU-01 | T-139-03 | Stylesheet hrefs are root-relative under the effective admin mount path, not external or nested relative URLs | ExUnit ConnTest | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs --warnings-as-errors` | No, Wave 0 | pending |
| 139-W0-02 | TBD | 0 | AAU-03 | T-139-01 | Alternate test-only preview/operator mounts preserve existing auth/session behavior and do not expose public router macro options | ExUnit ConnTest | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs --warnings-as-errors` | No, Wave 0 | pending |
| 139-W0-03 | TBD | 0 | AAU-02 | T-139-02 | Direct hard loads request CSS/fonts from mount-root URLs with 200 responses and expected content types | Playwright e2e | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` | No, Wave 0 | pending |
| 139-W0-04 | TBD | 0 | AAU-04 | T-139-04 | Browser proof fails on CSS/font 404s and verifies token-backed computed styling after direct `page.goto` | Playwright e2e | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset"` | No, Wave 0 | pending |
| 139-GATE-03 | TBD | Final | GATE-03 | T-139-04 | Both fast href assertions and serialized browser asset/style proof are present and passing | Mixed | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` | Partial | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` - focused first-HTML route matrix for AAU-01 and AAU-03.
- [ ] `mailglass_admin/test/support/endpoint_case.ex` - alternate test-only preview/operator mounts with unique `live_session_name` values.
- [ ] `mailglass_admin/e2e/admin-assets.spec.js` - focused direct-load network and computed-style proof for AAU-02 and AAU-04.

---

## Manual-Only Verifications

All phase behaviors have automated verification. No manual-only checks are required.

---

## Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-139-01 | Alternate operator mount accidentally bypasses authentication or session controls | Use existing `mailglass_operator_routes/2` auth/session path in test-only mounts; do not add public router options |
| T-139-02 | Font asset path traversal or unexpected asset names | Keep existing font allowlist in `MailglassAdmin.Controllers.Assets`; browser proof observes expected `.woff2` requests only |
| T-139-03 | External or nested relative stylesheet URL masks an asset-root regression | Assert stylesheet hrefs are root-relative under expected mount roots and reject bare `css-...` / nested path hrefs |
| T-139-04 | Structurally rendered but unstyled admin page passes tests | Fail browser gate on CSS/font non-200, bad content type, or missing token-backed computed styles |

---

## Validation Sign-Off

- [x] All phase requirements have automated verification coverage.
- [x] Sampling continuity has no three-task gap without automated verification.
- [x] Wave 0 covers all missing test-file references.
- [x] No watch-mode flags are used.
- [x] Feedback latency target is under 120 seconds for focused gates.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-07
