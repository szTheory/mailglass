# Phase 78: Seed-Data Expressiveness — Research

**Researched:** 2026-06-04
**Domain:** Demo and browser-fixture seed expansion; Playwright e2e assertion alignment
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Two seed surfaces — distinct, non-overlapping responsibilities.
  - `operator_fixtures.ex` (browser tenant): replay-flow DEPTH (existing exact/ambiguous/noop) + new inbound seed (to un-skip `operator.spec.js:254`) + empty-result tenant.
  - `demo_data.ex` (northstar tenant): BREADTH — full event-timeline badge taxonomy, all inbound outcomes, orphan-backlog, failed-ingest, reconciled/unmatched facts, truncation stress rows.
  - Rationale: `operator.spec.js` hard-binds replay tests to `deliveryRow(0..3)`; breadth additions there would shift indices.

- **D-02:** Empty-result state reached by seeding a second tenant (e.g., `"empty-tenant"`) with zero rows and navigating with `?tenant_id=`. No demo/browser data removed. Queries are strictly tenant-scoped.

- **D-03:** "14 Anymail outbound statuses" = event-timeline badges keyed on `event.type` (NOT `delivery.status` which has only 5 enum values). Seed `Event` rows of each of the 14 Anymail types on northstar deliveries. Canonical atoms: `queued, sent, rejected, failed, bounced, deferred, delivered, autoresponded, opened, clicked, complained, unsubscribed, subscribed, unknown`.

- **D-04:** Inbound badges via `normalize_inbound_outcome/1`. Seed at least one inbound execution run for each inbound outcome atom: `:no_match, :accept, :ignore, :reject, :bounce, :failed`.

- **D-05:** Replay-outcome states from `Event` rows — `type: :webhook_replay_succeeded` with `metadata["outcome"]` of `"replayed"` or `"noop"`, and `type: :webhook_replay_failed`. Seed all three.

- **D-06:** Reconciled vs unmatched — both branches of reconcile-facts support card. Orphan `Event` rows (`needs_reconciliation: true, delivery_id: nil`) + linked `type: :reconciled` event keyed by `metadata["reconciled_from_event_id"]`. `:reconciled` events must originate from the reconciler-path shape.

- **D-07:** New rows inserted at strictly OLDER timestamps (`minutes_ago(120+)`) to preserve `operator.spec.js` row indices 0–3.

- **D-08:** Truncation = Tailwind `truncate` class (`deliveries_list.ex:44`, `records_list.ex:50`). Seed recipient local-part ~80 chars and inbound subject ~150 chars.

- **D-09:** `demo.spec.js` and `operator.spec.js` seed-count/row assertions updated in the SAME commit as seed expansion. `mix.exs` version pins unchanged.

- **D-10 (constraint — NOT in scope):** Pre-existing `operator.spec.js:104` "exact replay flow" failure is Phase 79 debt. Do NOT fix it; do NOT let it block Phase 78.

### Claude's Discretion

- Exact stress-row character counts (at or above D-08 minimums), precise tenant-id string for the empty tenant, and how many event rows back each badge demonstration are left to the planner.

### Deferred Ideas (OUT OF SCOPE)

- Converting `operator.spec.js` replay tests from row-index selectors to stable testid/recipient selectors (larger diff, not needed when append-older preserves indices).
- Pre-existing `operator.spec.js:104` "exact replay flow" failure (Phase 79 debt).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEED-01 | Seed expansion across both seed surfaces so every screen state in the admin dashboard is reachable by a seeded URL | Section 3 (Screen State Coverage Map) details every missing/present seed per surface and builder pattern |
| SEED-02 | Same-commit e2e assertion updates — demo.spec.js and operator.spec.js seed-count/row assertions updated in the same commit as seed expansion; Playwright passes without follow-up fixup | Section 4 (E2E Assertion Change Surface) itemizes every assertion and its expected post-expansion value |
</phase_requirements>

---

## Summary

Phase 78 expands the two seed surfaces to make every dashboard screen state reachable. `demo_data.ex` currently seeds 6 deliveries (5 with events), 4 inbound records (4 outcomes partially covered), and 1 suppression — but misses 8 of 14 event-type badges (`:queued, :rejected, :autoresponded, :opened, :clicked, :complained, :unsubscribed, :subscribed`), has no orphan/reconciled events, no replay-outcome events, no truncation stress rows, and no empty-tenant. `operator_fixtures.ex` seeds 5 deliveries (the 4 replay-depth rows + 1 other) with zero inbound records, which skips the inbound MOTION-02 gate at `operator.spec.js:254`. Both files use only `Event.changeset/1` + `Repo.insert!` for direct seeding — no custom insert helper needed for outbound events.

The `Event` changeset (`event.ex`) accepts all 14 Anymail types plus `:reconciled` and the three replay types through `Ecto.Enum` — the constraint is not at the changeset level but at the semantic level: `:reconciled` events must carry the reconciler-path metadata shape (`reconciled_from_event_id`, `reconciled_provider`, `reconciled_provider_event_id`) and an orphan event must exist with `needs_reconciliation: true, delivery_id: nil` that is NOT yet covered by a `:reconciled` event (as detected by `unresolved_orphans_query`). The `:failed` inbound outcome requires `failure: %{...}` (non-empty map) per `ExecutionRun.validate_outcome_shape/1`.

The same-commit constraint (D-09/SEED-02) is structurally simple: `demo.spec.js` has no row-index assertions and only three implicit invariants (at least one delivery row, at least one inbound row, "AccountMailer" visible). `operator.spec.js` has four row-index couplings (`deliveryRow(0..3)`) that are preserved by the append-older timestamp strategy (D-07) — new seed rows inserted at `minutes_ago(120+)` sort below the existing four rows. The only `operator.spec.js` change needed is un-skipping the gated `test.skip` block at line 254 once an inbound record is seeded in `seed_browser_scenario!`.

**Primary recommendation:** Expand `demo_data.ex` with 8 additional event-type deliveries, add `:ignore` and `:failed` inbound runs, add replay-outcome events (replayed/noop/failed), add an orphan event (`needs_reconciliation: true, delivery_id: nil`) and a `:reconciled` event pointing to a different orphan, add truncation stress rows — all at `minutes_ago(130+)`. Expand `operator_fixtures.ex` with one inbound record + evidence + fresh run, register the empty tenant as a fixture constant. Update `operator.spec.js` to remove the `test.skip` wrapper on line 254. No assertion values change in `demo.spec.js` because its invariants are minimum-count not exact-count.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Badge taxonomy rendering | Frontend (LiveView components) | — | `Components.status_badge/1` renders on component mount from event/delivery/inbound data already in assigns |
| Seed data authoring | Database/Storage | — | Pure DB inserts in Elixir seed files; no UI layer |
| E2e assertion updates | Frontend (Playwright spec) | — | Spec files assert DOM state; updated in same commit as seeds |
| Empty-tenant navigation | API/Backend (query scoping) | Browser/Client (`?tenant_id=` param) | All operator queries are already tenant-scoped; empty tenant is zero-row, not a code change |
| Inbound test gate un-skip | Frontend (Playwright spec) | Database/Storage (seed) | The skip guard is in the spec; removing it requires the seed to exist first |

---

## Standard Stack

### Core (seed authoring)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Mailglass.Events.Event` | 1.4.5 | INSERT-only changeset for outbound event rows | Project's own append-only ledger |
| `MailglassInbound.InboundRecords` | 1.1.5 | `insert_inbound_record/1`, `insert_inbound_evidence/1`, `insert_execution_run/1` | Canonical public API for inbound seed data |
| `Mailglass.Outbound.Delivery` | 1.4.5 | `changeset/1` for delivery rows | Project's own delivery schema |

No new packages are installed in this phase. [VERIFIED: codebase grep] [CITED: demo_data.ex builder pattern]

### Supporting (e2e)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Playwright | ^1.59.1 | Browser-gate e2e spec execution | `npm run test:operator-browser` in `mailglass_admin/`; `npm run test:e2e` in `reference/demo_app/assets/` |

---

## Package Legitimacy Audit

No external packages are installed in Phase 78. This phase modifies only:
- `reference/demo_app/lib/mailglass_demo/demo_data.ex`
- `mailglass_admin/test/support/operator_fixtures.ex`
- `mailglass_admin/e2e/operator.spec.js`
- `reference/demo_app/assets/e2e/demo.spec.js`

**No registry audit required.** All changes are pure seed data (Elixir) and spec updates (JavaScript), consuming already-installed project libraries.

---

## Architecture Patterns

### System Architecture Diagram

```
[POST /demo/evidence/reset]
    → DemoData.reset!()
    → truncate all tables (RESTART IDENTITY CASCADE)
    → seed_outbound!()   → delivery!/1 + event!/4 (breadth: all 14 event types)
    → seed_inbound!()    → inbound_record!/1 + inbound_evidence!/2 + inbound_run!/... (all 6 outcomes)
    → demo.spec.js asserts: ≥1 delivery row, ≥1 inbound row, "AccountMailer" visible

[GET /ops/browser-reset]  (mailglass_admin TestAdopter router)
    → OperatorFixtures.reset!()
    → OperatorFixtures.seed_browser_scenario!()
    → delivery × 5 (replay depth: selected=0, noop=1, ambiguous=2, exact=3, other=4)
    → inbound record × 1 [NEW — Phase 78]
    → operator.spec.js uses deliveryRow(0..3) for replay tests
    → operator.spec.js uses inbound-record-row.nth(0) for MOTION-02 gate [NEW]

[?tenant_id=empty-tenant]
    → all operator queries return [] (no rows for that tenant_id)
    → deliveries list renders empty blank-slate copy
    → inbound list renders empty blank-slate copy
    → support cards show all zeros
```

### Recommended Project Structure (no changes)

The seed files are already in their correct locations. No new files are created:

```
reference/demo_app/lib/mailglass_demo/
    demo_data.ex             # MODIFIED — breadth seed expansion

mailglass_admin/test/support/
    operator_fixtures.ex     # MODIFIED — inbound seed + empty tenant

mailglass_admin/e2e/
    operator.spec.js         # MODIFIED — un-skip test.skip block

reference/demo_app/assets/e2e/
    demo.spec.js             # no change needed (min-count invariants still hold)
```

### Pattern 1: event!/4 shape for Anymail types

**What:** Insert an outbound `Event` row using the existing `event!/4` builder in `demo_data.ex`. The builder calls `Event.changeset/1` and `Repo.insert!`. The `type` field is cast through `Ecto.Enum` which accepts all 14 Anymail types plus the 6 internal types.

**When to use:** Seeding any outbound event type (`:queued`, `:sent`, `:rejected`, etc.) on an existing delivery.

```elixir
# Source: reference/demo_app/lib/mailglass_demo/demo_data.ex:306-319
defp event!(delivery, type, occurred_at, metadata) do
  %{
    tenant_id: @tenant,
    delivery_id: delivery.id,
    type: type,
    occurred_at: occurred_at,
    idempotency_key:
      "demo-event-#{delivery.provider_message_id}-#{type}-#{DateTime.to_unix(occurred_at)}",
    metadata: metadata,
    normalized_payload: %{"recipient" => delivery.recipient}
  }
  |> Event.changeset()
  |> Repo.insert!()
end
```

### Pattern 2: Orphan event shape (needs_reconciliation: true)

**What:** Seed an orphan event — `delivery_id: nil`, `needs_reconciliation: true` — that represents a webhook that arrived before its delivery. This makes `orphan_backlog.count > 0` in `SupportSummary.summarize_tenant/1` which triggers the Tier-1 orphan-backlog support card.

**When to use:** Seeding the orphan-backlog support card branch.

```elixir
# Shape derived from: lib/mailglass/operator/support_summary.ex:190-208
# unresolved_orphans_query: needs_reconciliation == true AND is_nil(delivery_id)
# AND NOT EXISTS a :reconciled event with reconciled_from_event_id = this event's id
%{
  tenant_id: @tenant,
  delivery_id: nil,                    # orphan: no delivery matched yet
  type: :sent,                         # any Anymail type is fine
  occurred_at: minutes_ago(125),
  needs_reconciliation: true,          # marks it as an orphan
  idempotency_key: "demo-orphan-unmatched-001",
  metadata: %{
    "provider" => "sendgrid",
    "provider_event_id" => "sg-demo-orphan-001",
    "webhook_event_id" => "some-uuid",
    "provider_message_id" => "sg-orphan-msg-001"
  },
  normalized_payload: %{}
}
|> Event.changeset()
|> Repo.insert!()
```

### Pattern 3: :reconciled event shape (reconciler-path metadata)

**What:** A `:reconciled` event is the "linked" signal. It MUST carry `metadata["reconciled_from_event_id"]` pointing to a DIFFERENT orphan event's UUID. `SupportSummary.reconcile_facts_summary/3` uses `unresolved_orphans_query` which checks `NOT EXISTS a :reconciled event with reconciled_from_event_id = orphan.id` — so the reconciled event must reference a different orphan than the still-unmatched one.

**When to use:** Seeding `reconcile_facts.reconciled_count > 0` (the reconciled branch).

```elixir
# Shape derived from: lib/mailglass/webhook/reconciler.ex:161-170
# The reconciled event points to an ALREADY-MATCHED orphan (a different event ID)
# so the unresolved_orphans_query excludes it.
%{
  tenant_id: @tenant,
  delivery_id: some_delivery.id,      # linked delivery
  type: :reconciled,
  occurred_at: minutes_ago(122),
  idempotency_key: "reconciled:" <> orphan_event_id_that_is_now_matched,
  metadata: %{
    "reconciled_from_event_id" => orphan_event_id_that_is_now_matched,
    "reconciled_provider" => "sendgrid",
    "reconciled_provider_event_id" => "sg-demo-reconciled-event-001"
  },
  normalized_payload: %{}
}
|> Event.changeset()
|> Repo.insert!()
```

**Critical:** Two separate orphans are required for both support-card branches to render simultaneously:
1. Orphan A with a `:reconciled` event pointing to it (makes `reconciled_count > 0`).
2. Orphan B with NO `:reconciled` event pointing to it (makes `still_unmatched_count > 0` and `orphan_backlog.count > 0`).

### Pattern 4: Replay-outcome events

**What:** Seed `Event` rows with replay types to populate `replay_outcomes_summary`. The `type: :webhook_replay_succeeded` with `metadata["outcome"] = "replayed"` or `"noop"`, and `type: :webhook_replay_failed` for the failed branch.

```elixir
# Source: lib/mailglass/operator/support_summary.ex:97-117
# replayed branch
event!(some_delivery, :webhook_replay_succeeded, minutes_ago(121), %{
  "provider" => "postmark",
  "outcome" => "replayed",
  "webhook_event_id" => "demo-replay-wh-001"
})

# noop branch
event!(some_delivery, :webhook_replay_succeeded, minutes_ago(122), %{
  "provider" => "postmark",
  "outcome" => "noop",
  "webhook_event_id" => "demo-replay-wh-002"
})

# failed branch
event!(some_delivery, :webhook_replay_failed, minutes_ago(123), %{
  "provider" => "postmark",
  "failure_reason" => "webhook_event_not_found"
})
```

### Pattern 5: :failed inbound execution run

**What:** The `:failed` outcome in `ExecutionRun` requires `failure: %{non-empty map}`. The `inbound_run!` builder in `demo_data.ex` passes `outcome_reason` but NOT `failure`. To seed `:failed`, use `InboundRecords.insert_execution_run/1` directly with `execution_failure: %{...}` which the `normalize_execution_attrs/1` function maps to `outcome: :failed, failure: execution_failure`.

```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:69-96
# Use execution_failure key (normalized to outcome: :failed, failure: map)
{:ok, _run} = InboundRecords.insert_execution_run(%{
  tenant_id: @tenant,
  inbound_record_id: failed_record.id,
  inbound_evidence_id: failed_evidence.id,
  source: :fresh,
  executed_at: minutes_ago(135),
  metadata: %{"demo" => true},
  execution_failure: %{"reason" => "parse_error", "provider" => "mailgun"}
})
```

### Pattern 6: :ignore inbound outcome

**What:** `:ignore` requires `mailbox` (present string) and no `outcome_reason` and `failure: %{}`. Pass directly to the existing `inbound_run!` builder.

```elixir
inbound_run!(ignore_record, ignore_evidence, :fresh, :ignore,
  "MailglassDemoWeb.Inbound.SpamMailbox")
```

### Pattern 7: Inbound record for operator_fixtures.ex

**What:** `OperatorFixtures` does not include `MailglassInbound` dependencies. The inbound tables are in the same database. Use the raw SQL insert pattern (similar to `insert_webhook_event!`) or import the `MailglassInbound.InboundRecords` API via the test repo.

**Note:** Looking at `operator_fixtures.ex`, the existing helpers use `TestRepo` (the admin's test repo) for outbound tables and raw SQL for webhook events. For inbound records, the simplest approach is to call `MailglassInbound.InboundRecords.*` functions with `MailglassAdmin.TestRepo` as the repo facade, or use raw SQL inserts matching the schema. The planner must verify which repo the inbound tables use in the admin test context. [ASSUMED — verify by checking OperatorFixtures test env repo config]

### Anti-Patterns to Avoid

- **Hand-inserting `:reconciled` type without reconciler metadata:** The `unresolved_orphans_query` uses `NOT EXISTS` on `metadata->>'reconciled_from_event_id'`; if that key is absent, the orphan will not be treated as matched even if a `:reconciled` event exists.
- **Using the same orphan event ID for both branches:** `unresolved_orphans_query` excludes any orphan that already has a `:reconciled` event pointing to it. You need TWO distinct orphan events: one matched (pointed to by `:reconciled`), one unmatched (no `:reconciled` pointing to it).
- **Inserting breadth rows in `operator_fixtures.ex`:** Would shift `deliveryRow(0..3)` indices; new rows must go in `demo_data.ex` or be inserted at `minutes_ago(120+)` with older timestamps in operator_fixtures.
- **Using `:suppressed` as an event type:** The `delivery.status` field accepts `:suppressed` but `Components.status_badge/1` routes it through the fallback clause (phantom atom per UI-SPEC Conflict 1). Do NOT seed an event of type `:suppressed` expecting a suppressed badge — there is no `:suppressed` in `@anymail_event_types` or `@mailglass_internal_types` that maps to a named badge.
- **Expecting `:subscribed` events from Anymail type.** The atom `:subscribed` IS in `@anymail_event_types` (event.ex:52) and IS a valid `Event.type` value — but it is NOT in the `status_badge/1` values list (components.ex:132-155). Seeding a `:subscribed` event works at the DB level but the badge will fall through to the `badge-outline` fallback. This is correct behavior per UI-SPEC — no conflict, just document it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Seeding `:failed` inbound outcomes | Custom SQL insert | `InboundRecords.insert_execution_run/1` with `execution_failure:` key | `normalize_execution_attrs` maps it correctly; bypassing goes around the changeset validation |
| Idempotency keys for demo events | `Ecto.UUID.generate()` random keys | Pattern from existing `event!/4`: `"demo-event-#{msg_id}-#{type}-#{unix}"` | Prevents duplicate-run confusion and matches project convention |
| Truncation in reset!() | Custom DELETE | Existing `TRUNCATE ... RESTART IDENTITY CASCADE` pattern | Already correct; append-only table constraint is bypassed safely via TRUNCATE (not per-row DELETE) |

---

## Screen State Coverage Map (SEED-01)

This section maps every required screen state to its seed surface, builder, and current presence/gap.

### Outbound Event-Timeline Badges (14 Anymail types)

| Badge atom | `status_class` | Currently seeded in `demo_data.ex`? | Seed action |
|------------|---------------|--------------------------------------|-------------|
| `:queued` | `badge-primary` | No | Add event of type `:queued` on a new delivery (`minutes_ago(130+)`) |
| `:sent` | `badge-primary` | Yes — invite, magic_link, receipt, payment_failed, usage_alert | Already covered |
| `:rejected` | `badge-error` | No | Add event of type `:rejected` on a new delivery |
| `:failed` | `badge-error` | No (delivery.status is :failed but NO event of type :failed) | Add event of type `:failed` |
| `:bounced` | `badge-error` | Yes — payment_failed, usage_alert | Already covered |
| `:deferred` | `badge-warning` | Yes — usage_alert | Already covered |
| `:delivered` | `badge-success` | Yes — invite, magic_link, receipt | Already covered |
| `:autoresponded` | `badge-outline` | No | Add event of type `:autoresponded` |
| `:opened` | `badge-success` | No | Add event of type `:opened` |
| `:clicked` | `badge-success` | No | Add event of type `:clicked` |
| `:complained` | `badge-error` | No | Add event of type `:complained` |
| `:unsubscribed` | `badge-warning` | No | Add event of type `:unsubscribed` |
| `:subscribed` | `badge-outline` (fallback) | No | Add event of type `:subscribed` (renders fallback badge — correct per UI-SPEC) |
| `:unknown` | `badge-outline` | No | Add event of type `:unknown` |

**Missing: 8 event types.** All can be seeded via `event!/4` on new dedicated deliveries inserted at `minutes_ago(130+)`.

### Inbound Outcome Badges (6 outcomes)

| Outcome atom (schema) | Normalized badge atom | Currently seeded? | Seed action |
|-----------------------|-----------------------|-------------------|-------------|
| `:no_match` | `:no_match` | Yes — `no_match` record | Already covered |
| `:accept` | `:accepted` | Yes — `support` record | Already covered |
| `:reject` | `:rejected` | Yes — `spam` record | Already covered |
| `:bounce` | `:bounced` | Yes — `refund` record | Already covered |
| `:ignore` | `:ignore` | No | Add new inbound record + `inbound_run!(record, evidence, :fresh, :ignore, "mailbox")` |
| `:failed` | `:failed_ingest` | No | Add new inbound record + `insert_execution_run` with `execution_failure:` key |

**Missing: 2 inbound outcomes** (`:ignore`, `:failed`).

### Support-Card Branches

| Branch | Data source | Currently present? | Seed action |
|--------|-------------|-------------------|-------------|
| `failed_ingest.count > 0` (Tier 1) | `WebhookEvent` with `status in [:failed, :dead]` | No | Seed a `WebhookEvent` with `status: :failed` (use `webhook!/...` builder, set `status: :failed`) |
| `orphan_backlog.count > 0` (Tier 1) | Orphan `Event` with `needs_reconciliation: true, delivery_id: nil`, in window, no `:reconciled` pointing to it | No | Seed orphan B (unmatched) |
| `replay_outcomes` any nonzero (Tier 1) | `Event` with type in `[:webhook_replay_succeeded, :webhook_replay_failed]` | No | Seed all 3 replay events |
| `reconcile_facts.reconciled_count > 0` (Tier 2 inline) | `Event` with `type: :reconciled` | No | Seed `:reconciled` event pointing at orphan A |
| `reconcile_facts.still_unmatched_count > 0` (Tier 2 inline) | Unresolved orphan count | No | Orphan B (same orphan used for backlog) |
| All-zero (Tier 2 compact row) | All counts zero | Reachable via empty-tenant | D-02 — navigate with `?tenant_id=empty-tenant` |

**Note on `failed_ingest`:** `support_summary.ex:14` defines `@failed_ingest_statuses [:failed, :dead]`. The `WebhookEvent` schema accepts `status` as a string enum (`"succeeded"`, `"failed"`, `"dead"`). The existing `webhook!` builder sets `status: :succeeded`. To seed a failed webhook, pass `status: :failed` (or `"failed"` — the builder stringifies atoms).

### Replay-Outcome States (D-05)

| State | Event type | `metadata["outcome"]` | Currently present? | Action |
|-------|-----------|----------------------|--------------------|--------|
| `:replayed` | `:webhook_replay_succeeded` | `"replayed"` | No | Add via `event!/4` at `minutes_ago(124)` |
| `:noop` | `:webhook_replay_succeeded` | `"noop"` | No | Add via `event!/4` at `minutes_ago(125)` |
| `:failed` | `:webhook_replay_failed` | n/a | No | Add via `event!/4` at `minutes_ago(126)` |

### Empty-Result State (D-02)

| State | How to reach | Currently present? | Action |
|-------|-------------|-------------------|--------|
| Empty deliveries list (blank slate) | `?tenant_id=empty-tenant` | Reachable now (any non-existent tenant_id works) | No seed data needed — ensure `OperatorFixtures` exports `empty_tenant_id/0 = "empty-tenant"` constant for test navigation |
| Empty inbound list | Same tenant | Reachable now | Same |
| All-zero support cards | Same tenant | Reachable now | Same |
| "Select a tenant" overview state | Blank `tenant_id` param | Already present | No change |

### Truncation Stress Rows (D-08)

| Field | `truncate` location | Minimum length | Currently seeded? | Action |
|-------|-------------------|----------------|-------------------|--------|
| Delivery `recipient` local-part | `deliveries_list.ex:44` | ~80 chars local-part | No — longest existing is ~30 chars | Add delivery with recipient like `"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@northstar-stress.example"` |
| Inbound `subject` | `records_list.ex:50` | ~150 chars | No — longest existing is ~55 chars | Add inbound record with subject of ~150+ chars |

**Note:** `mask_recipient/1` masks to `"a****@n*********************.example"` shape — the local-part still produces a long masked string (first char + stars × length), so a long local-part DOES overflow the `min-w-0 truncate` container even after masking. [VERIFIED: components.ex:270-275]

### Operator-Fixtures Inbound Seed (D-01, gated test un-skip)

| State | Location | Currently present? | Action |
|-------|----------|-------------------|--------|
| Inbound record for `browser-tenant` | `operator_fixtures.ex` | No (zero inbound records) | Add one `inbound_record` + evidence + fresh `:accept` run for `browser-tenant` at `minutes_ago(20)` (browser scenario uses `DateTime.utc_now()` based helpers — see `inbound_run!` in demo) |
| Gated test un-skip | `operator.spec.js:254` | `test.skip(...)` | Remove `test.skip` wrapper; implement the 4-step assertion from the comment |

---

## E2E Assertion Change Surface (SEED-02)

### operator.spec.js — Changes Required

| spec:line | assertion kind | current value | phase 78 change | risk |
|-----------|---------------|---------------|-----------------|------|
| operator.spec.js:254 | `test.skip(...)` | skipped | Remove skip wrapper; implement: navigate to `/ops/mail/inbound?tenant_id=browser-tenant`, click nth(0) inbound row, get `inbound_id` from URL, assert `#inbound-detail-${inboundId}` visible | **Required by SEED-02** |
| operator.spec.js:43 | `deliveryRow(page, 0)` | index 0 = selected_delivery (hours_ago(1)) | UNCHANGED — new seeds use `minutes_ago(120+)` which sorts below hours_ago(1) | No change needed |
| operator.spec.js:78 | `deliveryRow(page, 0)` | same | UNCHANGED | No change needed |
| operator.spec.js:108 | `deliveryRow(page, 3)` | index 3 = exact_delivery (hours_ago(2)) | UNCHANGED — preserved by D-07 | No change needed |
| operator.spec.js:124 | `deliveryRow(page, 2)` | index 2 = ambiguous_delivery (hours_ago(2)) | UNCHANGED | No change needed |
| operator.spec.js:154 | `deliveryRow(page, 1)` | index 1 = noop_delivery (hours_ago(2)) | UNCHANGED | No change needed |

**Row index stability verification:** Current ordering for `browser-tenant` deliveries (sort: `desc: last_event_at, inserted_at, id`):
- Index 0: `selected_delivery` — `last_event_at: hours_ago(1)` = newest
- Index 1: `noop_delivery` — `last_event_at: hours_ago(2)` (tied with exact and ambiguous, ordered by `inserted_at`)
- Index 2: `ambiguous_delivery` — `last_event_at: hours_ago(2)` (same)
- Index 3: `exact_delivery` — `last_event_at: hours_ago(2)` (same)
- Index 4: `browser-other` — `last_event_at: hours_ago(6)`

New breadth rows will use `minutes_ago(120+)` which equals `hours_ago(2+)` — they will slot AFTER index 4. Row indices 0–3 are protected. [VERIFIED: operator_fixtures.ex:16-135 + deliveries.ex:29-33]

**Important note:** `operator_fixtures.ex` uses `DateTime.utc_now()` based helpers (`hours_ago/1`), not a fixed `@now` timestamp like `demo_data.ex`. This means the inbound seed must also use `hours_ago/N` with N large enough to sort below existing rows.

### demo.spec.js — Changes Required

| spec:line | assertion kind | current value | phase 78 change | risk |
|-----------|---------------|---------------|-----------------|------|
| demo.spec.js:5 | seed-reset | `POST /demo/evidence/reset → ok()` | UNCHANGED — reset endpoint contract preserved | No change needed |
| demo.spec.js:20 | `getByText("AccountMailer")` | present | UNCHANGED — existing mailable not renamed | No change needed |
| demo.spec.js:31 | `operator-delivery-row.first()` exists | implicit ≥1 | UNCHANGED — new seeds add MORE rows, never remove | No change needed |
| demo.spec.js:31 | `phx-value-id` non-null | implicit | UNCHANGED | No change needed |
| demo.spec.js:45 | `inbound-record-row.first()` exists | implicit ≥1 | UNCHANGED — 4 inbound records already exist; adding 2 more | No change needed |
| demo.spec.js:45 | `phx-value-id` non-null on inbound row | implicit | UNCHANGED | No change needed |

**Conclusion: `demo.spec.js` requires zero assertion updates.** Its invariants are minimum-count (at least one row) rather than exact-count, and new breadth seed rows only add to the count. [VERIFIED: demo.spec.js full read]

---

## Common Pitfalls

### Pitfall 1: `:reconciled` event without proper orphan pairing
**What goes wrong:** Seeding a `:reconciled` event that points to a non-existent orphan ID, or having BOTH branches point at the same orphan ID, causing either `reconciled_count` or `still_unmatched_count` to be zero.
**Why it happens:** `unresolved_orphans_query` uses `NOT EXISTS (SELECT reconciled events WHERE reconciled_from_event_id = orphan.id)`. If the `:reconciled` event's `metadata["reconciled_from_event_id"]` does not match any orphan's `.id`, the support card branch will not render.
**How to avoid:** Create two distinct orphan events (A, B). Create a `:reconciled` event pointing at orphan A's ID. Orphan B remains unmatched. Both branches render.
**Warning signs:** `reconcile_facts.reconciled_count = 0` in the support summary despite inserting a `:reconciled` event.

### Pitfall 2: `:failed` inbound outcome requires `failure:` non-empty map
**What goes wrong:** Calling `inbound_run!(record, evidence, :fresh, :failed, mailbox)` (or passing `outcome: :failed` directly to `insert_execution_run`) without a `failure:` map causes `validate_outcome_shape/1` to fail.
**Why it happens:** `ExecutionRun.changeset` enforces `outcome == :failed and map_size(failure) > 0`.
**How to avoid:** Use `execution_failure: %{"reason" => "parse_error"}` key in `insert_execution_run` attrs. The `normalize_execution_attrs/1` function remaps this to `outcome: :failed, failure: map`.
**Warning signs:** `{:error, changeset}` with "must be :no_match, :accept, :ignore..." error.

### Pitfall 3: Row index drift from timestamps
**What goes wrong:** Adding a seed row to `operator_fixtures.ex` with a `last_event_at` newer than `hours_ago(2)` shifts `deliveryRow(1)`, `deliveryRow(2)`, or `deliveryRow(3)` expectations in operator.spec.js.
**Why it happens:** Delivery ordering is `desc: last_event_at, inserted_at, id`. New rows inserted in `seed_browser_scenario!` will push existing replay rows to higher indices if their timestamp is newer.
**How to avoid:** Any new delivery in operator_fixtures.ex (or inbound record) must use a timestamp OLDER than `hours_ago(6)` (the `browser-other` delivery). Use `hours_ago(10)` or more for inbound seeds.
**Warning signs:** operator.spec.js test 3/4/5 failures reporting wrong recipient text (wrong delivery selected at that index).

### Pitfall 4: `failed_ingest` support card requires WebhookEvent with failed status
**What goes wrong:** Seeding a delivery with `status: :failed` does NOT trigger `failed_ingest.count > 0`. The query is on `WebhookEvent.status in [:failed, :dead]`, not `Delivery.status`.
**Why it happens:** `support_summary.ex:14` defines `@failed_ingest_statuses [:failed, :dead]` and queries `WebhookEvent`, not `Delivery`.
**How to avoid:** Use the `webhook!` builder with `status: :failed` (or `event_type_normalized: "failed"`). The builder currently defaults to `status: :succeeded`.
**Warning signs:** `failed_ingest.count = 0` in the support summary despite deliveries having `status: :failed`.

### Pitfall 5: 24-hour window for support summary queries
**What goes wrong:** Orphan events, replay events, failed-ingest events, and reconciled events inserted with `minutes_ago(1500)` (25+ hours ago) will NOT appear in support-card counts.
**Why it happens:** `support_summary.ex:25` uses `@default_window_hours 24` — all subqueries filter `occurred_at >= window_started_at` (or `received_at` for webhooks).
**How to avoid:** Insert all new northstar breadth rows at `minutes_ago(120+)` (2–6 hours ago), well within the 24-hour window. D-07 requires strictly older than existing rows (newest existing is `minutes_ago(5)`), so `minutes_ago(120)` is safe.
**Warning signs:** Support cards show Tier 2 (zero-state) despite seeds being present.

### Pitfall 6: OperatorFixtures inbound insert needs the right repo
**What goes wrong:** `MailglassInbound.InboundRecords.*` functions use `MailglassInbound.Repo` internally. In the admin test context, `MailglassAdmin.TestRepo` is the test repo. Raw SQL inserts to inbound tables may fail if using the wrong repo reference.
**Why it happens:** The mailglass_admin test environment mounts the inbound tables on its own `TestRepo` facade, but `InboundRecords` functions default to their own repo.
**How to avoid:** Use direct SQL inserts to `mailglass_inbound_records`, `mailglass_inbound_evidence`, and `mailglass_inbound_replay_runs` tables in `operator_fixtures.ex` (matching the raw SQL pattern used for `insert_webhook_event!`), OR verify that passing `repo: MailglassAdmin.TestRepo` works with the InboundRecords API. [ASSUMED — planner must verify repo injection pattern]
**Warning signs:** `(DBConnection.OwnershipError)` or wrong repo process during operator_fixtures reset.

---

## Code Examples

### Verified patterns from codebase

#### Orphan event insertion (needs_reconciliation: true)
```elixir
# Source: lib/mailglass/operator/support_summary.ex:190-208 (unresolved_orphans_query shape)
# Source: lib/mailglass/events/event.ex:109-113 (cast fields)
orphan_b = %{
  tenant_id: @tenant,
  delivery_id: nil,
  type: :sent,
  occurred_at: minutes_ago(128),
  needs_reconciliation: true,
  idempotency_key: "demo-orphan-unmatched-001",
  metadata: %{
    "provider" => "sendgrid",
    "provider_event_id" => "sg-orphan-unmatched",
    "webhook_event_id" => "00000000-0000-0000-0000-000000000001",
    "provider_message_id" => "sg-orphan-msg-002"
  },
  normalized_payload: %{}
}
|> Event.changeset()
|> Repo.insert!()
```

#### :reconciled event insertion
```elixir
# Source: lib/mailglass/webhook/reconciler.ex:161-170 (canonical shape)
%{
  tenant_id: @tenant,
  delivery_id: some_delivery.id,
  type: :reconciled,
  occurred_at: minutes_ago(127),
  idempotency_key: "reconciled:" <> to_string(orphan_a.id),
  metadata: %{
    "reconciled_from_event_id" => to_string(orphan_a.id),
    "reconciled_provider" => "postmark",
    "reconciled_provider_event_id" => "pm-demo-orphan-a-event"
  },
  normalized_payload: %{}
}
|> Event.changeset()
|> Repo.insert!()
```

#### OperatorFixtures inbound seed pattern (raw SQL — mirrors insert_webhook_event! style)
```elixir
# Source: mailglass_admin/test/support/operator_fixtures.ex:214-241
# Pattern: raw SQL insert matching the schema
# The inbound tables (mailglass_inbound_records, mailglass_inbound_evidence,
# mailglass_inbound_replay_runs) must be inserted in dependency order.
# NOTE: exact SQL shape must be verified against the inbound schema migration.
# [ASSUMED — planner must verify column set]
```

---

## Runtime State Inventory

This is a seed-data phase, not a rename/migration phase. No runtime state is renamed. The `truncate!` / `reset!` functions use `RESTART IDENTITY CASCADE` which correctly resets all referenced tables. No stored data, live service config, OS-registered state, secrets, or build artifacts are affected.

**None — verified by audit of scope (data-only seed expansion, no renames, no schema changes).**

---

## Open Questions (RESOLVED)

1. **RESOLVED — OperatorFixtures inbound insert: which repo?** Use raw SQL against `mailglass_inbound_records` via `TestRepo.query!/2`, matching the existing `insert_webhook_event!` pattern; planner directs the executor to read the inbound migrations to assemble the exact column set first.
   - What we know: `InboundRecords.*` functions use `MailglassInbound.Repo` internally. `operator_fixtures.ex` uses `MailglassAdmin.TestRepo` for its outbound inserts and raw SQL for webhook events.
   - What's unclear: Whether `InboundRecords.insert_inbound_record/1` can be called in the admin test env, or whether raw SQL against `mailglass_inbound_records` via `TestRepo.query!/2` is the safer pattern.
   - Recommendation: Use raw SQL inserts for the inbound record, evidence, and run in operator_fixtures.ex, matching the `insert_webhook_event!` pattern. If `MailglassInbound.InboundRecords` exports repo-injection opts, use those. Planner should check `mailglass_admin/test/support/endpoint_case.ex` for sandbox setup to confirm table availability.

2. **RESOLVED — `subscribed` event type badge rendering.** Seed a `:subscribed` event for completeness; it renders via the `badge-outline` fallback (correct per UI-SPEC Conflict 1). Details below.
   - What we know: `:subscribed` is in `Event.__types__` (event.ex:52) and can be inserted. It is NOT in the `status_badge/1` `attr :status, :atom, values:` list (components.ex:132-155). Passing `:subscribed` to `status_badge/1` will fall through to the `badge-outline` fallback.
   - What's unclear: Whether the timeline renders `:subscribed` events at all (there may be a guard like `event_badge(event.type)` that suppresses them).
   - Recommendation: Seed a `:subscribed` event for completeness; document in plan comments that it renders as fallback `badge-outline`. This is correct per UI-SPEC Conflict 1.

3. **RESOLVED — `demo.spec.js` heading assertions after Phase 75.** The spec files already reflect Phase 75 changes; Phase 78 does NOT need to update these heading assertions. Details below.
   - What we know: Phase 75 already shipped (or is co-parallel). Current `demo.spec.js:27` asserts `"Operator overview"` (already updated from Phase 75 work — confirmed in spec file). `operator.spec.js:19` also asserts `"Operator overview"`.
   - What's unclear: Whether Phase 75's heading changes are already committed to the spec files.
   - Recommendation: The spec files already reflect Phase 75 changes (the actual spec files read show the Phase-75-era assertions, not the ASSERTION-INVENTORY baseline). Phase 78 does NOT need to update these heading assertions.

---

## Environment Availability

This phase requires only:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Seed file compilation | Yes | 1.18+ (project requirement) | — |
| PostgreSQL | Seed DB inserts | Yes (project requirement) | 15+ | — |
| Node.js (Playwright) | E2e test execution | Yes (project CI) | 20+ | — |

No new environment dependencies. No bundle rebuild required (data-only changes). [VERIFIED: CLAUDE.md "no Node toolchain anywhere" — this refers to CSS build; Playwright runs in CI via npm scripts in `assets/` and `mailglass_admin/`]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| E2e framework | Playwright 1.59.1 |
| E2e config (admin) | `mailglass_admin/playwright.config.cjs` |
| E2e config (demo) | `reference/demo_app/assets/playwright.config.cjs` |
| Admin run command | `npm run test:operator-browser` (from `mailglass_admin/`) |
| Demo run command | `npm run test:e2e` (from `reference/demo_app/assets/`) |
| Unit test (admin) | `mix test --warnings-as-errors --exclude flaky` (from `mailglass_admin/`) |
| Full gate | `mix verify.preview` (compile + test + asset build + git diff priv/static) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| SEED-01 | All 14 outbound event-type badges seeded | Visual/e2e | `npm run test:operator-browser` (demo) — asserts delivery row exists and timeline visible | Full badge coverage is a visual assertion confirmed by Playwright loading the operator with northstar tenant |
| SEED-01 | All 6 inbound outcome badges seeded | Visual/e2e | `npm run test:e2e` (demo) — asserts inbound row exists and detail header visible | |
| SEED-01 | Orphan-backlog support card Tier 1 present | Integration | `mix test test/mailglass_admin/operator_live_test.exs` | Support cards render from summarize_tenant; existing tests cover card rendering |
| SEED-01 | Reconcile-facts both branches present | Integration | Same as above | |
| SEED-01 | Replay-outcome support card Tier 1 present | Integration | Same as above | |
| SEED-01 | Empty-tenant zero-state reachable | e2e | Manual navigation with `?tenant_id=empty-tenant` — confirmed by empty list assertion | |
| SEED-01 | Truncation stress rows in list | e2e | `npm run test:operator-browser` / `npm run test:e2e` — rows appear in list | Truncation is visual; Playwright confirms rows load |
| SEED-02 | demo.spec.js passes after seed expansion | e2e | `npm run test:e2e` | No assertion value changes needed |
| SEED-02 | operator.spec.js passes after seed expansion + un-skip | e2e | `npm run test:operator-browser` | Un-skip test at line 254; new inbound seed enables it |
| SEED-02 | Pre-existing line 104 failure still pre-existing (not regressed) | e2e | Manual check / `test.only` isolation | D-10 — EXCLUDED from Phase 78 pass criteria; failure count does not increase |

### Sampling Rate

- **Per task commit:** `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs` (covers support-card rendering)
- **Per wave merge:** `mix verify.preview` in `mailglass_admin/` + `npm run test:e2e` in `reference/demo_app/assets/`
- **Phase gate:** Full `npm run test:operator-browser` green (excluding the known pre-existing line 104 failure per D-10) before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. No new test files need to be created. The un-skip of `operator.spec.js:254` is a spec modification, not a new file.

---

## Security Domain

This phase makes no changes to authentication, authorization, input validation, or cryptographic operations. All changes are read-only seed data inserts (test/dev only) and spec file updates. ASVS categories V2/V3/V4/V6 are not applicable. V5 (input validation) is not applicable — seed data is hardcoded constants, not user-supplied input.

**Security enforcement: not applicable to this phase.** [CITED: CLAUDE.md "telemetry no-PII" — all seeded recipients/subjects are synthetic demo data, not real PII]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `OperatorFixtures` can insert inbound records via raw SQL to `mailglass_inbound_records` using `MailglassAdmin.TestRepo.query!/2` (matching the `insert_webhook_event!` raw SQL pattern) | Pattern 7, Pitfall 6, Open Questions | If repo isolation prevents this, planner needs to restructure the inbound seed as a call to `MailglassInbound.InboundRecords.*` with repo injection — low risk, standard Elixir pattern |
| A2 | New demo_data.ex rows at `minutes_ago(130+)` will sort after index 4 (`browser-other` at `hours_ago(6)`) in operator_fixtures; the append-older principle is correct | Row index stability section | The operator_fixtures use `DateTime.utc_now()` at reset time, so `hours_ago(6)` is ~360 minutes; `minutes_ago(130)` is ~2h10m — they will be NEWER than hours_ago(6), not older. This only affects demo_data.ex (northstar) which does NOT overlap with operator_fixtures (browser-tenant). These are separate tenants. Row index risk is zero for northstar additions. |
| A3 | `:subscribed` event type, when passed to `status_badge/1` in the timeline, renders as `badge-outline` fallback rather than causing a compile-time or runtime error | Anti-patterns, Open Questions | If `status_badge/1` attr `:values` validation is strict at runtime and crashes on unknown atoms, seeding `:subscribed` could break the timeline. Low risk — `Ecto.Enum` accepts `:subscribed`, and the `_status` fallback clause in `status_class/1` handles unknown atoms. |

---

## Sources

### Primary (HIGH confidence)

- `reference/demo_app/lib/mailglass_demo/demo_data.ex` — current seed content, all builders verified by read
- `mailglass_admin/test/support/operator_fixtures.ex` — replay-depth seed, browser scenario verified by read
- `mailglass_admin/lib/mailglass_admin/components.ex:131-253` — full `status_badge/1` atom taxonomy verified
- `lib/mailglass/operator/support_summary.ex` — all four summarize functions verified, window query verified
- `lib/mailglass/events/event.ex` — `@anymail_event_types` + `@mailglass_internal_types` verified
- `lib/mailglass/webhook/reconciler.ex:161-170` — `:reconciled` event metadata shape verified
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` — outcome validation rules verified
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex:69-101` — `normalize_execution_attrs` for `:failed` outcome verified
- `mailglass_admin/e2e/operator.spec.js` — current spec file (includes Phase 75 updates) verified by read
- `reference/demo_app/assets/e2e/demo.spec.js` — current spec file verified by read
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — baseline assertions
- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — badge taxonomy (frozen)
- `lib/mailglass/operator/deliveries.ex:29-33` — sort order verified
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex:50-54` — inbound sort order verified
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:44` — `truncate` class on recipient verified
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex:50` — `truncate` class on subject verified
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — all Tier 1/Tier 2 branch conditions verified

### Secondary (MEDIUM confidence)

- `.planning/phases/78-seed-data-expressiveness/78-CONTEXT.md` — locked decisions, code context
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:202` — SEED-01 cites GAP-13, GAP-16

---

## Metadata

**Confidence breakdown:**
- Screen state coverage map: HIGH — derived directly from reading all badge atoms and current seed content
- Row-index stability analysis: HIGH — verified sort order and timestamp arithmetic
- `:reconciled` event seeding: HIGH — reconciler shape read from source
- OperatorFixtures inbound insert pattern: MEDIUM (A1 assumed) — raw SQL pattern is established but inbound table column set not verified
- Replay outcomes: HIGH — support_summary.ex query shapes verified

**Research date:** 2026-06-04
**Valid until:** Stable — pure data phase, no fast-moving dependencies. Valid until milestone closes.
