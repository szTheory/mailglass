---
phase: 98
slug: operator-deliveries-surface
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-14
updated: 2026-06-14
---

# Phase 98 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| operator URL params -> LiveView assigns | `delivery_id`, `status`, `provider`, `tenant_id`, `event`, and `window_hours` are untrusted query params normalized before render, filtering, and selection. | Operator navigation/filter strings; no secrets. |
| LiveView client events -> server handlers | Operator clicks submit delivery selection, support exemplar, filters, and replay events into LiveView handlers. | Delivery IDs, filter params, replay target IDs. |
| client viewport / JS.toggle -> render behavior | Mobile filter disclosure and list/detail layout are client-visible behavior without server state mutation. | Presentation state only. |
| seed -> test database | Browser seed writes deterministic test data into the truncated TestRepo database only. | Test deliveries, events, webhook rows, suppression state. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status | Evidence |
|-----------|----------|-----------|-------------|------------|--------|----------|
| T-98-01 | Denial of Service | `suppression_card.body_copy/1`, `headline/1` | mitigate | Add catch-all clauses and safe map reads so novel-shape suppression maps cannot crash the LiveView. | closed | `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:24`, `:37`, `:54`, `:62`; `mailglass_admin/test/mailglass_admin/operator_live_test.exs:512` |
| T-98-02 | Denial of Service | OperatorLive selected-delivery handlers | mitigate | Use nil-safe selected delivery reads and the existing no-selected replay branch. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:153`, `:197`, `:224`, `:240`; grep confirmed no `socket.assigns.selected_delivery.id` implementation reads. |
| T-98-03 | Tampering | `status_badge/1` attr validation | accept | Allow `:suppressed` as an input atom while keeping phantom atoms on the neutral fallback behavior. | closed | `mailglass_admin/lib/mailglass_admin/components.ex:158`, `:230`, `:255`, `:280`; accepted risk AR-98-03. |
| T-98-04 | Information Disclosure | `filters_active?/1` comparison | accept | Compare normalized filter params and treat tenant/window as scope/time, not content filters. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:521`, `:526`; accepted risk AR-98-04. |
| T-98-05 | Tampering | Mobile filter disclosure | mitigate | Use stateless `JS.toggle` and no server-side toggle event or socket assign. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:371`, `:380`; grep confirmed no `handle_event("toggle_filters"...)`. |
| T-98-06 | Information Disclosure | Mobile detail back affordance | mitigate | Reuse `build_path/4`; clear only `delivery_id`; blank-strip query params and preserve normalized filter scope. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:468`, `:735`, `:742`, `:747` |
| T-98-07 | Information Disclosure | Suppression/replay copy | accept | COPY-LD-14 copy uses domain text; list rows mask recipients via the shared masking primitive. | closed | `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:14`, `:43`, `:56`; `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:65`; `mailglass_admin/lib/mailglass_admin/components.ex:283`; accepted risk AR-98-07. |
| T-98-08 | Tampering | Conformance advisory script | mitigate | Do not flip the advisory gate; guard operator tracking cleanup with a scoped ExUnit assertion. | closed | `mailglass_admin/test/mailglass_admin/operator_live_test.exs:588`; `git diff --quiet scripts/check-conformance-advisory.sh` was recorded as OK in `98-03-SUMMARY.md`. |
| T-98-09 | Information Disclosure | Seed recipient data / PII | mitigate | Use non-PII `@example.com` seed data, preserve tenant scoping, and mask recipient display. | closed | `mailglass_admin/test/support/operator_fixtures.ex:132`, `:179`; `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:65`; `mailglass_admin/lib/mailglass_admin/components.ex:283` |
| T-98-10 | Information Disclosure | Detail-error reveal path | accept | Missing delivery IDs resolve to generic `:not_found` detail state without echoing the missing ID in the error text. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:438`, `:585`; accepted risk AR-98-10. |
| T-98-11 | Denial of Service | `?status=` atom-table exhaustion | accept | `cast_enum/2` uses `String.to_existing_atom/1`, allowlist membership, and rescues invalid atoms to `nil`. | closed | `mailglass_admin/lib/mailglass_admin/operator_live.ex:767`; accepted risk AR-98-11. |
| T-98-12 | Tampering | Frozen LLM baseline | mitigate | Add structural/e2e coverage without changing frozen baseline artifacts. | closed | `mailglass_admin/e2e/structural.spec.js:273`; `git diff --quiet docs/ui-baseline-scores.json test/mailglass_admin/ratchet_baseline_test.exs` returned 0. |
| T-98-SC | Tampering | Dependency/package installation surface | mitigate | No package installs or dependency manifest/lockfile edits in Phase 98. | closed | Phase commits touched only planning, operator source/tests/e2e/layout/static CSS files; no `mix.exs`, lockfile, `package.json`, or package lock file appeared in `git show --name-only` for Phase 98 commits. |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-98-03 | T-98-03 | `:suppressed` is an allowlisted badge input but intentionally retains neutral fallback output, avoiding a new status presentation contract. | Phase 98 plan-time threat model | 2026-06-14 |
| AR-98-04 | T-98-04 | `filters_active?/1` only compares normalized assigns already visible to the operator; excluding tenant/window avoids false filtered-empty states and does not read additional data. | Phase 98 plan-time threat model | 2026-06-14 |
| AR-98-07 | T-98-07 | Suppression/replay copy is locked UI text and does not introduce new data disclosure beyond existing masked recipient paths. | Phase 98 plan-time threat model | 2026-06-14 |
| AR-98-10 | T-98-10 | Generic detail-not-found behavior is acceptable because nonexistent IDs are not echoed and no extra detail is revealed. | Phase 98 plan-time threat model | 2026-06-14 |
| AR-98-11 | T-98-11 | Existing atom casting is acceptable because it uses `String.to_existing_atom/1`, allowlist membership, and invalid input rescue; the phase did not weaken it. | Phase 98 plan-time threat model | 2026-06-14 |

---

## Unregistered Flags

No `## Threat Flags` sections were present in the Phase 98 summary files, and the audit did not identify an unregistered implementation-time security flag.

---

## Security Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Threats found | 13 |
| Closed | 13 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-14 | 13 | 13 | 0 | Codex gsd-secure-phase |

---

## Verification Evidence

- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` - 30 tests, 0 failures.
- `cd mailglass_admin && bash scripts/check-conformance.sh` - OK.
- `cd mailglass_admin && mix mailglass_admin.assets.build` - OK.
- `cd mailglass_admin && git diff --exit-code priv/static/` - OK.
- `cd mailglass_admin && git diff --quiet docs/ui-baseline-scores.json test/mailglass_admin/ratchet_baseline_test.exs` - returned 0.
- Grep confirmed no implementation matches for `socket.assigns.selected_delivery.id`, `handle_event("toggle_filters"...)`, or explicit `status_class/status_icon/status_label(:suppressed)` clauses.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-14
