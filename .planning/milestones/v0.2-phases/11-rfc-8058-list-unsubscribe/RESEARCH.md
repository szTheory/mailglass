# Phase 11: RFC 8058 List-Unsubscribe - Research

**Researched:** 2026-04-28 [VERIFIED: 2026-04-28 workspace date]
**Domain:** RFC 8058 one-click unsubscribe for Elixir/Phoenix transactional email [VERIFIED: .planning/ROADMAP.md]
**Confidence:** MEDIUM [VERIFIED: synthesis from cited standards + verified repo fit, with two implementation-level open questions]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## 1. GET Confirmation Page (Browser Fallback) [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Decision:** Hybrid approach. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Default:** A built-in, layout-free, standalone HEEx template using `Mailglass.Components` that looks like a clean, neutral SaaS hosted page. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Escape Hatch:** Provide a configuration hook (`config :mailglass, :compliance, unsubscribe_redirect: "/settings/unsubscribe"`) that intercepts the GET request via a 302 redirect. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Rationale:** The built-in template provides "magical" day-one DX and instant RFC 8058 compliance without setup. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] It completely avoids the massive footgun of attempting to render inside the adopter's layout (which crashes when the core controller lacks the adopter's expected assigns like `@current_user`). [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] The redirect provides a clean eject path for production teams who demand total brand control. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

## 2. Exposing the `:unsubscribed` Event (State Sync) [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Decision:** Layered Lifecycle Architecture. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Primary (Transactional):** Provide a `Mailglass.Lifecycle` behaviour with a `handle_event(multi, event)` callback. The core controller passes its `Ecto.Multi` to this handler *before* executing the transaction. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Secondary (Observability):** Retain `Phoenix.PubSub` (`Projector.broadcast_delivery_updated/3`) strictly for transient, non-durable UI updates. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Rationale:** Adopters need to safely sync the unsubscribe state to their own systems (e.g., marking a `User` as `opted_out`). [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] The `Mailglass.Lifecycle` hook allows them to atomically update their tables or safely enqueue an Oban job in the exact same transaction. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] This eliminates the "dual-write" footgun and prevents blocking the lightning-fast RFC 8058 POST request with synchronous external API calls. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

## 3. Cryptographic Token Generation & Secret Rotation [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Decision:** `Phoenix.Token` with a multi-secret escape hatch. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Default:** Use `Phoenix.Token` backed by `Mailglass.Tracking.endpoint()` with a hardcoded salt (`"mailglass_unsubscribe_v1"`). [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Escape Hatch:** Provide `config :mailglass, :compliance, previous_secrets: [...]` which accepts a list of raw binary secrets. If `Phoenix.Token.verify` fails against the current endpoint, the library manually iterates over `previous_secrets` to verify. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Rationale:** *Correction to STACK.md:* Breaking in-flight unsubscribe links upon a `secret_key_base` rotation is a deliverability catastrophe (angry users click "Mark as Spam"). [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] This approach gives 90% of adopters zero-config setup using their existing Phoenix Endpoint. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] For the 10% who *must* roll their `secret_key_base` in an emergency, they drop their old secret into `previous_secrets`, and `mailglass` seamlessly verifies in-flight links without breaking a sweat or incurring spam penalties. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

## 4. URL Generation & Routing (Multi-Tenancy) [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Decision:** Config-driven base with multi-tenant override and a compile-time router macro. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Configuration:** Introduce `config :mailglass, :compliance, endpoint: MyAppWeb.Endpoint, host: "...", mount_path: "/mailglass/unsubscribe"`. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Macro:** `import Mailglass.Router` then mount with `mailglass_router_routes "/mailglass"`, generating `GET` + `POST` routes at `/mailglass/unsubscribe/:token` from the centralized mount-path contract. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Multi-Tenant Override:** Add an optional `compliance_host/1` callback to the `Mailglass.Tenancy` behaviour. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Generator:** `mix mailglass.gen.unsubscribe` outputs a strict, terminal-based installation checklist (config snippet + router macro + UAT test recipe) and copies zero files. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

**Rationale:** This mirrors the proven `Mailglass.Tracking` pattern. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] It completely eliminates the Phoenix Router "divergent path" footgun, solves the multi-tenancy URL problem using existing project DNA, strictly adheres to the no-copy generation rule, and guarantees the URL can be generated deterministically outside the web request cycle (where there is no `conn`), while satisfying the `< 900 bytes` RFC 8058 constraint. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

### Claude's Discretion

None recorded in `11-CONTEXT.md`. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

None recorded in `11-CONTEXT.md`. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| UNSUB-01 | `Mailglass.Compliance.Unsubscribe` mints and verifies minimal `delivery_id` tokens with `Phoenix.Token`, current endpoint first, and raw previous-secret fallback; `unsubscribe_url/2` fails fast when `byte_size(url) > 900`. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8058 requires the HTTPS URI itself to carry enough information because extra POST args are unavailable, and Phoenix.Token officially supports endpoint-backed or raw secret-key-base contexts. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| UNSUB-02 | `inject_unsubscribe_headers/2` is the only path that sets `List-Unsubscribe` and `List-Unsubscribe-Post`, and it must be atomic and stream-aware. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8058 requires both headers together for one-click signaling, and repo fit requires message-aware injection because current `Mailglass.Compliance.add_rfc_required_headers/1` only receives `%Swoosh.Email{}` while stream lives on `%Mailglass.Message{}`. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: lib/mailglass/compliance.ex] |
| UNSUB-03 | Core-package controller must serve GET fallback and idempotent POST without redirect, recording an `:unsubscribed` event. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8058 forbids redirecting the POST path, and repo fit favors `Mailglass.Events.append_multi/3` plus post-commit `Projector.broadcast_delivery_updated/3`. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/outbound/projector.ex] |
| UNSUB-04 | Router macro, configurable mount path, and generator must follow established Phoenix/router patterns in this repo. [VERIFIED: .planning/REQUIREMENTS.md] | `Mailglass.Webhook.Router` and `MailglassAdmin.Router` already establish the macro pattern: adopter-owned scope/pipeline, compile-time option validation, and explicit route helpers. [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |
| UNSUB-05 | Property tests must cover rotation, expiry, idempotent POST, open-redirect/SSRF resistance, and stream-conditional headers. [VERIFIED: .planning/REQUIREMENTS.md] | Existing tests already normalize StreamData property style for token rotation, redirect resistance, and convergence properties. [VERIFIED: test/mailglass/tracking/token_rotation_test.exs] [VERIFIED: test/mailglass/tracking/open_redirect_test.exs] [VERIFIED: test/mailglass/properties/webhook_idempotency_convergence_test.exs] |
| UNSUB-06 | Guides must document adopter setup, DKIM coverage expectations, rotation playbook, and ESP caveats. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8058 requires DKIM coverage of both unsubscribe headers, and the roadmap/requirements already call out ESP verification as part of the deliverability contract. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- `mailglass` core, not `mailglass_admin`, must own RFC 8058 unsubscribe because sibling packages are intentionally separated and `mailglass_admin` is a dev/admin surface, not a runtime dependency for core mail flows. [VERIFIED: CLAUDE.md]
- Only `Mailglass.Config` may call `Application.compile_env*`; any router-macro design that reads compile-time config outside that module conflicts with repo rules and the Phase 6 `NoCompileEnvOutsideConfig` enforcement. [VERIFIED: CLAUDE.md] [VERIFIED: test/mailglass/credo/no_compile_env_outside_config_test.exs]
- Multi-tenancy is first-class, so any unsubscribe flow must preserve `tenant_id` and avoid single-tenant fallbacks in transactional paths. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/tenancy.ex]
- Errors are public API; invalid, expired, or rotated-token failures must become structured `Mailglass.Error`-style outcomes rather than 500s or message-string contracts. [VERIFIED: CLAUDE.md]
- Telemetry metadata must never contain PII, so unsubscribe events and controller telemetry cannot emit recipient addresses, subjects, bodies, or raw URLs. [VERIFIED: CLAUDE.md]
- `mailglass_events` is append-only and all durable state changes should flow through the event ledger rather than ad hoc mutable tables. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/events.ex]
- Open/click tracking is off by default and auth-carrying messages must never be tracked; unsubscribe injection must not accidentally create a second link-rewrite path that bypasses those protections. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/tracking/rewriter.ex]
- The repo already prefers pluggable behaviours over magic, so any adopter sync hook should be a narrow optional behaviour, not implicit callbacks or global singleton registration. [VERIFIED: CLAUDE.md]

## Summary

Phase 11 should be implemented as a core-package Phoenix controller plus a message-aware unsubscribe service, not as an admin feature and not as a raw URL helper bolted onto `%Swoosh.Email{}`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mailglass/compliance.ex] The current repo fit is strong: tracking already uses `Phoenix.Token`, webhook ingest already uses an append-only event-first transaction model, and both webhook/admin packages already establish the preferred router-macro pattern. [VERIFIED: lib/mailglass/tracking.ex] [VERIFIED: lib/mailglass/tracking/token.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

The main technical constraint is RFC 8058 itself. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] One-click requires one `List-Unsubscribe` header containing at least one HTTPS URI, one `List-Unsubscribe-Post` header containing exactly `List-Unsubscribe=One-Click`, DKIM coverage of both headers, no cookies or auth context on POST, enough information encoded in the URI to complete the unsubscribe automatically, and no HTTPS redirect on the POST path. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] That aligns directly with the roadmap requirement to keep payloads minimal and URLs under 900 bytes, which is a practical guardrail below RFC 5322's 998-character hard line limit for header lines. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.rfc-editor.org/rfc/rfc5322.txt]

The biggest planner risks are repo-specific, not standards-specific: current `Mailglass.Compliance.add_rfc_required_headers/1` is email-only and therefore cannot safely inject stream-conditional unsubscribe headers; the `11-CONTEXT.md` compile-time `mount_path` idea conflicts with the repo's ban on `Application.compile_env*` outside `Mailglass.Config`; and `Mailglass.Lifecycle` does not exist yet, so the planner must either include it in Phase 11 scope or explicitly defer it. [VERIFIED: lib/mailglass/compliance.ex] [VERIFIED: CLAUDE.md] [VERIFIED: test/mailglass/credo/no_compile_env_outside_config_test.exs] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] [VERIFIED: search for `Mailglass.Lifecycle` in lib/ and test/ returned no module]

**Primary recommendation:** Use `Phoenix.Token` with `delivery_id`-only payloads, verify against the current endpoint then `previous_secrets`, inject both unsubscribe headers from one `%Mailglass.Message{}` path, and make POST append an idempotent `:unsubscribed` event before any adopter hook or PubSub fan-out. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/outbound/projector.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Unsubscribe URL signing and verification | API / Backend | Frontend Server (SSR) | Tokens are cryptographic server concerns, and Phoenix.Token derives key material from the endpoint or raw secret key base rather than browser state. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| `List-Unsubscribe` / `List-Unsubscribe-Post` header injection | API / Backend | — | Headers are added during outbound message assembly and depend on stream/mailable/tenant information in `%Mailglass.Message{}`. [VERIFIED: lib/mailglass/compliance.ex] [VERIFIED: lib/mailglass/outbound.ex] |
| GET confirmation page | Frontend Server (SSR) | API / Backend | The GET fallback is a server-rendered Phoenix controller path with a layout-free HEEx page or redirect escape hatch. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] |
| RFC 8058 one-click POST | API / Backend | Database / Storage | POST must validate the token, append an event transactionally, and return 200 without redirect. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: lib/mailglass/events.ex] |
| Idempotency and unsubscribe event durability | Database / Storage | API / Backend | Durable convergence belongs to the event ledger and its idempotency key path, while the controller only orchestrates the transaction. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/idempotency_key.ex] |
| Post-commit UI fan-out | API / Backend | — | The repo already treats `Projector.broadcast_delivery_updated/3` as best-effort post-commit PubSub, not as a durability mechanism. [VERIFIED: lib/mailglass/outbound/projector.ex] |
| Per-tenant unsubscribe host override | API / Backend | Frontend Server (SSR) | Tenant routing lives in `Mailglass.Tenancy`, and URL generation must work outside a request cycle using configured host data. [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.5` (released 2026-03-05) [VERIFIED: Hex API] | `Phoenix.Token`, router macros, controller/conn stack | Already required by the repo, current on Hex, and the official token API supports endpoint-backed or raw-secret contexts needed for current-endpoint plus previous-secret verification. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| `stream_data` | `1.3.0` (released 2026-03-09) [VERIFIED: Hex API] | Property tests for rotation, expiry, stream/header combinations, and idempotent convergence | Already present in test deps and already used for tracking/webhook properties in this repo. [VERIFIED: mix.exs] [VERIFIED: test/mailglass/tracking/open_redirect_test.exs] [VERIFIED: test/mailglass/properties/webhook_idempotency_convergence_test.exs] |
| `swoosh` | `1.25.0` (released 2026-04-02) [VERIFIED: Hex API] | Underlying message header container | Header injection must still terminate in the existing `%Swoosh.Email{}` because outbound rendering already depends on it. [VERIFIED: mix.exs] [VERIFIED: lib/mailglass/compliance.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.Events.append_multi/3` | repo internal [VERIFIED: lib/mailglass/events.ex] | Transactional append-only event write | Use for POST idempotency and `:unsubscribed` durability instead of raw repo inserts. [VERIFIED: lib/mailglass/events.ex] |
| `Mailglass.IdempotencyKey` | repo internal [VERIFIED: lib/mailglass/idempotency_key.ex] | Deterministic replay collapse | Use for repeated POSTs so the second click is a structural no-op that still returns 200. [VERIFIED: lib/mailglass/idempotency_key.ex] |
| `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` | repo internal [VERIFIED: lib/mailglass/outbound/projector.ex] | Best-effort post-commit fan-out | Use only after the event transaction commits if Phase 11 chooses to surface unsubscribe updates over PubSub. [VERIFIED: lib/mailglass/outbound/projector.ex] |
| `Mailglass.Webhook.Router` / `MailglassAdmin.Router` patterns | repo internal [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] | Macro style reference | Use these as the shape for an unsubscribe router macro: adopter-owned scope, compile-time opt validation, and explicit helpers. [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.Token` | JWT or custom HMAC URLs | Rejected because the project already locks "JWT tokens for unsubscribe" out of scope and Phoenix.Token already covers endpoint-backed plus raw-secret verification without a new dependency. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Current endpoint + `previous_secrets` fallback | Salt-only rotation | Salt-only rotation preserves tokens across salt changes but not across `secret_key_base` rotation, while Phoenix.Token explicitly accepts a raw secret key base as context for verification. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Core-package controller | `mailglass_admin` route/controller | Rejected because requirements explicitly place the controller in core, and `mailglass_admin` is a separate sibling package not guaranteed in adopter runtime deps. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: CLAUDE.md] |
| Single HTTPS URL only | HTTPS plus `mailto:` fallback | RFC 8058 requires one HTTPS URI and allows other non-HTTP/S URIs, so optional `mailto:` remains acceptable if atomic injection keeps the HTTPS URI first and intact. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [CITED: https://www.rfc-editor.org/rfc/rfc2369.txt] |

**Installation:**
```bash
# No new dependency is required for Phase 11.
# Existing deps already cover Phoenix.Token, router/controller work, and StreamData.
mix deps.get
```

## Architecture Patterns

### System Architecture Diagram

```text
Bulk/operational Message
  -> stream policy + render
  -> unsubscribe_url/2
  -> inject_unsubscribe_headers/2
  -> outbound delivery
  -> recipient MUA
  -> GET /mailglass/unsubscribe/:token
       -> verify token
       -> show built-in confirmation page or configured redirect
  -> POST /mailglass/unsubscribe/:token
       -> verify token against current endpoint
       -> if fail, verify against previous raw secrets
       -> load delivery + tenant context
       -> build Ecto.Multi
            -> append :unsubscribed event with idempotency key
            -> optional Mailglass.Lifecycle hook
       -> commit
       -> optional post-commit PubSub broadcast
       -> HTTP 200 (no redirect)
```

### Recommended Project Structure

```text
lib/
├── mailglass/compliance/unsubscribe.ex              # token mint/verify + URL builder + header injection
├── mailglass/compliance/unsubscribe_controller.ex   # GET fallback + POST one-click
├── mailglass/router.ex                              # unsubscribe router macro
└── mix/tasks/mailglass.gen.unsubscribe.ex           # no-copy installer/checklist generator

test/
├── mailglass/compliance/unsubscribe_test.exs                # token + URL + header unit tests
├── mailglass/compliance/unsubscribe_controller_test.exs     # GET/POST endpoint behavior
├── mailglass/router/unsubscribe_router_test.exs             # macro expansion + mount-path behavior
└── mailglass/properties/unsubscribe_property_test.exs       # rotation/expiry/idempotency/header properties
```

### Pattern 1: Current Endpoint First, Previous Raw Secrets Second
**What:** Sign with the current Phoenix endpoint context and verify in two phases: current endpoint first, then each raw previous secret string. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] [VERIFIED: lib/mailglass/tracking/token.ex]
**When to use:** Always for Phase 11 because requirements explicitly need in-flight links to survive emergency `secret_key_base` rotation. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
**Example:**
```elixir
# Source: Phoenix.Token docs + existing Mailglass.Tracking.Token rotation style.
def verify_unsubscribe(token) do
  endpoint = Mailglass.Tracking.endpoint()

  case Phoenix.Token.verify(endpoint, "mailglass_unsubscribe_v1", token, max_age: max_age()) do
    {:ok, delivery_id} when is_binary(delivery_id) ->
      {:ok, delivery_id}

    _ ->
      verify_with_previous_secrets(token)
  end
end
```

### Pattern 2: Atomic Header Injection from a Message-Aware Function
**What:** Build both unsubscribe headers from a single function that has `%Mailglass.Message{}` available, then write into the inner `%Swoosh.Email{}` exactly once. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [VERIFIED: lib/mailglass/compliance.ex]
**When to use:** For every `:bulk` message and opt-in `:operational` message; never for `:transactional`. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: RFC 8058 requirements + Mailglass.Compliance style.
def inject_unsubscribe_headers(%Mailglass.Message{} = message, url) do
  email =
    message.swoosh_email
    |> put_header_if_absent("List-Unsubscribe", "<#{url}>")
    |> put_header_if_absent("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")

  %{message | swoosh_email: email}
end
```

### Pattern 3: Idempotent POST via Event Append, Not Mutable Flags
**What:** Treat POST as "append `:unsubscribed` if not already recorded" rather than "flip a boolean", and derive idempotency from a deterministic key. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/idempotency_key.ex]
**When to use:** Every POST request, including repeated clicks and mailbox-provider replays. [VERIFIED: .planning/ROADMAP.md]
**Example:**
```elixir
# Source: existing Events.append_multi/3 + idempotency-key pattern.
Ecto.Multi.new()
|> Mailglass.Events.append_multi(:unsubscribe_event, %{
  tenant_id: tenant_id,
  delivery_id: delivery.id,
  type: :unsubscribed,
  idempotency_key: "unsubscribe:#{delivery.id}"
})
```

### Anti-Patterns to Avoid

- **Compile-time config reads in the router macro:** `11-CONTEXT.md` proposes `Application.compile_env`, but repo rules only allow that in `Mailglass.Config`; planner should route compile-time config through `Mailglass.Config` or keep the macro API explicit. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] [VERIFIED: CLAUDE.md]
- **Email-only header injection:** Extending the current `add_rfc_required_headers/1` directly on `%Swoosh.Email{}` will hide stream context and make `:bulk`/`:transactional` branching brittle. [VERIFIED: lib/mailglass/compliance.ex]
- **Redirecting POST:** RFC 8058 explicitly says the sender must not return an HTTPS redirect for the unsubscribe POST. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt]
- **Opaque GET confirmation inside adopter layout:** The phase context already identifies layout coupling as a crash footgun for core controllers. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
- **Dual-write side effects before commit:** Any adopter sync hook must receive the `Ecto.Multi`, not fire external work inline before the event ledger commits. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] [VERIFIED: lib/mailglass/outbound/projector.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Signed unsubscribe crypto | Custom JWT or HMAC format | `Phoenix.Token` | Official API already supports endpoint-backed and raw-secret contexts, which is exactly what the rotation escape hatch needs. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Event durability | Raw `Repo.insert(%Event{})` or mutable unsubscribe flags | `Mailglass.Events.append_multi/3` | The repo explicitly reserves append-only events as the legitimate write path and enforces that at the architecture level. [VERIFIED: lib/mailglass/events.ex] |
| Replay handling | Bespoke replay tables or mutable "already unsubscribed" booleans | Existing idempotency-key pattern | Repeated POSTs can converge through deterministic event keys the same way webhook replay does. [VERIFIED: lib/mailglass/idempotency_key.ex] [VERIFIED: lib/mailglass/webhook/ingest.ex] |
| Router shape | Ad hoc controller mounting instructions | Existing router-macro style | `Mailglass.Webhook.Router` and `MailglassAdmin.Router` already encode the macro conventions adopters see in this repo. [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |

**Key insight:** The repo already has the hard parts: token signing, append-only idempotent events, multi-tenant process context, and router macros. [VERIFIED: lib/mailglass/tracking/token.ex] [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/webhook/router.ex] Phase 11 should compose those parts instead of inventing a second persistence, crypto, or routing model. [VERIFIED: codebase synthesis]

## Common Pitfalls

### Pitfall 1: Treating RFC 8058 as "just add a link"
**What goes wrong:** The implementation sets `List-Unsubscribe` without `List-Unsubscribe-Post`, or uses a GET-only landing page and calls it one-click. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt]
**Why it happens:** `RFC 2369` alone allows generic unsubscribe URLs, but `RFC 8058` adds the specific POST signaling contract. [CITED: https://www.rfc-editor.org/rfc/rfc2369.txt] [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt]
**How to avoid:** Make `inject_unsubscribe_headers/2` the sole path and assert both headers appear together in tests and lint. [VERIFIED: .planning/REQUIREMENTS.md]
**Warning signs:** Unit tests only inspect `List-Unsubscribe`, or planners put POST behavior in a follow-up phase. [VERIFIED: planner risk inference from requirements]

### Pitfall 2: Breaking links on `secret_key_base` rotation
**What goes wrong:** Salt rotation passes tests, but real users hit expired or unverifiable links after an emergency endpoint secret rotation. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md]
**Why it happens:** Salt lists in the existing tracking token code preserve tokens only when the same underlying key base still exists. [VERIFIED: lib/mailglass/tracking/token.ex]
**How to avoid:** Verify first with `Mailglass.Tracking.endpoint()`, then retry with each raw `previous_secrets` value as the Phoenix.Token context. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html]
**Warning signs:** Tests cover only `config :mailglass, :tracking, salts:` changes and never swap the secret base context. [VERIFIED: test/mailglass/tracking/token_rotation_test.exs]

### Pitfall 3: Losing stream context during header injection
**What goes wrong:** `:transactional` mail accidentally gets unsubscribe headers, or `:bulk` mail misses them, because injection happens on `%Swoosh.Email{}` after message context is gone. [VERIFIED: lib/mailglass/compliance.ex]
**Why it happens:** Current compliance helpers are email-only, but the requirements are message-stream-dependent. [VERIFIED: lib/mailglass/compliance.ex] [VERIFIED: .planning/REQUIREMENTS.md]
**How to avoid:** Keep unsubscribe decisions on `%Mailglass.Message{}` until both headers are injected, then hand the updated `%Swoosh.Email{}` back to the pipeline. [VERIFIED: repo-fit recommendation from code]
**Warning signs:** Planner places unsubscribe injection entirely inside `Mailglass.Compliance.add_rfc_required_headers/1` without changing its input type or call site. [VERIFIED: planner risk from current code]

### Pitfall 4: Non-idempotent POST semantics
**What goes wrong:** First POST succeeds but a repeated POST raises, inserts a duplicate event, or returns a non-200 response. [VERIFIED: .planning/ROADMAP.md]
**Why it happens:** Controller code uses mutable state checks instead of the repo's existing idempotency-key pattern. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/idempotency_key.ex]
**How to avoid:** Encode POST idempotency in the event append itself and keep the HTTP response 200 for both first and repeated clicks. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
**Warning signs:** Tests assert a database row count increase on every POST or return 409/422 on duplicates. [VERIFIED: planner risk from requirements]

### Pitfall 5: Router shadowing and divergent mount paths
**What goes wrong:** The unsubscribe route is mounted under one path while URL generation uses another, or an adopter route shadows `/mailglass/unsubscribe/:token`. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]
**Why it happens:** Phoenix matches routes top to bottom, and the context's compile-time mount-path proposal conflicts with the repo's compile-env rule. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] [VERIFIED: CLAUDE.md]
**How to avoid:** Keep one source of truth for the path, mirror existing router-macro validation patterns, and add a route smoke test using the mounted test router. [VERIFIED: lib/mailglass/webhook/router.ex] [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]
**Warning signs:** Generator instructions mention one path while tests or helper output assert another. [VERIFIED: planner risk from context + repo patterns]

## Code Examples

Verified patterns from official sources and current repo style:

### Phoenix.Token verification with endpoint or raw secret context
```elixir
# Source: https://hexdocs.pm/phoenix/Phoenix.Token.html
Phoenix.Token.sign(MyAppWeb.Endpoint, "user auth", user_id)
Phoenix.Token.verify(MyAppWeb.Endpoint, "user auth", token, max_age: 86_400)
Phoenix.Token.verify(old_secret_key_base, "user auth", token, max_age: 86_400)
```

### Existing event-first composition pattern in mailglass
```elixir
# Source: lib/mailglass/events.ex + lib/mailglass/webhook/ingest.ex
Ecto.Multi.new()
|> Mailglass.Events.append_multi(:event, %{type: :unsubscribed, delivery_id: delivery.id})
|> Ecto.Multi.run(:after_event, fn _repo, changes ->
  {:ok, changes.event}
end)
```

### Existing router-macro shape in mailglass
```elixir
# Source: lib/mailglass/webhook/router.ex + mailglass_admin/lib/mailglass_admin/router.ex
scope "/", MyAppWeb do
  pipe_through :browser
  mailglass_unsubscribe_routes "/mailglass"
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Confirmation-page unsubscribe only | RFC 8058 one-click signaling with `List-Unsubscribe-Post` and POST semantics | RFC 8058, January 2017 [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] | One-click inbox UI support depends on the POST signaling contract, not just a generic unsubscribe URL. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] |
| Salt-list rotation only | Endpoint verification plus raw previous-secret fallback | Locked in Phase 11 context on 2026-04-27. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] | Preserves in-flight links across `secret_key_base` rotation instead of only salt rotation. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Header-by-header manual mutation | Single atomic unsubscribe injection path | Locked in `UNSUB-02`. [VERIFIED: .planning/REQUIREMENTS.md] | Prevents half-configured one-click behavior and makes linting/testing load-bearing. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- Bare `List-Unsubscribe` without `List-Unsubscribe-Post` is insufficient for RFC 8058 one-click signaling. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt]
- Salt rotation as the only migration story is insufficient for emergency `secret_key_base` rotation in this phase's requirements. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phoenix route-collision detection can be implemented at macro time by inspecting the router module's accumulated `:phoenix_routes` attribute before adding the unsubscribe routes. [VERIFIED: deps/phoenix/lib/phoenix/router.ex:299] [VERIFIED: deps/phoenix/lib/phoenix/router.ex:489] [VERIFIED: deps/phoenix/lib/phoenix/router.ex:740] | Common Pitfalls / Open Questions | Low — Phoenix's own router compilation path uses the same attribute to build `__routes__/0`, so the mechanism is stable within the repo's current Phoenix version. |
| A2 | The cleanest Phase 11 idempotency key is a deterministic `unsubscribe:<delivery_id>`-style namespace rather than a token digest. [ASSUMED] | Architecture Patterns | Low — either choice can satisfy the requirement if it is deterministic and replay-safe. |

## Open Questions (RESOLVED)

1. **Does Phase 11 include `Mailglass.Lifecycle`, or is it a Phase 11.1 / Phase 12 concern?**
   - Resolution: It is in Phase 11 scope. `11-CONTEXT.md` locks a transactional lifecycle hook as part of the unsubscribe state-sync story, so the behavior contract lands in `11-01` and the transaction integration lands in `11-03`. [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-01-PLAN.md] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-03-PLAN.md]

2. **What exact mechanism should satisfy "collision detection against adopter routes"?**
   - Resolution: Use Phoenix's compile-time `:phoenix_routes` accumulator. `Phoenix.Router` registers `@phoenix_routes` with `accumulate: true`, appends each generated route into that attribute, and later builds `__routes__/0` from the reversed attribute contents. The unsubscribe router macro can therefore inspect `Module.get_attribute(__CALLER__.module, :phoenix_routes)` before adding its own GET and POST routes and raise on verb/path collisions. [VERIFIED: deps/phoenix/lib/phoenix/router.ex:299] [VERIFIED: deps/phoenix/lib/phoenix/router.ex:489] [VERIFIED: deps/phoenix/lib/phoenix/router.ex:740]

3. **Should `Mailglass.Compliance.add_rfc_required_headers/1` stay email-only?**
   - Resolution: Yes. Preserve `add_rfc_required_headers/1` as the `%Swoosh.Email{}`-only generic RFC helper, and introduce a separate message-aware compliance path for unsubscribe injection so stream context remains available through the atomic header step. This minimizes API churn while satisfying the stream-conditional RFC 8058 requirement. [VERIFIED: lib/mailglass/compliance.ex] [VERIFIED: .planning/phases/11-rfc-8058-list-unsubscribe/11-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core implementation and tests | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Running tests and route/task validation | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | Event/delivery persistence tests | ✓ [VERIFIED: local command] | `14.17` client; local server accepting on `/tmp:5432` [VERIFIED: `psql --version`] [VERIFIED: `pg_isready`] | — |
| Existing test harness | Phase validation | ✓ [VERIFIED: local command] | Existing `ExUnit` + `StreamData`; selected Phase 11-adjacent tests passed `18 tests / 2 properties / 0 failures` on 2026-04-28. [VERIFIED: `mix test test/mailglass/tracking/token_rotation_test.exs test/mailglass/tracking/open_redirect_test.exs test/mailglass/compliance_test.exs`] | — |

**Missing dependencies with no fallback:**
- None found in the current workspace for planning or local Phase 11 validation. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `ExUnit` + `StreamData 1.3.0` [VERIFIED: mix.exs] [VERIFIED: Hex API] |
| Config file | `test/test_helper.exs` plus case templates in `test/support/` [VERIFIED: test/test_helper.exs] [VERIFIED: test/support/data_case.ex] [VERIFIED: test/support/webhook_case.ex] |
| Quick run command | `mix test test/mailglass/tracking/token_rotation_test.exs test/mailglass/tracking/open_redirect_test.exs test/mailglass/compliance_test.exs` [VERIFIED: local command] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs aliases + repo test convention] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UNSUB-01 | current-endpoint sign/verify, previous-secret fallback, URL-length guard, expired-token error | unit + property | `mix test test/mailglass/compliance/unsubscribe_test.exs test/mailglass/properties/unsubscribe_property_test.exs -x` | ❌ Wave 0 |
| UNSUB-02 | both headers injected atomically; present on `:bulk`, absent on `:transactional`, opt-in on `:operational` | unit + lint/integration | `mix test test/mailglass/compliance/unsubscribe_test.exs -x` | ❌ Wave 0 |
| UNSUB-03 | GET fallback/redirect; POST 200/no redirect/idempotent/event append | controller/integration | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs -x` | ❌ Wave 0 |
| UNSUB-04 | router macro mount behavior, helper path, generator instructions, route smoke | macro/integration | `mix test test/mailglass/router/unsubscribe_router_test.exs test/mix/tasks/mailglass.gen.unsubscribe_test.exs -x` | ❌ Wave 0 |
| UNSUB-05 | rotation boundary, expiry, repeated POST convergence, SSRF/open-redirect resistance | property | `mix test test/mailglass/properties/unsubscribe_property_test.exs -x` | ❌ Wave 0 |
| UNSUB-06 | guide examples and setup snippets stay current | docs/smoke | `mix test test/mailglass/docs/unsubscribe_guide_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/compliance/unsubscribe_test.exs test/mailglass/compliance/unsubscribe_controller_test.exs -x`
- **Per wave merge:** `mix test test/mailglass/properties/unsubscribe_property_test.exs -x`
- **Phase gate:** `mix test --warnings-as-errors`

### Wave 0 Gaps

- [ ] `test/mailglass/compliance/unsubscribe_test.exs` — covers `UNSUB-01` and `UNSUB-02`.
- [ ] `test/mailglass/compliance/unsubscribe_controller_test.exs` — covers `UNSUB-03`.
- [ ] `test/mailglass/router/unsubscribe_router_test.exs` — covers `UNSUB-04`.
- [ ] `test/mailglass/properties/unsubscribe_property_test.exs` — covers `UNSUB-01`, `UNSUB-03`, and `UNSUB-05`.
- [ ] `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` — covers `UNSUB-04`.
- [ ] `test/mailglass/docs/unsubscribe_guide_test.exs` — covers `UNSUB-06`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: RFC 8058 POST is token-authenticated rather than session-authenticated] | Token authenticity comes from `Phoenix.Token`, not user login. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| V3 Session Management | yes [CITED: RFC 8058 forbids cookies and auth context on POST] | POST handler must ignore cookies/session context and operate solely from the token. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] |
| V4 Access Control | yes [VERIFIED: phase scope] | Opaque signed token plus tenant-scoped delivery lookup. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] [VERIFIED: lib/mailglass/tenancy.ex] |
| V5 Input Validation | yes [VERIFIED: phase scope] | Binary token validation, URL-length guard, and strict header injection rules. [VERIFIED: .planning/REQUIREMENTS.md] |
| V6 Cryptography | yes [VERIFIED: phase scope] | `Phoenix.Token` with endpoint or raw secret-key-base context; no custom crypto. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Token tampering | Tampering | `Phoenix.Token.verify/4` must reject modified tokens before any DB work. [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] |
| Forced unsubscribe via predictable URLs | Spoofing | RFC 8058 recommends an opaque or hard-to-forge component in the URI, which `Phoenix.Token` provides. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] |
| CSRF/session confusion on POST | Spoofing / Elevation | RFC 8058 says POST must not rely on cookies or auth context, so handler logic must remain token-only. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] |
| Replay / repeated clicks | Repudiation / Tampering | Deterministic event idempotency key keeps repeated POSTs as 200 no-ops. [VERIFIED: lib/mailglass/events.ex] [VERIFIED: lib/mailglass/idempotency_key.ex] |
| Open redirect / SSRF through unsubscribe URLs | Tampering | Keep the token payload to `delivery_id` only and generate URLs from trusted config plus optional tenant host callback, not from untrusted query params. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mailglass/tracking/token.ex] |
| Route shadowing | Denial of Service | Route smoke tests and explicit mount-path validation are required because Phoenix matches top to bottom. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |

## Sources

### Primary (HIGH confidence)
- `https://www.rfc-editor.org/rfc/rfc8058.txt` - one-click unsubscribe header, POST, DKIM, no-cookie, and no-redirect requirements.
- `https://www.rfc-editor.org/rfc/rfc2369.txt` - List-Unsubscribe header semantics and multi-URL ordering rules.
- `https://www.rfc-editor.org/rfc/rfc5322.txt` - header line length limits used for the 900-byte implementation guardrail.
- `https://hexdocs.pm/phoenix/Phoenix.Token.html` - token signing and verification contexts, including raw secret-key-base usage.
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` - route ordering and scope/pipeline behavior.
- `https://hex.pm/api/packages/phoenix` - Phoenix current release version/date.
- `https://hex.pm/api/packages/stream_data` - StreamData current release version/date.
- `https://hex.pm/api/packages/swoosh` - Swoosh current release version/date.
- Local codebase files verified in this session: `CLAUDE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md`, `lib/mailglass/tracking.ex`, `lib/mailglass/tracking/token.ex`, `lib/mailglass/compliance.ex`, `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/outbound/projector.ex`, `lib/mailglass/events.ex`, `lib/mailglass/idempotency_key.ex`, `lib/mailglass/tenancy.ex`, `lib/mailglass/webhook/router.ex`, `mailglass_admin/lib/mailglass_admin/router.ex`, `test/mailglass/tracking/token_rotation_test.exs`, `test/mailglass/tracking/open_redirect_test.exs`, `test/mailglass/compliance_test.exs`, `test/support/data_case.ex`, `test/support/webhook_case.ex`, `test/test_helper.exs`.

### Secondary (MEDIUM confidence)
- None. [VERIFIED: source audit]

### Tertiary (LOW confidence)
- None beyond the explicit `[ASSUMED]` items logged above. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phoenix, StreamData, and Swoosh versions and roles were verified against Hex and the repo. [VERIFIED: Hex API] [VERIFIED: mix.exs]
- Architecture: MEDIUM - repo fit is well verified, but exact route-collision enforcement and lifecycle-hook scope remain open. [VERIFIED: codebase audit] [ASSUMED]
- Pitfalls: HIGH - the main pitfalls are directly grounded in RFC 8058, Phoenix docs, and existing repo seams. [CITED: https://www.rfc-editor.org/rfc/rfc8058.txt] [CITED: https://hexdocs.pm/phoenix/Phoenix.Token.html] [VERIFIED: codebase audit]

**Research date:** 2026-04-28 [VERIFIED: workspace date]
**Valid until:** 2026-05-28 for standards and Phoenix versions; re-check before execution if Phase 11 planning slips past 30 days. [ASSUMED]
