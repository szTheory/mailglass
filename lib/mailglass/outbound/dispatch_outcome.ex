defmodule Mailglass.Outbound.DispatchOutcome do
  @moduledoc false

  alias Mailglass.{
    ConfigError,
    SendError,
    SignatureError,
    StreamPolicyError,
    SuppressedError,
    TemplateError,
    TenancyError
  }

  @classes [:retryable, :terminal, :uncertain]
  @reason_classes [
    :provider_client_rejected,
    :provider_server_error,
    :transport_before_acceptance,
    :provider_acceptance_unknown,
    :pre_dispatch_failure
  ]

  @type class :: :retryable | :terminal | :uncertain
  @type reason_class ::
          :provider_client_rejected
          | :provider_server_error
          | :transport_before_acceptance
          | :provider_acceptance_unknown
          | :pre_dispatch_failure
  @type acceptance :: %{required(:message_id) => String.t(), required(:provider_response) => term()}
  @type t :: %__MODULE__{class: class(), reason_class: reason_class(), context: map()}

  @enforce_keys [:class, :reason_class]
  defstruct [:class, :reason_class, context: %{}]

  @spec accepted(acceptance()) :: {:accepted, acceptance()}
  def accepted(%{message_id: message_id, provider_response: _} = acceptance)
      when is_binary(message_id),
      do: {:accepted, acceptance}

  @spec new(class(), reason_class(), keyword() | map()) :: t()
  def new(class, reason_class, context \\ %{}) do
    validate_class!(class)
    validate_reason_class!(reason_class)

    %__MODULE__{class: class, reason_class: reason_class, context: Map.new(context)}
  end

  @spec retryable(reason_class(), keyword() | map()) :: t()
  def retryable(reason_class, context \\ %{}), do: new(:retryable, reason_class, context)

  @spec terminal(reason_class(), keyword() | map()) :: t()
  def terminal(reason_class, context \\ %{}), do: new(:terminal, reason_class, context)

  @spec uncertain(reason_class(), keyword() | map()) :: t()
  def uncertain(reason_class, context \\ %{}), do: new(:uncertain, reason_class, context)

  @spec classify(term()) :: {:accepted, acceptance()} | t()
  def classify({:ok, %{message_id: message_id, provider_response: _} = acceptance})
      when is_binary(message_id),
      do: accepted(acceptance)

  def classify({:error, %SendError{type: :adapter_failure, context: context}}) do
    classify_adapter_failure(context || %{})
  end

  def classify({:error, %SendError{}}), do: terminal(:pre_dispatch_failure)

  def classify({:error, error})
      when is_struct(error, ConfigError) or is_struct(error, SignatureError) or
             is_struct(error, StreamPolicyError) or is_struct(error, SuppressedError) or
             is_struct(error, TemplateError) or is_struct(error, TenancyError),
      do: terminal(:pre_dispatch_failure)

  def classify(_), do: uncertain(:provider_acceptance_unknown)

  @spec safe_projection(t()) :: %{
          class: class(),
          reason_class: reason_class(),
          correlation:
            %{availability: :available, identifier: String.t()} | %{availability: :unavailable}
        }
  def safe_projection(%__MODULE__{} = outcome) do
    %{
      class: outcome.class,
      reason_class: outcome.reason_class,
      correlation: correlation_projection(outcome.context)
    }
  end

  defp classify_adapter_failure(%{provider_status: status})
       when is_integer(status) and status in 400..499,
       do: terminal(:provider_client_rejected)

  defp classify_adapter_failure(%{provider_status: status})
       when is_integer(status) and status in 500..599,
       do: retryable(:provider_server_error)

  defp classify_adapter_failure(%{reason_class: :transport, dispatch_evidence: :before_acceptance}),
    do: retryable(:transport_before_acceptance)

  defp classify_adapter_failure(_), do: uncertain(:provider_acceptance_unknown)

  defp correlation_projection(%{correlation_id: identifier})
       when is_binary(identifier) and byte_size(identifier) > 0 and byte_size(identifier) <= 512,
       do: %{availability: :available, identifier: identifier}

  defp correlation_projection(_), do: %{availability: :unavailable}

  defp validate_class!(class) when class in @classes, do: :ok

  defp validate_class!(_), do: raise(ArgumentError, "invalid dispatch outcome class")

  defp validate_reason_class!(reason_class) when reason_class in @reason_classes, do: :ok

  defp validate_reason_class!(_), do: raise(ArgumentError, "invalid dispatch outcome reason class")
end
