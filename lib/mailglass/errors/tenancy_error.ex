defmodule Mailglass.TenancyError do
  @moduledoc """
  Raised when tenant context is required but not stamped on the process.

  `Mailglass.Tenancy.tenant_id!/0` raises this when the calling process has
  not been stamped via `Mailglass.Tenancy.put_current/1` (typically from an
  `on_mount/4` callback, Plug, or test setup). Callers that already hold
  tenant context may use `tenant_id!/0` as a fail-loud accessor; callers that
  want the configured default instead should use `Mailglass.Tenancy.current/0`.

  ## Types

  - `:unstamped` — no tenant_id present in the process dictionary

  Never retryable — the caller failed to establish tenant context.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [:unstamped]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :unstamped,
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
  Build a `Mailglass.TenancyError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata about the call site.
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

  defp format_message(:unstamped, _ctx),
    do:
      "Tenant context is not stamped on this process. " <>
        "Call Mailglass.Tenancy.put_current/1 in your on_mount/4 callback or test setup."
end
