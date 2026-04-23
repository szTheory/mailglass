# Phase 3: Transport + Send Pipeline — Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

The Fake adapter (built FIRST per D-13 project-level) is the merge-blocking release gate, and the full hot path — `Mailable → Outbound → preflight (Tenancy.assert_stamped! + Suppression + RateLimiter + Stream.policy_check) → Renderer → Persist(Ecto.Multi with Delivery insert + Event(:queued) + optional Oban.insert) → Worker → Adapter → Multi(Projector update + Event(:dispatched))` — is testable end-to-end against Fake without any real provider. At the close of Phase 3 an adopter writes `defmodule MyApp.UserMailer do; use Mailglass.Mailable, stream: :transactional; def welcome(user), do: new() |> to(user.email) |> subject("Welcome, #{user.name}") |> render(:welcome, %{user: user}); end`, pipes into `MyApp.UserMailer.deliver/1`, and receives `{:ok, %Mailglass.Outbound.Delivery{status: :sent}}` via the Fake adapter — with `Mailglass.TestAssertions.assert_mail_sent(mailable: MyApp.UserMailer)` asserting the send in fewer than 20 lines of test code.

**15 REQ-IDs:** AUTHOR-01 (Mailable behaviour + `use` macro ≤20 lines), TRANS-01..04 (Adapter behaviour + Fake + Swoosh wrapper + Outbound facade), SEND-01..05 (preflight pipeline + RateLimiter + Worker + Suppression.check_before_send + PubSub.Topics), TRACK-01 (off-by-default), TRACK-03 (signed click rewriting with Phoenix.Token rotation), TEST-01 (TestAssertions), TEST-02 (MailerCase + WebhookCase + AdminCase), TEST-05 (Clock injection).

**Out of scope for this phase (lands later):** Webhook plug + HMAC verification + provider-specific verifiers + event normalization (Phase 4 HOOK-01..07); LiveView preview admin (Phase 5 PREV-01..06); the 12 custom Credo checks including LINT-01 `NoRawSwooshSendInLib`, LINT-03 `NoUnscopedTenantQueryInLib`, TRACK-02 `NoTrackingOnAuthStream` AST inspection, LINT-05 `NoOversizedUseInjection` AST counter, LINT-06 `PrefixedPubSubTopics`, LINT-12 `NoDirectDateTimeNow` (all Phase 6); installer (Phase 7 INST-01..04). v0.5 items (List-Unsubscribe + DELIV-01..10, auto-suppression on bounce/complaint, stream-policy enforcement beyond the no-op seam) are further out — Phase 3 ships stable seams, v0.5 fills in behavior.

</domain>

<decisions>
## Implementation Decisions

### Fake adapter + test tooling (TRANS-01..02, TEST-01, TEST-02, TEST-05)

- **D-01:** **Fake storage = supervised GenServer + named public ETS table keyed by owner pid, with `$callers` + allow-list resolution.** Table name `:mailglass_fake_mailbox`. `Mailglass.Adapters.Fake.Storage` GenServer owns ownership mutations (checkout/checkin/allow/shared) + monitors owner pids for auto-cleanup; `:ets.lookup/2` reads happen without a GenServer call. Mirrors Swoosh.Adapters.Sandbox verbatim (already solved for Phoenix request processes, LiveView processes, Oban job processes, Wallaby/PhoenixTest.Playwright browser tests). Records `%Mailglass.Message{}` (NOT raw `%Swoosh.Email{}`) so `assert_mail_sent(mailable: UserMailer)` can recover the originating Mailable. Tenant stamped from `Mailglass.Tenancy.current/0` at record time. **Footgun avoided:** LiveView-rendered signup dispatches email from the LV process (no `$callers` link to the test pid) — allow-list resolution solves it; `$callers`-only does not.
- **D-02:** **`Mailglass.Adapters.Fake.Supervisor` is unconditionally started** in `Mailglass.Application` (child-specced AFTER `Mailglass.Repo`). Owns `Mailglass.Adapters.Fake.Storage` (one init-and-idle GenServer that creates the ETS table in `init/1` then never handles a message). Idle cost ≈ 2KB + one process; adopters routing production through `Mailglass.Adapters.Swoosh` pay nothing the Fake isn't doing. Named `Mailglass.Adapters.Fake.Storage` — documented in `api_stability.md` as library-reserved.
- **D-03:** **Fake simulation API funnels every event through the real write path.** Public functions on `Mailglass.Adapters.Fake`:
  - `@spec deliveries(keyword()) :: [recorded()]` — opts: `:tenant, :mailable, :recipient, :owner`; defaults to current-owner pid.
  - `@spec clear(keyword()) :: :ok` — default: current owner; `:all` clears all owners.
  - `@spec last_delivery(keyword()) :: recorded() | nil`.
  - `@spec trigger_event(message_id :: String.t(), type :: atom(), opts :: keyword()) :: {:ok, %Events.Event{}} | {:error, t()}` — looks up the Delivery by `provider_message_id`, builds an `%Events.Event{}`, runs `Mailglass.Repo.transact(fn -> Events.append_multi/3 + Projector.update_projections/2 end)`. **This is the SAME write path Phase 4 webhook ingest will consume.** `event_type ∈ Mailglass.Outbound.Delivery.__event_types__/0`. Opts: `:occurred_at, :reject_reason, :metadata`.
  - `@spec advance_time(integer() | Duration.t()) :: DateTime.t()` — delegates to `Mailglass.Clock.Frozen.advance/1`.
  - Forcing simulated events through the real Projector means the Fake proves the production write path; `assert_mail_bounced/2` reads the real `mailglass_deliveries` row. One source of truth.
- **D-04:** **Phase 3 extends `Mailglass.Outbound.Projector.update_projections/2` to `Phoenix.PubSub.broadcast` after every successful projection update.** Topic shape `mailglass:events:{tenant_id}` for tenant-wide and `mailglass:events:{tenant_id}:{delivery_id}` for per-delivery (per SEND-05). Payload `{:delivery_updated, delivery_id, event_type, meta}`. Broadcast failure never rolls back (broadcast runs AFTER `Repo.transact/1` commits). Admin LiveView + tests subscribe; `Mailglass.TestAssertions.assert_mail_delivered/2` + `assert_mail_bounced/2` use `assert_receive` against these broadcasts — no polling, no `Process.sleep`.
- **D-05:** **`Mailglass.TestAssertions` ships four matcher styles, mirroring Swoosh plus domain extensions:**
  ```elixir
  assert_mail_sent()                               # any mail
  assert_mail_sent(subject: "Welcome", to: "...")  # keyword match
  assert_mail_sent(%Mailglass.Message{mailable: MyApp.UserMailer})  # struct pattern (macro)
  assert_mail_sent(fn msg -> msg.stream == :transactional end)      # predicate
  last_mail()
  wait_for_mail(timeout \\ 100)                    # assert_receive-backed
  assert_no_mail_sent()
  assert_mail_delivered(msg_or_id, timeout \\ 100) # waits for :delivered PubSub broadcast
  assert_mail_bounced(msg_or_id, timeout \\ 100)   # waits for :bounced PubSub broadcast
  ```
  Macro form uses `defmacro` so users write idiomatic `%{mailable: UserMailer}` without quoting. Single-style matchers (Django's only-positional, ActionMailer's only-keyword) fail to scale — Swoosh already re-derived that lesson.
- **D-06:** **`Mailglass.MailerCase` is `async: true` by default.** `setup/1` block:
  ```elixir
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
  ```
  Ecto sandbox, Fake checkout, tenant stamp, PubSub subscribe, optional Clock freeze — all defaults. Override tenant via `@tag tenant: "..."` or `@tag tenant: :unset`; freeze via `@tag frozen_at: ~U[...]`. `Mailglass.WebhookCase` + `Mailglass.AdminCase` `use Mailglass.MailerCase` and layer Plug/LiveView helpers. The ONLY way to force `async: false` is `setup :set_mailglass_global` (explicit opt-out, mirrors `set_swoosh_global`).
- **D-07:** **`Mailglass.Clock` = runtime-configurable module with three-tier resolution.**
  ```elixir
  defmodule Mailglass.Clock do
    def utc_now do
      case Process.get(:mailglass_clock_frozen_at) do
        nil -> impl().utc_now()
        %DateTime{} = frozen -> frozen
      end
    end
    defp impl, do: Application.get_env(:mailglass, :clock, Mailglass.Clock.System)
  end
  ```
  `Mailglass.Clock.System` = prod (delegates `DateTime.utc_now/0`). `Mailglass.Clock.Frozen` = test helper; `freeze(dt)` + `advance(duration_or_ms)` mutate the process-dict key. Per-process isolation is `async: true`-safe (unlike accrue's single-named GenServer clock that forces `async: false` on billing tests). `Fake.advance_time/1` literally delegates to `Clock.Frozen.advance/1` — one mechanism, not two. Runtime config (NOT `compile_env`) so host apps don't recompile mailglass for tests. Phase 6 `LINT-12 NoDirectDateTimeNow` enforces this as the single legitimate clock source.
- **D-08:** **`Oban.Testing` mode is `:inline` by default in `MailerCase`.** Tests expecting `deliver_later/2` to run synchronously just work. `@tag oban: :manual` opts into the `assert_enqueued`/`perform_job/2` pattern for tests that need enqueue-time inspection. Documented in `MailerCase` moduledoc.

### Mailable + Outbound public API (AUTHOR-01, TRANS-03, TRANS-04, SEND-05)

- **D-09:** **`use Mailglass.Mailable, stream: …, tracking: […], from_default: …, reply_to_default: …` injects exactly 15 lines (≤20 per LINT-05).** Injection:
  ```elixir
  @behaviour Mailglass.Mailable
  @before_compile Mailglass.Mailable
  @mailglass_opts unquote(opts)
  import Swoosh.Email
  import Mailglass.Components
  def new, do: Mailglass.Message.new(__MODULE__, @mailglass_opts)
  def render(msg, tmpl, assigns \\ %{}),
    do: Mailglass.Renderer.render(msg, __MODULE__, tmpl, assigns)
  def deliver(msg, opts \\ []), do: Mailglass.Outbound.deliver(msg, opts)
  def deliver_later(msg, opts \\ []), do: Mailglass.Outbound.deliver_later(msg, opts)
  defoverridable new: 0, render: 3, deliver: 2, deliver_later: 2
  ```
  `@before_compile` hook registers the module for Phase 5 admin discovery without a compile-time global registry or `@on_load`. `defoverridable` preserves cross-cutting-concern wrapping (matches Swoosh.Mailer). Does NOT inject `import Phoenix.Component` — adopters opt in per-mailable to avoid HEEx collision risk. Does NOT inject `preview_props/0` default; optional callback handles it via `@optional_callbacks`. `@mailglass_opts` is the AST-visible bridge Phase 6 Credo (TRACK-02, stream checks) introspects.
- **D-10:** **Adopter convention = Shape (B):** `MyApp.UserMailer.welcome(user) |> MyApp.UserMailer.deliver()`. The injected `deliver/2` is `defdelegate deliver(msg, opts), to: Mailglass.Outbound, as: :send` — satisfies AUTHOR-01's verbatim "calls `Mailglass.Outbound.deliver/2`" because the top-level `Mailglass.deliver/2` is itself a defdelegate to `Outbound.send/2` and `MyApp.UserMailer.deliver/2` resolves to the same target. No separate `MyApp.Mailer` module (Phoenix.Swoosh Shape C) — mailglass config is global via `Mailglass.Config`, not per-mailer; the separation Phoenix.Swoosh needs doesn't apply. `UserMailer` stays the single grep-target for "where do welcome emails come from."
- **D-11:** **Three tiers of declaration by change frequency:**
  - **`use` opts (static, per-module, compile-time visible):** `stream`, `tracking`, `from_default`, `reply_to_default`. Stream is compile-time known (required for LINT AST check); tracking policy is compile-time known (required for TRACK-02 AST check).
  - **Runtime in builder function:** `subject/2`, `to/2`, assigns, per-call `from/2` override — this is where Swoosh's builder lives; don't fight it.
  - **No module attributes (no `@subject`, no `@from`) and no `subject/1` callback.** Module attrs tempt string interpolation that doesn't work; callbacks duplicate what the builder function already does.
- **D-12:** **`preview_props/0` is an optional zero-arity callback on the mailable module itself**, returning `[{atom, map}]` — one entry per preview scenario. Declared via `@optional_callbacks preview_props: 0` in `Mailglass.Mailable`. Phase 5 admin discovers via `@before_compile` registration + `function_exported?/3` probe. Zero-arity because scenarios are enumerable; no separate `UserMailer.Preview` module because physical distance from the mailable drifts over time (ActionMailer's `ApplicationMailerPreview` class is the cautionary tale).
- **D-13:** **`deliver/2` is canonical in public docs, docstrings, and adopter code.** `send/2` is the internal implementation verb in `Mailglass.Outbound`. `defdelegate deliver(msg, opts), to: __MODULE__, as: :send` on the facade. `Mailglass` top-level facade also delegates. Rationale: Swoosh adopters type `deliver`; ActionMailer type `deliver`; every email library in every language uses "deliver" as the public verb. `send` exists internally because it's shorter grep and avoids Kernel.send/2 shadow warning in internal modules.
- **D-14:** **`deliver_later/2` returns `{:ok, %Delivery{status: :queued}}` uniformly.** The Delivery row is inserted synchronously inside the same `Ecto.Multi` that calls `Oban.insert/3`; the Oban job carries the `delivery_id` string. Task.Supervisor fallback does the same synchronous Delivery insert + `Task.Supervisor.async_nolink/3` — same return shape. **Oban leakage (returning `%Oban.Job{}`) is explicitly rejected** because it would break the `mix compile --no-optional-deps --warnings-as-errors` CI lane (the public type signature would mention an optional dep). The Delivery row is the durable handoff point; the Oban job id is a non-durable implementation detail.
- **D-15:** **`deliver_many/2` returns `{:ok, [%Delivery{}]}` always** — one Delivery row per input Message, each carrying its own `:status` (`:queued | :sent | :failed`) and `:last_error :: %Mailglass.Error{} | nil`. No 3-tuple, no tagged `:partial`, no raise. Idempotency-key replay is automatic: each Delivery has a computed `idempotency_key = sha256(tenant_id <> mailable <> recipient <> content_hash)`; on retry of the same batch, successful rows no-op via the partial `UNIQUE` index and are re-fetched via `ON CONFLICT DO NOTHING RETURNING`. **Batch grouping:** one outer `Ecto.Multi` per `deliver_many/2` call, batched Delivery inserts via `Multi.insert_all`, one `Events.append_multi` per insert, one `Oban.insert_all` for the job tails (OSS Oban supports insert_all). Atomicity at the batch level.
- **D-16:** **Bang variants raise the underlying `%Mailglass.Error{}` struct directly** (never wrapped, never a generic string). `deliver!/2` raises the exact `%SendError{} | %SuppressedError{} | %RateLimitError{} | %TemplateError{}`. `deliver_many!/2` raises `%Mailglass.Error.BatchFailed{failures: [%Delivery{}]}` only if any delivery has `status: :failed`. **`deliver_later!/2` does NOT exist** — enqueue isn't a delivery, there's nothing delivery-shaped to raise about. Return-shape uniformity > "matching set" symmetry.
- **D-17:** **Oban-fallback warning fires exactly once at `Mailglass.Application.start/2`**, gated by `:persistent_term.put({:mailglass, :oban_warning_emitted}, true)`. Scan `Application.loaded_applications()`; if `:oban` absent and `config :mailglass, :async_adapter` is not explicitly `:task_supervisor`, emit:
  ```
  [mailglass] Oban not loaded; deliver_later/2 will use Task.Supervisor (non-durable).
  Set config :mailglass, async_adapter: :task_supervisor to silence this warning,
  or add {:oban, "~> 2.19"} to your deps for durable async delivery.
  ```
  No per-call warnings (log-pipeline DoS hazard). Explicit config opt-out is the "I know, I chose this" escape hatch.

### Send pipeline internals (AUTHOR-01 hot path, SEND-01..05, TRACK-01 runtime side)

- **D-18:** **Preflight pipeline = 5 named stages + 1 precondition.** Concrete sequence in `Mailglass.Outbound.send/2`:
  0. `Mailglass.Tenancy.assert_stamped!/0` — precondition; raises `%TenancyError{type: :unstamped}` if caller forgot to stamp.
  1. `Mailglass.Suppression.check_before_send/1` — behaviour call; `{:error, %SuppressedError{}}` short-circuit.
  2. `Mailglass.RateLimiter.check/3` (tenant_id, recipient_domain, stream) — ETS token bucket; `{:error, %RateLimitError{}}` short-circuit.
  3. `Mailglass.Stream.policy_check/1` — no-op seam at v0.1 (D-24).
  4. `Mailglass.Renderer.render/2` — HEEx → Premailex → Floki plaintext; `{:error, %TemplateError{}}` short-circuit.
  5. Persist (Ecto.Multi) — D-20 (sync) or D-21 (async).

  **Rationale for treating Tenancy as precondition, not stage:** `Tenancy.scope/2` is a query-scoping helper consumed inside `Events.append_multi/3` + Projector reads + suppression reads — it's not something the pre-send pipeline calls. What the pipeline needs is an assertion that the tenant stamp exists so `Events.append_multi/3` auto-capture via `Tenancy.current/0` doesn't silently fall back to `"default"` in a real multi-tenant adopter. **SEND-01 REQ-amendment: planner owns** (see Cross-cutting REQ Amendments).
- **D-19:** **Render is LATE (after preflight).** Rationale: suppression (indexed Postgres lookup, <100μs) + rate-limit (ETS, <10μs) checks are cheap; render is ~4ms per Phase 1 bench (40× cost). 99%+ of production sends have valid templates (compile-time HEEx checks catch syntax at BEAM level). Preview flow (Phase 5) catches render errors in dev — prod sends aren't the first line of defense. The <1% suppression hit rate doesn't justify reordering.
- **D-20:** **Sync `send/2` path = TWO Multis separated by the adapter call.**
  ```
  Multi#1 (sync)                           adapter.deliver(message)           Multi#2 (sync)
  ├─ Delivery insert                       (OUTSIDE any transaction)          ├─ Projector.update_projections
  ├─ Events.append_multi :event_queued     → {:ok, %{message_id, ...}}        ├─ Events.append_multi :event_dispatched
  └─ Repo.transact (commit)                → or {:error, _}                    └─ Repo.transact (commit)
  ```
  **Adapter-call-in-transaction is a hard no.** A Postmark/SendGrid POST under Postgres connection-pool pressure at 200/sec will starve the pool inside a minute. Orphan `:queued` Delivery between Multi#1 and Multi#2 after a crash is recoverable state: `Events.Reconciler` (Phase 2 D-19) handles it with orphan-age threshold ≥5min (exceeds Oban max backoff). The unsent message never went out; reconciliation re-dispatches or marks `:failed`. Return to caller: `{:ok, %Delivery{status: :sent}}` after Multi#2 commits; `{:error, e}` from adapter flows into a projection-update Multi with `:failed` status + `last_error` struct.
- **D-21:** **Async `deliver_later/2` path = single `Oban.insert/3`-composed Multi.**
  ```elixir
  Multi.new()
  |> Multi.insert(:delivery, Delivery.changeset(attrs))
  |> Events.append_multi(:event_queued, %{type: :queued, idempotency_key: ik, ...})
  |> Oban.insert(:job, fn %{delivery: d} ->
       Mailglass.Outbound.Worker.new(%{
         "delivery_id" => d.id,
         "mailglass_tenant_id" => Mailglass.Tenancy.current()
       })
     end)
  |> Mailglass.Repo.transact()
  ```
  Oban's `insert/3` explicitly composes inside caller transactions — either everything commits (Delivery + Event + Oban job all visible) or nothing does. No orphan jobs, no orphan deliveries.

  **Worker (`Mailglass.Outbound.Worker`)** runs the adapter call OUTSIDE any transaction, then its own Multi#2 (mirror of sync path) for projection update + `:dispatched` event. `Phase 2 D-33 TenancyMiddleware.wrap_perform/2` restores tenant from `"mailglass_tenant_id"` job args. Oban job retries handle transient adapter failures; Phase 4 reconciler handles orphans.

  **Task.Supervisor fallback explicitly re-stamps via `Mailglass.Tenancy.with_tenant(tenant_id, fn -> Worker.perform_async(...) end)`** for contract parity (process-dict inheritance is fragile across detached tasks under concurrent Tenancy.put_current mutations).
- **D-22:** **RateLimiter ETS ownership = Pattern A (tiny supervisor + init-and-idle `TableOwner` GenServer).**
  ```elixir
  defmodule Mailglass.RateLimiter.Supervisor do
    use Supervisor
    def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    @impl Supervisor
    def init(_opts), do: Supervisor.init([Mailglass.RateLimiter.TableOwner], strategy: :one_for_one)
  end

  defmodule Mailglass.RateLimiter.TableOwner do
    use GenServer
    @table :mailglass_rate_limit
    def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    @impl GenServer
    def init(:ok) do
      :ets.new(@table, [
        :set, :public, :named_table,
        read_concurrency: true, write_concurrency: :auto, decentralized_counters: true
      ])
      {:ok, %{}}
    end
    # no handle_call/cast/info — process exists only to own the table
  end
  ```
  Hot path is pure `:ets.update_counter/4` — no GenServer mailbox serialization. Table survives owner-crash via supervisor restart (counters reset; acceptable — rate-limit state is not load-bearing across crashes). Name `:mailglass_rate_limit` documented in `api_stability.md` as library-reserved.
- **D-23:** **Token bucket = leaky bucket with continuous refill**, evaluated via a single atomic `:ets.update_counter/4` multi-op. Per-key state `{key, tokens, last_refill_ms}`. `RateLimiter.check(_, _, :transactional)` short-circuits to `:ok` BEFORE any ETS touch. Default: `capacity = 100, refill_per_ms = 100/60_000` (100/min); configurable per `(tenant_id, recipient_domain)` via `Mailglass.Config`. Hot-path cost ≈1-3μs on OTP 27 with `decentralized_counters: true`. On over-limit: `{:error, %RateLimitError{retry_after_ms: ceil(1 / refill_per_ms)}}`. Pseudocode body:
  ```elixir
  def check(tenant_id, domain, _stream) do
    key = {tenant_id, domain}
    {capacity, refill_per_ms} = limits_for(tenant_id, domain)
    now_ms = System.monotonic_time(:millisecond)
    :ets.insert_new(@table, {key, capacity, now_ms})
    [{^key, tokens, last}] = :ets.lookup(@table, key)
    refilled = min(capacity, tokens + round((now_ms - last) * refill_per_ms))
    case :ets.update_counter(@table, key,
           [{2, 0, capacity, refilled}, {3, 0, 0, now_ms}, {2, -1, 0, 0}],
           {key, capacity, now_ms}) do
      [_, _, new_tokens] when new_tokens >= 0 -> :ok
      _ -> {:error, %RateLimitError{retry_after_ms: ceil(1 / refill_per_ms)}}
    end
  end
  ```
- **D-24:** **`:transactional` stream bypasses rate limiting unconditionally.** `:operational` + `:bulk` throttle. No configurable stream-allowlist. Documented as a reserved invariant in `api_stability.md`: *"The `:transactional` stream is never throttled by mailglass. If your provider 429s, back off at the provider boundary, not at mailglass's preflight."* A password-reset rate-limited because a marketing campaign saturated the bucket is a security incident (users locked out of recovery); this invariant is load-bearing for D-08.
- **D-25:** **`Mailglass.Stream.policy_check/1` = no-op seam at v0.1.** Returns `:ok` for valid streams (already enforced at schema level via `Ecto.Enum`), emits a single `[:mailglass, :outbound, :stream_policy, :stop]` event. v0.5 DELIV-02 swaps the implementation without touching callers — stream-policy enforcement (transactional=never-tracked, bulk=auto-List-Unsubscribe) lands in v0.5 via the Linkifier module that doesn't exist yet.
- **D-26:** **Telemetry granularity = 1 outer span + 3 inner spans + 2 single-emit events.** Avoids ceremonial `:start`/`:stop` pairs on sub-10μs work; full spans reserved for things that can raise, take ≥1ms, or have interesting latency distributions.
  - `[:mailglass, :outbound, :send, :start | :stop | :exception]` — outer span per `send/2`. `:stop` metadata: `%{tenant_id, mailable, delivery_id, stream, status: :ok | :suppressed | :rate_limited | :render_error | :dispatch_error, latency_ms}`.
  - `[:mailglass, :render, :message, :*]` — full span (Phase 1, extended).
  - `[:mailglass, :persist, :outbound, :multi, :*]` — full span around each Multi commit.
  - `[:mailglass, :outbound, :dispatch, :*]` — full span wrapping adapter call (provider latency is the fat tail).
  - `[:mailglass, :outbound, :suppression, :stop]` — single emit `%{hit: boolean, duration_us: integer}`.
  - `[:mailglass, :outbound, :rate_limit, :stop]` — single emit `%{allowed: boolean, duration_us: integer}`.

  All metadata whitelisted per Phase 1 D-31; Phase 6 LINT-02 `NoPiiInTelemetryMeta` enforces.
- **D-27:** **`Mailglass.PubSub.Topics` typed builder (SEND-05).** Functions: `events(tenant_id)`, `events(tenant_id, delivery_id)`, `deliveries(tenant_id)`. All return binaries prefixed `mailglass:` (Phase 6 LINT-06 `PrefixedPubSubTopics` enforces). Projector broadcasts on both `events(tenant_id)` and `events(tenant_id, delivery_id)` after each projection update — admin + per-delivery LiveView views subscribe separately.
- **D-28:** **`Mailglass.SuppressionStore.ETS` ships in Phase 3** (flagged as Phase 3 candidate in Phase 2 D-decisions). In-memory behaviour impl for test speed + a narrow production use case (single-node, read-heavy, sub-100-entry suppression lists where the Ecto round-trip is felt). The Ecto impl from Phase 2 remains the default; ETS is a `MailerCase`-level override via `config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS`. Same behaviour surface (`check/2`, `record/2`).
- **D-29:** **`Mailglass.Adapters.Swoosh` wraps any `Swoosh.Adapter` (TRANS-03).** Returns `{:ok, %{message_id: String.t(), provider_response: term()}}` on success. Error mapping: `{:error, {:api_error, status, body}}` → `%SendError{type: :adapter_failure, cause: %Swoosh.DeliveryError{...}, context: %{provider_status: status, provider_module: m}}`. Provider mapping table per Postmark/SendGrid for common error shapes (v0.5 extends to Mailgun/SES/Resend). Keeps adopter's Swoosh adapter config intact; adds normalized error mapping + `[:mailglass, :outbound, :dispatch, :*]` telemetry wrapping.

### Tracking opt-in + click rewriting (TRACK-01, TRACK-03)

- **D-30:** **Per-mailable tracking = compile-time `use` opt only.** `use Mailglass.Mailable, tracking: [opens: true, clicks: true]`. Shape (A) canonical. AST-inspectable by Phase 6 `TRACK-02 NoTrackingOnAuthStream` Credo check (receives the `use` AST node directly via `Credo.Code.prewalk/2`). **No per-call tracking opt**, **no runtime `Message.put_tracking/2`**, **no hybrid compile+runtime override**. Adopters can DISABLE tracking at runtime (via per-call opt `tracking: false`), never ENABLE. One policy per mailable module.
- **D-31:** **`opens` and `clicks` are independent booleans.** `tracking: [opens: boolean, clicks: boolean]`, both default `false`. Validated via NimbleOptions. No `:full | :opens_only | :off` sugar — Apple Mail Privacy Protection neuters opens but not clicks, so `opens: false, clicks: true` is a real configuration adopters will want once they understand the ecosystem. v0.5's List-Unsubscribe click counting (DELIV-01/03) is a SEPARATE `unsubscribe_tracking:` key, not folded into this one.
- **D-32:** **Tracking host is globally required when any mailable opts in.** Config shape:
  ```elixir
  config :mailglass, :tracking,
    host: "track.example.com",
    scheme: "https",
    salts: ["2026-q2", "2026-q1"],  # head = signer, all verify
    max_age: 63_072_000               # 2 years
  ```
  NimbleOptions `required: true` (conditional on at least one mailable having `tracking: [opens: true]` OR `tracking: [clicks: true]`). Validated in `Mailglass.Application.start/2`; boot fails with `%Mailglass.ConfigError{type: :missing, context: %{key: :tracking_host}}` on omission. No `Logger.warning` + default-to-main-host fallback — cookie isolation is load-bearing (the tracking endpoint is an untrusted-origin surface; do not serve authenticated UI from it — documented in brand). Multi-tenant: `Mailglass.Tenancy` behaviour gets optional `c:tracking_host/1` callback returning `{:ok, host} | :default`; per-tenant subdomain (`track.tenant-a.example.com`) supported; wildcard TLS is the adopter's problem, documented.
- **D-33:** **Phoenix.Token rotation via salts list.** Head of `:salts` signs; all salts verify (`Phoenix.Token.verify/4` iterated with early return on match). `key_iterations: 1000, key_length: 32, digest: :sha256` (Phoenix.Token defaults, explicit). `max_age: 2 * 365 * 86_400` (2 years, archived-email pixel loads still work without unbounded token lifetime). Separate from `secret_key_base` derivation so rotating one doesn't invalidate the other.
- **D-34:** **Open pixel URL shape:** `GET https://track.example.com/o/<token>.gif`. Token = `Phoenix.Token.sign(endpoint, hd(salts), {:open, delivery_id, tenant_id})`. Response: 43-byte transparent GIF89a, `Content-Type: image/gif`, `Cache-Control: no-store, private, max-age=0`, `Pragma: no-cache`, `X-Robots-Tag: noindex`, `put_secure_browser_headers`. `.gif` suffix placates Gmail's image proxy heuristics.
- **D-35:** **Click URL shape — pattern (a), full URL encoded inside signed token.** `GET https://track.example.com/c/<token>`, token = `Phoenix.Token.sign(endpoint, hd(salts), {:click, delivery_id, tenant_id, target_url})`. Server verifies, 302 redirects. **No `?r=` query parameter exists → open-redirect is structurally impossible, not merely mitigated.** Token size ≈200 bytes per link acceptable (Gmail 102KB clipping threshold; a heavy newsletter with 10 tracked links adds ~2KB). `target_url` validated at SIGN time: `URI.parse` scheme ∈ `["http", "https"]`; rejection surfaces as `%Mailglass.ConfigError{type: :invalid, context: %{rejected_url, reason: :scheme}}` during `deliver/2`, not only at verify time. Deduplicate GET clicks within 2s per `(delivery_id, user_agent_hash)` so Outlook SafeLinks pre-fetch doesn't double-count.
- **D-36:** **Link-rewriting scope.** Rewrite only `<a href="http(s)://...">` in the HTML body. Skip list:
  - `mailto:`, `tel:`, `sms:`, `#fragment`, `data:`, `javascript:`, scheme-less relative URLs
  - Any `<a data-mg-notrack>` or `<a data-mg-notrack="true">` (attribute stripped from final HTML wire)
  - Any href whose normalized form equals the List-Unsubscribe URL (v0.5 hook reserved)
  - Any `<a>` inside `<head>` (prefetch, canonical)

  Implementation: dedicated `Mailglass.Tracking.Rewriter` module, invoked AFTER `Mailglass.Renderer` (CSS-inlined HTML in → rewritten HTML out). **Plaintext body NEVER rewritten** — plaintext readers often go through text-only proxies; leaving original URLs serves user trust.
- **D-37:** **Open pixel injection = last child of `<body>`, auto-injected by Rewriter.** Markup: `<img src="..." width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0;" />`. `alt=""` avoids screen-reader announcement; `display:block` avoids inline-whitespace glitches. Never adopter-visible in template. Does NOT respect `<.preheader>` (preheader is above-the-fold semantic; pixel is end-of-body by convention). Floki-based insertion handles missing `<body>` by appending at root.
- **D-38:** **Runtime behavior when TRACK-02 auth-stream heuristic is bypassed = RAISE.** `Mailglass.Outbound.send/2` runtime guard: if the mailable's compile-time `@mailglass_opts` has `tracking: [opens: true]` OR `tracking: [clicks: true]` AND the calling function name (recovered from `Message.mailable_function`) matches the `magic_link|password_reset|verify_email|confirm_account` regex, raise `%Mailglass.ConfigError{type: :tracking_on_auth_stream, context: %{mailable: mod, function: fun_name}}`. **Dual enforcement:** Phase 6 Credo catches most cases at compile time; Phase 3 runtime guard catches the dynamic-function-name bypass (e.g., metaprogrammed mailables). D-08 is normative, not advisory. Adopters cannot turn this off — the "acknowledged" escape hatch is deliberately not provided.
- **D-39:** **`tenant_id` lives ONLY in the signed token payload, NEVER in the URL path or query.** Tracking endpoint decodes token → `Mailglass.Tenancy.put_current(tenant_id)` for the request → writes to `mailglass_events` scoped. Failed verification: HTTP 204 on pixel / HTTP 404 on click — never echo what was attempted (no enumeration). URL path + query leak to referrer headers, shared-link screenshots, Outlook SafeLinks pre-fetch logs, corporate proxies — signed payload is the only privacy-preserving option.

### Claude's Discretion

- Exact `Mailglass.Mailable` moduledoc wording (adopter-facing primary reference).
- Exact `Mailglass.Outbound.Delivery.new/1` helper signature for `deliver_many/2` batch-input construction.
- Exact telemetry measurement structure for the single-emit events (`:duration_us` vs `:measurements.duration`) — follow Phase 1 precedent.
- Exact error-mapping table in `Mailglass.Adapters.Swoosh` for Postmark + SendGrid error shapes (v0.1 covers the documented error vocabulary; v0.5 extends).
- Tracking endpoint's Plug pipeline composition (CachingBodyReader NOT needed — pixel/click endpoints don't need raw body preservation; that's Phase 4 territory).
- Fake adapter JSON-compatibility format (JSON.encode! on the `deliveries/1` output — structural, not ceremonial).
- `Mailglass.PubSub` supervision: Phase 3 adds a `{Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2}` child to `Mailglass.Application` (after `Mailglass.Repo`, before `Mailglass.Adapters.Fake.Supervisor`).
- `Mailglass.Outbound.Worker` Oban-queue name (`:mailglass_outbound`), max_attempts (20), unique constraint (per `delivery_id`).
- Exact `MailerCase` `@tag` vocabulary (`:tenant`, `:frozen_at`, `:oban`) — extend incrementally as tests need.

### Folded Todos

None — no pending todos matched Phase 3.

</decisions>

<spec_lock>
## Cross-cutting: REQ Amendments (planner owns)

- **SEND-01 rephrasing.** Current REQUIREMENTS.md text reads `Tenancy.scope → Suppression.check_before_send → RateLimiter.check → Stream.policy_check → render → Multi(...)`. Amend to: `Tenancy.assert_stamped! → Suppression.check_before_send → RateLimiter.check → Stream.policy_check → Renderer.render → Persist(Ecto.Multi)`. **Why:** `Tenancy.scope/2` is a query-scoping helper consumed inside `Events.append_multi/3` + Projector reads + SuppressionStore reads — it's not a pipeline stage. The actual pre-send tenancy concern is asserting the process-dict stamp exists so `Events.append_multi/3` auto-capture via `Tenancy.current/0` doesn't silently fall back to `"default"` under a real multi-tenant resolver. Mirrors the Phase 2 PERSIST-05 amendment pattern (D-02 of Phase 2 CONTEXT).
- **TRANS-04 clarification.** `send/2` is the internal implementation verb in `Mailglass.Outbound`; `deliver/2` is a `defdelegate ..., as: :send` alias. Public docs + docstrings use `deliver/2` exclusively; `send/2` exists for internal grep and to avoid the `Kernel.send/2` shadow warning in stack traces.

</spec_lock>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project locked context

- `.planning/PROJECT.md` — Key Decisions D-01..D-20 (project-level, locked). Most load-bearing for Phase 3: **D-07** (Oban optional, Task.Supervisor fallback, boot warning), **D-08** (tracking off by default, never on auth-carrying mailables), **D-09** (multi-tenancy first-class — informs RateLimiter key shape, Fake tenancy scoping, tracking-token payload), **D-13** (Fake adapter as merge-blocking release gate, built FIRST — shapes Phase 3 plan ordering), **D-14** (Anymail event taxonomy verbatim — already in Delivery.last_event_type enum), **D-17** (custom Credo enforces domain rules — forward-ref Phase 6 for LINT-01/TRACK-02/LINT-05/LINT-06/LINT-12), **D-20** (domain vocabulary: Mailable / Message / Delivery / Event as irreducible nouns).
- `.planning/REQUIREMENTS.md` — §Authoring AUTHOR-01, §Transport TRANS-01..04, §Send Pipeline SEND-01..05, §Tracking & Privacy TRACK-01 + TRACK-03 (TRACK-02 is Phase 6), §Test Tooling TEST-01 + TEST-02 + TEST-05 (TEST-03/04 are Phase 4/7). **SEND-01 amendment (Tenancy.scope → Tenancy.assert_stamped!) is cross-cutting** — see spec_lock above.
- `.planning/ROADMAP.md` — Phase 3 success criteria (5 checks); depends on Phases 1 + 2; pitfalls guarded against: LIB-01 (≤20-line use macro), LIB-03 (return-type stability), LIB-04 (tuple returns for adapters), LIB-05 (no `name: __MODULE__` singletons — RateLimiter is small supervisor child owning ETS), LIB-06 (renderer + Swoosh bridge pure), MAIL-01 (tracking off by default + D-38 runtime guard), TEST-01 (Fake first, Mox not used for transport), TEST-06 (Mailglass.Clock injection point).
- `.planning/STATE.md` — current position; Phase 2 complete 2026-04-22; Phase 3 ready to plan.

### Phase 1 + Phase 2 artifacts Phase 3 consumes

- `.planning/phases/01-foundation/01-CONTEXT.md` — Phase 1 D-01..D-33. Most load-bearing for Phase 3: D-01..D-09 (Error struct shapes — `%SendError{}`, `%TemplateError{}`, `%SuppressedError{}`, `%RateLimitError{}` all used by the preflight pipeline; pattern-match by struct, never message string), D-26..D-32 (Telemetry surface — Phase 3 adds `send_span/dispatch_span/batch_span/suppression-emit/rate_limit-emit` per D-26 above, all metadata whitelisted per Phase 1 D-31), D-33 (property-test shape — Phase 3 extends to include `tenant_id` assertions across generated sends).
- `.planning/phases/02-persistence-tenancy/02-CONTEXT.md` — Phase 2 D-01..D-43. Most load-bearing for Phase 3: **D-01/D-02** (`Events.append/1` + `append_multi/3` are the canonical writers consumed by both sync-path Multis and async-worker Multi#2), **D-05** (auto-capture of `tenant_id` via `Tenancy.current/0` — Phase 3 adds `Tenancy.assert_stamped!/0` precondition to prevent silent `"default"` fallback), **D-13..D-18** (Delivery 8 projection columns + `lock_version` + `Projector.update_projections/2` as single writer — Phase 3 adds PubSub broadcast extension per D-04), **D-29..D-34** (Tenancy behaviour + `SingleTenant` default + process-dict helpers + `Oban.TenancyMiddleware` — Phase 3 Worker uses the middleware), **D-40** (`tenant_id :: String.t()` — confirms Fake, RateLimiter key, and tracking-token payload all match the same type).
- `docs/api_stability.md` — locks SuppressedError/SendError/RateLimitError/TemplateError `:type` atom sets (Phase 1) + Tenancy behaviour surface + Telemetry event catalog (Phases 1+2). **Phase 3 extends with:** §Adapter return shape (TRANS-01 locked here — planner owns the edit), §Outbound facade signatures (`send/2`, `deliver/2`, `deliver_later/2`, `deliver_many/2`, `deliver!/2`, `deliver_many!/2`), §Mailable `__using__` injection budget (LINT-05 forward-ref), §RateLimiter check contract + reserved ETS table name, §PubSub topic format + reserved prefix, §Clock + Config additions.
- `lib/mailglass/message.ex` — `Message.new/2` + `Message.tenant_id :: String.t() | nil` — Phase 3 `use Mailglass.Mailable` `new/0` seeds this struct with `@mailglass_opts` defaults.
- `lib/mailglass/outbound/delivery.ex` — Delivery schema (Phase 2, frozen). Phase 3 inserts via Multi#1; Phase 3 Projector extension broadcasts after updates.
- `lib/mailglass/outbound/projector.ex` — `update_projections/2` (Phase 2, frozen behaviour — Phase 3 extends only the broadcast-after-commit side effect). Single writer for projection columns; consumed by sync path Multi#2, async-worker Multi#2, webhook ingest (Phase 4), Fake's `trigger_event/3`.
- `lib/mailglass/events.ex` — `append/1` + `append_multi/3` (Phase 2, frozen). Consumed by every Phase 3 write path.
- `lib/mailglass/suppression_store.ex` — Phase 2 behaviour; Phase 3 adds `Mailglass.SuppressionStore.ETS` impl per D-28.
- `lib/mailglass/tenancy.ex` — Phase 2 surface. **Phase 3 adds `Tenancy.assert_stamped!/0` + optional `c:tracking_host/1` callback** per D-18 + D-32.
- `lib/mailglass/optional_deps/oban.ex` — `Mailglass.Oban.TenancyMiddleware` (Phase 2, frozen). Phase 3 `Mailglass.Outbound.Worker` uses it.
- `lib/mailglass/errors/*` — 7 Phase-1 + Phase-2 error structs. **Phase 3 extends `%Mailglass.ConfigError{}` `:type` atom set** with `:tracking_on_auth_stream` + `:tracking_host_missing` (two new atoms; see D-32 + D-38).
- `lib/mailglass/repo.ex` — `Mailglass.Repo.transact/1` with SQLSTATE 45A01 translation (Phase 2, frozen). Every Phase 3 Multi flows through it.
- `lib/mailglass/renderer.ex` — `Mailglass.Renderer.render/2` (Phase 1, frozen). Called by preflight stage 4 per D-18.
- `lib/mailglass/telemetry.ex` — 4-level convention + `render_span/2` (Phase 1). Phase 3 adds `send_span/3` + `dispatch_span/3` + `persist_span/3` (per Phase 1 D-27 naming).
- `lib/mailglass/config.ex` — NimbleOptions schema extends with `:tracking` (host + scheme + salts + max_age), `:rate_limit` (defaults + per-domain overrides), `:async_adapter` (`:oban | :task_supervisor`), `:suppression_store` (behaviour module — already in Phase 2 schema, Phase 3 adds `.ETS` impl).

### Research synthesis

- `.planning/research/SUMMARY.md` §Executive Summary (ETS-only rate limiter recommended v0.1; Fake adapter merge-blocking gate), §Key Findings (Layer 3 + 4 build order), §"Phase 3: Transport + Send Pipeline" (expands on the working-core milestone), §Research Flags table Q2 (Tenancy auto-detect — NOT adopted, per Phase 2 D-32), Q7 (rate limiter ETS-only — adopted per D-22).
- `.planning/research/ARCHITECTURE.md` §1.1 (module catalog — `Mailglass.Outbound.Worker` + Adapter placements), **§2.1 (hot-path data flow — the canonical sequence diagram; Phase 3 D-18 + D-20 + D-21 implement this directly)**, §2.3 (failure modes — `lock_version` + optimistic_lock for dispatch race), **§3.3 (the one GenServer — RateLimiter ETS ownership pattern D-22 implements)**, §5 (behaviour boundaries — `Mailglass.Adapter` is the Phase 3 seam), §6 Layer 3 + 4 (build order), §7 (boundary blocks — `Mailglass.Outbound` + `Mailglass.Adapter(s)` + `Mailglass.RateLimiter` + `Mailglass.Mailable` sub-boundaries land this phase).
- `.planning/research/PITFALLS.md` — LIB-01 (oversized `use` — D-09 15-line budget), LIB-03 (return-type stability — D-14 + D-15 uniform `%Delivery{}`), LIB-04 (tuple returns for adapters — TRANS-01 already locks), LIB-05 (no singleton GenServers — D-22 supervisor-owned ETS pattern), LIB-06 (renderer + Swoosh bridge pure — Phase 1 CORE-07 enforced), MAIL-01 (tracking off by default — D-30 + D-38 dual enforcement), TEST-01 (Fake first — D-01..D-03 build it as the release gate), TEST-06 (Clock injection — D-07 Clock module).
- `.planning/research/STACK.md` §Required Deps + §Optional Deps — confirms Swoosh 1.25+ + Phoenix.PubSub as required; Oban 2.19+ as optional. No new deps for Phase 3 (Phoenix.Token is in Plug Crypto, already transitively via Phoenix).
- `.planning/research/FEATURES.md` — TS-01 (Mailable behaviour deliver/2/deliver_later/2/deliver_many/2), TS-05 (Adapter behaviour + Fake + Swoosh wrapper), TS-10 (telemetry 4-level), TS-14 (TestAssertions), TS-15 (tracking off by default), DF-09 (NoRawSwooshSendInLib forward-ref Phase 6), DF-11 (stateful time-advanceable Fake).

### Engineering DNA + domain language

- `prompts/mailglass-engineering-dna-from-prior-libs.md` §2.4 (Errors as public API contract — informs every error-struct return), §2.5 (Telemetry 4-level convention — D-26 implements), §2.7 (test pyramid — Fake is the release gate; real-provider sandbox advisory only), §2.8 (custom Credo at lint time — Phase 6 forward-ref), §3.5 (Fake-first pattern, canonical reference: `~/projects/accrue/accrue/lib/accrue/processor/fake.ex`).
- `prompts/mailer-domain-language-deep-research.md` §13 (canonical vocabulary — Mailable / Message / Delivery / Adapter are irreducible nouns; Phase 3 uses these names verbatim), §16 (status as projection, not authoritative state — informs the "two-Multi with orphan reconciliation" pattern in D-20).
- `prompts/Phoenix needs an email framework not another mailer.md` — founding thesis; Phase 3 is the milestone that proves the thesis ("we have a working core").

### Brand + ecosystem

- `prompts/mailglass-brand-book.md` — voice ("clear, exact, confident not cocky, warm not cute"). Phase 3 error messages follow: "Delivery blocked: recipient is on the suppression list", "Rate limit exceeded: retry after 250ms", "Tracking misconfigured: tracking host missing but `tracking: [opens: true]` declared on `MyApp.MarketingMailer`". Never "Oops!".
- `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — informs Oban 2.19+ (stable insert/3 Multi composition), Phoenix.Token + Plug.Crypto idioms, Swoosh 1.25 `:api_client` flag (adopter-configured per Phase 1 D-25-adjacent decision).

### Best-practice references

- `prompts/elixir-best-practices-deep-research.md` — `use` macro conventions, `defoverridable` idioms (informs D-09 mailable injection shape), ETS hot-path math patterns (`:ets.update_counter/4`, `decentralized_counters: true`).
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §3 (process architecture — confirms "one-GenServer-owning-ETS is idiomatic"), §4 (ETS concurrency — `write_concurrency: :auto` + `decentralized_counters: true` is the OTP 27 sweet spot).
- `prompts/phoenix-best-practices-deep-research.md` — `Phoenix.Token` rotation via salts list (D-33 pattern), endpoint config access patterns.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — `Phoenix.Component.__using__/1` pattern informs D-09 injection (but Phase 3 does NOT inject `import Phoenix.Component` — adopters opt in per mailable).
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` §API surface stability — `api_stability.md` extension for Phase 3 (Adapter return shape, Outbound facade signatures, Mailable injection budget).

### Reference implementations (sibling-constraint + prior-art)

- **Swoosh.Adapters.Sandbox** (`deps/swoosh/lib/swoosh/adapters/sandbox.ex`, or hex.pm/packages/swoosh) — **D-01 mirrors this pattern verbatim.** Ownership-by-pid + `$callers` + allow-list is already battle-tested for Phoenix + LiveView + Oban job processes. The Fake inherits documentation + integration guarantees.
- **Swoosh.Adapters.Test** (`deps/swoosh/lib/swoosh/adapters/test.ex`) — simpler pattern (`Process.group_leader()` + `send(pid, {:email, _})`); rejected for mailglass because it breaks for LiveView and Oban worker processes.
- **Swoosh.TestAssertions** (`deps/swoosh/lib/swoosh/test_assertions.ex`) — D-05 matcher styles mirror this.
- **Oban.insert/3** (`deps/oban/lib/oban.ex:606`) — **D-21 composes around this.** Returns `{:ok, %Job{}}` when called outside Multi; composes as a Multi step when given a builder function. The primitive Phase 3 async path depends on.
- **Oban.Testing** (`deps/oban/lib/oban/testing.ex`) — D-08 `:inline` default follows the convention.
- **`~/projects/accrue/accrue/lib/accrue/processor/fake.ex`** — Fake-first pattern reference (but mailglass diverges on storage primitive — accrue uses a single GenServer with struct state; mailglass uses Swoosh.Sandbox-style ETS+ownership for `async: true` at scale).
- **`~/projects/accrue/accrue/lib/accrue/billable.ex`** — `__using__` + `@before_compile` pattern (15-line injection budget). D-09 borrows this shape.
- **`~/projects/accrue/accrue/lib/accrue/mailer.ex`** — behaviour-as-facade (mailglass diverges to Message-centric rather than type+assigns, per domain-language D-20 project-level).
- **`~/projects/accrue/accrue/lib/accrue/test/mailer_assertions.ex`** — receive-based, process-local, `async: true`-safe. Directly portable into `Mailglass.TestAssertions`.
- **`~/projects/accrue/accrue/lib/accrue/workers/mailer.ex`** — prior-art Oban worker with `unique:` dedup. D-21 Worker shape follows.
- **`~/projects/accrue/accrue/lib/accrue/oban/middleware.ex`** — prior-art `operation_id`-via-process-dict pattern. Phase 2 `TenancyMiddleware` already mirrors; Phase 3 just consumes.

### External standards + prior art

- **Phoenix.Token / Plug.Crypto.MessageVerifier** — D-33 + D-34 + D-35 token shape; documented in Phoenix hex docs.
- **RFC 8058 (List-Unsubscribe-Post)** — v0.5 DELIV-01 forward-ref; D-36 reserves the skip-rule for when it lands.
- **Anymail event taxonomy** — https://anymail.dev/en/stable/sending/tracking/ — verbatim in Phase 2 Delivery enum; Phase 3 consumes.
- **Mailchimp open-redirect CVEs (2019, 2022)** — cautionary tale informing D-35 pattern (a) choice (no `?r=` param → structurally impossible to open-redirect).
- **SendGrid ECDSA signing** — forward-ref Phase 4 HOOK-04; not Phase 3.
- **Apple Mail Privacy Protection (iOS 15+)** — informs D-31 (independent opens/clicks booleans); documented in Mailable moduledoc so adopters understand opens-metric noise.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (shipped through Phase 2)

- **`Mailglass.Message`** (`lib/mailglass/message.ex`) — struct wrapping `%Swoosh.Email{}`; `tenant_id`, `stream`, `mailable` fields already present. Phase 3 `use Mailglass.Mailable` `new/0` seeds this with `@mailglass_opts` defaults.
- **`Mailglass.Outbound.Delivery`** (`lib/mailglass/outbound/delivery.ex`) — 8 projection columns + `lock_version` + full event-type enum (`:queued | :sent | ... | :dispatched | :suppressed`) already in place. Phase 3 inserts rows; no schema changes.
- **`Mailglass.Outbound.Projector.update_projections/2`** (`lib/mailglass/outbound/projector.ex`) — single writer for projection columns. Phase 3 extends only with `Phoenix.PubSub.broadcast` after successful commit (per D-04). Behaviour contract unchanged.
- **`Mailglass.Events.append/1` + `append_multi/3`** (`lib/mailglass/events.ex`) — canonical event writer. Phase 3 consumes in every write path.
- **`Mailglass.Repo.transact/1`** (`lib/mailglass/repo.ex`) — with SQLSTATE 45A01 translation active. Every Phase 3 Multi flows through it; on adopter `mailglass_events` update/delete attempts, `%EventLedgerImmutableError{}` raises.
- **`Mailglass.Tenancy`** + `Mailglass.Tenancy.SingleTenant` + `Mailglass.Oban.TenancyMiddleware` — Phase 3 adds `Tenancy.assert_stamped!/0` (D-18) + optional `c:tracking_host/1` callback (D-32). Worker uses the existing middleware.
- **`Mailglass.SuppressionStore`** behaviour + `.Ecto` default — Phase 3 adds `.ETS` impl for test speed + narrow production use (D-28). Phase 3 wires `SuppressionStore.check/2` into `Mailglass.Suppression.check_before_send/1` (public preflight helper).
- **`Mailglass.Renderer.render/2`** — pure pipeline, called by preflight stage 4 (D-18).
- **`Mailglass.Error` hierarchy** — 7 struct modules. Phase 3 extends `%Mailglass.ConfigError{}` `:type` with `:tracking_on_auth_stream` + `:tracking_host_missing`; uses `%SendError{}`, `%SuppressedError{}`, `%RateLimitError{}`, `%TemplateError{}` from the pipeline per struct.
- **`Mailglass.Telemetry`** — adds `send_span/3`, `dispatch_span/3`, `persist_span/3` per the Phase 1 D-27 naming convention. Existing metadata whitelist (D-31) covers every new event without extension.
- **`Mailglass.Config`** — NimbleOptions schema extends (no new pattern; additive).
- **`Mailglass.OptionalDeps.Oban`** gateway — `Mailglass.Outbound.Worker` is a new module conditionally compiled behind `Code.ensure_loaded?(Oban)` (matches existing pattern for `TenancyMiddleware`).

### Established Patterns (from Phases 1 + 2)

- **Closed atom sets with `__types__/0` + `api_stability.md` cross-check test** — Phase 3 extends `ConfigError.__types__/0` per D-38.
- **`defexception` + `@behaviour Mailglass.Error` + `new/1` formatter + `Jason.Encoder` on `[:type, :message, :context]`** — Phase 3 follows for any new struct (no new structs needed; existing cover the pipeline).
- **Behaviour + default impl + Config selector** — `Mailglass.Adapter` behaviour + `Mailglass.Adapters.Fake` + `Mailglass.Adapters.Swoosh` matches the existing `Mailglass.SuppressionStore` + `.Ecto` + `.ETS` pattern. `Mailglass.TemplateEngine` + HEEx default is the Phase 1 precedent.
- **Supervisor child owning ETS with init-and-idle GenServer** — D-22 RateLimiter shape follows. No prior mailglass module uses this pattern yet (Phase 2 Oban middleware does not own ETS), but it's idiomatic OTP.
- **Telemetry span helpers co-located per domain** — `Mailglass.Outbound.send_span/3` lives in `lib/mailglass/outbound.ex`; matches Phase 1 D-27 where `render_span/2` lives in `lib/mailglass/renderer.ex`.
- **Oban optional gateway + Task.Supervisor fallback with boot warning** — D-07 project-level; Phase 3 operationalizes via D-17 (single warning at `Application.start/2` gated by `:persistent_term`).
- **Boundary blocks** — Phase 1 root + Phase 2 `Mailglass.Events` + `Mailglass.Tenancy` sub-boundaries. Phase 3 adds `Mailglass.Outbound` (deps: `Repo, Events, Suppression, RateLimiter, Renderer, Telemetry, Tenancy, Adapter, Config`; notably NOT `Mailable` — Mailable depends on Outbound, not reverse), `Mailglass.Adapter` (deps: none; behaviour module; exports: `Mailglass.Adapters.Fake, Mailglass.Adapters.Swoosh`), `Mailglass.RateLimiter` (deps: `Config, Telemetry, Error`), `Mailglass.Mailable` (deps: `Components, Message, Renderer, Outbound`), `Mailglass.Tracking` (deps: `Config, Renderer, Floki, Phoenix.Token`).
- **`mix compile --no-optional-deps --warnings-as-errors` CI lane** — Phase 3 must keep passing. `Mailglass.Outbound.Worker` behind Oban gateway; `deliver_later/2` fallback path takes Task.Supervisor; no adapter code references Oban structs in the public type surface (D-14 rationale).

### Integration Points

- **`Mailglass.Application` supervision tree** — Phase 3 adds, in order after `Mailglass.Repo`:
  1. `{Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2}` — for Projector broadcasts + Fake simulation PubSub.
  2. `Task.Supervisor` with name `Mailglass.TaskSupervisor` — Oban-fallback async.
  3. `Mailglass.RateLimiter.Supervisor` — ETS owner per D-22.
  4. `Mailglass.Adapters.Fake.Supervisor` — per D-02.
  5. Conditional `Mailglass.Outbound.Worker` queue setup iff Oban loaded (`Code.ensure_loaded?(Oban)`).
- **`mix.exs`** — no new required deps. Phoenix.PubSub is transitively present via Phoenix; Phoenix.Token is in Plug.Crypto.
- **`config/config.exs` + `config/test.exs`** — Phase 3 adds `:async_adapter` (defaults `:oban` detection), `:rate_limit` (defaults 100/min), `:tracking` (required if any mailable opts in), `:suppression_store` (defaults `Mailglass.SuppressionStore.Ecto`; test.exs can override to `.ETS`).
- **`test/support/`** — new files: `mailer_case.ex`, `webhook_case.ex` (minimal stub; Phase 4 fleshes out), `admin_case.ex` (minimal stub; Phase 5 fleshes out). `Mailglass.TestAssertions` lives in `lib/` (exported for adopter consumption).
- **`docs/api_stability.md`** — extends with §Adapter (TRANS-01 return shape), §Outbound (facade signatures + bang variants), §Mailable (injection surface + `use` opts vocabulary), §RateLimiter (check/3 contract + reserved ETS table name `:mailglass_rate_limit`), §Clock (Mailglass.Clock.utc_now/0 contract + `Frozen.advance/1`), §PubSub (topic format + reserved `mailglass:` prefix), §Tracking (URL shapes + token payload schemas + rotation semantics).
- **Phase 4 hook points** — Phase 4's `Mailglass.Webhook.Plug` + provider verifiers consume `Mailglass.Events.append_multi/3` + `Mailglass.Outbound.Projector.update_projections/2` — Phase 3 does not change these APIs, just extends Projector with the post-commit broadcast.
- **Phase 5 hook points** — `MailglassAdmin.PreviewLive` consumes `Mailglass.Mailable.preview_props/0` (D-12 optional callback) + subscribes to `Mailglass.PubSub.Topics.events(tenant_id)` for live event streams.
- **Phase 6 hook points** — `NoOversizedUseInjection` AST-counts `Mailglass.Mailable.__using__/1` against the 20-line budget; `NoTrackingOnAuthStream` inspects `@mailglass_opts` + function names; `NoRawSwooshSendInLib` forbids `Swoosh.Mailer.deliver/1` anywhere in `lib/mailglass`; `PrefixedPubSubTopics` enforces `mailglass:` prefix (the `Mailglass.PubSub.Topics` builder shapes already comply); `NoDirectDateTimeNow` enforces `Mailglass.Clock` as the single legitimate clock source.

</code_context>

<specifics>
## Specific Ideas

- **Swoosh.Adapters.Sandbox is the ancestral library for the Fake adapter.** Not accrue's single-GenServer Fake (which doesn't handle `async: true` at scale). Swoosh.Sandbox is already solved for every process shape mailglass will see: Phoenix request, LiveView, Oban worker, Wallaby/PhoenixTest.Playwright browser tests. Borrowing its pattern means mailglass inherits documented integration guarantees at zero effort. Accrue's Fake stays relevant as a reference for the *event taxonomy simulation* shape (`trigger_event/3` API), not the storage primitive.
- **ActionMailer's `MessageDelivery` proxy is the anti-pattern.** `UserMailer.welcome(user).deliver_now` looks clever but hides that `.welcome(user)` did nothing. Phase 3 returns a real `%Message{}` from the builder; the send is an explicit second step. Elixir developers pipe; they don't chain lazy proxies.
- **The `%Mailglass.Delivery{}` is the universal handoff object.** Sync `deliver/2`, async `deliver_later/2`, Task.Supervisor fallback, `deliver_many/2`, Fake-adapter recorded sends, TestAssertions, webhook ingest (Phase 4), and admin LiveView (Phase 5) all converge on the same schema. Optional Oban never leaks into the public type signature — the Delivery row is the abstraction seam.
- **Two-Multi sync path + orphan reconciliation is the correct pattern.** Adapter-call-in-transaction is a hard no (Postgres connection-pool starvation under provider I/O). The orphan `:queued` Delivery between Multi#1 and Multi#2 is recoverable via `Events.Reconciler` (Phase 2 D-19). This is the "outbox pattern" correctly applied to transactional email — the ledger is the outbox, and the reconciler is the sweep.
- **`Oban.insert/3` inside an `Ecto.Multi` is the canonical async primitive.** It's designed to insert the job row in caller transactions. Any pattern that enqueues AFTER commit (`Repo.transact → Oban.insert`) creates orphan `:queued` Deliveries with no scheduled worker on crash between the two.
- **Compile-time `@mailglass_opts` is the bridge between `use` macro + Phase 6 Credo + Phase 5 admin discovery + Phase 3 runtime guard.** One attribute, four consumers, no drift.
- **Privacy enforcement is three layers, never fewer.** (1) NimbleOptions default=`false`, (2) Phase 6 Credo compile-time `TRACK-02` + function-name heuristic, (3) Phase 3 runtime guard raising `%ConfigError{type: :tracking_on_auth_stream}`. Silent warnings get muted; raising makes the violation a merge-blocking test failure in adopter CI.
- **Full-URL-in-signed-token click pattern structurally eliminates open-redirect.** No `?r=` query parameter exists in the URL surface; the class of bug Mailchimp shipped in 2019 and 2022 cannot occur. Gmail's 102KB clipping threshold leaves ~100KB of room even with heavy newsletters.
- **`:transactional` stream bypassing RateLimiter is an invariant, not a tunable.** A password-reset throttled because a marketing campaign saturated the bucket is a security incident. Documented in `api_stability.md` so adopters don't try to "fix" their provider's 429 by widening transactional limits.
- **Phase 3 property test shape** (informs planner's test decomposition of AUTHOR-01 + TRANS-02 + SEND-01):
  ```
  property "sync send converges: Delivery inserted + Event(:queued) + Event(:dispatched) with correct tenancy"
  property "async send converges: Multi inserts Delivery + Event(:queued) + Oban job atomically"
  property "deliver_many is idempotent: re-running after partial failure produces zero duplicates"
  property "every send emits send span with metadata subset of whitelist AND includes tenant_id"
  property "rate-limit over-capacity returns RateLimitError with non-negative retry_after_ms"
  property "Fake.trigger_event/3 writes through Projector + Events.append_multi (equivalent to webhook path)"
  ```
- **`Mailglass.Outbound.Worker` Oban args schema** (locked via api_stability.md):
  ```elixir
  %{
    "delivery_id" => binary(),          # UUIDv7 string
    "mailglass_tenant_id" => binary()   # matches TenancyMiddleware contract
  }
  ```
  Never serialize `%Message{}` into job args (adopter types may not be JSON-safe). The Worker fetches Delivery by id + loads the pre-rendered HTML from `delivery.metadata` or a blob store (Claude's discretion for the blob-store choice at v0.1 — likely in-row `delivery.rendered_html` jsonb column, matching `metadata` shape).
- **`Mailglass.Outbound.Worker` `unique:` opt** — `unique: [period: 3600, fields: [:args], keys: [:delivery_id]]` prevents double-enqueue on retry storms. Documented.
- **Tracking token JSON schema** (locked via api_stability.md):
  ```
  Open:  {:open,  delivery_id, tenant_id}
  Click: {:click, delivery_id, tenant_id, target_url}
  ```
  Atom-first tuple is JSON-unfriendly but stays inside the Phoenix.Token binary envelope — adopters never see the raw payload. If cross-language validation is ever needed (v0.5+), convert to a map with string keys.

</specifics>

<deferred>
## Deferred Ideas

- **Per-tenant adapter resolver** (v0.5 DELIV-07) — Phase 3 ships `Mailglass.Adapter` as a single-impl-per-config behaviour. Multi-resolver `Mailglass.AdapterRegistry` cached per `(tenant_id, scope)` lands v0.5. D-29's `Mailglass.Adapters.Swoosh` shape doesn't preclude it; the v0.5 registry plugs in at the Worker's adapter-resolution step.
- **Per-domain rate-limiting promotion from ETS to `:pg`-coordinated cluster limits** (v0.5 DELIV-08) — Phase 3 D-22 ships ETS-only. Promotion requires an empirical benchmark first.
- **List-Unsubscribe + RFC 8058 header injection** (v0.5 DELIV-01) — Phase 3 D-36 reserves the skip-rule in the Rewriter; the injection pipeline lands v0.5.
- **Stream-policy enforcement beyond no-op** (v0.5 DELIV-02) — Phase 3 D-25 ships the seam. v0.5 implements transactional-never-tracked + bulk-auto-List-Unsubscribe + physical-address-per-CAN-SPAM.
- **`Mailglass.SuppressionStore.Redis`** — for large-scale adopters needing Redis bloom filters. v0.5+. Phase 3 ships `.Ecto` default + `.ETS` test impl.
- **DKIM signing helper for self-hosted SMTP** (v0.5 DELIV-09) — adopter-owned at v0.1 via existing `gen_smtp` gateway.
- **`mix mail.doctor` live DNS deliverability checks** (v0.5 DELIV-06) — separate feature lane; depends on webhook ingest (Phase 4) + admin (Phase 5) for visualization.
- **Feedback-ID helper with stable SenderID format** (v0.5 DELIV-10) — Phase 1 COMP-02 already ships the auto-inject; stable format spec lives in api_stability.md extension at v0.5.
- **Per-call `tracking: [opens: true]` override** — deliberately rejected (D-30). Adopters who need it should create a separate mailable with the opposite default. Compile-time AST-inspectability is non-negotiable for TRACK-02.
- **Sliding-window rate limiting** — Phase 3 ships leaky-bucket with continuous refill (D-23). Sliding window adds memory + complexity with no throughput benefit for our use case.
- **`deliver_later!/2`** — deliberately rejected (D-16). Enqueue isn't a delivery; there's nothing delivery-shaped to raise about.
- **Mandatory `preview_props/0`** — deliberately optional (D-12). Punishing adopters who don't want Phase 5 admin is poor DX.
- **`Message.put_tracking/2` runtime function** — deliberately not shipped. Breaks TRACK-02 compile-time inspectability.
- **Wildcard TLS certificate management for multi-tenant tracking hosts** — adopter-owned. Documented in tracking guide, not automated by mailglass.
- **Consent UI / GDPR-aware tracking toggles** — permanently out of scope (marketing-concern territory). Documented.
- **Tracking event deduplication across provider webhook + mailglass tracking endpoint** — Phase 3 + Phase 4 write both when both fire (they measure different things: provider sees delivery/open-delivery, endpoint sees actual engagement). Deduplication UI lives in Phase 5 admin, not the ingest path.
- **Firefox ETP / Brave tracking-host blocking mitigations** — not mailglass's problem; we correctly report reality.
- **Sync `send/2` single-Multi with adapter-inside-transaction** — deliberately rejected (D-20). Any "we can optimize this later" reasoning applied here leads to a production outage the first time a provider's TLS handshake hangs.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 3.

</deferred>

---

*Phase: 03-transport-send-pipeline*
*Context gathered: 2026-04-22*
