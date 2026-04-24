defmodule Mailglass.Outbound do
  # Worker + Oban are conditionally compiled — suppress undefined warnings.
  @compile {:no_warn_undefined, [Mailglass.Outbound.Worker, Oban]}

  @moduledoc """
  Public facade for the mailglass send pipeline (TRANS-04, SEND-01).

  All four delivery shapes (sync, async, batch, bang variants) converge
  on the same `%Mailglass.Outbound.Delivery{}` return object. Adopter code
  pattern-matches by struct + status field — never by message strings.

  ## Public verbs

  `deliver/2` is the canonical public name (matches Swoosh + ActionMailer
  familiarity). `send/2` is the internal implementation verb; `deliver/2`
  is a `defdelegate` alias (D-13).

  ## Preflight pipeline (SEND-01, D-18)

  0. `Mailglass.Tenancy.assert_stamped!/0` — precondition (raises)
  1. `Mailglass.Tracking.Guard.assert_safe!/1` — D-38 precondition (raises)
  2. `Mailglass.Suppression.check_before_send/1`
  3. `Mailglass.RateLimiter.check/3` (`:transactional` bypasses)
  4. `Mailglass.Stream.policy_check/1` (no-op seam v0.1)
  5. `Mailglass.Renderer.render/1`
  6. Persist (two Multis separated by adapter call)

  Preconditions (0 + 1) raise on violation. Stages 2-5 return
  `{:error, struct}`; the `with` short-circuits.

  ## Two-Multi sync path (D-20)

  Multi#1 (inside `Repo.multi/1`):
  - `Ecto.Multi.insert(:delivery, Delivery.changeset(attrs))`
  - `Mailglass.Events.append_multi(:event_queued, ...)`

  Adapter call OUTSIDE any transaction.

  Multi#2 (inside `Repo.multi/1`):
  - `Ecto.Multi.update(:delivery, ...)` — applies
    `Projector.update_projections/2` with the dispatched event
  - `Mailglass.Events.append_multi(:event_dispatched, ...)`

  After Multi#2 commits → `Projector.broadcast_delivery_updated/3`.

  **Adapter-call-in-transaction is a hard no** (D-20) — Postgres
  connection-pool starvation under provider latency. Orphan `:queued`
  Delivery rows between Multi#1 and adapter call are reconcilable via
  `Mailglass.Events.Reconciler` (Phase 2 D-19) with age ≥5min.

  ## Return shapes

  - `{:ok, %Delivery{status: :sent}}` — sync success
  - `{:error, %Mailglass.Error{}}` — preflight short-circuit or Multi failure

  ## deliver_many/2 scope (v0.1)

  Async-only. Every message produces an Oban job (or Task.Supervisor spawn
  when Oban absent). Sync-batch fan-out deferred to v0.5.
  `[ASSUMED — Plan 05 Task 4 decision]`

  ## Heterogeneous-tenant batches

  `deliver_many/2` assumes all messages share the same tenant_id. Mixed-tenant
  batches corrupt idempotency key derivation (the hash includes tenant_id).
  Adopters must batch per-tenant. Future enhancement: raise ArgumentError on
  mixed tenants.
  """

  use Boundary,
    deps: [Mailglass],
    exports: [Delivery, Projector, Worker]

  alias Mailglass.{Clock, Events, Message, Renderer, Repo, Suppression, RateLimiter, Stream,
                   Tenancy, Telemetry}
  alias Mailglass.Outbound.{Delivery, Projector}
  alias Mailglass.Tracking

  # =========================================================
  # Public API — sync path
  # =========================================================

  @doc """
  Synchronous hot path. Runs the full preflight pipeline, persists the Delivery
  via two Multis (adapter call between them, OUTSIDE any transaction per D-20),
  and returns `{:ok, %Delivery{status: :sent}}` on success.

  `deliver/2` is the canonical public alias (see below). `send/2` is the
  internal implementation verb.
  """
  @doc since: "0.1.0"
  @spec send(Message.t(), keyword()) :: {:ok, Delivery.t()} | {:error, Mailglass.Error.t()}
  def send(%Message{} = msg, opts \\ []) do
    Telemetry.send_span(metadata_for(msg), fn ->
      do_send(msg, opts)
    end)
  end

  @doc """
  Canonical public verb for synchronous delivery (D-13). Delegates to `send/2`.
  Matches the naming convention from Swoosh and ActionMailer for adopter
  familiarity.
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
  `%Oban.Job{}` (D-14 return-shape lock).
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
  Async batch send (TRANS-04, D-15). v0.1 scope: **async-only** — every
  message in the batch produces an Oban job (or Task.Supervisor spawn
  when Oban absent). Sync-batch fan-out deferred to v0.5.
  `[ASSUMED — Plan 05 Task 4 decision]`

  ## Return shape

  `{:ok, [%Delivery{}]}` always (one row per input message). Each Delivery
  carries its own `:status`:
  - `:queued` — successfully enqueued
  - `:failed` — preflight rejected; `:last_error` carries the specific error

  Batch-level errors (DB unavailable) return `{:error, %Mailglass.Error{}}`.

  ## Replay safety

  `idempotency_key` + partial UNIQUE index make re-running the same batch a
  DB-level no-op. Existing rows are re-fetched via companion SELECT.
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
  delivery — nothing delivery-shaped to raise about, per D-16).
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
    with {:ok, delivery} <- load_delivery(delivery_id),
         {:ok, rendered} <- rehydrate_message(delivery),
         {:ok, dispatch_result} <- call_adapter(rendered, []) do
      case persist_dispatched_multi(delivery, dispatch_result, rendered) do
        {:ok, %{delivery: updated}} ->
          Projector.broadcast_delivery_updated(updated, :dispatched, %{
            tenant_id: updated.tenant_id,
            delivery_id: updated.id
          })

          {:ok, updated}

        {:error, _step, err, _changes} ->
          {:error, to_error(err)}
      end
    else
      {:error, %{__exception__: true} = err} ->
        persist_failed_by_id(delivery_id, err)
        {:error, err}

      other ->
        other
    end
  end

  # =========================================================
  # Internal — sync hot path
  # =========================================================

  defp do_send(%Message{} = msg, opts) do
    # Preflight (stages 0-5) — no DB writes yet
    with :ok <- Tenancy.assert_stamped!(),
         :ok <- Tracking.Guard.assert_safe!(msg),
         :ok <- Suppression.check_before_send(msg),
         :ok <- RateLimiter.check(msg.tenant_id, recipient_domain(msg), msg.stream),
         :ok <- Stream.policy_check(msg),
         {:ok, rendered} <- Renderer.render(msg) do
      rewritten = Tracking.rewrite_if_enabled(rendered)
      do_send_after_preflight(rewritten, opts)
    end
  end

  # Called only after all preflight stages pass. Multi#1 happens here, so we
  # can correctly persist :failed status when the adapter call fails (T-3-05-07).
  defp do_send_after_preflight(%Message{} = rendered, opts) do
    with {:ok, %{delivery: delivery}} <- persist_queued(rendered, opts),
         # I-07: stamp delivery.id into metadata BEFORE adapter sees the message.
         # Fake.deliver records metadata.delivery_id for TestAssertions correlation.
         rendered_with_id = Message.put_metadata(rendered, :delivery_id, delivery.id),
         {:ok, dispatch_result} <- call_adapter_or_persist_failure(delivery, rendered_with_id, opts),
         {:ok, %{delivery: updated}} <-
           persist_dispatched_multi(delivery, dispatch_result, rendered_with_id) do
      Projector.broadcast_delivery_updated(updated, :dispatched, %{
        tenant_id: updated.tenant_id,
        delivery_id: updated.id,
        provider: provider_tag(dispatch_result.provider_response)
      })

      {:ok, updated}
    else
      {:error, %{__exception__: true} = err} ->
        {:error, err}

      {:error, _step, changeset_or_err, _changes} ->
        {:error, to_error(changeset_or_err)}

      other ->
        other
    end
  end

  # Calls the adapter; on failure writes Multi#2 with :failed status (T-3-05-07).
  # Adapter call is OUTSIDE any transaction (D-20).
  defp call_adapter_or_persist_failure(%Delivery{} = delivery, %Message{} = rendered, opts) do
    case call_adapter(rendered, opts) do
      {:ok, _} = ok ->
        ok

      {:error, %{__exception__: true} = err} ->
        persist_failed_by_id(delivery.id, err)
        {:error, err}

      {:error, other} ->
        send_err = to_error(other)
        persist_failed_by_id(delivery.id, send_err)
        {:error, send_err}
    end
  end

  # =========================================================
  # Internal — async path (deliver_later)
  # =========================================================

  defp do_deliver_later(%Message{} = msg, opts) do
    with :ok <- Tenancy.assert_stamped!(),
         :ok <- Tracking.Guard.assert_safe!(msg),
         :ok <- Suppression.check_before_send(msg),
         :ok <- RateLimiter.check(msg.tenant_id, recipient_domain(msg), msg.stream),
         :ok <- Stream.policy_check(msg),
         {:ok, rendered} <- Renderer.render(msg) do
      rewritten = Tracking.rewrite_if_enabled(rendered)
      enqueue_via_async_adapter(rewritten, opts)
    end
  end

  defp enqueue_via_async_adapter(%Message{} = rendered, opts) do
    async_adapter =
      Keyword.get(opts, :async_adapter) ||
        Application.get_env(:mailglass, :async_adapter, :oban)

    cond do
      async_adapter == :task_supervisor ->
        enqueue_task_supervisor(rendered, opts)

      Mailglass.OptionalDeps.Oban.available?() ->
        enqueue_oban(rendered, opts)

      true ->
        enqueue_task_supervisor(rendered, opts)
    end
  end

  defp enqueue_oban(%Message{} = rendered, _opts) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id

    attrs = base_delivery_attrs(rendered, ik)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:delivery, Delivery.changeset(attrs))
      |> Events.append_multi(:event_queued, fn %{delivery: d} ->
           %{
             tenant_id: tenant_id,
             delivery_id: d.id,
             type: :queued,
             occurred_at: Clock.utc_now(),
             idempotency_key: ik,
             normalized_payload: %{}
           }
         end)
      |> Oban.insert(:job, fn %{delivery: d} ->
           Mailglass.Outbound.Worker.new(%{
             "delivery_id" => d.id,
             "mailglass_tenant_id" => tenant_id
           })
         end)
      |> Repo.multi()

    case result do
      {:ok, %{delivery: d}} ->
        {:ok, %{d | status: :queued, last_event_type: :queued}}

      {:error, _step, err, _} ->
        {:error, to_error(err)}
    end
  end

  defp enqueue_task_supervisor(%Message{} = rendered, _opts) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id
    attrs = base_delivery_attrs(rendered, ik)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:delivery, Delivery.changeset(attrs))
      |> Events.append_multi(:event_queued, fn %{delivery: d} ->
           %{
             tenant_id: tenant_id,
             delivery_id: d.id,
             type: :queued,
             occurred_at: Clock.utc_now(),
             idempotency_key: ik,
             normalized_payload: %{}
           }
         end)

    case Repo.multi(multi) do
      {:ok, %{delivery: d}} ->
        # Spawn non-linked task under Mailglass.TaskSupervisor.
        # Tenancy process-dict MUST be re-stamped (not inherited) — D-21.
        Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
          Mailglass.Tenancy.with_tenant(tenant_id, fn ->
            try do
              case dispatch_by_id(d.id) do
                {:ok, _} ->
                  :ok

                {:error, err} ->
                  require Logger

                  Logger.warning(
                    "[mailglass] Task.Supervisor dispatch failed: #{Exception.message(err)}"
                  )
              end
            rescue
              err ->
                require Logger

                Logger.warning(
                  "[mailglass] Task.Supervisor dispatch raised: #{Exception.message(err)}"
                )
            end
          end)
        end)

        {:ok, %{d | status: :queued, last_event_type: :queued}}

      {:error, _step, err, _} ->
        {:error, to_error(err)}
    end
  end

  # =========================================================
  # Internal — batch path (deliver_many)
  # =========================================================

  defp do_deliver_many(messages, _opts) do
    {eligible, failed_preflight} =
      messages
      |> Enum.map(&preflight_single/1)
      |> Enum.split_with(fn
        {:ok, _msg} -> true
        {:error, _err, _msg} -> false
      end)

    eligible_messages = Enum.map(eligible, fn {:ok, msg} -> msg end)

    failed_deliveries =
      Enum.map(failed_preflight, fn {:error, err, msg} ->
        build_failed_delivery(msg, err)
      end)

    case insert_batch(eligible_messages) do
      {:ok, inserted_deliveries} ->
        # I-13: Only re-enqueue :queued rows. On replay, some rows may already
        # be :sent/:failed — do NOT re-enqueue them (duplicate send risk).
        {fresh, _already_settled} =
          Enum.split_with(inserted_deliveries, fn d -> d.status == :queued end)

        enqueue_batch_jobs(fresh)
        {:ok, inserted_deliveries ++ failed_deliveries}

      {:error, _} = err ->
        err
    end
  end

  defp preflight_single(%Message{} = msg) do
    with :ok <- Tracking.Guard.assert_safe!(msg),
         :ok <- Suppression.check_before_send(msg),
         :ok <- RateLimiter.check(msg.tenant_id, recipient_domain(msg), msg.stream),
         :ok <- Stream.policy_check(msg),
         {:ok, rendered} <- Renderer.render(msg) do
      {:ok, Tracking.rewrite_if_enabled(rendered)}
    else
      {:error, err} -> {:error, err, msg}
      {:error, _step, err, _} -> {:error, to_error(err), msg}
    end
  end

  defp insert_batch([]), do: {:ok, []}

  defp insert_batch(messages) when is_list(messages) do
    now = Clock.utc_now()

    rows =
      Enum.map(messages, fn %Message{} = m ->
        ik = compute_idempotency_key(m)
        base_delivery_attrs(m, ik)
        |> Map.put(:id, Ecto.UUID.generate())
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:deliveries, Delivery, rows,
           on_conflict: :nothing,
           conflict_target:
             {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
           returning: true
         )
      |> Ecto.Multi.run(:events, fn repo, %{deliveries: {_count, inserted}} ->
           event_rows =
             Enum.map(inserted, fn d ->
               %{
                 id: Ecto.UUID.generate(),
                 tenant_id: d.tenant_id,
                 delivery_id: d.id,
                 type: :queued,
                 occurred_at: now,
                 idempotency_key: d.idempotency_key,
                 normalized_payload: %{},
                 metadata: %{},
                 needs_reconciliation: false,
                 inserted_at: now
               }
             end)

           {n, _} =
             repo.insert_all(Mailglass.Events.Event, event_rows,
               on_conflict: :nothing,
               conflict_target:
                 {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
               returning: false
             )

           {:ok, n}
         end)
      |> Repo.multi()

    case result do
      {:ok, %{deliveries: {_count, _inserted_rows}}} ->
        # Re-fetch all rows by idempotency_key (ON CONFLICT DO NOTHING doesn't return
        # conflicting rows, so we need a SELECT to get the full result set on replay).
        import Ecto.Query
        idempotency_keys = Enum.map(rows, & &1.idempotency_key) |> Enum.reject(&is_nil/1)

        all_rows =
          if idempotency_keys == [] do
            []
          else
            Repo.all(from(d in Delivery, where: d.idempotency_key in ^idempotency_keys))
          end

        {:ok, all_rows}

      {:error, _step, err, _} ->
        {:error, to_error(err)}
    end
  end

  defp enqueue_batch_jobs(deliveries) when is_list(deliveries) do
    async_adapter = Application.get_env(:mailglass, :async_adapter, :oban)
    use_oban = async_adapter != :task_supervisor and Mailglass.OptionalDeps.Oban.available?()

    if use_oban do
      jobs =
        Enum.map(deliveries, fn %Delivery{id: id, tenant_id: t} ->
          Mailglass.Outbound.Worker.new(%{
            "delivery_id" => id,
            "mailglass_tenant_id" => t
          })
        end)

      _ = Oban.insert_all(jobs)
      :ok
    else
      Enum.each(deliveries, fn %Delivery{id: id, tenant_id: t} ->
        Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
          Mailglass.Tenancy.with_tenant(t, fn ->
            try do
              case dispatch_by_id(id) do
                {:ok, _} ->
                  :ok

                {:error, err} ->
                  require Logger

                  Logger.warning(
                    "[mailglass] Task.Supervisor batch dispatch failed for #{id}: #{Exception.message(err)}"
                  )
              end
            rescue
              err ->
                require Logger

                Logger.warning(
                  "[mailglass] Task.Supervisor batch dispatch raised for #{id}: #{Exception.message(err)}"
                )
            end
          end)
        end)
      end)

      :ok
    end
  end

  defp build_failed_delivery(%Message{} = msg, err) do
    # NOT persisted — synthetic result-list entry for adopter observability.
    # I-17: top-level :status + :last_error fields (I-01 from Task 1).
    %Delivery{
      id: Ecto.UUID.generate(),
      tenant_id: msg.tenant_id,
      mailable: inspect(msg.mailable),
      stream: msg.stream,
      recipient: primary_recipient(msg),
      status: :failed,
      last_event_type: :failed,
      last_error: serialize_error(err),
      last_event_at: Clock.utc_now(),
      metadata: %{}
    }
  end

  # =========================================================
  # Internal — persistence helpers
  # =========================================================

  defp persist_queued(%Message{} = rendered, _opts) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id

    # I-01: Multi#1 writes status: :queued (public API column) AND
    # last_event_type: :queued (ledger projection).
    Telemetry.persist_outbound_multi_span(
      %{step_name: :persist_queued, tenant_id: tenant_id},
      fn ->
        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            :delivery,
            Delivery.changeset(%{
              tenant_id: tenant_id,
              mailable: inspect(rendered.mailable),
              stream: rendered.stream,
              recipient: primary_recipient(rendered),
              recipient_domain: recipient_domain(rendered),
              status: :queued,
              last_event_type: :queued,
              last_event_at: Clock.utc_now(),
              metadata: rendered.metadata || %{},
              idempotency_key: ik
            })
          )
          |> Events.append_multi(:event_queued, fn %{delivery: d} ->
               %{
                 tenant_id: tenant_id,
                 delivery_id: d.id,
                 type: :queued,
                 occurred_at: Clock.utc_now(),
                 idempotency_key: ik,
                 normalized_payload: %{}
               }
             end)
        )
      end
    )
  end

  defp call_adapter(%Message{} = rendered, opts) do
    {adapter_mod, adapter_opts} = resolve_adapter(opts)

    Telemetry.dispatch_span(
      %{
        tenant_id: rendered.tenant_id,
        mailable: rendered.mailable,
        provider: adapter_mod
      },
      fn ->
        adapter_mod.deliver(rendered, adapter_opts)
      end
    )
  end

  defp persist_dispatched_multi(
         %Delivery{} = delivery,
         %{message_id: pmid, provider_response: _resp},
         _rendered
       ) do
    event_occurred_at = Clock.utc_now()

    event_attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at,
      normalized_payload: %{provider_message_id: pmid}
    }

    # Build a stubbed Event to feed update_projections/2 (Phase 2 sig takes an Event struct).
    event_for_projection = %Mailglass.Events.Event{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at
    }

    # I-01: Multi#2 sets BOTH :status (public API snapshot) AND
    # :last_event_type (projection). :status is what adopters
    # pattern-match on per ROADMAP success criterion 1.
    Telemetry.persist_outbound_multi_span(
      %{step_name: :persist_dispatched, tenant_id: delivery.tenant_id},
      fn ->
        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.update(
            :delivery,
            Projector.update_projections(delivery, event_for_projection)
            |> Ecto.Changeset.change(%{
              status: :sent,
              last_event_type: :dispatched,
              provider_message_id: pmid,
              dispatched_at: event_occurred_at
            })
          )
          |> Events.append_multi(:event_dispatched, event_attrs)
        )
      end
    )
  end

  defp persist_failed_by_id(delivery_id, %{__exception__: true} = err) do
    case load_delivery(delivery_id) do
      {:ok, delivery} ->
        event_occurred_at = Clock.utc_now()

        event = %Mailglass.Events.Event{
          tenant_id: delivery.tenant_id,
          delivery_id: delivery.id,
          type: :failed,
          occurred_at: event_occurred_at
        }

        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.update(
            :delivery,
            Projector.update_projections(delivery, event)
            |> Ecto.Changeset.change(%{
              status: :failed,
              last_error: serialize_error(err)
            })
          )
          |> Events.append_multi(:event_failed, %{
               tenant_id: delivery.tenant_id,
               delivery_id: delivery.id,
               type: :failed,
               occurred_at: event_occurred_at,
               normalized_payload: %{error_type: err.__struct__}
             })
        )

      {:error, _} ->
        # Delivery not found — cannot persist failure, log and move on
        require Logger
        Logger.warning("[mailglass] persist_failed_by_id: delivery #{delivery_id} not found")
        :ok
    end
  end

  # =========================================================
  # Internal — error helpers
  # =========================================================

  # I-11: Serialize any %Mailglass.Error{} (or generic Exception) into a
  # plain map suitable for the :last_error :map column. Shape: %{type: atom,
  # message: binary, module: binary}. Adopters pattern-match on :type, never
  # on :message string (D-07 contract).
  defp serialize_error(%{__exception__: true, __struct__: mod} = err) do
    base = %{module: Atom.to_string(mod), message: Exception.message(err)}

    case err do
      %{type: t} when is_atom(t) -> Map.put(base, :type, t)
      _ -> base
    end
  end

  defp to_error(%{__exception__: true} = e), do: e

  defp to_error(%Ecto.Changeset{} = cs),
    do:
      Mailglass.SendError.new(:adapter_failure,
        context: %{reason_class: :persistence_failed, changeset: inspect(cs.errors)}
      )

  defp to_error(other),
    do:
      Mailglass.SendError.new(:adapter_failure, context: %{wrapped: inspect(other)})

  # =========================================================
  # Internal — message helpers
  # =========================================================

  defp load_delivery(id) do
    case Repo.get(Delivery, id) do
      nil ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{reason_class: :delivery_not_found}
         )}

      %Delivery{} = d ->
        {:ok, d}
    end
  end

  defp rehydrate_message(%Delivery{} = delivery) do
    # In the async path, the worker loads delivery by id. The rendered bytes
    # are stored in delivery.metadata (rendered_html, rendered_text, subject)
    # by base_delivery_attrs/2 at enqueue time. Reconstruct a minimal
    # %Message{} sufficient for the adapter call.
    #
    # I-11: Use String.to_existing_atom/1 guarded by Code.ensure_loaded/1.
    # If the mailable module was unloaded since dispatch, fail cleanly.
    case delivery.mailable do
      nil ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             reason_class: :mailable_unresolvable,
             delivery_id: delivery.id,
             why: :nil_mailable
           }
         )}

      mod_str when is_binary(mod_str) ->
        # ME-03: Both resolution paths use String.to_existing_atom/1.
        # String.to_atom/1 on a DB-sourced value is an atom-table exhaustion vector (T-3-12-01).
        # Primary path: try "Elixir." <> mod_str (the canonical Elixir module atom form).
        # Fallback path: try mod_str bare (for modules stored without the Elixir. prefix).
        try do
          mod_atom = String.to_existing_atom("Elixir." <> mod_str)

          if Code.ensure_loaded?(mod_atom) do
            {:ok, build_rehydrated_message(delivery, mod_atom)}
          else
            # Atom exists in atom table but module not loaded — try bare mod_str path.
            try do
              mod = String.to_existing_atom(mod_str)
              {:ok, build_rehydrated_message(delivery, mod)}
            rescue
              ArgumentError ->
                {:error,
                 Mailglass.SendError.new(:adapter_failure,
                   context: %{
                     reason_class: :mailable_unresolvable,
                     delivery_id: delivery.id,
                     mailable: mod_str,
                     why: :module_not_loaded
                   }
                 )}
            end
          end
        rescue
          ArgumentError ->
            # "Elixir." <> mod_str atom not in atom table — try the bare mod_str path
            # (e.g. "Mailglass.FakeFixtures.TestMailer" stored without Elixir. prefix).
            try do
              mod = String.to_existing_atom(mod_str)
              {:ok, build_rehydrated_message(delivery, mod)}
            rescue
              ArgumentError ->
                {:error,
                 Mailglass.SendError.new(:adapter_failure,
                   context: %{
                     reason_class: :mailable_unresolvable,
                     delivery_id: delivery.id,
                     mailable: mod_str,
                     why: :atom_not_found
                   }
                 )}
            end
        end
    end
  end

  # Reconstruct a minimal %Message{} from persisted delivery metadata.
  # Extracted to avoid duplicating Swoosh.Email assembly across both
  # rehydration paths (ME-03 restructure).
  defp build_rehydrated_message(%Delivery{} = delivery, mod_atom) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(delivery.recipient)
      |> Swoosh.Email.subject(get_in(delivery.metadata, ["subject"]) || "")
      |> Swoosh.Email.html_body(get_in(delivery.metadata, ["rendered_html"]))
      |> Swoosh.Email.text_body(get_in(delivery.metadata, ["rendered_text"]))

    %Message{
      swoosh_email: email,
      mailable: mod_atom,
      tenant_id: delivery.tenant_id,
      stream: delivery.stream,
      metadata: delivery.metadata || %{}
    }
  end

  defp resolve_adapter(opts) do
    case Keyword.fetch(opts, :adapter) do
      {:ok, {mod, kw}} ->
        {mod, kw}

      {:ok, mod} when is_atom(mod) ->
        {mod, []}

      :error ->
        case Application.get_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []}) do
          {mod, kw} -> {mod, kw}
          mod when is_atom(mod) -> {mod, []}
        end
    end
  end

  defp metadata_for(%Message{} = msg) do
    %{tenant_id: msg.tenant_id, mailable: msg.mailable, stream: msg.stream}
  end

  defp primary_recipient(%Message{swoosh_email: %Swoosh.Email{to: [{_, addr} | _]}}),
    do: String.downcase(addr)

  defp primary_recipient(_), do: ""

  defp recipient_domain(msg) do
    case String.split(primary_recipient(msg), "@", parts: 2) do
      [_, d] -> String.downcase(d)
      _ -> ""
    end
  end

  defp compute_idempotency_key(%Message{} = msg) do
    tenant_id = msg.tenant_id || ""
    mailable = inspect(msg.mailable)
    recipient = primary_recipient(msg)

    content_hash =
      :crypto.hash(:sha256, [
        msg.swoosh_email.text_body || "",
        msg.swoosh_email.html_body || ""
      ])
      |> Base.encode16(case: :lower)

    :crypto.hash(:sha256, [tenant_id, "|", mailable, "|", recipient, "|", content_hash])
    |> Base.encode16(case: :lower)
  end

  defp base_delivery_attrs(%Message{} = rendered, ik) do
    %{
      tenant_id: rendered.tenant_id,
      mailable: inspect(rendered.mailable),
      stream: rendered.stream,
      recipient: primary_recipient(rendered),
      recipient_domain: recipient_domain(rendered),
      status: :queued,
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      metadata:
        Map.merge(rendered.metadata || %{}, %{
          rendered_html: rendered.swoosh_email.html_body,
          rendered_text: rendered.swoosh_email.text_body,
          subject: rendered.swoosh_email.subject
        }),
      idempotency_key: ik
    }
  end

  # ME-05: Safe provider tag extraction from adapter dispatch result.
  # provider_response is adapter-defined (term()) — must not assume map shape.
  # Custom adapters may return tuples, atoms, strings, or nil in provider_response.
  # Map.get/3 on a non-map term raises BadMapError (T-3-12-03).
  defp provider_tag(%{adapter: a}), do: inspect(a)
  defp provider_tag(_), do: "unknown"
end
