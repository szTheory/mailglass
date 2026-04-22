defmodule Mailglass.SuppressedError do
  @moduledoc """
  Raised when delivery is blocked by the suppression list.

  Suppression is a permanent policy block — the recipient opted out,
  hard-bounced, or the tenant explicitly excluded them. Never retryable.
  The `:type` atoms mirror `Mailglass.Suppression.scope` for 1:1 match.

  ## Types

  - `:address` — the recipient address is globally suppressed
  - `:domain` — the recipient domain is globally suppressed
  - `:tenant_address` — the address is suppressed for the current tenant

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:address, :domain, :tenant_address]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :address | :domain | :tenant_address,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()}
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
  Build a `Mailglass.SuppressedError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the suppression record.
  """
  @doc since: "0.1.0"
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

  defp format_message(:address, _ctx),
    do: "Delivery blocked: recipient is on the suppression list"

  defp format_message(:domain, _ctx),
    do: "Delivery blocked: recipient domain is on the suppression list"

  defp format_message(:tenant_address, _ctx),
    do: "Delivery blocked: recipient is suppressed for this tenant"
end
