defmodule Mailglass.Operator.Tenants do
  @moduledoc """
  Tenant-scoped read model for operator tenant selector choices.
  """

  import Ecto.Query

  alias Mailglass.Outbound.Delivery
  alias Mailglass.{Repo, Tenancy}

  @type context :: map() | keyword() | term()
  @type tenant_row :: %{id: String.t(), label: String.t()}

  @doc """
  Lists distinct tenant ids visible to the given operator context.

  The projection is intentionally small: shell selectors only need an id and
  display label, and labels are currently the tenant ids themselves.
  """
  @spec list_tenants(context(), keyword()) :: [tenant_row()]
  def list_tenants(context, _opts \\ []) do
    Delivery
    |> where([delivery], not is_nil(delivery.tenant_id) and delivery.tenant_id != "")
    |> Tenancy.scope(context)
    |> group_by([delivery], delivery.tenant_id)
    |> order_by([delivery], asc: delivery.tenant_id)
    |> select([delivery], %{id: delivery.tenant_id, label: delivery.tenant_id})
    |> Repo.all()
  end
end
