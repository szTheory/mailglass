defmodule Host.InboundRepo do
  use Ecto.Repo,
    otp_app: :host,
    adapter: Ecto.Adapters.Postgres
end

defmodule Host.GeneratedHostTenancy do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(%{tenant_id: "generated-host"}), do: {:ok, :generated}

  def resolve_outbound_adapter_ref(_context), do: :default
end

defmodule Host.GeneratedHostAdapter do
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(message, _opts) do
    {:ok,
     %{
       message_id: "generated-host-#{message.metadata[:delivery_id]}",
       provider_response: %{adapter: :generated_host}
     }}
  end
end

defmodule Host.GeneratedProof do
  @moduledoc false
end
