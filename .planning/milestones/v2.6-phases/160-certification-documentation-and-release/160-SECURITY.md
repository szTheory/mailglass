---
phase: 160
slug: certification-documentation-and-release
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-20
verified: 2026-08-20
---

# Phase 160 — Security

> Consolidated security contract for generated-host certification, release authorization, protected publication, and exact-Hex adoption.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Generated host → package generators | Host-controlled configuration selects modules, repositories, and schema prefixes. | Runtime module names and database scope |
| Runtime/provider → proof artifact | Delivery outcomes become durable certification evidence. | Sanitized checkpoint status and ordering |
| Implementation → adopter documentation | Internal symbols could be presented as supported public API. | Stability and deprecation claims |
| Hex API → repository release state | Remote metadata influences release readiness. | Package names, versions, retirement state, checksums |
| Automation proposal → human authorization | A proposal becomes eligible for protected release. | Source/head SHAs, versions, content and candidate digests |
| Release inputs → protected workflow | Repository and dispatch input controls refs and package selection. | Candidate digest, tag SHA, package set |
| Protected workflow → Hex | Credential-bearing jobs perform irreversible publication. | Package archives, docs, release credentials |
| Hex artifacts → disposable adopter host | Public artifacts become the actual certified dependency graph. | Exact versions and lock checksums |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-160-01 | Tampering | Checkpoint order | high | mitigate | Exact ordered manifest plus missing, duplicate, and equal-order mutation tests | closed |
| T-160-02 | Information Disclosure | Proof artifact | high | mitigate | Closed sanitized schema rejects recipients, bodies, secrets, and provider payloads | closed |
| T-160-03 | Elevation of Privilege | Module/repo selection | high | mitigate | Literal configured modules, existing-atom resolution, scoped repos, and prefix assertions | closed |
| T-160-04 | Spoofing | API inventory | high | mitigate | Documentation is cross-checked against exported seams and stability contracts | closed |
| T-160-05 | Repudiation | Deprecation history | medium | mitigate | Explicit replacements/removal targets and stale-claim negative tests | closed |
| T-160-06 | Elevation of Privilege | Admin scope | high | mitigate | Contracts reject fabricated operator/admin behavior | closed |
| T-160-07 | Spoofing | Hex metadata | high | mitigate | HTTPS read-only fetch, exact package identities, semantic parsing, fixture tests | closed |
| T-160-08 | Tampering | Release target | high | mitigate | Exact target schema and three-package equality; activation requires reviewed identity | closed |
| T-160-09 | Repudiation | Version reconciliation | medium | mitigate | Structured report records live and repository inputs and comparisons | closed |
| T-160-10 | Tampering | Candidate package set | high | mitigate | Exact schema/set checks, duplicate and unknown rejection, content identity, final SHA check | closed |
| T-160-11 | Elevation of Privilege | Workflow permissions | high | mitigate | Read-only preparation, job-local permissions, and protected environment | closed |
| T-160-12 | Injection | Release inputs | high | mitigate | Structured arguments, no `eval`, escaped summaries, hostile-input fixtures | closed |
| T-160-13 | Spoofing | Candidate identity | high | mitigate | Authorization binds source/head SHAs, versions, package set, and both digests | closed |
| T-160-14 | Repudiation | Authorization | high | mitigate | Explicit digest-bearing authorization is recorded; no automatic approval | closed |
| T-160-15 | Elevation of Privilege | Release credentials | high | mitigate | Explicit authority, protected environment, job-local permissions, no secret output | closed |
| T-160-16 | Tampering | Tag/ref/package set | high | mitigate | Identity equality before merge and immutable tag SHA checks before every publish job | closed |
| T-160-17 | Repudiation | Partial publication | high | mitigate | Per-package release IDs/checksums and fail-closed completion ledger | closed |
| T-160-18 | Spoofing | Exact-Hex proof | high | mitigate | Lock/checksum verification and explicit rejection of path/git dependencies | closed |

## ASVS Level 1 Baseline

| Area | Evidence | Result |
|------|----------|--------|
| Input and schema validation | Release-policy hostile-input and mutation tests; exact JSON key/package-set validation | pass |
| Access and privilege control | Protected GitHub environment and job-local least-privilege permissions | pass |
| Sensitive data handling | Sanitized proof schema and no-secret-output workflow contracts | pass |
| Integrity and supply chain | Immutable tag SHA, package checksums, exact-Hex lock validation, no path/git fallback | pass |
| Logging and accountability | Candidate authorization, workflow URLs, release IDs, and checkpoint hashes in the completed ledger | pass |
| Fail-safe behavior | Partial/mismatched publication and adoption evidence cannot produce `completed=true` | pass |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-20 | 18 | 18 | 0 | Codex secure-phase hook |

The audit used the phase's negative/contract suites, `actionlint`, the canonical completed ledger, and the independently verified protected publication and adoption runs. No open threat at the configured default `high` threshold—and no lower-severity open threat—remains.

## Sign-Off

- [x] All threats have a disposition.
- [x] No risk required acceptance or transfer.
- [x] `threats_open: 0` confirmed at the `high` blocking threshold.
- [x] ASVS Level 1 baseline reviewed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-20
