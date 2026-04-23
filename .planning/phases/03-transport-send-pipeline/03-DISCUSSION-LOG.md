# Phase 3: Transport + Send Pipeline — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 03-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 03-transport-send-pipeline
**Areas discussed:** Fake adapter + test tooling; Public API (Mailable use + Outbound facade); Send pipeline internals; Tracking opt-in + click rewriting
**Mode:** Multi-area research-backed (4 parallel subagents). User directive: *"research using subagents, what is pros/cons/tradeoffs of each considering the example for each approach, what is idiomatic for elixir/plug/ecto/phoenix for this type of lib/app and in this ecosystem, lessons learned from other libs/apps in same space even from other languages/frameworks if they are popular successful, what did they do right that we should learn from, what did they do wrong/footguns we can learn from, great developer ergonomics/dx emphasized... user friendly... think deeply one-shot a perfect set of recommendations so i dont have to think, all recommendations are coherent/cohesive with each other and move us toward the goals/vision of this project... using great software architecture/engineering, principle of least surprise and great UI/UX wheere applicable great dev experience."*

Four research subagents ran in parallel, each briefed with Phases 1+2 locked context + project D-01..D-20 + brand voice + explicit coherence constraints (shared vocabulary, shared Projector + Events.append_multi write paths, shared Oban.TenancyMiddleware). Reports synthesized into a single coherent 35-decision set (D-01..D-39 with gaps for structure) under four topic groupings.

---

## Area 1 — Fake adapter + test tooling

### Q1.1 — Fake adapter state primitive

| Option | Description | Selected |
|--------|-------------|----------|
| Swoosh.Adapters.Sandbox-style (supervised GenServer + named public ETS, owner-pid keyed, `$callers` + allow-list) | Battle-tested for Phoenix request / LiveView / Oban worker / browser-test processes; verbatim-adoptable pattern | ✓ |
| Swoosh.Adapters.Test-style (`Process.group_leader()` + `send(pid, {:email, _})`) | Simpler, but breaks for LiveView and Oban worker processes — known pain | |
| Agent wrapping a map | Identical cost to GenServer with less control over monitors | |
| ETS-per-test-process | Explodes table count under `async: true` (ERL_MAX_ETS_TABLES ~1400) | |
| Accrue-style single-GenServer with struct state | Serialized bottleneck; blocks `async: true` at scale | |

**User's choice:** Swoosh.Sandbox pattern. **Notes:** D-01. Inherits Swoosh.Sandbox's Phoenix/LiveView/Oban/PhoenixTest.Playwright/Wallaby integration guarantees for free. Records `%Mailglass.Message{}` (not raw `%Swoosh.Email{}`) so `assert_mail_sent(mailable: UserMailer)` works.

### Q1.2 — Fake adapter supervision

| Option | Description | Selected |
|--------|-------------|----------|
| Unconditionally started after `Mailglass.Repo`; init-and-idle GenServer owns ETS | ≈2KB idle cost; no "not started" race on first deliver | ✓ |
| Conditionally started when `config :mailglass, adapter: Fake` | Adds branch logic + boot-order dependency on Config | |
| Start-on-demand from `Fake.deliver/2` | Race conditions under parallel test startup | |

**User's choice:** Unconditional. **Notes:** D-02.

### Q1.3 — Simulation API

| Option | Description | Selected |
|--------|-------------|----------|
| `trigger_event/3` runs the REAL `Events.append_multi + Projector.update_projections` path | Fake proves production write path; one source of truth with Phase 4 webhooks | ✓ |
| Fake-only in-memory event log | Duplicates production code paths; bugs hide | |
| Direct DB writes bypassing `Events.append` | Breaks `NoRawEventInsert` Credo check | |

**User's choice:** Real-path funnel. **Notes:** D-03 + D-04 (Projector extension to PubSub-broadcast after commit).

### Q1.4 — TestAssertions matcher style

| Option | Description | Selected |
|--------|-------------|----------|
| All three styles: keyword + struct-pattern macro + function predicate + `assert_mail_delivered/2` + `assert_mail_bounced/2` | Mirrors Swoosh plus Projector-broadcast-backed async assertions | ✓ |
| Keyword only | ActionMailer tried; had to add others later | |
| Pattern macro only | No quick ad-hoc multi-field predicates | |

**User's choice:** All three + two async. **Notes:** D-05. `wait_for_mail/1` uses `assert_receive` against the Fake-`send`-to-owner signal; `assert_mail_delivered/2` uses `assert_receive` against Projector PubSub broadcasts — no polling anywhere.

### Q1.5 — MailerCase template

| Option | Description | Selected |
|--------|-------------|----------|
| `async: true` default + Sandbox checkout + Fake checkout + Tenancy.put_current + PubSub subscribe + optional Clock freeze; `set_mailglass_global/1` forces `async: false` | Inherits Swoosh convention; tests opt out of isolation explicitly | ✓ |
| `async: false` default | Loses 5-10× test speed; no benefit | |
| Three parallel templates duplicating setup | Drift inevitable | |

**User's choice:** Compose. **Notes:** D-06. WebhookCase + AdminCase `use Mailglass.MailerCase` and layer Plug/LiveView helpers.

### Q1.6 — Clock injection

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime `Application.get_env` + process-dict Frozen override | Per-process per-test isolation; `async: true`-safe | ✓ |
| `Mix.env()` branch | Compile-time; breaks runtime test helpers | |
| Global GenServer clock (accrue pattern) | Blocks async | |
| Compile-time `Application.compile_env` | Recompile penalty | |

**User's choice:** Runtime + process-dict. **Notes:** D-07. `Fake.advance_time/1` delegates to `Clock.Frozen.advance/1`.

### Q1.7 — Oban test mode default

| Option | Description | Selected |
|--------|-------------|----------|
| `:inline` default; `@tag oban: :manual` opts out | `deliver_later` "just works" synchronously in tests | ✓ |
| `:manual` default | Users surprised when `deliver_later` produces no assertable mail | |

**User's choice:** `:inline`. **Notes:** D-08.

---

## Area 2 — Public API: Mailable `use` + Outbound facade

### Q2.1 — `use Mailglass.Mailable` injection

| Option | Description | Selected |
|--------|-------------|----------|
| 15 lines: @behaviour + @before_compile + @mailglass_opts + import Swoosh.Email + import Mailglass.Components + new/0 + render/3 + deliver/2 + deliver_later/2 + defoverridable | Matches Swoosh.Mailer idiom; enables Phase 5 admin discovery + Phase 6 Credo | ✓ |
| Minimal `@behaviour` only | Pushes repetition onto adopters (no `import Swoosh.Email`) | |
| Fatter injection with `import Phoenix.Component` | HEEx collision risk with adopter templates | |

**User's choice:** 15-line mid-shape. **Notes:** D-09. LINT-05 AST budget `15 ≤ 20`.

### Q2.2 — Adopter usage convention

| Option | Description | Selected |
|--------|-------------|----------|
| (A) ActionMailer-style `MyApp.UserMailer.welcome(user) \| Mailglass.deliver()` | Forces adopters to remember a top-level facade | |
| (B) Swoosh-native, injected `deliver` — `UserMailer.welcome(user) \| UserMailer.deliver()` | Pipe-native; `UserMailer` is single grep target | ✓ |
| (C) Phoenix.Swoosh-style separate `MyApp.Mailer` module | Adds module adopters don't need | |

**User's choice:** (B) with `defdelegate deliver, to: Mailglass.Outbound, as: :send`. **Notes:** D-10. Satisfies AUTHOR-01 verbatim via delegation chain.

### Q2.3 — Static declarations (subject/from/stream/tracking)

| Option | Description | Selected |
|--------|-------------|----------|
| Three tiers: `use` opts (stream/tracking/from_default/reply_to_default) + runtime builder (subject/to) + no attrs/callbacks | Matches Swoosh builder + enables compile-time Credo | ✓ |
| Module attrs (`@subject`, `@from`) | Can't interpolate config; silent override hazards | |
| `subject/1` callback | Duplicates builder function | |

**User's choice:** Three-tier. **Notes:** D-11.

### Q2.4 — preview_props/0 placement

| Option | Description | Selected |
|--------|-------------|----------|
| Optional zero-arity callback on the mailable module | Adjacent to email code; no separate file drift | ✓ |
| Separate `UserMailer.Preview` module | Doubles module count; physical distance drifts | |
| Required callback | Punishes non-Phase-5 adopters | |

**User's choice:** Optional callback. **Notes:** D-12.

### Q2.5 — Outbound facade naming (send vs deliver)

| Option | Description | Selected |
|--------|-------------|----------|
| `deliver/2` canonical + `send/2` internal; `defdelegate deliver, as: :send` | Matches universal email-library vocabulary | ✓ |
| Only `deliver/2` | Awkward telemetry span names; `Kernel.send/2` shadow warning in internal code | |
| Expose `send/2` publicly | Adopters confused by Kernel conflict | |

**User's choice:** `deliver` canonical, `send` internal. **Notes:** D-13.

### Q2.6 — deliver_later/2 return shape

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Synchronous `%Delivery{status: :queued}` insert + Oban job in same Multi; returns `{:ok, %Delivery{}}` uniformly | Honors TRANS-04 contract; no Oban type leakage | ✓ |
| (b) Returns `{:ok, %Oban.Job{}}` — Worker builds Delivery on first run | Breaks `--no-optional-deps` lane; type signature mentions optional dep | |
| Returns `{:ok, :enqueued}` | Opaque; prevents test assertions | |

**User's choice:** (a). **Notes:** D-14. Task.Supervisor fallback returns the same shape.

### Q2.7 — deliver_many/2 partial-failure semantics

| Option | Description | Selected |
|--------|-------------|----------|
| `{:ok, [%Delivery{}]}` always; each carries `status` + `last_error` | One shape; 1:1 input-output; Ecto.Multi philosophy | ✓ |
| `{:ok, successes, errors}` 3-tuple | Two shapes; loses 1:1 correspondence | |
| `{:partial, successes, errors}` tagged | Callers pattern-match two shapes | |
| Raise `%BatchError{failures}` | Breaks Oban worker composability | |

**User's choice:** Uniform `{:ok, [%Delivery{}]}`. **Notes:** D-15.

### Q2.8 — Bang variants

| Option | Description | Selected |
|--------|-------------|----------|
| `deliver!/2` + `deliver_many!/2` raise underlying `%Mailglass.Error{}` struct directly; `deliver_later!/2` does NOT exist | Preserves struct pattern-match; async has nothing to raise about | ✓ |
| Wrap in `%Swoosh.DeliveryError{}` | Breaks closed `:type` atom set | |
| Add `deliver_later!/2` for symmetry | Raises on what? Enqueue ≠ delivery | |

**User's choice:** Direct struct raise, no async bang. **Notes:** D-16.

### Q2.9 — Oban-fallback warning cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Exactly once at `Mailglass.Application.start/2`, `:persistent_term`-gated, `async_adapter: :task_supervisor` silences | Phoenix 1.8 convention; no log-pipeline DoS | ✓ |
| Per-call throttled warning | Log spam in burst traffic | |
| Never warning | Silent correctness hazard | |

**User's choice:** Boot-once gated. **Notes:** D-17.

---

## Area 3 — Send pipeline internals

### Q3.1 — Preflight pipeline sequence

| Option | Description | Selected |
|--------|-------------|----------|
| 5 stages + precondition: `Tenancy.assert_stamped!` → Suppression → RateLimiter → Stream.policy_check → Renderer → Persist | Tenancy as precondition, not stage (it's a query-scoping helper, not a pipeline call) | ✓ |
| Literal SEND-01 sequence (`Tenancy.scope → ...`) | `scope/2` is not a pipeline call; misphrased | |
| Stages-only (omit precondition) | Silent `"default"` tenant fallback on broken stamps | |

**User's choice:** Precondition + 5 stages. **Notes:** D-18. SEND-01 REQ-amendment: planner owns (see spec_lock).

### Q3.2 — Render timing

| Option | Description | Selected |
|--------|-------------|----------|
| Render AFTER preflight | <100μs preflight × 40 vs 4ms render; suppression hit rate <1% | ✓ |
| Render BEFORE preflight | Fails fast but wastes CPU on suppressed sends | |

**User's choice:** Late. **Notes:** D-19.

### Q3.3 — Sync path Multi grouping

| Option | Description | Selected |
|--------|-------------|----------|
| (2) Two Multis with adapter call outside any transaction | Adapter-in-transaction starves connection pool; orphans recoverable via Reconciler | ✓ |
| (1) Single Multi with `Multi.run(:adapter, ...)` | Holds Postgres connection across provider I/O | |

**User's choice:** Two Multis. **Notes:** D-20.

### Q3.4 — Async path Multi grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Single `Oban.insert/3`-composed Multi (Delivery + Event + Job atomic) | What Oban v2.17+ is designed for; no orphan jobs | ✓ |
| Enqueue-after-commit | Crash between commit and enqueue = orphan `:queued` | |

**User's choice:** Oban-in-Multi. **Notes:** D-21.

### Q3.5 — RateLimiter ETS ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Pattern A: tiny Supervisor + init-and-idle GenServer TableOwner | Hot path = pure `:ets.update_counter`; no mailbox serialization | ✓ |
| Pattern B: Module-as-GenServer with handle_call | Serializes every check through mailbox — destroys throughput | |
| Pattern C: Task child | No init lifecycle; easy to miss restart semantics | |
| Pattern D: `heir` for crash survival | Complexity tax; supervisor restart is sufficient | |

**User's choice:** Pattern A. **Notes:** D-22. Table name `:mailglass_rate_limit` reserved in api_stability.md.

### Q3.6 — Token bucket math

| Option | Description | Selected |
|--------|-------------|----------|
| Leaky bucket with continuous refill, atomic `:ets.update_counter/4` multi-op | 1-3μs hot path; no thundering herd | ✓ |
| Strict per-minute window | All buckets reset simultaneously at minute boundary | |
| Sliding window with timestamp list | More memory, more complexity, no throughput benefit | |

**User's choice:** Leaky bucket. **Notes:** D-23.

### Q3.7 — Per-stream rate-limit bypass

| Option | Description | Selected |
|--------|-------------|----------|
| `:transactional` bypasses unconditionally; `:operational` + `:bulk` throttle | Matches D-08 auth-never-blocked spirit | ✓ |
| Configurable stream-allowlist | Adopters misconfigure to "fix" marketing campaigns | |
| Never bypass | Password-reset lockout during incidents | |

**User's choice:** Unconditional bypass. **Notes:** D-24. Documented invariant.

### Q3.8 — Stream.policy_check at v0.1

| Option | Description | Selected |
|--------|-------------|----------|
| (a) No-op seam returning `:ok` + telemetry emit | v0.5 DELIV-02 swaps impl without touching callers | ✓ |
| Omit entirely | v0.5 has to add a preflight stage = API change | |
| Minimal enum check | Dead code (already enforced at schema level via Ecto.Enum) | |

**User's choice:** Seam. **Notes:** D-25.

### Q3.9 — Telemetry span granularity

| Option | Description | Selected |
|--------|-------------|----------|
| 1 outer send span + 3 inner full spans (render/persist/dispatch) + 2 single-emit events (suppression/rate_limit) | Matches work-cost; avoids ceremonial pairs on sub-10μs checks | ✓ |
| 5 full `:start`/`:stop` pairs (every stage) | Handler overhead × 2 per stage; ceremonial | |
| Single outer span with stage durations in `:stop` metadata | Conflicts with 4-level naming convention | |

**User's choice:** Mixed granularity by cost. **Notes:** D-26 + D-27 (PubSub.Topics) + D-28 (SuppressionStore.ETS) + D-29 (Adapters.Swoosh mapping).

---

## Area 4 — Tracking opt-in + click rewriting

### Q4.1 — Per-mailable tracking config shape

| Option | Description | Selected |
|--------|-------------|----------|
| (A) `use Mailglass.Mailable, tracking: [opens: true, clicks: true]` — compile-time | AST-inspectable for TRACK-02 Credo; one policy per module | ✓ |
| (B) Function-local `@tracking` | Fragile AST walking | |
| (C) Runtime `Message.put_tracking/2` | Defeats compile-time Credo | |
| (D) Per-call opt in `deliver/2` opts | Fully runtime; auditors can't track usage | |
| (E) Hybrid compile+runtime override | Invites runtime bypass | |

**User's choice:** (A). **Notes:** D-30. Runtime can DISABLE (per-call `tracking: false`), never ENABLE.

### Q4.2 — Opens vs clicks coupling

| Option | Description | Selected |
|--------|-------------|----------|
| Independent booleans (`opens: bool, clicks: bool`) | Apple Mail Privacy Protection makes `opens: false, clicks: true` a real config | ✓ |
| Coupled `tracking: :full \| :opens_only \| :off` | Hides the real axis | |

**User's choice:** Independent. **Notes:** D-31.

### Q4.3 — Tracking host config

| Option | Description | Selected |
|--------|-------------|----------|
| Required when any mailable opts in; validated at boot; multi-tenant via optional `c:tracking_host/1` callback | Cookie isolation mandatory; per-tenant subdomain supported | ✓ |
| Allow default to main host with `Logger.warning` | CVE waiting to happen | |
| Always-required globally even if no mailable opts in | Punishes non-tracking adopters | |

**User's choice:** Conditionally required. **Notes:** D-32.

### Q4.4 — Phoenix.Token rotation

| Option | Description | Selected |
|--------|-------------|----------|
| `salts: ["v3", "v2", "v1"]` list + `max_age: 2 years` | Concrete rotation; bounded token lifetime | ✓ |
| Single salt | No rotation path | |
| `max_age: :infinity` | Defeats signing | |

**User's choice:** Salts list + 2y. **Notes:** D-33.

### Q4.5 — Open pixel URL shape

| Option | Description | Selected |
|--------|-------------|----------|
| `GET /o/<token>.gif`, 43-byte GIF89a, `Cache-Control: no-store, private` | Gmail image proxy friendly; cache-bust safe | ✓ |
| POST | Pixels are GET; browsers/clients won't POST | |
| Query-string token | Harder to cache-bust; uglier email source | |

**User's choice:** Path token + `.gif`. **Notes:** D-34.

### Q4.6 — Click URL shape + open-redirect defense

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Full URL encoded inside signed token; no `?r=` param | Structurally impossible to open-redirect | ✓ |
| (b) Token + url param with HMAC | One HMAC bug = open redirect (Mailchimp CVEs) | |
| (c) Hybrid token covers url_hash | Complexity with no security win over (a) | |

**User's choice:** (a). **Notes:** D-35.

### Q4.7 — Link-rewriting scope

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite `<a href="http(s)://...">` only; skip `mailto:/tel:/sms:/#/data:/javascript:/relative`, `data-mg-notrack`, List-Unsubscribe URL, `<head>` links | Surgical; opt-out attribute for adopters | ✓ |
| Rewrite everything including `mailto:` | Breaks email-action links | |
| Rewrite including plaintext | Destroys copy/paste-as-destination user trust | |

**User's choice:** Surgical HTML-only. **Notes:** D-36.

### Q4.8 — Open pixel injection timing

| Option | Description | Selected |
|--------|-------------|----------|
| Last child of `<body>`, auto-injected by Rewriter; NEVER adopter-visible in template | Defers load; content-blockers less aggressive at end-of-body | ✓ |
| In `<head>` | Ignored by most clients | |
| Top of `<body>` | Content-blockers sometimes strip leading images | |
| Adopter-visible via template | Opens a footgun surface (adopters forget, or double-inject) | |

**User's choice:** End-of-body auto-inject. **Notes:** D-37.

### Q4.9 — Runtime behavior on TRACK-02 bypass

| Option | Description | Selected |
|--------|-------------|----------|
| (iii) RAISE `%ConfigError{type: :tracking_on_auth_stream}` at send time | D-08 is normative; merge-blocking in CI | ✓ |
| (i) Silent respect | Violates D-08 | |
| (ii) Warn + track anyway | Production log warnings get muted; PII risk persists | |

**User's choice:** Raise. **Notes:** D-38.

### Q4.10 — Tenancy interaction

| Option | Description | Selected |
|--------|-------------|----------|
| `tenant_id` in signed token payload ONLY; never URL path/query | Prevents referrer leak, screenshot leak, proxy log leak | ✓ |
| `tenant_id` in URL path (`/o/acme/<token>`) | Leaks to referrer headers, Outlook SafeLinks pre-fetch | |

**User's choice:** Signed payload. **Notes:** D-39.

---

## Claude's Discretion (delegated to planner/executor)

- Exact `Mailglass.Mailable` moduledoc wording.
- Exact `Mailglass.Outbound.Delivery.new/1` helper signature for `deliver_many/2` batch-input construction.
- Exact telemetry measurement structure for single-emit events (`:duration_us` vs `:measurements.duration`) — follow Phase 1 precedent.
- Exact error-mapping table in `Mailglass.Adapters.Swoosh` for Postmark + SendGrid shapes.
- Tracking endpoint Plug pipeline composition (CachingBodyReader NOT needed — pixel/click endpoints don't need raw body preservation).
- Fake adapter JSON-compatibility format on `deliveries/1` output.
- `Mailglass.PubSub` supervision order (after Repo, before Fake.Supervisor).
- `Mailglass.Outbound.Worker` Oban queue name (`:mailglass_outbound`), max_attempts (20), unique constraint per `:delivery_id`.
- Exact `MailerCase` `@tag` vocabulary (`:tenant`, `:frozen_at`, `:oban`).

## Deferred Ideas (captured in CONTEXT.md `<deferred>`)

Per-tenant adapter resolver (v0.5), `:pg`-coordinated rate limits (v0.5), List-Unsubscribe headers (v0.5), Stream-policy enforcement beyond no-op (v0.5), `SuppressionStore.Redis` (v0.5+), DKIM signing helper (v0.5), `mix mail.doctor` (v0.5), Feedback-ID stable format (v0.5), per-call tracking override (rejected permanently), sliding-window rate limiting (rejected), `deliver_later!/2` (rejected), mandatory `preview_props/0` (rejected), `Message.put_tracking/2` runtime (rejected), wildcard TLS automation (out of scope), consent UI (out of scope), tracking event dedup across webhook+endpoint (lives in Phase 5 admin), Firefox ETP mitigations (not our problem), sync single-Multi optimization (rejected permanently — production outage vector).
