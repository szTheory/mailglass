---
phase: 144
slug: signal-drift-integrity
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 144 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub workflows → branch-protection API | Privileged observation and owner-only mutation | PAT, protection JSON, status contexts |
| Local hygiene → GitHub API | Maintainer verification depends on local prerequisites and remote access | Token, CLI results, remediation status |
| Admin source → vendored icon inventory | Source-derived names must be completely enumerated | HEEx expressions and shipped icon keys |
| Release events → Hex workflows | Multiple release events coordinate privileged publication | Tags, workflow state, package versions |
| Release preflight → release creation | Recovery must establish current state before creating releases | Manifest tags, API status, PR labels |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-144-01 | Tampering | PAT/verifier workflow outcome | high | mitigate | Closed three-state result plus authoritative non-green reporter | closed |
| T-144-02 | Tampering | Required status-context identity | high | mitigate | Parsed display-name equality and historical-id negative control | closed |
| T-144-03 | Elevation of privilege | Scheduled mutation path | medium | mitigate | Read-only advisory and sole owner-controlled reassertion path | closed |
| T-144-04 | Tampering | Hygiene result classification | high | mitigate | Exact drift signature; every unavailable outcome is unknown/non-success | closed |
| T-144-05 | Repudiation | Hygiene JSON/text reporting | medium | mitigate | Distinct tested status and remediation in both emitters | closed |
| T-144-06 | Tampering | Dynamic icon extraction | medium | mitigate | Real-gate finite-form coverage and fail-closed unresolved expressions | closed |
| T-144-07 | Repudiation | Temporary icon fixture | low | mitigate | Cleanup registered before writes and asserted after execution | closed |
| T-144-08 | Denial of service | Linked release fan-out | high | mitigate | Shared static concurrency group with cancellation disabled | closed |
| T-144-09 | Tampering | Already-published package handling | high | mitigate | Three tested registry lookups, skip outputs, and successful no-op messages | closed |
| T-144-10 | Tampering | Tag/ref serialization input | medium | mitigate | Ref-independent group and executable old-pattern negative controls | closed |
| T-144-11 | Repudiation | Recovery visibility | medium | mitigate | Contracted trigger/state branches and bounded maintainer runbook | closed |
| T-144-12 | Denial of service | Partial linked-tag state | high | mitigate | Partial state fails; only confirmed 404 is treated as absent | closed |
| T-144-13 | Tampering | Repeated recovery triggers | high | mitigate | Checked-out manifest, fail-closed API queries, state no-ops, single action guard | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 13 | 13 | 0 | Codex / GSD ASVS L1 |

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require documentation.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set.

**Approval:** verified 2026-07-31
