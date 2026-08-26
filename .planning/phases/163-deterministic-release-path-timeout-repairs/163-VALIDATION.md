---
phase: 163
slug: deterministic-release-path-timeout-repairs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 163 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData + PostgreSQL/Ecto Sandbox; Playwright |
| **Config file** | `test/test_helper.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `MIX_ENV=test mix test test/mailglass/properties/<affected_property>.exs --warnings-as-errors` or `cd mailglass_admin && npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1` |
| **Full suite command** | Unchanged deterministic core suite and `cd mailglass_admin && npm run test:operator-browser` |
| **Estimated runtime** | Focused property: several minutes; focused browser: bounded by the existing server/test lifecycle; full protected gates: up to their existing CI deadlines |

---

## Sampling Rate

- **After database diagnosis or repair commits:** Run the affected 1,000-run property unseeded with warnings as errors.
- **After browser diagnosis or repair commits:** Run the full `gallery-matrix.spec.js` with one worker and no added retry.
- **After every plan wave:** Repeat the affected focused proof at the plan's documented finite count and record command, toolchain, elapsed range, first-attempt result, and attributed boundary.
- **Before `$gsd-verify-work`:** The unchanged deterministic core and operator-browser gates must be green.
- **Max feedback latency:** The existing bounded focused-test and CI job limits; no new global deadline.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 163-01-01 | 01 | 1 | DTRM-01 | T-163-01 | Attribute SQLSTATE/query/session without weakening bounds or exposing PII | property diagnosis | `MIX_ENV=test mix test test/mailglass/properties/idempotency_convergence_test.exs test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 163-01-02 | 01 | 1 | DTRM-01, DTRM-02 | T-163-01 | Keep the repair fixture/session/query-local and preserve 1,000 runs | property regression + repetition | `make toolchain CMD='mix test test/mailglass/properties/<affected_property>.exs --warnings-as-errors'` | ✅ | ⬜ pending |
| 163-02-01 | 02 | 1 | DTRM-03 | T-163-02 | Distinguish readiness from matrix execution without reducing coverage | browser diagnosis | `cd mailglass_admin && npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1` | ✅ | ⬜ pending |
| 163-02-02 | 02 | 1 | DTRM-03, DTRM-04 | T-163-02 | Keep any timing change finite and local; preserve live discovery and all axes | browser regression + repetition | `cd mailglass_admin && npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1` | ✅ | ⬜ pending |
| 163-03-01 | 03 | 2 | DTRM-02, DTRM-04 | T-163-01, T-163-02 | Do not broaden protected CI topology, retries, or job deadlines | integration | Unchanged deterministic core suite and `cd mailglass_admin && npm run test:operator-browser` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Record the focused-proof evidence format in the executable plans: command, toolchain, repetition count, elapsed range, first-attempt result, and attributed source boundary.
- [ ] Add no framework or package; existing ExUnit, StreamData, PostgreSQL, Sandbox, Playwright, and readiness infrastructure cover all requirements.
- [ ] Add durable diagnostic instrumentation only if reproduction proves an attribution field is missing; otherwise remove temporary diagnostics after capturing the regression.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Full 1,000-run properties and the complete gallery matrix remain intact.
- [ ] Protected integration commands and job-level deadlines remain unchanged.
- [ ] `nyquist_compliant: true` set after execution evidence passes.

**Approval:** pending
