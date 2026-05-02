defmodule Mailglass.TestSupport.RouteRecordingAdapter do
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = msg, opts) do
    if pid = Keyword.get(opts, :test_pid) do
      send(pid, {:adapter_route, Keyword.get(opts, :route), msg.metadata[:delivery_id], msg.tenant_id})
    end

    route = Keyword.get(opts, :route, :unknown)

    {:ok,
     %{
       message_id: "route-#{route}",
       provider_response: %{adapter: route}
     }}
  end
end

defmodule Mailglass.TestTenancy.RouteA do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:ok, :route_a}
end

defmodule Mailglass.TestTenancy.RouteB do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:ok, :route_b}
end

defmodule Mailglass.TestTenancy.InvalidRoute do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:error, :bad_shape}
end
