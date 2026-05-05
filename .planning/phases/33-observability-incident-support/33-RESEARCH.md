# Phase 33: Observability & Incident Support - Research

**Researched:** 2026-05-05
**Domain:** Operator support UX, telemetry contract alignment, and incident-response documentation for Phoenix/LiveView email operations
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Support surface shape
- **D-33-01:** Phase 33 should ship a hybrid support surface:
  - one canonical operator-facing troubleshooting guide in docs
  - narrow operator-facing support entrypoints inside the existing `mailglass_admin` delivery UI
- **D-33-02:** Do not build a separate in-app observability dashboard or incident center in Phase 33. That would overbroaden the product promise and duplicate LiveDashboard / PromEx / APM territory.
- **D-33-03:** The admin surface should act as the operator starting point for one selected delivery and current support cues, while docs remain the canonical explanation layer for telemetry, incident diagnosis, and escalation paths.
- **D-33-04:** Support guidance, telemetry naming, and admin copy must use the same language. Phase 33 should reduce drift between `guides/telemetry.md`, `guides/webhook-troubleshooting.md`, `guides/webhooks.md`, and the operator UI.

### Incident playbook shape
- **D-33-05:** The troubleshooting guide should use a hybrid information architecture:
  - symptom-first index for operator entry
  - pipeline-stage drilldowns for canonical diagnosis steps
- **D-33-06:** Operators should be able to start from real support prompts such as:
  - “customer says the email never arrived”
  - “provider is retrying or timing out”
  - “orphan backlog is growing”
  - “replay completed but nothing changed”
  and then land on one canonical stage-specific checklist.
- **D-33-07:** Stage drilldowns should reflect the actual mailglass support model:
  - delivery send / projection state
  - webhook signature + ingest
  - orphan / reconcile backlog
  - replay / reconcile repair actions
- **D-33-08:** Every incident path should explicitly distinguish:
  - provider lifecycle facts
  - operator-triggered replay facts
  - background reconcile facts
  Do not flatten these into one vague “repair” story.
- **D-33-09:** Each troubleshooting branch should include an explicit “mailglass can tell you this / mailglass cannot tell you this” note so the support surface stays honest about the boundary between app-local evidence and provider-side evidence.

### Backlog and health signals
- **D-33-10:** Phase 33 should add read-only summary indicators to the existing operator surface rather than requiring operators to infer support posture from raw telemetry or CLI output alone.
- **D-33-11:** Summary indicators should be support-oriented and exemplar-friendly, not chart-heavy. They should answer “what needs attention now?” and lead operators toward a concrete delivery, webhook identity, or reconcile run.
- **D-33-12:** Candidate support cues for this phase include:
  - recent webhook ingest failures
  - orphan count and oldest orphan age
  - reconcile linked vs still-unmatched outcomes
  - replay outcomes split into failed / no change / new work
  - webhook silence or stall cues when they can be stated honestly
- **D-33-13:** Keep deeper dashboarding and time-series visualization optional and external-first via LiveDashboard, OpenTelemetry, PromEx, Grafana, Sentry, Honeycomb, or similar adopter tooling. Phase 33 should not make those stacks mandatory.
- **D-33-14:** Support cues in the admin surface must not imply real-time guarantees, fleet-wide completeness, or provider-side truth that the codebase cannot actually prove.

### PII and privacy posture
- **D-33-15:** Keep the hard no-PII rule for telemetry, logs, and docs. The existing whitelist posture remains structural and should not be relaxed in Phase 33.
- **D-33-16:** Do not overcorrect into a fully redacted operator UI that makes real support work impossible. Mailglass still needs to satisfy the core JTBD of diagnosing a specific message problem.
- **D-33-17:** Adopt a middle-ground UI privacy posture:
  - keep tenant-scoped operator detail useful for authorized operators
  - mask the most human-identifying fields by default in overview-style surfaces where practical
  - require explicit reveal or stronger auth posture for exact human-facing identifiers when appropriate
- **D-33-18:** Any masking/reveal posture introduced here is presentation-layer minimization, not a substitute for route auth, mount auth, action-time auth, tenant scoping, or data redaction at log/inspect boundaries.
- **D-33-19:** Future search, exports, summaries, notes, or AI-assisted support features must be treated as new PII leak paths and held to the same privacy posture. Do not solve only the header/list surface and leave secondary leak paths open.

### Support model and telemetry contract
- **D-33-20:** Phase 33 should stay delivery-centric. Support flows should start from a selected delivery where possible and use telemetry / backlog signals to explain what happened around that delivery, rather than introducing a separate generic observability product surface.
- **D-33-21:** Preserve exactness:
  - replay is exact-target and delivery-entrypoint only
  - reconcile is background-first sweep / backfill behavior
  - provider retries are external lifecycle facts
  The UI and docs must not blur these.
- **D-33-22:** Favor exemplars over aggregates. If a summary signal is surfaced, the operator should be able to drill toward a concrete delivery, raw webhook row, or durable audit fact rather than stopping at a green/red status pill.
- **D-33-23:** Integration guidance should include safe, minimal examples for adopter observability backends using the existing telemetry contract, especially LiveDashboard / OpenTelemetry / Sentry / Honeycomb style integrations, without making them required for mailglass supportability.

### Recommendation-first workflow posture
- **D-33-24:** Downstream research, planning, and implementation for this phase should remain recommendation-first and decisive by default:
  - research broadly
  - synthesize one coherent recommendation set
  - avoid pushing routine local tradeoffs back to the user
- **D-33-25:** Escalate only when a choice would materially change:
  - raw payload retention or audit retention semantics
  - public admin / router / auth / session contract
  - tenant trust boundaries
  - default privacy posture or exposed metadata fields
  - a materially broader product promise, such as a true embedded observability console
- **D-33-26:** This recommendation-first posture should be applied earlier in GSD-style downstream workflows where the codebase, ecosystem norms, and project vision already point to a coherent default. Only very impactful contract or trust decisions should come back to the user.

### Claude's Discretion
- Exact support-card layout, naming, and placement within the existing operator LiveView.
- Exact symptom taxonomy and stage headings for the troubleshooting guide, as long as the hybrid symptom-first plus stage-drilldown structure remains intact.
- Exact thresholds, windows, and wording for support summary indicators, as long as they remain honest, tenant-safe, and exemplar-oriented.
- Exact reveal/masking behavior for operator-visible identifiers, as long as support usefulness remains intact and privacy minimization stays stronger than the current default.

### Deferred Ideas (OUT OF SCOPE)
- None listed in `33-CONTEXT.md`. [VERIFIED: codebase grep]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAT-02 | Operator-facing observability and incident-response/support docs cover delivery, webhook ingest, and reconciliation failure modes without exposing PII. [VERIFIED: codebase grep] | Canonical incident guide, tenant-scoped support cues in `MailglassAdmin.OperatorLive`, and telemetry/docs copy alignment satisfy the requirement without adding a new dashboard or external dependency. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

The smallest honest Phase 33 slice is: keep the existing delivery-centric operator LiveView, add one tenant-scoped support cue layer to that page, and consolidate the support documentation into one canonical operator incident guide. This fits the current codebase because the operator page already has tenant-safe delivery selection, replay availability, replay history, and timeline rendering; the webhook layer already emits PII-safe telemetry and stores enough durable facts to derive support cues without inventing a new incident-state subsystem. [VERIFIED: codebase grep]

The current docs are materially drifted from the shipped implementation. `guides/telemetry.md` still documents obsolete event paths such as `[:mailglass, :deliver]` and `[:mailglass, :reconcile]`, while the shipped code emits `[:mailglass, :outbound, :send, ...]`, `[:mailglass, :webhook, :ingest, ...]`, and `[:mailglass, :webhook, :reconcile, ...]`. `guides/webhook-troubleshooting.md` contains useful incident content, but it is webhook-only and not aligned with the replay/reconcile language now present in Phase 32. Phase 33 should fix that drift first rather than adding broader instrumentation surface area. [VERIFIED: codebase grep]

**Primary recommendation:** Ship one canonical `guides/operator-incident-support.md`, keep `guides/webhooks.md` as the setup/reference guide, slim `guides/telemetry.md` into a current event-contract reference, and add three read-only support cue groups to the existing operator page: webhook ingest failures, orphan/reconcile backlog, and replay outcome cues. Do not add fleet dashboards, incident objects, or mandatory external telemetry backends. [VERIFIED: codebase grep]

## Project Constraints (from CLAUDE.md)

- Use the existing Phoenix/LiveView/Postgres stack; no Node toolchain is part of the core product surface. [VERIFIED: codebase grep]
- Telemetry must stay on `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]`, with whitelisted metadata only and no PII. [VERIFIED: codebase grep]
- `mailglass_events` remains append-only; support features must treat the ledger as durable truth and must not rely on mutable audit state. [VERIFIED: codebase grep]
- Multi-tenancy remains first-class; every support read model must stay tenant-scoped. [VERIFIED: codebase grep]
- `mailglass_admin` stays mountable inside adopter-owned auth; Phase 33 must not introduce hosted auth or weaken the existing route/session boundary. [VERIFIED: codebase grep]
- Optional dependencies must stay optional through `Mailglass.OptionalDeps.*` style gating or equivalent existing patterns; this phase should not make OpenTelemetry or Oban mandatory. [VERIFIED: codebase grep]
- Documentation, UI copy, and logs must stay exact, technical, and not cute; do not imply provider truth the code cannot prove. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Delivery detail support entrypoint | Frontend Server (SSR / LiveView) | API / Backend | `MailglassAdmin.OperatorLive` already owns the selected-delivery UI and calls tenant-scoped read models on the server. [VERIFIED: codebase grep] |
| Support cue aggregation | API / Backend | Database / Storage | Honest cues should come from query modules over `mailglass_webhook_events` and `mailglass_events`, not from client-side inference. [VERIFIED: codebase grep] |
| Replay status and repair facts | Database / Storage | Frontend Server (SSR / LiveView) | Replay truth already lives in append-only `mailglass_events` rows and is rendered in the operator timeline/history. [VERIFIED: codebase grep] |
| Webhook ingest health signals | Database / Storage | API / Backend | Failure state lives in `mailglass_webhook_events.status`; orphan and reconcile facts live in the ledger plus telemetry emissions. [VERIFIED: codebase grep] |
| Canonical incident documentation | Static / Docs | Frontend Server (SSR / LiveView) | The guide should explain the support model, while the LiveView links operators into the right branch from a selected delivery or support cue card. [VERIFIED: codebase grep] |
| Privacy minimization in support UI | Frontend Server (SSR / LiveView) | API / Backend | Masking/reveal here is presentation logic layered on top of existing auth, tenant scoping, and redaction boundaries. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` locked | Existing web surface and router/mount contract for `mailglass_admin`. [VERIFIED: codebase grep] | Phase 33 belongs inside the shipped Phoenix router + LiveView operator surface, not in a separate console. [VERIFIED: codebase grep] |
| Phoenix LiveView | `1.1.28` locked; `1.1.30` latest stable on Hex as of 2026-05-05 | Server-rendered operator UI. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info] | The operator page already uses LiveView URL-backed state and server-side auth/action flows. Reusing that surface minimizes risk. [VERIFIED: codebase grep] |
| `:telemetry` | `1.4.1` locked and current on Hex as of 2026-05-05 | Existing event contract for outbound, webhook ingest, and reconcile instrumentation. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info] | Phase 33 should align docs and operator cues to the current telemetry contract rather than introducing a new signal pipeline. [VERIFIED: codebase grep] |
| Ecto / Postgres | `3.13.5` locked | Querying deliveries, webhook rows, and append-only ledger facts. [VERIFIED: codebase grep] | Honest support cues come from persisted state already in Postgres. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | `2.21.1` locked; `2.22.1` latest on Hex as of 2026-05-05 | Optional background scheduling for reconcile and pruning. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info] | Use only to explain or surface whether background reconcile is available; do not make it mandatory. [VERIFIED: codebase grep] |
| OpenTelemetry | `1.7.0` locked and current on Hex as of 2026-05-05 | Optional adopter-side backend export. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info] | Mention only as an external integration recipe fed by the existing telemetry contract. [VERIFIED: codebase grep] |
| Mix task `mailglass.reconcile` | shipped in repo | Manual background-first maintenance fallback. [VERIFIED: codebase grep] | Use in docs and support cues whenever Oban is absent or a human needs an on-demand sweep. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing operator LiveView + docs | New embedded observability dashboard | Rejected because the roadmap and Phase 33 context explicitly forbid a separate dashboard/incident center in this phase. [VERIFIED: codebase grep] |
| Querying durable read models | Telemetry-only transient health cues | Rejected because telemetry alone cannot populate honest operator exemplars or survive page refresh/history. [VERIFIED: codebase grep] |
| Existing optional external integrations | Shipping PromEx/Grafana/Sentry wiring as a requirement | Rejected because context locks external telemetry stacks to optional, external-first guidance only. [VERIFIED: codebase grep] |

**Installation:** No new dependency is recommended for Phase 33. Use the existing stack and optional integrations already declared in `mix.exs`. [VERIFIED: codebase grep]

**Version verification:** Phoenix LiveView `1.1.30`, Telemetry `1.4.1`, Oban `2.22.1`, and OpenTelemetry `1.7.0` were checked on Hex on 2026-05-05. The repo is currently locked to Phoenix LiveView `1.1.28`, Telemetry `1.4.1`, Oban `2.21.1`, and OpenTelemetry `1.7.0`; this phase does not require upgrading them. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info]

## Architecture Patterns

### System Architecture Diagram

```text
Operator selects tenant + delivery
        |
        v
MailglassAdmin.OperatorLive
        |
        +--> Delivery read model --------------------------+
        |                                                  |
        +--> Timeline read model ------------------------+ |
        |                                                | |
        +--> Replay history / replay target read models  | |
        |                                                | |
        +--> New support cue read model(s)               | |
        |                                                | |
        v                                                v v
  LiveView detail header / support cards / timeline --> Postgres
                                                        |      |
                                                        |      +--> mailglass_webhook_events
                                                        |           status/raw webhook identity
                                                        |
                                                        +--> mailglass_events
                                                             append-only provider, replay, and reconcile facts

Canonical operator incident guide
        |
        +--> symptom-first entry
        +--> stage drilldowns
        +--> telemetry reference links
        +--> safe next actions (replay vs reconcile vs escalate)

Optional adopter telemetry backend
        ^
        |
 Existing :telemetry contract
 (no new backend required)
```

### Recommended Project Structure

```text
guides/
├── operator-incident-support.md   # canonical operator guide
├── telemetry.md                   # current telemetry contract + backend recipes
├── webhooks.md                    # setup/provider/reference guide
└── webhook-troubleshooting.md     # reduced shim or redirect to canonical guide

lib/mailglass/operator/
├── support_summary.ex             # tenant-scoped support cue queries
└── support_exemplars.ex           # optional shaping for card/detail links

mailglass_admin/lib/mailglass_admin/operator/
├── support_cards.ex               # card rendering + copy
└── detail_header.ex               # delivery identity minimization and support link-outs
```

### Pattern 1: Delivery-Centric Support Entry
**What:** Keep support anchored on a selected delivery, then augment the detail view with support cues that explain nearby webhook/reconcile/replay facts. [VERIFIED: codebase grep]
**When to use:** Any incident flow that can start from a customer-reported delivery, replay result, or exemplar link from a support card. [VERIFIED: codebase grep]
**Example:**

```elixir
# Source: lib/mailglass/operator/replay_history.ex + lib/mailglass/operator/replay_targets.ex
def load_delivery_support(tenant_id, delivery_id) do
  %{
    replay_targets: Mailglass.Operator.ReplayTargets.list_delivery_targets(%{
      tenant_id: tenant_id,
      delivery_id: delivery_id
    }),
    replay_history: Mailglass.Operator.ReplayHistory.list_delivery_replay_history(%{
      tenant_id: tenant_id,
      delivery_id: delivery_id
    }),
    timeline: Mailglass.Operator.Timeline.list_delivery_events(%{
      tenant_id: tenant_id,
      delivery_id: delivery_id
    })
  }
end
```

### Pattern 2: Support Cue Cards Backed by Durable Facts
**What:** Build a small query layer that returns count + oldest age + exemplar identity from persisted tables, not from transient telemetry buffers. [VERIFIED: codebase grep]
**When to use:** Tenant-scoped support cards such as orphan backlog, recent failed webhook rows, and replay outcomes. [VERIFIED: codebase grep]
**Example:**

```elixir
# Source pattern: lib/mailglass/webhook/webhook_event.ex + lib/mailglass/events/event.ex
def summary(tenant_id, since) do
  %{
    failed_webhooks: failed_webhook_summary(tenant_id, since),
    orphan_backlog: orphan_summary(tenant_id),
    replay_outcomes: replay_summary(tenant_id, since),
    reconcile_outcomes: reconcile_summary(tenant_id, since)
  }
end
```

### Pattern 3: Symptom-First Docs, Stage-Exact Drilldowns
**What:** Start the guide with plain-language symptoms, then route each symptom into one canonical stage checklist: delivery send/projection, webhook signature/ingest, orphan/reconcile backlog, replay/manual repair. [VERIFIED: codebase grep]
**When to use:** Operator-facing docs where the same incident can begin from a customer report or a support card alert. [VERIFIED: codebase grep]
**Example:**

```markdown
## Symptom: Customer says the email never arrived
1. Check the selected delivery status and latest event.
2. Check whether the latest fact is provider lifecycle, replay audit, or reconcile audit.
3. If no webhook match exists, inspect orphan backlog cues.
4. If provider accepted the message, escalate to provider-side evidence; mailglass cannot prove inbox placement.
```

### Anti-Patterns to Avoid
- **Fake incident objects:** Do not invent a new `incident` schema or state machine just to color the UI. The codebase already has durable delivery, webhook, replay, and reconcile facts. [VERIFIED: codebase grep]
- **Telemetry-only operator UX:** Do not make the operator page depend on in-memory telemetry aggregation or imply real-time completeness. Use persisted exemplars first, telemetry second. [VERIFIED: codebase grep]
- **Provider-truth overclaiming:** `:delivered` means provider/recipient-MTA acceptance, not inbox placement; replay success means reprocessing completed, not that downstream state changed. [VERIFIED: codebase grep]
- **Overview PII leakage:** Do not spread exact recipient and provider identifiers into list-level or summary-level surfaces without minimization. Current detail header shows them directly, so Phase 33 should tighten overview copy instead of broadening exposure. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incident timeline truth | New mutable incident-status table | Existing `mailglass_events` ledger + `Mailglass.Operator.Timeline` / `ReplayHistory` | The ledger already distinguishes provider facts, replay audit, and reconcile audit. [VERIFIED: codebase grep] |
| Replay health inference | Heuristic “repair succeeded” badge logic | Existing replay audit metadata and `RepairState` presenter | Phase 32 already standardized availability/outcome/effect wording. [VERIFIED: codebase grep] |
| Background health subsystem | Mandatory PromEx/APM stack | Existing telemetry contract + optional external recipes | Context explicitly keeps external telemetry stacks optional. [VERIFIED: codebase grep] |
| Cross-tenant triage console | Global operator incident center | Existing tenant-scoped operator mount and read models | Trust boundaries are tenant-first and adopter-auth-owned. [VERIFIED: codebase grep] |

**Key insight:** Phase 33 should compose durable facts already present in the repo. The highest-risk mistake is not underbuilding; it is adding a broader support product promise than the code can honestly back. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Documenting obsolete telemetry names
**What goes wrong:** The support guide points operators at nonexistent event paths or stale metadata keys. [VERIFIED: codebase grep]
**Why it happens:** `guides/telemetry.md` still uses old paths like `[:mailglass, :deliver]` and `[:mailglass, :reconcile]`, while current code emits `[:mailglass, :outbound, :send, ...]` and `[:mailglass, :webhook, :reconcile, ...]`. [VERIFIED: codebase grep]
**How to avoid:** Rewrite `guides/telemetry.md` from the shipped telemetry modules first, then have the canonical incident guide link into that reference instead of duplicating event names. [VERIFIED: codebase grep]
**Warning signs:** Example snippets mention `metadata.function`, `[:mailglass, :deliver]`, or other shapes not present in `lib/mailglass/telemetry.ex` and `lib/mailglass/webhook/telemetry.ex`. [VERIFIED: codebase grep]

### Pitfall 2: Inventing a fake fleet-health model
**What goes wrong:** The UI shows “healthy/unhealthy” incident pills without durable evidence or tenant-safe exemplars. [VERIFIED: codebase grep]
**Why it happens:** It is tempting to convert transient telemetry into global status, but the current codebase only guarantees delivery facts, webhook row status, replay audit rows, and reconcile counts. [VERIFIED: codebase grep]
**How to avoid:** Limit support cards to count/age/exemplar summaries derived from Postgres and label them as attention cues, not guarantees. [VERIFIED: codebase grep]
**Warning signs:** Copy uses “all clear,” “real-time,” “fleet-wide,” or “provider outage” without a durable local fact behind it. [VERIFIED: codebase grep]

### Pitfall 3: Blurring replay and reconcile semantics
**What goes wrong:** Operators are told to “repair” an issue without learning whether replay, background reconcile, or provider retry is the relevant path. [VERIFIED: codebase grep]
**Why it happens:** Replay and reconcile both touch webhook-driven state, but the code treats them differently: replay is exact-target manual action; reconcile is background orphan sweep. [VERIFIED: codebase grep]
**How to avoid:** Keep separate card labels, timeline badges, and guide headings for provider lifecycle, replay audit, and reconcile audit. [VERIFIED: codebase grep]
**Warning signs:** UI or docs say “rerun processing” or “retry the webhook” when the actual step is `mix mailglass.reconcile` or waiting for provider retry. [VERIFIED: codebase grep]

### Pitfall 4: Leaking identifiers in summary surfaces
**What goes wrong:** Support cards or top-level headers expose full human identifiers beyond the selected-delivery context. [VERIFIED: codebase grep]
**Why it happens:** The current detail header shows full `recipient` and `provider_message_id`, and it is easy to reuse that pattern everywhere. [VERIFIED: codebase grep]
**How to avoid:** Keep full detail available inside the authorized selected-delivery pane, but mask or abbreviate identifiers in summary cards and list-level exemplars by default. [VERIFIED: codebase grep]
**Warning signs:** Support cards render raw email addresses, exact webhook payload snippets, or wide fan-out list surfaces. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from shipped code and the current repo:

### Telemetry-backed reconcile summary
```elixir
# Source: lib/mailglass/webhook/reconciler.ex
{:ok, %{scanned: scanned, linked: linked}} = Mailglass.Webhook.Reconciler.reconcile(tenant_id, 1000)
still_unmatched = max(scanned - linked, 0)
```

### Tenant-scoped replay history
```elixir
# Source: lib/mailglass/operator/replay_history.ex
Mailglass.Operator.ReplayHistory.list_delivery_replay_history(%{
  tenant_id: tenant_id,
  delivery_id: delivery_id
})
```

### Operator auth boundary for sensitive actions
```elixir
# Source: mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex
MailglassAdmin.Auth.authorize(adapter, :destructive_action, %{
  actor: operator_actor,
  delivery: delivery,
  replay_target: target
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fragmented support docs (`telemetry.md`, `webhook-troubleshooting.md`, `webhooks.md`) with drifted terminology | One canonical operator incident guide plus focused reference guides | Recommended for Phase 33; not yet shipped | Reduces copy drift and gives operators one entrypoint. [VERIFIED: codebase grep] |
| Stale telemetry examples (`[:mailglass, :deliver]`, `[:mailglass, :reconcile]`) | Current event families under `Mailglass.Telemetry` and `Mailglass.Webhook.Telemetry` | Shipped before Phase 33; docs lag behind | Support docs must be corrected before they can be trusted operationally. [VERIFIED: codebase grep] |
| Replay-only support cues in UI | Support cards for failed ingest, orphan backlog, replay outcomes, and reconcile outcomes | Recommended for Phase 33 | Gives operators enough “what needs attention now?” context without building a dashboard product. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- `guides/telemetry.md` event-path examples are outdated relative to the current telemetry modules and should not be used as the canonical operator reference in their current form. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Keeping `guides/webhook-troubleshooting.md` as a shim path is preferable to deleting it immediately. [ASSUMED] | Open Questions | Low. This affects doc migration ergonomics, not runtime behavior or trust boundaries. |

If planners prefer, they can ignore `A1` and keep the research recommendation set unchanged. [VERIFIED: codebase grep]

## Open Questions

1. **Should `guides/webhook-troubleshooting.md` remain as a thin entry shim or be fully replaced by the canonical operator guide?**
   - What we know: the current troubleshooting content is useful, but it is narrower than the Phase 33 support contract and now overlaps with replay/reconcile docs. [VERIFIED: codebase grep]
   - What's unclear: whether maintainers want to preserve the old path for inbound links or simplify to one guide immediately. [ASSUMED]
   - Recommendation: keep the file path, replace it with a short intro plus links into the canonical guide and `guides/webhooks.md`, then remove duplication. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | LiveView code, docs tests, mix tasks | ✓ | `1.19.5` | — |
| Mix | Test and docs verification commands | ✓ | `1.19.5` | — |
| PostgreSQL CLI | Local DB-backed verification and manual inspection | ✓ | `14.17` | Repo tests can still run if DB service is already available without direct `psql` use |
| Node | Not required by the recommended implementation cut | ✓ | `22.14.0` | Ignore |
| npm | Not required by the recommended implementation cut | ✓ | `11.1.0` | Ignore |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- None found for the recommended Phase 33 slice. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix (`mix test`) on Elixir `1.19.5`. [VERIFIED: codebase grep] |
| Config file | `mix.exs` aliases + `test/` and `mailglass_admin/test/`; no standalone `pytest`/`jest` config applies. [VERIFIED: codebase grep] |
| Quick run command | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs test/mailglass/docs_contract_test.exs test/mailglass/webhook/telemetry_test.exs test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAT-02 | Operator page surfaces support cues without weakening existing replay/auth semantics | integration | `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ |
| MAT-02 | Canonical support docs stay aligned with shipped telemetry and incident workflow terms | docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ |
| MAT-02 | Telemetry reference examples match the current event contract and remain PII-safe | unit/docs | `mix test test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs --warnings-as-errors` | ✅ |
| MAT-02 | Reconcile fallback guidance matches the shipped CLI/reporting contract | unit | `mix test test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors`
- **Per wave merge:** `mix test test/mailglass/webhook/telemetry_test.exs test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors`
- **Phase gate:** `mix test --warnings-as-errors`

### Wave 0 Gaps
- [ ] `test/mailglass/docs/operator_incident_support_guide_test.exs` — assert the canonical guide contains symptom-first entrypoints, stage drilldowns, and “can tell / cannot tell” honesty notes for MAT-02. [VERIFIED: codebase grep]
- [ ] `test/mailglass/operator/support_summary_test.exs` — verify new tenant-scoped support cue queries for failed webhook rows, orphan backlog, replay outcomes, and reconcile outcomes. [VERIFIED: codebase grep]
- [ ] `mailglass_admin/test/mailglass_admin/operator_support_cards_test.exs` or expansion of `operator_live_test.exs` — verify support card copy, exemplar links, and masked identifier defaults. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Adopter-owned `MailglassAdmin.Auth` and operator session whitelist in `MailglassAdmin.Router`. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Operator mount consumes explicit session keys only; no raw session leakage into LiveView assigns. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Tenant-scoped read models plus action-time `:destructive_action` authorization for replay. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Existing filter normalization and explicit required `tenant_id` / `delivery_id` checks in operator read models. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase 33 documents existing webhook verification behavior but does not introduce new cryptographic logic. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data exposure through support cards | Information Disclosure | Keep all support summary queries tenant-scoped and derive exemplar links from tenant-filtered records only. [VERIFIED: codebase grep] |
| PII leakage in telemetry/docs/UI copy | Information Disclosure | Preserve telemetry whitelist, avoid raw payload/recipient exposure in summary surfaces, and keep docs examples free of human identifiers. [VERIFIED: codebase grep] |
| False operator action guidance leading to unsafe replay/reconcile use | Tampering | Keep replay, reconcile, and provider retry as separate documented paths with exact labels. [VERIFIED: codebase grep] |
| Auth bypass by treating support cards as harmless | Elevation of Privilege | Keep the operator surface inside adopter auth and do not add secondary unauthenticated support routes. [VERIFIED: codebase grep] |

## Implementation Sequence

1. Rewrite the docs model first: create the canonical operator incident guide, decide which existing guides become reference docs versus redirects, and update telemetry terminology from shipped code. This gives planners a stable vocabulary before UI work begins. [VERIFIED: codebase grep]
2. Add a backend support-summary query module under `lib/mailglass/operator/` that returns tenant-scoped count/age/exemplar data for failed webhook rows, orphan backlog, replay outcomes, and reconcile outcomes. Do not start in the LiveView template. [VERIFIED: codebase grep]
3. Add support cards to `MailglassAdmin.OperatorLive` above or alongside the existing detail area, keeping the page delivery-centric and linking each cue to either a selected delivery or a drilldown-friendly filter state. [VERIFIED: codebase grep]
4. Tighten privacy presentation in the operator detail and summary surfaces after the cards exist, so copy and masking rules are tested against the real support layout instead of guessed in isolation. [VERIFIED: codebase grep]
5. Finish with docs-contract and UI regression coverage, then run the full suite. This order maximizes verification leverage because the guide and query semantics become the fixed contract the UI tests assert against. [VERIFIED: codebase grep]

## Sources

### Primary (HIGH confidence)
- `CLAUDE.md` - project constraints, telemetry/privacy rules, stack floor, and operator-surface boundaries. [VERIFIED: codebase grep]
- `.planning/phases/33-observability-incident-support/33-CONTEXT.md` - locked Phase 33 decisions and scope. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/METHODOLOGY.md` - milestone goal, requirement text, and workflow posture. [VERIFIED: codebase grep]
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `detail_header.ex`, `timeline.ex`, `repair_state.ex`, `destructive_action.ex`, `mount.ex`, `router.ex` - current operator UI, auth seam, and replay wording. [VERIFIED: codebase grep]
- `lib/mailglass/operator/*.ex`, `lib/mailglass/webhook/*.ex`, `lib/mix/tasks/mailglass.reconcile.ex` - durable facts, telemetry contract, replay/reconcile behavior, and supportable maintenance paths. [VERIFIED: codebase grep]
- `guides/telemetry.md`, `guides/webhook-troubleshooting.md`, `guides/webhooks.md`, `mailglass_admin/README.md` - current public/operator docs and drift points. [VERIFIED: codebase grep]
- `mix.exs`, `mailglass_admin/mix.exs`, `mix.lock`, `mix hex.info telemetry`, `mix hex.info phoenix_live_view`, `mix hex.info oban`, `mix hex.info opentelemetry` - locked versions and current Hex releases checked on 2026-05-05. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info]

### Secondary (MEDIUM confidence)
- None. All recommendations were grounded in repo sources or Hex metadata. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None beyond the open-question recommendation about whether to keep `guides/webhook-troubleshooting.md` as a shim path. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the recommended stack is the already-locked project stack, and package versions were cross-checked on Hex. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info]
- Architecture: HIGH - the recommendation stays inside existing LiveView/read-model/telemetry seams already present in the repo. [VERIFIED: codebase grep]
- Pitfalls: HIGH - the main risks are directly observable today as doc drift, replay/reconcile wording constraints, and current identifier exposure patterns. [VERIFIED: codebase grep]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04
