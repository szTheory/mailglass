---
phase: 150
slug: private-envelope-and-atomic-durable-enqueue
status: verified
# Only OPEN threats at or above workflow.security_block_on (high) count here.
threats_open: 0
asvs_level: 1
created: 2026-08-03
---

# Phase 150 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Prepared message → private envelope | Supported mail content and provider options become bounded, versioned JSON. | Private message content and routing |
| Public durable facts → private payload | Delivery, Event, and ID-only Oban arguments must not expose envelope content. | Public identifiers versus private content |
| Tenant worker context → payload lookup | Persisted identifiers request recovery of private queued content. | Tenant and delivery identifiers |
| Attachment source → persisted bytes | Mutable paths/uploads become immutable retry-stable data. | Attachment bytes and metadata |
| Ecto.Multi → Mailglass/Oban tables | Delivery, event, payload, and job must commit or roll back together. | Durable database writes |
| Migration prefix → PostgreSQL objects | Host search paths and decoy objects must not redirect private-table DDL. | Schema-qualified DDL |
| Host configuration → durable-success claim | Optional Oban presence and canonical queue readiness decide whether enqueue is usable. | Runtime/deployment configuration |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-150-01 | Information Disclosure | Payload/public surfaces | high | mitigate | Tenant-scoped private fetch plus recursive public-surface sentinel regression | closed |
| T-150-02 | Tampering / DoS | Envelope loader | high | mitigate | Version/schema/bounds checks, digest verification, and no persisted-to-atom conversion | closed |
| T-150-03 | Tampering / Information Disclosure | Attachments | high | mitigate | One-time byte materialization, data-only persistence, and TOCTOU regression | closed |
| T-150-04 | Elevation of Privilege | Payload lookup | high | mitigate | Tenant and delivery ID are both required by the scoped query | closed |
| T-150-05 | Tampering | V06 prefix resolution | high | mitigate | Prefix threaded through all DDL with hostile-search-path lifecycle proof | closed |
| T-150-06 | Information Disclosure | Delivery/Event/job projection | high | mitigate | Allowlisted public metadata and private-sentinel absence assertions | closed |
| T-150-07 | Repudiation / DoS | Atomic enqueue | high | mitigate | One ordered Multi and forced payload/job rollback tests | closed |
| T-150-08 | Tampering | Batch association | medium | mitigate | Stable per-item tenant/delivery identity and ordered mixed-result tests | closed |
| T-150-09 | Information Disclosure / Elevation of Privilege | Worker payload recovery | high | mitigate | Tenant restoration plus tenant-scoped payload-first lookup | closed |
| T-150-10 | Tampering | Persisted version/keys | high | mitigate | String-key allowlist, explicit versions, and no dynamic atom creation | closed |
| T-150-11 | Repudiation / DoS | Oban readiness/enqueue | high | mitigate | Typed readiness matrix, fail-closed gateway, transactional insert | closed |
| T-150-12 | Information Disclosure | Readiness errors | medium | mitigate | Bounded reason classes without content or configuration secrets | closed |
| T-150-13 | Repudiation / DoS | Production readiness | high | mitigate | Explicit readiness gate with bounded ConfigError outcomes | closed |
| T-150-14 | Repudiation | Application boot | high | mitigate | Ordinary boot remains separate from production-only readiness | closed |
| T-150-15 | Denial of Service | Canonical queue | high | mitigate | Worker queue is the source of truth and drift is rejected | closed |
| T-150-16 | Repudiation / DoS | Fallback claims | high | mitigate | Active outbound claims are manifest-scoped and contract-tested | closed |
| T-150-17 | Tampering | Queue documentation | high | mitigate | Documentation tokens are compared with `Worker.queue/0` | closed |
| T-150-18 | Information Disclosure | Payload guidance | medium | mitigate | No public archive, view, admin, or root Payload API is promised | closed |
| T-150-19 | Repudiation | Historical/inbound classification | low | accept | Preserve provenance and separately shipped inbound behavior; exclusions remain explicit | closed |
| T-150-20 | Tampering / DoS | JSON codec | high | mitigate | Depth/item/byte/finite-number bounds and hostile boundary tests | closed |
| T-150-21 | Information Disclosure | Serialization errors | high | mitigate | Stable reason classes only; fixtures are excluded from error context | closed |
| T-150-22 | Tampering | Attachment materialization | high | mitigate | Exact materialization and mutate/delete-after-dump proof | closed |
| T-150-23 | Elevation of Privilege | Persisted adapter route | high | mitigate | Required route plus projection mismatch rejection before resolution | closed |
| T-150-24 | Tampering | V06 catalog objects | high | mitigate | Schema-qualified DDL and decoy/search-path catalog assertions | closed |
| T-150-25 | Information Disclosure / Tampering | Legacy migration | high | mitigate | No backfill and exact legacy metadata retention proof | closed |
| T-150-26 | Denial of Service | V06 rollback/re-up | medium | mitigate | V05 survival and identical V06 re-up signature assertions | closed |
| T-150-27 | Tampering | Worker reconstruction | high | mitigate | Actual queued job dispatches original content after live-state mutation | closed |
| T-150-28 | Elevation of Privilege | Retry route | high | mitigate | Persisted route is authoritative; mismatch reaches no adapter | closed |
| T-150-29 | Repudiation | Oban job proof | medium | mitigate | Actual inserted job is fetched and exact ID-only arguments asserted | closed |
| T-150-30 | Repudiation | No-optional harness | high | mitigate | Isolated direct Elixir runtime, allowlisted paths, and optional-root denylist | closed |
| T-150-31 | Denial of Service | Public send without Oban | high | mitigate | Exact typed dependency-unavailable result; raises fail the proof | closed |
| T-150-32 | Tampering / Repudiation | Zero-effects claim | high | mitigate | Before/after durable, Oban, adapter, and Task observations | closed |
| T-150-SC | Tampering | Package supply chain | high | mitigate | No package installation or lockfile change in the phase | closed |

*Severity: critical > high > medium > low. Only open threats at or above `high` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-150-01 | T-150-19 | Historical and inbound material remains intentionally outside the active outbound contract. Keeping immutable provenance and explicit path/section exclusions is safer than deleting or rewriting separately shipped behavior. Severity is low and the disposition was locked at plan time. | Project plan / automated security gate | 2026-08-03 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-03 | 33 | 33 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-03
