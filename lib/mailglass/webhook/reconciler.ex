if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Reconciler do
    @moduledoc """
    Reconcile orphan webhook events against committed deliveries.

    An orphan webhook event is one inserted by `Mailglass.Webhook.Ingest`
    with `delivery_id: nil + needs_reconciliation: true` because the
    matching `mailglass_deliveries` row had not yet committed when the
    webhook arrived (a real race in production for low-latency
    providers).

    The canonical `reconcile/2` function is compiled in every install so
    operators can run the same maintenance sweep manually even when Oban is
    absent. When Oban is present, this module also exposes an Oban worker
    entrypoint via `perform/1` so adopters can schedule background runs.

    For each orphan older than 60 seconds (grace window for late commits):

      1. `Mailglass.Events.Reconciler.find_orphans/1` returns the candidate
         batch (tenant-scoped, age-bounded, newest `max_age_minutes` only)
      2. `Mailglass.Events.Reconciler.attempt_link/1` looks up the Delivery
         via `(provider, provider_message_id)` from the orphan's metadata
      3. On match: append a NEW `:reconciled` event (D-18 — append, never
         UPDATE the orphan row; preserves the SQLSTATE 45A01 append-only
         invariant) + call `Projector.update_projections/2` for the
         matched Delivery + post-commit broadcast on the Projector PubSub
         topic (Phase 3 D-04)
      4. On no-match: leave the orphan row untouched; next sweep retries

    After 7 days (`max_age_minutes: 7 * 24 * 60`), `find_orphans/1` filters
    the row out of the scan (admin LiveView shows it as "older than 7 days
    — unlikely to reconcile" per D-19).

    ## Optional-dep gating

    `available?/0` reports whether the Oban worker entrypoint is compiled.
    `Mailglass.Application` uses that to decide whether to warn about
    missing scheduled background workers. The manual CLI path still calls
    `reconcile/2` directly in both modes.

    ## Concurrency

    `unique: [period: 60]` dedupes overlapping cron runs when Oban is
    present. `concurrency: 1` is the implicit default for
    `:mailglass_reconcile` queue; adopters who raise it accept the
    reconciliation race (Ecto optimistic locking on the Delivery row still
    makes the final write correct, but duplicate `:reconciled` events
    become possible if two workers see the same orphan — the partial
    UNIQUE index on `idempotency_key` (`"reconciled:\#{orphan.id}"`)
    structurally prevents this anyway).
    """

    use Oban.Worker, queue: :mailglass_reconcile, unique: [period: 60]

    require Logger

    alias Ecto.Multi
    alias Mailglass.{Clock, Events, Repo}
    alias Mailglass.Events.Reconciler, as: EventsReconciler
    alias Mailglass.Outbound.Projector
    alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry

    @grace_seconds 60
    @max_age_minutes 7 * 24 * 60
    @batch_limit 1000

    @doc """
    Returns `true` when the Oban worker entrypoint is compiled.
    """
    @doc since: "0.1.0"
    @spec available?() :: true
    def available?, do: true

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      tenant_id = Map.get(args, "tenant_id")
      limit = Map.get(args, "limit", @batch_limit)

      # Phase 2 TenancyMiddleware wraps perform via `"mailglass_tenant_id"` in
      # job args when present; direct adopter cron args like `"tenant_id"`
      # just pass through here. Either way, `reconcile/2` is a pure
      # application-layer call — no middleware required at this layer.
      {:ok, _metrics} = reconcile(tenant_id, limit)
      :ok
    end

    @doc """
    Run the reconciliation sweep for the given tenant (or all tenants
    when `tenant_id` is `nil`).

    Returns `{:ok, %{scanned: n, linked: m}}` on success.

    Exposed as a public function so `mix mailglass.reconcile` can invoke
    the same code path; also useful in tests and for ops engineers who
    want to run a sweep out-of-band without waiting for the next cron tick.
    """
    @spec reconcile(String.t() | nil, pos_integer()) ::
            {:ok, %{scanned: non_neg_integer(), linked: non_neg_integer()}}
    def reconcile(tenant_id \\ nil, limit \\ @batch_limit)
        when (is_nil(tenant_id) or is_binary(tenant_id)) and is_integer(limit) and limit > 0 do
      WebhookTelemetry.reconcile_span(
        %{tenant_id: tenant_id},
        fn ->
          orphans =
            EventsReconciler.find_orphans(
              tenant_id: tenant_id,
              limit: limit,
              max_age_minutes: @max_age_minutes
            )
            |> Enum.filter(&past_grace?/1)

          {linked, _failed} =
            Enum.reduce(orphans, {0, 0}, fn orphan, {ok, err} ->
              case attempt_reconcile(orphan) do
                {:ok, _} ->
                  {ok + 1, err}

                {:error, :no_match} ->
                  {ok, err}

                {:error, reason} ->
                  Logger.warning(
                    "[mailglass] Reconcile attempt failed for orphan=#{orphan.id} reason=#{inspect(reason)}"
                  )

                  {ok, err + 1}
              end
            end)

          scanned = length(orphans)
          remaining = max(scanned - linked, 0)
          result = {:ok, %{scanned: scanned, linked: linked}}

          meta = %{
            tenant_id: tenant_id,
            scanned_count: scanned,
            linked_count: linked,
            remaining_orphan_count: remaining,
            status: :ok
          }

          {result, meta}
        end
      )
    end

    defp past_grace?(orphan) do
      case orphan.inserted_at do
        nil ->
          false

        %DateTime{} = inserted_at ->
          cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)
          DateTime.compare(inserted_at, cutoff) == :lt
      end
    end

    defp attempt_reconcile(orphan) do
      case EventsReconciler.attempt_link(orphan) do
        {:ok, {delivery, ^orphan}} ->
          reconciled_attrs = %{
            type: :reconciled,
            delivery_id: delivery.id,
            tenant_id: orphan.tenant_id,
            metadata: %{
              "reconciled_from_event_id" => orphan.id,
              "reconciled_provider" => extract_provider(orphan),
              "reconciled_provider_event_id" => extract_provider_event_id(orphan)
            },
            idempotency_key: "reconciled:" <> to_string(orphan.id),
            occurred_at: Clock.utc_now()
          }

          multi =
            Multi.new()
            |> Events.append_multi(:reconciled_event, reconciled_attrs)
            |> Multi.update(:projection, fn _changes ->
              Projector.update_projections(delivery, orphan)
            end)

          case Repo.transact(fn -> Repo.multi(multi) end) do
            {:ok, {:ok, changes}} ->
              maybe_broadcast(delivery, changes[:reconciled_event], orphan)
              {:ok, changes}

            {:ok, {:error, _step, reason, _changes_so_far}} ->
              {:error, reason}

            {:ok, changes} when is_map(changes) ->
              maybe_broadcast(delivery, changes[:reconciled_event], orphan)
              {:ok, changes}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, :delivery_not_found} ->
          {:error, :no_match}

        {:error, :malformed_payload} ->
          {:error, :no_match}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp maybe_broadcast(_delivery, nil, _orphan), do: :ok

    defp maybe_broadcast(delivery, reconciled_event, orphan) do
      Projector.broadcast_delivery_updated(delivery, :reconciled, %{
        event_id: reconciled_event.id,
        reconciled_from_event_id: orphan.id
      })
    end

    defp extract_provider(orphan) do
      case orphan.metadata do
        %{"provider" => provider} -> provider
        %{provider: provider} -> provider
        _ -> nil
      end
    end

    defp extract_provider_event_id(orphan) do
      case orphan.metadata do
        %{"provider_event_id" => id} -> id
        %{provider_event_id: id} -> id
        _ -> nil
      end
    end
  end
else
  defmodule Mailglass.Webhook.Reconciler do
    @moduledoc """
    Reconcile orphan webhook events against committed deliveries.

    This fallback definition is compiled when `Oban.Worker` is absent.
    The canonical `reconcile/2` sweep remains available for manual
    maintenance via `mix mailglass.reconcile`, while the Oban worker
    entrypoint is intentionally omitted.
    """

    require Logger

    alias Ecto.Multi
    alias Mailglass.{Clock, Events, Repo}
    alias Mailglass.Events.Reconciler, as: EventsReconciler
    alias Mailglass.Outbound.Projector
    alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry

    @grace_seconds 60
    @max_age_minutes 7 * 24 * 60
    @batch_limit 1000

    @doc """
    Returns `false` when the Oban worker entrypoint is not compiled.
    """
    @doc since: "0.1.0"
    @spec available?() :: false
    def available?, do: false

    @doc """
    Run the reconciliation sweep for the given tenant (or all tenants
    when `tenant_id` is `nil`).

    Returns `{:ok, %{scanned: n, linked: m}}` on success.
    """
    @spec reconcile(String.t() | nil, pos_integer()) ::
            {:ok, %{scanned: non_neg_integer(), linked: non_neg_integer()}}
    def reconcile(tenant_id \\ nil, limit \\ @batch_limit)
        when (is_nil(tenant_id) or is_binary(tenant_id)) and is_integer(limit) and limit > 0 do
      WebhookTelemetry.reconcile_span(
        %{tenant_id: tenant_id},
        fn ->
          orphans =
            EventsReconciler.find_orphans(
              tenant_id: tenant_id,
              limit: limit,
              max_age_minutes: @max_age_minutes
            )
            |> Enum.filter(&past_grace?/1)

          {linked, _failed} =
            Enum.reduce(orphans, {0, 0}, fn orphan, {ok, err} ->
              case attempt_reconcile(orphan) do
                {:ok, _} ->
                  {ok + 1, err}

                {:error, :no_match} ->
                  {ok, err}

                {:error, reason} ->
                  Logger.warning(
                    "[mailglass] Reconcile attempt failed for orphan=#{orphan.id} reason=#{inspect(reason)}"
                  )

                  {ok, err + 1}
              end
            end)

          scanned = length(orphans)
          remaining = max(scanned - linked, 0)
          result = {:ok, %{scanned: scanned, linked: linked}}

          meta = %{
            tenant_id: tenant_id,
            scanned_count: scanned,
            linked_count: linked,
            remaining_orphan_count: remaining,
            status: :ok
          }

          {result, meta}
        end
      )
    end

    defp past_grace?(orphan) do
      case orphan.inserted_at do
        nil ->
          false

        %DateTime{} = inserted_at ->
          cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)
          DateTime.compare(inserted_at, cutoff) == :lt
      end
    end

    defp attempt_reconcile(orphan) do
      case EventsReconciler.attempt_link(orphan) do
        {:ok, {delivery, ^orphan}} ->
          reconciled_attrs = %{
            type: :reconciled,
            delivery_id: delivery.id,
            tenant_id: orphan.tenant_id,
            metadata: %{
              "reconciled_from_event_id" => orphan.id,
              "reconciled_provider" => extract_provider(orphan),
              "reconciled_provider_event_id" => extract_provider_event_id(orphan)
            },
            idempotency_key: "reconciled:" <> to_string(orphan.id),
            occurred_at: Clock.utc_now()
          }

          multi =
            Multi.new()
            |> Events.append_multi(:reconciled_event, reconciled_attrs)
            |> Multi.update(:projection, fn _changes ->
              Projector.update_projections(delivery, orphan)
            end)

          case Repo.transact(fn -> Repo.multi(multi) end) do
            {:ok, {:ok, changes}} ->
              maybe_broadcast(delivery, changes[:reconciled_event], orphan)
              {:ok, changes}

            {:ok, {:error, _step, reason, _changes_so_far}} ->
              {:error, reason}

            {:ok, changes} when is_map(changes) ->
              maybe_broadcast(delivery, changes[:reconciled_event], orphan)
              {:ok, changes}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, :delivery_not_found} ->
          {:error, :no_match}

        {:error, :malformed_payload} ->
          {:error, :no_match}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp maybe_broadcast(_delivery, nil, _orphan), do: :ok

    defp maybe_broadcast(delivery, reconciled_event, orphan) do
      Projector.broadcast_delivery_updated(delivery, :reconciled, %{
        event_id: reconciled_event.id,
        reconciled_from_event_id: orphan.id
      })
    end

    defp extract_provider(orphan) do
      case orphan.metadata do
        %{"provider" => provider} -> provider
        %{provider: provider} -> provider
        _ -> nil
      end
    end

    defp extract_provider_event_id(orphan) do
      case orphan.metadata do
        %{"provider_event_id" => id} -> id
        %{provider_event_id: id} -> id
        _ -> nil
      end
    end
  end
end
