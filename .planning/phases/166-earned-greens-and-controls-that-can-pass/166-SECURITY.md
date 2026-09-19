---
phase: "166"
slug: "earned-greens-and-controls-that-can-pass"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-19"
---

# Phase 166 — Security

> Phase 166 threat-register audit, reconciled against the implementation, focused regression suite, and recorded post-merge evidence.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| CI workflow → GitHub API/cache | Read-only release and cache-control operations | Public repository metadata and dependency caches |
| CI workflow → Hex | Locked dependency resolution | Public package metadata and locked artifacts |
| Maintainer → advisory allowlist | Time-bounded security exception management | Public upstream advisory evidence |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-166-SC | Tampering | dependency resolution | high | mitigate | Locked dependencies and SHA-pinned actions | closed |
| T-166-01 | Elevation of Privilege | admin coverage CI | high | mitigate | Existing read-only workflow permissions; repo-local commands only | closed |
| T-166-02 | Tampering | coverage baseline | high | mitigate | Measured triple, hash, toolchain, and regression drill | closed |
| T-166-03 | Information Disclosure | coverage report | low | accept | Contains only source paths and hit counts | accepted |
| T-166-04 | Tampering | suite-floor env | high | mitigate | Occurrence, anti-vacuity, and negative-control tests | closed |
| T-166-05 | Tampering | suite thresholds | high | mitigate | Measured floor/ceiling and unchanged support implementation | closed |
| T-166-06 | Elevation of Privilege | workflow env entry | low | accept | Non-secret name/value in existing job | accepted |
| T-166-07 | Tampering | clock verification | high | mitigate | No production or workflow `faketime` use | closed |
| T-166-08 | Repudiation | advisory rationale | high | mitigate | Dated upstream evidence and falsifiable recheck | closed |
| T-166-09 | Elevation of Privilege | advisory expiry | high | mitigate | No date-override surface; real clock remains authoritative | closed |
| T-166-10 | Information Disclosure | advisory reason text | low | accept | Public URLs, PR numbers, and versions only | accepted |
| T-166-11 | Denial of Service | release retry | high | mitigate | Bounded retries and backoff | closed |
| T-166-12 | Elevation of Privilege | release API reads | high | mitigate | No permission expansion; read-only calls | closed |
| T-166-13 | Spoofing | proposal verdict | high | mitigate | `cannot-check` remains non-pass | closed |
| T-166-14 | Tampering | tagged-SHA skip | high | mitigate | Reachable-path seam tests | closed |
| T-166-15 | Information Disclosure | retry logs | low | accept | Public tag and label metadata only | accepted |
| T-166-16 | Tampering | Hex demo build | high | mitigate | One isolated Hex lane; path lanes unchanged | closed |
| T-166-17 | Tampering | trust cache keyspace | high | mitigate | Lane-prefixed keys/restores and contract test | closed |
| T-166-18 | Elevation of Privilege | CI steps | low | accept | No new permissions or secret access | accepted |
| T-166-19 | Repudiation | cache-isolation audit evidence | high | accept | Structural contract test plus recorded first-run lane-specific miss/save evidence; warm-cache observation remains continuously monitored | accepted |
| T-166-20 | Elevation of Privilege | baseline workflow dispatch | high | mitigate | Required inputs and live-path guards preserved | closed |
| T-166-21 | Spoofing | inactive-ledger signal | high | mitigate | Separate `baseline` output, never reused `completed` | closed |
| T-166-22 | Tampering | repo-hygiene exit | high | mitigate | `cannot_check` and blocked have distinct nonzero exits | closed |
| T-166-23 | Tampering | PR rollup parsing | medium | mitigate | Malformed data fails closed to `cannot_check` | closed |
| T-166-24 | Elevation of Privilege | PR-list fields | high | mitigate | Read-only fields under existing permissions | closed |
| T-166-25 | Information Disclosure | resolution artifact | low | accept | Published versions, SHA, and checksums are public | accepted |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-166-01 | T-166-03, T-166-06, T-166-10, T-166-15, T-166-18, T-166-25 | Each is explicitly low severity and carries only public or non-secret information, with no expanded authority. | Maintainer authorization via verify-work | 2026-09-19 |
| AR-166-02 | T-166-19 | The first post-merge run recorded independent lane-prefix miss/save evidence; a warm restore was not observed. The executable cache-isolation contract covers controllable behavior, while future cache telemetry remains monitored rather than treated as a phase-closing ceremony. | Maintainer authorization via verify-work | 2026-09-19 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Accepted | Open | Run By |
|---|---:|---:|---:|---:|---|
| 2026-09-19 | 26 | 19 | 7 | 0 | gsd-security-auditor + verification orchestrator |

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks documented
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-19
