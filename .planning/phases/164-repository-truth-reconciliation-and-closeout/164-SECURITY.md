---
phase: "164"
slug: repository-truth-reconciliation-and-closeout
status: blocked
threats_open: 10
asvs_level: 1
block_on: high
created: "2026-09-01"
---

# Phase 164 — Security

> Retroactive ASVS L1 verification of the STRIDE registers authored in the Phase 164 plans. High-severity open threats block phase completion.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Canonical checkout | Local repository identity versus protected `szTheory/mailglass` main | repository path, remote identity, Git SHA, porcelain |
| GitHub evidence | Local finalizer versus GitHub Actions APIs and retained artifacts | workflow/run identity, attempt, event, SHA, artifact digests |
| Ignored capture area | Finalizer and closeout scripts versus predictable local paths | JSON evidence, component output, filesystem links |
| Truth ledger | Tracked disposition claims versus repository-derived inventory | subject identity, state, authority, evidence, disposition |
| Operator guidance | Documentation versus runtime dependency availability | supported commands, package scope, current contract version |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-164-01 | Tampering | stale sweep removal | high | mitigate | Locked digest and singular removal contract | closed |
| T-164-02 | Repudiation | disposition ledger schema | high | mitigate | Required fields, enum, and duplicate checks | closed |
| T-164-03 | Tampering | ignore-rule preservation | high | mitigate | Must prove all six ignore files contain no proof-hiding rule after later edits | open |
| T-164-04 | Elevation of Privilege | protected release authority | high | mitigate | Exact candidate/digest and repository-admin contract | closed |
| T-164-05 | Spoofing | CI evidence | high | mitigate | Exact CI identity and malformed-data failure | closed |
| T-164-06 | Repudiation | historical guidance | medium | mitigate | Explicit historical applicability contract | closed |
| T-164-07 | Spoofing | package compatibility | medium | mitigate | Manifest-derived compatibility tests | closed |
| T-164-08 | Tampering | historical documentation | medium | mitigate | Current and historical sections tested separately | closed |
| T-164-09 | Tampering | ledger subject inventory | high | mitigate | Validator must reject extra fabricated subjects via exact set equality | open |
| T-164-10 | Repudiation | ledger completeness | high | mitigate | Nonblank fields and exact enums | closed |
| T-164-11 | Information Disclosure | ignore scope | medium | mitigate | Six ignore files derived and narrow visibility tested | closed |
| T-164-12 | Spoofing | closeout Git/CI identity | high | mitigate | Branch, SHA, run, and CI head checks | closed |
| T-164-13 | Tampering | scheduled evidence predicate | high | mitigate | Require exact registered-control set and complete run/workflow/digest bindings | open |
| T-164-14 | Repudiation | aggregate verdict precedence | high | mitigate | Add executable malformed/unavailable/pending/blocked/pass precedence coverage | open |
| T-164-15 | Elevation of Privilege | evidence command authority | high | mitigate | No dispatch, rerun, merge, or publish surface | closed |
| T-164-16 | Spoofing | CI run selection | high | mitigate | Attempt-one exact-SHA CI selection and raw re-query | closed |
| T-164-17 | Elevation of Privilege | finalizer authority | high | mitigate | Observation/fetch and ignored writes only | closed |
| T-164-18 | Spoofing | protected-main freshness | high | mitigate | Re-fetch origin/main at final decision and reassert all identities | open |
| T-164-19 | Tampering | persisted component evidence | high | mitigate | Reject incomplete scheduled-control evidence | open |
| T-164-20 | Repudiation | report provenance | high | mitigate | Persist timestamp, repository/SHA/run, sources, statuses, reasons | closed |
| T-164-21 | Elevation of Privilege | closeout operations | high | mitigate | No dispatch, rerun, merge, tag, or publish | closed |
| T-164-22 | Tampering | ledger enums | high | mitigate | Exact currentness/disposition and stale-outcome rules | closed |
| T-164-23 | Repudiation | required subjects | high | mitigate | Derive required subjects from Git, plans, proof, verification, ignores | closed |
| T-164-24 | Tampering | duplicate subjects | medium | mitigate | Ordering-independent duplicate rejection | closed |
| T-164-25 | Spoofing | repository authority | high | mitigate | Pin normalized origin and GitHub owner/repository to `szTheory/mailglass` | open |
| T-164-26 | Tampering | ledger semantic authority | high | mitigate | Authenticate state, authority, producer, evidence, and stable-ID relationships | open |
| T-164-27 | Repudiation | local capture paths | high | mitigate | Use private symlink-safe directories and leaf creation | open |
| T-164-28 | Elevation of Privilege | remote behavior | high | mitigate | Read-only remote behavior | closed |
| T-164-36 | Tampering | freshness authority | high | mitigate | Registry-specific age decision remains in scheduled sweep | closed |
| T-164-37 | Spoofing | scheduled provenance | high | mitigate | SHA, attempt, event, branch, status, workflow-SHA mutation tests | closed |
| T-164-38 | Repudiation | sweep completeness | high | mitigate | Require successful top-level sweep and exact complete envelope | open |
| T-164-39 | Elevation of Privilege | scheduled controls | medium | mitigate | No workflow/rerun/authorization/release surface | closed |
| T-164-SC | Tampering | package supply chain | low | accept | Acceptance is not yet documented; below the configured blocking threshold | open — below high threshold |

## Accepted Risks Log

No accepted risks. T-164-SC remains open below the configured blocking threshold; it has not been silently accepted.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-01 | 33 | 22 | 11 total / 10 blocking | gsd-security-auditor |

## Sign-Off

- [x] All registered threats were inspected at ASVS L1.
- [ ] All high-severity mitigations are present.
- [ ] Accepted risks are documented and approved.
- [ ] `threats_open: 0` confirmed.
- [ ] `status: verified` set in frontmatter.

**Approval:** blocked — ten high-severity threats require mitigation before phase advancement.
