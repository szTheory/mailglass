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
    Clock,
    Compliance,
    Config,
    Events,
    Message,
    Renderer,
    Repo,
    Suppression,
    RateLimiter,
    Stream,
    Tenancy,
    Telemetry
  }

  alias Mailglass.Outbound.{Delivery, Envelope, Payload, Preflight, Projector}
  alias Mailglass.Tracking

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
      do_deliver_many(messages, opts)
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
    with {:ok, delivery} <- load_delivery(delivery_id),
         {:ok, rendered} <- rehydrate_message(delivery),
         prepared = Message.put_metadata(rendered, :delivery_id, delivery.id),
         {:ok, adapter} <- resolve_persisted_adapter(delivery.adapter_ref),
         {:ok, dispatch_result} <- call_adapter(prepared, adapter) do
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
    with {:ok, normalized} <- Preflight.run(msg),
         {:ok, rendered} <- Renderer.render(normalized),
         :ok <- Preflight.validate_rendered_body(normalized, rendered),
         :ok <- Tracking.Guard.assert_safe!(normalized),
         :ok <- Suppression.check_before_send(normalized),
         :ok <- RateLimiter.check(normalized),
         :ok <- Stream.policy_check(normalized) do
      do_send_after_preflight(prepare_outbound_message(rendered), opts)
    end
  end

  # Called only after all preflight stages pass. Multi#1 happens here, so we
  # can correctly persist :failed status when the adapter call fails (T-3-05-07).
  defp do_send_after_preflight(%Message{} = rendered, opts) do
    with {:ok, route} <- resolve_sync_route(rendered, opts),
         {:ok, %{delivery: delivery}} <- persist_queued(rendered, route.adapter_ref),
         {:ok, dispatch_result} <-
           call_adapter_or_persist_failure(delivery, rendered, route.adapter),
         {:ok, %{delivery: updated}} <-
           persist_dispatched_multi(delivery, dispatch_result, rendered) do
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
  # Adapter call is outside any transaction.
  defp call_adapter_or_persist_failure(%Delivery{} = delivery, %Message{} = rendered, adapter) do
    case call_adapter(rendered, adapter) do
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
    with {:ok, normalized} <- Preflight.run(msg),
         {:ok, rendered} <- Renderer.render(normalized),
         :ok <- Preflight.validate_rendered_body(normalized, rendered),
         :ok <- Tracking.Guard.assert_safe!(normalized),
         :ok <- Suppression.check_before_send(normalized),
         :ok <- RateLimiter.check(normalized),
         :ok <- Stream.policy_check(normalized),
         prepared = prepare_outbound_message(rendered),
         {:ok, adapter_ref} <- resolve_async_adapter_ref(prepared, opts) do
      enqueue_via_async_adapter(prepared, adapter_ref, opts)
    end
  end

  defp enqueue_via_async_adapter(%Message{} = rendered, adapter_ref, opts) do
    async_adapter =
      Keyword.get(opts, :async_adapter) ||
        Application.get_env(:mailglass, :async_adapter, :oban)

    cond do
      async_adapter == :task_supervisor ->
        enqueue_task_supervisor(rendered, adapter_ref, opts)

      Mailglass.OptionalDeps.Oban.available?() ->
        enqueue_oban(rendered, adapter_ref, opts)

      true ->
        enqueue_task_supervisor(rendered, adapter_ref, opts)
    end
  end

  defp enqueue_oban(%Message{} = rendered, adapter_ref, _opts) do
    with {:ok, envelope} <- Envelope.dump(rendered, adapter_ref: adapter_ref) do
      enqueue_durable_oban(rendered, adapter_ref, envelope)
    end
  end

  # The only durable enqueue boundary: all public async Oban paths must enter
  # after their message is fully prepared, routed, and serialized.
  defp enqueue_durable_oban(%Message{} = rendered, adapter_ref, envelope) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id
    delivery_id = delivery_id!(rendered)
    attrs = base_delivery_attrs(rendered, ik, adapter_ref)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :delivery,
        Delivery.changeset(%Delivery{id: delivery_id}, attrs),
        Repo.multi_opts()
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
      |> Ecto.Multi.insert(
        :payload,
        fn %{delivery: d} -> Payload.from_envelope(tenant_id, d.id, envelope) end,
        Repo.multi_opts()
      )
      |> Mailglass.OptionalDeps.Oban.insert(
        :job,
        fn %{delivery: d} ->
          Mailglass.Outbound.Worker.new(%{
            "delivery_id" => d.id,
            "mailglass_tenant_id" => tenant_id
          })
        end,
        Repo.multi_opts()
      )

    result = run_durable_multi(multi)

    case result do
      {:ok, %{delivery: d, event_queued: _event, payload: _payload, job: _job}} ->
        {:ok, %{d | status: :queued, last_event_type: :queued}}

      {:error, _step, err, _} ->
        {:error, to_error(err)}
    end
  end

  defp run_durable_multi(multi) do
    Repo.multi(multi)
  rescue
    err in [Ecto.ConstraintError, Postgrex.Error] ->
      {:error, :transaction, err, %{}}
  end

  defp enqueue_task_supervisor(%Message{} = rendered, adapter_ref, _opts) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id
    delivery_id = delivery_id!(rendered)
    attrs = base_delivery_attrs(rendered, ik, adapter_ref)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :delivery,
        Delivery.changeset(%Delivery{id: delivery_id}, attrs),
        Repo.multi_opts()
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

    case Repo.multi(multi) do
      {:ok, %{delivery: d}} ->
        # AsyncAdapter dispatch (-11). TaskSupervisor impl is prod default;
        # Inline impl is test default. Tenancy re-stamp inside the closure works
        # for both paths (-15) — Inline runs sync under caller, TaskSupervisor
        # runs in fresh process; with_tenant/2 stamps the executing process
        # either way.
        Mailglass.Outbound.AsyncAdapter.dispatch(
          fn ->
            Mailglass.Tenancy.with_tenant(tenant_id, fn ->
              try do
                case dispatch_prepared(d, rendered) do
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
          end,
          []
        )

        {:ok, %{d | status: :queued, last_event_type: :queued}}

      {:error, _step, err, _} ->
        {:error, to_error(err)}
    end
  end

  # =========================================================
  # Internal — batch path (deliver_many)
  # =========================================================

  defp do_deliver_many(messages, opts) do
    # Each input owns a separate persistence boundary. Enum.map retains input
    # positions while allowing an individual serialization, routing, or job
    # failure to become that item's public failed result.
    {:ok, Enum.map(messages, &enqueue_batch_item(&1, opts))}
  end

  defp enqueue_batch_item(%Message{} = message, opts) do
    with {:ok, prepared} <- preflight_single(message),
         {:ok, adapter_ref} <- resolve_async_adapter_ref(prepared, opts) do
      idempotency_key = compute_idempotency_key(prepared)

      case fetch_existing_delivery(idempotency_key) do
        %Delivery{} = existing ->
          existing

        nil ->
          case enqueue_via_async_adapter(prepared, adapter_ref, opts) do
            {:ok, %Delivery{} = delivery} -> delivery
            {:error, err} -> build_failed_delivery(message, err)
          end
      end
    else
      {:error, err, failed_message} -> build_failed_delivery(failed_message, err)
      {:error, err} -> build_failed_delivery(message, err)
    end
  end

  defp preflight_single(%Message{} = msg) do
    with {:ok, normalized} <- Preflight.run(msg),
         {:ok, rendered} <- Renderer.render(normalized),
         :ok <- Preflight.validate_rendered_body(normalized, rendered),
         :ok <- Tracking.Guard.assert_safe!(normalized),
         :ok <- Suppression.check_before_send(normalized),
         :ok <- RateLimiter.check(normalized),
         :ok <- Stream.policy_check(normalized) do
      {:ok, prepare_outbound_message(rendered)}
    else
      {:error, err} -> {:error, err, msg}
      {:error, _step, err, _} -> {:error, to_error(err), msg}
    end
  end

  defp fetch_existing_delivery(idempotency_key) do
    import Ecto.Query

    query = from(d in Delivery, where: d.idempotency_key == ^idempotency_key, limit: 1)
    Repo.one(Tenancy.scope(query))
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

  defp persist_queued(%Message{} = rendered, adapter_ref) do
    ik = compute_idempotency_key(rendered)
    tenant_id = rendered.tenant_id
    delivery_id = delivery_id!(rendered)

    # I-01: Multi#1 writes status: :queued (public API column) AND
    # last_event_type: :queued (ledger projection).
    Telemetry.persist_outbound_multi_span(
      %{step_name: :persist_queued, tenant_id: tenant_id},
      fn ->
        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            :delivery,
            Delivery.changeset(%Delivery{id: delivery_id}, %{
              tenant_id: tenant_id,
              mailable: inspect(rendered.mailable),
              stream: rendered.stream,
              recipient: primary_recipient(rendered),
              recipient_domain: recipient_domain(rendered),
              adapter_ref: adapter_ref,
              status: :queued,
              last_event_type: :queued,
              last_event_at: Clock.utc_now(),
              metadata: rendered.metadata || %{},
              idempotency_key: ik
            }),
            Repo.multi_opts()
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

  defp call_adapter(%Message{} = rendered, {adapter_mod, adapter_opts}) do
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

  # The explicit Task.Supervisor path is intentionally non-durable, so it may
  # carry the already-prepared message in memory. It must not reconstruct that
  # private content from Delivery metadata.
  defp dispatch_prepared(%Delivery{} = delivery, %Message{} = rendered) do
    with {:ok, adapter} <- resolve_persisted_adapter(delivery.adapter_ref),
         {:ok, dispatch_result} <- call_adapter(rendered, adapter),
         {:ok, %{delivery: updated}} <-
           persist_dispatched_multi(delivery, dispatch_result, rendered) do
      Projector.broadcast_delivery_updated(updated, :dispatched, %{
        tenant_id: updated.tenant_id,
        delivery_id: updated.id
      })

      {:ok, updated}
    else
      {:error, %{__exception__: true} = err} ->
        persist_failed_by_id(delivery.id, err)
        {:error, err}

      other ->
        other
    end
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

    # Build a stubbed Event to feed update_projections/2 ( sig takes an Event struct).
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
            }),
            Repo.multi_opts()
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
            }),
            Repo.multi_opts()
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
  # on :message string ( contract).
  defp serialize_error(%{__exception__: true, __struct__: mod} = err) do
    base = %{module: Atom.to_string(mod), message: Exception.message(err)}

    case err do
      %{type: t} when is_atom(t) -> Map.put(base, :type, t)
      _ -> base
    end
  end

  defp to_error(%Ecto.ConstraintError{} = err),
    do:
      Mailglass.SendError.new(:adapter_failure,
        context: %{reason_class: :persistence_failed, constraint: err.constraint}
      )

  defp to_error(%Postgrex.Error{} = err),
    do:
      Mailglass.SendError.new(:adapter_failure,
        context: %{reason_class: :persistence_failed, postgres: err.postgres.code}
      )

  defp to_error(%{__exception__: true} = e), do: e

  defp to_error(%Ecto.Changeset{} = cs),
    do:
      Mailglass.SendError.new(:adapter_failure,
        context: %{reason_class: :persistence_failed, changeset: inspect(cs.errors)}
      )

  defp to_error(other),
    do: Mailglass.SendError.new(:adapter_failure, context: %{wrapped: inspect(other)})

  # =========================================================
  # Internal — message helpers
  # =========================================================

  defp load_delivery(id) do
    import Ecto.Query

    query =
      from(d in Delivery,
        where: d.id == ^id,
        limit: 1
      )

    case Repo.one(Tenancy.scope(query)) do
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
    metadata = rehydrated_metadata(delivery.metadata || %{})

    email =
      Swoosh.Email.new()
      |> put_rehydrated_recipient(delivery.recipient, delivery.metadata || %{})
      |> Swoosh.Email.subject(get_in(delivery.metadata, ["subject"]) || "")
      |> Swoosh.Email.html_body(get_in(delivery.metadata, ["rendered_html"]))
      |> Swoosh.Email.text_body(get_in(delivery.metadata, ["rendered_text"]))
      |> put_rehydrated_headers(Map.get(delivery.metadata || %{}, "headers", %{}))

    %Message{
      swoosh_email: email,
      mailable: mod_atom,
      tenant_id: delivery.tenant_id,
      stream: delivery.stream,
      metadata: metadata
    }
  end

  defp resolve_sync_route(%Message{} = rendered, opts) do
    case Keyword.fetch(opts, :adapter) do
      {:ok, adapter_override} ->
        with {:ok, adapter} <- normalize_runtime_adapter(adapter_override) do
          {:ok,
           %{
             adapter: adapter,
             adapter_ref: persisted_adapter_ref_for_runtime_adapter(adapter)
           }}
        end

      :error ->
        case Keyword.fetch(opts, :adapter_ref) do
          {:ok, adapter_ref} ->
            build_named_route(adapter_ref)

          :error ->
            resolve_tenancy_or_default_route(rendered, :sync)
        end
    end
  end

  defp resolve_async_adapter_ref(%Message{} = rendered, opts) do
    case Keyword.fetch(opts, :adapter) do
      {:ok, adapter_override} ->
        with {:ok, adapter} <- normalize_runtime_adapter(adapter_override) do
          case persisted_adapter_ref_for_runtime_adapter(adapter) do
            nil ->
              {:error,
               Mailglass.SendError.new(:adapter_failure,
                 context: %{reason_class: :queued_adapter_override_not_persistable}
               )}

            adapter_ref ->
              {:ok, adapter_ref}
          end
        end

      :error ->
        case Keyword.fetch(opts, :adapter_ref) do
          {:ok, adapter_ref} ->
            with {:ok, _adapter} <- safe_resolve_named_adapter(adapter_ref) do
              {:ok, persisted_adapter_ref(adapter_ref)}
            end

          :error ->
            case resolve_tenancy_outcome(rendered, :async) do
              :default ->
                {:ok, Delivery.default_adapter_ref()}

              {:ok, adapter_ref} ->
                with {:ok, _adapter} <- safe_resolve_named_adapter(adapter_ref) do
                  {:ok, persisted_adapter_ref(adapter_ref)}
                end

              {:error, err} ->
                {:error, err}
            end
        end
    end
  end

  defp resolve_tenancy_or_default_route(%Message{} = rendered, mode) do
    case resolve_tenancy_outcome(rendered, mode) do
      :default ->
        with {:ok, adapter} <- safe_default_adapter() do
          {:ok, %{adapter: adapter, adapter_ref: Delivery.default_adapter_ref()}}
        end

      {:ok, adapter_ref} ->
        build_named_route(adapter_ref)

      {:error, err} ->
        {:error, err}
    end
  end

  defp resolve_tenancy_outcome(%Message{} = rendered, mode) do
    context = %{tenant_id: rendered.tenant_id, message: rendered, mode: mode}

    case Tenancy.resolve_outbound_adapter_ref(context) do
      :default ->
        :default

      {:ok, adapter_ref} when is_atom(adapter_ref) or is_binary(adapter_ref) ->
        {:ok, adapter_ref}

      other ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             reason_class: :invalid_adapter_ref_callback,
             returned: inspect(other)
           }
         )}
    end
  end

  defp build_named_route(adapter_ref) do
    with {:ok, adapter} <- safe_resolve_named_adapter(adapter_ref) do
      {:ok, %{adapter: adapter, adapter_ref: persisted_adapter_ref(adapter_ref)}}
    end
  end

  defp resolve_persisted_adapter(nil), do: safe_default_adapter()

  defp resolve_persisted_adapter(adapter_ref) do
    if adapter_ref == Delivery.default_adapter_ref() do
      safe_default_adapter()
    else
      safe_resolve_named_adapter(adapter_ref)
    end
  end

  defp safe_default_adapter do
    {:ok, Config.default_adapter()}
  rescue
    err in [Mailglass.ConfigError, NimbleOptions.ValidationError] ->
      {:error, normalize_adapter_config_error(:adapter, nil, err)}
  end

  defp safe_resolve_named_adapter(adapter_ref) do
    {:ok, Config.resolve_adapter_ref(adapter_ref)}
  rescue
    err in [Mailglass.ConfigError, NimbleOptions.ValidationError] ->
      {:error, normalize_adapter_config_error(:adapters, adapter_ref, err)}
  end

  defp normalize_runtime_adapter(adapter) do
    case adapter do
      mod when is_atom(mod) ->
        {:ok, {mod, []}}

      {mod, opts} when is_atom(mod) and is_list(opts) ->
        if Keyword.keyword?(opts) do
          {:ok, {mod, opts}}
        else
          {:error, Mailglass.ConfigError.new(:invalid, context: %{key: :adapter})}
        end

      _ ->
        {:error, Mailglass.ConfigError.new(:invalid, context: %{key: :adapter})}
    end
  end

  defp persisted_adapter_ref_for_runtime_adapter(adapter) do
    cond do
      default_adapter_matches?(adapter) ->
        Delivery.default_adapter_ref()

      named_ref = matching_named_adapter_ref(adapter) ->
        named_ref

      true ->
        nil
    end
  end

  defp default_adapter_matches?(adapter) do
    case safe_default_adapter() do
      {:ok, default_adapter} -> default_adapter == adapter
      {:error, _err} -> false
    end
  end

  defp matching_named_adapter_ref(adapter) do
    try do
      Config.adapters()
      |> Enum.find_value(fn {registered_ref, registered_adapter} ->
        if registered_adapter == adapter, do: persisted_adapter_ref(registered_ref)
      end)
    rescue
      _ -> nil
    end
  end

  defp persisted_adapter_ref(adapter_ref) when is_atom(adapter_ref), do: Atom.to_string(adapter_ref)
  defp persisted_adapter_ref(adapter_ref) when is_binary(adapter_ref), do: adapter_ref

  defp normalize_adapter_config_error(_key, _adapter_ref, %Mailglass.ConfigError{} = err), do: err

  defp normalize_adapter_config_error(key, adapter_ref, %NimbleOptions.ValidationError{} = err) do
    Mailglass.ConfigError.new(:invalid,
      context: %{
        key: key,
        adapter_ref: adapter_ref,
        reason: Exception.message(err)
      }
    )
  end

  defp metadata_for(%Message{} = msg) do
    %{tenant_id: msg.tenant_id, mailable: msg.mailable, stream: msg.stream}
  end

  defp primary_recipient(%Message{} = message) do
    case Message.sole_recipient(message) do
      {:ok, %{address: address}} -> address
      {:error, _} -> ""
    end
  end

  defp recipient_domain(msg) do
    case String.split(primary_recipient(msg), "@", parts: 2) do
      [_, d] -> String.downcase(d)
      _ -> ""
    end
  end

  defp compute_idempotency_key(%Message{} = msg) do
    tenant_id = msg.tenant_id || ""
    mailable = inspect(msg.mailable)
    {:ok, %{field: field, address: recipient}} = Message.sole_recipient(msg)

    content_hash =
      :crypto.hash(:sha256, [
        msg.swoosh_email.text_body || "",
        msg.swoosh_email.html_body || ""
      ])
      |> Base.encode16(case: :lower)

    :crypto.hash(:sha256, [
      tenant_id,
      "|",
      mailable,
      "|",
      Atom.to_string(field),
      "|",
      recipient,
      "|",
      content_hash
    ])
    |> Base.encode16(case: :lower)
  end

  defp base_delivery_attrs(%Message{} = rendered, ik, adapter_ref) do
    %{
      tenant_id: rendered.tenant_id,
      mailable: inspect(rendered.mailable),
      stream: rendered.stream,
      recipient: primary_recipient(rendered),
      recipient_domain: recipient_domain(rendered),
      adapter_ref: adapter_ref,
      status: :queued,
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      # Delivery metadata is an adopter-visible projection. The stamped
      # delivery id and every reconstruction value live only in Payload.
      metadata: Map.drop(rendered.metadata || %{}, [:delivery_id, "delivery_id"]),
      idempotency_key: ik
    }
  end

  defp prepare_outbound_message(%Message{} = rendered) do
    delivery_id = existing_delivery_id(rendered) || Ecto.UUID.generate()

    rendered
    |> Message.put_metadata(:delivery_id, delivery_id)
    |> Compliance.apply_outbound_headers()
    |> Tracking.rewrite_if_enabled()
  end

  defp delivery_id!(%Message{} = rendered) do
    existing_delivery_id(rendered) ||
      raise ArgumentError, "delivery_id missing from message metadata before persistence"
  end

  defp existing_delivery_id(%Message{metadata: metadata}) when is_map(metadata) do
    metadata[:delivery_id] || metadata["delivery_id"]
  end

  defp existing_delivery_id(%Message{}), do: nil

  defp rehydrated_metadata(metadata) when is_map(metadata) do
    case Map.get(metadata, "delivery_id") do
      delivery_id when is_binary(delivery_id) ->
        Map.put_new(metadata, :delivery_id, delivery_id)

      _ ->
        metadata
    end
  end

  defp put_rehydrated_recipient(%Swoosh.Email{} = email, recipient, metadata) do
    case Map.get(metadata, "recipient_field") || Map.get(metadata, :recipient_field) do
      "cc" -> Swoosh.Email.cc(email, recipient)
      "bcc" -> Swoosh.Email.bcc(email, recipient)
      :cc -> Swoosh.Email.cc(email, recipient)
      :bcc -> Swoosh.Email.bcc(email, recipient)
      _ -> Swoosh.Email.to(email, recipient)
    end
  end

  defp put_rehydrated_headers(%Swoosh.Email{} = email, headers)
       when is_map(headers) or is_list(headers) do
    Enum.reduce(headers, email, fn {key, value}, acc ->
      Swoosh.Email.header(acc, key, value)
    end)
  end

  defp put_rehydrated_headers(%Swoosh.Email{} = email, _headers), do: email

  # ME-05: Safe provider tag extraction from adapter dispatch result.
  # provider_response is adapter-defined (term()) — must not assume map shape.
  # Custom adapters may return tuples, atoms, strings, or nil in provider_response.
  # Map.get/3 on a non-map term raises BadMapError (T-3-12-03).
  defp provider_tag(%{adapter: a}), do: inspect(a)
  defp provider_tag(_), do: "unknown"
end
