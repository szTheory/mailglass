defmodule Mailglass.Ports.Suppression do
  @moduledoc false

  @doc false
  @spec suppressed_sender?(String.t(), String.t()) :: boolean()
  def suppressed_sender?(tenant_id, address) when is_binary(tenant_id) and is_binary(address) do
    store = Mailglass.Config.suppression_store()

    case store.check(%{tenant_id: tenant_id, address: String.downcase(address)}) do
      {:suppressed, _entry} -> true
      :not_suppressed -> false
      {:error, _reason} -> false
    end
  rescue
    _error -> false
  catch
    _kind, _reason -> false
  end
end
