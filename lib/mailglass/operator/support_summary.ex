defmodule Mailglass.Operator.SupportSummary do
  @moduledoc """
  Tenant-scoped read model for operator support cues.
  """

  import Ecto.Query

  alias Mailglass.Clock
  alias Mailglass.Events.Event
  alias Mailglass.Repo
  alias Mailglass.Tenancy
  alias Mailglass.Webhook.WebhookEvent

  @failed_ingest_statuses [:failed, :dead]
  @replay_types [:webhook_replay_succeeded, :webhook_replay_failed]
  @default_window_hours 24

  @type filters :: map() | keyword()

  @spec summarize_tenant(filters()) :: map()
  def summarize_tenant(filters) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    window_hours = window_hours_from(normalized)
    window_started_at = DateTime.add(Clock.utc_now(), -window_hours, :hour)

    unresolved_orphans = unresolved_orphans_query(tenant_id, window_started_at)

    %{
      failed_ingest: failed_ingest_summary(tenant_id, window_started_at),
      orphan_backlog: orphan_backlog_summary(tenant_id, unresolved_orphans),
      replay_outcomes: replay_outcomes_summary(tenant_id, window_started_at),
      reconcile_facts: reconcile_facts_summary(tenant_id, window_started_at, unresolved_orphans)
    }
  end

  defp failed_ingest_summary(tenant_id, window_started_at) do
    query =
      from(webhook_event in WebhookEvent,
        where: webhook_event.tenant_id == ^tenant_id,
        where: webhook_event.status in ^@failed_ingest_statuses,
        where: webhook_event.received_at >= ^window_started_at
      )

    %{
      count: count_rows(query, tenant_id),
      latest:
        query
        |> order_by([webhook_event],
          desc: webhook_event.received_at,
          desc: webhook_event.inserted_at,
          desc: webhook_event.id
        )
        |> limit(1)
        |> select([webhook_event], %{
          webhook_event_id: webhook_event.id,
          provider: webhook_event.provider,
          provider_event_id: webhook_event.provider_event_id,
          received_at: webhook_event.received_at,
          status: webhook_event.status
        })
        |> Tenancy.scope(tenant_id)
        |> Repo.one()
    }
  end

  defp orphan_backlog_summary(tenant_id, unresolved_orphans) do
    oldest =
      unresolved_orphans
      |> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
      |> limit(1)
      |> select([event], %{
        event_id: event.id,
        occurred_at: event.occurred_at,
        provider: fragment("?->>'provider'", event.metadata),
        provider_event_id: fragment("?->>'provider_event_id'", event.metadata),
        webhook_event_id: fragment("?->>'webhook_event_id'", event.metadata)
      })
      |> Tenancy.scope(tenant_id)
      |> Repo.one()

    %{
      count: count_rows(unresolved_orphans, tenant_id),
      oldest: oldest,
      oldest_age_seconds: age_seconds(oldest)
    }
  end

  defp replay_outcomes_summary(tenant_id, window_started_at) do
    replay_query =
      from(event in Event,
        where: event.tenant_id == ^tenant_id,
        where: event.type in ^@replay_types,
        where: event.occurred_at >= ^window_started_at
      )

    counts = %{
      failed:
        replay_query
        |> where([event], event.type == ^:webhook_replay_failed)
        |> count_rows(tenant_id),
      noop:
        replay_query
        |> where(
          [event],
          event.type == ^:webhook_replay_succeeded and
            fragment("?->>'outcome' = 'noop'", event.metadata)
        )
        |> count_rows(tenant_id),
      replayed:
        replay_query
        |> where(
          [event],
          event.type == ^:webhook_replay_succeeded and
            fragment("?->>'outcome' = 'replayed'", event.metadata)
        )
        |> count_rows(tenant_id)
    }

    latest =
      replay_query
      |> order_by([event], desc: event.occurred_at, desc: event.inserted_at, desc: event.id)
      |> limit(1)
      |> select([event], %{
        delivery_id: event.delivery_id,
        event_id: event.id,
        occurred_at: event.occurred_at,
        provider: fragment("?->>'provider'", event.metadata),
        replay_outcome:
          fragment(
            "CASE WHEN ? = 'webhook_replay_failed' THEN 'failed' ELSE ?->>'outcome' END",
            event.type,
            event.metadata
          ),
        webhook_event_id: fragment("?->>'webhook_event_id'", event.metadata)
      })
      |> Tenancy.scope(tenant_id)
      |> Repo.one()

    %{
      counts: counts,
      latest: normalize_replay_latest(latest)
    }
  end

  defp reconcile_facts_summary(tenant_id, window_started_at, unresolved_orphans) do
    reconciled_query =
      from(event in Event,
        where: event.tenant_id == ^tenant_id,
        where: event.type == ^:reconciled,
        where: event.occurred_at >= ^window_started_at
      )

    oldest_unmatched =
      unresolved_orphans
      |> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
      |> limit(1)
      |> select([event], %{
        event_id: event.id,
        occurred_at: event.occurred_at,
        provider: fragment("?->>'provider'", event.metadata),
        provider_event_id: fragment("?->>'provider_event_id'", event.metadata),
        webhook_event_id: fragment("?->>'webhook_event_id'", event.metadata)
      })
      |> Tenancy.scope(tenant_id)
      |> Repo.one()

    %{
      reconciled_count: count_rows(reconciled_query, tenant_id),
      still_unmatched_count: count_rows(unresolved_orphans, tenant_id),
      latest_reconciled:
        reconciled_query
        |> order_by([event], desc: event.occurred_at, desc: event.inserted_at, desc: event.id)
        |> limit(1)
        |> select([event], %{
          delivery_id: event.delivery_id,
          event_id: event.id,
          occurred_at: event.occurred_at,
          provider: fragment("?->>'reconciled_provider'", event.metadata),
          reconciled_from_event_id: fragment("?->>'reconciled_from_event_id'", event.metadata),
          reconciled_provider_event_id:
            fragment("?->>'reconciled_provider_event_id'", event.metadata)
        })
        |> Tenancy.scope(tenant_id)
        |> Repo.one(),
      oldest_unmatched: oldest_unmatched
    }
  end

  defp unresolved_orphans_query(tenant_id, window_started_at) do
    from(event in Event,
      as: :orphan,
      where: event.tenant_id == ^tenant_id,
      where: event.needs_reconciliation == true and is_nil(event.delivery_id),
      where: event.occurred_at >= ^window_started_at,
      where:
        not exists(
          from(reconciled in Event,
            where: reconciled.tenant_id == parent_as(:orphan).tenant_id,
            where: reconciled.type == ^:reconciled,
            where:
              fragment(
                "?->>'reconciled_from_event_id' = CAST(? AS text)",
                reconciled.metadata,
                parent_as(:orphan).id
              )
          )
        )
    )
  end

  defp normalize_replay_latest(nil), do: nil

  defp normalize_replay_latest(latest) do
    %{
      delivery_id: latest.delivery_id,
      event_id: latest.event_id,
      occurred_at: latest.occurred_at,
      outcome: latest.replay_outcome,
      provider: latest.provider,
      webhook_event_id: latest.webhook_event_id
    }
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp count_rows(query, tenant_id) do
    query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> select([row], count(row.id))
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "",
    do: tenant_id

  defp fetch_tenant_id!(_filters), do: raise(ArgumentError, "tenant_id is required")

  defp window_hours_from(filters) do
    case Map.get(filters, :window_hours, @default_window_hours) do
      hours when is_integer(hours) and hours > 0 -> hours
      _ -> @default_window_hours
    end
  end

  defp age_seconds(nil), do: nil

  defp age_seconds(%{occurred_at: %DateTime{} = occurred_at}) do
    DateTime.diff(Clock.utc_now(), occurred_at, :second)
  end
end
