# The 2026 Phoenix/Elixir ecosystem map for senior engineers

**Bottom line up front:** The Elixir ecosystem in April 2026 is the most coherent it has ever been. Phoenix 1.8 (Aug 2025) plus LiveView 1.1 (Jul 2025) locked in a new default stack — Bandit as the web server, Req as the HTTP client, Swoosh for mail, Oban (with free OSS Oban Web) for jobs, daisyUI + Tailwind v4 for components, Ecto scopes baked into auth generators. José Valim's set-theoretic type system shipped inference of all constructs in 1.20-rc (Jan 2026), making Dialyzer's retirement a matter of when, not if. The pain points are narrow and specific: **authentication** (no Devise/Rodauth equivalent — `phx.gen.auth` generates code, Ash Authentication requires Ash, Pow is abandoned), **payments** (`stripity_stripe` is the only option, still on HTTPoison, with no Ecto-integrated billing layer anywhere in the ecosystem), plus a few stagnant corners like multi-tenancy libraries, Cloak encryption, and media-processing wrappers. Your two WIP projects land squarely in the two biggest holes. What follows is the opinionated map: pick these, skip those, watch these.

---

## 1. Core framework & runtime

**Phoenix (1.8.5).** Shipped Aug 5, 2025. Introduced **scopes** (first-class, router+LiveView-plumbed, generators emit scope-aware context functions — OWASP broken-access-control prevention by default), **magic-link auth** + `require_sudo_mode` in the auth generator, **Tailwind v4 + daisyUI** replacing hand-rolled `core_components.ex` (⚠️ `modal` component was removed; daisyUI uses native `<dialog>`), and `AGENTS.md` generated for LLM tooling. No 1.9 line exists yet. Requires OTP 25+. Retrofitting scopes into an existing 1.7 app is nontrivial.

**Phoenix LiveView (1.1.x).** 1.0 shipped Dec 2024 (API lockdown for risk-averse orgs); **1.1 added colocated hooks** — write JS hooks inline in HEEx via `<script :type={Phoenix.LiveView.ColocatedHook} name=".MyHook">`, dot-prefix auto-namespaces to module so library authors stop colliding on global hook names. Also **keyed comprehensions** for stable-identity list diffing, and a parser switch from Floki to lazy_html (lexbor-based, supports `:is()`/`:has()` selectors). Upgrade via `mix igniter.upgrade phoenix_live_view`.

**Phoenix.Component.** Canonical since 1.7. `attr`/`slot` with compile-time warnings, HEEx-everywhere. Surface is formally legacy relative to this.

**Phoenix.PubSub (~> 2.1).** Rock-solid. Default `:pg` adapter uses Erlang process groups — with `dns_cluster` (shipped in `phx.new`), multi-node BEAM clustering on Fly/K8s is trivial and **you do not need Redis** for pubsub. The Redis adapter (`phoenix_pubsub_redis 3.0.1`) remains available for cross-region deployments that can't cluster.

**Bandit (1.10.x) — the default.** Has been the default HTTP adapter since Phoenix 1.7.11, carried forward in 1.8. Pure Elixir on Thousand Island, full HTTP/2 + WebSocket RFC compliance, built-in connection draining. Up to ~4× Cowboy on some HTTP/1 workloads, at-parity-or-better on real Phoenix apps. **Only reason to choose Cowboy for greenfield: none.** Cowboy remains maintained for legacy apps.

**Plug (~> 1.18), Ecto (3.13.5), ecto_sql (3.13.5), Postgrex (~> 1.0).** Zero drama, zero alternatives, canonical. Ecto added **`@schema_redact`** in 2025 for auto-redacting sensitive fields from logs/inspects — use it.

---

## 2. Database & persistence

**Ecto + Postgrex.** Default. Prefer Postgres over MySQL if you have the choice — the entire ecosystem (Oban, Cloak, most libs) is Postgres-first.

**MyXQL (0.7.x).** Maintained by Wojtek Mach, low volume but alive. Inherits MySQL's limits: no RETURNING (no `:read_after_writes`), non-transactional DDL, no native UUID type.

**Oban (2.21.x) — THE job system, no debate.** Postgres/MySQL/SQLite engines, transactional enqueue, exactly-once semantics, built-in cron, rich observability. Dropping official support for PG <14. **Oban Web went free and OSS in January 2025** (Apache 2.0) — install the router macro unconditionally. **Oban Pro** remains commercial and essentially mandatory once you need global rate limits, workflows/DAGs, chains/chunks/batches, encrypted args, or Smart Engine queue partitioning; small apps can skip it.

**Quantum.** Redundant for any app running Oban — Oban's cron plugin covers it. Keep Quantum only if you have no DB.

**Broadway (1.3.0).** Dashbit's canonical data ingestion framework on GenStage. Official producers for SQS, Kafka, RabbitMQ, GCP PubSub. Use Broadway for external-queue streaming; use Oban for application job tables — different tools.

**Cloak / Cloak.Ecto (1.3.0).** ⚠️ **Stagnant but not dead** — last release April 2024, still 1.4M downloads/month. Encryption-at-rest with HMAC shadow columns for equality queries (ciphertext is random-IV and unsearchable). No per-user keys (Ecto.Type limitation). No credible replacement has emerged. Live with it.

**UUIDv7 — fragmented, three options.** `uuidv7` (martinthenth, Rust NIF) is the fastest and simplest. `uniq` (bitwalker) supports all UUID versions and is what Ash uses. `uuidv7` (ryanwinchester) emphasizes strict monotonicity. **Skip ULID entirely** — the original `ecto_ulid` is dead; use UUIDv7 (RFC 9562) instead for lexicographically sortable IDs.

**ecto_network (1.6.0).** Postgres INET/CIDR/MACADDR types. Actively maintained.

**Multi-tenancy — the canonical answer is "Ecto `prefix:` or Ash."** Triplex, Apartmentex, and Tenantex are all effectively dormant. Phoenix 1.8 scopes plus Ecto's built-in `prefix:` query option cover schema-per-tenant with ~200 lines less magic than Triplex. **If you're doing multi-tenant SaaS in 2026, default to row-level (a `tenant_id` column + Postgres RLS as defense-in-depth)** — simpler ops, easier analytics. Reach for schema-per-tenant only for strict compliance requirements with bounded tenant count (<1000). Ash Framework's `:attribute` and `:context` tenancy strategies are the most polished library-level answer, including auto-migration of tenant schemas.

---

## 3. Caching & in-memory

**Cachex (4.1.1) — single-node winner.** Rich: TTL, size limits, hooks, fallbacks (`Cachex.fetch/4`), transactions, warmers, on-disk backup. ⚠️ **Known pain: clustered mode doesn't support dynamic node membership** — bad fit for elastic Fly/K8s deployments that scale nodes in and out.

**Nebulex (3.x) — distributed/multi-tier winner.** Ecto-for-caching with pluggable adapters (Local, Partitioned, Replicated, Multilevel, Redis, Cachex). The idiomatic near-cache pattern is "Cachex local L1 + partitioned L2" via `nebulex_adapters_cachex`. Pick Nebulex when topology matters; pick Cachex when it doesn't.

**ETS + `:persistent_term`.** Still the fastest path for hot data — microsecond reads, zero GC. No library needed; `:ets.update_counter/3` for atomic counters, `:persistent_term` for rarely-mutated global config.

**Redix (1.5.3).** The only Redis client anyone uses. Redix processes are single connections — pool them yourself if throughput warrants. Explicit Valkey support in docs.

**2026 consensus on Redis.** The community has settled: **pure BEAM for BEAM-internal concerns, Redis only for cross-runtime needs.** Don't reach for Redis for pubsub, jobs, distributed locks, rate limiting, or caching — the BEAM primitives plus Oban/Cachex/Hammer outperform the ops cost. Reach for Redis when sharing state with non-BEAM services or when ops mandates it.

---

## 4. HTTP clients

**Req (0.5.17) — the standard.** Wojtek Mach's steps-based client, now the default HTTP dep in generated Phoenix 1.8 apps (required when Swoosh is generated). Auto-decompression (gzip/brotli/zstd), auto JSON, redirects, retries, streaming, AWS sigv4, test stubs via the `plug:` option. Rich plugin ecosystem: `req_llm`, `req_s3`, `req_sse`, `reqord` (VCR recording). Still 0.x but breakage has been minimal. **Use this for everything new.**

**Finch (~0.20).** The pool layer under Req (Mint + NimblePool). Touch directly only for pool-topology tuning.

**Mint.** The pure-functional HTTP/1+HTTP/2 primitive. Library authors only.

**Tesla (1.11.x) — fading legacy.** Still maintained but mindshare is gone. Its middleware/adapter architecture (the reason it won in 2018) has been quietly superseded by Req's composable steps. Andrea Leopardi (Mint/Redix author) has publicly cited Tesla's macro-heaviness as why he prefers Req. Don't start new projects with it; no urgent migration for existing code.

**HTTPoison (2.x) — definitively legacy.** Wraps hackney, which has questionable SSL defaults, no telemetry integration, and struggles under modern traffic patterns. **Migrate away.** Not acceptable for new code in 2026.

---

## 5. Authentication & authorization

> **⚠️ Ecosystem gap alert.** There is no Elixir equivalent to Devise, Rodauth, or Better Auth. The community deliberately traded "library" for "generator" based on the Valim/McCord thesis that auth should be owned code — which has left teams who want a maintained, pluggable dep with nothing good. **This is the single most-requested missing piece in the ecosystem, and your WIP auth library is filling it.**

**`mix phx.gen.auth` (Phoenix 1.8) — the de facto standard.** Magic-link default, password opt-in, `require_sudo_mode` plug for sensitive ops, scopes threaded through generated contexts. Bcrypt on Unix / pbkdf2 on Windows. **It's generated code, not a library** — upgrades are manual diffs, no OAuth, no passkeys, no MFA, no admin UI, no account linking. You start at roughly 40% of Devise's feature surface. Running the generator twice for User + Admin is explicitly brittle.

**Ash Authentication (4.4.9+).** The other legitimate "full" option, but **only if you adopt Ash Framework wholesale**. Password, magic link, OAuth2/OIDC, Apple/Google, token management, confirmation, password reset, planned OAuth2 provider mode. DSL-based so library upgrades propagate automatically. Hit ~70% of Devise's surface inside Ash's world. Not a drop-in for Phoenix+Ecto apps.

**Pow — abandoned.** ⚠️ Last release Jan 2025 was Elixir 1.18 deprecation cleanup. Hex pin `phoenix >= 1.3.0 and < 1.8.0` — it doesn't officially support the current Phoenix. Maintainer moved on to Assent. **Do not start new projects on Pow.**

**Assent (0.3.x).** Pow's successor as a framework-agnostic multi-provider OAuth/OIDC toolkit. Supports OAuth1, OAuth2, OIDC, PKCE, JWT client auth (RFC 7523), Apple Sign-In. You own the controller glue — it's a strategy library, not an auth system. Used by Ash Authentication and most modern starter kits.

**Guardian (2.3.2).** Alive and narrow. JWT token lib, nothing more — no registration, no sessions, no password reset. Canonical choice for mobile APIs and service-to-service JWT. For browser apps, `phx.gen.auth`'s session tokens beat it.

**Ueberauth + strategies.** The old default OAuth request-phase orchestrator. Individual strategies (google, github, apple, etc.) vary in maintenance; many are quiet but functional. Assent is generally newer and cleaner for greenfield.

**Oidcc / oidcc_plug / phx_gen_oidcc.** The **only OpenID-Certified** OIDC RP in the BEAM ecosystem, maintained by the Erlang Ecosystem Foundation Security WG. Full OIDC Core + dynamic client registration + PKCE + DPoP + FAPI + introspection. Overkill for commodity "Sign in with Google" but the correct choice for enterprise/healthcare/banking/FAPI workflows.

**Bodyguard.** Context-level authorization. Last repo push May 2024 — **feature-complete-and-paused**, not dead. The pattern (`authorize/3` on context modules) is so minimal that many teams copy it without the dep.

**LetMe (1.2.5).** Policy DSL with allow/deny rules, field redaction, Ecto scoping, introspection. Actively maintained but niche adoption. Returns only booleans — no reason-for-denial strings.

**Permit.** Curiosum's CanCanCan-inspired entry, presented at ElixirConf EU 2025. Its killer feature is auto-compiling rules into Ecto queries (what Bodyguard/LetMe make you do manually). Real library, modest adoption.

**Passkeys / WebAuthn — ⚠️ immature.** `wax_` (trailing underscore, namespace collision) is the canonical primitive — passes all 170 FIDO2 tests but slowed development. `webauthn_components` ships LiveView-friendly passkey UI but is explicitly labeled "early beta, not for production." **Ash Authentication has no first-class passkey support. `phx.gen.auth` generates no passkey flows.** Most production passkey implementations are hand-rolled on wax. **This is one of the areas where your auth library can make an outsized impact.**

---

## 6. Payments & billing

> **⚠️ The second major ecosystem gap.** The only serious Stripe client is aging, and **no Ecto-integrated billing layer exists** — every Phoenix SaaS team rebuilds subscriptions/invoices/webhook-persistence from scratch. Your Req-based Stripe client + Ecto billing layer is filling a genuine hole.

**stripity_stripe (3.2.0).** The only option. Maintained under `beam-community` but volunteer-driven, no Stripe-official support. ⚠️ **Still on HTTPoison/Hackney** — out of step with 2026 conventions. Ad-hoc OpenAPI codegen bolted onto v3 but releases lag Stripe's API by several versions (3.1.1 → 3.2.0 took ~6 months vs stripe-node's weekly cadence). No Ecto integration whatsoever — you get API structs, you model everything else. Webhook signature verification, Connect support, Idempotency-Key headers, test clocks all present.

**LemonSqueezy — `lemon_ex`.** Officially listed in LemonSqueezy's own docs. Maintained, modest scope (CRUD + webhook verification), HTTPoison-based. No billing abstraction.

**Paddle.** No first-class Elixir client. (The `paddle` hex package is an unrelated LDAP lib.) You hand-roll HTTP.

**Subscription management / metering.** Nothing. Not even an unmaintained one. **Unusual for a mature web ecosystem and exactly the shape of a Cashier-for-Phoenix opportunity.**

**OpenAPI codegen precedent.** `aj-foster/open-api-generator` (0.2.x, 111 stars) is the state of the art for generating idiomatic Elixir clients from OpenAPI specs with a pluggable HTTP stack — proof the Req-based approach is viable.

---

## 7. APIs (building)

**Phoenix JSON controllers.** The built-in `mix phx.gen.json` pattern (action-cased `*_json.ex` renderers) is fine for most APIs. Scopes flow through. **No built-in API versioning convention** — roll your own via URL prefix, `Accept` header plug, or per-controller namespacing.

**Absinthe (1.8.0, Nov 2025) — canonical GraphQL, very much alive.** The "Absinthe is dead" noise from 2023 is definitively wrong. Added `@oneOf` directive in 1.8. `absinthe_phoenix 2.0.4` (Dec 2025) finally refreshed after a 4-year dormancy on the subscriptions side. **Dataloader** (Nov 2025) is still required to solve N+1.

**AshGraphql (1.8.5).** Sits on Absinthe, auto-derives queries/mutations/subscriptions/SDL from Ash resources — massive boilerplate reduction if you're in Ash-land. You can drop to raw Absinthe inside the same schema for custom queries.

**GraphQL Federation.** Not first-class in Absinthe core (issue open since 2019, closed without native implementation). `absinthe_federation` (DivvyPayHQ, Apollo Federation v2 support) is the community port. Viable for Elixir subgraphs behind Apollo Router but not canonical.

**Hammer (7.2.0) — rate limiting.** v7 was a significant rewrite: new `use Hammer, backend: :ets` module pattern, algorithms expanded to fixed window + leaky bucket + token bucket, backends for ETS/atomic/Redis/Mnesia, poolboy dependency removed. Breaking change from v6; upgrade guide provided.

**PlugAttack (0.4.3).** Basically feature-complete. Safelist/blocklist/throttle with fail2ban-style backoff, ETS-backed. Best for quick IP-based rules; use Hammer for multi-node or richer algorithms.

**OpenApiSpex (3.21.4).** Still canonical for spec-first OpenAPI in Elixir. DSL-first, with a `CastAndValidate` plug for runtime request/response validation and Swagger/Redoc UI. Some teams prefer hand-written YAML + merge tooling (see the Curiosum critique); reasonable disagreement.

---

## 8. Real-time & WebSockets

**Phoenix Channels.** Unchanged, battle-tested, still the right choice for native mobile SDKs, custom protocols, and non-LiveView real-time consumers.

**Phoenix LiveView.** The real-time UI engine. Replaces React+GraphQL+WS+Redux for a large class of apps. Streams are the answer for large/unbounded collection state.

**Phoenix.Presence.** CRDT-based, canonical, no competitor. Memory scales with tracked entities × nodes — custom sharding needed beyond ~100k concurrent.

**Phoenix.Sync + ElectricSQL (0.3.x) — the emerging story.** Announced by Valim at ElixirConf US 2024, shipping as `phoenix_sync`. Embedded or HTTP mode, maps Ecto queries to Electric Shapes, `Phoenix.Sync.LiveView.sync_stream/4` drops into LiveView. **Still 0.x with limited query support** (no joins/order_by/limit/preload yet) — watch closely, don't bet a production launch on it pre-1.0.

---

## 9. Background jobs & data pipelines

**Oban (2.21.x)** — see §2. Canonical, no debate, Oban Web now free.

**Oban Pro (1.7+).** Commercial. Smart Engine (global concurrency + rate limits + auto-batching), Workflows (DAGs + cascade cancel), Batches, Chains/Chunks, DynamicPartitioner, encrypted args, decorators, Python bridge (Feb 2026). **Worth it when** you need cross-node rate limits, workflows, or batch fan-in/out — hand-rolling those on OSS Oban is painful.

**Broadway (1.3.0).** Production ingestion — SQS, Kafka, RabbitMQ, GCP PubSub. Back-pressure, batching, acks, rate limit, telemetry, built-in dashboard.

**Flow.** In-process windowed/aggregating stream computation on GenStage. Niche but sharp for analytics transforms.

**GenStage.** The primitive. Use directly only when writing custom producers.

---

## 10. Observability, logging, tracing, metrics

**Logger + LoggerJSON (7.x) + telemetry / telemetry_metrics.** The foundation. LoggerJSON ships formatters for GoogleCloud, Datadog, ECS/Elastic — drop it in via the Erlang `:logger` handler pipeline. Every major lib (Ecto, Phoenix, Oban, Broadway, Finch, Req) emits telemetry events.

**PromEx (~1.11+) — Prometheus + curated dashboards.** Plugins for Phoenix, Ecto, Oban, Broadway, BEAM, LiveView. **Use Peep as the storage adapter** for high-cardinality metrics (superior to `TelemetryMetricsPrometheus.Core`).

**OpenTelemetry Erlang.** Canonical package set: `opentelemetry` + `opentelemetry_api` + `opentelemetry_exporter` + `opentelemetry_semantic_conventions` from the core repo, plus instrumentation from `opentelemetry-erlang-contrib`: `opentelemetry_phoenix 2.0.1`, `opentelemetry_bandit` (or `opentelemetry_cowboy`), `opentelemetry_ecto`, `opentelemetry_req`. Start the OTel app as `:temporary` in releases so exporter failures can't crash your app. Cadence is slower than Python/JS OTel — tolerate it.

**Sentry Elixir (12.0.3).** The default error tracker. Uses the stdlib `JSON` module on Elixir 1.18+, Finch for transport, captures everything via `Sentry.LoggerHandler`. Built-in OTel `SpanProcessor` and Oban/Quantum cron check-ins. Peter Solnica (Drops) is contributing.

**Tower (0.6–0.7).** Vendor-agnostic error capture. Captures once via Logger handler, fans out to `tower_sentry` / `tower_honeybadger` / `tower_bugsnag` / `tower_rollbar` / `tower_slack`. **Worth it when** multi-destination or swapping vendors; overkill if you're 100% Sentry.

**AppSignal / Honeybadger.** Commercial APM with dedicated Elixir packages. Pick if you don't want to run Prom+Grafana+Tempo yourself.

**Phoenix LiveDashboard.** Built-in. Mount it everywhere.

---

## 11. Email, notifications, SMS, push

**Swoosh (1.17+) — canonical.** Phoenix generators use it. Adapters for every major provider: SMTP (gen_smtp), SendGrid, Mailgun, Postmark, Mandrill, SES, Resend, Brevo, Mailjet, SparkPost, MailPace. Functional/composable, non-blocking. `phoenix_swoosh` for LiveView-style templates.

**Bamboo (2.x) — legacy-but-maintained.** Thoughtbot handed it to beam-community; it still gets commits but momentum is gone. Don't migrate existing apps off it unnecessarily; don't start new apps on it. No `deliver_later` in Swoosh — wrap `Mailer.deliver/1` in an Oban worker, which is the canonical pattern anyway.

**Transactional provider picks.** Resend for startup DX and price, Postmark for best transactional deliverability, AWS SES at scale (worst DX — SNS gymnastics for bounces/complaints, and **⚠️ no canonical Elixir SES bounce/complaint library** — teams roll their own), SendGrid only if legacy-locked.

**ExTwilio (0.10+).** Still labeled "beta," has been for a decade, works fine. Most non-trivial Twilio usage is cleaner via Req + REST directly.

**Pigeon (2.0.1) — revived.** Push notifications for APNS, FCM v1, ADM. The long RC period is over as of Dec 2024; v2 is production-ready. Dispatcher architecture supports multiple configs.

---

## 12. Storage & file uploads

**Phoenix.LiveView.Upload + ExAws.S3 + Oban — the modern pattern.** LiveView's native upload is chunked, progress-aware, supports external uploaders via presigned URLs (`SimpleS3Upload` example in the docs). Pair with ExAws for presign and an Oban worker for post-processing. **This replaces Waffle entirely for new apps.**

**ExAws + ExAws.S3 (2.5.9+) — alive, new maintainer.** 2022–2023 stagnation concerns are outdated. Primary maintainer is now `bernardd` with Ben Wilson still around; added EKS Pod Identity support in Dec 2025. Still Hackney-by-default — swap to Finch/Req via `ex_aws` http_client config.

**aws-elixir (1.x).** Code-generated from AWS SDK specs, covers far more services than ExAws (including Bedrock). Lower-level API (you pass `%AWS.Client{}` and raw maps). Use when you need a service ExAws doesn't wrap. Ecosystem split with ExAws is unresolved.

**Waffle (1.1.7+).** Arc fork, still maintained but slow. Definition-module API, ImageMagick-centric transformations, heavy `waffle_ecto` coupling. **The momentum has left it.** Only use for legacy compatibility.

**Tigris / R2 / S3.** All S3-compatible via ExAws config. For new projects, **seriously consider R2 or Tigris over S3** — no egress fees (R2) or globally distributed (Tigris), both win on cost and latency.

---

## 13. Image & media processing

**Image (0.63+) — canonical.** Kip Cole's Vix/libvips wrapper. 2–3× faster than Mogrify, ~5× less memory, Bumblebee integration, Evision interop (QR/OpenCV), Blurhash, streaming. **Default choice.**

**Vix (0.38+).** The libvips NIF underneath Image. Use directly for fine-grained control or fewer deps.

**Mogrify (0.9.3).** ⚠️ **Effectively abandoned** — last commit May 2023. ImageMagick CLI wrapper with spawn overhead, ImageMagick-wide CVE exposure, slower, more memory. Don't start new projects on it.

**FFmpex.** The FFmpeg wrapper for video. Stable, no competition. Pair with Oban for async transcoding.

**Evision (0.2.14).** OpenCV bindings via code-gen NIFs, Nx-integrated. Heavy dep — only pull in when you need OpenCV specifically.

---

## 14. Testing

**ExUnit.** Async-by-default, concurrent-sandbox-aware. Unchanged foundation.

**Mox (~> 1.2) vs Mimic (2.3.x).** **Mox** remains the architectural-discipline choice — behaviour-backed, concurrent-safe, contract-first design. **Mimic** has quietly become the pragmatic default in many shops — module-replacement at test time, no behaviour required, Mox-compatible API, now with per-process mode for async. Pick Mox when you control the module and want the discipline; pick Mimic for mocking third-party libs you don't want to wrap.

**PhoenixTest (0.10.x+) — becoming canonical for feature tests.** Germán Velasco's Capybara-inspired unified API across LiveView + dead views + static pages. Pipe-friendly. **Key 2024–2025 architectural move:** PhoenixTest is now a driver protocol — `PhoenixTest.Playwright` implements the same syntax against real browsers (Playwright, no ChromeDriver pain). **For most feature tests, skip Wallaby.**

**Wallaby (0.30.x).** Still the serious E2E browser driver for multi-session work or testing outside LiveView. ChromeDriver flakiness remains. Trend is toward PhoenixTest.Playwright for new suites.

**Hound.** Legacy. Don't start new projects on it.

**StreamData (1.3.x).** Property-based testing with ExUnitProperties macros. **Gap:** no stateful property testing (use PropCheck/PropEr) and no file-based counterexample storage. Original intent to move into Elixir core has been deprioritized.

**ExMachina (2.7.x).** Factories. Moved from thoughtbot to beam-community org. Low velocity, still works. Some teams now prefer plain factory functions in `test/support` since the type system catches struct-field mistakes.

**Faker, Hammox (Mox + typespec enforcement).** Both fine; Hammox's value shrinks as the set-theoretic type system matures.

---

## 15. Code quality & static analysis — and the big type-system shift

**The set-theoretic type system is the headline story.** Valim's CNRS partnership (funded via Fresha + Tidewave) has been landing set-theoretic types into the compiler itself:

- 1.17 (2024): literals + basic types
- 1.18 (Dec 2024): pattern + return inference, plus **stdlib `JSON`** module
- 1.19 (2025): guard inference + **4× faster compile**, Lazy BDDs
- 1.20-rc (Jan 2026): **inference of all constructs**; rc.2 adds cross-clause inference (exhaustiveness, redundant-clause warnings); rc.3 adds cross-dependency inference (Apr–May 2026). Final 1.20 targeted May 2026.
- Next: **typed structs → function signatures → phase out Erlang typespecs**.

**Practically in April 2026:** the compiler now catches most bugs Dialyzer used to catch, with no PLT management, in a fraction of the time. **Greenfield projects are dropping Dialyxir.** Existing projects keep it for `-Wunmatched_returns` and deep BEAM analysis for now, but the retirement trajectory is clear.

**Credo (1.7.x).** Still the linter for readability/design checks. Increasingly paired with an autofix formatter plugin that handles mechanical rules.

**Styler (1.4.x) — canonical formatter plugin.** Adobe's no-config formatter-plus-code-cleaner: module directive ordering, pipe optimization, `Logger.warn` → `warning`, alias lifting, `# styler:sort` magic comment. **Trade-off is deliberate: no per-rule knobs.** Adobe's stance is "this is our internal tool, take it or fork it." Fast becoming the default in `.formatter.exs`.

**Quokka (2.12.x).** SmartRent's fork of Styler that **respects your `.credo.exs` config**, enabling per-rule control, plus extra Credo-rule rewrites. Pick Quokka if you want configurability, Styler if you want the opinionated experience.

**Sobelow (0.14.1).** Phoenix security scanner — XSS, SQLi surface, `Plug.Conn` misuse, secrets leaks, CSRF, insecure `Code.eval_*`. New maintainer (Holden Oullette) restored healthy release cadence in 2025. Required for regulated industries.

**mix_audit + mix hex.audit.** `hex.audit` flags retired packages; `mix_audit` scans CVEs. Both belong in CI.

**Boundary.** Saša Jurić's compile-time architectural boundary enforcement. Featured in Remote's Jan 2025 case study as key to scaling to ~15,000 files. Essential past ~50k LOC or ~10 engineers; overkill before that.

**ex_check.** Meta-runner that invokes format/credo/sobelow/dialyzer/doctor/test/audit in one command. Wire into CI.

**ex_doc (0.40.1).** Canonical, non-negotiable. Now emits `llms.txt` output for AI-assisted codebases.

---

## 16. Frontend integration

**Phoenix 1.8 ships Tailwind v4 + daisyUI** out of the box, configured via CSS (not `tailwind.config.js`). Heroicons are included as a git dep rendered via CSS masks (`<.icon name="hero-..." />`).

**LiveView 1.1 colocated hooks** are the new idiomatic default — `phx-hook=".LocalName"` with a dot prefix auto-namespaces to the module. Extracted at compile time under `_build/$MIX_ENV/phoenix-colocated/`.

**SaladUI (0.14.x) — shadcn-for-LiveView.** Best open-source shadcn-style kit, supports both library-import and `mix salad.install` file-copy modes (true shadcn pattern). **⚠️ Single-maintainer risk** — V1 in progress, tests incomplete. Watch velocity.

**PetalComponents (3.0.2).** 100+ HEEx components, 1.34M downloads, Tailwind v4 compatible. ⚠️ Name-clashes with Phoenix 1.7+ CoreComponents (`modal`, `button`, `input`) require aliasing. Paid Petal Pro adds generators/auth/boilerplate.

**Surface (0.12.x) — legacy-stable.** Last release Feb 2025; LiveView's `Phoenix.Component` + `attr`/`slot` absorbed Surface's core ideas. **Don't start new projects on it.**

**LiveSvelte, LiveReact, LiveVue.** All mature enough to use for JS islands when you have specific needs (complex local state, animation libraries, existing component kit). LiveSvelte is the most polished; LiveReact is late-rc; LiveVue is mature. Vite-based, SSR, E2E reactivity. Default to none of them unless you have a reason.

**LiveView Native (0.4.0-rc.1).** ⚠️ **Still pre-1.0 and not production-ready in April 2026** — same story as 2024. Ongoing work on SwiftUI and Jetpack Compose clients but no stable release and no clear "yes, we ship it" from real deployments. Treat as experimental.

---

## 17. Search

**Snap (0.13.0) — canonical Elasticsearch/OpenSearch client.** DSL-free, Ecto.Repo-style cluster module, Finch-based, streaming bulk ops, versioned index hotswap, namespace-based test sandboxing. Raw ES JSON (no query builder). 37k downloads/month.

**elasticsearch-elixir.** #1 by cumulative downloads but legacy; only for existing codebases.

**Meilisearch — fragmented.** `meilisearch_ex` tracks v1.x API best among the community clients. No official SDK from Meilisearch.

**Typesense — `ex_typesense` (2.0+)** with OpenAPI-generated internals, Ecto schema import.

**Postgres FTS + pg_trgm.** No dedicated library needed. Ecto fragments over `to_tsvector`/`to_tsquery` with GIN indexes + `similarity()` / `%` operator with trigram indexes. For many Phoenix apps, **this replaces ES entirely**. Combine with pgvector for hybrid search via RRF.

**pgvector-elixir (0.3.1) — canonical for vector search.** HNSW/IVFFlat indexes, halfvec/sparsevec/bit types, all distance operators (L2/cosine/inner/L1/hamming/jaccard), Nx tensor interop. **Postgres-native beats running a separate vector DB for most workloads.**

---

## 18. AI & LLMs

Elixir in 2026 is a *credible* full stack for LLM app development — closing the gap with Python for app-level work, still trailing for research/training. The unique wins: one-process-per-session agent concurrency, LiveView-streamed UIs, trivial composition with Phoenix+Postgres+Oban+Broadway, FLAME for burst GPU, and the Tidewave dev loop.

**ReqLLM (1.2.0) — becoming canonical.** Mike Hostetler's Req-plugin abstraction across 45+ providers and 665+ models via the models.dev registry. Vercel-AI-SDK-inspired `generate_text` / `stream_text` / `generate_object`. Canonical structs (Context/Message/ContentPart/Tool/Response/StreamChunk). **LangChain v0.7 adopted ReqLLM as its multi-provider adapter — the two are composing, not competing.**

**LangChain Elixir (0.7.0).** Mark Ericksen's high-level framework — still dominant for chain orchestration, tool calling, retries/fallbacks, token tracking, rate-limit callbacks, message processors, Ash integration. Providers: OpenAI Responses API, Anthropic (incl. WebSocket), Gemini/VertexAI, Bedrock, Ollama, Grok. Monthly releases; very much alive.

**openai_ex (0.9.21).** OpenAI-only, feature-complete (Responses, Assistants, Containers). Pick if OpenAI-only and you need every endpoint; otherwise use ReqLLM.

**Instructor — stalled.** No release in ~14 months. Community forked to **InstructorLite** (leaner, adds Anthropic/Gemini, drops streaming) which is the better default today. **Or** use ReqLLM's `generate_object/4` for provider-native structured output.

**Bumblebee (0.6) + Nx + EXLA + Axon.** Stable, coherent ML stack. EXLA migrated to MLIR (opens Triton-style kernels + IREE/Metal). Polaris split from Axon. **Gaps vs Python remain:** no sharding across devices for huge LLMs (Sean Moriarity flagged this in late 2024; still limited), model-zoo coverage lags Hugging Face Transformers (newest SOTA LLMs often not supported out-of-box). Production-capable for inference and small-to-mid training.

**Ollama.** Most usage is via LangChain's `ChatOllamaAI` or ReqLLM's Ollama provider rather than direct clients.

**MCP (Model Context Protocol).** **Tidewave** (Dashbit/Valim, 0.4+) runs an MCP server *inside* your Phoenix app in dev, exposing runtime state (logs, DB, Ecto queries, PubSub, jobs) to Claude/Cursor/Copilot — an AI pair-programming superpower. **Hermes MCP (0.14.1)** is the full generic MCP SDK (client + server, STDIO/SSE/Streamable HTTP, OTP-supervised) if you're building MCP servers for production.

**Jido — Elixir-native agent framework.** Immutable agent structs, directives (pure state transitions + side effects), CloudEvents-based signals, OTP supervision. Killer argument: **BEAM gives you thousands of supervised agent processes trivially** — something Python/asyncio struggles with. Still emerging vs Python's LangGraph/CrewAI/AutoGen.

---

## 19. Data & analytics

**Explorer (0.11.1) + Livebook + Kino.** Rust Polars via NIF, lazy queries, ADBC for Postgres/SQLite/Snowflake, FSS for S3, Parquet streaming, duration dtype. Livebook's Smart Cells integrate Nx/Bumblebee/Explorer with running clusters. One of Elixir's clearest wins.

**FLAME (0.5.x) — canonical for elastic / GPU burst.** Chris McCord's "treat your app as elastic" library — `FLAME.call` clones the whole app to an ephemeral node, runs a closure, shuts down. Backends for Fly, Kubernetes, local dev. **Dominant pattern** for GPU inference burst, ffmpeg/headless-Chrome/PDF jobs, on-demand ML training. The combination of Livebook + FLAME for driving a 64-GPU BERT run from your laptop (Grainger's ElixirConf 2024 demo) remains one of the strongest Elixir-unique stories — and it inspired direct ports in Rails and Python.

---

## 20. Internationalization

**Gettext.** Baseline for simple string translation. Keep it for UI strings.

**ex_cldr (2.47.0) + family.** Kip Cole's comprehensive CLDR wrapper — 700+ locales, active 2026 releases across the whole family: `ex_cldr_numbers`, `ex_cldr_dates_times`, `ex_cldr_calendars` (Coptic, Persian, Ethiopic, Japanese, composite), `ex_cldr_units`, `ex_cldr_currencies`, `ex_cldr_messages` (ICU MessageFormat — better plurals/gender than Gettext), `ex_money`, `ex_cldr_person_names` (newer). **Use both:** Gettext for translation, Cldr for formatting. ⚠️ **Single-maintainer project** — healthy but bus-factor risk, no competitor exists. Compile times and binary size grow with locale count; configure a subset.

---

## 21. Deployment & DevOps

**Fly.io — still the canonical documented default.** `phx.gen.release --docker` + `fly launch` remains the official tutorial path in Phoenix 1.8 docs. IPv6 private networking makes libcluster trivial. Post-2024 pricing/reliability grumbling exists but no replacement has become canonical.

**Gigalixir.** Alive, true Elixir-aware PaaS (hot upgrades, observer, remote console). Niche; pick when you specifically want Heroku-style git push + Elixir operations.

**Mix.Release.** Canonical artifact. Everything wraps it.

**libcluster.** Canonical node discovery. Kubernetes/DNS/Gossip/EPMD/EC2 strategies. No competitor.

**Horde (0.9.x).** Actively maintained; repo moved to `elixir-horde/`. Tagline now reads "distributed Supervisor and Registry backed by Postgres" — 2025 added a Postgres persistence path alongside the DeltaCRDT one. README now recommends **Highlander/HighlanderPG** for the common singleton case. Still pre-1.0; CRDT eventual consistency matters — read the guide before using it for money.

**SiteEncrypt.** Saša Jurić's embedded Let's Encrypt. Excellent for single-node/small-cluster; doesn't fit stateless K8s pods — use a real proxy there.

**Distillery.** Dead. Mix releases replaced it in Elixir 1.9.

---

## 22. Configuration & secrets

**`config/runtime.exs` — canonical and boring.** No debate. `Application.compile_env/3` for true compile-time values.

**Dotenvy (1.1.x).** Pure runtime.exs helper — typed `env!/2` casting, zero deps. Use inside `runtime.exs` for dev/prod parity. **Nvir** is a newer alternative that also patches `System.get_env` so downstream libs see values.

**Vapor — dead.** Author moved on with "runtime.exs solves most cases." Skip.

**dotenv_elixir (avdi/dotenv).** Legacy, poor release-mode fit. Use Dotenvy.

**vaultex.** HashiCorp Vault client, low velocity. Most teams just read AWS/GCP secret manager in runtime.exs or inject via platform env vars.

---

## 23. Admin & CMS

**Backpex (0.17.x) — the new canonical admin.** LiveView + Tailwind + daisyUI + Alpine. Configuration-driven (not generated), rich field types, filters, metrics, resource actions, multi-tenant. Biweekly releases through March 2026. Ecosystem extensions like `ash_backpex`. ⚠️ **Heavy CSS stack opinion** — daisyUI lock-in. Easily the strongest admin momentum.

**LiveAdmin (0.12.x).** Lighter alternative, no Tailwind/daisy lock-in, slower cadence than Backpex. Fewer features.

**Kaffy.** Once default, now lagging — not LiveView-native, Phoenix 1.7+ / phoenix_html 4 compat has been rough. Don't pick for greenfield.

**AshAdmin.** Obvious choice if you're on Ash. N/A otherwise.

**Beacon CMS (0.5.x) — not yet production-ready for general use.** DockYard-backed, runs DockYard's own 700+ page site, but still 0.x with breaking changes and drag-and-drop editor incomplete. Promising — not safe for bet-the-company launches. For brochureware, still pair Phoenix with a real headless CMS (Sanity/Strapi/Contentful) over HTTP, or hand-roll NimblePublisher for blog content.

---

## 24. Validation & data shaping

**Ecto.Changeset.** Canonical for anything schema-shaped, including schemaless changesets. No contender.

**Peri (0.6.2) — best choice for API-boundary validation.** Zoed Soupe's Plumatic-Schema-inspired lib for raw maps/keyword lists/tuples with nested schemas, conditional types, StreamData generators. Can convert Peri schemas to Ecto changesets. Lighter than Drops, more active than Norm, simpler than OpenApiSpex.

**Drops — Peter Solnica's dry-rb port.** Confirmed: same Solnica as dry-rb/rom-rb/Hanami core, now employed at Sentry on their Elixir SDK. 2025 brought **Drops.Relation** (0.1, July 2025) — automatic Ecto schema inference from DB introspection + composable queries, essentially ROM-for-Elixir. Early/pre-1.0; watch rather than bet.

**TypedStruct.** Still useful but fading — native typed structs are coming to Elixir in the set-theoretic type system milestone sequence. Don't build new long-lived DSLs around it.

**Domo, Norm.** Both largely eclipsed. Skip for new work.

**OpenApiSpex (3.21.4).** Canonical for spec-first APIs; see §7.

---

## 25. CLI & tooling

**Mix.** Built-in, unchanged.

**Burrito (1.3.0).** Single self-extracting binaries (macOS/Linux/Windows) via Zig cross-compilation. Useful but niche — for CLIs, desktop sidecars (Tauri+LiveView), air-gapped deploys. macOS Gatekeeper signing required; cadence has slowed (1.2 Sep 2024 → 1.3 Mar 2025). **Skip for web apps.**

**mix_test_watch (1.3.0) / mix_test_interactive (5.1+).** Either is fine; `mix_test_interactive` adds an interactive mode (toggle stale/failed/traced) — arguably better 2026 DX.

**Owl (0.13).** Colorized output, progress bars, spinners, select/multiselect, masked-secret shell commands, OSC-8 hyperlinks. Not a full TUI — for that, use Ratatouille or just stand up LiveView. For enhancing regular CLI scripts, Owl wins.

**ex_check.** Done software — format/credo/dialyzer/sobelow/deps.audit/hex.audit/doctor in one command.

---

## 26. Security & crypto

**Argon2id is the 2026 default.** Use `argon2_elixir (4.x)` — PHC winner, memory-hard, GPU/ASIC-resistant. Keep `bcrypt_elixir` for existing systems or memory-constrained hosts; switch to `pbkdf2_elixir` only for FIPS-140 compliance. All three share the Comeonin API so swapping is mechanical. Argon2 requires a C toolchain at build time (mildly annoying in Alpine CI).

**Joken (2.6.2).** Still the JWT standard, new maintainer, actively patched. Built on `erlang-jose`. For simple sessions, `Phoenix.Token` (plug_crypto) avoids JWT pitfalls entirely — prefer it when JWT isn't a hard requirement.

**Sobelow (0.14.1), plug_crypto, mix hex.audit, mix_audit.** All covered above; all belong in CI.

---

## 27. State management & business-logic frameworks

**Ash Framework (3.24.x) — the big story of 2024–2026.** Now funded (Zach Daniel employed full-time via Alembic's paid Ash Premium Support), #4 library by usage in the State of Elixir 2025 survey at 24.3% — behind only Phoenix (97.1%), LiveView (85.7%), and Absinthe (26%). Ash 3.0 brought security-by-default (actions no longer accept all public attributes), DSL cleanup, better DX. Active weekly releases.

**Ecosystem:** AshPostgres, AshGraphql, AshJsonApi, AshAuthentication/Phoenix, AshPhoenix, AshPaperTrail (audit), AshArchival (soft delete), AshMoney, AshOban, AshAdmin, AshCloak, AshStateMachine, AshDoubleEntry, AshEvents, **AshAI** (March 2025 — prompt-backed actions, secure LLM tool calling with policy enforcement, MCP server generation, vectorization), and **Reactor** (1.0, saga orchestrator with compensation — "Temporal for Elixir").

**Verdict:** Ash is legitimate and growing, but **not yet the recommended default.** Vanilla Phoenix+Ecto+contexts remains the safer, more hireable path. **Ash wins when:** you need multiple API surfaces (GraphQL + JSON:API + LiveView) from one domain, authorization/policies are complex, you want CRUD+admin shipped fast. **Avoid Ash when:** you dislike heavy DSL/macro magic, your domain doesn't fit a resource-oriented model, team has zero Elixir experience. The Pragmatic Bookshelf *Ash Framework* book (Daniel & Le, Aug 2025) is now the canonical learning resource.

**Commanded (1.4.9) + EventStore (1.4.8).** Alive but slow-moving; 5.5% of Elixir devs use it. Still *the* CQRS/ES choice if you need it. ⚠️ Testing event-sourced systems in Elixir is notoriously awkward (sandbox + in-memory adapter gymnastics). For lighter event-log needs, use **AshPaperTrail** or **AshEvents** rather than full CQRS/ES ceremony.

**Phoenix contexts.** Still the official Phoenix recommendation in 1.8. Contexts are a convention, not a framework — discipline is on you. They leak at large-app scale; that's where Ash or Boundary earn their keep.

---

## 28. Utility libraries worth knowing

**JSON — Elixir stdlib wins for new code.** Elixir 1.18 (Dec 2024) shipped a stdlib `JSON` module on OTP 27's `:json` NIF. **Benchmarks beat Jason.** `@derive {JSON.Encoder, only: [...]}` works identically. **Don't rip Jason out** — most libs still transitively depend on it while they support Elixir <1.18 — just stop adding it as a direct dep in new apps.

**Calendar stdlib wins over Timex.** Since Elixir 1.8, stdlib `Calendar` + `:tzdata` covers tz math, DateTime arithmetic, `Calendar.strftime`, ISO8601. Timex (3.7.13) is maintained but delegates to stdlib where possible — **the maintainer himself recommends auditing whether you need it.** Keep Timex only for `Timex.shift` calendar-aware month/year math, business-day helpers, or legacy. For localized formatting, use `ex_cldr_dates_times`, not Timex.

**Decimal (2.x).** Canonical arbitrary-precision. Ecto-integrated. Use for money.

**ex_money (5.19.2).** Currency-aware Decimal with ISO 4217 + ISO 24165 (crypto). Proper rounding, locale-aware formatting. `ex_money_sql` for atomic Postgres composite serialization. **Default for money handling.**

**nimble_csv (1.3.0) vs csv (3.2.1).** nimble_csv for production throughput (binary-pattern-matched, compiled parsers, `NimbleCSV.Spreadsheet` for Excel BOM/UTF-16); csv for higher-level ergonomics with maps. Senior teams pick nimble_csv.

**NimbleOptions, NimbleParsec.** Use NimbleOptions anywhere you accept `opts` in a public API — cheap wins in docs and error messages. NimbleParsec for structured text formats, DSLs, log parsing (order-of-magnitude faster than runtime combinators).

**Briefly (0.5.1).** Process-linked temp file/dir creation with auto-cleanup. Default choice — stdlib has no equivalent.

---

## 29. Documentation & static sites

**ExDoc (0.40.1).** Canonical. Now emits markdown/llms.txt for AI tooling. Non-negotiable for Hex packages.

**NimblePublisher.** Dashbit's minimal filesystem publishing (markdown + frontmatter → compile-time module attributes). Best for "blog inside my Phoenix app." Pair with `mdex` or `earmark_parser` + `makeup_elixir`.

**Tableau (0.26.1).** Mitchell Hanberg's standalone SSG — HEEx/Temple/Liquid/EEx templates, dev server, RSS/sitemap/SEO. Pick over NimblePublisher when you want a full standalone static site with opinionated defaults.

---

## 30. Feature flags & experimentation

**FunWithFlags (1.13.0) — Elixir-native default.** Redis or Ecto storage, ETS cache, Phoenix.PubSub sync, boolean/actor/group/percentage gates, dashboard included. ⚠️ Toggle-only — no experimentation or rich targeting.

**PostHog Elixir (1.0.1) — now officially maintained by PostHog.** As of Feb 2025, PostHog's core team took over the Elixir SDK. Event capture, boolean + multivariate feature flags, batch, groups, error tracking, Plug integration. **Strongest "flags + analytics + experiments in one tool" option for Elixir in 2026.**

**LaunchDarkly.** Official Erlang SDK (`launchdarkly_server_sdk`), Elixir-compatible. Use if your org already pays.

**Statsig.** Early Beta Elixir SDK (`statsig_elixir 0.14.1`) via Rust NIF. ⚠️ Rust NIFs may not work in all BEAM environments — test carefully.

**GroundControl, ConfigCat, Flagsmith.** All have Elixir clients; pick based on existing vendor.

**⚠️ Gap:** no Elixir-native A/B experimentation engine with proper stats (Eppo/GrowthBook equivalent). Use PostHog or external.

---

## Ecosystem weakspots — where to spend your OSS energy

The Elixir/Phoenix ecosystem is remarkably coherent in 2026. The gaps are narrow and specific — and **both your WIP projects target the most important ones.**

**1. Authentication is the #1 gap.** No Devise/Rodauth/Better-Auth equivalent exists. `phx.gen.auth` generates code (you own it, no library upgrades), Ash Authentication requires Ash adoption, Pow is abandoned. A modern, pluggable, Phoenix-idiomatic library with first-class **passkeys + magic links + OAuth/OIDC + MFA + account linking + admin impersonation + API tokens** behind a clean interface would be the most significant auth addition since Pow's original release. Passkey support in particular is hand-rolled on `wax` today; a polished passkey-first library would be genuinely novel. **Your WIP auth library is filling this.**

**2. Payments is a double gap.** `stripity_stripe` is the only option, volunteer-maintained on HTTPoison/Hackney, with release cadence 2–3× slower than Stripe's language-official SDKs. There is **no Ecto-integrated billing layer at all** — no Laravel-Cashier-for-Phoenix. Every SaaS team reinvents subscription/invoice/webhook-event modeling slightly differently. A Req-based OpenAPI-generated Stripe client (following `aj-foster/open-api-generator`'s pattern) plus a separate Ecto billing layer would set a new standard. **Your WIP is filling both.**

**3. Other notable gaps.** No canonical SES bounce/complaint handler. No Elixir-native A/B experimentation platform with stats. No Strapi-quality CMS (Beacon is still 0.x). Absinthe lacks first-class GraphQL Federation. Cloak encryption-at-rest is stagnant. Nx still lacks model sharding for huge LLMs. `absinthe_graphql_ws` (newer WS transport) hasn't been updated since July 2024. Multi-tenancy libraries (Triplex et al.) are all dormant — use Ecto `prefix:` or Ash. Media-processing leans heavily on a single maintainer (Kip Cole) across Image and the entire ex_cldr family.

**4. Watch these trajectories.** Set-theoretic types (full function signatures coming after 1.20). Phoenix.Sync + ElectricSQL (local-first sync, still 0.3). LiveView Native (0.4-rc, stuck). AshAI + Tidewave (AI-first Phoenix patterns). FLAME as a new category of "elastic BEAM" that's influencing Rails and Python.

## The closing recommendation

Your stack for a new Phoenix 1.8 SaaS in April 2026, picked with minimum regret:

Phoenix 1.8 + LiveView 1.1 + Bandit + Ecto 3.13 + Postgres + Oban (with free Oban Web, plus Pro if throughput warrants) + Req + Swoosh + Sentry + OpenTelemetry + PromEx + Tailwind v4 + daisyUI + Heroicons + Tigris or R2 for storage + Image for media + ExMachina + PhoenixTest + Mimic + Styler + Credo + Sobelow + stdlib JSON + ex_cldr + ex_money + FunWithFlags or PostHog + Backpex for admin + Fly.io for hosting. Drop Dialyxir; let 1.19/1.20 compiler warnings do the work. Auth: use `phx.gen.auth` for now — and if your WIP auth library lands before you need passkeys or account linking, switch to it. Payments: your WIP. That's the map.