---
phase: 151
slug: unified-dispatch-honest-outcomes-and-payload-lifecycle
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-03
---

# Phase 151 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Prepared message → provider adapter | Sync and durable work share one callback-compatible provider-input seam. | Recipient, content, headers, attachments, provider options |
| Adapter result → worker policy | Structured evidence selects retryable, terminal, or uncertain behavior. | Provider status/correlation and bounded reason classes |
| Worker → private payload lifecycle | Claims and settlements must be tenant-scoped, race-safe, and atomic with public facts. | Private envelope and lifecycle state |
| Success/outcome → Delivery/Event/Payload | Projection, ledger, and private scrub/retention facts settle together. | Non-sensitive audit facts and private tombstone |
| Retention operator → payload rows | Manual/optional maintenance must be tenant- and prefix-safe, bounded, and output-redacted. | Tenant identifier and aggregate counts |
| Missing Payload → terminal settlement | Historical or broken queued rows must never rebuild provider input from public metadata. | Public provenance only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-151-01 | Tampering | Shared dispatch seam | high | mitigate | Actual queued-job wire-equivalence oracle | closed |
| T-151-02 | Information Disclosure | Provider input/public surfaces | high | mitigate | Private/public sentinel separation regression | closed |
| T-151-03 | Tampering / Repudiation | Outcome classifier | high | mitigate | Closed structural classifier and no-text-match contract | closed |
| T-151-04 | Information Disclosure | Outcome projection | high | mitigate | Allowlisted bounded projection only | closed |
| T-151-05 | Elevation of Privilege / Tampering | V07 DDL | high | mitigate | Prefix-qualified DDL and hostile-search-path proof | closed |
| T-151-06 | Information Disclosure | Lifecycle constraints | high | mitigate | Closed state/reason/content matrix and catalog tests | closed |
| T-151-06B | DoS / Tampering | V07 downgrade | high | mitigate | Prefix-qualified pre-DDL refusal for lossy downgrade | closed |
| T-151-07 | Tampering | Payload claim/settlement | high | mitigate | Tenant-scoped CAS claim and atomic outcome Multi | closed |
| T-151-08 | Repudiation | Uncertain acceptance | high | mitigate | Unknown evidence defaults uncertain; worker cancels | closed |
| T-151-09 | Information Disclosure | Persisted outcome | high | mitigate | Safe projection excludes raw provider/private text | closed |
| T-151-10 | Elevation of Privilege | Tenant persistence | high | mitigate | Tenant predicates, scoped queries, prefix-aware Multi options | closed |
| T-151-11 | DoS | Prune batching | high | mitigate | Positive finite batch and deterministic limit | closed |
| T-151-12 | Elevation of Privilege | Payload pruning | high | mitigate | Explicit tenant required and prefix-scoped updates | closed |
| T-151-13 | Tampering | Recovery eligibility | medium | mitigate | Closed eligibility; no uncertain blind resend | closed |
| T-151-14 | Spoofing / Tampering | Prune entrypoints | medium | mitigate | Exact tenant-only worker args and required CLI tenant | closed |
| T-151-15 | Information Disclosure | Maintenance output | high | mitigate | Aggregate-only output and sentinel exclusion proof | closed |
| T-151-16 | Repudiation | Provider-boundary docs | high | mitigate | Executable at-least-once/no-exactly-once contract | closed |
| T-151-17 | Information Disclosure | Lifecycle guidance | high | mitigate | Executable public/private content exclusions | closed |
| T-151-18 | DoS | Retention operations | medium | mitigate | Finite defaults and one-batch documented contract | closed |
| T-151-19 | Information Disclosure | Missing Payload | high | mitigate | Payload-first terminalization; no metadata reconstruction | closed |
| T-151-20 | Tampering | Missing-Payload settlement | high | mitigate | Atomic/repeat-safe settlement and rollback-to-retry proof | closed |
| T-151-21 | Repudiation | Terminal reason | medium | mitigate | Distinct bounded Delivery/Event reason projection | closed |
| T-151-22 | DoS | Repeated missing jobs | medium | mitigate | First/repeat terminal cancellation with one event | closed |
| T-151-23 | Spoofing | Hostile legacy metadata | medium | mitigate | No-Payload handling occurs before route/adapter resolution | closed |
| T-151-SC | Tampering | Package supply chain | high | mitigate | No dependency or lockfile mutation | closed |

*Only open threats at or above the configured `high` threshold count toward `threats_open`.*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-03 | 24 | 24 | 0 | gsd-security-auditor (ASVS L1) |

Seven repeated `T-151-SC` declaration rows were deduplicated to one unique threat ID; all 31 declared rows were reviewed.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-03
