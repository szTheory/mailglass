defmodule Mailglass.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency (`{:oban, "~> 2.21"}`).

  When Oban is present, `available?/0` returns `true` and callers may safely
  reference `Oban`, `Oban.Worker`, and `Oban.Job`. When absent,
  `Mailglass.Outbound.deliver_later/2` falls back to `Task.Supervisor` with a
  `Logger.warning` emitted at boot (see `Mailglass.Application`).

  Oban integration lands in Phase 3 (Outbound). This gateway is delivered in
  Phase 1 so Config/Telemetry can reference it without forward-reference pain.

  ## Phase 2 addition — TenancyMiddleware (D-33)

  `Mailglass.Oban.TenancyMiddleware` (defined as a sibling module in this
  file, conditionally compiled when `Oban.Worker` is loaded) serializes
  `Mailglass.Tenancy.current/0` into job args on enqueue and restores it via
  `put_current/1` in `perform/1`. Mitigates process-dict-leakage risk across
  background boundaries. The module is absent when Oban is not loaded —
  `mix compile --no-optional-deps --warnings-as-errors` passes cleanly.

  OSS Oban 2.21 has no first-class middleware behaviour (that lives in Oban
  Pro). Mailglass ships the middleware as a plain module exposing `call/2`
  (the shape an adopter using Oban Pro can register directly) PLUS a
  `wrap_perform/2` helper that adopters using OSS Oban invoke inside their
  worker's `perform/1`. Both paths converge on the same
  `Mailglass.Tenancy.with_tenant/2` wrap.

  ## Lint Enforcement (Phase 6)

  The Credo check `NoBareOptionalDepReference` flags direct `Oban.*` calls
  outside this module. All Oban interaction routes through the Outbound
  facade, which consults `available?/0` before dispatching.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Migrations, Oban.Testing]}

  @doc """
  Returns `true` when `:oban` is loaded in the current runtime.

  Backed by `Code.ensure_loaded?/1`, so purge-aware and safe to call from
  compile-time callbacks (e.g. `Application.start/2`).
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)

  @doc """
  Gateway wrapper for `Oban.insert/3` used from `Ecto.Multi` pipelines.

  Returns the original multi unchanged when Oban is not loaded.
  """
  @doc since: "0.1.0"
  @spec insert(Ecto.Multi.t(), atom(), (map() -> term())) :: Ecto.Multi.t()
  def insert(multi, name, job_builder) when is_atom(name) and is_function(job_builder, 1) do
    if available?() do
      Oban.insert(multi, name, job_builder)
    else
      multi
    end
  end

  @doc """
  Gateway wrapper for `Oban.insert_all/1`.
  """
  @doc since: "0.1.0"
  @spec insert_all([term()]) :: term()
  def insert_all(jobs) when is_list(jobs) do
    if available?() do
      Oban.insert_all(jobs)
    else
      {:error, :oban_unavailable}
    end
  end
end

# Conditionally-compiled middleware. The entire `defmodule` is elided when
# `Oban.Worker` is unavailable, so `mix compile --no-optional-deps
# --warnings-as-errors` passes cleanly (the module simply does not exist).
# Callers must check `Code.ensure_loaded?(Mailglass.Oban.TenancyMiddleware)`
# before referencing it — mirrors the Sigra gateway pattern.
#
# The compile guard keys on `Oban.Worker` (which OSS Oban 2.21 exposes)
# rather than `Oban.Middleware` (which only exists in Oban Pro). Both API
# surfaces — middleware `call/2` for Pro users and `wrap_perform/2` for OSS
# users — converge on the same `Mailglass.Tenancy.with_tenant/2` wrap.
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Oban.TenancyMiddleware do
    @moduledoc """
    Serializes `Mailglass.Tenancy.current/0` across Oban job boundaries (D-33).

    ## Enqueue side

    Phase 3 `Mailglass.Outbound` adds a `put_tenant_in_args/2` helper that
    merges `%{"mailglass_tenant_id" => current()}` into job args at enqueue
    time. The serialized value is a plain string — JSON-safe, no coercion.

    ## Perform side

    Two equivalent integration paths — both converge on
    `Mailglass.Tenancy.with_tenant/2`.

    ### OSS Oban (`wrap_perform/2`)

    OSS Oban 2.21 has no middleware behaviour. Adopters wrap their worker's
    `perform/1` body:

        defmodule MyApp.MailerWorker do
          use Oban.Worker

          @impl Oban.Worker
          def perform(job) do
            Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
              # ... worker body; Mailglass.Tenancy.current/0 now returns
              # the tenant stamped at enqueue time.
              :ok
            end)
          end
        end

    ### Oban Pro (`call/2`)

    Oban Pro's `Oban.Middleware` behaviour invokes `call/2`. The shape this
    module exports matches the documented behaviour (`job` + `next/1`
    continuation) so Pro adopters register it directly:

        config :my_app, Oban,
          engine: Oban.Engines.Basic,
          middleware: [Mailglass.Oban.TenancyMiddleware],
          queues: [mailglass: 10]

    ## Contract

    - `job.args["mailglass_tenant_id"]` present and binary → wrap in
      `Mailglass.Tenancy.with_tenant/2`.
    - Key missing or non-binary → pass through unchanged. Lets adopters
      phase in the middleware without breaking existing jobs.
    - If the wrapped body raises, the prior tenant stamp is restored
      before the raise propagates (inherited from
      `Mailglass.Tenancy.with_tenant/2`).
    """

    @doc """
    Wraps `fun` in `Mailglass.Tenancy.with_tenant/2` when `job.args` carries
    a binary `"mailglass_tenant_id"`. Pass-through otherwise.

    This is the OSS-Oban-friendly integration surface — adopters invoke it
    from inside their `perform/1`. `fun` is zero-arity; the job struct is
    available in the closure the caller constructs.
    """
    @doc since: "0.1.0"
    @spec wrap_perform(map(), (-> any())) :: any()
    def wrap_perform(%{args: args}, fun) when is_function(fun, 0) do
      case args do
        %{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id) ->
          Mailglass.Tenancy.with_tenant(tenant_id, fun)

        _ ->
          fun.()
      end
    end

    @doc """
    Oban-Pro-compatible middleware entry point.

    `next/1` is the continuation supplied by Pro's middleware stack;
    receives the job and returns the perform result. For OSS adopters,
    prefer `wrap_perform/2`.
    """
    @doc since: "0.1.0"
    @spec call(map(), (map() -> any())) :: any()
    def call(%{args: args} = job, next) when is_function(next, 1) do
      case args do
        %{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id) ->
          Mailglass.Tenancy.with_tenant(tenant_id, fn -> next.(job) end)

        _ ->
          next.(job)
      end
    end
  end
end
