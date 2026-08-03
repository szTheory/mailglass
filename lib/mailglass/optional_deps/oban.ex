defmodule Mailglass.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency (`{:oban, "~> 2.21"}`).

  `available?/0` is dependency detection only: when Oban is present, it returns
  `true` and this gateway may safely reference `Oban`, `Oban.Worker`, and
  `Oban.Job`. It does not select an outbound adapter or authorize substitution.
  Selected `:oban` outbound work uses `ready?/1` and `insert/4` to fail-closed
  with typed errors when the dependency, configured instance, canonical queue,
  or transactional job insertion is unavailable.

  Oban integration lands in  (Outbound). This gateway is delivered in
   so Config/Telemetry can reference it without forward-reference pain.

  ##  addition — TenancyMiddleware

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

  ## Lint Enforcement

  The Credo check `NoBareOptionalDepReference` flags direct `Oban.*` calls
  outside this module. All Oban interaction routes through the Outbound
  facade, which uses this gateway's canonical readiness and insertion seams.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Migrations, Oban.Testing]}

  @doc """
  Returns `true` when `:oban` is loaded in the current runtime for dependency
  detection. It is not a readiness result or an outbound fallback decision.

  Backed by `Code.ensure_loaded?/1`, so purge-aware and safe to call from
  compile-time callbacks (e.g. `Application.start/2`).
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)

  @doc """
  Confirms canonical readiness: the configured default Oban instance can accept
  Mailglass's canonical worker queue. This is deliberately a producer-readiness
  check; successful `insert/4` remains the transactional proof of job creation.
  """
  @spec ready?(atom()) :: :ok | {:error, :dependency_unavailable | :instance_unavailable | :canonical_queue_unavailable}
  def ready?(canonical_queue) when is_atom(canonical_queue) do
    cond do
      not available?() ->
        {:error, :dependency_unavailable}

      true ->
        case configured_instance() do
          {:ok, config} when is_map(config) ->
            if canonical_queue_configured?(config, canonical_queue),
              do: :ok,
              else: {:error, :canonical_queue_unavailable}

          {:error, :instance_unavailable} ->
            {:error, :instance_unavailable}
        end
    end
  end

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
  Gateway wrapper for the prefix-aware four-argument Oban Multi variant.

  The caller supplies the same step options used by Mailglass persistence so
  the Oban job is inserted in the configured schema inside the active Multi.
  If Oban is unavailable, this adds a failed transaction step rather than
  returning an unchanged Multi; selected durable work therefore fails closed.
  """
  @doc since: "2.4.0"
  @spec insert(Ecto.Multi.t(), atom(), (map() -> term()), keyword()) :: Ecto.Multi.t()
  def insert(multi, name, job_builder, opts)
      when is_atom(name) and is_function(job_builder, 1) and is_list(opts) do
    if available?() do
      Oban.insert(multi, name, job_builder, opts)
    else
      Ecto.Multi.error(multi, name, :dependency_unavailable)
    end
  end

  defp configured_instance do
    try do
      {:ok, Oban.config(Oban)}
    rescue
      _ -> {:error, :instance_unavailable}
    catch
      :exit, _ -> {:error, :instance_unavailable}
    end
  end

  defp canonical_queue_configured?(config, canonical_queue) do
    expected = Atom.to_string(canonical_queue)

    config
    |> config_queues()
    |> Enum.any?(fn {queue, _opts} -> normalize_queue_name(queue) == expected end)
  end

  defp config_queues(config) when is_list(config), do: Keyword.get(config, :queues, [])
  defp config_queues(%{queues: queues}) when is_list(queues), do: queues
  defp config_queues(_), do: []

  defp normalize_queue_name(queue) when is_atom(queue), do: Atom.to_string(queue)
  defp normalize_queue_name(queue) when is_binary(queue), do: queue
  defp normalize_queue_name(_), do: nil

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
    Serializes `Mailglass.Tenancy.current/0` across Oban job boundaries.

    ## Enqueue side

     `Mailglass.Outbound` adds a `put_tenant_in_args/2` helper that
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
          queues: [mailglass_outbound: 10]

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
