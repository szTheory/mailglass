---
phase: 63
slug: inbound-contract-inventory-reconciliation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-31
---

# Phase 63 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Canonical inventory -> adopter integration decisions | Misleading docs could make adopters treat internal modules or unstable flows as supported public contract. | Stability-contract documentation and adopter-facing API expectations |
| Operator/replay wording -> tenant-scoped recovery behavior | If replay or prune semantics are described imprecisely, operators can infer unsafe cross-tenant or fresh-receipt behavior. | Operator command semantics, tenant scope, replay and prune recovery behavior |
| Telemetry/error wording -> external observability and incident tooling | Over-claiming telemetry or error semantics can leak incorrect expectations about PII, verification, or recovery behavior. | Telemetry family names, metadata-shape guarantees, structured error contracts |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-63-01 | Spoofing | `mailglass_inbound/docs/api_stability.md` ingress/provider wording | mitigate | `MailglassInbound.Ingress.Plug` is the stable provider-support seam for `:postmark`, `:sendgrid`, `:mailgun`, and `:ses`; provider modules remain internal, and docs-contract assertions pin both statements. | closed |
| T-63-02 | Elevation of Privilege | Replay and operator contract wording | mitigate | Stable operator behavior documents `mix mailglass.inbound.replay --tenant`, replay over stored canonical and raw evidence truth, confirmation semantics, and internal classification for replay, worker, queue, and job details; docs-contract assertions refute replay-as-fresh and public worker or queue contract claims. | closed |
| T-63-03 | Information Disclosure | Telemetry and error-contract claims | mitigate | Stability docs list only shipped PII-safe telemetry families, closed `:type` sets for `MailglassInbound.MIMEError`, `MailglassInbound.SignatureError`, and `MailglassInbound.S3FetchError`, and serialization exclusions for sensitive raw payload details; docs-contract assertions pin the error and telemetry tokens. | closed |
| T-63-SC | Tampering | npm/pip/cargo installs | n/a | No package-manager installs or dependency changes occurred in this docs-contract phase. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party) - n/a (not applicable)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Threats found | 4 |
| Closed | 4 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-31 | 4 | 4 | 0 | Codex |

## Evidence

- Plan-time threat model found in `63-01-PLAN.md`; `register_authored_at_plan_time: true`.
- Summary threat flags: none found in `63-01-SUMMARY.md`.
- `mailglass_inbound/docs/api_stability.md` documents the stable/testing/internal/deferred contract buckets, provider support through `MailglassInbound.Ingress.Plug`, replay and operator guardrails, PII-safe telemetry families, and closed structured error contracts.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` asserts required Phase 63 inventory tokens and refutes provider-module API, worker or queue contract, replay-as-fresh, and ExDoc-stability over-claims.
- Verification passed: `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`.
- Verification passed: `mix verify.stability_contract`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer / n/a)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-31
