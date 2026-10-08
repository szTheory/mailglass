---
phase: "168"
slug: "shared-workspace-and-usable-baseline"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 168 — Security

Authored threat registers from all four plans were checked against implementation at ASVS L1 depth. All nine mitigation dispositions have controls present; the existing asset supply-chain risk remains accepted as documented at plan time. This is a mitigation-presence audit, not a penetration test. The workflow permits the L1 short circuit with an authored register and no open threats.

## Trust Boundaries

| Boundary | Description | Data crossing |
| --- | --- | --- |
| Browser to server selection | Account, filter and record parameters are untrusted | Tenant and Delivery IDs, filter strings |
| Host actor to Account options | Selection options do not grant authority | Host-scoped Account list and actor |
| Stored facts to rendered UI | HEEx escapes values; summaries retain observed semantics | Names, IDs, diagnostics, events and timestamps |
| Confirmation to replay | Exact scoped target and action-time authorization precede execution | Tenant, Delivery, webhook event and actor |
| Theme request to persistence | Closed values and namespaced cookie | System/Light/Dark preference |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-168-01 | Information disclosure | Account switch and reads | high | mitigate | `OperatorLive.handle_params/3` derives host-actor options; `Operator.Shell.tenant_switch_path/2` removes prior record IDs. `Operator.Deliveries.scoped_query` retains tenant filtering and `Tenancy.scope`. Account-scope browser case and LiveView tests cover the switch. | closed |
| T-168-02 | Spoofing | Active navigation and scope label | medium | mitigate | Shell Account label and active destinations derive from committed server route/selection. URL helpers whitelist preserved filters. No client-side optimistic label substitution. Delayed/rejected visual presentation remains a UI evidence concern, not a missing scope control. | closed |
| T-168-03 | Injection | Labels, filters and diagnostics | medium | mitigate | Existing HEEx escaped interpolation and URI helpers remain in shell, filters, Quick view and replay; no raw HTML path added for host values. | closed |
| T-168-04 | Repudiation | Delivery summary | medium | mitigate | Quick view/detail retain event values and timestamps; missing values render Unavailable. Delivery status is not fabricated from absent observations. Focused operator/component tests retain exact facts. | closed |
| T-168-05 | Tampering | Theme preference | low | mitigate | `Theme.query_choice`/`cookie_choice` constrain choices; invalid or absent means System; existing namespaced HttpOnly SameSite cookie and local persistence path remain. Component and browser tests cover System versus explicit choice. | closed |
| T-168-06 | Repudiation | Status and feedback | medium | mitigate | Shared timestamps expose recorded UTC values, nil is Unavailable, fabricated gallery refresh time removed. `RepairState.flash_success` distinguishes observed replay outcomes; repeated-patch browser cases retain the same factual status. | closed |
| T-168-07 | Information disclosure | Quick view target | high | mitigate | `find_selected_delivery/2` matches the exact ID in the tenant-scoped collection; absent ID cannot fall back to another record. Browser Quick view case covers unavailable target. | closed |
| T-168-08 | Elevation of privilege | Replay confirmation | high | mitigate | `confirm_replay` selects from server candidate set, invokes `DestructiveAction.authorize` with actor/Delivery/target, then `Replay.execute`; core replay fetch retains tenant and Delivery predicates. LiveView/browser tests exercise recent-auth denial and exact target. | closed |
| T-168-09 | Repudiation | Replay outcome | medium | mitigate | Replay result status feeds existing `RepairState` outcome copy; pending, no-change, completion and denial retain target/facts. No downstream-delivery claim is inferred. | closed |
| T-168-SC | Tampering | Asset dependencies | low | accept | Existing Mix build, vendored assets and opt-in browser tooling reused. Locked dependencies were synchronized for execution; no new dependency/toolchain introduced by Phase 168. | closed |

## Accepted Risks Log

| Risk ID | Threat ref | Rationale | Accepted by | Date |
| --- | --- | --- | --- | --- |
| R-168-SC | T-168-SC | Existing dependency supply-chain exposure; phase introduces no new dependency or product Node toolchain. Plan wording about no installation refers to avoiding new packages, not restoring existing locked dependencies. | Approved execution plans 168-01..04 | 2026-10-07 |

## Security Audit Trail

| Audit date | Threats total | Closed | Open | Run by |
| --- | --- | --- | --- | --- |
| 2026-10-07 | 10 | 10 | 0 | Execute-phase orchestrator, L1 mitigation-presence check |

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risk documented from authored plans.
- [x] `threats_open: 0` confirmed (high blocking threshold).
- [x] `status: verified` set.

**Approval:** Verified 2026-10-07 at configured L1 depth.

## Security Audit 2026-10-08

| Metric | Count |
|---|---|
| Threats found | 10 |
| Closed | 10 |
| Open | 0 |
