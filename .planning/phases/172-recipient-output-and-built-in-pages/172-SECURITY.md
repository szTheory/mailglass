---
phase: "172"
slug: "recipient-output-and-built-in-pages"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 172 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Public component input → rendered email HTML | Author-controlled text and attributes are rendered through the existing HEEx component path. | Dynamic copy, URLs, image alternatives |
| Renderer HTML tree → generated plaintext | HTML nodes and link destinations are converted into a recipient-visible text body. | Element text, destinations, image alternatives, hidden markers |
| Untrusted unsubscribe token → GET controller | Token verification selects a valid, expired, or invalid page without leaking delivery data. | Signed token and status |
| Delivery recipient → built-in HEEx response | A valid recipient value is interpolated into the informational page. | Recipient string |
| Browser GET → durable unsubscribe state | GET displays state; only protocol POST performs the unsubscribe transition. | Request method and verified token |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-172-01 | Tampering | Public components and demo Mailable dynamic text/attributes | high | mitigate | Existing HEEx interpolation plus hostile-markup component assertions; focused component and preview tests passed. | closed |
| T-172-02 | Spoofing | Demo preview evidence claims | medium | mitigate | Named preview scenarios and browser assertions distinguish public components from AtlasDesk's separate HTML authoring path. | closed |
| T-172-03 | Tampering | Plaintext link extraction | medium | mitigate | Ordinary, nested, marked, and heading links retain their destinations once; case-sensitive URL regression is covered by renderer tests. | closed |
| T-172-04 | Information Disclosure | Renderer text and HTML output | medium | mitigate | Existing skip/marker-strip stages remain covered; generated plaintext and final HTML tests assert hidden content and internal markers do not leak. | closed |
| T-172-05 | Tampering | Recipient value in built-in HTML | high | mitigate | HEEx escapes hostile recipient markup; controller/template tests prove escaped output and absence of executable script markup. | closed |
| T-172-06 | Information Disclosure | Invalid/expired token responses | high | mitigate | Invalid/expired responses retain 404/410, render fixed recovery states, and tests assert token and recipient data are absent. | closed |
| T-172-07 | Elevation of Privilege | GET versus POST unsubscribe state | high | mitigate | Valid GET leaves event state unchanged; POST remains the only mutation path and retains event, suppression, lifecycle, and replay-idempotency checks. | closed |
| T-172-08 | Spoofing | Browser page completion claim | medium | mitigate | Valid-page copy explicitly states no unsubscribe occurred; recovery pages and browser evidence assert only supported next steps. | closed |
| T-172-SC | Tampering | Dependency supply chain | high | mitigate | No dependency or lockfile changes were introduced by the phase. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 9 | 9 | 0 | GSD phase verification (ASVS L1 artifact and test evidence) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09; all blocking threats have implementation or supply-chain evidence and passing checks.
