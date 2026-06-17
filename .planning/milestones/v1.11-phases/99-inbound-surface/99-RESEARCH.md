---
phase: 99
slug: inbound-surface
status: complete
created: 2026-06-14
requirements: GROUP-02, GROUP-03
---

# Phase 99: Inbound Surface - Research

## Objective

Answer: what does planning need to know before uplifting `/ops/mail/inbound`?

Phase 99 is an admin UI uplift over the existing `MailglassAdmin.InboundLive`.
It should not add a new route, public inbound API, provider integration, or core
feature. The one sanctioned package boundary change is a narrow internal
operator summary read model in `mailglass_inbound`, surfaced through
`MailglassAdmin.OptionalDeps.MailglassInbound`, so the inbound overview can show
truthful tenant/window counts without deriving them from the capped list read
model.

## Current Surface Shape

The current inbound surface is structurally close to pre-Phase-98 Operator:

- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` owns URL filter state,
  selected `inbound_id`, detail/timeline/routing/evidence loading, replay modal
  state, theme switching, and optional gateway access.
- The filter form is always visible and has no 390px `JS.toggle` disclosure.
- The master/detail grid still uses
  `lg:grid-cols-[minmax(22rem,28rem)_1fr]`, not the Phase 98
  `md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]` contract.
- At 390px, selecting an inbound row does not currently hide the list and reveal
  detail in place with a back affordance.
- The selected/detail empty prompt still says "inbound record" and "raw source"
  instead of the Phase 96 locked `COPY-LD-16` wording.
- `RoutingTrace` and `EvidenceCard` are split into the right components, but
  their group layouts are still simple stacked rows and include arbitrary
  `tracking-[0.08em]`.
- `RecordsList` has one generic empty branch. Phase 99 needs no-tenant,
  truly-empty, and filtered-empty distinctions.

## Read Model Findings

### Existing list read model

`mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` is the
tenant-scoped list read model. It applies:

- required tenant guard returning `[]` for blank/missing tenant;
- provider, outcome, window, and search filters;
- `Tenancy.scope/2` plus explicit `tenant_id` where clauses;
- latest fresh `ExecutionRun` projections for outcome and mailbox;
- default limit 50 and max limit 100.

This read model is not a safe source for overview totals. It is both capped and,
when the UI outcome filter is selected, intentionally narrowed. Phase 99 needs a
separate summary read model.

### Summary seam requirements

Add an internal/admin-only summary module, most naturally beside the current
operator read models:

- likely path:
  `mailglass_inbound/lib/mailglass_inbound/internal/operator/summary.ex`
- test path:
  `mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs`
- gateway wrapper:
  `MailglassAdmin.OptionalDeps.MailglassInbound.summary/2` or
  `inbound_summary/2`

The summary must accept the same base filter map shape used by `list_records/2`:

- `tenant_id`
- `provider`
- `search`
- `window_hours` / `recent_window_hours`

It must not apply the selected `outcome` filter to the denominator or outcome
breakdown. The outcome select narrows the list; the overview explains the
tenant/window distribution.

The summary should count total `InboundRecord` rows in the scoped window and
break down latest fresh `ExecutionRun.outcome` by the closed set from
`ExecutionRun.__outcomes__/0`: `:no_match`, `:accept`, `:ignore`, `:reject`,
`:bounce`, `:failed`. Records without a fresh run should either remain outside
the outcome breakdown while still contributing to `total`, or be surfaced as a
separate `:pending`/`nil` internal field only if the UI has a clear label. The
Phase 99 context only requires the closed outcome set, with `:ignore` included
if present.

## UI Implementation Findings

### Phase 98 analog to mirror

`mailglass_admin/lib/mailglass_admin/operator_live.ex` already contains the
responsive pattern Phase 99 should copy in place:

- mobile-only filter toggle:
  `phx-click={JS.toggle(to: "#operator-filter-panel")}`
- `data-testid="operator-filters-toggle"`
- filter panel class `hidden md:block`
- master/detail grid:
  `md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]`
- list card hidden on mobile when selected:
  `@selected_delivery && "max-md:hidden"`
- detail back link:
  `patch={build_path(@base_path, @filter_params, nil, @dark_chrome)}`
- detail column ordering:
  `is_nil(@selected_delivery) && "order-first md:order-none"`

Inbound should mirror those patterns with inbound-specific ids and copy, not
invent a new IA.

### Overview tier

The overview belongs between filters and the master/detail split. At 390px it
must render before the records list; at `>=768px` it appears above the list
column. Planning should avoid a decorative dashboard. A compact read-only card
cluster is enough:

- total InboundMessages in the tenant/window;
- no-match count;
- accepted count;
- no-match rate;
- compact secondary breakdown for reject/bounce/failed/ignore if present.

Use `data-testid="inbound-overview"`. Keep the group flat:
`bg-base-200 border border-base-300 rounded-box`, with inner mono chips on
`bg-base-100` for values that need scanability.

### RoutingTrace

`mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` already protects
the core semantics:

- only the upstream matcher produces verdicts;
- recipient actuals are masked through `Components.mask_recipient/1`;
- first failing clause is identified in view-only decoration;
- the component is read-only and rendered only by `InboundLive` for `:no_match`.

The planning work should focus on presentation:

- keep `data-testid="inbound-routing-trace"`;
- preserve `data-testid="inbound-route-card"` and
  `data-testid="inbound-trace-clause"` if possible;
- replace arbitrary tracking labels with `text-label uppercase font-bold
  text-secondary`;
- use an aligned grid for clause rows at wider widths and stack cleanly at
  390px;
- render Expected and Actual values as mono chips inside `bg-base-100`;
- keep `border-l-4 border-error` on first failing clause and
  `badge-outline badge-error` on route-level failure.

### EvidenceCard

`mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` already has the
right state model:

- `:redacted`
- `:revealed`
- `:denied`
- reveal via `phx-click="reveal_raw"` and the existing `:reveal_raw` auth seam;
- raw payload absent from default HTML and read-only when revealed.

The uplift should:

- keep `data-testid="inbound-evidence-card"`,
  `inbound-evidence-reveal`, `inbound-evidence-redacted`,
  `inbound-evidence-denied`, and `inbound-evidence-raw`;
- convert provider/payload/header/verification facts into mono key/value chips
  on `bg-base-100`;
- remove all `tracking-[0.08em]`;
- drop `btn-sm` on reveal/close controls if needed so `min-h-11` is effective;
- keep the raw `<pre>` scroll region bounded and read-only.

### Copy and empty states

Locked copy from `.planning/research/v1.11/SUMMARY.md`:

- `COPY-LD-03`: "No InboundMessages match these filters"
- `COPY-LD-10`: filter label "Window" becomes "Time window"
- `COPY-LD-16`: "Select an InboundMessage to inspect its Mailbox routing,
  execution timeline, and raw evidence."

Phase 99 should split empty states:

- no tenant selected: cause-naming empty state in the master/list area, no fake
  "clear filters" recovery;
- tenant has no inbound history: truly empty state, no clear action;
- active filters return no records: filtered empty state with a clear/reset
  action;
- selected id not found: existing detail-error band can stay, but copy should be
  banned-copy clean.

## Typography And Gate Findings

Current inbound violations from `rg`:

- `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
  has `tracking-[0.08em]` on the records-list heading.
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`
  has five `tracking-[0.08em]` filter labels and still says "Window".
- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex`
  has one `tracking-[0.08em]` clause label.
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex`
  has five `tracking-[0.08em]` labels.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex`
  has `text-lg` on its `h2`.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex`
  has the remaining `text-xl` violation; Phase 99 may perform the minimal
  token replacement if this is the only blocker before hardening the advisory
  gate.

`mailglass_admin/scripts/check-conformance-advisory.sh` currently always exits
0 and `.github/workflows/ci.yml` keeps the corresponding step
`continue-on-error: true`. After inbound cleanup and any minimal Preview
type-scale cleanup, Phase 99 should make this fail closed and remove the CI
continue-on-error flag.

## Seed And Browser Gate Findings

The single seed path is
`mailglass_admin/test/support/operator_fixtures.ex:seed_browser_scenario!/0`.
It already creates one inbound record with an `:accept` fresh run for a prior
operator browser regression. Phase 99 needs to extend that same seed, not add a
new seed script.

Needed seeded states:

- `:accept`
- `:no_match`
- `:reject`
- `:bounce`
- `:failed`
- record with no execution runs;
- record with missing evidence;
- suppression-flagged record;
- filtered-empty URL;
- truly-empty/no-tenant URL;
- long subject/content;
- detail-error `?inbound_id=` path.

Existing e2e coverage:

- `mailglass_admin/e2e/operator.spec.js` only checks inbound detail id and
  inbound orientation strip.
- `mailglass_admin/e2e/structural.spec.js` checks generic inbound nav, body
  weight, reduced-motion heading, focus ring on first link, and accent
  non-leakage. It does not yet assert inbound overview, responsive grid,
  mobile back affordance, routing trace scanability, evidence redaction, or the
  why-did-inbound-not-route JTBD.

Add inbound assertions to the existing operator browser gate
(`npm run test:operator-browser`), not a new harness.

## Security And Safety Notes

Planning must preserve these invariants:

- Admin runtime code must still compile when `mailglass_inbound` is absent.
  All optional inbound calls go through guarded `apply/3` in
  `MailglassAdmin.OptionalDeps.MailglassInbound`.
- Summary and detail/list reads must remain tenant-scoped with both explicit
  `tenant_id` predicates and `Tenancy.scope/2`.
- Search input must stay bound/escaped, following the existing
  `Records.escape_like/1` pattern.
- Overview stats must not expose raw addresses, subjects, headers, raw payload
  bytes, or cross-tenant counts.
- RoutingTrace must keep recipient actuals masked and must not reimplement
  matcher semantics.
- EvidenceCard must keep raw payload absent from default HTML; reveal remains
  capability-gated and read-only.

Every Phase 99 `PLAN.md` should include a `<threat_model>` block because the
workflow security gate is enabled by default. The main threats are cross-tenant
summary leakage, optional-dependency compile failure, raw evidence exposure, PII
leakage in routing trace, misleading capped totals, and conformance-gate
hardening before violations are cleaned.

## Recommended Planning Slices

1. Inbound summary read model and gateway seam.
   - Files: `mailglass_inbound/internal/operator/summary.ex`,
     summary tests, optional gateway, `InboundLive` assign plumbing.
   - Covers truthful overview counts and tenant safety.

2. Inbound IA and overview composition.
   - Files: `inbound_live.ex`, possibly `inbound/overview.ex` if extracting a
     component is clearer.
   - Covers filter disclosure, responsive grid, mobile detail back, overview
     placement, and split empty states.

3. RoutingTrace and EvidenceCard group uplift plus inbound type/copy cleanup.
   - Files: `routing_trace.ex`, `evidence_card.ex`, `filters_form.ex`,
     `replay_modal.ex`, and limited `inbound_live.ex`.
   - Covers GROUP-03, copy locks, and most conformance cleanup.

4. Seed, Playwright, bundle, and conformance hardening.
   - Files: `operator_fixtures.ex`, `operator.spec.js`,
     `structural.spec.js`, `.github/workflows/ci.yml`,
     `check-conformance-advisory.sh`, generated `priv/static/app.css`, plus
     minimal Preview type-token cleanup if it remains the only violation.
   - Covers flow validation, responsive assertions, and fail-closed gates.

## Validation Architecture

Automated validation should combine unit/read-model tests, LiveView tests,
browser structural assertions, and conformance gates:

- `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/summary_test.exs --warnings-as-errors`
  verifies tenant scoping, blank tenant behavior, provider/search/window filters,
  outcome breakdown, no outcome-filter denominator narrowing, and records beyond
  the `list_records/2` cap.
- `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors`
  verifies optional gateway wrapper use, overview assigns/rendering, empty-state
  branches, copy locks, reveal-state behavior, and no-optional-deps safety where
  practical.
- `cd mailglass_admin && npm run test:operator-browser` verifies existing
  operator gate plus new inbound assertions for overview visibility, one `h1`,
  390/768/1440 grid ratios, mobile back affordance, routing-trace scanability,
  evidence redaction, empty states, and why-did-inbound-not-route flow.
- `cd mailglass_admin && mix mailglass_admin.assets.build` followed by
  `git diff --exit-code priv/static/` verifies the committed CSS bundle.
- `bash mailglass_admin/scripts/check-conformance-advisory.sh` should fail
  closed after cleanup, and CI should no longer mark that step
  `continue-on-error: true`.
- `cd mailglass_admin && mix verify.preview` remains the broad admin package
  gate because it compiles with no optional deps, runs tests, builds assets, and
  checks bundle cleanliness.

## Open Planning Risks

- No `99-UI-SPEC.md` exists yet. The plan-phase UI gate should stop before
  planning unless `$gsd-ui-phase 99` is run or the operator explicitly replans
  with `--skip-ui`.
- The conformance gate's script comments are stale: they still mention defining
  a tracking token, while the locked Phase 96 decision says remove arbitrary
  tracking and rely on `text-label uppercase font-bold text-secondary`.
- Summary-count semantics for records with no fresh execution run need a
  deliberate test assertion so the UI does not silently misclassify pending/no-run
  states.
- Browser seed expansion must preserve existing row-index stability in operator
  tests.

## RESEARCH COMPLETE
