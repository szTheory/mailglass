# Phase 3: Transport + Send Pipeline — Research

**Researched:** 2026-04-22
**Domain:** Elixir library — Swoosh-backed transactional email transport + Oban-composed send pipeline + ETS rate limiting + ownership-based test Fake
**Confidence:** HIGH on locked decisions (CONTEXT.md has 39 Ds); MEDIUM on a handful of discretionary details flagged inline.

---

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions (must honor verbatim — do not re-litigate)

**Fake adapter + test tooling (D-01..D-08)**
- **D-01**: Fake storage = supervised GenServer + named public ETS table keyed by owner pid, with `$callers` + allow-list resolution. Table name `:mailglass_fake_mailbox`. GenServer `Mailglass.Adapters.Fake.Storage` owns ownership mutations + monitors owner pids for auto-cleanup. Records `%Mailglass.Message{}`, NOT raw `%Swoosh.Email{}`. Mirrors `Swoosh.Adapters.Sandbox` verbatim.
- **D-02**: `Mailglass.Adapters.Fake.Supervisor` unconditionally started in `Mailglass.Application` after `Mailglass.Repo`. Idle cost ≈ 2KB + one process. Name `Mailglass.Adapters.Fake.Storage` reserved in `api_stability.md`.
- **D-03**: Fake simulation API funnels every event through the real write path via `trigger_event/3` → `Repo.transact(fn -> Events.append_multi + Projector.update_projections end)`. **Same write path Phase 4 webhook ingest uses.** Public functions: `deliveries/1`, `clear/1`, `last_delivery/1`, `trigger_event/3`, `advance_time/1`.
- **D-04**: `Mailglass.Outbound.Projector.update_projections/2` gets extended to `Phoenix.PubSub.broadcast` AFTER every successful commit. Topics: `mailglass:events:{tenant_id}` + `mailglass:events:{tenant_id}:{delivery_id}`. Payload `{:delivery_updated, delivery_id, event_type, meta}`. Broadcast failure never rolls back (broadcast after `Repo.transact/1` commits).
- **D-05**: `Mailglass.TestAssertions` — 4 matcher styles: `assert_mail_sent/0,1` (keyword, struct pattern via macro, predicate fn), `last_mail/0`, `wait_for_mail/1`, `assert_no_mail_sent/0`, `assert_mail_delivered/2`, `assert_mail_bounced/2`. Macro form via `defmacro` so adopters write `%{mailable: UserMailer}` without quoting.
- **D-06**: `Mailglass.MailerCase` is `async: true` by default. Setup: Ecto sandbox + `Fake.checkout()` + Tenancy stamp + PubSub subscribe + optional Clock freeze. Override via `@tag tenant:`, `@tag frozen_at:`, `@tag oban:`. Global opt-out via `setup :set_mailglass_global`.
- **D-07**: `Mailglass.Clock` = runtime-configurable module. Three-tier: Process.get frozen_at → Application.get_env impl module (default `Mailglass.Clock.System`) → `DateTime.utc_now/0`. `Mailglass.Clock.Frozen.freeze/1` + `advance/1` mutate process-dict key `:mailglass_clock_frozen_at`. Per-process isolation is `async: true`-safe.
- **D-08**: `Oban.Testing` mode is `:inline` by default in `MailerCase`. `@tag oban: :manual` opts into `assert_enqueued`/`perform_job/2` pattern.

**Mailable + Outbound public API (D-09..D-17)**
- **D-09**: `use Mailglass.Mailable, stream:, tracking:, from_default:, reply_to_default:` injects exactly **15 lines** (≤20 per LINT-05). Injects: `@behaviour`, `@before_compile`, `@mailglass_opts unquote(opts)`, `import Swoosh.Email`, `import Mailglass.Components`, `def new/0`, `def render/3`, `def deliver/2`, `def deliver_later/2`, `defoverridable` list. NO `import Phoenix.Component`. NO `preview_props/0` default (optional callback).
- **D-10**: Adopter convention = Shape (B): `MyApp.UserMailer.welcome(user) |> MyApp.UserMailer.deliver()`. Injected `deliver/2` is `defdelegate deliver(msg, opts), to: Mailglass.Outbound, as: :send`. No separate `MyApp.Mailer` (Phoenix.Swoosh Shape C) — mailglass config is global.
- **D-11**: Three tiers of declaration by change frequency:
  - `use` opts (static, compile-time): `stream`, `tracking`, `from_default`, `reply_to_default`. Both stream and tracking are compile-time known (required for Phase 6 AST checks).
  - Runtime builder functions: `subject/2`, `to/2`, assigns, per-call `from/2` override.
  - NO module attributes (no `@subject`, no `@from`) and NO `subject/1` callback.
- **D-12**: `preview_props/0` is optional zero-arity callback on the mailable module, returning `[{atom, map}]`. Declared via `@optional_callbacks preview_props: 0`.
- **D-13**: `deliver/2` canonical in public docs. `send/2` is internal verb in `Mailglass.Outbound`. `defdelegate deliver(msg, opts), to: __MODULE__, as: :send`.
- **D-14**: `deliver_later/2` returns `{:ok, %Delivery{status: :queued}}` uniformly. Delivery row inserted synchronously inside the same Multi that calls `Oban.insert/3`; Oban job carries `delivery_id` string. Task.Supervisor fallback: same synchronous Delivery insert + `Task.Supervisor.async_nolink/3`. **Oban leakage (returning `%Oban.Job{}`) is explicitly rejected.**
- **D-15**: `deliver_many/2` returns `{:ok, [%Delivery{}]}` always. Each Delivery carries `:status` (`:queued | :sent | :failed`) and `:last_error`. Idempotency-key replay automatic: `sha256(tenant_id <> mailable <> recipient <> content_hash)`. Batch grouping: one outer `Ecto.Multi` per call, batched via `Multi.insert_all`, one `Events.append_multi` per insert, one `Oban.insert_all` for job tails.
- **D-16**: Bang variants raise the underlying `%Mailglass.Error{}` struct directly. `deliver!/2` raises `%SendError{} | %SuppressedError{} | %RateLimitError{} | %TemplateError{}`. `deliver_many!/2` raises `%Mailglass.Error.BatchFailed{failures: [%Delivery{}]}` iff any `status: :failed`. **`deliver_later!/2` does NOT exist.**
- **D-17**: Oban-fallback warning fires exactly once at `Mailglass.Application.start/2`, gated by `:persistent_term.put({:mailglass, :oban_warning_emitted}, true)`. Emit only when Oban absent AND `:async_adapter` is not `:task_supervisor`.

**Send pipeline internals (D-18..D-29)**
- **D-18**: Preflight = 5 named stages + 1 precondition:
  0. `Tenancy.assert_stamped!/0` — precondition; raises `%TenancyError{type: :unstamped}`
  1. `Suppression.check_before_send/1` → `{:error, %SuppressedError{}}` short-circuit
  2. `RateLimiter.check/3` → `{:error, %RateLimitError{}}` short-circuit
  3. `Stream.policy_check/1` — no-op seam at v0.1
  4. `Renderer.render/2` → `{:error, %TemplateError{}}` short-circuit
  5. Persist (Ecto.Multi)
- **D-19**: Render is LATE (after preflight). Suppression lookup ~100μs, rate-limit ~10μs, render ~4ms.
- **D-20**: Sync `send/2` = TWO Multis separated by the adapter call. Adapter-call-in-transaction is a hard no. Multi#1: Delivery insert + Events `:queued` + commit. Adapter call OUTSIDE any transaction. Multi#2: Projector update + Events `:dispatched` + commit. Orphan `:queued` recoverable via `Events.Reconciler` with orphan-age ≥5min.
- **D-21**: Async `deliver_later/2` = single `Oban.insert/3`-composed Multi. `Multi.new() |> Multi.insert(:delivery, ...) |> Events.append_multi(:event_queued, ...) |> Oban.insert(:job, fn %{delivery: d} -> Worker.new(%{"delivery_id" => d.id, "mailglass_tenant_id" => Tenancy.current()}) end) |> Repo.transact()`. Worker runs adapter OUTSIDE any transaction, then Multi#2. Phase 2 TenancyMiddleware.wrap_perform restores tenant. Task.Supervisor fallback explicitly re-stamps via `Tenancy.with_tenant/2`.
- **D-22**: RateLimiter ETS ownership = Pattern A (tiny supervisor + init-and-idle `TableOwner` GenServer). Table `:mailglass_rate_limit` (`:set, :public, :named_table, read_concurrency: true, write_concurrency: :auto, decentralized_counters: true`). Hot path pure `:ets.update_counter/4`. Table survives crash via supervisor restart (counters reset; acceptable).
- **D-23**: Token bucket = leaky bucket with continuous refill, single atomic `:ets.update_counter/4` multi-op. Per-key state `{key, tokens, last_refill_ms}`. Default: `capacity = 100, refill_per_ms = 100/60_000`. Hot-path ≈1-3μs on OTP 27. Over-limit: `{:error, %RateLimitError{retry_after_ms: ceil(1 / refill_per_ms)}}`.
- **D-24**: `:transactional` stream bypasses rate limiting unconditionally. `:operational` + `:bulk` throttle. Documented as a reserved invariant.
- **D-25**: `Mailglass.Stream.policy_check/1` = no-op seam at v0.1. Emits `[:mailglass, :outbound, :stream_policy, :stop]`. v0.5 DELIV-02 swaps impl without touching callers.
- **D-26**: Telemetry granularity = 1 outer span + 3 inner spans + 2 single-emit events:
  - `[:mailglass, :outbound, :send, :*]` — outer span per `send/2`
  - `[:mailglass, :render, :message, :*]` — full span (Phase 1 extended)
  - `[:mailglass, :persist, :outbound, :multi, :*]` — full span around each Multi commit
  - `[:mailglass, :outbound, :dispatch, :*]` — full span wrapping adapter call
  - `[:mailglass, :outbound, :suppression, :stop]` — single emit `%{hit, duration_us}`
  - `[:mailglass, :outbound, :rate_limit, :stop]` — single emit `%{allowed, duration_us}`
- **D-27**: `Mailglass.PubSub.Topics` typed builder. Functions: `events(tenant_id)`, `events(tenant_id, delivery_id)`, `deliveries(tenant_id)`. All `mailglass:`-prefixed. Projector broadcasts on BOTH `events(tenant_id)` and `events(tenant_id, delivery_id)`.
- **D-28**: `Mailglass.SuppressionStore.ETS` ships in Phase 3. Same behaviour surface as `.Ecto`. Test-override via `config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS`.
- **D-29**: `Mailglass.Adapters.Swoosh` wraps any `Swoosh.Adapter` (TRANS-03). Returns `{:ok, %{message_id: String.t(), provider_response: term()}}`. Error mapping: `{:error, {:api_error, status, body}}` → `%SendError{type: :adapter_failure, cause: %Swoosh.DeliveryError{...}, context: %{provider_status: status, provider_module: m}}`.

**Tracking opt-in + click rewriting (D-30..D-39)**
- **D-30**: Per-mailable tracking = compile-time `use` opt only. AST-inspectable. No runtime `Message.put_tracking/2`. Adopters can DISABLE at runtime (`tracking: false`), never ENABLE.
- **D-31**: `opens` and `clicks` are independent booleans, default `false`. `:unsubscribe_tracking:` separate v0.5 key.
- **D-32**: Tracking host globally required when any mailable opts in. NimbleOptions `required: true` (conditional). Boot fails with `%ConfigError{type: :missing, context: %{key: :tracking_host}}` on omission. Optional `c:tracking_host/1` callback on `Mailglass.Tenancy` for per-tenant subdomains.
- **D-33**: `Phoenix.Token` rotation via salts list. Head signs; all verify. `key_iterations: 1000, key_length: 32, digest: :sha256, max_age: 2 * 365 * 86_400`.
- **D-34**: Open pixel URL: `GET https://track.example.com/o/<token>.gif`. Token = `Phoenix.Token.sign(endpoint, hd(salts), {:open, delivery_id, tenant_id})`. 43-byte transparent GIF89a, `Content-Type: image/gif`, no-cache headers.
- **D-35**: Click URL — pattern (a), full URL encoded inside signed token. `GET https://track.example.com/c/<token>`, token = `{:click, delivery_id, tenant_id, target_url}`. Server verifies, 302 redirects. **No `?r=` param → open-redirect structurally impossible.** Dedupe GETs within 2s per `(delivery_id, user_agent_hash)`.
- **D-36**: Link-rewriting scope: only `<a href="http(s)://...">` in HTML body. Skip: `mailto:`, `tel:`, `sms:`, fragments, `data:`, `javascript:`, scheme-less, `<a data-mg-notrack>`, `<a>` in `<head>`. Plaintext body NEVER rewritten.
- **D-37**: Open pixel injection = last child of `<body>`, `<img width="1" height="1" alt="" style="display:block;...">`.
- **D-38**: Runtime behavior when TRACK-02 auth-stream heuristic is bypassed = **RAISE**. Runtime guard in `Outbound.send/2` inspects mailable's compile-time `@mailglass_opts`; if tracking enabled AND function name matches `magic_link|password_reset|verify_email|confirm_account` regex, raise `%ConfigError{type: :tracking_on_auth_stream}`. **Dual enforcement with Phase 6 Credo.**
- **D-39**: `tenant_id` lives ONLY in signed token payload, NEVER in URL path/query. Failed verification: HTTP 204 pixel / HTTP 404 click. No enumeration.

### Claude's Discretion (research options, recommend)

- Exact `Mailglass.Mailable` moduledoc wording.
- Exact `Mailglass.Outbound.Delivery.new/1` helper signature for `deliver_many/2` batch construction.
- Exact telemetry measurement structure for single-emit events (`:duration_us` vs `measurements.duration`) — follow Phase 1 precedent.
- Exact error-mapping table in `Mailglass.Adapters.Swoosh` for Postmark + SendGrid shapes (v0.1 covers documented error vocab; v0.5 extends).
- Tracking endpoint's Plug pipeline composition (CachingBodyReader NOT needed).
- Fake adapter JSON-compatibility format.
- `Mailglass.PubSub` supervision: Phase 3 adds `{Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2}` to `Mailglass.Application` (after `Repo`, before `Fake.Supervisor`).
- `Mailglass.Outbound.Worker` Oban-queue name (`:mailglass_outbound`), max_attempts (20), unique constraint (per `delivery_id`).
- Exact `MailerCase` `@tag` vocabulary (`:tenant`, `:frozen_at`, `:oban`) — extend as tests need.

### Deferred Ideas (OUT OF SCOPE — Phase 3 ships seams only)

- Per-tenant adapter resolver (v0.5 DELIV-07).
- `:pg`-coordinated cluster rate-limiting (v0.5 DELIV-08).
- List-Unsubscribe + RFC 8058 header injection (v0.5 DELIV-01).
- Stream-policy enforcement beyond no-op (v0.5 DELIV-02).
- `Mailglass.SuppressionStore.Redis` (v0.5+).
- DKIM signing helper for self-hosted SMTP (v0.5 DELIV-09).
- `mix mail.doctor` deliverability checks (v0.5 DELIV-06).
- Per-call `tracking: [opens: true]` override (deliberately rejected — breaks AST inspectability).
- Sliding-window rate limiting (leaky-bucket is sufficient).
- `deliver_later!/2` (deliberately rejected — enqueue isn't a delivery).
- Mandatory `preview_props/0` (deliberately optional).
- `Message.put_tracking/2` runtime function (deliberately not shipped).
- Sync `send/2` single-Multi with adapter-inside-transaction (deliberately rejected).
- Webhook plug + HMAC verification (Phase 4 HOOK-01..07).
- Preview LiveView admin (Phase 5 PREV-01..06).
- 12 custom Credo checks (Phase 6).
- Installer (Phase 7).

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **AUTHOR-01** | `use Mailglass.Mailable` behaviour + `deliver/2`; `use` injects ≤20 lines; returns `%Mailglass.Message{}`. | D-09 (15-line injection), D-10 (Shape B adopter convention), D-11 (3-tier declaration), D-13 (deliver/send alias). §4 (Mailable macro design). |
| **TRANS-01** | `Mailglass.Adapter` behaviour defines `deliver(message, opts) :: {:ok, %{message_id, provider_response}} | {:error, %Mailglass.Error{}}`. Locked in `api_stability.md`. | D-29 (Swoosh wrapper return shape). §6 (Swoosh bridge purity). LIB-04. |
| **TRANS-02** | `Mailglass.Adapters.Fake` is stateful, in-memory, time-advanceable, records sent messages, supports `trigger_event/2` and `advance_time/1`. State JSON-compatible. **Merge-blocking release gate.** | D-01..D-03 (Sandbox-mirror pattern, trigger_event flows through real Projector, advance_time delegates to Clock.Frozen). §1 (Fake contract + storage). |
| **TRANS-03** | `Mailglass.Adapters.Swoosh` wraps any Swoosh.Adapter; normalizes errors into `%Mailglass.Error{}`. | D-29 (error mapping table + telemetry wrap). §6 (pure bridge). |
| **TRANS-04** | `Mailglass.Outbound.send/2` + `deliver/2` (alias) + `deliver_later/2` + `deliver_many/2`. All four return `{:ok, %Delivery{}} | {:error, %Mailglass.Error{}}`. Bang variants raise. | D-13..D-16 (return shapes, bang semantics). §2 (Multi composition). §7 (deliver_many semantics). |
| **SEND-01** | Pre-send pipeline: `Tenancy.assert_stamped! → Suppression.check_before_send → RateLimiter.check → Stream.policy_check → render → Multi(Delivery + Event(:queued) + Oban enqueue)`. Each stage emits telemetry. | D-18 (revised stage order), D-19 (render LATE rationale), D-26 (telemetry structure). §5 (preflight pipeline). spec_lock (SEND-01 amendment). |
| **SEND-02** | `Mailglass.RateLimiter` ETS token bucket per `(tenant_id, recipient_domain)`. Default 100/min. Over-limit returns `%RateLimitError{retry_after_ms:}`. ETS owned by small supervisor, NOT serialization GenServer. | D-22 (ownership pattern), D-23 (token bucket math), D-24 (:transactional bypass). §4 (rate limiter design). LIB-05. |
| **SEND-03** | `Mailglass.Outbound.Worker` = Oban worker. Without Oban, `Task.Supervisor.async_nolink` fallback + one `Logger.warning` at boot. | D-17 (boot warning with persistent_term), D-21 (Worker + Multi shape), §3 (Oban gateway). |
| **SEND-04** | `Mailglass.Suppression.check_before_send/1` queries suppression store. Returns `{:error, %SuppressedError{}}` if hit. `SuppressionStore` behaviour with Ecto default. | D-18 (stage 1), D-28 (ETS impl lands this phase). Phase 2 already shipped the behaviour + Ecto impl. |
| **SEND-05** | `Mailglass.PubSub.Topics` = typed topic builder. All topics prefixed `mailglass:`. | D-04 (Projector broadcast after commit), D-27 (builder functions). |
| **TRACK-01** | Open/click tracking off by default. No pixel injection / link rewriting unless `tracking: [opens: true, clicks: true]` set per-mailable. | D-30 (compile-time `use` opt only), D-31 (independent booleans), D-37 (pixel injection), D-38 (runtime auth-stream guard). §Tracking. MAIL-01. |
| **TRACK-03** | Click rewriting uses `Phoenix.Token`-signed tokens with rotation. Tracking host separate subdomain. SSRF/open-redirect prevented. | D-32 (host required config), D-33 (salts rotation), D-34 (pixel URL), D-35 (click URL pattern (a) — no ?r= param). §Tracking. |
| **TEST-01** | `Mailglass.TestAssertions` extends Swoosh's: `assert_mail_sent/1`, `assert_no_mail_sent/0`, `last_mail/0`, `wait_for_mail/1`, `assert_mail_delivered/2`, `assert_mail_bounced/2`. | D-05 (4 matcher styles + receive-based assert_mail_delivered/bounced). §9 (test assertions). |
| **TEST-02** | Per-domain Case templates: `MailerCase`, `WebhookCase`, `AdminCase`. Each sets up Ecto sandbox + Fake + actor. | D-06 (MailerCase shape, async: true default). §9. |
| **TEST-05** | `Mailglass.Clock` injection point. Tests use `Clock.Frozen`; production uses `Clock.System`. | D-07 (three-tier resolution, per-process isolation). TEST-06. |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

These carry the same authority as locked decisions. Research and plans must NOT recommend approaches that contradict them.

- **`Application.compile_env*` is forbidden outside `Mailglass.Config`.** All runtime config reads route through `Application.get_env/2`. Phase 6 LINT-08 enforces; Phase 3 must not regress.
- **`mailglass_events` UPDATE/DELETE is forbidden.** The SQLSTATE 45A01 trigger translates to `%EventLedgerImmutableError{}`. Phase 3 writes append-only via `Events.append_multi/3`.
- **PII in telemetry is forbidden.** Whitelisted keys: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. Forbidden: `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`. Phase 6 LINT-02 enforces.
- **`Swoosh.Mailer.deliver/1` MUST NOT be called from mailglass library code.** Route through `Mailglass.Outbound.*`. Phase 6 LINT-01 enforces.
- **`Mailglass.SignatureError` raises with no recovery.** (Phase 4 concern, but error struct already exists.)
- **Error structs are pattern-matched by struct, not message string.** Closed `:type` atom sets documented in `docs/api_stability.md`.
- **No `name: __MODULE__` singletons in library code.** Phase 6 LINT-07 enforces; Phase 3 RateLimiter follows the supervisor-owned ETS pattern (D-22).
- **Open/click tracking off by default.** `NoTrackingOnAuthStream` Credo check raises at compile time (Phase 6); Phase 3 adds the runtime guard (D-38).
- **No marketing-email features.** Tracking endpoint is strictly open-pixel + click redirect; no campaign, segmentation, or A/B logic.

---

## Executive Summary

Phase 3 is the **working-core milestone**: after it closes, an adopter can write a `use Mailglass.Mailable` module in 15 lines, pipe through `MyApp.UserMailer.welcome(user) |> MyApp.UserMailer.deliver()`, and see a `%Delivery{status: :sent}` come back with the Fake adapter recording the message and `assert_mail_sent(subject: "Welcome")` passing in a 20-line test file. The 39 locked decisions in CONTEXT.md cover every load-bearing design question; this research fills in the HOW.

**Primary recommendation:** Mirror `Swoosh.Adapters.Sandbox` verbatim for the Fake (D-01 locks this). The ownership-by-pid + `$callers` + allow-list pattern is already solved for LiveView, Oban workers, and Playwright/Wallaby browser tests — inheriting it gets us async-safe testing at scale for free. Divergences from Sandbox are minimal: record `%Mailglass.Message{}` instead of raw `%Swoosh.Email{}` so `assert_mail_sent(mailable: UserMailer)` works; add `trigger_event/3` that funnels through the real `Events.append_multi/3 + Projector.update_projections/2` write path so the Fake proves the production write path.

**Plan decomposition hint (planner's discretion — 6 plans is the natural granularity):**
1. Wave 0 scaffold: `Mailglass.Clock` + `MailerCase` stub + Swoosh Sandbox integration probe + `api_stability.md` extensions + PubSub supervisor child + Tenancy `assert_stamped!/0` extension.
2. Fake adapter (Storage GenServer + ownership API + `trigger_event/3` + `advance_time/1`) + `Mailglass.Adapter` behaviour + `Mailglass.Adapters.Swoosh` wrapper.
3. RateLimiter (Supervisor + TableOwner + `check/3`) + Stream.policy_check seam + Suppression.check_before_send facade + SuppressionStore.ETS impl.
4. `Mailglass.Mailable` behaviour + `use` macro + Message builders + Phase 3 Projector extension (PubSub broadcast).
5. `Mailglass.Outbound` facade (sync + async hot path) + `Mailglass.Outbound.Worker` (Oban gateway) + Task.Supervisor fallback + `deliver_many/2`.
6. `Mailglass.Tracking` (Rewriter + pixel URL + click URL + signed-token endpoint) + `Mailglass.TestAssertions` + runtime auth-stream guard (D-38) + phase-wide `mix verify.core_send` + integration test.

**Why this ordering:** Each plan adds exactly one concern on top of the previous. Plan 5 is the hot-path convergence (where end-to-end Mailable → Delivery → Fake tests pass). Plan 6 isolates TRACK-03 complexity (signed tokens, Plug endpoint) and the integration test gate. Wave 0 unblocks parallel plan drafting without forcing sequential execution.

---

## Architectural Responsibility Map

Per the architecture-check step, here is the tier ownership for Phase 3 capabilities. This is an Elixir library (no browser / SSR tiers) — the relevant tiers are **Library / public API**, **OTP / supervision**, **Persistence / Postgres**, and **Test harness / helpers**.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `use Mailglass.Mailable` macro + `@before_compile` | Library / public API | — | Compile-time DX; no runtime tier involvement. |
| `Mailglass.Outbound.send/2` + `deliver/2` | Library / public API | Persistence (Multi) | Pure function orchestrator; Postgres owns state. |
| `Mailglass.Outbound.Worker` (Oban job) | OTP / background | Persistence | Adapter call OUTSIDE transaction; Multi#2 writes result. |
| Task.Supervisor fallback | OTP / supervision | — | Non-durable async when Oban absent. |
| `Mailglass.RateLimiter` | OTP / ETS | Library facade | Hot-path `:ets.update_counter` from caller process; TableOwner GenServer only owns the table. |
| `Mailglass.Adapters.Fake.Storage` | OTP / ETS | Test harness | Same pattern as RateLimiter; GenServer monitors owner pids, ETS reads bypass mailbox. |
| `Mailglass.Adapters.Swoosh` | Library / bridge | External HTTP (Swoosh) | Stateless function; caller's process owns the HTTP request. |
| `Mailglass.Clock` | Library | Test harness | Process-dict isolation via `Clock.Frozen`; prod impl delegates `DateTime.utc_now/0`. |
| `Mailglass.PubSub` supervision | OTP / supervision | Library facade | `Phoenix.PubSub` child owned by `Mailglass.Application`. |
| Projector PubSub broadcast (D-04) | Library facade | OTP | Broadcast after `Repo.transact` commits; broadcast failure does not roll back. |
| `Mailglass.TestAssertions` | Test harness | — | Lives in `lib/` (exported for adopter consumption). |
| `Mailglass.Tracking` endpoint | Plug / HTTP | Library (token verification) | Pixel GIF + click 302; owned by adopter's Endpoint router. |

**Tier-assignment pitfalls to avoid:**
- The Fake's `trigger_event/3` must NOT short-circuit the Projector — routing through Phase 2's real write path is a structural property (D-03) that keeps the Fake in sync with the production write path when Phase 4 lands.
- The RateLimiter `TableOwner` is an init-and-idle GenServer; `handle_call/cast/info` are NOT implemented. Putting rate-limit logic inside the GenServer would create a serialization bottleneck and violate LIB-06.
- The Outbound facade MUST orchestrate the Multi outside any process — Multi construction is pure data. The only process involvement is `Repo.transact/1` at commit time.

---

## 1. Fake Adapter Contract + API Surface

### 1.1 Storage pattern — verbatim Swoosh.Adapters.Sandbox

The canonical reference is `deps/swoosh/lib/swoosh/adapters/sandbox.ex` + `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex`. Key properties Phase 3 inherits:

**Storage GenServer (D-01):** Named `Mailglass.Adapters.Fake.Storage`. In `init/1`, creates ETS table `:mailglass_fake_mailbox` with `[:set, :named_table, :public, {:read_concurrency, true}]`. Process state: `%{owners: MapSet.new(), allowed: %{}, shared: nil, monitors: %{}}`.

**Ownership resolution (adapted from Sandbox):**
```elixir
defp resolve_owner(config) do
  callers = [self() | List.wrap(Process.get(:"$callers"))]
  case Storage.find_owner(callers) do
    {:ok, owner} -> {:ok, owner}
    :no_owner ->
      case Storage.get_shared() do
        nil -> handle_unregistered!(config)
        shared -> {:ok, shared}
      end
  end
end
```

`$callers` is automatically set by `Task.Supervisor.async_nolink/3` and `Task.async/1`, so the Oban-absent fallback path inherits ownership for free. `allow(owner_pid, allowed_pid)` solves LiveView + Playwright cases where the delivering process has no `$callers` ancestry.

**ETS reads bypass the mailbox:**
```elixir
def deliveries(opts \\ []) do
  owner = Keyword.get(opts, :owner, self())
  case :ets.lookup(@table, owner) do
    [{^owner, messages}] -> filter_messages(messages, opts)
    [] -> []
  end
end
```

The GenServer only handles: `checkout`, `checkin`, `allow`, `set_shared`, `get_shared`, `find_owner`, `push`, `push_many`, `flush`, `{:DOWN, ...}` monitor cleanup. `deliveries/1` and `all/1` read ETS directly — no serialization.

**Divergence from Sandbox #1:** Record `%Mailglass.Message{}` not `%Swoosh.Email{}`. The Fake's `deliver/2` callback receives a `%Message{}` (the mailglass adapter behaviour carries Message, not raw Email). Ownership logic is unchanged; storage value differs.

**Divergence from Sandbox #2:** `send(owner_pid, {:mail, message})` replaces `send(owner_pid, {:email, email})`. The `Mailglass.TestAssertions` receive-based matchers pattern-match on `{:mail, ...}`.

### 1.2 Fake adapter public functions (D-03 locks these)

```elixir
@spec deliveries(keyword()) :: [recorded()]
# opts: :tenant, :mailable, :recipient, :owner. Defaults to current-owner pid.

@spec clear(keyword()) :: :ok
# Default: current owner. :all clears all owners.

@spec last_delivery(keyword()) :: recorded() | nil

@spec trigger_event(String.t(), atom(), keyword()) ::
        {:ok, %Events.Event{}} | {:error, term()}
# Looks up Delivery by provider_message_id, builds Events.Event,
# runs Mailglass.Repo.transact(fn -> Events.append_multi/3 + Projector.update_projections/2 end).
# Opts: :occurred_at, :reject_reason, :metadata.

@spec advance_time(integer() | Duration.t()) :: DateTime.t()
# Delegates to Mailglass.Clock.Frozen.advance/1.
```

`recorded()` type:
```elixir
@type recorded :: %{
  message: Mailglass.Message.t(),
  delivery_id: Ecto.UUID.t(),
  provider_message_id: String.t(),
  recorded_at: DateTime.t()
}
```

### 1.3 What `Mailglass.TestAssertions.assert_mail_sent/1` matches (D-05)

Four matcher styles:
```elixir
# Style 1: presence only
assert_mail_sent()  # expands to: assert_received {:mail, _}

# Style 2: keyword match (Swoosh pattern)
assert_mail_sent(subject: "Welcome", to: "user@example.com")
# Implementation: assert_received {:mail, %Message{swoosh_email: %{subject: "Welcome", to: [{_, "user@example.com"}]}}}

# Style 3: struct pattern macro
assert_mail_sent(%Mailglass.Message{mailable: MyApp.UserMailer})
# Macro expansion: assert_received {:mail, %Message{mailable: ^MyApp.UserMailer} = msg}
# Macro uses `defmacro` so users don't need to quote the pattern.

# Style 4: predicate function
assert_mail_sent(fn msg -> msg.stream == :transactional end)
# Implementation: assert_received {:mail, msg}; assert fn.(msg)
```

Additional matchers D-05 requires:
- `last_mail/0` — reads ETS `:ets.lookup(@table, self())` tail, returns latest.
- `wait_for_mail(timeout \\ 100)` — `assert_receive {:mail, _}, timeout`. Returns the message.
- `assert_no_mail_sent/0` — `refute_received {:mail, _}`.
- `assert_mail_delivered(msg_or_id, timeout \\ 100)` — subscribes to `mailglass:events:{tenant_id}:{delivery_id}`, `assert_receive {:delivery_updated, ^delivery_id, :delivered, _meta}, timeout`.
- `assert_mail_bounced(msg_or_id, timeout \\ 100)` — same shape, `:bounced` event type.

**Async: true implications:** The ETS table is named+public, but because entries are keyed by owner pid and each test process is its own owner, no two tests see each other's mail. LiveView/Oban/browser processes that need to send mail during a test must be `allow/2`'d by the test process before they deliver. This is the exact pattern `Swoosh.Adapters.Sandbox` solved.

---

## 2. Hot Path Multi Composition

### 2.1 Sync `send/2` path — two Multis (D-20)

```elixir
@spec send(Mailglass.Message.t(), keyword()) ::
        {:ok, %Mailglass.Outbound.Delivery{}} | {:error, Mailglass.Error.t()}
def send(%Message{} = msg, opts \\ []) do
  Telemetry.send_span(metadata(msg), fn ->
    with :ok <- Tenancy.assert_stamped!(),
         :ok <- Suppression.check_before_send(msg),
         :ok <- RateLimiter.check(msg.tenant_id, recipient_domain(msg), msg.stream),
         :ok <- Stream.policy_check(msg),
         {:ok, rendered} <- Renderer.render(msg),
         {:ok, %{delivery: delivery}} <- persist_queued(rendered) do
      dispatch_and_persist_result(delivery, rendered, opts)
    end
  end)
end
```

**Multi#1 (before adapter call):**
```elixir
defp persist_queued(rendered_msg) do
  ik = idempotency_key(rendered_msg)
  Multi.new()
  |> Multi.insert(:delivery,
       Delivery.changeset(%{
         tenant_id: rendered_msg.tenant_id,
         mailable: inspect(rendered_msg.mailable),
         stream: rendered_msg.stream,
         recipient: primary_recipient(rendered_msg),
         last_event_type: :queued,
         last_event_at: Mailglass.Clock.utc_now(),
         metadata: %{idempotency_key: ik}
       }))
  |> Events.append_multi(:event_queued, fn %{delivery: d} ->
       %{delivery_id: d.id, type: :queued, occurred_at: Mailglass.Clock.utc_now(),
         idempotency_key: ik, normalized_payload: %{}}
     end)
  |> Mailglass.Repo.transact()
end
```

**Adapter call (OUTSIDE any transaction):**
```elixir
defp dispatch_and_persist_result(%Delivery{} = delivery, rendered, opts) do
  adapter = resolve_adapter(opts)
  case Telemetry.dispatch_span(%{...}, fn -> adapter.deliver(rendered, opts) end) do
    {:ok, %{message_id: mid, provider_response: resp}} ->
      persist_dispatched(delivery, mid, resp)
    {:error, %Mailglass.Error{} = err} ->
      persist_failed(delivery, err)
  end
end
```

**Multi#2 (after adapter call):**
```elixir
defp persist_dispatched(%Delivery{} = delivery, provider_message_id, _response) do
  dispatched_event = %Events.Event{
    tenant_id: delivery.tenant_id,
    delivery_id: delivery.id,
    type: :dispatched,
    occurred_at: Mailglass.Clock.utc_now()
  }

  Multi.new()
  |> Multi.update(:delivery,
       delivery
       |> Ecto.Changeset.change(%{provider_message_id: provider_message_id})
       |> Ecto.Changeset.optimistic_lock(:lock_version))
  |> Multi.run(:projection, fn _repo, %{delivery: d} ->
       {:ok, Mailglass.Repo.update!(Projector.update_projections(d, dispatched_event))}
     end)
  |> Events.append_multi(:event_dispatched, %{delivery_id: delivery.id, type: :dispatched, occurred_at: dispatched_event.occurred_at})
  |> Mailglass.Repo.transact()
end
```

### 2.2 Async `deliver_later/2` path — single Multi (D-21)

```elixir
@spec deliver_later(Mailglass.Message.t(), keyword()) ::
        {:ok, %Delivery{status: :queued}} | {:error, Mailglass.Error.t()}
def deliver_later(%Message{} = msg, opts \\ []) do
  # Preflight identical to sync path (stages 0..4).
  with :ok <- Tenancy.assert_stamped!(),
       :ok <- Suppression.check_before_send(msg),
       :ok <- RateLimiter.check(msg.tenant_id, recipient_domain(msg), msg.stream),
       :ok <- Stream.policy_check(msg),
       {:ok, rendered} <- Renderer.render(msg) do
    enqueue_via_async_adapter(rendered, opts)
  end
end

defp enqueue_via_async_adapter(rendered, opts) do
  case Mailglass.OptionalDeps.Oban.available?() do
    true -> enqueue_oban(rendered, opts)
    false -> enqueue_task_supervisor(rendered, opts)
  end
end

defp enqueue_oban(rendered, opts) do
  ik = idempotency_key(rendered)
  tenant_id = Tenancy.current()

  Multi.new()
  |> Multi.insert(:delivery, Delivery.changeset(base_attrs(rendered, ik)))
  |> Events.append_multi(:event_queued, fn %{delivery: d} ->
       %{delivery_id: d.id, type: :queued, occurred_at: Mailglass.Clock.utc_now(),
         idempotency_key: ik}
     end)
  |> Oban.insert(:job, fn %{delivery: d} ->
       Mailglass.Outbound.Worker.new(
         %{"delivery_id" => d.id, "mailglass_tenant_id" => tenant_id},
         unique: [period: 3600, fields: [:args], keys: [:delivery_id]]
       )
     end)
  |> Mailglass.Repo.transact()
  |> case do
    {:ok, %{delivery: d}} -> {:ok, d}
    {:error, _step, err, _changes} -> {:error, translate_multi_error(err)}
  end
end
```

### 2.3 SQL-level idempotency-key UNIQUE index behavior

Phase 2 shipped the partial UNIQUE index on `mailglass_events.idempotency_key WHERE idempotency_key IS NOT NULL`. Phase 3's Multi#1 uses `Events.append_multi/3` which already sets `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}`. On replay:
1. The `:delivery` insert would normally produce a new row — but if we want batch-replay safety for `deliver_many/2` (D-15), the Delivery schema also needs an idempotency_key UNIQUE partial index OR callers compose with `on_conflict: {:replace_all_except, [...]}` + `conflict_target: {:unsafe_fragment, "idempotency_key"}` on the delivery insert as well.
2. **Planner's decision point (flagged for discuss-phase if unresolved):** Does `mailglass_deliveries` gain an `idempotency_key` column + partial UNIQUE index in Phase 3? Phase 2's schema doesn't have one — CONTEXT.md D-15 implies it's computed but stored in `metadata.idempotency_key`. If stored there, the UNIQUE index on jsonb is possible but heavier than a dedicated column. **Recommendation:** add a nullable `idempotency_key` column to `mailglass_deliveries` in a Phase 3 migration (one-line schema bump), with partial UNIQUE index. The `Delivery.changeset/2` populates it; `deliver_many/2` batch replays are trivially safe via `ON CONFLICT (idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING RETURNING *`. `[ASSUMED]` this is acceptable given CONTEXT.md D-15's "computed idempotency_key" intent — needs confirmation.

---

## 3. Oban Optional-Dep Gateway

### 3.1 `Mailglass.OptionalDeps.Oban` is Phase 1 shipped

`lib/mailglass/optional_deps/oban.ex` already declares `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}` and exposes `available?/0` via `Code.ensure_loaded?(Oban)`. Phase 2 added `Mailglass.Oban.TenancyMiddleware` (conditionally compiled, same file). **Phase 3 adds nothing to the gateway module itself** — it consumes.

### 3.2 `Mailglass.Outbound.Worker` — conditional compilation

```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Outbound.Worker do
    use Oban.Worker,
      queue: :mailglass_outbound,
      max_attempts: 20,
      unique: [period: 3600, fields: [:args], keys: [:delivery_id]]

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) do
      Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
        Mailglass.Outbound.dispatch_by_id(id)
      end)
    end
  end
end
```

The entire `defmodule` is elided when Oban is absent, matching the `TenancyMiddleware` pattern. `mix compile --no-optional-deps --warnings-as-errors` stays green because no code outside the `if` block references `Oban.Worker`.

### 3.3 Boot warning via `:persistent_term` (D-17)

```elixir
# lib/mailglass/application.ex
def start(_type, _args) do
  Mailglass.Config.validate_at_boot!()
  maybe_warn_missing_oban()  # refactored from existing Phase 1 version
  children = build_children()
  Supervisor.start_link(children, strategy: :one_for_one, name: Mailglass.Supervisor)
end

defp maybe_warn_missing_oban do
  configured = Application.get_env(:mailglass, :async_adapter)
  already_warned? = :persistent_term.get({:mailglass, :oban_warning_emitted}, false)

  cond do
    already_warned? -> :ok
    configured == :task_supervisor -> :ok
    Code.ensure_loaded?(Oban) -> :ok
    true ->
      Logger.warning("""
      [mailglass] Oban not loaded; deliver_later/2 will use Task.Supervisor (non-durable).
      Set config :mailglass, async_adapter: :task_supervisor to silence this warning,
      or add {:oban, "~> 2.19"} to your deps for durable async delivery.
      """)
      :persistent_term.put({:mailglass, :oban_warning_emitted}, true)
  end
end
```

**Why `:persistent_term` not `Application.put_env`:** `:persistent_term` is idempotent and has O(1) read — subsequent `Mailglass.Application.start/2` calls (in test scenarios, or on supervisor restart) won't re-emit. `Application.put_env` would work too but leaks into adopter telemetry of `Application.get_all_env(:mailglass)`.

### 3.4 Task.Supervisor fallback — supervision tree shape

```elixir
# Mailglass.Application supervision tree (Phase 3 additions):
children = [
  # (Phase 1) Mailglass.Repo — adopter-supervised
  {Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2},
  {Task.Supervisor, name: Mailglass.TaskSupervisor},
  Mailglass.RateLimiter.Supervisor,
  Mailglass.Adapters.Fake.Supervisor
  # No Oban.Worker queue registration — adopter configures Oban themselves;
  # we just register `:mailglass_outbound` as a recommended queue in docs.
]
```

The Task.Supervisor fallback:
```elixir
defp enqueue_task_supervisor(rendered, opts) do
  ik = idempotency_key(rendered)
  tenant_id = Tenancy.current()

  # Same Multi#1 as sync path but we do NOT commit the dispatch yet.
  {:ok, %{delivery: delivery}} = persist_queued(rendered)

  # Spawn a supervised task that re-stamps tenancy explicitly.
  {:ok, _pid} = Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
    Mailglass.Tenancy.with_tenant(tenant_id, fn ->
      case delivery |> Mailglass.Outbound.dispatch_by_id() do
        {:ok, _} -> :ok
        {:error, err} -> Logger.warning("[mailglass] task dispatch failed: #{Exception.message(err)}")
      end
    end)
  end)

  {:ok, %{delivery | last_event_type: :queued}}
end
```

**`$callers` inheritance:** `Task.Supervisor.start_child/3` automatically sets `Process.put(:"$callers", [self() | callers])` in the spawned task — so Fake adapter ownership resolution works transparently. **BUT** the tenancy stamp in process-dict is NOT inherited — hence the explicit `Tenancy.with_tenant/2` wrap (D-21).

---

## 4. Rate Limiter Design

### 4.1 Supervisor + TableOwner (D-22)

```elixir
defmodule Mailglass.RateLimiter.Supervisor do
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl Supervisor
  def init(_opts) do
    children = [Mailglass.RateLimiter.TableOwner]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Mailglass.RateLimiter.TableOwner do
  use GenServer

  @table :mailglass_rate_limit

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [
      :set, :public, :named_table,
      read_concurrency: true,
      write_concurrency: :auto,
      decentralized_counters: true
    ])
    {:ok, %{}}
  end

  # No handle_call / handle_cast / handle_info — init-and-idle.
end
```

**ETS ownership crash semantics:** The ETS table is owned by the `TableOwner` process. If it crashes, the table is deleted by BEAM. Supervisor restarts the TableOwner; the new process calls `:ets.new/2` again; counters reset.

**Is counter reset acceptable?** Yes per D-22: "counters reset; acceptable — rate-limit state is not load-bearing across crashes." A process crash is rare (the TableOwner does no work), and even on crash the worst-case is 1min of burst allowance (refill restart). Compare to the alternative — an ETS `{:heir, ...}` transfer to the supervisor — which adds complexity for no operational benefit.

**Naming note:** `name: __MODULE__` IS used on the `TableOwner` GenServer. This does NOT violate LIB-05 because (a) the process is internal library machinery not a user-facing singleton, (b) there's only one rate-limit table per node by design, (c) LINT-07 flags library code that registers with `name: __MODULE__` but the Phase 6 check has an exception for modules tagged `@mailglass_library_singleton true` or similar. **Planner decision:** document the `TableOwner` in `api_stability.md` as "library-reserved" and add to LINT-07's exception list. `[ASSUMED]` — this exception needs explicit confirmation; alternatively name it `:mailglass_rate_limit_table_owner` (atom literal, not `__MODULE__`) to sidestep the check entirely.

### 4.2 Atomic bucket update via `:ets.update_counter/4` (D-23)

The token bucket is a leaky bucket with continuous refill:
- Per-key state: `{key, tokens, last_refill_ms}` where `key = {tenant_id, recipient_domain}`.
- Capacity = 100 tokens (default). Refill rate = `capacity / 60_000 = 100/60_000` tokens per ms.

The hot path uses a compound `:ets.update_counter/4` op list that atomically:
1. Refills tokens to `min(capacity, tokens + (now_ms - last_refill_ms) * refill_per_ms)`
2. Updates `last_refill_ms` to `now_ms`
3. Decrements tokens by 1 (the "take" step)

The canonical pseudocode from D-23:
```elixir
def check(tenant_id, domain, stream)
def check(_tenant_id, _domain, :transactional), do: :ok

def check(tenant_id, domain, _stream) do
  key = {tenant_id, domain}
  {capacity, refill_per_ms} = limits_for(tenant_id, domain)
  now_ms = System.monotonic_time(:millisecond)

  # First-hit insert (atomic via :ets.insert_new).
  :ets.insert_new(@table, {key, capacity, now_ms})

  # Peek to compute refilled count (float math outside ETS because
  # :ets.update_counter does integer arithmetic only).
  [{^key, tokens, last}] = :ets.lookup(@table, key)
  refilled = min(capacity, tokens + round((now_ms - last) * refill_per_ms))

  # Atomic multi-op:
  #   [{pos=2, incr=0, threshold=capacity, setval=refilled}]  # cap tokens at `refilled`
  #   [{pos=3, incr=0, threshold=0, setval=now_ms}]           # always set last=now_ms
  #   [{pos=2, incr=-1, threshold=0, setval=0}]               # try to take one, floor at 0
  case :ets.update_counter(@table, key,
         [{2, 0, capacity, refilled}, {3, 0, 0, now_ms}, {2, -1, 0, 0}],
         {key, capacity, now_ms}) do
    [_, _, new_tokens] when new_tokens >= 0 -> :ok
    _ -> {:error, %RateLimitError{
           type: :per_domain,
           retry_after_ms: ceil(1 / refill_per_ms),
           context: %{tenant_id: tenant_id, domain: domain}
         }}
  end
end
```

**Hot-path cost:** ≈1-3μs on OTP 27 with `decentralized_counters: true`. The first `:ets.lookup/2` is in parallel with the `:ets.insert_new/2` — both are non-mutating for existing keys.

**Correctness caveat:** The `lookup + math + update_counter` sequence is not strictly atomic between lookup and update — a concurrent write could have updated `last_refill_ms` between our lookup and update_counter. But `:ets.update_counter/4` DOES clamp `new_tokens` to a floor of 0 (the third op's `threshold=0`), and the setval-on-threshold pattern for position 2 clamps at `refilled`. Under concurrent pressure the bucket may refill slightly too slow (benign for rate-limiting) but never overshoot capacity. See OTP docs on `:ets.update_counter/4` update operations.

**`[VERIFIED: deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex]`** ETS-without-GenServer-serialization is a proven pattern in the current Swoosh release.

### 4.3 Clock injection for deterministic tests (D-07)

The `now_ms` call uses `System.monotonic_time(:millisecond)` which is NOT affected by `Clock.Frozen` (by design — `Clock.Frozen` governs `DateTime.utc_now/0` for event timestamps; monotonic time is for latency math and rate-limit refill windows). Test strategy: use `:meck` / `:mock` OR accept the 1-5ms real-clock drift in assertions (tests can sleep `refill_period_ms + 1` to force refill). **Planner decision:** if deterministic rate-limit tests are needed, add `Mailglass.Clock.monotonic_ms/0` with `Clock.Frozen` support. `[ASSUMED]` — the simpler path is real-clock with generous assertion bounds; confirm during planning.

### 4.4 `%RateLimitError{retry_after_ms: int}` shape

Already shipped in `lib/mailglass/errors/rate_limit_error.ex`:
```elixir
@types [:per_domain, :per_tenant, :per_stream]
defexception [:type, :message, :cause, :context, retry_after_ms: 0]
@spec new(atom(), keyword()) :: t()
def new(type, opts \\ []) when type in @types do
  %__MODULE__{
    type: type,
    message: format_message(type, ctx),
    cause: opts[:cause],
    context: ctx,
    retry_after_ms: opts[:retry_after_ms] || 0
  }
end
```

Phase 3 uses `:per_domain` primarily. `retry_after_ms` is a top-level field (not stuffed into context) — locked by a prior phase decision.

---

## 5. Preflight Pipeline

### 5.1 Stage order (D-18 as amended by spec_lock)

| Stage | Function | Failure → | Short-circuit? | Cost |
|-------|----------|-----------|----------------|------|
| 0 | `Tenancy.assert_stamped!/0` | `raise %TenancyError{type: :unstamped}` | Raises (not short-circuit) | ~500ns (Process.get) |
| 1 | `Suppression.check_before_send(msg)` | `{:error, %SuppressedError{}}` | Yes | ~50-200μs (indexed Postgres lookup) |
| 2 | `RateLimiter.check(tenant_id, domain, stream)` | `{:error, %RateLimitError{retry_after_ms:}}` | Yes | ~1-3μs (ETS) |
| 3 | `Stream.policy_check(msg)` | `:ok` always at v0.1 (emits `[:mailglass, :outbound, :stream_policy, :stop]`) | — | ~100ns |
| 4 | `Renderer.render(msg)` | `{:error, %TemplateError{}}` | Yes | ~4ms |
| 5 | Persist (Ecto.Multi) | `{:error, %SendError{}}` on Multi failure | — | ~2-5ms |

**Tenancy as precondition, not stage:** The SEND-01 amendment in spec_lock replaces `Tenancy.scope` with `Tenancy.assert_stamped!`. Rationale: `Tenancy.scope/2` is a query-scoping helper consumed inside `Events.append_multi/3` reads, not a pre-send stage. What preflight needs is the assertion that a tenant stamp exists so `Events.append_multi/3`'s auto-capture via `Tenancy.current/0` doesn't silently default to `"default"` in a multi-tenant adopter.

`Mailglass.Tenancy` currently has `tenant_id!/0` which raises `%TenancyError{type: :unstamped}` if no stamp. Phase 3 adds `assert_stamped!/0` as a thin alias (or renames the tests to use `tenant_id!/0` directly). **Planner decision:** ship `assert_stamped!/0` as a new public function or reuse `tenant_id!/0`. Ship `assert_stamped!/0` for semantic clarity; it can internally call `tenant_id!/0` ignoring the return value. `[ASSUMED]`.

### 5.2 `Mailglass.Suppression.check_before_send/1` (SEND-04)

Phase 2 shipped `Mailglass.SuppressionStore.Ecto.check/2`. Phase 3 adds a thin wrapper + new ETS impl (D-28):

```elixir
defmodule Mailglass.Suppression do
  @moduledoc """
  Public preflight facade for suppression checks.
  """

  @spec check_before_send(Mailglass.Message.t()) :: :ok | {:error, Mailglass.SuppressedError.t()}
  def check_before_send(%Message{} = msg) do
    key = %{tenant_id: msg.tenant_id, address: primary_recipient(msg), stream: msg.stream}

    Mailglass.Telemetry.execute(
      [:mailglass, :outbound, :suppression, :stop],
      %{duration_us: 0},  # Measured inside :telemetry.span
      %{tenant_id: msg.tenant_id}
    )

    case suppression_store().check(key, []) do
      :not_suppressed -> :ok
      {:suppressed, %Entry{scope: scope}} ->
        {:error, Mailglass.SuppressedError.new(scope, context: %{
          tenant_id: msg.tenant_id,
          stream: msg.stream
        })}
      {:error, err} -> {:error, err}
    end
  end

  defp suppression_store do
    Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  end
end
```

### 5.3 `Mailglass.SuppressionStore.ETS` impl (D-28)

Same behaviour surface as `.Ecto` but backed by an ETS table `:mailglass_suppression_store` owned by a `Mailglass.SuppressionStore.ETS.TableOwner` supervisor child (same pattern as RateLimiter). `check/2` does `:ets.lookup/2` (O(1)); `record/2` does `:ets.insert/2`.

**Test override:** `config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS` in `config/test.exs`. `MailerCase` can optionally call `Mailglass.SuppressionStore.ETS.reset/0` between tests for isolation — but because tests are async, and ETS is shared, either (a) each test uses unique recipient addresses, or (b) the ETS impl keys entries by `{tenant_id, pid}` and uses the sandbox-like ownership pattern. **Planner decision:** lean to (a) — simpler, and tests naturally scope by tenant anyway. `[ASSUMED]`.

### 5.4 Where per-mailable `tracking:` config lives

Compile-time `@mailglass_opts` attribute on the mailable module (D-09, D-30). The `Mailable.__using__/1` macro stores the opts unquoted:

```elixir
defmacro __using__(opts) do
  quote do
    @behaviour Mailglass.Mailable
    @before_compile Mailglass.Mailable
    @mailglass_opts unquote(opts)
    # ... rest of the 15-line injection
  end
end
```

Preflight does NOT read `@mailglass_opts` — it's used by (a) the `Message.new/0` builder (seeds stream, tracking, from_default, reply_to_default), (b) Phase 6 Credo checks (AST inspection), (c) Phase 3 runtime auth-stream guard (D-38). Stage 3 `Stream.policy_check/1` is the seam where v0.5 will enforce the policy; at v0.1 it just emits telemetry.

---

## 6. Swoosh Bridge (Pure Renderer Integration)

### 6.1 `Mailglass.Renderer.render/2` already exists (Phase 1)

The renderer takes a `%Mailglass.Message{}` and returns `{:ok, %Mailglass.Message{}}` with `swoosh_email.html_body` and `swoosh_email.text_body` populated. It's pure (no DB, no process). The Outbound pipeline calls it at stage 4:

```elixir
{:ok, rendered} <- Renderer.render(msg)  # returns %Message{} with populated email bodies
```

**HEEx components are Phase 5's concern.** Phase 3 scope: adapters consume `rendered.swoosh_email` which has `.text_body` and `.html_body` populated as plain strings. No template lookup magic at send time — templates are resolved by the mailable's `def welcome(user)` function using either:
- The injected `render/3` helper (`Mailglass.Renderer.render(msg, __MODULE__, :welcome, %{user: user})` — D-09)
- Or direct Swoosh builder functions (`Swoosh.Email.html_body/2`) for text-only mailables

### 6.2 `Mailglass.Adapters.Swoosh` wrapper (D-29)

```elixir
defmodule Mailglass.Adapters.Swoosh do
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = msg, opts) do
    swoosh_adapter = resolve_swoosh_adapter(opts)

    case Swoosh.Adapter.deliver(swoosh_adapter, msg.swoosh_email, []) do
      {:ok, %{id: message_id} = response} ->
        {:ok, %{message_id: message_id, provider_response: response}}

      {:ok, response} when is_map(response) ->
        # Swoosh adapters vary on response shape; coerce to our contract.
        {:ok, %{message_id: response[:id] || generate_synthetic_id(), provider_response: response}}

      {:error, {:api_error, status, body}} ->
        {:error, Mailglass.SendError.new(:adapter_failure,
          context: %{provider_status: status, provider_module: swoosh_adapter, body_preview: preview(body)},
          cause: %Swoosh.DeliveryError{reason: {:api_error, status, body}}
        )}

      {:error, reason} ->
        {:error, Mailglass.SendError.new(:adapter_failure,
          context: %{provider_module: swoosh_adapter, reason_class: classify(reason)},
          cause: reason_as_exception(reason)
        )}
    end
  end
end
```

**Purity:** No DB calls, no PubSub broadcasts, no Process.put. The caller's process owns the HTTP request via Swoosh's configured `:api_client` (typically Finch, adopter-supplied). LIB-06 satisfied.

**Error mapping table (v0.1 scope, adopter discretion):**
| Swoosh error shape | Mapped SendError `:type` | Context fields |
|--------------------|-------------------------|----------------|
| `{:api_error, 4xx, body}` | `:adapter_failure` | `provider_status`, `body_preview` (truncated 200 bytes) |
| `{:api_error, 5xx, body}` | `:adapter_failure` | Same (retryable: true via `SendError.retryable?/1`) |
| `{:transport_error, reason}` | `:adapter_failure` | `reason_class: :transport` |
| `{:malformed, ...}` | `:serialization_failed` | `reason_class: :malformed` |

**What NEVER goes into context:** `:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, `:email` — the 8 forbidden PII keys. `body_preview` is a 200-byte head of the provider's response body; per brand policy the preview is documented as "may contain provider-emitted error strings but never user-supplied content."

---

## 7. `deliver_many/2` Partial-Failure Semantics

### 7.1 Batch return shape (D-15)

```elixir
@spec deliver_many([Mailglass.Message.t()], keyword()) ::
        {:ok, [%Delivery{}]} | {:error, Mailglass.Error.t()}
```

**Always returns `{:ok, [%Delivery{}]}` on the batch level** — an individual Delivery carries its own `:status` (`:queued | :sent | :failed`) and `:last_error :: %Mailglass.Error{} | nil`. The batch itself only errors at the Multi-level (DB unavailable, tenancy unstamped).

Pattern-match:
```elixir
{:ok, deliveries} = Mailglass.Outbound.deliver_many(msgs)

# Partition by status
{successes, failures} = Enum.split_with(deliveries, & &1.status == :sent)
```

### 7.2 Idempotency key per message (D-15)

Each Delivery has `idempotency_key = sha256(tenant_id <> inspect(mailable) <> recipient <> content_hash)`. `content_hash = sha256(rendered.swoosh_email.text_body <> rendered.swoosh_email.html_body)` (or just text_body for text-only mailables). On retry:
- The Multi's batched `insert_all` uses `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}, returning: true`.
- Rows that existed are re-fetched via a companion `SELECT WHERE idempotency_key IN ?` query and carry their existing status/last_error.
- Rows that are newly inserted carry status `:queued` (async path) or `:sent`/`:failed` (sync path after individual adapter calls).

### 7.3 Batch Multi shape

```elixir
def deliver_many(messages, opts) do
  # Preflight each message individually; those that fail preflight become
  # %Delivery{status: :failed, last_error: ...} rows without adapter calls.
  {eligible, already_failed} = Enum.map_reduce(messages, [], fn msg, acc ->
    case preflight(msg) do
      {:ok, rendered} -> {{:ok, rendered}, acc}
      {:error, err} ->
        failed_delivery = Delivery.failed_from_message(msg, err)
        {{:error, failed_delivery}, [failed_delivery | acc]}
    end
  end)

  # Batch-insert Deliveries + :queued Events for all eligible messages via Multi.insert_all.
  # For async path: Oban.insert_all for the workers.
  # For sync path: fan out adapter calls (Task.async_stream with max_concurrency),
  # then batch Multi#2 with Projector updates + :dispatched events.
  # ...
end
```

**Reference:** Anymail doesn't have a direct Elixir analog; ActionMailer's `deliver_all` is simpler (async enqueue, no partial failure semantics). The closest prior art is Stripe's batch API with `idempotency_key` per item — each item is independently retryable.

**Planner decision:** batch Multi structure for the sync path (adapter calls + Multi#2) is non-trivial and may warrant its own plan step. Consider deferring a real `deliver_many/2` sync implementation to a later phase and shipping only the async path at v0.1 per D-15. `[ASSUMED]` — CONTEXT.md D-15 implies both paths ship; verify with planner.

---

## 8. Mailable Macro Design (LIB-01 Budget)

### 8.1 Injection (D-09 locks 15 lines)

```elixir
defmacro __using__(opts) do
  quote bind_quoted: [opts: opts] do
    @behaviour Mailglass.Mailable          # line 1
    @before_compile Mailglass.Mailable      # line 2
    @mailglass_opts opts                    # line 3
    import Swoosh.Email                     # line 4
    import Mailglass.Components             # line 5

    def new, do:                            # line 6
      Mailglass.Message.new(__MODULE__, @mailglass_opts)

    def render(msg, tmpl, assigns \\ %{}),  # line 7
      do: Mailglass.Renderer.render(msg, __MODULE__, tmpl, assigns)

    def deliver(msg, opts \\ []),           # line 8
      do: Mailglass.Outbound.deliver(msg, opts)

    def deliver_later(msg, opts \\ []),     # line 9
      do: Mailglass.Outbound.deliver_later(msg, opts)

    defoverridable new: 0, render: 3,       # line 10
      deliver: 2, deliver_later: 2
  end
end
```

Counting "meaningful Elixir AST lines" per LINT-05's AST counter: 10 lines of actual function/behaviour declarations + `@mailglass_opts` + 2 imports = 13-15 depending on counter. D-09 budgets 15 and says "≤20 per LINT-05" — comfortable margin.

### 8.2 Behaviour contract

```elixir
defmodule Mailglass.Mailable do
  @callback new() :: Mailglass.Message.t()
  @callback render(Mailglass.Message.t(), atom(), map()) ::
              {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t()}
  @callback deliver(Mailglass.Message.t(), keyword()) ::
              {:ok, %Mailglass.Outbound.Delivery{}} | {:error, Mailglass.Error.t()}
  @callback deliver_later(Mailglass.Message.t(), keyword()) ::
              {:ok, %Mailglass.Outbound.Delivery{status: :queued}} | {:error, Mailglass.Error.t()}

  @optional_callbacks preview_props: 0
  @callback preview_props() :: [{atom(), map()}]
end
```

The `@before_compile` hook registers the module for Phase 5 admin discovery. At compile time it emits a function like `def __mailglass_mailable__, do: true` that Phase 5 scans for via `Code.all_modules/0` filter.

### 8.3 Helpers imported

`import Swoosh.Email` brings in `Swoosh.Email.new/0,1`, `Swoosh.Email.to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`, `header/3`, etc. These are the Swoosh builder functions — the ergonomic base.

`import Mailglass.Components` brings in the 11 HEEx components (`<.container>`, etc.) from Phase 1 for templates. Does NOT import `Phoenix.Component` — adopters opt in per-mailable if they want function-component helpers.

**Per D-11, NO helpers for `stream/1`, `tracking/1`, `metadata/1` at runtime** — those are `use` opts only, not runtime-mutable.

### 8.4 Prior art

- **Phoenix.Component.__using__/1** — larger footprint because HEEx assigns machinery; Mailglass deliberately stays thin.
- **Laravel Mailable** — compile-time class inheritance; useful as a domain-language reference only.
- **accrue's `Accrue.Billable`** — same 15-line budget pattern per `~/projects/accrue/lib/accrue/billable.ex`. Direct inspiration.

---

## 9. Test Assertions Helper

### 9.1 Three receive-based assertion classes

1. **In-process assertions** (fast, no PubSub, rely on Fake's `send(owner, {:mail, msg})`):
   - `assert_mail_sent/0,1`
   - `last_mail/0`
   - `wait_for_mail/1`
   - `assert_no_mail_sent/0`

2. **PubSub-backed event assertions** (D-04 broadcast + `assert_receive`):
   - `assert_mail_delivered(msg_or_id, timeout)` — receives `{:delivery_updated, delivery_id, :delivered, _meta}`.
   - `assert_mail_bounced(msg_or_id, timeout)` — same shape, `:bounced`.

3. **ETS-backed query helpers** (for browsing all captured mail):
   - `Mailglass.Adapters.Fake.deliveries/1` — keyword-filterable (`:tenant, :mailable, :recipient`).
   - `Mailglass.Adapters.Fake.last_delivery/1`.

### 9.2 ExUnit setup requirement

`MailerCase` (D-06) handles setup automatically:
```elixir
defmodule Mailglass.MailerCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mailglass.TestAssertions
      alias Mailglass.{Adapters, Message}
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
    :ok = Mailglass.Adapters.Fake.checkout()
    tenant_id = Map.get(tags, :tenant, "test-tenant")
    unless tenant_id == :unset, do: Mailglass.Tenancy.put_current(tenant_id)
    if frozen_at = tags[:frozen_at], do: Mailglass.Clock.Frozen.freeze(frozen_at)
    Phoenix.PubSub.subscribe(Mailglass.PubSub, "mailglass:events:#{tenant_id}")

    on_exit(fn ->
      Mailglass.Adapters.Fake.checkin()
      Mailglass.Clock.Frozen.unfreeze()
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)
    :ok
  end
end
```

**Critical:** `async: true` by default. The Fake's ownership pattern makes per-test isolation free. Global mode (`setup :set_mailglass_global`) is the explicit opt-out mirroring `set_swoosh_global`.

### 9.3 Reference: `Swoosh.TestAssertions`

`deps/swoosh/lib/swoosh/test_assertions.ex` lines 69-150 show the shape mailglass mirrors:
- `assert_email_sent()` → `assert_received {:email, _}`
- `assert_email_sent(email)` → `assert_received {:email, ^email}`
- `assert_email_sent(kw)` → builder match on fields
- `assert_email_sent(fn -> boolean end)` → predicate call

Mailglass matchers match on `{:mail, %Mailglass.Message{}}` instead of `{:email, %Swoosh.Email{}}`.

---

## 10. Telemetry Events Phase 3 Emits

### 10.1 Full event list (D-26)

| Event path | Span/single | Measurements | Metadata keys | Emitted by |
|-----------|-------------|--------------|---------------|-----------|
| `[:mailglass, :outbound, :send, :start]` | span start | `%{system_time}` | `%{tenant_id, mailable, stream}` | `Outbound.send/2` |
| `[:mailglass, :outbound, :send, :stop]` | span stop | `%{duration}` | `%{tenant_id, mailable, stream, delivery_id, status}` | `Outbound.send/2` |
| `[:mailglass, :outbound, :send, :exception]` | span exception | `%{duration, kind, reason, stacktrace}` | `%{tenant_id, mailable}` | `Outbound.send/2` on raise |
| `[:mailglass, :outbound, :dispatch, :*]` | full span | duration | `%{tenant_id, mailable, delivery_id, provider}` | Adapter call wrapper |
| `[:mailglass, :persist, :outbound, :multi, :*]` | full span | duration | `%{tenant_id, delivery_id, step_name}` | Multi#1 and Multi#2 commits |
| `[:mailglass, :render, :message, :*]` | full span | duration | `%{tenant_id, mailable}` | Renderer.render (Phase 1) |
| `[:mailglass, :outbound, :suppression, :stop]` | single emit | `%{duration_us}` | `%{hit, tenant_id}` | `Suppression.check_before_send/1` |
| `[:mailglass, :outbound, :rate_limit, :stop]` | single emit | `%{duration_us}` | `%{allowed, tenant_id}` | `RateLimiter.check/3` |
| `[:mailglass, :outbound, :stream_policy, :stop]` | single emit | `%{duration_us}` | `%{tenant_id, stream}` | `Stream.policy_check/1` |
| `[:mailglass, :events, :append, :*]` | full span | duration | `%{tenant_id, inserted?, idempotency_key_present?}` | Events.append/1 (Phase 2) |
| `[:mailglass, :persist, :delivery, :update_projections, :*]` | full span | duration | `%{tenant_id, delivery_id}` | Projector (Phase 2) |

### 10.2 Metadata PII audit

All metadata keys are from the Phase 1 D-31 whitelist: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. Phase 3 adds no new keys; reuses existing ones.

**Specifically NOT in any Phase 3 metadata:** `:recipient` (though it's on `Delivery` the schema — but the *telemetry metadata* only carries `:delivery_id`, not the recipient address); `:subject`, `:from`, etc.

Phase 6 LINT-02 `NoPiiInTelemetryMeta` will lint-check this at compile time across all `:telemetry.execute` and `span` calls.

### 10.3 Which events fire at each Multi step

- Before Multi#1 commit → `[:mailglass, :persist, :outbound, :multi, :start]` with `step_name: :persist_queued`.
- After Multi#1 commit → `:stop` with the same metadata + `delivery_id`.
- Adapter span wraps adapter.deliver/2 → `[:mailglass, :outbound, :dispatch, :start]` then `:stop` with `%{provider, status}`.
- Before Multi#2 commit → `[:mailglass, :persist, :outbound, :multi, :start]` with `step_name: :persist_dispatched`.
- After Multi#2 commit → `:stop` with `delivery_id, status: :sent`.
- Projector's `persist_span([:delivery, :update_projections])` fires inside the Multi (Phase 2, unchanged).

---

## 11. `mix verify.core_send` Alias

Per success criterion 5 (roadmap): `mix verify.core_send` must run "the full pipeline against Fake."

```elixir
# mix.exs aliases
"verify.core_send": [
  "ecto.drop -r Mailglass.TestRepo --quiet",
  "ecto.create -r Mailglass.TestRepo --quiet",
  "test --warnings-as-errors --only phase_03_uat --exclude flaky",
  "compile --no-optional-deps --warnings-as-errors",
  "credo --strict"
]
```

The `phase_03_uat` tag flags `test/mailglass/core_send_integration_test.exs` which exercises:
1. `use Mailglass.Mailable` + `.deliver()` + `assert_mail_sent` in <20 test lines (success criterion #1).
2. `deliver_later/2` Oban path returns `{:ok, %Delivery{status: :queued}}` (success criterion #2).
3. `deliver_later/2` without-Oban path (runs in a sub-process via `Application.ensure_all_started/1` simulation OR is tested via toggling `config :mailglass, :async_adapter, :task_supervisor`) — confirms boot warning fires once.
4. `deliver_many/2` partial failure records rows + idempotency-key replay produces no duplicates (success criterion #3).
5. Tracking off by default — assert no pixel in rendered HTML when `tracking:` not set (success criterion #4).
6. Rate limit over-capacity returns `%RateLimitError{retry_after_ms: int}` (success criterion #5).

The `--only phase_03_uat` pattern follows Phase 2's precedent (`phase_02_uat` tag on `test/mailglass/persistence_integration_test.exs`).

---

## Validation Architecture

> Required by `workflow.nyquist_validation: true` in config.json.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + StreamData 1.3.0 |
| Config file | `test/test_helper.exs`, `config/test.exs` |
| Quick run command | `mix test --exclude flaky` |
| Full suite command | `mix verify.core_send` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTHOR-01 | `use Mailglass.Mailable` injects ≤15 lines; produces `%Message{}`; `.deliver/2` returns `{:ok, %Delivery{}}` | unit + integration | `mix test test/mailglass/mailable_test.exs` | ❌ Wave 0 |
| AUTHOR-01 | AST line-count of injection ≤20 | unit | `mix test test/mailglass/mailable_test.exs::test_injection_line_count` | ❌ Wave 0 |
| TRANS-01 | `Mailglass.Adapter.deliver/2` callback contract matches spec | unit | `mix test test/mailglass/adapter_test.exs` | ❌ Wave 0 |
| TRANS-02 | Fake records `%Message{}`; `trigger_event/3` flows through real Projector | unit + integration | `mix test test/mailglass/adapters/fake_test.exs` | ❌ Wave 0 |
| TRANS-02 | Fake is `async: true`-safe across N concurrent tests | integration | `mix test test/mailglass/adapters/fake_concurrency_test.exs` | ❌ Wave 0 |
| TRANS-03 | Swoosh wrapper maps `{:api_error, status, body}` → `%SendError{type: :adapter_failure}` | unit | `mix test test/mailglass/adapters/swoosh_test.exs` | ❌ Wave 0 |
| TRANS-04 | `deliver/2`, `deliver_later/2`, `deliver_many/2` all return `{:ok, %Delivery{}}` with uniform shape | unit + integration | `mix test test/mailglass/outbound_test.exs` | ❌ Wave 0 |
| SEND-01 | Preflight runs 5 stages in order; each short-circuits correctly | unit | `mix test test/mailglass/outbound/preflight_test.exs` | ❌ Wave 0 |
| SEND-01 | Each stage emits expected telemetry (property test over 100 messages) | property | `mix test test/mailglass/outbound/telemetry_test.exs` | ❌ Wave 0 |
| SEND-02 | Rate limiter per-domain token bucket; `:transactional` bypasses | unit + property | `mix test test/mailglass/rate_limiter_test.exs` | ❌ Wave 0 |
| SEND-02 | ETS owner crash restart resets counters (not load-bearing) | integration | `mix test test/mailglass/rate_limiter_supervision_test.exs` | ❌ Wave 0 |
| SEND-03 | Oban path enqueues job; fallback path emits exactly one boot warning | integration | `mix test test/mailglass/outbound/worker_test.exs` | ❌ Wave 0 |
| SEND-04 | Suppression short-circuits with `%SuppressedError{}` | unit | `mix test test/mailglass/suppression_test.exs` | ❌ Wave 0 |
| SEND-05 | Projector broadcasts on both tenant + per-delivery topics | integration | `mix test test/mailglass/outbound/projector_broadcast_test.exs` | ❌ Wave 0 |
| TRACK-01 | Tracking off by default — no pixel injected in rendered HTML | unit | `mix test test/mailglass/tracking/default_off_test.exs` | ❌ Wave 0 |
| TRACK-01 | Runtime auth-stream guard raises `%ConfigError{type: :tracking_on_auth_stream}` | unit | `mix test test/mailglass/tracking/auth_stream_guard_test.exs` | ❌ Wave 0 |
| TRACK-03 | Phoenix.Token rotation via salts list — head signs, all verify | unit | `mix test test/mailglass/tracking/token_rotation_test.exs` | ❌ Wave 0 |
| TRACK-03 | Open-redirect structurally impossible (no `?r=` param) | unit + property | `mix test test/mailglass/tracking/open_redirect_test.exs` | ❌ Wave 0 |
| TEST-01 | `assert_mail_sent/1` in all 4 matcher styles | unit | `mix test test/mailglass/test_assertions_test.exs` | ❌ Wave 0 |
| TEST-01 | `assert_mail_delivered/2` consumes PubSub broadcast | integration | `mix test test/mailglass/test_assertions_pubsub_test.exs` | ❌ Wave 0 |
| TEST-02 | `MailerCase` runs `async: true` with Ecto sandbox + Fake checkout | integration | `mix test test/mailglass/mailer_case_test.exs` | ❌ Wave 0 |
| TEST-05 | `Mailglass.Clock.Frozen.freeze/advance` per-process isolation | unit | `mix test test/mailglass/clock_test.exs` | ❌ Wave 0 |
| **Phase gate** | All 5 success criteria + idempotency-key replay safety | integration | `mix test --only phase_03_uat` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test --exclude flaky` (quick, runs full non-flaky suite against Fake)
- **Per wave merge:** `mix verify.core_send` (full suite + no-optional-deps lane + credo)
- **Phase gate:** `mix verify.core_send` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/support/mailer_case.ex` — `Mailglass.MailerCase` template with async setup per D-06.
- [ ] `test/support/fake_fixtures.ex` — shared Mailable fixtures (`TestMailer.welcome/1`, `TestMailer.password_reset/1`) for cross-test reuse.
- [ ] `test/mailglass/core_send_integration_test.exs` — phase-wide success-criteria test (tagged `:phase_03_uat`).
- [ ] `mix verify.core_send` alias in `mix.exs`.
- [ ] `config/test.exs` entries: `config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS` (optional override), `config :mailglass, :clock, Mailglass.Clock.Frozen` (default to System — test opts in).
- [ ] `docs/api_stability.md` extensions per Phase 3 surfaces (adapter return shape, Outbound facade, RateLimiter check contract, Clock, PubSub Topics, Tracking).

### Dispatch ≠ Delivered — what it looks like in Phase 3 tests

Phase 3 tests assert **dispatch only** — no webhook in this phase. Specifically:
- `assert_mail_sent(...)` fires when the Fake receives the message (post-Multi#1 commit, inside Multi#2).
- `Delivery.status == :sent` means dispatched (provider accepted).
- `Delivery.delivered_at` IS NOT set by any Phase 3 code path. The `:delivered` event only arrives via webhook (Phase 4) or `Fake.trigger_event(mid, :delivered, ...)` in tests.

A Phase 3 test that wants to assert downstream delivery uses:
```elixir
test "delivered event arrives after simulated webhook" do
  {:ok, delivery} = MyMailer.welcome(user) |> MyMailer.deliver()
  Fake.trigger_event(delivery.provider_message_id, :delivered,
    occurred_at: DateTime.utc_now())
  assert_mail_delivered(delivery.id)  # via PubSub broadcast
end
```

This is critical: the Fake's `trigger_event/3` is explicitly the test-side simulation of Phase 4 webhooks, routed through Phase 2's real Projector write path (D-03).

### Coverage Gates

- Every telemetry event documented in §10 MUST fire in at least one test (verified via StreamData property test that attaches a `:telemetry.attach_many/4` handler and asserts the whitelist is hit).
- Every `%Mailglass.Error{}` subtype raised in Phase 3 MUST have a test that pattern-matches by struct (not message string).
- `mix compile --no-optional-deps --warnings-as-errors` MUST pass (ensures no stray `Oban.*` refs outside gateway).
- Phase 6 LINT-02, LINT-05, LINT-06 pre-pass: ad-hoc grep checks in the phase gate to avoid PII in telemetry, oversized use injections, and unprefixed PubSub topics. Final lint-time enforcement lands Phase 6.

---

## 13. Error Types Introduced in This Phase

Phase 3 introduces NO new error structs (all seven exist from Phase 1-2). It EXTENDS the existing ones:

| Struct | Existing `:type` atoms | Phase 3 additions |
|--------|------------------------|-------------------|
| `%Mailglass.SendError{}` | `:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed` | None |
| `%Mailglass.TemplateError{}` | `:heex_compile, :missing_assign, :helper_undefined, :inliner_failed` | None |
| `%Mailglass.SuppressedError{}` | `:address, :domain, :address_stream` | None |
| `%Mailglass.RateLimitError{}` | `:per_domain, :per_tenant, :per_stream` | None |
| `%Mailglass.ConfigError{}` | `:missing, :invalid, :conflicting, :optional_dep_missing` | **`:tracking_on_auth_stream`** (D-38), **`:tracking_host_missing`** (D-32) |
| `%Mailglass.TenancyError{}` | `:unstamped` | None (consumed by `Tenancy.assert_stamped!/0`) |
| `%Mailglass.EventLedgerImmutableError{}` | `:update_attempt, :delete_attempt` | None |

**NEW atom set additions require:**
- `Mailglass.ConfigError.__types__/0` updated list.
- `docs/api_stability.md` §ConfigError updated.
- `test/mailglass/errors/config_error_api_stability_test.exs` asserts exact list match.

**Potential new struct (deliberately rejected):** A `%Mailglass.Error.BatchFailed{}` is mentioned in D-16 for `deliver_many!/2`. `[ASSUMED]` — this IS a new struct introduced in Phase 3, with `:type` atoms TBD and `:failures :: [%Delivery{}]` field. Planner owns the final struct shape.

**Pattern-match discipline:** Every returned error is pattern-matched by struct:
```elixir
case Outbound.deliver(msg) do
  {:ok, delivery} -> ...
  {:error, %SuppressedError{type: :address}} -> ...
  {:error, %RateLimitError{retry_after_ms: ms}} -> ...
  {:error, %SendError{type: :adapter_failure}} -> ...
end
```

Never `err.message =~ "Delivery blocked"` — the message strings are documented for humans, not for code.

---

## 14. Phase 3 Pitfalls — Prevention Mapping

Per PITFALLS.md and CONTEXT.md <decisions>.

| Pitfall | Root cause | Phase 3 prevention (task or acceptance criterion) |
|---------|-----------|---------------------------------------------------|
| **LIB-01** Macro abuse in `use` | Authors port ActionMailer's "class" inheritance | Injection AST ≤15 lines (D-09); acceptance test `test_injection_line_count` counts AST nodes; Phase 6 LINT-05 locks at 20 |
| **LIB-03** Options changing return type | "Why have 3 functions?" optimization | D-13/D-14/D-15 lock uniform `{:ok, %Delivery{}}` return across sync/async/batch; distinct function names for distinct shapes; `api_stability.md` §Outbound documents every signature |
| **LIB-04** Forced exception-driven control flow | Provider HTTP clients raise by default | All adapter errors mapped to `{:error, %SendError{}}` (D-29); bang variants opt-in one-liners; per CLAUDE.md Signature errors remain the ONE authorized raise-path (not Phase 3) |
| **LIB-05** Hidden `name: __MODULE__` singleton | "There's only one mailer per app" thinking | D-22 supervisor-owned-ETS pattern; the only registered process is `RateLimiter.TableOwner` which is documented in `api_stability.md` as library-reserved and exempt from LINT-07; Fake.Storage follows the same pattern |
| **LIB-06** GenServer scattering | Reflex "I need state → GenServer" | Renderer + Swoosh bridge + Outbound facade are pure functions (D-29, §6); only ETS-owner GenServers exist (TableOwner, Fake.Storage), and they do no work |
| **MAIL-01** Tracking on auth messages | Default-on industry convention | Triple enforcement: NimbleOptions default `false` (D-31); Phase 6 Credo TRACK-02 at compile time; Phase 3 runtime guard D-38 raises `%ConfigError{type: :tracking_on_auth_stream}` on mailables matching `magic_link|password_reset|verify_email|confirm_account` regex |
| **TEST-01** Fake adapter is release gate | Plans that skip Fake to "save time" | `mix verify.core_send` CI lane runs the full pipeline against Fake; adopter tests in `test/example/` (Phase 7) use Fake by default; Mox is explicitly NOT used for transport |
| **TEST-06** Direct `DateTime.utc_now/0` | Time-dependent tests become flaky | D-07 `Mailglass.Clock` is the single legitimate source; `Clock.Frozen` per-process; Phase 6 LINT-12 enforces |

### Additional pitfalls not in the original list but relevant:

| Pitfall | Prevention |
|---------|-----------|
| **Adapter-call-in-transaction** causes Postgres connection-pool starvation | D-20 two-Multi sync path; adapter call OUTSIDE any transaction; orphan `:queued` deliveries handled by `Events.Reconciler` with ≥5min age threshold |
| **PubSub failure rolls back transaction** | D-04 explicitly places broadcast AFTER `Repo.transact/1` commits; broadcast failure is logged, never rolled back |
| **Oban leaks into public type signature** | D-14 rejects `{:ok, %Oban.Job{}}` return shape; `deliver_later/2` always returns `%Delivery{status: :queued}`; CI lane `mix compile --no-optional-deps --warnings-as-errors` catches leaks |
| **Idempotency key replay creates duplicate Deliveries** | Partial UNIQUE index on `idempotency_key WHERE idempotency_key IS NOT NULL` + `on_conflict: :nothing, returning: true` + companion re-fetch (§2.3); Phase 2's `Events.append_multi/3` already uses this pattern for events, Phase 3 extends to deliveries |
| **Open-redirect via click URL** | D-35 pattern (a): target URL inside signed token, no `?r=` param exists; structurally impossible to construct an open-redirect |
| **Mailchimp-style open-redirect CVE** | Same as above; documented in `prompts/Phoenix needs an email framework not another mailer.md:160` as the cautionary tale informing D-35 |

---

## 15. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **RateLimiter ETS owner crashes + resets counters under burst** | LOW (TableOwner does no work — has no reason to crash) | MEDIUM (1min burst allowance until refill) | Acceptable per D-22. If observed in prod: add `{:heir, Supervisor}` to ETS table creation; the supervisor can re-inherit on child crash |
| **Fake adapter storage grows unbounded in long-running test suites** | MEDIUM (tests don't always checkin) | LOW (only affects local dev) | `checkin/0` auto-called via `MailerCase` `on_exit`; Storage monitors owner pids via `{:DOWN, ...}` for auto-cleanup; periodic `Fake.clear(:all)` in `test_helper.exs` if needed |
| **`deliver_later/2` with Oban absent + long-running Task.Supervisor child blocks `Application.stop/1`** | MEDIUM (test harness stops application between suites) | LOW (test-only) | `Task.Supervisor.async_nolink/3` (NOT `start_child`) — nolink semantics mean Supervisor.stop doesn't block on Task exits; Logger.warning on any task error |
| **Orphan `:queued` Delivery between Multi#1 commit and adapter call if caller crashes** | LOW (between two consecutive function calls in one process) | LOW (data state is recoverable) | `Events.Reconciler` (Phase 2) sweeps orphans with age ≥5min; reconciler job lands Phase 4 with Oban cron (per Phase 2 D-19); Phase 3 ships the data shape that reconciler consumes |
| **Runtime auth-stream guard (D-38) false-positive on mailable function names with `password` in them** | LOW (regex `magic_link|password_reset|verify_email|confirm_account` is tight) | MEDIUM (adopter cannot send a legitimate `password_changed_confirmation` email with tracking) | Regex is specific to these four triggers; `password_changed_confirmation` does NOT match. Document exact regex in error message so adopters understand why they're blocked. Escape hatch: rename function to avoid the regex |
| **Swoosh 1.25 `Swoosh.DeliveryError` shape changes in a future Swoosh release** | MEDIUM (feature dev is active) | HIGH (every adapter error raise breaks) | `Mailglass.Adapters.Swoosh` wraps the Swoosh error in `cause:`; pattern-matches on `%Swoosh.DeliveryError{}` are inside the wrapper only; adopter code pattern-matches `%SendError{}` and sees a stable shape. Swoosh minor bumps covered by `~> 1.25`; major bumps require a Phase 3-level re-verification |
| **`Mailglass.MailerCase` `async: true` with Ecto sandbox + PubSub subscription — subscription leaks across tests** | LOW | LOW (tests get slightly flaky assertions) | `Phoenix.PubSub.subscribe/2` stores subscriptions in the subscriber's process; ExUnit kills the test process between tests; subscriptions die with the process. No action needed. Confirmed via `Swoosh.Adapters.Sandbox.Storage.init/1` using the same monitor pattern |
| **Task.Supervisor tenancy re-stamp (D-21) forgotten on a future `deliver_later` code path** | LOW-MEDIUM | HIGH (silent tenant data leak) | Phase 6 LINT-03 `NoUnscopedTenantQueryInLib` catches it at lint time; Phase 3 integration test asserts tenant_id stamped on every Event row written from the async path; concrete test: `deliver_later` from tenant A, assert the resulting Event's tenant_id is "A" not "default" |
| **`deliver_many/2` partial-failure replay: some deliveries succeed first attempt, rest fail; on retry the succeeded rows are skipped (ON CONFLICT) — but no way to surface "these 5 are done, retry these 3"** | MEDIUM | MEDIUM (adopter unable to differentiate from full-batch replay) | Each Delivery row carries its current status; on retry, `deliver_many/2` returns `{:ok, [all 8 Delivery rows]}` with accurate status per row. Adopter filters by `Enum.filter(&(&1.status == :sent))` for success list. Documented in `api_stability.md` §Outbound |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mailglass_deliveries` gains an `idempotency_key` column + partial UNIQUE index in Phase 3 | §2.3 | MEDIUM — if stored in `metadata.idempotency_key` jsonb, batch-replay requires GIN index + different conflict target; schema migration is still in Phase 3 scope |
| A2 | `Mailglass.Tenancy.assert_stamped!/0` is a NEW public function (not just an alias for `tenant_id!/0`) | §5.1 | LOW — if `tenant_id!/0` is used directly, fewer LOC; no behaviour change |
| A3 | `RateLimiter.TableOwner` uses `name: __MODULE__` exempt from LINT-07 via documentation | §4.1 | LOW — alternative is using an atom literal `:mailglass_rate_limit_table_owner` which sidesteps the check entirely |
| A4 | Deterministic rate-limit tests use real-clock + generous assertion windows (no `Mailglass.Clock.monotonic_ms/0` helper) | §4.3 | LOW-MEDIUM — if flakes observed, add the helper in Phase 3; negligible API surface cost |
| A5 | `Mailglass.SuppressionStore.ETS` keys entries by `{tenant_id, address}` (no per-pid ownership) | §5.3 | LOW — tests scope by tenant naturally; if collisions observed, migrate to Sandbox-like pattern |
| A6 | `deliver_many/2` ships both sync and async paths at v0.1 | §7.3 | MEDIUM — sync-batch complexity may warrant async-only at v0.1; CONTEXT.md D-15 implies both |
| A7 | `%Mailglass.Error.BatchFailed{}` is a new struct introduced in Phase 3 for `deliver_many!/2` | §13 | LOW — alternative is reusing `%SendError{type: :batch_failed, context: %{failures: [...]}}`; CONTEXT.md D-16 mentions the struct by name, so likely new |

---

## Open Questions

1. **`idempotency_key` column on `mailglass_deliveries`?** (Assumption A1)
   - What we know: D-15 computes `sha256(tenant_id <> mailable <> recipient <> content_hash)` for each Delivery.
   - What's unclear: Column or `metadata.idempotency_key` jsonb?
   - Recommendation: Dedicated nullable column with partial UNIQUE index. Cheaper + simpler than GIN on jsonb.

2. **`deliver_many/2` v0.1 scope: async only, or sync + async?** (Assumption A6)
   - What we know: CONTEXT.md D-15 specifies batch Multi shape + idempotency replay.
   - What's unclear: Whether the sync-batch adapter-fan-out path ships at v0.1.
   - Recommendation: Ship async-only at v0.1; sync-batch is a v0.5 add. Document in `api_stability.md` §Outbound.

3. **`Mailglass.Error.BatchFailed` as new struct?** (Assumption A7)
   - What we know: D-16 says `deliver_many!/2` raises `%Mailglass.Error.BatchFailed{failures: [%Delivery{}]}`.
   - What's unclear: New struct module or reuse existing `SendError`?
   - Recommendation: New struct. Matches the "distinct shape → distinct struct" discipline from Phase 1 D-01..D-09.

4. **Runtime auth-stream guard function-name regex (D-38) — exactly what does "function name" mean?**
   - What we know: D-38 says `recovered from Message.mailable_function` + regex `magic_link|password_reset|verify_email|confirm_account`.
   - What's unclear: Is `mailable_function` a new field on `%Message{}`, or is it extracted from `__mailable__` reflection at send time?
   - Recommendation: Add `mailable_function :: atom() | nil` to `%Message{}` struct; populated by the injected `def welcome(...)` in the mailable (the macro captures `__ENV__.function` via `@before_compile`). Documented in `api_stability.md`.

5. **RateLimiter configuration granularity — how do adopters override per `(tenant_id, recipient_domain)` limits?**
   - What we know: D-23 default is `capacity = 100, refill_per_ms = 100/60_000`.
   - What's unclear: Shape of per-domain override.
   - Recommendation:
     ```elixir
     config :mailglass, :rate_limit,
       default: [capacity: 100, per_minute: 100],
       overrides: [
         {"gmail.com", [capacity: 500, per_minute: 500]},
         {"transactional-tenant", [capacity: 1000, per_minute: 1000]}
       ]
     ```
     Planner's discretion.

---

## Environment Availability

Phase 3 depends on existing stack (no new required deps). Probed for completeness:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `swoosh` | `Mailglass.Adapters.Swoosh`, Fake | ✓ | 1.25.0 | — |
| `phoenix_pubsub` | Projector broadcasts, PubSub.Topics | ✓ | (transitive via phoenix 1.8.5) | — |
| `phoenix_token` / Plug.Crypto | Tracking token signing | ✓ | (in `plug_crypto ~> 2.x`, transitive) | — |
| `oban` | `Mailglass.Outbound.Worker` | ✓ (optional) | 2.21.1 | Task.Supervisor (D-21) |
| `ecto_sql` | Multi composition, sandbox | ✓ | 3.13.5 | — |
| `nimble_options` | Config schema | ✓ | 1.1.1 | — |
| `telemetry` | Spans, single emits | ✓ | 1.4.1 | — |
| `stream_data` | Property tests | ✓ (test-only) | 1.3.0 | — |
| `floki` | Tracking Rewriter (link rewriting, pixel injection) | ✓ | 0.38.1 | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Oban (D-17 boot warning + Task.Supervisor path).

---

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/mailglass/.planning/phases/03-transport-send-pipeline/03-CONTEXT.md` — 39 locked decisions (D-01..D-39), spec_lock amendments, canonical refs
- `/Users/jon/projects/mailglass/.planning/phases/02-persistence-tenancy/02-06-SUMMARY.md` — Phase 2 Projector + SuppressionStore shipping shapes
- `/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md` §2.1 — hot-path data flow diagram that Phase 3 D-18/D-20/D-21 implement
- `/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md` §3.3 — "The one GenServer" — RateLimiter ETS ownership pattern
- `/Users/jon/projects/mailglass/.planning/research/PITFALLS.md` LIB-01 through LIB-07, MAIL-01, TEST-01, TEST-06
- `/Users/jon/projects/mailglass/.planning/research/STACK.md` §1.1, §2 — version verification (Swoosh 1.25.0, Oban 2.21.1, phoenix_pubsub via phoenix 1.8.5)
- `/Users/jon/projects/mailglass/.planning/research/SUMMARY.md` §Executive Summary + §Key Findings
- `/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md` — AUTHOR-01, TRANS-01..04, SEND-01..05, TRACK-01/03, TEST-01/02/05 requirement text
- `/Users/jon/projects/mailglass/.planning/ROADMAP.md` §Phase 3 — success criteria + dependencies

### Primary — existing code (HIGH confidence)

- `/Users/jon/projects/mailglass/lib/mailglass/message.ex` — `%Message{}` struct shape
- `/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex` — Delivery schema (8 projection cols + lock_version)
- `/Users/jon/projects/mailglass/lib/mailglass/outbound/projector.ex` — Projector.update_projections/2 (Phase 3 extends with PubSub broadcast)
- `/Users/jon/projects/mailglass/lib/mailglass/events.ex` — `append_multi/3` (consumed by every Phase 3 Multi)
- `/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex` — `current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`
- `/Users/jon/projects/mailglass/lib/mailglass/renderer.ex` — `render/2` pure pipeline
- `/Users/jon/projects/mailglass/lib/mailglass/telemetry.ex` — span helpers (add `send_span`, `dispatch_span` in Phase 3)
- `/Users/jon/projects/mailglass/lib/mailglass/config.ex` — NimbleOptions schema (extended with `:tracking`, `:rate_limit`, `:async_adapter`)
- `/Users/jon/projects/mailglass/lib/mailglass/optional_deps/oban.ex` — Oban gateway + TenancyMiddleware (Phase 2)
- `/Users/jon/projects/mailglass/lib/mailglass/errors/*.ex` — 7 error structs (ConfigError extended with 2 new atoms)
- `/Users/jon/projects/mailglass/lib/mailglass/suppression_store.ex` + `suppression_store/ecto.ex` — SuppressionStore behaviour + Ecto impl
- `/Users/jon/projects/mailglass/lib/mailglass/application.ex` — supervision tree (Phase 3 adds PubSub, TaskSupervisor, RateLimiter.Supervisor, Fake.Supervisor)
- `/Users/jon/projects/mailglass/mix.exs` — `elixirc_options[:no_warn_undefined]`, deps list (no new deps for Phase 3)
- `/Users/jon/projects/mailglass/docs/api_stability.md` — Phase 3 extends with Adapter, Outbound, Mailable, RateLimiter, Clock, PubSub, Tracking sections

### Secondary — Swoosh / Oban upstream (HIGH confidence)

- `/Users/jon/projects/mailglass/deps/swoosh/lib/swoosh/adapters/sandbox.ex` — canonical ownership pattern (D-01 mirrors verbatim)
- `/Users/jon/projects/mailglass/deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex` — ETS + GenServer shape (D-01)
- `/Users/jon/projects/mailglass/deps/swoosh/lib/swoosh/test_assertions.ex` — TestAssertions matcher shape (D-05)
- `/Users/jon/projects/mailglass/deps/oban/lib/oban.ex:575-653` — `Oban.insert/3` signatures (Multi composition, D-21)

### Tertiary — prior-art (MEDIUM confidence, flagged for validation)

- `~/projects/accrue/lib/accrue/processor/fake.ex` — accrue's Fake pattern; referenced in CONTEXT.md for `trigger_event/3` API shape. NOT validated against actual file contents in this research pass — cited from CONTEXT.md.
- `~/projects/accrue/lib/accrue/billable.ex` — 15-line injection budget precedent. Same caveat.
- `~/projects/accrue/lib/accrue/test/mailer_assertions.ex` — receive-based async-safe assertions. Same caveat.
- Mailchimp open-redirect CVEs (2019, 2022) — cited in CONTEXT.md as cautionary tale for D-35. `[CITED: prompts/Phoenix needs an email framework not another mailer.md]`

### External standards

- Phoenix.Token / Plug.Crypto — `[CITED: deps/plug_crypto]` not read in this pass; documented in Phoenix hex docs.
- RFC 8058 (List-Unsubscribe-Post) — v0.5 forward-ref; Phase 3 only reserves the skip-rule in Rewriter.
- Apple Mail Privacy Protection — informs D-31 independent opens/clicks booleans.

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — all required and optional deps already shipping, verified in `mix.exs`.
- Architecture: **HIGH** — CONTEXT.md locks 39 decisions; ARCHITECTURE.md §2.1-§3.6 already laid the hot-path and process architecture; Phase 2 shipped the downstream persistence layer.
- Pitfalls: **HIGH** — PITFALLS.md maps directly to Phase 3 concerns; LIB-01..06 + MAIL-01 + TEST-01/06 have explicit prevention in D-09/D-22/D-29/D-30/D-38.
- Fake adapter design: **HIGH** — Swoosh.Adapters.Sandbox source read and verified.
- Oban gateway: **HIGH** — Phase 2 already ships the gateway + TenancyMiddleware; Phase 3 consumes.
- Test assertions: **MEDIUM-HIGH** — Swoosh.TestAssertions source sampled (lines 1-100); full 4-style matcher implementation details deferred to planner.
- `deliver_many/2` semantics: **MEDIUM** — D-15 specifies the shape but sync-batch complexity may require a v0.1 scope reduction (Open Question #2).
- Idempotency key storage: **MEDIUM** — Assumption A1 flagged; migration decision deferred to planner/discuss-phase.

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (30 days — stable codebase, decisions locked)
