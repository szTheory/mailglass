# Phase 3: Transport + Send Pipeline — Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 38 new + 7 patches = 45 files
**Analogs found:** 44 / 45 (Tracking.Rewriter has no close in-repo analog — RESEARCH §Tracking + Floki deps stand in)

---

## Codebase State

Phase 3 builds on top of Phase 1 (error structs, `Mailglass.Config`, `Mailglass.Telemetry`, `Mailglass.Message`, `Mailglass.Renderer`, `Mailglass.OptionalDeps.*`) and Phase 2 (`Mailglass.Events`, `Mailglass.Outbound.Delivery`, `Mailglass.Outbound.Projector`, `Mailglass.Tenancy`, `Mailglass.Suppression.Entry`, `Mailglass.SuppressionStore.Ecto`, `Mailglass.Oban.TenancyMiddleware`). All of these are imported verbatim; Phase 3 extends a handful (`Projector` gains a post-commit PubSub broadcast, `Tenancy` gains `assert_stamped!/0`, `Error` type union grows by 0 structs but `%ConfigError{}` adds two `:type` atoms, `Telemetry` adds `send_span/3` + `dispatch_span/3`).

Primary analog sources:

- **In-repo (mailglass Phase 1 + 2 shipped code)** — `lib/mailglass/telemetry.ex`, `lib/mailglass/errors/rate_limit_error.ex`, `lib/mailglass/errors/config_error.ex`, `lib/mailglass/suppression_store/ecto.ex`, `lib/mailglass/outbound/projector.ex`, `lib/mailglass/events.ex`, `lib/mailglass/tenancy.ex`, `lib/mailglass/optional_deps/oban.ex`, `lib/mailglass/application.ex`, `lib/mailglass/message.ex`, `lib/mailglass/template_engine.ex`.
- **Deps (read-only reference)** — `deps/swoosh/lib/swoosh/adapters/sandbox.ex`, `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex`, `deps/swoosh/lib/swoosh/test_assertions.ex`, `deps/swoosh/lib/swoosh/adapters/test.ex`, `deps/oban/lib/oban.ex`.
- **Prior-art sibling libs** — `/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex` (use macro + `@before_compile`), `/Users/jon/projects/accrue/accrue/lib/accrue/mailer.ex` (behaviour + facade), `/Users/jon/projects/accrue/accrue/lib/accrue/mailer/default.ex` (Oban-enqueuing adapter), `/Users/jon/projects/accrue/accrue/lib/accrue/mailer/test.ex` (send-to-self test adapter), `/Users/jon/projects/accrue/accrue/lib/accrue/test/mailer_assertions.ex` (4-style matcher), `/Users/jon/projects/accrue/accrue/lib/accrue/workers/mailer.ex` (Oban worker + unique), `/Users/jon/projects/accrue/accrue/lib/accrue/oban/middleware.ex` (process-dict restore via `wrap_perform`), `/Users/jon/projects/accrue/accrue/lib/accrue/clock.ex` + `/Users/jon/projects/accrue/accrue/lib/accrue/test/clock.ex` (runtime clock indirection + `advance/2`).

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/application.ex` (patch: PubSub + Task.Supervisor + RateLimiter.Supervisor + Fake.Supervisor children; `:persistent_term` oban warn) | supervisor | boot-time | self (lines 1-35) | patch |
| `lib/mailglass/config.ex` (patch: `:async_adapter`, `:rate_limit`, `:tracking`, keep `:suppression_store`) | config | boot-time | self (lines 4-85) | patch |
| `lib/mailglass/telemetry.ex` (patch: `send_span/3`, `dispatch_span/3`, plus `@logged_events` additions) | utility | event emission | self (lines 104-135) | patch |
| `lib/mailglass/errors/config_error.ex` (patch: extend `@types` with `:tracking_on_auth_stream`, `:tracking_host_missing`) | error struct | N/A | self | patch |
| `lib/mailglass/tenancy.ex` (patch: add `assert_stamped!/0`; add optional `c:tracking_host/1`) | behaviour + module | process-dict | self (lines 40-148) | patch |
| `lib/mailglass/outbound/projector.ex` (patch: `Phoenix.PubSub.broadcast` after `Repo.transact` commits) | context (pure changeset) | transform + broadcast | self (lines 58-72) | patch |
| `lib/mailglass/clock.ex` [NEW] | utility | request-response | `~/projects/accrue/accrue/lib/accrue/clock.ex` (runtime dispatch pattern) | exact |
| `lib/mailglass/clock/system.ex` [NEW] | utility impl | request-response | `Mailglass.Tenancy.SingleTenant` (tiny default impl) | role-match |
| `lib/mailglass/clock/frozen.ex` [NEW] | test helper | process-dict r/w | `Mailglass.Tenancy` process-dict helpers (`put_current`/`with_tenant`) | role-match |
| `lib/mailglass/adapter.ex` [NEW] | behaviour | request-response | `lib/mailglass/suppression_store.ex` + `lib/mailglass/template_engine.ex` (2-of-2 Phase 2 behaviour precedent) | exact |
| `lib/mailglass/adapters/fake.ex` [NEW] | adapter + public API | in-mem write + ETS read | `deps/swoosh/lib/swoosh/adapters/sandbox.ex` (ownership + `$callers` + allow-list) | exact |
| `lib/mailglass/adapters/fake/supervisor.ex` [NEW] | supervisor | boot-time | RESEARCH §3.4 tree shape; pattern from `Mailglass.RateLimiter.Supervisor` (sibling in this phase) | role-match |
| `lib/mailglass/adapters/fake/storage.ex` [NEW] | GenServer (owns ETS + monitors) | ETS write + GenServer call | `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex` (entire file) | exact |
| `lib/mailglass/adapters/swoosh.ex` [NEW] | bridge adapter | request-response | `~/projects/accrue/accrue/lib/accrue/mailer/default.ex` (behaviour impl + error mapping) + RESEARCH §6.2 | role-match |
| `lib/mailglass/rate_limiter.ex` [NEW] | public API | ETS read/write | RESEARCH §4.2 (ETS update_counter multi-op) | no in-repo analog |
| `lib/mailglass/rate_limiter/supervisor.ex` [NEW] | supervisor | boot-time | RESEARCH §4.1 verbatim; no in-repo analog yet (first "supervisor owns ETS" pattern in mailglass) | role-match |
| `lib/mailglass/rate_limiter/table_owner.ex` [NEW] | GenServer (init-and-idle) | ETS ownership | RESEARCH §4.1 verbatim + `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex:59-63` (init creates ETS) | role-match |
| `lib/mailglass/suppression.ex` [NEW] | context/facade | request-response | `lib/mailglass/events.ex` (thin facade over store) | role-match |
| `lib/mailglass/suppression_store/ets.ex` [NEW] | behaviour impl | ETS read/write | `lib/mailglass/suppression_store/ecto.ex` + `Mailglass.RateLimiter.TableOwner` (sibling) | role-match |
| `lib/mailglass/suppression_store/ets/supervisor.ex` [NEW] | supervisor | boot-time | `Mailglass.RateLimiter.Supervisor` (sibling) | role-match |
| `lib/mailglass/suppression_store/ets/table_owner.ex` [NEW] | GenServer (init-and-idle) | ETS ownership | `Mailglass.RateLimiter.TableOwner` (sibling) | exact |
| `lib/mailglass/stream.ex` [NEW] | context (no-op seam) | request-response | `lib/mailglass/tenancy/single_tenant.ex` (tiny seam module) | role-match |
| `lib/mailglass/mailable.ex` [NEW] | behaviour + `__using__` macro | compile-time + runtime | `~/projects/accrue/accrue/lib/accrue/billable.ex` (15-line injection via `@before_compile`) | exact |
| `lib/mailglass/pub_sub.ex` [NEW] | utility | N/A (typed constructor) | `lib/mailglass/errors/rate_limit_error.ex:40-42` (`__types__/0` style closed-set accessor) | role-match |
| `lib/mailglass/pub_sub/topics.ex` [NEW] | utility (pure) | transform | RESEARCH §D-27 verbatim; no in-repo analog | no analog |
| `lib/mailglass/outbound.ex` [NEW] | public API facade + pipeline | request-response (hot path) | `~/projects/accrue/accrue/lib/accrue/mailer.ex` (behaviour + facade + telemetry span) + Phase 2 `lib/mailglass/events.ex:89-100` (Multi + Repo.transact pattern) | role-match |
| `lib/mailglass/outbound/worker.ex` [NEW] | Oban worker (conditional compile) | Oban perform | `~/projects/accrue/accrue/lib/accrue/workers/mailer.ex` (Oban.Worker + unique + perform) + `lib/mailglass/optional_deps/oban.ex:59+` (conditional defmodule) | exact |
| `lib/mailglass/tracking.ex` [NEW] | facade | request-response | `lib/mailglass/suppression.ex` (sibling, this phase) | role-match |
| `lib/mailglass/tracking/rewriter.ex` [NEW] | service (Floki transform) | transform | `lib/mailglass/renderer.ex:1-60` (pure pipeline + Floki) — no exact analog for anchor rewriting | no analog (weakest match in phase) |
| `lib/mailglass/tracking/token.ex` [NEW] | utility (Phoenix.Token wrapper) | sign/verify | `lib/mailglass/config.ex` shape + RESEARCH §Tracking D-33/34/35 | no analog |
| `lib/mailglass/tracking/plug.ex` [NEW] | Plug endpoint | HTTP request-response | RESEARCH §Tracking (no prior in-repo Plug; Phase 4 webhook Plug lands later) | no analog |
| `lib/mailglass/tracking/guard.ex` [NEW] | runtime guard (pure) | transform | `lib/mailglass/errors/rate_limit_error.ex` `new/2` (fail-loud error construction) | role-match |
| `lib/mailglass/test_assertions.ex` [NEW] | test helper (lib/) | process-mailbox + PubSub | `deps/swoosh/lib/swoosh/test_assertions.ex` (4 matcher styles) + `~/projects/accrue/accrue/lib/accrue/test/mailer_assertions.ex` (macro-based matcher + drain pattern) | exact |
| `test/support/mailer_case.ex` [NEW] | test case template | test infra | `test/support/data_case.ex` (Ecto sandbox setup) + RESEARCH §9.2 | role-match |
| `test/support/webhook_case.ex` [NEW] (Phase 4 stub) | test case template | test infra | `test/support/data_case.ex` + `test/support/mailer_case.ex` (sibling this phase) | role-match |
| `test/support/admin_case.ex` [NEW] (Phase 5 stub) | test case template | test infra | `test/support/data_case.ex` + `test/support/mailer_case.ex` | role-match |
| `mix.exs` (patch: `verify.core_send` alias; test `--only phase_03_uat`) | config | build-time | existing Phase 2 alias pattern; `sigra` / `accrue` mix.exs verify aliases | patch |
| `config/config.exs` (patch: `:async_adapter`, `:rate_limit`, `:tracking`) | config | boot-time | existing Phase 2 config | patch |
| `config/test.exs` (patch: `:suppression_store, Mailglass.SuppressionStore.ETS`; `:async_adapter, :task_supervisor` for one variant lane) | config | boot-time | existing Phase 2 `config/test.exs` | patch |
| `priv/repo/migrations/00000000000002_mailglass_deliveries_idempotency_key.exs` [NEW, conditional per RESEARCH §2.3] | migration | DDL | Phase 2 migration files (same style) | role-match |
| `lib/mailglass/outbound/delivery.ex` (patch IFF migration lands: add `:idempotency_key` field + changeset cast) | schema | CRUD | self (Phase 2) | patch |
| **Tests (all new)** | — | — | — | — |
| `test/mailglass/clock_test.exs` | test | unit | `test/mailglass/error_test.exs` (pure module test shape) | role-match |
| `test/mailglass/adapter_test.exs` | test | unit (behaviour contract) | `test/mailglass/suppression_store/ecto_test.exs` (behaviour + impl test) | role-match |
| `test/mailglass/adapters/fake_test.exs` | test | integration (ownership + ETS) | `deps/swoosh/test/swoosh/adapters/sandbox_test.exs` if present, else RESEARCH §1 | role-match |
| `test/mailglass/adapters/fake_concurrency_test.exs` | property test | async isolation | RESEARCH §1.3 (async: true with allow/2) | no analog |
| `test/mailglass/adapters/swoosh_test.exs` | test | unit (error mapping) | Phase 2 `test/mailglass/outbound/projector_test.exs` (pure changeset test) | role-match |
| `test/mailglass/rate_limiter_test.exs` | unit + property | ETS bucket math | RESEARCH §4.2 + StreamData existing usage | no analog |
| `test/mailglass/rate_limiter_supervision_test.exs` | integration | supervisor restart | RESEARCH §4.1 crash semantics | no analog |
| `test/mailglass/suppression_test.exs` | test | request-response | `test/mailglass/suppression_store/ecto_test.exs` | role-match |
| `test/mailglass/stream_test.exs` | test | unit (no-op seam) | `test/mailglass/tenancy_test.exs` (SingleTenant no-op) | role-match |
| `test/mailglass/mailable_test.exs` | test | macro + AST line count | `~/projects/accrue/accrue/test/accrue/billable_test.exs` (if exists) else macro expansion tests | role-match |
| `test/mailglass/outbound_test.exs` | test | integration (hot path) | Phase 2 `test/mailglass/events_test.exs` (Multi + transact shape) | role-match |
| `test/mailglass/outbound/preflight_test.exs` | test | unit (stage short-circuit) | `test/mailglass/error_test.exs` (closed atom set) | role-match |
| `test/mailglass/outbound/telemetry_test.exs` | property test | telemetry handlers | RESEARCH §10 + StreamData idiom | no analog |
| `test/mailglass/outbound/worker_test.exs` | integration | Oban perform | `~/projects/accrue/accrue/test/accrue/workers/mailer_test.exs` (if exists) | role-match |
| `test/mailglass/outbound/projector_broadcast_test.exs` | integration | PubSub | Phase 2 `test/mailglass/outbound/projector_test.exs` + `Phoenix.PubSub.subscribe` | role-match |
| `test/mailglass/tracking/default_off_test.exs` | test | unit | standard HTML diff assertion | role-match |
| `test/mailglass/tracking/auth_stream_guard_test.exs` | test | unit (raise) | `test/mailglass/error_test.exs` | role-match |
| `test/mailglass/tracking/token_rotation_test.exs` | test | unit (sign/verify) | Phoenix.Token docs | no analog |
| `test/mailglass/tracking/open_redirect_test.exs` | property test | URL safety | StreamData | no analog |
| `test/mailglass/test_assertions_test.exs` | test | self-hosting | `~/projects/accrue/accrue/test/accrue/test/mailer_assertions_test.exs` (if exists) | role-match |
| `test/mailglass/test_assertions_pubsub_test.exs` | integration | PubSub | projector_broadcast_test (sibling) | role-match |
| `test/mailglass/mailer_case_test.exs` | integration | setup/teardown | `test/mailglass/data_case_test.exs` (if exists) else inline | role-match |
| `test/mailglass/core_send_integration_test.exs` | phase gate (UAT) | end-to-end | Phase 2 `test/mailglass/persistence_integration_test.exs` pattern | role-match |

---

## Pattern Assignments

### Hot Path

#### `lib/mailglass/outbound.ex` [NEW] — (public API facade, request-response hot path)

**Analog A:** `~/projects/accrue/accrue/lib/accrue/mailer.ex` (behaviour + facade + `Telemetry.span` wrapper)

**Facade + telemetry span shape** (`accrue/lib/accrue/mailer.ex:40-51`):
```elixir
@spec deliver(email_type(), assigns()) :: {:ok, term()} | {:error, term()}
def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
  metadata = %{email_type: type, customer_id: assigns[:customer_id] || assigns["customer_id"]}

  Accrue.Telemetry.span([:accrue, :mailer, :deliver], metadata, fn ->
    if enabled?(type) do
      impl().deliver(type, assigns)
    else
      {:ok, :skipped}
    end
  end)
end
```

**Divergence notes:** mailglass returns `%Delivery{}` not `%Oban.Job{}`; facade name is `Mailglass.Outbound` (matches PROJECT D-20 "Outbound" vocabulary); arg is `%Mailglass.Message{}` not `(type, assigns)`; the `impl()` indirection is per-call adapter selection via `Mailglass.Config` not a behaviour impl selector; telemetry span is `[:mailglass, :outbound, :send]` per RESEARCH §D-26.

**Analog B:** `lib/mailglass/events.ex:89-115` (in-repo — Phase 2 Multi + `Repo.transact` + `events_append_span` pattern)

**Multi + transact pattern** (`events.ex:89-100`):
```elixir
def append(attrs) when is_map(attrs) do
  normalized = normalize(attrs)
  meta = %{
    tenant_id: normalized[:tenant_id],
    idempotency_key_present?: is_binary(Map.get(normalized, :idempotency_key))
  }
  Mailglass.Telemetry.events_append_span(meta, fn ->
    Mailglass.Repo.transact(fn -> do_insert(normalized) end)
  end)
end
```

**append_multi step** (`events.ex:110-115`):
```elixir
@spec append_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
def append_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
  normalized = normalize(attrs)
  changeset = Event.changeset(normalized)
  Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
end
```

**Divergence notes:** Phase 3 `persist_queued/1` is Multi#1; composes `Multi.insert(:delivery, Delivery.changeset(...))` then `Events.append_multi(:event_queued, ...)` then `Mailglass.Repo.transact/1`. Pipeline body lives in RESEARCH §2.1 verbatim. Two-Multi separation (Multi#1 → adapter.deliver/2 OUTSIDE any transaction → Multi#2) is non-negotiable per CONTEXT D-20.

**Preflight shape** (RESEARCH §5.1 + §2.1):
```elixir
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

**Shared with Worker:** `Mailglass.Outbound.dispatch_by_id/1` — Worker hydrates delivery by id then calls this; Task.Supervisor fallback calls the same function. This is the shared seam that keeps Oban-vs-Task-Supervisor returning identical Delivery rows.

---

#### `lib/mailglass/outbound/worker.ex` [NEW] — (Oban worker, conditional compile)

**Analog A:** `lib/mailglass/optional_deps/oban.ex:59-153` (in-repo — conditional `defmodule` gated by `Code.ensure_loaded?(Oban.Worker)`)

**Conditional compile + `wrap_perform` integration** (`optional_deps/oban.ex:59-90`):
```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Oban.TenancyMiddleware do
    @moduledoc """
    Serializes `Mailglass.Tenancy.current/0` across Oban job boundaries (D-33).
    ...
    """
    @spec wrap_perform(map(), (-> any())) :: any()
    def wrap_perform(%{args: args}, fun) when is_function(fun, 0) do
      case args do
        %{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id) ->
          Mailglass.Tenancy.with_tenant(tenant_id, fun)
        _ ->
          fun.()
      end
    end
  end
end
```

**Analog B:** `~/projects/accrue/accrue/lib/accrue/workers/mailer.ex:27-72` (Oban.Worker + unique + perform)

**Worker header + perform** (`accrue/workers/mailer.ex:27-56`):
```elixir
use Oban.Worker,
  queue: :accrue_mailers,
  max_attempts: 5,
  unique: [period: 60, fields: [:args, :worker]]

@impl Oban.Worker
def perform(%Oban.Job{args: %{"type" => type_str, "assigns" => assigns}}) do
  type = String.to_existing_atom(type_str)
  template_mod = resolve_template(type)
  ...
end
```

**Composed for Phase 3** (RESEARCH §3.2):
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

**Divergence notes:** queue name `:mailglass_outbound`; `max_attempts: 20` (vs accrue's 5 — transactional mail has tighter SLAs than billing emails); `unique` keys on `:delivery_id` specifically (not whole args); args are string keys per `TenancyMiddleware` contract (`"delivery_id"`, `"mailglass_tenant_id"`). NEVER serialize `%Message{}` into args per CONTEXT §specifics.

---

### Preflight

#### `lib/mailglass/suppression.ex` [NEW] — (context/facade, request-response)

**Analog:** `lib/mailglass/events.ex:1-100` (thin facade + telemetry + store indirection)

**Facade with store indirection** (inspired by `events.ex:83-100` + RESEARCH §5.2):
```elixir
defmodule Mailglass.Suppression do
  @moduledoc "Public preflight facade for suppression checks."
  alias Mailglass.Message

  @spec check_before_send(Message.t()) :: :ok | {:error, Mailglass.SuppressedError.t()}
  def check_before_send(%Message{} = msg) do
    key = %{tenant_id: msg.tenant_id, address: primary_recipient(msg), stream: msg.stream}

    case suppression_store().check(key, []) do
      :not_suppressed -> :ok
      {:suppressed, entry} -> {:error, Mailglass.SuppressedError.new(entry.scope, context: %{...})}
      {:error, err} -> {:error, err}
    end
  end

  defp suppression_store do
    Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  end
end
```

**Telemetry:** single-emit `[:mailglass, :outbound, :suppression, :stop]` per RESEARCH §D-26 — use `Mailglass.Telemetry.execute/3` NOT a full span (single-emit avoids ceremonial start/stop on sub-200μs work).

---

#### `lib/mailglass/rate_limiter.ex` [NEW] — (public API, ETS read/write)

**Analog:** RESEARCH §4.2 verbatim (no in-repo precedent — first `:ets.update_counter/4` hot-path user in mailglass)

**Per-stream bypass + check body** (RESEARCH §D-23 canonical):
```elixir
def check(tenant_id, domain, stream)
def check(_tenant_id, _domain, :transactional), do: :ok

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
    _ -> {:error, %RateLimitError{
           type: :per_domain,
           retry_after_ms: ceil(1 / refill_per_ms),
           context: %{tenant_id: tenant_id, domain: domain}
         }}
  end
end
```

**Telemetry:** single-emit `[:mailglass, :outbound, :rate_limit, :stop]` with `%{allowed: boolean, duration_us: int}` measurements — use `Telemetry.execute/3`.

**Divergence notes:** `:transactional` bypass is the FIRST function clause per CONTEXT D-24 — this is a load-bearing invariant, not a tunable. Error construction uses `%RateLimitError{}` directly (not `RateLimitError.new/2`) because `retry_after_ms` is a top-level field.

---

#### `lib/mailglass/rate_limiter/supervisor.ex` + `.../table_owner.ex` [NEW]

**Analog A:** `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex:59-63` (`init/1` creates ETS table)

**ETS init shape** (`sandbox/storage.ex:59-63`):
```elixir
@impl true
def init(_opts) do
  :ets.new(@table, [:set, :named_table, :public, {:read_concurrency, true}])
  {:ok, %{owners: MapSet.new(), allowed: %{}, shared: nil, monitors: %{}}}
end
```

**Analog B:** RESEARCH §4.1 verbatim (Supervisor + TableOwner)

**Complete tiny supervisor** (RESEARCH §D-22):
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
  # no handle_call / handle_cast / handle_info — init-and-idle.
end
```

**Divergence notes:** The OTP 27 ETS opts (`write_concurrency: :auto, decentralized_counters: true`) are mandatory — unlike Swoosh's Sandbox which is single-owner-per-test. `name: __MODULE__` IS used on `TableOwner` but documented in `api_stability.md` as library-reserved singleton (LINT-07 exception). RESEARCH §4.1 flags an `[ASSUMED]` — the planner should decide whether to name via atom literal `:mailglass_rate_limit_table_owner` (sidesteps LINT-07) vs. carve out the exception. Recommend the exception — the atom-literal name is harder to grep/stack-trace.

---

#### `lib/mailglass/stream.ex` [NEW] — (no-op seam, request-response)

**Analog:** `lib/mailglass/tenancy/single_tenant.ex` (tiny no-op seam module — 20 lines)

**No-op seam shape** (`tenancy/single_tenant.ex` entire file):
```elixir
defmodule Mailglass.Tenancy.SingleTenant do
  @moduledoc "Default resolver: scope/2 is a no-op."
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query
end
```

**Composed for Phase 3** (per CONTEXT D-25):
```elixir
defmodule Mailglass.Stream do
  @moduledoc "Stream policy seam. No-op at v0.1; v0.5 DELIV-02 swaps in real enforcement."

  @spec policy_check(Mailglass.Message.t()) :: :ok
  def policy_check(%Mailglass.Message{} = msg) do
    Mailglass.Telemetry.execute(
      [:mailglass, :outbound, :stream_policy, :stop],
      %{duration_us: 0},
      %{tenant_id: msg.tenant_id, stream: msg.stream}
    )
    :ok
  end
end
```

---

#### `lib/mailglass/tenancy.ex` (patch) — add `assert_stamped!/0`

**Analog:** self (`lib/mailglass/tenancy.ex:112-119`)

**Existing `tenant_id!/0`** (already in place):
```elixir
@spec tenant_id!() :: String.t()
def tenant_id! do
  case Process.get(@process_dict_key) do
    nil -> raise Mailglass.TenancyError.new(:unstamped)
    tenant_id when is_binary(tenant_id) -> tenant_id
  end
end
```

**Patch shape** (per CONTEXT D-18 + RESEARCH §5.1):
```elixir
@spec assert_stamped!() :: :ok
def assert_stamped! do
  _ = tenant_id!()
  :ok
end
```

Plus add optional `c:tracking_host/1` callback (CONTEXT D-32):
```elixir
@optional_callbacks tracking_host: 1
@callback tracking_host(context :: term()) :: {:ok, String.t()} | :default
```

---

### Adapter Behaviour + Fake

#### `lib/mailglass/adapter.ex` [NEW] — (behaviour)

**Analog:** `lib/mailglass/suppression_store.ex` (in-repo — behaviour with typedoc'd callback + `@type lookup_key ::`)

**Behaviour shape** (`suppression_store.ex:44-48`):
```elixir
@callback check(lookup_key(), keyword()) ::
            {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}

@callback record(record_attrs(), keyword()) ::
            {:ok, Entry.t()} | {:error, Ecto.Changeset.t() | term()}
```

**Composed for Phase 3** (per CONTEXT TRANS-01):
```elixir
defmodule Mailglass.Adapter do
  @moduledoc """
  Behaviour every mailglass adapter implements (TRANS-01).

  Return shape is locked in `docs/api_stability.md`.
  """

  @type deliver_ok :: %{required(:message_id) => String.t(), required(:provider_response) => term()}

  @callback deliver(Mailglass.Message.t(), keyword()) ::
              {:ok, deliver_ok()} | {:error, Mailglass.Error.t()}
end
```

---

#### `lib/mailglass/adapters/fake/storage.ex` [NEW] — (GenServer + ETS + monitors)

**Analog:** `deps/swoosh/lib/swoosh/adapters/sandbox/storage.ex` (entire file — 185 lines — copy structure verbatim, diverge only on the 2 items D-01 flags)

**Public checkout + find_owner API** (`sandbox/storage.ex:10-55`):
```elixir
def start_link(opts \\ []) do
  GenServer.start_link(__MODULE__, opts, name: __MODULE__)
end

def checkout, do: GenServer.call(__MODULE__, {:checkout, self()})
def checkin, do: GenServer.call(__MODULE__, {:checkin, self()})
def allow(owner_pid, allowed_pid), do: GenServer.call(__MODULE__, {:allow, owner_pid, allowed_pid})
def set_shared(pid), do: GenServer.call(__MODULE__, {:set_shared, pid})
def get_shared, do: GenServer.call(__MODULE__, :get_shared)
def find_owner(callers), do: GenServer.call(__MODULE__, {:find_owner, callers})

def all(owner_pid) do
  case :ets.lookup(@table, owner_pid) do
    [{^owner_pid, emails}] -> emails
    [] -> []
  end
end
```

**init + state** (`sandbox/storage.ex:59-63`):
```elixir
@impl true
def init(_opts) do
  :ets.new(@table, [:set, :named_table, :public, {:read_concurrency, true}])
  {:ok, %{owners: MapSet.new(), allowed: %{}, shared: nil, monitors: %{}}}
end
```

**find_owner (callers + allow-list)** (`sandbox/storage.ex:103-114`):
```elixir
def handle_call({:find_owner, callers}, _from, state) do
  result =
    Enum.find_value(callers, fn pid ->
      cond do
        MapSet.member?(state.owners, pid) -> {:ok, pid}
        owner = Map.get(state.allowed, pid) -> {:ok, owner}
        true -> nil
      end
    end)
  {:reply, result || :no_owner, state}
end
```

**push + test-pid notify** (`sandbox/storage.ex:116-126`):
```elixir
def handle_call({:push, owner_pid, email}, _from, state) do
  existing =
    case :ets.lookup(@table, owner_pid) do
      [{^owner_pid, emails}] -> emails
      [] -> []
    end
  :ets.insert(@table, {owner_pid, [email | existing]})
  send(owner_pid, {:email, email})
  {:reply, :ok, state}
end
```

**DOWN cleanup** (`sandbox/storage.ex:151-184`):
```elixir
@impl true
def handle_info({:DOWN, ref, :process, pid, _}, state) do
  if Map.has_key?(state.monitors, ref) do
    {:noreply, do_checkin(pid, state)}
  else
    {:noreply, state}
  end
end

defp do_checkin(pid, state) do
  :ets.delete(@table, pid)
  {to_demonitor, monitors} = Enum.split_with(state.monitors, fn {_ref, p} -> p == pid end)
  Enum.each(to_demonitor, fn {ref, _} -> Process.demonitor(ref, [:flush]) end)

  allowed = state.allowed
    |> Enum.reject(fn {allowed_pid, owner_pid} -> owner_pid == pid or allowed_pid == pid end)
    |> Map.new()
  # ... return updated state
end
```

**Divergences (RESEARCH §1.1 "Divergence from Sandbox"):**
1. Table name: `:mailglass_fake_mailbox` (vs `:swoosh_sandbox_emails`).
2. Stored value: `%Mailglass.Message{}` (vs `%Swoosh.Email{}`) — carries `mailable` + `tenant_id` fields that `assert_mail_sent(mailable: MyApp.UserMailer)` needs.
3. `send(owner_pid, {:mail, message})` (vs `{:email, email}`) — `Mailglass.TestAssertions` receive-based matchers pattern-match on `{:mail, _}`.
4. Also track `delivery_id` + `provider_message_id` + `recorded_at` in the stored tuple so `Fake.trigger_event/3` can look up the Delivery by `provider_message_id`.

---

#### `lib/mailglass/adapters/fake.ex` [NEW] — (adapter + public API — `deliveries/1`, `clear/1`, `last_delivery/1`, `trigger_event/3`, `advance_time/1`)

**Analog A:** `deps/swoosh/lib/swoosh/adapters/sandbox.ex:220-290` (adapter deliver + checkout/allow/encode_owner facade)

**Adapter callback + resolve_owner** (`sandbox.ex:220-308`):
```elixir
@impl true
def deliver(email, config) do
  case resolve_owner(config) do
    {:ok, owner} ->
      Storage.push(owner, email)
      {:ok, %{}}
    :ignored -> {:ok, %{}}
  end
end

defp resolve_owner(config) do
  callers = [self() | List.wrap(Process.get(:"$callers"))]
  case Storage.find_owner(callers) do
    {:ok, _owner} = ok -> ok
    :no_owner ->
      case Storage.get_shared() do
        nil -> handle_unregistered!(config)
        shared -> {:ok, shared}
      end
  end
end

defdelegate checkout(), to: Storage
defdelegate checkin(), to: Storage
defdelegate allow(owner_pid, allowed_pid), to: Storage
```

**Analog B:** `~/projects/accrue/accrue/lib/accrue/processor/fake.ex:125-172` (`trigger_event`-style `advance/2` + `now/0` public API)

**Advance + now pattern** (`accrue/processor/fake.ex:125-172`):
```elixir
@spec advance(GenServer.server(), integer()) :: :ok
def advance(server \\ __MODULE__, seconds)
def advance(__MODULE__, seconds) when is_integer(seconds), do: call({:advance, seconds})

@spec now() :: DateTime.t()
def now, do: current_time(__MODULE__)
```

**Composed for Phase 3 `trigger_event/3`** (per CONTEXT D-03):
```elixir
@spec trigger_event(String.t(), atom(), keyword()) ::
        {:ok, %Mailglass.Events.Event{}} | {:error, term()}
def trigger_event(provider_message_id, type, opts \\ []) do
  with {:ok, delivery} <- lookup_by_provider_message_id(provider_message_id),
       attrs <- build_event_attrs(delivery, type, opts) do
    Mailglass.Repo.transact(fn ->
      Mailglass.Events.append_multi(Ecto.Multi.new(), :event, attrs)
      |> Ecto.Multi.run(:projection, fn _repo, %{event: e} ->
           delivery
           |> Mailglass.Outbound.Projector.update_projections(e)
           |> Mailglass.Repo.update()
         end)
      |> Mailglass.Repo.transact()
    end)
  end
end
```

**Divergence notes:** `advance_time/1` delegates to `Mailglass.Clock.Frozen.advance/1` per D-03. `trigger_event/3` flows through the REAL `Events.append_multi/3 + Projector.update_projections/2` so Phase 4 webhook ingest uses the same write path — this is the load-bearing property of the Fake per D-03.

---

#### `lib/mailglass/adapters/swoosh.ex` [NEW] — (bridge adapter, request-response)

**Analog A:** `~/projects/accrue/accrue/lib/accrue/mailer/default.ex:31-40` (behaviour impl with input scalar check)

**Behaviour impl pattern** (`accrue/mailer/default.ex:31-40`):
```elixir
@behaviour Accrue.Mailer

@impl true
def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
  scalar_assigns = only_scalars!(assigns)
  %{type: Atom.to_string(type), assigns: stringify_keys(scalar_assigns)}
  |> Accrue.Workers.Mailer.new()
  |> Oban.insert()
end
```

**Analog B:** RESEARCH §6.2 verbatim (error mapping into `%SendError{}`)

**Error mapping shape** (RESEARCH §6.2):
```elixir
@behaviour Mailglass.Adapter

@impl Mailglass.Adapter
def deliver(%Mailglass.Message{} = msg, opts) do
  swoosh_adapter = resolve_swoosh_adapter(opts)

  case Swoosh.Adapter.deliver(swoosh_adapter, msg.swoosh_email, []) do
    {:ok, %{id: message_id} = response} ->
      {:ok, %{message_id: message_id, provider_response: response}}

    {:ok, response} when is_map(response) ->
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
```

**Divergence notes:** `body_preview` is a 200-byte head of the response body (document in moduledoc per CONTEXT §specifics / brand). LIB-01 — `Swoosh.Mailer.deliver/1` is forbidden in lib code; the wrapper calls `Swoosh.Adapter.deliver/3` directly (the lower-level primitive). NEVER put `:to, :from, :subject, :html_body, :body, :headers, :recipient, :email` in error context per Phase 1 D-31.

---

### Rate Limiter + ETS

_(covered above under Preflight)_

---

### Mailable Macro

#### `lib/mailglass/mailable.ex` [NEW] — (behaviour + `__using__` macro)

**Analog A:** `~/projects/accrue/accrue/lib/accrue/billable.ex` (entire file — 89 lines — the canonical 15-line injection via `@before_compile`)

**`__using__` + `@before_compile` pattern** (`billable.ex:48-68`):
```elixir
defmacro __using__(opts) do
  billable_type =
    case Keyword.get(opts, :billable_type) do
      nil -> __CALLER__.module |> Module.split() |> List.last()
      type when is_binary(type) -> type
    end

  quote do
    @__accrue_billable_type__ unquote(billable_type)
    @before_compile Accrue.Billable

    @doc false
    def __accrue__(:billable_type), do: @__accrue_billable_type__
  end
end

@doc false
defmacro __before_compile__(env) do
  billable_type = Module.get_attribute(env.module, :__accrue_billable_type__)
  quote do
    Ecto.Schema.has_one(:accrue_customer, Accrue.Billing.Customer,
      foreign_key: :owner_id,
      references: :id,
      where: [owner_type: unquote(billable_type)]
    )
    # ...
  end
end
```

**Analog B:** `lib/mailglass/template_engine.ex` (in-repo — behaviour `@callback` surface shape)

**Behaviour shape** (`template_engine.ex:24-30`):
```elixir
@callback compile(source :: String.t(), opts :: keyword()) ::
            {:ok, term()} | {:error, Mailglass.TemplateError.t()}

@callback render(compiled :: term(), assigns :: map(), opts :: keyword()) ::
            {:ok, iodata()} | {:error, Mailglass.TemplateError.t()}
```

**Composed for Phase 3 — injection body** (per CONTEXT D-09 verbatim + RESEARCH §8.1):
```elixir
defmacro __using__(opts) do
  quote bind_quoted: [opts: opts] do
    @behaviour Mailglass.Mailable          # line 1
    @before_compile Mailglass.Mailable      # line 2
    @mailglass_opts opts                    # line 3
    import Swoosh.Email                     # line 4
    import Mailglass.Components             # line 5

    def new, do: Mailglass.Message.new(__MODULE__, @mailglass_opts)  # 6
    def render(msg, tmpl, assigns \\ %{}),                           # 7
      do: Mailglass.Renderer.render(msg, __MODULE__, tmpl, assigns)
    def deliver(msg, opts \\ []),                                    # 8
      do: Mailglass.Outbound.deliver(msg, opts)
    def deliver_later(msg, opts \\ []),                              # 9
      do: Mailglass.Outbound.deliver_later(msg, opts)

    defoverridable new: 0, render: 3,                                # 10
      deliver: 2, deliver_later: 2
  end
end
```

**`@before_compile` for admin discovery** (RESEARCH §8.2):
```elixir
defmacro __before_compile__(_env) do
  quote do
    @doc false
    def __mailglass_mailable__, do: true
  end
end
```

**Behaviour callbacks** (RESEARCH §8.2):
```elixir
@callback new() :: Mailglass.Message.t()
@callback render(Mailglass.Message.t(), atom(), map()) ::
            {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t()}
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, %Mailglass.Outbound.Delivery{}} | {:error, Mailglass.Error.t()}
@callback deliver_later(Mailglass.Message.t(), keyword()) ::
            {:ok, %Mailglass.Outbound.Delivery{status: :queued}} | {:error, Mailglass.Error.t()}

@optional_callbacks preview_props: 0
@callback preview_props() :: [{atom(), map()}]
```

**Divergence notes:** 10 meaningful AST lines (D-09 says "exactly 15" — `bind_quoted` + 5 module attrs/imports count toward the budget; RESEARCH §8.1 counts "comfortable margin ≤20"). Phase 6 `LINT-05 NoOversizedUseInjection` enforces. Does NOT inject `import Phoenix.Component` per D-09 rationale (adopters opt in). `@mailglass_opts` is the AST-visible bridge for TRACK-02 Credo + Phase 3 runtime guard + Phase 5 admin discovery + `Message.new/0` seeding.

---

### Clock

#### `lib/mailglass/clock.ex` [NEW]

**Analog:** `~/projects/accrue/accrue/lib/accrue/clock.ex` (entire file — runtime dispatch pattern)

**Runtime dispatch via Application env** (`accrue/clock.ex:23-31`):
```elixir
@spec utc_now() :: DateTime.t()
def utc_now do
  case Application.get_env(:accrue, :env, :prod) do
    :test -> Accrue.Processor.Fake.now()
    _ -> DateTime.utc_now()
  end
end
```

**Composed for Phase 3** (per CONTEXT D-07 three-tier):
```elixir
defmodule Mailglass.Clock do
  @spec utc_now() :: DateTime.t()
  def utc_now do
    case Process.get(:mailglass_clock_frozen_at) do
      nil -> impl().utc_now()
      %DateTime{} = frozen -> frozen
    end
  end

  defp impl, do: Application.get_env(:mailglass, :clock, Mailglass.Clock.System)
end
```

**Divergence notes:** Three-tier resolution (process-dict frozen_at → Application.get_env impl → default `Clock.System`) is `async: true`-safe by design. Unlike accrue's single-env-flag which forces `async: false` on any test touching the clock. Phase 6 `LINT-12 NoDirectDateTimeNow` enforces this as the single legitimate clock source.

---

#### `lib/mailglass/clock/frozen.ex` [NEW]

**Analog:** `lib/mailglass/tenancy.ex:55-102` (process-dict helpers `put_current/1` + `with_tenant/2`)

**Process-dict put + with pattern** (`tenancy.ex:68-102`):
```elixir
@spec put_current(String.t() | nil) :: :ok
def put_current(tenant_id) when is_binary(tenant_id) do
  Process.put(@process_dict_key, tenant_id)
  :ok
end

@spec with_tenant(String.t(), (-> any())) :: any()
def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
  prior = Process.get(@process_dict_key)
  put_current(tenant_id)

  try do
    fun.()
  after
    if is_nil(prior) do
      Process.delete(@process_dict_key)
    else
      put_current(prior)
    end
  end
end
```

**Composed for Phase 3** (per CONTEXT D-07):
```elixir
defmodule Mailglass.Clock.Frozen do
  @key :mailglass_clock_frozen_at

  @spec freeze(DateTime.t()) :: DateTime.t()
  def freeze(%DateTime{} = dt) do
    Process.put(@key, dt)
    dt
  end

  @spec advance(integer() | Duration.t()) :: DateTime.t()
  def advance(ms) when is_integer(ms) do
    current = Process.get(@key) || DateTime.utc_now()
    new = DateTime.add(current, ms, :millisecond)
    Process.put(@key, new)
    new
  end

  @spec unfreeze() :: :ok
  def unfreeze do
    Process.delete(@key)
    :ok
  end
end
```

---

#### `lib/mailglass/clock/system.ex` [NEW]

**Analog:** `lib/mailglass/tenancy/single_tenant.ex` (tiny default impl)

```elixir
defmodule Mailglass.Clock.System do
  @spec utc_now() :: DateTime.t()
  def utc_now, do: DateTime.utc_now()
end
```

---

### PubSub Topics

#### `lib/mailglass/pub_sub/topics.ex` [NEW]

**Analog:** no in-repo analog yet (first PubSub topic helper in mailglass). RESEARCH §D-27 is canonical.

**Topic builder** (per CONTEXT D-27):
```elixir
defmodule Mailglass.PubSub.Topics do
  @spec events(String.t()) :: String.t()
  def events(tenant_id) when is_binary(tenant_id),
    do: "mailglass:events:#{tenant_id}"

  @spec events(String.t(), Ecto.UUID.t()) :: String.t()
  def events(tenant_id, delivery_id) when is_binary(tenant_id) and is_binary(delivery_id),
    do: "mailglass:events:#{tenant_id}:#{delivery_id}"

  @spec deliveries(String.t()) :: String.t()
  def deliveries(tenant_id) when is_binary(tenant_id),
    do: "mailglass:deliveries:#{tenant_id}"
end
```

**Divergence notes:** ALL topics MUST be prefixed `mailglass:` — Phase 6 `LINT-06 PrefixedPubSubTopics` enforces. The builder's shape is what adopters grep.

---

### Projector Broadcast Extension

#### `lib/mailglass/outbound/projector.ex` (patch — add PubSub broadcast after commit)

**Analog:** self (`lib/mailglass/outbound/projector.ex:58-72`)

**Current changeset-only shape** (`projector.ex:58-72`):
```elixir
@spec update_projections(Delivery.t(), Event.t()) :: Ecto.Changeset.t()
def update_projections(%Delivery{} = delivery, %Event{} = event) do
  Mailglass.Telemetry.persist_span(
    [:delivery, :update_projections],
    %{tenant_id: delivery.tenant_id, delivery_id: delivery.id},
    fn ->
      delivery
      |> Ecto.Changeset.change()
      |> maybe_advance_last_event(event)
      |> maybe_set_once_timestamp(event)
      |> maybe_flip_terminal(event)
      |> Ecto.Changeset.optimistic_lock(:lock_version)
    end
  )
end
```

**Patch strategy** (per CONTEXT D-04): `update_projections/2` signature stays unchanged — callers compose it into their `Ecto.Multi`. The post-commit broadcast side effect lives in a NEW function `broadcast_delivery_updated/3` that callers invoke AFTER their `Repo.transact/1` returns `{:ok, _}`. Do NOT embed the broadcast inside the changeset or `persist_span` — broadcasts MUST happen outside the transaction per D-04 "broadcast runs AFTER `Repo.transact/1` commits."

**New function shape** (per CONTEXT D-04 + RESEARCH §2.1 Multi#2):
```elixir
@spec broadcast_delivery_updated(Delivery.t(), atom(), map()) :: :ok
def broadcast_delivery_updated(%Delivery{} = delivery, event_type, meta) when is_atom(event_type) do
  payload = {:delivery_updated, delivery.id, event_type, meta}

  # Broadcast failure never rolls back (fire-and-forget; log-only on error).
  _ = Phoenix.PubSub.broadcast(
    Mailglass.PubSub,
    Mailglass.PubSub.Topics.events(delivery.tenant_id),
    payload
  )

  _ = Phoenix.PubSub.broadcast(
    Mailglass.PubSub,
    Mailglass.PubSub.Topics.events(delivery.tenant_id, delivery.id),
    payload
  )

  :ok
end
```

**Divergence notes:** Broadcasts to BOTH `events(tenant_id)` and `events(tenant_id, delivery_id)` per D-27. Callers are `Mailglass.Outbound.send/2` (Multi#2 success), `Mailglass.Outbound.Worker.perform/1` (Multi#2 success), `Mailglass.Adapters.Fake.trigger_event/3` (after its own `Repo.transact/1`), and (Phase 4) `Mailglass.Webhook.Plug`.

---

### Tracking

#### `lib/mailglass/tracking.ex` [NEW] — (facade)

**Analog:** `lib/mailglass/suppression.ex` (sibling this phase — facade with store indirection)

See Suppression pattern above.

#### `lib/mailglass/tracking/rewriter.ex` [NEW] — (Floki-based HTML transform)

**Analog:** no close analog. `lib/mailglass/renderer.ex:1-60` is the nearest — pure Floki-walking pipeline. RESEARCH §Tracking D-36 + D-37 is canonical.

**Pure pipeline shape** (`renderer.ex:1-25`):
```elixir
@moduledoc """
Pure-function render pipeline: HEEx → plaintext → CSS inlining → data-mg-* strip.

All functions are side-effect free. No processes, no DB, no HTTP calls.

## Pipeline (D-15 — plaintext runs BEFORE CSS inlining)

1. `render_html/2` — calls Mailglass.TemplateEngine.HEEx.render/3, returns HTML iodata
2. `to_plaintext/1` — custom Floki walker on the pre-VML logical HTML
3. `inline_css/1` — Premailex.to_inline_css/2 (preserves MSO conditionals per D-14)
4. `strip_mg_attributes/1` — removes all data-mg-* from the final HTML wire
"""
```

**Composed for Phase 3 `Tracking.Rewriter`** (per CONTEXT D-36 + D-37):
- Parse HTML with Floki.
- Walk `<a>` tags in `<body>` only (skip `<head>`).
- Skip hrefs matching `mailto:`, `tel:`, `sms:`, `#`, `data:`, `javascript:`, scheme-less.
- Skip any `<a data-mg-notrack>` (strip attribute in final output).
- Skip any href equal to normalized List-Unsubscribe URL (v0.5 hook reserved).
- Replace qualifying hrefs with `Mailglass.Tracking.Token.click_url/3`.
- Append `<img src="..." width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0;" />` as last child of `<body>`.

**Divergence notes:** Plaintext body NEVER rewritten per D-36. Called AFTER `Renderer.render/2` (which produces CSS-inlined HTML). Output: rewritten HTML string, unchanged plaintext.

---

#### `lib/mailglass/tracking/token.ex` [NEW]

**Analog:** no in-repo analog. RESEARCH §D-33/34/35 is canonical.

**Sign/verify with rotation** (per CONTEXT D-33 + D-35):
```elixir
@spec click_url(Endpoint.t(), String.t(), Ecto.UUID.t(), String.t(), String.t()) :: String.t()
def click_url(endpoint, delivery_id, tenant_id, target_url, host) do
  validate_target!(target_url)
  [head_salt | _] = salts()
  token = Phoenix.Token.sign(endpoint, head_salt, {:click, delivery_id, tenant_id, target_url},
    key_iterations: 1000, key_length: 32, digest: :sha256
  )
  "https://#{host}/c/#{token}"
end

@spec verify_click(Endpoint.t(), String.t()) ::
        {:ok, {Ecto.UUID.t(), String.t(), String.t()}} | :error
def verify_click(endpoint, token) do
  Enum.find_value(salts(), :error, fn salt ->
    case Phoenix.Token.verify(endpoint, salt, token,
           max_age: 2 * 365 * 86_400, key_iterations: 1000, key_length: 32, digest: :sha256) do
      {:ok, {:click, delivery_id, tenant_id, target_url}} ->
        {:ok, {delivery_id, tenant_id, target_url}}
      _ -> nil
    end
  end)
end
```

**Divergence notes:** `validate_target!/1` raises `%Mailglass.ConfigError{type: :invalid, context: %{rejected_url, reason: :scheme}}` at SIGN time per D-35. `tenant_id` lives ONLY in the signed payload, NEVER in URL path/query per D-39 — so failed verify returns HTTP 204 (pixel) or 404 (click), never echoing what was attempted.

---

#### `lib/mailglass/tracking/plug.ex` [NEW]

**Analog:** no in-repo analog (Phase 4 webhook plug lands later). RESEARCH §Tracking endpoint Plug composition.

**Route shape** (per CONTEXT D-34 + D-35):
```elixir
defmodule Mailglass.Tracking.Plug do
  use Plug.Router
  # GET /o/:token.gif → 43-byte GIF89a + no-cache headers + put_secure_browser_headers
  # GET /c/:token → 302 redirect (verified) or 404 (unverified)
  # CachingBodyReader is NOT needed (pixel/click don't need raw-body preservation).
end
```

---

#### `lib/mailglass/tracking/guard.ex` [NEW] — (runtime auth-stream guard per D-38)

**Analog:** `lib/mailglass/errors/rate_limit_error.ex` (fail-loud error construction)

**Runtime guard shape** (per CONTEXT D-38):
```elixir
@auth_fn_regex ~r/^(magic_link|password_reset|verify_email|confirm_account)/

@spec assert_safe!(Mailglass.Message.t()) :: :ok
def assert_safe!(%Mailglass.Message{mailable: mod, metadata: meta}) when is_atom(mod) do
  opts = mod.__mailglass_opts__()

  if tracking_enabled?(opts) and auth_function?(meta[:mailable_function]) do
    raise Mailglass.ConfigError.new(:tracking_on_auth_stream,
      context: %{mailable: mod, function: meta[:mailable_function]}
    )
  end
  :ok
end
```

**Divergence notes:** The runtime guard is invoked from `Mailglass.Outbound.send/2` (NOT the preflight pipeline — it's a PRECONDITION like `assert_stamped!/0`). Dual enforcement with Phase 6 `LINT-01 TRACK-02` Credo check — compile-time catches most cases; runtime catches dynamic function names. Adopters cannot turn this off.

---

### Test Infrastructure

#### `lib/mailglass/test_assertions.ex` [NEW]

**Analog A:** `deps/swoosh/lib/swoosh/test_assertions.ex` (4 matcher styles — Swoosh original)

**Four matcher styles** (`test_assertions.ex:72-116`):
```elixir
def assert_email_sent do
  assert_received {:email, _}
end

def assert_email_sent(%Email{} = email) do
  assert_received {:email, ^email}
end

def assert_email_sent(params) when is_list(params) do
  assert_received {:email, email}
  Enum.each(params, &assert_equal(email, &1))
end

def assert_email_sent(fun) when is_function(fun, 1) do
  assert_received {:email, email}
  assert fun.(email)
end
```

**Analog B:** `~/projects/accrue/accrue/lib/accrue/test/mailer_assertions.ex` (macro-based matcher + drain pattern + predicate escape hatch)

**Macro-based matcher** (`accrue/test/mailer_assertions.ex:40-56`):
```elixir
defmacro assert_email_sent(type_or_matcher, opts \\ [], timeout \\ 100) do
  quote do
    matcher = Accrue.Test.MailerAssertions.__matcher__(unquote(type_or_matcher), unquote(opts))
    t = unquote(timeout)
    observed = Accrue.Test.MailerAssertions.__collect_emails__(t)

    case Enum.find(observed, &Accrue.Test.MailerAssertions.__match__(&1, matcher)) do
      {_type, assigns} -> assigns
      nil -> ExUnit.Assertions.flunk(
        Accrue.Test.MailerAssertions.__failure_message__(matcher, observed, t))
    end
  end
end
```

**Drain/collect pattern** (`accrue/test/mailer_assertions.ex:203-209`):
```elixir
defp collect_emails(acc, timeout) do
  receive do
    {:accrue_email_delivered, type, assigns} -> collect_emails([{type, assigns} | acc], 0)
  after
    timeout -> Enum.reverse(acc)
  end
end
```

**Composed for Phase 3** (per CONTEXT D-05):
```elixir
defmacro assert_mail_sent(pattern_or_opts \\ [])

defmacro assert_mail_sent(params) when is_list(params) do
  quote do
    assert_received {:mail, msg}
    Enum.each(unquote(params), fn
      {:subject, v} -> assert msg.swoosh_email.subject == v
      {:to, v} -> assert Enum.any?(msg.swoosh_email.to, fn {_, addr} -> addr == v end)
      {:mailable, v} -> assert msg.mailable == v
      {:stream, v} -> assert msg.stream == v
    end)
  end
end

defmacro assert_mail_sent({:%{}, _, _} = struct_pattern) do
  quote do
    assert_received {:mail, unquote(struct_pattern)}
  end
end

# ... plus: last_mail/0, wait_for_mail/1, assert_no_mail_sent/0,
# assert_mail_delivered/2 (PubSub), assert_mail_bounced/2 (PubSub)
```

**PubSub-backed assertions** (per CONTEXT D-04 + D-05):
```elixir
@spec assert_mail_delivered(Delivery.t() | String.t(), timeout()) :: :ok
def assert_mail_delivered(msg_or_id, timeout \\ 100) do
  delivery_id = to_delivery_id(msg_or_id)
  assert_receive {:delivery_updated, ^delivery_id, :delivered, _meta}, timeout
  :ok
end
```

**Divergence notes:** matchers match `{:mail, %Message{}}` not `{:email, %Email{}}`; macro form uses `defmacro` so users write `%{mailable: UserMailer}` without quoting (accrue's pattern); predicate fn variant mirrors Swoosh; `assert_mail_delivered/2` consumes PubSub broadcasts per D-04 (no polling, no `Process.sleep`).

---

#### `test/support/mailer_case.ex` [NEW]

**Analog A:** `test/support/data_case.ex` (in-repo — Ecto sandbox + tenant stamp + async default)

**`ExUnit.CaseTemplate` + setup shape** (`data_case.ex:22-48`):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    alias Mailglass.TestRepo
    import Ecto
    import Ecto.Changeset
    import Ecto.Query
    import Mailglass.DataCase
  end
end

setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  tenant_id = Map.get(tags, :tenant, "test-tenant")
  unless tenant_id == :unset, do: Mailglass.Tenancy.put_current(tenant_id)
  :ok
end
```

**Composed for Phase 3** (per CONTEXT D-06):
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

  @doc "Sets Fake + Swoosh to global mode; forces async: false."
  def set_mailglass_global(context \\ %{}) do
    if Map.get(context, :async), do: raise "MailerCase global mode requires async: false"
    Mailglass.Adapters.Fake.set_shared(self())
    on_exit(fn -> Mailglass.Adapters.Fake.set_shared(nil) end)
    :ok
  end
end
```

**Divergence notes:** `async: true` by default (Fake's ownership makes this safe); `@tag oban: :manual` opts into `assert_enqueued`/`perform_job` patterns per D-08; `@tag tenant: :unset` disables stamping for tests asserting the unstamped-fail path; `setup :set_mailglass_global` mirrors `set_swoosh_global` — explicit opt-out is the only path.

---

### Mix Tooling

#### `mix.exs` (patch — `verify.core_send` alias)

**Analog:** existing Phase 2 `mix.exs` aliases + RESEARCH §11

**Alias shape** (per RESEARCH §11):
```elixir
"verify.core_send": [
  "ecto.drop -r Mailglass.TestRepo --quiet",
  "ecto.create -r Mailglass.TestRepo --quiet",
  "test --warnings-as-errors --only phase_03_uat --exclude flaky",
  "compile --no-optional-deps --warnings-as-errors",
  "credo --strict"
]
```

**Divergence notes:** `phase_03_uat` tag flags `test/mailglass/core_send_integration_test.exs` which exercises the 5 roadmap success criteria + idempotency-key replay safety. Mirrors Phase 2's `phase_02_uat` tag precedent.

---

### Application Supervision Tree

#### `lib/mailglass/application.ex` (patch — add 4 children; idempotent Oban warning)

**Analog:** self (`lib/mailglass/application.ex:1-35`)

**Current shape** (`application.ex:7-35`):
```elixir
def start(_type, _args) do
  if Code.ensure_loaded?(Mailglass.Config) and
       function_exported?(Mailglass.Config, :validate_at_boot!, 0) do
    Mailglass.Config.validate_at_boot!()
  end

  maybe_warn_missing_oban()

  children = []  # Phase 1 intentionally empty

  Supervisor.start_link(children, strategy: :one_for_one, name: Mailglass.Supervisor)
end

defp maybe_warn_missing_oban do
  unless Code.ensure_loaded?(Oban) do
    Logger.warning("""
    [Mailglass] Oban is not loaded. deliver_later/2 will use Task.Supervisor
    as a fallback, which does not survive node restarts. Add {:oban, "~> 2.21"}
    to your mix.exs for production use.
    """)
  end
end
```

**Patched shape** (per RESEARCH §3.4 + CONTEXT §Integration Points):
```elixir
def start(_type, _args) do
  if Code.ensure_loaded?(Mailglass.Config) and
       function_exported?(Mailglass.Config, :validate_at_boot!, 0) do
    Mailglass.Config.validate_at_boot!()
  end

  maybe_warn_missing_oban()  # gated by :persistent_term per CONTEXT D-17

  children = [
    {Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2},
    {Task.Supervisor, name: Mailglass.TaskSupervisor},
    Mailglass.RateLimiter.Supervisor,
    Mailglass.Adapters.Fake.Supervisor,
    Mailglass.SuppressionStore.ETS.Supervisor
  ]

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

**Divergence notes:** Child order matters: PubSub first (Projector broadcasts depend on it), then `Task.Supervisor` (Oban fallback), then `RateLimiter.Supervisor`, then `Fake.Supervisor`, then `SuppressionStore.ETS.Supervisor`. `Mailglass.Repo` is adopter-supervised (per Phase 1/2) and not in this tree. `:persistent_term`-gated Oban warning is idempotent across supervisor restarts per D-17.

---

### Errors

#### `lib/mailglass/errors/config_error.ex` (patch — extend `@types`)

**Analog:** self (`lib/mailglass/errors/config_error.ex:23` — closed `@types` list)

**Current `@types`** (`config_error.ex:23`):
```elixir
@types [:missing, :invalid, :conflicting, :optional_dep_missing]
```

**Patched `@types`** (per CONTEXT D-32 + D-38):
```elixir
@types [
  :missing, :invalid, :conflicting, :optional_dep_missing,
  :tracking_on_auth_stream, :tracking_host_missing
]
```

**Plus extend** `format_message/2` clauses for the two new types (brand voice: "Tracking misconfigured: ..." never "Oops!") and update the `@type t ::` union and `__types__/0` signature accordingly.

**Plus update** `docs/api_stability.md` — §ConfigError `:type` atom set, per the Phase 1 D-31 cross-check test pattern.

---

## Shared Patterns

### Error construction (all preflight short-circuits + adapter failures)

**Source:** `lib/mailglass/errors/rate_limit_error.ex:68-78` (in-repo — Phase 1 `new/2` idiom)

**Apply to:** all Phase 3 error raises and `{:error, ...}` returns.

```elixir
@spec new(atom(), keyword()) :: t()
def new(type, opts \\ []) when type in @types do
  ctx = opts[:context] || %{}
  %__MODULE__{
    type: type,
    message: format_message(type, ctx),
    cause: opts[:cause],
    context: ctx,
    retry_after_ms: opts[:retry_after_ms] || 0
  }
end
```

**Rules:** Always pattern-match on the struct module + `:type` atom, never on `:message`. Closed `:type` atom sets tested via `__types__/0` against `docs/api_stability.md`. `Jason.Encoder` derived on `[:type, :message, :context]` only (exclude `:cause` — may carry PII).

### Telemetry span emission (hot path + adapter + persist)

**Source:** `lib/mailglass/telemetry.ex:89-95` (in-repo — Phase 1 `span/3`)

**Apply to:** `Mailglass.Outbound.send_span/3`, `dispatch_span/3`, `persist_span/3`.

```elixir
@spec span([atom()], map(), (-> result)) :: result when result: term()
def span(event_prefix, metadata, fun)
    when is_list(event_prefix) and is_map(metadata) and is_function(fun, 0) do
  :telemetry.span(event_prefix, metadata, fn ->
    result = fun.()
    {result, metadata}
  end)
end
```

**Rules:** Metadata whitelist per Phase 1 D-31: `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. **NEVER** include `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`. Phase 6 `LINT-02 NoPiiInTelemetryMeta` enforces. Single-emit events (suppression, rate_limit, stream_policy) use `Mailglass.Telemetry.execute/3` with `%{duration_us: int}` measurement per RESEARCH §D-26.

### Multi + `Repo.transact/1` shape (every Phase 3 write path)

**Source:** `lib/mailglass/events.ex:95-99` (in-repo — Phase 2 canonical)

**Apply to:** `Mailglass.Outbound.send/2` Multi#1 + Multi#2, `Mailglass.Outbound.Worker.perform/1` Multi#2, `Mailglass.Adapters.Fake.trigger_event/3`, `Mailglass.Outbound.deliver_later/2` (single Multi with `Oban.insert/3` step).

```elixir
Mailglass.Telemetry.events_append_span(meta, fn ->
  Mailglass.Repo.transact(fn -> do_insert(normalized) end)
end)
```

**Rules:** Every Multi flows through `Mailglass.Repo.transact/1` (which translates SQLSTATE 45A01 into `%EventLedgerImmutableError{}`). Adapter HTTP call MUST NOT happen inside any transaction (D-20). PubSub broadcast MUST NOT happen inside any transaction (D-04).

### Optional-dep gating (`Code.ensure_loaded?`)

**Source:** `lib/mailglass/optional_deps/oban.ex:36-46` + `:59+` (in-repo — Phase 1+2 canonical)

**Apply to:** `Mailglass.Outbound.Worker` (entire `defmodule` wrapped in `if Code.ensure_loaded?(Oban.Worker) do ... end`).

```elixir
@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

@spec available?() :: boolean()
def available?, do: Code.ensure_loaded?(Oban)
```

**Rules:** `mix compile --no-optional-deps --warnings-as-errors` MUST stay green. No public type signature may reference Oban structs (D-14 rationale — returning `%Oban.Job{}` from `deliver_later/2` would break this lane).

### Closed atom set + `__types__/0` + api_stability cross-check

**Source:** `lib/mailglass/errors/rate_limit_error.ex:40-42` (in-repo — Phase 1 canonical)

**Apply to:** `Mailglass.ConfigError.__types__/0` extension; `Mailglass.Outbound.Delivery.__event_types__/0` (already shipped Phase 2 — used by Fake for `trigger_event/3` validation).

```elixir
@doc "Returns the closed set of valid :type atoms. Tested against docs/api_stability.md."
@doc since: "0.1.0"
@spec __types__() :: [atom()]
def __types__, do: @types
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/mailglass/tracking/rewriter.ex` | service (Floki transform) | HTML transform | No prior mailglass/prior-art library rewrites anchor hrefs; RESEARCH §D-36/37 is canonical. Floki usage patterns from `lib/mailglass/renderer.ex` apply. |
| `lib/mailglass/tracking/token.ex` | utility (Phoenix.Token) | sign/verify | No prior mailglass library uses Phoenix.Token rotation; Phoenix hex docs + RESEARCH §D-33 are the references. |
| `lib/mailglass/tracking/plug.ex` | Plug endpoint | HTTP request-response | Phase 4 webhook Plug lands later — this is the FIRST Plug endpoint in mailglass. Plug.Router idiom + RESEARCH §Tracking stand in. |
| `lib/mailglass/pub_sub/topics.ex` | utility (pure) | transform | FIRST PubSub topic builder in mailglass; CONTEXT D-27 verbatim. |
| `lib/mailglass/rate_limiter.ex` | ETS hot path | read/write | FIRST `:ets.update_counter/4` hot-path user; RESEARCH §4.2 is canonical. |
| `test/mailglass/adapters/fake_concurrency_test.exs` | property test | async isolation | FIRST property test for concurrent ownership; RESEARCH §1.3 guides. |
| `test/mailglass/outbound/telemetry_test.exs` | property test | metadata whitelist | FIRST property test for telemetry-emission metadata; RESEARCH §10 + §3 specifics guide. |
| `test/mailglass/tracking/open_redirect_test.exs` | property test | URL safety | FIRST property test for URL-pattern invariants; StreamData + RESEARCH §D-35 pattern (a) guide. |
| `test/mailglass/tracking/token_rotation_test.exs` | test | sign/verify | FIRST test for Phoenix.Token rotation; Phoenix docs + RESEARCH §D-33 guide. |

---

## Metadata

**Analog search scope:**
- `/Users/jon/projects/mailglass/lib/**` (Phase 1 + Phase 2 shipped code)
- `/Users/jon/projects/mailglass/deps/swoosh/lib/**` (Swoosh.Adapters.Sandbox + Storage + TestAssertions + Test)
- `/Users/jon/projects/mailglass/deps/oban/lib/oban.ex` (Multi composition surface)
- `/Users/jon/projects/accrue/accrue/lib/accrue/**` (billable, mailer, mailer/default, mailer/test, test/mailer_assertions, workers/mailer, oban/middleware, clock, test/clock, processor, processor/fake)
- `/Users/jon/projects/mailglass/.planning/phases/01-foundation/01-PATTERNS.md` (Phase 1 analog catalog for style conventions)
- `/Users/jon/projects/mailglass/.planning/phases/02-persistence-tenancy/02-PATTERNS.md` (Phase 2 analog catalog)

**Files scanned:** ~40 Elixir source files + 3 phase PATTERNS/CONTEXT/RESEARCH artifacts.

**Pattern extraction date:** 2026-04-22

**Key patterns identified:**
- All controllers/adapters use **behaviour + default-impl + Config selector** (TemplateEngine + SuppressionStore + Adapter all follow this shape).
- All hot paths use **`Telemetry.span/3` wrapping `Repo.transact/1` wrapping `Multi` composition**. Never adapter-in-transaction.
- All error structs use **`defexception` + `@behaviour Mailglass.Error` + `@types [...]` + `__types__/0` + `new/2` formatter + `Jason.Encoder` on `[:type, :message, :context]`**.
- All ETS-owning modules follow **tiny-supervisor + init-and-idle TableOwner GenServer** (D-22). `Swoosh.Adapters.Sandbox.Storage` is the exception (full GenServer + handle_call) because ownership mutation is its primary workload.
- All process-dict helpers pair `put/1` with `with_X/2` restore-on-raise (Tenancy → Clock.Frozen symmetry).
- All `use` macros inject ≤20 lines, set `@before_compile` for discovery, and emit a `__X__/1` reflection callback.
- All optional-dep-gated modules use `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, [...]}` + conditional `defmodule`.
