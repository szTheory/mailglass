# Phase 39: Inbound Package Foundation - Research

**Researched:** 2026-05-06 [VERIFIED: local system date]  
**Domain:** `mailglass_inbound` package contract, router DSL, mailbox behaviour, and tenant-safe inbound persistence foundation [VERIFIED: ROADMAP.md, 39-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: local repo evidence across planning docs and core modules]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `39-CONTEXT.md`. [VERIFIED: 39-CONTEXT.md]

### Locked Decisions

### Canonical `InboundMessage` contract
- **D-39-01:** The canonical adopter-facing `%InboundMessage{}` contract must
  be a plain normalized struct, not an Ecto schema.
- **D-39-02:** `%InboundMessage{}` is the normalized routing and mailbox input,
  not the durable truth record and not the replay/audit history record.
- **D-39-03:** Stable first-class fields on `%InboundMessage{}` should cover:
  tenant scope, provider provenance, provider message reference when available,
  RFC `Message-ID`, envelope recipient, sender/recipient header data, subject,
  normalized headers, sent/received timestamps, normalized body fields, and a
  normalized attachment manifest.
- **D-39-04:** `tenant_id` and envelope-recipient semantics are first-class
  stable fields. Do not make routing depend only on visible `To` headers.
- **D-39-05:** Raw provider payloads, raw request headers/body, signature
  evidence, replay identifiers, mailbox outcomes, retention policy, storage
  paths, and provider-only extras must stay out of the stable public struct.
- **D-39-06:** Provider-specific extras may only enter the stable struct if
  they normalize honestly across first-party ingress providers. Do not use the
  public struct as a dumping ground for provider shape drift.

### Router DSL shape
- **D-39-07:** The public routing contract should use one adopter-owned router
  module with a thin declarative macro DSL that compiles into normalized pure
  route data consumed by a plain runtime matcher engine.
- **D-39-08:** Routing semantics are top-to-bottom, first-match wins, exactly
  one mailbox target per inbound message.
- **D-39-09:** Multiple matcher clauses on one route are logical `AND`. Multiple
  route lines are logical `OR` by order.
- **D-39-10:** The public Phase 39 matcher surface should stay narrow:
  recipient, subject, and header matching only, with exact string and regex
  support only.
- **D-39-11:** No-match must be an explicit non-exceptional result. Route miss
  is not an automatic bounce.
- **D-39-12:** Defer arbitrary function predicates, mailbox self-registration,
  body/attachment/provider/raw-MIME matching, negation/boolean combinators, and
  multi-match fan-out routing.

### Mailbox behaviour contract
- **D-39-13:** The public mailbox contract should be one narrow behaviour with
  one stable callback: `process/1`.
- **D-39-14:** Mailbox outcome classes should be locked to:
  - `:accept`
  - `:ignore`
  - `{:reject, reason}`
  - `{:bounce, reason}`
- **D-39-15:** Raised exceptions, exits, and throws are execution failures, not
  mailbox outcomes. Retry and failure handling should key off execution failure,
  not overload reject/bounce semantics.
- **D-39-16:** Async execution mode must stay behind internal runners so inline,
  Oban-backed, bounded fallback, and replay execution all invoke the same
  adopter callback contract.
- **D-39-17:** Do not expose `before_process`, `after_process`, `around_process`,
  `handle_failed`, or queue/job-shaped callbacks in the Phase 39 public API.
- **D-39-18:** `{:bounce, reason}` is a first-class recorded outcome now, but
  richer bounce-delivery machinery remains a later-phase concern.

### Storage and evidence boundary
- **D-39-19:** `mailglass_inbound` should store one stable canonical inbound
  record plus one internal raw-evidence record in Postgres.
- **D-39-20:** Canonical persisted data is adopter-facing and provider-normalized.
  Evidence data is raw/debug/replay material and may remain provider-shaped.
- **D-39-21:** Attachment bytes, raw MIME, provider payload JSON, selected raw
  ingress headers, verification facts, and parse warnings belong in the evidence
  boundary, not on the canonical row and not on the stable public struct.
- **D-39-22:** Replay must never masquerade as a fresh receive. Replay is a new
  execution against stored evidence linked to the original inbound message.
- **D-39-23:** Keep the no-cross-package-FK posture. Package-local FK from
  inbound evidence to the package’s own canonical inbound record is acceptable;
  cross-package coupling to `mailglass` tables is not.
- **D-39-24:** The storage design should preserve append-only truth for evidence
  and replay history. Avoid mutable “latest truth only” semantics.
- **D-39-25:** Do not introduce behaviour-backed external raw storage or a full
  event-sourced projection model in Phase 39. Both expand support and mental
  burden beyond the narrow first inbound slice.

### Recommendation-first downstream posture
- **D-39-26:** Downstream research, planning, and implementation for this phase
  should default to decisive one-shot synthesis rather than repeated user
  interviewing.
- **D-39-27:** Escalate only when a choice is likely to materially change:
  - the stable public `mailglass_inbound` contract
  - tenant trust boundaries
  - replay/audit semantics
  - package-support burden in a meaningful way
  - a user-visible default workflow the project owner is especially likely to
    care about directly
- **D-39-28:** This recommendation-first posture should be shifted left in GSD
  workflows for Mailglass generally: research broadly, recommend one coherent
  set, and surface options only for truly high-impact contract or trust choices.

### the agent's Discretion
- Exact field names for normalized recipient/header/body/attachment fields, as
  long as the boundary between stable normalized data and evidence remains
  intact.
- Exact internal module names for the router engine, execution runner, replay
  runner, and persistence mappers.
- Exact canonical/evidence table names and whether evidence is one table or a
  small cluster of package-local tables.
- Exact docs and tests used to prove first-match routing, mailbox outcome
  semantics, and replay distinction.

### Deferred Ideas (OUT OF SCOPE)
- Arbitrary function predicates and custom matcher behaviours in the routing DSL.
- Body, attachment, provider, or raw-MIME routing matchers.
- Multi-match / fan-out routing.
- Mailbox lifecycle hooks beyond `process/1`.
- External object-storage behaviour for raw evidence.
- Full event-sourced inbound projection architecture.
- Conductor-style inbound dev UI.
- Mailgun, SES, and SMTP relay ingress.
</user_constraints>

<phase_requirements>
## Phase Requirements

Verbatim requirement text comes from `REQUIREMENTS.md`. [VERIFIED: REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| MODEL-01 | Adopter can depend on one canonical `%InboundMessage{}` struct for the first-party inbound package, with stable fields for routing, tenancy, and provider provenance. [VERIFIED: REQUIREMENTS.md] | Use one plain `%MailglassInbound.InboundMessage{}` value object modeled after `Mailglass.Message`, with stable normalized fields only and all raw/provider-only evidence kept in internal persistence. [VERIFIED: message.ex, 39-CONTEXT.md] |
| ROUTE-01 | Adopter can route inbound mail to mailboxes using one DSL that matches on recipient, subject, and headers. [VERIFIED: REQUIREMENTS.md] | Use one adopter-owned router macro that compiles routes into pure ordered route data, then match at runtime with first-match-wins semantics and exact/regex support only. [VERIFIED: router.ex, 39-CONTEXT.md] |
| MAILBOX-01 | Adopter can implement mailbox handlers with explicit `:accept`, `:reject`, `:ignore`, and `{:bounce, reason}` outcomes. [VERIFIED: REQUIREMENTS.md] | Use one narrow mailbox behaviour with `process/1` only; treat raises/exits/throws as execution failures handled by internal runners, not mailbox outcomes. [VERIFIED: 39-CONTEXT.md] |
| STORE-01 | Operator can persist each inbound message as both normalized canonical data and raw provider source material sufficient for replay and debugging. [VERIFIED: REQUIREMENTS.md] | Phase 39 should lay the storage foundation with a canonical inbound row plus an internal evidence row owned by `mailglass_inbound`, so Phase 40/41 can add provider ingest without redesigning the public contract. [VERIFIED: ROADMAP.md, 39-CONTEXT.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Mailglass is Phoenix-first, Postgres-only, and multi-tenant by default, so the inbound package should reuse the host Repo boundary and explicit `tenant_id` semantics rather than inventing a package-local runtime store. [VERIFIED: CLAUDE.md, repo.ex, tenancy.ex]
- Stable public value objects stay separate from internal persistence and runtime machinery, which is already the house pattern in `Mailglass.Message`, `Mailglass.Webhook.Provider`, and the `docs/api_stability.md` contract inventory. [VERIFIED: message.ex, webhook/provider.ex, docs/api_stability.md]
- Optional dependencies must stay behind `Mailglass.OptionalDeps.*` gateways, so later async inbound execution should reuse the existing Oban-gating philosophy instead of exposing queue-shaped public callbacks. [VERIFIED: CLAUDE.md, optional_deps.ex, 39-CONTEXT.md]
- No cross-package foreign keys should be introduced just to make sibling-package integration feel tighter; the core repo already treats cross-boundary truth as logical rather than FK-enforced where that preserves package independence. [VERIFIED: 39-CONTEXT.md, events/event.ex]
- Honest surface area is mandatory: Phase 39 should recommend only recipient/subject/header routing, one `process/1` mailbox callback, and Postgres-backed canonical/evidence storage because broader claims are explicitly deferred. [VERIFIED: METHODOLOGY.md, 39-CONTEXT.md]

## Summary

Phase 39 should define `mailglass_inbound` as the inbound analog of `Mailglass.Message`: one stable adopter-facing value object, one thin authoring macro, one narrow behaviour, and one internal persistence boundary that keeps raw ingress truth out of the public contract. [VERIFIED: message.ex, router.ex, webhook/provider.ex, 39-CONTEXT.md]

The decisive recommendation is to keep `%MailglassInbound.InboundMessage{}` plain and normalized, compile router declarations into pure ordered route data, expose only `Mailbox.process/1`, and persist inbound state as two package-local records: a canonical normalized inbound row and a raw evidence row linked by package-local FK. That matches the existing Mailglass split between stable semantic seams and internal operational truth, and it satisfies `MODEL-01`, `ROUTE-01`, `MAILBOX-01`, plus the storage foundation later phases need for `STORE-01`. [VERIFIED: message.ex, webhook/webhook_event.ex, events/event.ex, ROADMAP.md, REQUIREMENTS.md, 39-CONTEXT.md]

**Primary recommendation:** implement Phase 39 around four contract seams only: `%MailglassInbound.InboundMessage{}`, `MailglassInbound.Router`, `MailglassInbound.Mailbox`, and package-local canonical/evidence persistence with replay linkage but no public replay/event API yet. [VERIFIED: ROADMAP.md, 39-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stable inbound message contract | API / Backend | — | The stable contract is a library value object consumed by routers, mailboxes, and tests, analogous to `Mailglass.Message` rather than a database row. [VERIFIED: message.ex, 39-CONTEXT.md] |
| Router DSL authoring and validation | API / Backend | — | `Mailglass.Router` already shows the house style: thin macro surface, compile-time option validation, and explicit runtime ownership after expansion. [VERIFIED: router.ex] |
| Route matching engine | API / Backend | Internal Runtime | Matching should execute against pure compiled route data so replay, inline execution, and future async runners all share one deterministic matcher. [VERIFIED: 39-CONTEXT.md] |
| Mailbox callback contract | API / Backend | Internal Runtime | Adopters own one `process/1` callback, while retries, inline execution, Oban execution, and replay remain internal runner concerns. [VERIFIED: 39-CONTEXT.md] |
| Canonical inbound persistence | Database / Storage | API / Backend | The canonical normalized row is the durable package truth that Phase 40/41 provider ingestion will write after normalization. [VERIFIED: ROADMAP.md, 39-CONTEXT.md] |
| Raw evidence and replay linkage | Database / Storage | Internal Runtime | Raw payloads, verification facts, and replay linkage belong in internal evidence storage, just as raw webhook payloads live outside the stable event struct today. [VERIFIED: webhook/webhook_event.ex, events/event.ex, 39-CONTEXT.md] |

## Standard Stack

### Core

| Library / Artifact | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.18` project floor; local `1.19.5` available [VERIFIED: mix.exs, local env probe] | Language/runtime floor for the sibling package work | Phase 39 should stay inside the same language/runtime floor already locked for the repo instead of creating a divergent sibling-package baseline. [VERIFIED: PROJECT.md, mix.exs] |
| Ecto / Ecto SQL | `~> 3.13` [VERIFIED: mix.exs] | Internal canonical/evidence schemas and package-local changesets | The repo already standardizes internal persistence on Ecto schemas behind a host-configured Repo facade. [VERIFIED: schema.ex, repo.ex, mix.exs] |
| PostgreSQL | `14+` requirement; local `14.17` available [VERIFIED: README.md, local env probe] | Durable canonical/evidence storage and later replay linkage | Postgres is already a hard project constraint, and the repo uses DB-level invariants for truth semantics rather than pluggable storage backends. [VERIFIED: README.md, CLAUDE.md, repo.ex] |
| `Mailglass.Message` pattern | `0.3.2` repo line [VERIFIED: mix.exs, message.ex] | Value-object template for `%InboundMessage{}` | The stable outbound contract is already a plain struct with stable fields and helper functions, which is the exact pattern Phase 39 wants on inbound. [VERIFIED: message.ex, 39-CONTEXT.md] |
| `Mailglass.Router` pattern | `0.3.2` repo line [VERIFIED: mix.exs, router.ex] | Macro design template for router DSL | The repo already prefers narrow macros with `NimbleOptions` validation and runtime helpers rather than macro-heavy DSL engines. [VERIFIED: router.ex] |
| `Mailglass.Webhook.Provider` posture | `0.3.2` repo line [VERIFIED: mix.exs, webhook/provider.ex] | Public/internal boundary template for provider churn | The webhook provider seam is already conn-free, narrow, and explicit about keeping provider-specific variance behind internal contracts. [VERIFIED: webhook/provider.ex] |

### Supporting

| Library / Artifact | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.Schema` | `0.3.2` repo line [VERIFIED: mix.exs, schema.ex] | Shared schema stamping for package-local tables | Use for internal inbound Ecto schemas so IDs, foreign keys, and timestamps stay aligned with the rest of the repo. [VERIFIED: schema.ex] |
| `Mailglass.Repo` | `0.3.2` repo line [VERIFIED: mix.exs, repo.ex] | Host-app Repo boundary | Use for all `mailglass_inbound` persistence so the sibling package stays adopter-configured rather than owning its own Repo. [VERIFIED: repo.ex] |
| `Mailglass.Tenancy` | `0.3.2` repo line [VERIFIED: mix.exs, tenancy.ex] | Explicit tenant stamping and query scoping | Use as the tenant context source and scoping seam for canonical/evidence queries and replay execution. [VERIFIED: tenancy.ex] |
| `Mailglass.OptionalDeps.Oban` gateway pattern | `0.3.2` repo line [VERIFIED: mix.exs, optional_deps.ex] | Future async execution seam | Use later for Oban-backed execution without leaking queue types into the Phase 39 public mailbox contract. [VERIFIED: optional_deps.ex, 39-CONTEXT.md] |
| `Mailglass.Webhook.WebhookEvent` / `Mailglass.Events.Event` split | `0.3.2` repo line [VERIFIED: webhook/webhook_event.ex, events/event.ex] | Proven normalized-row versus raw-evidence separation | Use as the persistence precedent for separating canonical inbound rows from provider-shaped evidence and replay history. [VERIFIED: webhook/webhook_event.ex, events/event.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain `%InboundMessage{}` value object [VERIFIED: 39-CONTEXT.md] | Public Ecto schema | That would collapse stable contract and storage shape together, which conflicts with the existing `Mailglass.Message` pattern and the locked boundary between normalized data and raw evidence. [VERIFIED: message.ex, 39-CONTEXT.md] |
| Thin router macro + pure matcher [VERIFIED: router.ex, 39-CONTEXT.md] | Function-predicate DSL or mailbox self-registration | That would expand the public contract into speculative workflow-engine behavior the context explicitly defers. [VERIFIED: 39-CONTEXT.md] |
| One `process/1` behaviour [VERIFIED: 39-CONTEXT.md] | Lifecycle hooks like `before_process/1` or queue-shaped callbacks | The older inbound research mentioned broader mailbox hooks, but Phase 39 now locks a much narrower contract to reduce support burden and keep execution policy internal. [VERIFIED: v0.1-research/FEATURES.md, 39-CONTEXT.md] |
| Canonical row + internal evidence row in Postgres [VERIFIED: 39-CONTEXT.md] | External raw-storage behaviour, LocalFS/S3 adapters, or full event sourcing | Those expand support and retention semantics too early and are explicitly deferred from this phase. [VERIFIED: 39-CONTEXT.md, v0.1-research/FEATURES.md] |

**Installation:**  
```bash
mix deps.get
mix compile --warnings-as-errors
```  
[VERIFIED: mix.exs]

**Version verification:** Phase 39 does not require new third-party dependencies; the recommendation is to reuse the repo’s existing Elixir, Ecto, Postgres, and optional-dependency stack exactly as already declared. [VERIFIED: mix.exs, README.md]

## Architecture Patterns

### System Architecture Diagram

```text
provider ingress (Phase 40/41)
        |
        v
raw provider request + verification facts
        |
        v
normalizer
        |
        +--> %MailglassInbound.InboundMessage{}
        |         |
        |         v
        |   MailglassInbound.Router (compiled route data)
        |         |
        |         v
        |   first-match runtime matcher
        |         |
        |         +--> {:ok, mailbox_module}
        |         |         |
        |         |         v
        |         |   Mailbox.process/1
        |         |         |
        |         |         +--> :accept | :ignore | {:reject, reason} | {:bounce, reason}
        |         |         \--> raise/exit/throw => execution failure in internal runner
        |         |
        |         \--> :no_match
        |
        +--> canonical inbound row (normalized adopter-facing truth)
        |
        \--> evidence row (raw payload, headers, MIME, verification facts, replay linkage)
                    |
                    v
              replay execution later reuses:
              stored evidence -> normalize -> %InboundMessage{} -> same matcher -> same mailbox callback
```
[VERIFIED: ROADMAP.md, 39-CONTEXT.md, webhook/webhook_event.ex, message.ex]

### Recommended Project Structure

```text
mailglass_inbound/
├── lib/mailglass_inbound/inbound_message.ex    # stable value object
├── lib/mailglass_inbound/router.ex             # public DSL macro
├── lib/mailglass_inbound/router/route.ex       # pure compiled route data
├── lib/mailglass_inbound/router/matcher.ex     # runtime matcher engine
├── lib/mailglass_inbound/mailbox.ex            # public behaviour
├── lib/mailglass_inbound/inbound_messages/     # internal canonical persistence
├── lib/mailglass_inbound/evidence/             # internal raw evidence persistence
├── lib/mailglass_inbound/execution/            # inline/replay/async runners
└── test/mailglass_inbound/                     # contract tests
```
[VERIFIED: ROADMAP.md, 39-CONTEXT.md, existing repo package/module layout]

### Pattern 1: Stable Value Object Over Public Schema
**What:** Expose `%MailglassInbound.InboundMessage{}` as a plain normalized struct with stable fields for routing, tenancy, and mailbox input only. [VERIFIED: 39-CONTEXT.md]  
**When to use:** Always at the public package boundary, including router matching, mailbox callbacks, and public docs/tests. [VERIFIED: MODEL-01, 39-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: lib/mailglass/message.ex
defmodule MailglassInbound.InboundMessage do
  @type t :: %__MODULE__{
          tenant_id: String.t() | nil,
          provider: atom(),
          provider_message_ref: String.t() | nil,
          message_id: String.t() | nil,
          envelope_recipient: String.t(),
          from: %{address: String.t(), name: String.t() | nil} | nil,
          to: [%{address: String.t(), name: String.t() | nil}],
          cc: [%{address: String.t(), name: String.t() | nil}],
          subject: String.t() | nil,
          headers: %{optional(String.t()) => [String.t()]},
          sent_at: DateTime.t() | nil,
          received_at: DateTime.t() | nil,
          text_body: String.t() | nil,
          html_body: String.t() | nil,
          attachments: [map()]
        }

  defstruct [
    :tenant_id,
    :provider,
    :provider_message_ref,
    :message_id,
    :envelope_recipient,
    :from,
    to: [],
    cc: [],
    :subject,
    headers: %{},
    :sent_at,
    :received_at,
    :text_body,
    :html_body,
    attachments: []
  ]
end
```

### Pattern 2: Declarative Router Compiled To Pure Route Data
**What:** Keep the public DSL as a thin macro and move matching semantics into pure route structs plus one matcher module. [VERIFIED: router.ex, 39-CONTEXT.md]  
**When to use:** For all adopter-authored routing declarations, replay, and future async execution. [VERIFIED: ROUTE-01, 39-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: lib/mailglass/router.ex
defmodule MyApp.InboundRouter do
  use MailglassInbound.Router

  route SupportMailbox,
    recipient: "support@example.com",
    subject: ~r/refund/i

  route BillingMailbox,
    recipient: ~r/^billing\+/,
    header: {"x-priority", "high"}
end
```

### Pattern 3: One Stable Mailbox Callback, Explicit Result Tuples
**What:** Public mailbox modules implement `process/1` only and return explicit semantic outcomes. [VERIFIED: 39-CONTEXT.md]  
**When to use:** For every adopter mailbox module, regardless of whether execution is inline, replayed, or later Oban-backed. [VERIFIED: MAILBOX-01, 39-CONTEXT.md]  
**Example:**
```elixir
defmodule MyApp.SupportMailbox do
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(%MailglassInbound.InboundMessage{} = message) do
    case message.subject do
      nil -> {:reject, :missing_subject}
      "AUTO-REPLY" -> :ignore
      _ -> :accept
    end
  end
end
```

### Pattern 4: Canonical Row Plus Internal Evidence Row
**What:** Persist normalized inbound truth separately from raw ingress evidence, then link replay and mailbox outcomes back to the canonical inbound message without mutating that message into “latest truth only.” [VERIFIED: 39-CONTEXT.md, webhook/webhook_event.ex, events/event.ex]  
**When to use:** For all provider ingestion and later replay features. [VERIFIED: STORE-01, 39-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: lib/mailglass/webhook/webhook_event.ex + lib/mailglass/events/event.ex
# Canonical row:
#   mailglass_inbound_messages
# Evidence row:
#   mailglass_inbound_message_evidence
# Optional later history row:
#   mailglass_inbound_mailbox_runs
#
# Recommended invariant:
#   evidence.inbound_message_id -> inbound_messages.id
#   replay references evidence.id and original inbound_message_id
#   mailbox outcome history appends new rows instead of mutating evidence into "latest status"
```

### Anti-Patterns to Avoid

- **Public Ecto schema as `%InboundMessage{}`:** This would lock provider/storage churn into the adopter contract and contradict the existing `Mailglass.Message` design. [VERIFIED: message.ex, 39-CONTEXT.md]
- **Routing on visible `To` headers only:** Envelope recipient is a locked first-class field because aliases, BCC, and provider rewrites can make header-only routing wrong. [VERIFIED: 39-CONTEXT.md]
- **Mailbox lifecycle DSL sprawl:** `before_process`, `after_process`, function predicates, or queue-job callbacks would turn Phase 39 into a workflow engine the context explicitly defers. [VERIFIED: 39-CONTEXT.md]
- **Canonical row overloaded with raw MIME and attachment bytes:** The repo already separates normalized semantic truth from raw provider evidence in webhook storage. [VERIFIED: webhook/webhook_event.ex, events/event.ex]
- **Cross-package FK to core `mailglass` tables:** The repo already uses logical linking to preserve package independence; inbound should keep the same posture. [VERIFIED: events/event.ex, 39-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public inbound contract | Public schema that mirrors provider payloads | One normalized plain struct | Stable adopter contracts should not drift every time provider parsing changes. [VERIFIED: message.ex, 39-CONTEXT.md] |
| Router execution model | Mini workflow engine with predicate callbacks and multi-dispatch | Thin macro + pure matcher | The repo already prefers macros only for authoring ergonomics and validation, with runtime logic in normal modules. [VERIFIED: router.ex, METHODOLOGY.md] |
| Async public API | Queue-shaped public callbacks or Oban job semantics | Internal runner seam behind `process/1` | Optional-dependency policy already keeps job runtime details out of stable adopter APIs. [VERIFIED: optional_deps.ex, 39-CONTEXT.md] |
| Raw evidence storage | External storage abstraction in Phase 39 | Package-local Postgres evidence row | The context explicitly defers external object storage, and the repo already uses Postgres for audit truth. [VERIFIED: 39-CONTEXT.md, repo.ex] |
| Replay state | Mutable “latest mailbox status” field as the whole story | Append-only replay/mailbox-run history linked to canonical/evidence records | Replay must stay distinguishable from fresh receive, and append-only truth is already a core Mailglass pattern. [VERIFIED: 39-CONTEXT.md, events/event.ex, operator/replay_history.ex] |

**Key insight:** the main design risk in Phase 39 is not missing functionality; it is collapsing four different concerns into one public struct or one magic DSL. Mailglass already succeeds when stable semantics, persistence truth, and runtime policy stay separate. [VERIFIED: docs/api_stability.md, message.ex, webhook/provider.ex, 39-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating `%InboundMessage{}` as the durable truth record
**What goes wrong:** Provider-shaped evidence, replay IDs, mailbox outcomes, and retention metadata leak into the stable public struct, making every future provider addition a contract change. [VERIFIED: 39-CONTEXT.md]  
**Why it happens:** It is tempting to reuse one struct for parsing, routing, persistence, replay, and operator audit. [VERIFIED: v0.1-research/FEATURES.md, 39-CONTEXT.md]  
**How to avoid:** Keep `%InboundMessage{}` normalized and plain; move raw request material and execution history into internal evidence/history schemas. [VERIFIED: message.ex, webhook/webhook_event.ex, 39-CONTEXT.md]  
**Warning signs:** Proposed fields like `raw_mime`, `signature_result`, `storage_path`, `replay_id`, or `mailbox_outcome` appear on the public struct. [VERIFIED: 39-CONTEXT.md]

### Pitfall 2: Making routing depend on visible headers instead of envelope truth
**What goes wrong:** Routes miss or misclassify mail when providers rewrite `To`, preserve aliases differently, or deliver via BCC-style recipient handling. [VERIFIED: 39-CONTEXT.md]  
**Why it happens:** Subject/header matchers are visible to adopters, while envelope recipient handling feels more internal. [VERIFIED: 39-CONTEXT.md]  
**How to avoid:** Make `envelope_recipient` a required first-class field and define recipient routing against it first, with header data as additional match material only. [VERIFIED: REQUIREMENTS.md, 39-CONTEXT.md]  
**Warning signs:** DSL proposals that speak only about `to:` or raw `"to"` headers and omit envelope recipient semantics. [VERIFIED: 39-CONTEXT.md]

### Pitfall 3: Storing only mutable “latest state” for mailbox processing
**What goes wrong:** Replay becomes indistinguishable from fresh receive, and operators cannot prove what ran, when it ran, and whether a later execution was a replay or an original process attempt. [VERIFIED: 39-CONTEXT.md]  
**Why it happens:** A single row with `status` or `outcome` feels simpler than append-only run history. [VERIFIED: events/event.ex, operator/replay_history.ex]  
**How to avoid:** Keep canonical inbound data stable, keep raw evidence durable, and append mailbox-run or replay-history records instead of rewriting truth in place. [VERIFIED: 39-CONTEXT.md, events/event.ex, operator/replay_history.ex]  
**Warning signs:** Designs that say “replay just reruns and updates the same row” or “latest outcome is enough.” [VERIFIED: 39-CONTEXT.md]

## Code Examples

Verified patterns from repo sources:

### Value-object public contract
```elixir
# Source: lib/mailglass/message.ex
defstruct [
  :swoosh_email,
  :mailable,
  :mailable_function,
  :tenant_id,
  stream: :transactional,
  tags: [],
  metadata: %{},
  assigns: %{}
]
```
[VERIFIED: message.ex]

### Thin macro with explicit validation
```elixir
# Source: lib/mailglass/router.ex
defmacro mailglass_router_routes(path, opts \\ []) do
  opts = validate_opts!(opts)
  configured_mount_path = normalize_mount_path(Mailglass.Config.compliance_mount_path())
  requested_mount_path = requested_mount_path(path, opts[:mount_path])
  route_path = "#{requested_mount_path}/:token"
  ...
end
```
[VERIFIED: router.ex]

### Narrow provider behaviour that hides runtime details
```elixir
# Source: lib/mailglass/webhook/provider.ex
@callback verify!(raw_body :: binary(), headers :: [{String.t(), String.t()}], config :: map()) ::
            :ok | {:ok, :replay}

@callback normalize(raw_body :: binary(), headers :: [{String.t(), String.t()}]) ::
            [Mailglass.Events.Event.t()]
```
[VERIFIED: webhook/provider.ex]

### Internal raw evidence kept separate from normalized semantic event rows
```elixir
# Sources: lib/mailglass/webhook/webhook_event.ex + lib/mailglass/events/event.ex
schema "mailglass_webhook_events" do
  field(:raw_payload, :map, redact: true)
  ...
end

schema "mailglass_events" do
  field(:normalized_payload, :map, default: %{})
  field(:metadata, :map, default: %{})
  ...
end
```
[VERIFIED: webhook/webhook_event.ex, events/event.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Earlier inbound research listed `Mailglass.Inbound.Mailbox` with `before_process/1`, `process/1`, and `bounce_with/2`. [VERIFIED: v0.1-REQUIREMENTS.md, v0.2-REQUIREMENTS.md] | Phase 39 now locks one stable `process/1` callback with explicit outcome tuples only. [VERIFIED: 39-CONTEXT.md, REQUIREMENTS.md] | Locked on 2026-05-06 in Phase 39 context. [VERIFIED: 39-CONTEXT.md] | Smaller public contract, less support burden, and cleaner alignment with later internal runners. [VERIFIED: 39-CONTEXT.md, METHODOLOGY.md] |
| Earlier research imagined inbound storage behaviours such as LocalFS + S3 for raw MIME. [VERIFIED: v0.1-research/FEATURES.md] | Phase 39 now keeps storage foundation in package-local Postgres canonical/evidence records and defers external raw-storage behaviours. [VERIFIED: 39-CONTEXT.md] | Locked on 2026-05-06 in Phase 39 context. [VERIFIED: 39-CONTEXT.md] | Narrower first milestone and no premature retention/storage-support surface. [VERIFIED: PROJECT.md, 39-CONTEXT.md] |
| Earlier roadmap language grouped inbound as a broader v0.5+ future slice. [VERIFIED: README.md, v0.1-ROADMAP.md] | `v1.1` now opens a tightly bounded sibling-package milestone with explicit Phase 39-42 sequencing. [VERIFIED: ROADMAP.md, PROJECT.md] | 2026-05-06 milestone activation. [VERIFIED: PROJECT.md, ROADMAP.md] | Phase 39 can now recommend exact package seams instead of speculative long-tail provider breadth. [VERIFIED: ROADMAP.md, REQUIREMENTS.md] |

**Deprecated/outdated:**
- Public mailbox lifecycle hooks for the first inbound contract are outdated relative to the locked Phase 39 decisions and should not be revived in planning. [VERIFIED: v0.1-REQUIREMENTS.md, 39-CONTEXT.md]
- Storage-backend abstractions for raw inbound evidence are outdated for this phase because the context explicitly defers them. [VERIFIED: v0.1-research/FEATURES.md, 39-CONTEXT.md]

## Assumptions Log

All material claims in this research were verified against local repo artifacts; no user-confirmation assumptions remain. [VERIFIED: repo file audit]

## Open Questions (RESOLVED)

None that block Phase 39 planning. The locked decisions already constrain the public contract, and the remaining discretion is implementation naming and exact internal table/module layout rather than phase-scope semantics. [VERIFIED: 39-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | package implementation and tests | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| Mix | build, compile, and test workflow | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| PostgreSQL client | local persistence/test verification | ✓ [VERIFIED: local env probe] | `14.17` [VERIFIED: local env probe] | — |

**Missing dependencies with no fallback:** None found for Phase 39 research and planning. [VERIFIED: local env probe]

**Missing dependencies with fallback:** None needed; Phase 39 can be planned entirely on the existing repo toolchain. [VERIFIED: mix.exs, local env probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test aliases [VERIFIED: mix.exs, test tree grep] |
| Config file | `test/test_helper.exs` and `test/support/*` conventions [VERIFIED: test tree grep] |
| Quick run command | `mix test test/mailglass/message_test.exs test/mailglass/router/unsubscribe_router_test.exs --warnings-as-errors` as the closest existing contract-pattern smoke today; Phase 39 should add sibling-package equivalents. [VERIFIED: test tree grep] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODEL-01 | `%InboundMessage{}` exposes only normalized stable fields and excludes raw evidence concerns. [VERIFIED: REQUIREMENTS.md, 39-CONTEXT.md] | unit | `mix test test/mailglass_inbound/inbound_message_test.exs --warnings-as-errors` | ❌ Wave 0 |
| ROUTE-01 | Router DSL compiles ordered routes and matcher returns first-match or explicit no-match. [VERIFIED: REQUIREMENTS.md, 39-CONTEXT.md] | unit | `mix test test/mailglass_inbound/router_test.exs --warnings-as-errors` | ❌ Wave 0 |
| MAILBOX-01 | Mailbox behaviour accepts only `process/1` and explicit result tuples; raises are treated separately by runners. [VERIFIED: REQUIREMENTS.md, 39-CONTEXT.md] | unit | `mix test test/mailglass_inbound/mailbox_test.exs --warnings-as-errors` | ❌ Wave 0 |
| STORE-01 foundation | Canonical/evidence schema boundary keeps raw evidence out of the public contract and preserves replay distinction. [VERIFIED: ROADMAP.md, REQUIREMENTS.md, 39-CONTEXT.md] | integration | `mix test test/mailglass_inbound/persistence_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass_inbound/inbound_message_test.exs test/mailglass_inbound/router_test.exs test/mailglass_inbound/mailbox_test.exs --warnings-as-errors` once the files exist. [VERIFIED: recommended from requirement map]
- **Per wave merge:** `mix test test/mailglass_inbound --warnings-as-errors` once the sibling-package suite exists. [VERIFIED: recommended from requirement map]
- **Phase gate:** `mix test --warnings-as-errors` plus compile on the new sibling package path before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/mailglass_inbound/inbound_message_test.exs` — pins stable field inventory and public/plain-struct semantics for `MODEL-01`. [VERIFIED: gap from repo audit]
- [ ] `test/mailglass_inbound/router_test.exs` — proves first-match-wins, exact/regex matching, and no-match semantics for `ROUTE-01`. [VERIFIED: gap from repo audit]
- [ ] `test/mailglass_inbound/mailbox_test.exs` — proves accepted outcome set and runner/error boundary for `MAILBOX-01`. [VERIFIED: gap from repo audit]
- [ ] `test/mailglass_inbound/persistence_test.exs` — proves canonical/evidence separation and tenant-safe persistence boundaries. [VERIFIED: gap from repo audit]
- [ ] `test/mailglass_inbound/replay_test.exs` — proves replay-not-fresh-receive semantics at the persistence boundary. [VERIFIED: gap from repo audit]
- [ ] Sibling-package test wiring in `mailglass_inbound/mix.exs` once the package scaffold lands. [VERIFIED: ROADMAP.md indicates sibling package not yet present]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Phase 39 does not define end-user auth flows. [VERIFIED: ROADMAP.md, 39-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | No session or cookie surface is introduced in this phase. [VERIFIED: ROADMAP.md, 39-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: tenant scope is first-class] | Explicit `tenant_id` on public contract and package-local scoping through `Mailglass.Tenancy`. [VERIFIED: tenancy.ex, 39-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: router DSL and persistence inputs] | `NimbleOptions`-style router validation plus changeset validation on internal schemas. [VERIFIED: router.ex, schema.ex, repo patterns] |
| V6 Cryptography | no for Phase 39 itself; yes later for ingress verification [VERIFIED: phase scope, roadmap sequencing] | Verification facts belong in evidence rows, but provider signature verification lands in Phase 40/41 ingress work. [VERIFIED: ROADMAP.md, 39-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant message or evidence leak | Information Disclosure / Elevation of Privilege | Stamp and scope every canonical/evidence query with `tenant_id`, and keep `tenant_id` first-class on `%InboundMessage{}` and persisted rows. [VERIFIED: tenancy.ex, 39-CONTEXT.md] |
| Replay masquerading as fresh receive | Repudiation / Tampering | Link replay to stored evidence and append replay/run history rather than mutating the original record into looking newly received. [VERIFIED: 39-CONTEXT.md, operator/replay_history.ex] |
| Raw ingress PII leaking through logs or inspect output | Information Disclosure | Keep raw payloads in internal evidence schemas and mark sensitive raw fields `redact: true`, following the existing webhook evidence precedent. [VERIFIED: webhook/webhook_event.ex] |
| Router regex or matcher sprawl becoming an execution-policy footgun | Denial of Service / Tampering | Keep the matcher surface narrow to exact string and regex on recipient/subject/header only, with pure matching logic and no arbitrary callbacks. [VERIFIED: 39-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `./.planning/phases/39-inbound-package-foundation/39-CONTEXT.md` - locked Phase 39 contract, storage, and deferred-scope decisions. [VERIFIED: repo file read]
- `./.planning/ROADMAP.md` - Phase 39-42 sequencing and storage/execution dependency notes. [VERIFIED: repo file read]
- `./.planning/PROJECT.md` - milestone posture, maintainer boundary, and sibling-package scope. [VERIFIED: repo file read]
- `./.planning/REQUIREMENTS.md` - `MODEL-01`, `ROUTE-01`, `MAILBOX-01`, and `STORE-01` definitions. [VERIFIED: repo file read]
- `./.planning/METHODOLOGY.md` - recommendation-first and honest-surface constraints. [VERIFIED: repo file read]
- `./docs/api_stability.md` - stable-versus-internal contract posture. [VERIFIED: repo file read]
- `./lib/mailglass/message.ex` - plain value-object public contract precedent. [VERIFIED: repo file read]
- `./lib/mailglass/router.ex` - thin macro and compile-time validation precedent. [VERIFIED: repo file read]
- `./lib/mailglass/webhook/provider.ex` - narrow provider-boundary precedent. [VERIFIED: repo file read]
- `./lib/mailglass/schema.ex`, `./lib/mailglass/repo.ex`, `./lib/mailglass/tenancy.ex`, `./lib/mailglass/optional_deps.ex` - persistence, tenant, and optional-dependency house patterns. [VERIFIED: repo file read]
- `./lib/mailglass/webhook/webhook_event.ex`, `./lib/mailglass/events/event.ex`, `./lib/mailglass/events.ex` - normalized-versus-raw persistence split and append-only truth patterns. [VERIFIED: repo file read]

### Secondary (MEDIUM confidence)

- `./.planning/milestones/v0.1-research/FEATURES.md`, `ARCHITECTURE.md`, and `PITFALLS.md` - earlier inbound ideas and pitfalls used only as historical comparison against the newer locked Phase 39 decisions. [VERIFIED: repo file read]

### Tertiary (LOW confidence)

- None. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the recommendation reuses declared repo dependencies and existing contract patterns instead of selecting speculative new libraries. [VERIFIED: mix.exs, core modules]
- Architecture: HIGH - the public/internal split, thin macro posture, tenant boundary, and append-only truth patterns are all already established in the repo and explicitly locked in `39-CONTEXT.md`. [VERIFIED: 39-CONTEXT.md, message.ex, router.ex, events/event.ex]
- Pitfalls: HIGH - the main failure modes are directly implied by the locked decisions and by existing repo precedents around tenancy, raw evidence handling, and append-only history. [VERIFIED: 39-CONTEXT.md, tenancy.ex, webhook/webhook_event.ex, operator/replay_history.ex]

**Research date:** 2026-05-06 [VERIFIED: local system date]  
**Valid until:** 2026-06-05 for planning purposes unless the Phase 39 context or v1.1 requirement set changes. [VERIFIED: bounded to current repo artifacts]
