defmodule Mailglass.PublishError do
  @moduledoc """
  Raised when installer golden drift is detected during the `mix mailglass.publish.check` task.

  ## Types

  - `:publish_blocked_golden_drift` — the generated installer snippets do not match the expected goldens.
  """

  @behaviour Mailglass.Error

  @types [:publish_blocked_golden_drift]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :publish_blocked_golden_drift,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()}
        }

  @doc "Returns the closed set of valid `:type` atoms."
  @doc since: "0.2.0"
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.PublishError` struct.
  """
  @doc since: "0.2.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx
    }
  end

  defp format_message(:publish_blocked_golden_drift, ctx) do
    base = "Publish blocked: installer goldens drifted. Run:\n\nMIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors"

    case ctx[:output] do
      output when is_binary(output) and output != "" ->
        base <> "\n\nSubprocess output:\n" <> output

      _ ->
        base
    end
  end
end
