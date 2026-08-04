---
phase: 153
slug: generated-host-proof-docs-and-release-gate
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-04
---

# Phase 153 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Repository packages → disposable host | Only package-allowlisted artifacts and public APIs cross. | Executable package artifacts and configuration |
| Configured schema → Postgres | Qualified checks prevent public-schema fallback. | Migration and lifecycle state |
| Public send/HTTP APIs → durable effects | Rejections precede queue, provider, feedback, or suppression effects. | Messages, webhooks, one-click tokens |
| Host observations → retained proof | Evidence is bounded, hashed, and PII-free. | Counts, statuses, hashes, run identity |
| Git/workflows → Hex | Exact resolver output and protected approval control publication. | Candidate SHA, packages, versions, credentials |
| Hex → downstream host | Exact public artifacts must repeat the adopter journey. | Immutable archives and metadata |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|-----------|----------|-----------|----------|-------------|---------------------|--------|
| T-153-01 | Tampering | Local dependency source | high | mitigate | Package build/unpack and Hex path/git-source rejection in `generated_host_proof.sh` | closed |
| T-153-02 | Tampering | Schema migration | high | mitigate | Qualified inventory/public-absence/version checks in `journey.ex` | closed |
| T-153-03 | Spoofing | Shallow host success | high | mitigate | Fresh Phoenix host plus executable migrate/boot/persisted-job proof | closed |
| T-153-04 | Information Disclosure | Checkpoint JSON | high | mitigate | Allowlisted hashed manifest and privacy-rejecting validator | closed |
| T-153-05 | Spoofing | Async success evidence | high | mitigate | Normal supervised Oban polling without direct worker execution | closed |
| T-153-06 | Tampering | Sync/async parity | high | mitigate | Canonical full provider-input comparison | closed |
| T-153-07 | Information Disclosure | Captured provider input | high | mitigate | Checkpoint emits hashes/counts only | closed |
| T-153-08 | Repudiation | Payload scrub | medium | mitigate | Qualified terminal lifecycle and scrub-state observation | closed |
| T-153-09 | Spoofing | Negative-control success | high | mitigate | Real isolated rejections with complete zero-effect snapshots | closed |
| T-153-10 | Tampering | Public schema fallback | high | mitigate | Wrong-schema rejection and schema-qualified catalog checks | closed |
| T-153-11 | Denial of Service | Polling/control | medium | mitigate | Closed controls and bounded endpoint/job polling deadlines | closed |
| T-153-12 | Information Disclosure | Error/checkpoint context | medium | mitigate | Closed reason classes/counts and sensitive-field rejection | closed |
| T-153-13 | Spoofing | Provider webhook | high | mitigate | Real signed/forged HTTP proof with forged `401` and zero effects | closed |
| T-153-14 | Tampering | One-click scope | high | mitigate | Delivery-derived URL, exact counts, and scoped suppression controls | closed |
| T-153-15 | Repudiation | Replay convergence | medium | mitigate | Repeated responses plus canonical event/suppression cardinality | closed |
| T-153-16 | Information Disclosure | Signature/token evidence | high | mitigate | Status/count-only retention; raw secrets/tokens/addresses blocked | closed |
| T-153-17 | Information Disclosure | Preflight output | high | mitigate | Redacted check/remediation output with secret-output tests | closed |
| T-153-18 | Spoofing | Production operator mount | high | mitigate | Host authentication precedes operator routes; `401`/`200` proof | closed |
| T-153-19 | Tampering | Migration-currentness | high | mitigate | Public migration-version API and fail-closed checks | closed |
| T-153-20 | Elevation of Privilege | Development routes | high | mitigate | Production proof rejects `dev_routes` and anonymous access | closed |
| T-153-21 | Tampering | Executable documentation | medium | mitigate | Parsed executable adopter blocks reject private seams | closed |
| T-153-22 | Elevation of Privilege | Admin mounting guide | high | mitigate | Authenticated host-owned mounting guidance is contract-tested | closed |
| T-153-23 | Spoofing | Feedback configuration guide | high | mitigate | Signing and fail-closed production guidance is contract-tested | closed |
| T-153-24 | Information Disclosure | Example configuration | medium | mitigate | Synthetic values plus secret-shaped evidence rejection | closed |
| T-153-25 | Tampering | Changed-package resolver | high | mitigate | Per-package bases, ownership allowlists, linked set, exact target match | closed |
| T-153-26 | Repudiation | Release evidence | high | mitigate | Immutable ledger and live verifier bind SHA, runs, and outputs | closed |
| T-153-27 | Elevation of Privilege | Publish workflow | critical | mitigate | Gated selected-package jobs use protected `hex-publish` environment | closed |
| T-153-29 | Elevation of Privilege | Protected publication | critical | mitigate | Verifier rejects absent approval, deployment, workflow, or artifact | closed |
| T-153-30 | Tampering | Published artifacts | critical | mitigate | Exact tags, versions, checksums, package set, docs, retirement checks | closed |
| T-153-31 | Repudiation | Release proof ledger | high | mitigate | Ledger binds workflow/job IDs, URLs, SHA, approvals, and outputs | closed |
| T-153-32 | Spoofing | Registry propagation | high | mitigate | Exact Hex resolution with path/git override rejection | closed |
| T-153-SC | Tampering | Package installs | high | mitigate | Resolver-selected exact audited artifacts; no new npm/pip/cargo installs | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-04 | 32 | 32 | 0 | gsd-security-auditor |

Focused contracts passed with 105 tests, 0 failures, and 1 intentional skip.
The live ledger verifier also passed for `mailglass-v2.4.1`.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-04
