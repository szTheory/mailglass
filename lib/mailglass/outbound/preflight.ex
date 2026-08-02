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

  @doc false
  @spec validate_rendered_body(Message.t(), Message.t()) :: :ok | {:error, SendError.t()}
  def validate_rendered_body(
        %Message{swoosh_email: %{html_body: html_body}},
        %Message{} = rendered
      )
      when is_function(html_body, 1) do
    validate_body(rendered)
  end

  def validate_rendered_body(%Message{}, %Message{} = rendered), do: validate_body(rendered)

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

  defp validate_envelope(%Message{} = message) do
    case Message.sole_recipient(message) do
      {:ok, _recipient} ->
        :ok

      {:error, {:recipient_count_invalid, count}} ->
        {:error,
         SendError.new(:preflight_rejected,
           context: %{reason_class: :recipient_count_invalid, recipient_count: count}
         )}

      {:error, :recipient_invalid} ->
        recipient_invalid_error()
    end
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
