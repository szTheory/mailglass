# Phase 78: Seed-Data Expressiveness - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make **every screen state in the `mailglass_admin` dashboard reachable by a seeded URL** —
every badge color, every support-card branch, every empty/error state — by expanding the demo
seed data, and update the e2e seed-count/row assertions in the **same commit** so Playwright
stays green across the commit boundary.

**In scope:** seed expansion across the two seed surfaces (`reference/demo_app/.../demo_data.ex`
and `mailglass_admin/test/support/operator_fixtures.ex`), and the same-commit updates to
`demo.spec.js` and `operator.spec.js` seed-count/row assertions.

**Out of scope:** any IA / design-system / motion changes (Phases 75–77); fixing the pre-existing
`operator.spec.js:104` replay-flow failure (Phase 79 debt); bumping `reference/demo_app/mix.exs`
or `reference/host_app/mix.exs` version pins (must stay unchanged — D-? reference-baseline
coupling).

**Gap-register citation (anti-churn gate):** SEED-01 cites GAP-13 (zero-state) and GAP-16
(empty states) at severity ≥ 3.
</domain>

<decisions>
## Implementation Decisions

### Surface Division of Labor

- **D-01:** Two seed surfaces keep **distinct, non-overlapping responsibilities.**
  `operator_fixtures.ex` (browser tenant, drives `operator.spec.js` via `GET /browser-reset`)
  owns **replay-flow depth** (the existing exact / ambiguous / noop scenarios driven by row
  index), **plus** a new **inbound seed** (to un-skip the gated inbound test at
  `operator.spec.js:248/254`) and the **empty-result tenant**.
  `demo_data.ex` (northstar tenant, drives `demo.spec.js` via `POST /demo/evidence/reset`) owns
  **breadth** — full event-timeline badge taxonomy, all inbound outcomes, orphan-backlog,
  failed-ingest, reconciled/unmatched facts, and truncation stress rows.
  *Rationale:* `operator.spec.js` hard-binds replay tests to `deliveryRow(0..3)` with no
  testid/recipient anchor; breadth additions there would shift indices. `demo.spec.js` asserts
  only list/timeline visibility, so it tolerates breadth without index coupling.

- **D-02:** The **empty-result state** is reached by seeding a **second tenant with zero rows**
  (constant such as `"empty-tenant"`) and navigating with its `?tenant_id=`. No demo/browser
  data is removed. Queries are strictly tenant-scoped (`load_deliveries/1`,
  `SupportSummary.summarize_tenant/1`), so a sibling empty tenant reaches every empty state
  (empty deliveries list, empty inbound, all-zero support cards). The "Select a tenant…"
  overview state remains separately reachable with a blank `tenant_id`.

### Status Taxonomy & Badge Coverage

- **D-03:** "All 14 Anymail outbound statuses" means **event-timeline badges keyed on
  `event.type`**, NOT `delivery.status` (which has only 5 enum values: `:queued, :sent,
  :dispatched, :failed, :suppressed`). Seed `Event` rows of **each of the 14 Anymail types**
  (`queued, sent, rejected, failed, bounced, deferred, delivered, autoresponded, opened,
  clicked, complained, unsubscribed, subscribed, unknown`) on northstar deliveries so every
  branch of `components.ex status_badge/1` renders. **Canonical schema atoms govern** — the
  loose past-tense names in the success-criterion text (`:accepted/:rejected/:bounced/
  :failed_ingest`) map to the real atoms (inbound: `[:no_match, :accept, :ignore, :reject,
  :bounce, :failed]`; `:failed_ingest` → outcome `:failed`).

- **D-04:** Inbound badges render via `normalize_inbound_outcome/1` (`:accept→:accepted`, etc.,
  `components.ex:126-129`). Seed at least one inbound execution run for **each** inbound outcome
  so each inbound badge color is reachable.

- **D-05:** **Replay-outcome** states derive from `Event` rows — `type: :webhook_replay_succeeded`
  with `metadata["outcome"]` of `"replayed"` (new work) or `"noop"` (no change), and
  `type: :webhook_replay_failed` (failed). Seed all three so the replay-outcomes Tier-1 support
  card renders each branch (counts come from `support_summary.ex:97-117`).

- **D-06:** **Reconciled vs unmatched** (both support-card branches) derive from orphan `Event`
  rows (`needs_reconciliation: true, delivery_id: nil`) plus a linked `type: :reconciled` event
  keyed by `metadata["reconciled_from_event_id"]`. Seed **both** a reconciled fact and a
  still-unmatched orphan so both branches of the reconcile-facts support card render
  (`support_summary.ex:190-210`, branches gated on count `> 0` in `support_cards.ex:180-207`).
  `:reconciled` events must originate from the reconciler path shape — do not hand-insert a type
  the changeset rejects (`event.ex:56`).

### Row-Index Stability

- **D-07:** New breadth/stress/empty/inbound rows are inserted at **strictly older timestamps**
  (e.g. `minutes_ago(120+)`), because deliveries sort `desc: last_event_at, desc: inserted_at,
  desc: id` (`deliveries.ex:29-33`) and inbound sort `desc: received_at, desc: inserted_at`
  (`records.ex:50-52`). This preserves `operator.spec.js` row indices 0–3 (selected=0, noop=1,
  ambiguous=2, exact=3). **Do not** convert `operator.spec.js` to testid/recipient selectors this
  phase — append-older keeps the diff small and the regression surface low.

### Truncation Stress

- **D-08:** Truncation is the Tailwind `truncate` (single-line ellipsis) class on recipient
  (`deliveries_list.ex:44`) and inbound subject (`records_list.ex:50`); no `line-clamp`, no schema
  length cap. Seed a recipient local-part of ~80 chars and an inbound subject of ~150 chars to
  decisively overflow the `min-w-0` flex column. Masking (`mask_recipient`) preserves length, so a
  long local part still overflows post-mask.

### Same-Commit Assertion Contract

- **D-09:** `demo.spec.js` and `operator.spec.js` seed-count / row assertions are updated in the
  **same commit** as the seed expansion (SEED-02). No follow-up fixup PR. `reference/demo_app/
  mix.exs` and `reference/host_app/mix.exs` version pins stay **unchanged**.

- **D-10 (constraint — NOT in scope to fix):** The pre-existing `operator.spec.js:104` "exact
  replay flow shows ready copy and records a new-work outcome" failure is **Phase 79 debt**
  (`resolves_phase: 79`, surfaced in Phase 77; fails identically against the pre-77 baseline). The
  Phase 78 "Playwright passes without a follow-up fixup" criterion is read as: *no NEW failures
  introduced; the one known pre-existing failure stays documented and excluded.* Phase 78 must
  neither be blamed for it nor attempt to fix it.

### Claude's Discretion

- Exact stress-row character counts (≥ the D-08 minimums), the precise tenant-id string for the
  empty tenant, and how many event rows back each badge demonstration are left to the planner —
  the constraints above bound the choices.

### Folded Todos

None folded — the one matched todo is explicitly assigned to Phase 79 (see D-10 / Deferred).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — status-badge taxonomy table,
  empty/error/loading state inventory, support-card Tier-1/Tier-2 hierarchy, Health Count Colors.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — GAP-13, GAP-16 (the
  severity-3 anti-churn citations for SEED-01).
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — every e2e
  heading/seed-count/row-index assertion baseline that Phase 78 ripples (esp. the Seed-Count
  Baseline Summary and the row-index rows flagged "Phase 78 (SEED-02)").
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` — northstar breadth seed surface.
- `mailglass_admin/test/support/operator_fixtures.ex` — browser-tenant replay-depth seed surface.
- `mailglass_admin/e2e/operator.spec.js` + `reference/demo_app/assets/e2e/demo.spec.js` — the
  two spec files whose assertions update in the same commit.
- `mailglass_admin/lib/mailglass_admin/components.ex` — `status_badge/1` taxonomy (every badge atom
  needing a seeded row) + `normalize_inbound_outcome/1`.
- `mailglass/lib/.../operator/support_summary.ex` — `summarize_tenant/1`: orphan_backlog,
  failed_ingest, replay_outcomes, reconcile_facts data sources and branch conditions.
- `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` — replay/reconcile UI labels.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassDemo.DemoData` (`demo_data.ex`) already has private builders: `delivery!/1`, `event!/4`,
  `webhook!/…`, `suppression!/4`, `inbound_record!/1`, `inbound_evidence!/2`, `inbound_run!/…`,
  `minutes_ago/1`. Breadth seeding extends these — no new infra.
- `MailglassAdmin.OperatorFixtures.seed_browser_scenario!/0` + `reset!/0` — browser-tenant surface
  with exact/ambiguous/noop replay scenarios already present; helpers `insert_delivery!`,
  `insert_event!`, `insert_webhook_event!`, `insert_linked_event!`, `insert_suppression!`.
- `SupportSummary.summarize_tenant/1` is the existing data seam for all support-card counts — no
  new query infrastructure needed (UI-SPEC D-? note at `74-UI-SPEC.md:265`).

### Established Patterns
- Append-only `mailglass_events`: UPDATE/DELETE raises SQLSTATE 45A01 — seeds INSERT only; truncate
  uses `RESTART IDENTITY CASCADE`.
- `:reconciled` events must come from the reconciler-path shape; the Event changeset rejects
  arbitrary insertion (`event.ex:56`).
- Delivery row ordering `desc: last_event_at, inserted_at, id`; inbound `desc: received_at,
  inserted_at` — timestamp choice controls list index.
- `tenant_id` on every record; all operator queries strictly tenant-scoped.

### Integration Points
- `demo.spec.js` reset → `POST /demo/evidence/reset` (token-gated) → `DemoData.reset!()`.
- `operator.spec.js` reset → `GET /browser-reset` → `OperatorFixtures.reset!` +
  `seed_browser_scenario!`.
- The demo_app mounts the admin operator, so `demo_data.ex` breadth drives the demo operator's
  support cards and timeline badges; `operator_fixtures.ex` drives the admin test gate.
</code_context>

<specifics>
## Specific Ideas

- Canonical inbound outcome atoms: execution_run `[:no_match, :accept, :ignore, :reject, :bounce,
  :failed]`; replay_run `[:accept, :ignore, :reject, :bounce, :failed]`. Badge normalization maps
  `:accept→:accepted` etc.
- 14 Anymail event types (per CLAUDE.md): queued, sent, rejected, failed, bounced, deferred,
  delivered, autoresponded, opened, clicked, complained, unsubscribed, subscribed, unknown.
- Replay outcome metadata key: `metadata["outcome"]` ∈ `"replayed" | "noop"` on
  `:webhook_replay_succeeded`; `:webhook_replay_failed` for the failed branch.
</specifics>

<deferred>
## Deferred Ideas

- Converting `operator.spec.js` replay tests from row-index selectors (`deliveryRow(0..3)`) to
  stable testid/recipient selectors — deliberately deferred (D-07); larger diff, not needed when
  append-older preserves indices.

### Reviewed Todos (not folded)
- `preexisting-replay-flow-e2e-failure.md` — **NOT folded.** Explicitly `resolves_phase: 79`
  (operator.spec.js:104 "exact replay flow" timeline assertion; confirmed pre-existing, fails
  against pre-77 baseline). Captured as constraint D-10 — Phase 78 must not be blamed for it nor
  fix it; triage belongs to the Phase 79 verification wave.
</deferred>
