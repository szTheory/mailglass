if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Reconciler do
    @moduledoc """
    Oban cron worker that closes the orphan-webhook race window
    (CONTEXT D-17, D-18).

    An orphan webhook event is one inserted by `Mailglass.Webhook.Ingest`
    with `delivery_id: nil + needs_reconciliation: true` because the
    matching `mailglass_deliveries` row had not yet committed when the
    webhook arrived (a real race in production for low-latency
    providers).

    This worker runs on a `*/5 * * * *` cron schedule (adopters wire the
    cron in their own Oban config; see `guides/webhooks.md` — lands with
    Plan 04-09). For each orphan older than 60 seconds (grace window for
    late commits):

      1. `Mailglass.Events.Reconciler.find_orphans/1` returns the candidate
         batch (tenant-scoped, age-bounded, newest `max_age_minutes` only)
      2. `Mailglass.Events.Reconciler.attempt_link/1` looks up the Delivery
         via `(provider, provider_message_id)` from the orphan's metadata
      3. On match: append a NEW `:reconciled` event (D-18 — append, never
         UPDATE the orphan row; preserves the SQLSTATE 45A01 append-only
         invariant) + call `Projector.update_projections/2` for the
         matched Delivery + post-commit broadcast on the Projector PubSub
         topic (Phase 3 D-04)
      4. On no-match: leave the orphan row untouched; next tick retries

    After 7 days (`max_age_minutes: 7 * 24 * 60`), `find_orphans/1` filters
    the row out of the scan (admin LiveView shows it as "older than 7 days
    — unlikely to reconcile" per D-19).

    ## Optional-dep gating

    The entire module is conditionally compiled at file top level behind
    `if Code.ensure_loaded?(Oban.Worker)`. When Oban is absent, a stub
    module is defined that exposes `available?/0 → false`;
    `Mailglass.Application` emits a consolidated `Logger.warning` at boot
    (D-20) directing operators to run `mix mailglass.reconcile` and
    `mix mailglass.webhooks.prune` from their own cron infrastructure.

    ## Concurrency

    `unique: [period: 60]` dedupes overlapping cron runs — if a previous
    tick is still processing when the next fires, the second is a no-op
    at the Oban layer. `concurrency: 1` is the implicit default for
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
    Returns `true` when the Reconciler module is fully compiled (Oban
    available). Callers use this in `mix mailglass.reconcile` and in
    `Mailglass.Application` to decide whether to invoke the worker or
    emit the Oban-missing warning.
    """
    @doc since: "0.1.0"
    @spec available?() :: boolean()
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
    @spec reconcile(String.t() | nil, pos_integer()) :: {:ok, %{scanned: non_neg_integer(), linked: non_neg_integer()}}
    def reconcile(tenant_id \\ nil, limit \\ @batch_limit)
        when (is_nil(tenant_id) or is_binary(tenant_id)) and is_integer(limit) and limit > 0 do
      # Plan 08 named helper. The inner fn returns `{result, stop_meta}` —
      # `reconcile_span/2` recognizes the tuple shape and attaches the
      # per-run enrichment (`scanned_count`, `linked_count`,
      # `remaining_orphan_count`) to the `:stop` event.
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
                  # D-23 whitelist: no orphan metadata, no raw payload — only
                  # the orphan id (UUID; not PII) and the reason atom.
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

    # The orphan MUST be older than the grace window (default 60s). Newer
    # orphans may reflect an in-flight dispatch where the Delivery commit is
    # still pending; skipping them gives the write path time to settle.
    defp past_grace?(orphan) do
      case orphan.inserted_at do
        nil ->
          false

        %DateTime{} = inserted_at ->
          cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)
          DateTime.compare(inserted_at, cutoff) == :lt
      end
    end

    # CONTEXT D-18: APPEND a :reconciled event; do NOT UPDATE the orphan row.
    # Flat Multi composition per Plan 04-06 revision W4 — no nested Repo.multi
    # inside Multi.run. The outer transaction must be able to roll back every
    # write atomically on any late failure.
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

          # D-14 amendment: :reconciled is internal-only to mailglass_events.
          # The Delivery.last_event_type enum deliberately does NOT include
          # :reconciled — it is an audit-only lifecycle event, not a real
          # state transition. Pass the ORPHAN event (with its original type
          # like :delivered / :bounced / etc.) to update_projections/2 so
          # the delivery projection reflects the ACTUAL event the provider
          # originally reported. The :reconciled event in the ledger records
          # the audit moment (when did the orphan get linked?) without
          # polluting the delivery summary.
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
              # `Repo.transact/1` wraps a single call to `Repo.multi/1`;
              # the unwrapped success shape is just the changes map.
              maybe_broadcast(delivery, changes[:reconciled_event], orphan)
              {:ok, changes}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, :delivery_not_found} ->
          {:error, :no_match}

        {:error, :malformed_payload} ->
          # Orphan has no (provider, provider_message_id) pair to match on.
          # Admin LiveView surfaces these; Reconciler leaves them alone.
          {:error, :no_match}

        {:error, reason} ->
          {:error, reason}
      end
    end

    # Post-commit broadcast (Phase 3 D-04 invariant — broadcast AFTER the
    # transact/1 returns `{:ok, _}`, never inside). Best-effort; the
    # Projector.broadcast_delivery_updated/3 helper absorbs PubSub failures
    # so a node partition cannot propagate into the worker loop.
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
    Stub module — Oban is not loaded, so the Reconciler worker is not compiled.

    `available?/0` returns `false`. `mix mailglass.reconcile` reads this
    flag and exits with a non-zero status when invoked.
    """

    @doc since: "0.1.0"
    @spec available?() :: false
    def available?, do: false
  end
end
