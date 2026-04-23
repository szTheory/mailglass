# Phase 4: Webhook Ingest — Research

**Researched:** 2026-04-23
**Domain:** Phoenix/Plug webhook ingest with HMAC verification, Anymail event normalization, idempotent Ecto.Multi persistence, Oban orphan reconciliation
**Confidence:** HIGH (all 27 CONTEXT decisions verified against shipped Phase 1–3 code; SendGrid ECDSA + Plug body_reader contracts cross-checked against official docs)

## Summary

Phase 4 is a **plumbing phase**, not a discovery phase. CONTEXT.md `04-CONTEXT.md` already locks 27 decisions (D-01..D-29) covering verifier shape, plug routing, body reader, ingest Multi, orphan reconciliation, error/telemetry surface, DDL split, and forward-references. Of those: signature-verify ordering, the two-callback Provider behaviour, the `Repo.transact/1` ingest Multi composition, and the append-only `:reconciled` event are non-negotiable constraints, not exploration space. The Phase 2/3 codebase has already shipped every dependency this phase consumes — `Events.append_multi/3` (function-form), `Outbound.Projector.update_projections/2` + `broadcast_delivery_updated/3`, `Repo.transact/1` + `Repo.multi/1`, `Tenancy.put_current/1` + `with_tenant/2`, `Clock.utc_now/0`, `IdempotencyKey.for_webhook_event/2`, `OptionalDeps.Oban.available?/0`, `PubSub.Topics.events/{1,2}`, the SQLSTATE 45A01 trigger, and the `mailglass_events` partial UNIQUE on `idempotency_key`. The webhook plug threads through these without modification.

The research deliverable is therefore: (1) **verify** every locked pattern still works against the shipped 2026 stack (Plug 1.19.1, OTP 27, Phoenix 1.8.5), (2) **document the exact signatures** Phase 4 plans must call so the planner doesn't have to re-read the code, (3) **resolve the three open questions** flagged in ROADMAP — SendGrid ECDSA on OTP 27 `:crypto`/`:public_key`, CachingBodyReader + Plug 1.18 chain interaction, orphan reconciliation cadence — and (4) **specify the Validation Architecture** mapping each REQ-ID to a concrete test command. All three open questions resolve with HIGH confidence: the DER-not-PEM SendGrid pattern is correct; Plug 1.19.1's `:body_reader` MFA contract is stable since Plug 1.5.1 (PR #698); `*/5` cron with 60-second age threshold is the chosen cadence (per CONTEXT D-17, accrue-verbatim).

**Primary recommendation:** Plan exactly to CONTEXT.md. Do not relitigate any D-XX decision. Wave 0 lands the migration V02 + WebhookCase fixtures + test signing keys; Wave 1 ships CachingBodyReader + Provider behaviour + Postmark/SendGrid impls; Wave 2 ships Plug + Router macro + Tenancy callback extension + error atom-set extensions; Wave 3 ships Ingest Multi + Reconciler/Pruner Oban workers; Wave 4 ships StreamData property tests + phase-wide UAT gate. The hardest cell to verify is the SendGrid ECDSA test fixture (because the test cannot use a real SendGrid private key); the planner must include a "mint test ECDSA P-256 keypair via `:public_key.generate_key/1`" Wave 0 task.

## Architectural Responsibility Map

Phase 4 is server-side only (no browser tier; no SSR). The capability map below shows which subsystem owns each behavior:

| Capability | Primary Owner | Secondary Owner | Rationale |
|------------|---------------|-----------------|-----------|
| Raw body capture for HMAC | `Mailglass.Webhook.CachingBodyReader` (request process, before parsers) | — | Must run BEFORE `Plug.Parsers` consumes the body; iodata accumulation across `{:more, _, _}` chunks for SendGrid batches |
| Signature verification | `Mailglass.Webhook.Providers.{Postmark,SendGrid}.verify!/3` | `Mailglass.Webhook.Plug` (orchestrator) | Pure function on `(raw_body, headers, config)`; raises `%SignatureError{}` on failure; no Conn coupling |
| Provider event → Anymail taxonomy mapping | `Mailglass.Webhook.Providers.{Postmark,SendGrid}.normalize/2` | — | Pure function returning `[%Mailglass.Events.Event{}]`; exhaustive case + `Logger.warning` fallthrough to `:unknown` (D-05) |
| Tenant resolution | `Mailglass.Tenancy.resolve_webhook_tenant/1` (NEW optional callback per D-12) | `Mailglass.Tenancy.ResolveFromPath` (NEW shipped sugar) | Behaviour callback runs AFTER signature verify (D-13); receives `verified_payload` map for Stripe-Connect-style strategies |
| Ingest persistence | `Mailglass.Webhook.Ingest.ingest_multi/3` (NEW) | `Mailglass.Repo.transact/1` (Phase 2) | One Ecto.Multi: webhook_events row + N events rows + Projector update; `SET LOCAL statement_timeout/lock_timeout` per D-29 |
| Delivery projection update | `Mailglass.Outbound.Projector.update_projections/2` (Phase 2/3) | — | Already shipped; D-15 monotonic + optimistic lock; Phase 4 calls verbatim |
| Post-commit broadcast | `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` (Phase 3 D-04) | — | Already shipped; reuses topics `events(tenant_id)` + `events(tenant_id, delivery_id)` |
| Routing / mounting | `Mailglass.Webhook.Router.mailglass_webhook_routes/2` macro (NEW) | adopter `scope` + `pipe_through` | Match LiveDashboard / Oban Web idiom; provider-per-path (D-07) |
| Orphan reconciliation cron | `Mailglass.Webhook.Reconciler` Oban worker (NEW) | `Mailglass.Events.Reconciler.{find_orphans,attempt_link}/1,2` (Phase 2 shipped) | `*/5 * * * *` cron (D-17); 60s age threshold; appends `:reconciled` event (D-18) — never UPDATEs orphan row |
| Webhook payload retention | `Mailglass.Webhook.Pruner` Oban cron (NEW) | `mix mailglass.webhooks.prune` mix task (NEW) | Daily cron deletes `mailglass_webhook_events` rows by `status` + age; `Logger.warning` boot fallback if Oban absent |
| Error surface extensions | `Mailglass.SignatureError` (Phase 1 shipped) + `Mailglass.TenancyError` + `Mailglass.ConfigError` | — | Atom-set extensions only (no new structs) per D-21 + D-14 + D-21-rationale |
| Telemetry surface | `Mailglass.Webhook.Telemetry` (NEW; co-located span helpers per Phase 3 convention) | `Mailglass.Telemetry.span/3` (Phase 1) | Five new event paths under `[:mailglass, :webhook, *]` (D-22); metadata whitelist per D-23 |

## Standard Stack

### Core (already shipped — no new required deps for Phase 4)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `plug` | 1.19.1 (mix.lock confirmed) | Webhook plug + `body_reader` MFA contract | Required by Phoenix; `:body_reader` stable since 1.5.1 (PR #698) [VERIFIED: HexDocs] |
| `plug_crypto` | 2.1.1 (mix.lock confirmed) | `secure_compare/2` for Postmark Basic Auth (D-04) | **Already transitive via Plug 1.19.1** (no new dep needed) [VERIFIED: mix.lock] |
| `:crypto` (OTP 27 stdlib) | OTP 27 | SHA-256 hash + HMAC primitives | Already in `extra_applications: [:logger, :crypto]` (mix.exs:30) [VERIFIED: mix.exs] |
| `:public_key` (OTP 27 stdlib) | OTP 27 | ECDSA verify + DER decode for SendGrid | Stdlib; **must add to `extra_applications`** in mix.exs (currently absent — flag for planner) [VERIFIED: mix.exs grep] |
| `phoenix` | 1.8.5 | Routing + PubSub | Phase 1 shipped; Phase 4 mounts via Router macro [VERIFIED: mix.lock] |
| `phoenix_pubsub` | (transitive via Phoenix 1.8.5) | Post-commit broadcast | Already wired as `Mailglass.PubSub` (Phase 3) [VERIFIED: lib/mailglass/application.ex:21] |
| `ecto_sql` | 3.13.x | `Ecto.Multi` composition + `Repo.transact/1` | Phase 2 shipped [VERIFIED: mix.exs:65] |
| `jason` | 1.4 | Webhook JSON body parsing | Already required [VERIFIED: mix.exs:76] |

### Optional (Phase 4 consumes existing gateway)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | 2.21+ (optional) | `Mailglass.Webhook.Reconciler` cron (`*/5 * * * *`) + `Mailglass.Webhook.Pruner` cron (daily) | When adopter ships Oban; otherwise `Logger.warning` boot fallback per D-20 [VERIFIED: lib/mailglass/optional_deps/oban.ex] |

### Test-only (already in mix.lock)

| Library | Version | Purpose |
|---------|---------|---------|
| `stream_data` | 1.3 | HOOK-07 1000-replay property + signature/tenant property tests (D-27) |
| `mox` | 1.2 | Not used for transport; reserved for adopter-supplied mock provider behaviours |

### Alternatives Considered (already rejected by CONTEXT)

| Instead of | Could Use | Why CONTEXT rejects |
|------------|-----------|---------------------|
| Sealed two-callback `Provider` (`@moduledoc false`) | Adopter-extensible behaviour | D-01 rationale: PROJECT D-10 defers Mailgun/SES/Resend to v0.5; sealing now keeps the surface stable. v0.5 adds `Mailgun`, `SES`, `Resend` modules behind the same internal behaviour. |
| `:public_key.pem_decode/1` | DER decode | D-03 rationale: SendGrid dashboard ships base64 DER (no `-----BEGIN PUBLIC KEY-----` framing); `pem_decode/1` does NOT parse it. Verified independently in this research. |
| Single-dispatcher `/webhooks/:provider` | Per-provider path (`/webhooks/postmark`, `/webhooks/sendgrid`) | D-07 rationale: matches ActionMailbox + django-anymail; cleaner telemetry; cleaner secret resolution. |
| Async ingest as v0.1 default | Sync (P50 ~15-30ms, P99 ~150-300ms) | D-11 rationale: Task.Supervisor is unsafe for webhook normalization (provider already received 200; in-memory queue loss = silent ledger corruption). |
| `Task.Supervisor` cron for orphan reconciliation | Oban cron + `Logger.warning` + mix task fallback | D-20 rationale: hand-rolled scheduling has no crash recovery, no backoff, no telemetry; Phase 3 D-17 pattern reused. |
| UPDATE orphan event on reconciliation | Append `:reconciled` event | D-18 rationale: SQLSTATE 45A01 trigger means UPDATE raises; trigger carve-out would muddy the immutability invariant. Append preserves append-only structurally. |
| Hardcoded Postmark IP allowlist | Documented in `guides/webhooks.md`, opt-in config | D-04 rationale: Postmark's own docs warn IPs change; opt-in avoids surprise-blocking; IPs are a list to copy-paste. |
| Auto-suppression on bounce/complaint | Telemetry handler recipe in `guides/webhooks.md` | D-25 rationale: re-opening Phase 3 deferred lock for v0.5 DELIV-02 creates migration nightmare across hard-bounce classifier + scope coupling + manual-source collisions. |

**No new dependencies to install.** All Phase 4 libraries are already declared in `mix.exs` (Phase 1 shipped). Verify version currency before plan-time:

```bash
mix hex.outdated plug plug_crypto phoenix oban
```

**Action item for Plan 1 (Wave 0):** Add `:public_key` to `extra_applications` in `mix.exs:30`. Without it, releases may strip the OTP app and SendGrid verification will fail with `:undef` at runtime in production.

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        ADOPTER PHOENIX ENDPOINT                          │
│                                                                          │
│  Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason,     │
│    body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},   │
│    length: 10_000_000                                                    │
│                                                                          │
│  Router:  scope "/", MyAppWeb do                                         │
│             pipe_through :mailglass_webhooks                             │
│             mailglass_webhook_routes "/webhooks"   ◄── D-06 macro        │
│           end                                                            │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
                                  │  POST /webhooks/{postmark|sendgrid}
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        Mailglass.Webhook.Plug                            │
│                                                                          │
│   1. extract_headers_and_raw_body(conn)        ──► {raw_body, headers}   │
│      (reads conn.private[:raw_body] from CachingBodyReader)              │
│                                                                          │
│   2. Provider.verify!(raw_body, headers, cfg)                            │
│      └► raise %SignatureError{type: <one of 7>, provider:}  →  401       │
│      └► raise %ConfigError{type: :webhook_verification_key_missing} →500 │
│                                                                          │
│   3. Tenancy.resolve_webhook_tenant(context)                             │
│      └► {:ok, tenant_id}  →  Tenancy.put_current(tenant_id)              │
│      └► {:error, _}       →  raise %TenancyError{                        │
│                                       type: :webhook_tenant_unresolved}  │
│                                       →  422                             │
│                                                                          │
│   4. events = Provider.normalize(raw_body, headers)  [pure]              │
│                                                                          │
│   5. Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events)   │
│      ─► Repo.transact(fn -> Repo.multi(multi) end)                       │
│         where multi composes:                                            │
│         ┌─ SET LOCAL statement_timeout='2s'; lock_timeout='500ms'        │
│         ├─ insert mailglass_webhook_events (UNIQUE replay = no-op)       │
│         ├─ for each event:                                               │
│         │    Events.append_multi(name, attrs_fn)                         │
│         │    └─ delivery_id resolved by lookup; nil → orphan             │
│         │       + needs_reconciliation: true                             │
│         ├─ for each event with delivery match:                           │
│         │    Multi.update Projector.update_projections(delivery, event)  │
│         └─ flip mailglass_webhook_events.status -> :succeeded            │
│                                                                          │
│   6. (post-commit) Projector.broadcast_delivery_updated/3 per delivery   │
│      └► Phoenix.PubSub on events(tenant_id) + events(tenant_id, did)     │
│                                                                          │
│   7. send_resp(conn, 200, "")                                            │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        ▼                         ▼                         ▼
   admin LiveView         adopter telemetry        Oban: Reconciler */5
   (Phase 5 reads         handlers (auto-          + Pruner daily
   PubSub)                suppression recipe)       (Phase 4 ships)
                                                                          
                                                  ┌─────────────────────┐
   (orphan flow, async)                           │   Reconciler:       │
   Webhook arrives BEFORE Delivery row commits    │   find_orphans/1    │
   ──► event row inserted with delivery_id=nil    │      (existing)     │
       + needs_reconciliation=true                │   attempt_link/2    │
                                                  │      (existing)     │
   Reconciler */5 cron picks it up:               │   appends           │
   ──► matched: append :reconciled event          │   :reconciled event │
       + Projector.update_projections             │   in transact/1     │
       + broadcast                                └─────────────────────┘
   ──► no_match: leave alone, retry next tick                            
   ──► >7d old: drop from scan (admin shows hint)                        
```

### Recommended Project Structure

```
lib/mailglass/webhook/
├── caching_body_reader.ex           # D-09 — iodata accumulation
├── plug.ex                          # D-10 — single-ingress orchestrator
├── router.ex                        # D-06 — mailglass_webhook_routes/2 macro
├── provider.ex                      # D-01 — sealed two-callback @moduledoc false behaviour
├── providers/
│   ├── postmark.ex                  # D-04 — Basic Auth + IP allowlist
│   └── sendgrid.ex                  # D-03 — ECDSA via :public_key
├── ingest.ex                        # D-15 — ingest_multi/3 composition + statement_timeout
├── reconciler.ex                    # D-17 — Oban cron */5 (conditional compile)
├── pruner.ex                        # D-16 — Oban daily cron (conditional compile)
└── telemetry.ex                     # D-22 — span helpers (5 events)

lib/mailglass/tenancy/
└── resolve_from_path.ex             # D-12 — opt-in URL-prefix sugar

lib/mailglass/migrations/postgres/
└── v02.ex                           # D-15 — webhook_events table + drop events.raw_payload

lib/mailglass/errors/                # EXTENSIONS only (no new structs):
├── signature_error.ex               # D-21 — atom set 4 → 7 values
├── tenancy_error.ex                 # D-14 — atom set 1 → 2 values
└── config_error.ex                  # D-21 rationale — :webhook_verification_key_missing

priv/repo/migrations/
└── 00000000000003_mailglass_webhook_events.exs   # 8-line wrapper, calls Migration.up/0

test/support/
├── webhook_case.ex                  # extends Phase 3 stub with D-26 helpers
├── webhook_fixtures.ex              # mint test ECDSA keypair + sign helpers
└── fixtures/webhooks/
    ├── postmark/
    │   ├── delivered.json
    │   ├── bounced.json
    │   ├── opened.json
    │   ├── clicked.json
    │   └── spam_complaint.json
    └── sendgrid/
        ├── batch_5_events.json
        └── single_event.json

test/mailglass/webhook/
├── caching_body_reader_test.exs
├── plug_test.exs
├── router_test.exs
├── providers/
│   ├── postmark_test.exs
│   └── sendgrid_test.exs
├── ingest_test.exs
├── reconciler_test.exs
└── pruner_test.exs

test/mailglass/properties/
├── webhook_idempotency_convergence_test.exs    # HOOK-07: 1000-replay
├── webhook_signature_failure_test.exs           # property D-27 #2
└── webhook_tenant_resolution_test.exs           # property D-27 #3
```

### Pattern 1: Two-callback Provider behaviour with pure tuple input (D-01, D-02)

**What:** `@moduledoc false` behaviour with `verify!/3` (raises) + `normalize/2` (pure). No `%Plug.Conn{}` in the contract — verifier receives `{raw_body, headers, config}`.

**When to use:** Every provider in `lib/mailglass/webhook/providers/`. v0.5 adds `Mailgun`, `SES`, `Resend` behind the same shape.

**Example:**
```elixir
# lib/mailglass/webhook/provider.ex
defmodule Mailglass.Webhook.Provider do
  @moduledoc false  # SEALED — adopter-extensible v0.5

  @callback verify!(raw_body :: binary(), headers :: [{String.t(), String.t()}], config :: map()) :: :ok
  @callback normalize(raw_body :: binary(), headers :: [{String.t(), String.t()}]) :: [%Mailglass.Events.Event{}]
end
```

### Pattern 2: SendGrid ECDSA verification on OTP 27 (D-03 — verified against `:public_key` v1.17+)

**What:** SendGrid ships base64-encoded DER (NOT PEM) — `:public_key.der_decode/2` is the correct entry point.

**Verification chain:**
```elixir
# Source: D-03 verbatim; verified against erlang.org/docs/27/apps/public_key/public_key
@spec verify_signature(binary(), binary(), binary(), binary()) :: :ok
defp verify_signature(raw_body, signature_b64, timestamp, public_key_b64) do
  decoded = Base.decode64!(public_key_b64)
  {:SubjectPublicKeyInfo, alg_id, pk_bits} =
    :public_key.der_decode(:SubjectPublicKeyInfo, decoded)
  {:AlgorithmIdentifier, _oid, ec_params_der} = alg_id
  ecc_params = :public_key.der_decode(:EcpkParameters, ec_params_der)
  pk = {{:ECPoint, pk_bits}, ecc_params}

  signed_payload = timestamp <> raw_body
  sig = Base.decode64!(signature_b64)

  case :public_key.verify(signed_payload, :sha256, sig, pk) do
    true -> :ok
    false -> raise Mailglass.SignatureError.new(:bad_signature, provider: :sendgrid)
  end
rescue
  # Bad Base64, malformed DER, ASN.1 decode error, wrong algorithm
  e in [ArgumentError, MatchError] ->
    raise Mailglass.SignatureError.new(:malformed_header,
            provider: :sendgrid,
            cause: e)
end
```

**Curve:** prime256v1 / P-256 / secp256r1 — SendGrid's documented default. OID `{1,2,840,10045,3,1,7}`.

**Headers parsed:**
- `X-Twilio-Email-Event-Webhook-Signature` (base64-encoded DER ECDSA signature)
- `X-Twilio-Email-Event-Webhook-Timestamp` (string timestamp)

**Signed payload format:** `timestamp + raw_body` concatenation (RAW BYTES — no JSON re-encoding) [VERIFIED: twilio.com docs].

**Replay tolerance:** **300 seconds** — SendGrid does NOT document one but Stripe / Svix / Standard Webhooks consensus is 5 minutes. Configurable via `config :mailglass, :sendgrid, timestamp_tolerance_seconds: 300`. Tested with `Mailglass.Clock.Frozen.advance/1` in `WebhookCase` (D-26).

**Pattern-match strictly on `true`:** `case` not `if` — `false`, `{:error, _}`, and DER-decode exceptions are all `:bad_signature` or `:malformed_header`. Closes the "wrong algo silently returns false" footgun called out in D-03.

### Pattern 3: Postmark Basic Auth verification (D-04)

**What:** Postmark has NO HMAC. Per-tenant Basic Auth credentials are the trust boundary; opt-in IP allowlist is belt-and-suspenders.

**Constant-time comparison:**
```elixir
# Plug.Crypto 2.1.1 ships secure_compare/2 — already in deps
defp verify_basic_auth!(headers, %{username: u, password: p}) do
  case List.keyfind(headers, "authorization", 0) do
    {"authorization", "Basic " <> b64} ->
      case Base.decode64(b64) do
        {:ok, "#{u}:#{p}" = expected} ->
          # Decode the actual creds and constant-time compare
          # NOTE: cannot interpolate variables in pattern; use the
          # decoded-and-split approach instead:
          case String.split(decoded_value, ":", parts: 2) do
            [user, pass] ->
              if Plug.Crypto.secure_compare(user, u) and Plug.Crypto.secure_compare(pass, p),
                do: :ok,
                else: raise Mailglass.SignatureError.new(:bad_credentials, provider: :postmark)
            _ ->
              raise Mailglass.SignatureError.new(:malformed_header, provider: :postmark)
          end
        _ ->
          raise Mailglass.SignatureError.new(:malformed_header, provider: :postmark)
      end
    nil ->
      raise Mailglass.SignatureError.new(:missing_header, provider: :postmark)
  end
end
```

**IP allowlist (opt-in via `config :mailglass, :postmark, ip_allowlist: [cidrs]`):**
- Read `conn.remote_ip` AFTER adopter-configured `Plug.RewriteOn` has run.
- CIDR membership test: pure Elixir using `:inet.parse_address/1` + bit math (no new dep).
- **Boot-time `Logger.warning`** when allowlist on but `:trusted_proxies` unset (D-04).
- 13 currently-published Postmark webhook IPs are documented in `guides/webhooks.md` — NOT hardcoded (Postmark's own docs warn they can change). Source: https://postmarkapp.com/support/article/800-ips-for-firewalls

### Pattern 4: CachingBodyReader with iodata accumulation (D-09 — verified against Plug 1.19.1)

**What:** Custom `:body_reader` MFA module that accumulates raw body across `{:more, _, _}` chunks (required for SendGrid batches up to 128 events).

**Plug 1.19.1 contract** [VERIFIED: HexDocs Plug.Parsers]:
```
:body_reader — {Module, :function, [args]}; defaults to {Plug.Conn, :read_body, []}
Receives (conn, opts); returns {:ok, body, conn} | {:more, body, conn} | {:error, reason}
opts contains :read_length and :read_timeout matching Plug.Conn.read_body/2
```

**Implementation (D-09 verbatim):**
```elixir
defmodule Mailglass.Webhook.CachingBodyReader do
  @moduledoc """
  Custom Plug.Parsers `:body_reader` that preserves raw request bytes
  in `conn.private[:raw_body]` for HMAC verification while still
  allowing JSON parsing downstream.

  Accumulates iodata across `{:more, _, _}` chunks and flattens on
  final `{:ok, _, _}` — required for SendGrid batch payloads up to
  128 events (~3 MB). Plug.Parsers should be configured with
  `length: 10_000_000` (10 MB cap; 2 MB headroom over default 8 MB).

  ## Footgun: Plug.Parsers.MULTIPART does NOT honor :body_reader
  (Plug issue #884). Mailglass providers POST JSON, so this is
  irrelevant for the library — but adopters adding `:multipart` to
  the same parsers config will silently bypass this reader. Documented
  in guides/webhooks.md.
  """
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        raw = IO.iodata_to_binary([conn.private[:raw_body] || <<>>, body])
        {:ok, body, Plug.Conn.put_private(conn, :raw_body, raw)}

      {:more, body, conn} ->
        raw = [conn.private[:raw_body] || <<>>, body]
        {:more, body, Plug.Conn.put_private(conn, :raw_body, raw)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

**Storage location:** `conn.private[:raw_body]` (library-reserved, off the adopter `assigns` contract; matches lattice_stripe convention).

**Adopter-side wiring** (documented in `guides/webhooks.md`):
```elixir
# my_app_web/endpoint.ex
plug Plug.Parsers,
  parsers: [:json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
  length: 10_000_000
```

### Pattern 5: Webhook ingest one-Multi composition (D-15 + amended HOOK-06)

**What:** Single `Repo.transact/1` block wraps `Repo.multi(multi)` (matches Phase 3 D-20 pattern). Multi composes: webhook_events insert → N events.append_multi → projector updates → status flip. PubSub broadcast happens AFTER the transact block returns `{:ok, _}` (D-04 invariant).

**Critical: `transact/1` vs `multi/1` — both are needed.** Phase 2 added `Repo.transact/1` (Ecto 3.13+ tuple-rollback semantics). Phase 3 added `Repo.multi/1` as a public Ecto.Multi runner. The Webhook ingest pattern is `Repo.transact(fn -> Repo.multi(multi) end)` because:
- `Repo.transact/1` provides SQLSTATE 45A01 translation (rescues `Postgrex.Error`).
- `Repo.multi/1` handles the canonical Multi 4-tuple `{:error, step, reason, changes}` → `{:error, _}` collapse.
- Composition: `Repo.transact(fn -> case Repo.multi(multi) do {:ok, c} -> {:ok, c}; {:error, _, r, _} -> {:error, r} end end)`.

**Statement timeout / lock timeout (D-29):**
```elixir
# Inside the transact block, BEFORE Repo.multi(multi):
Mailglass.Repo.query!("SET LOCAL statement_timeout = '2s'", [])
Mailglass.Repo.query!("SET LOCAL lock_timeout = '500ms'", [])
```
**Note:** `Mailglass.Repo` does not currently expose `query!/2`. Plan for `Wave 0` task: add `query!/2` passthrough delegate (one-line addition; no SQLSTATE translation needed because raw query). Alternatively, `Application.get_env(:mailglass, :repo).query!/2` works directly inside the transact closure — but using the facade keeps the rescue clause discoverable.

**Multi step ordering (D-15 amended HOOK-06):**
```elixir
defmodule Mailglass.Webhook.Ingest do
  alias Ecto.Multi
  alias Mailglass.{Events, Repo}
  alias Mailglass.Outbound.Projector

  @spec ingest_multi(atom(), binary(), [%Events.Event{}]) ::
          {:ok, map()} | {:error, term()}
  def ingest_multi(provider, raw_body, [_ | _] = events) do
    Repo.transact(fn ->
      _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
      _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

      multi =
        Multi.new()
        # Step 1: webhook_events insert (UNIQUE = replay no-op)
        |> Multi.insert(:webhook_event, webhook_event_changeset(provider, raw_body, events),
            on_conflict: :nothing,
            conflict_target: [:provider, :provider_event_id])
        # Step 2..N+1: events.append_multi for each event (function form)
        |> append_events_for_each(events)
        # Step N+2..2N+1: projector updates for each event with matched delivery
        |> update_projections_for_each(events)
        # Step 2N+2: flip webhook_events.status :processing -> :succeeded
        # NOTE: webhook_events is NOT append-only (no trigger), so UPDATE is allowed
        |> Multi.update_all(:flip_status, ..., set: [status: :succeeded])

      case Repo.multi(multi) do
        {:ok, changes} -> {:ok, changes}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end)
  end
end
```

**After commit:** the plug iterates the events that had matched deliveries and calls `Projector.broadcast_delivery_updated/3` for each. Broadcast failure is non-fatal (already handled inside `safe_broadcast/2` per `lib/mailglass/outbound/projector.ex:180-204`).

### Pattern 6: Append-based reconciliation (D-18)

**What:** When the orphan event later finds its Delivery, the worker INSERTS a new `:reconciled` event — never UPDATEs the orphan row.

**Why this is structural, not policy:** The `mailglass_events_immutable_trigger` (Plan 02-02 verbatim) raises SQLSTATE 45A01 on UPDATE/DELETE. Trying to back-fill `delivery_id` on the orphan row would raise. Appending a new `:reconciled` event preserves the append-only invariant without any trigger carve-out.

**`:reconciled` event extension to D-14:** Currently `Mailglass.Events.Event` declares `@anymail_event_types` + `@mailglass_internal_types = [:dispatched, :suppressed]` (lib/mailglass/events/event.ex:56). **Phase 4 must extend `@mailglass_internal_types` to `[:dispatched, :suppressed, :reconciled]`.** This is an additive Ecto.Enum change — verify with the planner that adding to a closed atom set requires a migration only if the column type is `Ecto.Enum`-backed (it is `:text` at the DB level per V01:73 → no DB migration needed; only `lib/mailglass/events/event.ex` schema changes).

**Reconciler worker shape (matches Phase 2-05 SUMMARY hint + Phase 3 D-17 boot-warning pattern):**
```elixir
# lib/mailglass/webhook/reconciler.ex — conditionally compiled
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Reconciler do
    use Oban.Worker, queue: :mailglass_reconcile, unique: [period: 60]

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      tenant_id = Map.get(args, "tenant_id")
      orphans = Mailglass.Events.Reconciler.find_orphans(
        tenant_id: tenant_id,
        limit: 1000,
        max_age_minutes: 7 * 24 * 60
      )

      Enum.reduce_while(orphans, {:ok, 0}, fn orphan, {:ok, n} ->
        case attempt_reconcile(orphan) do
          {:ok, _} -> {:cont, {:ok, n + 1}}
          {:error, :no_match} -> {:cont, {:ok, n}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end

    defp attempt_reconcile(orphan) do
      case Mailglass.Events.Reconciler.attempt_link(orphan) do
        {:ok, {delivery, _orphan}} ->
          # D-18: APPEND a :reconciled event; do NOT update the orphan row
          Mailglass.Repo.transact(fn ->
            Ecto.Multi.new()
            |> Mailglass.Events.append_multi(:reconciled_event, %{
                 type: :reconciled,
                 delivery_id: delivery.id,
                 tenant_id: delivery.tenant_id,
                 metadata: %{
                   reconciled_from_event_id: orphan.id,
                   reconciled_provider: extract_provider(orphan),
                   reconciled_provider_event_id: extract_provider_event_id(orphan)
                 },
                 idempotency_key: "reconciled:#{orphan.id}"
               })
            |> Ecto.Multi.update(:projector, fn %{reconciled_event: e} ->
                 Mailglass.Outbound.Projector.update_projections(delivery, e)
               end)
            |> Mailglass.Repo.multi()
          end)

        {:error, :delivery_not_found} -> {:error, :no_match}
        {:error, _} = err -> err
      end
    end
  end
end
```

**Cron registration:** `{Oban, plugins: [{Oban.Plugins.Cron, crontab: [{"*/5 * * * *", Mailglass.Webhook.Reconciler}]}]}` — but adopters wire this into THEIR Oban config; mailglass documents the cron entry in `guides/webhooks.md`. (Per CLAUDE.md "no `name: __MODULE__` singletons in library code" + Phase 1 OptionalDeps pattern — mailglass does not start its own Oban supervisor.)

### Anti-Patterns to Avoid

- **Calling `Swoosh.Mailer.deliver/1` from webhook code:** Phase 4 writes events ONLY; never sends mail. CLAUDE.md "Don't put PII in telemetry metadata" + "webhook plug = single ingress" both already rule this out.
- **`Repo.update(orphan_event, ...)` to back-fill `delivery_id`:** SQLSTATE 45A01 raises (`Mailglass.EventLedgerImmutableError`). Use append-based reconciliation (D-18).
- **Putting `:to`, `:from`, `:subject`, `:body`, `:headers`, `:recipient`, `:email`, OR `:ip` in telemetry metadata:** D-23 whitelist + LINT-02 (Phase 6) catch this. IP is excluded specifically — adopters extract it from their own handler chain.
- **Pattern-matching `Mailglass.SignatureError` by message string:** Use the struct + `:type` atom. The atom set is closed (`signature_error.ex:27` extended to 7 values per D-21).
- **Catch-all `_ -> :hard_bounce`** in provider mappers: D-05 + Phase 6 `EventTaxonomyIsVerbatim` Credo check (D-23, D-28). Unmapped → `Logger.warning` + `:unknown` only.
- **Reading `conn.body_params` for HMAC:** the parser has already deconstructed JSON. Read `conn.private[:raw_body]` (set by CachingBodyReader BEFORE parsing).
- **`name: __MODULE__` GenServers:** Phase 4 adds NO new supervised processes (D-20 + integration-points note). Reconciler + Pruner are Oban workers; Plug is request-process.
- **Cross-Application.put_env in tests:** `WebhookCase` uses `async: false` for global Postmark config; per-test config goes through plug opts, not `Application.put_env`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Constant-time string compare for Basic Auth | `==/2` or `match?/2` | `Plug.Crypto.secure_compare/2` | Timing-attack safe; already in deps via Plug 1.19.1 transitive |
| Base64 / DER / ECDSA crypto | hand-rolled | `Base.decode64!/1` + `:public_key.der_decode/2` + `:public_key.verify/4` (OTP 27 stdlib) | Crypto is hard; `:public_key` battle-tested since OTP R14 |
| Webhook idempotency / replay protection | manual select-then-insert | UNIQUE partial index + `on_conflict: :nothing` (Postgres) | Race-free; Phase 2 already shipped the pattern with verbatim conflict_target fragment |
| Periodic cron scheduling | `Process.send_after/3` GenServer loop | `Oban.Plugins.Cron` (free Oban) + `Logger.warning` boot fallback | Phase 3 D-17 verbatim pattern; cron in OSS Oban 2.21 — no Pro needed [VERIFIED: hexdocs.pm/oban] |
| Append-only invariant enforcement | application checks | DB trigger raising SQLSTATE 45A01 (Phase 2 V01 shipped) | Belt-and-suspenders; trigger fires for every UPDATE/DELETE attempt regardless of code path |
| Multi 4-tuple → 2-tuple collapse | hand-rolled | `case Repo.multi(multi) do {:ok, c} -> {:ok, c}; {:error, _, r, _} -> {:error, r} end` (Phase 3 pattern) | Phase 3 already standardized this; Phase 4 reuses verbatim |
| JSON body parsing | hand-rolled | `Jason.decode!/1` (already required) | Plug.Parsers does it for us; raw body is what we KEEP via CachingBodyReader |
| Custom error structs | new `defexception` | extend `%SignatureError{}` + `%TenancyError{}` + `%ConfigError{}` atom sets | Phase 1 D-09 hierarchy; D-21 + D-14 + D-21 rationale extend in-place |
| Telemetry handler raise-isolation | try/rescue per emit | `:telemetry.span/3` (already wrapped by `Mailglass.Telemetry.span/3`) | Phase 1 D-27 invariant — handlers that raise are detached automatically |
| Tenancy plumbing across Oban job boundary | manual put_current/get_current | `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` (Phase 2 shipped) | Already conditionally compiled; Reconciler + Pruner workers use it |

**Key insight:** Phase 4 is **almost entirely composition** of Phase 1–3 primitives. The new code is the Provider behaviour + 2 impls + Plug + Router macro + CachingBodyReader + Ingest module + 2 Oban workers + tenancy callback extension + 1 migration + telemetry helpers + 3 error atom-set extensions. Every other piece is already shipped and battle-tested.

## Runtime State Inventory

> Phase 4 is greenfield from the runtime-state perspective (no rename / refactor / migration of existing identifiers). The only operational state changes are NEW DB tables + NEW Oban cron registrations.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | NEW table `mailglass_webhook_events` (D-15 V02 migration); existing `mailglass_events.raw_payload` column DROPPED in V02 (verified nullable in V01:77, no shipped writes target it) | Adopters run `mix ecto.migrate` after upgrading mailglass; column drop is destructive but no shipped code reads it |
| Live service config | NEW Oban cron entries: `Mailglass.Webhook.Reconciler` (`*/5 * * * *`) + `Mailglass.Webhook.Pruner` (daily) — adopters wire into THEIR `Oban` config; mailglass does not start its own Oban supervisor | Documented in `guides/webhooks.md`; installer (Phase 7) emits the cron block |
| OS-registered state | None — webhook plug is in-process; no OS-registered tasks or daemons | None |
| Secrets / env vars | NEW config keys: `:mailglass, :postmark, basic_auth: {user, pass}` + optional `:ip_allowlist`; `:mailglass, :sendgrid, public_key:` (base64 DER); `:mailglass, :webhook_retention, succeeded_days:` etc. — all per-adopter, never bundled | Documented in `guides/webhooks.md`; `Mailglass.Config` schema extends additively |
| Build artifacts / installed packages | None — no NIFs, no compiled assets | None |

**Nothing found in OS-registered state or build artifacts** — verified by absence of `extra_applications` changes (except adding `:public_key`) and no NIF/asset Wave tasks. The DDL change (V02 dropping `mailglass_events.raw_payload`) IS destructive but verified safe: `lib/mailglass/migrations/postgres/v01.ex:77` shows `add(:raw_payload, :map)` (nullable, no `null: false`); `lib/mailglass/events/event.ex:84` declares `field(:raw_payload, :map)` (no `:default`); shipped writers do not populate it (verified via Plan 02-05 SUMMARY).

## Common Pitfalls

### Pitfall 1: Using `:public_key.pem_decode/1` for SendGrid public key

**What goes wrong:** `pem_decode/1` returns `[]` or raises because SendGrid ships base64 DER (no `-----BEGIN PUBLIC KEY-----` framing). All signature verifies fail; tests pass against re-PEM-wrapped fixtures but production fails.

**Why it happens:** Most "verify ECDSA in Elixir" tutorials assume PEM input from `cert.pem` files.

**How to avoid:** Use `:public_key.der_decode(:SubjectPublicKeyInfo, Base.decode64!(b64))` per D-03 verbatim. The pattern is non-negotiable.

**Warning signs:** `case` clause never matches `{:SubjectPublicKeyInfo, _, _}`; tests pass with PEM input but the fixture is the wrong shape.

### Pitfall 2: `body_reader` not invoked because `Plug.Parsers` runs after the parser short-circuits

**What goes wrong:** Adopter wires `Plug.Parsers` AFTER `Plug.Static` or AFTER a controller-level catch — the body is consumed before the custom reader runs. `conn.private[:raw_body]` is empty; signature verify fails with `:bad_signature`.

**Why it happens:** Plug pipeline ordering is implicit — adopters often add `Plug.Parsers` AFTER routing rather than at the endpoint level.

**How to avoid:** Document explicitly in `guides/webhooks.md`: `Plug.Parsers` MUST be in `endpoint.ex`, BEFORE `plug MyAppWeb.Router`. The CachingBodyReader is part of the `:body_reader` MFA, NOT a separate plug. The installer (Phase 7) emits the correct snippet.

**Warning signs:** Tests with `Plug.Test.conn(:post, ..., payload)` work (because `Plug.Conn.read_body/2` is implicit) but production `conn.private[:raw_body]` is `nil`.

### Pitfall 3: `Plug.Parsers.MULTIPART` does NOT honor `:body_reader` (Plug issue #884)

**What goes wrong:** Adopter adds `:multipart` to the `Plug.Parsers` config (e.g., for file upload routes) — multipart requests bypass the CachingBodyReader entirely. Currently irrelevant because Postmark + SendGrid POST JSON, but v0.5 SES SNS subscription confirmation (separate JSON) and `mailglass_inbound` (multipart MIME) hit this.

**Why it happens:** Multipart streaming uses `Plug.Conn` directly — `:body_reader` was never wired in.

**How to avoid:** Documented footgun in `guides/webhooks.md` per D-09. v0.5 inbound work will need a separate solution (probably a controller-level raw-MIME read).

**Warning signs:** Multipart webhooks fail signature verify; JSON webhooks pass.

### Pitfall 4: Inserting orphan event with `delivery_id: nil` succeeds, but `Projector.update_projections/2` requires a non-nil `%Delivery{}`

**What goes wrong:** The Multi step that calls `Projector.update_projections(delivery, event)` cannot run for orphans — there's no delivery. If the Multi step is unconditional, it fails with `FunctionClauseError`.

**Why it happens:** `Projector.update_projections/2` pattern-matches `%Delivery{}` (lib/mailglass/outbound/projector.ex:59).

**How to avoid:** The Ingest Multi must conditionally compose projector steps. Pattern:
```elixir
events_with_deliveries
|> Enum.reduce(multi, fn {event, delivery}, acc ->
     Multi.update(acc, {:projector, event.id}, fn changes ->
       Projector.update_projections(delivery, Map.fetch!(changes, {:event, event.id}))
     end)
   end)
# Orphan events skip the projector step entirely
```

**Warning signs:** Test with orphan webhook event raises `FunctionClauseError`; non-orphan tests pass.

### Pitfall 5: Telemetry metadata containing `conn.remote_ip` triggers Phase 6 LINT-02 + GDPR ambiguity

**What goes wrong:** Naturally tempting to put `ip: conn.remote_ip` in `[:mailglass, :webhook, :signature, :verify, :stop]` metadata for forensics. D-23 EXPLICITLY excludes IP. Phase 6's `NoPiiInTelemetryMeta` Credo check would flag (or should be extended to flag IP).

**Why it happens:** "It's just an IP, not really PII."

**How to avoid:** D-23 whitelist enforces metadata = only atoms / booleans / non-neg integers / opaque IDs. IP for abuse investigation is adopter-extensible — they attach their own handler on `[:mailglass, :webhook, :signature, :verify, :stop]` with `status: :failed` and pull `conn.remote_ip` from their own plug lineage.

**Warning signs:** Credo strict mode flags the metadata; if it doesn't, propose extending `NoPiiInTelemetryMeta` to include `:ip`, `:user_agent`, `:remote_ip`.

### Pitfall 6: `SET LOCAL statement_timeout` outside a transaction is a no-op

**What goes wrong:** `SET LOCAL` only affects the current transaction. Calling it outside `Repo.transact/1` silently does nothing; the configured timeouts don't apply.

**Why it happens:** Missing the "LOCAL" keyword effect.

**How to avoid:** Always call inside the `transact/1` closure, BEFORE the `Repo.multi(multi)` call. Verify with a test that runs a slow `pg_sleep(3.0)` and asserts `statement_timeout` fires.

**Warning signs:** Webhook ingest under load → unbounded query latency; provider retry storm builds.

### Pitfall 7: `Mailglass.Tenancy.put_current/1` leaks across requests in a long-lived process

**What goes wrong:** The Plug puts tenant_id in process dict and forgets to clean up. The next request on the same process sees the previous tenant.

**Why it happens:** Cowboy/Bandit pool processes are reused across requests.

**How to avoid:** Use `Mailglass.Tenancy.with_tenant/2` (block form, restores prior on exit) — NOT `put_current/1` directly. The plug should be:
```elixir
Mailglass.Tenancy.with_tenant(tenant_id, fn ->
  events = Provider.normalize(raw_body, headers)
  Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events)
end)
```

**Warning signs:** Multi-tenant property test (D-27) shows cross-tenant event leakage; verifiable by alternating tenants in a sequence.

### Pitfall 8: Adding `:reconciled` to `@anymail_event_types` instead of `@mailglass_internal_types`

**What goes wrong:** Per PROJECT D-14 amendment in CONTEXT spec_lock: "Anymail event taxonomy verbatim for provider-sourced webhook events; mailglass reserves one additional lifecycle event `:reconciled`...". `:reconciled` is mailglass-internal, NOT Anymail. Putting it in the wrong list breaks the "provider events are verbatim Anymail" invariant + Credo check.

**Why it happens:** Both lists merge into `@event_types` so the Ecto.Enum works either way at runtime — but the semantic distinction matters for Phase 6 LINT.

**How to avoid:** Add to `@mailglass_internal_types` (lib/mailglass/events/event.ex:56). Verify with a unit test asserting `:reconciled in Mailglass.Events.Event.__internal_types__()` (or equivalent reflector).

**Warning signs:** Phase 6 `EventTaxonomyIsVerbatim` Credo check flags `:reconciled` as a non-verbatim Anymail value.

### Pitfall 9: SendGrid timestamp tolerance comparison uses `DateTime.diff/2` on a string timestamp

**What goes wrong:** SendGrid sends timestamp as a string (e.g., `"1610142000"`). `DateTime.diff/2` requires `%DateTime{}`. Direct comparison fails or compares string sort.

**Why it happens:** Easy parsing oversight; tests pass with int timestamps, production fails with string.

**How to avoid:** `String.to_integer(timestamp_header) |> DateTime.from_unix!()` then compare with `Mailglass.Clock.utc_now/0`. Tolerance = 300s. Use `Mailglass.Clock.Frozen.advance/1` in tests to verify boundary cases.

**Warning signs:** All SendGrid tests pass with synthetic timestamps; first real SendGrid webhook fails verify with `:timestamp_skew`.

### Pitfall 10: Test fixtures stored as static JSON files break when the test signs them with a fresh test keypair

**What goes wrong:** Fixture has a baked-in signature header from SendGrid's actual production key (impossible to regenerate without access). Test signing key generates a different signature; fixture verifies-fail in tests.

**Why it happens:** Naive "save the real webhook payload" fixture approach.

**How to avoid:** Store ONLY the JSON body as fixtures. The `webhook_fixtures.ex` helper (D-26) re-signs each fixture with a test ECDSA P-256 keypair generated via `:public_key.generate_key({:namedCurve, :secp256r1})` at test suite start. Postmark fixtures need only Basic Auth header injection (test credentials).

**Warning signs:** Tests pass on first import of a fixture; subsequent runs fail because the signature is non-deterministic (ECDSA uses random k each sign).

## Code Examples

### Mint a test ECDSA P-256 keypair (for SendGrid signature tests)

```elixir
# test/support/webhook_fixtures.ex (Wave 0)
defmodule Mailglass.WebhookFixtures do
  @moduledoc """
  Test ECDSA P-256 keypair generation + payload signing for
  SendGrid webhook fixture re-signing. Avoids dependency on real
  SendGrid private keys.
  """

  @doc "Generate fresh ECDSA P-256 keypair. Returns {:public_key_b64_der, :private_key}."
  def generate_sendgrid_keypair do
    {pub_key, priv_key} = :crypto.generate_key(:ecdh, :secp256r1)
    # Wrap into the SubjectPublicKeyInfo DER + base64 form SendGrid would deliver
    spki_der = :public_key.der_encode(:SubjectPublicKeyInfo, build_spki(pub_key))
    {Base.encode64(spki_der), priv_key}
  end

  @doc "Sign payload with private key; returns base64 ECDSA signature."
  def sign_sendgrid_payload(timestamp, raw_body, priv_key) do
    payload = timestamp <> raw_body
    sig = :public_key.sign(payload, :sha256, {:ECPrivateKey, priv_key, build_ec_params()})
    Base.encode64(sig)
  end

  # Helpers building SubjectPublicKeyInfo + EC params per OTP 27 :public_key
  # ... (see Pattern 2 inverse construction)
end
```

**Source:** Synthesized from D-03 + Pattern 2 above + verified against erlang.org/docs/27/apps/public_key.

### `Mailglass.Webhook.Plug.call/2` skeleton (pseudocode)

```elixir
defmodule Mailglass.Webhook.Plug do
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    provider = Keyword.fetch!(opts, :provider)  # :postmark | :sendgrid
    config = resolve_config!(provider, opts)

    {raw_body, headers} = extract_headers_and_raw_body(conn)

    Mailglass.Webhook.Telemetry.ingest_span(
      %{provider: provider, status: :pending},
      fn ->
        try do
          provider_module(provider).verify!(raw_body, headers, config)

          tenant_id =
            case Mailglass.Tenancy.resolve_webhook_tenant(%{
                   provider: provider,
                   conn: conn,
                   raw_body: raw_body,
                   headers: headers,
                   path_params: conn.path_params,
                   verified_payload: nil
                 }) do
              {:ok, tid} -> tid
              {:error, reason} ->
                raise Mailglass.TenancyError.new(:webhook_tenant_unresolved,
                        context: %{provider: provider, reason: reason})
            end

          Mailglass.Tenancy.with_tenant(tenant_id, fn ->
            events = provider_module(provider).normalize(raw_body, headers)

            case Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events) do
              {:ok, _changes} ->
                # Post-commit: broadcast per matched delivery
                broadcast_post_commit(events)
                {Plug.Conn.send_resp(conn, 200, ""), %{status: :ok}}

              {:error, reason} ->
                Logger.error("[mailglass] webhook ingest failed: #{inspect(reason)}")
                {Plug.Conn.send_resp(conn, 500, ""), %{status: :ingest_failed}}
            end
          end)
        rescue
          e in Mailglass.SignatureError ->
            Logger.warning(
              "Webhook signature failed: provider=#{provider} reason=#{e.type}"
            )
            {Plug.Conn.send_resp(conn, 401, ""), %{status: :signature_failed}}

          e in Mailglass.TenancyError ->
            {Plug.Conn.send_resp(conn, 422, ""), %{status: :tenant_unresolved}}

          e in Mailglass.ConfigError ->
            Logger.error("[mailglass] webhook config error: #{Exception.message(e)}")
            {Plug.Conn.send_resp(conn, 500, ""), %{status: :config_error}}
        end
      end
    )
  end

  defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
  defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
end
```

**Source:** Synthesized from D-10 + D-13 + D-14 + D-21 + D-22 + accrue/lattice_stripe prior-art per CONTEXT canonical_refs.

### Router macro (D-06, matching LiveDashboard idiom)

```elixir
defmodule Mailglass.Webhook.Router do
  @moduledoc """
  Router macro for mounting Mailglass webhook endpoints. Match
  `Phoenix.LiveDashboard.Router.live_dashboard/2` + `Oban.Web.Router.oban_dashboard/2`.

  ## Usage

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import Mailglass.Webhook.Router

        pipeline :mailglass_webhooks do
          plug :accepts, ["json"]
        end

        scope "/", MyAppWeb do
          pipe_through :mailglass_webhooks
          mailglass_webhook_routes "/webhooks"
        end
      end
  """

  defmacro mailglass_webhook_routes(path, opts \\ []) do
    providers = Keyword.get(opts, :providers, [:postmark, :sendgrid])
    as = Keyword.get(opts, :as, :mailglass_webhook)

    quote bind_quoted: [path: path, providers: providers, as: as] do
      for provider <- providers do
        post "#{path}/#{provider}",
          Mailglass.Webhook.Plug,
          [provider: provider],
          as: :"#{as}_#{provider}"
      end
    end
  end
end
```

**Source:** D-06 + D-08 (shared vocabulary with Phase 5 admin) + LiveDashboard precedent.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single-callback `validate_request` (django-anymail single function) | Two-callback split: `verify!/3` + `normalize/2` (D-01) | Phase 4 ships sealed | Cleaner separation: crypto vs taxonomy. Fixtures need only test signing keys; normalize is pure. |
| `:public_key.pem_decode/1` for ECDSA keys | `:public_key.der_decode/2` for SendGrid SubjectPublicKeyInfo | OTP 27, but applicable since OTP R14 | Avoids the "PEM not parsing" silent verify-fail. SendGrid specifically. |
| Direct `Plug.Crypto` dep | Transitive via Plug 1.19.1 | Plug ≥ 1.5.1 | No new dep needed; already in mix.lock 2.1.1 |
| UPDATE event row to back-fill `delivery_id` | Append `:reconciled` event (D-18) | Phase 4 ships | Preserves append-only invariant structurally; SQLSTATE 45A01 trigger never fires |
| `Repo.transaction/1` (deprecated tuple semantics) | `Repo.transact/1` (Ecto 3.13+ tuple-rollback) + `Repo.multi/1` (canonical Multi shape) | Phase 2 + Phase 3 | Composition pattern: `transact(fn -> case multi(m) do ... end end)` |
| Hand-rolled cron loop via `Process.send_after/3` | `Oban.Plugins.Cron` (free Oban) + `Logger.warning` boot fallback | Phase 4 D-17/D-20 (Phase 3 D-17 precedent) | Crash recovery, backoff, telemetry — for free. Fallback honest about not being durable. |
| Storing raw_payload on `mailglass_events` (with trigger carve-out) | Split into `mailglass_webhook_events` (mutable, prunable) | Phase 4 D-15 (V02 migration) | Append-only ledger stays pristine; GDPR erasure is targeted DELETE on the mutable table |

**Deprecated/outdated:**
- `Repo.transaction/1` 4-tuple error returns: Phase 2 standardized on `transact/1` 2-tuple. Phase 4 follows.
- Mailgun-style HMAC-SHA256 over `(timestamp + token)` — v0.5 forward-compat; not Phase 4 scope.
- AMP for Email — Cloudflare sunsetted Oct 20, 2025 (PROJECT D-03 references). Not in scope.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | OTP 27 `:public_key.der_decode(:SubjectPublicKeyInfo, ...)` returns the exact 3-tuple shape `{:SubjectPublicKeyInfo, alg_id, pk_bits}` documented in D-03 | Pattern 2 / SendGrid verification | LOW — Erlang public_key API stable since R14; OTP 27 docs confirm shape. Verify via `:erlang.system_info(:otp_release)` + smoke test in Wave 0. |
| A2 | SendGrid documents 300-second timestamp tolerance is the right window | D-03 | LOW — SendGrid does NOT document; Stripe/Svix/Standard-Webhooks consensus is 300s; CONTEXT D-03 locks 300s. Adopters can override via config. |
| A3 | Postmark currently publishes 13 webhook IPs (D-04) | Pattern 3 | LOW — count may shift; documentation in `guides/webhooks.md` (NOT hardcoded) is the mitigation. |
| A4 | `Mailglass.Repo` needs a public `query!/2` for `SET LOCAL statement_timeout` | Pattern 5 | LOW-MEDIUM — alternative is `Application.get_env(:mailglass, :repo).query!/2` direct. Wave 0 task: add `query!/2` passthrough delegate to facade for consistency. |
| A5 | `:public_key` is NOT in `extra_applications` (mix.exs:30) and must be added | Standard Stack | HIGH if not addressed — release strips OTP app; SendGrid verification fails with `:undef` in production. **Plan 1 Wave 0 must include this mix.exs edit.** |
| A6 | Adding `:reconciled` to `@mailglass_internal_types` does not require a DB migration | Pitfall 8 | LOW — V01:73 stores `type` as `:text`; Ecto.Enum is application-side validation. Verify with a "migrate down then up" test if planner is paranoid. |
| A7 | `Plug.Parsers` invokes the `:body_reader` MFA BEFORE JSON parsing, exactly once per request | Pattern 4 | LOW — Plug 1.19.1 docs confirm contract stable since 1.5.1 (PR #698). Tested behavior: chunked uploads return `{:more, _, _}` cycle until final `{:ok, _, _}`. |
| A8 | OSS Oban 2.21 `Oban.Plugins.Cron` supports `*/5` cron syntax without Pro | Pattern 6 / Reconciler | LOW — Cron is in OSS Oban since 2.0 (free). Confirmed via hexdocs.pm/oban (no Pro tag on Plugins.Cron). |
| A9 | `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` works correctly when called outside the transact block (i.e., post-commit from the plug) | Pattern 5 / step 6 | LOW — function is `:rescue/catch :exit`-wrapped (lib/mailglass/outbound/projector.ex:180-204); `Repo.transact` returns `{:ok, _}` BEFORE broadcast runs. |
| A10 | `Mailglass.Tenancy` can have `@optional_callbacks resolve_webhook_tenant: 1` ADDED without breaking existing adopter modules implementing `@behaviour Mailglass.Tenancy` | D-12 / Tenancy extension | LOW — `@optional_callbacks` is non-breaking by Elixir's behaviour spec; adopters not implementing it are unaffected. SingleTenant gains a default impl. |

**Action for planner:** Items A4 + A5 are concrete Wave 0 tasks (file edits to `lib/mailglass/repo.ex` + `mix.exs`) that must NOT be skipped. Item A1 should have a smoke test in Wave 0 (a `setup_all` in `sendgrid_test.exs` that exercises the DER-decode chain on a freshly-generated keypair).

## Open Questions (RESOLVED)

All three open questions flagged in ROADMAP for `/gsd-research-phase` are RESOLVED:

1. **SendGrid ECDSA verification API on OTP 27 `:crypto`.** ✅ Resolved by D-03 — uses `:public_key.der_decode/2` (NOT `:pem_decode/1`); curve prime256v1; verified against erlang.org/docs/27 + Twilio docs.
2. **`CachingBodyReader` + Plug 1.18 chain interaction.** ✅ Resolved by D-09 — `:body_reader` MFA stable since Plug 1.5.1 (PR #698), Plug 1.19.1 in mix.lock; iodata accumulation across `{:more, _, _}`; multipart caveat documented.
3. **Orphan reconciliation worker scope and cadence.** ✅ Resolved by D-17 — `*/5 * * * *` cron, 60s age threshold, 1000 rows/tick, 7-day max age (matches accrue verbatim).

**Remaining minor open question:** the exact NimbleOptions schema keys for `:postmark` and `:sendgrid` config subtrees. CONTEXT marks this as "Claude's Discretion." Recommendation:

```elixir
postmark: [
  enabled: [type: :boolean, default: true],
  basic_auth: [type: {:tuple, [:string, :string]}, required: false],
  ip_allowlist: [type: {:list, :string}, default: []]   # CIDR notation
],
sendgrid: [
  enabled: [type: :boolean, default: true],
  public_key: [type: {:or, [:string, nil]}, default: nil],  # base64 DER
  timestamp_tolerance_seconds: [type: :pos_integer, default: 300]
],
webhook_retention: [
  succeeded_days: [type: {:or, [:pos_integer, {:in, [:infinity]}]}, default: 14],
  dead_days: [type: {:or, [:pos_integer, {:in, [:infinity]}]}, default: 90],
  failed_days: [type: {:or, [:pos_integer, {:in, [:infinity]}]}, default: :infinity]
],
webhook_ingest_mode: [type: {:in, [:sync, :async]}, default: :sync]
```

Planner can finalize during Plan 1 (Wave 0).

## Environment Availability

> Phase 4 has no NEW external dependencies. All required tools are already in the project (Phase 1-3 verified working).

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Erlang OTP | Entire phase | ✓ | 27.x (mix.exs `~> 1.18` Elixir requires OTP 26+; CI verified per CI-02 STATE) | — |
| `:public_key` (OTP stdlib) | SendGrid ECDSA verify | ✓ | OTP 27 stdlib | — (must be added to `extra_applications` per A5) |
| `:crypto` (OTP stdlib) | All HMAC + key generation | ✓ | OTP 27 stdlib | Already in `extra_applications: [:crypto]` (mix.exs:30) |
| `plug_crypto` | `secure_compare/2` for Postmark | ✓ | 2.1.1 (mix.lock confirmed transitive via Plug 1.19.1) | — |
| Postgres | DDL trigger + UNIQUE partial index + `mailglass_webhook_events` table | ✓ | 15+ (Phase 2 verified) | — (PROJECT-level Postgres-only at v0.1) |
| Oban (optional) | Reconciler + Pruner cron | ✓ if adopter has it | 2.21+ optional dep declared | `Logger.warning` boot fallback + `mix mailglass.reconcile` mix task per D-20 |
| `stream_data` | HOOK-07 1000-replay property + signature/tenant property tests | ✓ test-only | 1.3 | — |

**No missing dependencies.** Environment is fully provisioned.

## Project Constraints (from CLAUDE.md)

These directives are LAW for Phase 4 plans. Treat with same authority as locked CONTEXT decisions:

1. **Don't use `Application.compile_env*` outside `Mailglass.Config`.** All Phase 4 config (`:postmark`, `:sendgrid`, `:webhook_retention`, `:webhook_ingest_mode`) extends `Mailglass.Config` schema; runtime reads via `Application.get_env/2`.
2. **Don't UPDATE or DELETE `mailglass_events` rows.** Reconciliation appends `:reconciled` event (D-18); never back-fills `delivery_id`. Mutable retention work happens on `mailglass_webhook_events` (NEW, no trigger).
3. **Don't put PII in telemetry metadata.** D-23 whitelist enforces; Phase 6 LINT-02 catches at compile time. IP, user-agent, raw bytes all excluded.
4. **Don't call `Swoosh.Mailer.deliver/1` directly inside mailglass library code.** Phase 4 writes events ONLY; never sends mail. Auto-suppression deferred to v0.5 DELIV-02.
5. **Don't recover from webhook signature failures.** `%Mailglass.SignatureError{}` raises with no recovery path; plug rescues at ONE point + returns 401.
6. **Don't write to `mailglass_admin/priv/static/` without committing the rebuilt bundle.** N/A for Phase 4 (no admin assets).
7. **Don't pattern-match errors by message string.** Match `%SignatureError{type: t}` where `t in @types`; never `String.contains?(e.message, ...)`.
8. **Don't use `name: __MODULE__` to register singletons in library code.** Phase 4 adds NO supervised processes (Reconciler + Pruner are Oban-driven; Plug is request-process).
9. **Don't enable open/click tracking by default.** N/A for Phase 4.
10. **Don't ship marketing-email features here.** N/A for Phase 4.

**Additionally from CLAUDE.md "Engineering DNA":**
- Pluggable behaviours over magic — `Mailglass.Webhook.Provider` is sealed (`@moduledoc false`) per D-01 BUT lives behind a behaviour for v0.5 unsealing.
- Errors as a public API contract — `%SignatureError{}.type` closed atom set extends from 4 to 7 (D-21); documented in `docs/api_stability.md`.
- Telemetry on `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` — D-22 ships 5 webhook event paths matching this.
- Append-only `mailglass_events` — preserved structurally via `:reconciled` event (D-18).
- Multi-tenancy first-class — D-12 extends `Mailglass.Tenancy` with `resolve_webhook_tenant/1`.
- Custom Credo checks at lint time — Phase 6 will ship `EventTaxonomyIsVerbatim` (D-23, D-28); Phase 4 ships compliant code.
- Optional deps gated through `Mailglass.OptionalDeps.*` — Reconciler + Pruner conditionally compiled (D-20 + Phase 3 D-17 pattern).
- `mix compile --no-optional-deps --warnings-as-errors` MUST pass — verified by Phase 1+ CI lane.

## Validation Architecture

> Required per `workflow.nyquist_validation` (default enabled — no `false` setting found in `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (standard) + StreamData 1.3 (property-based) |
| Config file | `test/test_helper.exs` (Phase 2 wired migration runner; Phase 3 wired Mox + ObanHelpers) |
| Quick run command | `mix test test/mailglass/webhook/ --warnings-as-errors` |
| Phase property suite | `mix test test/mailglass/properties/ --warnings-as-errors` |
| Full suite | `mix test --warnings-as-errors` |
| Phase UAT gate | `mix verify.phase_04` (NEW alias — model after `verify.phase_03` in mix.exs:116) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOOK-01 | CachingBodyReader preserves raw bytes across `{:more, _}` chunks; iodata flattens on final `{:ok, _}` | unit + integration | `mix test test/mailglass/webhook/caching_body_reader_test.exs -x` | ❌ Wave 0 |
| HOOK-01 | Adopter wiring snippet from `guides/webhooks.md` works in test endpoint | integration | `mix test test/mailglass/webhook/plug_test.exs::"runs through endpoint+parsers" -x` | ❌ Wave 0 |
| HOOK-02 | Router macro generates 2 routes per `mailglass_webhook_routes/2` call; `:as` opt works | unit | `mix test test/mailglass/webhook/router_test.exs -x` | ❌ Wave 0 |
| HOOK-02 | Plug returns 200 OK on duplicate webhook (idempotency replay); returns 401 on forged signature; returns 422 on tenant-unresolved; returns 500 on config error | integration | `mix test test/mailglass/webhook/plug_test.exs::"http response code matrix" -x` | ❌ Wave 0 |
| HOOK-03 | Postmark Basic Auth + IP allowlist; `secure_compare/2` used; `Logger.warning` on missing trusted_proxies | unit + property | `mix test test/mailglass/webhook/providers/postmark_test.exs -x` + `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ Wave 0 |
| HOOK-04 | SendGrid ECDSA via `:public_key.der_decode/2` + `:public_key.verify/4`; 300s timestamp tolerance; pattern-match strictly on `true` | unit + property | `mix test test/mailglass/webhook/providers/sendgrid_test.exs -x` + `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ Wave 0 |
| HOOK-05 | All 14 Anymail event types + `:unknown` fallthrough with `Logger.warning`; no silent `_ -> :hard_bounce` | unit | `mix test test/mailglass/webhook/providers/postmark_test.exs::"event taxonomy mapping"` + sendgrid equivalent | ❌ Wave 0 |
| HOOK-05 | `reject_reason` closed atom set | unit | `mix test test/mailglass/webhook/providers/postmark_test.exs::"reject_reason mapping"` | ❌ Wave 0 |
| HOOK-06 | Ingest one-Multi: webhook_events insert + N events insert + Projector update + status flip; orphan path inserts events with `delivery_id: nil + needs_reconciliation: true`; PubSub broadcast post-commit | integration | `mix test test/mailglass/webhook/ingest_test.exs -x` | ❌ Wave 0 |
| HOOK-06 | `SET LOCAL statement_timeout = '2s'; lock_timeout = '500ms'` fires inside transact | integration | `mix test test/mailglass/webhook/ingest_test.exs::"statement_timeout fires under load"` (uses `pg_sleep(3.0)`) | ❌ Wave 0 |
| HOOK-07 | StreamData 1000-replay convergence property: any sequence of (webhook_event, replay_count 1..10) converges to single-application state | property (1000 runs) | `mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors` | ❌ Wave 0 |
| TEST-03 | Property: signature failure raises EXACTLY ONE of 7 `SignatureError.type` atoms; no partial DB writes | property | `mix test test/mailglass/properties/webhook_signature_failure_test.exs -x` | ❌ Wave 0 |
| TEST-03 | Property: tenant resolution via SingleTenant + ResolveFromPath stamps correctly; bad strategy raises `%TenancyError{type: :webhook_tenant_unresolved}` | property | `mix test test/mailglass/properties/webhook_tenant_resolution_test.exs -x` | ❌ Wave 0 |
| Reconciler | Orphan event + later Delivery commit → Reconciler appends `:reconciled` event within 5 min cron tick | integration | `mix test test/mailglass/webhook/reconciler_test.exs -x` | ❌ Wave 0 |
| Pruner | Daily cron deletes succeeded webhook_events older than retention | integration | `mix test test/mailglass/webhook/pruner_test.exs -x` | ❌ Wave 0 |
| Telemetry | All 5 webhook spans emit; metadata is whitelist-conformant (zero PII keys) | integration | `mix test test/mailglass/webhook/plug_test.exs::"telemetry events emitted"` + `test/mailglass/webhook/reconciler_test.exs::"reconcile span"` | ❌ Wave 0 |
| Phase UAT | Combined Phase 4 success criteria pass | integration (UAT) | `mix verify.phase_04` (NEW alias) | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/webhook/ --warnings-as-errors --exclude flaky` (~5-15s typical)
- **Per wave merge:** `mix test test/mailglass/webhook/ test/mailglass/properties/ --warnings-as-errors --exclude flaky` (~30-90s typical including the 1000-replay property)
- **Phase gate before `/gsd-verify-work`:** `mix verify.phase_04` followed by `mix verify.cold_start` to ensure Phase 4 doesn't break the full suite from a fresh DB

### Wave 0 Gaps

All test infrastructure is NEW. The full Wave 0 setup must include:

- [ ] `test/support/webhook_case.ex` — extend Phase 3 stub with D-26 helpers (`mailglass_webhook_conn/3`, `assert_webhook_ingested/3`, `stub_postmark_fixture/1`, `stub_sendgrid_fixture/1`, `freeze_timestamp/1`)
- [ ] `test/support/webhook_fixtures.ex` — generate test ECDSA P-256 keypair via `:crypto.generate_key/2`; sign helpers per Pattern 2
- [ ] `test/support/fixtures/webhooks/postmark/*.json` — 5 fixtures (delivered, bounced, opened, clicked, spam_complaint)
- [ ] `test/support/fixtures/webhooks/sendgrid/*.json` — 2 fixtures (single event + batch of 5)
- [ ] `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs` — 8-line wrapper that calls `Mailglass.Migration.up()` (existing `Mailglass.Migration.up/0` will pick up V02 dispatcher entry)
- [ ] `lib/mailglass/migrations/postgres/v02.ex` — D-15 DDL: create `mailglass_webhook_events` table + UNIQUE + status partial index; drop `mailglass_events.raw_payload`
- [ ] `lib/mailglass/migrations/postgres.ex` — bump `@current_version` from 1 to 2; verify dispatcher picks up V02 module
- [ ] `mix.exs` — (a) add `:public_key` to `extra_applications`; (b) add `verify.phase_04` alias mirroring `verify.phase_03`
- [ ] `lib/mailglass/repo.ex` — add `query!/2` passthrough delegate (no SQLSTATE translation needed; raw passthrough)
- [ ] `lib/mailglass/events/event.ex` — add `:reconciled` to `@mailglass_internal_types` (one-line change)
- [ ] `docs/api_stability.md` — extend §Error types (`SignatureError` 4→7 atoms; `TenancyError` +1; `ConfigError` +1) + §Tenancy behaviour (`resolve_webhook_tenant/1` optional callback) + §Telemetry catalog (5 webhook events + 1 reconcile span) + new §Webhook section (Provider behaviour shape, Plug opts, CachingBodyReader contract, Router macro signature)

**Framework install:** None (StreamData 1.3 already in deps; ExUnit is stdlib).

## Security Domain

> Required per `security_enforcement` default = enabled (no `false` setting found in config).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Postmark Basic Auth via `Plug.Crypto.secure_compare/2`; SendGrid ECDSA via `:public_key.verify/4` + 300s timestamp tolerance; closed `%SignatureError{type: t}` atom set (7 values) means callers can structurally distinguish failure modes |
| V3 Session Management | no | Webhook plug intentionally bypasses `:fetch_session` (CONTEXT D-06 requires `pipeline :mailglass_webhooks` with NO `:browser`, NO `:fetch_session`, NO `:protect_from_forgery`) |
| V4 Access Control | yes | Tenant resolution via `Mailglass.Tenancy.resolve_webhook_tenant/1` callback (D-12) — runs AFTER signature verify (D-13 — closes Stripe-Connect chicken-and-egg). Cross-tenant leak prevention via Phase 6 LINT-03 `NoUnscopedTenantQueryInLib`. |
| V5 Input Validation | yes | NimbleOptions validates all `:postmark` / `:sendgrid` config at boot; `Mailglass.IdempotencyKey.sanitize/1` strips non-ASCII-printable bytes from provider-supplied event IDs (already shipped, lib/mailglass/idempotency_key.ex:71); event-type strings pattern-matched literally with `Logger.warning + :unknown` fallthrough (D-05) |
| V6 Cryptography | yes | NEVER hand-roll: `:public_key.verify/4` for ECDSA; `Plug.Crypto.secure_compare/2` for Basic Auth; `:crypto.generate_key/2` for test keypair generation; ALL through OTP/Plug stdlib |
| V7 Error Handling | yes | `%SignatureError{}` raises with no recovery path; closed atom set; `Logger.warning("Webhook signature failed: provider=X reason=Y")` per D-24 — reason atom only, NO IP / headers / payload excerpt |
| V8 Data Protection | yes | Raw payloads live in `mailglass_webhook_events` (mutable, prunable, GDPR-erasable per D-15) — NOT in append-only `mailglass_events`; `inspect:` output redacted via `redact: true` per accrue precedent |
| V13 API & Web Service | yes | Path-per-provider (D-07); router macro is the documented mount path; `Plug.Parsers` `:length: 10_000_000` cap prevents DoS via large bodies |

### Known Threat Patterns for Phase 4 stack (Plug + Postgres + Oban)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook signature forgery (Postmark / SendGrid) | Spoofing | `Plug.Crypto.secure_compare/2` (timing-safe); `:public_key.verify/4` strict-true match; closed `%SignatureError{}` atom set |
| Replay attacks (legit webhook re-sent) | Tampering | UNIQUE partial index on `mailglass_webhook_events(provider, provider_event_id)` + `on_conflict: :nothing` (D-15); idempotency key per event in batch with `:index` suffix; HOOK-07 1000-replay property test |
| Body tampering (modify JSON after signing) | Tampering | Signature is over RAW bytes (D-09 CachingBodyReader); JSON re-encoding never substitutes for raw_body in verify chain |
| Cross-tenant data leak via webhook payload | Information Disclosure | `Tenancy.resolve_webhook_tenant/1` runs AFTER verify (D-13); `Tenancy.with_tenant/2` block-scopes the ingest; Phase 6 LINT-03 `NoUnscopedTenantQueryInLib` enforces query scoping; multi-tenant property test in D-27 |
| PII leakage via telemetry metadata | Information Disclosure | D-23 whitelist (atoms / booleans / non-neg integers / opaque IDs only); LINT-02 (Phase 6) lints; documented exclusion of `:ip`, `:user_agent`, header values |
| Provider retry storm DoS via slow DB | DoS | `SET LOCAL statement_timeout = '2s'; lock_timeout = '500ms'` (D-29); duplicate-detection telemetry (`[:mailglass, :webhook, :duplicate, :stop]`) lets adopters alert before logs fill |
| SQL injection via path/header/body | Tampering | All DB writes via Ecto changesets + parameterized queries; raw_body stored as JSONB (PG-side validation); no string interpolation into SQL anywhere in Phase 4 code |
| Open redirect via tenant resolution callback | Tampering | N/A — webhook plug never redirects; returns only 200/401/422/500 |
| Unbounded raw_payload storage (DoS via large bodies) | DoS | `Plug.Parsers` `:length: 10_000_000` cap; D-15 retention config + Pruner cron deletes succeeded payloads after 14 days |
| Forged webhook causes ledger corruption | Tampering | SQLSTATE 45A01 trigger on `mailglass_events` (Phase 2 V01); webhook_events flip to `:succeeded` only AFTER all event rows commit in same Multi |
| Missing public_key extra_application strips OTP app in release | Repudiation | A5 in Assumptions Log: Wave 0 task adds `:public_key` to `extra_applications` (mix.exs) |
| IP-based attacker enumeration via Postmark allowlist | Information Disclosure | Allowlist is OPT-IN (D-04); when on, attempts past allowlist still raise `%SignatureError{type: :ip_disallowed}` (no different from credential-based reject) |

**Threat that does NOT apply but might seem to:**
- "Use of `Application.compile_env*` in production" — Phase 4 reads runtime config via `Application.get_env/2` per CLAUDE.md constraint #1; Config schema additions land in `Mailglass.Config` only.

## Sources

### Primary (HIGH confidence)

- **`./CLAUDE.md`** — project instructions, engineering DNA, brand voice, "things not to do" list (10 items)
- **`.planning/phases/04-webhook-ingest/04-CONTEXT.md`** — 27 locked decisions D-01..D-29 + spec_lock + canonical_refs + code_context + specifics + deferred (456 lines)
- **`lib/mailglass/events.ex`** — `Events.append/1` + `append_multi/3` (function-form supported per Phase 3); replay-detection sentinel is `inserted_at: nil` not `id: nil`
- **`lib/mailglass/events/reconciler.ex`** — `find_orphans/1` + `attempt_link/2` shipped Phase 2; pure query, zero Oban dep; default `max_age_minutes: 7 * 24 * 60`
- **`lib/mailglass/outbound/projector.ex`** — `update_projections/2` + `broadcast_delivery_updated/3`; D-15 monotonic + optimistic_lock; PubSub `:rescue/catch :exit`-wrapped
- **`lib/mailglass/repo.ex`** — `transact/1` + `multi/1` + `insert/2` + `update/2` + `delete/2` (NEEDS `query!/2` added per A4); SQLSTATE 45A01 translation centralized
- **`lib/mailglass/tenancy.ex`** + `lib/mailglass/tenancy/single_tenant.ex` — `Tenancy` behaviour with `scope/2` + `tracking_host/1` (optional); process-dict via `:mailglass_tenant_id`; `with_tenant/2` block form is the canonical scoping primitive
- **`lib/mailglass/errors/signature_error.ex`** — closed atom set currently `[:missing, :malformed, :mismatch, :timestamp_skew]` (4); D-21 extends to 7
- **`lib/mailglass/errors/tenancy_error.ex`** — closed atom set currently `[:unstamped]`; D-14 adds `:webhook_tenant_unresolved`
- **`lib/mailglass/errors/config_error.ex`** — closed atom set currently 7 values; adds `:webhook_verification_key_missing` per D-21 rationale
- **`lib/mailglass/migrations/postgres/v01.ex`** — `mailglass_events.raw_payload` is nullable (line 77); idempotency_key partial UNIQUE present; SQLSTATE 45A01 trigger present; safe to drop column in V02
- **`lib/mailglass/idempotency_key.ex`** — `for_webhook_event(provider, event_id)` shipped Phase 1; `sanitize/1` strips non-ASCII-printable; max length 512 bytes
- **`lib/mailglass/optional_deps/oban.ex`** — `available?/0` predicate; `TenancyMiddleware` conditionally compiled with `wrap_perform/2` (OSS) + `call/2` (Pro) shapes
- **`lib/mailglass/pub_sub/topics.ex`** — `events/1` (tenant-wide) + `events/2` (per-delivery) — Phase 4 uses both
- **`lib/mailglass/clock.ex`** — `utc_now/0` with three-tier resolution (process-frozen → configured impl → System); `Mailglass.Clock.Frozen.advance/1` for tests
- **`lib/mailglass/telemetry.ex`** — `span/3` named span helpers per domain; events_append_span, persist_span, send_span, dispatch_span, persist_outbound_multi_span shipped
- **`lib/mailglass/config.ex`** — NimbleOptions-validated; brand theme cached in :persistent_term; Postgres-only at v0.1
- **`mix.exs`** — Plug 1.18 in deps spec, Plug 1.19.1 in lock; Phoenix 1.8; Oban 2.21+ optional
- **`mix.lock`** — `plug_crypto 2.1.1` confirmed transitive
- **`.planning/REQUIREMENTS.md`** — HOOK-01 through HOOK-07 (lines 104-110); TEST-03 (line 134-135)
- **`.planning/research/STACK.md`** — referenced by CONTEXT canonical_refs (no new deps for Phase 4)
- **`.planning/phases/02-persistence-tenancy/02-02-SUMMARY.md`** — V01 DDL details
- **`.planning/phases/02-persistence-tenancy/02-05-SUMMARY.md`** — Events.append pipeline + replay detection sentinel; Reconciler pure-query + Phase 4 worker shape preview
- **`lib/mailglass/adapters/fake.ex`** — `trigger_event/3` writes through SAME `Events.append_multi + Projector.update_projections + broadcast_delivery_updated` path Phase 4 ingest uses (CONTEXT D-03 Phase 3 reference)

### Secondary (MEDIUM confidence — verified against multiple sources)

- **[Twilio SendGrid Event Webhook Security Features](https://www.twilio.com/docs/sendgrid/for-developers/tracking-events/getting-started-event-webhook-security-features)** — Signed payload = `timestamp + raw_body`; ECDSA + SHA-256; X-Twilio-Email-Event-Webhook-Signature/Timestamp headers; signature is base64; key form not specified (D-03 supplies the answer: DER not PEM)
- **[Erlang/OTP 27 :public_key docs](https://www.erlang.org/docs/27/apps/public_key/public_key)** — `der_decode(:SubjectPublicKeyInfo, ...)` returns `{:SubjectPublicKeyInfo, AlgorithmIdentifier, key_bits}`; `verify(Msg, DigestType, Signature, Key)` — confirmed shape
- **[HexDocs Plug.Parsers `:body_reader`](https://hexdocs.pm/plug/Plug.Parsers.html)** — MFA contract `{Module, :function, [args]}`; defaults to `{Plug.Conn, :read_body, []}`; multipart caveat (does NOT honor body_reader)
- **[Plug PR #698](https://github.com/elixir-plug/plug/pull/698)** — `:body_reader` option added; stable since Plug 1.5.1
- **[Plug issue #884](https://github.com/elixir-plug/plug/issues/884)** — multipart parser does not invoke body_reader
- **[Postmark Webhooks Overview](https://postmarkapp.com/developer/webhooks/webhooks-overview)** — Basic Auth (no HMAC); IP can change per attempt
- **[Postmark IPs for Firewalls](https://postmarkapp.com/support/article/800-ips-for-firewalls)** — current webhook IP list (changes; document but don't hardcode per D-04)
- **[Oban.Plugins.Cron HexDocs](https://hexdocs.pm/oban/Oban.Plugins.Cron.html)** — Cron is in OSS Oban 2.0+; `*/5 * * * *` syntax supported

### Tertiary (LOW confidence — single source / unverified)

- **[Zenn: Erlang/Elixir SendGrid signature verification](https://zenn.dev/siiibo_tech/articles/erlang-elixir-sendgrid-signature-verify-20230812)** (Japanese) — concrete DER-not-PEM walkthrough; cited in CONTEXT D-03 for cross-validation

### Reference Implementations (sibling-constraint per CONTEXT canonical_refs)

- `~/projects/lattice_stripe/lib/lattice_stripe/webhook/{plug,cache_body_reader,signature_verification_error}.ex` — verifier + CachingBodyReader + closed-atom-set precedent
- `~/projects/accrue/accrue/lib/accrue/webhook/{plug,webhook_event,ingest,pruner}.ex` — webhook_events table + Pruner + transactional Multi pattern
- `~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex` — Oban cron reconciler with 60s grace + 1000 rows/tick
- `~/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs` — migration shape D-15 follows
- `~/projects/sigra/lib/sigra/admin/router.ex` — router-macro shape (D-08 shared vocabulary)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libs verified in mix.lock; no new deps; Plug 1.19.1 + Phoenix 1.8.5 + plug_crypto 2.1.1 + ecto 3.13 + Oban 2.21+ all current
- Architecture patterns: HIGH — every pattern verified against existing Phase 1/2/3 code OR sealed by CONTEXT decision; SendGrid ECDSA shape verified against erlang.org/docs/27 + Twilio docs
- Pitfalls: HIGH — 7 of 10 are direct code references to shipped behavior (Repo, Projector, Events, Tenancy); 3 are CONTEXT-derived (D-03 PEM-vs-DER, D-09 multipart, D-23 IP exclusion)
- Security domain: HIGH — ASVS mapping derived from CONTEXT D-21..D-24 + CLAUDE.md constraints + verified shipped code
- Validation architecture: HIGH — 1:1 REQ-ID coverage with concrete commands; Wave 0 gaps fully enumerated
- Open questions: HIGH — all three ROADMAP-flagged questions resolved by CONTEXT decisions verified in this research

**Research date:** 2026-04-23
**Valid until:** 2026-05-23 (30 days; stable subsystem — Plug, Phoenix, Postgres, OTP `:public_key` rarely change in patch releases)

## RESEARCH COMPLETE

**Phase:** 4 — Webhook Ingest
**Confidence:** HIGH

### Key Findings

- **All 27 CONTEXT decisions verified** against shipped Phase 1-3 code OR external authoritative sources (Twilio, Erlang OTP, Plug). Zero CONTEXT decisions need revisiting.
- **Three ROADMAP open questions resolved:** SendGrid ECDSA pattern (DER-not-PEM, prime256v1, signed_payload = timestamp + raw_body, 300s tolerance) confirmed; Plug `:body_reader` MFA contract stable since 1.5.1 (PR #698) confirmed; orphan reconciliation cadence `*/5` cron + 60s grace + 1000 rows/tick locked.
- **No new dependencies required.** `plug_crypto 2.1.1` already transitive via Plug 1.19.1; `:public_key` is OTP stdlib (must add to `extra_applications` per A5).
- **Two non-obvious Wave 0 gaps surfaced:** (a) `mix.exs` needs `:public_key` in `extra_applications` or releases strip it and SendGrid breaks in production; (b) `Mailglass.Repo` needs a `query!/2` passthrough delegate so `SET LOCAL statement_timeout` (D-29) is callable through the facade.
- **D-15 V02 migration is safe:** verified `mailglass_events.raw_payload` is nullable in V01:77 with no shipped writers populating it; column drop will not corrupt data.
- **`:reconciled` event extension is application-side only:** V01 stores `type` as `:text`, so adding to `@mailglass_internal_types` is a one-line change to `lib/mailglass/events/event.ex:56` — no DB migration needed for the enum extension itself.

### File Created

`.planning/phases/04-webhook-ingest/04-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All deps in mix.lock; no new deps; Plug 1.19.1 / Phoenix 1.8.5 / OTP 27 verified |
| Architecture | HIGH | Every pattern either verified against shipped code or sealed by CONTEXT |
| Pitfalls | HIGH | 7 of 10 reference shipped code; 3 derived from CONTEXT decisions |
| Validation Architecture | HIGH | 1:1 REQ-ID coverage with concrete commands; UAT gate aliased after Phase 3 |
| Security Domain | HIGH | ASVS mapping derived from CONTEXT + CLAUDE.md + verified shipped code |
| Reconciliation cadence | HIGH | accrue-verbatim per D-17; */5 cron + 60s grace + 1000 rows/tick |
| Tenant resolution composability | MEDIUM-HIGH | D-12 callback shape verified compositional; ResolveFromPath + verified_payload + header strategies all documented in `guides/webhooks.md` (Phase 4 ships first guide) |

### Open Questions

None blocking. The single minor open question — exact NimbleOptions schema keys for `:postmark` / `:sendgrid` config subtrees — is marked Claude's Discretion in CONTEXT and resolved with a recommendation in §Open Questions for the planner to finalize during Plan 1.

### Ready for Planning

Research complete. The planner can now decompose Phase 4 into PLAN.md files. Recommended wave structure:

- **Wave 0 (foundations + DDL):** Plan 1 — `:public_key` extra_application + `Repo.query!/2` + Mailglass.Migrations.Postgres.V02 + `:reconciled` enum extension + `mailglass_events.raw_payload` drop + 8-line synthetic test migration + WebhookCase + WebhookFixtures + verify.phase_04 alias + api_stability.md scaffolding
- **Wave 1 (provider primitives):** Plans 2-3 — `Mailglass.Webhook.Provider` behaviour + `CachingBodyReader` + `Providers.Postmark` (Basic Auth + IP allowlist) + `Providers.SendGrid` (ECDSA via :public_key.der_decode + 300s tolerance)
- **Wave 2 (orchestration):** Plans 4-5 — `Mailglass.Webhook.Plug` + `Mailglass.Webhook.Router` macro + `Mailglass.Tenancy` extension (`resolve_webhook_tenant/1` optional callback + `ResolveFromPath` module) + error atom-set extensions (`%SignatureError{}` 4→7, `%TenancyError{}` +1, `%ConfigError{}` +1)
- **Wave 3 (persistence + cron):** Plans 6-7 — `Mailglass.Webhook.Ingest.ingest_multi/3` (with statement_timeout) + `Mailglass.Webhook.Reconciler` Oban worker + `Mailglass.Webhook.Pruner` Oban worker + `Mix.Tasks.Mailglass.Reconcile` + `Mix.Tasks.Mailglass.Webhooks.Prune`
- **Wave 4 (telemetry + properties + UAT):** Plans 8-9 — `Mailglass.Webhook.Telemetry` span helpers + 3 StreamData property tests (HOOK-07 1000-replay, signature failure, tenant resolution) + phase-wide `core_webhook_integration_test.exs` tagged `:phase_04_uat` + `guides/webhooks.md` first draft + sign-off via `mix verify.phase_04`

This decomposition aligns with the 7-area research synthesis in CONTEXT (verifier architecture, plug+body_reader, ingest+failure lanes, raw payload storage, orphan reconciliation, error+telemetry, testability+forward-references) and the wave-based delivery cadence Phase 3 established (12 plans across 5 waves).
