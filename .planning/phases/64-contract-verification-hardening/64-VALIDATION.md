---
phase: 64
slug: contract-verification-hardening
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
validated: 2026-05-31
---

# Phase 64 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix |
| **Config file** | `mailglass_inbound/test/test_helper.exs` and root `test/test_helper.exs` |
| **Quick run command** | `cd mailglass_inbound && mix verify.support_contract.inbound` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused command named by the task plan; for cross-contract changes run `cd mailglass_inbound && mix verify.support_contract.inbound`.
- **After every plan wave:** Run `mix verify.stability_contract`.
- **Before `$gsd-verify-work`:** `mix verify.stability_contract` must be green.
- **Max feedback latency:** 60 seconds for focused checks, 180 seconds for aggregate stability verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | PROOF-01 | T-64-01 | Package identity, value-object, and PubSub runtime seams carry package-line `since` metadata | unit | `cd mailglass_inbound && mix compile --warnings-as-errors` | Existing tests plus compiled-doc proof | green |
| 64-01-02 | 01 | 1 | PROOF-01 | T-64-02 | Runtime ingress, router, and mailbox direct entrypoints carry exact compiled-doc metadata without promoting helpers | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/caching_body_reader_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | Existing focused tests plus compiled-doc proof | green |
| 64-02-01 | 02 | 1 | PROOF-01 | T-64-03 | Stable structured-error modules carry `0.2.0` module metadata and keep closed-set API narrow | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/mime_error_test.exs test/mailglass_inbound/signature_error_test.exs test/mailglass_inbound/s3_fetch_error_test.exs --warnings-as-errors` | Existing focused tests plus compiled-doc proof | green |
| 64-02-02 | 02 | 1 | PROOF-01 | T-64-04 | Operator Mix task stability remains module-level and does not promote `run/*` | unit | `cd mailglass_inbound && mix compile --warnings-as-errors` | Existing compile lane plus compiled-doc proof | green |
| 64-03-01 | 03 | 1 | PROOF-01 | T-64-05 | Fixture builders and ingress testing drivers carry testing-bucket `0.2.0` metadata only | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/fixtures_test.exs test/mailglass_inbound/test/ingress_test.exs --warnings-as-errors` | Existing focused tests plus compiled-doc proof | green |
| 64-03-02 | 03 | 1 | PROOF-01 | T-64-06 | Assertion macros and mailbox case template carry testing-bucket metadata while internals remain unpromoted | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs test/mailglass_inbound/mailbox_case_test.exs --warnings-as-errors` | Existing focused tests plus compiled-doc proof | green |
| 64-04-01 | 04 | 1 | PROOF-02 | T-64-07 | Stable structured-error closed `:type` docs exactly match `__types__/0` in order | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/mime_error_test.exs test/mailglass_inbound/signature_error_test.exs test/mailglass_inbound/s3_fetch_error_test.exs --warnings-as-errors` | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | green |
| 64-04-02 | 04 | 1 | PROOF-03 | T-64-08, T-64-09 | Adoption/stability docs reject stale pins, stale release-line prose, and stable-surface over-claims while permitting deferred language | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | green |
| 64-05-01 | 05 | 2 | PROOF-01 | T-64-10 | Inbound package owns authoritative compiled-doc stability proof for stable runtime, error, task, and testing surfaces | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` | `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` | green |
| 64-05-02 | 05 | 2 | PROOF-01 | T-64-11, T-64-12 | Root stability lane delegates to package-owned inbound support-contract alias and docs-only lane meaning remains separate | integration | `mix verify.stability_contract` | `test/mailglass/stability_contract_test.exs` plus alias wiring | green |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

- [x] `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` - compiled-doc metadata proof for inbound stable and adopter-facing testing surfaces.
- [x] `mailglass_inbound/docs/api_stability.md` - explicit `Closed :type set` bullets for `MailglassInbound.MIMEError`.
- [x] `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - docs-contract assertions for closed type sets, over-claims, and stale release/install claims.
- [x] `mailglass_inbound/mix.exs` - `verify.support_contract.inbound` and preferred env wiring.
- [x] `mix.exs` and `test/mailglass/stability_contract_test.exs` - root aggregate wiring delegates to the inbound package lane.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-31

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Task rows audited | 10 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Evidence 2026-05-31

- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` passed: 24 tests, 0 failures.
- `mix verify.stability_contract` passed: core stability tests, admin support-contract tests, inbound support-contract tests, and docs check all green.
