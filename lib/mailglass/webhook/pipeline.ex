defmodule Mailglass.Webhook.Pipeline do
  @moduledoc false

  alias Mailglass.{ConfigError, SignatureError, TenancyError}

  @type outcome ::
          {:replay}
          | {:control_plane, term()}
          | {:ingested, binary(), non_neg_integer(), boolean()}
          | {:ingest_failed, binary(), non_neg_integer()}
          | {:signature_failed, atom()}
          | {:tenant_unresolved, atom()}
          | {:config_error, atom()}

  @doc false
  @spec run(atom(), term(), [{String.t(), String.t()}], map()) :: outcome()
  def run(provider, request, headers, deps)
      when is_atom(provider) and is_list(headers) and is_map(deps) do
    try do
      case deps.verify.(provider, request, headers) do
        {:ok, :replay} ->
          {:replay}

        {:ok, :control_plane, value} ->
          {:control_plane, value}

        :ok ->
          # The resolver is deliberately after verification. Keeping the order
          # here makes it auditable and lets this module be tested without Plug.
          tenant_id = deps.resolve_tenant.(provider, request, headers)

          deps.with_tenant.(tenant_id, fn ->
            events = deps.normalize.(provider, request, headers)

            case deps.ingest.(provider, request, events) do
              {:ok, %{duplicate: duplicate} = result} when is_boolean(duplicate) ->
                # This callback is only reached after the ingest transaction
                # returns successfully; duplicates retain their no-repeat policy.
                deps.broadcast.(result)
                {:ingested, tenant_id, length(events), duplicate}

              {:error, _reason} ->
                {:ingest_failed, tenant_id, length(events)}
            end
          end)
      end
    rescue
      error in SignatureError -> {:signature_failed, error.type}
      error in TenancyError -> {:tenant_unresolved, error.type}
      error in ConfigError -> {:config_error, error.type}
    end
  end
end
