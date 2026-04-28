defmodule Mailglass.StreamPolicyError do
  @moduledoc """
  Raised when a message violates stream policy.

  ## Types

  - `:stream_policy_violated` — the message violates rules for its assigned stream.
  """

  @behaviour Mailglass.Error

  @types [:stream_policy_violated]

  @derive {Jason.Encoder, only: [:type, :message, :context, :detail]}
  defexception [:type, :message, :cause, :context, :detail]

  @type t :: %__MODULE__{
          type: :stream_policy_violated,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          detail: %{rule: atom(), suggestion: String.t()} | nil
        }

  @doc false
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, detail: detail}) do
    format_message(type, detail)
  end

  @doc """
  Build a `Mailglass.StreamPolicyError` struct.
  """
  @doc since: "0.2.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    detail = opts[:detail]

    %__MODULE__{
      type: type,
      message: format_message(type, detail),
      cause: opts[:cause],
      context: opts[:context] || %{},
      detail: detail
    }
  end

  defp format_message(:stream_policy_violated, %{rule: rule, suggestion: suggestion}) do
    "Stream policy violated (#{rule}): #{suggestion}"
  end

  defp format_message(:stream_policy_violated, _) do
    "Stream policy violated"
  end
end
