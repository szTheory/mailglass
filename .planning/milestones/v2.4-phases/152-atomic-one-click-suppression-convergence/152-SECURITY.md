---
phase: 152
slug: atomic-one-click-suppression-convergence
status: verified
# Blocking gate: count of OPEN threats at or above `block_on: high`.
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-03
---

# Phase 152 — Security

## Verdict: SECURED

The Phase 152 register was authored at planning time and contains twelve mitigated threats. At ASVS L1, every declared mitigation has a present, implementation-level control in its cited boundary. No implementation files were modified by this audit.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| one-click HTTP → token/Delivery resolution | Signed opaque token resolves a persisted Delivery before scope is derived. | Untrusted token; trusted delivery ID, tenant, recipient, stream |
| trusted Delivery → tenant transaction | Delivery facts enter tenant-restored, prefix-explicit convergence. | Tenant, address, stream, delivery ID |
| Ecto.Multi → PostgreSQL | Unique canonical event/suppression identities arbitrate concurrent requests. | Durable event and suppression rows |
| committed transaction → lifecycle/PubSub | Created-only bounded facts reach optional post-commit effects. | Tenant, delivery ID, event type, scope, stream |
| suppression store → outbound adapter | Matching suppression is checked before dispatch. | Normalized outbound message and suppression result |

## Threat Register

| Threat ID | Category | Severity | Disposition | Status | Implementation evidence |
|---|---|---|---|---|---|
| T-152-01 | Tampering / Elevation | high | mitigate | closed | [`unsubscribe.ex`](../../../lib/mailglass/compliance/unsubscribe.ex:35) verifies signed, max-age token; [`unsubscribe_controller.ex`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:73) resolves only its Delivery and restores `delivery.tenant_id` before convergence at [line 100](../../../lib/mailglass/compliance/unsubscribe_controller.ex:100). |
| T-152-02 | Tampering / Repudiation | high | mitigate | closed | [`unsubscribe_convergence.ex`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:51) builds one `Ecto.Multi`; conflict inserts/refetches use unique identities and `Repo.multi_opts` at [lines 57](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:57), [102](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:102), and [122](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:122). |
| T-152-03 | Information Disclosure | medium | mitigate | closed | [`unsubscribe_controller.ex`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:47) returns exact empty 200 for expired/invalid targets; genuine convergence errors are exact empty 500 at [line 96](../../../lib/mailglass/compliance/unsubscribe_controller.ex:96). |
| T-152-04 | Denial of Service / Tampering | high | mitigate | closed | Named transaction failure steps are present at [`unsubscribe_convergence.ex:56`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:56) and [`:75`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:75); result errors map to empty 500. |
| T-152-05 | Denial of Service | high | mitigate | closed | Created-only post-commit invocation is at [`unsubscribe_controller.ex:121`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:121); lifecycle work is a separate `Repo.multi` with rescue/catch isolation at [line 136](../../../lib/mailglass/compliance/unsubscribe_controller.ex:136). |
| T-152-06 | Information Disclosure | high | mitigate | closed | Effect attrs are an explicit five-key whitelist with no recipient/token/content at [`unsubscribe_controller.ex:121`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:121); durable suppression metadata is exactly three bounded keys at [`unsubscribe_convergence.ex:200`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:200). |
| T-152-07 | Repudiation / Tampering | high | mitigate | closed | `created` is derived only from durable insert/promotion outcomes at [`unsubscribe_convergence.ex:81`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:81), and effects run only on `:created` at [`unsubscribe_controller.ex:121`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:121). |
| T-152-08 | Tampering / Information Disclosure | high | mitigate | closed | Tenant restoration precedes convergence at [`unsubscribe_controller.ex:100`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:100); every convergence insert/refetch/update passes explicit prefix options (for example [`unsubscribe_convergence.ex:61`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:61), [`:113`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:113), [`:176`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:176)). |
| T-152-09 | Elevation / Information Disclosure | high | mitigate | closed | Both synchronous and asynchronous outbound paths call suppression preflight before provider work at [`outbound.ex:274`](../../../lib/mailglass/outbound.ex:274) and [`outbound.ex:311`](../../../lib/mailglass/outbound.ex:311). |
| T-152-10 | Repudiation | medium | mitigate | closed | Executable runtime contract is published in [`api_stability.md:29`](../../../docs/api_stability.md:29), with focused contract tests included in the passing audit matrix. |
| T-152-11 | Information Disclosure | high | mitigate | closed | Operator guidance explicitly forbids recording token/message content and bounds verification evidence at [`unsubscribe.md:142`](../../../guides/unsubscribe.md:142). |
| T-152-12 | Denial of Service / Tampering | medium | mitigate | closed | Compatibility contract specifies fresh-Multi, post-commit, separate best-effort lifecycle execution at [`api_stability.md:41`](../../../docs/api_stability.md:41); implementation calls `handle_event(Ecto.Multi.new(), attrs)` separately at [`unsubscribe_controller.ex:136`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:136). |

## Review-Discovered Concerns

| Concern | Status | Evidence |
|---|---|---|
| Tenant-restored post-commit effects | closed | Effect call is within `Tenancy.with_tenant(delivery.tenant_id, ...)` at [`unsubscribe_controller.ex:41`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:41). |
| Temporary same-identity suppression promotion race | closed | Conditional, prefix-explicit promotion and loser refetch are present at [`unsubscribe_convergence.ex:163`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:163). |
| Database/repository exception disclosure | closed | Bounded exception classification/logging is present at [`unsubscribe_controller.ex:100`](../../../lib/mailglass/compliance/unsubscribe_controller.ex:100). |
| Mutable production failure switch | closed | Injection seam is compiled only under `Mix.env() == :test` at [`unsubscribe_convergence.ex:216`](../../../lib/mailglass/compliance/unsubscribe_convergence.ex:216). |
| Race proof and preflight bridge | closed | Focused matrix includes real concurrent and real-Outbound preflight tests (see audit evidence below). |

## Unregistered Flags

None. `## Threat Flags` is absent from all three Phase 152 summaries; no executor-discovered attack surface is unmapped.

## Accepted Risks Log

No accepted risks. All register entries have the `mitigate` disposition and are closed.

## Audit Evidence

- `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/schema_prefix_hardening_test.exs test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors`
  - Passed: 120 tests, 1 property, 0 failures, 1 skipped.
- The run emitted existing migration-version and missing optional-OTLP-exporter warnings; neither is a Phase 152 threat-register mitigation failure or an unregistered attack-surface flag.

## Security Audit Trail

| Audit Date | ASVS | Block Threshold | Threats Total | Closed | Blocking Open | Non-blocking Open | Run By |
|---|---:|---|---:|---:|---:|---:|---|
| 2026-08-03 | 1 | high | 12 | 12 | 0 | 0 | gsd-security-auditor |

## Sign-Off

- [x] All threats have a disposition and implementation evidence.
- [x] No accepted or transferred risks require documentation.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-03
