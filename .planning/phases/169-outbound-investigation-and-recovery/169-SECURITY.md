---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-08"
---

# Phase 169 — Security

Independent gsd-security-auditor review: **SECURED, 17/17 closed**, ASVS level 1, blocking threshold high. Register authored in the five plans; shared T-169-SC is counted once. Review covered checkout a2307018 and its implementation ancestors; this is source inspection, not a claim of a new full test run.

## Trust Boundaries

| Boundary | Data crossing |
|---|---|
| Browser URL and command events → core reads/actions | Account, Delivery, Event and stored request IDs; frozen review state |
| Host authorization → replay command | Existing destructive-action and recent-auth decision |
| Database observations/audits → Admin presentation | Allowlisted diagnostics and bounded observations; no raw payload/session/exception detail |
| Test harness/assets → acceptance evidence | Test-only routes, fixture identity, served CSS and revision |
| Sibling exports → adopter documentation | Internal read seams and API stability classification |

## Threat Register

Unqualified Admin paths below are relative to `mailglass_admin/lib/mailglass_admin/`; test basenames resolve in their respective test directories.

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-169-01 | Information disclosure | Exact Delivery lookup | high | mitigate | lib/mailglass/operator/deliveries.ex:75–85; operator_live.ex:1728–1751: exact ID plus Account and Tenancy.scope. | closed |
| T-169-02 | Tampering | URL/filter state | medium | mitigate | operator_live.ex:1310–1330,2256–2309 and operator/shell.ex:104–109,151–159: bounded normalized filters; Account switch drops object IDs. | closed |
| T-169-03 | Elevation of privilege | First replay tracer | high | mitigate | operator_live.ex:527–561: reload Delivery and target, then host authorization before Replay.execute/1. | closed |
| T-169-SC | Tampering | npm/pip/cargo installs | high | mitigate | Diff 987ae8c8..HEAD changes no npm/pip/cargo manifest or lockfile; 169-05-SUMMARY.md:156 records no installed test packages. Conditional audit not triggered. | closed |
| T-169-04 | Information disclosure | Exact support reads | high | mitigate | lib/mailglass/operator/support_summary.ex:73–133; operator_live.ex:2330–2370: scoped narrow projection and shared missing/foreign state. | closed |
| T-169-05 | Tampering | Health observation presentation | medium | mitigate | operator_live.ex:1822–1941,700–850,2524–2555: independent populations, shared window, correct units and destinations. | closed |
| T-169-06 | Information disclosure | Availability handling | high | mitigate | operator_live.ex:1767–1782,1943–1963,2350–2375: allowlisted transient errors only; other faults re-raised. | closed |
| T-169-07 | Information disclosure | Timeline.get_delivery_event/3 | high | mitigate | lib/mailglass/operator/timeline.ex:44–71; operator_live.ex:1459–1484: Account+Delivery+Event predicates and exact identity. | closed |
| T-169-08 | Information disclosure | Timeline presenter | high | mitigate | operator_live.ex:1427–1453; operator/timeline.ex:189–230: safe field projection, no raw maps. | closed |
| T-169-09 | Tampering | Suppression interpretation | medium | mitigate | lib/mailglass/operator/suppressions.ex:18–51,126–127; lib/mailglass/suppression.ex:110–128; operator/suppression_card.ex:73–88: current scoped record and truthful policy limits. | closed |
| T-169-10 | Tampering | Replay target selection | high | mitigate | operator_live.ex:1987–2025,527–548: frozen material facts, full candidate comparison and current membership. | closed |
| T-169-11 | Elevation of privilege | Replay command | high | mitigate | operator_live.ex:538–561; operator/destructive_action.ex:15–26: host callback after target revalidation, immediately before execution. | closed |
| T-169-12 | Repudiation | Duplicate queued Confirm | medium | mitigate | operator_live.ex:517–524,622; lib/mailglass/webhook/replay.ex:39–49: review consumed before submission, duplicates ignored; request audit appended. | closed |
| T-169-13 | Information disclosure | Replay feedback | high | mitigate | operator/repair_state.ex:91–118,205–229; lib/mailglass/webhook/replay.ex:63–110: fixed safe copy and controlled persistence failure after rollback. | closed |
| T-169-14 | Tampering | Rendered evidence provenance | medium | mitigate | mailglass_admin/e2e/phase169-journey.spec.js:269–393; 169-BASELINE.md: capture provenance and served/built CSS mismatch check. | closed |
| T-169-15 | Information disclosure | Connected operator UI | high | mitigate | operator/deliveries_list.ex:180–182,253–255; operator/quick_view.ex:109; operator_live.ex:1427–1453,2055–2074; operator_live_test.exs:1203–1204: masking, safe metadata/URL fields and private-content rejection. | closed |
| T-169-16 | Repudiation | API surface classification | low | mitigate | docs/api_stability.md:128–139; mailglass_admin/docs/api_stability.md:133–148; deliveries_test.exs:163–285; timeline_test.exs:112–150: sibling inventory and retained ordering/return assertions. | closed |

## Unregistered Flags

None. Plan 01 explicitly declares none. Synthetic mutation/fault routes are confined to `mailglass_admin/test/support/endpoint_case.ex:76–79,264–298`; later summaries declare no new unmapped surface.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-08 | 17 | 17 | 0 | gsd-security-auditor; persisted by orchestrator |

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks required.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set.

**Approval:** Verified 2026-10-08; phase-level verification remains separate.
