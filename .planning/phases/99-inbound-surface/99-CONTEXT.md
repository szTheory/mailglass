# Phase 99: Inbound Surface - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 99 uplifts the existing `mailglass_admin` inbound operator surface at
`/ops/mail/inbound`. The work adds a read-only inbound overview tier, brings the
Inbound master/detail IA up to the Phase 98 Operator contract, reworks
`RoutingTrace` and `EvidenceCard` into scannable on-token group layouts, adds
coherent empty/loading/error coverage, clears inbound typography/token violations,
and verifies the why-did-inbound-not-route JTBD flow.

This phase does not add a new route, product capability, public inbound API,
provider integration, or core/inbound functional feature. The only sanctioned
non-inbound edit is minimal conformance cleanup needed to harden the existing
admin typography/tracking gate, as described in D-14.
</domain>

<decisions>
## Implementation Decisions

### Scope / Surface Contract

- **D-01:** Build on the existing `MailglassAdmin.InboundLive` mounted at
  `/ops/mail/inbound` inside the existing operator shell. Do not create a
  sibling LiveView, router path, or product feature. All inbound package access
  continues through `MailglassAdmin.OptionalDeps.MailglassInbound` and guarded
  runtime `apply/3`; `MailglassAdmin` must still compile cleanly when the
  optional inbound package is absent.

### Inbound Overview / At-a-Glance Tier

- **D-02:** Add an inbound overview tier before the records list at 390px and
  above the list column at `>=768px`, matching `IA-LD-09`. It shows exact
  tenant-scoped counts for the active time window: total InboundMessages, counts
  by outcome (`:no_match`, `:accept`, `:reject`, `:bounce`, `:failed`, with
  `:ignore` included if present), and no-match rate.
- **D-03:** Do not derive overview totals from `list_records/2`; that read model
  is limited to 50 by default and 100 max, so list-derived totals can lie. Add a
  narrow internal operator summary seam in `mailglass_inbound` and expose it via
  `MailglassAdmin.OptionalDeps.MailglassInbound`. The seam is internal/admin
  only, tenant-scoped, and not part of the public `mailglass_inbound` stable API.
- **D-04:** The summary should respect `tenant_id`, `provider`, `search`, and
  `window_hours`. It should not apply the selected `outcome` filter to the
  denominator/breakdown; the outcome select narrows the list, while the overview
  explains the current tenant/window distribution.

### IA / Responsive Layout

- **D-05:** Reapply the Phase 98 Operator layout contract to Inbound:
  - Filters are wrapped in a 390px `Phoenix.LiveView.JS.toggle` disclosure and
    remain always visible at `>=768px`.
  - Master/detail uses `md:grid-cols-[40%_60%]` and
    `min-[1440px]:!grid-cols-[33%_67%]`.
  - At 390px, the records list fills the width. Selecting an InboundMessage hides
    the list and reveals detail in place with a "Back to inbound records"
    affordance. This is a patch to the existing URL state, not a new route.
  - When no record is selected, `orientation_strip surface={:inbound}` remains
    the right-column/detail-pane orientation content.
- **D-06:** Add stable `data-testid` hooks for the new/uplifted groups following
  the existing kebab pattern: `inbound-overview`,
  `inbound-filters-toggle`, `inbound-detail-back`,
  `inbound-routing-trace`, `inbound-evidence-card`, and existing list/detail
  hooks preserved.

### RoutingTrace / EvidenceCard Group Layouts

- **D-07:** Rework `RoutingTrace` in place. It remains read-only, rendered only
  for `:no_match`, and never owns raw-source reveal behavior. Render route
  clauses as an aligned scannable grid with expected and actual values as mono
  chips on `bg-base-100` / surface-sunken inside the `bg-base-200` card. Keep
  first-failing emphasis on `border-l-4 border-error` and route-level
  `badge-outline badge-error` per `STATE-LD-18`. Mask recipient actuals through
  `Components.mask_recipient/1`; do not reimplement matcher semantics in the
  view.
- **D-08:** Rework `EvidenceCard` in place as the locked/info reveal affordance.
  Preserve the existing `:redacted`, `:revealed`, and `:denied` state model and
  `:reveal_raw` authorization seam. Present verification facts and redaction
  metadata as mono key/value chips on surface-sunken. Keep raw payload read-only
  and absent from default HTML. Drop `btn-sm` on inbound reveal/close controls if
  needed so `min-h-11` is the effective touch target.

### Copy / Empty / Loading / Error States

- **D-09:** Use the Phase 96 copy locks where they are in Phase 99 scope:
  - Inbound list empty heading: "No InboundMessages match these filters"
    (`COPY-LD-03`).
  - Inbound select prompt: "Select an InboundMessage to inspect its Mailbox
    routing, execution timeline, and raw evidence." (`COPY-LD-16`).
  - Filter label "Window" becomes "Time window" (`COPY-LD-10`).
  - Keep the banned-copy sweep: no "Oops", "Whoops", "Uh oh", or generic
    "Something went wrong" strings on the inbound surface.
- **D-10:** Split empty states like Phase 98 did for Operator: no tenant selected,
  tenant has no inbound history, and active filters return no results. Filtered
  empty gets a reset/clear action; truly empty does not pretend clearing filters
  will create data. Loading state can stay synchronous unless implementation
  adopts async assigns; if explicit loading UI is added, use
  "Loading InboundMessages..." per `COPY-LD-15`.

### Seed / Flow Verification

- **D-11:** Extend the single existing browser seed path
  `OperatorFixtures.seed_browser_scenario!/0`; do not add per-state seed scripts.
  The seeded tenant must cover happy, error, boundary, and missing-evidence
  inbound states by URL params: at least `:accept`, `:no_match`, `:reject`,
  `:bounce`, `:failed`, no execution runs, missing evidence, suppression-flagged,
  filtered-empty, truly-empty/no-tenant, long subject/content, and a detail-error
  `?inbound_id=` path. Preserve row-index stability for existing operator tests.
- **D-12:** Extend Playwright structural coverage in the existing
  `operator_browser_gate` lane rather than adding a harness. Add inbound-specific
  assertions for overview visibility, exact one `h1`, 390/768/1440 grid contract,
  mobile back affordance, routing-trace scannability at 390px, evidence redaction,
  empty-state variants, and the why-did-inbound-not-route JTBD flow.

### Typography / Gate Hardening

- **D-13:** Remove every remaining inbound arbitrary `tracking-[0.08em]` and
  raw `text-lg/xl/2xl/...` usage. Use `text-label uppercase font-bold
  text-secondary` for labels and `text-heading` where heading scale is needed.
  Do not add or edit `brandbook/tokens.css` for tracking in this phase; the
  later locked pattern is to remove arbitrary tracking and rely on the existing
  semantic type classes.
- **D-14:** Flip `mailglass_admin/scripts/check-conformance-advisory.sh` from
  advisory to fail-closed after cleanup, and remove `continue-on-error: true`
  from the CI step. If the only remaining violation is the Preview
  `preview_live.ex` `text-xl`, perform the minimal token replacement needed for
  the gate and leave Preview IA/dark-mode work to Phase 100.

### Codex's Discretion

- Exact internal module/file name for the inbound summary read model, provided it
  stays internal/operator-scoped and tenant-safe.
- Exact visual copy for overview stat labels, provided the data points above are
  present and the copy follows the Phase 96 thoughtful-maintainer voice.
- Exact shape of the Playwright assertions, provided they exercise the Phase 99
  acceptance criteria and run in the existing operator browser gate.

### Folded Todos

None folded into Phase 99.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 99 goal and success criteria.
- `.planning/REQUIREMENTS.md` - v1.11 scope locks and GROUP-02/GROUP-03 requirements.
- `.planning/research/v1.11/SUMMARY.md` - canonical locked decisions for IA, state, dark mode, motion, and copy.
- `.planning/RATCHET-GAP-REGISTER.md` - active v1.11 gap register and anti-churn citation contract.
- `.planning/phases/98-operator-deliveries-surface/98-CONTEXT.md` - Operator layout/seed/test pattern Phase 99 should mirror.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - existing inbound LiveView, URL state, optional gateway calls, and render layout.
- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` - existing routing trace component to uplift.
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` - existing raw-source evidence/reveal component to uplift.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - inbound list, empty branch, row selection semantics.
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` - inbound filter labels and controls.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - inbound modal type-scale and touch-target cleanup.
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` - runtime gateway boundary for optional inbound access.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - tenant-scoped list read model and current limit behavior.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex` - tenant-scoped detail read model.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` - closed inbound outcome set.
- `mailglass_admin/test/support/operator_fixtures.ex` - single browser seed path to extend.
- `mailglass_admin/e2e/structural.spec.js` - structural assertions and Phase 98 grid pattern to extend.
- `.github/workflows/ci.yml` - conformance gate wiring and operator browser gate.
- `mailglass_admin/scripts/check-conformance-advisory.sh` - advisory typography/tracking gate to harden.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Operator.Shell.shell/1` already provides the active Inbound nav state, dark/light toggle, orientation strip, tenant chip, flash region, and surface paths.
- `MailglassAdmin.InboundLive` already owns URL-preserved filters, selected `inbound_id`, `dark_chrome`, reveal state, tenant-scoped list/detail/timeline loading, and replay confirm flow.
- Existing inbound components are already split into focused files:
  `RecordsList`, `DetailHeader`, `Timeline`, `RoutingTrace`, `EvidenceCard`,
  `ReplayModal`, and `FiltersForm`.
- The optional inbound gateway is already the sanctioned seam for read models,
  route explanation, and replay.
- Phase 98's Operator implementation is the live pattern for responsive
  master/detail, mobile filter disclosure, group testids, and Playwright grid
  assertions.

### Established Patterns

- Admin UI uses semantic daisyUI/Tailwind classes backed by the canonical
  `--mg-*` token system. Avoid hex colors, arbitrary tracking, raw type-scale
  utilities, off-grid gap utilities, and faux-bold weights.
- Route state is URL state. Selection and filters use `push_patch`, not new
  routes.
- Optional inbound access is guarded by `Code.ensure_loaded?` plus gateway
  `available?/0`; direct `MailglassInbound.*` references from admin runtime code
  are avoided.
- Browser verification uses one deterministic seed from
  `OperatorFixtures.seed_browser_scenario!/0`, reset through `/ops/browser-reset`.
- `priv/static/app.css` is a committed generated artifact; any CSS-affecting
  markup/class changes require `mix mailglass_admin.assets.build` and a clean
  `git diff --exit-code priv/static/`.

### Integration Points

- New overview data connects from `InboundLive.assign_inbound_state/3` to a new
  internal inbound summary read model through `OptionalDeps.MailglassInbound`.
- Responsive/detail behavior connects to the existing `inbound_id` URL param and
  should mirror Operator's `max-md:hidden` list behavior and back patch.
- `RoutingTrace` continues to receive trace data from
  `OptionalDeps.MailglassInbound.explain_routes/2`; only the presentation changes.
- `EvidenceCard` continues to receive authorization state from
  `InboundLive.authorize_reveal/1`; no new auth action or adapter is introduced.
- The conformance hardening touches `ci.yml` and the advisory script after the
  markup cleanup is complete.
</code_context>

<specifics>
## Specific Ideas

- Inbound overview should feel like the Operator support-card triage pattern, but
  read-only: a compact stat row/card cluster for "InboundMessages", "No match",
  "Accepted", and "No-match rate" is enough.
- The `RoutingTrace` clause layout should compare `Expected` and `Actual` in
  fixed columns at wide widths and stack cleanly at 390px. Use mono chips for
  matcher values, actual values, and header facts.
- The current list/detail structure already has `inbound-master-detail`,
  `inbound-records-list-card`, and `inbound-detail-column`; preserve these hooks
  and add only the missing hooks needed for new assertions.
- Keep PII minimization load-bearing: recipient/sender actuals stay masked,
  raw payload bytes stay absent until reveal is granted, and no new overview stat
  exposes raw addresses or subjects.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 99 scope.

### Reviewed Todos (not folded)

No matching pending todos were found for Phase 99.
</deferred>
