---
phase: 99-inbound-surface
verified: 2026-06-15T05:43:13Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 99: Inbound Surface Verification Report

**Phase Goal:** Apply the same group + page/IA + responsive + flow + a11y treatment to `/ops/mail/inbound` (InboundLive): add an inbound overview tier, rework `RoutingTrace` and `EvidenceCard`, add empty/loading states, fix `text-xl` to token violations, and re-apply the cross-surface uplift to inbound.
**Verified:** 2026-06-15T05:43:13Z
**Status:** passed
**Re-verification:** No - initial verification file; includes the post-`7e52ad74` denied EvidenceCard browser-coverage fix.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | An inbound overview / at-a-glance tier exists, mirrors the operator triage pattern, and is backed by real uncapped tenant summary data. | VERIFIED | `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` renders `data-testid="inbound-overview"` with `InboundMessages`, `No match`, `Accepted`, and `No-match rate`; `InboundLive` assigns `load_inbound_summary/1`; `Summary.summarize/2` uses tenant-scoped aggregate reads with `Tenancy.scope(tenant_id)` and does not call `Records.list_records`. |
| 2 | `RoutingTrace` and `EvidenceCard` are scannable, on-token group layouts with aligned clause grid, mono chips, masked actuals, and locked/reveal affordance. | VERIFIED | `routing_trace.ex` renders `inbound-routing-trace`, `inbound-route-card`, and `inbound-trace-clause`, masks recipient actuals through `Components.mask_recipient/1`, and uses token classes. `evidence_card.ex` keeps raw bytes absent by default, renders raw only in `:revealed`, and renders denied as `bg-base-100 border-warning text-base-content`. |
| 3 | Inbound has coherent empty/loading/error states, token cleanup is complete, and the why-did-inbound-not-route flow is browser-reachable from seed data. | VERIFIED | `records_list.ex` splits no-tenant, truly-empty, and filtered-empty states. `structural.spec.js` covers no-tenant/truly-empty/filtered-empty/detail-error/loading contract and selected/detail flow. `operator.spec.js` covers the why-did-inbound-not-route browser flow. Conformance gates and grep checks found no raw large type or arbitrary tracking violations under `mailglass_admin/lib`. |
| 4 | Inbound meets the same responsive, a11y, and WCAG-AA bar as Operator in light/dark at 390/768/1440, including denied EvidenceCard coverage. | VERIFIED | `structural.spec.js` contains the 390/768/1440 light/dark contrast matrix and now logs into a real `deny-reveal` tenant/session, requires `inbound-evidence-denied`, requires `inbound-evidence-raw` absent, and contrast-checks the denied state. Local rerun passed: `1 passed (29.3s)`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/summary.ex` | Tenant-scoped inbound aggregate summary seam. | VERIFIED | Exists, substantive, uses `record.tenant_id == ^tenant_id`, `Tenancy.scope(tenant_id)`, latest fresh run subquery, provider/search/window filters, and ignores outcome. |
| `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` | Optional admin summary gateway. | VERIFIED | `summary/2` calls `apply(MailglassInbound.Internal.Operator.Summary, :summarize, [filters, opts])`; no direct admin references outside gateway found. |
| `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` | Read-only overview tier. | VERIFIED | Renders stable `inbound-overview` hook and summary labels/values from the summary assign. |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | Inbound IA, summary wiring, responsive/detail state, empty/error routing. | VERIFIED | Uses `<Overview.overview summary={@inbound_summary} />`, mobile filter/detail hooks, synchronous loading contract, valid-UUID guard, and gateway degradation. |
| `mailglass_admin/lib/mailglass_admin/inbound/{routing_trace,evidence_card,filters_form,replay_modal}.ex` | Group layout and token cleanup. | VERIFIED | Components are substantive and covered by component tests; no blocking stub/debt markers found. |
| `mailglass_admin/e2e/{operator,structural}.spec.js` | Browser flow/responsive/WCAG coverage. | VERIFIED | Tests include inbound JTBD flow, responsive grid, empty/error/loading, redacted/revealed/denied evidence states. |
| `mailglass_admin/test/support/{operator_fixtures,endpoint_case}.ex` | Browser seed/login support. | VERIFIED | Seeds a real `deny-reveal` no-match inbound row with evidence/run tenant ownership; `/browser-login` fetches query params, stores `subject_id`, and redirects with `cache-control: no-store`. |
| `mailglass_admin/scripts/check-conformance-advisory.sh` and `.github/workflows/ci.yml` | Fail-closed TYPE-lg/xl and TRACK conformance gate. | VERIFIED | Script counts TYPE/TRACK failures and CI step runs without `continue-on-error` in the same step block. |
| `mailglass_admin/priv/static/app.css` | Rebuilt static bundle. | VERIFIED | `git diff --exit-code priv/static/` passed from `mailglass_admin`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `optional_deps/mailglass_inbound.ex` | `MailglassInbound.Internal.Operator.Summary` | `apply/3` wrapper | WIRED | Manual trace found `apply(MailglassInbound.Internal.Operator.Summary, :summarize, [filters, opts])`. |
| `summary.ex` | tenant scope | aggregate query | WIRED | Query has explicit tenant predicate and `Tenancy.scope(tenant_id)`. |
| `InboundLive` | summary gateway | `load_inbound_summary/1` | WIRED | Blank tenant and gateway-unavailable branches return zero summary; available branch calls `apply(@gateway, :summary, [summary_filters, []])` excluding outcome. |
| `InboundLive` | `Overview.overview/1` | rendered component | WIRED | Template renders `<Overview.overview summary={@inbound_summary} />`. |
| `RoutingTrace` | `mask_recipient/1` | recipient actual masking | WIRED | Recipient actuals call `Components.mask_recipient(actual)`. |
| `structural.spec.js` | `endpoint_case.ex` and fixtures | denied browser auth/session | WIRED | Test uses `subject_id=deny-reveal`, `tenant_id=deny-reveal`; auth denies `:reveal_raw` for that subject/tenant. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `Overview.overview/1` | `@summary` | `InboundLive.load_inbound_summary/1` -> optional gateway -> `Summary.summarize/2` | Yes | FLOWING |
| `RoutingTrace.routing_trace/1` | `@trace` | `routing_trace_for/2` -> `apply(@gateway, :explain_routes, [inbound_router, record])` for `:no_match` detail | Yes | FLOWING |
| `EvidenceCard.evidence_card/1` | `@evidence`, `@reveal_state` | Tenant-scoped detail read model and LiveView `authorize_reveal/1` event | Yes | FLOWING |
| Browser denied state | selected no-match row | `/ops/browser-reset` fixture -> `deny-reveal` tenant row -> `/ops/browser-login?subject_id=deny-reveal` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Denied EvidenceCard WCAG matrix covers light/dark 390/768/1440 | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 e2e/structural.spec.js --grep "Inbound: WCAG AA contrast matrix"` | `1 passed (29.3s)` | PASS |
| Inbound LiveView/component tests | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` | `60 tests, 0 failures` | PASS |
| Optional dependency compile lane | `cd mailglass_admin && mix compile --warnings-as-errors --no-optional-deps` | exit 0 | PASS |
| Normal admin compile lane | `cd mailglass_admin && mix compile --warnings-as-errors` | exit 0 | PASS |
| Hard conformance gate | `cd mailglass_admin && bash scripts/check-conformance.sh` | `OK: design-system conformance clean.` | PASS |
| Advisory conformance gate now fail-closed | `cd mailglass_admin && bash scripts/check-conformance-advisory.sh` | `OK: advisory design-system conformance clean.` | PASS |
| Static CSS bundle clean | `cd mailglass_admin && git diff --exit-code priv/static/` | exit 0 | PASS |

### Probe Execution

No phase-declared or conventional `scripts/*/tests/probe-*.sh` probes were found. Step 7c skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| GROUP-02 | Plans 99-01, 99-02, 99-04, 99-05 | Inbound overview / at-a-glance tier exists, mirroring operator support-card triage. | SATISFIED | Summary seam, optional gateway, Overview component, `InboundLive` wiring, and browser tests are present and passing. |
| GROUP-03 | Plans 99-03, 99-04, 99-05 | Inbound `RoutingTrace` and `EvidenceCard` are scannable, on-token group layouts. | SATISFIED | RoutingTrace grid/chips/masking and EvidenceCard redacted/revealed/denied states exist and are covered by component plus browser contrast tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | - | - | - | No unresolved `TBD`/`FIXME`/`XXX`, placeholder implementation, or hardcoded-empty data path was found in phase-modified source files. Empty-list matches were legitimate render branches or fixture setup. |

### Human Verification Required

None. The phase goal is covered by deterministic source inspection, ExUnit/component tests, conformance scripts, compile gates, and Playwright browser checks.

### Gaps Summary

No blocking gaps found. The prior denied EvidenceCard browser-coverage gap is closed in code: the structural contrast matrix now exercises a real denied browser session and fails if the denied state is absent or raw evidence appears.

---

_Verified: 2026-06-15T05:43:13Z_
_Verifier: the agent (gsd-verifier)_
