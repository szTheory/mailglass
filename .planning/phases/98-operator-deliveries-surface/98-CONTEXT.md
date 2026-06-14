# Phase 98: Operator / Deliveries Surface - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Group + page/IA + responsive + flow + a11y uplift of `/ops/mail` (OperatorLive) — compose the
already-uplifted shared components (Phase 97) into coherent, on-brand GROUPS; an IA that orients
both first-time and advanced operators on landing (gov.uk least-surprise); full happy/error/boundary
state coverage; mobile-first 390/768/1440 responsiveness; accessibility; and deterministic
seed/fixture data tuned for every operator state reachable by seeded URL. Also folds in the
pre-existing CR-01/02/03 nil-guard tech debt.

**In scope:** GROUP-01, PAGE-01, PAGE-02, RESP-01, FLOW-01, FLOW-02, A11Y-01, A11Y-02 — for the
**Operator surface only** (`/ops/mail`, `OperatorLive` + `operator/*` components). This phase
ANCHORS the cross-surface GROUP/PAGE/RESP/FLOW/A11Y pattern re-applied on Phases 99 (Inbound) and
100 (Preview).

**Out of scope:** Inbound surface (99); Preview surface (100); global microcopy pass (101); global
motion pass (102). Shared COMPONENTS were already uplifted in Phase 97 — this phase composes them,
it does not re-uplift them. This phase IMPLEMENTS the locked v1.11 research decisions
(`.planning/research/v1.11/SUMMARY.md`, 69 LD-IDs) — it does NOT re-decide any axis owned by an LD-ID
(motion, state matrix, dark resolution, IA placement, literal copy).
</domain>

<decisions>
## Implementation Decisions

### Overview / Master-Detail IA Reconciliation

- **D-01:** **Keep both views; bring both to the locked spec.** The existing `:overview` view
  (`operator_live.ex:280-363` — orientation_strip + Health stat cards + Navigate cards) stays as the
  **first-time orientation landing** that satisfies PAGE-01's "orient first-time operators on
  landing." The `:deliveries` view stays as the advanced master-detail surface (PAGE-01 "advanced
  operators"). The IA-LD locks (IA-LD-01..07) are silent on the overview — they govern the
  master-detail layout — so the overview is retained as a composition-layout realization of PAGE-01,
  NOT dropped. BOTH views must be brought into full conformance with the locked tokens / responsive
  grid / disclosure / a11y rules below. (User decision, 2026-06-14.)

### Conformance Gaps to Fix (fold into the group/IA uplift)

- **D-02:** Correct the master-detail responsive grid to the **locked IA-LD-03 percentages**: 390px
  → master list 100% width, record selection reveals detail at 100% with a back affordance (NOT a
  push_patch to a new route); 768px → `grid-cols-[40%_60%]`; 1440px → `grid-cols-[33%_67%]`. The
  current `lg:grid-cols-[minmax(22rem,28rem)_1fr]` (`operator_live.ex:396`) does NOT match the lock
  (wrong percentages, `lg:` breakpoint instead of the 768/1440 tiers) and must be replaced. Column
  widths are grid percentage templates; intra-column spacing uses token gaps (IA-LD-03).
- **D-03:** Remove the banned arbitrary `tracking-[0.08em]` from the deliveries-list card `h2`
  (`operator_live.ex:~409`) and apply the locked filter/section label token
  `text-label uppercase font-bold text-secondary` (IA-LD-04). Letter-spacing is token-owned; the
  tightened conformance grep gate (RATCHET-03) already fails on arbitrary `tracking-[…]`. Audit the
  whole operator template for any other `text-lg/xl/2xl`, arbitrary `tracking-[…]`, `ease-in`, or
  layout-property-transition escapes and fix to token.

### Seed / Fixture Strategy (FLOW-01 — reachable by seeded URL)

- **D-04:** **Extend the single existing `OperatorFixtures.seed_browser_scenario!/0`** to additionally
  cover the currently-unseeded states, and reach every state by **URL params against that one
  dataset** — do NOT add new seed entry points or per-state seed scripts. Add: truly-empty/no-tenant
  path (COPY-LD-02), filtered-empty (COPY-LD-01, reached via a non-matching `?status=`/`?provider=`
  combo), detail-error (`:not_found`, reached via a non-existent `?delivery_id=` —
  `detail_error_for/2` at `operator_live.ex:550-552` already returns `:not_found`), an active
  suppression already present, and a `:suppressed`/novel-shape delivery row. Why this way: the e2e
  harness is built on ONE fixed seed (`operator_browser_server.ex:30`, `endpoint_case.ex:87`) keyed
  on stable constants (`@tenant_id "browser-tenant"`, fixed recipients), all state navigation in
  `operator.spec.js`/`structural.spec.js` is already URL-param driven, and row-index stability that
  `deliveryRow(page, index)` depends on (D-07 ordering at `operator_fixtures.ex:131-133`) must not
  shift. Preserve PII minimization (`mask_recipient/1`) and multi-tenant safety in all seed work.

### CR Nil-Guard Tech Debt (fold-in)

- **D-05:** Fix all three CRs with the **minimal in-place idiom already used by their neighbours** —
  no happy-path refactor:
  - **CR-01:** add a catch-all `defp body_copy(_), do: <COPY-LD-14 fallback string>` to
    `suppression_card.ex:55-57`, mirroring the existing `headline/1`/`label/1` fallbacks.
  - **CR-02:** replace the bare `socket.assigns.selected_delivery.id` reads (`operator_live.ex:153`,
    `:241`) with a nil-safe read (`get_in(... Access.key(:id))` or a guarded private helper) — NOT a
    new branch in the `handle_event` happy path (would change push_patch/flash control flow the specs
    assert).
  - **CR-03:** add `:suppressed` to the `status_badge` `attr :status, values:` list
    (`components.ex:158-183`). The `status_class`/`status_icon`/`status_label` fallback clauses
    already render it as neutral `badge-outline`/"Unknown" per STATE-LD-05 — this is a one-line
    attr-list correction only; do NOT add an explicit non-fallback `:suppressed` clause (would
    contradict STATE-LD-05's phantom-atom lock).

### 390px Filter Disclosure, Group Spacing, e2e Tagging

- **D-06:** Implement the 390px filter disclosure (IA-LD-02) as a **`Phoenix.LiveView.JS.toggle`**
  on the inline `<section>` filter panel (base `hidden md:block` + JS toggle, visible "Filters"
  button with expand/collapse indicator), NOT a new socket assign — stateless, URL-param-free,
  consistent with existing `JS.focus`/`JS.focus_first` usage. At ≥768px filter controls are
  persistently visible (no toggle) per IA-LD-02. CSS+LiveView.JS only (no client JS hook).
- **D-07:** Standardize group inter-spacing on the **existing token rhythm** already in the template
  — outer groups `gap-lg`, intra-group `gap-md`/`gap-sm` (`operator_live.ex:281,285,397`,
  `shell.ex:181`). No arbitrary `gap-[…]` (would trip the token structural assertion). Flat elevation
  (border-first, `bg-base-200 border border-base-300 rounded-box`, no shadow-overlay).
- **D-08:** Tag new/uplifted group containers with **`data-testid="operator-{group}"` kebab cells**
  (extends the existing `operator-master-detail`, `operator-detail-column`, `operator-overview`,
  `operator-detail-error`, `operator-empty-detail` scheme) so the Playwright structural layer queries
  them via `getByTestId` exactly like the existing operator accent/touch-target assertions
  (`structural.spec.js`). Rebuild + **commit `priv/static/app.css`**; `git diff --exit-code
  priv/static/` (`verify.preview`, `mix.exs:183-188`) reds CI on an uncommitted bundle.

### Claude's Discretion

- Exact internal shape of the extended seed dataset (record count per state, ordering) provided
  row-index stability for existing specs is preserved and every state is URL-reachable.
- Precise grouping/visual rhythm of the overview Health + Navigate cards, provided spacing is on the
  token scale and flat-elevation/10%-accent rules hold.
- The exact back-navigation affordance at 390px when a record is selected (IA-LD-03 requires it be a
  `:if`-toggled in-place reveal with back, NOT a push_patch to a new route).

### Folded Todos

- **`2026-06-13-refresh-outbound-admin-ui-look-and-feel.md`** (match 0.9) — the operator/outbound
  surface refresh is exactly this phase's scope (and the v1.11 milestone's sanctioned realization).
  Folded into Phase 98.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.11/SUMMARY.md` — **PRIMARY.** The canonical locked-decision file (69 LD-IDs).
  Operator-binding: **IA-LD-01** (orientation_strip placement), **IA-LD-02** (filter persistence +
  390px disclosure toggle), **IA-LD-03** (master-detail split 390/768/1440 percentages), **IA-LD-04**
  (filter label token; drop `tracking-[0.08em]`), **IA-LD-05** (SupportCards two-tier triage DOM
  order), **IA-LD-06** (nav L1/L2 labelling), **IA-LD-07** (empty/loading-state placement matrix),
  **STATE-LD-05** (status atoms incl. `:suppressed` phantom→fallback), **STATE-LD-09**
  (orientation_strip rest-only), **STATE-LD-13** (filters_form states), plus **MOTION-LD-***,
  **DARK-LD-***, **COPY-LD-01/02/14** for the operator surface. Cite LD-IDs; never re-read dossier bodies.
- `.planning/phases/97-cross-surface-component-layer/97-CONTEXT.md` + `97-*-SUMMARY.md` — what the
  shared-component layer already settled (focus rings, detail_headers text-xl fix, filters_form
  tracking removal, support_cards btn-sm) — do NOT re-propose component-level fixes done in 97.
- `.planning/RATCHET-GAP-REGISTER.md` — the carried-forward GAP register; reopen/close operator rows
  with run_id; sev≥3 citation gate.
- `.planning/STATE.md` — v1.11 "Hard design constraints" + "Scope Locks" blocks (binding).
- `.planning/REQUIREMENTS.md` — GROUP-01, PAGE-01/02, RESP-01, FLOW-01/02, A11Y-01/02 acceptance text.
- `mailglass_admin/docs/design-system.md` — motion vocabulary + per-component checklist.
- `brandbook/tokens.css` (token source of truth), `brandbook/brand-book.md` (voice/visual).
- `.planning/milestones/v1.7-phases/76-component-library-and-design-system-hardening/76-REVIEW.md`
  (CR-01/02/03 §58/76/105 — exact descriptions of the nil-guard tech debt being folded in).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`operator_live.ex`** — the OperatorLive LiveView. Two views: `:overview` (lines ~280-363, Health
  stat cards + Navigate cards) and `:deliveries` (master-detail, ~365+). `@status_values`
  (line ~33, includes `:suppressed`), `detail_error_for/2` (~550-552, returns `:not_found` for a
  missing `delivery_id`), `build_path/4` URL-param navigation, `JS` usage (~31, 467-468).
- **`operator/shell.ex`** — shell + orientation_strip (~314-367), nav_link/nav_pill (aria-current at
  ~206/229), gap-token rhythm (~181).
- **`operator/filters_form.ex`** (FiltersForm.fields), **`operator/support_cards.ex`** (two-tier
  triage, ~34-35), **`operator/suppression_card.ex`** (body_copy/1 no fallback ~55-57),
  **`operator/deliveries_list.ex`** (deliveries_list, `deliveryRow` index stability),
  **`operator/detail_headers.ex`**.
- **`components.ex`** — `status_badge` (attr list ~158-183), status_class/icon/label fallback clauses
  (render phantom atoms as `badge-outline`/"Unknown" per STATE-LD-05).
- **Seed harness:** `OperatorFixtures.seed_browser_scenario!/0` (`test/support/operator_fixtures.ex`,
  fixed `@tenant_id "browser-tenant"`, recipients ~10/156-159, ordering note ~131-133),
  `operator_browser_server.ex:30` (single seed + `Process.sleep(:infinity)`), `endpoint_case.ex:87`.
- **e2e:** `mailglass_admin/e2e/structural.spec.js` + `operator.spec.js` (`openOperator` ~13-31,
  `deliveryRow(page,index)`), all state nav is URL-param driven.

### Established Patterns

- **Bundle-clean gate:** `verify.preview` runs `cmd git diff --exit-code priv/static/`
  (`mix.exs:183-188`) — rebuilt `app.css` must be committed.
- **Tightened conformance gates (RATCHET-03):** grep gates fail on `text-lg/xl/2xl`, arbitrary
  `tracking-[…]`, `ease-in`, layout-property transitions.
- **Structural ratchet:** kebab `data-testid="operator-{name}"` + Playwright `getByTestId`.
- **Frozen 36-cell LLM-score baseline** (3 surfaces × 6 pillars × 2 themes); operator surface is one
  of the three — do NOT add new baseline keys.

### Integration Points

- `operator_live.ex` render — the master-detail grid template (D-02), filter section (D-06), overview
  cards (D-01); `@status_values` / `status_badge` attr contract (CR-03).
- `operator/suppression_card.ex` body_copy/1 (CR-01); `operator_live.ex:153/241` selected_delivery
  reads (CR-02).
- `OperatorFixtures.seed_browser_scenario!/0` — extend for all states (D-04).
- `e2e/structural.spec.js` + `operator.spec.js` — operator group assertions + state coverage.
- `RATCHET-GAP-REGISTER.md` — operator GAP rows.
</code_context>

<specifics>
## Specific Ideas

- Master-detail grid uses the locked IA-LD-03 percentages (40/60 @768, 33/67 @1440), NOT the current
  `minmax(22rem,28rem)_1fr` template, and stacks to 100%-width in-place reveal (with back) at 390px.
- Every operator state is reachable from the ONE seeded dataset by URL params — no per-state seed
  scripts — so the existing single-seed e2e harness and row-index stability are preserved.
- CR fixes use the local fallback-clause / nil-safe-read idiom only; CR-03 is a one-line attr-list
  correction (the fallback already renders `:suppressed` correctly).
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope. (Inbound at-a-glance tier IA-LD-09 and RoutingTrace/
EvidenceCard rework are explicitly Phase 99; the overview/master-detail reconciliation here is the
operator analog, kept in-scope via D-01.)

### Reviewed Todos (not folded)

None reviewed-but-not-folded — the one matched todo was folded (see Folded Todos).
</deferred>
