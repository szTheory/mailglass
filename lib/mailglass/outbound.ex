defmodule Mailglass.Outbound do
  # Worker is conditionally compiled — suppress undefined warnings.
  @compile {:no_warn_undefined, [Mailglass.Outbound.Worker]}

  @moduledoc """
  Public facade for the mailglass send pipeline.

  All four delivery shapes (sync, async, batch, bang variants) converge
  on the same `%Mailglass.Outbound.Delivery{}` return object. Adopter code
  pattern-matches by struct + status field — never by message strings.

  ## Public verbs

  `deliver/2` is the canonical public name (matches Swoosh + ActionMailer
  familiarity). `send/2` is the internal implementation verb and a retained
  compatibility bridge; `deliver/2` is the stable-lane `defdelegate` alias
  for synchronous sends.

  ## Preflight pipeline

  0. `Mailglass.Tenancy.assert_stamped!/0` — precondition (raises)
  1. `Mailglass.Tracking.Guard.assert_safe!/1` —  precondition (raises)
  2. `Mailglass.Suppression.check_before_send/1`
  3. `Mailglass.RateLimiter.check/3` (`:transactional` bypasses)
  4. `Mailglass.Stream.policy_check/1` (no-op seam v0.1)
  5. `Mailglass.Renderer.render/1`
  6. Persist (two Multis separated by adapter call)

  Preconditions (0 + 1) raise on violation. Stages 2-5 return
  `{:error, struct}`; the `with` short-circuits.

  ## Two-Multi sync path

  Multi#1 (inside `Repo.multi/1`):
  - `Ecto.Multi.insert(:delivery, Delivery.changeset(attrs))`
  - `Mailglass.Events.append_multi(:event_queued, ...)`

  Provider adapter delivery runs outside the database transaction to avoid pool starvation and lock amplification.

  Multi#2 (inside `Repo.multi/1`):
  - `Ecto.Multi.update(:delivery, ...)` — applies
    `Projector.update_projections/2` with the dispatched event
  - `Mailglass.Events.append_multi(:event_dispatched, ...)`

  After Multi#2 commits → `Projector.broadcast_delivery_updated/3`.

  **Adapter-call-in-transaction is a hard no** — Postgres
  connection-pool starvation under provider latency. Orphan `:queued`
  Delivery rows between Multi#1 and adapter call are reconcilable via
  `Mailglass.Events.Reconciler` with age >= 5min.

  ## Return shapes

  - `{:ok, %Delivery{status: :sent}}` — sync success
  - `{:error, %Mailglass.Error{}}` — preflight short-circuit or Multi failure

  ## deliver_many/2 scope (v0.1)

  Async-only. Every message produces an Oban job (or Task.Supervisor spawn
  when Oban absent). Sync-batch fan-out deferred to v0.5.
  ## Heterogeneous-tenant batches

  `deliver_many/2` assumes all messages share the same tenant_id. Mixed-tenant
  batches corrupt idempotency key derivation (the hash includes tenant_id).
  Adopters must batch per-tenant. Future enhancement: raise ArgumentError on
  mixed tenants.
  """

  # Worker is conditionally compiled — only export it when Oban is loaded.
  # Keeps `mix compile --no-optional-deps --warnings-as-errors` clean.
  @oban_exports if Code.ensure_loaded?(Oban.Worker), do: [Worker], else: []

  use Boundary,
    deps: [Mailglass],
    exports: [Delivery, Projector] ++ @oban_exports

  alias Mailglass.{
    Message,
    Tenancy,
    Telemetry
  }

  alias Mailglass.Outbound.{Delivery, Dispatch, Persistence, Preflight, Projector, Routes}
  import Kernel, except: [send: 2]

  # =========================================================
  # Public API — sync path
  # =========================================================

  @doc """
  Synchronous hot path. Runs the full preflight pipeline, persists the Delivery
  via two Multis (adapter call between them, outside any transaction),
  and returns `{:ok, %Delivery{status: :sent}}` on success.

  `deliver/2` is the canonical public alias (see below). `send/2` remains as a
  legacy compatibility bridge so existing callers can migrate without a runtime
  break, but new adopter code should call `deliver/2`.
  """
  @doc since: "0.1.0"
  @spec send(Message.t() | Swoosh.Email.t(), keyword()) ::
          {:ok, Delivery.t()} | {:error, Mailglass.Error.t()}
  def send(msg, opts \\ [])

  def send(%Message{} = msg, opts) do
    Telemetry.send_span(metadata_for(msg), fn ->
      do_send(msg, opts)
    end)
  end

  def send(%Swoosh.Email{} = email, opts) do
    msg = Message.build(email, tenant_id: Tenancy.current())
    send(msg, opts)
  end

  @doc """
  Canonical public verb for synchronous delivery. Delegates to `send/2`.
  Matches the naming convention from Swoosh and ActionMailer for adopter
  familiarity and is the stable-lane front door documented by the `1.x`
  compatibility policy.
  """
  @doc since: "0.1.0"
  defdelegate deliver(msg, opts \\ []), to: __MODULE__, as: :send

  @doc """
  Bang variant — raises the error struct directly on failure.
  """
  @doc since: "0.1.0"
  @spec deliver!(Message.t(), keyword()) :: Delivery.t()
  def deliver!(%Message{} = msg, opts \\ []) do
    case deliver(msg, opts) do
      {:ok, %Delivery{} = d} ->
        d

      {:error, %{__exception__: true} = err} ->
        raise err

      {:error, other} ->
        raise Mailglass.SendError.new(:adapter_failure,
                context: %{wrapped: inspect(other)}
              )
    end
  end

  # =========================================================
  # Public API — async path (Task 3)
  # =========================================================

  @doc """
  Async delivery. Runs preflight pipeline, persists the Delivery, and enqueues
  an Oban job (or spawns a Task.Supervisor task when Oban is absent).
  Always returns `{:ok, %Delivery{status: :queued}}` on success — never an
  `%Oban.Job{}` ( return-shape lock).
  """
  @doc since: "0.1.0"
  @spec deliver_later(Message.t(), keyword()) ::
          {:ok, Delivery.t()} | {:error, Mailglass.Error.t()}
  def deliver_later(%Message{} = msg, opts \\ []) do
    Telemetry.send_span(metadata_for(msg), fn ->
      do_deliver_later(msg, opts)
    end)
  end

  # =========================================================
  # Public API — batch path (Task 4)
  # =========================================================

  @doc """
  Async batch send. v0.1 scope: **async-only** — every
  message in the batch produces an Oban job (or Task.Supervisor spawn
  when Oban absent). Sync-batch fan-out deferred to v0.5.

  ## Return shape

  `{:ok, [%Delivery{}]}` always (one row per input message). Each Delivery
  carries its own `:status`:
  - `:queued` — successfully enqueued
  - `:failed` — preflight rejected; `:last_error` carries the specific error

  Batch-level errors (DB unavailable) return `{:error, %Mailglass.Error{}}`.

  ## Replay safety

  Idempotency keys make duplicate dispatch attempts a database-level no-op.
  Existing rows are re-fetched via companion SELECT.
  """
  @doc since: "0.1.0"
  @spec deliver_many([Message.t()], keyword()) ::
          {:ok, [Delivery.t()]} | {:error, Mailglass.Error.t()}
  def deliver_many([], _opts), do: {:ok, []}

  def deliver_many(messages, opts) when is_list(messages) do
    Telemetry.send_span(%{batch_size: length(messages)}, fn ->
      case Tenancy.assert_stamped!() do
        :ok -> do_deliver_many(messages, opts)
      end
    end)
  end

  @doc """
  Bang variant of `deliver_many/2`. Raises `%Mailglass.Error.BatchFailed{}`
  when any Delivery has `status: :failed`.

  `deliver_later!/2` is deliberately NOT provided (enqueue isn't a
  delivery — nothing delivery-shaped to raise about.
  """
  @doc since: "0.1.0"
  @spec deliver_many!([Message.t()], keyword()) :: [Delivery.t()]
  def deliver_many!(messages, opts \\ []) do
    {:ok, deliveries} = deliver_many(messages, opts)

    failures = Enum.filter(deliveries, fn d -> d.status == :failed end)

    cond do
      failures == [] ->
        deliveries

      length(failures) == length(deliveries) ->
        raise Mailglass.Error.BatchFailed.new(:all_failed,
                context: %{count: length(deliveries)},
                failures: failures
              )

      true ->
        raise Mailglass.Error.BatchFailed.new(:partial_failure,
                context: %{count: length(deliveries), failed_count: length(failures)},
                failures: failures
              )
    end
  end

  # =========================================================
  # Public helper — called by Outbound.Worker (Task 3)
  # =========================================================

  @doc """
  Hydrates a Delivery by id, calls the adapter OUTSIDE any transaction, and
  writes Multi#2. Called by `Mailglass.Outbound.Worker.perform/1` and by the
  `Task.Supervisor` fallback in `enqueue_task_supervisor/2`.

  Declared public so the Worker can call it from outside this module.
  """
  @doc since: "0.1.0"
  @spec dispatch_by_id(binary()) ::
          {:ok, Delivery.t()} | {:error, Mailglass.Error.t()}
  def dispatch_by_id(delivery_id) when is_binary(delivery_id) do
    with {:ok, delivery} <- Persistence.fetch_delivery(delivery_id),
         {:ok, rendered} <- Persistence.rehydrate_message(delivery),
         prepared = Message.put_metadata(rendered, :delivery_id, delivery.id),
         {:ok, adapter} <- Routes.resolve_persisted(delivery.adapter_ref),
         {:ok, dispatch_result} <- Dispatch.call_adapter(prepared, adapter) do
      case Persistence.persist_dispatched(delivery, dispatch_result) do
        {:ok, %{delivery: updated}} ->
          Projector.broadcast_delivery_updated(updated, :dispatched, %{
            tenant_id: updated.tenant_id,
            delivery_id: updated.id
          })

          {:ok, updated}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, %{__exception__: true} = err} ->
        Persistence.persist_failed_by_id(delivery_id, err)
        {:error, err}

      other ->
        other
    end
  end

  # =========================================================
  # Internal — sync hot path
  # =========================================================

  defp do_send(%Message{} = msg, opts) do
    with {:ok, rendered} <- Preflight.run(msg) do
      do_send_after_preflight(rendered, opts)
    end
  end

  # Called only after all preflight stages pass. Multi#1 happens here, so we
  # can correctly persist :failed status when the adapter call fails (T-3-05-07).
  defp do_send_after_preflight(%Message{} = rendered, opts) do
    with {:ok, route} <- Routes.resolve_sync(rendered, opts),
         {:ok, %{delivery: delivery}} <- Persistence.persist_queued(rendered, route.adapter_ref),
         {:ok, dispatch_result} <-
           Dispatch.call_adapter_or_persist_failure(delivery, rendered, route.adapter),
         {:ok, %{delivery: updated}} <-
           Persistence.persist_dispatched(delivery, dispatch_result) do
      Projector.broadcast_delivery_updated(updated, :dispatched, %{
        tenant_id: updated.tenant_id,
        delivery_id: updated.id,
        provider: provider_tag(dispatch_result.provider_response)
      })

      {:ok, updated}
    else
      {:error, %{__exception__: true} = err} ->
        {:error, err}

      other ->
        other
    end
  end

  # =========================================================
  # Internal — async path (deliver_later)
  # =========================================================

  defp do_deliver_later(%Message{} = msg, opts) do
    with {:ok, prepared} <- Preflight.run(msg),
         {:ok, adapter_ref} <- Routes.resolve_async(prepared, opts) do
      enqueue_via_async_adapter(prepared, adapter_ref, opts)
    end
  end

  defp enqueue_via_async_adapter(%Message{} = rendered, adapter_ref, opts) do
    case Dispatch.async_mode(opts) do
      :oban ->
        Persistence.enqueue_oban(rendered, adapter_ref)

      :task_supervisor ->
        with {:ok, delivery} <- Persistence.persist_task_queued(rendered, adapter_ref) do
          Dispatch.enqueue_one(delivery, &dispatch_by_id/1)
        end
    end
  end

  # =========================================================
  # Internal — batch path (deliver_many)
  # =========================================================

  defp do_deliver_many(messages, opts) do
    {eligible, failed_preflight} =
      messages
      |> Preflight.run_many()
      |> Enum.split_with(fn
        {:ok, _index, _msg} -> true
        {:error, _index, _err, _msg} -> false
      end)

    eligible_messages = Enum.map(eligible, fn {:ok, index, msg} -> {index, msg} end)

    {routable, failed_routes} =
      eligible_messages
      |> Enum.map(fn {index, %Message{} = msg} ->
        case Routes.resolve_async(msg, opts) do
          {:ok, adapter_ref} -> {:ok, index, {msg, adapter_ref}}
          {:error, err} -> {:error, index, err, msg}
        end
      end)
      |> Enum.split_with(fn
        {:ok, _index, _route} -> true
        {:error, _index, _err, _msg} -> false
      end)

    failed_deliveries =
      Enum.map(failed_preflight ++ failed_routes, fn {:error, index, err, msg} ->
        {index, Persistence.build_failed_delivery(msg, err)}
      end)

    routes = Enum.map(routable, fn {:ok, _index, route} -> route end)
    route_indexes = Enum.map(routable, fn {:ok, index, _route} -> index end)

    case Persistence.insert_batch(routes, Dispatch.async_mode(opts)) do
      {:ok, inserted_deliveries, :oban} ->
        {:ok, restore_batch_order(route_indexes, inserted_deliveries, failed_deliveries)}

      {:ok, inserted_deliveries, :task_supervisor} ->
        # I-13: Only re-enqueue :queued rows. On replay, some rows may already
        # be :sent/:failed — do NOT re-enqueue them (duplicate send risk).
        {fresh, _already_settled} =
          Enum.split_with(inserted_deliveries, fn d -> d.status == :queued end)

        with {:ok, dispatch_updates} <- Dispatch.enqueue_many(fresh, &dispatch_by_id/1) do
          deliveries =
            Enum.map(inserted_deliveries, fn delivery ->
              Map.get(dispatch_updates, delivery.id, delivery)
            end)

          {:ok, restore_batch_order(route_indexes, deliveries, failed_deliveries)}
        end

      {:error, _} = err ->
        err
    end
  end

  defp restore_batch_order(route_indexes, deliveries, failed_deliveries) do
    route_indexes
    |> Enum.zip(deliveries)
    |> Kernel.++(failed_deliveries)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  defp metadata_for(%Message{} = msg) do
    %{tenant_id: msg.tenant_id, mailable: msg.mailable, stream: msg.stream}
  end

  # ME-05: Safe provider tag extraction from adapter dispatch result.
  # provider_response is adapter-defined (term()) — must not assume map shape.
  # Custom adapters may return tuples, atoms, strings, or nil in provider_response.
  # Map.get/3 on a non-map term raises BadMapError (T-3-12-03).
  defp provider_tag(%{adapter: a}), do: inspect(a)
  defp provider_tag(_), do: "unknown"
end
