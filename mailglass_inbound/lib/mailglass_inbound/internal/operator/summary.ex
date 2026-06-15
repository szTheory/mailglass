defmodule MailglassInbound.Internal.Operator.Summary do
  @moduledoc false
  # Tenant-scoped aggregate read model for the admin inbound overview tier.
  #
  # This intentionally does not derive from the capped list read model, which may
  # also be narrowed by the selected outcome filter. Summary totals use the same
  # tenant/provider/window/search filters, but ignore outcome so the overview
  # denominator remains truthful for the active tenant/window.

  import Ecto.Query

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Repo
  alias Mailglass.Tenancy

  @default_window_hours 168
  @outcomes ExecutionRun.__outcomes__()
  @zero_outcomes Map.new(@outcomes, &{&1, 0})
  @zero_summary %{
    total: 0,
    outcomes: @zero_outcomes,
    unclassified: 0,
    no_match_rate: 0.0
  }

  @type filters :: map() | keyword()
  @type summary :: %{
          total: non_neg_integer(),
          outcomes: %{ExecutionRun.outcome() => non_neg_integer()},
          unclassified: non_neg_integer(),
          no_match_rate: float()
        }

  @spec summarize(filters(), keyword()) :: map()
  def summarize(filters, _opts \\ []) do
    normalized = normalize_filters(filters)

    case fetch_tenant_id(normalized) do
      {:ok, tenant_id} ->
        from(record in InboundRecord, as: :rec)
        |> where([rec: record], record.tenant_id == ^tenant_id)
        |> maybe_filter_provider(normalized[:provider])
        |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
        |> maybe_filter_search(normalized[:search])
        |> select([rec: _record], %{outcome: subquery(latest_fresh_run_outcome(tenant_id))})
        |> Tenancy.scope(tenant_id)
        |> Repo.all()
        |> summarize_rows()

      :blank ->
        @zero_summary
    end
  end

  defp latest_fresh_run_outcome(tenant_id) do
    from(run in ExecutionRun,
      where:
        run.tenant_id == ^tenant_id and
          run.source == :fresh and
          run.inbound_record_id == parent_as(:rec).id,
      order_by: [desc: run.inserted_at],
      limit: 1,
      select: run.outcome
    )
  end

  defp summarize_rows(rows) do
    total = length(rows)

    {outcomes, unclassified} =
      Enum.reduce(rows, {@zero_outcomes, 0}, fn %{outcome: outcome}, {outcomes, unclassified} ->
        case cast_outcome_atom(outcome) do
          outcome when outcome in @outcomes ->
            {Map.update!(outcomes, outcome, &(&1 + 1)), unclassified}

          _ ->
            {outcomes, unclassified + 1}
        end
      end)

    %{
      total: total,
      outcomes: outcomes,
      unclassified: unclassified,
      no_match_rate: no_match_rate(outcomes.no_match, total)
    }
  end

  defp no_match_rate(_no_match, 0), do: 0.0

  defp no_match_rate(no_match, total) do
    Float.round(no_match / total * 100, 1)
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id(%{tenant_id: tenant_id})
       when is_binary(tenant_id) and tenant_id != "",
       do: {:ok, tenant_id}

  defp fetch_tenant_id(_filters), do: :blank

  defp maybe_filter_provider(query, provider) when is_binary(provider) and provider != "" do
    where(query, [rec: record], record.provider == ^provider)
  end

  defp maybe_filter_provider(query, _provider), do: query

  defp maybe_filter_search(query, search) when is_binary(search) do
    case String.trim(search) do
      "" ->
        query

      trimmed ->
        pattern = "%" <> escape_like(trimmed) <> "%"

        where(
          query,
          [rec: record],
          ilike(record.subject, ^pattern) or
            ilike(record.envelope_recipient, ^pattern) or
            ilike(record.provider_message_id, ^pattern)
        )
    end
  end

  defp maybe_filter_search(query, _search), do: query

  defp escape_like(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  defp maybe_filter_window(query, nil) do
    since = DateTime.add(DateTime.utc_now(), -@default_window_hours, :hour)
    where(query, [rec: record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, window_hours)
       when is_integer(window_hours) and window_hours > 0 do
    since = DateTime.add(DateTime.utc_now(), -window_hours, :hour)
    where(query, [rec: record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, _window_hours), do: query

  defp cast_outcome_atom(outcome) when is_atom(outcome), do: outcome

  defp cast_outcome_atom(outcome) when is_binary(outcome) do
    atom = safe_existing_atom(outcome)
    if atom in @outcomes, do: atom, else: nil
  end

  defp cast_outcome_atom(_outcome), do: nil

  defp safe_existing_atom(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end
end
