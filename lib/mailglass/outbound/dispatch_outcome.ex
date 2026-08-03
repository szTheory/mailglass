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
  @safe_error_modules [
    ConfigError,
    SendError,
    SignatureError,
    StreamPolicyError,
    SuppressedError,
    TemplateError,
    TenancyError
  ]
  @reason_classes [
    :provider_client_rejected,
    :provider_server_error,
    :transport_before_acceptance,
    :provider_acceptance_unknown,
    :pre_dispatch_failure,
    :legacy_payload_missing,
    :payload_missing,
    :payload_corrupt,
    :payload_unsupported_version,
    :payload_expired,
    :payload_scrubbed,
    :payload_dispatching
  ]

  @type class :: :retryable | :terminal | :uncertain
  @type reason_class ::
          :provider_client_rejected
          | :provider_server_error
          | :transport_before_acceptance
          | :provider_acceptance_unknown
          | :pre_dispatch_failure
          | :legacy_payload_missing
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

  def classify({:error, %SendError{context: %{outcome_class: class, reason_class: reason}}})
      when class in @classes and reason in @reason_classes,
      do: new(class, reason, error_module: SendError)

  def classify({:error, %SendError{context: %{reason_class: reason}}})
      when reason in [:payload_corrupt, :payload_unsupported_version],
      do: terminal(reason, error_module: SendError)

  def classify({:error, %SendError{type: :adapter_failure, context: context}}) do
    context
    |> classify_adapter_failure()
    |> with_error_module(SendError)
  end

  def classify({:error, %SendError{}}), do: terminal(:pre_dispatch_failure, error_module: SendError)

  def classify({:error, error})
      when is_struct(error, ConfigError) or is_struct(error, SignatureError) or
             is_struct(error, StreamPolicyError) or is_struct(error, SuppressedError) or
             is_struct(error, TemplateError) or is_struct(error, TenancyError),
      do: terminal(:pre_dispatch_failure, error_module: error.__struct__)

  def classify(_), do: uncertain(:provider_acceptance_unknown)

  @spec safe_projection(t()) :: %{
          class: class(),
          reason_class: reason_class(),
          correlation:
            %{availability: :available, identifier: String.t()} | %{availability: :unavailable}
        }
  def safe_projection(%__MODULE__{} = outcome) do
    projection = %{
      class: outcome.class,
      reason_class: outcome.reason_class,
      correlation: correlation_projection(outcome.context)
    }

    case safe_error_module(outcome.context) do
      nil -> projection
      module -> Map.put(projection, :module, Atom.to_string(module))
    end
  end

  defp classify_adapter_failure(nil), do: uncertain(:provider_acceptance_unknown)

  defp classify_adapter_failure(%{provider_status: status})
       when is_integer(status) and status in 400..499,
       do: terminal(:provider_client_rejected)

  defp classify_adapter_failure(%{provider_status: status})
       when is_integer(status) and status in 500..599,
       do: retryable(:provider_server_error)

  defp classify_adapter_failure(%{reason_class: :transport, dispatch_evidence: :before_acceptance}),
    do: retryable(:transport_before_acceptance)

  defp classify_adapter_failure(%{reason_class: reason})
       when reason in [
              :payload_missing,
              :legacy_payload_unavailable,
              :payload_corrupt,
              :payload_unsupported_version,
              :payload_expired,
              :payload_scrubbed
            ],
       do: terminal(if(reason == :legacy_payload_unavailable, do: :payload_missing, else: reason))

  defp classify_adapter_failure(%{reason_class: :payload_dispatching}),
    do: uncertain(:payload_dispatching)

  defp classify_adapter_failure(_), do: uncertain(:provider_acceptance_unknown)

  defp correlation_projection(%{correlation_id: identifier})
       when is_binary(identifier) and byte_size(identifier) > 0 and byte_size(identifier) <= 512,
       do: %{availability: :available, identifier: identifier}

  defp correlation_projection(_), do: %{availability: :unavailable}

  defp with_error_module(%__MODULE__{} = outcome, module) when module in @safe_error_modules,
    do: %{outcome | context: Map.put(outcome.context, :error_module, module)}

  defp safe_error_module(%{error_module: module}) when module in @safe_error_modules, do: module
  defp safe_error_module(_), do: nil

  defp validate_class!(class) when class in @classes, do: :ok

  defp validate_class!(_), do: raise(ArgumentError, "invalid dispatch outcome class")

  defp validate_reason_class!(reason_class) when reason_class in @reason_classes, do: :ok

  defp validate_reason_class!(_), do: raise(ArgumentError, "invalid dispatch outcome reason class")
end
