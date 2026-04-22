defmodule Mailglass.SendError do
  @moduledoc """
  Raised when email delivery fails.

  ## Types

  - `:adapter_failure` — the Swoosh adapter returned an error (retryable)
  - `:rendering_failed` — HEEx or CSS-inlining pipeline failed
  - `:preflight_rejected` — suppression or rate-limit check blocked the send
  - `:serialization_failed` — message could not be serialized for the adapter

  ## Per-kind Fields

  - `:delivery_id` — binary reference to the failed `%Mailglass.Delivery{}`
    record when available (lands in Phase 2). `nil` when the failure occurred
    before the delivery row was persisted.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed]

  # D-06 / T-PII-002: `:cause` deliberately excluded from JSON serialization —
  # adapter errors wrapped in `:cause` may carry provider payloads with PII.
  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :delivery_id]

  @type t :: %__MODULE__{
          type: :adapter_failure | :rendering_failed | :preflight_rejected | :serialization_failed,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          delivery_id: binary() | nil
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{type: :adapter_failure}), do: true
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.SendError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the failure.
  - `:delivery_id` — the `%Mailglass.Delivery{}` id when available.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      delivery_id: opts[:delivery_id]
    }
  end

  # Brand-voice-conformant messages (D-08). Never "Oops!" or "Something went wrong."
  defp format_message(:adapter_failure, _ctx), do: "Delivery failed: adapter returned an error"
  defp format_message(:rendering_failed, _ctx), do: "Delivery failed: template could not be rendered"
  defp format_message(:preflight_rejected, _ctx), do: "Delivery blocked: pre-send check failed"
  defp format_message(:serialization_failed, _ctx), do: "Delivery failed: message could not be serialized"
end
