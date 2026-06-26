# Phase 113: Data-Display - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix LiveView admin data-display components, responsive tables, KPI cards, data states, status encoding, long-value handling  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Responsive Data Lists

- **D-01:** Deliveries and inbound records keep the existing master-detail URL and selection
  behavior, but their current list-only row markup is upgraded into semantic data tables at
  `>=768px` and card/list presentations below `768px`.
- **D-02:** The table/card implementation must preserve Phase 112 pagination behavior: result
  count always visible, pagination chrome only for multiple pages, and disabled boundary controls.
  Do not re-litigate or fake count/page metadata.

### Canonical KPI And Severity Encoding

- **D-03:** Phase 113 reuses `MailglassAdmin.Components.stat_card/1` and `status_badge/1` as the
  canonical KPI and status primitives. Planning should widen certification and migration coverage,
  not create new stat/status components.
- **D-04:** Severity/status remains icon + visible label + color. Color-only, icon-only, and bare
  placeholder states are regressions. "All clear" must render as a real, readable state.

### Distinct Data States

- **D-05:** DATA-03 is satisfied with distinct reusable data-state templates for no-data,
  unavailable/error, permission-denied, and stale-data. Current true-empty, filtered, and no-tenant
  branches can seed the no-data variants, but permission/stale/unavailable must not collapse into
  generic empty/error copy.
- **D-06:** Live-refresh mechanics are out of scope. Stale-data means the admin can honestly render
  a stale/unavailable state when the current read/display data is known to be stale or unavailable;
  it does not require polling, streams, or auto-refresh.

### Long Real-World Values And Proof

- **D-07:** Long values are handled with truncate + tooltip/title, expansion, wrapping, or another
  deterministic pattern chosen per field. UUIDs, tenant ids, provider ids, module/function names,
  URLs, subjects, non-ASCII names, and timestamps must never overflow, chop incoherently, or force
  horizontal scrolling.
- **D-08:** Proof stays inside existing repo-local lanes: component tests, gallery specimens,
  Playwright structural assertions, conformance gates, and realistic demo/test data. No pixel diff,
  screenshot baseline, runtime dependency, or new asset pipeline is introduced for this phase.

### the agent's Discretion

- Exact table column set and card field ordering, provided the operator can scan status, recipient
  or mailbox, tenant, provider, event/outcome, and timestamp without losing selection semantics.
- Exact shared component shape for data-state templates, if planning finds a small reusable helper
  cleaner than page-local markup.
- Exact tooltip/truncation implementation per field, provided accessible names and long-value proof
  hold across light/dark/system and mobile/desktop breakpoints.

### Folded Todos

None - `todo.match-phase 113` returned 0 matches.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

None - analysis stayed within Phase 113 scope.

### Reviewed Todos (not folded)

None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Deliveries and Inbound lists render as tables >=768px and transform to card/list layout <768px. | Current list modules render `ul` row buttons; plan should add desktop semantic tables plus mobile cards fed by the same assigns and preserving `phx-click`, `phx-value-id`, `aria-current`, `aria-selected`, pagination, and result-count behavior. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `.planning/phases/113-data-display/113-CONTEXT.md`] |
| DATA-02 | Every stat/KPI card uses canonical `stat_card`; no clipped labels, bare placeholders, or fake all-clear state. | `Components.stat_card/1` already provides label title, value title, no-wrap tabular value, explicit empty/loading/unavailable text, and severity icon+label+color; plan should certify all KPI call sites rather than create a new primitive. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`] |
| DATA-03 | Empty, error, permission-denied, and stale-data states are distinct templates. | Existing true-empty, filtered, no-tenant, detail-error, and unavailable branches exist but are not unified into the four-template taxonomy; plan should add a reusable data-state helper or tightly shared markup with distinct test IDs/copy. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `.planning/phases/113-data-display/113-CONTEXT.md`] |
| DATA-04 | Severity/status is icon+label+color and scannable under stress. | `Components.status_badge/1` and `Components.stat_card/1` already encode visible labels, Heroicons, and semantic classes; plan should extend call-site and browser proof for table/card rows, stat cards, gallery, and fallback/unknown states. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/e2e/structural.spec.js`] |
| DATA-05 | Long real-world values handle UUIDs, module/function names, URLs, non-ASCII names, and timestamps gracefully. | Existing primitives use `truncate` + `title`, but list row IDs and metadata are not fully protected; plan should add deterministic field-level truncation/wrap/expand patterns plus ExUnit and Playwright overflow proof. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/e2e/structural.spec.js`, `reference/demo_app/lib/mailglass_demo/demo_data.ex`] |
</phase_requirements>

## Summary

Phase 113 should be a focused data-presentation pass over existing `mailglass_admin` components. The implementation should keep data loading, URL state, selection, tenant scope, and pagination behavior unchanged, while replacing only the list presentation layer with desktop tables and mobile cards. Current `DeliveriesList` and `RecordsList` already centralize row selection, empty branches, result counts, pagination controls, status badges, and metadata display, so those two modules are the primary implementation targets. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]

Use the existing `MailglassAdmin.Components.stat_card/1` and `status_badge/1`; do not invent parallel KPI or status primitives. Component tests already assert stat-card severity icons, visible labels, semantic classes, meaningful empty/loading/unavailable values, label/value titles, and non-interactivity. Status-badge tests already cover outbound, inbound, timeline, phantom, and nil states. Planning should widen coverage to all Phase 113 call sites and structural browser proofs. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/e2e/structural.spec.js`]

The only reusable addition worth planning is a small data-state presentation helper if it prevents duplicated no-data/error/permission/stale markup. No new runtime Hex dependencies, npm packages, asset pipeline, screenshots, pixel diff, polling, streams, or live-refresh mechanics are needed for this phase. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`, `.planning/research/v1.13/SUMMARY.md`, `.planning/research/v1.13/STACK.md`]

**Primary recommendation:** Implement table/card variants inside `DeliveriesList` and `RecordsList`, certify existing `stat_card`/`status_badge` usage, add a reusable data-state helper only if it stays small, and extend existing ExUnit, gallery, Playwright structural, and conformance gates.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Responsive delivery/inbound list presentation | Frontend Server (LiveView components) | Browser / Client | Phoenix function components emit table/card markup and responsive classes; browser CSS applies the `md` breakpoint. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/assets/css/app.css`] |
| Selection and URL state | Frontend Server (LiveView) | Browser / Client | Existing row/card interactions patch URL state through `phx-click` and `phx-value-id`; Phase 113 should preserve those contracts. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| KPI/stat cards | Frontend Server (shared components) | Browser / Client | `Components.stat_card/1` owns KPI markup, severity indicator, and truncation contracts; pages pass values and labels. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound/overview.ex`] |
| Status/severity encoding | Frontend Server (shared components) | Browser / Client | `Components.status_badge/1` owns status-to-icon/color/label mapping; callers should not map badge classes locally. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/scripts/check-conformance.sh`] |
| Data-state templates | Frontend Server (shared or list-local component) | API / Backend | The UI owns distinct no-data/error/permission/stale presentation; backend/read models only provide the state signal. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| Long-value handling | Frontend Server (components) | Browser / Client | Components choose field-specific `truncate`+`title`, wrap, or expand markup; browser structural tests verify no overflow. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/e2e/structural.spec.js`] |

## Project Constraints (from CLAUDE.md)

- `mailglass_admin` is a mountable LiveView dashboard for Phoenix; host-app friendliness is mandatory, so Phase 113 must not hijack host auth, theme, assets, Repo, global CSS, or routes. [VERIFIED: repo: `CLAUDE.md`, `.planning/REQUIREMENTS.md`]
- The repo has no Node asset pipeline; admin CSS is built to committed `mailglass_admin/priv/static/app.css`, and class changes must leave the bundle clean after `mix mailglass_admin.assets.build`. [VERIFIED: repo: `CLAUDE.md`, `mailglass_admin/mix.exs`]
- New runtime Hex dependencies are out of scope for v1.13, and Phase 113 should install no external packages. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`]
- Brand voice is clear, exact, confident, warm, modern, and technical; data-state copy must avoid "Oops", "Whoops", "Uh oh", and generic "Something went wrong" phrasing. [VERIFIED: repo: `CLAUDE.md`, `mailglass_admin/test/mailglass_admin/voice_test.exs`]
- Domain language should use Mailable, Message, Delivery, Event, InboundMessage, Mailbox, and Suppression; avoid generic "email" when a precise noun exists. [VERIFIED: repo: `CLAUDE.md`]
- Telemetry and UI metadata must not leak PII; list recipients remain masked by `Components.mask_recipient/1`. [VERIFIED: repo: `CLAUDE.md`, `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`]
- No `AGENTS.md`, `.claude/skills/`, or `.agents/skills/` project instruction files were found in this workspace scan; the root `CLAUDE.md` is the actionable project instruction file for this research. [VERIFIED: repo: `rg --files -g 'AGENTS.md' -g '.claude/skills/**/SKILL.md' -g '.agents/skills/**/SKILL.md' -g 'CLAUDE.md'`]

## Standard Stack

### Core

| Library / Module | Version / Shape | Purpose | Why Standard |
|------------------|-----------------|---------|--------------|
| Phoenix LiveView | `phoenix_live_view 1.1.32` locked, `~> 1.1` declared | Server-rendered function components, LiveView events, URL patch state, component tests. | Existing admin surfaces and test helpers already use LiveView and `Phoenix.LiveViewTest`. [VERIFIED: repo: `mix.exs`, `mix.lock`, `mailglass_admin/test/mailglass_admin/components_test.exs`] |
| Phoenix | `phoenix 1.8.8` locked, `~> 1.8` declared | Phoenix app/router/component runtime. | Existing admin package is Phoenix-based and uses Phoenix component conventions. [VERIFIED: repo: `mix.exs`, `mix.lock`] |
| `MailglassAdmin.Components.stat_card/1` | public function component | Canonical KPI/stat card with meaningful empty/loading/unavailable values and severity. | Phase 110 made it canonical; Phase 113 should certify usage, not create a replacement. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `.planning/phases/113-data-display/113-CONTEXT.md`] |
| `MailglassAdmin.Components.status_badge/1` | public function component | Canonical status/severity badge with icon, label, and semantic class. | Existing tests and conformance gates treat private badge helpers as drift. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/scripts/check-conformance.sh`] |
| Tailwind v4 / daisyUI vendored CSS path | Tailwind v4.1.12 comment in `app.css`, daisyUI vendored plugin blocks | Responsive classes, semantic tokens, light/dark/system styling. | Existing zero-Node asset build and semantic class gates are already armed. [VERIFIED: repo: `mailglass_admin/assets/css/app.css`, `mailglass_admin/mix.exs`] |

### Supporting

| Library / Module | Version / Shape | Purpose | When to Use |
|------------------|-----------------|---------|-------------|
| `@playwright/test` | `1.59.1` installed in `mailglass_admin` | Browser structural assertions for responsive layout, overflow, contrast, gallery specimens, system theme. | Extend `structural.spec.js` for table/card, long-value, status, and data-state proof. [VERIFIED: repo: `mailglass_admin/package.json`, `mailglass_admin/package-lock.json`, `npm ls @playwright/test`] |
| `Phoenix.LiveViewTest.render_component/2` | official HexDocs API | Isolated function component rendering. | Use for `stat_card`, `status_badge`, list components, and any data-state helper. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| `Phoenix.Component.attr/3` and slots | official HexDocs API | Public function component API declarations. | Use if adding `data_state/1` or long-value helper attrs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| `reference/demo_app` demo data | repo-local fixtures | Realistic delivery/inbound stress values. | Use existing long subject and demo data patterns for proof without introducing new fixture infrastructure. [VERIFIED: repo: `reference/demo_app/lib/mailglass_demo/demo_data.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Desktop semantic table plus mobile cards | One CSS-squished table at all widths | Squished columns are the exact DATA-01 failure mode and harm scanability. [VERIFIED: repo: `.planning/REQUIREMENTS.md`] |
| Mobile cards with repeated field labels | Hide columns on mobile | Hiding status, tenant, provider, event/outcome, or timestamp loses operator context; repeated labels keep the row self-contained. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`; CITED: https://bati-itao.github.io/learning/esdc-self-paced-web-accessibility-course/module8/responsive-tables.html] |
| `Components.stat_card/1` | Page-local stat card markup | Page-local cards already caused drift; conformance gates should keep KPIs routed through the primitive. [VERIFIED: repo: `mailglass_admin/scripts/check-conformance.sh`] |
| `Components.status_badge/1` | Local status-to-class helpers | Local helpers duplicate taxonomy and risk color-only/icon-only regressions. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/scripts/check-conformance.sh`] |
| `truncate` + `title`, wrap, or expand per field | Global `overflow-auto` horizontal scrolling | Long unbroken strings can break reflow; horizontal scrolling should not be the default for Phase 113 list cards. [CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap] |

**Installation:** No package installation is recommended for Phase 113. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `.planning/REQUIREMENTS.md`]

```bash
# none
```

## Package Legitimacy Audit

No external packages should be installed in Phase 113, so the package legitimacy gate is not applicable. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `.planning/REQUIREMENTS.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No install |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens Deliveries or Inbound surface
  |
  v
Existing LiveView handle_params/assigns
  |-- tenant scope, filters, pagination metadata
  |-- selected delivery/record URL state
  |-- read-model entries already loaded
  v
List component boundary
  |-- result count header always visible
  |-- if empty/error/permission/stale -> distinct data-state template
  |-- else render two responsive presentations from same assigns
  |      |-- >=768px: semantic table
  |      |     |-- status column first
  |      |     |-- recipient/mailbox, tenant, provider, event/outcome, timestamp
  |      |     `-- row/select action preserves phx-click + phx-value-id
  |      `-- <768px: card/list item
  |            |-- status badge and primary identity first
  |            |-- repeated field labels for metadata
  |            `-- same selection semantics and non-color selected cue
  |
  v
Shared primitives
  |-- Components.status_badge/1 for every status/outcome
  |-- Components.stat_card/1 for every KPI
  |-- optional Components.data_state/1 if it reduces duplicate templates
  `-- field-specific long-value helper/pattern
  |
  v
Validation
  |-- ExUnit render_component/live tests
  |-- /dev/mail/gallery specimens
  |-- Playwright responsive/overflow/status structural assertions
  `-- conformance grep gate for no drift
```

### Recommended Project Structure

```text
mailglass_admin/lib/mailglass_admin/
├── components.ex                    # Keep stat_card/status_badge; add data_state/1 only if small.
├── operator/
│   └── deliveries_list.ex            # Desktop table + mobile cards for Deliveries.
├── inbound/
│   └── records_list.ex               # Desktop table + mobile cards for Inbound records.
├── operator_live.ex                  # Preserve assigns, selected state, pagination integration.
├── inbound_live.ex                   # Preserve assigns, selected state, pagination integration.
└── gallery_live.ex                   # Add Phase 113 specimens for tables/cards/data states/long values.

mailglass_admin/test/mailglass_admin/
├── components_test.exs               # Certify shared helper/stat/status contracts.
├── operator_live_test.exs            # Delivery table/card/state regression.
└── inbound_live_test.exs             # Inbound table/card/state regression.

mailglass_admin/e2e/
└── structural.spec.js                # Responsive table/card, overflow, status, and gallery proof.
```

### Pattern 1: Dual Presentation From One Assign Set

**What:** Render a desktop `<table>` at `md` and a mobile card/list at `max-md`, both generated from the same `@deliveries` or `@records`. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]

**When to use:** Use in `DeliveriesList.deliveries_list/1` and `RecordsList.records_list/1` when entries are present. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]

**Example:**

```elixir
# Source: repo pattern recommendation for Phase 113.
<div class="hidden md:block">
  <table data-testid="operator-deliveries-table" class="table w-full table-fixed">
    <thead>
      <tr>
        <th scope="col">Status</th>
        <th scope="col">Recipient</th>
        <th scope="col">Tenant</th>
        <th scope="col">Provider</th>
        <th scope="col">Event</th>
        <th scope="col">Last event</th>
      </tr>
    </thead>
    <tbody>
      <tr :for={delivery <- @deliveries} data-selected={selected?(@selected_delivery, delivery)}>
        <td><Components.status_badge status={delivery.status} size={:sm} /></td>
        <td><span class="truncate" title={Components.mask_recipient(delivery.recipient)}>{Components.mask_recipient(delivery.recipient)}</span></td>
        <td><span class="mono truncate" title={delivery.tenant_id}>{delivery.tenant_id}</span></td>
        <td>{String.upcase(delivery.provider || "unknown")}</td>
        <td>{label(delivery.last_event_type)}</td>
        <td><span class="mono whitespace-nowrap" title={format_datetime(delivery.last_event_at)}>{format_datetime(delivery.last_event_at)}</span></td>
      </tr>
    </tbody>
  </table>
</div>

<ul data-testid="operator-deliveries-cards" class="divide-y divide-base-300 md:hidden">
  <li :for={delivery <- @deliveries}>
    <button phx-click="select_delivery" phx-value-id={delivery.id}>
      <!-- same values, mobile field labels, same selected semantics -->
    </button>
  </li>
</ul>
```

### Pattern 2: Distinct Data-State Helper

**What:** Use one small helper for state templates if it can encode distinct `:empty`, `:error`, `:permission_denied`, and `:stale` variants without becoming a generic content framework. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]

**When to use:** Use in list empty branches, detail error/unavailable areas, and gallery specimens where the same state taxonomy needs proof. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/lib/mailglass_admin/gallery_live.ex`]

**Example:**

```elixir
# Source: repo pattern recommendation for Phase 113.
attr :kind, :atom, values: [:empty, :error, :permission_denied, :stale], required: true
attr :title, :string, required: true
attr :body, :string, required: true
attr :icon, :string, default: nil
attr :rest, :global, default: %{}

def data_state(assigns) do
  ~H"""
  <section class="flex min-h-64 flex-col items-center justify-center gap-sm p-6 text-center" {@rest}>
    <.icon name={@icon || data_state_icon(@kind)} class={["h-8 w-8", data_state_icon_class(@kind)]} />
    <div class="space-y-1">
      <h3 class="text-body font-bold text-base-content">{@title}</h3>
      <p class="text-body text-secondary">{@body}</p>
    </div>
  </section>
  """
end
```

### Pattern 3: Field-Specific Long-Value Handling

**What:** Choose truncation+title for compact identifiers, `whitespace-nowrap` for timestamps, and wrapping/expansion for URLs or subjects where the value must be read. [CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap]

**When to use:** Apply to delivery IDs, inbound IDs, tenant IDs, provider IDs, provider message IDs, module/function names, mailbox names, URLs, long subjects, non-ASCII names, and timestamps. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `reference/demo_app/lib/mailglass_demo/demo_data.ex`]

**Example:**

```elixir
# Source: existing primitive style in Components.stat_card/1 and tenant_chip/1.
<span class="mono min-w-0 truncate" title={record.id}>{record.id}</span>
<span class="min-w-0 overflow-wrap-anywhere" title={record.mailbox}>{record.mailbox}</span>
<span class="mono whitespace-nowrap" title={format_datetime(record.received_at)}>
  {format_datetime(record.received_at)}
</span>
```

### Anti-Patterns to Avoid

- **Rendering only card rows on desktop:** DATA-01 explicitly requires semantic tables at `>=768px`. [VERIFIED: repo: `.planning/REQUIREMENTS.md`]
- **Squishing the desktop table onto mobile:** This is the named failure Phase 113 exists to close. [VERIFIED: repo: `.planning/REQUIREMENTS.md`]
- **Creating `delivery_status_badge/1` or `inbound_status_badge/1`:** Status mapping belongs in `Components.status_badge/1`. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/scripts/check-conformance.sh`]
- **Using `—`, `___`, color-only chips, or icon-only state:** Phase 113 locks meaningful text states and icon+label+color severity. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`; CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]
- **Adding polling or streams for stale data:** D-06 explicitly excludes live-refresh mechanics. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]
- **Adding screenshots or pixel baselines:** D-08 excludes pixel diff and screenshot baselines. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| KPI/stat cards | New page-local card components | `MailglassAdmin.Components.stat_card/1` | Existing primitive already handles label/value truncation, meaningful states, and severity. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Status/severity badges | New status class/icon maps in list modules | `MailglassAdmin.Components.status_badge/1` | Existing primitive owns taxonomy, icons, labels, and semantic classes. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Recipient masking | New masking helper in list modules | `Components.mask_recipient/1` | One audited masking definition prevents PII drift. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Pagination metadata | Fake totals from current entries length | Existing Phase 112 page metadata | D-02 requires preserving real count/page metadata. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`] |
| Responsive proof | Screenshot comparisons | Existing Playwright structural assertions | Project excludes pixel diff; structural DOM/computed-style assertions are the established gate. [VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`, `.planning/REQUIREMENTS.md`] |
| Long-string resilience | One global `overflow-auto` wrapper | Per-field truncate/title, wrap, or expand | Long values have different operator value; timestamps need no-wrap, URLs/subjects may need wrapping or expansion. [CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33] |

**Key insight:** Phase 113 is not a data-layer phase; it is a presentation-contract phase over existing read models and primitives. Custom replacements create drift, while shared primitives plus structural proof make the planner's tasks smaller and easier to verify. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Table Semantics Get Lost During Mobile Reflow

**What goes wrong:** A desktop table is replaced by div-only markup everywhere or a mobile card hides column labels, making relationships unclear. [CITED: https://www.w3.org/WAI/tutorials/tables/; CITED: https://bati-itao.github.io/learning/esdc-self-paced-web-accessibility-course/module8/responsive-tables.html]  
**Why it happens:** Developers optimize for CSS appearance instead of preserving data relationships. [ASSUMED]  
**How to avoid:** Render a semantic table only at `md` and up; render mobile cards with visible field labels and the same core values. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]  
**Warning signs:** No `<table>`, no `<th scope="col">`, mobile cards with value-only metadata, or missing status/timestamp on mobile. [VERIFIED: repo: `.planning/REQUIREMENTS.md`]

### Pitfall 2: Dual Markup Drifts Behavior

**What goes wrong:** Desktop rows select correctly but mobile cards lose `phx-value-id`, selected state, focus ring, or URL patch behavior. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]  
**Why it happens:** The two views are implemented as separate branches with different event attributes. [ASSUMED]  
**How to avoid:** Keep a shared row/card helper or shared assign normalization, and assert both presentations carry selection semantics. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]  
**Warning signs:** Playwright only clicks desktop rows, or ExUnit only searches for one presentation's test IDs. [VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`]

### Pitfall 3: Generic Empty State Hides Real Operator Meaning

**What goes wrong:** No-data, filtered-empty, unavailable/error, permission-denied, and stale all collapse into "No records" or a generic error. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`]  
**Why it happens:** Empty states are treated as copy variants instead of state templates. [ASSUMED]  
**How to avoid:** Model `:empty`, `:error`, `:permission_denied`, and `:stale` explicitly in helper/test IDs/copy. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]  
**Warning signs:** One `data-testid` covers multiple states, or unavailable uses the no-data icon/copy. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]

### Pitfall 4: Long Values Pass Unit Tests But Overflow In Browser

**What goes wrong:** UUIDs, provider message IDs, module names, URLs, non-ASCII names, or timestamps overflow at 320-390px or force page-wide horizontal scrolling. [VERIFIED: repo: `.planning/REQUIREMENTS.md`; CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33]  
**Why it happens:** ExUnit string assertions do not exercise layout, and unbroken strings ignore normal wrapping. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap]  
**How to avoid:** Add realistic long values to component/gallery specimens and assert no element/page horizontal overflow in Playwright. [VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`, `reference/demo_app/lib/mailglass_demo/demo_data.ex`]  
**Warning signs:** `truncate` without `title`, `min-w-0` missing inside flex/grid cells, or long IDs printed in mono without a container constraint. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`]

### Pitfall 5: Severity Becomes Color-Only Under Space Pressure

**What goes wrong:** Mobile cards or compact table cells drop the visible label and rely on color or icon alone. [VERIFIED: repo: `.planning/REQUIREMENTS.md`; CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]  
**Why it happens:** Designers compress status UI for density. [ASSUMED]  
**How to avoid:** Keep `status_badge/1` and `stat_card/1` intact in every presentation, and assert visible status labels in the table and card DOM. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`]  
**Warning signs:** `.badge-*` classes appear outside `Components.status_badge/1`, or a status icon has no adjacent text. [VERIFIED: repo: `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/e2e/structural.spec.js`]

## Code Examples

Verified patterns from repo and official sources:

### Render Component Contract Test

```elixir
# Source: Phoenix.LiveViewTest HexDocs + existing repo components_test.exs.
html =
  render_component(&Components.stat_card/1,
    label: "Failed",
    value: 2,
    severity: :error
  )

assert html =~ "hero-x-circle"
assert html =~ "Problem"
assert html =~ "text-error"
```

[CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/components_test.exs`]

### Existing Status Badge Usage

```elixir
# Source: existing DeliveriesList pattern.
<Components.status_badge status={delivery.status} size={:sm} />
```

[VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`]

### Existing Stat Card Usage

```elixir
# Source: existing OperatorLive overview pattern.
<Components.stat_card
  label="All-clear status"
  value={all_clear_label(@support_summary)}
  state={all_clear_state(@support_summary)}
  severity={all_clear_severity(@support_summary)}
  severity_label={all_clear_label(@support_summary)}
  data-testid="operator-overview-health-allclear"
/>
```

[VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`]

### Playwright Overflow Assertion Pattern

```javascript
// Source: existing structural.spec.js pattern.
await assertNoElementHorizontalOverflow(
  page.getByTestId("operator-deliveries-table"),
  "operator deliveries desktop table"
);

await assertNoElementHorizontalOverflow(
  page.getByTestId("operator-deliveries-cards"),
  "operator deliveries mobile cards"
);
```

[VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| List-only row buttons for deliveries/inbound | Desktop semantic table plus mobile card/list | Phase 113 target, planned 2026-06-19 | Satisfies DATA-01 while preserving existing selection behavior. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`] |
| Page-local/stat-card-like KPI markup | `Components.stat_card/1` canonical primitive | Phase 110 completed before Phase 113 | Phase 113 should certify all surfaces use the primitive. [VERIFIED: repo: `.planning/STATE.md`, `mailglass_admin/lib/mailglass_admin/components.ex`] |
| Per-surface status maps | `Components.status_badge/1` canonical primitive | Earlier admin UI phases, present before Phase 113 | Phase 113 should keep all table/card status UI routed through the primitive. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/scripts/check-conformance.sh`] |
| Generic empty/error branch | Four distinct data-state templates | Phase 113 target, planned 2026-06-19 | Prevents no-data, unavailable/error, permission-denied, and stale-data collapse. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`] |

**Deprecated/outdated:**
- Bare dash placeholders for unavailable values are outdated for KPI/data-display surfaces; use meaningful empty/unavailable/stale text. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `mailglass_admin/test/mailglass_admin/components_test.exs`]
- Color-only status is outdated and violates the phase and WCAG use-of-color requirement. [VERIFIED: repo: `.planning/REQUIREMENTS.md`; CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]
- Mobile squished tables are out of scope as a solution; card/list transformation is locked. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Developers often lose table semantics because they optimize CSS appearance before data relationships. | Common Pitfalls | Low; affects explanatory rationale, not implementation constraints. |
| A2 | Dual desktop/mobile markup commonly drifts because branches carry separate event attributes. | Common Pitfalls | Medium; planner can avoid this with explicit test tasks either way. |
| A3 | Empty states are often treated as copy variants instead of state templates. | Common Pitfalls | Low; phase decisions already require explicit templates. |
| A4 | Designers compress severity UI under density pressure. | Common Pitfalls | Low; phase decisions and tests prevent the regression regardless. |

## Open Questions (RESOLVED)

1. **Should the data-state helper live in `Components` or stay list-local?**
   - What we know: D-05 allows a distinct reusable helper if it is cleaner than page-local markup. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]
   - What's unclear: How many call sites need the exact same taxonomy after implementation. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`]
   - Recommendation: Start with `Components.data_state/1` only if at least two surfaces use identical structure; otherwise keep state markup in the list/detail component and certify with tests. [ASSUMED]
   - **RESOLVED:** In favor of a public `Components.data_state/1` — three surfaces (`deliveries_list`, `records_list`, `inbound_live` detail-error) share the identical four-state taxonomy, meeting the ≥2-surface rule. Decided by Plan `113-01` (Task 2). [VERIFIED: repo: `.planning/phases/113-data-display/113-01-PLAN.md`]

2. **Which fields get truncation versus wrapping or expansion?**
   - What we know: UUIDs, tenant IDs, provider IDs, module/function names, URLs, subjects, non-ASCII names, and timestamps are in scope. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]
   - What's unclear: The final table column set and mobile field ordering are delegated to planner discretion. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]
   - Recommendation: Truncate+title compact IDs/names in tables, use repeated labels and wrapping/expandable content in cards where readability matters, and keep timestamps no-wrap with a title. [CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33; ASSUMED]
   - **RESOLVED:** Per-field long-value handling fixed by the UI-SPEC DATA-05 table and baked into Plans `113-02`/`113-03` (Task 1): compact IDs/module names `truncate` + `title`, timestamps `whitespace-nowrap` + `title`, `table-fixed`/`min-w-0` to prevent horizontal scroll. [VERIFIED: repo: `.planning/phases/113-data-display/113-02-PLAN.md`, `.planning/phases/113-data-display/113-03-PLAN.md`, `.planning/phases/113-data-display/113-UI-SPEC.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit/component/live tests | ✓ | 1.19.5, OTP 28 | — [VERIFIED: command: `elixir --version`] |
| Mix | `mix test`, `mix verify.preview`, asset build | ✓ | 1.19.5, OTP 28 | — [VERIFIED: command: `mix --version`] |
| Node.js | Playwright structural tests | ✓ | v22.14.0 | — [VERIFIED: command: `node --version`] |
| npm | Playwright dependency install/scripts | ✓ | 11.1.0 | — [VERIFIED: command: `npm --version`] |
| `@playwright/test` | Existing browser structural suite | ✓ | 1.59.1 | — [VERIFIED: command: `cd mailglass_admin && npm ls @playwright/test --depth=0`] |
| `@axe-core/playwright` | Phase 116 axe work, not Phase 113 | ✗ | — | Skip in Phase 113; do not install here. [VERIFIED: command: `cd mailglass_admin && npm ls @axe-core/playwright --depth=0`; VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`] |

**Missing dependencies with no fallback:** none for Phase 113. [VERIFIED: command: environment audit above]  
**Missing dependencies with fallback:** `@axe-core/playwright` is absent, but Phase 113 does not require it and should use existing Playwright structural checks. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest; Playwright `@playwright/test 1.59.1`. [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/package.json`] |
| Config file | `mailglass_admin/playwright.config.cjs` for browser tests; ExUnit via package test setup. [VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/package.json`] |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` [VERIFIED: repo: `mailglass_admin/mix.exs`] |
| Full suite command | `cd mailglass_admin && mix verify.preview && bash scripts/check-conformance.sh && npm run test:operator-browser -- --grep \"Data|stat_card|status|overflow|responsive\"` [VERIFIED: repo: `mailglass_admin/mix.exs`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/package.json`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DATA-01 | Desktop deliveries/inbound are tables at >=768 and cards/lists below 768. | component + browser structural | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors && npm run test:operator-browser -- --grep "responsive"` | ✅ / extend existing [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`, `mailglass_admin/e2e/structural.spec.js`] |
| DATA-02 | All KPI cards use `Components.stat_card/1`; meaningful empty/all-clear states. | component + conformance | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && bash scripts/check-conformance.sh` | ✅ / extend existing [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/scripts/check-conformance.sh`] |
| DATA-03 | No-data, unavailable/error, permission-denied, and stale templates are distinct. | component + live + gallery | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | ✅ / add cases [VERIFIED: repo: test files listed] |
| DATA-04 | Severity/status uses icon+label+color in table, card, stat, and gallery contexts. | component + browser structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && npm run test:operator-browser -- --grep "status|stat_card"` | ✅ / extend existing [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/e2e/structural.spec.js`] |
| DATA-05 | Long values never overflow or chop incoherently. | component + browser structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "overflow|long"` | ✅ / extend existing [VERIFIED: repo: `mailglass_admin/e2e/structural.spec.js`] |

### Sampling Rate

- **Per task commit:** `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` [VERIFIED: repo: existing tests]
- **Per wave merge:** `cd mailglass_admin && mix verify.preview && bash scripts/check-conformance.sh` [VERIFIED: repo: `mailglass_admin/mix.exs`, `mailglass_admin/scripts/check-conformance.sh`]
- **Phase gate:** `cd mailglass_admin && mix verify.preview && bash scripts/check-conformance.sh && npm run test:operator-browser -- --grep "responsive|stat_card|status|overflow|Data"` plus any newly named Phase 113 grep. [VERIFIED: repo: `mailglass_admin/package.json`, `mailglass_admin/e2e/structural.spec.js`]

### Wave 0 Gaps

- [ ] Add list-component or LiveView assertions for `operator-deliveries-table`, `operator-deliveries-cards`, `inbound-records-table`, and `inbound-records-cards`. [VERIFIED: repo: current tests lack those Phase 113 test IDs]
- [ ] Add data-state tests/specimens for no-data, unavailable/error, permission-denied, and stale. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, current state branches]
- [ ] Add Playwright long-value specimens/assertions using UUIDs, tenant IDs, provider IDs, module/function names, URLs, non-ASCII names, and timestamps. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`, `mailglass_admin/e2e/structural.spec.js`]
- [ ] Extend `check-conformance.sh` with Phase 113 drift gates only after the intended selectors/component names exist. [VERIFIED: repo: `mailglass_admin/scripts/check-conformance.sh`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct change | Existing operator LiveSession/auth remains unchanged. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`] |
| V3 Session Management | no direct change | No new session or cookie behavior in Phase 113. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`] |
| V4 Access Control | yes | Preserve existing tenant-scoped read-model inputs and do not add raw admin Repo reads. [VERIFIED: repo: `CLAUDE.md`, `.planning/REQUIREMENTS.md`] |
| V5 Input Validation | yes | Preserve existing filter validation and URL-backed state; do not parse or trust new field values in presentation helpers. [VERIFIED: repo: `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`] |
| V6 Cryptography | no | Phase 113 does not introduce cryptography. [VERIFIED: repo: `.planning/phases/113-data-display/113-CONTEXT.md`] |

### Known Threat Patterns for Phoenix LiveView Data Display

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data exposure through display joins or demo shortcuts | Information Disclosure | Keep existing read-model assigns; do not query admin Repo from list components; preserve tenant-scoped URL state. [VERIFIED: repo: `CLAUDE.md`, `.planning/REQUIREMENTS.md`] |
| PII leakage in list tables/cards | Information Disclosure | Continue masking recipients with `Components.mask_recipient/1`; never print raw recipient in list summaries. [VERIFIED: repo: `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`] |
| Permission-denied rendered as no-data | Repudiation / Information Disclosure | Use a distinct permission-denied template so operators can distinguish authorization from empty records without leaking hidden data. [VERIFIED: repo: `.planning/REQUIREMENTS.md`, `.planning/phases/113-data-display/113-CONTEXT.md`] |
| Unsafe title/tooltip content | Cross-Site Scripting | Keep HEEx escaped interpolation and do not use `raw` for long values or tooltips. [VERIFIED: repo: existing HEEx interpolation in `mailglass_admin/lib/mailglass_admin/components.ex`] |

## Sources

### Primary (HIGH confidence)

- Repo: `.planning/phases/113-data-display/113-CONTEXT.md` - locked Phase 113 decisions and boundaries. [VERIFIED: repo]
- Repo: `.planning/REQUIREMENTS.md` - DATA-01..DATA-05 acceptance criteria and v1.13 scope locks. [VERIFIED: repo]
- Repo: `.planning/STATE.md` - current milestone status and Phase 109-112 inherited decisions. [VERIFIED: repo]
- Repo: `CLAUDE.md` - project constraints, domain language, brand voice, and no-new-runtime dependency posture. [VERIFIED: repo]
- Repo: `mailglass_admin/lib/mailglass_admin/components.ex` - `stat_card/1`, `status_badge/1`, `mask_recipient/1`. [VERIFIED: repo]
- Repo: `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` and `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - current list structures. [VERIFIED: repo]
- Repo: `mailglass_admin/test/mailglass_admin/components_test.exs`, `operator_live_test.exs`, `inbound_live_test.exs` - existing verification patterns. [VERIFIED: repo]
- Repo: `mailglass_admin/e2e/structural.spec.js` - browser structural proof style. [VERIFIED: repo]

### Secondary (MEDIUM confidence)

- W3C WCAG Understanding 1.4.1 Use of Color - color not sole carrier of meaning. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]
- W3C WCAG Technique C33 - long URLs/strings and reflow. [CITED: https://www.w3.org/WAI/WCAG21/Techniques/css/C33]
- MDN `overflow-wrap` - CSS behavior for unbreakable strings. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap]
- ESDC responsive tables accessibility course - responsive table options and nested-list/card reflow. [CITED: https://bati-itao.github.io/learning/esdc-self-paced-web-accessibility-course/module8/responsive-tables.html]
- Phoenix LiveViewTest HexDocs - `render_component/2` test pattern. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Phoenix.Component HexDocs - function component attrs and slots. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- Carbon Design System status indicator pattern - status indicators use icon/shape/color/label. [CITED: https://carbondesignsystem.com/patterns/status-indicator-pattern/]
- USWDS icon-list accessibility tests - color alone must not convey icon meaning. [CITED: https://designsystem.digital.gov/components/icon-list/accessibility-tests/]

### Tertiary (LOW confidence)

- Assumptions in the Assumptions Log, explicitly marked `[ASSUMED]`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended implementation libraries/modules are already present in repo and version-checked locally. [VERIFIED: repo and command audit]
- Architecture: HIGH - primary work maps directly to existing list components, shared components, LiveViews, gallery, and Playwright suite. [VERIFIED: repo]
- Pitfalls: MEDIUM - core pitfalls are phase-verified; explanatory causes include limited assumed industry patterns. [VERIFIED: repo; ASSUMED where marked]

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for repo-local implementation patterns; re-check external docs if planning is delayed beyond 30 days. [ASSUMED]
