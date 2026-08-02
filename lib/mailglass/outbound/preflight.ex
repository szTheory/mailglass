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
    with {:ok, to} <- normalize_recipient_collection(email.to),
         {:ok, cc} <- normalize_recipient_collection(email.cc),
         {:ok, bcc} <- normalize_recipient_collection(email.bcc) do
      validate_normalized_envelope(to, cc, bcc)
    else
      :error -> recipient_invalid_error()
    end
  end

  defp validate_normalized_envelope(to, cc, bcc) do
    recipients = to ++ cc ++ bcc
    count = length(recipients)

    cond do
      count != 1 ->
        {:error,
         SendError.new(:preflight_rejected,
           context: %{reason_class: :recipient_count_invalid, recipient_count: count}
         )}

      to == [] ->
        # Phase 149 persists only a recipient address. Retaining a `cc`/`bcc`
        # field through the async boundary needs the private envelope planned for
        # Phase 150, so reject these shapes instead of silently converting them.
        {:error,
         SendError.new(:preflight_rejected,
           context: %{reason_class: :recipient_field_unsupported}
         )}

      true ->
        :ok
    end
  end

  defp normalize_recipient_collection(recipients) when is_list(recipients) do
    recipients
    |> Enum.reduce_while({:ok, []}, fn recipient, {:ok, acc} ->
      case normalize_recipient(recipient) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      :error -> :error
    end
  end

  defp normalize_recipient_collection(_), do: :error

  defp normalize_recipient(address) when is_binary(address) do
    if valid_address?(address), do: {:ok, {"", address}}, else: :error
  end

  defp normalize_recipient({name, address})
       when (is_binary(name) or is_nil(name)) and is_binary(address) do
    if valid_address?(address), do: {:ok, {name || "", address}}, else: :error
  end

  defp normalize_recipient(_), do: :error

  defp valid_address?(address) do
    String.valid?(address) and String.trim(address) != "" and
      Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, address)
  end

  defp recipient_invalid_error do
    {:error, SendError.new(:preflight_rejected, context: %{reason_class: :recipient_invalid})}
  end

  defp validate_body(%Message{swoosh_email: email}) do
    states = [html_body_state(email.html_body), text_body_state(email.text_body)]

    cond do
      :present in states ->
        :ok

      :unsupported in states ->
        {:error,
         SendError.new(:preflight_rejected,
           context: %{reason_class: :body_invalid, body_state: :unsupported}
         )}

      true ->
        {:error,
         SendError.new(:preflight_rejected,
           context: %{reason_class: :body_invalid, body_state: :empty}
         )}
    end
  end

  defp html_body_state(body) when is_function(body, 1), do: :present
  defp html_body_state(body) when is_binary(body), do: binary_body_state(body)
  defp html_body_state(nil), do: :empty
  defp html_body_state(_body), do: :unsupported

  defp text_body_state(body) when is_binary(body), do: binary_body_state(body)
  defp text_body_state(nil), do: :empty
  defp text_body_state(_body), do: :unsupported

  defp binary_body_state(body) do
    if String.valid?(body) do
      if String.trim(body) == "", do: :empty, else: :present
    else
      :unsupported
    end
  end
end
