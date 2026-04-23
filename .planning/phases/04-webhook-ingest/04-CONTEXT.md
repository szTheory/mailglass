# Phase 4: Webhook Ingest — Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

A Postmark or SendGrid webhook POST arriving at `/webhooks/<provider>` is HMAC/Basic-Auth-verified on the raw body, parsed to the Anymail event taxonomy verbatim (+ one mailglass-internal `:reconciled` lifecycle event — see D-16), persisted through one `Ecto.Multi` (webhook_events row + events ledger row(s) + Delivery projection update) within `Repo.transact/1`, and the Projector post-commit broadcast (Phase 3 D-04) is what admin LiveViews (Phase 5) and adopter telemetry handlers subscribe to. N-replayed webhooks converge to the same state as applied once — signature-verify failure raises `%Mailglass.SignatureError{}` at call site with no recovery path and returns 401; forged or malformed-but-signed requests fall through to 422 (tenant-unresolved) or 200 (orphan delivery). A permanent orphan-reconciliation worker runs on an Oban cron so admin never sees "stuck" orphaned events in steady state.

At the close of Phase 4 an adopter runs `import Mailglass.Webhook.Router` + `mailglass_webhook_routes "/webhooks"` in their Phoenix router inside a minimal pipeline (no `:browser`, no `:fetch_session`, no `:protect_from_forgery`), wires `Plug.Parsers` with `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` and `length: 10_000_000` in their `endpoint.ex`, and receives normalized `Mailglass.Event` rows (plus Delivery projection updates + PubSub broadcasts) for every real Postmark/SendGrid event that hits their app. Fake-adapter-simulated events (Phase 3 D-03) flow through the SAME `Events.append_multi/3` + `Projector.update_projections/2` path the webhook plug uses — the tests that already run against Fake prove the production write path.

**8 REQ-IDs:** HOOK-01 (CachingBodyReader), HOOK-02 (Webhook.Plug + router macro + 200-on-replay semantics), HOOK-03 (Postmark = Basic Auth + IP allowlist opt-in), HOOK-04 (SendGrid = ECDSA via OTP 27 `:crypto`/`:public_key`), HOOK-05 (Anymail taxonomy verbatim + `Logger.warning` + `:unknown` fallthrough on unmapped types), HOOK-06 (one `Ecto.Multi`: webhook_events insert + events insert + Delivery projection update + PubSub broadcast + orphan `delivery_id: nil` handling), HOOK-07 (StreamData 1000-replay property test), TEST-03 (property tests on signature verification + idempotency + tenant resolution).

**Out of scope for this phase (lands later):** LiveView preview admin (Phase 5 PREV-01..06); twelve custom Credo checks including `NoPiiInTelemetryMeta` (LINT-02) and `EventTaxonomyIsVerbatim` (new in D-23, lands Phase 6); installer + webhook scaffolding generator (Phase 7 INST-01..04). v0.5 items explicitly deferred from Phase 4: **auto-suppression on terminal events** (DELIV-02 — D-21 below); **async-ingest mode** (`:webhook_ingest_mode: :async` reserved in D-09 but implementation defers); **Mailgun / SES / Resend** provider verifiers (PROJECT D-10 — verifier behaviour shape is sealed at v0.1 so v0.5 plugs them in without API break); **per-tenant adapter resolver** via `c:adapter_for/1` (DELIV-07 — shape parallels D-10 `c:resolve_webhook_tenant/1`); **prod admin dashboard** showing orphan-events panel + DLQ visualization (v0.5); **`mailglass_inbound`** (v0.5+, separate package).

</domain>

<decisions>
## Implementation Decisions

### Verifier architecture (HOOK-03, HOOK-04, HOOK-05)

- **D-01: Sealed two-callback Provider behaviour.** `Mailglass.Webhook.Provider` with `@moduledoc false` (not adopter-extensible at v0.1 — PROJECT D-10 already defers Mailgun/SES/Resend to v0.5). Two callbacks:
  ```elixir
  @callback verify!(raw_body :: binary(), headers :: [{String.t(), String.t()}], config :: map()) :: :ok
  @callback normalize(raw_body :: binary(), headers :: [{String.t(), String.t()}]) :: [%Mailglass.Events.Event{}]
  ```
  `verify!/3` is the bang form — raises `%Mailglass.SignatureError{}` on failure, matching the engineering-DNA "no recovery from forged webhooks" invariant verbatim. `normalize/2` is pure — takes verified bytes, returns a list of `%Event{}` structs in Anymail taxonomy. Two concrete modules ship: `Mailglass.Webhook.Providers.Postmark` + `Mailglass.Webhook.Providers.SendGrid`. Exhaustive `case provider` dispatch in `Mailglass.Webhook.Plug` — non-listed providers return `{:error, :unknown_provider}` at router-mount time (compile error, not runtime 404).
- **D-02: Pure tuple input, not `%Plug.Conn{}`.** Verifier receives `{raw_body, headers, config}` — keeps the behaviour portable for v0.5 SES SQS polling + inbound testing contexts where no Conn exists. `Mailglass.Webhook.Plug` does the conn→tuple adaptation at one choke point (`extract_headers_and_raw_body/1`). Tests build fixtures in 3 lines of setup without Conn scaffolding.
- **D-03: SendGrid ECDSA verification on OTP 27 uses `:public_key.der_decode/2`, NOT `:public_key.pem_decode/1`.** SendGrid ships a one-line base64-encoded DER (no `-----BEGIN PUBLIC KEY-----` framing) in the dashboard — `pem_decode/1` does not parse it. The correct sequence:
  ```elixir
  decoded = Base.decode64!(sendgrid_public_key_b64)
  {:SubjectPublicKeyInfo, alg_id, pk_bits} = :public_key.der_decode(:SubjectPublicKeyInfo, decoded)
  {:AlgorithmIdentifier, _oid, ec_params_der} = alg_id
  ecc_params = :public_key.der_decode(:EcpkParameters, ec_params_der)
  pk = {{:ECPoint, pk_bits}, ecc_params}
  signed_payload = timestamp <> raw_body
  sig = Base.decode64!(sendgrid_signature_b64)
  :public_key.verify(signed_payload, :sha256, sig, pk)  # => true | false
  ```
  Curve is **prime256v1 (P-256 / secp256r1)** — SendGrid's documented default. Headers: `X-Twilio-Email-Event-Webhook-Signature` + `X-Twilio-Email-Event-Webhook-Timestamp`. **Pattern-match strictly on `true`** — raise on `false`, `{:error, _}`, and DER-decode exceptions (closes the "wrong algo silently returns `false`" footgun). **300-second replay tolerance window** — Stripe / Svix / Standard Webhooks consensus; SendGrid does not document one but every peer library converges there.
- **D-04: Postmark verification = Basic Auth via `Plug.Crypto.secure_compare/2` + opt-in IP allowlist.** Postmark has no HMAC (per provider docs). Per-tenant Basic Auth credentials are the trust boundary — compared with `Plug.Crypto.secure_compare/2` for timing safety. **IP allowlist is off by default**; when enabled via `config :mailglass, :postmark, ip_allowlist: [cidrs]`, the plug reads `conn.remote_ip` (adopter-configured `Plug.RewriteOn`) and checks membership. Emit `Logger.warning` at `Mailglass.Application.start/2` if allowlist is on but `:trusted_proxies` is unset — Postmark's own docs warn "the origin IP address can change for each attempt," and this makes the opt-in safer than opt-out. The 13 currently-published Postmark webhook IPs are documented in `guides/webhooks.md`, not hardcoded (they can change). Postmark static-IP deprecation is API-only; webhooks are unaffected.
- **D-05: Anymail event taxonomy verbatim (PROJECT D-14) enforced by compile-time Credo check + runtime `:unknown` fallthrough.** `Mailglass.Webhook.Providers.*.normalize/2` pattern-matches each provider's event string literally. Unmapped strings fall through to `:unknown` via `Logger.warning("[mailglass] Unmapped provider event: provider=<p> raw_type=<s>")` — no silent `_ -> :hard_bounce` catch-all. Phase 6 ships a new Credo check `EventTaxonomyIsVerbatim` that lints the provider modules and rejects any catch-all that maps to a non-`:unknown` taxonomy atom (D-23).

### Plug mounting + CachingBodyReader (HOOK-01, HOOK-02)

- **D-06: Router macro as primary DX; naked plug as documented escape hatch.** Matches `Phoenix.LiveDashboard.Router.live_dashboard/2` + `Oban.Web.Router.oban_dashboard/2` idioms verbatim.
  ```elixir
  # router.ex
  import Mailglass.Webhook.Router

  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
    # NO :browser, NO :fetch_session, NO :protect_from_forgery
  end

  scope "/", MyAppWeb do
    pipe_through :mailglass_webhooks
    mailglass_webhook_routes "/webhooks"
  end
  ```
  Generates two `post` routes (`/webhooks/postmark`, `/webhooks/sendgrid`) each forwarding to `Mailglass.Webhook.Plug` with `provider: :postmark | :sendgrid`. Adopters with custom pipelines fall back to naked `plug Mailglass.Webhook.Plug, provider: :postmark` inside their own scope.
- **D-07: Provider-per-path routing, NOT single-dispatcher.** Matches ActionMailbox (`/rails/action_mailbox/postmark/inbound_emails`, `/rails/action_mailbox/sendgrid/inbound_emails`) + django-anymail (`/anymail/sendgrid/tracking/`, `/anymail/postmark/tracking/`). Cleaner telemetry (`provider: :postmark` known at route-init, not parsed from path param); cleaner secret-resolution (one secret per route; no dispatcher-level payload peek).
- **D-08: Shared router-macro vocabulary across Phase 4 + Phase 5.** Lock the convention now so Phase 5 admin router doesn't drift:
  | Phase 4 (this) | Phase 5 (admin) |
  |---|---|
  | `import Mailglass.Webhook.Router` | `import MailglassAdmin.Router` |
  | `mailglass_webhook_routes path, opts` | `mailglass_admin_routes path, opts` |
  | `:as` (default `:mailglass_webhook`) | `:as` (default `:mailglass_admin`) |
  | `:providers` (NimbleOptions-validated list; defaults `[:postmark, :sendgrid]`) | `:on_mount`, `:layout`, `:session_name` |
  Both macros use `defmacro name(path, opts \\ [])` invoked inside an adopter-owned `scope` with adopter-owned `pipe_through` — same shape as LiveDashboard + Oban Web.
- **D-09: `Mailglass.Webhook.CachingBodyReader.read_body/2` with iodata accumulation.**
  ```elixir
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        raw = IO.iodata_to_binary([conn.private[:raw_body] || <<>>, body])
        {:ok, body, Plug.Conn.put_private(conn, :raw_body, raw)}
      {:more, body, conn} ->
        raw = [conn.private[:raw_body] || <<>>, body]
        {:more, body, Plug.Conn.put_private(conn, :raw_body, raw)}
      {:error, reason} -> {:error, reason}
    end
  end
  ```
  Stored in `conn.private[:raw_body]` (library-reserved, off the adopter `assigns` contract — matches lattice_stripe). **Accumulates iodata across `{:more, _, _}` chunks**, flattens on final `{:ok, _, _}` — required for SendGrid batch payloads up to 128 events. `Plug.Parsers` configured with `length: 10_000_000` (10 MB cap; 2 MB over default 8 MB for headroom). Documented footgun: `Plug.Parsers.MULTIPART` does not honor `:body_reader` (Plug issue #884) — irrelevant since providers POST JSON, but surface in `guides/webhooks.md` for adopters adding `:multipart`.
- **D-10: Webhook plug owns ingest end-to-end; NO user handler at the plug layer.** `Mailglass.Webhook.Plug.call/2` does: extract raw_body + headers → `Provider.verify!/3` → `Tenancy.resolve_webhook_tenant/1` (D-12) → `Tenancy.put_current/1` → `Provider.normalize/2` → `Mailglass.Webhook.Ingest.ingest_multi/3` (Ecto.Multi) → `Repo.transact/1` → 200 OK + PubSub broadcast (via Projector.update_projections/2, already Phase 3 D-04). **User handlers subscribe to post-commit PubSub broadcasts** on `Mailglass.PubSub.Topics.events(tenant_id)` or `events(tenant_id, delivery_id)` — the webhook plug is the single library-level ingress, matching CLAUDE.md "webhook plug is the single ingress — no parallel Plug in adopter code." No `:handler` opt accepted by the plug.

### Ingest path + failure lanes (HOOK-04, HOOK-06)

- **D-11: Sync ingest as the v0.1 default.** Verify → normalize → Ecto.Multi → 200 OK, all in the request process. P50 ≈ 15–30 ms, P99 ≈ 150–300 ms — ~30–60× headroom against SendGrid's 10 s / Postmark's 2 min timeouts. Matches Phase 3 D-20 symmetry (`send/2` sync default, `deliver_later/2` explicit opt-in) and reads HOOK-06 literally ("one `Ecto.Multi`"). **No mandatory Oban dep for Phase 4 ingest** — preserves PROJECT D-07. The `:webhook_ingest_mode` config key lands in `Mailglass.Config` with default `:sync`; `:async` is `@moduledoc false` in v0.1 (reserves the knob without shipping the DLQ admin that justifies async). Async rejected as v0.1 default because the Task.Supervisor fallback is **unsafe** for webhook normalization — the provider has already received 200, so in-memory queue loss on a node restart is silent data loss (unrecoverable ledger corruption), contradicting the product thesis.
- **D-12: Tenant resolution via `Mailglass.Tenancy` behaviour callback + batteries-included `ResolveFromPath`.** Extend `Mailglass.Tenancy` with:
  ```elixir
  @optional_callbacks resolve_webhook_tenant: 1
  @callback resolve_webhook_tenant(context :: %{
    provider: atom(),
    conn: Plug.Conn.t(),
    raw_body: binary(),
    headers: [{String.t(), String.t()}],
    path_params: map(),
    verified_payload: map() | nil
  }) :: {:ok, String.t()} | {:error, term()}
  ```
  `SingleTenant.resolve_webhook_tenant/1 → {:ok, "default"}` (zero-config single-tenant DX). Ship `Mailglass.Tenancy.ResolveFromPath` as opt-in sugar for URL-prefix adopters (reads `context.path_params["tenant_id"]`). Multi-tenant adopters implement their own; three patterns documented in `guides/multi-tenancy.md`: **URL prefix** (ResolveFromPath or custom), **verified payload field** (Stripe-Connect style: `context.verified_payload["account"]`), **request header** (Shopify-style: `context.headers["x-shop-domain"]`). Parallels locked Phase 3 D-32 `c:tracking_host/1` and queued v0.5 DELIV-07 `c:adapter_for/1` — one consistent callback convention across the Tenancy behaviour.
- **D-13: Signature verify FIRST, tenant resolve SECOND.** Closes the Stripe-Connect chicken-and-egg trap ("never trust a sub-account ID before the envelope is verified"). Secrets resolved via plug opt `secret: {module, :fn, [args]}` (runtime tuple) or static binary — the webhook path is an INDEX into the adopter's secret table, not a trusted input. Mismatched path/secret combos simply fail signature verification with `%SignatureError{}` (fail-closed). Tenant callback runs AFTER `verify!/3` returns `:ok`; receives `verified_payload: map()` for payload-field strategies, or `nil` before normalization if adopter resolves from path/headers only.
- **D-14: `%Mailglass.TenancyError{}.type` gains `:webhook_tenant_unresolved`.** Extends the Phase 2 closed atom set (currently `:unstamped` only). Rescued by the webhook plug to HTTP 422 (distinct from signature 401, distinct from orphan-delivery 200 with orphan row). Three failure lanes stay separable in admin triage + dashboards.

### Raw payload storage ⚠️ DDL change (HOOK-06 amendment + GDPR)

- **D-15: Split webhook raw payloads into `mailglass_webhook_events` table.** Matches accrue prior-art verbatim. `mailglass_events` remains the append-only pointer ledger (SQLSTATE 45A01 trigger unchanged) — drops the current `raw_payload` column. New table:
  ```sql
  CREATE TABLE mailglass_webhook_events (
    id               UUID PRIMARY KEY,
    tenant_id        TEXT NOT NULL,
    provider         TEXT NOT NULL,                     -- 'postmark' | 'sendgrid'
    provider_event_id TEXT NOT NULL,                    -- provider's event id (used for UNIQUE)
    event_type_raw   TEXT NOT NULL,                     -- provider's string before normalization
    event_type_normalized TEXT,                         -- Anymail taxonomy atom-as-string, NULL until normalized
    status           TEXT NOT NULL,                     -- :received | :processing | :succeeded | :failed | :dead
    raw_payload      JSONB NOT NULL,                    -- mutable, prunable, PII lives here
    received_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    processed_at     TIMESTAMP WITH TIME ZONE,
    inserted_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL
  );
  CREATE UNIQUE INDEX mailglass_webhook_events_provider_event_id_idx
    ON mailglass_webhook_events (provider, provider_event_id);
  CREATE INDEX mailglass_webhook_events_tenant_status_idx
    ON mailglass_webhook_events (tenant_id, status) WHERE status IN ('failed', 'dead');
  ```
  **Idempotency split:** webhook-source idempotency = UNIQUE `(provider, provider_event_id)` on `mailglass_webhook_events`; the event ledger's `idempotency_key` partial UNIQUE index remains intact for non-webhook sources (Phase 3 Fake.trigger_event/3, v0.5 inbound). Ingest Multi: insert `mailglass_webhook_events` first with `status: :processing` (UNIQUE raises = replay no-op via `on_conflict: :nothing`), then insert one or more `mailglass_events` rows (with their own idempotency_key = `"{provider}:{provider_event_id}:{index}"` for batch providers), then Projector.update_projections/2, then flip webhook_events.status to `:succeeded` in the SAME Multi. Append-only ledger stays pristine; raw evidence is a separate mutable artifact; GDPR erasure is a targeted `DELETE FROM mailglass_webhook_events WHERE raw_payload->>'to' = ?`.
  - **Migration plan:** Phase 4 ships `V02` migration via `Mailglass.Migration` (the Oban-pattern dispatcher from Phase 2 P02). DOES NOT amend the shipped V01 — V02 creates `mailglass_webhook_events`, drops `mailglass_events.raw_payload` (the column is nullable and unused in v0.1 shipped code; safe drop). Immutability trigger is non-column-aware, so dropping a column via ALTER TABLE is an operator action not covered by the UPDATE/DELETE-on-row trigger — migration runs clean.
- **D-16: `Mailglass.Webhook.Pruner` Oban cron + retention config.** Daily cron, deletes `mailglass_webhook_events` rows based on `status` + age:
  ```elixir
  config :mailglass, :webhook_retention,
    succeeded_days: 14,           # :infinity to disable
    dead_days: 90,                # :infinity to disable
    failed_days: :infinity        # dead is the terminal-after-retries state; failed can be investigated
  ```
  `mix mailglass.webhooks.prune --status :succeeded --older-than-days 7` as manual-trigger sibling. Behind OptionalDeps.Oban gateway; absent-Oban degradation = `Logger.warning` at boot + adopter runs the mix task in their own cron.

### Orphan reconciliation (HOOK-06 orphan clause, TEST-03)

- **D-17: `Mailglass.Webhook.Reconciler` Oban cron `*/5 * * * *` in Phase 4.** Ship the worker — do not defer. Phase 5 admin is dev-only and doesn't render real-provider orphans, but v0.5 prod admin absolutely will, and deferring the worker forces v0.5 to ship manual-reconcile UX that `*/5` cron makes unnecessary. Match accrue's shipped pattern verbatim (`/Users/jon/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex`): `use Oban.Worker, queue: :mailglass_reconcile`, 60-second age threshold (grace window for worker commit), 1000 rows per tick, 7-day max-age cutoff (already in shipped `find_orphans/1`). The previously-noted `*/15` preference in Phase 2 STATE note line 133 is unlocked and changed to `*/5` — SendGrid p99 is 1.3 s, Postmark similar, so 60 s grace with a 5-minute sweep is ~100× safety margin without meaningful DB churn.
- **D-18: Immutability-safe reconciliation via append, not UPDATE.** The Phase 2 shipped `Events.Reconciler.attempt_link/2` returns `{:ok, {delivery, event}}` without mutating either row (verified in `lib/mailglass/events/reconciler.ex:107-133`). The ARCHITECTURE.md §4 DDL comment "nullable: orphan webhooks before reconcile" is misleading and should read "nullable: orphan webhooks forever; linkage expressed by appending a `:reconciled` event, not by back-filling the original." **Worker flow:**
  1. `find_orphans/1` → list of orphan events older than 60 s, newer than 7 d.
  2. For each candidate, `attempt_link/2` → `{:matched, delivery, event}` or `{:no_match, event}`.
  3. Matched path, inside `Repo.transact/1`:
     - `Events.append_multi/3` inserts a NEW event with `type: :reconciled`, `delivery_id: matched_delivery.id`, `metadata: %{reconciled_from_event_id: orphan_event.id, reconciled_provider: orphan.provider, reconciled_provider_event_id: orphan.provider_event_id}`, `idempotency_key: "reconciled:#{orphan_event.id}"`.
     - `Projector.update_projections/2` on the matched Delivery — applies the orphan's `last_event_type` / `last_event_at` / terminal flags now that the link exists, triggering the Phase 3 D-04 PubSub broadcast.
  4. No-match path: leave the orphan row untouched. The `needs_reconciliation = true` partial index keeps it cheap to re-scan next tick.
  Original orphan event rows stay untouched with `delivery_id = nil` forever — the `:reconciled` event IS the linkage audit record. No trigger carve-out. Append-only preserved structurally, not by policy.
- **D-19: Permanent-orphan terminal state = do nothing.** After 7 d, `find_orphans/1`'s existing cutoff filters them out of the reconciler scan. The rows persist in the ledger (audit value), stop consuming steady-state query load (index filter), and admin LiveView renders "older than 7 days — unlikely to reconcile, dismiss?" as UI hint. **"Dismiss" is LiveView state only, not a DB UPDATE** (preserves D-15 invariant). Alternatives (flip to `:permanently_orphaned` = UPDATE, violates D-15; archive table = premature; append "permanent orphan" event = wastes a row for zero new signal) all lose to "just let them sit."
- **D-20: Oban-optional degradation = Logger.warning + mix task, NOT Task.Supervisor cron.** Follow Phase 3 D-17 pattern: `:persistent_term`-gated single `Logger.warning` at `Mailglass.Application.start/2`:
  ```
  [mailglass] Orphan reconciliation requires :oban; orphan events will accumulate until
  you either run `mix mailglass.reconcile --tenant-id X --max-age-minutes N` manually
  or add {:oban, "~> 2.19"} to your deps.
  ```
  Ship `Mix.Tasks.Mailglass.Reconcile` (arg: `--tenant-id`, `--max-age-minutes`, `--batch-size`). **No Task.Supervisor periodic loop** — the Phase 3 `Task.Supervisor` fallback at `lib/mailglass/outbound.ex:407` is for one-shot async delivery, not cron; hand-rolled scheduling has no crash recovery, no backoff, no telemetry integration, and competes with adopters' eventual Oban. Senior-Phoenix-dev persona almost always has Oban.

### Error + telemetry surface (OBS-01, OBS-02, OBS-05, HOOK-04)

- **D-21: `%Mailglass.SignatureError{}.type` closed atom set.** Seven values:
  ```elixir
  @types [
    :missing_header,        # Authorization / X-Twilio-* absent
    :malformed_header,      # header present but unparseable (bad Base64, missing "Basic " prefix)
    :bad_credentials,       # Postmark Basic Auth mismatch (secure_compare returns false)
    :ip_disallowed,         # Postmark IP allowlist (opt-in) mismatch
    :bad_signature,         # ECDSA / HMAC math returned false; COLLAPSES :tampered_body
    :timestamp_skew,        # SendGrid timestamp outside 300s tolerance
    :malformed_key          # PEM/DER decode failure at config validate-at-boot time
  ]
  ```
  `:tampered_body` deliberately excluded — ECDSA cannot distinguish tampered body from wrong key, so collapsing into `:bad_signature` accurately reflects what the math can tell you. `:secret_not_configured` = `%Mailglass.ConfigError{type: :webhook_verification_key_missing}`, NOT `%SignatureError{}` — separation preserves the type contract (accrue's `plug.ex:96` muddles this; mailglass does not). **Field name stays `:type`** (consistent with Phase 1 Mailglass.Error hierarchy — all 7 error structs use `:type + :message + :context`; a one-struct deviation to `:reason` for lattice_stripe alignment is rejected because the "naming collision with `event.type`" it would resolve is addressable in variable scope, not struct-field naming). Documented in `docs/api_stability.md` alongside Phase 1–3 atom sets.
- **D-22: Telemetry event catalog.** Five events covering the webhook ingest surface:
  - **Outer span** `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` — wraps plug entry → Multi commit. Stop metadata: `%{provider, tenant_id, status: :ok | :signature_failed | :config_error | :tenant_unresolved | :normalize_failed | :duplicate, event_count, delivery_id_matched :: boolean, duplicate :: boolean}`.
  - **Inner span** `[:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]` — wraps `Provider.verify!/3` only. Matches lattice_stripe's `[:lattice_stripe, :webhook, :verify, :*]` exactly. Stop metadata: `%{provider, status: :ok | :failed, failure_reason :: atom | nil}`.
  - **Single-emit** `[:mailglass, :webhook, :normalize, :stop]` — fires once per event inside batch payloads. Metadata: `%{provider, event_type :: atom | :unknown, mapped :: boolean}`. Alertable on sustained `mapped: false` rate.
  - **Single-emit** `[:mailglass, :webhook, :orphan, :stop]` — fires when normalized event has no matching Delivery. Metadata: `%{provider, event_type, tenant_id, age_seconds :: non_neg_integer | nil}` (age computed from provider timestamp when available).
  - **Single-emit** `[:mailglass, :webhook, :duplicate, :stop]` — idempotency-key collision. Metadata: `%{provider, event_type}`. Lets adopters distinguish Postmark retry storms from real traffic cheaply.
  - Additionally: `[:mailglass, :webhook, :reconcile, :start | :stop | :exception]` full span per reconciler run (D-17). Stop metadata: `%{tenant_id, scanned_count, linked_count, remaining_orphan_count}`.
- **D-23: Telemetry metadata whitelist (LINT-02 `NoPiiInTelemetryMeta` compliant).** Whitelist:
  ```
  %{provider, tenant_id, event_type, status, failure_reason, mapped, duplicate,
    delivery_id_matched, event_count, age_seconds, scanned_count, linked_count,
    remaining_orphan_count, delivery_id}
  ```
  All atoms, booleans, non-neg integers, or opaque tenant/delivery IDs. **Explicitly excluded**: `:ip` (high-cardinality, GDPR-ambiguous), `:user_agent`, any header value, `:raw_body_size`, recipient / subject / body / headers content. IP for abuse investigation is adopter-extensible — they attach their own handler on `[:mailglass, :webhook, :signature, :verify, :stop]` with `status: :failed` and pull `conn.remote_ip` from their own plug lineage. Documented in `guides/webhooks.md`.
- **D-24: Signature-failure Logger audit.** `Logger.warning("Webhook signature failed: provider=#{provider} reason=#{reason}")` — reason atom only. No IP, no header values, no payload excerpt. Matches accrue's `webhook/plug.ex:49` pattern verbatim. Per-request replay of Logger.warnings (retry storms → log DoS) mitigated by the duplicate-detection telemetry: adopters build Grafana alerts on the `:duplicate :stop` single-emit rate rather than log-scraping.

### Auto-suppression DEFERRED to v0.5 DELIV-02

- **D-25: Phase 4 writes Event rows ONLY. No suppression side effects inside the ingest Multi.** Honors the Phase 3 `03-CONTEXT.md` deferred-list entry (`"auto-suppression on bounce/complaint"` → v0.5 DELIV-02). Re-opening that lock for a 3-lines-per-event change creates a v0.5 migration nightmare: the hard-bounce classifier per provider (Postmark TypeCode 1 vs SendGrid `event="bounce" + type="bounce"` excluding "blocked"), `:address` vs `:address_stream` scoping for unsubscribes, collision behavior with existing manual suppressions carrying `source: "admin:..."`, stream-scope for orphans that have no Delivery to read stream-id from — all of it needs to be designed together in v0.5, not split across Phase 4 and v0.5 with subtle drift. **Adopters wanting auto-suppression now** attach a telemetry handler on `[:mailglass, :webhook, :normalize, :stop]` → call `Mailglass.Suppressions.add/3` per event with their own classification logic. One-page recipe in `guides/webhooks.md` §Auto-suppression via telemetry.

### Testability + forward-references

- **D-26: `Mailglass.WebhookCase` helpers.** Extend the Phase 3 `WebhookCase` stub with:
  - `mailglass_webhook_conn(provider, payload, opts \\ [])` — builds `Plug.Test.conn(:post, "/webhooks/#{provider}", payload)`, attaches computed signature headers (SendGrid ECDSA via test signing key; Postmark Basic Auth via test credentials), puts JSON content-type, runs full pipeline through CachingBodyReader + `Mailglass.Webhook.Plug`. Returns final `%Plug.Conn{}`.
  - `assert_webhook_ingested(pattern_or_fn, timeout \\ 100)` — sugar for `Phoenix.PubSub.subscribe` + `assert_receive` on the post-commit broadcast. Matches pattern: `%{type: :delivered, provider: :sendgrid}` or predicate `fn msg -> msg.tenant_id == "t1" end`.
  - `stub_postmark_fixture/1` + `stub_sendgrid_fixture/1` — load + re-sign real-provider fixture payloads from `test/support/fixtures/webhooks/{provider}/*.json`.
  - `freeze_timestamp/1` — inherits Phase 3 D-07 Clock.Frozen; required for SendGrid ECDSA timestamp-skew tests.
- **D-27: StreamData property tests (TEST-03, HOOK-07).** Three property generators:
  - Generate `(webhook_event, replay_count ∈ 1..10)` sequences of length 100, replay each sequence 10 times → total 1000 scenarios. Assert converged state equals single-application state (HOOK-07 verbatim).
  - Generate `(provider, signature_failure_mode)` pairs → assert exactly one of the seven `SignatureError.type` atoms is raised, with no partial DB writes.
  - Generate `(tenant_resolution_strategy, webhook_payload)` → assert tenant_id on persisted event equals expected resolution, `:webhook_tenant_unresolved` error raised cleanly on bad strategy.
- **D-28: Compile-time Credo forward-references (Phase 6 LINT).** New check name: `EventTaxonomyIsVerbatim` — lints `lib/mailglass/webhook/providers/*.ex` and rejects catch-all clauses that map to non-`:unknown` taxonomy atoms. Companion to LINT-02 (`NoPiiInTelemetryMeta`), LINT-06 (`PrefixedPubSubTopics`), LINT-12 (`NoDirectDateTimeNow`). Phase 4 ships compliant code; Phase 6 ships the check.
- **D-29: `statement_timeout` + `lock_timeout` on webhook process.** Wrap the Ecto.Multi in `Repo.transact/1` with Postgres `SET LOCAL statement_timeout = '2s'; SET LOCAL lock_timeout = '500ms';` to prevent provider-retry-storm feedback loops from compounding DB pressure. Documented runbook entry in `guides/webhooks.md` describing the symptom (sustained 5xx under load → provider retry amplification → more DB pressure) and the v0.5 async escape hatch.

### Claude's Discretion

- Exact wording of provider-verifier moduledocs (`Postmark` vs `SendGrid`) following brand voice.
- Exact NimbleOptions schema keys for `:postmark` and `:sendgrid` config subtrees (`secret`, `public_key`, `basic_auth: {user, pass}`, `ip_allowlist`, `timestamp_tolerance_seconds`).
- Exact `Mailglass.Webhook.Router` macro internal shape (NimbleOptions validation of `:providers`, `:as` default).
- Exact Oban queue concurrency for `:mailglass_reconcile` (recommend `concurrency: 1` per node — reconciliation is not throughput-sensitive).
- Exact test fixture format + file layout under `test/support/fixtures/webhooks/`.
- Exact `Mix.Tasks.Mailglass.Reconcile` + `Mix.Tasks.Mailglass.Webhooks.Prune` arg parsing via `OptionParser`.
- Exact `guides/webhooks.md` outline (install + verify + multi-tenant + telemetry + auto-suppression recipe + async escape-hatch note).
- `Mailglass.Webhook.Ingest.ingest_multi/3` internal Multi step ordering (webhook_events insert first, then events, then projector — but exact step names for telemetry readability).
- Whether `mailglass_webhook_events.id` is UUIDv7 (consistent with Phase 1 project-wide) — default YES.
- Whether `received_at` is `Mailglass.Clock.utc_now/0` or the provider-asserted timestamp (recommend BOTH: `received_at` = clock, `provider_timestamp` = parsed from payload if present).

### Folded Todos

None — no pending todos matched Phase 4.

</decisions>

<spec_lock>
## Cross-cutting: REQ Amendments + Project-level Amendments (planner owns)

- **PROJECT D-14 amendment.** Current: *"Anymail event taxonomy verbatim for normalized webhook events."* Amend to: *"Anymail event taxonomy verbatim for provider-sourced webhook events; mailglass reserves one additional lifecycle event `:reconciled` for linking orphan webhooks to their late-committing Delivery rows (see Phase 4 D-18). The `:reconciled` event carries `metadata.reconciled_from_event_id` and is emitted only by `Mailglass.Webhook.Reconciler`, never by provider mappers."* Rationale: preserves the ledger as the single source of truth for "what happened" — losing the reconciliation moment from the audit trail costs more debuggability than the strictness of "verbatim" buys.
- **HOOK-06 amendment.** Current: *"Webhook ingest is one `Ecto.Multi`: insert Event row (with `idempotency_key`) `on_conflict: :nothing` + update Delivery projection columns + broadcast via `PubSub` to admin LiveView topic."* Amend to: *"Webhook ingest is one `Ecto.Multi`: insert `mailglass_webhook_events` row with UNIQUE `(provider, provider_event_id)` `on_conflict: :nothing` (idempotency key); normalize to one or more `mailglass_events` rows with idempotency_key `"{provider}:{provider_event_id}:{index}"`; update `mailglass_deliveries` projection columns via `Projector.update_projections/2`; broadcast via `Phoenix.PubSub` post-commit (Phase 3 D-04). Orphan webhooks (no matching `delivery_id`) insert the `mailglass_events` row with `delivery_id: nil + needs_reconciliation: true` and are linked later by `Mailglass.Webhook.Reconciler` (Phase 4 D-17/D-18)."* Reflects D-15 separate-table split + D-18 append-based reconciliation.
- **Phase 2 shipped DDL amendment (V02 migration).** Phase 4 ships `Mailglass.Migrations.Postgres.V02` which (a) creates `mailglass_webhook_events` table + indexes (D-15), (b) drops `mailglass_events.raw_payload` column (unused in shipped v0.1 code). V01 is NOT amended — it stays as the authoritative "first ever" migration for existing mailglass installs; V02 is the Phase-4 evolution.
- **`Mailglass.Tenancy` behaviour extension.** Add `@optional_callbacks resolve_webhook_tenant: 1` + callback spec (D-12). `SingleTenant` gains a `resolve_webhook_tenant/1 → {:ok, "default"}` default impl. New module `Mailglass.Tenancy.ResolveFromPath` ships as opt-in sugar. Documented in `docs/api_stability.md` as an additive, optional-callback extension (no breaking change for Phase 2 adopters).
- **`Mailglass.TenancyError` + `Mailglass.ConfigError` + `Mailglass.SignatureError` `:type` atom-set extensions.** `%TenancyError{}` gains `:webhook_tenant_unresolved` (D-14). `%ConfigError{}` gains `:webhook_verification_key_missing` (D-21 exclusion rationale). `%SignatureError{}` atom set expands from the shipped single-placeholder to the seven enumerated in D-21. All three documented in `docs/api_stability.md`.

</spec_lock>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project locked context

- `.planning/PROJECT.md` — Key Decisions D-01..D-20 (project-level, locked). Most load-bearing for Phase 4: **D-07** (Oban optional — gates D-17/D-20), **D-08** (tracking off by default — unrelated to ingest but informs shared telemetry whitelist discipline), **D-09** (multi-tenancy first-class — drives D-12/D-13/D-14), **D-10** (Postmark + SendGrid only at v0.1 — gates D-01 sealed behaviour), **D-14** (Anymail taxonomy verbatim — AMENDED by Phase 4 D-18 to add internal `:reconciled` event), **D-15** (append-only event ledger — drives D-15 table-split + D-18 append-based reconciliation), **D-17** (custom Credo checks — forward-refs D-23 `EventTaxonomyIsVerbatim`), **D-20** (domain vocabulary — Event is irreducible, no renaming).
- `.planning/REQUIREMENTS.md` — §Webhook Ingest HOOK-01..HOOK-07, §Test Tooling TEST-03. HOOK-06 amendment + PROJECT D-14 amendment are load-bearing — see spec_lock above.
- `.planning/ROADMAP.md` — Phase 4 success criteria (5 checks); depends on Phases 2 + 3; pitfalls guarded against: MAIL-03 (idempotency), MAIL-08 (no silent taxonomy catch-all), HOOK-04 (200 on replay + 401 on real mismatch), OBS-02 (telemetry no raw payload), OBS-05 (signature failure log no payload leak).
- `.planning/STATE.md` — Phase 3 complete 2026-04-23; Phase 4 ready to plan. Note line 133 (`*/15` preference) is unlocked and downgraded to `*/5` per D-17.

### Phase 1 + Phase 2 + Phase 3 artifacts Phase 4 consumes

- `.planning/phases/01-foundation/01-CONTEXT.md` — Phase 1 D-01..D-33. Most load-bearing: **D-01..D-09** (Error struct shapes — `%SignatureError{}` + `%ConfigError{}` + `%TenancyError{}` extended by Phase 4 per D-21/D-14), **D-26..D-32** (Telemetry 4-level convention — Phase 4 D-22 ships `[:mailglass, :webhook, :*]` events whose metadata must comply with D-31's closed whitelist plus the D-23 Phase-4 extensions).
- `.planning/phases/02-persistence-tenancy/02-CONTEXT.md` — Phase 2 D-01..D-43. Most load-bearing: **D-01/D-02** (`Events.append/1` + `append_multi/3` are the ONLY writers consumed by the ingest Multi + reconciler + Fake.trigger_event/3), **D-13..D-18** (Delivery projection via Projector — Phase 4 D-10 consumes), **D-19** (`Events.Reconciler.find_orphans/1` + `attempt_link/2` — Phase 4 D-17/D-18 ship the worker that runs them), **D-29..D-34** (Tenancy behaviour — Phase 4 D-12 extends with `resolve_webhook_tenant/1`).
- `.planning/phases/03-transport-send-pipeline/03-CONTEXT.md` — Phase 3 D-01..D-39. Most load-bearing: **D-03/D-04** (Fake.trigger_event/3 uses Projector.update_projections + PubSub broadcast — the same write path webhook ingest uses; this is why "Fake proves the production write path" is structural not aspirational), **D-17** (Oban-optional boot-warning pattern — Phase 4 D-20 mirrors for the Reconciler), **D-18** (preflight `Tenancy.assert_stamped!/0` precondition — Phase 4 ingest does the same stamping via D-12 callback), **D-20** (sync send default with two-Multis-separated-by-adapter-call — Phase 4 D-11 sync default is the symmetric analog), **D-26** (telemetry granularity principle — Phase 4 D-22 applies same principle to webhook spans), deferred list entry ("auto-suppression on bounce/complaint" → v0.5 DELIV-02, reaffirmed by Phase 4 D-25).

### Existing code artifacts Phase 4 extends or consumes

- `lib/mailglass/idempotency_key.ex` — `IdempotencyKey.for_webhook_event(provider, event_id)` returns `"provider:event_id"`. Phase 4 uses the amended form `"provider:event_id:index"` for SendGrid batch events where index distinguishes per-event-within-payload.
- `lib/mailglass/events.ex` + `lib/mailglass/events/event.ex` + `lib/mailglass/events/reconciler.ex` — Phase 2 shipped. Phase 4 consumes `append_multi/3` in every write path, consumes `Reconciler.find_orphans/1` + `Reconciler.attempt_link/2` in the cron worker.
- `lib/mailglass/outbound/projector.ex` — Phase 2 shipped + Phase 3 extended with PubSub broadcast (D-04). Phase 4 D-10 + D-18 consume — no further extension needed.
- `lib/mailglass/tenancy.ex` + `lib/mailglass/tenancy/single_tenant.ex` — Phase 2 shipped. Phase 4 D-12 extends with `resolve_webhook_tenant/1` optional callback + `ResolveFromPath` module.
- `lib/mailglass/errors/signature_error.ex` (if sit/stub exists from Phase 1) + `tenancy_error.ex` + `config_error.ex` — Phase 4 D-21 + D-14 extend closed atom sets.
- `lib/mailglass/repo.ex` — `transact/1` with SQLSTATE 45A01 translation. Every Phase 4 ingest + reconciler write flows through it.
- `lib/mailglass/migration.ex` + `lib/mailglass/migrations/postgres/v01.ex` — Phase 4 adds `lib/mailglass/migrations/postgres/v02.ex` (D-15 migration plan).
- `lib/mailglass/optional_deps/oban.ex` — `Oban.TenancyMiddleware` (Phase 2 shipped). Phase 4 D-20 Reconciler + D-16 Pruner both use it.
- `lib/mailglass/clock.ex` — Phase 1 shipped; D-03 SendGrid timestamp-tolerance math uses `Mailglass.Clock.utc_now/0`.
- `lib/mailglass/pub_sub/topics.ex` + `lib/mailglass/pub_sub.ex` — Phase 3 shipped. Phase 4 broadcasts via existing `events(tenant_id)` + `events(tenant_id, delivery_id)` topics through Projector (no new topics).
- `lib/mailglass/config.ex` — NimbleOptions schema extends additively with `:postmark`, `:sendgrid`, `:webhook_retention`, `:webhook_ingest_mode`.
- `docs/api_stability.md` — Phase 4 extends §Error types, §Tenancy behaviour, §Telemetry catalog.

### Research + architecture synthesis

- `.planning/research/SUMMARY.md` — §"Phase 4: Webhook Ingest," §Research Flags row Q4 (`CachingBodyReader + Plug 1.18`, `SendGrid ECDSA on OTP 27`, `orphan reconciliation cadence`) — Phase 4 resolves all three: Plug 1.18 body-reader contract stable since Plug 1.5.1, PR #698, no subtle breakage (D-09); ECDSA via `:public_key.der_decode/2` not `pem_decode/1` (D-03); `*/5` cron + 60s age threshold + accrue-verbatim pattern (D-17).
- `.planning/research/ARCHITECTURE.md` §2.2 (webhook ingest cold path — the canonical sequence diagram; Phase 4 D-10 + D-15 implement this with the DDL-split amendment), §2.3 (race-condition table — confirms the orphan race is real on both Postmark + SendGrid), §4 (DDL — Phase 4 D-15 AMENDS by moving raw_payload out of `mailglass_events`), §5 (behaviour boundaries — `Mailglass.Webhook` sub-boundary lands this phase with deps `[Mailglass, Repo, Events, Projector, Tenancy, Renderer-not, Telemetry, Config, PubSub]`), §6 Layer 5 (build order — this is Layer 5), §7 (boundary blocks — `Mailglass.Webhook` + sub-boundaries `Mailglass.Webhook.Providers.*`, `Mailglass.Webhook.Router`, `Mailglass.Webhook.Ingest`, `Mailglass.Webhook.Reconciler`, `Mailglass.Webhook.Pruner`).
- `.planning/research/PITFALLS.md` — **MAIL-03** (idempotency end-to-end — UNIQUE split per D-15), **MAIL-08** (Anymail taxonomy verbatim + `Logger.warning` fallthrough, no silent `_ -> :hard_bounce` — D-05 + D-23), **MAIL-09** (provider_message_id UNIQUE — enforced via `mailglass_webhook_events(provider, provider_event_id)` per D-15), **HOOK-04** (200 on replay + 401 on mismatch — D-10 plug response table), **OBS-01** (telemetry no PII — D-23 whitelist), **OBS-02** (webhook telemetry never logs raw payload — D-24), **OBS-05** (signature failure logs no payload leak — D-24), PITFALLS.md table rows around Postmark Basic Auth + IP (D-04), SendGrid ECDSA (D-03), Mailgun timestamp tolerance (forward-ref v0.5), Svix/Standard-Webhooks 300s consensus (D-03).
- `.planning/research/STACK.md` — no new required deps (Plug already required; `:crypto` + `:public_key` are OTP stdlib; Oban already optional). Phase 4 does NOT add Plug.Crypto (already transitive via Phoenix + Plug).
- `.planning/research/FEATURES.md` — TS-11 (webhook event normalization to Anymail taxonomy), DF-09 (CachingBodyReader for raw-body preservation), DF-12 (orphan reconciliation worker shape).

### Engineering DNA + domain language

- `prompts/mailglass-engineering-dna-from-prior-libs.md` §2.4 (Errors as public API contract — D-21 atom set), §2.5 (Telemetry 4-level — D-22), §4.5 (webhook ingest pattern, reference: `~/projects/lattice_stripe/lib/lattice_stripe/webhook/`), §6.5 (signature-failure raises with no recovery — D-10 plug response + D-24 Logger policy).
- `prompts/mailer-domain-language-deep-research.md` §13 (canonical vocabulary — Event is irreducible), §16 (status as projection — drives the "reconciled event, not UPDATE" pattern of D-18).
- `prompts/Phoenix needs an email framework not another mailer.md` §webhook taxonomy (drives D-05 Anymail verbatim + D-23 Credo enforcement).

### Brand + ecosystem

- `prompts/mailglass-brand-book.md` — voice applied to every error message in this phase. Examples: `"Webhook signature failed: provider=postmark reason=bad_credentials"` (D-24), `"Webhook tenant resolution failed: no tenant matches for Postmark ServerID 12345"` (D-14), `"Mailglass webhook verification key missing: configure :webhook_verification_key in your :mailglass config"` (D-21 exclusion). Never "Oops!".

### Reference implementations (sibling-constraint + prior-art)

- **`~/projects/lattice_stripe/lib/lattice_stripe/webhook/plug.ex`** — plug-level signature verification + NimbleOptions schema + path-matching `call/2` pattern. D-06 + D-10 port this shape.
- **`~/projects/lattice_stripe/lib/lattice_stripe/webhook/cache_body_reader.ex`** — the ancestral CachingBodyReader shape. D-09 upgrades with iodata accumulation across chunks for SendGrid batch payloads.
- **`~/projects/lattice_stripe/lib/lattice_stripe/webhook/signature_verification_error.ex`** — closed atom set (`:missing_header | :invalid_header | :no_matching_signature | :timestamp_expired`). D-21 ports the pattern but (a) keeps field name `:type` not `:reason` (mailglass hierarchy consistency), (b) expands atom set to 7 for Postmark + SendGrid coverage.
- **`~/projects/lattice_stripe/lib/lattice_stripe/telemetry.ex:143-161`** — `[:lattice_stripe, :webhook, :verify, :stop]` span with `%{result: :ok | :error, error_reason: atom | nil}` metadata — D-22 inner span directly mirrors.
- **`~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex`** — `construct_event/4` single-function verifier. D-01 splits into verify + normalize for cleaner taxonomy-mapping isolation.
- **`~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex`** — Oban cron reconciler with 60s grace + 1000 rows/tick. D-17 ports verbatim with webhook-specific orphan-match logic.
- **`~/projects/accrue/accrue/lib/accrue/webhook/plug.ex`** — `[:accrue, :webhook, :receive]` span + `Logger.warning("Webhook signature verification failed: #{e.reason}")` no-PII pattern. D-22 + D-24 mirror.
- **`~/projects/accrue/accrue/lib/accrue/webhook/webhook_event.ex`** — mutable webhook-events schema with `raw_body, redact: true` (for `Inspect` safety). D-15 ports the schema shape (`redact: true` on `:raw_payload` field to protect `IO.inspect` output).
- **`~/projects/accrue/accrue/lib/accrue/webhook/ingest.ex`** — transactional dual-write pattern (webhook_event + Oban job + ledger entry in one Ecto.Multi). D-15 + D-10 port the shape; mailglass doesn't need the Oban job since ingest is sync (D-11).
- **`~/projects/accrue/accrue/lib/accrue/webhook/pruner.ex`** — Oban cron Pruner. D-16 ports verbatim.
- **`~/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs`** — the migration shape D-15 follows.
- **`~/projects/accrue/accrue/lib/accrue/config.ex:133-147`** — retention config keys + NimbleOptions schema. D-16 ports.
- **`~/projects/accrue/accrue/lib/accrue/webhooks/dlq.ex:206-236`** — `prune/1` + `prune_succeeded/1` with `:infinity` bypass. D-16 ports.
- **`~/projects/sigra/lib/sigra/admin/router.ex`** — router-macro shape. D-08 shared-vocabulary table mirrors — Phase 5 admin router will align.
- **`~/projects/sigra/priv/templates/sigra.install/admin/router_injection.ex`** — sigra uses installer-injected routes rather than a router macro. Noted as an alternative for Phase 7 installer; Phase 4 still ships the router macro per D-06 because it stabilizes the vocabulary for Phase 5 admin.
- **Rails ActionMailbox ingresses** (`rails/actionmailbox/app/controllers/action_mailbox/ingresses/postmark/inbound_emails_controller.rb`, `sendgrid/inbound_emails_controller.rb`) — provider-per-path convention + HTTP Basic Auth for Postmark. D-07 + D-04 precedent.
- **django-anymail** (`anymail/webhooks/sendgrid.py`, `anymail/webhooks/postmark.py`, `anymail/webhooks/base.py`) — `validate_request` + `parse_events` two-callback split + reject_reason taxonomy. D-01 + D-05 precedent; confirms the two-callback pattern is the multi-language norm for this domain.
- **stripity_stripe `Stripe.WebhookPlug`** — plug-as-behaviour with handler configuration. Rejected as Phase 4 shape because (a) mailglass has no user handler at this layer per D-10, (b) stripity_stripe does NOT ship a CachingBodyReader (leaves it to adopter) — mailglass does, so the DX story is materially better.
- **Phoenix LiveDashboard** (`Phoenix.LiveDashboard.Router.live_dashboard/2`) + **Oban Web** (`Oban.Web.Router.oban_dashboard/2`) — router-macro precedent D-06 + D-08 port verbatim shape.
- **Svix / Standard Webhooks** — 300s timestamp tolerance + raw body signing consensus. D-03 aligns.

### External standards + provider docs

- **[Postmark Webhooks Overview](https://postmarkapp.com/developer/webhooks/webhooks-overview)** — Basic Auth (no HMAC) + IP can change per attempt. D-04.
- **[Postmark Bounce Webhook](https://postmarkapp.com/developer/webhooks/bounce-webhook)** — TypeCode 1 = HardBounce (v0.5 auto-suppression reference, not Phase 4 scope).
- **[Postmark IPs for Firewalls](https://postmarkapp.com/support/article/800-ips-for-firewalls)** — 13 published webhook IPs as of research date. D-04 documents but does NOT hardcode.
- **[SendGrid Event Webhook Security Features](https://www.twilio.com/docs/sendgrid/for-developers/tracking-events/getting-started-event-webhook-security-features)** — ECDSA via `X-Twilio-Email-Event-Webhook-Signature` + timestamp header; signed payload = `timestamp + raw_body`. D-03.
- **[Erlang public_key module docs (OTP 27)](https://www.erlang.org/docs/27/apps/public_key/public_key)** — `:public_key.der_decode/2` + `:public_key.verify/4` API. D-03.
- **[Zenn: Erlang/Elixir SendGrid signature verification](https://zenn.dev/siiibo_tech/articles/erlang-elixir-sendgrid-signature-verify-20230812)** (Japanese) — concrete DER-not-PEM pattern walkthrough. D-03 validates.
- **[Anymail "Securing Webhooks"](https://anymail.dev/en/stable/tips/securing_webhooks/)** — cross-language reference for webhook security posture. D-04 + D-11.
- **[Plug PR #698](https://github.com/elixir-plug/plug/pull/698)** — `:body_reader` custom option. Stable since Plug 1.5.1. D-09.
- **[Plug issue #884](https://github.com/elixir-plug/plug/issues/884)** — `Plug.Parsers.MULTIPART` does not use `body_reader`. D-09 documented footgun.
- **[Mailgun Securing Webhooks](https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks)** — v0.5 forward-compat (HMAC-SHA256 over `timestamp + token`).
- **[AWS SNS Verifying Signatures](https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html)** — v0.5 forward-compat (SubscribeURL GET on SubscriptionConfirmation).
- **[Resend Verify Webhook Requests](https://resend.com/docs/dashboard/webhooks/verify-webhooks-requests)** — v0.5 forward-compat (Svix-based signing; fits D-01 shape).
- **[Stripe: Receive events in your webhook endpoint](https://docs.stripe.com/webhooks)** — 30s timeout + async recommendation pattern. D-11 notes — mailglass stays sync for bounded normalization.
- **[Svix: Webhook Timeout Best Practices](https://www.svix.com/resources/webhook-university/reliability/webhook-timeout-best-practices/)** — industry consensus on response budgets. D-11 latency math.
- **[Shopify Webhooks HTTPS Delivery](https://shopify.dev/docs/apps/build/webhooks/subscribe/https)** — `X-Shopify-Shop-Domain` header + per-shop HMAC secret lookup. D-12 multi-tenant guide pattern.
- **[Stripe Connect webhooks](https://docs.stripe.com/connect/webhooks)** — `event.account` field post-verify + one platform-wide signing secret. D-12 payload-field pattern.
- **[Mainmatter: Handling Webhooks in Phoenix](https://mainmatter.com/blog/2018/02/14/handling-webhooks-in-phoenix/)** — Elixir-community CachingBodyReader pattern. D-09 precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (shipped through Phases 1–3)

- **`Mailglass.IdempotencyKey.for_webhook_event/2`** (`lib/mailglass/idempotency_key.ex`) — Phase 1 shipped. Phase 4 extends usage to per-event-within-batch form: `"#{provider}:#{provider_event_id}:#{index}"` for SendGrid batches.
- **`Mailglass.Events.append_multi/3` + `Events.append/1`** (`lib/mailglass/events.ex`) — Phase 2 shipped. The SINGLE writer path into `mailglass_events` — Phase 4 ingest Multi + Reconciler both consume. Never parallel-path.
- **`Mailglass.Events.Reconciler.find_orphans/1` + `Events.Reconciler.attempt_link/2`** (`lib/mailglass/events/reconciler.ex`) — Phase 2 shipped as pure-query helpers. Phase 4 D-17 ships the Oban worker that drives them.
- **`Mailglass.Outbound.Projector.update_projections/2`** (`lib/mailglass/outbound/projector.ex`) — Phase 2 + Phase 3 D-04 shipped (extended with post-commit PubSub broadcast). Phase 4 D-10 ingest Multi + D-18 reconciler consume it identically — one single writer for Delivery projections, admin LiveView sees updates for free.
- **`Mailglass.Repo.transact/1`** (`lib/mailglass/repo.ex`) — Phase 2 shipped with SQLSTATE 45A01 translation. Every Phase 4 Multi flows through it.
- **`Mailglass.Tenancy`** + `Mailglass.Tenancy.SingleTenant` + `Mailglass.Oban.TenancyMiddleware` (`lib/mailglass/tenancy.ex`, `lib/mailglass/tenancy/single_tenant.ex`, `lib/mailglass/optional_deps/oban.ex`) — Phase 2 shipped. Phase 4 D-12 adds `resolve_webhook_tenant/1` optional callback + `Mailglass.Tenancy.ResolveFromPath` sugar module.
- **`Mailglass.Clock.utc_now/0`** (`lib/mailglass/clock.ex`) — Phase 1 shipped with test-time freeze support. Phase 4 D-03 SendGrid timestamp-tolerance math uses it; `Mailglass.Clock.Frozen.freeze/1` in `WebhookCase` tests.
- **`Mailglass.Error` hierarchy** (`lib/mailglass/errors/*.ex`) — Phase 1 + 2 shipped. Phase 4 D-21 extends `%SignatureError{}.type` closed atom set (seven values); D-14 extends `%TenancyError{}.type` with `:webhook_tenant_unresolved`; D-21 rationale extends `%ConfigError{}.type` with `:webhook_verification_key_missing`. All three update `docs/api_stability.md`.
- **`Mailglass.Telemetry` span helpers** (`lib/mailglass/telemetry.ex`) — Phase 1 + 2 + 3 shipped. Phase 4 D-22 adds `webhook_ingest_span/3`, `webhook_verify_span/3`, `webhook_reconcile_span/3` following Phase 1 D-27 naming convention (span helpers co-located per domain in `lib/mailglass/webhook/telemetry.ex` — new file, same pattern).
- **`Mailglass.PubSub.Topics.events/1` + `events/2`** (`lib/mailglass/pub_sub/topics.ex`) — Phase 3 shipped. Phase 4 consumes via Projector — no new topics.
- **`Mailglass.Config`** (`lib/mailglass/config.ex`) — NimbleOptions schema. Phase 4 extends additively: `:postmark` (secret / basic_auth / ip_allowlist / enabled), `:sendgrid` (public_key / timestamp_tolerance_seconds / enabled), `:webhook_retention` (succeeded_days / dead_days / failed_days), `:webhook_ingest_mode` (default `:sync`).
- **`Mailglass.Migration`** + `Mailglass.Migrations.Postgres.V01` (`lib/mailglass/migration.ex`, `lib/mailglass/migrations/postgres/v01.ex`) — Phase 2 shipped. Phase 4 adds `Mailglass.Migrations.Postgres.V02` (D-15 DDL split).
- **`Mailglass.OptionalDeps.Oban`** gateway — Phase 2 + 3 shipped. Phase 4 `Mailglass.Webhook.Reconciler` + `Mailglass.Webhook.Pruner` use it (conditional compile behind `Code.ensure_loaded?(Oban)`).
- **`Mailglass.Outbound.Delivery`** (`lib/mailglass/outbound/delivery.ex`) — Phase 2 + 3 shipped. Phase 4 writes NOTHING directly to deliveries — always through Projector. `last_event_type` enum already includes `:reconciled` candidate via extension mechanism (D-18 verifies this at plan time — if enum is closed, Phase 4 migration also extends it).

### Established Patterns (from Phases 1–3)

- **Closed atom sets with `__types__/0` + `api_stability.md` cross-check** — Phase 4 extends `SignatureError.__types__/0` to seven values per D-21 + `TenancyError.__types__/0` with `:webhook_tenant_unresolved` per D-14.
- **`defexception` + `@behaviour Mailglass.Error` + `new/1` formatter + `Jason.Encoder` on `[:type, :message, :context]`** — Phase 4 extends existing structs, adds no new error structs.
- **Behaviour + default impl + Config selector** — D-01 `Mailglass.Webhook.Provider` + `Providers.Postmark` + `Providers.SendGrid` matches the Phase 2 `Mailglass.Tenancy` + `SingleTenant` pattern + Phase 3 `Mailglass.Adapter` + `Fake`/`Swoosh` pattern. Same shape, same discoverability.
- **Supervisor child owning ETS is the Phase 3 D-22 idiom; Phase 4 adds NOTHING ETS-backed** — webhook ingest is request-process, reconciler/pruner are Oban-driven. No new supervised GenServer in the Application tree.
- **Telemetry span helpers co-located per domain** — `lib/mailglass/webhook/telemetry.ex` is new and mirrors `lib/mailglass/outbound.ex`'s `send_span/3` placement.
- **Oban optional gateway + boot warning** — D-20 mirrors Phase 3 D-17 exactly: `:persistent_term`-gated single `Logger.warning` at `Mailglass.Application.start/2`.
- **Boundary blocks** — Phase 4 adds `Mailglass.Webhook` sub-boundary with sub-blocks `Mailglass.Webhook.Router`, `Mailglass.Webhook.Plug`, `Mailglass.Webhook.Providers`, `Mailglass.Webhook.Ingest`, `Mailglass.Webhook.Reconciler`, `Mailglass.Webhook.Pruner`, `Mailglass.Webhook.CachingBodyReader`, `Mailglass.Webhook.Telemetry`. Deps: `[Mailglass, Repo, Events, Projector, Tenancy, Telemetry, Config, PubSub, OptionalDeps.Oban]`. Explicitly NOT a dependent of `Mailglass.Outbound` (webhook ingest writes events without going through the send pipeline).
- **`mix compile --no-optional-deps --warnings-as-errors` CI lane** — Phase 4 must keep passing. Reconciler + Pruner behind OptionalDeps.Oban; no Provider module references Oban structs in the public type surface.

### Integration Points

- **`Mailglass.Application` supervision tree** — Phase 4 adds NOTHING to the tree (webhook ingest is request-process; Reconciler + Pruner are Oban-owned). The only boot-time side effect is the D-20 + D-04 `Logger.warning` calls gated by `:persistent_term`.
- **`mix.exs`** — no new required deps. Plug is transitively required via Phoenix; `:crypto` + `:public_key` are OTP stdlib; `:oban` is optional (already declared in Phase 3).
- **`config/config.exs` + `config/test.exs`** — Phase 4 adds `:postmark`, `:sendgrid`, `:webhook_retention`, `:webhook_ingest_mode` keys (additive; no reshuffle of Phase 1–3 keys). `config/test.exs` adds stub secrets for WebhookCase.
- **`test/support/`** — new files: `webhook_case.ex` (extends Phase 3 stub), `fixtures/webhooks/postmark/*.json`, `fixtures/webhooks/sendgrid/*.json`, `webhook_fixtures.ex` (helpers for re-signing fixtures with test keys). `Mailglass.TestAssertions` extends Phase 3's `assert_mail_delivered/2` + `assert_mail_bounced/2` with `assert_webhook_ingested/3` per D-26.
- **`docs/api_stability.md`** — extends §Error types (SignatureError 7-atom set, TenancyError +1, ConfigError +1), §Tenancy behaviour (`resolve_webhook_tenant/1` optional callback), §Telemetry catalog (5 webhook events + 1 reconcile span), §PubSub topics (no new topics — reuses Phase 3 shape), §Webhook (NEW section: Provider behaviour shape, plug-opts, CachingBodyReader contract, router-macro signature).
- **`guides/webhooks.md`** — new guide (Phase 7 will generate more, but this one ships with Phase 4 for the §Auto-suppression via telemetry recipe per D-25 and §Multi-tenant patterns per D-12). Phase 7 installer consumes.
- **Phase 5 hook points** — `MailglassAdmin.*` LiveViews will subscribe to `Mailglass.PubSub.Topics.events(tenant_id)` and render webhook events + orphans + reconciled events via the Phase 3 + Phase 4 broadcast. NO coupling — Phase 5 reads, doesn't write.
- **Phase 6 hook points** — `EventTaxonomyIsVerbatim` Credo check (new, forward-ref per D-23) lints `lib/mailglass/webhook/providers/*.ex`; `NoPiiInTelemetryMeta` (LINT-02) lints Phase 4 telemetry metadata; `NoUnscopedTenantQueryInLib` (LINT-03) lints every Phase 4 Ecto query.
- **Phase 7 hook points** — `mix mailglass.install` generates the router macro mount snippet + the `Plug.Parsers` body_reader snippet + config stubs; golden-diff CI catches any Phase 4 router-macro signature change.

</code_context>

<specifics>
## Specific Ideas

- **The verifier behaviour is two callbacks, not one or three.** Django-anymail locked the shape (`validate_request` + `parse_events`), ActionMailbox confirms it (authenticate-before-action + per-ingress body parse), lattice_stripe collapses to one because it's single-provider. Mailglass ships two callbacks because two providers with fundamentally different signature mechanics (Postmark Basic Auth vs SendGrid ECDSA) need to isolate crypto from taxonomy. v0.5 Mailgun + Resend fit the same two-callback shape; SES adds an optional `handle_control_message/2` for `SubscriptionConfirmation` without breaking v0.1 providers.
- **The `:reconciled` event is a mailglass-internal lifecycle event, not a provider event.** It has no "verbatim Anymail" precedent because it's expressing a mailglass-specific state transition that doesn't exist in provider vocabulary. Documenting it as the ONE exception to D-14 preserves the taxonomy discipline: every other event is provider-sourced and verbatim.
- **Separate `mailglass_webhook_events` table is the only architecturally coherent answer** given the tension between D-15 append-only, retention needs, GDPR erasure, and debug value. Accrue shipped this pattern. Keeping raw_payload on `mailglass_events` with a trigger carve-out would mean "which columns are really immutable?" debates at every future schema change. Splitting is the structural choice that keeps the invariant clean.
- **`*/5` cron beats `*/15` cron** by 3× on orphan-linked latency with negligible DB cost (5 queries/hour/tenant extra). The STATE note preference for `*/15` was not load-bearing and is unlocked here.
- **Tenant resolution via callback is the only pattern that composes with every adopter strategy.** URL prefix, payload field, and header are all adopter-driven compositions of the same callback. Forcing one strategy into the library would either foreclose strategies we can't predict (GitHub App `installation_id` style) or ship a pre-built menu that ages out (provider sub-account identifiers change).
- **Signature verify FIRST, tenant resolve SECOND** is non-negotiable for security. The Stripe Connect chicken-and-egg (tenant in payload, but payload must be verified first) is resolved by the same pattern Stripe uses: one platform-wide (or per-endpoint) signing secret, tenant extracted from verified payload. Mailglass's plug opt `secret:` supports both static binary + runtime `{m, f, a}` tuple so adopters can dispatch to per-endpoint secrets without rolling their own plug.
- **Sync ingest is correct for libraries; async is correct for application-layer webhook relays.** Stripe's "always async" advice targets unbounded business logic in user handlers; mailglass normalization is bounded (pattern-match + insert + broadcast), so the sync tax is predictable. HOOK-06 reads the normalization as one `Ecto.Multi` — sync makes that literal. v0.5 async opt-in is for adopters with unusual bottleneck profiles, not the default.
- **Never put IP in telemetry metadata.** High-cardinality label explosion aside, IP is GDPR-ambiguous under some interpretations and legally-unambiguous PII under others. Keep it in `Logger.warning` where adopters can elect their own scrub policy. This is the discipline accrue's plug enforces and it's the right call here.
- **`%SignatureError{}.type` stays `:type`.** The researcher recommended renaming to `:reason` for lattice_stripe alignment. Rejected: Phase 1 locked `:type + :message + :context` across every mailglass error struct; a one-struct deviation for a cosmetic naming-collision argument (event.type vs err.type — distinct variable scopes) is worse than the consistency it sacrifices.
- **`:secret_not_configured` is a `%ConfigError{}`, not `%SignatureError{}`.** Accrue's `plug.ex:96` raises SignatureError for missing endpoint config — that's a muddle (adopter sees 400 + SignatureError trace when the real fix is "set the config"). Mailglass separates: missing config raises ConfigError at boot (config validate); verify-time failures raise SignatureError with the seven atoms.
- **Postmark IP allowlist is OPT-IN.** Postmark's own docs warn that origin IPs can change. Opt-in avoids surprise-blocking legitimate webhooks for adopters who haven't configured `Plug.RewriteOn`. The `Logger.warning` at boot when allowlist is on but `:trusted_proxies` is unset is the safeguard that makes the opt-in usable.
- **Webhook ingest process gets `lock_timeout` + `statement_timeout`.** 2s statement timeout + 500ms lock timeout, `SET LOCAL` inside `Repo.transact/1`. Prevents the "slow DB → provider retries → more DB pressure → DoS loop" feedback cycle documented in the sync-vs-async research.
- **No Task.Supervisor cron for orphan reconciliation.** The Phase 3 Outbound Task.Supervisor fallback is one-shot async delivery, not periodic sweep. Periodic scheduling needs crash recovery + backoff + telemetry + doesn't-fight-Oban, and Task.Supervisor has none of those. Adopters without Oban run `mix mailglass.reconcile` from their own cron infrastructure (system cron, Kubernetes CronJob, etc.) — this is honest and doesn't pretend to be durable.

### Phase 4 property test shape (informs planner's test decomposition of TEST-03 + HOOK-07)

```
property "webhook ingest is idempotent under 1000 (event, replay 1..10) sequences"
property "SendGrid ECDSA verification rejects any bit-flip in signed payload"
property "Postmark Basic Auth verification rejects any bit-flip in credentials"
property "signature failure always raises exactly one %SignatureError{} atom from the closed set of 7"
property "tenant resolution via SingleTenant always stamps 'default'"
property "tenant resolution via ResolveFromPath stamps path_params['tenant_id']"
property "tenant resolution callback error raises %TenancyError{type: :webhook_tenant_unresolved}"
property "orphan event + later Delivery commit → Reconciler appends :reconciled event within 5 min"
property "every webhook emits ingest span; every signature emits verify span; batch normalizes emit one :normalize :stop per event"
```

### v0.5 forward-references explicit in Phase 4 code

- `Mailglass.Config :webhook_ingest_mode` accepts `:sync | :async` but `:async` is `@moduledoc false` — value parses at boot, implementation path is `raise "async ingest is v0.5"` stub.
- `Mailglass.Tenancy.resolve_webhook_tenant/1` optional callback shape is stable — v0.5 DELIV-07 `adapter_for/1` adds a sibling callback with the same context map shape.
- `Mailglass.Webhook.Providers` exhaustive dispatch — v0.5 adds `Mailgun`, `SES`, `Resend` modules behind the same `@moduledoc false` internal behaviour; adopter API stays `mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :mailgun]`.
- `Mailglass.Webhook.Reconciler` worker shape supports v0.5 prod admin: telemetry already covers `scanned_count / linked_count / remaining_orphan_count`, admin dashboard just subscribes and renders.
- Auto-suppression recipe in `guides/webhooks.md` shows the telemetry-handler pattern adopters use today; v0.5 DELIV-02 converts the recipe into first-class library behavior with `config :mailglass, :webhook_auto_suppress, :all | :bounce_complaint_only | :off`.

</specifics>

<deferred>
## Deferred Ideas

- **Async webhook ingest via Oban** (v0.5 — tied to prod admin + DLQ visualization). `:webhook_ingest_mode: :async` reserved in D-09; implementation waits for the DLQ admin story.
- **Auto-suppression on terminal events (`:bounced` hard + `:complained` + `:unsubscribed`)** (v0.5 DELIV-02). D-25 defers; telemetry-handler recipe documented as the v0.1 path.
- **Mailgun / SES / Resend provider verifiers** (v0.5 — PROJECT D-10). D-01 sealed behaviour absorbs them without API break; SES needs one new optional callback `handle_control_message/2` for SubscriptionConfirmation.
- **Adopter-extensible `Mailglass.Webhook.Provider` behaviour** (v0.5 — when the surface is stable across 5 providers). D-01 gates via `@moduledoc false`.
- **Prod admin dashboard with orphan panel + DLQ visualization** (v0.5 — `mailglass_admin` prod admin, not Phase 5 dev preview). Phase 4 telemetry already covers the data needs.
- **Per-tenant adapter resolver `c:adapter_for/1`** (v0.5 DELIV-07). Parallels Phase 4 D-12 `c:resolve_webhook_tenant/1`.
- **`raw_payload` retention policy beyond status-age heuristic** (v0.5 — customer-specific retention per tenant via callback). D-16 ships default two-knob config.
- **SNS subscription confirmation auto-GET** (v0.5 SES — `handle_control_message/2` callback).
- **Mailgun HMAC-SHA256 timestamp-token replay-cache** (v0.5 Mailgun — adds `config :mailglass, :mailgun, replay_cache_seconds: 60`).
- **Multi-provider webhook path `/webhooks/:provider`** (single-dispatcher style) — deliberately rejected (D-07). Provider-per-path stays.
- **Plug-level `:handler` opt for user-dispatched webhook callbacks** — deliberately rejected (D-10). Users subscribe to post-commit PubSub instead.
- **Task.Supervisor cron for orphan reconciliation** — deliberately rejected (D-20). Adopters without Oban run mix task from external cron.
- **Update `mailglass_events.delivery_id` post-reconciliation** — deliberately rejected (D-18, D-15 enforcement). Append-only preserved by appending `:reconciled` event.
- **Trigger carve-out to permit specific-column UPDATE on events** — deliberately rejected (D-18 rationale). Creates "which columns are really immutable?" debates at every schema change.
- **Hybrid sync-insert + async-normalize ingest** (Option C from sync/async research) — deliberately rejected. "Brief admin shows `event_type: nil`" violates brand voice discipline.
- **Storing IP in telemetry metadata** — deliberately rejected (D-23). GDPR-ambiguous + cardinality-explosion; adopter-extensible via their own handler.
- **Renaming `%SignatureError{}.type` to `:reason`** — deliberately rejected (D-21 rationale). Consistency with Phase 1 Mailglass.Error hierarchy wins over lattice_stripe alignment.
- **Postmark IP allowlist on by default** — deliberately rejected (D-04). Postmark's own docs warn IPs change; opt-in is safer.
- **Adopter-provided `SignatureError.type` atoms** (beyond the closed 7) — deliberately rejected. Adding atoms is a minor-version API expansion; ad-hoc adopter atoms muddle pattern-match contracts.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 4.

</deferred>

---

*Phase: 04-webhook-ingest*
*Context gathered: 2026-04-23*
