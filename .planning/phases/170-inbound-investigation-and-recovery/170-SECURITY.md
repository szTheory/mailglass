---
phase: "170"
slug: inbound-investigation-and-recovery
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 170 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| URL and LiveView events -> exact inbound reads | Account, page, filter, and record identifiers are untrusted selectors; reads remain tenant-scoped and foreign/missing IDs are indistinguishable. | Account IDs, record IDs, filters, persisted inbound metadata |
| Provider evidence and route matcher -> ordinary HTML | Persisted evidence, raw payload, and matcher values can contain PII, secrets, or markup; ordinary rendering uses safe fields and masked values. | Provider facts, raw payload, headers, matcher values |
| Stored run history and outcome filter -> operator read model | Persisted executions are selected by tenant, source, and time; the filter agrees with the latest-fresh outcome displayed in the row. | Run IDs, source, outcome, mailbox, timestamps, filter values |
| Stored route binding -> replay eligibility | Only a durable safe binding may select the Mailbox implementation for a tenant-scoped replay. | Account ID, record ID, binding, Mailbox identity |
| Browser confirmation -> host authorization and replay | A reviewed target is re-read and authorized immediately before a side effect; stale, denied, and duplicate submissions do not append extra runs. | Reviewed Account/record, eligibility, authorization result, replay request |
| Command result and history refresh -> status UI | Command feedback and selected history snapshots remain separate facts; unavailable history is not rendered as success or empty history. | Replay result, timestamped run history, read status |
| Source assets -> served UI evidence | Rendered evidence must identify the source and served asset revisions so stale assets cannot masquerade as current behavior. | Source revision, CSS hashes, served route, screenshots |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-170-01 | Information Disclosure | Exact record selection | high | mitigate | Tenant predicate and `Tenancy.scope/2` on exact reads; foreign and missing IDs share a non-disclosing result. `internal/operator/detail.ex:75–119`; `inbound_live.ex:1638–1655`. | closed |
| T-170-02 | Tampering | URL selection and filters | medium | mitigate | Server-side parameter normalization and exact selected-ID preservation. `inbound_live.ex:938–955,1731–1745,1904–1912`. | closed |
| T-170-03 | Repudiation | Read-state explanation | medium | mitigate | Absent package, operational failure, and successful-empty states remain distinct. `inbound/read_result.ex:13–20`; `inbound/records_list.ex:70–136`. | closed |
| T-170-04 | Tampering | Mailbox outcome normalization | high | mitigate | Only the allowlisted callback result is persisted with outcome shape validation. `mailbox.ex:35–40`; `inbound_records.ex:69–105`; `execution_run.ex:16–17,84–104`. | closed |
| T-170-05 | Elevation of Privilege | Replay binding resolution | high | mitigate | Resolve only a tenant-scoped durable binding; reject legacy module-text reconstruction. `internal/replay.ex:54–64,270–287,324–354`; `execution.ex:346–425`. | closed |
| T-170-06 | Repudiation | ExecutionRun lineage | medium | mitigate | Persist source and exact callback outcome in append-only execution lineage. `execution.ex:52–71,299–315`; `replay_test.exs:459–479`. | closed |
| T-170-07 | Information Disclosure | Evidence facts and raw payload | high | mitigate | Exact safe-field allowlist; raw source is reveal-gated and ordinary HTML remains redacted. `inbound/evidence_card.ex:88–119,176–190`; `inbound_live.ex:1675–1687`. | closed |
| T-170-08 | Information Disclosure | RoutingTrace matcher values | high | mitigate | Mask or withhold subject, recipient, header, and expected matcher literals. `inbound/routing_trace.ex:151–180,199–231`. | closed |
| T-170-09 | Spoofing | Current route explanation | medium | mitigate | Current rules are labeled as simulation and separated from historical execution. `inbound/routing_trace.ex:30–36`. | closed |
| T-170-10 | Information Disclosure | Detail and timeline reads | high | mitigate | Exact tenant predicate and `Tenancy.scope/2` cover detail and history reads. `internal/operator/detail.ex:75–119`; `internal/operator/timeline.ex:27–49`. | closed |
| T-170-11 | Repudiation | Latest-fresh summary and lineage | medium | mitigate | Latest-fresh selection is deterministic and timeline retains source, ID, and timestamp. `internal/operator/records.ex:161–170`; `internal/operator/detail.ex:108–119`; `internal/operator/timeline.ex:29–46`. | closed |
| T-170-12 | Tampering | Outcome filter and presentation | medium | mitigate | Filter and row projection use the same tenant-scoped latest-fresh subquery; regression covers older fresh and replay outcomes. `internal/operator/records.ex:161–170,288–312`; `records_test.exs:444–472`. | closed |
| T-170-13 | Elevation of Privilege | Replay authorization ordering | high | mitigate | Revalidate the exact reviewed target before host authorization and tenant-scoped replay. `inbound_live.ex:1037–1047,1164–1233,1283–1285`; `internal/replay.ex:54–64`. | closed |
| T-170-14 | Tampering | Durable route binding | high | mitigate | Current safe binding is resolved at action time; stale or unsafe legacy bindings are rejected. `internal/replay.ex:290–354`; `execution.ex:346–425`; `inbound_live.ex:1204–1219`. | closed |
| T-170-15 | Information Disclosure | Eligibility reasons | medium | mitigate | Foreign/missing IDs are equivalent and typed reasons omit raw evidence and exception data. `internal/replay.ex:25–37,316–322`; `inbound_live.ex:1241–1277`; `inbound/replay_modal.ex:129–157`. | closed |
| T-170-16 | Denial of Service | Duplicate replay submission | medium | mitigate | A review token is consumed once and repeated confirmation cannot start another replay. `inbound_live.ex:469–500`; `inbound_live_test.exs:1249–1258`. | closed |
| T-170-17 | Repudiation | Replay command feedback | high | mitigate | Persisted run result, pre-run failure, and no-change outcome have distinct feedback. `inbound_live.ex:1037–1090,1101–1126`; `execution.ex:64–71`. | closed |
| T-170-18 | Information Disclosure | Timeline refresh | medium | mitigate | Scoped reads preserve the last successful snapshot and sanitize unavailable-state feedback. `inbound_live.ex:1138–1150,1574–1598,655–695`; `inbound/read_result.ex:13–20`. | closed |
| T-170-19 | Information Disclosure | Connected investigation | high | mitigate | Browser asserts foreign-ID nondisclosure and ordinary evidence redaction. `phase170-journey.spec.js:89–165,229–239`. | closed |
| T-170-20 | Elevation of Privilege | Connected replay | high | mitigate | Connected stale, denied, and rapid-repeat confirmation cases assert no run or at most one run and expected authorization calls. `phase170-journey.spec.js:169–226`; `test/support/endpoint_case.ex:201–215,414–426`. | closed |
| T-170-21 | Repudiation | Rendered acceptance record | low | mitigate | Source and served asset hashes are recorded; automated and rendered evidence are distinguished. `phase170-journey.spec.js:303–338`; `170-RENDERED.md`. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the configured threshold count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 21 | 21 | 0 | GSD security auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09
