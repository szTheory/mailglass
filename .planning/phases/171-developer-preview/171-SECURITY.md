---
phase: "171"
slug: "developer-preview"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 171 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser URL and event → PreviewLive | Module, scenario, editable keys, and draft values are untrusted and must resolve against discovered, supported values. | URL strings, event payloads, scalar drafts |
| Host router → preview mount | The adopter owns development-route exposure; the preview macro does not provide authorization. | Route configuration and request |
| Mailable/Renderer HTML → iframe | Rendered HTML is displayed with scripts disabled; same-origin behavior does not make it a sanitizer or network boundary. | Synthetic or author-controlled HTML and resource URLs |
| Preview projection → author interpretation | Raw, headers, width, and backdrop are preview representations and cannot establish provider or recipient-client behavior. | Rendered content and presentation labels |
| Synthetic capture → maintainer | Capture artifacts may contain scenario data and stay in the ignored temporary output path. | Synthetic scenario data and screenshots |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-171-01 | Elevation of Privilege | PreviewLive selection | high | mitigate | Existing-atom conversion and discovered Mailable/scenario membership checks reject arbitrary URL selections before invoking a Mailable; covered by Preview LiveView tests. | closed |
| T-171-02 | Information Disclosure | Adopter route mount | high | mitigate | The guide preserves the host-owned `:dev_routes` guard and states that route exposure belongs to the adopter. | closed |
| T-171-03 | Tampering | `assigns_changed` | high | mitigate | Only default-declared editable scalar keys and valid payload shapes are accepted; parsing consumes complete values before scenario rendering. | closed |
| T-171-04 | Repudiation | Last-successful output state | medium | mitigate | Drafts and parsed values are separate from renderer output; retained output is labeled as the last successful preview after pending or failed attempts. | closed |
| T-171-05 | Denial of Service | Text-change render frequency | low | mitigate | Free-text inputs use built-in LiveView debounce; selection and error handling remain server-owned. | closed |
| T-171-06 | Tampering | HTML iframe | medium | mitigate | The iframe keeps the script-disabled `sandbox="allow-same-origin"` contract, asserted by LiveView tests. | closed |
| T-171-07 | Information Disclosure | Remote iframe resources | medium | mitigate | Preview guidance states that remote URLs may trigger browser requests and recommends synthetic, non-sensitive assigns; it makes no network-isolation claim. | closed |
| T-171-08 | Spoofing | Raw and Header representations | medium | mitigate | Raw is labeled illustrative and generated Message-ID/Date values are identified as preview values, not provider facts. | closed |
| T-171-09 | Spoofing | Width and backdrop claims | medium | mitigate | Controls and copy identify CSS-pixel width and browser backdrop as independent presentation settings, not email-client proof. | closed |
| T-171-10 | Information Disclosure | Preview captures | medium | mitigate | Captures use synthetic fixture data and ignored temporary output; rendered review limits the evidence claim and notes artifact sensitivity. | closed |
| T-171-SC | Tampering | Package installation | high | mitigate | The four plans added no package install or dependency/lockfile changes; the threat's required package-legitimacy gate was not triggered. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 11 | 11 | 0 | Codex, ASVS L1 source and artifact review |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09
