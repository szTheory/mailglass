---
phase: "179"
slug: "compatibility-policy-status-map-and-brand-pin"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-17"
---

# Phase 179 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Status data to screen | Database and webhook status atoms become operator-facing words | Status atoms and delivery facts |
| Repository source to contract test | Source scans establish public API and copy contracts | Source text and module/function names |
| Policy document to verifier | A hand-edited compatibility table drives protected public names | Markdown table rows and public API identifiers |
| Network to repository | A pinned brand archive is downloaded and its bytes become committed assets | HTTPS response bytes and archive digest |
| ZIP archive to filesystem | Archive member names cross into repository paths | Member paths and asset bytes |
| Pin file to CI | A hand-edited pin could redirect the asset source of truth | Commit, archive digest, asset paths and hashes |
| Agent research to record | Search outcomes are recorded and could overstate clearance | Registry results and trademark status |
| Record to announcement gate | The record determines whether public claims can be allowed | Search status, dates, and override fields |
| Agent to outside registries | Queries leave the local machine | Public name and variants; tool identity |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-179-01 | Spoofing | `StatusMap.classify/1` | medium | mitigate | Exact status clauses have no fallback; source-derived universe and unknown/nil rejection are covered in `status_map_test.exs` | closed |
| T-179-02 | Repudiation | Contract tests | medium | mitigate | Copy contract detector self-tests and recorded mutation run demonstrate the contract tests can fail on violations (`copy_contract_test.exs`, 179-01-SUMMARY.md) | closed |
| T-179-03 | Information disclosure | `delivery_class/1`, Copy | low | accept | Pure functions use status atoms and booleans; the phase adds no PII or telemetry | closed |
| T-179-04 | Repudiation | `brand_v2_compat_policy_test` | medium | mitigate | Required marker, non-empty table, content/name checks and parser-failure tests prevent false green results | closed |
| T-179-05 | Tampering | Public API names | medium | mitigate | Policy rows check live modules, functions, enums and fields; reverse coverage catches newly added operator modules | closed |
| T-179-06 | Tampering | Brand archive download | high | mitigate | HTTPS peer verification, system CA validation, hostname matching, and commit-derived immutable URLs (`scripts/brand_pin.exs`) | closed |
| T-179-07 | Tampering | `init/2`, `update/3` | high | mitigate | Required SHA-256 is checked against exact downloaded bytes before member reads or writes; refusal tests cover mismatch | closed |
| T-179-08 | Tampering | ZIP member extraction | high | mitigate | In-memory extraction reads only pinned members and rejects traversal, absolute, backslash, NUL, and unowned paths before writes | closed |
| T-179-09 | Tampering | `brandbook/brand.pin.json` | medium | mitigate | Test-owned archive hash, per-asset digests, and owned-directory set equality catch changed, missing, or smuggled assets | closed |
| T-179-10 | Repudiation | Brand pin tamper tests | medium | mitigate | Named failure assertions, non-vacuous manifest checks, and recorded mutation run guard the test suite against false green | closed |
| T-179-11 | Spoofing | `trademark-search.json` | high | mitigate | Record invariants reject unsupported clearance claims; current caution state remains non-clear and mutation tests exercise invalid states | closed |
| T-179-12 | Elevation of privilege | Trademark `decision/2` | high | mitigate | Missing, malformed, blocked, invalid, and expired records deny; blocked takes precedence over override; incomplete overrides deny | closed |
| T-179-13 | Denial of service | Trademark gate tests | medium | mitigate | Test dates are injected from the record and fixed before expiry; the committed contract test contains no direct current-time reads | closed |
| T-179-14 | Information disclosure | Registry and RDAP queries | low | accept | Only the public name “mailglass” and its variants are queried; the searcher field names the tool, not a person | closed |
| T-179-SC | Tampering | Dependency installation | low | accept | No npm, pip, or cargo packages were added; OTP standard libraries and locked Jason remain in use, and lockfiles are unchanged | closed |

*Status: open · closed · open below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-179-01 | T-179-03 | Status and copy helpers operate on already-classified status values and add no PII or telemetry | Plan 179-01 threat model | 2026-11-17 |
| AR-179-02 | T-179-14 | Registry queries disclose only the public name and variants; the recorded searcher is the tool identity | Plan 179-04 threat model | 2026-11-17 |
| AR-179-03 | T-179-SC | The phase adds no package installs and leaves dependency lockfiles unchanged | Plans 179-01 through 179-04 threat models | 2026-11-17 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-17 | 15 | 15 | 0 | gsd-security-auditor (ASVS L1; focused trademark gate contract: 45 tests, 0 failures) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-17
