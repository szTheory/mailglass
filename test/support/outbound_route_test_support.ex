defmodule Mailglass.TestSupport.RouteRecordingAdapter do
  @moduledoc false
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = msg, opts) do
    if pid = Keyword.get(opts, :test_pid) do
      send(
        pid,
        {:adapter_route, Keyword.get(opts, :route), msg.metadata[:delivery_id], msg.tenant_id}
      )
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
  @moduledoc false
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:ok, :route_a}
end

defmodule Mailglass.TestTenancy.RouteB do
  @moduledoc false
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:ok, :route_b}
end

defmodule Mailglass.TestTenancy.InvalidRoute do
  @moduledoc false
  @behaviour Mailglass.Tenancy

  # Reason: this adapter intentionally returns `{:error, :bad_shape}` — a value
  # OUTSIDE the `@callback resolve_outbound_adapter_ref/1` return contract — to
  # prove that `Mailglass.Outbound.send/2` rejects malformed Tenancy callback
  # shapes with a `Mailglass.SendError` instead of silently falling back. The
  # divergence is the test contract (see test/mailglass/outbound_test.exs:195
  # "invalid tenancy callback output fails loudly..."). Suppress the dialyzer
  # callback_type_mismatch warning at the function level rather than via the
  # repo-wide ignore-file because the suppression is local and tightly bound
  # to this single deliberately-misshapen adapter.
  @dialyzer {:nowarn_function, resolve_outbound_adapter_ref: 1}

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context), do: {:error, :bad_shape}
end
