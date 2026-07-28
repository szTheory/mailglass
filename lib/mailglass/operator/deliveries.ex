defmodule Mailglass.Operator.Deliveries do
  @moduledoc """
  Tenant-scoped read model for recent operator delivery browsing.
  """

  import Ecto.Query

  alias Mailglass.Outbound.Delivery
  alias Mailglass.{Repo, Tenancy}

  @default_limit 50
  @max_limit 100
  @default_window_hours 168

  @type filters :: map() | keyword()

  @spec list_recent_deliveries(filters(), keyword()) :: [map()]
  def list_recent_deliveries(filters, opts \\ []) do
    filters
    |> list_recent_deliveries_page(opts)
    |> Map.fetch!(:entries)
  end

  # Dialyzer infers this returns `[struct()]` because `Ecto.Repo.all/2` is spec'd
  # `[Ecto.Schema.t()]` regardless of the query's `select`. This query selects a
  # single string column (`delivery.provider`), so the real return is
  # `[String.t()]` and the spec below is correct — the imprecision is upstream in
  # Ecto's spec, not here. Suppressed at the definition site (matching
  # `Mix.Tasks.Mailglass.Doctor`) rather than in `.dialyzer_ignore.exs`, which is
  # at its documented hard cap and reserved for file-level ignores.
  @dialyzer {:nowarn_function, list_providers: 2}
  @spec list_providers(filters(), keyword()) :: [String.t()]
  def list_providers(filters, _opts \\ []) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)

    Delivery
    |> where([delivery], delivery.tenant_id == ^tenant_id)
    |> where([delivery], not is_nil(delivery.provider) and delivery.provider != "")
    |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
    |> Tenancy.scope(tenant_id)
    |> group_by([delivery], delivery.provider)
    |> order_by([delivery], asc: delivery.provider)
    |> select([delivery], delivery.provider)
    |> Repo.all()
  end

  @spec list_recent_deliveries_page(filters(), keyword()) :: map()
  def list_recent_deliveries_page(filters, opts \\ []) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    page = page_from(normalized, opts)
    per_page = per_page_from(normalized, opts)

    query = scoped_query(normalized, tenant_id)
    total_count = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> order_by([delivery],
        desc: delivery.last_event_at,
        desc: delivery.inserted_at,
        desc: delivery.id
      )
      |> limit(^per_page)
      |> offset(^offset_for(page, per_page))
      |> delivery_projection()
      |> Repo.all()

    page_result(entries, total_count, page, per_page)
  end

  defp scoped_query(normalized, tenant_id) do
    Delivery
    |> where([delivery], delivery.tenant_id == ^tenant_id)
    |> maybe_filter_provider(normalized[:provider])
    |> maybe_filter_status(normalized[:status])
    |> maybe_filter_event(normalized[:event] || normalized[:last_event_type])
    |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
    |> Tenancy.scope(tenant_id)
  end

  defp delivery_projection(query) do
    select(query, [delivery], %{
      id: delivery.id,
      tenant_id: delivery.tenant_id,
      mailable: delivery.mailable,
      stream: delivery.stream,
      recipient: delivery.recipient,
      provider: delivery.provider,
      provider_message_id: delivery.provider_message_id,
      status: delivery.status,
      last_event_type: delivery.last_event_type,
      last_event_at: delivery.last_event_at,
      inserted_at: delivery.inserted_at
    })
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "",
    do: tenant_id

  defp fetch_tenant_id!(_filters), do: raise(ArgumentError, "tenant_id is required")

  defp page_from(filters, opts),
    do: positive_integer(Map.get(filters, :page, Keyword.get(opts, :page)), 1)

  defp per_page_from(filters, opts) do
    filters
    |> Map.get(
      :per_page,
      Map.get(filters, :limit, Keyword.get(opts, :per_page, Keyword.get(opts, :limit)))
    )
    |> positive_integer(@default_limit)
    |> min(@max_limit)
  end

  defp positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  defp positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> default
    end
  end

  defp positive_integer(_value, default), do: default

  defp offset_for(page, per_page), do: (page - 1) * per_page

  defp page_result(entries, total_count, page, per_page) do
    total_pages = total_pages(total_count, per_page)

    %{
      entries: entries,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: total_pages,
      has_previous?: page > 1 and total_pages > 0,
      has_next?: page < total_pages
    }
  end

  defp total_pages(0, _per_page), do: 0
  defp total_pages(total_count, per_page), do: ceil(total_count / per_page)

  defp maybe_filter_provider(query, provider) when is_binary(provider) and provider != "" do
    where(query, [delivery], delivery.provider == ^provider)
  end

  defp maybe_filter_provider(query, _provider), do: query

  defp maybe_filter_status(query, status) when is_atom(status) and not is_nil(status) do
    where(query, [delivery], delivery.status == ^status)
  end

  defp maybe_filter_status(query, _status), do: query

  defp maybe_filter_event(query, event) when is_atom(event) and not is_nil(event) do
    where(query, [delivery], delivery.last_event_type == ^event)
  end

  defp maybe_filter_event(query, _event), do: query

  defp maybe_filter_window(query, nil) do
    since = DateTime.add(Mailglass.Clock.utc_now(), -@default_window_hours, :hour)
    where(query, [delivery], delivery.last_event_at >= ^since)
  end

  defp maybe_filter_window(query, window_hours)
       when is_integer(window_hours) and window_hours > 0 do
    since = DateTime.add(Mailglass.Clock.utc_now(), -window_hours, :hour)
    where(query, [delivery], delivery.last_event_at >= ^since)
  end

  defp maybe_filter_window(query, _window_hours), do: query
end
