defmodule Mailglass.SignatureError do
  @moduledoc """
  Raised when webhook signature verification fails.

  Webhook signature errors are never retryable — the caller is either
  misconfigured (wrong secret) or the request is a forgery. Let the
  process crash under supervision and surface a 4xx to the provider.

  ## Types

  - `:missing` — the provider's signature header is not present on the request
  - `:malformed` — the header is present but cannot be parsed
  - `:mismatch` — the signature does not match the computed HMAC
  - `:timestamp_skew` — the signed timestamp is outside the acceptable window

  ## Per-kind Fields

  - `:provider` — the provider atom (`:postmark`, `:sendgrid`, `:mailgun`, …)
    that rejected the request.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:missing, :malformed, :mismatch, :timestamp_skew]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :provider]

  @type t :: %__MODULE__{
          type: :missing | :malformed | :mismatch | :timestamp_skew,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          provider: atom() | nil
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
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
  Build a `Mailglass.SignatureError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the request.
  - `:provider` — the provider atom that rejected the request.
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
      provider: opts[:provider]
    }
  end

  defp format_message(:missing, _ctx),
    do: "Webhook signature verification failed: signature header is missing"

  defp format_message(:malformed, _ctx),
    do: "Webhook signature verification failed: signature is malformed"

  defp format_message(:mismatch, _ctx),
    do: "Webhook signature verification failed: signature does not match"

  defp format_message(:timestamp_skew, _ctx),
    do: "Webhook signature verification failed: timestamp is outside acceptable window"
end
