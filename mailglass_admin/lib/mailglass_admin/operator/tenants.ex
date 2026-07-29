defmodule MailglassAdmin.Operator.Tenants do
  @moduledoc """
  Shell-facing tenant selector seam.

  Admin code consumes this module instead of reading tenant-bearing tables
  directly. Core owns outbound tenant discovery; the optional inbound package is
  reached only through its runtime gateway.
  """

  alias Mailglass.Operator.Tenants, as: CoreTenants
  alias MailglassAdmin.Operator.Accounts

  @type tenant_row :: %{id: String.t(), label: String.t()}

  @doc """
  Returns distinct selector rows from outbound activity plus optional inbound ids.

  `:account_labels` may provide a `%{tenant_id => display_name}` map. The `id`
  remains the tenant id used by URLs and read-model calls; only `label` changes.
  """
  @spec list_tenants(term(), keyword()) :: [tenant_row()]
  def list_tenants(context, opts \\ []) do
    account_labels = Keyword.get(opts, :account_labels, %{})

    inbound_gateway =
      Keyword.get(opts, :inbound_gateway, MailglassAdmin.OptionalDeps.MailglassInbound)

    context
    |> outbound_rows(opts)
    |> Kernel.++(inbound_rows(inbound_gateway, context, opts))
    |> Accounts.apply_labels(account_labels)
  end

  defp outbound_rows(context, opts), do: CoreTenants.list_tenants(context, opts)

  defp inbound_rows(gateway, context, opts) when is_atom(gateway) do
    if Code.ensure_loaded?(gateway) and function_exported?(gateway, :available?, 0) and
         apply(gateway, :available?, []) and function_exported?(gateway, :list_tenants, 2) do
      apply(gateway, :list_tenants, [context, opts])
    else
      []
    end
  end

  defp inbound_rows(_gateway, _context, _opts), do: []
end
