---
phase: 25
slug: deliverability-doctor
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/mail_doctor_task_test.exs test/mailglass/deliverability --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/mail_doctor_task_test.exs test/mailglass/deliverability --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | DOCTOR-01 | T-25-01 | CLI accepts exactly one `--domain` target and emits grouped SPF/DKIM/DMARC/MX/BIMI findings without requiring repo runtime state. | integration | `mix test test/mix/tasks/mail_doctor_task_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 25-02-01 | 02 | 1 | DOCTOR-02 | T-25-02 | Analyzer outputs use only `pass`, `warn`, `fail`, or `cannot_verify`, and transient DNS uncertainty never collapses into a false hard-fail. | unit + property | `mix test test/mailglass/deliverability test/mailglass/properties/deliverability_status_property_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 25-03-01 | 03 | 2 | DOCTOR-03 | T-25-03 | Human and JSON formatters preserve honest remediation language and versioned result keys without overstating certainty. | unit | `mix test test/mailglass/deliverability/formatter_test.exs test/mix/tasks/mail_doctor_task_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/mail_doctor_task_test.exs` — strict CLI parsing, unknown-flag rejection, positional-arg rejection, grouped human output, JSON output
- [ ] `test/mailglass/deliverability/spf_test.exs` — record presence, duplicate SPF, recursion counting, terminal policy classification
- [ ] `test/mailglass/deliverability/dkim_test.exs` — selector-required `cannot_verify`, TXT/CNAME handling, revoked key, key-length advisory
- [ ] `test/mailglass/deliverability/dmarc_test.exs` — `_dmarc` discovery, duplicate-record handling, `p`/`sp`/`pct`/`rua`/alignment classification
- [ ] `test/mailglass/deliverability/mx_test.exs` — MX present, Null MX, absent MX ambiguity wording
- [ ] `test/mailglass/deliverability/bimi_test.exs` — `default._bimi` lookup, readiness-only wording, DMARC prerequisite warnings
- [ ] `test/mailglass/deliverability/formatter_test.exs` — human output contract and JSON schema version
- [ ] `test/mailglass/properties/deliverability_spf_property_test.exs` — SPF recursion, lookup-limit, and void-lookup properties
- [ ] `test/mailglass/properties/deliverability_status_property_test.exs` — status-domain invariants and uncertainty classification
- [ ] `test/support/deliverability_resolver_stub.ex` — deterministic resolver fixtures independent of live DNS

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-world DNS output sanity check against a known domain set | DOCTOR-01, DOCTOR-03 | Live DNS answers are environment-dependent and should not gate CI deterministically | Run `mix mail.doctor --domain example.com --verbose` and a second domain with known DMARC/BIMI posture; confirm human output stays bounded, grouped, and honest about uncertainty |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
