---
phase: "182"
slug: "admin-words-and-layout-one-job-first"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-15"
---

# Phase 182 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator read model (core) to admin UI | Additive lifecycle fields on `Mailglass.Operator.Deliveries` maps, tenant-scoped | Delivery timestamps and booleans, no `last_error`, no `reject_reason` text |
| Stored provider values to rendered HTML | Mailer names, provider time strings and cause text come from stored rows | Untrusted strings rendered through HEEx autoescape |
| Brand book zip to repository | `scripts/brand_status_marks.exs` pins the five status marks from the book | Zip bytes (hash-checked before any member read), derived `status-marks.json` |
| Demo capture to committed evidence | `capture-before-catalog.cjs` and the review gate write the after-catalog | Screenshots, aria sidecars, judge verdicts (reserved email domains only) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-182-01 | Information disclosure | Core operator projection | medium | mitigate | Tenancy scope kept; new keys are same-row projections; `last_error`/`reject_reason` never selected; key set pinned by `deliveries_projection_test` | closed |
| T-182-02 | Tampering | Brand mark pin script | medium | mitigate | sha256 and size checked against the pin before any member read; only `status-marks.json` is written; teeth in `brand_status_marks_test` | closed |
| T-182-03 | Repudiation | Release ledger | low | accept | `release-target.json` untouched (empty diff) | closed |
| T-182-04 | Tampering | Email search | medium | mitigate | `escape_like/1` before `ilike`; no new query parameter; journey test with `@` and `-` | closed |
| T-182-05 | Information disclosure | Cause text | medium | mitigate | `last_error` never reaches admin lib; `phase182_cause_contract_test` seeds `last_error` and asserts it never renders | closed |
| T-182-06 | Tampering (XSS) | Status marks and timestamps | low | mitigate | Only allow-listed `raw` (`js_inline()`); source scan with planted-violation control | closed |
| T-182-07 | Tampering (XSS) | Provider time | low | mitigate | `DateTime.from_iso8601/1`; unparseable value shown escaped; hostile-markup test | closed |
| T-182-08 | Repudiation | Zone display | low | accept | Zone always visible, exact UTC in tooltip and `data-utc`; pinned by the time/status contract | closed |
| T-182-09 | Denial of service | Mailer name | medium | mitigate | Binaries only, no `String.to_atom`; atom-count test with a control that creates atoms | closed |
| T-182-10 | Tampering (XSS) | Mailer identity | low | mitigate | HEEx autoescape only; hostile stored name test | closed |
| T-182-11 | Spoofing | Router and test ids | low | mitigate | Router and `stability_contract_test` untouched; `:deliveries` key kept; testids kept | closed |
| T-182-12 | Spoofing | Review gate | high | mitigate | `evidence_quote` must be a literal substring of the aria sidecar; calibration known-bad and known-good enforced; gate passes on committed catalog | closed |
| T-182-13 | Tampering | After-catalog | medium | mitigate | sha256 bindings, unlisted-file red, live binding to the bundle bytes | closed |
| T-182-14 | Repudiation | Served SHA | medium | mitigate | Forced recreate, container PID and start time recorded, dirty-tree refusal, served-asset sha equals disk and git blob | closed |
| T-182-15 | Information disclosure | Captured evidence | medium | mitigate | Unreserved-email and reset-token checks on aria text, cases and verdicts | closed |
| T-182-16 | Information disclosure | Local evidence dir | low | mitigate | `reference/demo_app/tmp/` is git-ignored; clean tree confirmed | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-182-01 | T-182-03 | Release ledger is not edited by this phase; ledger edits are their own reviewed PR | Plan 182-01 threat model | 2026-11-15 |
| AR-182-02 | T-182-08 | Compact zone display trades width for a visible zone token; exact UTC stays in tooltip and `data-utc` | Plan 182-03 threat model | 2026-11-15 |

*Accepted risks do not resurface in future audit runs.*

---

## Observations (non-blocking, not register rows)

- Plan 182-04 renamed the DOM id `delivery-detail-mailable` to `delivery-detail-mailer`. It is not a route, `data-testid`, module or path helper, and nothing in the repo references the old id. Only external tooling that selects on that id would notice.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-15 | 16 | 16 | 0 | gsd-security-auditor (final tree after review fixes 17b02830 and 4417b105; 196 admin and 29 core scoped tests, 0 failures) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-15
