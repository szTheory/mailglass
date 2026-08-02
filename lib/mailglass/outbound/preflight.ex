defmodule Mailglass.Outbound.Preflight do
  @moduledoc false

  alias Mailglass.{Message, SendError, Tenancy, TenancyError}

  @spec run(Message.t()) :: {:ok, Message.t()} | {:error, SendError.t()} | no_return()
  def run(%Message{} = message) do
    with {:ok, tenant_id} <- resolve_tenant(),
         :ok <- validate_envelope(message),
         :ok <- validate_body(message) do
      {:ok, %{message | tenant_id: tenant_id}}
    end
  end

  # `tenant_id!/0` deliberately remains the strict accessor. Resolve the
  # configured resolver before consulting a fallback so a custom resolver can
  # never inherit SingleTenant's implicit "default" tenant.
  defp resolve_tenant do
    case Application.get_env(:mailglass, :tenancy, Mailglass.Tenancy.SingleTenant) do
      resolver when resolver in [nil, Mailglass.Tenancy.SingleTenant] ->
        {:ok, valid_tenant_id!(Tenancy.current())}

      _custom_resolver ->
        {:ok, valid_tenant_id!(Tenancy.tenant_id!())}
    end
  end

  defp valid_tenant_id!(tenant_id) when is_binary(tenant_id) do
    if String.trim(tenant_id) == "" do
      raise TenancyError.new(:unstamped)
    end

    tenant_id
  end

  defp validate_envelope(%Message{swoosh_email: email}) do
    recipients = List.wrap(email.to) ++ List.wrap(email.cc) ++ List.wrap(email.bcc)

    if length(recipients) == 1 do
      :ok
    else
      {:error, SendError.new(:preflight_rejected, context: %{reason_class: :recipient_count})}
    end
  end

  defp validate_body(%Message{swoosh_email: email}) do
    if present_body?(email.html_body) or present_body?(email.text_body) do
      :ok
    else
      {:error, SendError.new(:preflight_rejected, context: %{reason_class: :empty_body})}
    end
  end

  defp present_body?(body) when is_binary(body), do: String.trim(body) != ""
  defp present_body?(body) when is_function(body, 1), do: true
  defp present_body?(_body), do: false
end
