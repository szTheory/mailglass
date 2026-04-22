# Architecture Research — mailglass

**Domain:** Phoenix-native transactional email framework (3 sibling Hex packages)
**Researched:** 2026-04-21
**Confidence:** HIGH (most decisions are already locked in `PROJECT.md` D-01..D-20 and `prompts/mailglass-engineering-dna-from-prior-libs.md` §2-§4; remainder synthesized from `prompts/mailer-domain-language-deep-research.md` §13 aggregate boundaries and `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §1-§7)

---

## 0. Executive summary

Mailglass is **three sibling Hex packages** sharing a planning repo and a release cadence:

| Package | Role | v0.1? |
|---|---|---|
| `mailglass` | Core: Mailable, Message, Renderer, Adapter, Webhook, Suppression, Event ledger, Tenancy, Telemetry, Errors, Config | YES |
| `mailglass_admin` | Mountable LiveView UI: dev preview (v0.1) → prod admin (v0.5) | YES (preview only) |
| `mailglass_inbound` | Action Mailbox equivalent: Router DSL, Mailbox behaviour, ingress plugs, raw MIME storage | NO (v0.5+) |

The core is a **functional pipeline** (`Mailable → Message → render → pre-send checks → Ecto.Multi(Delivery + Event(:queued) + Oban job) → worker dispatches → Adapter → Event(:dispatched)`), with an **append-only event ledger** as the single source of truth for delivery history, an **Anymail-taxonomy webhook normalizer** that records events idempotently, and a **PubSub broadcast layer** that lets `mailglass_admin` LiveViews stream live updates without polling.

The recommended top-level namespace catalog in the question is **directionally correct** with a few refinements (notably: split `Mailglass.Adapter` into a behaviour module + an `Adapters/` namespace; promote `Mailglass.Outbound` and `Mailglass.Inbound` as facade contexts per `mailglass-engineering-dna-from-prior-libs.md` §4.1; add `Mailglass.Repo` for `transact/1` per accrue DNA; promote `Mailglass.PubSub.Topics` so the topic taxonomy is grep-able; add `Mailglass.IdempotencyKey` as a tiny shared module). Process architecture is **almost entirely functional** — only one `GenServer` (the rate-limiter token bucket) and one `Registry` (tenant-adapter cache) are actually justified; everything else is OTP primitives (`Task.Supervisor`, `Phoenix.PubSub`) or stateless code.

**Build order:** Layer 0 (Error/Config/Telemetry/Repo) → Layer 1 (Message + Components + Renderer) → Layer 2 (Ecto schemas + immutability trigger) → Layer 3 (Adapter behaviour + Fake + Swoosh wrapper) → Layer 4 (Mailable + outbound facade + Oban worker) → Layer 5 (Webhook plug) → Layer 6 (mailglass_admin preview) → Layer 7 (installer + golden-diff). Use `boundary` to enforce the dependency graph.

**Confidence anchors:** §3.6 of `mailglass-engineering-dna-from-prior-libs.md` locks the event-ledger schema verbatim (HIGH). PROJECT.md D-15 locks the immutability trigger (HIGH). `mailer-domain-language-deep-research.md` §13 locks aggregate boundaries (HIGH). `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §2 locks the application supervision tree shape (HIGH). The rate-limiter-as-GenServer-vs-ETS-only choice is the **only material open question** in this dimension (MEDIUM; recommend ETS-only for v0.1, GenServer wrapper only if real cluster coordination becomes needed in v0.5+).

---

## 1. Module / package structure (validated + refined)

### 1.1 The proposed namespace catalog — verdict by module

| Proposed module | Verdict | Notes |
|---|---|---|
| `Mailglass` (top-level facade) | **KEEP** | Per `mailglass-engineering-dna-from-prior-libs.md` §2.1: root module is the public surface (reflection + orchestration + error types). Delegates to subnamespaces. |
| `Mailglass.Mailable` (behaviour) | **KEEP** | Behaviour module + the `use Mailglass.Mailable` macro. One per `MyApp.UserMailer.welcome/1`. |
| `Mailglass.Message` (struct + builders) | **KEEP** | Per `mailer-domain-language-deep-research.md` §3 noun #2. Pure struct, no processes. Wraps/extends `%Swoosh.Email{}`. |
| `Mailglass.Delivery` (Ecto schema + context) | **REFINE** | Split: `Mailglass.Outbound.Delivery` (Ecto schema) + `Mailglass.Outbound` (facade context). Aggregate boundary per `mailer-domain-language-deep-research.md` §13. |
| `Mailglass.Event` (Ecto schema + append-only enforcement) | **REFINE** | Move to `Mailglass.Events.Event` (schema) + `Mailglass.Events` (writer context that enforces `Ecto.Multi` invariant). Per `mailglass-engineering-dna-from-prior-libs.md` §3.6. |
| `Mailglass.Suppression` (Ecto schema + context) | **REFINE** | Split: `Mailglass.Suppression.Entry` (schema) + `Mailglass.Suppression` (context with `add/3`, `suppressed?/1`, `list/1`, `check_before_send/1`). Add `Mailglass.SuppressionStore` behaviour for the Ecto-vs-custom seam. |
| `Mailglass.Components` (HEEx component library) | **KEEP** | Per PROJECT.md v0.1 list. `<.container>`, `<.section>`, `<.row>`, `<.column>`, `<.heading>`, `<.text>`, `<.button>`, `<.img>`, `<.link>`, `<.hr>`, `<.preheader>`. MSO VML fallbacks per D-18. |
| `Mailglass.Renderer` (HEEx → CSS-inlined → minified → plaintext pipeline) | **KEEP** | Pipeline orchestrator. Composes `Mailglass.TemplateEngine` (HEEx default), `Premailex` (CSS inlining), `Floki` (auto-plaintext). Pure functions. |
| `Mailglass.Adapter` (transport behaviour wrapping Swoosh) | **REFINE** | Module-level: `Mailglass.Adapter` is the **behaviour**. Implementations live under `Mailglass.Adapters.*` (`Mailglass.Adapters.Fake`, `Mailglass.Adapters.Swoosh`). Mirrors `Swoosh.Adapter` / `Swoosh.Adapters.*` convention. |
| `Mailglass.Adapter.Fake` | **MOVE** | → `Mailglass.Adapters.Fake`. Per accrue DNA (`mailglass-engineering-dna-from-prior-libs.md` §3.5): in-memory, deterministic, time-advanceable, the release-blocking gate. |
| `Mailglass.Webhook` (plug + signature verification + event normalization per provider) | **REFINE** | Hierarchy: `Mailglass.Webhook` (facade), `Mailglass.Webhook.Plug` (Plug behaviour), `Mailglass.Webhook.CachingBodyReader` (raw-body preservation per `lattice_stripe` pattern), `Mailglass.Webhook.Event` (normalized struct), `Mailglass.Webhook.Providers.{Postmark,SendGrid,Mailgun,SES,Resend}` (one mapper per provider), `Mailglass.Webhook.Handler` (behaviour for adopter dispatch). |
| `Mailglass.Tenancy` (scope behaviour) | **KEEP** | Behaviour: `current_scope/1`, `tenant_id/1`, `scope_query/2`. Defaults to identity (single-tenant) per PROJECT.md D-09. |
| `Mailglass.Telemetry` (event taxonomy + helpers) | **KEEP** | `span/3` wrapper around `:telemetry.span/3` per `mailglass-engineering-dna-from-prior-libs.md` §2.5. Strict 4-level naming `[:mailglass, :domain, :resource, :action]`. |
| `Mailglass.Error` (struct hierarchy) | **KEEP** | Per `mailglass-engineering-dna-from-prior-libs.md` §2.4: `Mailglass.Error` parent + `SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`, plus a new `EventLedgerImmutableError` for the SQLSTATE 45A01 trigger catch (gotcha §6.2). |
| `Mailglass.Config` (NimbleOptions-validated runtime config) | **KEEP** | Per `mailglass-engineering-dna-from-prior-libs.md` gotcha §6.1: never `compile_env!` for runtime settings; always `Application.get_env/2` + `Mailglass.Config.resolve!/1` validated at boot. |
| `MailglassAdmin.*` | **KEEP** | Sibling Hex package. Router macro, LiveViews, components. v0.1 = preview only. v0.5 = sent-mail browser, suppression UI, replay. |
| `MailglassInbound.*` | **KEEP** | Sibling Hex package, v0.5+. Router DSL, Mailbox behaviour, ingress plugs, storage. |

### 1.2 Additions to the catalog (not in the question but needed)

| Module | Purpose | Why |
|---|---|---|
| `Mailglass.Outbound` | Public facade context for the send path: `send/2`, `send!/2`, `deliver_later/2`, `deliver_many/2`. Custom Credo check `NoRawSwooshSendInLib` enforces "all sends go through here." | Per `mailglass-engineering-dna-from-prior-libs.md` §2.8 + §4.1. The single chokepoint where suppression/telemetry/audit/event-log are guaranteed. |
| `Mailglass.Outbound.Delivery` | Ecto schema for one (Message, recipient, provider) tuple. | Per `mailer-domain-language-deep-research.md` §13 aggregate boundary. |
| `Mailglass.Outbound.Worker` | Oban worker (when present); falls back to `Task.Supervisor` child process. | Per PROJECT.md D-07: Oban optional with fallback warning. |
| `Mailglass.Events` | Writer context. `append/2` is the **only** way to insert into `mailglass_events`; refuses calls outside an `Ecto.Multi`. | Per `mailglass-engineering-dna-from-prior-libs.md` §3.6: every mutation is a Multi that includes an event row. Centralizing the writer prevents drift. |
| `Mailglass.Events.Event` | Ecto schema. Triggered immutable. | Carries the SQLSTATE 45A01 catch + re-raise as `EventLedgerImmutableError`. |
| `Mailglass.Repo` | Wrapper exposing `transact/1` (the modern `Repo.transaction/1` shim per Ecto 3.13 deprecation track). | Per `mailglass-engineering-dna-from-prior-libs.md` §5 starter skeleton. Adopters inject their own `repo:` via Config; this is the indirection. |
| `Mailglass.IdempotencyKey` | Tiny pure module: `for_provider_message_id(provider, id)`, `for_webhook_event(provider, event_id)`. Returns deterministic strings used in the partial UNIQUE index. | Single source of truth for key shape. Used in event ledger writes and webhook dedup. |
| `Mailglass.PubSub` + `Mailglass.PubSub.Topics` | Thin wrappers around `Phoenix.PubSub`. `Topics` exposes `events_for_tenant/1`, `events_for_delivery/2`, etc. | Avoids string-typo bugs across LiveView subscribers. Grep-able topic taxonomy. |
| `Mailglass.TemplateEngine` | Behaviour: `compile/2`, `render/3`. HEEx is the default impl in `Mailglass.TemplateEngine.HEEx`; MJML is opt-in `Mailglass.TemplateEngine.MJML` via `:mrml` per D-18. | Pluggable per `mailglass-engineering-dna-from-prior-libs.md` §3.4. |
| `Mailglass.SuppressionStore` | Behaviour: `add/3`, `lookup/2`, `delete/2`, `list/1`. Default impl is `Mailglass.SuppressionStore.Ecto`. | Pluggable per `mailglass-engineering-dna-from-prior-libs.md` §3.4 + §4.2. |
| `Mailglass.UnsubscribeToken` | Phoenix.Token-backed signing/verification, with a `KeyProvider` indirection so adopters can rotate keys. | Per PROJECT.md v0.5 list (RFC 8058) + Constraints §security. |
| `Mailglass.Compliance` | `add_unsubscribe_headers/1` (RFC 8058), `add_feedback_id/2`, `add_physical_address/2` (auto for `:bulk` stream), `dkim_sign/2` (v0.5+). Custom Credo check `RequiredListUnsubscribeHeaders` enforces. | Per `mailglass-engineering-dna-from-prior-libs.md` §4.7 + PROJECT.md v0.5 list. |
| `Mailglass.Application` | OTP application module — supervision tree owner. | Required for the Application behaviour. |
| `Mailglass.Credo.*` | Custom Credo checks: `NoRawSwooshSendInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`, `NoUnscopedTenantQueryInLib`. | Per PROJECT.md D-17 + `mailglass-engineering-dna-from-prior-libs.md` §2.8. |

### 1.3 Where each domain concept lives — final aggregate map

Following `mailer-domain-language-deep-research.md` §13 aggregate boundaries verbatim:

| Domain noun | Owning namespace | Representation |
|---|---|---|
| **Mailable** | `Mailglass.Mailable` (behaviour + macro) | Module-per-mailer in the adopter's app: `MyApp.UserMailer`. Owns scenario, input contract, preview fixtures, rendering rules. Does **not** own provider IDs / webhook events / suppression. |
| **Message** | `Mailglass.Message` (struct) | Pure struct. Owns content, visible headers, attachments, references, metadata, tags. Does **not** own retry history or webhook events. |
| **Delivery** | `Mailglass.Outbound.Delivery` (schema) + `Mailglass.Outbound` (facade) | Owns recipient, provider/account choice, dispatch attempts, tracking summary, provider refs. Does **not** own a mutable shared message body. |
| **Event** | `Mailglass.Events.Event` (schema, immutable) + `Mailglass.Events` (writer) | Append-only facts. The single source of truth for delivery history (lifecycle + provider-normalized). |
| **InboundMessage** (v0.5+) | `MailglassInbound.InboundMessage` (schema) + `MailglassInbound.Ingress` (boundary plug per provider) | Owns raw source, parsed source, envelope, attachments, inbound provider refs, processing summary. |
| **Mailbox** (v0.5+) | `MailglassInbound.Mailbox` (behaviour) | Handler concept. NOT the UI inbox. |
| **Suppression** | `Mailglass.Suppression.Entry` (schema) + `Mailglass.Suppression` (context) + `Mailglass.SuppressionStore` (behaviour) | Owns scope, reason, source, created/expires timestamps. Does not own preference semantics. |

Secondary nouns from `mailer-domain-language-deep-research.md` §4 (Address, Recipient, SendingIdentity, Tenant, Stream): **kept as field-level concepts inside Message/Delivery**, not promoted to standalone schemas in v0.1. Promoting them to schemas can wait until they have lifecycle (e.g., `Mailglass.SendingIdentity` schema once DNS/DKIM verification lands in v0.5).

---

## 2. Data flow — end-to-end traces

### 2.1 Transactional send (the hot path)

```
Caller:                                                                                  
  Mailglass.deliver_later(MyApp.UserMailer.welcome(user))                                
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 1. Mailable resolution                                                                │ 
│    MyApp.UserMailer.welcome(user)  →  %Mailglass.Message{...} (incomplete)            │ 
│    Pure function call. No side effects.                                                │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 2. Render pipeline (Mailglass.Renderer.render/2)                                      │ 
│    HEEx compile  →  CSS inline (Premailex)  →  minify  →  plaintext (Floki)           │ 
│    On crash: emit [:mailglass, :preview, :render, :exception]; raise TemplateError.    │ 
│    Output: %Mailglass.Message{} with html_body, text_body populated.                  │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 3. Compliance auto-injection (Mailglass.Compliance)                                   │ 
│    if stream == :bulk: add List-Unsubscribe + List-Unsubscribe-Post + physical addr.   │ 
│    Always: add Feedback-ID, ensure Message-ID, Date, MIME-Version.                     │ 
│    Custom Credo check enforces this ran for all non-:transactional sends.              │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 4. Pre-send checks (Mailglass.Outbound.preflight/2)                                   │ 
│    a. Suppression lookup: SuppressionStore.lookup(tenant_id, recipient)                │ 
│       hit  →  {:error, %SuppressedError{}}, emit ops telemetry, NO row written.        │ 
│    b. Rate limit: ETS counter check per (tenant_id, recipient_domain).                 │ 
│       over  →  {:error, %RateLimitError{retry_after: ms}}, NO row written.             │ 
│    c. Stream policy: enforce per-stream invariants (e.g., :transactional rejects       │ 
│       open/click tracking links per PROJECT.md D-08).                                  │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 5. Persist (Mailglass.Outbound.persist_and_enqueue/2) — ONE Ecto.Multi                │ 
│    Multi.new()                                                                         │ 
│    |> Multi.insert(:delivery, Delivery.changeset(...))                                 │ 
│    |> Multi.insert(:event, fn %{delivery: d} ->                                        │ 
│         Events.changeset(:queued, delivery_id: d.id, ...)                              │ 
│       end)                                                                             │ 
│    |> Oban.insert(:job, MyAppMail.Worker.new(...))   # if Oban loaded                  │ 
│    |> Mailglass.Repo.transact()                                                        │ 
│                                                                                        │ 
│    If Oban absent: Task.Supervisor.start_child(...) AFTER the Multi commits, with      │ 
│    a Logger.warning. NEVER inside the transaction (per Ecto best practices §6).        │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ├─── Phoenix.PubSub.broadcast("mailglass:events:#{tenant_id}", {:event, :queued, ...}) 
   │    (Outside the transaction; PubSub failure must not roll back the send.)           
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 6. Worker dispatch (Mailglass.Outbound.Worker.perform/1)                              │ 
│    a. SELECT delivery by id; emit [:mailglass, :outbound, :send, :start]               │ 
│    b. Resolve adapter via Mailglass.Tenancy.adapter_for(delivery.tenant_id)            │ 
│       (cached in Registry per §3 below)                                                 │ 
│    c. Adapter.deliver(message)  →  {:ok, %{message_id: provider_msg_id}}              │ 
│       or {:error, normalized_error}                                                    │ 
│    d. Ecto.Multi:                                                                      │ 
│         |> Multi.update(:delivery, set: [provider_message_id: ..., dispatched_at:])    │ 
│         |> Multi.insert(:event, Events.changeset(:dispatched, ...))                    │ 
│       Per `mailglass-engineering-dna-from-prior-libs.md` gotcha §6.2: every state      │ 
│       change is a Multi-with-event.                                                    │ 
│    e. Emit [:mailglass, :outbound, :send, :stop] with status, message_id, latency_ms.  │ 
│    f. Broadcast {:event, :dispatched, delivery_id, ...} to tenant + delivery topics.   │ 
│                                                                                        │ 
│    On adapter error: insert Event(:rejected | :failed) + retry via Oban (with backoff).│ 
│    On crash: emit :exception telemetry; Oban handles retry; suppress on terminal fail. │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
```

### 2.2 Webhook ingest (the cold path)

```
Provider POST → /webhooks/postmark                                                       
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 1. Plug.Parsers with custom body reader                                               │ 
│    Mailglass.Webhook.CachingBodyReader preserves raw body bytes BEFORE parsing.        │ 
│    (Required because HMAC verifies the raw body, not the parsed JSON.)                 │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 2. Mailglass.Webhook.Plug.call/2                                                      │ 
│    a. Lookup provider config (secret, scheme) from Mailglass.Config.                   │ 
│    b. Verify signature: Postmark = Basic Auth + IP allowlist; SendGrid = ECDSA;        │ 
│       Mailgun = HMAC-SHA256; SES = SNS sig; Resend = signing key.                      │ 
│    c. On mismatch: emit [:mailglass, :webhook, :signature, :verify, :fail];           │ 
│       raise %Mailglass.SignatureError{}. NO recovery (per PROJECT.md inheriting        │ 
│       accrue D-08 in `mailglass-engineering-dna-from-prior-libs.md` §6.5). 401 to LB.  │ 
│    d. On match: emit [:mailglass, :webhook, :signature, :verify, :ok].                 │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 3. Provider mapper (Mailglass.Webhook.Providers.Postmark.normalize/1)                 │ 
│    raw payload  →  %Mailglass.Webhook.Event{                                           │ 
│       event_id: "<provider event id>",       # used as idempotency_key                 │ 
│       event_type: :delivered | :bounced | :complained | ...,    # Anymail taxonomy     │ 
│       provider_message_id: "<provider msg id>",   # used to lookup Delivery            │ 
│       reject_reason: :invalid | nil,                                                    │ 
│       provider: :postmark, raw: raw_payload }                                          │ 
│    Per PROJECT.md D-14: Anymail event taxonomy verbatim.                                │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 4. Lookup + persist — ONE Ecto.Multi                                                  │ 
│    a. SELECT delivery WHERE provider_message_id = ?  (UNIQUE index → fast)             │ 
│       miss  →  emit ops telemetry "orphan webhook"; record event with delivery_id=nil  │ 
│       and a "needs_reconciliation" flag. (Some providers fire :bounced before our     │ 
│       worker has recorded the dispatched provider_message_id — race we MUST tolerate.) │ 
│    b. Build idempotency_key = IdempotencyKey.for_webhook_event(provider, event_id).    │ 
│    c. Multi:                                                                            │ 
│         |> Multi.insert(:event, Events.changeset(...),                                 │ 
│              on_conflict: :nothing,                                                    │ 
│              conflict_target: [:idempotency_key])                                      │ 
│         |> Multi.update(:delivery, [last_event_type:, last_event_at:,                  │ 
│              terminal?:, delivered_at? bounced_at? complained_at?])                    │ 
│       Idempotency: if event already inserted (replay), the insert is a no-op AND       │ 
│       the Delivery update is also no-op (changeset has no real changes). Safe.         │ 
│    d. Suppression auto-add for :bounced (hard) / :complained / :unsubscribed:         │ 
│         within the same Multi: |> Multi.insert(:suppression, ...) via                  │ 
│         Suppression.add_changeset/2 with on_conflict: :nothing.                        │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
   │                                                                                     
   ├─── Phoenix.PubSub.broadcast(topic_for(tenant, delivery_id), {:event, type, ...})   
   │                                                                                     
   ▼                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────────┐ 
│ 5. Return 200 OK to provider.                                                         │ 
│    Per Anymail's guidance (`mailer-domain-language-deep-research.md` §11 "Footguns"): │ 
│    one event raising must NOT nuke the whole batch. Each event is its own Multi.       │ 
└──────────────────────────────────────────────────────────────────────────────────────┘ 
                                                                                         
[admin LiveView: subscribed to "mailglass:events:#{tenant_id}" on mount; receives        
 {:event, ...}; calls Phoenix.LiveView.stream_insert/4 to update the timeline.            
 Page load reads from the Events table, not from process state — PubSub is delta only.]  
```

### 2.3 Failure modes & race conditions (validated)

| Failure mode | Where | Handling |
|---|---|---|
| **Adapter raises during deliver** | Worker step 6c | Oban retries with backoff; final failure inserts `Event(:failed)`; emits `[:mailglass, :outbound, :send, :exception]`; suppresses on `:bounced` terminal-class errors only. |
| **Postgres unavailable during preflight Multi** | Step 5 | Caller receives `{:error, %DBConnection.ConnectionError{}}`; Oban not enqueued; nothing persisted. Correct. |
| **PubSub broadcast fails after Multi commits** | Step 5 trailing broadcast | Logged at warning; admin LiveView falls back to next page-refresh / next event. PubSub is observability, not correctness. |
| **Webhook arrives before worker dispatches (race)** | Step 4a of webhook flow | `provider_message_id` lookup misses. Record event with `delivery_id = nil` and `needs_reconciliation = true`; nightly Oban job reconciles when the worker eventually populates `provider_message_id`. (Postmark and SendGrid both occasionally exhibit this; documented in their forums.) |
| **Webhook replay (provider double-fires)** | Step 4c of webhook flow | Partial UNIQUE index on `idempotency_key` makes the insert a no-op (`on_conflict: :nothing`). Delivery update is also a no-op because changeset has no real changes (we set the same `last_event_at`). Safe. |
| **Two workers dispatch the same delivery** | Step 6 of send flow | Oban's `unique:` option on the worker (constraint on `delivery_id`) prevents enqueue. Belt+suspenders: the `Multi.update(:delivery)` step uses `optimistic_lock(:lock_version)` so a second update raises `Ecto.StaleEntryError`. |
| **SQLSTATE 45A01 from immutability trigger** | Anywhere code tries to UPDATE/DELETE `mailglass_events` | `Mailglass.Repo.transact/1` rescues `Postgrex.Error` with `pg_code: "45A01"` and re-raises as `%Mailglass.EventLedgerImmutableError{}`. Per `mailglass-engineering-dna-from-prior-libs.md` gotcha §6.2. |
| **Telemetry handler raises** | Anywhere | `:telemetry.span/3` catches; per §2.5 of DNA doc telemetry must NEVER raise from handlers. The `Mailglass.Telemetry` wrapper enforces. |
| **Suppression race: send to alice@x while alice@x added to suppressions concurrently** | Steps 4a + admin Suppression.add | Acceptable race. v0.1: best-effort check at preflight. v0.5+: optionally promote to a check-constraint via DB function `is_suppressed(tenant_id, address)` called inside the Delivery insert. |

---

## 3. Process architecture

### 3.1 Application supervision tree

Per `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §2 ("A good default application tree is boring"). Adapted for mailglass:

```
Mailglass.Application                                                                    
├─ Mailglass.Telemetry                       # attaches handlers, supervises poller       
├─ {Phoenix.PubSub, name: Mailglass.PubSub}                                              
├─ {Registry, keys: :unique, name: Mailglass.AdapterRegistry}                            
│                                              # dynamic per-tenant adapter cache         
├─ Mailglass.RateLimiter                       # owns ETS table (see §3.3 below)          
├─ {Task.Supervisor, name: Mailglass.TaskSupervisor}                                     
│                                              # fallback for deliver_later when Oban     
│                                              # absent; also for fire-and-forget         
│                                              # broadcasts where we do NOT want to       
│                                              # block the calling process                
└─ (Adopter's Repo, Endpoint, Oban supervised by their own Application — not by us.)     
```

**Notes:**
- `Mailglass` is a library, not an application that boots an Endpoint or a Repo. Adopters supervise their own Repo and Phoenix Endpoint. We supervise *our own* PubSub, Registry, RateLimiter, TaskSupervisor.
- We do **not** start `Mailglass.Repo` — it is a thin wrapper that delegates to the adopter's Repo (configured via NimbleOptions). Following accrue's pattern from `mailglass-engineering-dna-from-prior-libs.md` §5.
- Children are minimal because **the work is functional**. The send pipeline is just code, not processes.

### 3.2 What is NOT a process (and why)

Per `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §1 ("A process is not a class") and §2 ("do not funnel hot application traffic through one named GenServer"):

| Concern | NOT a process. Why? |
|---|---|
| Renderer / Components / Message construction | Pure functions. No state, no concurrency primitive needed. |
| Mailable resolution | Module dispatch. |
| Event ledger writes | Inline `Ecto.Multi` from the calling process. No queueing layer needed; Postgres is the queue. |
| Webhook signature verification | Plug call inside the request process. |
| Provider mapper (`Webhook.Providers.*`) | Pure function `normalize/1`. |
| Suppression lookup | DB query from the calling process (worker or web request). |
| Tenancy `scope/2` | Pure function on a `%Scope{}` struct. |

### 3.3 The one GenServer — `Mailglass.RateLimiter`

**Recommendation: ETS-only token bucket; no GenServer for v0.1.** Promote to a GenServer-supervised bucket only if and when cluster-coordinated limits become required (v0.5+ cross-node deliverability per PROJECT.md v0.5 list).

Rationale (synthesized from `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §3 ("ETS for fast local derived state") and §4 ("ETS done properly")):

- **v0.1 (single-node):** A named ETS table `:mailglass_rate_limit` owned by a tiny supervisor child whose only job is to create the table at boot (so the table outlives any one process is overkill; an ETS-owning `GenServer.init/1` that calls `:ets.new/2` is acceptable and standard). Token bucket math is implemented as functions that `:ets.update_counter/4` with `read_concurrency: true, write_concurrency: :auto, decentralized_counters: true` per §4 of the system design doc. **No serialization bottleneck**, no message-passing per send.
- **v0.5+ (multi-node):** When per-tenant limits need cross-node coordination, the right answer is *not* a single GenServer that becomes a bottleneck. The right answer is one of: (a) a per-(tenant, domain) `:pg`-based agreement protocol; (b) a Postgres-row token bucket using `SELECT ... FOR UPDATE` advisory locks; (c) Oban itself (Oban Pro's `unique:` with sliding window). Defer this decision until v0.5 with a real benchmark.

**The `Mailglass.RateLimiter` module-shape stays the same** in both versions — caller does `RateLimiter.check(tenant_id, recipient_domain)` → `:ok | {:error, %RateLimitError{retry_after: ms}}`. The implementation behind it can evolve.

### 3.4 Registry — `Mailglass.AdapterRegistry`

Per the question's prompt and `mailglass-engineering-dna-from-prior-libs.md` §4.2 (multi-adapter).

Use case: the adopter declares per-tenant adapters via `Mailglass.Tenancy.adapter_for/1` callback. We **cache the resolved adapter module** in a Registry entry keyed by `tenant_id` to avoid re-running the adopter's resolver on every send.

```elixir
case Registry.lookup(Mailglass.AdapterRegistry, tenant_id) do
  [{_pid, adapter}] -> adapter
  [] ->
    adapter = MyApp.Tenancy.adapter_for(tenant_id)
    Registry.register(Mailglass.AdapterRegistry, tenant_id, adapter)
    adapter
end
```

Cache invalidation: `Mailglass.Tenancy.evict_adapter_cache(tenant_id)` is exposed for adopters to call when they change a tenant's provider config.

### 3.5 Task.Supervisor — `Mailglass.TaskSupervisor`

Two uses:
1. **`deliver_later` fallback** when `:oban` is not loaded (PROJECT.md D-07). The Multi commits the delivery + queued event; immediately after, `Task.Supervisor.start_child(...)` runs the worker logic in a supervised task. With a `Logger.warning` on startup that informs the adopter Oban is recommended for production.
2. **Fire-and-forget side broadcasts** (PubSub fan-out, optional reconciliation jobs).

Per `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §2: `{Task.Supervisor, name: ...}` (single supervisor) is fine; only promote to `{PartitionSupervisor, child_spec: Task.Supervisor, ...}` if profiling shows the supervisor process itself is contended. Unlikely at email volumes.

### 3.6 PubSub topic taxonomy

Per the question, with a small refinement: encode topics through `Mailglass.PubSub.Topics` so they are grep-able and typo-proof.

```elixir
defmodule Mailglass.PubSub.Topics do
  @doc "All events for a tenant. Subscribed by the admin dashboard list view."
  def events_for_tenant(tenant_id), do: "mailglass:events:#{tenant_id}"

  @doc "All events for one delivery. Subscribed by the admin detail view."
  def events_for_delivery(tenant_id, delivery_id),
    do: "mailglass:events:#{tenant_id}:#{delivery_id}"

  @doc "Suppression list changes. Subscribed by suppression management UI."
  def suppression_for_tenant(tenant_id), do: "mailglass:suppressions:#{tenant_id}"

  @doc "Operator-class events: bounces, complaints, DLQ. For alert handlers."
  def ops_events, do: "mailglass:ops"
end
```

Subscribers (`MailglassAdmin` LiveViews) call `Phoenix.LiveView.stream_insert/4` per `phoenix-live-view-best-practices-deep-research.md` §5 (streams for large volatile collections; admin event timelines are exactly this shape).

---

## 4. Database schema design

### 4.1 Conventions (locked)

- **Postgres only.** Per PROJECT.md Constraints §Persistence.
- **`binary_id` UUID PKs** with `Ecto.UUID` cast. Per `mailglass-engineering-dna-from-prior-libs.md` §3.8.
- **`timestamps(type: :utc_datetime_usec)`** for microsecond precision (event ordering matters). Per §3.8.
- **`tenant_id` on every record.** Per PROJECT.md D-09. Single-tenant adopters get a default tenant_id from `Tenancy` (e.g., `"default"`).
- **`metadata jsonb` on every record** for adopter extensibility. Empty map default. Indexed via GIN in v0.5 if needed.
- **No soft-delete** on transactional tables. Status enums + audit via Events.
- **Migrations shipped as templates** generated by `mix mailglass.install` so the adopter owns them. Per `mailglass-engineering-dna-from-prior-libs.md` §3.2.

### 4.2 `mailglass_deliveries`

```sql
CREATE TABLE mailglass_deliveries (
  id            UUID PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  mailable      TEXT NOT NULL,          -- "MyApp.UserMailer.welcome/1" — for grouping
  stream        TEXT NOT NULL,          -- 'transactional' | 'operational' | 'bulk'
  recipient     TEXT NOT NULL,          -- normalized lowercased
  recipient_domain TEXT NOT NULL,       -- denormalized for rate-limit + analytics

  provider      TEXT,                   -- :postmark | :sendgrid | ...
  provider_message_id TEXT,             -- populated by worker AFTER adapter returns

  -- Projected summary fields (cheap reads for admin lists)
  last_event_type TEXT NOT NULL,        -- 'queued' on insert
  last_event_at   TIMESTAMPTZ NOT NULL,
  terminal        BOOLEAN NOT NULL DEFAULT false,
  dispatched_at   TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  bounced_at      TIMESTAMPTZ,
  complained_at   TIMESTAMPTZ,
  suppressed_at   TIMESTAMPTZ,

  metadata        JSONB NOT NULL DEFAULT '{}',
  lock_version    INTEGER NOT NULL DEFAULT 1,    -- optimistic_lock

  inserted_at     TIMESTAMPTZ NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL
);

-- Hot lookup: webhook → delivery
CREATE UNIQUE INDEX mailglass_deliveries_provider_msg_id_idx
  ON mailglass_deliveries (provider, provider_message_id)
  WHERE provider_message_id IS NOT NULL;

-- Admin: list deliveries by tenant + recent
CREATE INDEX mailglass_deliveries_tenant_recent_idx
  ON mailglass_deliveries (tenant_id, last_event_at DESC);

-- Admin: search by recipient
CREATE INDEX mailglass_deliveries_tenant_recipient_idx
  ON mailglass_deliveries (tenant_id, recipient);

-- Filter by stream + status
CREATE INDEX mailglass_deliveries_tenant_stream_terminal_idx
  ON mailglass_deliveries (tenant_id, stream, terminal, last_event_at DESC);
```

**Why projection columns.** Per `mailer-domain-language-deep-research.md` §12 ("prefer facts first, summaries second"): events are the truth, but `last_event_type`, `delivered_at`, etc. are denormalized projections so the admin list view doesn't need to JOIN events on every render. Maintained inside the same `Ecto.Multi` that inserts the event, never independently. Custom Credo check could enforce: "any insert into `events` for an existing delivery must be in a Multi that also updates the delivery's projection fields."

### 4.3 `mailglass_events` (the load-bearing table; per PROJECT.md D-15)

```sql
CREATE TABLE mailglass_events (
  id                UUID PRIMARY KEY,
  tenant_id         TEXT NOT NULL,
  delivery_id       UUID,                 -- nullable: orphan webhooks before reconcile
  type              TEXT NOT NULL,        -- :queued | :dispatched | :delivered | ...
                                          -- mailglass internal + Anymail-normalized
  occurred_at       TIMESTAMPTZ NOT NULL, -- provider's reported time, or now() for internal

  idempotency_key   TEXT,                 -- e.g., "postmark:webhook:abc123"
  reject_reason     TEXT,                 -- :invalid | :bounced | :timed_out | ...

  raw_payload       JSONB,                -- full provider payload for replay (webhook only)
  normalized_payload JSONB NOT NULL DEFAULT '{}',

  needs_reconciliation BOOLEAN NOT NULL DEFAULT false,

  inserted_at       TIMESTAMPTZ NOT NULL
);

-- Idempotency: replay-safe webhooks
CREATE UNIQUE INDEX mailglass_events_idempotency_key_idx
  ON mailglass_events (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Hot read: timeline for one delivery
CREATE INDEX mailglass_events_delivery_idx
  ON mailglass_events (delivery_id, occurred_at)
  WHERE delivery_id IS NOT NULL;

-- Tenant firehose for admin
CREATE INDEX mailglass_events_tenant_recent_idx
  ON mailglass_events (tenant_id, inserted_at DESC);

-- Reconciliation worker
CREATE INDEX mailglass_events_needs_reconcile_idx
  ON mailglass_events (tenant_id, inserted_at)
  WHERE needs_reconciliation = true;

-- ❶ The immutability function
CREATE OR REPLACE FUNCTION mailglass_raise_immutability()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'mailglass_events is append-only'
    USING ERRCODE = '45A01';
END;
$$ LANGUAGE plpgsql;

-- ❷ The trigger (per PROJECT.md D-15)
CREATE TRIGGER mailglass_events_immutable
  BEFORE UPDATE OR DELETE ON mailglass_events
  FOR EACH ROW EXECUTE FUNCTION mailglass_raise_immutability();
```

**Why no FK from events.delivery_id → deliveries.id.** Two reasons: (1) orphan webhooks must record successfully (`delivery_id = nil`) per §2.3 race-conditions; (2) the FK would block the immutability invariant if a delivery were ever deleted. We keep the relationship logical but not physically enforced; the Events writer (`Mailglass.Events.append/2`) validates `delivery_id` exists when non-nil.

### 4.4 `mailglass_suppressions`

```sql
CREATE TABLE mailglass_suppressions (
  id            UUID PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  address       TEXT NOT NULL,        -- normalized lowercased
  scope         TEXT NOT NULL,        -- 'address' | 'domain' | 'address_stream'
  stream        TEXT,                 -- nullable; only for scope='address_stream'
  reason        TEXT NOT NULL,        -- :hard_bounce | :complaint | :unsubscribe |
                                      -- :manual | :policy | :invalid_recipient
  source        TEXT NOT NULL,        -- 'webhook:postmark' | 'admin:user_id=...' | 'auto'
  expires_at    TIMESTAMPTZ,          -- nullable; permanent if NULL
  metadata      JSONB NOT NULL DEFAULT '{}',
  inserted_at   TIMESTAMPTZ NOT NULL
);

-- Hot pre-send check (the dominant query)
CREATE UNIQUE INDEX mailglass_suppressions_tenant_address_scope_idx
  ON mailglass_suppressions (tenant_id, address, scope, COALESCE(stream, ''));

-- Admin: address-scoped lookup
CREATE INDEX mailglass_suppressions_tenant_address_idx
  ON mailglass_suppressions (tenant_id, address);

-- Expiry sweeper
CREATE INDEX mailglass_suppressions_expires_idx
  ON mailglass_suppressions (expires_at)
  WHERE expires_at IS NOT NULL;
```

### 4.5 What v0.1 explicitly does NOT need

- **No `mailglass_subscribers` / `mailglass_lists` / `mailglass_campaigns` tables.** Marketing email is permanently out of scope per PROJECT.md D-03. The `mailglass-engineering-dna-from-prior-libs.md` §4.3 schema list mentioned these because that doc was written when marketing was contemplated; PROJECT.md narrowed it.
- **No `mailglass_inbound` / `mailglass_domains` tables in v0.1.** Inbound lands in v0.5+ as `mailglass_inbound` package. Domain DKIM verification lands in v0.5.
- **No materialized views.** The projection columns on `mailglass_deliveries` (`last_event_at`, `delivered_at`, etc.) are sufficient for admin reads. Materialized rollups can wait until volume justifies them.

### 4.6 Status state machine — enforce in app, NOT in DB check constraint

The question asks: "Constraint enforcement (status state machine via check constraints?)"

**Recommendation: NO check constraint in v0.1.** Reasoning:

1. The Anymail event taxonomy permits "weird" sequences: `:opened` events can arrive before `:delivered` events from some providers; `:bounced` can arrive before our internal `:dispatched` (orphan race per §2.3). A naive state machine (`queued → dispatched → delivered → terminal`) breaks on real provider data.
2. The append-only `mailglass_events` table IS the truth. Projections on `mailglass_deliveries` are computed from the latest event — they do not need to enforce ordering.
3. App-level guard: `Mailglass.Outbound.update_projections/2` only updates projection columns to "later" values (e.g., never overwrites `delivered_at` once set). This is testable and documented; a check constraint would be brittle.
4. Per `ecto-best-practices-deep-research.md` §6.2: prefer DB-enforced correctness — but only for invariants that are actually invariant. Email lifecycle ordering is provider-dependent and not a real invariant.

Revisit in v1.0+ if specific bugs appear.

---

## 5. Behaviour boundaries (what's pluggable)

Per PROJECT.md D-17 (`@behaviour Mailglass.*`) and `mailglass-engineering-dna-from-prior-libs.md` §3.4 (combine optional deps + pluggable behaviours).

| Behaviour | Default impl | Why pluggable | Consumed where |
|---|---|---|---|
| `Mailglass.Adapter` | `Mailglass.Adapters.Swoosh` (wraps any `Swoosh.Adapter` and normalizes errors); `Mailglass.Adapters.Fake` (test gate) | Adopters use any of Swoosh's 12+ adapters; Fake is the release gate (PROJECT.md D-13) | `Mailglass.Outbound.Worker` |
| `Mailglass.TemplateEngine` | `Mailglass.TemplateEngine.HEEx` | MJML opt-in via `:mrml` (PROJECT.md D-18); future Liquid/Mustache adapters possible | `Mailglass.Renderer` |
| `Mailglass.SuppressionStore` | `Mailglass.SuppressionStore.Ecto` | Tests can use `Mailglass.SuppressionStore.ETS`; large-scale adopters might want Redis bloom filters | `Mailglass.Suppression`, `Mailglass.Outbound.preflight` |
| `Mailglass.Tenancy` | `Mailglass.Tenancy.SingleTenant` (returns `tenant_id: "default"`) | Adopters with multi-tenancy plug in `MyApp.Tenancy` returning a `%Scope{}` from a request/conn | Outbound, Webhook, Admin LiveView mount |
| `Mailglass.UnsubscribeToken` | `Mailglass.UnsubscribeToken.PhoenixToken` (uses `Phoenix.Token.sign/3`) | Adopters needing key rotation or external KMS plug in their own | `Mailglass.Compliance.add_unsubscribe_headers/1` (v0.5) |
| `Mailglass.Webhook.Handler` | `Mailglass.Webhook.Handler.Default` (writes Event + broadcasts PubSub) | Adopters can layer custom logic (e.g., "on :complaint, page the on-call") | `Mailglass.Webhook.Plug` |
| `MailglassInbound.Mailbox` (v0.5+) | none — adopter declares all | Application logic, not framework concern | `MailglassInbound.Router` |
| `MailglassInbound.Storage` (v0.5+) | `MailglassInbound.Storage.LocalFS` | S3 adapter for production; LocalFS for dev | `MailglassInbound.Ingress.*` |

**Discovery rule:** every behaviour is wired via `Mailglass.Config` NimbleOptions. No magic auto-discovery. Adopter explicitly opts in:

```elixir
config :mailglass,
  adapter: {Mailglass.Adapters.Swoosh, swoosh_adapter: {Swoosh.Adapters.Postmark, ...}},
  suppression_store: Mailglass.SuppressionStore.Ecto,
  tenancy: MyApp.Tenancy,
  unsubscribe_token: Mailglass.UnsubscribeToken.PhoenixToken
```

Per `mailglass-engineering-dna-from-prior-libs.md` gotcha §6.1: validated at boot via `Mailglass.Config.resolve!/1`.

---

## 6. Build order (validated + refined)

The proposed Layer 0 → Layer 7 order is **correct in dependency direction** but missing one critical gate. Here is the refined order with rationale:

| Layer | Components | Why this order |
|---|---|---|
| **0. Foundations** | `Mailglass.Error` (+ subtypes), `Mailglass.Config` (NimbleOptions), `Mailglass.Telemetry` primitives, `Mailglass.Repo` (transact wrapper), `Mailglass.IdempotencyKey` | Every later layer depends on these. Config/Errors/Telemetry are zero-dep; building them first means every other module already has its instrumentation hooks. Per `mailglass-engineering-dna-from-prior-libs.md` §2.4–§2.5. |
| **1. Pure rendering** | `Mailglass.Message` (struct), `Mailglass.Components` (HEEx), `Mailglass.TemplateEngine` (behaviour) + `.HEEx` impl, `Mailglass.Renderer` (pipeline) | All pure functions. No DB, no processes. Can be tested with `assert render(...) == expected_html`. The "demo on day one" demo. |
| **2. Persistence schemas** | `Mailglass.Outbound.Delivery` (Ecto schema), `Mailglass.Events.Event` (schema, with the immutability trigger migration), `Mailglass.Suppression.Entry` (schema), `Mailglass.Events` (writer context with the Multi invariant), `Mailglass.SuppressionStore` (behaviour + Ecto impl) | Must come before adapter/mailable so the send pipeline can be wired end-to-end. Critically: the immutability trigger lands here with its own integration test (`assert_raise EventLedgerImmutableError`). |
| **3. Transport** | `Mailglass.Adapter` (behaviour), `Mailglass.Adapters.Fake` **first**, then `Mailglass.Adapters.Swoosh` (wraps `Swoosh.Adapter`) | **Per PROJECT.md D-13: build Fake first.** It's the release gate. Building Swoosh wrapper after means we can validate the whole pipeline against Fake before depending on a real adapter. |
| **4. Send pipeline** | `Mailglass.Tenancy` (behaviour + SingleTenant default), `Mailglass.RateLimiter` (ETS), `Mailglass.Suppression` (context with `check_before_send/1`), `Mailglass.Mailable` (behaviour + macro), `Mailglass.Outbound` (facade with `send/2`, `deliver_later/2`), `Mailglass.Outbound.Worker` (Oban worker + Task.Supervisor fallback), `Mailglass.PubSub.Topics` | The hot path. End-to-end testable with Fake adapter at the close of this layer. **Marker for "we have a working core."** |
| **5. Webhook ingest** | `Mailglass.Webhook.CachingBodyReader`, `Mailglass.Webhook.Event` (struct), `Mailglass.Webhook.Providers.Postmark`, `Mailglass.Webhook.Providers.SendGrid` (PROJECT.md D-10: only these two for v0.1), `Mailglass.Webhook.Plug`, `Mailglass.Webhook.Handler` (behaviour + Default impl), `Mailglass.Compliance` (RFC-required headers; full RFC 8058 unsubscribe lands in v0.5 per PROJECT.md) | Depends on Events writer (Layer 2) and Adapter (Layer 3) being stable so we can verify webhook → event → projection update end-to-end. |
| **6. mailglass_admin (preview only for v0.1)** | `MailglassAdmin.Router` macro, `MailglassAdmin.PreviewLive` (mailable sidebar with `preview_props/1` auto-discovery; device toggle; HTML/Text/Raw/Headers tabs per PROJECT.md v0.1 list), `MailglassAdmin.Components` | Sibling Hex package. Depends on Mailable + Renderer being stable. Dev-only mount per PROJECT.md D-11. The full prod admin (sent-mail browser, suppression UI, replay) is a v0.5 milestone. |
| **6.5 Custom Credo checks** | `Mailglass.Credo.NoRawSwooshSendInLib`, `Mailglass.Credo.RequiredListUnsubscribeHeaders` (v0.5+), `Mailglass.Credo.NoPiiInTelemetryMeta`, `Mailglass.Credo.NoUnscopedTenantQueryInLib` | **Insertion point matters**: build these once Layers 4 and 5 stabilize, so the rules can be refined against real code. Per `mailglass-engineering-dna-from-prior-libs.md` §2.8. |
| **7. Installer + golden-diff CI** | `mix mailglass.install` task, `priv/templates/mailglass.install/*.eex`, `test/example/` Phoenix host app, golden-diff snapshot test, `mix verify.phase<NN>` aliases | **Per `mailglass-engineering-dna-from-prior-libs.md` §3.2**: build only after the public API is stable, otherwise the goldens churn. Per PROJECT.md v0.1 list: `--no-admin` flag matrix; `.mailglass_conflict_*` sidecars on rerun. |

**The added gate:** Layer 6.5 (Custom Credo checks) belongs *between* the implementation layers and the installer, not after everything. They enforce rules that the installer-generated code will be measured against.

**Layer 0 + Layer 1 are the "demo day" milestone.** With those two layers, you can demo `Mailglass.Renderer.render(MyApp.UserMailer.welcome(user))` and produce inlined-CSS HTML+text. That's the v0.0.x preview release; everything from Layer 2 onward is the v0.1 milestone.

---

## 7. Boundary enforcement — `boundary` library

**Recommendation: YES, adopt `boundary` from Layer 0.** Per accrue/sigra DNA inferred from `mailglass-engineering-dna-from-prior-libs.md` §2.8 (custom Credo checks for domain rules) — `boundary` is the structural complement to those lint-time checks.

Suggested boundary definitions:

```elixir
defmodule Mailglass do
  use Boundary,
    deps: [],
    exports: [Outbound, Mailable, Message, Renderer, Components, Suppression,
             Webhook, Tenancy, Telemetry, Error, Config, IdempotencyKey,
             PubSub.Topics, Adapters.Fake, Adapter]
end

defmodule Mailglass.Outbound do
  use Boundary,
    deps: [Mailglass.Message, Mailglass.Renderer, Mailglass.Compliance,
           Mailglass.Suppression, Mailglass.RateLimiter, Mailglass.Events,
           Mailglass.Tenancy, Mailglass.Telemetry, Mailglass.Error,
           Mailglass.Repo, Mailglass.PubSub, Mailglass.Adapter]
end

defmodule Mailglass.Events do
  use Boundary, deps: [Mailglass.Repo, Mailglass.Telemetry, Mailglass.Error]
  # Note: Events does NOT depend on Outbound or Webhook — they depend on it.
end

defmodule Mailglass.Webhook do
  use Boundary,
    deps: [Mailglass.Events, Mailglass.Suppression, Mailglass.Tenancy,
           Mailglass.Telemetry, Mailglass.Error, Mailglass.IdempotencyKey,
           Mailglass.PubSub, Mailglass.Repo]
end

defmodule Mailglass.Renderer do
  use Boundary, deps: [Mailglass.Message, Mailglass.TemplateEngine, Mailglass.Components,
                       Mailglass.Telemetry, Mailglass.Error]
end
```

**The contract `boundary` enforces** (which Credo cannot):
- `Mailglass.Renderer` cannot accidentally start depending on `Mailglass.Outbound` or `Repo`. Renderer is pure.
- `Mailglass.Events` cannot accidentally depend on `Mailglass.Outbound` (cycle).
- `MailglassAdmin.*` (in the sibling package) declares its mailglass deps explicitly; it cannot import private internals.
- `Mailglass.Adapters.*` cannot reach back into `Mailglass.Outbound` (adapters are leaves).

Per `boundary` docs: it runs as a Mix compiler and fails the build on violation. Wire it into the Lint lane per `mailglass-engineering-dna-from-prior-libs.md` §2.2.

---

## 8. Confidence assessment + open questions

| Area | Confidence | Notes |
|---|---|---|
| Top-level module catalog | HIGH | Validated against `mailer-domain-language-deep-research.md` §13 + `mailglass-engineering-dna-from-prior-libs.md` §4.1; refinements tracked above. |
| Event ledger schema + immutability trigger | HIGH | Locked in PROJECT.md D-15 and `mailglass-engineering-dna-from-prior-libs.md` §3.6. Verbatim port from accrue. |
| Aggregate boundaries (Mailable / Message / Delivery / Event / Suppression) | HIGH | `mailer-domain-language-deep-research.md` §13 explicitly defines what each owns and does NOT own. |
| Send pipeline data flow | HIGH | Synthesized from `mailglass-engineering-dna-from-prior-libs.md` §4.7 + Ecto best-practices §6 (Multi for compound writes). |
| Webhook idempotency via partial UNIQUE index | HIGH | PROJECT.md v0.1 list + `mailglass-engineering-dna-from-prior-libs.md` §3.6. |
| Process architecture (mostly functional, one ETS rate limiter) | HIGH | Aligned with `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §1-§4. |
| Build order | HIGH | Standard layered approach; refinement adds Credo checks at 6.5. |
| `boundary` adoption | MEDIUM-HIGH | Per accrue/sigra DNA implied; concrete boundary blocks are my synthesis and may need adjustment as code is written. |
| **Rate limiter: ETS-only vs GenServer** | **MEDIUM** | Recommend ETS-only for v0.1; GenServer wrapper only if cluster-coordinated limits needed in v0.5+. The single material design choice that may be revisited. |
| **Status state machine: app-enforced vs DB check constraint** | MEDIUM | Recommend app-enforced (no DB constraint). Provider event ordering is non-monotonic in practice; check constraint would be brittle. Revisit in v1.0+ if specific bugs appear. |
| **Orphan webhook handling (events with `delivery_id = nil`)** | MEDIUM | The reconciliation worker is described but not yet specified in detail. Phase-specific research needed during v0.5 webhook work. |

**Open questions for downstream phases:**
1. Exact NimbleOptions schema for `Mailglass.Config` — defer to Layer 0 phase planning.
2. Whether `Mailglass.Tenancy` should auto-detect Phoenix 1.8 `Scope` — defer to Layer 4 phase planning.
3. Reconciliation worker schedule + scope — defer to v0.5 webhook milestone.
4. mailglass_admin LiveView routing macro signature (parameter shape, scope passing) — defer to Layer 6 phase planning, prototype against `~/projects/sigra/lib/sigra/admin/router.ex`.
5. Whether to adopt `:typed_struct` / `:typed_ecto_schema` for the schema modules — minor; defer to Layer 2 phase planning.

---

## 9. Document cross-reference index

When implementing each layer, the highest-fidelity reference is:

| Layer | Primary references (with citations) |
|---|---|
| 0 (Errors / Config / Telemetry) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §2.4 (error model), §2.5 (telemetry), §6.1 (Config gotcha) |
| 1 (Renderer) | `prompts/Phoenix needs an email framework not another mailer.md` §3 "MJML vs ... component-native"; PROJECT.md D-18 |
| 2 (Schemas + immutability) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §3.6; PROJECT.md D-15; `prompts/ecto-best-practices-deep-research.md` §6, §7 |
| 3 (Adapter behaviour + Fake) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §3.5 (Fake-first); PROJECT.md D-13; reference impl: `~/projects/accrue/accrue/lib/accrue/processor/fake.ex` |
| 4 (Mailable + send pipeline) | `prompts/mailer-domain-language-deep-research.md` §13 (aggregate boundaries); `prompts/Phoenix needs an email framework not another mailer.md` §6 (DX target); `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §3, §8 |
| 5 (Webhook) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §4.5; reference impl: `~/projects/lattice_stripe/lib/lattice_stripe/webhook/{plug.ex,cache_body_reader.ex}`; PROJECT.md D-10, D-14 |
| 6 (mailglass_admin) | `prompts/phoenix-live-view-best-practices-deep-research.md` §3 (function components first), §5 (streams); reference impl: `~/projects/sigra/lib/sigra/admin/`; PROJECT.md D-11 |
| 6.5 (Credo checks) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §2.8; PROJECT.md D-17 |
| 7 (Installer + golden-diff) | `prompts/mailglass-engineering-dna-from-prior-libs.md` §3.2; PROJECT.md D-12; reference impl: `~/projects/sigra/test/sigra/install/golden_diff_test.exs` |

---

*End of architecture research.*
