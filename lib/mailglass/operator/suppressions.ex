defmodule Mailglass.Operator.Suppressions do
  @moduledoc """
  Tenant-scoped read model for operator suppression visibility.
  """

  import Ecto.Query

  alias Mailglass.Clock
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.{Repo, Tenancy}

  @immutable_reasons [:complaint, :policy, :unsubscribe]

  @type context :: map() | keyword()

  @spec get_delivery_suppression_state(context(), keyword()) :: map() | nil
  def get_delivery_suppression_state(context, _opts \\ []) do
    normalized = normalize_context(context)
    tenant_id = fetch_tenant_id!(normalized)
    recipient = fetch_recipient(normalized)
    stream = fetch_stream(normalized)
    recipient_domain = extract_domain(recipient)
    now = Clock.utc_now()

    Entry
    |> where([entry], entry.tenant_id == ^tenant_id)
    |> where([entry], is_nil(entry.expires_at) or entry.expires_at > ^now)
    |> where_matches(recipient, recipient_domain, stream)
    |> order_by(
      [entry],
      asc:
        fragment(
          """
          CASE
            WHEN ? = 'address_stream' THEN 0
            WHEN ? = 'address' THEN 1
            WHEN ? = 'domain' THEN 2
            ELSE 3
          END
          """,
          entry.scope,
          entry.scope,
          entry.scope
        ),
      desc: entry.inserted_at,
      desc: entry.id
    )
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
    |> project_state()
  end

  defp normalize_context(context) when is_list(context), do: Map.new(context)
  defp normalize_context(context) when is_map(context), do: Map.new(context)

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "",
    do: tenant_id

  defp fetch_tenant_id!(_context), do: raise(ArgumentError, "tenant_id is required")

  defp fetch_recipient(%{recipient: recipient}) when is_binary(recipient) and recipient != "",
    do: String.downcase(recipient)

  defp fetch_recipient(%{delivery: %Delivery{recipient: recipient}})
       when is_binary(recipient) and recipient != "",
       do: String.downcase(recipient)

  defp fetch_recipient(_context), do: raise(ArgumentError, "recipient is required")

  defp fetch_stream(%{stream: stream}) when is_atom(stream), do: stream
  defp fetch_stream(%{delivery: %Delivery{stream: stream}}) when is_atom(stream), do: stream
  defp fetch_stream(_context), do: nil

  defp where_matches(query, recipient, recipient_domain, nil) do
    where(
      query,
      [entry],
      (entry.scope == :address and fragment("?::text", entry.address) == ^recipient) or
        (entry.scope == :domain and fragment("?::text", entry.address) == ^recipient_domain)
    )
  end

  defp where_matches(query, recipient, recipient_domain, stream) when is_atom(stream) do
    where(
      query,
      [entry],
      (entry.scope == :address and fragment("?::text", entry.address) == ^recipient) or
        (entry.scope == :domain and fragment("?::text", entry.address) == ^recipient_domain) or
        (entry.scope == :address_stream and fragment("?::text", entry.address) == ^recipient and
           entry.stream == ^stream)
    )
  end

  defp project_state(nil), do: nil

  defp project_state(%Entry{} = entry) do
    reversibility = reversibility_for(entry.reason)

    %{
      id: entry.id,
      tenant_id: entry.tenant_id,
      address: entry.address,
      scope: entry.scope,
      stream: entry.stream,
      reason: entry.reason,
      source: entry.source,
      expires_at: entry.expires_at,
      reversible?: reversibility == :reversible,
      reversibility: reversibility,
      reversibility_copy: reversibility_copy(reversibility)
    }
  end

  defp reversibility_for(reason) when reason in @immutable_reasons, do: :immutable
  defp reversibility_for(_reason), do: :reversible

  defp reversibility_copy(:reversible), do: "Reversible in a later phase"
  defp reversibility_copy(:immutable), do: "Immutable by policy"

  defp extract_domain(email) do
    case String.split(email, "@", parts: 2) do
      [_local, domain] -> String.downcase(domain)
      _ -> ""
    end
  end
end
